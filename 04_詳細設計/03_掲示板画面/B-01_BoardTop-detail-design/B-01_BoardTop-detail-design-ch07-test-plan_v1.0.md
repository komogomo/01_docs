# B-01 BoardTop 詳細設計書 ch07 テスト観点・UT/IT 方針 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH07  
**Version:** 1.0  
**Supersedes:** -  
**Created:** 2025-11-22  
**Updated:** 2025-11-22  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** Draft

---

## 7.1 本章の目的

本章では、BoardTop コンポーネント（B-01）に対する **単体テスト（UT）** および簡易結合テスト（軽い IT）の観点を整理する。  
試験の切り口は TKD 標準に従い、以下の 3 区分で定義する。

- 正常系: 正常な設計通りの挙動を確認する。
- 純異常系: アプリケーションレイヤでハンドリングされているエラー処理の挙動を確認する。
- 異常系: OS / ネットワーク断など危険な操作を伴う例外ケース。開発時の試験は **机上試験のみ** とする。

---

## 7.2 テスト対象範囲

- 対象コンポーネント
  - `BoardTopPage`
  - `BoardTopHeader`
  - `BoardTopControls`（`BoardTabBar` / `BoardScopeFilter`）
  - `BoardPostSummaryList` / `BoardPostSummaryCard`
  - `BoardNewPostEntry`
  - `BoardEmptyState` / `BoardErrorState`
  - `BoardPagination`

- 対象外（別コンポーネントのテストで扱う）
  - AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider の単体テスト
  - Supabase クライアントの接続テスト、RLS テスト（DB／インフラ側）
  - BoardDetail / PostForm との結合シナリオ（各詳細設計 ch07 で扱う）

---

## 7.3 テスト環境前提

- テストランナー: Jest
- UI テストヘルパ: React Testing Library（RTL）
- i18n:
  - StaticI18nProvider のテスト用ラッパで `t()` を利用するか、  
    または i18n をモックして固定文言を返す。
- データアクセス:
  - `fetchBoardTopPage` など共通データアクセス API は **モック化** し、  
    実際の Supabase 接続は行わない（UT レベルでは API コールを発生させない）。

---

## 7.4 正常系テスト観点

正常なシナリオで設計通りに動作することを確認する。

### 7.4.1 初期表示（正常）

- 条件
  - URL クエリなし、または `tab=all&scope=all&page=1&perPage=20` 相当。
  - データ取得モックが `items` を 1 件以上返す（`totalCount >= 1`）。
- 期待値
  - タイトル「掲示板」が表示されている。
  - タブ「すべて」が選択状態で表示されている。
  - 範囲フィルタ「すべて」が選択状態で表示されている。
  - `BoardPostSummaryCard` が `items.length` 件表示されている。
  - 空状態・エラー状態はいずれも表示されていない。

### 7.4.2 タブ切替（正常）

- 条件
  - 初期状態から「お知らせ」タブ（`notice`）をクリック。
- 期待値
  - `tab` が `"notice"` に更新される。
  - `page` が 1 にリセットされる。
  - データ取得関数が `tab="notice"` で呼び出される（モックの引数で確認）。
  - Router モック上の URL が `?tab=notice` を含む値に更新される。

### 7.4.3 範囲切替（正常）

- 条件
  - 初期状態から `scope = "global"` を選択。
- 期待値
  - `scope` が `"global"` に更新される。
  - `page` が 1 にリセットされる。
  - データ取得関数が `scope="global"` で呼び出される。

### 7.4.4 ページング（正常）

- 条件
  - テストデータ: `totalCount = 45`, `perPage = 20`。
  - ページネーション上で「2」を選択。
- 期待値
  - ページネーションコンポーネント上に 1〜3 ページ分が表示される。
  - ページ 2 をクリックすると、`page = 2` でデータ取得関数が呼び出される。

### 7.4.5 新規投稿ボタン（管理組合ロール・正常）

- 条件
  - props で `viewerRole = "admin"`, `canPost = true` を渡す。
- 期待値
  - 「新規投稿」ボタンが表示される。
  - ボタンをクリックすると `onNewPost` ハンドラが 1 回呼ばれる。

### 7.4.6 新規投稿ボタン（一般利用者・正常）

- 条件
  - props で `viewerRole = "user"`, `canPost = false` を渡す。
- 期待値
  - 「新規投稿」ボタンは表示されない。

---

## 7.5 純異常系テスト観点（エラー処理）

