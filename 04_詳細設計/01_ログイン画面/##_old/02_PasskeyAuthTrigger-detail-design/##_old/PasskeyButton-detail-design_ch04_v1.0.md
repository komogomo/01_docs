# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch04 実装設計 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH04
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.0 / アジェンダ標準準拠）

---

## 第4章 実装設計

### 4.1 ファイル構成（実装対象）

```
src/
  components/
    auth/
      PasskeyButton/
        PasskeyButton.tsx            # 本体
        PasskeyButton.types.ts       # 型定義（Props/State/Error）
        index.ts                     # エクスポート
  app/
    api/
      corbado/
        session/route.ts             # サーバ検証・Supabase連携（推奨）
  lib/
    supabase/client.ts               # Browserクライアント生成
    corbado/verifySession.ts         # （任意）検証ユーティリティ
```

> **方針**: PasskeyButton は **UIトリガ + 最小ロジック** に限定し、Corbado 検証や JWT 取扱いは **/api/corbado/session** へ集約。

---

### 4.2 主要型定義（`PasskeyButton.types.ts`）

```ts
export type PasskeyState = 'idle' | 'loading' | 'success' | 'error';

export interface PasskeyError {
  code: string; // NOT_ALLOWED | ORIGIN_MISMATCH | NETWORK | AUTH_ERROR | UNKNOWN
  message: string; // i18n 済み文言
  type: 'error_network' | 'error_denied' | 'error_origin' | 'error_auth' | 'error_unknown';
}

export interface PasskeyButtonProps {
  className?: string;              // レイアウト拡張（色上書き禁止）
  onSuccess?: () => void;          // セッション確立後の通知
  onError?: (e: PasskeyError) => void; // 分類済みエラー通知
}
```

---

### 4.3 コンポーネント実装（`PasskeyButton.tsx`）

```tsx
'use client';
import React, { useCallback, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { useErrorHandler } from '@/components/common/ErrorHandlerProvider';
import type { PasskeyButtonProps, PasskeyState, PasskeyError } from './PasskeyButton.types';
import { KeyRound, Loader2, CheckCircle, AlertCircle } from 'lucide-react';

export const PasskeyButton: React.FC<PasskeyButtonProps> = ({ className = '', onSuccess, onError }) => {
  const [state, setState] = useState<PasskeyState>('idle');
  const supabase = createClient();
  const { t } = useI18n();
  const notifyError = useErrorHandler();

  const classifyError = (err: any): PasskeyError => {
    if (err?.name === 'NotAllowedError') {
      return { code: 'NOT_ALLOWED', message: t('error.passkey_denied'), type: 'error_denied' };
    }
    const msg = String(err?.message || '');
    if (msg.includes('ORIGIN') || msg.includes('origin')) {
      return { code: 'ORIGIN_MISMATCH', message: t('error.origin_mismatch'), type: 'error_origin' };
    }
    if (msg.includes('NETWORK') || err?.code === 'ECONNABORTED') {
      return { code: 'NETWORK', message: t('error.network'), type: 'error_network' };
    }
    return { code: 'AUTH_ERROR', message: t('error.network'), type: 'error_auth' };
  };

  const handleLogin = useCallback(async () => {
    if (state === 'loading') return; // 二重起動防止
    try {
      setState('loading');

      // 推奨方式: サーバで Corbado 検証・Supabase 連携（トークン非露出）
      const res = await fetch('/api/corbado/session', { method: 'POST' });
      if (!res.ok) throw new Error('NETWORK');
      const token = await res.text();

      const { error } = await supabase.auth.signInWithIdToken({ provider: 'corbado', token });
      if (error) throw error;

      setState('success');
      onSuccess?.();
    } catch (err: any) {
      const e = classifyError(err);
      setState('error');
      notifyError(e.message);
      onError?.(e);
    }
  }, [state, supabase, notifyError, t, onSuccess, onError]);

  return (
    <button
      type="button"
      onClick={handleLogin}
      className={`w-full h-12 rounded-2xl bg-blue-600 text-white font-medium flex items-center justify-center gap-2 hover:bg-blue-500 disabled:opacity-60 transition ${className}`}
      disabled={state === 'loading'}
      aria-live="polite"
    >
      {state === 'loading' && <Loader2 className="animate-spin" aria-hidden />}
      {state === 'success' && <CheckCircle aria-hidden />}
      {state === 'error' && <AlertCircle aria-hidden />}
      {state === 'idle' && <KeyRound aria-hidden />}
      <span>
        {state === 'success' ? t('auth.passkey.success')
          : state === 'loading' ? t('auth.passkey.progress')
          : state === 'error' ? t('auth.retry')
          : t('auth.passkey.login')}
      </span>
    </button>
  );
};

PasskeyButton.displayName = 'PasskeyButton';
```

