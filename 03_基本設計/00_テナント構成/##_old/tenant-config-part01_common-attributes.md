a---
section_id: 01
section_name: 共通属性定義・拡張インターフェース
source_file: harmonet-tenant-config-schema_v1.0.md
version: 1.0
phase: 4 (整合スキーマ化)
reviewer: Claude
---

# 1. 共通属性定義・拡張インターフェース

## 1.1 共通メタ属性
```yaml
tenant_common:
  tenant_id:
    type: string
    description: テナントを一意に識別するID
    format: uuid
    required: true
  created_at:
    type: datetime
    description: レコード作成日時（ISO8601）
    default: now()
  updated_at:
    type: datetime
    description: レコード更新日時（ISO8601）
    default: now()
  status:
    type: string
    enum: [active, inactive, archived]
    description: データの有効状態

1.2 システム共通フィールド
system_common:
  language:
    type: string
    enum: [ja, en, zh]
    description: 表示言語コード（UI切替用）
    default: ja
  timezone:
    type: string
    description: タイムゾーン識別子（IANA形式）
    default: Asia/Tokyo
  theme_mode:
    type: string
    enum: [light, dark, auto]
    description: 表示テーマモード
    default: auto
  currency:
    type: string
    description: 通貨コード（ISO4217）
    default: JPY

1.3 拡張インターフェース定義
extension_interface:
  translation_api:
    type: object
    description: 翻訳エンジン設定
    properties:
      provider:
        type: string
        enum: [deepl, google, openai]
        description: 利用翻訳プロバイダ
      cache_enabled:
        type: boolean
        description: 翻訳結果キャッシュの有効化
        default: true
      cache_ttl:
        type: integer
        description: キャッシュ保持時間（秒）
        default: 86400
  storage_api:
    type: object
    description: ファイルストレージ連携設定
    properties:
      provider:
        type: string
        enum: [s3, gcs, local]
      bucket_name:
        type: string
      base_path:
        type: string
        default: /harmonet/uploads/

1.4 共通定数とバリデーションポリシー
constants:
  max_file_size_mb:
    type: integer
    description: 添付ファイル最大サイズ（MB）
    default: 10
  supported_mime_types:
    type: array
    description: 許可MIMEタイプ一覧
    items: [application/pdf, image/jpeg, image/png]
validation_policies:
  string_length:
    min: 1
    max: 255
  id_pattern:
    regex: "^[a-zA-Z0-9_-]+$"
    description: 英数字・ハイフン・アンダースコアのみ許可

1.5 メタデータ拡張仕様
metadata_extension:
  schema_version:
    type: string
    description: スキーマ定義のバージョン識別子
    default: "v1.0"
  compatible_versions:
    type: array
    description: 後方互換対象バージョン
    items: ["v0.9"]
  last_reviewed_by:
    type: string
    description: 最終レビュー担当（AI識別名）
    default: タチコマ

<!-- Claude Review -->

（Claudeが命名規則・型整合・属性再利用パターンを指摘する箇所）

<!-- /Claude Review -->

Created: 2025-11-01
Last Updated: 2025-11-01
Document ID: HNM-TNT-PART01-20251101
Author: タチコマ（HarmoNet AI Architect）