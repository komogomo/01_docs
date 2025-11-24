# B-02 BoardDetail 詳細設計書 ch02 画面構造・コンポーネント構成 v1.1

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH02
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 2.1 レイアウト全体構成

### 2.1.1 画面レイアウト概要

BoardDetail は、HarmoNet 共通レイアウト（AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider）配下の「メインコンテンツ領域」に表示される。レイアウト階層（論理レベル）は次の通りとする。

* `RootLayout`（アプリ共通レイアウト）

  * `AppHeader`（共通ヘッダー）
  * `Main` コンテンツ領域

    * `BoardDetailPage`（本コンポーネントのページコンテナ）
  * `AppFooter`（共通フッター）

LanguageSwitch / StaticI18nProvider は RootLayout 側で適用済みとし、本章では BoardDetail 固有部分のみを対象とする。

### 2.1.2 BoardDetail 内部構造

`BoardDetailPage` 配下の構造は以下の通りとする（SP 基準）。

* `BoardDetailPage`

  * `BoardDetailHeader`（タイトル・カテゴリ・メタ情報）
  * `BoardDetailBody`（本文・添付・翻訳/TTS・コメントを含むメイン領域）

    * `BoardDetailContentSection`（本文表示）
    * `BoardDetailAttachmentSection`（添付ファイル一覧）
    * `BoardDetailTranslationTtsSection`（翻訳/TTS 操作用セクション）
    * `BoardDetailCommentSection`（コメント一覧・コメント入力）
  * `BoardDetailFooter`（戻るボタンなどの下部アクション）
  * `BoardDetailPdfPreviewModal`（PDF プレビューモーダル、必要な場合のみ表示）

PDF プレビューは掲示板共通仕様（モーダルで表示、背景タップ無効、下部に「タップで閉じる」）に従い、BoardDetail ではそのモーダルを起動するトリガと閉じる制御のみを行う。PDF ビューア自体の実装は共通部品として扱う。

BoardDetail は、投稿の作成・編集・削除そのもののフォームロジックを持たず、B-03 BoardPostForm コンポーネントに委譲する。BoardDetail 上には、必要に応じて「編集」などのアクション入口のみを配置する。

---

## 2.2 主要コンポーネントの役割

### 2.2.1 BoardDetailPage

* URL `/board/[postId]` に対応するトップレベルコンポーネント。
* ルーティングから `postId` を受け取り、単一投稿・コメント・添付・翻訳/TTS キャッシュの取得処理を起動する。
* ローディング・エラー・権限不足・正常表示の各状態を統括し、子コンポーネントの出し分けを行う。
* 投稿の編集・削除などの操作を行う場合、B-03 BoardPostForm への遷移または埋め込みをトリガする。

### 2.2.2 BoardDetailHeader

* 表示内容（例）:

  * カテゴリバッジ（例: お知らせ / 規約・ルール）
  * 投稿タイトル
  * メタ情報行（投稿者種別ラベル・投稿日時・回覧板ステータスなど）
* BoardTop とトーンを揃えつつ、詳細画面としてやや情報量の多いヘッダーを構成する。
* 投稿者表示名・ロール表示は、B-03 BoardPostForm で定義された表示名モード（匿名 / ニックネームなど）に従う。

### 2.2.3 BoardDetailContentSection

* 投稿本文のフルテキストを表示するセクション。
* 長文の可読性を優先し、行間・余白を多めにとる。
* 将来、段落構造（改行・箇条書き）を反映する場合でも、このセクション内で完結する。

### 2.2.4 BoardDetailAttachmentSection

* 添付ファイル（主に PDF）一覧の表示を担当するセクション。
* 各添付行にはファイル名・アイコン・（必要なら）ファイルサイズを表示し、タップ/クリックで `BoardDetailPdfPreviewModal` を開く。
* 添付が存在しない場合はセクション自体を非表示、または簡易な「添付なし」表示を行う（UI 詳細は ch05）。
* 添付ファイル情報は、`board_attachments` 相当のテーブルから取得したデータを使用する（詳細は ch03）。

### 2.2.5 BoardDetailTranslationTtsSection

* 翻訳・音声読み上げに関する UI をまとめるセクション。
* 以下の要素を含むことを想定する（具体 UI は ch05 で定義）。

  * 表示テキスト切替（原文 / 翻訳文）
  * 翻訳実行ボタン（未翻訳の場合）
  * 翻訳結果表示領域
  * TTS 実行ボタン（音声読み上げ開始/停止）
  * 翻訳/TTS 状態表示（処理中・エラーなど）
* 実際の翻訳/TTS 処理は共通コンポーネント側で実装し、BoardDetail はそれらのトリガと状態表示のオーケストレーションを行う。
* 翻訳・TTS の利用有無やサポート言語は、掲示板共通仕様および B-03/B-04 系詳細設計に従う。

### 2.2.6 BoardDetailCommentSection

* コメント一覧およびコメント入力 UI を表示するセクション。
* コメント機能の有効/無効、投稿権限（管理組合のみ／全利用者など）は掲示板基本設計および B-03 詳細設計に従う。
* BoardDetail 側では、以下の構造を前提とする。

  * コメントリスト
  * コメント入力欄（必要なロールのみ表示）
  * 投稿ボタン
