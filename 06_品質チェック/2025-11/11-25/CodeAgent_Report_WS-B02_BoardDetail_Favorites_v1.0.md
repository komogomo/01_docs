# WS-B02 BoardDetail Favorites 作業レポート

## 1. 作業概要

- **目的**
  - 掲示板詳細画面 BoardDetail に「お気に入り（★）」トグルを追加し、ユーザが任意の投稿をお気に入り登録／解除できるようにする。
  - 掲示板TOP 画面 BoardTop に「☆ お気に入り」フィルタタブを追加し、ログインユーザのお気に入り投稿のみを一覧表示できるようにする。
- **前提**
  - Prisma スキーマに `board_favorites` モデルが定義済みであること。
  - Supabase Auth＋Prisma によるユーザ／テナント認証が既に導入済みであること。

## 2. 変更ファイル一覧

### バックエンド / API / サーバサイド

- `prisma/schema.prisma`
  - `board_favorites` モデルとそのリレーション（`tenants`, `users`, `board_posts`）を確認。
  - `board_posts` に `favorites board_favorites[]` リレーションを追加済み。
- `app/api/board/posts/route.ts`
  - `BoardPostSummaryDto` に `isFavorite: boolean` を追加。
  - `GET /api/board/posts` で、ログインユーザ向けの `favorites` を include し、`isFavorite` を算出して返却。
- `app/api/board/favorites/route.ts`（新規）
  - `POST   /api/board/favorites` … お気に入り登録。
  - `DELETE /api/board/favorites` … お気に入り解除。
- `src/server/board/getBoardPostById.ts`
  - `BoardPostDetailDto` に `isFavorite: boolean` を追加。
  - `getBoardPostById` 内で `board_favorites` を参照し、`isFavorite` を設定。

### フロントエンド / 画面側

- `src/components/board/BoardTop/types.ts`
  - `BoardTab` を `"all" | BoardCategoryKey | "favorite"` に拡張。
  - `BoardPostSummary` に `isFavorite: boolean` を追加。
- `src/components/board/BoardTop/BoardTopPage.tsx`
  - API レスポンス DTO に `isFavorite?: boolean` を追加し、`BoardPostSummary` にマッピング。
  - フィルタロジックを拡張し、`tab === "favorite"` のとき `post.isFavorite` が `true` の投稿のみを表示。
  - タブ変更ハンドラ `handleChangeTab` を追加し、`tab` 更新と同時に URL クエリ `?tab=...` を `router.replace()` で反映（`favorite` を含む）。
- `src/components/board/BoardTop/BoardTabBar.tsx`
  - カテゴリタブ列の最後に `BoardTab = "favorite"` 用の「☆」タブを追加。
  - アクティブ時: `border-yellow-400 text-yellow-400`、非アクティブ時: `border-gray-200 text-gray-500`。
- `src/components/board/BoardDetail/BoardDetailPage.tsx`
  - `data.isFavorite` を初期値とする `isFavorite` state を追加。
  - タイトル直下・本文タイル直前に右寄せの★ボタンを配置。
  - ★ボタン押下時に `/api/board/favorites` へ `POST` / `DELETE` を発行し、レスポンスの `isFavorite` に応じて state を更新。
  - エラー時に小さな赤字メッセージを表示（`board.detail.favorite.error`）。

### 文言 / 多言語

- `public/locales/ja/common.json`
  - `board.top.tab.favorite`: 「お気に入り」。
  - `board.detail.favorite.add`: 「お気に入りに追加」。
  - `board.detail.favorite.remove`: 「お気に入りを解除」。
  - `board.detail.favorite.error`: 「お気に入りの更新に失敗しました。時間をおいて再度お試しください。」
- `public/locales/en/common.json`
  - `board.top.tab.favorite`: "Favorites"。
  - `board.detail.favorite.add`: "Add to favorites"。
  - `board.detail.favorite.remove`: "Remove from favorites"。
  - `board.detail.favorite.error`: "Failed to update favorites. Please try again later."。
