# HarmoNet Phase5 Step5-4 指示書
## タスク概要
以下のファイルを参照し、HarmoNetの正式なデータベーステーブル定義書を生成すること。

- ER定義書: `/01_docs/05_implementation/03_harmonet-er-entity-definition_v1.2.yaml`
- Prismaスキーマ: `/01_docs/05_implementation/04_harmonet-prisma-schema_v1.0.prisma`

## 出力仕様
出力対象:  
`/01_docs/05_implementation/05_harmonet-db-table-definition_v1.0.md`

## ドキュメント構成
1. **概要**
   - Phase, Version, Document ID, Created / Last Updated
   - 使用技術: Supabase (PostgreSQL) + Prisma ORM
   - 生成元: ER定義 v1.2 ＋ Prismaスキーマ v1.0

2. **共通方針**
   - RLS(行レベルセキュリティ)前提での multi-tenant 設計
   - Prismaスキーマに基づく物理モデル
   - Enumは Prisma側簡略化方針に従う
   - updated_at はアプリ層制御（@default(now()) 運用）
   - JSON/Nullable許容設計による冗長防止
   - Supabase標準の timestamp(timezone付き) を想定

3. **テーブル定義一覧**
   各モデルを1章ずつ扱い、下記フォーマットで整理すること。

テーブル名: tenants
カラム名	型	Not Null	デフォルト	説明
id	uuid	✔	gen_random_uuid()	主キー
tenant_code	text	✔		テナントコード
...	...	...	...	...
制約: PRIMARY KEY(id), UNIQUE(tenant_code)				
備考: RLS有効化対象


4. **補足**
- 各テーブルの外部キー制約およびリレーションを一覧化
- translation_cache / tts_cache のキャッシュ保持期間を30日と明記
- facility_settings の fee_per_day / fee_unit の意味を補足
- audit_logs / moderation_logs の用途を追記

5. **ChangeLog**

v1.0 (2025-11-04)

初版: ER定義 v1.2 + Prisma v1.0 に基づく完全テーブル定義書

Phase5 Step5-4成果物


## 出力条件
- Markdown形式で1ファイル完結
- 表形式整備済（全モデル網羅）
- SupabaseでのDDL実装に転用可能な構造

