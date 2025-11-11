# 第5章: セキュリティ対策（A-01〜A-03共通）

**Document ID:** HARMONET-LOGIN-CH05-SECURITY  
**Version:** 1.1  
**Status:** Phase9 承認仕様準拠（ContextKey: HarmoNet_LoginFeature_Phase9_v1.3_Approved）  
**Last Updated:** 2025-11-10  

---

## ch05-1. 目的と適用範囲

本章は、HarmoNetログイン機能における **セキュリティ設計方針** を定義する。  
対象範囲は以下のコンポーネント全体に及ぶ：

- **A-01 MagicLinkForm**
- **A-02 PasskeyButton**
- **A-03 AuthCallbackHandler**
- **共通層:** StaticI18nProvider, Supabase Auth, RLS, JWT

本設計の目標は「セキュリティを意識させない安心感」。  
ユーザー操作は簡潔で自然、しかし内部では堅牢なゼロトラスト設計を維持する。

---

## ch05-2. 脅威モデル（Threat Model）

| 脅威分類 | 想定攻撃 | 対応策概要 |
|-----------|-----------|-------------|
| **認証系攻撃** | Magic Linkの盗用、Passkey偽装 | Link署名の短期有効化、Origin限定のWebAuthn |
| **セッション乗っ取り** | JWT窃取、XSS経由の盗用 | HttpOnly + Secure Cookie、CSP、sanitize-html |
| **CSRF** | 不正クリックによる送信再試行 | RESTless設計（非フォーム送信）、SameSite=Strict |
| **リプレイ攻撃** | OTP再利用、メール転送悪用 | Supabase側トークン一度きり／60秒TTL |
| **情報漏洩** | テナント間アクセス、ID推測 | tenant_idベースRLS＋UUID v7採用 |
| **DoS/Brute Force** | 再送信乱発 | localStorageクールダウン＋1時間3回制限 |

---

## ch05-3. 防御設計（技術層別）

### 3.1 通信層
- **HTTPS/TLS1.3**（HSTS有効, redirect強制）
- **CSP (Content Security Policy)**  
  `default-src 'self'; script-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline';`
- **SRI (Subresource Integrity)**: 外部CDNを使用しない原則。
- **Referrer-Policy:** `strict-origin-when-cross-origin`
- **X-Frame-Options:** `DENY`（Clickjacking防止）

### 3.2 認証層（Supabase Auth）
- Magic Link: `signInWithOtp` のトークンTTL = **60秒**  
- Passkey: WebAuthn APIによるOrigin-bound Credential（偽装不可）
- Supabase側では `user_metadata.tenant_id` によりRLSを強制。

### 3.3 クライアント層
- **CSRF防止:** すべてのPOST通信はfetch APIによるRESTless設計。
- **XSS防止:**  
  - 外部HTML注入禁止（React自動エスケープ）  
  - 動的コンテンツは `sanitize-html` でフィルタリング。  
- **localStorage利用範囲:** 送信履歴（日時・回数）のみ。個人情報は保存しない。
- **入力検証:** email正規表現、全角・半角混在の自動整形。

