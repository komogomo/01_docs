# WS-B99 Board API Multi-Tenant Guard 強化実装指示書 v1.0

## 1. ゴール / 概要

* Prisma 経由で掲示板関連の行を取得する API について、**他テナントの行を「読む」可能性もゼロにする**。
* 既存の権限仕様（誰がコメント/投稿を削除・返信できるか）は変えず、**where 句に tenant フィルタを必ず含める形に改修**する。
* 対象は以下 3 エンドポイントのみとし、スキーマや RLS ポリシーには一切手を入れない。

  * `POST /api/board/comments`（コメント作成）
  * `DELETE /api/board/comments/[commentId]`（コメント削除）
  * `DELETE /api/board/posts/[postId]`（投稿削除）

CodeAgent_Report の保存先：

* `/01_docs/06_品質チェック/CodeAgent_Report_WS-B99_BoardApiTenantGuard_v1.0.md`

---

## 2. スコープ

### 2.1 対象

* リポジトリ：`D:/Projects/HarmoNet`
* Next.js App Router プロジェクト。
* Prisma を通じて `board_posts` / `board_comments` を操作している API ルート。

対象ファイル（想定パス）：

1. コメント作成 API

   * `app/api/board/comments/route.ts`
2. コメント削除 API

   * `app/api/board/comments/[commentId]/route.ts`
3. 投稿削除 API

   * `app/api/board/posts/[postId]/route.ts`

### 2.2 非スコープ

* DB スキーマ変更（`schema.prisma` やマイグレーションの追加）は禁止。
* Supabase RLS ポリシーの変更は禁止。
* 掲示板の UI / コンポーネント（BoardTop / BoardDetail / BoardPostForm）の JSX やスタイルは変更しない。
* 管理ロールによる「他人の投稿・コメント削除」機能の追加はこの WS の対象外（今後別タスクで扱う）。

---

## 3. 事前条件 / 契約

### 3.1 認証・テナント情報の前提

* Supabase Auth により、API 内では現在ユーザを識別できる状態であること。
* アプリケーション側ユーザテーブル `users` と、テナント所属テーブル `user_tenants` が既に存在し、

  * `user_tenants.user_id` + `user_tenants.tenant_id` + `status = 'active'` で「アクティブな所属テナント」を取得できる前提とする。
* 掲示板関連テーブル `board_posts` / `board_comments` には `tenant_id` が存在し、ユーザ所属テナントと一致していること。

### 3.2 既存仕様として維持する点

* コメント削除：

  * 「自分が投稿したコメントのみ削除できる」仕様は維持する。
* 投稿削除：

  * 現在実装されている権限条件（投稿者本人または管理ロール等）は維持し、今回の改修で変更しない。
* ステータスの扱い：

  * 物理削除 / 論理削除の方針は現行実装を踏襲する（この WS では変更しない）。

---

## 4. 実装ルール

### 4.1 テナントフィルタの基本方針

* すべての対象 API で、次の順序を必ず守ること：

  1. Supabase 経由で **現在のアプリケーションユーザ ID** を取得する。
  2. `user_tenants` から、そのユーザの **アクティブな `tenant_id` 一覧** を取得する。
  3. Prisma クエリでは、**必ず `tenant_id: { in: tenantIds }` を where 条件に含める**。
  4. `findFirst` / `findUnique` の結果が `null` の場合、**404 Not Found** として扱う。
* これにより、ID を直接指定されても **他テナントの行は一切ヒットしない** ようにする。

### 4.2 共通ユーティリティ関数

* `user_tenants` からアクティブテナント一覧を取得する処理は、可能な限り共通化する。
* 例）`src/server/tenant/getActiveTenantIdsForUser.ts` のようなユーティリティを新設し、

  * 引数：`supabaseClient` / `userId`
  * 戻り値：`string[]`（tenantIds）
* ただし既存のディレクトリ構成・命名規則（`harmonet-frontend-directory-guideline_v1.0`）に反しない場所に置くこと。

### 4.3 エラーハンドリング

* テナント所属が 1 件も取得できなかった場合：

  * 401 または 403 を返す（現行実装に合わせる）。
* Prisma クエリ結果が `null`（= 自テナント内に対象行が存在しない）の場合：

  * **404 Not Found** を返す。
  * 他テナントの存在有無は推測できないようにする。
* 既存のエラーレスポンスフォーマット（`{ errorCode, message }` 等）があれば、それに揃える。

---

## 5. エンドポイント別の具体的変更指示

### 5.1 コメント作成 API (`POST /api/board/comments`)

対象ファイル：

* `app/api/board/comments/route.ts`

現状の問題点（概要）：

* `board_posts.findFirst({ where: { id: postId, status: "published" } })` のように、`tenant_id` で絞らずに投稿を取得している。
* その後に Supabase で `user_tenants` を参照して権限チェックしているが、「他テナントの投稿が存在するかどうか」は判別可能な構造になっている。

修正方針：

1. Supabase から現在ユーザとアクティブテナント一覧を取得する。

2. Prisma で投稿を取得する際、必ず `tenant_id: { in: tenantIds }` を条件に追加する：

   ```ts
   const post = await prisma.board_posts.findFirst({
     where: {
       id: postId,
       status: "published",
       tenant_id: { in: tenantIds },
     },
   });
   ```

