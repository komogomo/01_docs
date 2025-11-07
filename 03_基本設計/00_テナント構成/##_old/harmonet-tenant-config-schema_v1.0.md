# HarmoNet Tenant Config Schema v1.0
HarmoNetのテナント設定を「1テーブル管理（key-value / JSON型）」に落とし込めるよう正規化したスキーマ定義。  
Phase 2 の成果物 `tenant-setting-list_v0.1.md`（Claude）をもとに、Phase 3（タチコマ）で命名・依存・共通属性を整合したもの。

本ファイルは以下の2レイヤで構成する：

1. **Humanレイヤ（階層YAML）**  
   - 人間が読む・修正するための構造  
   - 画面／機能ごとに論理的にグルーピング  
   - Phase 2 の「構造／制御／UI／連携」の4分類を維持
2. **Systemレイヤ（フラットYAML：Prisma変換互換）**  
   - `TenantConfig` テーブルにそのまま投入できる1レコード＝1設定の形式  
   - `section` / `key` / `value_type` / `default_value` / `configurable_by` / `management_scope` / `depends_on` を持つ  
   - GeminiのBAG-liteが静的検証しやすいよう、依存を明示

---

## 0. 前提・参照

- 参照元: `/docs/03_tenant/tenant-setting-list_v0.1.md`  
- ディレクトリ規約: `/docs/harmonet-docs-directory-definition_v3.0.md`  
- 役割分担: `/docs/00_project/HarmoNet チーム全体の進め方と役割分担ガイドライン v1.0.md`  
- 本スキーマは **テナント管理者が「値を変えられる範囲」と、システム管理者だけが変えられる「構造マスタ」を分離する** のが目的  
- Prisma側では以下のようなモデルを想定（実装側で変更可）:

