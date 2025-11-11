# MagicLinkForm 詳細設計書 - 第7章：環境設定（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH07  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第7章 環境設定

### 7.1 Supabase 環境変数

```bash
# Supabase認証設定
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>

# 管理用（バックエンドのみ使用）
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

# メールリンクリダイレクト設定
NEXT_PUBLIC_MAGICLINK_REDIRECT=/auth/callback
```

**備考**  
- `SUPABASE_SERVICE_ROLE_KEY` はフロントエンドに露出させない。  
- `.env.local` は個人開発環境、`.env.production` はCI/CD配布対象。  
- Redirect URLは `tenant_config` で上書き可能。  

---

### 7.2 テナント設定（tenant_config）

#### 7.2.1 構造例
```typescript
// テナント設定モデル
interface TenantConfig {
  tenant_id: string;
  tenant_name: string;
  corbado_project_id?: string;
  supabase_project_ref: string;
  magiclink_redirect: string;
  smtp_domain: string;
  smtp_sender_name: string;
  created_at: Date;
  updated_at: Date;
}
```

#### 7.2.2 運用例
| tenant_id | tenant_name | magiclink_redirect | smtp_domain | supabase_project_ref |
|------------|--------------|--------------------|--------------|----------------------|
| T001 | Alpha管理組合 | https://alpha.harmonet.app/auth/callback | mail.alpha.jp | proj_alpha |
| T002 | Bravo管理組合 | https://bravo.harmonet.app/auth/callback | mail.bravo.jp | proj_bravo |

**運用ルール**  
- 各テナントごとに `magiclink_redirect` と `smtp_domain` を必ず設定。  
- MagicLink送信時、`tenant_context` から設定値を参照し、メールリンクを生成。  

---

### 7.3 環境ファイル構成
```
.env.local                # 開発環境
.env.staging              # ステージング
.env.production           # 本番環境
.env.tenant.<tenant_id>   # テナント個別設定
```

#### 各ファイル例

**`.env.production`**
```bash
NEXT_PUBLIC_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://api.harmonet.app
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
NEXT_PUBLIC_MAGICLINK_REDIRECT=/auth/callback
```

**`.env.tenant.T001`**
```bash
TENANT_ID=T001
NEXT_PUBLIC_MAGICLINK_REDIRECT=https://alpha.harmonet.app/auth/callback
SMTP_DOMAIN=mail.alpha.jp
SMTP_SENDER_NAME=HarmoNet通知（Alpha管理組合）
```

---

### 7.4 認証関連設定

| 設定項目 | 内容 | 推奨値 |
|----------|------|--------|
| `shouldCreateUser` | 自動ユーザー作成可否 | false |
| `emailRedirectTo` | メール内リンク先 | `/auth/callback`（tenant_config優先） |
| `auth.signInWithOtp()` | 認証API | Supabase v2.43 |
| `RLS_POLICY` | 行レベルセキュリティ | 有効（tenant_idで分離） |

---

### 7.5 i18n設定

#### 言語リソース配置
```
/public/locales/
 ├─ ja/common.json
 ├─ en/common.json
 └─ zh/common.json
```

**共通キー構成**
```json
"auth": {
  "magiclink": {
    "enter_email": "メールアドレスを入力",
    "send": "Magic Linkを送信",
    "sent": "メールを送信しました",
    "check_email": "メールをご確認ください"
  }
}
```

---

### 7.6 CI/CD環境での考慮点
- SecretsはGitHub Actionsの`Environment Secrets`で管理。  
- デプロイ時に `.env.production` とテナント別 `.env.tenant.*` を自動マージ。  
- Supabaseの`auth.config.toml`はCIで自動更新可。  

---

### 7.7 セキュリティ監査対応
- `.env`ファイルをGit追跡対象外に設定。  
- `NEXT_PUBLIC_*` 以外のキーをブラウザに露出させない。  
- Secrets管理はVaultまたはSupabase Secrets機能を使用。  

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。マルチテナント対応・tenant_config構造・CI/CD連携を明記。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第8章 監査・保守指針（ch08）へ進む
