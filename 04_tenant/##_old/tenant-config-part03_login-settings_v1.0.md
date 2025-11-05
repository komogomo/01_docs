Tenant Config — Part 03
ログイン画面設定（Phase 4 整合版）
1. 文書概要

本書は、harmonet-tenant-config-schema_v1.1 に基づき、
各テナントごとにカスタマイズ可能なログイン画面設定項目を定義する。

本定義は「共通属性定義（Part 01）」および「ロール・権限構造（Part 02）」に準拠し、
テナント単位でのUI外観・認証ポリシー・ログイン方式の制御を目的とする。

2. 構造位置（スキーマ連携）
schema_reference:
  base_schema: harmonet-tenant-config-schema_v1.1
  parent_section: tenant_settings
  part_dependency:
    - tenant-config-part01_common-attributes
    - tenant-config-part02_roles-and-permissions
  applies_to:
    module: authentication
    ui: login_screen
  description: |
    各テナントが持つ認証設定・UI設定の構成要素。
    ログイン方式やセッション制御、多言語設定を含む。

3. ログイン設定項目一覧
login_settings:

  # --- 認証方式 ---
  auth_method:
    type: enum
    enum: [email_magiclink, email_password, sso]
    default: email_magiclink
    description: |
      ログインの認証方式。
      - email_magiclink : メール送信によるワンクリック認証（推奨）
      - email_password  : 従来のメール＋パスワード形式
      - sso             : 外部SSO連携（Keycloak / Google Workspace など）

  # --- トークン・セッション管理 ---
  session:
    access_token_expiry_minutes:
      type: integer
      default: 30
      description: "アクセストークンの有効期限（分単位）"
    refresh_token_expiry_days:
      type: integer
      default: 7
      description: "リフレッシュトークンの有効期間（日単位）"
    concurrent_sessions_limit:
      type: integer
      default: 2
      description: "同時ログインを許可する端末数。0は無制限。"

  # --- パスワードポリシー ---
  password_policy:
    min_length: 8
    require_uppercase: true
    require_number: true
    require_special_char: true
    description: "パスワード認証利用時の複雑性ポリシー"
    note: "email_magiclinkの場合は無効"

  # --- 多言語設定 ---
  language_settings:
    default_language:
      type: string
      enum: [ja, en, zh]
      default: ja
      description: "初回アクセス時のUI言語"
    allow_language_switch:
      type: boolean
      default: true
      description: "ログイン画面での言語切替ボタン表示可否"

  # --- UIテーマ設定 ---
  ui_theme:
    logo_url:
      type: string
      description: "テナント固有ロゴのURL。設定がない場合は共通ロゴを使用"
    accent_color:
      type: string
      format: hex
      default: "#3B82F6"
      description: "主要ボタンおよび強調要素の色"
    background_style:
      type: enum
      enum: [light, dark]
      default: light
      description: "ログイン画面の背景トーン（ライト／ダーク）"
    show_tenant_name:
      type: boolean
      default: true
      description: "ログイン画面にテナント名を表示するか"

  # --- セキュリティオプション ---
  security:
    allow_auto_login:
      type: boolean
      default: false
      description: "認証済みブラウザで自動ログインを許可するか"
    two_factor_auth:
      type: boolean
      default: false
      description: "二要素認証を有効化するか（v1.2以降対応予定）"
    blocklist_mode:
      type: boolean
      default: true
      description: "不正アクセス元IPの自動ブロックを有効化"

4. アクセス制御と認証制限
access_control:
  tenant_based_login:
    enabled: true
    description: |
      各テナント固有のログインURLを生成し、他テナントからの認証を拒否。
      例） https://app.harmonnet.jp/login/{tenant_code}
  allowed_domains:
    type: array
    example: ["@example.com"]
    description: |
      テナントに属するユーザーのメールドメイン制限。
      指定ドメイン外のメールアドレスによる新規ログインを禁止。
  login_attempt_limits:
    max_attempts: 5
    lockout_minutes: 15
    description: "連続ログイン失敗による一時ロック制御"

5. 管理者権限における編集可否
editable_by:
  system_admin:
    - all
  tenant_admin:
    - language_settings
    - ui_theme
    - security.allow_auto_login
  general_user:
    - none
description: |
  各ロールによるログイン設定編集の可否。
  テナント管理者は外観設定・軽微なセキュリティ設定に限定。
  システム管理者のみ認証方式やトークン構成を変更可能。

6. 表示仕様（UIメタ設定）
ui_display:
  layout: centered_card
  logo_position: top
  language_toggle_position: top_right
  button_style: rounded
  font_family: "BIZ UDゴシック"
  transition_effect: fade_in
  note: "全テナントで共通スタイルを維持しつつ、ロゴ・色は個別適用可能。"

7. メタ情報
| 項目               | 値                                  |
| ---------------- | ---------------------------------- |
| **Version**      | 1.0                                |
| **Document ID**  | HNM-TENANT-PART03-20251101         |
| **Based on**     | harmonet-tenant-config-schema_v1.1 |
| **Phase**        | 4（整合化）                             |
| **Author**       | タチコマ（HarmoNet Architect）           |
| **Reviewer**     | Claude（予定）                         |
| **Auditor**      | Gemini（BAG-lite監査予定）               |
| **Created**      | 2025-11-01                         |
| **Last Updated** | 2025-11-01                         |
