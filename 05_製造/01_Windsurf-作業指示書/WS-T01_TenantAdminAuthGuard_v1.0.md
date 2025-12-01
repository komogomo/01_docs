# Windsurf 作業指示書: テナント管理者認証ガードの実装 (WS-T01)

本ドキュメントは、HarmoNet のテナント管理者コンソール (`/t-admin`) における認証・認可ガードを強化・統一するための作業指示書である。

## 1. 目的とゴール
*   **目的:** `/t-admin` 配下の認証ロジックを統一し、実装漏れを防ぐ「安全な最小構成」にする。
*   **ゴール:**
    1.  **Middleware ガード:** `/t-admin` へのアクセス時に未ログイン・権限不足を即座に弾く。
    2.  **統一エントリポイント:** Server Components 内での認証・コンテキスト取得を単一のヘルパー関数で行う。
    3.  **既存コードの整理:** 各ページに散在する個別チェック処理を削除・統合する。

## 2. 作業ルール（厳守）
*   **バックアップ:** 既存ファイルを変更する場合は、**必ず事前にバックアップコピーを作成すること**。
    *   例: `cp app/t-admin/layout.tsx app/t-admin/layout.tsx.bk`
    *   作業完了後、問題なければバックアップは削除してよいが、作業中は保持する。
*   **禁止事項:**
    *   DBスキーマ ([prisma/schema.prisma](file:///d:/Projects/HarmoNet/prisma/schema.prisma)) の変更。
    *   RLSポリシーの変更。
    *   ディレクトリ構成の変更。
    *   一般ユーザー向け画面 (`/board` 等) への変更。

## 3. 実装ステップ

### Step 1: Middleware 用 Supabase クライアントの作成
Middleware 内でセッション管理と DB アクセスを行うためのユーティリティを作成する。

*   **作成ファイル:** `src/lib/supabase/middleware.ts` (新規作成)
*   **要件:**
    *   `@supabase/ssr` の `createServerClient` を使用。
    *   `NextRequest` と `NextResponse` を受け取り、Cookie を適切に処理する `updateSession` 関数をエクスポート。
    *   **重要:** この関数内で以下の処理を行うこと。
        1.  `supabase.auth.getUser()` でユーザー取得。
        2.  未ログインなら `/login` へリダイレクト。
        3.  ログイン済みなら、`user_roles` テーブルを検索し、`tenant_admin` ロールを持っているか確認。
            *   *Note:* `user_roles` は `user_id` と `tenant_id` で検索する必要があるが、URLパラメータ等から `tenant_id` が特定できない場合（ルート直下など）、どう判定するか？
            *   *補足:* `/t-admin` はテナント管理機能であり、通常はログインユーザーが所属するテナントの管理者であることを確認する。ここでは「いずれかのテナントの `tenant_admin` であること」または「特定のテナントコンテキスト（URL等）があればその管理者であること」をチェックするロジックが望ましいが、まずは「未ログイン排除」を最優先とし、ロールチェックは可能な範囲（DBアクセス負荷を考慮）で実装する。
            *   **指示:** 今回はシンプルに **「未ログインチェック」** と **「`/t-admin` 配下へのアクセス権（ロール有無）」** のチェックを行う。
        4.  権限なしなら `/home` (またはトップ) へリダイレクト。

### Step 2: Middleware の実装
Next.js の Middleware を配置し、`/t-admin` 配下をガードする。

*   **作成ファイル:** `middleware.ts` (ルートディレクトリ)
*   **要件:**
    *   `matcher` を `['/t-admin/:path*']` に設定。
    *   Step 1 で作成した `updateSession` を呼び出す。

### Step 3: サーバーサイド認証ヘルパーの作成
Server Components で使用する統一的な認証コンテキスト取得関数を作成する。

*   **作成ファイル:** `src/lib/auth/tenantAdminAuth.ts` (新規作成)
*   **要件:**
    *   関数名: `getTenantAdminContext()` (または類似)
    *   処理内容:
        1.  [createSupabaseServerClient()](file:///d:/Projects/HarmoNet/src/lib/supabaseServerClient.ts#4-28) でクライアント作成。
        2.  `getUser()` でユーザー取得。
        3.  `user_tenants` から所属テナントIDを取得。
        4.  `user_roles` から `tenant_admin` 権限を確認。
        5.  認証エラー、権限エラー時は、この関数内で `redirect()` を投げるか、エラーを返して呼び出し元でリダイレクトさせる（`redirect` を投げる方が実装漏れが少ないため推奨）。
    *   戻り値: `{ user, tenantId, tenantName }` などのコンテキスト情報。

### Step 4: 既存ページの改修
既存の `/t-admin` 配下のページをリファクタリングする。

*   **対象:** [app/t-admin/layout.tsx](file:///d:/Projects/HarmoNet/app/t-admin/layout.tsx), `app/t-admin/**/page.tsx`
*   **作業手順:**
    1.  **バックアップ作成** ([.bk](file:///d:/Projects/HarmoNet/app/favicon.ico.bk) ファイル)。
    2.  各ファイルの冒頭にある個別の `supabase.auth.getUser()` や `user_roles` チェック処理を削除。
    3.  代わりに Step 3 の `getTenantAdminContext()` を呼び出す形に変更。
    4.  取得した `tenantId` 等を使って後続の処理を行う。

## 4. 検証項目
実装後、以下の動作を確認すること。

1.  **未ログインアクセス:** シークレットウィンドウで `/t-admin/users` にアクセスし、ログイン画面へリダイレクトされるか。
2.  **一般ユーザーアクセス:** 一般ユーザーでログイン後、`/t-admin/users` にアクセスし、ホーム画面等へリダイレクトされるか（403 Forbidden でも可）。
3.  **管理者アクセス:** テナント管理者でログイン後、`/t-admin/users` が正常に表示されるか。
4.  **リグレッション:** 既存のホーム画面や掲示板が正常に動作するか（Middlewareの影響がないか）。

## 5. 提出物
*   修正したソースコード一式
*   削除したバックアップファイルは、動作確認完了後に指示があれば削除する（今回は残したままでよい）。
