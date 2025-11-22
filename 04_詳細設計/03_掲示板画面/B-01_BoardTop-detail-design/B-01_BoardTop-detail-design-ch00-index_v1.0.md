# B-01 BoardTop 詳細設計書 ch00 Index v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-INDEX
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## ChangeLog

| Version | Date       | Author    | Summary          |
| ------- | ---------- | --------- | ---------------- |
| 1.0     | 2025-11-22 | Tachikoma | 初版作成（章構成・関連文書定義） |

---

## 0.1 文書の目的

本書は、HarmoNet 掲示板機能における **掲示板TOP画面コンポーネント BoardTop（B-01）** の詳細設計書を章別に管理するためのインデックスである。
`harmonet-detail-design-agenda-standard_v1.0.md` に準拠し、BoardTop に必要な章構成と、それぞれの役割・対応ファイル名を一覧として定義する。

本 Index 自体には実装仕様の詳細は記載せず、各章の位置付けと参照関係のみを示す。

---

## 0.2 対象コンポーネント

* コンポーネント ID: **B-01**
* 名称: **BoardTop**（掲示板 TOP 一覧画面）
* 対応 URL: `/board`

本コンポーネントは、テナント内の掲示板投稿を一覧表示する画面であり、タブ・範囲フィルタ・ページネーションを用いて回覧板情報を俯瞰できるようにする。

---

## 0.3 章構成一覧

BoardTop 詳細設計は、以下の章別ファイルで構成する。

| ch | 章タイトル             | 役割 / 内容概要                                       | 対応ファイル名（想定）                                            |
| -- | ----------------- | ----------------------------------------------- | ------------------------------------------------------ |
| 00 | Index             | 本一覧。対象コンポーネントと章構成、関連文書を定義。                      | `B-01_BoardTop-detail-design-ch00-index_v1.0.md`       |
| 01 | 概要                | 目的・スコープ・用語・関連ドキュメント・前提条件を定義。                    | `B-01_BoardTop-detail-design-ch01-overview_v1.0.md`    |
| 02 | 画面構造・コンポーネント構成    | 画面レイアウト・コンポーネント分割・ルーティングを定義。                    | `B-01_BoardTop-detail-design-ch02-layout_v1.0.md`      |
| 03 | データモデル・入出力仕様      | `schema.prisma` に基づく入出力 DTO・取得条件・ソート定義。         | `B-01_BoardTop-detail-design-ch03-data-model_v1.0.md`  |
| 04 | 状態管理・イベント遷移       | タブ切替・フィルタ・ページング等の状態・イベント・遷移図。                   | `B-01_BoardTop-detail-design-ch04-state-event_v1.0.md` |
| 05 | UI 詳細仕様・メッセージ仕様   | カード構造・テキスト・アイコン・i18n キー・メッセージ出力位置。              | `B-01_BoardTop-detail-design-ch05-ui-spec_v1.0.md`     |
| 06 | 結合・依存関係（共通部品・他画面） | AppHeader/AppFooter/LanguageSwitch などとの結合・遷移関係。 | `B-01_BoardTop-detail-design-ch06-integration_v1.0.md` |
| 07 | テスト観点・UT/IT 方針    | Jest/RTL による UT 観点・モック方針・主要テストケース一覧。            | `B-01_BoardTop-detail-design-ch07-test-plan_v1.0.md`   |

※ 章タイトル・ファイル名は初版案であり、TKD による承認後に確定とする。

---

## 0.4 関連ドキュメント

BoardTop 詳細設計の前提となる関連ドキュメントを以下に示す。

| 種別     | 名称                                               | 備考                                         |
| ------ | ------------------------------------------------ | ------------------------------------------ |
| 要件定義   | `functional-requirements-all_v1.6.md`            | 掲示板機能（投稿・コメント・回覧板・翻訳・TTS 等）の要件。            |
| 非機能要件  | `Nonfunctional-requirements_v1.0.md`             | 認証方式・性能・セキュリティ・運用方針。                       |
| 技術スタック | `harmonet-technical-stack-definition_v4.4.md`    | Next.js / Supabase / Prisma / i18n 等の技術前提。 |
| 基本設計   | `board-design-ch00-index_v2.2.md`                | 掲示板機能 基本設計 目次。                             |
| 基本設計   | `board-design-ch01_v2.2.md`                      | 掲示板機能 全体概要・用語定義。                           |
| 基本設計   | `board-design-ch03_v2.4.md`                      | 掲示板TOP画面（BoardTop）基本設計。                    |
| スキーマ   | `schema.prisma.txt`                              | `board_posts` など掲示板関連テーブル定義（唯一の正）。         |
| 詳細設計標準 | `harmonet-detail-design-agenda-standard_v1.0.md` | 詳細設計書の章構成・記載粒度標準。                          |

---

## 0.5 今後の執筆・更新方針

1. まず `B-01_BoardTop-detail-design-ch01-overview_v1.0.md` および `-ch02-layout_v1.0.md` を優先して執筆し、BoardTop の役割と画面構造を確定する。
2. 続いて `schema.prisma` に基づき `-ch03-data-model_v1.0.md` を作成し、BoardTop が扱う入出力データとソート・フィルタ条件を明文化する。
3. 状態管理・イベント（ch04）、UI/メッセージ仕様（ch05）、結合（ch06）、テスト観点（ch07）は、実装タスクおよび Jest/RTL テスト設計と並行して詳細化していく。
4. 章構成そのものを変更する必要が生じた場合は、本 Index の ChangeLog に記録し、バージョンを `v1.1` 以降へ更新する。
