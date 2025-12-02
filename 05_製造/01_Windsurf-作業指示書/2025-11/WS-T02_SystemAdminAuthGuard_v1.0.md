# 作業指示書: システム管理者認証ガードの実装

**ドキュメントID**: WS-T02_SystemAdminAuthGuard
**バージョン**: v1.0
**作成日**: 2025/12/01

## 1. 目的

システム管理者エリア (`/sys-admin` 配下) に対しても、テナント管理者エリア (`/t-admin`) と同様の認証ガード（Middleware + Server Helper）を導入し、セキュリティの強化と実装の統一を図る。

## 2. 前提条件

*   **設計書の遵守**: 以下の設計書に基づき実装すること。
    *   基本設計書: `d:\AIDriven\01_docs\03_基本設計\04_共通設計\harmonet-auth-guard-design_v1.0.md`
    *   詳細設計書: `d:\AIDriven\01_docs\04_詳細設計\08_認証基盤\harmonet-auth-guard-detail-design_v1.0.md`
*   **既存機能の維持**: リファクタリング前後で、システム管理機能の動作が変わらないこと。
*   **制約事項**:
    *   DBスキーマ、RLSポリシーの変更は禁止。
    *   ディレクトリ構造の大幅な変更は禁止。

## 3. 作業手順

### 3.1. Middleware (`src/proxy.ts` & [src/lib/supabase/middleware.ts](file:///d:/Projects/HarmoNet/src/lib/supabase/middleware.ts)) の更新

1.  **`src/proxy.ts`**:
    *   `config.matcher` に `/sys-admin/:path*` を追加する。

2.  **[src/lib/supabase/middleware.ts](file:///d:/Projects/HarmoNet/src/lib/supabase/middleware.ts)**:
    *   [updateSession](file:///d:/Projects/HarmoNet/src/lib/supabase/middleware.ts#5-60) 関数内に、`/sys-admin` 向けのガードロジックを追加する。
    *   **条件**:
        *   パスが `/sys-admin` で始まり、かつ `/sys-admin/login` **ではない** 場合。
    *   **判定**:
        *   未ログイン (`user` が null) -> `/sys-admin/login` へリダイレクト。
        *   `user_roles` テーブルに `system_admin` ロールがない -> `/home` へリダイレクト。
    *   ※ 既存の `/t-admin` 向けロジックは維持すること。

### 3.2. Server Helper (`src/lib/auth/systemAdminAuth.ts`) の作成

新規ファイル `src/lib/auth/systemAdminAuth.ts` を作成し、以下の機能を実装する。
※ 詳細仕様は [harmonet-auth-guard-detail-design_v1.0.md](file:///d:/AIDriven/01_docs/04_%E8%A9%B3%E7%B4%B0%E8%A8%AD%E8%A8%88/08_%E8%AA%8D%E8%A8%BC%E5%9F%BA%E7%9B%A4/harmonet-auth-guard-detail-design_v1.0.md) を参照。

1.  **`getSystemAdminContext()`**:
    *   Server Components用。
    *   認証・認可NG時は `redirect('/sys-admin/login')`。
    *   OK時は `{ user, adminClient }` を返す。

2.  **`getSystemAdminApiContext()`**:
    *   Route Handlers用。
    *   認証・認可NG時は `SystemAdminApiError` を throw。

3.  **`SystemAdminApiError` クラス**:
    *   APIエラーハンドリング用。

### 3.3. 既存ページのリファクタリング

以下のファイルの認証ロジックを、`getSystemAdminContext()` を使用するように書き換える。

*   **対象ファイル**:
    *   [app/sys-admin/tenants/page.tsx](file:///d:/Projects/HarmoNet/app/sys-admin/tenants/page.tsx)
*   **変更内容**:
    *   既存の [requireSystemAdmin](file:///d:/Projects/HarmoNet/app/sys-admin/tenants/page.tsx#7-44) 関数を削除（または置換）。
    *   `getSystemAdminContext()` を呼び出して `adminClient` を取得。
    *   個別の認証チェックコードを削除。

※ [app/sys-admin/login/page.tsx](file:///d:/Projects/HarmoNet/app/sys-admin/login/page.tsx) はログインページのため、ガード対象外（変更不要、またはリダイレクトロジックのみ確認）。

### 3.4. 既存APIのリファクタリング

以下のファイルの認証ロジックを、`getSystemAdminApiContext()` を使用するように書き換える。

*   **対象ファイル**:
    *   [app/api/sys-admin/tenants/route.ts](file:///d:/Projects/HarmoNet/app/api/sys-admin/tenants/route.ts)
*   **変更内容**:
    *   既存の [ensureSystemAdmin](file:///d:/Projects/HarmoNet/app/api/sys-admin/tenants/route.ts#6-67) 関数を削除。
    *   `getSystemAdminApiContext()` を呼び出し、`try-catch` でエラーハンドリング。
    *   `SystemAdminApiError` 捕捉時は、設計書で定義されたJSONレスポンスを返す。

## 4. 成果物

*   更新された `src/proxy.ts`, [src/lib/supabase/middleware.ts](file:///d:/Projects/HarmoNet/src/lib/supabase/middleware.ts)
*   新規作成された `src/lib/auth/systemAdminAuth.ts`
*   リファクタリングされた `app/sys-admin` 配下のファイル

## 5. 検証項目

実装後、以下の動作を確認すること。

1.  **未ログインアクセス**:
    *   `/sys-admin/tenants` -> `/sys-admin/login` にリダイレクトされるか。
2.  **一般ユーザーアクセス**:
    *   `/sys-admin/tenants` -> `/home` にリダイレクトされるか。
3.  **システム管理者アクセス**:
    *   `/sys-admin/tenants` -> 正常に表示されるか。
4.  **APIアクセス**:
    *   未認証でAPIを叩いた場合、401エラーが返るか。