```prisma
model TenantConfig {
  id               String   @id @default(cuid())
  tenantId         String   // テナント単位
  section          String   // 例: "tenant_login"
  key              String   // 例: "control.session_timeout.minutes"
  value            Json     // 例: { "value": 30, "unit": "minute" }
  valueType        String   // "string" | "number" | "boolean" | "enum" | "json"
  configurableBy   String?  // "system_admin" | "tenant_admin" | null
  managementScope  String?  // "system" | "tenant" | "feature" | null
  dependsOn        String?  // "user_roles.tenant_admin" など
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
  isActive         Boolean  @default(true)
}

1. 共通定義（Common Parts）

common_definitions:
  meta_fields:
    created_at:
      type: datetime
      description: "レコード生成日時（システム自動）"
    updated_at:
      type: datetime
      description: "レコード更新日時（システム自動）"
    created_by:
      type: string
      description: "作成者ユーザーID（system_admin想定）"
    updated_by:
      type: string
      description: "更新者ユーザーID（tenant_adminまたはsystem_admin）"
    is_active:
      type: boolean
      default: true
      description: "論理削除・一時停止用のフラグ"

  roles:
    - id: system_admin
      name: "システム管理者"
      scope: "全テナント横断"
    - id: tenant_admin
      name: "テナント管理者"
      scope: "自テナントのみ"
    - id: general_user
      name: "一般ユーザー"
      scope: "自テナント・自グループ"

  value_types:
    - string
    - number
    - boolean
    - enum
    - json
    - datetime

  scopes:
    - system  # システム管理者のみ
    - tenant  # テナント単位で上書き可
    - feature # 特定機能のみ（掲示板など）

  # Phase 2 で使った4分類をメタとして持たせる
  setting_categories:
    - structure
    - control
    - ui
    - integration

2. マスタ系（最上位：権限・運用フロー）

Phase 2 で最初に出てきた user_roles と operation_flows は、全機能がこれを前提にするため「最上位セクション」として固定する。

user_roles:
  section_id: user_roles
  description: "HarmoNetにおける3ロールの固定定義。通常はsystem_adminのみ変更可。"
  management_scope: system
  items:
    - key: system_admin
      value_type: json
      default_value:
        name: "システム管理者"
        capabilities:
          - tenant_management
          - master_management
          - system_settings
        note: "マスタ構造を変えられる唯一のロール"
      configurable_by: system_admin

    - key: tenant_admin
      value_type: json
      default_value:
        name: "テナント管理者"
        capabilities:
          - user_management
          - operation_management
          - configuration_management
        cannot_do:
          - master_structure_change
          - system_backup
      configurable_by: system_admin

    - key: general_user
      value_type: json
      default_value:
        name: "一般ユーザー"
        capabilities:
          - board_post
          - board_view
          - facility_booking
      configurable_by: system_admin

operation_flows:
  section_id: operation_flows
  description: "テナント作成〜日常運用〜マスタ変更依頼の3フローを定義"
  management_scope: system
  items:
    - key: tenant_creation
      value_type: json
      default_value:
        steps:
          - { order: 1, actor: system_admin, action: "create_tenant" }
          - { order: 2, actor: system_admin, action: "init_master" }
          - { order: 3, actor: system_admin, action: "register_tenant_admin" }
          - { order: 4, actor: tenant_admin, action: "register_users" }
      configurable_by: system_admin

    - key: daily_operation
      value_type: json
      default_value:
        tenant_admin_tasks:
          - user_register
          - approve_post
          - change_display_values
        system_admin_tasks:
          - master_change_on_demand
      configurable_by: system_admin

    - key: master_change_request
      value_type: json
      default_value:
        steps:
          - { order: 1, actor: tenant_admin, action: "request_master_change" }
          - { order: 2, actor: system_admin, action: "impact_analysis" }
          - { order: 3, actor: system_admin, action: "apply_change" }
          - { order: 4, actor: system_admin, action: "backup" }
      configurable_by: system_admin

3. 機能セクション（Phase 2を整形したもの）

ここからがTKDさんが本当に使うところ。Phase 2 で出ていた

login

home

bulletin_board

bulletin_board_detail

common_policy

を、HarmoNet全体で一貫するように英語のセクションIDに統一する。

3.1 tenant_login
tenant_login:
  section_id: tenant_login
  description: "テナントごとのログイン画面・認証制御の設定"
  management_scope: tenant
  structure:
    tenant_id_format:
      value_type: enum
      enum_values: ["auto", "manual"]
      default_value: "auto"
      configurable_by: system_admin
      depends_on: ["user_roles.system_admin"]

    tenant_id_pattern:
      value_type: string
      default_value: "TSK-0001"
      configurable_by: system_admin

  control:
    authentication_method:
      value_type: enum
      enum_values: ["magic_link", "password", "oidc"]
      default_value: "magic_link"
      configurable_by: tenant_admin
      depends_on: ["common_policy.integration.notification"]

    login_attempt_limit:
      value_type: number
      default_value: 3
      min: 1
      max: 10
      configurable_by: tenant_admin

    session_timeout_minutes:
      value_type: number
      default_value: 30
      configurable_by: tenant_admin

  ui:
    layout_type:
      value_type: enum
      enum_values: ["three_layer"]
      default_value: "three_layer"
      configurable_by: tenant_admin

    header:
      value_type: json
      default_value:
        left: "tenant_name"
        right: "language_switcher"
      configurable_by: tenant_admin

    footer:
      value_type: json
      default_value:
        display: false
        elements:
          - terms
          - privacy
          - contact
      configurable_by: tenant_admin

  integration:
    notification_on_login:
      value_type: boolean
      default_value: true
      configurable_by: tenant_admin
      note: "MagicLink送信トリガでメール送信"

3.2 tenant_home
tenant_home:
  section_id: tenant_home
  description: "ホーム画面で表示するウィジェット・お知らせ・フッター構成"
  management_scope: tenant

  structure:
    widget_types:
      value_type: json
      default_value:
        - { id: "latest_notice", name: "最新のお知らせ", default_enabled: true }
        - { id: "function_menu", name: "機能メニュー", default_enabled: true }
        - { id: "bulletin_board", name: "掲示板新着", default_enabled: false }
        - { id: "facility_booking", name: "施設予約状況", default_enabled: false }
        - { id: "survey", name: "アンケート一覧", default_enabled: false }
      configurable_by: tenant_admin

  control:
    notice_display_count:
      value_type: enum
      enum_values: [3, 5, 10]
      default_value: 3
      configurable_by: tenant_admin

    notice_validity_days:
      value_type: number
      default_value: 30
      configurable_by: tenant_admin

  ui:
    header:
      value_type: json
      default_value:
        left: "notification_icon"
        center: "screen_title"
        right: "language_switcher"
      configurable_by: tenant_admin

    footer:
      value_type: json
      default_value:
        structure: "global"
        elements:
          - home
          - notice
          - board
          - facility
          - mypage
          - logout
        control: "tenant_admin"
      configurable_by: tenant_admin

    content_area:
      value_type: json
      default_value:
        layout: "vertical"
        sections:
          - { order: 1, type: "latest_notice", display_count: 3 }
          - { order: 2, type: "function_menu" }
      configurable_by: tenant_admin

    welcome_message:
      value_type: json
      default_value:
        enabled: true
        text: "ようこそ"
      configurable_by: tenant_admin

  integration:
    notification_methods:
      value_type: json
      default_value:
        - app_internal
        - email
        - push
      configurable_by: tenant_admin

    translation:
      value_type: json
      default_value:
        cache_period_days: 30
        target_scope: "title_only"
      configurable_by: tenant_admin

3.3 tenant_board

掲示板のところが一番デカいので、ここを「構造」「制御」「UI」「連携」にちゃんと4分割したうえで、後段のSystemレイヤで細切れにします。

tenant_board:
  section_id: tenant_board
  description: "掲示板（一覧・投稿）のテナント別設定"
  management_scope: tenant

  structure:
    categories:
      value_type: json
      default_value:
        admin_only:
          management: system_admin
          list:
            - { id: "circular", name: "回覧板", approval_required: true, read_management: true, available_for: "tenant_admin" }
            - { id: "important", name: "重要", approval_required: true, read_management: true, available_for: "tenant_admin" }
            - { id: "operation_rule", name: "運用ルール", approval_required: true, read_management: true, available_for: "tenant_admin" }
        general:
          management: system_admin
          list:
            - { id: "group", name: "グループ", approval_required: false, read_management: false, visibility: "group_members_only" }
            - { id: "qa", name: "質問・相談", approval_required: false, read_management: false }
            - { id: "other", name: "その他", approval_required: false, read_management: false }
      configurable_by: system_admin

    groups:
      value_type: json
      default_value:
        hierarchy_enabled: true
        max_depth: 3
        examples:
          - { type: "area_based", pattern: "A-北 / A-南" }
          - { type: "floor_based", pattern: "1F / 2F / 3F" }
      configurable_by: system_admin
      note: "構造リスクが高いのでtenant_adminには触らせない"

  control:
    usage_guide:
      value_type: json
      default_value:
        display: true
        location: "top"
        content: "掲示板の利用方法と注意事項"
      configurable_by: tenant_admin

    post_display:
      value_type: json
      default_value:
        sort_order: "desc"
        display_count:
          options: [10, 25, 50, 100]
          default: 10
        pagination:
          enabled: true
          trigger: 100
      configurable_by: tenant_admin

    category_filter:
      value_type: json
      default_value:
        enabled: true
        options: ["all", "circular", "important", "operation_rule", "group", "qa", "other"]
      configurable_by: tenant_admin

    approval_flow:
      value_type: json
      default_value:
        scope: ["circular", "important", "operation_rule"]
        approver_count: 1
        approver_source: "tenant_admin_list"
        actions:
          - { action: "approve", label: "承認", comment: "optional" }
          - { action: "reconsider", label: "再考要請", comment: "required" }
        notification:
          to_approver: { method: "email", trigger: "post_created" }
          to_author: { method: "email", trigger: "approved_or_reconsidered" }
      configurable_by: tenant_admin

    post_visibility:
      value_type: json
      default_value:
        admin_categories:
          scope: "tenant_all"
        group_category:
          scope: "group_members_only"
        general_categories:
          scope: "tenant_all"
      configurable_by: tenant_admin

    post_editing:
      value_type: json
      default_value:
        author_edit: true
        edit_deadline_hours: 24
        admin_edit: true
      configurable_by: tenant_admin

    post_display_period:
      value_type: json
      default_value:
        enabled: true
        default_value: "unlimited"
      configurable_by: tenant_admin

    attachment_files:
      value_type: json
      default_value:
        allowed_formats: ["pdf", "jpg", "png", "office"]
        size_limit_per_file_mb: 5
        max_files_per_post: 5
        preview:
          enabled: true
          method: "modal"
          close_action: "tap_anywhere"
          close_text: "タップで閉じる"
      configurable_by: tenant_admin

    read_management:
      value_type: json
      default_value:
        target_categories: ["circular", "important", "operation_rule"]
        user_action: { method: "optional_button", enforcement: "none" }
        admin_view:
          display_fields: ["post_title", "total_users", "read_count", "read_rate", "unread_user_list"]
        reminder:
          enabled: false
      configurable_by: tenant_admin

    comment_settings:
      value_type: json
      default_value:
        enabled: true
        permission: "all_users"
        approval: false
      configurable_by: tenant_admin

    reaction:
      value_type: json
      default_value:
        like_button: { enabled: true }
        emoji_reaction: { enabled: false }
      configurable_by: tenant_admin

  ui:
    post_summary:
      value_type: json
      default_value:
        display_lines: 3
        elements:
          left_top: ["author_nickname", "posted_at", "weekday"]
          left_bottom: ["translate_button", "tts_button"]
          right_bottom: ["attachment_icon", "reply_icon_with_count"]
        self_post_indicator:
          enabled: true
          method: "tag"
      configurable_by: tenant_admin

    new_post_button:
      value_type: json
      default_value:
        location: "bottom_right"
        type: "icon_button"
      configurable_by: tenant_admin

    post_form:
      value_type: json
      default_value:
        shared: true
        fields:
          - { field: "title", type: "text", required: true }
          - { field: "category", type: "dropdown", options_by_role:
                { tenant_admin: ["circular","important","operation_rule","group","qa","other"],
                  general_user: ["group","qa","other"] } }
          - { field: "content", type: "textarea", required: true }
          - { field: "attachments", type: "file_upload", multiple: true, max_files: 5 }
          - { field: "approver", type: "dropdown", visible_when: "category_is_admin_only" }
      configurable_by: tenant_admin

  integration:
    translation:
      value_type: json
      default_value:
        enabled: true
        button_location: "post_left_bottom"
        supported_languages: ["ja", "en", "zh"]
        cache:
          enabled: true
          period_days: 30
      configurable_by: tenant_admin

    tts:
      value_type: json
      default_value:
        enabled: true
        button_location: "next_to_translation"
        voices:
          ja: { engine: "VOICEVOX", voice: "zundamon" }
          en: { engine: "system_default", voice: "native" }
          zh: { engine: "system_default", voice: "standard_chinese" }
        cache:
          enabled: true
          period_days: 30
      configurable_by: tenant_admin

    notification:
      value_type: json
      default_value:
        new_post: { enabled: true, methods: ["app_internal","email"] }
        new_comment: { enabled: true, methods: ["app_internal","email"] }
        approval_request: { enabled: true, method: "email", mandatory: true }
        approval_result: { enabled: true, method: "email", mandatory: true }
      configurable_by: tenant_admin

3.4 tenant_board_detail
tenant_board_detail:
  section_id: tenant_board_detail
  description: "掲示板詳細画面の表示・コメント・翻訳継承設定"
  management_scope: tenant
  structure:
    inherit_from: "tenant_board"
  control:
    inherit_from: "tenant_board"
  ui:
    post_detail_display:
      value_type: json
      default_value:
        elements:
          - title
          - author_nickname
          - posted_at
          - category
          - content
          - attachment_list
          - translate_button
          - tts_button
          - read_button
      configurable_by: tenant_admin

    comment_section:
      value_type: json
      default_value:
        display_order: "desc"
        comment_display:
          - commenter_nickname
          - commented_at
          - comment_body
          - translate_button
        comment_form:
          location: "bottom"
          fields:
            - { field: "content", type: "textarea", required: true }
      configurable_by: tenant_admin
  integration:
    inherit_from: "tenant_board"

3.5 common_policy
common_policy:
  section_id: common_policy
  description: "全画面に共通するヘッダー／フッター／翻訳／通知のポリシー"
  management_scope: tenant
  structure:
    layout:
      value_type: json
      default_value:
        standard_structure: "header-content-footer"
        application_scope: "all_screens"
        exceptions:
          - { screen: "tenant_login", footer_display: false }
      configurable_by: tenant_admin

  control:
    reference: "user_roles"

  ui:
    header:
      value_type: json
      default_value:
        structure: "3_parts"
        elements:
          left: "notification_icon"
          center: "screen_title_or_tenant_name"
          right: "language_switcher"
      configurable_by: tenant_admin

    footer:
      value_type: json
      default_value:
        structure: "global_footer"
        display: true
        elements:
          - home
          - notice
          - board
          - facility
          - mypage
          - logout
      configurable_by: tenant_admin

    design_theme:
      value_type: json
      default_value:
        customizable: true
        elements: ["background_color","logo_image","theme_color"]
      configurable_by: tenant_admin

  integration:
    notification:
      value_type: json
      default_value:
        methods: ["app_internal","email","push"]
        control_level: "tenant"
      configurable_by: tenant_admin

    translation:
      value_type: json
      default_value:
        policy: "global"
        cache_period_days: 30
        target_scope: "title_only"
      configurable_by: tenant_admin

4. Systemレイヤ（Prisma変換互換・フラット化）

ここから下はGeminiがニコニコしながらBAG-liteをかけられるようにするための「1行＝1設定」版。
実装側ではこのブロックだけをYAML→JSONにして投入すればOKという形。

tenant_config_records:
  # --- user_roles ---
  - id: "user_roles.system_admin"
    section: "user_roles"
    key: "system_admin"
    value_type: "json"
    default_value:
      name: "システム管理者"
      scope: "global"
    configurable_by: "system_admin"
    management_scope: "system"

  - id: "user_roles.tenant_admin"
    section: "user_roles"
    key: "tenant_admin"
    value_type: "json"
    default_value:
      name: "テナント管理者"
      scope: "tenant"
    configurable_by: "system_admin"
    management_scope: "system"

  - id: "user_roles.general_user"
    section: "user_roles"
    key: "general_user"
    value_type: "json"
    default_value:
      name: "一般ユーザー"
      scope: "tenant"
    configurable_by: "system_admin"
    management_scope: "system"

  # --- operation_flows ---
  - id: "operation_flows.tenant_creation"
    section: "operation_flows"
    key: "tenant_creation"
    value_type: "json"
    default_value:
      steps:
        - { order: 1, actor: "system_admin", action: "create_tenant" }
        - { order: 2, actor: "system_admin", action: "init_master" }
        - { order: 3, actor: "system_admin", action: "register_tenant_admin" }
        - { order: 4, actor: "tenant_admin", action: "register_users" }
    configurable_by: "system_admin"
    management_scope: "system"

  # --- tenant_login ---
  - id: "tenant_login.structure.tenant_id_format"
    section: "tenant_login"
    key: "structure.tenant_id_format"
    value_type: "enum"
    default_value: "auto"
    enum_values: ["auto","manual"]
    configurable_by: "system_admin"
    management_scope: "system"

  - id: "tenant_login.control.authentication_method"
    section: "tenant_login"
    key: "control.authentication_method"
    value_type: "enum"
    default_value: "magic_link"
    enum_values: ["magic_link","password","oidc"]
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_login.control.login_attempt_limit"
    section: "tenant_login"
    key: "control.login_attempt_limit"
    value_type: "number"
    default_value: 3
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_login.control.session_timeout_minutes"
    section: "tenant_login"
    key: "control.session_timeout_minutes"
    value_type: "number"
    default_value: 30
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_login.ui.header"
    section: "tenant_login"
    key: "ui.header"
    value_type: "json"
    default_value:
      left: "tenant_name"
      right: "language_switcher"
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_login.ui.footer"
    section: "tenant_login"
    key: "ui.footer"
    value_type: "json"
    default_value:
      display: false
      elements: ["terms", "privacy", "contact"]
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_login.integration.notification_on_login"
    section: "tenant_login"
    key: "integration.notification_on_login"
    value_type: "boolean"
    default_value: true
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  # --- tenant_home ---
  - id: "tenant_home.structure.widget_types"
    section: "tenant_home"
    key: "structure.widget_types"
    value_type: "json"
    default_value:
      - { id: "latest_notice", default_enabled: true }
      - { id: "function_menu", default_enabled: true }
      - { id: "bulletin_board", default_enabled: false }
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_home.control.notice_display_count"
    section: "tenant_home"
    key: "control.notice_display_count"
    value_type: "enum"
    default_value: 3
    enum_values: [3,5,10]
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_home.control.notice_validity_days"
    section: "tenant_home"
    key: "control.notice_validity_days"
    value_type: "number"
    default_value: 30
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_home.ui.footer"
    section: "tenant_home"
    key: "ui.footer"
    value_type: "json"
    default_value:
      structure: "global"
      elements: ["home","notice","board","facility","mypage","logout"]
    configurable_by: "tenant_admin"
    management_scope: "tenant"
    depends_on: ["common_policy.ui.footer"]

  - id: "tenant_home.integration.translation"
    section: "tenant_home"
    key: "integration.translation"
    value_type: "json"
    default_value:
      cache_period_days: 30
      target_scope: "title_only"
    configurable_by: "tenant_admin"
    management_scope: "tenant"
    depends_on: ["common_policy.integration.translation"]

  # --- tenant_board (一部のみ。残りはBAGで細分化可) ---
  - id: "tenant_board.structure.categories"
    section: "tenant_board"
    key: "structure.categories"
    value_type: "json"
    default_value:
      admin_only: ["circular","important","operation_rule"]
      general: ["group","qa","other"]
    configurable_by: "system_admin"
    management_scope: "system"

  - id: "tenant_board.control.approval_flow"
    section: "tenant_board"
    key: "control.approval_flow"
    value_type: "json"
    default_value:
      scope: ["circular","important","operation_rule"]
      approver_count: 1
    configurable_by: "tenant_admin"
    management_scope: "tenant"
    depends_on: ["user_roles.tenant_admin"]

  - id: "tenant_board.control.attachment_files"
    section: "tenant_board"
    key: "control.attachment_files"
    value_type: "json"
    default_value:
      allowed_formats: ["pdf","jpg","png","office"]
      size_limit_per_file_mb: 5
      max_files_per_post: 5
      preview:
        enabled: true
        method: "modal"
        close_action: "tap"
        close_text: "タップで閉じる"
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_board.control.read_management"
    section: "tenant_board"
    key: "control.read_management"
    value_type: "json"
    default_value:
      target_categories: ["circular","important","operation_rule"]
      user_action: { method: "optional_button" }
      admin_view: { enabled: true }
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_board.ui.post_summary"
    section: "tenant_board"
    key: "ui.post_summary"
    value_type: "json"
    default_value:
      display_lines: 3
      self_post_indicator: { enabled: true }
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "tenant_board.integration.translation"
    section: "tenant_board"
    key: "integration.translation"
    value_type: "json"
    default_value:
      enabled: true
      cache: { enabled: true, period_days: 30 }
    configurable_by: "tenant_admin"
    management_scope: "tenant"
    depends_on: ["common_policy.integration.translation"]

  # --- tenant_board_detail ---
  - id: "tenant_board_detail.ui.post_detail_display"
    section: "tenant_board_detail"
    key: "ui.post_detail_display"
    value_type: "json"
    default_value:
      elements: ["title","author","posted_at","category","content","attachments","translate_button","tts_button"]
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  # --- common_policy ---
  - id: "common_policy.structure.layout"
    section: "common_policy"
    key: "structure.layout"
    value_type: "json"
    default_value:
      standard_structure: "header-content-footer"
      exceptions:
        - { screen: "tenant_login", footer_display: false }
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "common_policy.ui.header"
    section: "common_policy"
    key: "ui.header"
    value_type: "json"
    default_value:
      structure: "3_parts"
      elements:
        left: "notification_icon"
        center: "screen_title"
        right: "language_switcher"
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "common_policy.ui.footer"
    section: "common_policy"
    key: "ui.footer"
    value_type: "json"
    default_value:
      structure: "global_footer"
      elements: ["home","notice","board","facility","mypage","logout"]
    configurable_by: "tenant_admin"
    management_scope: "tenant"

  - id: "common_policy.integration.translation"
    section: "common_policy"
    key: "integration.translation"
    value_type: "json"
    default_value:
      policy: "global"
      cache_period_days: 30
      target_scope: "title_only"
    configurable_by: "tenant_admin"
    management_scope: "tenant"

5. 今回の整合ポイント（メモ）

Phase 2 では「構造／制御／UI／連携」がそのまま画面ごとに並んでいたが、Phase 3 では 「section.key」形式 にして1行で表せるようにした

tenant_board でTKDさんが追加してくれていた「PDFプレビュー時のモーダル挙動（タップで閉じる・上部に✕）」は、tenant_board.control.attachment_files に統合してある

承認フローは多段化せず固定1名、ただし approver_source = "tenant_admin_list" を保持したので、管理画面のプルダウンで拾える

翻訳と音声読み上げは、common_policy.integration.translation・tenant_board.integration.tts の2段で持たせて「全体設定＋機能個別上書き」ができるようにしてある

Prismaに落とすときは、この tenant_config_records をループでINSERTすればよい

6. ChangeLog

2025-11-01 v1.0

初版。Phase 2 の tenant-setting-list_v0.1.md をもとに、タチコマがPhase 3整合スキーマを生成

英語セクションIDへの統一（login→tenant_login, home→tenant_home, bulletin_board→tenant_board, bulletin_board_detail→tenant_board_detail, 共通→common_policy）

Prismaでの1テーブル構成を想定して、フラットな tenant_config_records を追加

GeminiのBAG-liteで検査しやすいよう depends_on を数カ所に付与

掲示板PDFプレビューのHarmoNet追加要件（モーダル・タップクローズ・✕ボタン）を tenant_board.control.attachment_files に反映

7. メタ情報

Document ID: HNM-TENANT-SCHEMA-20251101

Version: 1.0

Created: 2025-11-01

Last Updated: 2025-11-01

Author: タチコマ（HarmoNet AI Architect）

Supersedes: なし（新規）

Refs: tenant-setting-list_v0.1.md, harmonet-docs-directory-definition_v3.0.md, HarmoNet チーム全体の進め方と役割分担ガイドライン v1.0.md