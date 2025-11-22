# B-03 BoardPostForm 詳細設計書 ch06 テスト・品質保証設計 v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH06
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 6.1 本章の目的

本章では、掲示板投稿フォーム **B-03 BoardPostForm** に対するテストおよび品質保証の方針を定義する。

* ユニットテスト（React コンポーネント／ロジック）
* 結合テスト（BoardPostForm と投稿 API との連携）
* メッセージ／バリデーション仕様の検証
* ログ出力・フェイルソフト挙動の確認

を対象とし、テスト観点と代表的なテストケースを整理する。

---

## 6.2 テスト対象範囲

### 6.2.1 コンポーネント・モジュール

* `BoardPostForm` コンポーネント本体
* BoardPostForm が依存するロジック・フック

  * バリデーションロジック
  * フォーム状態管理ロジック
  * 添付ファイルハンドリング（選択・削除、アップロードトリガ）
  * 回覧板設定ロジック
* BoardPostForm から呼び出される投稿 API ラッパ

  * 例: `createBoardPost(request: CreateBoardPostRequest)`

翻訳・TTS の実際の動作は B-04 側のテストで扱い、BoardPostForm 側では

* 「投稿 API 呼び出しが成功／失敗した場合の UI 挙動」

に限定して確認する。

### 6.2.2 テスト環境

* テストランナー: Vitest（またはプロジェクト標準）
* コンポーネントテスト: React Testing Library
* 実行環境: Node.js + jsdom

---

## 6.3 ユニットテスト（コンポーネント単体）

### 6.3.1 初期表示

**目的:** 初期状態および固定 UI 要素が設計どおりであることを確認する。

代表テストケース:

1. 画面タイトルが `board.postForm.title` に対応するテキストで表示されること。
2. タイトル／本文／投稿区分／宛先／添付／回覧板のフィールドが表示されていること。
3. 初期状態で:

   * 必須マークが付与されているフィールド（投稿区分・タイトル・本文）が期待どおりであること。
   * エラー表示領域が空であること。
   * `isSubmitting = false` 相当の状態で、「投稿する」ボタンが有効であること。

### 6.3.2 入力とバリデーション

**目的:** ch04 の状態管理・バリデーション仕様および ch05 のメッセージ仕様に沿ってエラーが表示されることを確認する。

代表テストケース:

1. 投稿区分未選択で「投稿する」を押下した場合、

   * 該当フィールド下に `board.postForm.error.category.required` に対応するメッセージが表示されること。
   * 全体エラーサマリに `board.postForm.error.summary.validation` が表示されること。

2. 対象範囲 = GROUP かつグループ未選択で「投稿する」を押下した場合、

   * `board.postForm.error.audienceGroup.required` が表示されること。

3. タイトルが空の場合、

   * `board.postForm.error.title.required` が表示されること。

4. 本文が空、またはエディタのダミー値のみの場合、

   * `board.postForm.error.content.required` または `board.postForm.error.content.invalid` が表示されること。

5. 回覧板設定が不正（回覧板対象外カテゴリに対して回覧 ON など）の場合、

   * `board.postForm.error.circulation.invalid` が表示されること。

6. PDF 以外のファイル・許可されない拡張子を添付しようとした場合、

   * `board.postForm.error.attachment.pdfOnly` または許可形式エラー用キーが表示されること。

### 6.3.3 UI 状態遷移

**目的:** ボタン状態・確認ダイアログ・ローディング状態が正しく遷移することを確認する。

代表テストケース:

1. 入力が有効な状態で「投稿する」を押下した場合、

   * 確認ダイアログが表示されること。

2. 確認ダイアログで「キャンセル」を押下した場合、

   * ダイアログが閉じ、投稿 API は呼ばれないこと。

3. 確認ダイアログで「はい」を押下した場合、

   * 投稿 API ラッパが 1 回だけ呼び出されること。
   * `isSubmitting` が true になり、「投稿する」ボタンが disabled になること。

4. 投稿 API 呼び出し中に再度「投稿する」ボタンを押しても、追加の呼び出しが発生しないこと。

