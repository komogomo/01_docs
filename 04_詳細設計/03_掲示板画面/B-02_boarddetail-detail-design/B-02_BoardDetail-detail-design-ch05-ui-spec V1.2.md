# B-02 BoardDetail 詳細設計書 ch05 UI仕様・メッセージ v1.2

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH05
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板詳細画面コンポーネント **BoardDetail（B-02）** の UI 要素（レイアウト・ボタン・ラベル・状態表示）および i18n メッセージキーを定義する。
対象となる操作は以下とする。

* 投稿本文・添付の閲覧
* 翻訳ボタン
* 読み上げ（TTS）ボタン
* コメント一覧表示・コメント入力
* **投稿単位の返信ボタン**
* **投稿単位の削除ボタン**
* **コメント単位の削除ボタン**

編集・新規投稿・AI モデレーションロジックは B-03 BoardPostForm と API 側の責務とし、本章では「BoardDetail の画面上に表示される UI とメッセージ」のみを扱う。

---

## 5.2 画面構成と主要 UI 要素

### 5.2.1 画面構造の再掲（論理）

* BoardDetailHeader

  * カテゴリバッジ
  * タイトル
  * 投稿者情報（表示名・ロールラベル）
  * 投稿日時
  * 回覧板ステータス（必要に応じて）
  * **投稿アクションボタン群（返信・編集・削除）**
* BoardDetailContentSection

  * 本文（原文 or 翻訳文）
* BoardDetailAttachmentSection

  * 添付ファイル一覧（タップで PDF プレビュー）
* BoardDetailTranslationTtsSection

  * 翻訳ボタン
  * TTS 再生/停止ボタン
  * 翻訳結果表示領域
* BoardDetailCommentSection

  * コメント一覧（各コメントに投稿者名・日時・削除ボタン）
  * コメント入力欄
  * コメント送信ボタン
* BoardDetailFooter

  * 「掲示板に戻る」ボタン
* BoardDetailPdfPreviewModal

  * PDF ビューア
  * 上部「閉じる」リンク or アイコン
  * 下部「タップで閉じる」テキスト

---

## 5.3 投稿アクション（返信・編集・削除）

### 5.3.1 投稿アクションボタン表示ルール

投稿ヘッダー右上に、以下のボタン群を配置する。

* 返信ボタン

  * ラベル: `board.detail.post.reply`
  * アイコン: 矢印 or 吹き出し（実装時に決定）
  * 表示条件: ログイン済みかつ投稿権限を持つユーザ（`canPost` 相当のフラグ）
* 編集ボタン

  * ラベル: `board.detail.post.edit`
  * 表示条件: 投稿者本人、または管理組合ロールのユーザ
* 削除ボタン

  * ラベル: `board.detail.post.delete`
  * 表示条件: 管理組合ロール、または投稿者本人（運用ポリシーに従う）

### 5.3.2 返信ボタンの挙動

* 押下時に B-03 BoardPostForm を「返信モード」で呼び出す。
* 返信先投稿 ID（`parentPostId`）を持った新規投稿として扱う。
* 遷移先は `/board/new?replyTo={postId}` のような形を想定し、詳細は B-03 側で定義する。

### 5.3.3 編集ボタンの挙動

* 押下時に B-03 BoardPostForm を「編集モード」で呼び出す。
* 遷移先は `/board/{postId}/edit` などを想定し、実際のルーティングは B-03 / ルーティング設計に従う。

### 5.3.4 削除ボタンの挙動

* 押下時に確認ダイアログを表示する。

  * タイトル: `board.detail.post.delete.confirmTitle`
  * メッセージ: `board.detail.post.delete.confirmMessage`
  * ボタン: `board.detail.post.delete.confirmYes` / `board.detail.post.delete.confirmNo`
* 確認で「はい」を選択した場合にのみ、**バックエンドで論理削除（例: `status` を `archived` / `deleted` 等に更新）を行う API** を呼び出す。

  * 物理削除（レコードの DELETE）は行わない前提とし、履歴や監査用データは DB 上に残る。
* 削除成功時は BoardTop (`/board`) へ遷移し、情報メッセージ `board.detail.post.delete.success` を表示する（表示位置・方式は BoardTop 側で定義）。
* 削除失敗時は `board.detail.post.delete.error` を表示し、画面は BoardDetail に留まる。

---

## 5.4 コメント UI

### 5.4.1 コメント一覧

1 コメントごとに以下を表示する。

* 投稿者表示名（B-03 の表示名モードに従う）
* ロールラベル（管理組合 / 一般 等）
* 投稿日時
* コメント本文
* **削除ボタン（条件付き）**

削除ボタン:

* ラベル: `board.detail.comment.delete`
* 表示条件: コメント投稿者本人、または管理組合ロール
* 押下時の挙動:

  * 確認ダイアログを表示（キー: `board.detail.comment.delete.confirm*`）
  * 確認後、**バックエンドで論理削除（コメントの `status` 更新やフラグ更新）を行う API** を呼び出す。

    * コメントも物理削除は行わず、監査・トラブル調査のためのデータは DB に残す方針とする。
  * 成功時はコメント一覧を再取得 or ローカルから該当コメントを除去
  * 失敗時は `board.detail.comment.delete.error` を表示

### 5.4.2 コメント入力欄

