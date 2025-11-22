# MagicLink 認証トラブル＆修正レポート

このレポートは、HarmoNet における Supabase MagicLink 認証〜認可フローのトラブルと、その解消までの対応内容を整理したものです。
最終構成をベースに、時系列＋技術要素別にまとめています。

---

## 1. 目的と最終到達点

- **目的**
  - Supabase Auth（MagicLink + PKCE）を使い、  
    `/login → メール → MagicLink クリック → /auth/callback → /home`  
    というフローで
    - 認証（Supabase Auth セッション確立）
    - アプリ側ユーザマスタとの紐付け（`public.users`）
    - テナント所属（`public.user_tenants`）による認可  
    を行うこと。

- **最終到達点**
  - テストユーザ `ttakeda+sync5@gmail.com` で MagicLink ログインすると、
    安定して `/home` に遷移し、サーバ側での認可チェックも通る状態になった。

---

## 2. システム構成（最終形）

### 2-1. フロントエンド／認証

- **技術スタック**
  - Next.js App Router
  - `@supabase/ssr` の `createBrowserClient`

- **/login**
  - `MagicLinkForm` から `supabase.auth.signInWithOtp` を呼び出し、
    指定メールアドレスへ MagicLink を送信。
  - `emailRedirectTo` は `/auth/callback` を指す。

- **/auth/callback**
  - Client Component `AuthCallbackHandler` を表示。
  - Supabase クライアント設定:
    - `auth.flowType = 'pkce'`
    - `auth.detectSessionInUrl = true`
  - 処理フロー:
    - `supabase.auth.onAuthStateChange` で `SIGNED_IN` イベントを購読。
    - 初回に `supabase.auth.getSession()` で既にセッションがあるか確認。
    - いずれかでセッションが取得できたら `router.replace('/home')`。
    - 一定時間待ってもセッションが得られなければ `/login?error=auth_failed` に戻す。
  - ログ:
    - URL、`getSession` の結果、`onAuthStateChange` の状態変化などを `logInfo` で出力。

### 2-2. サーバサイド／認可

- **/home**
  - Server Component として実装。
  - `createSupabaseServerClient`（`@supabase/ssr` の `createServerClient` + Next.js `cookies()`）を使用。
  - 処理フロー:
    1. `supabase.auth.getUser()` で認証済みか確認。
    2. `public.users` から `id = jwt.sub` や `email` に基づきアプリユーザ（`appUser`）を取得。
    3. `public.user_tenants` から `user_id = appUser.id` かつ `status = 'active'` の membership を取得。
    4. 途中でエラーや未取得があればログ出力し `/login?error=...` にリダイレクト。
    5. すべて成功した場合のみ `/home` の UI を描画。

### 2-3. DB／Prisma／RLS

- **テーブル構成**
  - `auth.users`（Supabase 標準認証テーブル）
  - `public.users`（アプリ側ユーザマスタ）
  - `public.tenants`（テナント）
  - `public.user_tenants`（ユーザとテナントの紐付け）

- **ID 同期トリガー**
  - `auth.users` への `INSERT` をフックし、`public.users` に
    - `id`（`auth.users.id` と一致）
    - `email`
    - その他 NOT NULL カラム  
    を同期する `handle_new_auth_user` トリガー関数＋トリガーを用意。

- **RLS ポリシー（最終形）**
  - `users_select`:
    - `id = jwt.sub` または `tenant_id = jwt.tenant_id` の場合に閲覧可。
  - `user_tenants_select`:
    - `tenant_id = jwt.tenant_id`
    - **または** `user_id = jwt.sub`
    - のいずれかを満たす行だけ閲覧可。  
    → tenant_id クレームが無くても「自分自身の membership」は見える。

---

## 3. 主なトラブルと修正内容（時系列）

### 3-1. `/auth/callback` サーバ実装によるセッション不成立

- **現象**
  - MagicLink をクリックして `/auth/callback` に飛ぶと、
    毎回 `/login?error=no_session` などにリダイレクトされる。

- **原因**
  - `/auth/callback` を Server Component とし、
    サーバ側で `createClient(SERVICE_ROLE_KEY)` → `auth.getSession()` →
    `public.users` / `user_tenants` を参照する構成にしていた。
  - Supabase MagicLink（PKCE）は
    - URL の **フラグメント（`#` 以下）** にトークン／コードを埋め込む。
    - ブラウザの Supabase クライアントがそれを読み取り、**クライアント側でセッション確立**。
  - サーバコンポーネントからは URL フラグメントが見えないため、
    サーバ側の `auth.getSession()` は常にセッションなしとなり、認証失敗扱いになっていた。

- **修正**
  - `/auth/callback/page.tsx` を
    - Client Component をレンダリングするだけのシンプルなページに戻す。
  - 認証処理（セッション確立・リダイレクト）は `AuthCallbackHandler`（クライアント）で行う。
  - 認可処理（ユーザマスタ・テナントチェック）は `/home` Server Component に移動。

- **結果**
  - MagicLink の設計（クライアントでのセッション確立）と整合した構成となり、
    サーバ側でセッションを無理に取得しようとして失敗する問題を解消。

