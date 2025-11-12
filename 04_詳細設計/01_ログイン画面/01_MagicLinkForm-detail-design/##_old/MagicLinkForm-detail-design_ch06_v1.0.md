# MagicLinkForm 詳細設計書 - 第6章：セキュリティ設計（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH06
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式整合版（技術スタック v4.0 準拠）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第6章 セキュリティ設計

### 6.1 目的

MagicLinkForm のセキュリティ設計は、パスワードレス認証の信頼性を維持しつつ、**不正送信・なりすまし・情報漏洩リスク**を最小化することを目的とする。
本章では、メールリンク運用上の脅威対策、RLS整合、秘密情報管理、監査方針を定義する。

---

### 6.2 脅威モデルと対策方針

| 想定脅威                          | リスク内容                | 対策概要                                                                  |
| ----------------------------- | -------------------- | --------------------------------------------------------------------- |
| **Email Enumeration**（存在確認攻撃） | 登録有無を悪用され、ユーザー情報が漏洩  | UIは常に成功応答（「送信しました」）を固定表示。ログに詳細結果を残すのみ。                                |
| **大量送信 (SPAM/DoS)**           | ボットによる連続送信攻撃         | Supabase Auth のレート制限 + 逆プロキシ(WAF)で制御。UIは `state==='sending'` による連打防止。 |
| **リンク乗っ取り / 不正リダイレクト**        | Magic Link を悪用し外部へ誘導 | `emailRedirectTo` のホワイトリスト固定化。`.env` に明示登録。                           |
| **トークン盗用 / 再利用**              | メールリンクやセッションを奪取      | HTTPS強制 + 短期有効期限(10分) + ワンタイム使用。Secure/HTTPOnly Cookie限定。             |
| **XSS / HTML注入**              | 入力欄経由のスクリプト混入        | React自動エスケープ + `dangerouslySetInnerHTML`禁止。CSPヘッダ設定。                  |
| **CSRF**                      | 他サイトからの送信誘導          | Supabase APIがCORS制限 + SameSite=Strict Cookie採用。                       |
| **SMTPなりすまし**                 | メール改ざん／認証失敗          | SPF/DKIM/DMARC 有効化。ドメインキーを定期更新。                                       |

---

### 6.3 Magic Link 発行ポリシー

| 設定項目   | 方針                            | 理由         |
| ------ | ----------------------------- | ---------- |
| 有効期限   | **10分以内**                     | 攻撃ウィンドウ最小化 |
| ワンタイム性 | 使用後即失効                        | リンク再利用防止   |
| リダイレクト | 固定 `APP_ORIGIN/auth/callback` | 外部サイト誘導防止  |
| ユーザー作成 | `shouldCreateUser: false`     | 管理者登録制を維持  |
| メール本文  | 個人情報非掲載                       | PII漏洩リスク排除 |

---

### 6.4 Supabase Auth 設定要件

| 設定項目             | 推奨値                | 備考                         |
| ---------------- | ------------------ | -------------------------- |
| JWT有効期限          | 5〜10分              | セッション再発行可                  |
| Rate Limit       | デフォルト＋WAF          | DoS対策                      |
| Provider         | Emailのみ            | PasskeyButton(A-02)と共存     |
| Redirect Domains | 本番/検証2件のみ          | app / stg 環境固定             |
| SMTP署名           | SPF + DKIM + DMARC | サブドメイン(auth.example.com)利用 |

---

### 6.5 クライアント防御実装

* **多重送信防止**：ボタン `disabled` 制御、状態 `sending` ロック。
* **エラー一般化**：UIでは詳細非表示（列挙攻撃防止）、サーバーログのみ詳細保持。
* **ARIA安全**：`aria-live="polite"` により情報暴露なしに状態通知。
* **コード最小化**：`dangerouslySetInnerHTML` 不使用。DOM生成はReact経由で自動エスケープ。

---

### 6.6 RLS（Row Level Security）整合

* 認証完了後、Supabase が自動付与するセッションJWTにより tenant_id 判定を実施。
* RLSは「`tenant_id = (auth.jwt() ->> 'tenant_id')`」を原則とし、MagicLinkFormはRLS適用前段階に留まる。
* `users`, `user_tenants` テーブルでテナント紐付けを明示。
* データ操作はすべてサーバーサイド経由で実施（直接DB操作なし）。

---

### 6.7 ログ・監査方針

| ログ種別         | 収集内容                        | 保存方針                   |
| ------------ | --------------------------- | ---------------------- |
| **送信イベントログ** | 時刻、IP、UA、tenant_id、ハッシュ化メール | Supabase Storageへ暗号化保存 |
| **失敗イベントログ** | Error Code / Stack / Status | 監査用S3 (WORMポリシー)       |
| **Rate制限ログ** | リクエスト頻度 / IP / User-Agent   | 通常ログと別カテゴリ保存           |
| **監査可視化**    | Supabase Logs + Sentry統合    | Phase10で運用拡張予定         |

---

### 6.8 運用セーフガード

* メンテナンス中は `.env` フラグ `DISABLE_MAGICLINK=true` で送信停止。
* CAPTCHA (hCaptcha) オプションを Feature Flag 化。
* WebViewやモバイルメーラ起動環境では「手動入力ログイン」誘導を準備。
* 管理者監査レポートを定期生成し、送信量異常を検知。

---

### 6.9 秘密情報・環境変数管理

* `.env` に格納可能な公開値は `NEXT_PUBLIC_` プレフィックス限定。
* SMTP / API Secret は**サーバー側環境のみ保持**。
* 秘密情報は `.env.local` 管理・Git除外。
* ローテーション周期：**90日**。最小権限原則（PoLP）を遵守。

---

### 6.10 セキュリティ検証方針

| 検証項目        | 手法                     | 頻度     |
| ----------- | ---------------------- | ------ |
| CSRF/XSSテスト | OWASP ZAP + Playwright | 各リリース前 |
| レート制限テスト    | Locust / k6            | 半期1回   |
| メールリンク再利用   | 自動テスト（E2E）             | 各リリース前 |
| .env監査      | CI自動検査                 | 毎ビルド   |

---

### 🧾 Change Log

| Version | Date       | Summary                                     |
| ------- | ---------- | ------------------------------------------- |
| v1.0    | 2025-11-11 | 初版（Phase9仕様：RLS整合／脅威モデル強化／メール安全化／環境変数管理統合版） |