* プレースホルダ: `board.detail.comment.input.placeholder`
* 送信ボタンラベル: `board.detail.comment.submit`
* `canPostComment = false` の場合:

  * 入力欄と送信ボタンを非活性 or 非表示とし、代わりに簡易メッセージ `board.detail.comment.disabled` を表示する。

コメント送信結果メッセージ:

* 成功時: 必須ではないが、控えめなトースト or インラインメッセージ `board.detail.comment.submit.success` を表示可能とする。
* 失敗時: `commentError` に応じて以下を出し分ける。

  * 一般エラー: `board.detail.comment.submit.error`
  * AI モデレーションブロック: `board.detail.comment.submit.moderationBlocked`

AI モデレーションの詳細（スコア・理由）は UI には出さず、「内容を見直してください」といった抑止的な文言とする。

---

## 5.5 翻訳・TTS UI

### 5.5.1 翻訳ボタン

* 原文が表示されている状態で、翻訳ボタンを表示する。
* ボタンラベル: `board.detail.i18n.translateButton`
* 翻訳中は `board.detail.i18n.translating` としてスピナー付きラベルに切り替える。
* 翻訳結果が存在する場合は、原文/翻訳の切替トグルを表示する。

  * トグルラベル: `board.detail.i18n.viewOriginal` / `board.detail.i18n.viewTranslated`

### 5.5.2 TTS ボタン

* 対応言語の場合のみ、TTS ボタンを表示する。
* ボタンラベル: 再生 `board.detail.tts.play`、停止 `board.detail.tts.stop`
* 再生中はアイコンを停止マークに切替え、`isTtsPlaying` フラグに連動させる。
* エラー時は控えめなインラインメッセージ `board.detail.tts.error` を表示する。

---

## 5.6 PDF プレビュー UI

### 5.6.1 添付一覧

* 各添付行の表示要素:

  * ファイルアイコン（PDF / その他）
  * ファイル名
  * 必要に応じてファイルサイズ
* タップ/クリック時:

  * `PDF_PREVIEW_OPENED` イベントを発行し、`BoardDetailPdfPreviewModal` を表示する。

### 5.6.2 PDF プレビューモーダル

* 上部:

  * 「閉じる」テキストリンク or ✕ アイコン（キー: `board.detail.pdf.close`）
* 中央:

  * PDF ビューアコンポーネント
* 下部中央:

  * 「タップで閉じる」テキスト（キー: `board.detail.pdf.tapToClose`）

背景タップでは閉じず、PDF のスクロールやズーム操作を優先する。
閉じる操作は「上部の閉じる」または「モーダル全体タップ（ビューア領域外）」で行う。

---

## 5.7 エラー・状態メッセージ

### 5.7.1 画面全体のエラー

* 投稿が存在しない場合:

  * キー: `board.detail.error.notFound`
* 閲覧権限がない場合:

  * キー: `board.detail.error.forbidden`
* 通信エラー/不明なエラー:

  * キー: `board.detail.error.generic`

### 5.7.2 コメント関連

* 送信成功: `board.detail.comment.submit.success`
* 一般的な送信失敗: `board.detail.comment.submit.error`
* AI モデレーションによるブロック: `board.detail.comment.submit.moderationBlocked`
* 削除成功: `board.detail.comment.delete.success`
* 削除失敗: `board.detail.comment.delete.error`

### 5.7.3 投稿削除関連

* 削除成功: `board.detail.post.delete.success`
* 削除失敗: `board.detail.post.delete.error`

---

## 5.8 i18n キー命名ポリシー

* プレフィックス: すべて `board.detail.*` とし、BoardTop や他画面と衝突しないようにする。
* 大分類:

  * `board.detail.header.*`  : ヘッダー要素
  * `board.detail.body.*`    : 本文・添付
  * `board.detail.i18n.*`    : 翻訳 UI
  * `board.detail.tts.*`     : TTS UI
  * `board.detail.comment.*` : コメント UI
  * `board.detail.post.*`    : 投稿アクション（返信・編集・削除）
  * `board.detail.error.*`   : 画面全体のエラー

実際の文言（日本語/英語/中国語）は StaticI18nProvider 用の辞書ファイルで定義し、本章ではキー体系と UI 上の使い所のみを示す。

---

## 5.9 他章との関係

* ch01 概要

  * BoardDetail の役割と B-03/B-04 との責務分担を定義。
* ch02 レイアウト

  * 本章で定義したボタン・リンクが、どのセクション・どの位置に配置されるかを定義。
* ch03 データモデル

  * アクション表示条件（viewerRole, canPostComment 等）の元となるフィールドを定義。
* ch04 状態管理・イベント

  * コメント送信失敗（モデレーションブロックを含む）や削除成功/失敗時に、どの状態フラグ・メッセージを更新するかを定義。
* B-03 BoardPostForm ch08 AI モデレーション

  * コメント送信時の AI モデレーションブロックは、BoardDetail では `board.detail.comment.submit.moderationBlocked` のメッセージ表示としてのみ反映される。

本章 v1.2 は、B-02 ch01〜ch04 v1.1/1.2、および B-03/B-04 系詳細設計、AI モデレーション仕様と整合する形で UI およびメッセージ仕様を定義している。
将来的に返信のスレッド表示や追加アクションが必要になった場合は、本章を v1.3 以降に更新し、ボタン配置とメッセージキーを拡張する。