> **補足**: 互換モード（`@corbado/web-js` 直接呼び出し）を併置する場合は、`NEXT_PUBLIC_AUTH_DRIVER=corbado-react|web-js` フラグで分岐し、`Corbado.load() → Corbado.passkey.login()` から `id_token` を取得して同様に `signInWithIdToken()` へ委譲する。

---

### 4.4 サーバ連携実装（`/app/api/corbado/session/route.ts`）

```ts
import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
// import { CorbadoService } from '@corbado/node'; // 公式SDK採用を想定

export async function POST(req: NextRequest) {
  try {
    // 1) Corbadoの short_session Cookie を取得
    const shortSession = cookies().get('cbo_short_session')?.value;
    if (!shortSession) return NextResponse.json({ error: 'NO_SESSION' }, { status: 401 });

    // 2) Corbado 側でセッション検証（擬似）
    // const service = new CorbadoService({ apiSecret: process.env.CORBADO_API_SECRET! });
    // const verified = await service.verifySession(shortSession);
    // if (!verified) return NextResponse.json({ error: 'VERIFY_FAILED' }, { status: 401 });

    // 3) Verified token を返却（本番はサーバ → Supabase 直結も可）
    const idToken = 'verified-id-token-from-corbado';
    return new NextResponse(idToken, { status: 200, headers: { 'Content-Type': 'text/plain' } });
  } catch (e) {
    return NextResponse.json({ error: 'NETWORK' }, { status: 500 });
  }
}
```

> **運用注記**: 本番では **サーバ内で直接 Supabase セッションを確立** し、フロントにトークンを返さず 204 を返す方式も可。UI 側は 200/204 の成否のみ監視。

---

### 4.5 例外設計（分類表）

| 例外コード             | 分類              | UI表示                    | 対処                  |
| ----------------- | --------------- | ----------------------- | ------------------- |
| `NOT_ALLOWED`     | `error_denied`  | `error.passkey_denied`  | 再試行誘導（キャンセル）        |
| `ORIGIN_MISMATCH` | `error_origin`  | `error.origin_mismatch` | RP ID / Origin 設定修正 |
| `NETWORK`         | `error_network` | `error.network`         | 回線確認・再試行            |
| `AUTH_ERROR`      | `error_auth`    | `error.network`         | セッション再確立            |

---

### 4.6 セキュリティ実装指針

* **HTTPS 必須**（WebAuthn 仕様）
* **Cookie 指針**: `HttpOnly`, `Secure`, `SameSite=Lax`, `Max-Age ≤ 900s`
* **Token 非永続化**: `localStorage` 等への保存禁止。必要時はサーバ交換。
* **RLS 整合**: JWTクレーム（user_id / tenant_id）で境界維持。
* **CORS**: `NEXT_PUBLIC_APP_URL` のみ許可。

---

### 4.7 アクセシビリティ & パフォーマンス

* A11y: `aria-live="polite"`、フォーカスリングは Design System 既定。
* UX: 1クリック＝1リクエスト。loading中は `disabled` で二重起動防止。
* レンダリング: 依存配列で `useCallback` 安定化、不要再描画を抑制。

---

### 4.8 UT/Jest スケルトン

```ts
// src/components/auth/PasskeyButton/PasskeyButton.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { PasskeyButton } from './PasskeyButton';

test('初期表示は「パスキーでログイン」', () => {
  render(<PasskeyButton />);
  expect(screen.getByText('パスキーでログイン')).toBeInTheDocument();
});

test('クリックでloading→成功ハンドラ発火', async () => {
  render(<PasskeyButton onSuccess={jest.fn()} />);
  fireEvent.click(screen.getByRole('button'));
  // fetch と supabase.auth.signInWithIdToken はモック化して成功応答を返す
});
```

---

### 4.9 受入基準（Acceptance Criteria）

1. TypeScript strict で型エラー 0。
2. ESLint/Prettier エラー 0。
3. Storybook で `idle/loading/success/error` を切替確認できる。
4. Jest UT（最小2件）が通過。
5. Corbado → `/api/corbado/session` → Supabase の一連でセッション確立が成功。

---

### 4.10 ChangeLog

| Version | Date       | Author    | Summary                                  |
| ------- | ---------- | --------- | ---------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版。UI本体・サーバ連携・例外分類・セキュリティ・UT を実装設計として定義。 |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch04_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
