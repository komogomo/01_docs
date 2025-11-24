# B-01 BoardTop 詳細設計書 ch07 テスト観点・UT/IT 方針 v1.1

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH07
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 7.1 本章の目的

本章では、BoardTop コンポーネント（B-01）に対する **単体テスト（UT）** および簡易結合テスト（軽い IT）の観点を整理する。fileciteturn14file1
試験の切り口は TKD 標準に従い、以下の 3 区分で定義する。

* 正常系: 正常な設計通りの挙動を確認する。
* 純異常系: アプリケーションレイヤでハンドリングされているエラー処理の挙動を確認する。
* 異常系: OS / ネットワーク断など危険な操作を伴う例外ケース。開発時の試験は **机上試験のみ** とする。

v1.1 では、翻訳（i18n）および読み上げ（TTS）の UI を含めた観点を追加する。

---

## 7.2 テスト対象範囲

* 対象コンポーネント

  * `BoardTopPage`
  * `BoardTopHeader`
  * `BoardTopControls`（`BoardTabBar` / `BoardScopeFilter`）
  * `BoardPostSummaryList` / `BoardPostSummaryCard`
  * `BoardNewPostEntry`
  * `BoardEmptyState` / `BoardErrorState`
  * `BoardPagination`

* 対象外（別コンポーネントのテストで扱う）

  * AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider の単体テスト
  * Supabase クライアントの接続テスト、RLS テスト（DB／インフラ側）
  * BoardDetail / BoardPostForm との結合シナリオ（各詳細設計 ch07 で扱う）
  * 翻訳/TTS サービス（B-04）の詳細ロジック（B-04 側のテスト範囲）

---

## 7.3 テスト環境前提

* テストランナー: Jest
* UI テストヘルパ: React Testing Library（RTL）
* i18n:

  * StaticI18nProvider のテスト用ラッパで `t()` を利用するか、
  * i18n をモックして固定文言を返す。
* データアクセス:

  * `fetchBoardTopPage` など共通データアクセス API は **モック化** し、
    実際の Supabase 接続は行わない（UT レベルでは API コールを発生させない）。
* ロール:

  * `viewerRole` は共通ロール定義の文字列（例: `"management"` / `"resident"` 等）を使用し、テスト内では意味が伝わるダミー値を用いる。

---

## 7.4 正常系テスト観点

### 7.4.1 初期表示（正常）

* 条件

  * URL クエリなし、または `tab=all&scope=all&page=1&perPage=20` 相当。
  * データ取得モックが `posts` を 1 件以上返す（`totalCount >= 1`）。
* 期待値

  * タイトル「掲示板」が表示されている（`board.top.title`）。
  * タブ「すべて」が選択状態で表示されている。
  * 範囲フィルタ「すべて」が選択状態で表示されている。
  * `BoardPostSummaryCard` が `posts.length` 件表示されている。
  * 空状態・エラー状態はいずれも表示されていない。

### 7.4.2 タブ切替（正常）

* 条件

  * 初期状態から「お知らせ」タブ（例: `notice`）をクリック。
* 期待値

  * `tab` が `"notice"` に更新される。
  * `page` が 1 にリセットされる。
  * データ取得関数が `tab="notice"` で呼び出される（モックの引数で確認）。
  * Router モック上の URL が `?tab=notice` を含む値に更新される。

### 7.4.3 範囲切替（正常）

* 条件

  * 初期状態から `scope = "management"` など別スコープを選択。
* 期待値

  * `scope` が選択した値に更新される。
  * `page` が 1 にリセットされる。
  * データ取得関数が指定した `scope` で呼び出される。

### 7.4.4 ページング（正常）

* 条件

  * テストデータ: `totalCount = 45`, `perPage = 20`。
  * ページネーション上で「2」を選択。
* 期待値

  * ページネーションコンポーネント上に 1〜3 ページ分が表示される。
  * ページ 2 をクリックすると、`page = 2` でデータ取得関数が呼び出される。

### 7.4.5 新規投稿ボタン（投稿可能ロール）

* 条件

  * props で `canPost = true` を渡す。
* 期待値

  * 「新規投稿」ボタン（`board.top.newPost`）が表示される。
  * ボタンをクリックすると、新規投稿ハンドラ（BoardPostForm への遷移処理）が 1 回呼ばれる。

### 7.4.6 新規投稿ボタン（投稿不可ロール）

* 条件

  * props で `canPost = false` を渡す。
* 期待値

  * 「新規投稿」ボタンは表示されない。

### 7.4.7 翻訳キャッシュありのカード表示

* 条件

  * テストデータの 1 件について、

    * `baseLanguage = "ja"`
    * `currentLanguage = "en"`
    * `hasTranslation = true`
    * `translatedPreview` に値あり
      を設定。
* 期待値

  * カード本文には `translatedPreview` が表示されている。
  * 原文/翻訳切替リンク `board.top.i18n.viewOriginal` / `board.top.i18n.viewTranslated` が表示されている。
  * 切替リンクのクリックにより、表示文言が原文／翻訳で切り替わる。

### 7.4.8 翻訳キャッシュなしのカード表示

* 条件

  * テストデータの 1 件について、

    * `hasTranslation = false`
      を設定。
* 期待値

  * カード本文には `contentPreview`（原文サマリ）が表示されている。
  * 「翻訳」ボタン（`board.top.i18n.translate`）が表示されている。

### 7.4.9 翻訳ボタン押下（正常）

* 条件

  * `hasTranslation = false` のカードで、翻訳ボタン押下時に B-04 側の翻訳関数モックが正常完了するように設定。
