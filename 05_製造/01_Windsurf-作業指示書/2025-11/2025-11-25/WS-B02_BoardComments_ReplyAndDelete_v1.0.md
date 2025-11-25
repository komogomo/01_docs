# WS-B02 BoardComments 返信＋自投稿削除 実装指示書_v1.0

## 1. ゴール

* 掲示板投稿に対する「返信（コメント）」機能を実装する。
* 返信は **既存の掲示板投稿画面 BoardPostForm** を利用して行う（専用画面は増やさない）。
* 返信は `board_comments` テーブルで管理し、将来の自投稿削除に対応できるようにしておく。
* BoardDetail では、返信ボタン／返信一覧／自分の返信の削除ボタンを提供する。
* BoardTop では、各投稿の返信数をアイコン＋件数で表示する。

## 2. 前提・対象スコープ

### 2.1 前提

* Prisma スキーマに `board_comments` モデルが既に定義済みであること。
* 掲示板投稿（`board_posts`）・ユーザ（`users`）・テナント（`tenants`）の RLS／認証は既に導入済み。
* BoardPostForm（新規投稿画面）は添付／翻訳／モデレーションまで実装済み。fileciteturn12file0

### 2.2 スコープ

* BoardDetail:

  * 本文直下のアクション行に「返信」ボタンを追加し、BoardPostForm（返信モード）へ遷移させる。
  * `board_comments` に保存された返信一覧を表示する。
  * 自分の返信のみ削除できる UI を提供する（削除 API 呼び出し）。
* BoardTop:

  * 各投稿カードに「返信数」アイコン＋件数を表示する（クリップ添付アイコンの左隣）。
* BoardPostForm:

  * `replyTo` クエリパラメータを解釈し、「通常投稿モード」と「返信モード」を切り替える。
  * 返信モード時は `/api/board/comments` に POST する。

## 3. DB モデル（前提確認）

```prisma
model board_comments {
  id                String   @id @default(uuid())
  tenant_id         String
  post_id           String        // 親: board_posts.id
  author_id         String
  content           String   @db.Text
  parent_comment_id String?       // 将来のコメントへの返信に利用可（現時点では null 想定）
  created_at        DateTime @default(now())
  updated_at        DateTime @updatedAt
  status            comment_status @default(active)

  tenant tenants     @relation(fields: [tenant_id], references: [id])
  post   board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)
  author users       @relation(fields: [author_id], references: [id])
}
```

* 本WSでは `status = active` のみを対象とする。
* 親投稿削除時に `board_comments` は自動削除される（`onDelete: Cascade`）。

## 4. API 仕様

### 4.1 返信作成 API: `POST /api/board/comments`

* ファイル: `app/api/board/comments/route.ts`（新規）
* メソッド: `POST`
* リクエストボディ（JSON）:

```json
{
  "postId": "<board_posts.id>",
  "content": "・・・返信本文・・・"
}
```

* サーバ処理フロー:

  1. 認証から `tenant_id`, `user_id` を取得する。
  2. `postId` が未指定または空の場合は `400 { errorCode: "validation_error" }` を返す。
  3. `board_posts` から `tenant_id = tenantId` かつ `id = postId` かつ `status = 'published'` の投稿を取得し、存在しない場合は `404 { errorCode: "post_not_found" }`。
  4. グループタグなどにより、現在ユーザがその投稿を閲覧可能か（RLS 前提）を確認する。
  5. `content` が空または一定文字数未満の場合は `400 { errorCode: "comment_empty" }`。
  6. `board_comments` に INSERT:

     * `tenant_id = tenantId`
     * `post_id = postId`
     * `author_id = user_id`
     * `content = content`
     * `status = 'active'`
  7. 成功時: `201 { ok: true }` を返す（必要なら `commentId` も返却してよい）。
  8. 失敗時: `500 { errorCode: "comment_create_failed" }` を返し、詳細はログに出力する。

