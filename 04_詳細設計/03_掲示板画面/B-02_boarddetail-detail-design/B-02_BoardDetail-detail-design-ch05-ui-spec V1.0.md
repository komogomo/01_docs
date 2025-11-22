# B-02 BoardDetail 詳細設計書 ch05 UI 詳細仕様・メッセージ仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH05
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板詳細画面コンポーネント BoardDetail（B-02）の **UI 詳細仕様** と **メッセージ仕様（含む i18n キー）** を定義する。
ch02 で定義したレイアウト構造および ch03/ch04 で定義したデータモデル・状態モデルに基づき、Windsurf が Tailwind + React で実装可能なレベルまで粒度を落とす。

UI トーンは HarmoNet 共通（やさしい・自然・控えめ、白基調、角丸 2xl、控えめなシャドウ）に準拠し、BoardTop（B-01）との一貫性を維持する。

---

## 5.2 画面全体構成（SP 基準）

### 5.2.1 要素の縦並び順

SP（スマートフォン）画面での縦並び順は次の通りとする（PC も基本的に同順）。

1. `BoardDetailHeader`
2. `BoardDetailContentSection`（本文）
3. `BoardDetailAttachmentSection`（添付一覧）
4. `BoardDetailTranslationTtsSection`（翻訳/TTS）
5. `BoardDetailCommentSection`（コメント一覧 + 入力）
6. `BoardDetailFooter`（戻るボタン等）
7. `BoardDetailPdfPreviewModal`（モーダル表示時のみ）

### 5.2.2 コンテナの基本スタイル（イメージ）

Tailwind を用いたスタイルのイメージ（厳密なクラス指定は実装時に微調整可）：

* 画面コンテナ: `flex flex-col gap-4 px-4 py-4 max-w-xl mx-auto`
* セクション間: `gap-4` 程度で適度な余白をとる。
* カード/セクション: `rounded-2xl shadow-sm border border-gray-100 bg-white p-4` をベースとし、本文・コメントは行間を広めにとる。

---

## 5.3 BoardDetailHeader（タイトル・カテゴリ・メタ情報）

### 5.3.1 表示項目

* カテゴリバッジ

  * 表示: `categoryName`
  * スタイル: `text-xs rounded-full bg-gray-100 px-2 py-0.5` 程度。
* タイトル

  * 表示: `title`
  * スタイル: `text-base font-semibold`。複数行の折り返しを許容。
* メタ情報行

  * 表示例: 「管理組合 ・ 2025/01/23 18:30」

    * 投稿者種別ラベル: `authorDisplayType`（例: 「管理組合」「一般利用者」）

      * i18n キー例: `board.detail.authorType.admin`, `board.detail.authorType.user`
    * 日時表示: `createdAt` をローカルフォーマット（YYYY/MM/DD HH:MM）に整形。
  * スタイル: `text-xs text-gray-500 mt-1`。

---

## 5.4 BoardDetailContentSection（本文表示）

### 5.4.1 表示内容

* 本文テキスト: `post.content`
* 段落構造: 改行を `<p>` 相当のブロックとして扱い、連続する改行は空行として表示する（実装方針はシンプルな `white-space: pre-line` 相当でよい）。

### 5.4.2 スタイル

* 本文: `text-sm leading-relaxed text-gray-800` を基本とする。
* セクションタイトル（必要な場合）: 「本文」などのラベルは表示せず、スペースと余白で区切るのみとする（UI をシンプルに保つ）。

---

## 5.5 BoardDetailAttachmentSection（添付ファイル一覧）

### 5.5.1 表示条件

* 添付が 1 件以上ある場合のみ表示する。
* 添付がない場合、本セクションは表示しない。

### 5.5.2 表示項目

* セクションタイトル

  * ラベル（日本語）: 「添付ファイル」
  * i18n キー例: `board.detail.attachment.title`
* 添付行（`BoardAttachmentItem` ごと）

  * アイコン: PDF の場合は PDF アイコン（共通アイコンセット）。
  * ファイル名: `fileName`
  * ファイルサイズ（任意）: KB/MB 単位への変換表示（必要であれば）。

### 5.5.3 インタラクション

