# MagicLinkForm 詳細設計書 - 第6章：セキュリティ設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH06
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Passkey統合対応・脅威モデル拡張）

---

## 第6章 セキュリティ設計

### 6.1 目的

MagicLinkForm (A-01) のセキュリティ設計は、**MagicLink（メールリンク認証）** と **Passkey（WebAuthn認証）** の両方式を統合し、パスワードレス認証の信頼性・可用性・多要素性を強化することを目的とする。
本章では、従来のメールリンク運用に加えて、Corbado SDK 経由のWebAuthn認証に関する脅威モデル、RLS整合、通信セキュリティ、秘密情報管理を明確化する。

---

### 6.2 脅威モデルと対策方針

| 想定脅威                  | リスク内容                | 対策概要                                         |
| --------------------- | -------------------- | -------------------------------------------- |
| **Email Enumeration** | 登録有無の推測による情報漏洩       | UIは常に成功メッセージ固定、ログのみ詳細記録。                     |
| **大量送信 (SPAM/DoS)**   | ボットによる連続送信攻撃         | Supabase Authレート制限 + 状態 `sending` による多重送信防止。 |
| **リンク乗っ取り／不正リダイレクト**  | MagicLink経由で外部ドメイン誘導 | `emailRedirectTo` を `.env` 定義の固定値に限定。        |
| **トークン盗用／再利用**        | セッションハイジャック          | HTTPS + 短期JWT（10分） + Secure/HTTPOnly Cookie。 |
| **WebAuthn Origin偽装** | Passkey登録元偽装によるなりすまし | Corbado SDKのRP ID固定・Origin検証必須設定。            |
| **Corbado API不正利用**   | 認証APIの外部悪用           | `CORBADO_API_SECRET` をサーバー側専用で管理、フロント非公開。    |
| **Passkey拒否／中断**      | 認証途中キャンセルによる脆弱状態     | `error_auth` 状態保持と再試行制御で安全にリカバリ。             |
| **XSS / HTML注入**      | 入力欄経由スクリプト混入         | React自動エスケープ + `dangerouslySetInnerHTML` 禁止。 |
| **CSRF**              | 他ドメインからのフォーム送信       | Supabase CORS設定 + SameSite=Strict Cookie。    |
| **SMTPなりすまし**         | 認証メール偽造              | SPF/DKIM/DMARC整備。Authドメイン専用サブドメイン運用。         |

---

### 6.3 Magic Link / Passkey ポリシー

| 項目        | 設定方針                          | 理由                     |
| --------- | ----------------------------- | ---------------------- |
| 有効期限      | **10分以内**                     | 短期トークンで攻撃ウィンドウを最小化     |
| ワンタイム性    | 使用後即失効                        | トークン再利用防止              |
| リダイレクト    | 固定：`APP_ORIGIN/auth/callback` | 不正遷移防止                 |
| ユーザー作成    | `shouldCreateUser: false`     | 登録は管理者制限               |
| Passkey登録 | Corbadoダッシュボード管理（ユーザー登録時のみ）   | 不正登録防止                 |
| RP ID     | `harmonet.app` 固定             | WebAuthn標準準拠（Origin一致） |

---

### 6.4 Supabase / Corbado Auth 設定要件

| 項目                  | 推奨設定                                      | 備考             |
| ------------------- | ----------------------------------------- | -------------- |
| Supabase JWT有効期限    | 5〜10分                                     | 短期セッション採用      |
| Corbado Session TTL | 10分                                       | Supabaseと整合性保持 |
| Rate Limit          | 標準＋WAF追加                                  | 攻撃抑止           |
| Corbado ProjectID   | `.env` に `NEXT_PUBLIC_CORBADO_PROJECT_ID` | 参照用（公開可）       |
| Corbado SecretKey   | `.env` に `CORBADO_API_SECRET`             | 非公開。サーバー専用。    |
| HTTPS強制             | 必須                                        | WebAuthn要件     |

---

### 6.5 クライアント防御実装

