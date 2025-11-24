# B-02 BoardDetail 詳細設計書 ch07 テスト観点・UT/IT 方針 v1.1

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH07
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 7.1 本章の目的

本章では、BoardDetail コンポーネント（B-02）に対する **単体テスト（UT）** および簡易結合テスト（軽い IT）の観点を整理する。
試験の切り口は TKD 標準に従い、以下の 3 区分で定義する。

* 正常系: 正常な設計通りの挙動を確認する。
* 純異常系: アプリケーションレイヤでハンドリングされているエラー処理の挙動を確認する。
* 異常系: OS / ネットワーク断など危険な操作を伴う例外ケース。開発時の試験は **机上試験のみ** とする。

BoardDetail は「閲覧＋コメント投稿 UI」を担当し、投稿・編集・AI モデレーションロジックは B-03 BoardPostForm および API 側の責務とする。
AI モデレーションによるブロックは、BoardDetail からは「コメント送信失敗の一種」として扱う。

---

## 7.2 テスト対象範囲

### 7.2.1 対象コンポーネント

* `BoardDetailPage`
* `BoardDetailHeader`
* `BoardDetailContentSection`
* `BoardDetailAttachmentSection`
* `BoardDetailTranslationTtsSection`
* `BoardDetailCommentSection`
* `BoardDetailFooter`
* `BoardDetailPdfPreviewModal`

### 7.2.2 対象外

* AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider の単体テスト
* Supabase クライアントの接続テスト、RLS テスト（DB／インフラ側）
* BoardTop / BoardPostForm との結合シナリオ全体（それぞれの詳細設計 ch07 で扱う）
* AI モデレーションロジックそのもの（B-03 ch08 および API 側のテスト範囲）

---

## 7.3 テスト環境前提

* テストランナー: Jest
* UI テストヘルパ: React Testing Library（RTL）
* i18n:

  * StaticI18nProvider のテスト用ラッパで `t()` を利用するか、
  * i18n をモックして固定文言を返す。
* データアクセス:

  * `fetchBoardDetailPage` / `postBoardComment` / `deleteBoardPost` / `deleteBoardComment` など共通データアクセス API は **モック化** し、実際の Supabase 接続は行わない。
* ロール:

  * `viewerRole` は共通ロール定義の文字列（例: `"management"` / `"resident"` 等）を使用し、テスト内では意味が伝わるダミー値を用いる。

---

## 7.4 正常系テスト観点

### 7.4.1 初期表示（投稿詳細表示）

* 条件

  * `postId` に対応する投稿・コメント・添付データが正常に取得できるモックを用意する。
* 期待値

  * Header にカテゴリバッジ + タイトル + メタ情報（投稿者種別ラベル + 投稿日時）が表示される。
  * 本文セクションに `post.content` が表示されている。
  * 添付がある場合、添付セクションにファイル名一覧が表示されている。
  * コメントセクションにコメント件数分のアイテムが表示されている。
  * エラー状態・空状態（NotFound 等）は表示されない。

### 7.4.2 コメント入力・送信（投稿可能ロール）

* 条件

  * `viewerRole = "management"` など、コメント投稿権限を持つロールのテスト値を設定。
  * `canPostComment = true` の状態でレンダリング。
  * コメント投稿 API モックは正常に `ok: true` と `BoardCommentItem[]` を返す。
* 期待値

  * コメント入力欄と送信ボタンが表示されている。
  * テキスト入力後に送信ボタンをクリックすると、投稿 API が 1 回呼ばれる。
  * 成功後、入力欄が空になり、コメント一覧末尾に新しいコメントが追加される。

### 7.4.3 コメント入力欄の非表示（投稿不可ロール）

* 条件

  * `viewerRole = "resident"` など、投稿不可のロール値を設定。
  * `canPostComment = false` の状態でレンダリング。
* 期待値

  * コメント一覧は表示されるが、コメント入力欄・送信ボタンは表示されない。
  * `board.detail.comment.disabled` の文言（またはそれに相当する表示）が確認できる。

### 7.4.4 翻訳表示（翻訳済み）

* 条件

  * `i18nState.hasTranslation = true`、`translatedText` にテキストが入った状態のテストデータを用意。
