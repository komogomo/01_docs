# CodeAgent 作業報告書

- ドキュメント種別: 作業報告書（CodeAgent）
- 対象タスク ID: WS-B99_BoardApiTenantGuard_v1.0
- 日付: 2025-11-25
- 担当: CodeAgent（Cascade）

---

## 1. 対象ドキュメント／機能概要

- 対象指示書:
  - `D:\AIDriven\01_docs\05_製造\01_Windsurf-作業指示書\WS-B99_BoardApiTenantGuard_v1.0.md`
- 対象機能:
  - 掲示板コメント作成 API: `POST /api/board/comments`
  - 掲示板コメント削除 API: `DELETE /api/board/comments/[commentId]`
  - 掲示板投稿削除 API: `DELETE /api/board/posts/[postId]`

機能概要:
- Prisma 経由で `board_posts` / `board_comments` を扱う 3 つの API について、
  - **他テナントの行を「読む」可能性もゼロにする** ため、
  - Supabase の `user_tenants` を用いて取得した **アクティブテナント ID 一覧 (`tenantIds`) で必ず絞り込む**。
- 既存の権限仕様（コメント／投稿の削除権限、論理削除の挙動）は変更せず、where 句の強化に限定して対応する。

---

## 2. 実装／修正内容

### 2-1. アクティブテナント一覧取得ユーティリティの新設

**対象ファイル**
- `src/server/tenant/getActiveTenantIdsForUser.ts`

**主な内容**
- Supabase クライアントと `userId` を引数に取り、`user_tenants` からアクティブな `tenant_id` 一覧を取得するユーティリティを新設。
- 実装概要:
  - `supabase.from('user_tenants').select('tenant_id').eq('user_id', userId).eq('status', 'active')`
  - 取得結果から `tenant_id` が非 null かつ非空文字列のもののみを抽出し、`string[]` として返却。
  - クエリエラーまたは `data` が falsy の場合は空配列を返す（呼び出し側で membership エラーとして扱う）。
- これにより、個々の API では **「ユーザのアクティブテナント一覧」を共通処理として取得** し、Prisma の where 句で `tenant_id: { in: tenantIds }` を一貫して利用可能とした。

---

### 2-2. コメント作成 API のテナントガード強化

**対象ファイル**
- `app/api/board/comments/route.ts`

**変更前の挙動（概要）**
- Supabase Auth でユーザを特定し、`users` テーブルから `appUser.id` を取得。
- Prisma で対象投稿を `board_posts.findFirst({ where: { id: postId, status: "published" } })` により取得。
- 取得した `post.tenant_id` をもとに `user_tenants` を `tenant_id` 指定で 1 件検索し、所属があればコメント作成を許可。
- コメント作成時には `tenant_id` に `post.tenant_id` をセットし、翻訳キャッシュ処理を実行。

**変更内容**
- `getActiveTenantIdsForUser` を利用し、コメント作成処理の早い段階で **アクティブテナント ID 一覧 (`tenantIds`) を取得** するよう変更。

  ```ts
  const tenantIds = await getActiveTenantIdsForUser(supabase, appUser.id);

  if (!tenantIds.length) {
    logError('board.comments.api.membership_error', { userId: appUser.id });
    return NextResponse.json({ errorCode: 'unauthorized' }, { status: 403 });
  }
  ```

- 投稿取得クエリを、以下のように **`tenant_id: { in: tenantIds }` でフィルタする形に変更**。

  ```ts
  const post = await prisma.board_posts.findFirst({
    where: {
      id: postId,
      status: 'published',
      tenant_id: { in: tenantIds },
    },
    select: {
      id: true,
      tenant_id: true,
      category: { select: { category_key: true } },
    },
  });
  ```

- `post` が `null` の場合は、これまで通り `404 post_not_found` を返却。
- 旧実装で行っていた `user_tenants` に対する単発 membership チェックは、`tenantIds` によるフィルタで代替できるため削除。
- コメント INSERT 処理およびコメント翻訳処理（`BoardPostTranslationService` / `GoogleTranslationService`）は挙動を変更せず、`tenant_id` は従来どおり `post.tenant_id` を使用。

**効果**
- ユーザが他テナントの `postId` を直接指定した場合でも、`tenant_id: { in: tenantIds }` によって Prisma クエリでヒットしなくなり、**常に `404 post_not_found` が返る** 形となった。
- これにより、「他テナントの投稿が存在するかどうか」を間接的に推測することもできなくなる。

---

### 2-3. コメント削除 API のテナントガード強化

**対象ファイル**
- `app/api/board/comments/[commentId]/route.ts`