### 4.2 返信削除 API: `DELETE /api/board/comments/[commentId]`

* ファイル: `app/api/board/comments/[commentId]/route.ts`（新規）
* メソッド: `DELETE`
* パスパラメータ: `commentId: string`
* サーバ処理フロー:

  1. 認証から `tenant_id`, `user_id` を取得する。
  2. `board_comments` から `id = commentId` のレコードを取得する。
  3. 見つからない場合は `404 { errorCode: "comment_not_found" }`。
  4. `tenant_id` が一致しない場合、および `author_id != user_id` かつ 管理ロールでもない場合は `403 { errorCode: "forbidden" }`。
  5. 条件を満たす場合、`delete` を実行する。
  6. 成功時: `200 { ok: true }` を返す。
  7. 失敗時: `500 { errorCode: "comment_delete_failed" }`。

### 4.3 返信一覧取得（サーバ関数）

* ファイル例: `src/server/board/getBoardCommentsForPost.ts`

```ts
type BoardCommentSummary = {
  id: string
  content: string
  authorDisplayName: string
  createdAt: string
  isDeletable: boolean
}

export async function getBoardCommentsForPost(
  tenantId: string,
  postId: string,
  currentUserId: string | null,
): Promise<BoardCommentSummary[]> {
  // Prisma で board_comments を取得し、表示名ロジックと isDeletable を組み立てる
}
```

* クエリ条件:

  * `tenant_id = tenantId`
  * `post_id = postId`
  * `status = 'active'`
  * `created_at` 降順
* `authorDisplayName` ロジック:

  * 当面は `users.display_name` を使用（将来 `author_display_name` などと揃える余地あり）。
* `isDeletable`:

  * `author_id = currentUserId` のとき `true`、それ以外は `false`（管理者による削除は将来拡張で対応）。

## 5. BoardPostForm 側の変更（返信モード）

### 5.1 URL パラメータ

* `/board/new?replyTo={postId}` を解釈する。
* `replyTo` あり → 返信モード、なし → 通常投稿モード。

### 5.2 UI 挙動

* 返信モード時（`replyTo` あり）の追加表示:

  * フォーム上部に控えめなテキストで「この投稿への返信です」等のメッセージを表示。
  * 親投稿のタイトルを 1 行サマリで表示できれば望ましい（WS 内で `getBoardPostTitleById` などを呼んでよい）。
* それ以外の UI（タイトル／本文／添付／翻訳／モデレーション）は通常投稿モードと同一。

### 5.3 送信先 API の分岐

* 既存の submit ロジックを拡張し、`replyTo` の有無で送信先を切り替える。

疑似コード:

```ts
const searchParams = useSearchParams()
const replyTo = searchParams.get('replyTo')

const isReplyMode = !!replyTo

async function handleSubmit(values: FormValues) {
  // values から本文などを構築

  if (isReplyMode) {
    // 返信モード → /api/board/comments
    const res = await fetch('/api/board/comments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        postId: replyTo,
        content: values.body,
      }),
    })

    // 成功時の遷移先は BoardDetail (/board/[postId]) に戻す
  } else {
    // 通常投稿 → 既存どおり /api/board/posts
  }
}
```

* 返信モード時は、既存の添付／翻訳／モデレーション処理のうち、「返信に対して意味がある部分」のみを残す必要があればWS側で調整するが、基本は **同じロジックをそのまま流用** してよい。

### 5.4 送信後の遷移先

* 通常投稿: 既存仕様どおり（`/board` など）。
* 返信投稿: **親投稿の詳細画面** に戻す。

  * 例: `/board/${replyTo}` に `router.push`。

## 6. BoardDetail の UI 変更

### 6.1 返信ボタン

* 配置:

  * 本文直下のアクション行（翻訳／読上げの並び）の左端。
  * 並び順（左→右）:

    1. 返信ボタン
    2. 翻訳アイコン（Lucide `Languages`）
    3. 読上げアイコン（Lucide `Volume2`）

