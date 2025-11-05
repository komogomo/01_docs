# HarmoNet Tenant Config Schema — Part 04: ホーム画面設定定義 v1.2

---

## 1. 概要

本章では、HarmoNet における **ホーム画面（ログイン後の初期表示画面）** の構造と設定項目を定義する。  
この画面は入居者・管理者双方の「日常の入り口」として機能し、  
テナント固有の情報や主要機能へのアクセスを一元的に提供する。

---

## 2. 設計思想

- **やさしく・自然・控えめなUI：** Appleカタログ風の余白と整然さを基調とし、安心感を重視。
- **情報優先度の明確化：** 最上部に「重要なお知らせ」、その下に「募集中アンケート」、続いて主要機能タイルを配置。
- **モジュール化された拡張性：** 各タイル機能は独立設定可能で、テナント運用方針に応じて有効／無効を切替可能。
- **共通ナビゲーション：** フッターを固定化し、操作迷子を防止。
- **未来拡張性：** AIアシスタントエリアや通知機能を将来的に追加できる余地を確保。

---

## 3. スキーマ定義（YAML）

```yaml
home_screen:
  
  # ========================================
  # 3.1 Header（画面上部）
  # ========================================
  header:
    show_logo:
      type: boolean
      default: true
      configurable_by: tenant_admin
      description: "テナントロゴの表示制御"
    
    show_language_toggle:
      type: boolean
      default: true
      configurable_by: tenant_admin
      linked_to: "Part 01: language_settings"
      description: "言語切替ボタンの表示制御。Part 01の言語設定と連携"
    
    show_notification_icon:
      type: boolean
      default: false
      configurable_by: tenant_admin
      note: "将来の通知機能拡張用"
      description: "通知アイコンの表示制御（現在は非実装）"
    
    description: "画面上部の共通ヘッダー領域。言語切替とロゴを表示。"

  # ========================================
  # 3.2 Content（主要コンテンツ領域）
  # ========================================
  content:
    
    # 重要なお知らせ
    important_notice:
      enabled:
        type: boolean
        default: true
        configurable_by: tenant_admin
        description: "重要なお知らせ表示の有効化"
      
      source:
        type: string
        enum: [notice_board, manual_selection]
        default: notice_board
        description: "重要なお知らせの取得元。掲示板の'重要'タグ投稿を自動参照"
      
      display_limit:
        type: integer
        default: 3
        range: [1, 10]
        configurable_by: tenant_admin
        description: "表示件数の上限"
      
      highlight_style:
        type: string
        enum: [banner, card, list]
        default: banner
        description: "強調表示スタイル"
      
      description: "重要なお知らせを最大N件まで表示。掲示板の'重要'タグ投稿を参照。"
    
    # 募集中アンケート
    active_survey:
      enabled:
        type: boolean
        default: true
        configurable_by: tenant_admin
        description: "募集中アンケート表示の有効化"
      
      display_condition:
        type: string
        enum: [active_only, all, draft_only]
        default: active_only
        description: "表示条件。active_only = 募集期間内（start_date <= now <= end_date AND status='active'）"
      
      display_limit:
        type: integer
        default: 3
        range: [1, 10]
        configurable_by: tenant_admin
        description: "複数募集中の場合の表示上限"
      
      sort_order:
        type: string
        enum: [created_desc, start_date_desc, priority_desc]
        default: start_date_desc
        description: "表示優先順の制御"
      
      highlight_style:
        type: string
        enum: [card_emphasis, inline, banner]
        default: card_emphasis
        description: "強調表示スタイル"
      
      description: "募集中のアンケートを目立つカード形式で表示。募集期間外は自動非表示。"
    
    # 機能タイル
    module_tiles:
      enabled_modules:
        type: array
        items:
          type: string
          enum: [notice, board, facility_booking, survey, guidelines, mypage]
        default: [notice, board, facility_booking, survey, guidelines]
        configurable_by: tenant_admin
        description: "ホーム画面に表示する機能タイル"
      
      display_order:
        type: array
        items:
          type: string
          enum: [notice, board, facility_booking, survey, guidelines, mypage]
        default: [notice, board, facility_booking, survey, guidelines]
        configurable_by: tenant_admin
        description: "タイルの表示順序。配列の順番通りに表示"
      
      guidelines_source_ref:
        type: string
        value: "tenant-config-part05_board-settings_v1.0.md"
        description: "運用ルール（ガイドライン）の参照先。掲示板設定のガイドラインカテゴリ定義と連携"
        note: "Part 05で定義される掲示板のガイドラインカテゴリと整合"
      
      description: "主要機能タイル群。お知らせ・掲示板・施設予約・アンケート・運用ルールを表示。"
    
    # レイアウト設定
    layout:
      style:
        type: string
        enum: [scrollable_card_grid, vertical_list, horizontal_scroll]
        default: scrollable_card_grid
        description: "ホーム画面のレイアウト方式"
      
      grid_columns:
        mobile: 1
        tablet: 2
        desktop: 3
        description: "カードグリッドの列数（デバイス別レスポンシブ対応）"
      
      card_spacing:
        type: string
        enum: [compact, normal, spacious]
        default: normal
        configurable_by: tenant_admin
        description: "カード間の余白設定"
      
      description: "ホーム画面のレイアウト仕様。レスポンシブデザイン対応。"
    
    background_style:
      type: string
      enum: [light, dark, auto]
      default: light
      configurable_by: tenant_admin
      linked_to: "Part 01: theme_mode"
      description: "背景スタイル。Part 01のtheme_modeと連携"
    
    description: "ホーム画面の主要コンテンツ構成。"

  # ========================================
  # 3.3 Footer（画面下部ナビゲーション）
  # ========================================
  footer:
    menu_items:
      type: array
      items:
        - id: home
          label_ja: "ホーム"
          label_en: "Home"
          icon: "home"
          path: "/home"
        
        - id: board
          label_ja: "掲示板"
          label_en: "Board"
          icon: "message-square"
          path: "/board"
        
        - id: facility_booking
          label_ja: "施設予約"
          label_en: "Facility"
          icon: "calendar"
          path: "/facility-booking"
        
        - id: mypage
          label_ja: "マイページ"
          label_en: "My Page"
          icon: "user"
          path: "/mypage"
      
      configurable_by: tenant_admin
      description: "フッターナビゲーション項目。各項目はアイコン・ラベル・パスで定義"
    
    logout:
      show_in_footer: false
      location: "header_dropdown"
      description: "ログアウトはフッターではなく、ヘッダーのユーザーメニュー内に配置"
    
    fixed:
      type: boolean
      default: true
      description: "フッターを固定表示（全画面共通、ログイン画面を除く）"
    
    description: "全画面共通のフッターナビゲーション。ログイン画面を除き常時表示。"

  # ========================================
  # 3.4 UIテーマ連携
  # ========================================
  ui_theme:
    inherit_from: "tenant-config-part03_login-settings_v1.1.md :: ui_theme"
    description: "Part 03で定義されたUIテーマ設定（ロゴ・アクセントカラー・フォント等）を継承"
    
    additional_settings:
      card_shadow:
        type: string
        enum: [none, subtle, medium, strong]
        default: subtle
        description: "カードシャドウの強度"
      
      transition_duration:
        type: string
        default: "0.3s"
        description: "画面遷移・アニメーション速度"
      
      description: "ホーム画面固有のUI調整項目"
    
    note: "accent_color, font_family等の基本設定はPart 03を参照"

  # ========================================
  # 3.5 権限設定
  # ========================================
  editable_by:
    system_admin: ['*']
    tenant_admin:
      - content.important_notice
      - content.active_survey
      - content.module_tiles
      - content.layout
      - content.background_style
      - header.show_logo
      - header.show_language_toggle
      - header.show_notification_icon
      - footer.menu_items
    general_user: [none]
```

