# WS-B02 BoardDetail お気に入り（★）実装指示書_v1.0

## 1. ゴール

* 掲示板詳細画面 BoardDetail（B-02）に「お気に入り（★）トグル」機能を追加する。
* ログインユーザが任意の掲示板投稿をお気に入り登録／解除できるようにし、将来的にマイページで「お気に入り一覧」を表示できるようにする。
* 既に schema.prisma に追加済みの `board_favorites` テーブル定義を前提とし、そのテーブルを用いて実装する。

## 2. 対象スコープ

### 2.1 フロントエンド

* 対象コンポーネント（想定）

  * `app/board/[postId]/page.tsx`（BoardDetail ページ）
  * `src/components/board/BoardDetail/BoardDetail.tsx`（または同等コンポーネント）
* 対象機能

  * BoardDetail 画面のヘッダに「お気に入り★」トグルを表示する。
  * クリックでお気に入り登録／解除 API を呼び出し、UI 状態を即時反映する。
  * 「掲示板TOPのカテゴリフィルタに『☆ お気に入り』タブを追加し、ON 時はログインユーザのお気に入り投稿のみを一覧表示する。」

### 2.2 バックエンド

* 対象 API ルート（新規）

  * `POST   /api/board/favorites`   … お気に入り登録
  * `DELETE /api/board/favorites`   … お気に入り解除
* 既存の BoardDetail 用取得関数

  * `getBoardPostDetail(tenantId, postId, currentUserId)` を拡張し、

    * ログインユーザにとっての `isFavorite: boolean` を返すようにする。

### 2.3 将来スコープ（今回のWSでは実装しないが考慮すること）

* マイページでの「お気に入り一覧」表示。

  * `GET /api/board/favorites` を用いて、`board_favorites` + `board_posts` を JOIN した一覧を返す想定。

## 3. 仕様リファレンス

* DB スキーマ: `/mnt/data/schema.prisma.txt` 内 `board_favorites` 定義（TKD 追記済み）。
* 掲示板設計サマリ: `/mnt/data/B-00_HarmoNet-bbs-board Design-decision-summary_v1.0.md`（お気に入り仕様を後で追記予定）。

## 4. DB / RLS 前提

### 4.1 `board_favorites` モデル（前提）

* 想定定義:

```prisma
model board_favorites {
  id         String   @id @default(uuid())
  tenant_id  String
  user_id    String
  post_id    String
  created_at DateTime @default(now())

  tenant tenants     @relation(fields: [tenant_id], references: [id])
  user   users       @relation(fields: [user_id], references: [id])
  post   board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)

  @@unique([tenant_id, user_id, post_id])
}
```

* 1ユーザ1投稿につき1件のみ（`@@unique`）。
* 親投稿削除時に自動削除（`onDelete: Cascade`）。

### 4.2 RLS / Supabase 側

* 本WSでは、Prisma 経由で `board_favorites` を操作する前提のため、RLS 側の変更は不要。
* 将来 Supabase 経由で直接参照する場合は、`tenant_id = auth.jwt().tenant_id AND user_id = auth.uid()` を基本としたポリシーを検討する。

## 5. API 実装

### 5.1 `POST /api/board/favorites`（登録）

1. 認証情報から `tenant_id` / `user_id` を取得する。
2. リクエストボディ JSON をパースし、`postId` を取得する。
3. `board_posts` から `tenant_id` 一致かつ `id = postId` の投稿が存在することを確認する（存在しない場合は 404）。
4. Prisma を用いて `board_favorites` に INSERT する。

   * `tenant_id`, `user_id`, `post_id` をセット。
   * `@@unique([tenant_id, user_id, post_id])` による一意制約により、既に存在する場合は `upsert` もしくは unique violation を無視する形で冪等に扱う。
5. レスポンス

   * 成功時: `200` + `{ isFavorite: true }` を返す。
   * エラー時: `4xx/5xx` + `{ errorCode: "favorite_create_failed" }`（ログ出力必須）。

### 5.2 `DELETE /api/board/favorites`（解除）

1. 認証情報から `tenant_id` / `user_id` を取得する。
2. リクエストボディ JSON から `postId` を取得する。
3. `board_favorites` に対して、`tenant_id`, `user_id`, `post_id` で `deleteMany` を実行する。
4. レスポンス

   * 成功時（削除件数 0 でも）: `200` + `{ isFavorite: false }` を返す。
   * エラー時: `{ errorCode: "favorite_delete_failed" }`。