### 3.4 サーバー層
- **RLSポリシー:**  
  ```sql
  CREATE POLICY tenant_isolation ON users
  FOR SELECT USING (auth.uid() = id AND tenant_id = current_setting('app.current_tenant_id'));

・JWT構造:
{
  "sub": "uuid",
  "aud": "authenticated",
  "user_metadata": { "tenant_id": "xxxx-tenant-uuid" },
  "exp": 1700000000
}

・エラーレスポンス: 汎用メッセージのみ返却（内部エラー非公開）。

ch05-4. Passkeyセキュリティ詳細
| 項目              | 設計内容                                   |
| --------------- | -------------------------------------- |
| **プロトコル**       | WebAuthn Level 2                       |
| **認証器タイプ**      | Platform (内蔵)優先。Fallbackなし。            |
| **登録時Origin検証** | `window.location.origin` = `rpId` 強制一致 |
| **鍵保管先**        | デバイスセキュア領域（OS Keychain）                |
| **失効処理**        | Supabase Authから`passkey.delete()`で解除   |
| **複数デバイス登録**    | 許可（登録履歴をuser_metadataに記録）              |
| **ログインロジック**    | passkey → fallback: Magic Link（自動選択）   |

パスキー認証情報はデバイス内に留まり、クラウド側に鍵は保存されない。
ユーザーの端末PINまたは生体認証を通じて署名が生成される。

ch05-6. ログ・監査・可観測性
| ログ区分           | 出力先                      | 内容                            |
| -------------- | ------------------------ | ----------------------------- |
| **Auth Log**   | Supabase Auth            | signIn/signOut/passkey 登録     |
| **RLS Event**  | PostgreSQL Audit Trigger | SELECT / UPDATE / DELETE イベント |
| **Edge Log**   | Supabase Edge Function   | OTP送信・再送エラー記録                 |
| **Client Log** | Console (開発時のみ)          | 送信状態／残クールダウン時間                |

・監査ログの保持期間：90日
・個人識別情報はマスキング（Email → h***@example.com）

ch05-7. エラーハンドリングとUI安全設計
・すべてのユーザー向けエラー文言は多言語対応（C-03）。
・技術的詳細は画面に表示しない。常に「再試行」「時間をおいて試す」と案内。
・Supabase側で500系発生時、UIではFallbackメッセージ＋リロード提案を表示。
・フォーム入力値は送信後に即座にクリア。

ch05-8. セキュリティテスト指針
| 分類            | 試験項目                   | 合格基準               |
| ------------- | ---------------------- | ------------------ |
| **通信**        | HTTPS強制 / HTTP無効       | 100%リダイレクト成功       |
| **CSRF/XSS**  | リクエスト改ざん・スクリプト挿入試験     | 実行不可               |
| **RLS検証**     | 他テナントデータ参照             | 不可（403）            |
| **OTPリプレイ**   | 同一Link再利用              | 無効（Supabaseトークン失効） |
| **Passkey模倣** | 異Origin署名              | 検証失敗（Origin不一致）    |
| **アクセシビリティ**  | aria-live, focus, tab順 | 全要素対応済             |

ch05-9. 受け入れ基準（定量）
1.OWASP ASVS Level 1 100%適合
2.Lighthouse Security スコア ≥ 95点
3.Passkey登録成功率 ≥ 99%（全対応ブラウザ）
4.Magic Link送信リンク有効時間 ≤ 60秒
5.他テナント参照試験 100%遮断（RLSログ監査一致）
6.CSRF/XSS模倣試験全項目失敗（実行防止）

ch05-10. 今後の拡張方針
・デバイス紛失対応: MyPage内でのPasskey無効化機能
・SMS認証連携: 高齢者・メール不達対応策としてPhase10以降検討
・Edge Function署名: OTPメール送信署名の強化（ES256）
・監査通知: 不正アクセス試行検出時に管理者へ通知

ch05-11. 整合性と参照
・Supabase設定: 20251107000001_enable_rls_policies.sql
・Prisma Schema: schema.prisma 内 User, Tenant モデル
・参照ドキュメント:
　・login-feature-design-ch03_latest.md（ログイン画面仕様）
　・login-feature-design-ch04_v1.1.md（Magic Link送信完了）
　・HarmoNet_Phase9_DB_Construction_Report_v1.0.md（RLS構成）

ch05-12. 変更履歴
| Version  | Date       | Summary                                                 |
| -------- | ---------- | ------------------------------------------------------- |
| **v1.1** | 2025-11-10 | Magic Link + Passkey対応。RLS仕様統合。XSS/CSRF対策再設計。Phase9承認版。 |
| **v1.0** | 2025-10-27 | 初版（旧Phase8ベース, Magic Link単体構成）。                         |

**[← 第4章に戻る](login-feature-design-ch04_latest.md)  |  [第6章へ →](login-feature-design-ch06_latest.md)**

**Created:** 2025-11-10 / **Last Updated:** 2025-11-10 / **Version:** 1.1 / **Document ID:** HARMONET-LOGIN-CH05-SECURITY