- `public/locales/zh/common.json`
  - `board.top.tab.favorite`: 「收藏」。
  - `board.detail.favorite.add`: 「加入收藏」。
  - `board.detail.favorite.remove`: 「取消收藏」。
  - `board.detail.favorite.error`: 「更新收藏状态失败，请稍后重试。」。

## 3. 実装詳細

### 3-1. `board_favorites` モデル前提

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

- 1ユーザ1投稿につき 1 レコード（`@@unique`）。
- 親投稿削除時に自動削除（`onDelete: Cascade`）。

### 3-2. `/api/board/favorites` の仕様

#### 共通

- 認証
  - Supabase Auth → `users`（メール一致・`status = active`）→ `user_tenants`（`status = active`）で `tenantId` / `userId` を決定。
- リクエストボディ
  - JSON `{ postId: string }`（`postId` が無い場合は `400 validation_error`）。

#### `POST /api/board/favorites`

1. 認証・テナント解決（上記）。
2. `board_posts` から `tenant_id = tenantId` かつ `id = postId` かつ `status = 'published'` の投稿があるか確認（無ければ `404 not_found`）。
3. Prisma で `board_favorites.upsert` を実行：
   - where: `tenant_id_user_id_post_id`（複合一意キー）。
   - create: `tenant_id, user_id, post_id` を保存。
   - update: 空オブジェクト（存在時は何も更新しない）。
4. 成功時: `200 { isFavorite: true }` を返却。
5. エラー時: `500 { errorCode: "favorite_create_failed" }` を返却し、詳細は `logError` で記録。

#### `DELETE /api/board/favorites`

1. 認証・テナント解決。
2. `board_favorites.deleteMany({ tenant_id, user_id, post_id })` を実行。
3. レコードが存在しなくても成功扱いとし、`200 { isFavorite: false }` を返却。
4. エラー時: `500 { errorCode: "favorite_delete_failed" }` を返却。

### 3-3. BoardDetail の `isFavorite` 取得

- `getBoardPostById({ tenantId, postId, currentUserId })` 内で、投稿取得後に `board_favorites` を参照：

```ts
const favorite = await (prisma as any).board_favorites.findFirst({
  where: {
    tenant_id: tenantId,
    user_id: currentUserId,
    post_id: postId,
  },
  select: { id: true },
});

const isFavorite = !!favorite;
```

- 戻り値 `BoardPostDetailDto` に `isFavorite` を追加し、BoardDetailPage に渡す。

### 3-4. BoardDetail の UI 仕様

- ★ボタン配置
  - カテゴリバッジ＋投稿日時
  - タイトル
  - 投稿者名
  - **上記の直下・本文カード直前** に右寄せで★ボタンを配置。
- 見た目
  - ボタン: `h-7 w-7` の丸ボタン（`border-2 bg-white`）。
  - アクティブ（`isFavorite = true`）
    - クラス: `border-yellow-400 text-yellow-400`
    - アイコン: Lucide `Star`（アウトラインのみ、塗りつぶし無し）。
  - 非アクティブ
    - クラス: `border-gray-200 text-gray-400 hover:border-yellow-300 hover:text-yellow-400`。
- アクセシビリティ
  - `aria-label` を `isFavorite` に応じて変更：
    - 追加前: `board.detail.favorite.add`
    - 追加後: `board.detail.favorite.remove`

- クリック挙動（疑似コード）

```ts
const [isFavorite, setIsFavorite] = useState(data.isFavorite ?? false);
const [isUpdatingFavorite, setIsUpdatingFavorite] = useState(false);

async function handleToggleFavorite() {
  if (isUpdatingFavorite) return;
  setIsUpdatingFavorite(true);
  setFavoriteErrorKey(null);

  try {
    const method = isFavorite ? "DELETE" : "POST";
    const res = await fetch("/api/board/favorites", {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ postId: data.id }),
    });

    if (!res.ok) throw new Error("favorite_api_error");

    const json = (await res.json().catch(() => ({}))) as { isFavorite?: boolean };
    setIsFavorite(typeof json.isFavorite === "boolean" ? json.isFavorite : !isFavorite);
  } catch {
    setFavoriteErrorKey("board.detail.favorite.error");
  } finally {
    setIsUpdatingFavorite(false);
  }
}
```