---

### 3-2. PKCE コード交換とレースコンディション

- **現象**
  - `/auth/callback` をクライアント側に戻しても、
    `auth.getSession()` を即座に呼ぶと `session = null` のことがある。
  - `exchangeCodeForSession` を手動で呼んだ際には、
    かえってエラーや 500 が発生した。

- **原因**
  - `@supabase/ssr` では、`auth.flowType = 'pkce'` かつ
    `auth.detectSessionInUrl = true` のとき、
    リダイレクト URL の `code` を自動検出して Exchange を行う。
  - この自動処理が完了する前に `getSession()` を呼んでいたため、
    レースコンディションで `null` が返るケースがあった。
  - さらに `exchangeCodeForSession` を手動で呼ぶと、
    自動処理と干渉したり、`code_verifier` 前提を満たせずエラーになる可能性があった。

- **修正**
  - `lib/supabaseClient.ts` で
    - `auth.flowType = 'pkce'`
    - `auth.detectSessionInUrl = true`
    を明示。
  - `AuthCallbackHandler` を再設計:
    - `supabase.auth.onAuthStateChange` で `SIGNED_IN` を監視。
    - 初期表示時に `auth.getSession()` を一度だけ試す。
    - いずれかでセッション取得できたら `/home` へ `router.replace`。
    - 一定時間内にセッションが得られなければ `/login?error=auth_failed` へ戻す。
  - 併せて URL (`href`), `getSession` 結果、`onAuthStateChange` 状態などを詳細ログ出力。

- **結果**
  - PKCE に伴うレースコンディションを解消。
  - MagicLink クリック後に安定して `auth.callback.success` →
    `auth.callback.redirect.home` のログが出るようになった。

---

### 3-3. `/home` での認可エラー（`public.users` 不整合）

- **現象**
  - `/auth/callback` から `/home` には来るが、
    `/home` 側で 500 エラーまたは `unauthorized` となり `/login` に戻される。

- **原因**
  - `auth.users.id`（JWT の `sub`）と `public.users.id` が一致していない状態で
    何度もシードや手動編集を繰り返していた。
  - RLS ポリシーは
    - `users_select` が「`id = jwt.sub` または `tenant_id = jwt.tenant_id`」の場合のみ閲覧可。
  - このため
    - `auth.getUser()` は成功するが
    - `public.users` への SELECT は RLS で弾かれ、`appUser` が `null` になる、
    という状態になっていた。

- **修正方針**
  - 真のソースを `auth.users` に統一し、
    `auth.users.id` / `email` を `public.users` に同期させるトリガーを導入。

---

### 3-4. `auth.users` → `public.users` 同期トリガーとその修正

1. **初回トリガー導入**
   - `supabase/migrations/20251118000002_sync_auth_users_to_public_users.sql` を作成し、
     `handle_new_auth_user` トリガー関数とトリガーを定義。
   - `auth.users` への INSERT 時に `public.users` にレコードを自動作成し、
     `id` / `email` を一致させる。

2. **NOT NULL カラム不足による失敗**
   - `public.users` には
     - `created_at`
     - `updated_at`
     - `status`
     など `NOT NULL` のカラムが存在。
   - トリガーでこれらを埋めていなかったため INSERT が失敗し、
     例外が Auth の 500 エラーとして表面化するケースがあった。

3. **トリガーのハードニング**
   - `20251118000003_fix_handle_new_auth_user.sql` で関数を修正し、
     `BEGIN ... EXCEPTION WHEN others THEN NULL; END;` で例外を握りつぶす形に。
   - これにより、`public.users` への INSERT が失敗しても
     Auth フロー自体は 500 にならないようにした。

4. **NOT NULL カラムをすべて明示的に挿入**
   - `20251118000004_fix_handle_new_auth_user_columns.sql` で再修正。
   - トリガー内の INSERT に
     - `tenant_id`（初期は NULL 可）
     - `language`（デフォルト `'ja'` 等）
     - `created_at`, `updated_at`（`now()`）
     - `status`（`'active'`）
     などを追加し、`NOT NULL` 制約をすべて満たすようにした。

- **結果**
  - 新規ユーザが MagicLink ログインするたびに、
    `auth.users` と `public.users` の `id` / `email` が一致したレコードが自動作成されるようになった。
  - `/home` で `appUser` を取得できるようになった。

---

### 3-5. Prisma シードスクリプトとユニーク制約エラー

- **現象**
  - `prisma/seed.ts` を複数回実行すると、
    `passkey_credentials` テーブルに対してユニーク制約エラーが発生。

- **原因**
  - `passkey_credentials` に対して毎回 `create` を行っており、
   既存レコードとユニークキーが重複していた。

- **修正**
  - `passkey_credentials` のシードを `upsert` に変更し、
    存在すれば更新、無ければ作成するようにした。

- **結果**
  - シードを何度実行しても安全になり、
    認証テスト用のデータ整備が容易になった。

---

### 3-6. RLS による `user_tenants` 不可視問題

