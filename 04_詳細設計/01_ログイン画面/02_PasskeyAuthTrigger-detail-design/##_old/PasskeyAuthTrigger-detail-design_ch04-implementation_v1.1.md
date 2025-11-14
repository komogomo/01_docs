# HarmoNet 詳細設計書 - PasskeyAuthTrigger (A-02) ch04 v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH04
**Version:** 1.1
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.2 / MagicLinkForm 統合対応）

---

## 第4章 実装設計

### 4.1 実装対象構成

PasskeyAuthTrigger は MagicLinkForm 内で動作する非UIモジュールであり、React Hook として定義される。UI描画は一切行わず、Promise ベースで結果を返す。
認証処理の本体は `usePasskeyAuthTrigger.ts`、サーバ検証は `/api/corbado/session` で実施する。

```
src/
  hooks/
    auth/
      usePasskeyAuthTrigger.ts        # 本体（Hook）
  app/
    api/
      corbado/
        session/route.ts              # Corbado Node SDK 検証
  lib/
    supabase/client.ts                # Supabase Browser Client 生成
```

---

### 4.2 Hook実装構成

```typescript
import { createClient } from '@/lib/supabase/client';
import Corbado from '@corbado/web-js';
import { useErrorHandler } from '@/components/common/ErrorHandlerProvider';
import { useI18n } from '@/components/common/StaticI18nProvider';

export const usePasskeyAuthTrigger = ({ onSuccess, onError, passkeyEnabled }: PasskeyAuthTriggerOptions) => {
  const supabase = createClient();
  const { t } = useI18n();
  const handleError = useErrorHandler();

  const execute = async (): Promise<void> => {
    if (!passkeyEnabled) return; // MagicLinkフォールバック
    try {
      await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
      const result = await Corbado.passkey.login();
      if (!result?.id_token) throw new Error('NO_TOKEN');

      const { error } = await supabase.auth.signInWithIdToken({ provider: 'corbado', token: result.id_token });
      if (error) throw error;
      onSuccess?.();
    } catch (err: any) {
      const error = classifyError(err, t);
      handleError(error.message);
      onError?.(error);
    }
  };

  return { execute };
};

function classifyError(err: any, t: (k:string)=>string): PasskeyAuthError {
  if (err?.name === 'NotAllowedError') return { code: 'NOT_ALLOWED', message: t('error.passkey_denied'), type: 'error_denied' };
  if (String(err?.message || '').includes('ORIGIN')) return { code: 'ORIGIN_MISMATCH', message: t('error.origin_mismatch'), type: 'error_origin' };
  if (String(err?.message || '').includes('NETWORK')) return { code: 'NETWORK', message: t('error.network'), type: 'error_network' };
  return { code: 'AUTH_ERROR', message: t('error.network'), type: 'error_auth' };
}
```

---

### 4.3 サーバ連携構成（`/app/api/corbado/session/route.ts`）

```typescript
import { verify } from '@corbado/node';
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { token } = await req.json();
    const result = await verify(token, process.env.CORBADO_API_SECRET!);
    if (!result.valid) throw new Error('INVALID_TOKEN');
    return NextResponse.json({ id_token: result.id_token });
  } catch (e) {
    return NextResponse.json({ error: 'verification_failed' }, { status: 400 });
  }
}
```

> **備考:** 本実装はフロントからの id_token をサーバ側で安全に検証する構成であり、Supabase 認証層との中継役を担う。

---

### 4.4 関数責務表

| 関数名                 | 役割                                            | 備考                                   |
| ------------------- | --------------------------------------------- | ------------------------------------ |
| **execute()**       | Passkey認証処理の本体。Corbado SDK呼出〜Supabase連携までを担当。 | 成功時 `onSuccess()`、失敗時 `onError()` 通知 |
| **classifyError()** | 例外オブジェクトを分類し、StaticI18nProvider のキーへ変換。       | ErrorHandlerProvider 経由で通知           |

---

### 4.5 エラーハンドリング設計

| 例外コード           | 分類            | メッセージキー                 | 通知方式                 |
| --------------- | ------------- | ----------------------- | -------------------- |
| NOT_ALLOWED     | error_denied  | `error.passkey_denied`  | ErrorHandlerProvider |
| ORIGIN_MISMATCH | error_origin  | `error.origin_mismatch` | 同上                   |
| NETWORK         | error_network | `error.network`         | 同上                   |
| AUTH_ERROR      | error_auth    | `error.network`         | 同上                   |

---

### 4.6 セキュリティ仕様

* HTTPS 通信必須（WebAuthn要件）。
* Corbado SDK は `harmonet.app` ドメイン固定。
* Supabase JWT は 10分有効。`tenant_id` によりRLS適用。
* Corbadoトークンは `localStorage` に保存禁止。検証後即破棄。
* `/api/corbado/session` は API Secret を Vault で暗号管理。
* CORS は `NEXT_PUBLIC_APP_URL` のみ許可。

---

### 4.7 パフォーマンス設計

| 項目         | 内容                                         |
| ---------- | ------------------------------------------ |
| SDK初期化     | Lazyロード（execute時のみ）                        |
| Supabase呼出 | Promise連結による直列制御（不要再描画防止）                  |
| メモ化        | useCallback によりハンドラ再生成を防止                  |
| 依存関係       | `[onSuccess, onError, handleError, t]` に限定 |

---

### 4.8 UT スケルトン

```typescript
import { renderHook, act } from '@testing-library/react';
import { usePasskeyAuthTrigger } from '@/hooks/auth/usePasskeyAuthTrigger';

describe('usePasskeyAuthTrigger', () => {
  it('正常時に onSuccess が呼ばれる', async () => {
    const onSuccess = jest.fn();
    const { result } = renderHook(() => usePasskeyAuthTrigger({ passkeyEnabled: true, onSuccess }));
    await act(async () => {
      await result.current.execute();
    });
    expect(onSuccess).toHaveBeenCalled();
  });
});
```

---

### 4.9 受入基準（Acceptance Criteria）

1. Corbado SDK → Supabase 認証連携が正常に動作すること。
2. onSuccess / onError コールバックが正しく呼ばれること。
3. 型定義・Lint・UT すべてエラーなし。
4. MagicLinkForm 統合時に UI 側の状態変化が正常に反映されること。
5. 非同期例外が発生してもアプリがクラッシュしないこと。

---

### 4.10 ChangeLog

| Version | Date           | Author              | Summary                                                      |
| ------- | -------------- | ------------------- | ------------------------------------------------------------ |
| 1.0     | 2025-11-11     | Tachikoma           | 旧 PasskeyButton 実装設計（UI構成版）                                  |
| **1.1** | **2025-11-12** | **Tachikoma / TKD** | **PasskeyAuthTrigger 構成へ改訂。Hook 実装・UI削除・MagicLinkForm統合対応。** |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyAuthTrigger-detail-design/PasskeyAuthTrigger-detail-design_ch04_v1.1.md`
**Compliance:** harmoNet-detail-design-agenda-standard_v1.0