* 期待値

  * ボタン押下で翻訳リクエスト関数が 1 回呼び出される。
  * 完了後に `hasTranslation = true` / `translatedPreview` を持つ新しいデータが反映され、カード本文が翻訳済みサマリに変わる。

### 7.4.10 TTS ボタン表示

* 条件

  * テストデータの 1 件について `isTtsAvailable = true` を設定。
* 期待値

  * カード内に TTS ボタン（`board.top.tts.play`）が表示されている。
  * `isTtsAvailable = false` のカードには TTS ボタンが表示されない。

---

## 7.5 純異常系テスト観点（エラー処理）

### 7.5.1 空状態（データなし）

* 条件

  * データ取得モックが `posts = []`, `totalCount = 0` を返す。
* 期待値

  * 空状態コンポーネント（`BoardEmptyState`）が表示される。

    * 見出し: `board.top.empty`
  * 投稿カードは 1 件も表示されない。
  * エラー状態コンポーネントは表示されない。

### 7.5.2 エラー状態（一覧取得エラー）

* 条件

  * データ取得モックが例外を throw する。
* 期待値

  * エラー状態コンポーネント（`BoardErrorState`）が表示される。

    * 見出し: `board.top.error.fetch`
    * 「再読み込み」ボタン: `board.top.error.retry`
  * 投稿カードは表示されない。
  * 「再読み込み」ボタンをクリックすると、データ取得関数が再度呼び出される。

### 7.5.3 翻訳キャッシュ取得エラー

* 条件

  * `fetchBoardTopPage` 内部で翻訳キャッシュ取得が失敗した場合を想定し、
    原文サマリのみを持つ `BoardPostSummary` を返すようにモックを設定する。
* 期待値

  * 原文サマリ（`contentPreview`）のみが表示される。
  * 翻訳ボタン（`board.top.i18n.translate`）が表示される。
  * 画面全体のエラー状態は表示されない（一覧表示は継続）。

### 7.5.4 翻訳ボタン押下時のエラー

* 条件

  * 翻訳ボタン押下時に B-04 側の翻訳関数モックがエラーを返すように設定。
* 期待値

  * カード本文は原文サマリ表示のまま変わらない。
  * 控えめなエラーメッセージ（例: `board.top.i18n.error`）が表示される。
  * 画面全体のエラー状態は表示されない。

### 7.5.5 TTS エラー

* 条件

  * TTS ボタン押下時に B-04 側の TTS 関数モックがエラーを返すように設定。
* 期待値

  * 再生中状態が解除される。
  * `board.top.tts.error` が表示される。

### 7.5.6 ログ出力（純異常系）

* 条件

  * データ取得モックが例外を throw する状態で BoardTop をレンダリング。
  * 共通 Logger をモック化しておく。
* 期待値

  * `logError("board.top.fetch.error", context)` が 1 回呼ばれる。
  * `context` には少なくとも `scope`, `page`, `viewerRole`, `errorType` が含まれる。

---

## 7.6 異常系テスト観点（机上試験）

v1.0 から内容は変更せず、翻訳/TTS の導入後も同じ方針を維持する。fileciteturn14file1
OS レベルのプロセス強制終了やネットワーク断絶など、危険な操作を伴う異常は、開発時の実機テストでは行わず **机上試験のみ** とする。

* ネットワーク断絶中のアクセス

  * 一覧取得はエラーとなり、エラー状態コンポーネント＋`board.top.fetch.error` ログが出力されることを期待。
* Supabase 一時障害

  * 一時的に 5xx が返された場合でも、復旧後に再読み込みを行えば正常系に戻ることを期待。

---

## 7.7 ログ出力テスト観点

* ログ出力自体は共通 Logger のテスト範囲とし、BoardTop 側では「適切なタイミングで Logger を呼んでいるか」を確認する。
* 観点例:

  * 正常系:

    * 一覧取得開始時: `logInfo("board.top.fetch.start", context)` が 1 回呼ばれる。
    * 一覧取得成功時: `logInfo("board.top.fetch.success", context)` が 1 回呼ばれる。
  * 純異常系:

    * 一覧取得失敗時: `logError("board.top.fetch.error", context)` が 1 回呼ばれる。

Logger はモック化し、呼び出し回数と引数（`viewerRole`, `scope`, `page`, `totalCount` など）が想定通りであることを検証する。

---

## 7.8 簡易結合テスト（IT）観点

* StaticI18nProvider で BoardTop をラップしてレンダリングし、

  * 画面タイトル
  * タブラベル
  * 範囲ラベル
  * 空／エラー状態のメッセージ
  * 翻訳ボタンラベル・TTS ボタンラベル
    が期待する文言で表示されることを確認する。
* HOME → BoardTop の遷移:

  * HOME 画面のテストで `/board` へのリンクが機能していることを確認する。
* BoardTop → BoardDetail の遷移:

  * BoardTop 側では「正しい URL 形式（`/board/[id]`）」に遷移要求を出しているかまで確認し、
    詳細画面側のテストで実データ表示を検証する。

---

## 7.9 テストケース管理

* 個別のテストケース ID・優先度・実施結果管理（スプレッドシート等）は、別途テスト計画書またはテストケース管理表で管理する。
* 本章は「BoardTop で最低限カバーすべき観点」を列挙したものであり、必要に応じて詳細ケースを追加してよい。

本章 v1.1 は、B-01 ch03/ch05 v1.1 および B-02/B-03/B-04 系詳細設計に整合する形で、翻訳/TTS を含めた BoardTop のテスト観点を定義している。
