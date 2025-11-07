# HarmoNet Tenant Config Schema — Part 05: 掲示板設定定義 v1.0

---

## 1. 概要

本章では、HarmoNet における**掲示板（Board）機能をテナント単位で運用するための設定項目**を定義する。  
Part 04（ホーム画面設定）から参照される「運用ルール表示」「ガイドラインカテゴリ」「掲示板モジュールタイル表示」の実体となる設定をここで提供する。

本Partは、以下の既存Partから参照される。

- Part 01: 共通属性定義 … `language_settings`, `theme_mode`
- Part 02: 権限・ロール設計 … 投稿・編集・削除・ピン留めの許可ロール
- Part 03: ログイン・UIテーマ設定 … 掲示板詳細画面のUI継承
- Part 04: ホーム画面設定 … `content.module_tiles.guidelines_source_ref` が本Partを参照

---

## 2. 設計思想

- **やさしく・自然・控えめ**  
  掲示板は入居者が最も頻繁に触れる機能であるため、運用ルールも「読むだけで分かる」構造にする。
- **カテゴリ運用の一元化**  
  「重要」「お知らせ」「質問」「ルール」など、掲示板で使うカテゴリ・タグをテナント管理者が差し替えられるようにする。
- **ホーム画面との連携前提**  
  Part 04 が「運用ルールをタイルに出す」ための参照先を本Partで定義し、別ファイルに書き散らさない。
- **PDF添付プレビュー要件への対応**  
  HarmoNetの掲示板は管理組合がPDFを添付する運用を前提とするため、プレビューON/OFFやモーダル表示方式を設定で制御できるようにしておく。

---

## 3. スキーマ定義（YAML）

