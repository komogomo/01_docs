# HarmoNet 詳細設計書 - PasskeyButton (A-02) v1.2

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-DESIGN  
**Version:** 1.2  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** Phase9 技術統合版（Next.js 16 / Supabase v2.43 / React 19 / Corbado連携）  

---

## 📚 参照文書
- /01_docs/00_project/harmonet-technical-stack-definition_v3.9.md
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch03_v1.3.1.md
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch05_v1.1.md
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch06_v1.1.md
- /01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md
- schema.prisma, 20251107000000_initial_schema.sql, 20251107000001_enable_rls_policies.sql

---

## 第1章 概要

### 1.1 目的
HarmoNet ログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** の詳細設計を定義する。  
本バージョンでは、技術スタック v3.9 の方針に従い **Corbado WebAuthn SDK** を用いてパスキー認証を実施し、**Supabase に Id Token を渡してセッションを確立**するフローを採用する。

### 1.2 ポリシー
- Next.js 16.0.1 (App Router) / React 19 / TypeScript 5.6
- Corbado Web SDK（@corbado/web-js）で WebAuthn（Passkey）を実行
- 認証成功後、`supabase.auth.signInWithIdToken({ provider: 'corbado', token })`
- StaticI18nProvider による多言語対応、控えめなUIトーン、アクセシブルな状態提示

---

## 第2章 構造設計

### 2.1 依存関係
- @supabase/supabase-js ^2.43.0
- @corbado/web-js ^2.x
- next ^16.0.1, react ^19.0.0
- tailwindcss ^3.4, shadcn/ui, lucide-react

### 2.2 Props / State

```ts
export interface PasskeyButtonProps {
  className?: string;
  onSuccess?: () => void;
  onError?: (error: PasskeyError) => void;
}

type PasskeyState = 'idle' | 'loading' | 'success' | 'error_denied' | 'error_origin' | 'error_network';

export interface PasskeyError {
  code: string;
  message: string;
  type: PasskeyState;
}
```

### 2.3 実装例（Next.js 16 / App Router）

```tsx
'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { Button } from '@/components/ui/button';
import { KeyRound, Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import { Corbado } from '@corbado/web-js'; // 仮の命名。実際の初期化方法はCorbado公式に従う

export function PasskeyButton({ className, onSuccess, onError }: PasskeyButtonProps) {
  const [state, setState] = useState<PasskeyState>('idle');
  const [error, setError] = useState<PasskeyError | null>(null);
  const { t } = useI18n();
  const router = useRouter();
  const supabase = createClient();

  const handlePasskeyLogin = useCallback(async () => {
    setState('loading');
    setError(null);
    try {
      // 1) Corbado で WebAuthn 認証を実行して id_token を取得
      const corbado = new Corbado({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
      const result = await corbado.loginWithPasskey(); // 実際のAPI名はCorbado公式に合わせる
      const idToken = result?.idToken;
      if (!idToken) {
        const e: PasskeyError = { code: 'DENIED', message: t('error.passkey_denied'), type: 'error_denied' };
        setError(e); setState(e.type); onError?.(e); return;
      }

      // 2) Supabase に Id Token を渡してセッション確立
      const { data, error: authError } = await supabase.auth.signInWithIdToken({
        provider: 'corbado',
        token: idToken
      });

      if (authError) {
        const e: PasskeyError = { code: 'ORIGIN', message: t('error.origin_mismatch'), type: 'error_origin' };
        setError(e); setState(e.type); onError?.(e); return;
      }

      setState('success');
      onSuccess?.();
      setTimeout(() => router.push('/mypage'), 1200);
    } catch (err) {
      const e: PasskeyError = { code: 'NETWORK', message: t('error.network'), type: 'error_network' };
      setError(e); setState(e.type); onError?.(e);
    }
  }, [router, supabase, t, onError, onSuccess]);

  return (
    <Button
      onClick={handlePasskeyLogin}
      disabled={state === 'loading'}
      variant="outline"
      className={`w-full h-12 rounded-xl font-bold flex items-center justify-center gap-2 ${className || ''}`}
      aria-busy={state === 'loading'}
      aria-live="polite'
    >
      {state === 'loading' && <Loader2 className="animate-spin" />}
      {state === 'success' && <CheckCircle className="text-green-600" />}
      {state.startsWith('error') && <AlertCircle className="text-red-500" />}
      {state === 'idle' && <KeyRound />}
      <span>
        {state === 'success'
          ? t('auth.success')
          : state.startsWith('error')
          ? t('auth.retry')
          : t('auth.passkey')}
      </span>
    </Button>
  );
}
```

> **注記:** Corbado SDK のAPI名・初期化方法（`new Corbado({...})` / `loginWithPasskey()` など）は、導入するSDKバージョンの公式サンプルに合わせて微調整すること。

---

## 第3章 ロジック設計

### 3.1 フロー
1. ボタン押下 → state=loading  
2. Corbado SDK で WebAuthn 認証を開始  
3. 成功時に `id_token` を受領  
4. Supabase `signInWithIdToken({ provider: 'corbado', token })` でセッション確立  
5. 成功表示 → `/mypage` へ遷移  
6. 失敗時は種別別メッセージ（denied / origin / network）

### 3.2 エラー分類
| 種別 | 例 | 表示キー |
|------|----|----------|
| error_denied | ユーザーキャンセル/生体拒否 | `error.passkey_denied` |
| error_origin | IdToken検証失敗、ドメイン不一致 | `error.origin_mismatch` |
| error_network | 通信例外 | `error.network` |

---

## 第4章 UI設計（抜粋）
- ボタン：`w-full h-12 rounded-xl font-medium`、lucide-reactアイコンで状態可視化
- i18n：`auth.passkey` / `auth.success` / `auth.retry` / `error.*` を `common.json` に定義
- アクセシビリティ：`aria-busy` / `aria-live="polite"` / 状態テキストを `role="status"` で補強可

---

## 第5章 テスト仕様（抜粋）
- Corbado SDK をモックし、id_token あり/なし/例外の分岐を検証
- Supabase `signInWithIdToken` の成功/失敗分岐をモックで再現
- 主要ケース：初期表示、成功遷移、denied、origin、network、onSuccess/onError 発火

---

## 第6章 セキュリティ考慮
- WebAuthn 検証（challenge, rpId, attestation）は Corbado 側の責務
- Supabase は JWT セッション確立後、RLS によりデータアクセスを制御
- HTTPS/Origin 一致、Cookie Secure、XSS/CSRF 標準対策

---

## 第7章 依存・設定
- env: `NEXT_PUBLIC_CORBADO_PROJECT_ID` を追加
- Corbado管理画面で RP ID（本番ドメイン）を登録
- 開発環境は `localhost` → `http://localhost` のOrigin設定に注意

---

## 第8章 監査・保守指針（本コンポーネント）
- SDKバージョン差分を月次確認し、API名/戻り値の変動を監視
- IdToken検証エラーのログを集約（Sentry等）
- UXテレメトリ：成功率/所要時間/キャンセル率を記録

---

## 第9章 ChangeLog
| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v1.0 | 2025-11-10 | TKD / Claude | 初版（Supabase直呼び出し案） |
| v1.1 | 2025-11-10 | TKD / Tachikoma | 実在API整合（Next.js16対応） |
| **v1.2** | **2025-11-10** | **TKD / Tachikoma** | **Corbado連携方式へ全面切替。Supabaseは `signInWithIdToken` に限定。** |

---