---

## 6.4 結合テスト（API 連携）

### 6.4.1 投稿成功ケース

**目的:** 投稿 API が成功した場合の画面挙動を確認する。

テストシナリオ:

1. 有効な入力を行い、「投稿する」→確認ダイアログ「はい」を選択する。
2. 投稿 API モックが `200/201` を返すように設定する。
3. 期待値:

   * エラーサマリおよびフィールドエラーが表示されないこと。
   * 投稿成功トースト用の i18n キー（`board.postForm.toast.submitSuccess`）が発行されるか、または親コンポーネントの `onSubmitSuccess(postId)` が呼ばれること。
   * 親コンポーネント経由で B-02 BoardDetail への遷移が行われること（遷移自体はモックで確認）。

### 6.4.2 投稿失敗ケース（HTTP ステータス別）

**目的:** 投稿 API のステータスコードに応じたエラーメッセージと UI 挙動を確認する。

代表テストケース:

1. 400 バリデーションエラー

   * API モックが 400 を返し、エラー内容を JSON で返す。
   * BoardPostForm が `board.postForm.error.submit.validation` を全体エラーとして設定し、必要に応じてフィールドエラーにマッピングすること。

2. 401/403 認証・権限エラー

   * `board.postForm.error.submit.auth` を表示し、必要であればログイン画面への遷移トリガを発行すること。

3. 409 競合

   * `board.postForm.error.submit.conflict` を表示すること。

4. 500 サーバエラー

   * `board.postForm.error.submit.server` を表示すること。

5. ネットワーク例外

   * API 呼び出しモックで例外を投げる。
   * BoardPostForm が `board.postForm.error.submit.network` を設定し、「再送する」ボタンを表示すること（存在する場合）。

### 6.4.3 再送動作

**目的:** ネットワークエラー後に再送が正しく動作することを確認する。

テストシナリオ:

1. 最初の投稿試行でネットワーク例外を発生させる。
2. エラー表示とともに「再送する」ボタンが表示されること。
3. 「再送する」押下時に、同一リクエスト内容で投稿 API が再呼び出しされること。

---

## 6.5 ログ出力確認

BoardPostForm から共通 Logger を呼び出す場合、以下のイベントが正しく出力されることを確認する。

代表イベント例:

1. フォーム表示時:

   * event: `"board.post.form_open"`
   * context: `{ tenantId, viewerUserId }`

2. 投稿ボタン押下時:

   * event: `"board.post.submit_click"`
   * context: `{ categoryTag, audienceType, isCirculation }`

3. 投稿成功時:

   * event: `"board.post.create_success"`
   * context: `{ postId, categoryTag, audienceType }`

4. 投稿失敗時:

   * event: `"board.post.create_failed"`
   * context: `{ errorCode, httpStatus }`

テストでは Logger をモックし、指定された event 名と context が渡されていることを確認する。

---

## 6.6 非機能観点（フォーム固有）

BoardPostForm に対する UI レベルの非機能観点として、以下を確認対象とする。

1. 入力応答性

   * 一般的な端末・ブラウザで、入力・スクロール・添付操作に対する応答がストレスなく行えること。

2. エラーメッセージの可読性

   * PC／スマホ両方で、エラーメッセージが折り返し時にも読みやすいフォントサイズ・行間になっていること。

3. アクセシビリティ（最低限）

   * エラーメッセージが入力フィールドと視覚的に近接して表示されること。
   * ラベルと入力が紐づいていること（label + input の構造）。

これらは主にデザインレビュー／動作確認のチェックリストとして扱い、自動テストの範囲外としてよい。

---

## 6.7 まとめ

本章では、B-03 BoardPostForm のテスト・品質保証方針として、

* ユニットテストでの初期表示・バリデーション・UI 状態遷移の確認
* 結合テストでの投稿 API 成功／失敗／再送動作の確認
* ログ出力・フェイルソフト挙動の検証

を定義した。実装時には、本章の観点に基づき Vitest／React Testing Library を用いてテストコードを整備し、掲示板投稿フォームの品質を担保する。
