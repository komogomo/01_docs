# 調査報告書: ホーム・掲示板画面におけるテナントID参照の整合性確認

## 基本情報
- **実施日**: 2025-11-27
- **実施者**: Antigravity
- **目的**: ホーム画面および掲示板画面が、ユーザーに紐づく正しいテナントID（`user_tenants` ベース）を参照して動作しているかを確認する。

## 1. 調査対象
- **ホーム画面**: `app/home/page.tsx`
- **掲示板画面**: `app/board/page.tsx` および `app/api/board/posts/route.ts`

## 2. 調査結果サマリ
**結論: 整合性あり (OK)**

両画面ともに、ログインユーザーの `user_id` を基点として `user_tenants` テーブルを検索し、`status = 'active'` である有効なテナントIDを特定して使用しています。
これにより、今回実装した認証コールバック (`auth/callback/route.ts`) と同様に、`user_tenants` を「所属の正」とするロジックで統一されています。

## 3. 詳細調査内容

### 3.1 ホーム画面 (`app/home/page.tsx`)
- **ロジック**:
  1. `supabase.auth.getUser()` で認証ユーザーを取得。
  2. `public.users` テーブルからアプリユーザー情報を取得。
  3. **`user_tenants` テーブルを検索し、`user_id` が一致かつ `status = 'active'` のレコードから `tenant_id` を取得。**
  4. 取得した `tenant_id` を用いて `tenant_settings` (お知らせ設定など) を読み込み、画面を描画。
- **データアクセス権限 (RLS)**:
  - `user_tenants` テーブルには `user_id = auth.uid()` (自分のID) での参照を許可するポリシーが存在するため、JWTに `tenant_id` が含まれていなくても正常にテナントIDを特定可能です。

### 3.2 掲示板画面 (`app/board/page.tsx` / `/api/board/posts`)
- **画面 (`page.tsx`)**:
  - ホーム画面と同様に、まず `user_tenants` から正しい `tenant_id` を解決します。
  - 解決した `tenant_id` を Props として Client Component (`BoardTopPage`) に渡し、API リクエストのクエリパラメータとして使用します。
- **API (`route.ts`)**:
  - リクエストパラメータとして受け取った `tenantId` をそのまま信用せず、**再度サーバーサイドで `user_tenants` をチェック** しています。
  - 「リクエストされた `tenantId` に、このユーザーが `active` な状態で所属しているか」を検証し、検証OKの場合のみデータを返却します。
  - データ取得には `Prisma Client` を使用しているため、Supabase RLS の制約を受けずにデータを取得・表示できています。

## 4. 補足事項
- **JWTトークン**: 現状のブラウザセッションの JWT トークンを確認したところ、`tenant_id` クレームは含まれていませんでした。しかし、上記の通り `user_tenants` テーブルへのアクセス権限（自分の所属確認）が確保されているため、アプリケーション動作に支障はありません。

以上
