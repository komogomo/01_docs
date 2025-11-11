# MagicLinkForm 詳細設計書 - 第6章：セキュリティ考慮事項（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH06  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第6章 セキュリティ考慮事項

### 6.1 脅威モデル（要点）

| 脅威 | 想定リスク | 対策 |
|------|-----------|------|
| **Email Enumeration**（存在確認攻撃） | メールアドレス存在有無が第三者に推測される | UIは常に「送信しました（メールをご確認ください）」で固定応答。ログには詳細記録。 |
| **Rate Limiting回避** | 短時間大量リクエストでSPAM/DoS化 | サーバー側レート制限（Supabase Authの内蔵制限 + 逆プロキシ制限）。クライアント側は連打防止（`state==='sending'`）。 |
| **リンク乗っ取り／リダイレクト悪用** | `emailRedirectTo` を悪用し任意サイトへ誘導 | リダイレクト許可ドメインの**厳格ホワイトリスト**化（`.env` / 環境設定参照）。 |
| **トークン窃取** | メールリンクや端末からトークンを盗む | HTTPS必須、短期有効期限、1回限りの使用、クリップボード禁止（UI方針）、Secure/HTTPOnly Cookie。 |
| **XSS** | 入力欄やメッセージからのスクリプト注入 | React自動エスケープ、`dangerouslySetInnerHTML`不使用、Content-Security-Policy導入。 |
| **CSRF** | フォーム送信のなりすまし | 認証APIはSameSite=Strict Cookie、POSTのみ、CORS厳格化。 |
| **SPF/DKIM/DMARC未整備** | メール到達性低下 / なりすまし | 発信ドメインでSPF/DKIM/DMARC有効化。サブドメイン鍵管理。 |

---

### 6.2 Magic Link 設定ポリシー

- **有効期限**：推奨 **10分以内**。試験段階は 15–30分でも可。  
- **ワンタイム性**：リンク使用後は失効。再利用禁止。  
- **リダイレクト**：`emailRedirectTo = {APP_ORIGIN}/auth/callback` 固定。サブドメイン展開はホワイトリスト化。  
- **ユーザー自動作成**：`shouldCreateUser: false` を基本。管理者が事前登録。  
- **メール本文**：リンク以外の個人情報を含めない。サポート連絡先のみ。  

---

### 6.3 Supabase Auth 設定（推奨）

| 設定項目 | 推奨値 | 備考 |
|----------|--------|------|
| JWT有効期限 | 5〜10分 | 短期化＋リフレッシュを許可 |
| Rate Limit | デフォルト＋WAF | 国別/ASN別ブロックも検討 |
| Provider | Emailのみ | Phase9はパスワードレス（MagicLink + Passkey） |
| Redirect Domains | 本番/検証の2件のみ | 通常は`https://app.example.com` / `https://stg.example.com` |
| SMTP送信 | SPF/DKIM/DMARC整備 | サブドメイン（auth.example.com）推奨 |

---

### 6.4 フロントエンド防御

- ボタンクリック後は `disabled`（多重送信防止）。  
- 失敗時の詳細理由は表示しない（列挙回避）。  
- `aria-live="polite"` のみ使用し、エラー詳細はトースト等で一般化。  
- エラーコードはサーバーログへのみ詳細出力（PIIを含めない）。  

---

### 6.5 RLS（Row Level Security）整合

- 認証後のセッションは Supabase で自動付与。  
- RLSポリシーは**テナントIDに基づくアクセス制御**（`tenant_id = auth.uid()` ではなく、ユーザー-テナント紐付けテーブルで判定）。  
- MagicLinkは**ログインまで**を担い、データ可視性はRLS側の責務。  

---

### 6.6 監査・ログ設計

- **成功/失敗イベント**をすべてロギング（時刻、IP、UA、tenant_id、masked email）。  
- Rate Limit 該当は別カテゴリで記録。  
- 監査用テーブルはPII最小化（メールはハッシュ + 下4桁等）。  
- 重要イベントは**不変ログ**（WORM相当）へ定期転送。  

---

### 6.7 運用セーフガード

- **メンテナンス時停止**：送信UIを一時停止可能なフラグを`.env` or Feature Flagで提供。  
- **CAPTCHA導入オプション**：スパム流入時のみ有効化（hCaptchaなど）。  
- **ブラウザ互換**：WebView等でメールリンクが開く場合に備え、手入力復帰導線をUIに準備。  

---

### 6.8 秘密情報と環境変数

- `.env` に `NEXT_PUBLIC_*` 以外の秘密を置かない。  
- SMTP資格情報は**サーバー専用**・ローテーションを定期実施。  
- 監視用キーは**読み取り専用**・最小権限（PoLP）。  

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。脅威モデル、RLS整合、メール/リダイレクト/レート制限の詳細化。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第7章 環境設定（ch07）へ進む