* 仕様:

  * ボタンラベル: `返信する`（i18n キー例: `board.detail.reply.action`）。
  * アイコン: Lucide `MessageCircle`（または同系の吹き出しアイコン）。
  * `aria-label="この投稿に返信する"`。
  * クリックで `/board/new?replyTo={postId}` に遷移。

### 6.2 返信一覧表示

* 返信セクションの構成:

  * 見出し: `返信`（i18n キー: `board.detail.reply.heading`）。
  * 返信が 0 件の場合: 「表示できる返信はありません。」などのメッセージを表示（任意）。
  * 返信が 1 件以上ある場合: `BoardCommentSummary[]` を時系列降順で表示。

* 1件あたりの表示要素:

  * 1行目: `authorDisplayName`（左）＋ `createdAt`（右）
  * 2行目以降: `content`（改行を反映したテキスト表示）
  * 自削除ボタン:

    * `isDeletable = true` の場合のみ、右上に小さなゴミ箱アイコン（Lucide `Trash2`）を表示。
    * クリックで `DELETE /api/board/comments/{id}` を呼び出し、成功時は当該コメントを一覧から削除。

### 6.3 エラーハンドリング

* 返信送信失敗時:

  * 画面下部トーストやフォーム直下に「返信の送信に失敗しました。」を表示（i18n キー: `board.detail.reply.error.submit`）。
* 返信削除失敗時:

  * 「返信の削除に失敗しました。」を表示（i18n キー: `board.detail.reply.error.delete`）。

## 7. BoardTop の返信数表示

### 7.1 データ取得

* 掲示板一覧取得ロジック（`getBoardPostList` 相当）で、`board_comments` を集計し `replyCount: number` を DTO に追加する。
* 集計方法（Prisma 例）:

```ts
const posts = await prisma.board_posts.findMany({
  // 既存条件
  include: {
    _count: {
      select: { comments: true },
    },
  },
})

// DTO 組み立て時に replyCount = post._count.comments
```

### 7.2 UI 配置

* カード右上にあるクリップアイコン（添付有無）を基準に、その左隣に返信数を表示する。
* 表示内容:

  * アイコン: Lucide `MessageCircle`（`h-4 w-4` 程度）。
  * テキスト: 返信件数（例: `3`）。
* ホバー `title="返信 3件"`（i18n）。
* クリック挙動はなし（現時点では単なる件数表示）。

## 8. テスト観点

### 8.1 バックエンド

* `POST /api/board/comments`

  * 正常系: 有効な `postId` と `content` でコメントが作成されること。
  * 異常系: `postId` 不正、`content` 空、閲覧権限無しの投稿などで適切なステータス・エラーコードを返すこと。

* `DELETE /api/board/comments/[commentId]`

  * 正常系: 自分のコメントを削除できること。
  * 異常系: 他人のコメント削除時に 403 となること／存在しないIDで 404 となること。

### 8.2 フロントエンド

* BoardPostForm

  * `/board/new`（replyTo 無し）では通常投稿フローが維持されていること。
  * `/board/new?replyTo=xxx` では返信モードとなり、`/api/board/comments` が呼ばれること。
  * 返信成功時に親投稿詳細画面に戻ること。

* BoardDetail

  * 「返信する」ボタンが本文アクション行の左端に表示されること。
  * 返信送信後に BoardDetail で返信一覧に新しいコメントが表示されること（再描画 or 再フェッチ）。
  * 自分の返信にのみ削除アイコンが表示され、削除後に一覧から消えること。

* BoardTop

  * 返信件数が 0 の投稿では `0` またはアイコン非表示（どちらか仕様に合わせて）となること。
  * 返信が 1件以上ある投稿で正しい件数が表示されること。

## 9. CodeAgent_Report 保存先

* 本タスクに対する CodeAgent_Report は、以下に保存すること。

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-B02_BoardComments_ReplyAndDelete_v1.0.md`
