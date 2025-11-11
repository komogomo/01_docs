# Claude 実行指示書（Phase9.7 認証拡張対応）

**プロジェクト:** HarmoNet（マルチテナント型コミュニティOS）  
**フェーズ:** Phase9.7 – 認証方式拡張対応（Passkey + MagicLink制御）  
**対象環境:** Supabase（Docker / PostgreSQL 15.6 / Prisma 6.19）  
**担当:** Claude（実装）＋ TKD（確認・承認）  
**監督:** Tachikoma（PMO / Architect）  
**作業日:** 2025-11-07  
**Document ID:** HNM-AUTH-EXT-INSTR-20251107  
**Version:** 1.0.1  

---

## 🎯 目的

Magic Link（メール認証）と Passkey（WebAuthn/FIDO2）の統合、  
およびテナント単位の Magic Link 有効時間・回数制御機構を導入する。  

本作業では Phase9.6 環境（RLS実装済・Prisma整合済）を基盤とし、  
DB拡張・RLS追記・Seed更新・文書改訂を安全に実施する。

---

## 🧩 現在のDB状態（Phase9.6 / 2025-11-06 時点）

| 項目 | 状態 |
|------|------|
| **テーブル数** | 31 |
| **ENUM型数** | 11 |
| **RLSポリシー数** | 104（全テーブル適用済） |
| **認証構成** | Magic Link（GoTrue v2）／Passkey未導入 |
| **Prismaスキーマ** | v1.7 |
| **マイグレーション履歴** | `20251107000000_initial_schema.sql` / `20251107000001_enable_rls_policies.sql` |
| **DB構築報告書** | HarmoNet_Phase9_DB_Construction_Report_v1.0.md |
| **技術基準** | harmonet-technical-stack-definition_v3.6.md |

---

## 🧭 作業概要

| 項目 | 内容 |
|------|------|
| 認証方式 | MagicLink＋Passkey ハイブリッド化 |
| 制御範囲 | テナント単位（auth_policy_json） |
| 拡張項目 | 有効時間・回数・Passkey許可・レート制限 |
| 新規構成 | 2テーブル追加・2列追加・8RLSポリシー追加 |
| Prisma更新 | schema.prisma 追記・Client再生成 |
| Seed更新 | 権限 `manage_auth_policy` 追加 |
| ドキュメント更新 | Technical Stack v3.6 / DB報告書 v1.1 |

---

## ⚙️ 作業手順（Claude実行）

### STEP 1️⃣ 対象ファイルをClaudeナレッジに登録

| 種別 | ファイル | 目的 |
|------|-----------|------|
| 技術基準 | `/01_docs/05_implementation/harmonet-technical-stack-definition_v3.6.md` | 技術構成・認証仕様基準 |
| DB報告 | `/01_docs/05_implementation/HarmoNet_Phase9_DB_Construction_Report_v1.0.md` | 現行DB構成 |
| マイグレーション | `/01_docs/05_implementation/20251107000000_initial_schema.sql` | スキーマ定義 |
| RLS構成 | `/01_docs/05_implementation/20251107000001_enable_rls_policies.sql` | 現行ポリシー定義 |
| ドキュメント定義 | `/01_docs/00_project/harmonet-document-policy_latest.md` | 出力ルール |
| ディレクトリ定義 | `/01_docs/00_project/harmonet-docs-directory-definition_v3.4-Final.md` | ディレクトリ構成基準 |
| AI開発ガイド | `/01_docs/00_project/ai-driven-development-guide_v1.0.md` | 実行体制・権限指針 |

---

### STEP 2️⃣ 新規マイグレーション作成

ファイル名：  
`/supabase/migrations/20251107000002_auth_policy_extension.sql`