* コメント送信イベントはデータアクセス層に引き渡し、バリデーションやメッセージ表示は B-03 を正とするメッセージ仕様（i18n キー体系）に合わせる。

### 2.2.7 BoardDetailFooter

* 「掲示板に戻る」ボタンなどの下部アクションをまとめる領域。
* 必要に応じて、最下部に「最終更新日時」などの補助情報を表示する。
* 戻り先は基本的に BoardTop (`/board`) とし、ブラウザバックとの併用はしない（実装詳細は ch04）。

### 2.2.8 BoardDetailPdfPreviewModal

* PDF 添付ファイルをモーダルでプレビュー表示するコンポーネント。
* 掲示板共通仕様に従い、以下の要件を満たす。

  * 画面上部に「閉じる」テキストまたは ✕ アイコンを表示。
  * 画面下部中央に「タップで閉じる」文言を表示。
  * モーダル全体タップで閉じるが、PDF ビューア部のスクロール操作を妨げないよう考慮する。
  * 背景タップでは閉じない（PDF 操作優先）。
* BoardDetail は、どの添付をプレビュー中かを状態として持ち、このモーダルに渡す。
* PDF ビューアそのものは共通コンポーネント（例: `PdfViewer`）として別途実装し、本画面ではそのラッパとして扱う。

---

## 2.3 ルーティングとパラメータ

### 2.3.1 ルーティング

* パス: `/board/[postId]`
* HTTP メソッド: GET（画面表示）
* 認証: MagicLink 認証済みユーザのみ。未認証の場合は `/login` へリダイレクト（アプリ共通仕様）。

### 2.3.2 パスパラメータ

* `postId: string`

  * `board_posts.id` に対応。UUID 形式を想定。
  * BoardDetailPage は `postId` をもとに投稿本体および関連データを取得する。

### 2.3.3 クエリパラメータ

初版では、BoardDetail 独自のクエリパラメータは定義しない。PDF プレビュー状態などの一時的な UI 状態は URL には乗せず、画面内部の state として管理する。

将来的に、コメント一覧のソート順やページングなどを URL で表現する必要が出てきた場合は、その時点でクエリパラメータを設計し、本章を v1.2 以降に更新する。

---

## 2.4 レスポンシブレイアウト方針

### 2.4.1 SP（スマートフォン）

* 基本は 1 カラムの縦積みレイアウトとし、要素の順序は以下とする。

  1. `BoardDetailHeader`
  2. `BoardDetailContentSection`
  3. `BoardDetailAttachmentSection`
  4. `BoardDetailTranslationTtsSection`
  5. `BoardDetailCommentSection`
  6. `BoardDetailFooter`
* 各セクションの上下に十分な余白を確保し、長文でも読みやすいようにする。
* PDF プレビューモーダル表示中は、背後のスクロールはロックする（共通モーダル仕様に従う）。

### 2.4.2 PC（デスクトップ）

* コンテンツ幅は最大幅（例: 960〜1200px）で中央寄せにし、左右に余白を持たせる。
* レイアウト順序は SP と同一とし、左右 2 カラムに無理に分割しない（設計と実装のシンプルさを優先）。
* コメントセクションのみ、余裕があれば高さをやや広く取り、長文コメントが読みやすいようにする。

---

## 2.5 コンポーネント間の依存関係

### 2.5.1 依存関係概要

* `BoardDetailPage`

  * `BoardDetailHeader`
  * `BoardDetailBody`

    * `BoardDetailContentSection`
    * `BoardDetailAttachmentSection`
    * `BoardDetailTranslationTtsSection`
    * `BoardDetailCommentSection`
  * `BoardDetailFooter`
  * `BoardDetailPdfPreviewModal`

BoardDetailPage は、投稿本体・コメント・添付・翻訳/TTS 状態を取得し、それぞれのセクションに必要な props を渡す。

### 2.5.2 props の方向性（論理）

* `BoardDetailHeader`

  * props: 投稿タイトル、カテゴリ情報、投稿者種別ラベル、作成日時、回覧板ステータスなど。
* `BoardDetailContentSection`

  * props: 本文テキスト、必要に応じてマークアップ情報。
* `BoardDetailAttachmentSection`

  * props: 添付ファイル配列（id, fileName, fileType, fileSize など）、プレビュー開始ハンドラ。
* `BoardDetailTranslationTtsSection`

  * props: 原文テキスト、翻訳結果、翻訳/TTS 状態、各種ハンドラ（翻訳実行・TTS 開始/停止）。
* `BoardDetailCommentSection`

  * props: コメント一覧、コメント投稿可能かどうか、送信ハンドラ。
* `BoardDetailPdfPreviewModal`

  * props: 表示中フラグ、現在プレビュー中の添付ファイル情報、閉じるハンドラ。

### 2.5.3 外部依存

BoardDetail は、次の外部要素に依存するが、その具体実装は本章では扱わない（該当章・別文書で定義）。

* Supabase クライアントおよび掲示板関連テーブル向けのデータアクセス API
* 認証コンテキスト（現在ユーザ・tenantId・viewerRole）
* 翻訳・TTS 共通コンポーネント／フック
* PDF ビューアコンポーネント（PDF.js 等をラップしたもの）

以上により、BoardDetail の画面構造とコンポーネント構成の論理レベルを定義する。詳細な props 型定義や Tailwind クラス、イベントハンドラの具体シグネチャは、ch03〜ch05 で記述する。
