# MagicLinkForm 詳細設計書 - 第3章：ロジック設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH03
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Passkey自動統合対応）

---

## 第3章 ロジック設計

### 3.1 処理概要

MagicLinkForm (A-01) は、ユーザー入力のメールアドレスを基に、**Supabase Auth** および **Corbado SDK (WebAuthn)** を自動的に切り替えて認証を行う統合型ロジックである。
従来の MagicLinkForm は Supabase 専用のメールリンク送信処理のみを担っていたが、本改訂では以下の点を強化した。

| 項目    | 改訂内容                                                                         |
| ----- | ---------------------------------------------------------------------------- |
| 自動判定  | Supabaseの `user_profiles.passkey_enabled` を参照し、Corbado または Supabase APIを自動選択 |
| 統合処理  | `handleLogin()` で両方式を一括処理                                                    |
| 新状態追加 | `passkey_auth`, `success`, `error_auth` を導入                                  |
| 結果統合  | Supabaseセッション確立後、共通リダイレクト `/mypage`                                          |

本章では、入力検証・状態管理・主要ロジック・例外ハンドリング・i18n連携を含む完全なロジック構成を定義する。

---

### 3.2 入力検証設計

#### 3.2.1 検証仕様

* `type="email"` + 正規表現で形式検証。
* Passkey利用可否はSupabaseサーバー上の属性値に基づくため、フロントではメール形式のみ確認する。

```typescript
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
function validateEmail(email: string): boolean {
  return EMAIL_RE.test(email);
}
```

| 検証タイミング | 説明                    |
| ------- | --------------------- |
| 入力変更時   | 即時バリデーションを行いエラーハイライト  |
| 送信前     | 最終確認を実施。エラーなら即 return |

---

### 3.3 状態管理設計

```typescript
type MagicLinkState =
  | 'idle'          // 初期状態
  | 'sending'       // MagicLink送信中
  | 'passkey_auth'  // Passkey認証中
  | 'sent'          // MagicLink送信完了
  | 'success'       // 認証完了（Passkey or MagicLink）
  | 'error_invalid' // 入力形式エラー
  | 'error_network' // 通信・API失敗
  | 'error_auth';   // Passkey認証失敗

interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkState;
}
```

| 状態              | 概要             | 遷移トリガー                                    |
| --------------- | -------------- | ----------------------------------------- |
| `idle`          | 初期状態。入力可能      | 初期表示または再送信後                               |
| `sending`       | MagicLink送信処理中 | `handleLogin()` 呼出 (passkeyEnabled=false) |
| `passkey_auth`  | Passkey認証中     | `handleLogin()` 呼出 (passkeyEnabled=true)  |
| `sent`          | MagicLink送信完了  | Supabase応答成功時                             |
| `success`       | 認証成功           | Supabaseセッション確立後                          |
| `error_invalid` | 入力不正           | バリデーション失敗時                                |
| `error_network` | 通信失敗           | Supabase / Corbado通信エラー                   |
| `error_auth`    | 認証拒否           | Corbadoログインキャンセル時                         |

---

### 3.4 メインロジック構造

#### 3.4.1 handleLogin 実装

