# B-03 BoardPostForm 詳細設計書 ch00 Index v1.1

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH00-INDEX
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 0.1 文書の目的

本書は、HarmoNet 掲示板機能における **掲示板投稿画面コンポーネント BoardPostForm（B-03）** の詳細設計書を章別に管理するためのインデックスである。
`harmonet-detail-design-agenda-standard_v1.0.md` に準拠し、BoardPostForm に必要な章構成と、それぞれの役割・対応ファイル名を一覧として定義する。

BoardPostForm は、掲示板への **新規投稿** および **既存投稿の編集** を行う入力 UI を提供し、掲示板 TOP（B-01）および詳細（B-02）と連携して機能する。

---

## 0.2 対象コンポーネント

* コンポーネント ID: **B-03**
* 名称: **BoardPostForm**（掲示板 投稿フォーム）
* 主な利用形態:
  * 新規投稿ページ: `/board/new`
  * 編集モード: 掲示板詳細画面（B-02）内でのインライン編集用コンポーネントとして再利用

本コンポーネントは、以下の入力 UI を提供する役割を持つ。

* **投稿者名の表示設定**（匿名／ニックネーム ※必須選択）
* タイトル入力
* 本文入力
* カテゴリ選択（お知らせ / 規約・ルール / 回覧板 等）
* 対象範囲選択（GLOBAL / GROUP 等）
* 添付ファイルアップロード（PDF / Office ファイル）
* 必要に応じた回覧板設定

---

## 0.3 章構成一覧

BoardPostForm 詳細設計は、以下の章別ファイルで構成する。

| ch | 章タイトル             | 役割 / 内容概要                                         | 対応ファイル名（想定）                                                 |
| -- | ----------------- | ------------------------------------------------- | ----------------------------------------------------------- |
| 00 | Index             | 本一覧。対象コンポーネントと章構成、関連文書を定義。                        | `B-03_BoardPostForm-detail-design-ch00-index_v1.1.md`       |
| 01 | 概要                | 目的・スコープ・前提条件（新規/編集モード・権限等）を定義。                  | `B-03_BoardPostForm-detail-design-ch01-overview_v1.1.md`    |
| 02 | 画面構造・コンポーネント構成    | 画面レイアウト・セクション構成・レスポンシブ方針。                         | `B-03_BoardPostForm-detail-design-ch02-layout_v1.1.md`      |
| 03 | データモデル・入出力仕様      | State/DTO 定義・投稿者表示モード・添付仕様・API インタフェース。             | `B-03_BoardPostForm-detail-design-ch03-data-model_v1.1.md`  |
| 04 | 状態管理・イベント遷移       | 入力変更・バリデーション・確認ダイアログ（プレビュー）・送信ロジック。             | `B-03_BoardPostForm-detail-design-ch04-state-event_v1.1.md` |
| 05 | UI 詳細仕様・メッセージ仕様   | ラベル・エラーメッセージ・注意文言・確認ダイアログの詳細。                     | `B-03_BoardPostForm-detail-design-ch05-ui-spec_v1.1.md`     |
| 06 | 結合・依存関係（共通部品・他画面） | B-01/B-02 との連携・インライン編集時の振る舞い・添付API連携。               | `B-03_BoardPostForm-detail-design-ch06-integration_v1.1.md` |
| 07 | テスト観点・UT/IT 方針    | ユニットテスト・結合テスト観点（匿名選択・編集モード含む）。                  | `B-03_BoardPostForm-detail-design-ch07-test-plan_v1.1.md`   |

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
| 他画面詳細  | `B-02_BoardDetail-detail-design-ch00〜07`         | 編集モードの呼び出し元（詳細画面）との整合確認用。                         |

---

## 0.5 今後の執筆・更新方針

1. `B-03_BoardPostForm-detail-design-ch01-overview_v1.1.md` 以降、編集機能および追加要件（投稿者表示モード・添付仕様）を反映した詳細設計を順次更新する。
2. 特に ch03（データモデル）および ch04（ロジック）においては、新規投稿と編集の差異（初期値の扱い等）を明確に定義する。
3. ch05（UI）では、誤送信防止のためのプレビュー付き確認ダイアログの仕様を詳述する。