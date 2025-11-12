# HarmoNet 詳細設計書（ログイン画面）ch05 - セキュリティ設計 v1.0

**Document ID:** HNM-LOGIN-FEATURE-CH05
**Version:** 1.0
**Created:** 2025-11-11
**Updated:** 2025-11-11
**Supersedes:** 初版（Magic Link単体構成）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update
**Standard:** harmonet-detail-design-agenda-standard_v1.0（安全テンプレートモード適用）

---

## 第1章：概要

本章では、HarmoNetログイン機能における **セキュリティ設計方針** を定義する。
Phase9以降は Corbado公式構成（@corbado/react + @corbado/node）を中核とし、SupabaseはRLS認可層として統合運用する。

### 1.1 適用範囲

* Magic Link（Supabase Auth / signInWithOtp）
* Passkey（Corbado WebAuthn / verifySession）
* 共通セッション検証API：`/api/session`
* Supabase RLS / Prisma Schema / JWT管理層

---

## 第2章：脅威モデル（Threat Model）

| 脅威分類            | 想定攻撃                   | 対応策概要                                             |
| --------------- | ---------------------- | ------------------------------------------------- |
| 認証系攻撃           | Magic Link盗用、Passkey偽装 | Corbado verifySession + TTL15分 + Origin限定WebAuthn |
| セッション乗っ取り       | JWT窃取、XSS              | HttpOnly + Secure Cookie, CSP, sanitize-html      |
| CSRF            | 不正クリック送信               | RESTless設計, SameSite=Lax                          |
| リプレイ攻撃          | OTP再利用、メール転送悪用         | Supabase OTP TTL=60秒, 一度きり有効                      |
| 情報漏洩            | テナント越えアクセス             | tenant_id + corbado_user_id RLS強制                 |
| DoS/Brute Force | 短時間再送信乱発               | localStorageクールダウン（1時間3回） + Corbadoレート制御          |

---

## 第3章：防御設計（技術層別）

### 3.1 通信層

* HTTPS/TLS1.3（HSTS有効, redirect強制）
* CSP: `default-src 'self'; script-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline';`
* SRI: 外部CDN未使用
* Referrer-Policy: `strict-origin-when-cross-origin`
* X-Frame-Options: `DENY`

### 3.2 認証層（Corbado + Supabase）

| 区分         | 技術要素                | 内容                                    |
| ---------- | ------------------- | ------------------------------------- |
| Passkey    | Corbado WebAuthn    | Platform認証限定, Origin検証必須              |
| セッション検証    | Corbado Node SDK    | verifySession(cookie) によるJWT検証        |
| Magic Link | Supabase Auth       | signInWithOtp, TTL=60秒                |
| セッション連携    | Supabase Auth       | signInWithIdToken(provider='corbado') |
| RLS        | Supabase/PostgreSQL | tenant_id + corbado_user_id で強制制御     |

### 3.3 クライアント層

* CSRF防止：RESTless fetch構成
* XSS防止：React自動エスケープ + sanitize-html
* localStorage：送信履歴のみ保持
* 入力検証：email正規表現, 全角/半角整形
* Cookie属性：`HttpOnly`, `Secure`, `SameSite=Lax`, `Max-Age=900s`

### 3.4 サーバー層

* `/api/session` による集中セッション検証
* Corbado.verifySession(cookie) → Supabase.signInWithIdToken()
* JWT発行・検証責務をCorbado側に限定
* Supabaseは認可(RLS)のみに使用
* CORBADO_API_SECRETはEdge Function非対応

### 3.5 Passkeyセキュリティ詳細

| 項目       | 設計内容                                                 |
| -------- | ---------------------------------------------------- |
| プロトコル    | WebAuthn Level 3 draft準拠                             |
| 認証器      | Platform優先、Fallbackなし                                |
| Origin検証 | `window.location.origin === RP ID` 強制                |
| 鍵保管      | OSセキュア領域（Keychain / TPM）                             |
| Cookie管理 | `cbo_short_session`（15分） + `supabase-auth-token`（同期） |
| 失効処理     | Corbado + Supabase 二段階削除                             |
| 多端末登録    | 許可、user_metadataで追跡                                  |

### 3.6 ログ・監査・可観測性

| ログ区分        | 出力先                    | 内容                        |
| ----------- | ---------------------- | ------------------------- |
| Auth Log    | Supabase Auth          | signIn/signOut/passkey登録  |
| Corbado Log | Corbado Cloud Console  | 認証イベント/失敗率                |
| RLS Event   | PostgreSQL Audit       | SELECT/UPDATE/DELETE イベント |
| API Log     | Supabase Edge Function | `/api/session` 呼出履歴       |
| Client Log  | Console（開発時）           | 状態遷移/送信試行                 |

* 監査ログ保持期間：90日
* 個人情報はマスキング処理済み

### 3.7 エラーハンドリング・UI安全設計

* ユーザー向けエラーは多言語対応（StaticI18nProvider）
* 技術的詳細は非表示、再試行案内のみ
* 500系発生時：フォーム値クリア、`AuthErrorBanner` 表示
* `aria-live="polite"` により読み上げ対応

---

## 第4章：セキュリティテスト指針

| 分類        | 試験項目             | 合格基準                 |
| --------- | ---------------- | -------------------- |
| 通信        | HTTPS強制 / HTTP拒否 | リダイレクト100%成功         |
| CSRF/XSS  | 改ざん・挿入スクリプト      | 実行不可                 |
| RLS検証     | 他テナント参照          | 403応答                |
| OTPリプレイ   | 同一MagicLink再利用   | 無効化成功                |
| Passkey模倣 | 異Origin署名        | `/api/session` 401応答 |
| Cookie期限  | 15分経過後アクセス       | `/login` へリダイレクト     |

---

## 第5章：定量受入基準

| 指標                       | 基準値                |
| ------------------------ | ------------------ |
| OWASP ASVS               | Level 2（Passkey対応） |
| Lighthouse Security      | ≥97                |
| Passkey成功率               | ≥99%               |
| Magic Link有効時間           | ≤60秒               |
| Cookie有効時間               | ≤15分               |
| RLS逸脱検知                  | 0件                 |
| Corbado VerifySession失敗率 | ≤0.1%              |

---

## 第6章：拡張方針

* MyPageからのPasskey無効化（ユーザー制御機能）
* SMS認証連携（Phase10以降）
* Supabase Edge Functionへの署名強化
* 不正アクセス通知の管理者向け配信

---

## 第7章：関連ファイル

| 種別      | ファイル名                                            | 用途               |
| ------- | ------------------------------------------------ | ---------------- |
| API     | `/app/api/session/route.ts`                      | セッション検証処理        |
| 認証構成    | `login-feature-design-ch03_v1.0.md`              | Passkey設計        |
| 状態管理    | `login-feature-design-ch02_v1.0.md`              | ログイン状態制御         |
| セッション管理 | `login-feature-design-ch04_v1.0.md`              | SessionHandler仕様 |
| DB構成    | `HarmoNet_Phase9_DB_Construction_Report_v1.0.md` | RLSポリシー定義        |

---

## 第8章：改訂履歴

| Version | Date       | Author          | Summary                                                |
| ------- | ---------- | --------------- | ------------------------------------------------------ |
| 1.0     | 2025-11-11 | TKD + Tachikoma | Corbado公式構成に統一。Cookie属性詳細化。脅威モデル・防御設計を技術スタックv4.0準拠に刷新。 |