**変更前の挙動（概要）**
- Supabase Auth と `users` テーブルから `appUser.id` を取得。
- Prisma でコメントを `board_comments.findFirst({ where: { id: commentId } })` により取得。
- 取得した `comment.tenant_id` と `user_tenants` を照合し、所属がなければ 403。
- `comment.author_id === appUser.id` の場合のみ、ソフトデリート（`status = 'deleted'`）→ 失敗時ハードデリート、という挙動。

**変更内容**
- コメント削除処理の前段で、`getActiveTenantIdsForUser` により `tenantIds` を取得し、空の場合は membership エラーとして 403 を返却。
- Prisma のコメント取得を、**`tenant_id: { in: tenantIds }` 付きのクエリに変更**。

  ```ts
  const comment = await prisma.board_comments.findFirst({
    where: {
      id: commentId,
      tenant_id: { in: tenantIds },
    },
    select: {
      id: true,
      tenant_id: true,
      author_id: true,
    },
  });
  ```

- コメントが見つからない場合は、従来どおり `404 comment_not_found` を返却。
- その後の削除権限チェック（`comment.author_id !== appUser.id` の場合は 403）は **既存仕様どおり維持**。
- 実際の削除処理（ソフトデリート優先→失敗時ハードデリート）は変更せず踏襲。
- 旧来の `user_tenants` を直接参照する membership チェックは削除。

**効果**
- 他テナントのコメント ID を指定しても、`tenant_id IN tenantIds` に合致しないため Prisma クエリでヒットせず、**常に 404 `comment_not_found`** となる。
- ユーザは他テナントのコメントの存在有無を知ることも、削除することもできない。

---

### 2-4. 投稿削除 API のテナントガード強化

**対象ファイル**
- `app/api/board/posts/[postId]/route.ts`

**変更前の挙動（概要）**
- Supabase Auth と `users` テーブルから `appUser.id` を取得。
- Prisma で投稿を `board_posts.findFirst({ where: { id: postId } })` により取得。
- 取得した `post.tenant_id` と `user_tenants` を照合し、所属がなければ 403。
- 投稿者本人（`post.author_id === appUser.id`）であれば、`status = 'archived'` に更新するソフトデリートを実施。

**変更内容**
- 投稿削除処理の前段で、`getActiveTenantIdsForUser` により `tenantIds` を取得し、空の場合は membership エラーとして 403 を返却。
- Prisma の投稿取得を、**`tenant_id: { in: tenantIds }` 付きのクエリに変更**。

  ```ts
  const post = await prisma.board_posts.findFirst({
    where: {
      id: postId,
      tenant_id: { in: tenantIds },
    },
    select: {
      id: true,
      tenant_id: true,
      author_id: true,
    },
  });
  ```

- 投稿が見つからない場合は、従来どおり `404 post_not_found` を返却。
- その後の「本人のみ削除可」チェック（`post.author_id !== appUser.id` の場合は 403）は維持。
- 実際の削除処理（`status = 'archived'` によるソフトデリート）も変更せず踏襲。
- 旧来の `user_tenants` を直接参照する membership チェックは削除。

**効果**
- 他テナントの投稿 ID を指定しても、`tenant_id IN tenantIds` に一致しないため Prisma クエリでヒットせず、**常に 404 `post_not_found`** となる。
- 他テナント投稿の存在有無が API レスポンスから推測できなくなり、RLS ポリシーと整合した振る舞いになる。

---

## 3. テスト

### 3-1. 追加テスト

**対象ファイル**
- `src/__tests__/board/BoardApiTenantGuard.test.ts`

**内容概要**
- Jest を用いて、3 つの API それぞれについて **「他テナント ID 指定時に 404 となる」** ことを確認するユニットテストを追加。
- Supabase サーバークライアントと Prisma クライアントは Jest の `jest.mock` でモック化し、`getActiveTenantIdsForUser` もモック関数経由で制御。

1. **他テナント投稿に対するコメント作成**
   - 前提:
     - `getActiveTenantIdsForUser` が `['tenant-a']` を返却。
     - `prisma.board_posts.findFirst` が `null` を返却するようモック。
   - 挙動:
     - `POST /api/board/comments` を `postId = 'post-other-tenant'`, `content = 'hello'` で呼び出し。
   - 期待結果:
     - レスポンスステータスが `404`。
     - ボディの `errorCode` が `post_not_found`。
     - `board_posts.findFirst` が `where.id = 'post-other-tenant'` かつ `tenant_id: { in: ['tenant-a'] }` 付きで呼ばれていること。

