# HarmoNet 詳細設計書（ログイン画面）ch06 - PasskeyAuthTrigger（A-02）設計 v1.0

**Document ID:** HNM-LOGIN-FEATURE-CH06-A02
**Version:** 1.0
**Created:** 2025-11-11
**Updated:** 2025-11-11
**Supersedes:** 旧A-02 PasskeyButton（Supabase直呼び）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update
**Standard:** harmonet-detail-design-agenda-standard_v1.0（安全テンプレートモード適用）

---

## 第1章：概要

本章は、HarmoNetログイン画面における **A-02: PasskeyAuthTrigger** の詳細設計を定義する。
Corbado公式構成（`@corbado/react` + `@corbado/node`）を用い、UIトリガーは **CorbadoAuth** を起動して `/api/session` 検証を経由してSupabaseセッションを確立する。
ch02（状態管理）・ch03（Passkey認証）・ch04（SessionHandler）・ch05（セキュリティ）に完全整合する。

### 1.1 目的

* ユーザー操作1アクションで **CorbadoAuth** を起動
* 成功時は `/api/session` → Supabase連携 → `/mypage` 遷移
* 失敗時は一貫したエラー表示（AuthErrorBanner）とリトライ導線

---

## 第2章：依存関係と前提

### 2.1 技術依存

* `@corbado/react`（`CorbadoProvider`, `CorbadoAuth`）
* `@corbado/node`（`CorbadoSDK.verifySession(cookie)`）
* `@supabase/supabase-js v2.43`（サーバ側 `signInWithIdToken` のみ）
* Next.js 16 App Router, React 19, Tailwind 4

### 2.2 前提条件

* `NEXT_PUBLIC_CORBADO_PROJECT_ID` / `CORBADO_API_SECRET` が設定済み
* RP ID/Origin はCorbado側に登録済み
* `/app/api/session/route.ts` がch04仕様で実装済み

---

## 第3章：UI構成

### 3.1 レイアウト（トリガーボタン → 認証ページ遷移）

```mermaid
graph TD
  A[PasskeyAuthTrigger (A-02)] -->|click| B[/login/passkey]
  B --> C[<CorbadoProvider><CorbadoAuth/></CorbadoProvider>]
  C --> D[/api/session]
  D --> E[Supabase Session]
  E --> F[/mypage]
```

### 3.2 スタイル仕様（HarmoNet共通トーン）

| 要素   | 値                               |
| ---- | ------------------------------- |
| 背景   | `#F9FAFB`                       |
| 角丸   | `rounded-2xl`                   |
| フォント | BIZ UDゴシック                      |
| 影    | `shadow-sm`                     |
| 配色   | ベース：`#111827` / アクセント：`#2563EB` |

---

## 第4章：状態遷移とUX

| 状態      | 表示          | 動作                             |
| ------- | ----------- | ------------------------------ |
| idle    | 「パスキーでログイン」 | クリックで `/login/passkey` 遷移      |
| loading | 認証中…        | CorbadoAuth表示（モーダル/ページ）        |
| success | 認証成功        | `/api/session` 検証→`/mypage` 遷移 |
| error   | エラー         | `AuthErrorBanner` 表示・リトライ導線    |

> *注:* 旧A-02の `supabase.auth.signInWithPasskey()` 直呼びは不採用。

---

## 第5章：Props仕様・型定義

| Prop   | 型            | 必須        | 既定                         | 説明       |   |          |      |
| ------ | ------------ | --------- | -------------------------- | -------- | - | -------- | ---- |
| label  | string       | -         | `t('auth.passkey.button')` | ボタン文言    |   |          |      |
| onOpen | `() => void` | -         | 内部実装                       | クリック時フック |   |          |      |
| state  | `'idle'      | 'loading' | 'success'                  | 'error'` | ✓ | `'idle'` | 表示状態 |

```ts
export type PasskeyAuthTriggerProps = {
  label?: string;
  onOpen?: () => void;
  state: 'idle' | 'loading' | 'success' | 'error';
};
```

---

## 第6章：実装設計（抜粋）

### 6.1 トリガーコンポーネント