アプリケーションでハンドリングしているエラー処理の挙動を確認する。

### 7.5.1 空状態（データなし）

- 条件
  - データ取得モックが `items = []`, `totalCount = 0` を返す。
- 期待値
  - 空状態コンポーネント（`BoardEmptyState`）が表示される。
    - 見出し: `board.top.empty.title`
    - 説明文: `board.top.empty.description`
  - 投稿カードは 1 件も表示されない。
  - エラー状態コンポーネントは表示されない。

### 7.5.2 エラー状態（取得エラー）

- 条件
  - データ取得モックが例外を throw する。
- 期待値
  - エラー状態コンポーネント（`BoardErrorState`）が表示される。
    - 見出し: `board.top.error.title`
    - 説明文: `board.top.error.description`
    - 「再読み込み」ボタン: `board.top.error.retry`
  - 投稿カードは表示されない。
  - 「再読み込み」ボタンをクリックすると、データ取得関数が再度呼び出される。

### 7.5.3 ログ出力（純異常系）

- 条件
  - データ取得モックが例外を throw する状態で BoardTop をレンダリング。
  - 共通 Logger をモック化しておく。
- 期待値
  - `logError("board.top.fetch.error", context)` が 1 回呼ばれる。
  - `context` には少なくとも `tab`, `scope`, `page`, `perPage`, `viewerRole`, `errorType` が含まれる。

---

## 7.6 異常系テスト観点（机上試験）

OS レベルのプロセス強制終了やネットワーク断絶など、危険な操作を伴う異常は、開発時の実機テストでは行わず **机上試験のみ** とする。  
ここでは「発生しうる異常」と「期待されるアプリ側の振る舞い」を整理する。

### 7.6.1 ネットワーク断絶中のアクセス

- 想定異常
  - アプリ起動中にネットワーク断が発生し、その状態で BoardTop の一覧取得が行われる。
- 期待される挙動（机上）
  - データ取得はエラーとなり、エラー状態コンポーネントが表示される。
  - ログに `board.top.fetch.error` が出力される。
  - ネットワーク復旧後、利用者が「再読み込み」ボタンを押すと、正常系のフェッチフローに戻る。

### 7.6.2 Supabase 一時障害

- 想定異常
  - Supabase 側の一時的な障害により、一定時間 5xx エラーが返される。
- 期待される挙動（机上）
  - エラー発生時にはエラー状態コンポーネントが表示される。
  - ログに `board.top.fetch.error` が出力される。
  - 障害解消後に再度「再読み込み」を行えば正常に一覧が表示される。

※ これらの異常系は、E2E テストまたは本番運用での観測を通じて確認し、UT レベルでは再現しない前提とする。

---

## 7.7 ログ出力テスト観点

ログそのもののフォーマットや出力先は共通 Logger 側のテスト範囲とし、BoardTop では「適切なタイミングで Logger を呼んでいるか」を確認する。

- 正常系
  - 一覧取得開始時: `logInfo("board.top.fetch.start", context)` が 1 回呼ばれる。
  - 一覧取得成功時: `logInfo("board.top.fetch.success", context)` が 1 回呼ばれる。
- 純異常系
  - 一覧取得失敗時: `logError("board.top.fetch.error", context)` が 1 回呼ばれる。

Logger はモック化し、呼び出し回数と引数（`viewerRole`, `tab`, `scope`, `page`, `perPage`, `totalCount` など）が想定通りであることを検証する。

---

## 7.8 簡易結合テスト（IT）観点

- StaticI18nProvider で BoardTop をラップしてレンダリングし、  
  - 画面タイトル  
  - タブラベル  
  - 範囲ラベル  
  - 空／エラー状態のメッセージ  
  がいずれも期待する文言で表示されることを確認する。
- HOME → BoardTop の遷移:
  - HOME 画面のテストで `/board` へのリンクが機能していることを確認する。
- BoardTop → BoardDetail の遷移:
  - BoardTop 側では「正しい URL 形式（`/board/[id]`）」に遷移要求を出しているかまで確認し、  
    詳細画面側のテストで実データ表示を検証する。

---

## 7.9 テストケース管理

- 個別のテストケース ID・優先度・実施結果管理（スプレッドシート等）は、別途テスト計画書またはテストケース管理表で管理する。
- 本章は「BoardTop で最低限カバーすべき観点」を列挙したものであり、必要に応じて詳細ケースを追加してよい。