* 添付行全体をタップ/クリックすると、`onOpenPreview(attachmentId)` を呼び出し、`BoardDetailPdfPreviewModal` を開く。
* ホバー時（PC）は下線または背景色をわずかに変える程度のフィードバック。

---

## 5.6 BoardDetailTranslationTtsSection（翻訳/TTS）

### 5.6.1 表示内容

* セクションタイトル

  * ラベル（日本語）: 「翻訳・読み上げ」
  * i18n キー例: `board.detail.i18n.title`

* 表示モード切替

  * 原文/翻訳文の切替タブ、またはトグルボタン。
  * ラベルとキー例:

    * 原文: `board.detail.i18n.original` = 「原文を表示」
    * 翻訳: `board.detail.i18n.translated` = 「翻訳文を表示」

* 翻訳ボタン

  * ラベル: 「翻訳する」
  * i18n キー例: `board.detail.i18n.translateButton`
  * 表示条件: `hasTranslation === false && isTranslating === false` の場合に表示。

* 翻訳中表示

  * 文言: 「翻訳しています…」
  * i18n キー例: `board.detail.i18n.translating`

* 翻訳エラー表示

  * 文言: 「翻訳に失敗しました。」
  * i18n キー例: `board.detail.i18n.translationError`

* 翻訳結果

  * `translatedText` を本文と同様のスタイル（`text-sm leading-relaxed`）で表示。

* TTS ボタン

  * ラベル: 「読み上げ」 / 「停止」
  * i18n キー例:

    * `board.detail.tts.play` = 「読み上げ」
    * `board.detail.tts.stop` = 「停止」
  * 表示条件: `isTtsAvailable === true` の場合のみ。

* TTS 状態

  * 読み上げ中: 「読み上げ中…」 (`board.detail.tts.playing`)
  * エラー: 「読み上げに失敗しました。」 (`board.detail.tts.error`)

---

## 5.7 BoardDetailCommentSection（コメント）

### 5.7.1 コメント一覧

* セクションタイトル

  * ラベル（日本語）: 「コメント」
  * i18n キー例: `board.detail.comment.title`

* コメントアイテム（`BoardCommentItem`）

  * 表示項目:

    * 投稿者名: `authorDisplayName`
    * 投稿者種別ラベル: `authorDisplayType`（管理組合 / 一般利用者）

      * i18n キー例: `board.detail.comment.authorType.admin`, `board.detail.comment.authorType.user`
    * 投稿日時: `createdAt` をローカルフォーマットで表示。
    * 本文: `content`
  * スタイル:

    * コンパクトなカードまたはリスト行として表示し、本文は `text-sm text-gray-800`。

### 5.7.2 コメント入力欄

* 表示条件

  * `canPostComment === true` の場合に表示する。

* 入力欄

  * プレースホルダ（日本語）: 「コメントを入力してください」
  * i18n キー例: `board.detail.comment.input.placeholder`
  * 入力コンポーネント: `textarea`（複数行入力）を想定。

* 送信ボタン

  * ラベル: 「コメントを投稿」
  * i18n キー例: `board.detail.comment.submit`
  * 状態:

    * 入力中かつ `commentInput` が空でない場合のみ有効。
    * `isCommentSubmitting === true` の間は無効化し、「送信中…」表示にするかスピナーを表示。

* 送信成功時メッセージ（任意）

  * 簡易なトーストまたは画面下部に「コメントを投稿しました。」を表示する。
  * i18n キー例: `board.detail.comment.submitSuccess`

* 送信失敗時メッセージ

  * 文言: 「コメントの投稿に失敗しました。時間をおいて再度お試しください。」
  * i18n キー例: `board.detail.comment.submitError`

---

## 5.8 BoardDetailFooter（戻るボタン等）

### 5.8.1 表示内容

* 「掲示板に戻る」ボタン

  * ラベル（日本語）: 「掲示板に戻る」
  * i18n キー例: `board.detail.backToList`

### 5.8.2 インタラクション

* ボタン押下で `/board` への遷移を行う。タブ・範囲などを復元するかどうかは BoardTop 側の仕様に従う（初版では単純に `/board` へ戻る）。

---

