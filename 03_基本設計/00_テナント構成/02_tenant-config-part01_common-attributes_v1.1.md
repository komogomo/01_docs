a---
section_id: 01
section_name: 共通属性定義・拡張インターフェース
source_file: harmonet-tenant-config-schema_v1.0.md
version: 1.1
phase: 4 (整合スキーマ化)
reviewer: Claude
---

# 1. 共通属性定義・拡張インターフェース（v1.1）

## 1.1 共通メタ属性
```yaml
tenant_common:
  tenant_id:
    type: string
    description: テナントを一意に識別するID
    format: uuid
    required: true

  created_by:
    type: string
    description: レコード作成者のユーザーID
    format: uuid
    required: true
    reference: users.id

  updated_by:
    type: string
    description: レコード最終更新者のユーザーID
    format: uuid
    required: true
    reference: users.id

  created_at:
    type: datetime
    description: レコード作成日時（ISO8601）
    default: now()

  updated_at:
    type: datetime
    description: レコード更新日時（ISO8601）
    default: now()

  is_deleted:
    type: boolean
    description: 論理削除フラグ
    default: false

  deleted_at:
    type: datetime
    description: 削除日時
    nullable: true

  deleted_by:
    type: string
    description: 削除実行者のユーザーID
    format: uuid
    nullable: true

  status:
    type: string
    enum: [active, inactive, archived]
    description: データの有効状態

  display_order:
    type: integer
    description: 表示順序（昇順）
    nullable: true

1.2 システム共通フィールド
system_common:
  application_scope:
    description: フィールドの適用スコープ
    levels:
      - tenant_level:
          description: テナント全体設定
          entities: [tenants, tenant_settings]
      - user_level:
          description: ユーザー個別設定
          entities: [users, user_preferences]
      - post_level:
          description: 投稿単位設定（翻訳用）
          entities: [posts, comments]

  language:
    type: string
    enum: [ja, en, zh]
    scope: [tenant_level, user_level, post_level]
    description: |
      tenant_level: テナントデフォルト言語
      user_level: ユーザー表示言語
      post_level: 投稿言語識別
    default: ja

  timezone:
    type: string
    scope: [tenant_level, user_level]
    description: |
      tenant_level: テナントデフォルトタイムゾーン
      user_level: ユーザー個別タイムゾーン
    default: Asia/Tokyo

  theme_mode:
    type: string
    enum: [light, dark, auto]
    scope: [tenant_level, user_level]
    default: auto

  currency:
    type: string
    scope: [tenant_level]
    description: テナント全体の通貨単位（将来の有料機能用）
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
      cache_enabled:
        type: boolean
        default: true
      cache_ttl:
        type: integer
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

  tts_api:
    type: object
    description: 音声読み上げエンジン設定
    properties:
      enabled:
        type: boolean
        default: true
      provider:
        type: string
        enum: [voicevox, google_tts, openai_tts]
        default: voicevox
      voice_settings:
        type: object
        properties:
          ja:
            engine: voicevox
            voice: zundamon
          en:
            engine: google_tts
            voice: en-US-Neural2-A
          zh:
            engine: google_tts
            voice: zh-CN-Wavenet-A
      cache_enabled:
        type: boolean
        default: true
      cache_ttl:
        type: integer
        description: キャッシュ保持時間（秒）
        default: 2592000  # 30日

  notification_api:
    type: object
    description: 通知エンジン設定
    properties:
      email_enabled:
        type: boolean
        default: true
      email_provider:
        type: string
        enum: [sendgrid, ses, smtp]
        default: sendgrid
      app_notification_enabled:
        type: boolean
        default: true
      push_notification_enabled:
        type: boolean
        default: false
      push_provider:
        type: string
        enum: [fcm, apns]
        nullable: true

1.4 共通定数とバリデーションポリシー
constants:
  max_file_size_mb:
    type: integer
    default: 5
    configurable_by: tenant_admin
    range: [1, 50]

  max_files_per_post:
    type: integer
    default: 5
    configurable_by: tenant_admin
    range: [1, 20]

  supported_mime_types:
    type: array
    items:
      - application/pdf
      - image/jpeg
      - image/png
      - image/gif
      - image/webp
      - application/vnd.openxmlformats-officedocument.wordprocessingml.document
      - application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      - application/vnd.openxmlformats-officedocument.presentationml.presentation
      - application/msword
      - application/vnd.ms-excel
      - application/vnd.ms-powerpoint

  session_timeout_minutes:
    type: integer
    default: 30
    configurable_by: tenant_admin
    range: [5, 1440]

  translation_cache_ttl_days:
    type: integer
    default: 30
    configurable_by: tenant_admin
    options: [1, 7, 30]

  tts_cache_ttl_days:
    type: integer
    default: 30
    configurable_by: tenant_admin
    options: [1, 7, 30]

  login_attempt_limit:
    type: integer
    default: 3
    configurable_by: tenant_admin
    range: [1, 10]

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
    default: "v1.1"
  compatible_versions:
    type: array
    items: ["v1.0"]
  last_reviewed_by:
    type: string
    enum: [tachikoma, claude, gemini, tkd]
    default: tachikoma

<!-- Claude Review -->

Claude Review - Part 01: 共通属性定義・拡張インターフェース
（v1.0に対するレビュー全文を保持）

<!-- /Claude Review -->

Created: 2025-11-01
Last Updated: 2025-11-01
Document ID: HNM-TNT-PART01-20251101
Author: タチコマ（HarmoNet AI Architect）