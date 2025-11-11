# HarmoNet 詳細設計書 - MagicLinkForm (A-01) v1.1

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-DESIGN  
**Version:** 1.1  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-01  
**Component Name:** MagicLinkForm  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** Phase9 技術統合版（Next.js 16 / Supabase v2.43 / React 19）  

---

## 📚 参照文書
- /01_docs/00_project/harmonet-technical-stack-definition_v3.9.md  
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch03_v1.3.1.md  
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch04_v1.1.md  
- /01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md  
- schema.prisma, initial_schema.sql, enable_rls_policies.sql  

---

## 第1章 概要

### 1.1 目的
本書は HarmoNet ログイン画面における **メールリンク認証フォーム（A-01 MagicLinkForm）** の詳細設計を定義する。  
ユーザーがメールアドレスを入力して送信すると、Supabase Auth が **Magic Link** を発行し、  
メール経由でワンタップログインを可能にする。

### 1.2 設計方針
- Supabase JS SDK v2.43+ の `auth.signInWithOtp()` を利用。  
- パスワードレス認証（Magic Link）。  
- Next.js 16.0.1 (App Router) + React 19 + TypeScript 5.6。  
- StaticI18nProvider による i18n、簡潔で安心感のあるUI。  
- Supabaseがセッション管理とRLSを担当。  

---

## 第2章 構造設計

### 2.1 Props / State

```ts
export interface MagicLinkFormProps {
  className?: string;
  onSent?: () => void;
  onError?: (error: MagicLinkError) => void;
}

type MagicLinkState = 'idle' | 'sending' | 'sent' | 'error_invalid' | 'error_network';

export interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkState;
}

2.2 実装例
'use client';

import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { Button, Input } from '@/components/ui';
import { Loader2, Mail, CheckCircle, AlertCircle } from 'lucide-react';

export function MagicLinkForm({ className, onSent, onError }: MagicLinkFormProps) {
  const supabase = createClient();
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [state, setState] = useState<MagicLinkState>('idle');
  const [error, setError] = useState<MagicLinkError | null>(null);

  const handleSendMagicLink = useCallback(async () => {
    if (!email.includes('@')) {
      const e = { code: 'INVALID_EMAIL', message: t('error.invalid_email'), type: 'error_invalid' } as MagicLinkError;
      setError(e); setState(e.type); onError?.(e);
      return;
    }

    try {
      setState('sending');
      const { error: authError } = await supabase.auth.signInWithOtp({
        email,
        options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}/auth/callback` },
      });

      if (authError) throw authError;
      setState('sent');
      onSent?.();
    } catch (err) {
      const e = { code: 'NETWORK', message: t('error.network'), type: 'error_network' } as MagicLinkError;
      setError(e); setState(e.type); onError?.(e);
    }
  }, [email, supabase, t, onError, onSent]);

  return (
    <form
      onSubmit={(e) => { e.preventDefault(); handleSendMagicLink(); }}
      className={`w-full flex flex-col gap-3 ${className || ''}`}
    >
      <Input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder={t('auth.enter_email')}
        className="h-12 rounded-xl px-3 border"
        required
      />
      <Button
        type="submit"
        disabled={state === 'sending'}
        variant="outline"
        className="h-12 rounded-xl flex items-center justify-center gap-2"
      >
        {state === 'sending' && <Loader2 className="animate-spin" />}
        {state === 'sent' && <CheckCircle className="text-green-600" />}
        {state.startsWith('error') && <AlertCircle className="text-red-500" />}
        {state === 'idle' && <Mail />}
        <span>
          {state === 'sent' ? t('auth.email_sent') :
           state.startsWith('error') ? t('auth.retry') :
           t('auth.send_magic_link')}
        </span>
      </Button>
      {state === 'sent' && <p className="text-sm text-gray-500">{t('auth.check_your_email')}</p>}
    </form>
  );
}

第3章 ロジック設計
| 状態            | 説明              |
| ------------- | --------------- |
| idle          | 初期状態            |
| sending       | Supabaseへリクエスト中 |
| sent          | 成功（メール送信完了）     |
| error_invalid | 入力エラー（形式不正）     |
| error_network | 通信・API失敗        |

第4章 UI設計
・BIZ UDゴシック / 16px
・入力欄＋ボタンを縦並びで配置
・成功時は淡い緑色メッセージを表示
・エラー時は赤色メッセージ、アクセシブルにaria-live="polite"

第5章 テスト仕様
・入力値なし → error_invalid
・成功 → sent
・Supabaseエラー → error_network
・onSent / onError コールバック発火確認

第6章 セキュリティ考慮
・HTTPS通信必須
・Supabase側でメールリンクの有効期限を短期設定
・ユーザー存在確認を抑止 (shouldCreateUser:false)
・XSS / CSRF / Email Enumeration対策

第7章 環境設定

・.env に NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
・Supabase Auth 設定で emailRedirectTo を /auth/callback に指定

第8章 監査・保守指針
・Supabase SDK バージョンの更新を月次確認
・MagicLink送信成功率・遷移ログを分析
・auth/callback の安全性テストを年次実施

第9章 ChangeLog
| Version  | Date           | Author              | Description                                                   |
| -------- | -------------- | ------------------- | ------------------------------------------------------------- |
| v1.0     | 2025-11-10     | TKD / Claude        | 初版（Phase8仕様）                                                  |
| **v1.1** | **2025-11-10** | **TKD / Tachikoma** | **Phase9技術スタック準拠、Supabase `signInWithOtp()` 採用、Next.js16対応。** |
