# HarmoNet 詳細設計書 - MagicLinkForm (A-01) v1.0

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-DESIGN
**Version:** 1.0
**Created:** 2025-11-11
**Updated:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Supersedes:** MagicLinkForm-detail-design_v1.1（Phase8構成）
**Status:** ✅ Phase9正式仕様（Next.js 16 / Supabase v2.43 / React 19 / 技術スタックv4.0対応）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第1章 概要

### 1.1 目的

本設計書は、HarmoNetログイン画面における **A-01: MagicLinkForm** の詳細設計を定義する。
本コンポーネントは、ユーザーがメールアドレスを入力し、Supabase Auth の `signInWithOtp()` を通じて Magic Link を送信する役割を担う。
Corbado構成と並列で、Phase9の完全パスワードレス認証基盤を構成する。

### 1.2 責務

| 項目       | 内容                                                   |
| -------- | ---------------------------------------------------- |
| **目的**   | メールアドレス入力フォームからMagic Linkを送信する                       |
| **依存**   | Supabase Auth (`signInWithOtp`) / StaticI18nProvider |
| **成功時**  | ユーザーへメール送信完了メッセージ表示 (`sent` 状態)                      |
| **失敗時**  | 入力エラー・通信エラーを状態遷移でハンドリング                              |
| **UI統一** | PasskeyAuthTrigger (A-02) と同一トーンを維持                  |

---

## 第2章 機能設計

### 2.1 Props仕様

```ts
export interface MagicLinkFormProps {
  className?: string;
  onSent?: () => void;
  onError?: (error: MagicLinkError) => void;
}

export interface MagicLinkError {
  code: string;
  message: string;
  type: 'error_invalid' | 'error_network';
}
```

### 2.2 State仕様

| 状態            | 説明              |
| ------------- | --------------- |
| idle          | 初期状態            |
| sending       | Supabaseへリクエスト中 |
| sent          | メール送信成功         |
| error_invalid | 入力不正（形式エラー）     |
| error_network | 通信・API失敗        |

---

## 第3章 ロジック設計

```tsx
'use client';
import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { Loader2, Mail, CheckCircle, AlertCircle } from 'lucide-react';

export function MagicLinkForm({ className, onSent, onError }: MagicLinkFormProps) {
  const supabase = createClient();
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [state, setState] = useState<'idle'|'sending'|'sent'|'error_invalid'|'error_network'>('idle');

  const handleSendMagicLink = useCallback(async () => {
    if (!email.includes('@')) {
      const e = { code: 'INVALID_EMAIL', message: t('error.invalid_email'), type: 'error_invalid' };
      setState(e.type); onError?.(e as any); return;
    }

    try {
      setState('sending');
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}/auth/callback` },
      });
      if (error) throw error;
      setState('sent'); onSent?.();
    } catch {
      const e = { code: 'NETWORK', message: t('error.network'), type: 'error_network' };
      setState(e.type); onError?.(e as any);
    }
  }, [email, supabase, t, onError, onSent]);

  return (
    <form onSubmit={(e) => { e.preventDefault(); handleSendMagicLink(); }} className={`flex flex-col gap-3 ${className || ''}`}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder={t('auth.enter_email')}
        className="h-12 rounded-2xl px-3 border text-base"
        required
      />
      <button
        type="submit"
        disabled={state === 'sending'}
        className="h-12 rounded-2xl shadow-sm bg-blue-600 text-white flex items-center justify-center gap-2 disabled:opacity-60 hover:bg-blue-500 transition-all"
      >
        {state === 'sending' && <Loader2 className="animate-spin" size={18} />}
        {state === 'sent' && <CheckCircle className="text-green-600" size={18} />}
        {state.startsWith('error') && <AlertCircle className="text-red-500" size={18} />}
        <span>
          {state === 'sent' ? t('auth.email_sent') :
           state.startsWith('error') ? t('auth.retry') :
           t('auth.send_magic_link')}
        </span>
      </button>
      {state === 'sent' && <p className="text-sm text-gray-500" aria-live="polite">{t('auth.check_your_email')}</p>}
    </form>
  );
}
```

---

## 第4章 UI仕様

| 項目    | 値                           |
| ----- | --------------------------- |
| フォント  | BIZ UDゴシック                  |
| 背景    | `#F9FAFB`                   |
| ボタン高さ | `48px`                      |
| ボタン色  | `#2563EB` (hover:`#3B82F6`) |
| 角丸    | `rounded-2xl`               |
| 影     | `shadow-sm`                 |
| トーン   | やさしく・自然・控えめ                 |

---

## 第5章 再レンダー・副作用設計

* `useState` により入力と状態を明確に分離。
* フォーム送信中はボタンを無効化（`disabled`）。
* 成功・失敗時は状態のみ変更、再描画最小化。
* 多言語切替は StaticI18nProvider 経由で即時反映。

---

## 第6章 セキュリティ仕様

* HTTPS通信必須。
* Supabase側でメールリンクTTLを60秒に設定。
* `shouldCreateUser: false` により存在確認攻撃を防止。
* Email Enumeration防止（エラーメッセージ共通化）。
* XSS / CSRF対策（RESTless構成 + Reactエスケープ）。
* Supabase RLSによりtenant_id境界を保証。

---

## 第7章 テスト観点

| テストID     | シナリオ   | 期待結果                 |
| --------- | ------ | -------------------- |
| UT-A01-01 | 正常送信   | `/auth/callback` に遷移 |
| UT-A01-02 | 入力不正   | `error_invalid` 状態   |
| UT-A01-03 | 通信断    | `error_network` 状態   |
| UT-A01-04 | i18n切替 | 即時反映                 |
| UT-A01-05 | 再送防止   | sending中はボタンdisabled |

---

## 第8章 関連ファイル

| 種別      | ファイル                                                       | 用途                     |
| ------- | ---------------------------------------------------------- | ---------------------- |
| 状態管理    | `login-feature-design-ch02_v1.0.md`                        | MagicLinkForm仕様（A-01）  |
| セッション管理 | `login-feature-design-ch04_v1.0.md`                        | `/auth/callback`ハンドリング |
| セキュリティ  | `login-feature-design-ch05_v1.0.md`                        | Cookie/RLS仕様           |
| 共通UI    | `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md` | 多言語Provider            |

---

## 第9章 改訂履歴

| Version | Date       | Author          | Summary                                                         |
| ------- | ---------- | --------------- | --------------------------------------------------------------- |
| 1.0     | 2025-11-11 | TKD + Tachikoma | Phase9正式仕様。Supabase OTP構成を採用し、Corbado構成と並列化。UI・セキュリティ・UT観点を標準化。 |