```typescript
'use client';
import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import Corbado from '@corbado/web-js';
import type { MagicLinkError } from './MagicLinkForm.types';

export function useMagicLink(onSent?: () => void, onError?: (e: MagicLinkError) => void, passkeyEnabled?: boolean) {
  const supabase = createClient();
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [state, setState] = useState<MagicLinkState>('idle');
  const [error, setError] = useState<MagicLinkError | null>(null);

  const handleLogin = useCallback(async () => {
    if (!validateEmail(email)) {
      const e: MagicLinkError = {
        code: 'INVALID_EMAIL',
        message: t('error.invalid_email'),
        type: 'error_invalid',
      };
      setError(e);
      setState(e.type);
      onError?.(e);
      return;
    }

    try {
      if (passkeyEnabled) {
        setState('passkey_auth');
        await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
        const result = await Corbado.passkey.login();
        if (!result?.id_token) throw new Error('Passkey login failed');

        const { error: authError } = await supabase.auth.signInWithIdToken({
          provider: 'corbado',
          token: result.id_token,
        });
        if (authError) throw authError;
        setState('success');
        onSent?.();
      } else {
        setState('sending');
        const { error: otpError } = await supabase.auth.signInWithOtp({
          email,
          options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}/auth/callback` },
        });
        if (otpError) throw otpError;
        setState('sent');
        onSent?.();
      }
    } catch (err: any) {
      const mapped = mapUnifiedError(err, t, passkeyEnabled);
      setError(mapped);
      setState(mapped.type);
      onError?.(mapped);
    }
  }, [email, passkeyEnabled, t, supabase, onSent, onError]);

  return { state, email, setEmail, error, handleLogin };
}
```

---

### 3.5 統合エラーマッピング関数

```typescript
function mapUnifiedError(err: any, t: (key: string) => string, passkeyEnabled?: boolean): MagicLinkError {
  const msg = err?.message || '';

  // Corbado passkey 失敗判定
  if (passkeyEnabled && (msg.includes('cancel') || msg.includes('NotAllowedError'))) {
    return {
      code: 'PASSKEY_DENIED',
      message: t('auth.passkey.denied'),
      type: 'error_auth',
    };
  }

  // Supabase invalid email
  if (msg.includes('Invalid email')) {
    return {
      code: 'INVALID_EMAIL',
      message: t('error.invalid_email'),
      type: 'error_invalid',
    };
  }

  // ネットワーク系
  if (msg.includes('Network') || msg.includes('fetch')) {
    return {
      code: 'NETWORK_ERROR',
      message: t('error.network'),
      type: 'error_network',
    };
  }

  return {
    code: 'UNKNOWN',
    message: t('error.unknown'),
    type: passkeyEnabled ? 'error_auth' : 'error_network',
  };
}
```

---

### 3.6 イベント・ハンドラ設計

| イベント名     | 発火条件    | ハンドラ               | 説明                           |
| --------- | ------- | ------------------ | ---------------------------- |
| `Submit`  | フォーム送信時 | `handleLogin()`    | メール検証＋認証呼出（Supabase/Corbado） |
| `onSent`  | 成功時     | `onSent?.()`       | 親へ通知（画面遷移・完了表示）              |
| `onError` | 失敗時     | `onError?.(error)` | 親でUI制御・ログ送信                  |

---

### 3.7 i18n キー仕様

```json
{
  "auth": {
    "passkey": {
      "login": "パスキーで認証中...",
      "denied": "パスキー認証が拒否されました。",
      "success": "パスキー認証が完了しました。"
    },
    "magiclink": {
      "send": "Magic Linkを送信",
      "sent": "メールを送信しました",
      "invalid_email": "メールアドレスの形式が正しくありません",
      "network_error": "通信エラーが発生しました",
      "unknown_error": "予期しないエラーが発生しました"
    },
    "error": {
      "network": "通信エラーが発生しました",
      "invalid_email": "メールアドレスの形式が正しくありません",
      "unknown": "予期しないエラーが発生しました"
    }
  }
}
```

---

### 3.8 リトライ・例外戦略

* 失敗時（`error_*`）はUIで保持し、再送信で`idle`へ戻す。
* `error_auth`（パスキー拒否）は再試行可能。
* Supabase APIエラー（429/500）は自動リトライ禁止。
* 予期せぬ例外は ErrorHandlerProvider (C-16) に委譲。
* PasskeyとMagicLinkで統一された `handleLogin` を維持し、UX一貫性を確保。

---

### 🧾 Change Log

| Version  | Date           | Summary                                           |
| -------- | -------------- | ------------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（Supabase専用MagicLink実装）                         |
| **v1.1** | **2025-11-12** | **Corbado連携統合。passkeyEnabled自動判定・共通ハンドラ設計・状態追加。** |
