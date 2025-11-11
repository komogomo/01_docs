# MagicLinkForm 詳細設計書 - 第3章：ロジック設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH03  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第3章 ロジック設計

### 3.1 入力検証

#### 3.1.1 仕様
- 必須入力、`type="email"` に加えて **軽量正規表現** で検証する。  
- 送信直前にも再検証（多重送信予防）。

```typescript
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateEmail(email: string): boolean {
  return EMAIL_RE.test(email);
}
```

---

### 3.2 状態管理

```typescript
type MagicLinkState =
  | 'idle'
  | 'sending'
  | 'sent'
  | 'error_invalid'
  | 'error_network'
  | 'error_unknown';

interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkState;
}
```

---

### 3.3 メインフロー

```typescript
'use client';

import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import type { MagicLinkError } from './MagicLinkForm.types'; // 任意（分離時）

export function useMagicLink(onSent?: () => void, onError?: (e: MagicLinkError) => void) {
  const supabase = createClient();
  const { t } = useI18n();

  const [state, setState] = useState<MagicLinkState>('idle');
  const [email, setEmail] = useState('');
  const [error, setError] = useState<MagicLinkError | null>(null);

  const handleSendMagicLink = useCallback(async () => {
    if (state === 'sending') return;

    // 入力検証
    if (!validateEmail(email)) {
      const e: MagicLinkError = {
        code: 'INVALID_EMAIL',
        message: t('auth.magiclink.invalid_email'),
        type: 'error_invalid',
      };
      setError(e);
      setState(e.type);
      onError?.(e);
      return;
    }

    try {
      setState('sending');

      const { error: authError } = await supabase.auth.signInWithOtp({
        email,
        options: {
          shouldCreateUser: false,
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (authError) {
        throw authError;
      }

      setState('sent');
      onSent?.();
    } catch (err: any) {
      const mapped = mapSupabaseError(err, t);
      setError(mapped);
      setState(mapped.type);
      onError?.(mapped);
    }
  }, [email, state, supabase, t, onSent, onError]);

  return {
    state,
    email,
    setEmail,
    error,
    handleSendMagicLink,
  };
}
```

---

### 3.4 エラーマッピング

```typescript
type TFn = (key: string) => string;

function mapSupabaseError(err: any, t: TFn): MagicLinkError {
  const status = err?.status || err?.code || 0;
  // 代表的エラーの文言整備（i18nキー）
  if (status === 400 || err?.message?.includes('Invalid email')) {
    return {
      code: 'INVALID_EMAIL',
      message: t('auth.magiclink.invalid_email'),
      type: 'error_invalid',
    };
  }
  if (status === 429 || /rate/i.test(err?.message || '')) {
    return {
      code: 'RATE_LIMITED',
      message: t('auth.magiclink.rate_limited'),
      type: 'error_network',
    };
  }
  if (status >= 500) {
    return {
      code: 'SERVER_ERROR',
      message: t('auth.magiclink.server_error'),
      type: 'error_network',
    };
  }
  return {
    code: 'UNKNOWN',
    message: t('auth.magiclink.unknown_error'),
    type: 'error_unknown',
  };
}
```

---

### 3.5 イベント設計

| イベント | 発火条件 | ハンドラ | 備考 |
|---------|---------|---------|------|
| Submit | ボタンクリック / Enter | `handleSendMagicLink` | 多重送信抑止（`state==='sending'`） |
| onSent | 成功時 | `onSent?.()` | 親で遷移やToast実行 |
| onError | 失敗時 | `onError?.(error)` | 親でエラー表示やログ収集 |

---

### 3.6 i18nキー（論理）

```json
{
  "auth": {
    "magiclink": {
      "send": "Magic Linkを送信",
      "sending": "送信中...",
      "sent": "メールを送信しました",
      "check_email": "メールをご確認ください",
      "invalid_email": "メールアドレスの形式が正しくありません",
      "network_error": "通信エラーが発生しました",
      "server_error": "サーバーでエラーが発生しました",
      "unknown_error": "予期しないエラーが発生しました",
      "rate_limited": "短時間に送信しすぎました。しばらくしてから再試行してください。"
    }
  }
}
```

---

### 3.7 例外・リトライ戦略
- `error_*` 状態では **300ms** 後に `idle` へ戻すのは任意。UX次第で `reset()` を提供して親が制御しても良い。  
- Rate limit（429）時は **自動リトライしない**。明示メッセージのみ。  
- 成功（`sent`）後はフォームをdisableし、再送リンクをUIで提供する案も可。

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。i18nキーを`auth.magiclink.*`へ統一、Supabaseエラーマッピング追加。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第4章 UI設計（ch04）へ進む