---

## 4. 表示構成概要

| 領域      | 主要要素                           | 表示制御      | 備考                     |
| ------- | ------------------------------ | --------- | ---------------------- |
| Header  | ロゴ、言語切替、通知アイコン（将来）           | テナント設定    | Part 01言語設定・Part 03テーマ連携 |
| Content | 重要なお知らせ・募集中アンケート・機能タイル       | テナント設定    | 優先度順で縦並び・レスポンシブ対応      |
| Footer  | ホーム／掲示板／施設予約／マイページ（ログアウトは除外） | 共通固定・一部設定 | ログイン画面を除く全画面共通         |

---

## 5. 他パートとの連携

| 参照先                | 連携内容                                             |
| ------------------ | ------------------------------------------------ |
| Part 01: 共通属性定義    | 言語設定（`language_settings`）、テーマモード（`theme_mode`）を参照 |
| Part 02: 権限・ロール設計  | `editable_by` 構造を完全継承                            |
| Part 03: ログイン設定    | UIテーマ連携（`accent_color`, `font_family`, `logo_url`） |
| Part 05: 掲示板設定（予定） | 運用ルール（ガイドライン）カテゴリを参照                             |
| UI共通設計仕様書         | `ui-common-spec_latest.md` 準拠                     |

---

## 6. 補足仕様

### 6.1 重要なお知らせの判定ロジック
- **取得元:** 掲示板投稿の `tag: important` を参照
- **表示条件:** 公開済み（`status: published`）かつ有効期限内
- **並び順:** 投稿日時降順（新しい順）

### 6.2 募集中アンケートの判定ロジック
- **表示条件:** `start_date <= now <= end_date AND status = 'active'`
- **複数募集中の場合:** `display_limit` で制限、`sort_order` で優先順制御
- **募集終了後:** 自動非表示

### 6.3 機能タイルの動作
- **表示制御:** `enabled_modules` で有効化
- **表示順:** `display_order` の配列順に従う
- **運用ルール連携:** Part 05の掲示板設定で定義されるガイドラインカテゴリと整合

