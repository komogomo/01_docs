# B-03 BoardPostForm 詳細設計書 ch00 Index v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH00-INDEX
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 0.1 文書の目的

本書は、HarmoNet 掲示板機能における **掲示板投稿画面コンポーネント BoardPostForm（B-03）** の詳細設計書を章別に管理するためのインデックスである。
`harmonet-detail-design-agenda-standard_v1.0.md` に準拠し、BoardPostForm に必要な章構成と、それぞれの役割・対応ファイル名を一覧として定義する。

BoardPostForm は、掲示板への **新規投稿** および（必要に応じて）**既存投稿の編集** や **コメント返信** を行う入力 UI を提供し、掲示板 TOP（B-01）および詳細（B-02）のテストデータ生成源としても機能する。

---

## 0.2 対象コンポーネント

* コンポーネント ID: **B-03**
* 名称: **BoardPostForm**（掲示板 投稿フォーム）
* 対応 URL（初版想定）:

  * 新規投稿: `/board/new`
  * 編集: `/board/[postId]/edit`（将来拡張）

本コンポーネントは、以下の入力 UI を提供する役割を持つ。

* タイトル入力
* 本文入力
* カテゴリ選択（お知らせ / 規約・ルール / 回覧板 等）
* 対象範囲選択（GLOBAL / GROUP 等）
* 添付ファイルアップロード（PDF 等）
* 必要に応じた回覧板設定（MVP の範囲は基本設計に従う）

---

## 0.3 章構成一覧

BoardPostForm 詳細設計は、以下の章別ファイルで構成する。

| ch | 章タイトル             | 役割 / 内容概要                                         | 対応ファイル名（想定）                                                 |
| -- | ----------------- | ------------------------------------------------- | ----------------------------------------------------------- |
| 00 | Index             | 本一覧。対象コンポーネントと章構成、関連文書を定義。                        | `B-03_BoardPostForm-detail-design-ch00-index_v1.0.md`       |
| 01 | 概要                | 目的・スコープ・用語・関連ドキュメント・前提条件を定義。                      | `B-03_BoardPostForm-detail-design-ch01-overview_v1.0.md`    |
| 02 | 画面構造・コンポーネント構成    | 画面レイアウト・コンポーネント分割・ルーティングを定義。                      | `B-03_BoardPostForm-detail-design-ch02-layout_v1.0.md`      |
| 03 | データモデル・入出力仕様      | `schema.prisma` に基づく入力DTO・POST/PUT API・バリデーション項目。 | `B-03_BoardPostForm-detail-design-ch03-data-model_v1.0.md`  |
| 04 | 状態管理・イベント遷移       | 入力値・バリデーション状態・送信/キャンセル・ドラフト保存等。                   | `B-03_BoardPostForm-detail-design-ch04-state-event_v1.0.md` |
| 05 | UI 詳細仕様・メッセージ仕様   | 各入力項目のラベル・プレースホルダ・エラーメッセージ・i18n キー。               | `B-03_BoardPostForm-detail-design-ch05-ui-spec_v1.0.md`     |
| 06 | 結合・依存関係（共通部品・他画面） | BoardTop/Detail との遷移、添付アップロードAPI、Logger との結合。     | `B-03_BoardPostForm-detail-design-ch06-integration_v1.0.md` |
| 07 | テスト観点・UT/IT 方針    | Jest/RTL による UT 観点・バリデーション試験・主要テストケース。            | `B-03_BoardPostForm-detail-design-ch07-test-plan_v1.0.md`   |

※ 章タイトル・ファイル名は初版案であり、TKD による承認後に確定とする。

---

## 0.4 関連ドキュメント

BoardPostForm 詳細設計の前提となる関連ドキュメントを以下に示す。

| 種別     | 名称                                               | 備考                                                |
| ------ | ------------------------------------------------ | ------------------------------------------------- |
| 要件定義   | `functional-requirements-all_v1.6.md`            | 掲示板機能（投稿・コメント・回覧板・翻訳・TTS 等）の要件。                   |
| 非機能要件  | `Nonfunctional-requirements_v1.0.md`             | 認証方式・性能・セキュリティ・運用方針。                              |
| 技術スタック | `harmonet-technical-stack-definition_v4.4.md`    | Next.js / Supabase / Prisma / i18n 等の技術前提。        |
| 基本設計   | `board-design-ch00-index_v2.2.md`                | 掲示板機能 基本設計 目次。                                    |
| 基本設計   | `board-design-ch01_v2.2.md`                      | 掲示板機能 全体概要・用語定義。                                  |
| 基本設計   | `board-design-ch05_vX.Y.md`                      | 掲示板投稿画面（BoardPostForm）基本設計。                       |
| スキーマ   | `schema.prisma.txt`                              | `board_posts` / `board_attachments` / 回覧板関連テーブル等。 |
| 詳細設計標準 | `harmonet-detail-design-agenda-standard_v1.0.md` | 詳細設計書の章構成・記載粒度標準。                                 |
| 他画面詳細  | `B-01_BoardTop-detail-design-ch00〜07`            | 一覧画面への反映方法確認用。                                    |
| 他画面詳細  | `B-02_BoardDetail-detail-design-ch00〜07`         | 詳細画面との整合確認用。                                      |

---

## 0.5 今後の執筆・更新方針

1. まず `B-03_BoardPostForm-detail-design-ch01-overview_v1.0.md` および `-ch02-layout_v1.0.md` を優先して執筆し、BoardPostForm の役割と画面構造を確定する。
2. 続いて `schema.prisma` に基づき `-ch03-data-model_v1.0.md` を作成し、入力 DTO・バリデーション項目・POST/PUT API を明文化する。
3. 状態管理・イベント（ch04）、UI/メッセージ仕様（ch05）、結合（ch06）、テスト観点（ch07）は、B-01/B-02 との整合を維持しつつ、実装タスクおよび Jest/RTL テスト設計と並行して詳細化していく。
4. 章構成そのものを変更する必要が生じた場合は、本 Index の ChangeLog に記録し、バージョンを `v1.1` 以降へ更新する。