### 5.3 BoardDetail 取得関数の拡張

* 対象関数: `getBoardPostDetail(tenantId, postId, currentUserId)`。
* 追加仕様:

  * 既存の `BoardPostDetail` 型に `isFavorite: boolean` を追加する。
  * ロジック:

```ts
const favorite = await prisma.board_favorites.findUnique({
  where: {
    tenant_id_user_id_post_id: {
      tenant_id: tenantId,
      user_id: currentUserId,
      post_id: postId,
    },
  },
})

return {
  ...postDetail,
  isFavorite: !!favorite,
}
```

### 5.4 BoardTop 用フィルタ拡張（カテゴリ「☆」）

- 既存の掲示板一覧取得関数（例: `getBoardPostList`）に `filter = 'favorite'` を追加する。
- `filter = 'favorite'` の場合:
  - 現在の `tenant_id` / `user_id` で `board_favorites` を JOIN し、
  - 該当ユーザがお気に入り登録した `board_posts` のみを返す。
- BoardTop のカテゴリフィルタの最後に「☆」ボタンを追加し、
  - ☆ ON → `filter = 'favorite'`
  - 他カテゴリとは排他（同時選択不可）

* `currentUserId` が存在しない（未ログイン）場合は `isFavorite = false` とする。

## 6. フロントエンド実装

### 6.1 BoardDetail コンポーネント

1. `BoardPostDetail` 型に `isFavorite: boolean` を追加し、サーバ関数の戻り値と揃える。

2. タイトル行の右端に Lucide `Star` アイコンを追加する。

   * `isFavorite = true` のときは塗りつぶし表示（filled）、`false` のときはアウトライン表示。
   * `aria-label` は `"お気に入りに追加"` / `"お気に入りを解除"` を `isFavorite` に応じて切り替える。

3. クリックハンドラ

* 疑似コード:

```ts
const [isFavorite, setIsFavorite] = useState(post.isFavorite)
const [isUpdating, setIsUpdating] = useState(false)

async function handleToggleFavorite() {
  if (isUpdating) return
  setIsUpdating(true)
  try {
    const method = isFavorite ? 'DELETE' : 'POST'
    const res = await fetch('/api/board/favorites', {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ postId: post.id }),
    })

    if (!res.ok) throw new Error('Favorite API error')
    const data = await res.json()
    setIsFavorite(data.isFavorite)
  } catch (e) {
    // エラー時はトーストなどで通知（"お気に入りの更新に失敗しました"）
  } finally {
    setIsUpdating(false)
  }
}
```

* `isUpdating = true` の間はボタンを無効化して二重クリックを防止する。

### 6.2 BoardTop との整合

* 本WSでは BoardTop の UI 変更は必須ではないが、可能であれば：

  * `getBoardList` の戻り値に `isFavorite` を追加し、
  * カテゴリフィルタの最後に『☆』タブを追加し、ON時にお気に入りのみ表示する
* トグル操作を BoardTop からも行う場合は、BoardDetail と同じ API を利用する（ただし、この部分は別WSでもよい）。

## 7. テスト観点

### 7.1 バックエンド

* `/api/board/favorites`（POST）

  * 正常系: 存在しない `tenant_id, user_id, post_id` 組み合わせに対して 1件作成されること。
  * 冪等性: 既に存在する場合でもエラーにならず 200 / `isFavorite: true` が返ること。
* `/api/board/favorites`（DELETE）

  * 正常系: 対象レコードが削除され、200 / `isFavorite: false` が返ること。
  * 対象レコードが存在しなくても 200 を返すこと。
* `getBoardPostDetail`

  * `board_favorites` が存在するとき `isFavorite = true`、存在しないとき `false` となること。

### 7.2 フロントエンド

* BoardDetail コンポーネントのテスト

  * 初期レンダリングで `post.isFavorite` に応じたアイコンが表示されること。
  * クリックで `fetch('/api/board/favorites', { method: 'POST' })` / `DELETE` が呼ばれること。
  * API の戻り値に応じて `isFavorite` state が切り替わること。
  * エラー時にメッセージが表示されること（簡易で可）。

## 8. CodeAgent_Report 保存先

* 本タスクに対する CodeAgent_Report は、以下に保存すること。

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-B02_BoardDetail_Favorites_v1.0.md`
