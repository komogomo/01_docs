# WS-AuthFlowIntegration_v1.0

## 1. Task Summary

* 目的: MagicLink 認証フロー（MagicLink Backend → /auth/callback → /home 遷移）を **1つの連続タスク**として統合し、Next.js App Router + Supabase Auth にて正しく実装する。
* 対象コンポーネント:

  * MagicLinkForm (A-01)
  * AuthCallbackHandler (`app/auth/callback/page.tsx`)
  * HomePage (`app/home/page.tsx`)
* EdgeFunction 不使用。tenant_id は DB 側 RLS で解決。JWT の再発行は行わない。

---

## 2. Target Files

* `src/components/auth/MagicLinkForm/MagicLinkForm.tsx`
* `app/auth/callback/page.tsx`
* `app/home/page.tsx`（存在しない場合は新規作成）

---

## 3. References

* D:\AIDriven\01_docs\05_製造\01_Windsurf-作業指示書\WS-A01_MagicLinkBackendIntegration_v1.0.md
* D:\AIDriven\01_docs\04_詳細設計\01_ログイン画面\A-00LoginPage-detail-design_v1.3.md
* D:\AIDriven\01_docs\04_詳細設計\01_ログイン画面\MagicLinkForm-detail-design_v1.3.md
* D:\AIDriven\01_docs\03_基本設計\03_画面設計\02_ホーム画面\home-feature-design-ch02_v2.1.md
* D:\Projects\HarmoNet\prisma\schema.prisma（RLS参照のため）

---

## 4. Implementation Rules

* MagicLinkForm は既存仕様を変更しない。
* `/auth/callback` は "セッション確認 → 遷移" のみ担当し、状態は保持しない。
* セッション取得は `supabase.auth.getSession()` を使用。
* 認証成功: `/home` へ `router.replace('/home')`。
* 失敗時: `/login?error=auth_failed` に遷移。
* EdgeFunction / JWT クレーム更新は行わない。
* Home画面は CSR ページとして実装。
* UI 変更は禁止（既存コンポーネント依存）。

---

## 5. Flow Specification

### 5.1 認証シーケンス（統合版）

```
/login
  ↓ MagicLink送信
メール受信
  ↓ リンクタップ
/auth/callback
  ↓ supabase.auth.getSession()
    ・成功 → /home
    ・失敗 → /login?error=auth_failed
/home
```

### 5.2 Callback ロジック概要

```ts
const { data: { session } } = await supabase.auth.getSession();
if (session) router.replace('/home');
else router.replace('/login?error=auth_failed');
```

### 5.3 Home 遷移後の動作

* Home画面で Supabase セッションが有効なら、RLS によりユーザー固有のお知らせ等が取得可能。
* tenant_id は DB の RLS 条件内で user_id → tenant_id を参照して解決する。

---

## 6. Acceptance Criteria

* TypeCheck / Lint / Build すべて 0 エラー。
* `/login → MagicLink → /auth/callback → /home` が一度で成功すること。
* Home画面が認証後に正しく表示されること（RLS が正常動作）。
* UI 崩れなし。
* CodeAgent_Report を正しいパスへ出力。

---

## 7. Forbidden Actions

* EdgeFunction の追加。
* JWT の書き換えやカスタムクレーム付与。
* UI / 文言 / ディレクトリ構造の変更。
* 不要なログ・例外処理の追加。
* 認証方式の追加や仕様変更。

---

## 8. CodeAgent_Report

* Task: AuthFlowIntegration
* Attempts / Score / TypeCheck / Lint / Build / Summary を記載。
* 保存先:

```
/01_docs/06_品質チェック/CodeAgent_Report_AuthFlowIntegration_v1.0.md
```

---

## 9. Testing Method

### 9.1 Unit Tests (MagicLinkForm 必須)

* MagicLinkForm の Vitest + RTL テストを実行し、全テストケースが PASS すること。

```
npm test MagicLinkForm
```

* Callback / Home の UT は今回スコープ外（TypeCheck/Lint/Build のみ）。

### 9.2 TypeCheck / Lint / Build

```
npm run type-check
npm run lint
npm run build
```

### 9.3 Auth Flow 動作確認（E2E ライトチェック）

1. `/login` で MagicLink を送信。
2. メールリンクを踏む（Mailpitなどで手動確認）。
3. `/auth/callback` → `/home` に正常遷移すること。

---