- `isUpdatingFavorite = true` の間はボタンを disabled にし、二重リクエストを防止。

### 3-5. BoardTop の「☆ お気に入り」タブ

- `BoardTab` 型に `"favorite"` を追加。
- `BoardTopPage` のフィルタロジック：

```ts
const filteredPosts = useMemo(() => {
  if (tab === "all") return posts;
  if (tab === "favorite") {
    return posts.filter((post) => post.isFavorite);
  }
  return posts.filter((post) => post.categoryKey === (tab as BoardCategoryKey));
}, [posts, tab]);
```

- タブ UI (`BoardTabBar`) の最後に追加：

```tsx
const id: BoardTab = "favorite";
const active = activeTab === id;
const baseClasses =
  "whitespace-nowrap rounded-full px-3 py-1.5 font-medium border-2 transition-colors";
const activeClasses = "bg-white text-yellow-400 border-yellow-400";
const inactiveClasses = "bg-white text-gray-500 border-gray-200";

<button
  key={id}
  type="button"
  onClick={() => onChange(id)}
  className={`${baseClasses} ${active ? activeClasses : inactiveClasses}`}
  data-testid={`board-top-tab-${id}`}
  aria-label={t("board.top.tab.favorite")}
>
  <Star className="h-4 w-4" aria-hidden="true" />
</button>
```

- `tab` 状態と URL の連動
  - タブ切替時に `handleChangeTab` を呼び出し、`router.replace()` で `?tab=favorite` などを付与。
  - 初期値算出時にも `tab=favorite` を有効な値として解釈。

## 4. 動作確認

### 4-1. BoardDetail（お気に入りトグル）

1. 任意の掲示板投稿詳細画面を開く。
2. タイトル下・本文タイル直前の★ボタンがグレー枠＋グレーアイコンで表示されることを確認。
3. ★ボタンをクリック：
   - ボタンが黄色枠＋黄色アイコンに変化すること。
   - ネットワークタブで `POST /api/board/favorites` が 200 を返却していること。
4. 再度クリック：
   - ボタンがグレー表示に戻ること。
   - `DELETE /api/board/favorites` が 200 を返却していること。

### 4-2. BoardTop（☆フィルタ）

1. `/board` に遷移し、カテゴリタブ列の最後に ☆ タブが表示されていることを確認。
2. ☆タブをクリック：
   - タブ枠とアイコンが黄色（枠＝`border-yellow-400`、文字＝`text-yellow-400`）になること。
   - URL が `/board?tab=favorite` となること。
   - お気に入り登録済みの投稿のみ一覧に表示されること。
3. 他のタブを選択：
   - それぞれのカテゴリに応じて一覧が切り替わること。
   - URL `tab` パラメータも `tab=important` 等に切り替わること。

## 5. 残課題・今後の拡張余地

1. **BoardTop からの直接トグル**
   - 現時点では BoardDetail からのみお気に入り登録／解除を行う設計。
   - 将来的には BoardTop の各カードにも★アイコンを表示し、一覧画面からもトグル操作ができるようにする余地がある（同一 API を再利用）。

2. **マイページ「お気に入り一覧」**
   - 指示書にある通り、マイページから `board_favorites` を基にした一覧を表示する `GET /api/board/favorites` は今回未実装。
   - 今後、`board_favorites`＋`board_posts` を JOIN した DTO を返す API と、その UI を追加する想定。

3. **パフォーマンス最適化**
   - 現状、BoardDetail 表示ごとに `board_favorites.findFirst` を 1 回発行している。
   - 規模拡大時には、`board_posts` と `board_favorites` の JOIN でまとめて取得する、あるいはキャッシュ層を用意する検討余地がある。

---

以上が、WS-B02 BoardDetail Favorites（お気に入り）機能の実装・確認内容のレポートです。