### 6.4 フッターナビゲーション
- **固定表示:** 全画面共通（ログイン画面を除く）
- **ログアウト:** フッターではなくヘッダーのユーザーメニュー内に配置
- **レスポンシブ:** モバイル表示ではアイコンのみ、タブレット以上でラベル表示

### 6.5 レイアウト・レスポンシブ対応
- **モバイル（〜767px）:** 1列表示
- **タブレット（768px〜1023px）:** 2列表示
- **デスクトップ（1024px〜）:** 3列表示
- **スクロール:** 縦スクロール前提、カード間の余白は `card_spacing` で調整

---

## 7. トレーサビリティ

| 項目           | 参照文書                                          |
| ------------ | --------------------------------------------- |
| 共通属性・言語設定    | `tenant-config-part01_common-attributes_v1.1.md` |
| 権限・ロール設計     | `tenant-config-part02_roles-and-permissions_v1.1.md` |
| UIテーマ・ログイン設定 | `tenant-config-part03_login-settings_v1.1.md` |
| 掲示板設計        | `tenant-config-part05_board-settings_v1.0.md`（予定） |
| UI仕様共通       | `ui-common-spec_latest.md`                    |
| デザイン基準       | `harmonet-style-guideline_latest.md`          |

---

## 8. ChangeLog

| No | 更新箇所                           | 種別      | 修正内容                                                    | 理由                       |
| -- | ------------------------------ | ------- | ------------------------------------------------------- | ------------------------ |
| 1  | 全フィールド                         | 構造拡張    | `type`, `default`, `range/enum`, `configurable_by` を追加 | 実装可能性の向上・バリデーション強化       |
| 2  | `content.active_survey`        | 定義明確化   | 表示条件の判定ロジック明記・`display_limit`, `sort_order` 追加        | アンケート表示制御の精緻化            |
| 3  | `content.module_tiles`         | 参照先修正   | `guideline_category_ref` → `guidelines_source_ref` に変更  | Part 05（掲示板設定）との整合性確保    |
| 4  | `header.show_language_toggle`  | 参照追加    | `linked_to: "Part 01: language_settings"` を明記          | Part 01言語設定との連携明示        |
| 5  | `footer`                       | 構造化     | メニュー項目詳細定義（id, label, icon, path）・logout移動           | UI設計の精緻化・フッター役割の明確化      |
| 6  | `ui_theme_link` → `ui_theme`   | 参照整理    | Part 03継承形式に変更・`accent_color_ref` 削除                   | 冗長定義の排除・参照関係の明確化         |
| 7  | `content.layout`               | 詳細追加    | `grid_columns`（1/2/3列）・レスポンシブ仕様を明記                     | 実装ガイダンスの強化・デバイス対応の明確化    |
| 8  | `content.important_notice`     | 構造拡張    | `source`, `highlight_style` の選択肢を追加                    | 将来の手動選択機能拡張への対応          |
| 9  | `content.layout.card_spacing`  | 設定追加    | カード間余白の制御項目を追加                                          | UI調整の柔軟性向上               |
| 10 | `ui_theme.additional_settings` | ホーム画面固有 | `card_shadow`, `transition_duration` を追加              | ホーム画面特有のUI調整項目を定義        |
| 11 | `ui_theme.additional_settings.transition_duration` | 型定義追加 | `type: string` を明記 | Claude形式統一ルール準拠 |
| 12 | `content.background_style` | 参照明示 | `linked_to: "Part 01: theme_mode"` を追加 | Gemini監査対応・参照関係の明確化 |
| 13 | `editable_by.system_admin` | 値修正 | `[all]` → `['*']` に変更 | Phase 2共通スキーマ準拠 |

---

## 9. メタ情報

| 項目               | 値                                   |
| ---------------- | ----------------------------------- |
| **Version**      | 1.2                                 |
| **Document ID**  | HNM-TENANT-CONFIG-P04-HOME          |
| **Created**      | 2025-11-01                          |
| **Last Updated** | 2025-11-01                          |
| **Author**       | タチコマ（HarmoNet AI Architect）         |
| **Reviewer**     | Claude（Design Specialist）           |
| **Approver**     | TKD（Project Owner）                  |
| **Review Status** | ⏳ Pending Tachikoma Approval        |
| **Based on Schema** | harmonet-tenant-config-schema_v1.1.md |
| **Phase**        | 4（整合スキーマ化）                          |
| **Supersedes**   | tenant-config-part04_home-screen_v1.1.md |

review_status:
  reviewer: タチコマ
  reviewed_at: 2025-11-01
  status: ✅ Approved (Final Release)
  next_step: "Gemini監査結果をPhase 5ドキュメント統合に反映"
  notes: "Claude修正版v1.2は全項目においてPhase 4基準を満たし、Gemini監査結果も安定品質を確認。Part 04を正式承認とする。"

---

**本文書は、HarmoNet Phase 4 AI連携運用ガイドライン v1.0 に基づき作成された。**  
**タチコマによる最終確認後、Gemini BAG-lite監査を実施予定。**
