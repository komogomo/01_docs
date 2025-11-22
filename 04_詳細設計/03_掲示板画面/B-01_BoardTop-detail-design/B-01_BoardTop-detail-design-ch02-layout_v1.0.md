# B-01 BoardTop 詳細設計書 ch02 画面構造・コンポーネント構成 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH02
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 2.1 レイアウト全体構成

### 2.1.1 画面レイアウト概要

BoardTop は、HarmoNet 共通レイアウト（AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider）配下の「メインコンテンツ領域」に表示される。
レイアウト階層（論理レベル）は次の通りとする。

* `RootLayout`（アプリ共通レイアウト）

  * `AppHeader`（共通ヘッダー）
  * `Main` コンテンツ領域

    * `BoardTopPage`（本コンポーネントのページコンテナ）
  * `AppFooter`（共通フッター）

LanguageSwitch / StaticI18nProvider は、RootLayout 側で既に適用されている前提とし、本章では BoardTop 固有部分のみを対象とする。

### 2.1.2 BoardTop 内部構造

`BoardTopPage` 配下の構造は以下の通りとする。

* `BoardTopPage`

  * `BoardTopHeader`（画面タイトル・説明テキスト）
  * `BoardTopControls`（タブ＋範囲フィルタの操作領域）

    * `BoardTabBar`
    * `BoardScopeFilter`
  * `BoardPostSummarySection`（一覧とページングのまとめ領域）

    * `BoardPostSummaryList`（カードリスト本体）

      * `BoardPostSummaryCard`（単一投稿カード、複数）
    * `BoardEmptyState`（対象件数 0 件時のみ）
    * `BoardErrorState`（取得エラー時のみ）
    * `BoardPagination`（ページネーション＋件数セレクタ）

なお、新規投稿の入口（ボタン）は、掲示板基本設計 ch03 の方針に従い、BoardTop 内に配置する。具体的な位置（上部ボタン / 右下 FAB 等）は UI 仕様（ch05）で詳細定義するが、本章では `BoardNewPostEntry` として論理コンポーネントを定義しておく。

* `BoardTopPage`

  * ...上記構成に加え、`BoardNewPostEntry`（新規投稿ボタン）を適切な位置に配置

---

## 2.2 主要コンポーネントの役割

### 2.2.1 BoardTopPage

* 役割:

  * URL `/board` に対応するトップレベルコンポーネント。
  * クエリパラメータ（`tab`, `scope`, `page`, `perPage`）を解釈し、内部状態の初期値を決定する。
  * Supabase 経由で掲示板投稿一覧データの取得処理を起動し、ローディング・成功・空・エラーの各状態に応じて子コンポーネントを出し分ける。
  * 新規投稿画面（またはモーダル）への遷移トリガ（`BoardNewPostEntry`）を提供する。

### 2.2.2 BoardTopHeader

* 役割:

  * 画面タイトル（例: 「掲示板」）とサブタイトル（例: 「管理組合からのお知らせや回覧板を一覧で確認できます。」）を表示する。
  * レスポンシブに対応し、SP では 1 カラム・PC では余白を広めにとった中央寄せレイアウトとする。

### 2.2.3 BoardTopControls（BoardTabBar / BoardScopeFilter）

* `BoardTopControls` は、タブと範囲フィルタをまとめて配置するコンテナとする。

* `BoardTabBar`

  * タブ: `ALL`, `NOTICE`, `RULES`（基本設計 ch03 に準拠）。
  * 選択中タブを視覚的に強調し、タブ切替時に BoardTopPage へイベントを通知する。

* `BoardScopeFilter`

  * 範囲: `ALL`（= GLOBAL + 所属グループ）, `GLOBAL`, `GROUP` など基本設計で定義された値を切り替えるドロップダウンまたはセグメントコントロール。
  * 範囲変更時に BoardTopPage へイベントを通知し、ページ番号を 1 にリセットする。

### 2.2.4 BoardPostSummarySection

* 一覧表示とページネーションをまとめて扱うセクションコンテナ。
  次の要素を縦方向に並べる。

1. `BoardPostSummaryList`

   * 取得済みの投稿配列を受け取り、`BoardPostSummaryCard` を列挙して表示する。
2. `BoardEmptyState`

   * 投稿件数が 0 件のときのみ表示。条件式は ch04 状態管理で定義する。
3. `BoardErrorState`

   * API 取得に失敗した場合のみ表示。エラー内容に応じてメッセージを切替えるかどうかは ch05 で定義。
4. `BoardPagination`

   * 現在ページ・総ページ数・表示件数選択などを表示し、ページ変更イベントを BoardTopPage に通知する。

### 2.2.5 BoardPostSummaryCard

* 単一の掲示板投稿をカード形式で表示するコンポーネント。
  含まれる要素（詳細は ch05 で定義予定）：

* カテゴリバッジ（お知らせ / 規約 / 回覧板 など）

* タイトル（1〜2 行で折り返し）

* メタ情報行（投稿者種別・投稿日時・既読/未読アイコン 等）

* 本文サマリ（冒頭数行）

* 添付ファイル有無アイコン（クリップ）

* ピン留めアイコン（必要な場合）

カード全体をタップ / クリックすると、投稿詳細画面 `/board/[id]` へ遷移する。

