# HarmoNet Phase5 Step5-3〜5-4 指示書
## タスク概要
以下のファイルを参照し、HarmoNetの**ER図およびテーブル定義書**を作成すること。

- ER定義書: `/01_docs/05_implementation/03_harmonet-er-entity-definition_v1.2.yaml`
- Prismaスキーマ: `/01_docs/05_implementation/04_harmonet-prisma-schema_v1.0.prisma`

## 出力ファイル
- ER図: `/01_docs/05_implementation/05_harmonet-er-diagram_v1.0.png`
- テーブル定義書: `/01_docs/05_implementation/05_harmonet-db-table-definition_v1.0.md`

---

## 出力要件

### 🎨 ER図 (Step5-3)
- 形式: PNG（Mermaid ERまたはPlantUML等で生成）
- 内容: 各エンティティ間のリレーション（1:N, N:M）を明示
- 各ノード（テーブル）に主キーを含める
- `tenant_id` の共通構造を強調（Multi-Tenant構成であることを視覚的に示す）
- `translation_cache` と `tts_cache` を「キャッシュ層」グループにまとめて表示
- `facility_settings` と `facilities` を「施設予約モジュール」としてグループ化
- 出力例タイトル：「HarmoNet ER Diagram (Phase5 - v1.2 / Prisma v1.0 準拠)」

---

### 🧱 テーブル定義書 (Step5-4)
**対象:** すべてのモデル（ER v1.2 + Prisma v1.0）  
**フォーマット:**

テーブル名: tenants
カラム名	型	Not Null	デフォルト	説明
id	uuid	✔	gen_random_uuid()	主キー
tenant_code	text	✔		テナントコード
...	...	...	...	...
制約: PRIMARY KEY(id), UNIQUE(tenant_code)				
備考: RLS有効化対象


**追加ルール**
- translation_cache / tts_cache は保持期間30日を明記
- facility_settings に料金単位(fee_unit)・期間制約(reservable_until_months)を明記
- audit_logs / moderation_logs に用途補足コメントを付与
- ENUMはPhase9準拠の簡略化方針（Status, ReactionType, DecisionType のみ）

---

## 出力仕様
- Markdown完全版1枚構成（05_harmonet-db-table-definition_v1.0.md）
- 併せてER図ファイルを生成（05_harmonet-er-diagram_v1.0.png）
- ファイル末尾に `ChangeLog` セクションを必ず記載すること

---

## ChangeLog

v1.0 (2025-11-04)

ER図およびテーブル定義書 初版

ER定義 v1.2 + Prisma v1.0 に基づく

Phase5 Step5-3〜5-4 完了成果物