# B-03 BoardPostForm 詳細設計書 ch05 メッセージ・UI 表示仕様 v1.2

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH05
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板投稿画面コンポーネント **BoardPostForm（B-03）** における

* ラベル・プレースホルダ・補助テキスト
* バリデーションエラーメッセージ
* 投稿成功／失敗メッセージ
* 添付ファイル・回覧板に関する注意文言
* 確認ダイアログ（プレビュー付き）の表示内容

を定義する。メッセージはすべて i18n キーとして定義し、実際の文言は StaticI18nProvider の辞書側で管理する。

---

## 5.2 ラベル・プレースホルダ

### 5.2.1 フィールド一覧と i18n キー

| UI 要素          | 役割               | i18n キー例                                       |
| -------------- | ---------------- | ---------------------------------------------- |
| 画面タイトル         | 新規/編集画面タイトル       | `board.postForm.title.new` / `board.postForm.title.edit` |
| 投稿者ロール見出し    | 「投稿者」見出し         | `board.postForm.section.author`                |
| **表示名モードラベル** | 「名前の表示」           | `board.postForm.field.displayName.label`       |
| **表示名: 匿名** | 選択肢「匿名で投稿」       | `board.postForm.option.anonymous`              |
| **表示名: ニックネーム** | 選択肢「ニックネームを表示」    | `board.postForm.option.nickname`               |
| 投稿区分ラベル        | 「投稿区分」           | `board.postForm.field.category.label`          |
| 投稿区分プレースホルダ    | 「選択してください」       | `board.postForm.field.category.placeholder`    |
| 対象範囲ラベル        | 「宛先」             | `board.postForm.field.audience.label`          |
| タイトルラベル        | 「タイトル」           | `board.postForm.field.title.label`             |
| タイトルプレースホルダ    | 例: 「設備点検のお知らせ」   | `board.postForm.field.title.placeholder`       |
| 本文ラベル          | 「本文」             | `board.postForm.field.content.label`           |
| 本文プレースホルダ      | 例: 「本文を入力してください」 | `board.postForm.field.content.placeholder`     |
| 添付セクション見出し     | 「添付ファイル」         | `board.postForm.section.attachment`            |
| 添付ボタンラベル       | 「ファイルを選択」        | `board.postForm.button.attachFile`             |
| 添付注意書き         | 「PDF / Word / Excel / PowerPoint ファイルを選択できます。」 | `board.postForm.note.attachmentAllowed`        |
| 回覧板チェックラベル     | 「回覧板として扱う」       | `board.postForm.field.circulation.label`       |
| 回覧対象グループラベル    | 「回覧先グループ」        | `board.postForm.field.circulationGroups.label` |
| 回覧期限ラベル        | 「回覧期限」           | `board.postForm.field.circulationDue.label`    |
| 投稿ボタン（新規）      | 「投稿する」           | `board.postForm.button.submit`                 |
| 保存ボタン（編集）      | 「保存する」           | `board.postForm.button.save`                   |
| キャンセルボタン       | 「キャンセル」          | `board.postForm.button.cancel`                 |

具体的な文言は多言語辞書で定義する。本章ではキーの粒度と用途のみを定義する。

---

## 5.3 バリデーションエラーメッセージ

### 5.3.1 エラー表示の基本方針

* 各フィールド単位でエラーメッセージを表示する。
* フォーム最上部または下部に、全体エラーのサマリを表示する。

### 5.3.2 フィールド別エラーキー

| 条件                    | エラー種別    | i18n キー例                                      |
| --------------------- | -------- | --------------------------------------------- |
| 投稿区分が未選択              | 必須入力エラー  | `board.postForm.error.category.required`      |
| **表示名モードが未選択** | 必須入力エラー  | `board.postForm.error.displayName.required`   |
| 対象範囲が GROUP だがグループ未選択 | 必須入力エラー  | `board.postForm.error.audienceGroup.required` |
| タイトルが空                | 必須入力エラー  | `board.postForm.error.title.required`         |
| タイトルが最大文字数を超過         | 桁数オーバー   | `board.postForm.error.title.maxLength`        |
| 本文が空                  | 必須入力エラー  | `board.postForm.error.content.required`       |
| 本文がエディタのダミー値のみ        | 無効な本文    | `board.postForm.error.content.invalid`        |
| 回覧板フラグ ON だが回覧対象が不適切  | 回覧設定エラー  | `board.postForm.error.circulation.invalid`    |
| 添付に許可外のファイルを選択        | 添付形式エラー  | `board.postForm.error.attachment.invalidType` |
| 添付ファイルサイズが上限を超過       | 添付サイズエラー | `board.postForm.error.attachment.tooLarge`    |

### 5.3.3 全体エラーサマリ

| シナリオ               | i18n キー例                                  |
| ------------------ | ----------------------------------------- |
| 必須入力エラーが 1 件以上存在する | `board.postForm.error.summary.validation` |
| 添付ファイル関連エラーが存在する   | `board.postForm.error.summary.attachment` |
| サーバ側バリデーションエラー     | `board.postForm.error.summary.server`     |

---

## 5.4 投稿成功・失敗メッセージ

### 5.4.1 成功時

