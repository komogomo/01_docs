---
section_id: 02
section_name: 権限・役割構造定義
source_file: harmonet-tenant-config-schema_v1.0.md
version: 1.0
phase: 4 (整合スキーマ化)
reviewer: Claude
---

# 2. 権限・ロール構造定義

## 2.1 ロール階層
```yaml
roles:
  admin:
    description: テナント管理者（管理組合・運営担当）
    inherits: [resident]
    permissions_ref: admin_permissions

  resident:
    description: 居住者（標準利用者）
    inherits: [guest]
    permissions_ref: resident_permissions

  guest:
    description: 外部閲覧者・招待ユーザー
    inherits: []
    permissions_ref: guest_permissions

2.2 権限マトリクス
permissions_matrix:
  admin_permissions:
    can_post: true
    can_edit_any_post: true
    can_delete_any_post: true
    can_manage_users: true
    can_manage_tenant_settings: true
    can_approve_posts: true
    can_view_audit_logs: true
    can_manage_facility_booking: true
    can_manage_translation_cache: true

  resident_permissions:
    can_post: true
    can_edit_own_post: true
    can_delete_own_post: true
    can_comment: true
    can_request_translation: true
    can_reserve_facility: true
    can_view_notice_pdf: true

  guest_permissions:
    can_post: false
    can_comment: false
    can_reserve_facility: false
    can_view_notice_pdf: true
    can_request_translation: false

2.3 権限グループ
permission_groups:
  posting:
    description: 掲示板・お知らせ投稿に関する操作
    permissions: [can_post, can_edit_any_post, can_edit_own_post, can_delete_own_post]
  translation:
    description: 翻訳機能に関する操作
    permissions: [can_request_translation, can_manage_translation_cache]
  facility:
    description: 施設予約に関する操作
    permissions: [can_reserve_facility, can_manage_facility_booking]
  system_admin:
    description: テナント管理機能全般
    permissions: [can_manage_users, can_manage_tenant_settings, can_view_audit_logs]

2.4 動的権限拡張（拡張ロール）
role_extensions:
  custom_roles_enabled:
    type: boolean
    default: false
    description: テナント管理者が独自ロールを追加できるかどうか

  custom_role_schema:
    type: object
    nullable: true
    description: 独自ロール構成（custom_roles_enabled=trueの場合）
    properties:
      name:
        type: string
      inherits:
        type: array
        items: [admin, resident, guest]
      permissions:
        type: array
        items: [posting, translation, facility, system_admin]

2.5 承認フロー定義
approval_flows:
  post_submission:
    enabled: true
    approver_roles: [admin]
    description: 掲示板投稿の承認フロー
  facility_booking:
    enabled: false
    approver_roles: []
    description: 施設予約の承認は不要（即時確定）

2.6 権限適用ポリシー
permission_policies:
  inheritance_mode:
    type: string
    enum: [merge, override]
    default: merge
    description: ロール継承時の権限適用モード

  conflict_resolution:
    type: string
    enum: [deny_overrides, allow_overrides]
    default: deny_overrides
    description: 権限衝突時の解決ポリシー

2.7 権限監査ログ仕様
permission_audit:
  enabled: true
  log_events:
    - role_assignment
    - permission_change
    - custom_role_creation
  retention_days: 365
  output_target: audit_logs

<!-- Claude Review -->

Claude Review - Part 02: 権限・ロール構造定義
（命名・継承構造・承認フローの整合性を重点的に確認）

<!-- /Claude Review -->

Created: 2025-11-01
Last Updated: 2025-11-01
Document ID: HNM-TNT-PART02-20251101
Author: タチコマ（HarmoNet AI Architect）