- **現象**
  - `public.users` 取得は成功するが、
    `public.user_tenants` のクエリ結果が常に `null` となり、
    `/home` で `auth.callback.unauthorized.no_tenant` が記録される。

- **原因**
  - 当初の `user_tenants_select` ポリシー:
    ```sql
    USING (
      tenant_id::text = ((select auth.jwt()) ->> 'tenant_id')
    );
    ```
  - JWT にはまだ `tenant_id` クレームを実装しておらず、
    条件が常に false となっていた。
  - そのため、`user_tenants` に正しい行が存在していても RLS によって見えなかった。

- **修正**
  - ポリシーを次のように修正:
    ```sql
    USING (
      tenant_id::text = ((select auth.jwt()) ->> 'tenant_id')
      OR user_id = ((select auth.jwt()) ->> 'sub')
    );
    ```
  - これにより、
    - テナントクレームがある場合：従来どおり `tenant_id` で制御。
    - テナントクレームが無い場合：少なくとも「自分自身（`sub`）の行」は閲覧可能。

- **結果**
  - `/home` で本人の membership 情報を取得できるようになり、
    認可処理が RLS によってブロックされることはなくなった。

---

### 3-7. `user_tenants` レコード未作成による最終認可失敗

- **現象**
  - `ttakeda+sync5@gmail.com` でログインすると、
    - `home.debug.auth_user`（auth.user OK）
    - `home.debug.app_user_query`（public.users OK）
    までは出るが、
    - 最終的に `auth.callback.unauthorized.no_tenant` となり `/login?error=unauthorized` に戻される。

- **原因**
  - 認可ロジックは `public.users.tenant_id` ではなく
    `public.user_tenants` の membership を見ていた:
    ```ts
    .from('user_tenants')
    .select('tenant_id')
    .eq('user_id', appUser.id)
    .eq('status', 'active')
    .maybeSingle();
    ```
  - `public.users` には `tenant_id` を手動で入れていたが、
    `user_tenants` に対応する行が作成されていなかった。

- **修正**
  - Supabase SQL Editor で次を実行し、
    `harmonet-demo` テナントとの membership を作成:
    ```sql
    WITH u AS (
      SELECT id FROM public.users WHERE email = 'ttakeda+sync5@gmail.com'
    ),
    t AS (
      SELECT id FROM public.tenants WHERE tenant_code = 'harmonet-demo'
    )
    INSERT INTO public.user_tenants (user_id, tenant_id, status)
    SELECT u.id, t.id, 'active'
    FROM u, t
    ON CONFLICT DO NOTHING;
    ```

- **結果**
  - `/home` の membership チェックが成功し、
    `ttakeda+sync5@gmail.com` でのログイン後に安定して `/home` が表示されるようになった。

---

## 4. 最終的なログインフロー

1. `/login` でメールアドレスを入力し、`signInWithOtp` により MagicLink を送信。
2. ユーザーがメールの MagicLink をクリック → `/auth/callback` に遷移。
3. ブラウザ側:
   - `createBrowserClient` が URL の `code` / `hash` を検出。
   - PKCE フローで `exchange` を行い、セッションを確立。
4. `AuthCallbackHandler`:
   - `onAuthStateChange` で `SIGNED_IN` を検出。
   - セッションが確認できたら `router.replace('/home')`。
5. `/home` Server Component:
   - `auth.getUser()` で認証済みか確認。
   - `public.users` から `appUser` を取得。
   - `user_tenants` から active membership を取得。
   - すべて成功した場合にのみ `/home` を表示。
   - 失敗時は詳細ログを出力して `/login?error=...` にリダイレクト。

---

## 5. Lessons Learned / 今後の指針

- **MagicLink + PKCE の前提**
  - セッション確立は「クライアント側」で行う設計になっている。
  - Server Component だけで完結させようとすると今回のような `no_session` 問題が起きる。

- **認証と認可の分離**
  - 認証（Auth セッション確立）はクライアント or 汎用 SSR パターンに任せる。
  - 認可（ユーザマスタ・テナント所属チェック）は Server Component で行う。

- **`auth.users` をソースオブトゥルースにする**
  - `auth.users.id` / `email` を `public.users` に同期するトリガーを用意し、
    JWT.sub と `public.users.id` を一致させることで、RLS と整合した設計にする。

- **RLS のバランス**
  - セキュリティを保ちつつ、「ログインユーザは自分自身の行を見られる」ポリシーを用意すると、
    認可まわりのデバッグが大幅にやりやすくなる。

- **詳細ログの重要性**
  - URL・セッション有無・`auth_user`・`app_user`・`membership` などを段階的にログ出力したことで、
    どの層（Auth / ユーザマスタ / テナント）が問題かを素早く切り分けられた。

---

## 6. 状態のまとめ

- テストユーザ `ttakeda+sync5@gmail.com` での MagicLink 認証〜認可フローは正常に動作している。
- Supabase SSR パターン、PKCE 設定、ID 同期トリガー、RLS、シードデータは互いに整合した状態にある。
- 本レポートは、今後の機能追加やトラブルシュートのための基礎ドキュメントとして利用可能である。
