# HarmoNet 認証ガード 基本設計書

| 項目 | 内容 |
| :--- | :--- |
| ドキュメントID | harmonet-auth-guard-design |
| バージョン | v1.1 |
| 作成日 | 2025/12/01 |
| 作成者 | Antigravity |
| 更新日 | 2025/12/01 |
| ステータス | 改訂版 |

## 1. 目的

本ドキュメントは、HarmoNetアプリケーションにおけるテナント管理者エリア（`/t-admin` 配下）およびシステム管理者エリア（`/sys-admin` 配下）のセキュリティ強化と、認証・認可ロジックの統一的な実装方針を定義するものである。
従来、各画面やAPIごとに個別に実装されていた認証ロジックを、Middlewareと共通ヘルパー関数に集約することで、実装漏れを防ぎ、保守性を向上させることを目的とする。

## 2. アーキテクチャ概要

テナント管理者エリアへのアクセス制御は、以下の2層構造で実施する。

1.  **一次ガード (Middleware)**:
    *   リクエストがアプリケーションサーバーに到達した直後に実行。
    *   Supabaseセッションの有無と、ロール（`tenant_admin` または `system_admin`）の有無を高速にチェック。
    *   不正なリクエストを即座にリダイレクトし、サーバーリソースの消費を抑える。

2.  **二次ガード (Server Helper)**:
    *   Page Component (Server Component) や Route Handler (API) の処理開始時に実行。
    *   認証コンテキスト（User情報、Tenant情報）を確実に取得し、呼び出し元に提供。
    *   Middlewareをすり抜けた場合や、より厳密なチェックが必要な場合の最終防壁として機能。

## 3. 詳細仕様

### 3.1. Middleware (`src/proxy.ts`)

Next.js の Middleware 機能を使用し、`/t-admin` 配下への全リクエストをインターセプトする。
※ Next.js 16.0.1 以降の仕様に準拠し、ファイル名は `proxy.ts` とする。

*   **適用パス**: `/t-admin/:path*`, `/sys-admin/:path*`
*   **処理フロー**:
    1.  `updateSession` 関数を呼び出し、Supabaseのセッション情報を取得・更新。
    2.  ユーザーが未ログインの場合:
        *   `/login` (テナント管理) または `/sys-admin/login` (システム管理) へリダイレクト (307 Temporary Redirect)。
    3.  ユーザーがログイン済みだが、必要なロールを持たない場合:
        *   `/t-admin` へのアクセスで `tenant_admin` なし -> `/home` へリダイレクト。
        *   `/sys-admin` へのアクセスで `system_admin` なし -> `/home` へリダイレクト（または403表示）。
    4.  上記以外（認証・認可OK）の場合:
        *   リクエストを後続の処理（Page/API）へ通す。

### 3.2. Server Helper

各ページおよびAPIの実装内で呼び出す共通関数を提供する。

#### 3.2.1. テナント管理者用 (`src/lib/auth/tenantAdminAuth.ts`)

**`getTenantAdminContext()`**
*   **用途**: Server Components (Page) 用
*   **戻り値**: `{ user, tenantId, tenantName }`
*   **挙動**:
    *   認証または認可に失敗した場合、即座に `redirect()` を実行し、処理を中断する。
    *   呼び出し側は `await` するだけでよく、エラーハンドリングを記述する必要がない。

**`getTenantAdminApiContext()`**
*   **用途**: Route Handlers (API) 用
*   **戻り値**: `{ user, tenantId, tenantName }`
*   **挙動**:
    *   認証または認可に失敗した場合、カスタムエラー `TenantAdminApiError` を throw する。
    *   呼び出し側は `try-catch` ブロックで囲み、エラーを捕捉してレスポンスを返す必要がある。

#### 3.2.2. システム管理者用 (`src/lib/auth/systemAdminAuth.ts`)

**`getSystemAdminContext()`**
*   **用途**: Server Components (Page) 用
*   **戻り値**: `{ user, adminClient }`
*   **挙動**:
    *   認証または認可に失敗した場合、即座に `redirect('/sys-admin/login')` を実行する。

**`getSystemAdminApiContext()`**
*   **用途**: Route Handlers (API) 用
*   **戻り値**: `{ user, adminClient }`
*   **挙動**:
    *   認証または認可に失敗した場合、カスタムエラー `SystemAdminApiError` を throw する。

#### 3.2.3. エラーハンドリング (API)
APIルートでは、専用のエラークラス（`TenantAdminApiError`, `SystemAdminApiError`）を捕捉し、以下のJSONレスポンスを返すことで統一する。

```json
// 401 Unauthorized (未ログイン)
{
  "error": "Unauthorized"
}

// 403 Forbidden (権限なし)
{
  "error": "Forbidden"
}
```

## 4. 適用範囲

本設計の適用対象は以下の通りである。

*   **テナント管理者**:
    *   ページ: `/t-admin` 配下のすべての Page Component
    *   API: `/api/t-admin` 配下のすべての Route Handler
*   **システム管理者**:
    *   ページ: `/sys-admin` 配下のすべての Page Component（`/sys-admin/login` を除く）
    *   API: `/api/sys-admin` 配下のすべての Route Handler

## 5. 備考

*   **ファイル名の変更**: Next.js の警告対応のため、Middlewareの実装ファイルは `src/middleware.ts` ではなく `src/proxy.ts` を使用する。
*   **既存ロジックとの互換性**: 既存の `createSupabaseServerClient` 等のユーティリティは引き続き内部で使用されるが、直接呼び出すのではなく、本ヘルパー関数を経由することを推奨する。