```yaml
board_settings:

  # ========================================
  # 3.1 基本設定
  # ========================================
  general:
    enabled:
      type: boolean
      default: true
      configurable_by: tenant_admin
      description: "掲示板機能の有効／無効を制御"
    default_language:
      type: string
      enum: [ja, en, zh]
      default: ja
      linked_to: "Part 01: language_settings"
      description: "掲示板投稿の既定言語"
    allow_multi_language_post:
      type: boolean
      default: true
      configurable_by: tenant_admin
      description: "多言語投稿（翻訳フィールド付き）の利用可否"
    description: "掲示板全体に関する基本的な動作設定"

  # ========================================
  # 3.2 カテゴリ・タグ定義
  # ========================================
  categories:
    type: array
    items:
      - id: important
        label_ja: "重要"
        label_en: "Important"
        label_zh: "重要"
        color: "red"
        description: "ホーム画面の『重要なお知らせ』にも連動可能なカテゴリ"
      - id: notice
        label_ja: "お知らせ"
        label_en: "Notice"
        label_zh: "公告"
        color: "blue"
      - id: question
        label_ja: "質問"
        label_en: "Question"
        label_zh: "質問"
        color: "amber"
      - id: rule
        label_ja: "運用ルール"
        label_en: "Guideline"
        label_zh: "規則"
        color: "gray"
    configurable_by: tenant_admin
    description: "掲示板で利用するカテゴリ一覧。ホーム画面や通知と連携するIDで管理する"

  tags:
    type: array
    items:
      - id: pinned
        label: "ピン留め"
      - id: pdf
        label: "PDF添付"
      - id: survey
        label: "アンケート"
    description: "カテゴリとは別に付与できるタグ定義"

  # ========================================
  # 3.3 ガイドライン・運用ルール定義
  # ========================================
  guideline_categories:
    type: array
    items:
      - id: facility_rule
        label_ja: "施設利用ルール"
        label_en: "Facility Rules"
        description: "施設予約画面と共通の運用ルール"
      - id: garbage_rule
        label_ja: "ゴミ出しルール"
        label_en: "Garbage Rules"
      - id: board_posting_rule
        label_ja: "掲示板投稿ルール"
        label_en: "Board Posting Rules"
        description: "投稿・コメントの禁止事項など"
    configurable_by: tenant_admin
    description: "ホーム画面や『運用ルール』タイルから参照されるガイドラインカテゴリ"

  guideline_source_ref:
    type: string
    value: "tenant-config-part05_board-settings_v1.0.md"
    description: "Part 04のmodule_tiles.guidelines_source_refが参照する先。最新版をここに固定する"
    note: "他パートからはこのフィールドを参照することで運用ルール定義にアクセスする"

  # ========================================
  # 3.4 添付ファイル・PDFプレビュー設定
  # ========================================
  attachment:
    allow_pdf:
      type: boolean
      default: true
      description: "PDF添付の許可。管理組合がPDFで回覧板を出す前提"
    preview_mode:
      type: string
      enum: [modal, inline, none]
      default: modal
      description: "PDFをクリックしたときの表示方式。HarmoNetではmodalを標準とする"
    modal_close_behavior:
      tap_to_close:
        type: boolean
        default: true
        description: "モーダル全体タップで閉じる"
      show_close_icon:
        type: boolean
        default: true
        description: "モーダル上部に✕アイコンを表示する"
      background_click_close:
        type: boolean
        default: false
        description: "背景タップで閉じるかどうか。PDFスクロールを優先するため通常はfalse"
    description: "掲示板投稿に添付されるPDF等の表示に関する設定"

  # ========================================
  # 3.5 モデレーション（投稿制御）
  # ========================================
  moderation:
    require_approval:
      type: boolean
      default: false
      configurable_by: tenant_admin
      description: "投稿を公開する前にテナント管理者の承認を必要とするか"
    prohibited_words_ref:
      type: string
      default: ""
      description: "禁止ワードリストの参照先。未設定時はAIモデレーションに委譲"
    ai_moderation_enabled:
      type: boolean
      default: true
      description: "AIによる自動モデレーションを有効にする"
    description: "掲示板投稿・コメントのモデレーションに関する設定"

  # ========================================
  # 3.6 UI連携（Part 04・UI共通設計）
  # ========================================
  ui_integration:
    expose_to_home:
      type: boolean
      default: true
      description: "ホーム画面（Part 04）のモジュールタイルに掲示板関連の情報を表示する"
    home_tile_label:
      type: object
      label_ja: "運用ルール"
      label_en: "Guidelines"
      label_zh: "規則"
      description: "ホーム画面に表示するタイル名称"
    inherit_ui_theme:
      type: boolean
      default: true
      linked_to: "tenant-config-part03_login-settings_v1.1.md :: ui_theme"
      description: "Part 03で定義されたUIテーマを掲示板画面にも適用する"
    description: "ホーム画面や共通UIとの連携に関する設定"

  # ========================================
  # 3.7 権限設定
  # ========================================
  editable_by:
    system_admin: ['*']
    tenant_admin:
      - general
      - categories
      - tags
      - guideline_categories
      - attachment
      - moderation
      - ui_integration
    general_user:
      - none

4. 画面連携の前提

ホーム画面（Part 04）との連携

Part 04 の
content.module_tiles.guidelines_source_ref
は、本Partの
board_settings.guideline_source_ref
を指すことを前提とする。

これにより「ホームから運用ルールを開く」動線が1か所で定義される。

掲示板詳細設計（board-detail-design_*.md）との連携

掲示板詳細画面は、本Partのカテゴリ・タグ定義を読み込み、プルダウン・バッジとして表示する。

PDFプレビュー設定は本Partの attachment.preview_mode を優先する。

UI共通設計仕様書との整合

背景タップで閉じない、✕アイコンを表示する、モーダル全体タップで閉じる、というHarmoNet掲示板の追加要件をここに根付かせる。

5. 他パートとの連携
| 参照元              | 参照先（本Partの項目）                         | 説明                    |
| ---------------- | ------------------------------------- | --------------------- |
| Part 04: ホーム画面設定 | `board_settings.guideline_source_ref` | ホームの「運用ルール」タイルが参照する先  |
| 掲示板詳細設計書         | `categories`, `tags`, `attachment`    | 投稿画面・一覧画面で使用する分類と表示方式 |
| UI共通設計仕様書        | `ui_integration`                      | 掲示板画面の見た目を共通UIに揃えるため  |

6. ChangeLog
| No | 種別 | 内容                                          | 備考               |
| -- | -- | ------------------------------------------- | ---------------- |
| 1  | 新規 | Part 05（掲示板設定）を新規作成                         | Part 04が参照していたため |
| 2  | 連携 | `guideline_source_ref` を定義し、Part 04の参照先を実体化 | ドキュメント間参照の解消     |
| 3  | 機能 | PDFプレビュー設定を明示（modal / inline / none）        | 掲示板PDF要件に対応      |

7. メタ情報
| 項目               | 値                            |
| ---------------- | ---------------------------- |
| **Version**      | 1.0                          |
| **Document ID**  | HNM-TENANT-CONFIG-P05-BOARD  |
| **Created**      | 2025-11-02                   |
| **Last Updated** | 2025-11-02                   |
| **Author**       | タチコマ（HarmoNet AI Architect）  |
| **Reviewer**     | Claude（Design Specialist）想定  |
| **Approver**     | TKD（Project Owner）           |
| **Phase**        | 6（統合監査フェーズでの追補）              |
| **Supersedes**   | ー                            |
| **Status**       | Draft for Phase 6 Full Audit |

