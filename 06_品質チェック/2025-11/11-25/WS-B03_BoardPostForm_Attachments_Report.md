# WS-B03 BoardPostForm 添付機能 実装レポート

## 1. 概要

本タスクでは、掲示板新規投稿画面（`/board/new`）における添付ファイル機能の実装と、それに付随する表示名（匿名／ニックネーム）・動的翻訳・詳細画面でのプレビュー機能の整備を行いました。

最終的に以下が実現されています。

- 新規投稿時に PDF / Office / 画像(JPG/PNG) の添付（最大5件・5MB/件）
- Supabase Storage へのアップロードと `board_attachments` 登録
- 掲示板詳細ページでの PDF / 画像プレビュー＆全ファイルダウンロード
- 一般利用者の「匿名で投稿する」選択時に、一覧／詳細で「匿名」表示
- 投稿本文の EN / ZH への動的翻訳とキャッシュ保存・表示

---

## 2. スコープ・要件整理

- 対象フロー：
  - `/board/new` からの「新規投稿」時のみ
  - 編集・削除時の添付追加／削除は別タスク
- 添付仕様：
  - 許可される MIME：PDF、Office（Word/Excel/PowerPoint）、画像（JPG/PNG）
  - 1ファイル最大：5MB
  - 1投稿あたり最大：5件
  - 設定値は将来テナント設定から変更可能なように**一元管理**
- バックエンド：
  - `/api/board/posts` を JSON / multipart 両対応に
  - Supabase Storage `board-attachments` バケットに保存
  - `board_attachments` テーブルにメタ情報登録
  - 失敗時は投稿と添付をロールバック
- 詳細表示：
  - Storage のオブジェクトパスを直接見せず、API 経由で配信
  - PDF プレビュー / 画像プレビュー / ダウンロードをサポート
- 表示名：
  - 一般利用者：ラジオボタンで「匿名で投稿する」 or 「ニックネームを表示する」
  - 管理組合投稿：管理組合名固定表示（ラジオなし）
- 動的翻訳：
  - 投稿作成時に ja→en/zh を翻訳
  - `board_post_translations` へキャッシュ保存し、一覧／詳細で利用

---

## 3. 実装内容

### 3.1 DB スキーマ変更（Prisma / Supabase）

**ファイル:** `prisma/schema.prisma`

- `board_posts` に著者表示名カラムを追加

  ```prisma
  model board_posts {
    id                  String @id @default(uuid())
    tenant_id           String
    category_id         String
    author_id           String
    author_display_name String?   // ★ 追加
    title               String
    content             String @db.Text
    status              board_post_status @default(draft)
    created_at          DateTime @default(now())
    updated_at          DateTime @updatedAt
    ...
  }
  ```

- `board_post_translations` / `board_comment_translations` は既存モデルを利用（`id` / `created_at` / `updated_at` が NOT NULL）。

**DB 反映：**

- `npx prisma db push` で Supabase の `board_posts` テーブルに `author_display_name` カラムを追加済み。

---

### 3.2 添付設定の一元管理

**ファイル:** `src/lib/boardAttachmentSettings.ts`

- 添付仕様を一元管理する設定モジュールを定義／更新。

  - 許可 MIME を PDF / Office / JPG / PNG に拡張
  - `maxSizePerFileBytes = 5MB`
  - `maxCountPerPost = 5`
  - 将来 tenant_settings からの上書きを想定した構造

- フロント／バックでこの設定モジュールを参照し、同一ルールでバリデーションを実施。

---

### 3.3 投稿 API `/api/board/posts`（新規投稿）

**ファイル:** `app/api/board/posts/route.ts`

#### (1) JSON / multipart 両対応

- `Content-Type` を見て、
  - `multipart/form-data` → `req.formData()` 経由で
  - `application/json` → 従来どおり `req.json()`
  としてパラメータを取得。