* 期待値

  * 「翻訳・読み上げ」セクションで、翻訳タブに切り替えると翻訳済み本文が表示される。
  * 翻訳ボタン（「翻訳する」）は表示されない（既に翻訳済みのため）。

### 7.4.5 PDF プレビュー起動

* 条件

  * 添付に PDF ファイルが含まれているテストデータを用意。
* 期待値

  * 添付行をクリックすると PDF プレビューモーダルが表示される。
  * モーダル内に「閉じる」と「タップで閉じる」の文言が表示されている。

### 7.4.6 戻るボタン

* 条件

  * BoardDetailFooter の「掲示板に戻る」ボタンをクリック。
* 期待値

  * Router モックが `/board` への遷移を要求していることを確認する。

### 7.4.7 投稿削除（論理削除成功）

* 条件

  * 投稿削除ボタンが表示されるロール（管理組合 or 投稿者本人）でレンダリング。
  * 削除 API モック `deleteBoardPost` が `ok: true` を返す。
* 期待値

  * 削除ボタン押下で確認ダイアログが表示される。
  * 「はい」を選択すると削除 API が 1 回呼ばれる。
  * 成功後、BoardTop (`/board`) への遷移が要求される。

### 7.4.8 コメント削除（論理削除成功）

* 条件

  * コメント削除ボタンが表示されるロール（管理組合 or コメント投稿者本人）でレンダリング。
  * 削除 API モック `deleteBoardComment` が `ok: true` を返す。
* 期待値

  * コメント行の削除ボタン押下で確認ダイアログが表示される。
  * 「はい」を選択すると削除 API が 1 回呼ばれる。
  * 成功後、コメント一覧から該当コメントが消えている（再取得 or ローカル更新で反映）。

---

## 7.5 純異常系テスト観点（エラー処理）

### 7.5.1 投稿が存在しない（NotFound）

* 条件

  * `fetchBoardDetailPage` モックが「NotFound」種別のエラーを返す。
* 期待値

  * BoardDetailPage が「投稿が見つかりません」系のエラーメッセージ（ch05 で定義）を表示する。
  * 本文・添付・コメントセクションは表示されない。

### 7.5.2 閲覧権限不足（Forbidden）

* 条件

  * `fetchBoardDetailPage` モックが「Forbidden」種別のエラーを返す。
* 期待値

  * 「この投稿を閲覧する権限がありません」系のメッセージ（ch05 で定義）を表示する。
  * 本文・添付・コメントセクションは表示されない。

### 7.5.3 通常の取得エラー（ネットワーク/不明）

* 条件

  * `fetchBoardDetailPage` モックがネットワークエラー or 不明エラーを返す。
* 期待値

  * 一般的なエラーメッセージ（「掲示板を読み込めませんでした」等）が表示される。
  * 再読み込みボタンが表示され、クリック時に再度データ取得関数が呼ばれる。

### 7.5.4 コメント送信失敗（一般エラー）

* 条件

  * コメント投稿 API モック `postBoardComment` が `ok: false` かつ `errorCode = "network_error"` を返す。
* 期待値

  * コメント入力欄は残ったまま（ユーザの入力は消さない）。
  * 送信中フラグが解除される（ボタンが再度押下可能な状態）。
  * 「コメントの投稿に失敗しました…」メッセージ（`board.detail.comment.submit.error`）が表示される。

### 7.5.5 コメント送信失敗（AI モデレーションブロック）

* 条件

  * コメント投稿 API モック `postBoardComment` が `ok: false` かつ `errorCode = "ai_moderation_blocked"` を返す。
* 期待値

  * コメント入力欄は残ったまま（ユーザの入力は消さない）。
  * 送信中フラグが解除される。
  * モデレーション専用メッセージ `board.detail.comment.submit.moderationBlocked` が表示される。
  * AI モデルのスコアや理由は UI に表示されない。

### 7.5.6 翻訳エラー

* 条件

  * 翻訳 API モックがエラーを返す。
* 期待値

  * `i18nState.translationError` がセットされ、
  * 「翻訳に失敗しました。」メッセージ（`board.detail.i18n.error` 等）が表示される。

### 7.5.7 TTS エラー

* 条件

  * TTS API モックがエラーを返す。
* 期待値

  * `i18nState.ttsError` がセットされ、
  * 「読み上げに失敗しました。」メッセージ（`board.detail.tts.error` 等）が表示される。

