# B-03 BoardPostForm 詳細設計書 ch05 メッセージ・UI 表示仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH05
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板投稿フォーム **B-03 BoardPostForm** における

* ラベル・プレースホルダ・補助テキスト
* バリデーションエラーメッセージ
* 投稿成功／失敗メッセージ
* 添付ファイル・回覧板に関する注意文言
* 翻訳・TTS 関連の表示（B-04 との関係は最小限）

を定義する。メッセージはすべて i18n キーとして定義し、実際の文言は StaticI18nProvider の辞書側で管理する。

---

## 5.2 ラベル・プレースホルダ

### 5.2.1 フィールド一覧と i18n キー

| UI 要素          | 役割               | i18n キー例                                       |
| -------------- | ---------------- | ---------------------------------------------- |
| 画面タイトル         | 新規投稿画面タイトル       | `board.postForm.title`                         |
| 投稿者ロールセクション見出し | 「投稿者」見出し         | `board.postForm.section.author`                |
| 投稿区分ラベル        | 「投稿区分」           | `board.postForm.field.category.label`          |
| 投稿区分プレースホルダ    | 「選択してください」       | `board.postForm.field.category.placeholder`    |
| 対象範囲ラベル        | 「宛先」             | `board.postForm.field.audience.label`          |
| タイトルラベル        | 「タイトル」           | `board.postForm.field.title.label`             |
| タイトルプレースホルダ    | 例: 「設備点検のお知らせ」   | `board.postForm.field.title.placeholder`       |
| 本文ラベル          | 「本文」             | `board.postForm.field.content.label`           |
| 本文プレースホルダ      | 例: 「本文を入力してください」 | `board.postForm.field.content.placeholder`     |
| 添付セクション見出し     | 「添付ファイル」         | `board.postForm.section.attachment`            |
| 添付ボタンラベル       | 「ファイルを選択」        | `board.postForm.button.attachPdf`              |
| 添付注意書き         | 「添付可能なファイル形式（PDF / Office ファイル）のみ選択できます。」   | `board.postForm.note.attachmentPdfOnly`        |
| 回覧板チェックラベル     | 「回覧板として扱う」       | `board.postForm.field.circulation.label`       |
| 回覧対象グループラベル    | 「回覧先グループ」        | `board.postForm.field.circulationGroups.label` |
| 回覧期限ラベル        | 「回覧期限」           | `board.postForm.field.circulationDue.label`    |
| 投稿ボタン          | 「投稿する」           | `board.postForm.button.submit`                 |
| キャンセルボタン       | 「キャンセル」          | `board.postForm.button.cancel`                 |

具体的な文言は多言語辞書で定義する。本章ではキーの粒度と用途のみを定義する。

---

## 5.3 バリデーションエラーメッセージ

### 5.3.1 エラー表示の基本方針

* 各フィールド単位でエラーメッセージを表示する。
* フォーム最上部または下部に、全体エラーのサマリを表示する。
* メッセージは i18n キーとして扱い、具体文言は辞書で定義する。

### 5.3.2 フィールド別エラーキー

| 条件                    | エラー種別    | i18n キー例                                      |
| --------------------- | -------- | --------------------------------------------- |
| 投稿区分が未選択              | 必須入力エラー  | `board.postForm.error.category.required`      |
| 対象範囲が GROUP だがグループ未選択 | 必須入力エラー  | `board.postForm.error.audienceGroup.required` |
| タイトルが空                | 必須入力エラー  | `board.postForm.error.title.required`         |
| タイトルが最大文字数を超過         | 桁数オーバー   | `board.postForm.error.title.maxLength`        |
| 本文が空                  | 必須入力エラー  | `board.postForm.error.content.required`       |
| 本文がエディタのダミー値のみ        | 無効な本文    | `board.postForm.error.content.invalid`        |
| 回覧板フラグ ON だが回覧対象が不適切  | 回覧設定エラー  | `board.postForm.error.circulation.invalid`    |
| 添付に PDF 以外のファイルを選択    | 添付形式エラー  | `board.postForm.error.attachment.pdfOnly`     |
| 添付ファイルサイズが上限を超過       | 添付サイズエラー | `board.postForm.error.attachment.tooLarge`    |

### 5.3.3 全体エラーサマリ

フォーム全体に対する代表的なエラーサマリメッセージを定義する。

| シナリオ               | i18n キー例                                  |
| ------------------ | ----------------------------------------- |
| 必須入力エラーが 1 件以上存在する | `board.postForm.error.summary.validation` |
| 添付ファイル関連エラーが存在する   | `board.postForm.error.summary.attachment` |
| サーバ側バリデーションエラー     | `board.postForm.error.summary.server`     |

---

## 5.4 投稿成功・失敗メッセージ

### 5.4.1 投稿成功時

* 投稿に成功した場合、B-03 BoardPostForm では基本的に B-02 BoardDetail へ遷移する。
* フォーム画面上に成功メッセージを表示するかどうかは B-02 側の仕様に委ねる。
* API レスポンスが成功（201/200）であれば、少なくとも以下のメッセージキーを利用可能とする。

