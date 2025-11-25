# WS-B03 BoardPostForm 添付ファイル実装指示書_v1.0

## 1. ゴール

* 掲示板投稿画面 BoardPostForm に、PDF 添付ファイルのアップロード機能を追加する。
* 添付ファイルは Supabase Storage（`board-attachments` バケット）に保存し、メタ情報を `board_attachments` テーブルに登録する。
* 既存の投稿作成フロー（本文・タイトル・カテゴリなど）を崩さずに拡張する。

## 2. 対象スコープ

### 2.1 フロントエンド

* 対象コンポーネント（想定）

  * `src/components/board/BoardPostForm/BoardPostForm.tsx`
* 対象機能

  * 新規投稿時の添付ファイル選択（複数）
  * 編集時の添付ファイル追加・削除
  * 画面上の簡易プレビュー（ファイル名一覧のみでよい）

### 2.2 バックエンド

* 対象 API ルート（想定）

  * `app/api/board/posts/route.ts`（新規投稿用）
  * `app/api/board/posts/[postId]/route.ts` 等（編集用、存在すれば）
* Supabase 連携

  * Supabase サーバクライアントを用いて

    * `board_posts` への INSERT / UPDATE
    * Storage `board-attachments` への `upload()` / `remove()`
    * `board_attachments` への INSERT / DELETE

## 3. 仕様リファレンス

* 詳細設計:

  * B-03 BoardPostForm 詳細設計 ch09 添付ファイル連携仕様_v1.0

    * 添付保存方式（Supabase Storage + `board_attachments`）
    * 権限・表示ルール
    * アップロード／削除フロー

## 4. データ構造・Storage 設計

### 4.1 Storage

* バケット: `board-attachments`（Supabase Storage / private）
* オブジェクトパス:

  * `tenant-{tenant_id}/post-{post_id}/{uuid}.{ext}`
* 本タスクでは、署名付き URL の生成は BoardDetail 側（別タスク）で行うため、ここでは「アップロードまで」を対象とする。

### 4.2 DB テーブル `board_attachments`

* 既存 Prisma モデルを前提とする。
* 利用カラム:

  * `id` … 添付ID（UUID, PK）
  * `tenant_id` … テナントID
  * `post_id` … 紐づく掲示板投稿ID（`board_posts.id`）
  * `file_url` … Storage 上のオブジェクトパス or URL
  * `file_name` … 元ファイル名
  * `file_type` … MIME タイプ（`application/pdf`）
  * `file_size` … バイト数
  * `created_at` … 登録日時

## 5. フロントエンド実装詳細

### 5.1 UI 仕様

* BoardPostForm に以下の UI を追加する。

  * ラベル: 「添付ファイル」
  * `<input type="file" multiple>` もしくは同等のファイル選択コンポーネント
  * PDF のみ選択可能に制限する（`accept="application/pdf"`）
* 選択済みファイルの一覧表示

  * ファイル名のみを縦に並べて表示
  * 各行に「×」アイコン（選択解除／削除）を表示

### 5.2 クライアント側ロジック

* React state 例:

```ts
const [files, setFiles] = useState<File[]>([])
```

* `onChange` で選択ファイルを `files` に格納

  * 既存フォームの入力値（タイトル・本文など）とは別管理
* バリデーション:

  * MIME タイプが `application/pdf` 以外の場合は拒否
  * 1 ファイルあたりのサイズ上限（例: 10MB）を超える場合はエラー
* 送信時:

  * 既存の `onSubmit` ハンドラを拡張し、`FormData` を構築する

```ts
const formData = new FormData()
formData.append('title', title)
formData.append('body', body)
// 既存のフィールドもすべて追加

files.forEach((file, index) => {
  formData.append('attachments', file)
})

await fetch('/api/board/posts', {
  method: 'POST',
  body: formData,
})
```

* 成功時:

  * 既存の挙動（例: 投稿完了メッセージ表示・画面遷移）を維持
