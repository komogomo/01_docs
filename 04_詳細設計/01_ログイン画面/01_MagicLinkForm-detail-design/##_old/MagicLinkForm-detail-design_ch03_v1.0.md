# MagicLinkForm 詳細設計書 - 第3章：ロジック設計（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH03
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式整合版（技術スタック v4.0 準拠）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第3章 ロジック設計

### 3.1 処理概要

MagicLinkForm は、ユーザーのメールアドレスを入力として受け取り、Supabase Auth の `signInWithOtp()` を実行して Magic Link を発行する。
この章では、フォーム入力検証、送信ロジック、エラー処理、イベントハンドリング、および i18n 構成を含むフロントエンドロジックの詳細を定義する。

主要責務：

* メール入力値の検証と補正
* Supabase 認証 API 呼び出しと結果ハンドリング
* 状態遷移制御（`idle → sending → sent/error_*`）
* 翻訳・例外処理統合（StaticI18nProvider）
* 親コンポーネントとのイベント連携（onSent, onError）

---

### 3.2 入力検証設計

#### 3.2.1 検証仕様

* HTML5の `type="email"` に加え、軽量正規表現で形式検証を行う。
* `@` と `.` を含む基本構造を確認。
* 入力内容が不正な場合、即座に `error_invalid` 状態へ遷移し、翻訳メッセージを表示する。

```typescript
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validateEmail(email: string): boolean {
  return EMAIL_RE.test(email);
}
```

#### 3.2.2 再検証タイミング

| 検証タイミング | 説明                    |
| ------- | --------------------- |
| 入力変更時   | フィールド即時バリデーション（視覚的補助） |
| 送信前     | API呼出し前の最終確認（多重送信防止）  |

---

### 3.3 状態管理設計

```typescript
type MagicLinkState =
  | 'idle'           // 初期状態
  | 'sending'        // Supabase呼出中
  | 'sent'           // 成功（メール送信完了）
  | 'error_invalid'  // 入力エラー
  | 'error_network'  // 通信失敗
  | 'error_unknown'; // 想定外エラー

interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkState;
}
```

| 状態              | 説明                    | 遷移トリガー                     |
| --------------- | --------------------- | -------------------------- |
| `idle`          | 初期状態。入力可能。            | 初期表示、再送信後リセット              |
| `sending`       | Magic Link送信中。ボタン無効化。 | `handleSendMagicLink()` 呼出 |
| `sent`          | メール送信完了。完了メッセージ表示。    | Supabase応答成功時              |
| `error_invalid` | 入力検証エラー。              | バリデーション失敗時                 |
| `error_network` | 通信／APIエラー。            | Supabase応答異常時              |
| `error_unknown` | 想定外の例外。               | その他の例外捕捉時                  |

---

### 3.4 メインロジック構造

#### 3.4.1 全体構成

MagicLinkForm のロジックは React Hooks (`useState`, `useCallback`) により完結する。
外部ライブラリは Supabase SDK と StaticI18nProvider のみを利用し、依存を最小化する。

```typescript
'use client';
import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import type { MagicLinkError } from './MagicLinkForm.types';

export function useMagicLink(onSent?: () => void, onError?: (e: MagicLinkError) => void) {
  const supabase = createClient();
  const { t } = useI18n();

  const [state, setState] = useState<MagicLinkState>('idle');
  const [email, setEmail] = useState('');
  const [error, setError] = useState<MagicLinkError | null>(null);

  const handleSendMagicLink = useCallback(async () => {
    if (state === 'sending') return; // 多重送信防止

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

      if (authError) throw authError;

      setState('sent');
      onSent?.();
    } catch (err: any) {
      const mapped = mapSupabaseError(err, t);
      setError(mapped);
      setState(mapped.type);
      onError?.(mapped);
    }
  }, [email, state, supabase, t, onSent, onError]);

  return { state, email, setEmail, error, handleSendMagicLink };
}
```

---

### 3.5 エラーマッピング関数

Supabase の返却エラーを i18n メッセージへ変換する。

```typescript
type TFn = (key: string) => string;

function mapSupabaseError(err: any, t: TFn): MagicLinkError {
  const status = err?.status || err?.code || 0;

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

### 3.6 イベント・ハンドラ設計

| イベント名     | 発火条件    | ハンドラ                    | 説明                      |
| --------- | ------- | ----------------------- | ----------------------- |
| `Submit`  | フォーム送信時 | `handleSendMagicLink()` | 入力検証＋Supabase呼出         |
| `onSent`  | 成功時     | `onSent?.()`            | 親コンポーネントへ通知（成功メッセージ表示等） |
| `onError` | 失敗時     | `onError?.(error)`      | 親でエラー表示・ログ出力            |

---

### 3.7 i18n キー仕様

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

### 3.8 リトライ・例外戦略

* 失敗時は `error_*` 状態で保持し、ユーザー操作により `idle` に戻す。
* `RATE_LIMITED` 時は自動リトライを禁止（手動再送のみ）。
* Supabase API の応答遅延（>10s）発生時は UI 側でタイムアウト検知を検討。
* 想定外例外 (`error_unknown`) は ErrorHandlerProvider に委譲。

---

### 🧾 Change Log

| Version | Date       | Summary                                                |
| ------- | ---------- | ------------------------------------------------------ |
| v1.0    | 2025-11-11 | 初版（Phase9仕様：Supabase認証ロジック・入力検証・エラーマッピング統合、UIイベント構成定義） |