| 用途       | i18n キー例                             |
| -------- | ------------------------------------ |
| 投稿完了トースト | `board.postForm.toast.submitSuccess` |

### 5.4.2 投稿失敗時

投稿 API の結果に応じて、次のようにメッセージキーを使い分ける。

| ステータス / エラー種別    | メッセージ内容の例          | i18n キー例                                 |
| ---------------- | ------------------ | ---------------------------------------- |
| 400 バリデーションエラー   | 入力内容に誤りがあります       | `board.postForm.error.submit.validation` |
| 401/403 認証・権限エラー | 認証が切れています／権限がありません | `board.postForm.error.submit.auth`       |
| 409 競合           | 他のユーザの更新と競合しました    | `board.postForm.error.submit.conflict`   |
| 500 サーバエラー       | サーバエラーが発生しました      | `board.postForm.error.submit.server`     |
| ネットワーク例外         | ネットワークエラーが発生しました   | `board.postForm.error.submit.network`    |

B-04 による翻訳失敗は、投稿の成功／失敗とは切り離されるため、BoardPostForm では投稿成功として扱い、翻訳失敗を直接表示しない。翻訳状況の表示は B-02 側で検討する。

---

## 5.5 添付ファイル・回覧板の注意文言

### 5.5.1 添付ファイル

掲示板投稿フォームでの添付ファイルに関する注意文言を定義する。

| 用途        | 内容の例                              | i18n キー例                                     |
| --------- | --------------------------------- | -------------------------------------------- |
| 添付セクション説明 | 「掲示板の投稿には関連する資料ファイルを添付できます。」」 | `board.postForm.note.attachment.description` |
| 添付形式制限    | 「添付可能なファイル形式は PDF / Office（Word / Excel / PowerPoint）などです。」            | `board.postForm.note.attachment.pdfOnly`     |
| 添付サイズ制限   | 「1 ファイルあたり xxMB まで添付できます。」        | `board.postForm.note.attachment.sizeLimit`   |
| プレビューに関する補足   | 「PDF は画面上でプレビューでき、それ以外のファイルはダウンロードして閲覧します。」 | `board.postForm.note.attachment.previewPdfOnly` |

サイズ上限の具体値は非機能要件に従い、実際の文言は辞書と揃える。

### 5.5.2 回覧板設定

回覧板に関するユーザ向け注意文言を定義する。

| 用途        | 内容の例                          | i18n キー例                                      |
| --------- | ----------------------------- | --------------------------------------------- |
| 回覧板チェック補足 | 「回覧板にすると、指定したグループに順番に回覧されます。」 | `board.postForm.note.circulation.description` |
| 回覧期限補足    | 「回覧期限を過ぎると、自動的に回覧完了として扱われます。」 | `board.postForm.note.circulation.due`         |

具体的な回覧フローの説明は B-02 / 管理者画面側の仕様書で詳細化し、本書では BoardPostForm 上で必要な最小限の補足にとどめる。

---

## 5.6 確認ダイアログのメッセージ

投稿ボタン押下後に表示する確認ダイアログのメッセージを定義する。

| 要素       | i18n キー例                               |
| -------- | -------------------------------------- |
| タイトル     | `board.postForm.confirm.submit.title`  |
| 本文       | `board.postForm.confirm.submit.body`   |
| 確定ボタンラベル | `board.postForm.confirm.submit.ok`     |
| キャンセルラベル | `board.postForm.confirm.submit.cancel` |

本文の例（日本語）:

> この内容で掲示板に投稿します。よろしいですか？

実際の文言は辞書側で定義し、本書ではキーの構造と役割のみを示す。

---

## 5.7 エリア別メッセージ配置

### 5.7.1 画面全体レイアウトとの関係

* エラーサマリ領域:

  * フォーム上部（画面タイトルの直下）に設置する。
  * 代表的なエラーを 1 行で表示し、詳細は各フィールド下のメッセージで補う。
* フィールド単位エラー:

  * 各入力フィールド直下に 1 行で表示する。
  * 余白とフォントサイズは HarmoNet 共通フォームコンポーネントに合わせる。

### 5.7.2 トースト通知

* 投稿成功時・サーバエラー時には、画面右上または下部にトースト通知を表示してもよい。
* トーストメッセージは共通トーストコンポーネントに委譲し、BoardPostForm は i18n キーのみ渡す。

---

## 5.8 テスト観点（メッセージ関連）

メッセージ仕様に関する主要なテスト観点を列挙する。詳細なテストケースは ch06 で定義する。

1. 必須フィールド未入力時に、対応するエラーメッセージキーが設定されること。
2. サーバが 400 / 500 などのステータスを返した場合、適切なエラーキーが `submitError` に設定されること。
3. 投稿成功時に成功トースト用の i18n キーが発行されること（必要に応じて）。
4. 添付ファイルエラー（形式・サイズ）時に、フィールド下とサマリの両方が期待どおりに表示されること。
5. 回覧板設定が不正な場合に、回覧専用のエラーキーが設定されること。

以上により、BoardPostForm におけるメッセージと UI 表示仕様を定義する。