- multipart 時に取得する主なフィールド：
  - `tenantId`, `authorId`, `categoryKey`, `title`, `content`
  - `forceMasked`, `uiLanguage`
  - `displayNameMode`（`anonymous` / `nickname`）
  - `attachments`（`File[]`）

#### (2) 添付バリデーション

- `getBoardAttachmentSettingsForTenant(tenantId)` を利用し、
  - 個数上限：`attachmentSettings.maxCountPerPost`
  - MIME 許可：`attachmentSettings.allowedMimeTypes`
  - サイズ上限：`attachmentSettings.maxSizePerFileBytes`
- 違反時は `400 validation_error` を返却（WS の仕様に沿ったエラーコード）。

#### (3) 投稿 INSERT と添付アップロード

- `board_posts` へ INSERT：
  - AI モデレーション結果に応じて `title` / `content` をマスク or そのまま
  - `author_display_name`：
    - `displayNameMode === 'anonymous'` の場合のみ `'匿名'` を保存
    - それ以外（ニックネーム）は `null`（従来どおり `users.display_name` を使用）

- 添付ファイルがある場合：
  - `createSupabaseServiceRoleClient()` で `board-attachments` バケットにアップロード
  - オブジェクトパス形式：
    - `tenant-${tenantId}/post-${postId}/${uuid}.${ext}`
  - `board_attachments` に以下を登録：
    - `tenant_id`, `post_id`, `file_url`（オブジェクトパス）, `file_name`, `file_type`, `file_size`

- 添付アップロードまたは `board_attachments` 登録でエラー発生時：
  - 関連 `board_attachments` を delete
  - `board_posts` 本体も delete
  - `500 attachment_upload_failed` を返却

#### (4) 翻訳処理のトリガ

- 投稿成功後、`BoardPostTranslationService` を使って
  - 日本語→英語・中国語の翻訳
  - `board_post_translations` にキャッシュ保存

---

### 3.4 一覧 API `/api/board/posts`（BoardTop / Home）

**ファイル:** `app/api/board/posts/route.ts`

- `prisma.board_posts.findMany` で
  - カテゴリ・翻訳・添付有無・著者情報を取得。
- `BoardPostSummaryDto` の `authorDisplayName` を決定するロジック：

  ```ts
  const authorDisplayName =
    (post as any).author_display_name && typeof (post as any).author_display_name === 'string'
      ? (post as any).author_display_name
      : post.author.display_name;
  ```

- これにより、
  - 一般利用者で「匿名で投稿する」を選んだ投稿 → `author_display_name = "匿名"` が優先
  - それ以外 → `users.display_name`（管理組合アカウントなど）が使用される。

---

### 3.5 添付ダウンロード API

**ファイル:** `app/api/board/attachments/[attachmentId]/route.ts`

- エンドポイント：`GET /api/board/attachments/{attachmentId}`

- 処理内容：
  - Supabase Server Client でログインユーザー／テナントを判定
  - `board_attachments` から `id` と `tenant_id` でレコード取得
  - 対応する `board_posts` が同一テナントかつ `published` であることを確認
  - `createSupabaseServiceRoleClient()` 経由で Storage から `download(file_url)`
  - Content-Type / Content-Length / Content-Disposition をセットしてバイナリを返却

- これにより、`board_attachments.file_url`（オブジェクトパス）は外部に露出せず、
  - プレビュー用 iframe / img
  - ダウンロード用リンク
  は常にこの API を経由する。

---

### 3.6 投稿詳細取得 `getBoardPostById`

**ファイル:** `src/server/board/getBoardPostById.ts`

- 添付：
  - `board_attachments.file_url` をそのまま返さず、
  - `fileUrl: /api/board/attachments/${attachment.id}` を `BoardAttachmentDto` にセット。
- 著者名：
  - 一覧 API と同様に `author_display_name` があればそれを優先し、なければ `users.display_name`。

---

