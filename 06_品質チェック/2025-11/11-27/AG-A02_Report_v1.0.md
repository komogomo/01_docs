# 作業報告書: AG-A02 Auth Callback Tenant Binding

## 基本情報
- **作業指示書**: AG-A02_AuthCallbackTenantBinding_v1.0.md
- **実施者**: Antigravity
- **実施日**: 2025-11-27
- **ステータス**: 指示①完了

## 実施内容: 指示① Auth Callback のテナント判定＋テナント状態チェック実装

### 1. 実装概要
`app/auth/callback/route.ts` を実装し、以下の要件を満たすようにしました。
- Supabase Auth からのユーザー取得
- `public.users` および `user_tenants` テーブルを用いたテナント特定
- **テナント状態チェック (`tenants.status = 'active'`) の実装**
- 認証成功時の `/home` へのリダイレクト
- 認証失敗時（テナント無効含む）の `/login?error=unauthorized` へのリダイレクト

### 2. 技術的変更点
- **Service Role Client の導入**:
  - 課題: ログイン直後のコールバック時点では、ユーザーの JWT にまだ `tenant_id` が含まれていない（またはクレームとして機能していない）ため、RLS（Row Level Security）により `tenants` テーブルや `user_tenants` テーブルの参照が拒否される問題が発生しました。
  - 解決策: `src/lib/supabaseServiceRoleClient.ts` を利用し、管理者権限（Service Role Key）でデータベースを参照することで、RLS をバイパスして正確なテナント状態チェックを行えるようにしました。

### 3. 検証結果
- **テストケース**:
  - 対象: `admin@gmail.com` (テナントID: `ab3d...`, Status: `active`)
  - 手順: Magic Link ログインフローを実行。
  - 結果: 正常に `/home` へリダイレクトされることを確認。
- **エッジケース対応**:
  - テナントが無効（Inactive）な場合、または所属情報がない場合は、ログイン画面へエラー付きでリダイレクトされるロジックとなっていることをコード上で確認済み。

## 次のステップ
- 指示②「t-admin ユーザ登録（/t-admin/users）実装」への着手準備完了。