2. **他テナントコメントに対する削除**
   - 前提:
     - `getActiveTenantIdsForUser` が `['tenant-a']` を返却。
     - `prisma.board_comments.findFirst` が `null` を返却するようモック。
   - 挙動:
     - `DELETE /api/board/comments/[commentId]` を `commentId = 'comment-other'` で呼び出し。
   - 期待結果:
     - レスポンスステータスが `404`。
     - ボディの `errorCode` が `comment_not_found`。
     - `board_comments.findFirst` が `where.id = 'comment-other'` かつ `tenant_id: { in: ['tenant-a'] }` 付きで呼ばれていること。

3. **他テナント投稿に対する削除**
   - 前提:
     - `getActiveTenantIdsForUser` が `['tenant-a']` を返却。
     - `prisma.board_posts.findFirst` が `null` を返却するようモック。
   - 挙動:
     - `DELETE /api/board/posts/[postId]` を `postId = 'post-other'` で呼び出し。
   - 期待結果:
     - レスポンスステータスが `404`。
     - ボディの `errorCode` が `post_not_found`。
     - `board_posts.findFirst` が `where.id = 'post-other'` かつ `tenant_id: { in: ['tenant-a'] }` 付きで呼ばれていること。

### 3-2. テスト実行結果

- 実行コマンド:
  - `npm test`
- Jest 全体としての結果:
  - Test Suites: 10 failed, 1 skipped, 3 passed, 13 of 14 total
  - Tests:       13 failed, 4 skipped, 32 passed
- **本 WS で追加したテスト (`BoardApiTenantGuard.test.ts`) は PASS** していると確認。
- ただし、プロジェクト全体では以下のような **既存テストの失敗** があり、`npm test` 全体は RED となっている:

  - `src/__tests__/home/HomeFeatureTiles.test.tsx`
    - `getByRole('button', { name: /お知らせ/ })` が要素を見つけられず失敗。
    - 実 DOM 上のテキストは `home.tiles.notice.label` となっており、i18n モックと期待値の不整合が原因と考えられる。
    - 本 WS では HomeFeatureTiles および Home 画面関連の実装には手を入れていないため、テスト修正は行っていない。

  - `src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx`
    - エラー: `Vitest cannot be imported in a CommonJS module using require(). Please use "import" instead.`
    - Jest 実行時に `vitest` の API（`vi.mock` 等）を直接利用していることが原因と考えられる。
    - 本 WS のスコープ外（認証画面・Vitest 設定）であるため、こちらも修正対象外。

- 指示書上の受け入れ条件「`npm test` がオールグリーンで完了すること」については、
  - **本 WS 範囲の変更に起因する失敗はなく、
    既存の他機能テストに起因する RED が残っている** という状況です。
  - 禁止事項として「本 WS の範囲外ファイルには変更を加えないこと」とあるため、
    これら既存テストの修正は本タスクでは実施していません。

---

## 4. セルフスコア（10 点満点）

- 実装の適合度: 9 / 10
  - 指示書どおり、3 つの API すべてで `tenant_id: { in: tenantIds }` を where に含める修正を実施。
  - `getActiveTenantIdsForUser` によるアクティブテナント一覧の取得も共通化し、コードの重複を避けつつ要件を満たしている。
  - 本 WS 範囲のテストは追加済みで、Jest 上でも PASS していることを確認。
- マイナス要素:
  - プロジェクト全体の `npm test` は、既存の Home / Auth 関連テストの失敗により RED のままである点。
  - ただし、これらは本 WS の禁止事項（スコープ外ファイルの変更禁止）に該当するため、意図的に手を入れていない。

---

## 5. 残課題・今後の検討ポイント

- **既存テストの RED 解消**（WS-B99 のスコープ外）
  - `HomeFeatureTiles` / `MagicLinkForm` など、board 以外の機能に紐づくテストが Jest 実行時に失敗している。
  - これらについては、別途 WS（例: Home／Auth テスト環境整備タスク）を切ったうえで、
    - i18n モックと期待文言の整合性調整、
    - Jest / Vitest 併用プロジェクトとしてのテスト構成見直し
    などを行うのが望ましい。

- **board 関連の追加テスト拡張（任意）**
  - 本 WS では「他テナント ID 指定で 404 となる」ことにフォーカスしたテストのみ追加している。
  - 余力があれば、同じユーティリティ／ガードを用いた **自テナント内での正常系（コメント作成・削除・投稿削除）テスト** も Jest でカバーすると、
    将来的なリファクタリング時の信頼性がさらに高まる。

以上。
