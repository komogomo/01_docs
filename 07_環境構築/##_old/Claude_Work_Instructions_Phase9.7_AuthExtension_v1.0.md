# Claude 実行指示書（Phase9.7 認証拡張実装）

**プロジェクト:** HarmoNet（マルチテナント型コミュニティOS）  
**フェーズ:** Phase9.7 – 認証方式拡張対応  
**対象環境:** Supabase（Docker Desktop / PostgreSQL 15.6 / RLS有効）  
**担当:** Claude（実装）＋ TKD（承認）  
**監督:** タチコマ（PMO / Architect）  
**作業日:** 2025-11-07  
**Document ID:** HNM-AUTH-EXT-INSTR-20251107  
**Version:** 1.0  

---

## 🎯 目的

Magic Link + Passkey 認証方式の統合、およびテナント単位での Magic Link 有効時間／使用回数制御を導入する。  
既存Phase9 DB環境（RLS・Prisma構成済）をベースに、DB拡張・RLSポリシー・シード更新を安全に実施する。

---

## 🧩 現在のDB状態（Phase9.6 / 2025-11-06 時点）

- **スキーマ構成:** 31テーブル  
- **ENUM型:** 11種  
- **RLSポリシー:** 104件（全テーブル適用済）  
- **認証構成:** Magic Link（GoTrue標準）＋ Passkey未実装  
- **Prisma schema.prisma:** v1.7  
- **マイグレーション履歴:**  
  - `20251107000000_initial_schema.sql`（初期スキーマ）  
  - `20251107000001_enable_rls_policies.sql`（RLS全適用）  
- **Seed投入:** 管理者・テナント・ユーザー3種（tkd alias済）  
- **構築報告:** `/01_docs/05_implementation/HarmoNet_Phase9_DB_Construction_Report_v1.0.md`  

---

## 🧭 作業概要

### ✅ 目的
1. Passkey（WebAuthn/FIDO2）を標準認証方式として追加。  
2. Magic Link（メール認証）をフォールバック方式として維持。  
3. テナント単位で Magic Link の有効時間・回数を制御できるようにする。  
4. 各認証イベントを監査可能にし、ログを残す仕組みを導入する。  

### ✅ 作業成果
- スキーマ拡張（+2テーブル／+2列）  
- 新RLSポリシー（+8件）  
- Prisma再生成  
- Seed更新（新権限追加）  
- DB構築報告書更新（v1.1）  

---

## ⚙️ 作業手順（Claude実行手順）

### STEP 1️⃣ 対象ドキュメントの参照・読込

Claudeは以下のファイルをナレッジに読み込むこと。

| 区分 | ファイル | 用途 |
|------|-----------|------|
| 技術定義 | `/01_docs/05_implementation/harmonet-technical-stack-definition_v3.5.md` | 現行技術構成基準 |
| DB報告 | `/01_docs/05_implementation/HarmoNet_Phase9_DB_Construction_Report_v1.0.md` | 現行DBスキーマとRLS構成 |
| マイグレーション | `/01_docs/05_implementation/20251107000000_initial_schema.sql` | 現行テーブル定義 |
| RLS定義 | `/01_docs/05_implementation/20251107000001_enable_rls_policies.sql` | 現行ポリシー構成 |
| 実装合意 | `/01_docs/00_project/harmonet-phase9-implementation-agreement_v1.0.md` | Phase9運用方針 |
| 技術ガイド | `/01_docs/00_project/ai-driven-development-guide_v1.0.md` | AI駆動実装ガイド |

---

### STEP 2️⃣ 新規マイグレーションSQL作成

ファイル名：  
`/supabase/migrations/20251107000002_auth_policy_extension.sql`

内容（DDL全体）：

```sql
-- =============================
-- Auth Policy Extension Migration
-- =============================

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

-- 新規テーブル: magic_link_usage_logs
CREATE TABLE magic_link_usage_logs (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  token_id TEXT NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 新規テーブル: audit_auth_events
CREATE TABLE audit_auth_events (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT,
  event_type TEXT NOT NULL,
  event_json JSONB NOT NULL,
  occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

STEP 3️⃣ RLSポリシーの追加

対象ファイル：
/supabase/migrations/20251107000003_enable_rls_auth_extension.sql

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

1.schema.prisma に以下を追加：

model tenant_settings {
  id               String   @id
  tenant_id        String
  auth_policy_json Json     @default("{}")
  // 既存フィールド省略
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

STEP 6️⃣ DBリセット＋マイグレーション適用

npx supabase db reset

実行後、以下を確認：

新規2テーブルが作成されている
・tenant_settings に auth_policy_json が存在
・user_profiles に passkey_enabled が存在
・Prisma Clientが再生成済み
・RLSポリシー（SELECT/INSERT）が正しく適用済み

STEP 7️⃣ ドキュメント更新

Claudeは以下の2ドキュメントを更新すること：
ファイル

| ファイル                                                                        | 更新目的                      |
| --------------------------------------------------------------------------- | ------------------------- |
| `/01_docs/05_implementation/harmonet-technical-stack-definition_v3.6.md`    | Passkey + MagicLink統合仕様反映 |
| `/01_docs/05_implementation/HarmoNet_Phase9_DB_Construction_Report_v1.1.md` | 新スキーマ・RLS・Seed反映／認証拡張追記   |

STEP 8️⃣ 検証・承認

Supabase Studioで2テーブル確認
・Prisma Studioで tenant_settings.auth_policy_json 確認
・MagicLink生成・使用テスト（トークン確認・使用回数制限）
・TKDが動作検証後、承認コメントを記録

📘 納品成果物一覧

| 区分       | ファイル名                                          | 格納場所                          |
| -------- | ---------------------------------------------- | ----------------------------- |
| マイグレーション | 20251107000002_auth_policy_extension.sql       | `/supabase/migrations/`       |
| RLSポリシー  | 20251107000003_enable_rls_auth_extension.sql   | `/supabase/migrations/`       |
| Prisma更新 | schema.prisma                                  | `/prisma/`                    |
| Seed更新   | seed.ts                                        | `/prisma/`                    |
| 技術定義書    | harmonet-technical-stack-definition_v3.6.md    | `/01_docs/05_implementation/` |
| DB構築報告書  | HarmoNet_Phase9_DB_Construction_Report_v1.1.md | `/01_docs/05_implementation/` |

✅ 承認フロー
| ステップ    | 担当     | 内容                    |
| ------- | ------ | --------------------- |
| 実装・DB構築 | Claude | SQL / Prisma / Seed実施 |
| 動作確認    | TKD    | Studio／Prismaで検証      |
| 監査      | Gemini | RLS・構造監査（BAG-lite）    |
| 統合承認    | タチコマ   | ドキュメント整合確認・最終承認       |

Status: Ready for Execution
Action: Claude → 実行開始後、TKDが進捗を確認・承認する。