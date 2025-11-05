1. 共通メタ属性定義
meta_attributes:
  tenant_id:
    type: uuid
    description: "テナント固有のUUID。全データの主キー参照に使用"
  
  created_at:
    type: datetime
    default: "auto_now"
    description: "レコード作成日時"
  
  updated_at:
    type: datetime
    default: "auto_now"
    description: "レコード更新日時"
  
  status:
    type: string
    enum: [active, inactive, archived]
    default: active
    description: "データ状態（論理削除やアーカイブ管理に利用）"

2. ロール階層定義
roles:
  system_admin:
    name: "システム管理者"
    name_en: "System Administrator"
    description: "全テナント横断の最高管理権限。マスタ変更・システム設定・リストアを実行可能"
    scope: global
    inherits: []
    permissions_ref: system_admin_permissions

  tenant_admin:
    name: "テナント管理者"
    name_en: "Tenant Administrator"
    alias: "管理組合役員"
    description: "自テナント内の管理者。承認・設定変更・ユーザー管理を担当"
    scope: tenant
    inherits: [general_user]
    permissions_ref: tenant_admin_permissions

  general_user:
    name: "一般ユーザー"
    name_en: "General User"
    alias: "住民"
    description: "基本利用者。投稿・閲覧・予約・コメント等を実施"
    scope: tenant
    inherits: []
    permissions_ref: general_user_permissions

3. 権限マトリクス定義
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

    # 設定変更
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
      note: "投稿時にプルダウンで1名選択"

    approval_actions:
      - action: approve
        label: "承認"
        effect: "投稿を公開"
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

5. 権限適用ポリシー定義
permission_policies:
  inheritance_mode:
    type: string
    enum: [merge, override]
    default: merge
    description: "親ロールの権限を継承し、子ロールで追加定義可能"

  conflict_resolution:
    type: string
    enum: [deny_overrides, allow_overrides]
    default: deny_overrides
    description: "拒否権限が優先される安全モード"

6. 監査ログ定義
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

7. メタ情報
| 項目               | 値                           |
| ---------------- | --------------------------- |
| **Version**      | 1.1                         |
| **Document ID**  | HNM-TENANT-CONFIG-20251101  |
| **Created**      | 2025-11-01                  |
| **Last Updated** | 2025-11-01                  |
| **Author**       | タチコマ（HarmoNet AI Architect） |
| **Status**       | Phase 4 整合版（Claudeレビュー反映済）  |