## 5.9 BoardDetailPdfPreviewModal（PDF プレビュー）

### 5.9.1 表示条件

* `isPdfPreviewOpen === true` の場合に表示する。
* `activeAttachmentId` に対応する `BoardAttachmentItem` を表示対象とする。

### 5.9.2 UI 要素

* 上部バー

  * 左上または右上に「閉じる」テキストまたは ✕ アイコン。
  * i18n キー例: `board.detail.pdf.close` = 「閉じる」

* 本文エリア

  * PDF ビューアコンポーネントを全画面または大きめの領域で表示。

* 下部メッセージ

  * ラベル（日本語）: 「タップで閉じる」
  * i18n キー例: `board.detail.pdf.tapToClose`

### 5.9.3 挙動

* モーダル全体（PDF ビューアを除くオーバーレイ領域）をタップすると閉じる。
* 上部の「閉じる」テキスト/アイコンをタップしても閉じる。
* 背景タップでは閉じない（PDF スクロール操作を優先）。

---

## 5.10 メッセージ・i18n キー一覧（BoardDetail）

BoardDetail で新規に定義する静的 i18n キーの一覧を次に示す（日本語版は例）。

| 用途                 | i18n キー                                  | 日本語例                            |
| ------------------ | ---------------------------------------- | ------------------------------- |
| セクション: 添付タイトル      | `board.detail.attachment.title`          | 添付ファイル                          |
| セクション: 翻訳/TTS タイトル | `board.detail.i18n.title`                | 翻訳・読み上げ                         |
| 翻訳: 原文タブ           | `board.detail.i18n.original`             | 原文を表示                           |
| 翻訳: 翻訳文タブ          | `board.detail.i18n.translated`           | 翻訳文を表示                          |
| 翻訳: 実行ボタン          | `board.detail.i18n.translateButton`      | 翻訳する                            |
| 翻訳: 実行中            | `board.detail.i18n.translating`          | 翻訳しています…                        |
| 翻訳: エラー            | `board.detail.i18n.translationError`     | 翻訳に失敗しました。                      |
| TTS: 再生ボタン         | `board.detail.tts.play`                  | 読み上げ                            |
| TTS: 停止ボタン         | `board.detail.tts.stop`                  | 停止                              |
| TTS: 再生中           | `board.detail.tts.playing`               | 読み上げ中…                          |
| TTS: エラー           | `board.detail.tts.error`                 | 読み上げに失敗しました。                    |
| コメントセクションタイトル      | `board.detail.comment.title`             | コメント                            |
| コメント入力プレースホルダ      | `board.detail.comment.input.placeholder` | コメントを入力してください                   |
| コメント送信ボタン          | `board.detail.comment.submit`            | コメントを投稿                         |
| コメント送信成功           | `board.detail.comment.submitSuccess`     | コメントを投稿しました。                    |
| コメント送信失敗           | `board.detail.comment.submitError`       | コメントの投稿に失敗しました。時間をおいて再度お試しください。 |
| コメント投稿者種別: 管理組合    | `board.detail.comment.authorType.admin`  | 管理組合                            |
| コメント投稿者種別: 一般利用者   | `board.detail.comment.authorType.user`   | 一般利用者                           |
| 戻るボタン              | `board.detail.backToList`                | 掲示板に戻る                          |
| PDF モーダル: 閉じる      | `board.detail.pdf.close`                 | 閉じる                             |
| PDF モーダル: タップで閉じる  | `board.detail.pdf.tapToClose`            | タップで閉じる                         |

※ 実際の i18n ファイルでは、StaticI18nProvider の構造に合わせてネスト定義を行う。キー名や階層を変更する場合は、本詳細設計書側も更新すること。

---

## 5.11 アクセシビリティとフォーカス制御

* 主要な操作要素（コメント入力欄、送信ボタン、翻訳/TTS ボタン、戻るボタン）はすべてキーボード操作（Tab キー）でフォーカスできること。
* PDF プレビューモーダル表示中は、フォーカスがモーダル内に留まるように実装する（背景要素にフォーカスが移動しないようにする）。
* エラー状態や送信失敗時のメッセージは、できるだけ近くの要素の直後に表示し、視覚的に分かりやすくする。
