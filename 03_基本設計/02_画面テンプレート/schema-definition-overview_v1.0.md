# HarmoNet Schema Definition Overview v1.0
HarmoNetプロジェクトにおけるスキーマ設計の基本方針・構造規範を定義する。

---

## 🎯 目的
HarmoNetのスキーマは、  
**「マルチテナント環境における柔軟な拡張性」と「AI支援による自動整合性維持」**  
を両立させることを目的とする。

本書では、データモデル設計における哲学・原則・命名規則・関連ドキュメントを体系化する。

---

## 🧭 設計思想（Design Philosophy）

1. **Schema as Source of Truth（スキーマが唯一の真実）**  
   すべての実装（DB・API・画面構成）はスキーマを基点として生成される。  
   仕様変更はスキーマ上で先に定義し、アプリケーションがそれに追従する。

2. **Tenant-Oriented Design（テナント主導設計）**  
   テナント固有設定をスキーマの中核に据え、  
   共通テーブルと個別テーブルの階層分離によってマルチテナントを実現する。

3. **Loose Coupling / High Cohesion（疎結合・高凝集）**  
   機能モジュール間の依存を最小化し、  
   テーブル単位で責務が完結するよう設計する。

4. **Scalable Evolution（拡張容易性）**  
   テナント単位・機能単位のスキーマ拡張が容易に行えるよう、  
   「拡張スキーマ（_ext）」や「JSON構造」など柔軟な構造を許容する。

---

## 🧩 スキーマ構造レイヤー定義

| レイヤー | 名称 | 概要 |
|-----------|------|------|
| L0 | **system_base** | システム共通テーブル（ユーザー、ロール、権限など） |
| L1 | **tenant_core** | テナント管理の中核（tenant, tenant_config, tenant_member など） |
| L2 | **feature_layer** | 機能別テーブル（掲示板、施設予約、アンケートなど） |
| L3 | **extension_layer** | 拡張・カスタム用途（_ext テーブル、履歴、統計など） |
| L4 | **log_audit_layer** | 監査・操作ログなど非機能領域 |

---

## 🗂️ スキーマ命名規則

| 対象 | 命名ルール | 例 |
|------|-------------|----|
| テーブル名 | `tenant_<module>_<entity>` | `tenant_board_post`, `tenant_facility_booking` |
| 主キー | `id`（全テーブル共通） | `id` |
| 外部キー | `<参照テーブル名>_id` | `tenant_id`, `post_id` |
| タイムスタンプ | `created_at`, `updated_at`, `deleted_at` | 一律 |
| 状態フラグ | `is_active`, `is_deleted`, `is_public` | 一律 |
| テナント識別 | `tenant_id` | すべてのL1〜L3層テーブルに必須 |

---

## 🧠 テナント設定スキーマの原則

1. **設定をデータ化する（Config as Data）**  
   テナント設定（承認フロー・翻訳・容量・通知など）はコードに埋め込まず、  
   すべてDBで定義・制御する。

2. **設定項目は「3軸」で定義**  

軸1: 性質（構造設定／制御設定／UI設定／連携設定）
軸2: 階層（グローバル／機能別／画面別／ユーザー別）
軸3: 頻度（init／low／mid／high）

→ ClaudeがPhase 2で自動分類、Geminiが解析可能なYAML形式で保持。

3. **設定スキーマはモジュール分割**  
- `tenant_common_config`
- `tenant_board_config`
- `tenant_facility_config`
- `tenant_survey_config`
- `tenant_admin_config`

---

## ⚙️ スキーマ管理サイクル

TKD（要件入力）
↓
Claude（構造化・スキーマ案生成）
↓
タチコマ（整合レビュー・命名統一）
↓
Gemini（BAG-lite解析・構造監査）
↓
タチコマ（最終統合・Prisma生成）


出力成果物:
- `harmonet-tenant-config-schema_v1.0.md`（設計書）
- `prisma-schema_latest.prisma`（実装定義）
- `bag-pre-impl-report.yaml`（Gemini監査）

---

## 🔒 正規化方針
- 第3正規形（3NF）を原則とする。
- JSONB列を用いる場合は、構造拡張のみに限定。
- ENUM値は別途`enum_definitions` テーブルで定義し、AIによる検証を許可。

---

## 🧾 スキーマ間リレーション設計
- ER設計は機能単位で完結するように構築。
- テナント単位でのDELETE／CASCADE操作は**論理削除**で処理。
- 関連付けの方向は「親→子」を原則とし、双方向依存を禁止。

---

## 🧩 スキーマのAI連携形式（Claude / Gemini連携用）
YAMLブロックを用い、各エンティティをAIが解釈可能な形式で定義する。

例：
```yaml
entity: tenant_board_config
description: 掲示板機能のテナント設定
attributes:
  - name: allow_pdf_attachment
    type: boolean
    default: true
    description: PDF添付の可否
  - name: approval_required
    type: boolean
    default: false
    description: 投稿承認フローの有無
  - name: category_structure
    type: string
    enum: ["flat", "hierarchical"]
    default: "flat"
relations:
  - tenant_id -> tenant_core.tenant.id

Prisma連携ルール

PrismaスキーマはこのYAML構造を基に自動生成される。

Prismaファイルの管理方針：

/05_implementation/prisma-schema_latest.prisma（最新版）

/99_archive/implementation/prisma-schema_vX.X.prisma（旧版）

Prisma出力はClaude提案 + タチコマ統合 + Gemini監査後に確定。

📋 参照ドキュメント

/03_tenant/harmonet-tenant-config-schema_v1.0.md

/06_audit/bag-pre-impl-report.yaml

/05_implementation/harmonet-technical-stack-definition_v3.2.md

/00_project/harmonet-document-policy_latest.md

🧾 ChangeLog
Date	Version	Summary	Author
2025-11-01	1.0	初版作成（スキーマ設計原則定義）	タチコマ

Document ID: HNM-SCHEMA-OVERVIEW-20251101
Version: 1.0
Created: 2025-11-01
Author: タチコマ（HarmoNet AI Architect）