* **多重送信防止:** ボタン `disabled` 制御（`sending` / `passkey_auth` 状態時無効）。
* **例外共通化:** Supabase/Corbadoエラーを `mapUnifiedError()` で一元化。
* **ARIAセーフ通知:** `aria-live="polite"` により情報漏洩なしで状態報告。
* **CSPヘッダ:** `script-src 'self'; object-src 'none';` により外部スクリプト制限。
* **Corbado通信:** `window.isSecureContext` を確認し、HTTP環境での実行を拒否。

---

### 6.6 RLS（Row Level Security）整合

* 認証後、Corbado経由でも Supabase JWT が `tenant_id` を保持することを保証。
* RLSポリシーは `tenant_id = (auth.jwt() ->> 'tenant_id')` を基準とする。
* Passkeyユーザーも MagicLinkユーザーと同一の `user_profiles` レコード構造を使用。
* Corbado UserID は `external_auth_id` フィールドに保存（UUIDv4形式）。
* SupabaseとCorbado間でRLS整合を保つため、サーバー側検証ロジックで JWT署名を相互確認。

---

### 6.7 ログ・監査ポリシー

| ログ種別            | 収集内容                                              | 保存先                    | 備考     |
| --------------- | ------------------------------------------------- | ---------------------- | ------ |
| **送信イベントログ**    | email, tenant_id, IP, 成否, mode(passkey/magiclink) | Supabase Storage (暗号化) | GDPR対応 |
| **Passkey認証ログ** | 成否, RP ID, UserAgent, Timestamp                   | Sentry + Supabase Logs | 監査追跡   |
| **Rate制限ログ**    | IP, UserAgent, Count                              | Supabase Logs          | 攻撃監視   |
| **Corbado通信ログ** | API応答コード, ProjectID, JWT署名検証結果                    | 非公開ストレージ               | 内部監査専用 |

---

### 6.8 運用セーフガード

* `.env` に `DISABLE_AUTH_FLOW=true` でログイン機能を一時停止可能。
* Passkey登録フラグを FeatureFlag 管理し、段階的リリースを実現。
* メンテナンス中はユーザーに再送信抑止メッセージを表示。
* Supabase / Corbado API バージョン変更検知を CI で自動通知。
* 半年ごとに認証ログを自動監査し、異常操作（連続拒否など）をレポート化。

---

### 6.9 秘密情報・環境変数管理

| 変数名                              | 用途                | 保護範囲               |
| -------------------------------- | ----------------- | ------------------ |
| `NEXT_PUBLIC_SUPABASE_URL`       | Supabaseクライアント初期化 | フロント公開可            |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY`  | 匿名接続キー            | フロント公開可            |
| `NEXT_PUBLIC_CORBADO_PROJECT_ID` | Corbado識別子        | フロント公開可            |
| `CORBADO_API_SECRET`             | Corbado API連携キー   | サーバー専用。CIシークレット登録。 |
| `SUPABASE_SERVICE_ROLE_KEY`      | Supabaseサービスキー    | サーバー専用。ログ生成用。      |
| `DISABLE_AUTH_FLOW`              | 緊急停止フラグ           | 管理者専用              |

---

### 6.10 セキュリティ検証方針

| 検証項目            | 手法                      | 頻度     |
| --------------- | ----------------------- | ------ |
| CSRF/XSSテスト     | OWASP ZAP + Playwright  | 各リリース前 |
| Rate Limit試験    | Locust / k6             | 半期1回   |
| MagicLink再利用テスト | Playwright E2E          | 各リリース前 |
| Passkey拒否テスト    | Corbado Mock + Jest     | 各ビルド時  |
| 環境変数監査          | CI自動検査                  | 毎ビルド   |
| JWT署名整合検証       | Supabase + Corbado連携テスト | 各デプロイ前 |

---

### 🧾 Change Log

| Version  | Date           | Summary                                      |
| -------- | -------------- | -------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（MagicLink専用構成）                            |
| **v1.1** | **2025-11-12** | **Passkey統合対応。Corbado脅威モデル追加・RLS整合・環境変数拡張。** |
