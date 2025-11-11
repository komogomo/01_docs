# PasskeyButton 詳細設計書 - 第6章：ロジック実装（v1.1 改訂版）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH06  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / PasskeyButton-detail-design_v1.4.md  
**Reviewer:** TKD  
**Status:** Phase9 正式仕様整合版  

---

## 第6章：ロジック実装

### 6.1 Passkey認証フロー

#### 6.1.1 全体フロー（Corbado SDK + Supabase連携）
```typescript
'use client';
import { useCallback, useState } from 'react';
import Corbado from '@corbado/web-js';
import { createClient } from '@/lib/supabase/client';
import { useErrorHandler } from '@/components/common/ErrorHandlerProvider';
import { PasskeyError } from './PasskeyButton.types';

export const usePasskeyLogin = (
  onSuccess?: () => void,
  onError?: (e: PasskeyError) => void
) => {
  const [state, setState] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const handleError = useErrorHandler();
  const supabase = createClient();

  const handlePasskeyLogin = useCallback(async () => {
    if (state === 'loading') return;
    setState('loading');

    try {
      // Step 1: Corbado SDK 初期化
      await Corbado.load({
        projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!,
      });

      // Step 2: Passkey 認証実行
      const result = await Corbado.passkey.login();
      if (!result?.success) throw new Error('Passkey login failed');

      // Step 3: Supabase 認証連携
      const { error } = await supabase.auth.signInWithIdToken({
        provider: 'corbado',
        token: result.id_token,
      });

      if (error) throw error;

      // Step 4: 成功時処理
      setState('success');
      onSuccess?.();
    } catch (err: any) {
      // Step 5: 失敗時処理
      setState('error');
      const e: PasskeyError = {
        code: err.code || 'unknown',
        message: err.message || 'Unexpected error',
        type: 'error_auth',
      };
      onError?.(e);
      handleError(e);

      // Step 6: 再試行可能化
      setTimeout(() => setState('idle'), 300);
    }
  }, [state, supabase, onSuccess, onError, handleError]);

  return { handlePasskeyLogin, state };
};

6.2 処理概要
| ステップ   | 処理内容           | 主要API / 関数                             |
| ------ | -------------- | -------------------------------------- |
| Step 1 | Corbado SDK初期化 | `Corbado.load()`                       |
| Step 2 | Passkey認証実行    | `Corbado.passkey.login()`              |
| Step 3 | Supabaseログイン連携 | `supabase.auth.signInWithIdToken()`    |
| Step 4 | 成功処理           | `onSuccess()`                          |
| Step 5 | 失敗処理           | `onError(error)` + `setState('error')` |
| Step 6 | 状態復帰           | `setTimeout(setState('idle'))`         |

6.3 PasskeyError 構造
export interface PasskeyError {
  code: string;
  message: string;
  type: 'error_network' | 'error_auth' | 'error_unknown';
}

利用方針
・error_auth: Corbado認証失敗
・error_network: 通信エラー
・error_unknown: 不明な例外
・全てErrorHandlerProvider経由でUI通知される

6.4 成功時の動作
・state を 'success' に更新
・親コンポーネントで onSuccess() が発火
・Supabaseセッションが確立し、マイページへ遷移

if (state === 'success') router.push('/home');

6.5 エラーハンドリング
| 種別            | 例外           | 表示メッセージ           | 再試行 |
| ------------- | ------------ | ----------------- | --- |
| Corbado 初期化失敗 | projectId不正  | 「認証設定に問題があります」    | 可   |
| Passkey認証失敗   | 生体認証拒否・PIN誤り | 「認証に失敗しました」       | 可   |
| Supabase連携失敗  | token検証エラー   | 「サーバーでエラーが発生しました」 | 可   |
| 不明例外          | その他          | 「予期しないエラーが発生しました」 | 可   |

6.6 状態管理（UI連携）
switch (state) {
  case 'loading':
    return <Loader2 className="animate-spin" />;
  case 'success':
    return <CheckCircle className="text-green-500" />;
  case 'error':
    return <XCircle className="text-red-500" />;
  default:
    return <KeyRound />;
}

・状態は useState で制御
・UI構成は第5章の仕様に一致
・i18nテキストは "auth.passkey.*" キー群を使用

6.7 セキュリティ考慮事項
・Corbado.load() は1リクエスト1初期化
・id_token はSupabase経由でのみ利用
・NEXT_PUBLIC_CORBADO_PROJECT_ID のみフロント公開可
・サービスキー(CORBADO_API_SECRET) はサーバー専用
・CSRF防止・RLS適用済（Supabase Auth標準対応）

6.8 パフォーマンス最適化
・useCallback によるハンドラメモ化
・不要再レンダリング抑止
・API呼び出し失敗時に即座にidleへ復帰
・Supabase側セッション再利用による高速化

🧾 ChangeLog
| Version | Date       | Summary                                                                  |
| ------- | ---------- | ------------------------------------------------------------------------ |
| v1.0    | 2025-01-10 | 初版（Supabase.signInWithPasskey 構成）                                        |
| v1.1    | 2025-11-10 | Corbado SDK + Supabase.signInWithIdToken構成へ全面更新。状態管理統一、例外型整備、セキュリティ仕様追加。 |

文書ステータス: ✅ Phase9 正式整合版