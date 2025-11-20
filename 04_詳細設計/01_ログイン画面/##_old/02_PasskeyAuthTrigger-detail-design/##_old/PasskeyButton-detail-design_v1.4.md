# HarmoNet 詳細設計書 - PasskeyButton (A-02) v1.4

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-DESIGN  
**Version:** 1.4  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** Phase9 正式仕様（Next.js 16 / React 19 / Supabase v2.43 / Corbado SDK整合版）  

---

## 第1章 概要

### 1.1 目的
本設計書は、HarmoNetログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** の最終設計を定義する。  
v1.4では、**Corbado SDKの公式API構成を用いつつ、HarmoNet設計思想（A-01〜A-03分離構造）に適合**するよう再整備した。

---

### 1.2 責務
| 項目 | 内容 |
|------|------|
| **目的** | Passkeyによるワンタップログイン |
| **トリガ** | `<button>` 押下時にCorbadoの`passkey.login()`を呼び出す |
| **成功時** | Corbado発行の`id_token`をSupabase Authに委譲 |
| **失敗時** | ErrorHandlerProvider (C-16) 経由でUI通知 |
| **UI統一** | MagicLinkFormと同一のボタンスタイル・i18n構成 |

---

### 1.3 前提条件
| 項目 | 条件 |
|------|------|
| **ブラウザ** | WebAuthn Level 2準拠（Safari/Chrome/Edge 最新版） |
| **認証SDK** | Corbado SDK v2.x (`@corbado/web-js`) |
| **データ層** | Supabase Auth v2.43 (`signInWithIdToken`) |
| **RLS制御** | tenant_id スコープ（PostgreSQL 15.6） |
| **翻訳** | StaticI18nProvider (C-03)経由 `"auth.passkey.*"` |

---

## 第2章 構造設計

### 2.1 依存関係
```mermaid
graph TD
    A[MagicLinkForm (A-01)] --> B[PasskeyButton (A-02)]
    B --> C[AuthCallbackHandler (A-03)]
    B --> D[Supabase Auth]
    B --> E[Corbado SDK]
    F[StaticI18nProvider (C-03)] --> B
    G[ErrorHandlerProvider (C-16)] --> B

第3章 Props定義
export interface PasskeyButtonProps {
  className?: string;
  onSuccess?: () => void;
  onError?: (error: PasskeyError) => void;
}

export interface PasskeyError {
  code: string;
  message: string;
  type: 'error_network' | 'error_auth' | 'error_unknown';
}

第4章 内部状態管理
type PasskeyState = 'idle' | 'loading' | 'success' | 'error';

・state: 現在の認証状態
・error: 最新の例外内容

第5章 処理ロジック
5.1 認証フロー
'use client';
import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import Corbado from '@corbado/web-js';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { useErrorHandler } from '@/components/common/ErrorHandlerProvider';
import { KeyRound, Loader2, CheckCircle } from 'lucide-react';

export const PasskeyButton: React.FC<PasskeyButtonProps> = ({
  className,
  onSuccess,
  onError,
}) => {
  const [state, setState] = useState<PasskeyState>('idle');
  const { t } = useI18n();
  const handleError = useErrorHandler();
  const supabase = createClient();

  const handlePasskeyLogin = useCallback(async () => {
    try {
      setState('loading');

      await Corbado.load({
        projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!,
      });

      const result = await Corbado.passkey.login();
      if (!result?.success) throw new Error('Login failed');

      const { id_token } = result;
      const { error } = await supabase.auth.signInWithIdToken({
        provider: 'corbado',
        token: id_token,
      });

      if (error) throw error;

      setState('success');
      onSuccess?.();
    } catch (err: any) {
      setState('error');
      const e: PasskeyError = {
        code: err.code || 'unknown',
        message: err.message || 'Unexpected error',
        type: 'error_auth',
      };
      onError?.(e);
      handleError(e.message);
    }
  }, [onSuccess, onError, handleError, supabase]);

  return (
    <button
      type="button"
      onClick={handlePasskeyLogin}
      className={`
        w-full h-12 rounded-2xl bg-blue-600 text-white font-medium
        hover:bg-blue-500 transition disabled:opacity-60
        flex items-center justify-center gap-2 ${className}
      `}
      disabled={state === 'loading'}
    >
      {state === 'loading' ? (
        <>
          <Loader2 className="animate-spin" size={20} />
          {t('auth.passkey.progress')}
        </>
      ) : state === 'success' ? (
        <>
          <CheckCircle size={20} />
          {t('auth.passkey.success')}
        </>
      ) : (
        <>
          <KeyRound size={20} />
          {t('auth.passkey.login')}
        </>
      )}
    </button>
  );
};

第6章 UI仕様
項目	値
フォント	BIZ UDゴシック
角丸	rounded-2xl
影	shadow-sm
配色	#2563EB / hover:#3B82F6
高さ	48px
横幅	100%
状態別表示	idle / loading / success / error
i18nキー	"auth.passkey.login", "auth.passkey.progress", "auth.passkey.success"

第7章 テスト仕様（概要）
| テストID    | 内容          | 期待結果                       |
| -------- | ----------- | -------------------------- |
| T-A02-01 | 成功パスキー認証    | Supabaseセッション作成済み          |
| T-A02-02 | 無効トークン      | ErrorHandlerProvider呼出     |
| T-A02-03 | ネットワーク断     | `"error_network"` 発火       |
| T-A02-04 | i18n切替      | 表示文言がlocaleに応じて変化          |
| T-A02-05 | Storybook表示 | idle/loading/success 3状態描画 |

第8章 セキュリティ考慮
・HTTPS必須
・RP ID / Origin はCorbado側で検証
・Supabaseは短期セッションJWTを採用（60分）
・CSRFリスク無し（RESTless構成）

第9章 ChangeLog
| Version  | Date           | Author              | Description                                     |
| -------- | -------------- | ------------------- | ----------------------------------------------- |
| v1.0     | 2025-11-10     | Claude              | 初版（Supabase直呼び出し案）                              |
| v1.2     | 2025-11-10     | Tachikoma           | Corbado SDK試験版                                  |
| v1.3     | 2025-11-10     | Tachikoma           | Corbado公式UI構成検証版（参考保管）                          |
| **v1.4** | **2025-11-10** | **Tachikoma / TKD** | **正式仕様：独立ボタン構成 + Corbado.passkey.login() 方式確立** |

Author: Tachikoma
Reviewer: TKD
Directory: /01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design/
Status: ✅ 正式仕様登録（v1.3は##_oldへ移動）