```sql
-- Auth Policy Extension Migration

-- tenant_settings 拡張
ALTER TABLE tenant_settings
  ADD COLUMN auth_policy_json JSONB NOT NULL DEFAULT jsonb_build_object(
    'version', 1,
    'effective_from', NOW(),
    'magic_link_expiry_minutes', 10,
    'magic_link_max_uses', 3,
    'passkey_enabled', true,
    'rate_limit_per_ip_per_hour', 60
  );

-- user_profiles 拡張
ALTER TABLE user_profiles
  ADD COLUMN passkey_enabled BOOLEAN NOT NULL DEFAULT false;

-- magic_link_usage_logs
CREATE TABLE magic_link_usage_logs (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  token_id TEXT NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- audit_auth_events
CREATE TABLE audit_auth_events (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT,
  event_type TEXT NOT NULL,
  event_json JSONB NOT NULL,
  occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

STEP 3️⃣ 新RLSポリシー追加

ファイル名：
20251107000003_enable_rls_auth_extension.sql：昨晩最終状態

-- RLS for auth extension tables

-- magic_link_usage_logs
ALTER TABLE magic_link_usage_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY magic_link_usage_logs_select ON magic_link_usage_logs
  FOR SELECT USING (tenant_id::text = (auth.jwt() ->> 'tenant_id'));
CREATE POLICY magic_link_usage_logs_insert ON magic_link_usage_logs
  FOR INSERT WITH CHECK (tenant_id::text = (auth.jwt() ->> 'tenant_id'));

-- audit_auth_events
ALTER TABLE audit_auth_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_auth_events_select ON audit_auth_events
  FOR SELECT USING (tenant_id::text = (auth.jwt() ->> 'tenant_id'));
CREATE POLICY audit_auth_events_insert ON audit_auth_events
  FOR INSERT WITH CHECK (tenant_id::text = (auth.jwt() ->> 'tenant_id'));

STEP 4️⃣ Prisma更新
1.schema.prisma に以下追記：CLaude要レビュー
model tenant_settings {
  id               String   @id
  tenant_id        String
  auth_policy_json Json     @default("{}")
}

model user_profiles {
  user_id         String
  tenant_id       String
  passkey_enabled Boolean  @default(false)
  updated_at      DateTime
  @@id([user_id, tenant_id])
}

model magic_link_usage_logs {
  id        String   @id
  tenant_id String
  user_id   String
  token_id  String
  used_at   DateTime @default(now())
}

model audit_auth_events {
  id          String   @id
  tenant_id   String
  user_id     String?
  event_type  String
  event_json  Json
  occurred_at DateTime @default(now())
}

2.Prisma再生成
npx prisma generate

STEP 5️⃣ Seed更新（権限追加）

対象ファイル：/prisma/seed.ts:Claude要レビュー。現状のseedの記述方式を正とする。

await prisma.permissions.create({
  data: {
    id: crypto.randomUUID(),
    permission_key: 'manage_auth_policy',
    resource: 'tenant_settings',
    action: 'update',
    description: 'テナント認証ポリシー管理',
  },
});

await prisma.role_permissions.create({
  data: {
    role_id: tenantAdminRoleId,
    permission_id: (await prisma.permissions.findFirst({
      where: { permission_key: 'manage_auth_policy' },
    }))!.id,
  },
});

STEP 6️⃣ マイグレーション適用と検証
npx supabase db reset

確認項目：

新2テーブル作成済み
・tenant_settings に auth_policy_json
・user_profiles に passkey_enabled
・RLS SELECT / INSERT 正常動作

STEP 7️⃣ ドキュメント更新
更新対象：
| ファイル                                                | 更新内容                                       |
| --------------------------------------------------- | ------------------------------------------ |
| `05_harmonet-technical-stack-definition_v3.6.md`    | 認証方式統合（MagicLink + Passkey）・AuthPolicy構成反映 |
| `05_HarmoNet_Phase9_DB_Construction_Report_v1.1.md` | 新スキーマ・RLS・Seed追加を反映しChangeLog更新            |

✅ 納品成果物一覧
| 区分       | ファイル名                                             | 配置先                           |
| -------- | ------------------------------------------------- | ----------------------------- |
| マイグレーション | 20251107000002_auth_policy_extension.sql          | `/supabase/migrations/`       |
| RLSポリシー  | 20251107000003_enable_rls_auth_extension.sql      | `/supabase/migrations/`       |
| Prisma更新 | schema.prisma                                     | `/prisma/`                    |
| Seed更新   | seed.ts                                           | `/prisma/`                    |
| 技術定義書    | 05_harmonet-technical-stack-definition_v3.6.md    | `/01_docs/05_implementation/` |
| DB構築報告書  | 05_HarmoNet_Phase9_DB_Construction_Report_v1.1.md | `/01_docs/05_implementation/` |

🔄 承認フロー
| ステップ | 担当        | 内容                         |
| ---- | --------- | -------------------------- |
| 実装   | Claude    | SQL / Prisma / Seed 実施     |
| 検証   | TKD       | Supabase Studio / Prisma確認 |
| 監査   | Gemini    | BAG-lite監査（RLS・構造整合）       |
| 承認   | Tachikoma | 全体整合確認・文書承認                |

Status: Ready for Execution
Next Action: Claudeが実行を開始し、TKDが順次確認。