3. `post` が `null` の場合：

   * 404 を返す（`return NextResponse.json({ errorCode: "not_found" }, { status: 404 })` など、現行スタイルに合わせる）。

4. それ以降の membership チェックは、**二重チェックとして残しても・削除しても良い**が、

   * 防御的に残す場合は `tenantIds` を使うのであれば簡略化できることを意識する。

5. コメント INSERT 時には、`tenant_id` に `post.tenant_id` をセットする現行仕様がある場合はそのまま踏襲する。

### 5.2 コメント削除 API (`DELETE /api/board/comments/[commentId]`)

対象ファイル：

* `app/api/board/comments/[commentId]/route.ts`

現状の問題点（概要）：

* `board_comments.findFirst({ where: { id: commentId } })` のように、`tenant_id` で絞っていない。
* その後で Supabase から membership を確認しているため、「コメントが他テナントに存在するか」は間接的に推測可能。

修正方針：

1. Supabase から現在ユーザとアクティブテナント一覧を取得する。

2. Prisma でコメントを取得する際、必ず `tenant_id: { in: tenantIds }` を条件に追加する：

   ```ts
   const comment = await prisma.board_comments.findFirst({
     where: {
       id: commentId,
       tenant_id: { in: tenantIds },
     },
   });
   ```

3. `comment` が `null` の場合：

   * 404 を返す。

4. `comment` が取得できた場合、**既存の「本人のみ削除可能」チェック**を維持する：

   ```ts
   if (comment.author_id !== appUser.id) {
     return NextResponse.json({ errorCode: "forbidden" }, { status: 403 });
   }
   ```

5. 削除自体の実装（物理削除 or `status = 'deleted'` など）は現行のまま踏襲する。

### 5.3 投稿削除 API (`DELETE /api/board/posts/[postId]`)

対象ファイル：

* `app/api/board/posts/[postId]/route.ts`

現状の問題点（概要）：

* `board_posts.findFirst({ where: { id: postId } })` で `tenant_id` を絞っていない。
* その後で membership / 権限チェックを行っているため、他テナントの投稿の存在有無を推測し得る。

修正方針：

1. Supabase から現在ユーザとアクティブテナント一覧を取得する。

2. Prisma で投稿を取得する際、必ず `tenant_id: { in: tenantIds }` を条件に追加する：

   ```ts
   const post = await prisma.board_posts.findFirst({
     where: {
       id: postId,
       tenant_id: { in: tenantIds },
     },
   });
   ```

3. `post` が `null` の場合：

   * 404 を返す。

4. `post` が取得できた場合、**既存の削除権限チェック**（投稿者本人 or 管理者ロール等）を維持する。

5. 削除自体の実装（物理削除 / 論理削除）は現行のまま踏襲する。

---

## 6. テスト

### 6.1 既存テストの確認

* 既に存在するユニットテスト / 結合テストがある場合は、改修後もすべて緑になることを確認する。
* とくに、

  * 自テナント内の投稿・コメントに対しては、これまで通り作成 / 削除ができること。

### 6.2 追加すべきテスト（最小）

テストフレームワークはプロジェクト既定（Vitest など）に合わせること。

1. **他テナント投稿に対するコメント作成**

   * 条件：

     * Aテナントのユーザでログイン。
     * Bテナントの `board_posts.id` を直接指定して `POST /api/board/comments` を叩く。
   * 期待結果：

     * 404 が返る。

2. **他テナントコメントに対する削除**

   * 条件：

     * Aテナントのユーザでログイン。
     * Bテナントの `board_comments.id` を直接指定して `DELETE /api/board/comments/[commentId]` を叩く。
   * 期待結果：

     * 404 が返る。

3. **他テナント投稿に対する削除**

   * 条件：

     * Aテナントの管理者ユーザでログイン（権限がある想定）。
     * Bテナントの `board_posts.id` を直接指定して `DELETE /api/board/posts/[postId]` を叩く。
   * 期待結果：

     * 404 が返る。

4. **自テナント内での通常動作が維持されていること**

   * 既存テスト or 簡易追加テストで、

     * 自テナント投稿へのコメント作成・削除が成功すること。
     * 自テナント投稿の削除が成功すること。

---

## 7. 受け入れ条件

Windsurf 実装の完了条件は次のとおりとする。

1. 3 つの API すべてで、Prisma のクエリに `tenant_id: { in: tenantIds }` が含まれていること。
2. 他テナントの ID を直接指定しても、常に 404 が返ること。
3. 自テナント内の通常操作（コメント作成/削除、投稿削除）が従来どおり成功すること。
4. 追加・変更したテストを含め、`npm test`（またはプロジェクト標準のテストコマンド）がオールグリーンで完了すること。
5. `[CodeAgent_Report]` にて、

   * 対象ファイル
   * 該当差分の概要
   * テスト結果
   * セルフスコア（10点満点）
     を記載し、`/01_docs/06_品質チェック/CodeAgent_Report_WS-B99_BoardApiTenantGuard_v1.0.md` に保存すること。

---

## 8. Meta / 禁止事項

* この WS の範囲外のファイル（UI コンポーネント、他の API ルート、設定ファイルなど）には変更を加えないこと。
* スキーマ・マイグレーション・RLS には手を触れないこと。
* ディレクトリ構成やファイル移動・リネームは行わないこと。
* 新たなライブラリの追加（`package.json` の変更）は禁止。
