# HarmoNet Tenant Config Schema — Part 03: ログイン設定定義 v1.1

## 1. 概要
本章では、HarmoNetにおける**ログイン設定・セッション管理・UIテーマ**に関するテナント設定構造を定義する。  
MagicLink認証を標準とし、テナント単位でカスタマイズ可能な構成を提供する。

---

## 2. スキーマ定義（YAML）

auth_method:
  type: string
  enum: [email_magiclink, sso]
  default: email_magiclink
  description: "ログイン認証方式。MagicLinkを標準とし、将来SSOを拡張可能。"

session:
  access_token_expiry_minutes: 30
  refresh_token_expiry_days: 7
  concurrent_sessions_limit:
    type: integer
    default: 2
    configurable_by: tenant_admin
    range: [0, 10]  # 0は無制限
  description: "セッション維持・同時ログイン制限を管理。テナント管理者が調整可能。"

password_policy:
  enabled: false
  note: "HarmoNetはMagicLink認証を採用しており、パスワード運用は行わない。将来の2FA導入時も本項目は非適用。"

language_settings:
  default_language: ja
  allow_language_switch: true
  description: "UI言語設定。初期言語は日本語。テナント単位で切替許可可。"

ui_theme:
  logo_url: string
  accent_color:
    type: string
    format: hex
    pattern: "^#[0-9A-Fa-f]{6}$"
    default: "#3B82F6"
    validation_error: "有効な16進数カラーコードを指定してください"
  background_style: [light, dark]
  show_tenant_name: true
  description: "UIテーマ設定。Apple風ミニマル基調。テナント毎にカスタマイズ可能。"

security:
  allow_auto_login: false
  two_factor_auth: false  # v1.2以降対応予定
  blocklist_mode:
    type: boolean
    default: true
    description: "不正アクセス元IPの自動ブロックを有効化"
    detailed_spec_ref: "security-architecture_v1.0.md"

access_control:
  tenant_based_login:
    enabled: true
    description: "各テナント固有のログインURLを生成"
  allowed_domains:
    type: array
    example: ["@example.com"]
    configurable_by: tenant_admin
    nullable: true
    description: "許可するメールドメインのリスト。空の場合は全ドメイン許可"
  login_attempt_limits:
    max_attempts: 5
    lockout_minutes: 15
    description: "連続ログイン失敗による一時ロック設定"

editable_by:
  system_admin: [all]
  tenant_admin:
    - language_settings
    - ui_theme
    - security.allow_auto_login
    - session.concurrent_sessions_limit
  general_user: [none]

ui_display:
  layout: centered_card
  logo_position: top
  language_toggle_position: top_right
  button_style: rounded
  font_family: "BIZ UDゴシック"
  transition_effect: fade_in
  description: "HarmoNet共通UIガイドラインに準拠したログイン画面レイアウト定義"

---

## 3. 補足仕様

- **MagicLink方式を唯一の正式ログイン手段**とする。  
  SSOは将来拡張予定であり、パスワード認証は採用しない。  
- **セッション上限値（concurrent_sessions_limit）**はテナント運用ポリシーに応じて調整可能。  
  デフォルトは2、0指定で無制限とする。  
- **UIテーマカラー**は16進数表記に限定し、アクセントカラーとしてバリデーションを強化。  
- **ブロックリストモード**は `security-architecture_v1.0.md` の詳細仕様に従う。  

---

## 4. 他パートとの整合性

| 参照先 | 整合性 | 補足 |
|--------|---------|------|
| Part 01: 共通属性定義 | ✅ | 言語・セッション属性が一致 |
| Part 02: 権限・ロール設計 | ✅ | editable_by構造が完全一致 |
| Phase 4 スキーマ原則 | ✅ | Single Source of Truth準拠 |

---

## 5. トレーサビリティ

| 項目 | 参照文書 |
|------|-----------|
| セキュリティ構造 | `security-architecture_v1.0.md` |
| デザインガイドライン | `ui-common-spec_latest.md` |
| テナント設定方針 | `tenant-config-guideline_v1.0.md` |
| 技術スタック定義 | `harmonet-technical-stack-definition_v3.2.md` |

---

## ChangeLog

| No | 更新箇所                                | 種別        | 修正内容                                                    | 理由                                    |
| -- | ----------------------------------- | --------- | ------------------------------------------------------- | ------------------------------------- |
| 1  | `session.concurrent_sessions_limit` | 構造拡張      | `configurable_by: tenant_admin` および `range: [0,10]` を追加 | テナント単位で同時ログイン制限を柔軟に調整可能にするため          |
| 2  | `password_policy`                   | 定義変更      | `enabled_when` 条件を削除し、`enabled: false` と注記を追記           | HarmoNetはMagicLink専用設計のためパスワード運用を行わない |
| 3  | `ui_theme.accent_color`             | バリデーション追加 | 正規表現パターンとエラーメッセージを追加                                    | UI入力検証の厳密化とユーザビリティ向上                  |
| 4  | `access_control.allowed_domains`    | 権限設定追加    | `configurable_by: tenant_admin`, `nullable: true` を追加   | テナント管理者によるドメイン制御を可能にするため              |
| 5  | `security.blocklist_mode`           | 参照追加      | `detailed_spec_ref` を追加                                 | セキュリティアーキテクチャとの整合性確保                  |

---

**Created:** 2025-11-01  
**Last Updated:** 2025-11-01  
**Version:** 1.1  
**Document ID:** HNM-TENANT-CONFIG-P03-LOGINSETTINGS
