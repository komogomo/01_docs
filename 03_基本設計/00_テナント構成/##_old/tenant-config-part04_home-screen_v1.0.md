HarmoNet Tenant Config Schema — Part 04: ホーム画面設定定義 v1.0
1. 概要

本章では、HarmoNet における ホーム画面（ログイン後の初期表示画面） の構造と設定項目を定義する。
この画面は入居者・管理者双方の「日常の入り口」として機能し、
テナント固有の情報や主要機能へのアクセスを一元的に提供する。

2. 設計思想

やさしく・自然・控えめなUI：Appleカタログ風の余白と整然さを基調とし、安心感を重視。

情報優先度の明確化：最上部に「重要なお知らせ」、その下に「募集中アンケート」、続いて主要機能タイルを配置。

モジュール化された拡張性：各タイル機能は独立設定可能で、テナント運用方針に応じて有効／無効を切替可能。

共通ナビゲーション：フッターを固定化し、操作迷子を防止。

未来拡張性：AIアシスタントエリアや通知機能を将来的に追加できる余地を確保。

3. スキーマ定義（YAML）
home_screen:
  header:
    show_logo: true
    show_language_toggle: true
    show_notification_icon: false
    description: "画面上部の共通ヘッダー領域。言語切替とロゴを表示。"

  content:
    important_notice:
      enabled: true
      source: "notice_board"
      display_limit: 3
      highlight_style: "banner"
      description: "重要なお知らせを最大3件まで表示。掲示板の '重要' タグ投稿を参照。"
    active_survey:
      enabled: true
      display_condition: "active_only"
      highlight_style: "card_emphasis"
      description: "募集中のアンケートを目立つカード形式で表示。募集期間外は非表示。"
    module_tiles:
      enabled_modules: ["notice", "board", "facility_booking", "survey", "guidelines"]
      display_order: ["notice", "board", "facility_booking", "survey", "guidelines"]
      guideline_category_ref: "board-detail-guideline_latest.md"
      description: "主要機能タイル群。お知らせ・掲示板・施設予約・アンケート・運用ルールを表示。"
    layout_style: "scrollable_card_grid"
    background_style: "light"
    description: "ホーム画面の主要コンテンツ構成。"

  footer:
    menu_items:
      - home
      - board
      - facility_booking
      - mypage
      - logout
    fixed: true
    description: "全画面共通のフッターナビゲーション。ログイン画面を除き常時表示。"

  ui_theme_link:
    inherit_from: "ui_theme"
    accent_color_ref: "#3B82F6"
    font_family: "BIZ UDゴシック"
    transition_effect: "fade_in"
    description: "Part 03のUIテーマ設定と連携。"

  editable_by:
    system_admin: [all]
    tenant_admin:
      - content.important_notice
      - content.active_survey
      - content.module_tiles
    general_user: [none]

4. 表示構成概要
| 領域      | 主要要素                     | 表示制御   | 備考             |
| ------- | ------------------------ | ------ | -------------- |
| Header  | ロゴ、言語切替                  | 固定表示   | テナントテーマと連動     |
| Content | お知らせ・アンケート・機能タイル         | テナント設定 | 優先度順で縦並び       |
| Footer  | ホーム／掲示板／施設予約／マイページ／ログアウト | 共通固定   | ログイン画面を除く全画面共通 |

5. 他パートとの連携
| 参照先               | 連携内容                               |
| ----------------- | ---------------------------------- |
| Part 01: 共通属性定義   | 言語設定（language_settings）を参照         |
| Part 02: 権限・ロール設計 | editable_by 構造を参照                  |
| Part 03: ログイン設定   | UIテーマ連携（accent_color, font_family） |
| UI共通設計仕様書         | `ui-common-spec_latest.md` 準拠      |
| 掲示板詳細設計           | 運用ルールカテゴリ参照（共通構造）                  |

6. 補足仕様

アンケートの表示条件：display_condition: active_only により、期間外は自動非表示。

重要なお知らせの定義：掲示板投稿の tag: important を参照。

機能タイルの表示順：display_order で自由に変更可能。

ガイドラインカテゴリ参照：掲示板詳細設計（Part 06）と共通化し、冗長定義を排除。

モバイル優先レイアウト：layout_style: scrollable_card_grid により縦スクロール前提。

7. トレーサビリティ
| 項目          | 参照文書                                          |
| ----------- | --------------------------------------------- |
| テーマ・フォント構成  | `tenant-config-part03_login-settings_v1.1.md` |
| 掲示板詳細ガイドライン | `board-detail-design-ch06_latest.md`          |
| UI仕様共通      | `ui-common-spec_latest.md`                    |
| デザイン基準      | `harmonet-style-guideline_latest.md`          |

8. メタ情報
| 項目            | 内容                          |
| ------------- | --------------------------- |
| Version       | 1.0                         |
| Document ID   | HNM-TENANT-CONFIG-P04-HOME  |
| Created       | 2025-11-01                  |
| Author        | タチコマ（HarmoNet AI Architect） |
| Reviewer      | Claude（Design Specialist）   |
| Approval      | TKD（Project Owner）          |
| Review Status | Pending Takikoma Approval   |

ChangeLog
| No | 更新箇所 | 種別 | 修正内容                   | 理由               |
| -- | ---- | -- | ---------------------- | ---------------- |
| 1  | 新規作成 | 新規 | Part 04 ホーム画面設定構造を新規定義 | Phase 4 仕様に基づく新設 |
