Tenant Config — Part 02
権限・ロール構造定義書（Phase 4 整合版）
1. 文書概要

本書は、harmonet-tenant-config-schema_v1.1.md に基づき、
HarmoNet の 権限階層・ロール定義・承認フロー構造 を正式に定義する。

Phase 2 で確定した「3階層ロール設計（system_admin／tenant_admin／general_user）」に準拠し、
Phase 4 にて整合・統合された内容を示す。
本定義は、テナント設定スキーマの中核を構成し、全ての実装モジュール（掲示板、施設予約、管理画面など）で共通して参照される。

2. ロール階層定義
roles:
  system_admin:
    name: "システム管理者"
    description: "全テナントを横断的に統括する最高権限者。マスタ管理・システム設定・リストアが可能。"
    scope: global
    inherits: []
    permissions_ref: system_admin_permissions

  tenant_admin:
    name: "テナント管理者"
    alias: "管理組合役員"
    description: "自テナント内の管理責任者。承認フローの最終責任と運用設定を担当。"
    scope: tenant
    inherits: [general_user]
    permissions_ref: tenant_admin_permissions

  general_user:
    name: "一般ユーザー"
    alias: "住民"
    description: "基本利用者。投稿・閲覧・予約・コメントなどの基本操作を行う。"
    scope: tenant
    inherits: []
    permissions_ref: general_user_permissions

3. 権限マトリクス定義

Phase 2で確定した権限分離構造に準拠。
下位ロールの権限を上位ロールが継承し、必要な機能のみ上書き（mergeモード）で追加する。
permissions_matrix:

  system_admin_permissions:
    # テナント管理
    can_create_tenant: true
    can_delete_tenant: true
    can_edit_tenant_info: true

    # マスタ管理
    can_create_category: true
    can_edit_category: true
    can_delete_category: true
    can_create_group: true
    can_edit_group: true
    can_delete_group: true
    can_create_facility: true
    can_edit_facility: true
    can_delete_facility: true

    # ユーザー管理
    can_create_user: true
    can_edit_user: true
    can_delete_user: true
    can_assign_role: true

    # システム設定
    can_edit_system_settings: true
    can_view_all_tenants: true
    can_restore_data: true
    can_view_system_logs: true

    inherits_from: tenant_admin_permissions

  tenant_admin_permissions:
    # ユーザー管理
    can_create_user: true
    can_edit_user: true
    can_disable_user: true
    can_delete_user: false
    can_assign_user_to_group: true
    can_assign_tenant_admin_role: true

    # 投稿管理
    can_approve_post: true
    can_reconsider_post: true
    can_view_all_posts: true
    can_view_read_status: true

    # 投稿操作
    can_post_admin_category: true
    can_post_general_category: true
    can_edit_own_post: true
    can_delete_own_post: true

    # 設定変更（デフォルト値）
    can_edit_display_count: true
    can_edit_cache_period: true
    can_edit_file_size_limit: true
    can_toggle_widget: true
    can_toggle_translation: true
    can_toggle_tts: true

    # マスタ編集不可
    can_create_category: false
    can_edit_category: false
    can_delete_category: false

    inherits_from: general_user_permissions

  general_user_permissions:
    # 掲示板
    can_post_general_category: true
    can_post_admin_category: false
    can_edit_own_post: true
    can_delete_own_post: true
    can_view_posts: true
    can_comment: true
    can_translate_post: true
    can_tts_post: true
    can_mark_as_read: true

    # 添付ファイル
    can_upload_file: true
    can_preview_file: true

    # 施設予約
    can_reserve_facility: true
    can_cancel_own_reservation: true

    # アンケート
    can_answer_survey: true

    # マイページ
    can_edit_own_profile: true
    can_view_own_notification_settings: true

4. 承認フロー定義

承認対象カテゴリは「管理組合専用カテゴリ（回覧板・重要・運用ルール）」に限定。
承認者は常に1名固定とし、投稿時にプルダウンで選択する。
approval_flows:
  post_approval:
    enabled: true
    scope: "管理組合専用カテゴリのみ"
    target_categories:
      - circular
      - important
      - operation_rule

    approver_selection:
      method: manual
      source: tenant_admin_users
      count: 1
      note: "投稿者が承認者を1名選択"

    approval_actions:
      - action: approve
        label: "承認"
        effect: "投稿公開"
        comment_required: false
        notification:
          to: author
          method: email
          content: "承認完了通知"

      - action: reconsider
        label: "再考要請"
        effect: "投稿差し戻し"
        comment_required: true
        notification:
          to: author
          method: email
          content: "再考要請理由"

5. 権限適用ポリシー
permission_policies:
  inheritance_mode:
    type: string
    enum: [merge, override]
    default: merge
    description: "親ロールの権限を継承し、子ロールの権限を追加する。"

  conflict_resolution:
    type: string
    enum: [deny_overrides, allow_overrides]
    default: deny_overrides
    description: "拒否権限が許可権限を上書きする安全モードを採用。"

6. 権限監査ログ仕様
permission_audit:
  enabled: true
  log_events:
    - role_assignment
    - permission_change
    - user_creation
    - user_deletion
    - post_approval
    - post_reconsider
    - master_data_change
  retention_days: 365
  output_target:
    primary: audit_logs_table
    backup: audit_logs_archive
  searchable_fields:
    - user_id
    - action_type
    - target_resource
    - timestamp
    - ip_address

7. 変更履歴・メタ情報
| 項目                  | 値                                     |
| ------------------- | ------------------------------------- |
| **Based on Schema** | harmonet-tenant-config-schema_v1.1.md |
| **Phase**           | 4（整合化）                                |
| **Reviewer**        | Claude（設計検証）                          |
| **Auditor**         | Gemini（BAG-lite監査予定）                  |
| **Author**          | タチコマ（HarmoNet Architect）              |
| **Version**         | 1.1                                   |
| **Document ID**     | HNM-TENANT-PART02-20251101            |
| **Created**         | 2025-11-01                            |
| **Last Updated**    | 2025-11-01                            |