### 7.5.8 投稿削除失敗

* 条件

  * 削除 API モック `deleteBoardPost` が `ok: false` を返す。
* 期待値

  * BoardTop には遷移せず、BoardDetail に留まる。
  * `board.detail.post.delete.error` が表示される。

### 7.5.9 コメント削除失敗

* 条件

  * 削除 API モック `deleteBoardComment` が `ok: false` を返す。
* 期待値

  * コメント一覧から該当コメントは消えない。
  * `board.detail.comment.delete.error` が表示される。

---

## 7.6 異常系テスト観点（机上試験）

OS レベルのプロセス強制終了やネットワーク断絶など、危険な操作を伴う異常は、開発時の実機テストでは行わず **机上試験のみ** とする。ここでは「発生しうる異常」と「期待されるアプリ側の振る舞い」を整理する。

### 7.6.1 ネットワーク断絶中のアクセス

* 想定異常

  * BoardDetail 表示中にネットワーク断が発生し、その状態で再読み込みを行う。
* 期待される挙動（机上）

  * 再取得はエラーとなり、エラー状態コンポーネントが表示される。
  * ログに `board.detail.fetch.error` が出力される。
  * ネットワーク復旧後、利用者が再度「再読み込み」ボタンを押すと、正常系のフェッチフローに戻る。

### 7.6.2 Supabase 一時障害

* 想定異常

  * Supabase 側の一時的な障害により、一定時間 5xx エラーが返される。
* 期待される挙動（机上）

  * エラー発生時にはエラー状態コンポーネントが表示される。
  * ログに `board.detail.fetch.error` が出力される。
  * 障害解消後に再度「再読み込み」を行えば正常に詳細が表示される。

※ これらの異常系は、E2E テストまたは本番運用での観測を通じて確認し、UT レベルでは再現しない前提とする。

---

## 7.7 ログ出力テスト観点

* ログ出力自体は共通 Logger のテスト範囲とし、BoardDetail 側では「適切なタイミングで Logger を呼び出しているか」を確認する。
* 観点例:

  * 正常系: 詳細取得開始時に `logInfo("board.detail.fetch.start", ...)` が 1 回呼ばれる。
  * 正常系: 詳細取得成功時に `logInfo("board.detail.fetch.success", ...)` が 1 回呼ばれる。
  * 純異常系: 詳細取得失敗時に `logError("board.detail.fetch.error", ...)` が 1 回呼ばれる。
  * 純異常系: コメント送信失敗時に `logError("board.detail.comment.error", ...)` が 1 回呼ばれる（モデレーションブロック含む）。
  * 純異常系: 翻訳/TTS エラー時に `logError("board.detail.translation.error" / "board.detail.tts.error", ...)` が呼ばれる。
  * 純異常系: 投稿・コメント削除失敗時に `logError("board.detail.post.delete.error" / "board.detail.comment.delete.error", ...)` が呼ばれる。
* Logger はモック化し、呼び出し回数と引数（`postId`, `viewerRole`, `errorType` など）が想定通りであることを検証する。

---

## 7.8 簡易結合テスト（IT）観点

* StaticI18nProvider で BoardDetail をラップしてレンダリングし、

  * 添付セクションタイトル
  * 翻訳/TTS セクションタイトル
  * コメントセクションの各メッセージ
    が期待する文言で表示されることを確認する。
* BoardTop → BoardDetail の遷移:

  * BoardTop のテストで `/board/[postId]` へのリンクが正しく機能していることを確認する。
* BoardDetail → BoardTop の戻り:

  * BoardDetailFooter の「掲示板に戻る」ボタンで `/board` に遷移要求を出していることを確認する。

---

## 7.9 テストケース管理

* 個別のテストケース ID・優先度・実施結果管理（スプレッドシート等）は、別途テスト計画書またはテストケース管理表で管理する。
* 本章は「BoardDetail で最低限カバーすべき観点」を列挙したものであり、必要に応じて詳細ケースを追加してよい。

本章 v1.1 は、B-02 ch01〜ch06 v1.1/1.2、および B-03/B-04 系詳細設計、AI モデレーション仕様に整合する形でテスト観点を定義している。変更や追加仕様が発生した場合は、本章を v1.2 以降に更新し、テスト観点を拡張する。