### 2.2.6 BoardNewPostEntry

* 役割:

  * 権限を持つユーザ（管理組合ロールなど）のみ、「新規投稿」入口を表示する。
  * 表示位置・形状（ボタン / FAB）は ch05 で詳細に定義するが、イベントとしては「新規投稿画面への遷移」または「投稿フォームモーダルのオープン」を BoardTopPage に通知する。

---

## 2.3 ルーティングとクエリパラメータ

### 2.3.1 ルーティング

* パス: `/board`
* HTTP メソッド: GET（画面表示）
* 認証: MagicLink 認証済みユーザのみ。未認証の場合は `/login` へリダイレクト（アプリ共通仕様）。

### 2.3.2 クエリパラメータ

BoardTop は、以下のクエリパラメータをサポートする。
不正値が指定された場合は、最寄りのデフォルト値へフォールバックする。

| パラメータ     | 型      | 許可値                        | デフォルト | 用途                     |
| --------- | ------ | -------------------------- | ----- | ---------------------- |
| `tab`     | string | `all` / `notice` / `rules` | `all` | 表示タブ種別の選択              |
| `scope`   | string | `all` / `global` / `group` | `all` | 表示範囲（GLOBAL / GROUP 等） |
| `page`    | number | 1 以上の整数                    | `1`   | 現在ページ番号                |
| `perPage` | number | 10 / 20 / 50               | `20`  | 1 ページあたり表示件数           |

クエリパラメータは、URL 直打ち・ブックマーク・HOME からの遷移など複数経路で利用される可能性があるため、BoardTopPage 初期化時に以下のルールで解釈する。

1. `tab` / `scope` / `page` / `perPage` を URL から読み込む。
2. 各値が許容値か検証し、不正な場合はデフォルト値へ丸める。
3. 内部状態（ch04 で定義）へ反映し、その状態に基づいて一覧取得クエリを発行する。

ページ遷移やタブ切替などで状態が変化した場合は、URL のクエリパラメータも同期更新する（ブラウザの戻るボタンで状態が戻るようにする）。

---

## 2.4 レスポンシブレイアウト方針

### 2.4.1 SP（スマートフォン）

* 1 カラムレイアウトを基本とし、要素の縦積み順序は次の通り。

  1. `BoardTopHeader`
  2. `BoardTopControls`（タブ＋範囲フィルタ）
  3. `BoardNewPostEntry`（必要な場合）
  4. `BoardPostSummarySection`（一覧・空/エラー・ページング）
* タブやフィルタは横スクロール不要な幅に収める（必要に応じてラップ）。
* カード幅は画面幅 − 両側の安全マージン（例: 16px）とし、指でのタップ操作を優先した余白を確保する。

### 2.4.2 PC（デスクトップ）

* コンテンツ最大幅を制限し（例: 960〜1200px）、左右に十分な余白を確保する。
* レイアウト順序は SP と同一とし、PC 専用の複雑なレイアウト分岐は行わない（実装・設計のシンプルさを優先）。
* タブバーやフィルタは横並び配置とし、見出しと一体感のあるデザインとする（具体値は ch05）。

---

## 2.5 コンポーネント間の依存関係

### 2.5.1 依存関係概要

BoardTop 内のコンポーネント間依存をテキストで定義する。

* `BoardTopPage`

  * クエリパラメータと内部状態を管理し、Supabase からのデータ取得を行う。
  * 子コンポーネントに対して、現在のタブ・範囲・ページ情報・投稿一覧・ローディング／エラー状態などを props で渡す。

* `BoardTabBar`

  * 表示専用 + 入力イベント通知。
    props: 現在タブ, onChangeTab(tab: TabType)

* `BoardScopeFilter`

  * 表示専用 + 入力イベント通知。
    props: 現在範囲, onChangeScope(scope: ScopeType)

* `BoardPostSummaryList`

  * 表示専用。
    props: 投稿配列, onSelectPost(postId: string)

* `BoardEmptyState` / `BoardErrorState`

  * 表示専用。
    props: メッセージ／再読み込みハンドラ（ErrorState のみ）

* `BoardPagination`

  * 表示 + 入力イベント通知。
    props: 現在ページ, 総ページ数, perPage, onChangePage, onChangePerPage

* `BoardNewPostEntry`

  * 表示制御 + 入力イベント通知。
    props: canPost (boolean), onNewPost()

### 2.5.2 外部依存

BoardTop は、次の外部要素に依存するが、その具体実装は本章では扱わない（該当章・別文書で定義）。

* Supabase クライアントおよび `board_posts` 向けのリポジトリ／フック
  → ch03 データモデル・入出力仕様 / 共通データアクセス層の詳細設計
* 認証コンテキスト（現在ユーザ・tenant_id・ロール）
  → 認証基盤・共通レイアウト側の仕様
* ルーティング機構（Next.js App Router の `Link` / `router.push` 等）
  → 実装時に Next.js 公式推奨に従う。詳細は ch06 結合で扱う。

以上により、BoardTop の画面構造とコンポーネント構成の論理レベルを定義する。詳細な props 型定義や Tailwind クラス、イベントハンドラの具体シグネチャは、ch03〜ch05 で記述する。
