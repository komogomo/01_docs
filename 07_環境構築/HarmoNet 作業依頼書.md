件名: Phase9 Migration修正 — updated_atトリガー削除対応（Gemini監査指摘対応）
発行者: タチコマ（HarmoNet PMO / Architect）
宛先: Claude（HarmoNet Design Specialist）
日付: 2025-11-04

🎯 背景

GeminiのPhase9監査レビューにて、create_initial_schema.sql に含まれる update_updated_at_column() トリガー群が、
Prismaスキーマの定義 (@default(now())) と競合していることが確認されました。

Phase9以降の設計思想では、

updated_at の更新責務は アプリケーション層（Next.js / Prisma） に一元化する。

データベース側の自動更新トリガーは廃止する。

このため、DB層のトリガーを削除し、設計思想を統一します。

🧩 Geminiレビュー指摘要約
| 項目       | 内容                                                           | 優先度    |
| -------- | ------------------------------------------------------------ | ------ |
| **不整合**  | `update_updated_at_column()` 関数＋各テーブルの BEFORE UPDATE トリガーが存在 | 🔴 重大  |
| **原因**   | Prisma側で `@updatedAt` 未指定のため、アプリ層とDB層の更新ロジックが二重化             |        |
| **推奨対応** | DB側のトリガー削除（Prisma設計を優先）                                      | ✅ 採用決定 |

🛠 修正内容（依頼事項）

新規マイグレーションスクリプトを作成してください。

ファイル名

20251105_remove_updated_at_triggers.sql

格納先

/01_docs/05_implementation/

実施内容

1.関数削除
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

2.以下テーブルの BEFORE UPDATE トリガーをすべて削除
tenants
tenant_settings
tenant_features
users
board_categories
board_posts
board_comments
announcements
facilities
facility_settings
facility_reservations

3.冒頭コメント（ヘッダ）
-- HarmoNet Migration Script
-- Phase9 修正版: updated_at トリガー削除対応 (Gemini監査結果反映)
-- Document ID: HNM-MIG-20251105-001
-- Created: 2025-11-05
-- Author: Claude (HarmoNet Design Specialist)
-- Reviewed by: Tachikoma (HarmoNet Architect)

4.文末メタ情報
Created: 2025-11-05  
Last Updated: 2025-11-05  
Version: 1.0  
Document ID: HNM-MIG-20251105-001

💡 注意事項

Prismaスキーマ（v1.0）はそのまま使用すること（変更不要）。

トリガー削除後は prisma migrate dev によりDB同期を実施予定。

Windsurf / Cursor における更新処理は updated_at = new Date() を明示設定する。

既存のRLSポリシーには影響なし。

✅ 成果物条件

SQL文書を Markdown 形式（📎 HarmoNet標準形式）で納品すること。

/01_docs/05_implementation/ への格納を想定したパス構成で記述。

Claude署名を明記のうえ、Phase9準拠の完全版として出力。

🚀 実施後フロー

Claude → 修正版SQL作成（v1.0）

タチコマ → 整合性チェック

Gemini → BAG-lite再監査

TKD → 最終承認

以上、正式依頼。
Phase9 DBスキーマの最終整合性を確保するため、優先度「高」で対応願います。

— タチコマ（HarmoNet Architect / PMO）