* 失敗時:

  * エラーメッセージを画面上に表示（簡易で可）

## 6. バックエンド実装詳細

### 6.1 新規投稿 API (`POST /api/board/posts`)

1. リクエスト受信

   * `multipart/form-data` を受け取り、

     * 文字列系フィールド（タイトル・本文・カテゴリなど）
     * 添付ファイル群（フィールド名: `attachments`）
       を取り出す。

2. 認証・テナント取得

   * Supabase Auth / JWT 等から `user_id` / `tenant_id` を取得。

3. `board_posts` への INSERT

   * 既存仕様に従い、投稿レコードを作成。
   * INSERT 結果から `post_id` を取得。

4. 添付ファイルのアップロード

   * 添付ファイルが 0 件の場合はスキップ。
   * 各ファイルについて:

     * オブジェクトパスを生成: `tenant-{tenant_id}/post-{post_id}/{uuid}.{ext}`
     * Supabase Storage `board-attachments` に `upload()`
     * 失敗時はログ出力し、投稿全体をエラーとして扱う（ロールバック方針は現行実装に合わせる）。

5. `board_attachments` への INSERT

   * アップロード成功ごとに `board_attachments` にレコードを追加。
   * 使用値:

     * `tenant_id`: 上記で取得した値
     * `post_id`: 3. で作成した投稿ID
     * `file_url`: アップロード時のパスまたは URL
     * `file_name`: `file.name`
     * `file_type`: `file.type`
     * `file_size`: `file.size`

6. レスポンス

   * 成功時: `201` + `{ postId: string }`
   * 失敗時: `4xx/5xx` + エラーメッセージ

### 6.2 編集時の添付追加／削除

* 追加:

  * `PUT /api/board/posts/{postId}` 等の既存エンドポイントを拡張し、新規添付分だけを `FormData` で受け取り、6.1 の 4〜5 と同じ処理を行う。
* 削除:

  * BoardPostForm の編集画面から、添付 ID ごとに「削除」リクエストを送信する。
  * エンドポイント例: `DELETE /api/board/posts/{postId}/attachments/{attachmentId}`
  * サーバ側処理:

    1. `board_attachments` から対象レコードを取得（`tenant_id` と投稿者IDをチェック）。
    2. `file_url` を基に Storage から `remove()`。
    3. 正常終了時に `board_attachments` レコードを DELETE。

## 7. バリデーション・制約

* 対象ファイル種別: `application/pdf` のみ。
* サイズ上限: 1 ファイルあたり 10MB 程度（実際の値は定数で管理し、必要に応じて変更可能とする）。
* 添付数上限: 一旦制限なしでもよいが、UI/パフォーマンス上の問題が出る場合は別途上限を検討する。

## 8. テスト観点（受け入れ条件）

### 8.1 正常系

1. 添付なし投稿

   * 投稿が正常に作成される。
   * `board_attachments` にレコードが作成されない。

2. 単一 PDF 添付

   * 投稿が作成される。
   * Storage `board-attachments` に 1 ファイル保存される。
   * `board_attachments` に 1 レコード作成される。

3. 複数 PDF 添付

   * すべてのファイルが Storage + `board_attachments` に保存される。

4. 編集画面で添付追加

   * 既存添付に加えて新規添付が追加保存される。

5. 編集画面で添付削除

   * 指定した添付のみ Storage + `board_attachments` から削除される。

### 8.2 異常系

1. 非 PDF ファイルを選択

   * フロント側でエラー表示し、送信しない。

2. サイズ超過

   * フロント側でエラー表示し、送信しない。

3. Storage へのアップロード失敗

   * 投稿全体を失敗として扱い、エラーメッセージを返す。

## 9. CodeAgent_Report 保存先

* 本タスクに対する CodeAgent_Report は、以下に保存すること。

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_Attachments_v1.0.md`