```tsx
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useI18n } from '@/lib/i18n';

export function PasskeyAuthTrigger() {
  const { t } = useI18n();
  const router = useRouter();
  const [state, setState] = useState<'idle'|'loading'|'success'|'error'>('idle');

  const onClick = () => {
    setState('loading');
    router.push('/login/passkey');
  };

  return (
    <button
      type="button"
      aria-label={t('auth.passkey.button')}
      disabled={state==='loading'}
      onClick={onClick}
      className="h-11 px-4 rounded-2xl shadow-sm transition-all"
    >
      {state==='loading' ? t('auth.passkey.loading') : t('auth.passkey.button')}
    </button>
  );
}
```

### 6.2 `/login/passkey` ページ（CorbadoAuth）

```tsx
import { CorbadoProvider, CorbadoAuth } from '@corbado/react';

export default function PasskeyLoginPage() {
  return (
    <CorbadoProvider projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}>
      <CorbadoAuth />
    </CorbadoProvider>
  );
}
```

### 6.3 `/api/session`（サーバ検証）

> 実装は **ch04** の仕様に委譲。要点：`CorbadoSDK.verifySession(cookie)` → `supabase.auth.signInWithIdToken({ provider:'corbado' })`。

---

## 第7章：副作用・再レンダー設計

* UI側はトリガーの状態のみ管理（`idle/loading/success/error`）。
* 認証ロジックはCorbadoAuth + `/api/session` へ委譲。
* 成功時の画面遷移はサーバ検証成功後に行う（`router.push('/mypage')` はページ側で実施）。

---

## 第8章：i18n 文言定義（ja/en/zh）

| key                  | ja        | en                    | zh       |
| -------------------- | --------- | --------------------- | -------- |
| auth.passkey.button  | パスキーでログイン | Sign in with Passkey  | 使用通行密钥登录 |
| auth.passkey.loading | 認証中...    | Authenticating...     | 正在验证...  |
| auth.passkey.error   | 認証に失敗しました | Authentication failed | 验证失败     |

---

## 第9章：アクセシビリティ設計

* `aria-live="polite"` で状態更新を読み上げ
* 失敗時は `role="alert"` で通知
* キーボード操作（Enter/Space）対応、フォーカス復帰を保証

---

## 第10章：セキュリティ考慮

* 直呼び認証の禁止：`@corbado/web-js` や `supabase.auth.signInWithPasskey()` を**クライアントで実行しない**。
* Cookie方針：`cbo_short_session`（15分） + `supabase-auth-token` を **HttpOnly / Secure / SameSite=Lax** で管理。
* RLS：`tenant_id` + `corbado_user_id` により行分離（詳細はch05）。

---

## 第11章：UT観点（最小セット）

| ID       | シナリオ    | 操作                  | 期待結果                              |
| -------- | ------- | ------------------- | --------------------------------- |
| UT-06-01 | 認証成功    | クリック→CorbadoAuth→成功 | `/api/session` 200 → `/mypage` 遷移 |
| UT-06-02 | 認証失敗    | 途中キャンセル             | `AuthErrorBanner` 表示、再試行可         |
| UT-06-03 | i18n切替  | ja↔en↔zh            | 文言即時切替                            |
| UT-06-04 | 再レンダー抑制 | 連打                  | 二重遷移なし                            |
| UT-06-05 | A11y    | キーボード操作             | 起動・復帰ともに可能                        |

---

## 第12章：関連ファイル

| 種別             | ファイル                                | 用途                |
| -------------- | ----------------------------------- | ----------------- |
| 状態管理           | `login-feature-design-ch02_v1.0.md` | ログイン状態制御          |
| Passkey認証      | `login-feature-design-ch03_v1.0.md` | CorbadoAuth設計     |
| SessionHandler | `login-feature-design-ch04_v1.0.md` | `/api/session` 仕様 |
| セキュリティ         | `login-feature-design-ch05_v1.0.md` | Cookie/RLS方針      |

---

## 第13章：改訂履歴

| Version | Date       | Author          | Summary                                                 |
| ------- | ---------- | --------------- | ------------------------------------------------------- |
| 1.0     | 2025-11-11 | TKD + Tachikoma | 旧PasskeyButtonを廃止し、CorbadoAuth起動トリガとして再定義。方式B（公式構成）に統一。 |
