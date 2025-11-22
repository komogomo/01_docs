# B-01 BoardTop 詳細設計書 ch05 UI 詳細仕様・メッセージ仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH05
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板TOP画面コンポーネント BoardTop（B-01）の **UI 詳細仕様** と **メッセージ仕様（含む i18n キー）** を定義する。
ch02 で定義したレイアウト構造および ch03/ch04 で定義したデータモデル・状態モデルに基づき、Windsurf が Tailwind + React で実装可能なレベルまで粒度を落とす。

UI トーンは HarmoNet 共通（やさしい・自然・控えめ、白基調、角丸 2xl、控えめなシャドウ）に準拠する。

---

## 5.2 画面全体構成（SP 基準）

### 5.2.1 要素の縦並び順

SP（スマートフォン）画面での縦並び順は次の通りとする（PC も基本的に同順）。

1. `BoardTopHeader`
2. `BoardTopControls`（`BoardTabBar` + `BoardScopeFilter`）
3. `BoardNewPostEntry`（管理組合ロールのみ表示）
4. `BoardPostSummarySection`

   * `BoardPostSummaryList`（通常）
   * `BoardEmptyState`（0件時）
   * `BoardErrorState`（エラー時）
   * `BoardPagination`

### 5.2.2 コンテナの基本スタイル（イメージ）

Tailwind を用いたスタイルのイメージ（厳密なクラス指定は実装時に微調整可）：

* 画面コンテナ: `flex flex-col gap-4 px-4 py-4 max-w-xl mx-auto`
* セクション間: `gap-3`〜`gap-4` 程度で適度な余白をとる。
* カード: `rounded-2xl shadow-sm border border-gray-100 bg-white p-4` をベースとし、内容に応じて行間・余白を調整。

---

## 5.3 BoardTopHeader（タイトル・説明）

### 5.3.1 表示項目

* タイトル行

  * 文言（日本語）: 「掲示板」
  * i18n キー（例）: `board.top.title`
* サブタイトル行

  * 文言（日本語）: 「管理組合からのお知らせや回覧板を一覧で確認できます。」
  * i18n キー（例）: `board.top.subtitle`

### 5.3.2 スタイル

* タイトル: `text-lg font-semibold` 相当（BIZ UD ゴシック前提）。
* サブタイトル: `text-sm text-gray-600` 相当で、2 行程度までの折り返しを許容。

---

## 5.4 BoardTopControls（タブ・範囲フィルタ）

### 5.4.1 BoardTabBar

#### 表示内容

タブは 3 つとし、ラベル・キーを以下のように定義する。

| タブキー     | ラベル（日本語） | i18n キー例               | 意味            |
| -------- | -------- | ---------------------- | ------------- |
| `all`    | すべて      | `board.top.tab.all`    | すべてのカテゴリの投稿   |
| `notice` | お知らせ     | `board.top.tab.notice` | 管理組合からのお知らせ系  |
| `rules`  | 規約・ルール   | `board.top.tab.rules`  | 規約・ルール関連のお知らせ |

#### スタイル

* SP: 横スクロール不要なタブバーを想定（3つ）。
* アクティブタブ: 下線または背景色で強調（例: `border-b-2` + アクセントカラー）。
* 非アクティブタブ: テキストカラー薄め（`text-gray-500`）でホバー時のみ濃くする。

### 5.4.2 BoardScopeFilter

#### 表示内容

範囲フィルタはドロップダウン（またはセグメントボタン）で表示し、ラベル・キーを以下とする。

| scope 値  | ラベル（日本語）  | i18n キー例                 | 意味                       |
| -------- | --------- | ------------------------ | ------------------------ |
| `all`    | すべて       | `board.top.scope.all`    | GLOBAL + 所属グループの投稿すべて    |
| `global` | 全体（全住民向け） | `board.top.scope.global` | 全テナント住民向け（GLOBAL）のお知らせのみ |
| `group`  | グループのみ    | `board.top.scope.group`  | 自分の所属グループ向け投稿のみ          |

#### スタイル

