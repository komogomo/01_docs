# B-02 BoardDetail 詳細設計 ch08 添付ファイル表示仕様_v1.0

## 1. 目的

* 掲示板詳細画面 BoardDetail（B-02）における、添付ファイル表示・プレビュー・ダウンロード機能の仕様を定義する。
* BoardPostForm で登録された添付ファイル（`board_attachments`）を、閲覧専用画面として適切に表示する。

## 2. 対象範囲

* 対象画面: `/board/[postId]` 掲示板詳細画面 BoardDetail。
* 対象機能:

  * 投稿に紐づく添付ファイル一覧の表示。
  * 添付ファイルのプレビュー表示（PDF／画像）。
  * 添付ファイルのダウンロード操作。
* 本章では、添付の登録・削除ロジック（BoardPostForm 側）は対象外とする。

## 3. 使用データ

### 3.1 入力データ構造

* BoardDetail コンポーネントは、以下の情報を props として受け取る。

```ts
type Attachment = {
  id: string
  fileName: string
  fileType: string
  fileSize: number
  fileUrl: string // 添付取得 API の URL (/api/board/attachments/{attachmentId})
}

type BoardPostDetail = {
  id: string
  tenantId: string
  title: string
  body: string
  bodyType: 'plain' | 'tiptap'
  categoryCode: string
  groupTagCode: string | null
  authorDisplayName: string
  createdAt: string
  // 既存の翻訳・TTS 用フィールドがあればここに追加
  attachments: Attachment[]
}
```

* `attachments` は、`board_attachments` に登録された添付ファイルを 0件以上保持する。

### 3.2 データ取得元

* サーバ側の BoardDetail 用クエリ（または API）で、`board_posts` と `board_attachments` を結合して取得する。
* 例: `getBoardPostWithAttachments(postId, tenantId)` 内で

  * `board_posts` 1件
  * `board_attachments` 0件以上
    をまとめて返却する。

### 3.3 データ取得インターフェース

* BoardDetail 用のサーバ関数インターフェースを次のように定義する。

```ts
type Attachment = {
  id: string
  fileName: string
  fileType: string
  fileSize: number
  fileUrl: string // Storage のオブジェクトパス or URL
}

type BoardPostDetail = {
  id: string
  tenantId: string
  title: string
  body: string
  bodyType: 'plain' | 'tiptap'
  categoryCode: string
  groupTagCode: string | null
  authorDisplayName: string
  createdAt: string
  attachments: Attachment[]
}

async function getBoardPostDetail(
  tenantId: string,
  postId: string,
  currentUserId: string
): Promise<BoardPostDetail | null>
```

* 取得仕様（概念SQL）

```sql
SELECT
  p.id,
  p.tenant_id,
  p.title,
  p.body,
  p.body_type,
  p.category_code,
  p.group_tag_code,
  p.author_display_name,
  p.created_at,
  a.id        AS attachment_id,
  a.file_name AS attachment_file_name,
  a.file_type AS attachment_file_type,
  a.file_size AS attachment_file_size,
  a.file_url  AS attachment_file_url
FROM board_posts p
LEFT JOIN board_attachments a
  ON a.post_id = p.id
WHERE
  p.tenant_id = :tenant_id
  AND p.id = :post_id;
```

* 利用イメージ

  * `/board/[postId]/page.tsx` 等で `getBoardPostDetail(tenantId, postId, currentUserId)` を呼び出し、戻り値をそのまま `<BoardDetail post={data} />` に渡す。

## 4. 画面レイアウト

画面レイアウト

### 4.1 添付ファイルセクション配置

* 本文カードの直下に「添付ファイル」セクションを追加する。
* 添付が 1 件以上存在する場合のみ表示し、0 件の場合はセクション自体を非表示とする。
* レイアウト（スマホ基準）

  * セクションタイトル行（例: 「添付ファイル」）
  * 添付ファイルリスト（1 行 = 1 ファイル）

### 4.2 添付ファイル行の表示要素

* 各行の要素

  * 左: ファイル種別アイコン（PDF の場合は PDF アイコン）
  * 中央: ファイル名（`file_name`）
  * 右: 操作ボタン

    * プレビューボタン（例: 「プレビュー」）
    * ダウンロードボタン（例: 「ダウンロード」）
* 長いファイル名は 1 行で省略表示（末尾に `…`）。

## 5. 添付ファイルプレビュー仕様

### 5.1 起動方法

* 添付ファイル行の「プレビュー」ボタンをタップ／クリックすると、プレビュー用モーダルを表示する。
* プレビュー対象:

  * PDF: `file_type` または `fileName` から PDF と判定できる場合。
  * 画像: `file_type` または `fileName` から JPG / JPEG / PNG と判定できる場合。
* 上記以外のファイル種別（Office 等）はプレビュー対象外とし、「ダウンロード」のみ提供する。

### 5.2 モーダル表示仕様

* 画面全体を覆うフルスクリーンモーダル（掲示板TOPの PDF プレビュー仕様とトーンを統一する）。
* モーダル内コンテンツ

  * 上部: 小さな「閉じる」テキストまたは ✕ アイコンを右上に表示。
  * 中央: 添付種別に応じて以下のいずれかを表示する。

    * PDF: `<iframe src={fileUrl}>` による PDF ビュー。
    * 画像(JPG/PNG): `<img src={fileUrl}>` による画像ビュー（`object-contain`、縦スクロール）。
  * 下部中央: 「タップで閉じる」テキストを控えめに表示。
* 操作

  * 「閉じる」テキスト／✕ アイコンをタップするとモーダルを閉じる。
  * モーダル全体（表示領域を含む）を短くタップした場合もモーダルを閉じる。
  * 背景だけをタップして閉じるような挙動は実装せず、閲覧コンテンツのスクロール操作を優先する。

### 5.3 プレビュー用 URL

* `Attachment.fileUrl` には、`/api/board/attachments/{attachmentId}` 形式の URL を格納する。
* BoardDetail は `fileUrl` をそのまま `<iframe>` / `<img>` の `src` として利用する。
* Supabase Storage 上のオブジェクトパスや署名付き URL の生成は、`/api/board/attachments/{attachmentId}` 側の内部実装とし、本画面からは意識しない。

## 6. ダウンロード仕様

### 6.1 操作

* 添付ファイル行の「ダウンロード」ボタンをタップ／クリックすると、ブラウザのダウンロード動作を起動する。

### 6.2 URL の扱い

* ダウンロード時も、`Attachment.fileUrl`（`/api/board/attachments/{attachmentId}`）をそのままリンク先として使用する。
* `fileUrl` の背後で Supabase Storage からファイルを取得し、適切な Content-Type / Content-Disposition を付与して返却するのは API 側の責務とする。

## 7. エラーハンドリング

* PDF プレビュー／ダウンロード時に署名付き URL の取得に失敗した場合

  * 画面下部にトーストメッセージなどでエラーを表示する（例: 「ファイルを読み込めませんでした。」）。
  * BoardDetail 本体の表示には影響を与えない。
* 添付ファイル自体が削除済み（Storage 上に存在しない）場合

  * URL 取得時エラーとして扱い、同様のエラーメッセージを表示する。

## 8. メッセージ表示仕様（案）

* 添付一覧

  * 添付が 0 件の場合: セクション非表示（メッセージは表示しない）。
* エラー系

  * PDF プレビュー失敗時: 「ファイルを読み込めませんでした。」
  * ダウンロード失敗時: 「ファイルをダウンロードできませんでした。」

※ メッセージ文言の最終決定は共通メッセージ設計に従い、必要に応じて i18n キーを定義する。
