# PasskeyAuthTrigger 詳細設計書 - 第4章：実装設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH04**
**Version:** 1.2
**Supersedes:** v1.1
**Status:** MagicLinkForm v1.2 整合（error.* 体系を最新化 / 必要最小限更新）

---

## 4.1 実装対象構成

PasskeyAuthTrigger は MagicLinkForm (A-01) に統合される **非UIロジックモジュール**であり、React Hook 形式で提供される。UI 描画や状態制御は MagicLinkForm が担当するため、本モジュールは **認証処理・例外分類・通知発火** に責務を限定する。

構成は以下の通り：

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
    supabase/client.ts                # Supabase Browser Client
```

---

## 4.2 Hook 実装構成（最新 error.* 対応済）

```ts
import { createClient } from '@/lib/supabase/client';
import Corbado from '@corbado/web-js';
import { useErrorHandler } from '@/components/common/ErrorHandlerProvider';
import { useI18n } from '@/components/common/StaticI18nProvider';

export const usePasskeyAuthTrigger = ({ onSuccess, onError, passkeyEnabled }: PasskeyAuthTriggerOptions) => {
  const supabase = createClient();
  const { t } = useI18n();
  const handleError = useErrorHandler();

  const execute = async (): Promise<void> => {
    if (!passkeyEnabled) return; // MagicLink へフォールバック
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

// ⭐ v1.2：errorキー体系を最新化
function classifyError(err: any, t: (k: string) => string): PasskeyAuthError {
  if (err?.name === 'NotAllowedError') {
    return {
      code: 'NOT_ALLOWED',
      message: t('error.denied'),
      type: 'error_denied',
    };
  }

  if (String(err?.message || '').includes('ORIGIN')) {
    return {
      code: 'ORIGIN_MISMATCH',
      message: t('error.origin_mismatch'),
      type: 'error_origin',
    };
  }

  if (String(err?.message || '').includes('NETWORK')) {
    return {
      code: 'NETWORK',
      message: t('error.network'),
      type: 'error_network',
    };
  }

  return {
    code: 'AUTH_ERROR',
    message: t('error.auth'),
    type: 'error_auth',
  };
}
```

---

## 4.3 サーバ連携構成（変更なし）

```ts
import { verify } from '@corbado/node';
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { token } = await req.json();
    const result = await verify(token, process.env.CORBADO_API_SECRET!);
    if (!result.valid) throw new Error('INVALID_TOKEN');

    return NextResponse.json({ id_token: result.id_token });
  } catch {
    return NextResponse.json({ error: 'verification_failed' }, { status: 400 });
  }
}
```

※ Supabase と Corbado の認証境界を安全に橋渡しする中継処理。構造は v1.1 のままで問題なし。

---

## 4.4 関数責務表

| 関数名             | 役割                         | 備考                          |
| --------------- | -------------------------- | --------------------------- |
| execute()       | Passkey → Supabase 認証の本体処理 | 成功で onSuccess / 失敗で onError |
| classifyError() | ⭐ 最新 error.* 体系に変換した例外分類   | ErrorHandlerProvider へ通知    |

---

## 4.5 エラーハンドリング（v1.2 最新化）

| 例外コード           | 分類            | メッセージキー（最新版）            |
| --------------- | ------------- | ----------------------- |
| NOT_ALLOWED     | error_denied  | `error.denied`          |
| ORIGIN_MISMATCH | error_origin  | `error.origin_mismatch` |
| NETWORK         | error_network | `error.network`         |
| AUTH_ERROR      | error_auth    | `error.auth`            |

※ 旧キー `error.passkey_denied` は完全廃止。
※ MagicLinkForm v1.2 と完全整合。

---

## 4.6 セキュリティ仕様（変更なし）

* WebAuthn 仕様により **HTTPS 必須**。
* Corbado SDK の RP ID は harmoNet.app 固定。
* Supabase JWT は10分有効、`tenant_id` による RLS 適用。
* Corbado の id_token は保存禁止、検証後即破棄。
* `/api/corbado/session` の API SECRET は Vault 管理。
* CORS は `NEXT_PUBLIC_APP_URL` のみ許可。

---

## 4.7 パフォーマンス設計

* SDK 初期化は Lazyロード方式（execute() 呼出時のみ）。
* Supabase 呼出は async/await の直列処理。
* useCallback によるハンドラ再生成抑制。
* 依存配列は最小限（onSuccess / onError / handleError / t）。

---

## 4.8 UT スケルトン（変更なし）

```ts
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

## 4.9 受入基準

1. Passkey → Supabase 認証が成功すること。
2. onSuccess / onError が正しく発火すること。
3. 型・Lint・UT がすべて通過すること。
4. MagicLinkForm 統合時に UI が正しく遷移すること。
5. 例外時でもアプリがクラッシュしないこと。

---

## 4.10 ChangeLog

| Version | Date       | Summary                                   |
| ------- | ---------- | ----------------------------------------- |
| 1.2     | 2025-11-14 | error.*体系へ統一。classifyError/エラーテーブルの最小限更新。 |
| 1.1     | 2025-11-12 | PasskeyAuthTrigger構成へ改訂。MagicLinkForm統合。  |