* SP: タブバーの右側または下側に配置し、ラベル＋▼アイコンのシンプルなドロップダウン。
* PC: タブバーと同じ行に右寄せで配置してもよい。

---

## 5.5 BoardNewPostEntry（新規投稿入口）

### 5.5.1 表示条件

* `canPost === true`（viewerRole = admin に相当）の場合のみ表示する。
* 一般利用者（viewerRole = `user`）には表示しない。

### 5.5.2 表示内容

* ラベル（日本語）: 「新規投稿」
* i18n キー例: `board.top.newPost.button`
* アクセシビリティ: ボタン role を持ち、スクリーンリーダーで「新規投稿」と読まれるようにする。

### 5.5.3 スタイル

* ボタン: 共通ボタンスタイル（Primary）を利用。

  * 例: `inline-flex items-center justify-center rounded-full px-4 py-2 text-sm font-medium` など。
* SP: タブ・範囲フィルタの直下にフル幅または中央寄せで配置。

### 5.5.4 動作

* クリック／タップ時に `onNewPost()` を発火し、

  * 投稿フォーム画面への遷移、または
  * 投稿フォームモーダルのオープン
    のどちらかを行う（実際の遷移方式は投稿フォーム詳細設計の方針に従う）。

---

## 5.6 BoardPostSummaryCard（投稿サマリカード）

### 5.6.1 カード構造

1. 1行目: カテゴリバッジ + （必要に応じて）回覧板アイコン
2. 2行目: タイトル
3. 3行目: メタ情報行（投稿者種別ラベル・投稿日時・既読状態アイコン（将来））
4. 4行目: 本文サマリ
5. 右上 or 下部: 添付ファイルアイコン（クリップ）

### 5.6.2 各項目の仕様

* カテゴリバッジ

  * 表示内容: `categoryName`
  * i18n キー: カテゴリマスタ側（静的 i18n）で定義。BoardTop 側は `categoryName` をそのまま表示。
  * スタイル: `text-xs rounded-full bg-gray-100 px-2 py-0.5` 程度。

* タイトル

  * 表示内容: `title`
  * スタイル: `text-sm font-semibold`。最大 2 行まで表示し、それ以上は `...` で省略。

* メタ情報行

  * 表示内容（例）: 「管理組合 ・ 2025/01/23 18:30」

    * 投稿者種別ラベル: `authorDisplayType`（例: 「管理組合」「一般利用者」）。

      * i18n キー例: `board.common.authorType.admin`, `board.common.authorType.user`
    * 日時表示: `createdAt` をローカルフォーマット（YYYY/MM/DD HH:MM）に整形。
  * スタイル: `text-xs text-gray-500`。

* 本文サマリ

  * 表示内容: `contentPreview`
  * サマリ生成ルール（ch03 に基づく）:

    * 本文先頭から一定文字数（例: 80〜120文字）までを抽出。
    * 改行はスペースに変換。
    * 途中で切れた場合は `…` を付与。
  * スタイル: `text-xs text-gray-700 mt-1`。最大 3 行程度で省略。

* 添付ファイルアイコン

  * 表示条件: `hasAttachment === true` の場合のみ表示。
  * アイコン: クリップアイコン（共通アイコンセットから選定）。
  * i18n 用 title 属性例: `board.top.attachment.tooltip`（日本語: 「添付ファイルあり」）。

### 5.6.3 カード全体のインタラクション

* カード全体をタップ／クリックすると、投稿詳細画面 `/board/[id]` へ遷移する。
* ホバー時（PC）:

  * わずかにシャドウを強める or 境界線色を濃くする程度の控えめなフィードバック。

---

## 5.7 空状態・エラー状態の表示

### 5.7.1 空状態（BoardEmptyState）

* 表示条件: `items.length === 0 && !isError && !isLoading`。
* 文言（日本語例）:

  * 見出し: 「表示できる投稿がありません」
  * 補足文: 「選択した条件に該当する掲示板投稿はありません。」
* i18n キー例:

  * `board.top.empty.title`
  * `board.top.empty.description`