* 投稿/保存完了時に表示するトーストメッセージ。

| 用途         | i18n キー例                             |
| ---------- | ------------------------------------ |
| 投稿完了トースト   | `board.postForm.toast.submitSuccess` |
| 編集保存完了トースト | `board.postForm.toast.saveSuccess`   |

### 5.4.2 失敗時

投稿 API の結果に応じて、次のようにメッセージキーを使い分ける。

| ステータス / エラー種別    | メッセージ内容の例          | i18n キー例                                 |
| ---------------- | ------------------ | ---------------------------------------- |
| 400 バリデーションエラー   | 入力内容に誤りがあります       | `board.postForm.error.submit.validation` |
| 401/403 認証・権限エラー | 認証が切れています／権限がありません | `board.postForm.error.submit.auth`       |
| 409 競合           | 他のユーザの更新と競合しました    | `board.postForm.error.submit.conflict`   |
| 500 サーバエラー       | サーバエラーが発生しました      | `board.postForm.error.submit.server`     |
| ネットワーク例外         | ネットワークエラーが発生しました   | `board.postForm.error.submit.network`    |

---

## 5.5 添付ファイル・回覧板の注意文言

### 5.5.1 添付ファイル

| 用途        | 内容の例                              | i18n キー例                                     |
| --------- | --------------------------------- | -------------------------------------------- |
| 添付セクション説明 | 「掲示板の投稿には関連する資料ファイルを添付できます。」」 | `board.postForm.note.attachment.description` |
| 添付形式制限    | 「PDF または Office ファイル（Word / Excel / PowerPoint）を選択できます。」 | `board.postForm.note.attachmentAllowed` |
| 添付サイズ制限   | 「1 ファイルあたり xxMB まで添付できます。」        | `board.postForm.note.attachment.sizeLimit`   |
| プレビューに関する補足   | 「PDF は画面上でプレビューでき、それ以外のファイルはダウンロードして閲覧します。」 | `board.postForm.note.attachment.previewNote` |

### 5.5.2 回覧板設定

| 用途        | 内容の例                          | i18n キー例                                      |
| --------- | ----------------------------- | --------------------------------------------- |
| 回覧板チェック補足 | 「回覧板にすると、指定したグループに順番に回覧されます。」 | `board.postForm.note.circulation.description` |
| 回覧期限補足    | 「回覧期限を過ぎると、自動的に回覧完了として扱われます。」 | `board.postForm.note.circulation.due`         |

---

## 5.6 確認ダイアログのメッセージ

投稿ボタン押下後に表示する確認ダイアログの仕様を定義する。
誤送信およびコミュニティ内トラブル防止のため、入力内容のプレビューと注意喚起を含める。

### 5.6.1 メッセージ・ラベル定義

| 要素       | i18n キー例                               | 備考 |
| -------- | -------------------------------------- | ---- |
| タイトル     | `board.postForm.confirm.submit.title`  | 「投稿内容の確認」 |
| 注意喚起文     | `board.postForm.confirm.submit.notice` | 「投稿内容は全住民（またはグループ）に公開されます。ご近所トラブル防止のため、内容をいま一度ご確認ください。」 |
| プレビューヘッダ: タイトル | `board.postForm.confirm.preview.title` | |
| プレビューヘッダ: カテゴリ | `board.postForm.confirm.preview.category` | |
| プレビューヘッダ: 本文 | `board.postForm.confirm.preview.content` | |
| プレビューヘッダ: 添付 | `board.postForm.confirm.preview.attachment` | |
| 確定ボタンラベル | `board.postForm.confirm.submit.ok`     | 「投稿する」または「保存する」 |
| キャンセルラベル | `board.postForm.confirm.submit.cancel` | 「キャンセル」 |

### 5.6.2 UI 構造

確認ダイアログは以下の要素を順に配置する（スクロール可能とする）。

1. **ダイアログタイトル**
2. **注意喚起メッセージ**（強調表示）
3. **プレビュー領域**（背景色あり）
   * **タイトル:** 入力されたタイトル
   * **カテゴリ:** 選択されたカテゴリ名（対象範囲含む）
   * **本文:** 入力された本文（簡易表示）
   * **添付ファイル:** ファイル名一覧（ある場合）
4. **アクションボタン**（キャンセル / 確定）

---

## 5.7 エリア別メッセージ配置

### 5.7.1 画面全体レイアウトとの関係

* エラーサマリ領域: フォーム上部（画面タイトルの直下）。
* フィールド単位エラー: 各入力フィールド直下。

### 5.7.2 トースト通知

* 投稿/保存成功時・サーバエラー時には、画面右上または下部にトースト通知を表示する。

---

## 5.8 テスト観点（メッセージ関連）

1. **表示名モード**: 未選択時に `board.postForm.error.displayName.required` が表示されること。
2. **編集モード**: 画面タイトルが編集用になり、ボタンが「保存する」になっていること。
3. **添付ファイル**: Office ファイル選択時にエラーにならず、不許可ファイル選択時に `invalidType` エラーが出ること。
4. **確認ダイアログ**: 投稿ボタン押下時にプレビューと注意喚起文言が表示されていること。

以上により、BoardPostForm におけるメッセージと UI 表示仕様を定義する。