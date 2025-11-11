# HarmoNet Phase9 ログインコンポーネント設計書レビュー v1.0

**Document ID:** HARMONET-REVIEW-LOGIN-COMPONENTS-V1.0  
**Review Date:** 2025年11月10日  
**Reviewer:** Claude (AI Technical Reviewer)  
**Target Documents:**
- `MagicLinkForm-detail-design_v1.1.md`
- `PasskeyButton-detail-design_v1.2.md`

**Technology Stack:**
- Next.js 16.0.1 (App Router)
- React 19.0.0
- Supabase JS SDK v2.43.0
- Corbado WebAuthn SDK (@corbado/web-js) v2.x
- TypeScript 5.6

---

## 📋 目次

1. [レビュー概要](#レビュー概要)
2. [Supabase JS SDK v2.43 API整合性](#1-supabase-js-sdk-v243-api整合性)
3. [Next.js 16 / React 19 構文適合性](#2-nextjs-16--react-19-構文適合性)
4. [2ファイル間整合性](#3-2ファイル間整合性)
5. [セキュリティ・UX考慮](#4-セキュリティux考慮)
6. [総合評価](#総合評価)
7. [修正推奨事項](#修正推奨事項)
8. [次のアクション](#次のアクション)

---

## レビュー概要

本レビューは、HarmoNet Phase9におけるログイン画面コンポーネント2件の詳細設計書について、以下の観点から技術的整合性を検証したものです。

**レビュー観点:**
- APIやメソッドが実在するか（Supabase v2.43, Corbado SDK）
- コード例が技術的に成立するか（Next.js 16構文含む）
- 2ファイル間の整合性（UIトーン・i18n・状態管理など）
- セキュリティ・UX上の見落としがないか

**検証方法:**
- Supabase公式ドキュメント参照（2025年11月時点）
- Corbado公式npm/GitHubリポジトリ参照
- Next.js 16公式ドキュメント参照
- プロジェクトナレッジ（技術スタック定義書 v3.9）との整合性確認

---

## 1. Supabase JS SDK v2.43 API整合性

### 1.1 MagicLinkForm (A-01) - ✅ 適合

#### ✓ **適合項目**

```typescript
// 設計書記載のAPI利用
const { error } = await supabase.auth.signInWithOtp({
  email,
  options: { 
    shouldCreateUser: false, 
    emailRedirectTo: `${window.location.origin}/auth/callback` 
  },
});
```

**検証結果:**
- ✅ `supabase.auth.signInWithOtp()` は実在するAPI
- ✅ `email` パラメータは必須かつ正規
- ✅ `options.shouldCreateUser` (boolean) は正規パラメータ
- ✅ `options.emailRedirectTo` (string) は正規パラメータ
- ✅ 戻り値: `{ data: { user: null, session: null }, error: AuthError | null }`

**Supabase公式ドキュメント:**
> "If the user doesn't exist, signInWithOtp() will signup the user instead. To restrict this behavior, you can set shouldCreateUser in SignInWithPasswordlessCredentials.options to false."

#### ⚠️ **指摘事項**

**1. エラーハンドリングの変数名不整合**

```typescript
// 設計書記載
const { error: authError } = await supabase.auth.signInWithOtp({...});
if (authError) throw authError;
```

**問題点:**
- 変数名を `error` から `authError` に変更しているが、後続で一貫性がない
- catch ブロックでは `err` を使用

**推奨:**
```typescript
const { error } = await supabase.auth.signInWithOtp({...});
if (error) throw error;
```

**2. shouldCreateUser の挙動確認が必要**

- 設計書: `shouldCreateUser: false`
- 実際の挙動: **未登録ユーザーはエラーになる**
- **要確認事項:** Phase9では事前にユーザー登録フローが必要か？
- **推奨:** ユーザー登録方法（管理者による事前登録 or 自己登録）を明確化

---

### 1.2 PasskeyButton (A-02) - ❌ **重大な問題: Corbado API記述不整合**

#### ❌ **設計書に記載されているコード（v1.2）**

```typescript
// 設計書記載（実際には動作しない）
const corbado = new Corbado({ 
  projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! 
});
const { idToken } = await corbado.loginWithPasskey();
```

#### **実際のCorbado @corbado/web-js API（2025年11月時点）**

**1. 初期化方法が異なる**

```typescript
import Corbado from '@corbado/web-js';

// グローバル初期化（アプリ起動時に一度だけ実行）
await Corbado.load({ 
  projectId: 'pro-XXXXXXXXXXXXXXXXXXXX' 
});

// 以降は Corbado.xxx でメソッド呼び出し
// new Corbado() によるインスタンス化は不可
```

**2. loginWithPasskey() メソッドは存在しない**

- `corbado.loginWithPasskey()` → **存在しないメソッド**
- Corbado SDKは **UIコンポーネント駆動型** の設計

**3. Corbado公式の推奨実装パターン**

```typescript
// React コンポーネント利用（推奨）
import { CorbadoProvider, CorbadoAuth } from '@corbado/react';

function App() {
  const onLoggedIn = () => {
    // 認証成功後の処理
    // Corbado.sessionToken または Corbado.user 経由で id_token 取得
  };

  return (
    <CorbadoProvider projectId="<Project ID>">
      <CorbadoAuth onLoggedIn={onLoggedIn} />
    </CorbadoProvider>
  );
}
```

**または、低レベルAPIを使用:**

```typescript
// UIコンポーネントをマウント
const authElement = document.getElementById('corbado-auth');
Corbado.mountAuthUI(authElement, {
  onLoggedIn: () => {
    const idToken = Corbado.sessionToken; // これでトークン取得
    // Supabase連携処理
  },
});
```

#### **正しい実装例（Next.js 16 + App Router）**

```typescript
'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { Button } from '@/components/ui/button';
import { KeyRound, Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import Corbado from '@corbado/web-js';

export function PasskeyButton({ className, onSuccess, onError }: PasskeyButtonProps) {
  const [state, setState] = useState<PasskeyState>('idle');
  const [error, setError] = useState<PasskeyError | null>(null);
  const { t } = useI18n();
  const router = useRouter();
  const supabase = createClient();
  const [corbadoLoaded, setCorbadoLoaded] = useState(false);

  // Corbado初期化（コンポーネントマウント時に一度だけ）
  useEffect(() => {
    const initCorbado = async () => {
      try {
        await Corbado.load({ 
          projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! 
        });
        setCorbadoLoaded(true);
      } catch (err) {
        console.error('Corbado initialization failed:', err);
      }
    };
    initCorbado();
  }, []);

  const handlePasskeyLogin = useCallback(async () => {
    if (!corbadoLoaded) {
      const e: PasskeyError = {
        code: 'CORBADO_NOT_LOADED',
        message: t('error.system'),
        type: 'error_network'
      };
      setError(e);
      setState('error_network');
      onError?.(e);
      return;
    }

    setState('loading');
    setError(null);
    
    try {
      // 方法1: Corbadoの認証状態を確認
      if (!Corbado.isAuthenticated) {
        throw new Error('User not authenticated with Corbado');
      }
      
      // 方法2: sessionTokenを取得（Corbado認証後に利用可能）
      const idToken = Corbado.sessionToken;
      
      if (!idToken) {
        throw new Error('No ID token available');
      }

      // Supabaseセッション確立
      const { error: supabaseError } = await supabase.auth.signInWithIdToken({
        provider: 'corbado',
        token: idToken,
      });

      if (supabaseError) throw supabaseError;

      setState('success');
      onSuccess?.();
      router.push('/mypage');
    } catch (err: any) {
      let errorType: PasskeyState = 'error_network';
      let errorMessage = t('error.network');

      if (err.name === 'NotAllowedError') {
        errorType = 'error_denied';
        errorMessage = t('error.passkey_denied');
      } else if (err.message?.includes('origin')) {
        errorType = 'error_origin';
        errorMessage = t('error.origin_mismatch');
      }

      const e: PasskeyError = {
        code: err.code || 'UNKNOWN',
        message: errorMessage,
        type: errorType
      };
      setError(e);
      setState(errorType);
      onError?.(e);
    }
  }, [corbadoLoaded, t, supabase, router, onSuccess, onError]);

  return (
    <Button
      onClick={handlePasskeyLogin}
      disabled={state === 'loading' || !corbadoLoaded}
      className={className}
      variant="outline"
    >
      {state === 'loading' && <Loader2 className="animate-spin" />}
      {state === 'success' && <CheckCircle />}
      {state.startsWith('error') && <AlertCircle />}
      {state === 'idle' && <KeyRound />}
      <span>
        {state === 'success' ? t('auth.success') :
         state.startsWith('error') ? t('auth.retry') :
         t('auth.passkey')}
      </span>
    </Button>
  );
}
```

#### **重要な注意事項**

1. **Corbado UIコンポーネントの事前表示が必要な場合**
   - PasskeyButtonは「既に登録済みのPasskeyでログイン」するボタン
   - 初回登録時は別途 `<CorbadoAuth>` コンポーネントでPasskey登録UIを表示する必要がある
   - 設計書では「MyPageでPasskey登録」と記載されているため整合性は取れている

2. **Corbado.sessionToken のライフサイクル**
   - Corbado認証完了後のみ取得可能
   - ページリロード後は再認証が必要（Corbadoセッション管理依存）

3. **代替実装案: CorbadoAuth コンポーネント統合**
   ```typescript
   // PasskeyButtonの代わりに、CorbadoAuthを直接配置
   <CorbadoAuth 
     onLoggedIn={async () => {
       const idToken = Corbado.sessionToken;
       await supabase.auth.signInWithIdToken({ provider: 'corbado', token: idToken });
       router.push('/mypage');
     }}
   />
   ```

---

## 2. Next.js 16 / React 19 構文適合性

### 2.1 適合項目 ✅

#### **MagicLinkForm & PasskeyButton 共通**

- ✅ `'use client'` ディレクティブの配置
- ✅ `useRouter` from `'next/navigation'` (App Router対応)
- ✅ `useState`, `useCallback`, `useEffect` フックの利用
- ✅ `router.push(path)` メソッド
- ✅ TypeScript 5.6 型定義

**検証済みコード例:**
```typescript
'use client';

import { useRouter } from 'next/navigation'; // ✅ 正しいimport
const router = useRouter();
router.push('/mypage'); // ✅ Next.js 16で動作
```

### 2.2 指摘事項 ⚠️

#### **1. createClient() の実装確認が必要**

```typescript
// 両設計書で使用
import { createClient } from '@/lib/supabase/client';
const supabase = createClient();
```

**要確認事項:**
- `/lib/supabase/client.ts` が `'use client'` ディレクティブを持つか
- Browser環境専用のクライアント作成ロジックか
- SSR時の挙動（Client Componentでのみ呼び出されるため問題ないが確認推奨）

**推奨実装例:**
```typescript
// /lib/supabase/client.ts
'use client';

import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

#### **2. 環境変数アクセスの型安全性**

```typescript
process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!
```

**現状:**
- TypeScript `!` 非null アサーション演算子を使用
- 実行時にundefinedの場合はエラー

**推奨:**
```typescript
// /lib/env.ts で環境変数を検証
export const CORBADO_PROJECT_ID = (() => {
  const id = process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID;
  if (!id) throw new Error('CORBADO_PROJECT_ID is not defined');
  return id;
})();

// コンポーネント内
import { CORBADO_PROJECT_ID } from '@/lib/env';
await Corbado.load({ projectId: CORBADO_PROJECT_ID });
```

#### **3. window.location.origin の使用**

```typescript
// MagicLinkForm内
emailRedirectTo: `${window.location.origin}/auth/callback`
```

**問題点:**
- SSR時に `window` は未定義（ただしClient Componentなので問題なし）
- 開発環境と本番環境で自動切り替え

**推奨:** 現状で問題なし。必要に応じて環境変数で明示的に指定も可能。

---

## 3. 2ファイル間整合性

### 3.1 整合している項目 ✅

| 項目 | MagicLinkForm | PasskeyButton | 評価 |
|------|---------------|---------------|------|
| **i18n** | `useI18n()` from `StaticI18nProvider` | 同左 | ✅ |
| **UIフォント** | BIZ UDゴシック想定 | 同左 | ✅ |
| **カラー** | Apple Blue (#2563EB) | 同左 | ✅ |
| **状態管理** | `idle → loading → success/error` | 同左 | ✅ |
| **コールバック** | `onSuccess`, `onError` | 同左 | ✅ |
| **アイコン** | lucide-react | 同左 | ✅ |
| **ボタンコンポーネント** | shadcn/ui `<Button>` | 同左 | ✅ |

### 3.2 不整合・曖昧な点 ⚠️

#### **1. エラーメッセージキーの未定義**

```typescript
// MagicLinkForm で使用
t('error.invalid_email')
t('error.network')
t('auth.email_sent')
t('auth.check_your_email')

// PasskeyButton で使用
t('error.passkey_denied')
t('error.origin_mismatch')
t('error.network')
t('auth.success')
t('auth.retry')
t('auth.passkey')
```

**問題点:**
- `/public/locales/{locale}/common.json` にこれらのキーが定義されているか不明
- 実装時にエラーが発生するリスク

**推奨:** i18n辞書ファイルを事前作成

```json
// /public/locales/ja/common.json
{
  "auth": {
    "email": "メールアドレス",
    "send_magic_link": "ログインリンクを送信",
    "email_sent": "送信完了",
    "check_your_email": "メールをご確認ください",
    "passkey": "パスキーでログイン",
    "success": "認証成功",
    "retry": "再試行"
  },
  "error": {
    "invalid_email": "メールアドレスの形式が正しくありません",
    "network": "通信エラーが発生しました",
    "passkey_denied": "認証がキャンセルされました",
    "origin_mismatch": "ドメインが一致しません",
    "system": "システムエラーが発生しました"
  }
}
```

#### **2. 状態名の不整合**

```typescript
// MagicLinkForm
type MagicLinkState = 'idle' | 'sending' | 'sent' | 'error_invalid' | 'error_network';

// PasskeyButton
type PasskeyState = 'idle' | 'loading' | 'success' | 'error_denied' | 'error_origin' | 'error_network';
```

**不整合点:**
- MagicLinkForm: `sending` (進行中) → `sent` (成功)
- PasskeyButton: `loading` (進行中) → `success` (成功)

**推奨:** 命名を統一

```typescript
// 統一案1: loading/success パターン
type MagicLinkState = 'idle' | 'loading' | 'success' | 'error_invalid' | 'error_network';

// 統一案2: 共通基底型を定義
type AuthBaseState = 'idle' | 'loading' | 'success';
type MagicLinkState = AuthBaseState | 'error_invalid' | 'error_network';
type PasskeyState = AuthBaseState | 'error_denied' | 'error_origin' | 'error_network';
```

#### **3. Props型定義の配置**

**現状:**
- 設計書には型定義が記載されているが、実装ファイルパスが不明
- 各コンポーネントファイル内に定義するのか、共通型ファイルに定義するのか不明確

**推奨:**
```typescript
// /types/auth.ts
export type AuthState = 'idle' | 'loading' | 'success' | 'error';

export interface AuthError {
  code: string;
  message: string;
  type: AuthState;
}

export interface MagicLinkFormProps {
  className?: string;
  onSent?: () => void;
  onError?: (error: AuthError) => void;
}

export interface PasskeyButtonProps {
  className?: string;
  onSuccess?: () => void;
  onError?: (error: AuthError) => void;
}
```

#### **4. UIコンポーネントのimport先不整合**

```typescript
// MagicLinkForm
import { Button, Input } from '@/components/ui';

// PasskeyButton
import { Button } from '@/components/ui/button';
```

**問題点:**
- MagicLinkForm: `/components/ui` からまとめてimport
- PasskeyButton: `/components/ui/button` から個別import

**推奨:** shadcn/ui の標準に従い個別importに統一
```typescript
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
```

---

## 4. セキュリティ・UX考慮

### 4.1 適切な実装 ✅

#### **MagicLinkForm**
- ✅ HTTPS通信前提（Supabase SDK標準）
- ✅ `shouldCreateUser: false` でユーザー列挙攻撃対策
- ✅ `emailRedirectTo` でコールバックURL指定
- ✅ メールアドレスの基本的なバリデーション (`email.includes('@')`)

#### **PasskeyButton**
- ✅ WebAuthn標準仕様準拠（Corbado経由）
- ✅ Origin検証エラーの分類 (`error_origin`)
- ✅ ユーザーキャンセルの分類 (`error_denied`)

#### **共通**
- ✅ アクセシビリティ: `aria-live="polite"`, `role="status"` (設計書に記載)
- ✅ 状態に応じたボタン無効化 (`disabled={state === 'loading'}`)
- ✅ アイコンによる視覚的フィードバック

### 4.2 見落としリスク・追加推奨事項 ⚠️

#### **1. Corbado Origin設定の確認必須**

**PasskeyButtonの error_origin 分岐:**
```typescript
} else if (err.message?.includes('origin')) {
  errorType = 'error_origin';
  errorMessage = t('error.origin_mismatch');
}
```

**要確認事項:**
- Corbado管理画面で `rpId` (Relying Party ID) が正しく設定されているか
- 開発環境: `localhost` (http://localhost:3000)
- 本番環境: `harmonet.app` (https://harmonet.app)
- Corbadoは **Originの完全一致** を要求するため、設定ミスでエラー多発のリスク

**推奨設定:**
```
開発: rpId = "localhost", origin = "http://localhost:3000"
本番: rpId = "harmonet.app", origin = "https://harmonet.app"
```

#### **2. Supabaseセッション永続化の確認**

```typescript
// PasskeyButton
const { error } = await supabase.auth.signInWithIdToken({
  provider: 'corbado',
  token: idToken,
});
```

**要確認事項:**
- Supabase `signInWithIdToken` 成功後、セッションがCookieに保存されるか
- Cookie設定: `httpOnly`, `secure`, `sameSite` の値
- RLS Policyが適用されるタイミング（セッション確立直後か、次のリクエストからか）

**推奨:** セッション確立後のテスト
```typescript
// セッション取得の確認
const { data: { session } } = await supabase.auth.getSession();
console.log('Session:', session);
```

#### **3. レート制限の実装**

**現状:** 設計書にレート制限の記載なし

**リスク:**
- Magic Link の連続送信による悪用
- Passkeyの連続試行によるアカウントロックアウト

**推奨実装例:**
```typescript
// MagicLinkForm にレート制限追加
const [lastSentTime, setLastSentTime] = useState<number>(0);
const COOLDOWN_MS = 60000; // 60秒

const handleSendMagicLink = useCallback(async () => {
  const now = Date.now();
  if (now - lastSentTime < COOLDOWN_MS) {
    const remainingSeconds = Math.ceil((COOLDOWN_MS - (now - lastSentTime)) / 1000);
    const e: MagicLinkError = {
      code: 'RATE_LIMIT',
      message: t('error.rate_limit', { seconds: remainingSeconds }),
      type: 'error_network'
    };
    setError(e);
    onError?.(e);
    return;
  }
  
  // ... 既存の送信ロジック
  setLastSentTime(now);
}, [lastSentTime, t, onError]);
```

#### **4. エラーメッセージの情報漏洩対策**

**現状:**
```typescript
// 詳細なエラーをそのまま表示
const e = { code: err.code, message: t('error.network'), type: 'error_network' };
```

**リスク:**
- ユーザー列挙攻撃（メールアドレスの存在確認）
- システム内部情報の漏洩

**推奨:**
```typescript
// ユーザーには一般的なメッセージ、ログには詳細情報
try {
  // ... 認証処理
} catch (err: any) {
  // Sentry等に詳細ログ送信
  console.error('Auth error:', err);
  
  // ユーザーには一般的なメッセージのみ
  const e: AuthError = {
    code: 'AUTH_ERROR',
    message: t('error.auth_failed'), // 「認証に失敗しました」
    type: 'error_network'
  };
  setError(e);
  onError?.(e);
}
```

#### **5. XSS対策の確認**

**MagicLinkFormの入力値:**
```typescript
const [email, setEmail] = useState('');
```

**確認事項:**
- React標準のエスケープ処理で保護される（問題なし）
- ただし、`emailRedirectTo` に外部入力を含めないこと

**現状:** `window.location.origin` を使用しているため問題なし

#### **6. CSRF対策**

**Supabase認証の仕組み:**
- Supabase SDKは内部でCSRFトークンを管理
- Cookie設定で `sameSite` が適切に設定されている前提

**推奨確認事項:**
```typescript
// Supabaseクライアント作成時のオプション確認
createBrowserClient(url, key, {
  auth: {
    persistSession: true,
    storageKey: 'supabase.auth.token',
    storage: window.localStorage, // または window.sessionStorage
  },
  cookies: {
    // sameSite: 'lax' または 'strict' が設定されているか確認
  }
});
```

---

## 総合評価

| 評価項目 | MagicLinkForm v1.1 | PasskeyButton v1.2 | 備考 |
|---------|-------------------|-------------------|------|
| **API実在性** | ✅ 適合 | ❌ **Corbado API不整合** | PasskeyButtonは要修正 |
| **Next.js 16構文** | ✅ 適合 | ✅ 適合 | 両方とも問題なし |
| **型定義の明確性** | ✅ 明確 | ✅ 明確 | 配置場所の明示を推奨 |
| **i18n整合性** | ⚠️ 辞書確認要 | ⚠️ 辞書確認要 | common.json作成必須 |
| **状態管理整合性** | ⚠️ 命名統一推奨 | ⚠️ 命名統一推奨 | loading/success に統一 |
| **セキュリティ** | ✅ 基本的に適切 | ⚠️ Origin設定要確認 | レート制限追加推奨 |
| **実装可能性** | ✅ 高 | ❌ **要修正** | Corbado API修正後は可能 |

### 総合コメント

**MagicLinkForm v1.1:**
- Supabase API の使用方法は正確
- 軽微な改善点（変数名統一、レート制限追加）はあるが、基本的に実装可能
- **評価: 🟢 実装可能（軽微な修正推奨）**

**PasskeyButton v1.2:**
- **Corbado API の記述が実際のSDKと完全に不整合**
- `new Corbado()` および `loginWithPasskey()` は存在しないAPI
- UIコンポーネント駆動型の実装に全面改訂が必要
- **評価: 🔴 実装不可（v1.3への改訂必須）**

---

## 修正推奨事項

### 🔴 Critical (即時対応必須)

#### **1. PasskeyButton v1.2 → v1.3 改訂**

**必要な修正:**
- Corbado API を `@corbado/web-js` の実際の仕様に準拠
- `new Corbado()` を削除し、`Corbado.load()` による初期化に変更
- `loginWithPasskey()` を削除し、以下のいずれかに変更:
  - **案A:** UIコンポーネント (`<CorbadoAuth>`) を直接配置
  - **案B:** `Corbado.sessionToken` を使用したカスタムボタン実装
  - **案C:** `Corbado.mountAuthUI()` で動的にUI生成

**推奨実装案（案B）:**
```typescript
// PasskeyButton v1.3 コンセプト
'use client';

import { useEffect, useState } from 'react';
import Corbado from '@corbado/web-js';

export function PasskeyButton({ onSuccess, onError }: PasskeyButtonProps) {
  const [corbadoReady, setCorbadoReady] = useState(false);
  
  useEffect(() => {
    Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! })
      .then(() => setCorbadoReady(true));
  }, []);

  const handleLogin = async () => {
    if (!Corbado.isAuthenticated) {
      // Corbado UI Component を別途表示するか、
      // エラーメッセージを表示
      return;
    }
    
    const idToken = Corbado.sessionToken;
    // Supabase連携...
  };

  return <button onClick={handleLogin} disabled={!corbadoReady}>...</button>;
}
```

#### **2. Corbado連携フロー図の追加**

設計書に以下のフロー図を追加:

```
[PasskeyButton クリック]
         ↓
[Corbado初期化状態確認]
    ↓ (未初期化)
  [エラー表示]
    ↓ (初期化済み)
[Corbado.isAuthenticated?]
    ↓ (false)
  [Corbado UIへ誘導]
    ↓ (true)
[Corbado.sessionToken 取得]
         ↓
[Supabase signInWithIdToken()]
         ↓
[セッション確立]
         ↓
[/mypage へ遷移]
```

---

### 🟡 High (Phase9完了前に対応)

#### **3. i18n辞書キー定義ファイル作成**

**作成ファイル:**
- `/public/locales/ja/common.json`
- `/public/locales/en/common.json`
- `/public/locales/zh/common.json`

**必須キー:**
```json
{
  "auth": {
    "email": "...",
    "send_magic_link": "...",
    "email_sent": "...",
    "check_your_email": "...",
    "passkey": "...",
    "success": "...",
    "retry": "..."
  },
  "error": {
    "invalid_email": "...",
    "network": "...",
    "passkey_denied": "...",
    "origin_mismatch": "...",
    "system": "...",
    "rate_limit": "..."
  }
}
```

#### **4. 共通型定義ファイル作成**

**作成ファイル:** `/types/auth.ts`

```typescript
export type AuthState = 'idle' | 'loading' | 'success' | 'error';

export interface AuthError {
  code: string;
  message: string;
  type: AuthState;
}

export interface MagicLinkFormProps {
  className?: string;
  onSent?: () => void;
  onError?: (error: AuthError) => void;
}

export interface PasskeyButtonProps {
  className?: string;
  onSuccess?: () => void;
  onError?: (error: AuthError) => void;
}

export type MagicLinkState = AuthState | 'error_invalid' | 'error_network';
export type PasskeyState = AuthState | 'error_denied' | 'error_origin' | 'error_network';
```

#### **5. createClient() の実装確認**

**確認事項:**
- `/lib/supabase/client.ts` が存在するか
- `'use client'` ディレクティブがあるか
- `createBrowserClient` を使用しているか

**推奨実装:**
```typescript
// /lib/supabase/client.ts
'use client';

import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

---

### 🟢 Medium (実装中に対応)

#### **6. エラーハンドリングの統一**

**統一方針:**
- 変数名: `error` に統一（`authError`, `err` は使わない）
- エラー型: `AuthError` インターフェースに統一
- ログ出力: `console.error()` で詳細ログ、ユーザーには一般メッセージ

**実装例:**
```typescript
try {
  const { error } = await supabase.auth.signInWithOtp({...});
  if (error) throw error;
} catch (error: any) {
  console.error('Auth error:', error);
  const authError: AuthError = {
    code: error.code || 'UNKNOWN',
    message: t('error.network'),
    type: 'error_network'
  };
  setError(authError);
  onError?.(authError);
}
```

#### **7. レート制限の実装**

**MagicLinkForm に追加:**
```typescript
const [lastSentTime, setLastSentTime] = useState<number>(0);
const COOLDOWN_MS = 60000; // 60秒

// handleSendMagicLink 内でチェック
const now = Date.now();
if (now - lastSentTime < COOLDOWN_MS) {
  // エラー処理
  return;
}
```

**代替案:** Supabase Edge Function でサーバーサイドレート制限

#### **8. テストケース追加**

**必要なテスト:**
1. **MagicLinkForm**
   - 正常系: メールアドレス入力 → 送信成功
   - 異常系: 無効なメールアドレス → エラー表示
   - 異常系: Supabase APIエラー → ネットワークエラー表示
   - レート制限: 連続送信 → クールダウンメッセージ

2. **PasskeyButton**
   - 正常系: Corbado認証済み → Supabase連携 → 遷移
   - 異常系: Corbado未認証 → エラー表示
   - 異常系: Origin不一致 → origin_mismatch エラー
   - 異常系: ユーザーキャンセル → passkey_denied エラー

**モック実装例:**
```typescript
// Corbado SDKモック
jest.mock('@corbado/web-js', () => ({
  load: jest.fn().mockResolvedValue(undefined),
  isAuthenticated: true,
  sessionToken: 'mock-id-token',
}));

// Supabaseモック
jest.mock('@/lib/supabase/client', () => ({
  createClient: () => ({
    auth: {
      signInWithIdToken: jest.fn().mockResolvedValue({ error: null }),
    },
  }),
}));
```

---

## 次のアクション

### **即時対応（本日中）**

1. **PasskeyButton v1.2 → v1.3 改訂**
   - Corbado公式ドキュメント再確認: https://docs.corbado.com/
   - Corbado npm package 確認: https://www.npmjs.com/package/@corbado/web-js
   - 実装パターンを3案（A/B/C）から選択し、TKDに承認依頼

2. **Corbado管理画面の設定確認**
   - rpId と Origin の設定値確認
   - 開発環境用と本番環境用の設定分離

### **Phase9完了前（1週間以内）**

3. **i18n辞書ファイル作成**
   - `/public/locales/ja/common.json` 作成
   - 他言語版（en/zh）も作成

4. **共通型定義ファイル作成**
   - `/types/auth.ts` 作成
   - 両コンポーネントで import

5. **createClient() 実装確認**
   - `/lib/supabase/client.ts` の存在確認
   - 実装内容のレビュー

### **実装フェーズ（2週間以内）**

6. **コンポーネント実装**
   - MagicLinkForm v1.1 実装（軽微な修正を反映）
   - PasskeyButton v1.3 実装（全面改訂版）

7. **統合テスト**
   - Corbado ↔ Supabase 連携動作確認
   - エラーハンドリング確認
   - レート制限動作確認

8. **セキュリティテスト**
   - Origin検証テスト
   - CSRF対策確認
   - セッション永続化確認

---

## 参考資料

### **公式ドキュメント**

1. **Supabase JS SDK v2.43**
   - signInWithOtp: https://supabase.com/docs/reference/javascript/auth-signinwithotp
   - signInWithIdToken: https://supabase.com/docs/reference/javascript/auth-signinwithidtoken

2. **Corbado WebAuthn SDK**
   - npm package: https://www.npmjs.com/package/@corbado/web-js
   - GitHub: https://github.com/corbado/javascript
   - 公式ドキュメント: https://docs.corbado.com/

3. **Next.js 16**
   - useRouter (App Router): https://nextjs.org/docs/app/api-reference/functions/use-router
   - usePathname: https://nextjs.org/docs/app/api-reference/functions/use-pathname

### **技術スタック参照**

- HarmoNet技術スタック定義書 v3.9
- HarmoNet命名規則マトリクス v2.0
- 共通デザインシステム v1.1
- 共通i18n仕様 v1.0

---

## 改訂履歴

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v1.0 | 2025-11-10 | Claude | 初版作成。MagicLinkForm v1.1 / PasskeyButton v1.2 レビュー実施。Corbado API不整合を検出。 |

---

**Document Status:** ✅ Complete  
**Review Status:** 🔴 **PasskeyButton v1.3 改訂必須**  
**Approved by:** (Pending - TKD Review Required)

---

*このレビュー結果に基づき、PasskeyButton設計書の改訂を最優先で実施してください。MagicLinkFormは軽微な修正のみで実装可能です。*