* スタイル:

  * アイコン（薄い情報アイコン）＋テキストを中央寄せ表示。
  * `py-8 text-center text-sm text-gray-500` 程度。

### 5.7.2 エラー状態（BoardErrorState）

* 表示条件: `isError === true`。
* 文言（日本語例）:

  * 見出し: 「掲示板を読み込めませんでした」
  * 補足文: 「通信状況をご確認のうえ、もう一度お試しください。」
* ボタン:

  * ラベル: 「再読み込み」
  * i18n キー例:

    * `board.top.error.title`
    * `board.top.error.description`
    * `board.top.error.retry`
* 動作:

  * ボタン押下で `onRetry()` を呼び出し、`RELOAD_REQUESTED` イベントを発火させる。

---

## 5.8 メッセージ・i18n キー一覧（BoardTop）

BoardTop で新規に定義する静的 i18n キーの一覧を次に示す（日本語版は例）。

| 用途           | i18n キー                         | 日本語例                       |
| ------------ | ------------------------------- | -------------------------- |
| 画面タイトル       | `board.top.title`               | 掲示板                        |
| サブタイトル       | `board.top.subtitle`            | 管理組合からのお知らせや回覧板を一覧で確認できます。 |
| タブ: すべて      | `board.top.tab.all`             | すべて                        |
| タブ: お知らせ     | `board.top.tab.notice`          | お知らせ                       |
| タブ: 規約・ルール   | `board.top.tab.rules`           | 規約・ルール                     |
| 範囲: すべて      | `board.top.scope.all`           | すべて                        |
| 範囲: 全体       | `board.top.scope.global`        | 全体（全住民向け）                  |
| 範囲: グループ     | `board.top.scope.group`         | グループのみ                     |
| 新規投稿ボタン      | `board.top.newPost.button`      | 新規投稿                       |
| 添付ありツールチップ   | `board.top.attachment.tooltip`  | 添付ファイルあり                   |
| 空状態タイトル      | `board.top.empty.title`         | 表示できる投稿がありません              |
| 空状態説明        | `board.top.empty.description`   | 選択した条件に該当する掲示板投稿はありません。    |
| エラータイトル      | `board.top.error.title`         | 掲示板を読み込めませんでした             |
| エラー説明        | `board.top.error.description`   | 通信状況をご確認のうえ、もう一度お試しください。   |
| エラー再試行ボタン    | `board.top.error.retry`         | 再読み込み                      |
| 投稿者種別: 管理組合  | `board.common.authorType.admin` | 管理組合                       |
| 投稿者種別: 一般利用者 | `board.common.authorType.user`  | 一般利用者                      |

※ 実際の i18n ファイルでは、StaticI18nProvider の構造に合わせてネスト定義を行う。

---

## 5.9 アクセシビリティとフォーカス制御

* 主要な操作要素（タブ・範囲フィルタ・新規投稿ボタン・カード・再読み込みボタン）はすべてキーボード操作（Tab キー）でフォーカスできること。
* タブは ARIA ロール `tablist` / `tab` を用いて実装することが望ましい（実装コストとのバランスを見て判断）。
* エラー状態・空状態の見出しは `role="status"` などを利用し、スクリーンリーダーで認識しやすくすることを検討する。

---

## 5.10 Windsurf 実装時の注意点

1. Tailwind クラスは本章の方針をベースにしつつ、実機プレビュー（SP/PC）でバランスを確認して微調整してよい。ただし、カードのトーン（白基調・角丸 2xl・シャドウ控えめ）は崩さないこと。
2. i18n キーは本一覧に従い、StaticI18nProvider の辞書ファイルに追加する。キー名や階層を変更する場合は、詳細設計書側も更新すること。
3. メッセージ文言は、設計書の日本語を基準とし、実装時に微修正が必要な場合は TKD と相談のうえで反映すること。
4. ロール別 UI（新規投稿ボタンの表示/非表示など）は、`viewerRole` / `canPost` の値にのみ依存させ、ロール判定ロジックを BoardTop 内に書かないこと。
