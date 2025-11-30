# AG-WS-DB-Cleanup 実施報告書

## 1. 概要
`AG-WS-DB-Cleanup_RemoveUnusedStatusColumns_v1.0.md` に基づき、不要なステータスカラムの削除および関連コードの修正を実施しました。

## 2. 実施内容

### 2.1 データベース変更
以下のカラムを削除しました。
*   `tenants.is_active`
*   `users.status`
*   `user_tenants.status`
*   `user_tenants.joined_at`

**実施手順:**
1.  `prisma/schema.prisma` から定義を削除。
2.  `board_categories` テーブルの RLS ポリシー `board_categories_select` が `user_tenants.status` に依存していたため、手動で DROP しました。
3.  `npx prisma db push` を実行し、変更をデータベースに適用しました。
4.  `psql` コマンドにて、対象カラムが物理的に削除されていることを確認しました。

### 2.2 コード修正
以下のファイルにおいて、削除されたカラムへの参照（主に `.eq('status', 'active')` によるフィルタリング）を削除しました。

*   `app/auth/callback/route.ts`
*   `app/home/page.tsx`
*   `app/api/board/posts/route.ts`
*   `app/api/board/notifications/mark-seen/route.ts`
*   `app/api/board/notifications/has-unread/route.ts`
*   `app/api/board/attachments/[attachmentId]/route.ts`
*   `app/api/board/favorites/route.ts`
*   `prisma/seed.ts`

### 2.3 検証結果
*   **静的解析**: `tsc` (TypeScript Compiler) によるチェックを行い、削除されたカラムに関連する型エラーが解消されていることを確認しました。
*   **DB整合性**: `user_tenants` および `users` テーブル定義を確認し、カラムが削除されていることを確認しました。

## 3. 補足事項
*   `board_categories` の RLS ポリシー `board_categories_select` は削除された状態です。現行のアプリケーションロジック（Prisma 利用）では影響ありませんが、将来的に Supabase Client から直接 `board_categories` を参照する場合は、新たなポリシー（`status` チェックを含まないもの）を作成する必要があります。
*   `board_posts` 等の他のテーブルの RLS ポリシーは、JWT 内の `tenant_id` を使用する単純なチェックであったため、変更の影響を受けていません。

以上