### 3.7 フロントエンド：投稿フォーム

**ファイル:** `src/components/board/BoardPostForm/BoardPostForm.tsx`

- 添付ファイル UI：
  - `accept` 属性を設定モジュールから生成（PDF / Office / JPG / PNG）
  - ファイル選択時に
    - 種別（MIME）・サイズ・総数をチェック
    - 不許可の場合はエラーメッセージ（3言語）を表示
    - 6件目以降はリストに追加せず、「最大5件」エラーのみ表示
- 送信：
  - 添付ありの場合、`FormData` に各フィールド＋`attachments` を詰めて `/api/board/posts` に `multipart/form-data` で送信。
- 表示名：
  - 一般利用者：ラジオボタン
    - 「匿名で投稿する」 / 「ニックネームを表示する」
  - 管理組合として投稿時（posterType=management）：ラジオは表示せず、「管理組合として投稿する」の固定文言。

---

### 3.8 フロントエンド：詳細画面プレビュー

**ファイル:** `src/components/board/BoardDetail/BoardDetailPage.tsx`

- 添付リスト表示レイアウトを調整：
  - 1行目：ファイル名（折り返し・最大2行）
  - 2行目：サイズ（KB）
  - 3行目右側：プレビュー／ダウンロードボタン
  - 長いファイル名でもボタンが縦長にならないように調整。

- プレビューボタンの挙動：
  - 判定関数：
    - `isPdfAttachment(fileType, fileName)`  
    - `isImageAttachment(fileType, fileName)`：JPG / JPEG / PNG 判定
  - `isPdf || isImage` の場合に「プレビュー」ボタンを表示。
  - モーダル内：
    - PDF → `<iframe src={url}>`
    - 画像 → `<img src={url} className="object-contain">`

- ダウンロードボタン：
  - すべての添付に対して `href={file.fileUrl}`（= `/api/board/attachments/{id}`）で新規タブ。

---

### 3.9 動的翻訳サービス

**ファイル:** `src/server/services/translation/BoardPostTranslationService.ts`

- `translateAndCacheForPost`：
  - OpenAI 翻訳（GoogleTranslationService 経由）で EN / ZH 翻訳
  - `board_post_translations` へ upsert
    - 常に `id: randomUUID()`
    - `created_at`, `updated_at` を `new Date().toISOString()` で明示的にセット
    - `onConflict: 'post_id,lang'` により、同一投稿・同一言語は上書き

- `translateAndCacheForComment`：
  - 同様に `board_comment_translations` にコメント翻訳を upsert（今後のコメント機能向け）。

- これにより、NOT NULL 制約付きの `id` / `created_at` / `updated_at` によるエラーを解消し、  
  新規投稿の EN / ZH 表示が機能。

---

## 4. 実装された主な機能一覧

- **添付機能**
  - PDF / Office / 画像(JPG/PNG) 添付（最大5件・5MB/件）
  - Supabase Storage & `board_attachments` 連携
  - 詳細画面での PDF / 画像プレビュー（モーダル）
  - ダウンロードリンク（API 経由）

- **表示名制御**
  - 一般利用者：
    - 「匿名で投稿する」→ 「匿名」として表示
    - 「ニックネームを表示する」→ ユーザーの `display_name`
  - 管理組合：
    - 投稿者区分＝管理組合時は管理組合アカウント名を表示（ラジオなし）

- **動的翻訳**
  - 投稿作成時に ja→en/zh 翻訳
  - `board_post_translations` にキャッシュ保存
  - BoardTop / 詳細で言語タブ切り替えにより翻訳済み本文を表示

- **エラーハンドリング・ロールバック**
  - 添付アップロード失敗時の投稿／添付ロールバック
  - 翻訳 API エラー時はログ出力のみで投稿自体は成功させるフェイルソフト設計

---

以上が、今回の WS-B03 における改修内容と最終実装のレポートです。
