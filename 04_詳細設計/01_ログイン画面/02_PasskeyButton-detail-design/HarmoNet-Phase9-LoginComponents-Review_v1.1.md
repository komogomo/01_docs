# HarmoNet Phase9 ログインコンポーネント設計書レビュー v1.1

**Document ID:** HARMONET-REVIEW-LOGIN-COMPONENTS-V1.1  
**Review Date:** 2025年11月10日  
**Reviewer:** Claude (AI Technical Reviewer)  
**Target Documents:**
- `MagicLinkForm-detail-design_v1.1.md`
- `PasskeyButton-detail-design_v1.3.md` ← **最新版**

**Technology Stack:**
- Next.js 16.0.1 (App Router)
- React 19.0.0
- Supabase JS SDK v2.43.0
- **Corbado SDK: @corbado/react v2.x + @corbado/node v2.x** ← **v1.3で変更**
- TypeScript 5.6

---

## 📋 目次

1. [レビュー変更点（v1.0 → v1.1）](#レビュー変更点v10--v11)
2. [Supabase JS SDK v2.43 API整合性](#1-supabase-js-sdk-v243-api整合性)
3. [Corbado公式構成の適合性](#2-corbado公式構成の適合性)
4. [Next.js 16 / React 19 構文適合性](#3-nextjs-16--react-19-構文適合性)
5. [2ファイル間整合性](#4-2ファイル間整合性)
6. [セキュリティ・UX考慮](#5-セキュリティux考慮)
7. [総合評価](#総合評価)
8. [修正推奨事項](#修正推奨事項)
9. [次のアクション](#次のアクション)

---

## レビュー変更点（v1.0 → v1.1）

### **v1.0レビュー時の主な問題点**
- PasskeyButton v1.2 が `@corbado/web-js` を使用
- `new Corbado()` および `loginWithPasskey()` が**存在しないAPI**として指摘
- 実装不可と判定

### **v1.3での改善内容**
- ✅ **Corbado公式構成に完全移行**
  - `@corbado/react` (CorbadoProvider + CorbadoAuth)
  - `@corbado/node` (サーバーサイドセッション処理)
- ✅ `@corbado/web-js` を完全廃止
- ✅ UIコンポーネント駆動型の実装

### **本レビュー（v1.1）の結論**
🎉 **PasskeyButton v1.3は実装可能** - Corbado公式パターンに準拠し、技術的に成立する設計になりました。

---

## 1. Supabase JS SDK v2.43 API整合性

### 1.1 MagicLinkForm (A-01) - ✅ 適合

**前回レビュー（v1.0）からの変更なし。以下は再確認結果。**

#### ✓ **適合項目**

```typescript
const { error } = await supabase.auth.signInWithOtp({
  email,
  options: { 
    shouldCreateUser: false, 
    emailRedirectTo: `${window.location.origin}/auth/callback` 
  },
});
```

- ✅ `signInWithOtp()` は実在するAPI（Supabase v2.43で確認済み）
- ✅ パラメータ構造は正規
- ✅ 戻り値構造も正規

#### ⚠️ **軽微な指摘事項（v1.0と同じ）**

1. **エラー変数名の不整合**
   - 設計書内で `authError` → `error` への統一を推奨
   - catch ブロックでは `err` を使用しているため、一貫性のため `error` に統一

2. **shouldCreateUser: false の挙動確認**
   - 未登録ユーザーはエラーになる
   - Phase9でのユーザー登録フロー（管理者登録 or 自己登録）の明確化が必要

---

## 2. Corbado公式構成の適合性

### 2.1 PasskeyButton (A-02) v1.3 - ✅ **適合**

#### **v1.3の実装構成**

```typescript
// 1. Provider設定（app/layout.tsx）
'use client';
import { CorbadoProvider } from '@corbado/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <CorbadoProvider projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}>
          {children}
        </CorbadoProvider>
      </body>
    </html>
  );
}

// 2. 認証UI（app/auth/page.tsx）
'use client';
import { CorbadoAuth } from '@corbado/react';

export default function Auth() {
  const router = useRouter();
  
  return (
    <CorbadoAuth 
      onLoggedIn={() => router.push('/api/session')} 
    />
  );
}

// 3. サーバーセッション（app/api/session/route.ts）
import { sdk as corbado } from '@/lib/corbado';

export async function GET(req: Request) {
  const shortSession = req.cookies.get('cbo_short_session')?.value;
  const user = await corbado.sessions().validateToken(shortSession);
  
  // Supabase連携
  const { error } = await supabase.auth.signInWithIdToken({
    provider: 'corbado',
    token: shortSession,
  });
  
  return NextResponse.json({ user });
}
```

#### ✅ **Corbado公式パターンとの整合性**

| 項目 | v1.3設計書 | Corbado公式 | 判定 |
|------|-----------|------------|------|
| **Provider設定** | `<CorbadoProvider>` | ✅ 同じ | ✅ 適合 |
| **認証UI** | `<CorbadoAuth>` | ✅ 同じ | ✅ 適合 |
| **サーバーSDK** | `@corbado/node` | ✅ 同じ | ✅ 適合 |
| **セッションCookie** | `cbo_short_session` | ✅ 同じ | ✅ 適合 |
| **セッション検証** | `sdk.sessions().validateToken()` | ✅ 同じ | ✅ 適合 |

**検証元:**
- Corbado公式ブログ: "How to Implement Passkeys in Next.js Apps"
- GitHub: corbado/example-passkeys-nextjs
- npm: @corbado/react, @corbado/node

#### ✅ **技術的成立性**

1. **CorbadoProvider の役割**
   - WebAuthn認証フローを管理
   - `projectId` でCorbadoプロジェクトと接続
   - Client Component として動作

2. **CorbadoAuth の動作**
   - ユーザーにWebAuthn認証UIを提示
   - 成功時に `cbo_short_session` Cookieを発行
   - `onLoggedIn` コールバックで後処理を実行

3. **サーバーサイド連携**
   - `/api/session` でCorbado JWTを検証
   - Supabase `signInWithIdToken` でSupabaseセッション確立
   - RLS有効化

#### ⚠️ **実装上の注意点**

**1. layout.tsx での Provider 配置**

```typescript
// ❌ 良くない例: layout.tsx全体をClient Component化
'use client';
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <CorbadoProvider projectId={...}>
          {children}
        </CorbadoProvider>
      </body>
    </html>
  );
}

// ✅ 推奨: 別ファイルでラップしてServer Componentを維持
// app/providers.tsx
'use client';
export function Providers({ children }) {
  return (
    <CorbadoProvider projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}>
      {children}
    </CorbadoProvider>
  );
}

// app/layout.tsx (Server Component)
import { Providers } from './providers';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

**2. Supabase連携のタイミング**

```typescript
// 現在の設計: /api/session で連携
export async function GET(req: Request) {
  const shortSession = req.cookies.get('cbo_short_session')?.value;
  const user = await corbado.sessions().validateToken(shortSession);
  
  // Supabase連携
  const { error } = await supabase.auth.signInWithIdToken({
    provider: 'corbado',
    token: shortSession,
  });
  
  if (error) throw error;
  
  return NextResponse.json({ user });
}
```

**問題:** Supabase `signInWithIdToken` が `corbado` プロバイダーをサポートしているか不明

**推奨確認事項:**
- Supabase管理画面で `corbado` をカスタムOAuthプロバイダーとして登録が必要
- または、Corbado JWTを検証後、Supabaseの管理APIで直接セッション作成

**代替実装案:**
```typescript
// Corbado JWT検証後、Supabaseアクセストークンを発行
const user = await corbado.sessions().validateToken(shortSession);

// Supabase Admin APIでセッション作成
const { data, error } = await supabaseAdmin.auth.admin.createUser({
  email: user.email,
  user_metadata: { corbado_user_id: user.id }
});
```

**3. エラーハンドリング**

```typescript
// 設計書の記載が簡潔すぎる
const user = await corbado.sessions().validateToken(shortSession);
// ↓ 追加すべきエラー処理
if (!user) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}
```

---

## 3. Next.js 16 / React 19 構文適合性

### 3.1 MagicLinkForm - ✅ 適合

- ✅ `'use client'` ディレクティブ
- ✅ `useRouter` from `'next/navigation'`
- ✅ React 19 hooks 使用

### 3.2 PasskeyButton v1.3 - ✅ 適合

#### **適合項目**

```typescript
// ✅ Client Component
'use client';

// ✅ Next.js 16 App Router hooks
import { useRouter } from 'next/navigation';

// ✅ React 19 標準hooks
import { useState, useEffect, useCallback } from 'react';

// ✅ Server Action / Route Handler
// app/api/session/route.ts
export async function GET(req: Request) { ... }
```

#### **Next.js 16 固有の注意点**

**1. Async params / searchParams（Next.js 16の破壊的変更）**

```typescript
// ❌ Next.js 15以前
export default function Page({ params, searchParams }) {
  const { id } = params; // 同期アクセス
}

// ✅ Next.js 16以降
export default async function Page({ params, searchParams }) {
  const { id } = await params; // await が必須
}
```

PasskeyButton v1.3ではparamsを使用していないため、この問題は影響なし。

**2. middleware.ts → proxy.ts 変更**

Next.js 16では `middleware.ts` が `proxy.ts` に変更されましたが、HarmoNetでMiddlewareを使用していない場合は影響なし。

#### ⚠️ **指摘事項**

**1. Server Component と Client Component の混在**

設計書では layout.tsx に `'use client'` を追加していますが、これは推奨されません。

```typescript
// ❌ 設計書の記載
// app/layout.tsx
'use client';
export default function RootLayout({ children }) { ... }

// ✅ 推奨パターン
// app/providers.tsx
'use client';
export function Providers({ children }) {
  return <CorbadoProvider>{children}</CorbadoProvider>;
}

// app/layout.tsx (Server Component維持)
import { Providers } from './providers';
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

**理由:**
- layout.tsx をClient Componentにすると、すべての子ページもClient Componentになる
- Server Componentsの利点（データフェッチの効率化、バンドルサイズ削減）が失われる

---

## 4. 2ファイル間整合性

### 4.1 整合している項目 ✅

| 項目 | MagicLinkForm v1.1 | PasskeyButton v1.3 | 評価 |
|------|-------------------|-------------------|------|
| **i18n** | `useI18n()` from `StaticI18nProvider` | 同左 | ✅ |
| **UIトーン** | BIZ UDゴシック、控えめ | 同左 | ✅ |
| **認証フロー** | Supabase Auth | Corbado → Supabase | ✅ 補完関係 |
| **コールバック** | `onSent`, `onError` | `onLoggedIn` | ✅ |
| **状態管理** | useState hooks | 同左 | ✅ |

### 4.2 不整合・曖昧な点 ⚠️

#### **1. i18n辞書キーの未定義（v1.0と同じ）**

```typescript
// MagicLinkForm
t('error.invalid_email')
t('error.network')
t('auth.email_sent')

// PasskeyButton v1.3（設計書には記載なし）
// Corbado Auth UIは自動で多言語対応するが、
// エラーメッセージなどカスタム部分は要定義
```

**推奨:** `/public/locales/ja/common.json` を事前作成

```json
{
  "auth": {
    "email": "メールアドレス",
    "send_magic_link": "ログインリンクを送信",
    "email_sent": "送信完了",
    "check_your_email": "メールをご確認ください",
    "passkey": "パスキーでログイン",
    "success": "認証成功"
  },
  "error": {
    "invalid_email": "メールアドレスの形式が正しくありません",
    "network": "通信エラーが発生しました",
    "unauthorized": "認証が必要です"
  }
}
```

#### **2. エラーハンドリングの統一**

```typescript
// MagicLinkForm: 詳細なエラー型定義あり
export interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkState;
}

// PasskeyButton v1.3: エラー型定義が不明確
// 設計書に記載なし
```

**推奨:** 共通エラー型の定義

```typescript
// /types/auth.ts
export interface AuthError {
  code: string;
  message: string;
  type: string;
}

export interface MagicLinkError extends AuthError {
  type: 'error_invalid' | 'error_network';
}

export interface PasskeyError extends AuthError {
  type: 'error_unauthorized' | 'error_network';
}
```

#### **3. 認証完了後の遷移先**

```typescript
// MagicLinkForm: メール送信後は画面そのまま
onSent?.();

// PasskeyButton v1.3: 認証成功後
onLoggedIn={() => router.push('/api/session')}
// その後 /mypage へ遷移（設計書記載）
```

**統一性:** MagicLinkもメールリンククリック後は `/mypage` へ遷移するため、整合性あり。

---

## 5. セキュリティ・UX考慮

### 5.1 適切な実装 ✅

#### **MagicLinkForm**
- ✅ HTTPS通信（Supabase標準）
- ✅ `shouldCreateUser: false` でユーザー列挙攻撃対策
- ✅ `emailRedirectTo` でコールバックURL指定

#### **PasskeyButton v1.3**
- ✅ WebAuthn標準準拠（Corbado経由）
- ✅ Origin/RP ID検証（Corbado側で実施）
- ✅ JWT短期有効期限（<1h）
- ✅ サーバーサイドセッション検証

### 5.2 追加推奨事項 ⚠️

#### **1. Corbado Origin設定の確認**

**設定必須項目:**
- Corbado管理画面で `rpId` と `origin` を登録
- 開発環境: `rpId = "localhost"`, `origin = "http://localhost:3000"`
- 本番環境: `rpId = "harmonet.app"`, `origin = "https://harmonet.app"`

**確認方法:**
```bash
# Corbado管理画面で設定を確認
# https://app.corbado.com/app/settings/general/rp-id
```

#### **2. Supabase「corbado」プロバイダー登録**

**確認事項:**
```typescript
// Supabaseが「corbado」をOAuthプロバイダーとして認識するか？
const { error } = await supabase.auth.signInWithIdToken({
  provider: 'corbado', // ← これが有効か確認
  token: shortSession,
});
```

**推奨:** Supabase管理画面でカスタムOAuthプロバイダーを設定

```sql
-- Supabase RLSポリシーでCorbado認証を許可
CREATE POLICY "Allow Corbado authenticated users"
ON public.users
FOR ALL
TO authenticated
USING (auth.jwt() ->> 'provider' = 'corbado');
```

#### **3. レート制限（v1.0から継続）**

**MagicLinkForm にレート制限追加を推奨:**

```typescript
const [lastSentTime, setLastSentTime] = useState<number>(0);
const COOLDOWN_MS = 60000; // 60秒

const handleSendMagicLink = useCallback(async () => {
  const now = Date.now();
  if (now - lastSentTime < COOLDOWN_MS) {
    const remainingSeconds = Math.ceil((COOLDOWN_MS - (now - lastSentTime)) / 1000);
    setError({
      code: 'RATE_LIMIT',
      message: t('error.rate_limit', { seconds: remainingSeconds }),
      type: 'error_network'
    });
    return;
  }
  
  // ... 既存ロジック
  setLastSentTime(now);
}, [lastSentTime]);
```

#### **4. CORS設定**

**PasskeyButton で `/api/session` を呼び出す際:**

```typescript
// app/api/session/route.ts
export async function GET(req: Request) {
  // CORS設定（必要に応じて）
  const response = NextResponse.json({ user });
  response.headers.set('Access-Control-Allow-Origin', process.env.NEXT_PUBLIC_APP_URL!);
  return response;
}
```

#### **5. Cookie設定の確認**

```typescript
// CorbadoProvider の設定
<CorbadoProvider
  projectId={...}
  setShortSessionCookie={true} // ✅ 設計書に記載あり
  // 以下を追加推奨
  cookieOptions={{
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
  }}
>
```

---

## 総合評価

| 評価項目 | MagicLinkForm v1.1 | PasskeyButton v1.3 | 備考 |
|---------|-------------------|-------------------|------|
| **API実在性** | ✅ 適合 | ✅ **適合** | v1.3でCorbado公式構成に準拠 |
| **Next.js 16構文** | ✅ 適合 | ⚠️ layout.tsx改善推奨 | Providers分離推奨 |
| **型定義の明確性** | ✅ 明確 | ⚠️ エラー型追加推奨 | 共通型定義作成 |
| **i18n整合性** | ⚠️ 辞書確認要 | ⚠️ 辞書確認要 | common.json作成必須 |
| **セキュリティ** | ✅ 基本的に適切 | ✅ 適切 | Supabase連携確認要 |
| **実装可能性** | ✅ 高 | ✅ **高** | v1.3で実装可能に改善 |

### 総合コメント

**🎉 PasskeyButton v1.3は実装可能になりました！**

**改善点:**
- ✅ Corbado公式パターン（@corbado/react + @corbado/node）に準拠
- ✅ UIコンポーネント駆動型の実装で技術的に成立
- ✅ サーバーサイドセッション検証を実装

**残存課題:**
- ⚠️ layout.tsx の Client Component化（Providers分離推奨）
- ⚠️ Supabase「corbado」プロバイダー登録の確認
- ⚠️ i18n辞書ファイルの作成
- ⚠️ エラーハンドリングの型定義追加

**MagicLinkForm v1.1:**
- 前回レビューから変更なし
- 軽微な改善点はあるが、基本的に実装可能
- **評価: 🟢 実装可能（軽微な修正推奨）**

**PasskeyButton v1.3:**
- Corbado公式構成への移行により大幅改善
- layout.tsx の構造改善とSupabase連携確認が必要
- **評価: 🟢 実装可能（中程度の修正推奨）**

---

## 修正推奨事項

### 🟡 High (Phase9完了前に対応)

#### **1. layout.tsx の Providers 分離**

**現状（設計書）:**
```typescript
// app/layout.tsx
'use client'; // ← これを削除
export default function RootLayout({ children }) { ... }
```

**推奨:**
```typescript
// app/providers.tsx
'use client';
import { CorbadoProvider } from '@corbado/react';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <CorbadoProvider
      projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}
      setShortSessionCookie={true}
    >
      {children}
    </CorbadoProvider>
  );
}

// app/layout.tsx (Server Componentとして維持)
import { Providers } from './providers';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

#### **2. Supabase「corbado」プロバイダー設定確認**

**確認項目:**
1. Supabase管理画面で `corbado` をカスタムOAuthプロバイダーとして登録
2. または、代替実装を採用（Supabase Admin APIで直接ユーザー作成）

**代替実装例:**
```typescript
// app/api/session/route.ts
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // サービスロールキー
);

export async function GET(req: Request) {
  const shortSession = req.cookies.get('cbo_short_session')?.value;
  if (!shortSession) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Corbado JWT検証
  const corbadoUser = await corbado.sessions().validateToken(shortSession);
  if (!corbadoUser) {
    return NextResponse.json({ error: 'Invalid session' }, { status: 401 });
  }

  // Supabase Admin APIでユーザー取得または作成
  const { data: existingUser } = await supabaseAdmin.auth.admin.getUserById(corbadoUser.id);
  
  if (!existingUser) {
    // 初回ログイン: ユーザー作成
    await supabaseAdmin.auth.admin.createUser({
      id: corbadoUser.id,
      email: corbadoUser.email,
      user_metadata: { corbado_user_id: corbadoUser.id },
    });
  }

  // アクセストークン発行
  const { data, error } = await supabaseAdmin.auth.admin.generateLink({
    type: 'magiclink',
    email: corbadoUser.email,
  });

  if (error) throw error;

  return NextResponse.json({ user: corbadoUser, access_token: data.properties.action_link });
}
```

#### **3. i18n辞書ファイル作成**

**作成ファイル:**
- `/public/locales/ja/common.json`
- `/public/locales/en/common.json`
- `/public/locales/zh/common.json`

**必須キー（再掲）:**
```json
{
  "auth": {
    "email": "メールアドレス",
    "send_magic_link": "ログインリンクを送信",
    "email_sent": "送信完了",
    "check_your_email": "メールをご確認ください",
    "passkey": "パスキーでログイン",
    "success": "認証成功"
  },
  "error": {
    "invalid_email": "メールアドレスの形式が正しくありません",
    "network": "通信エラーが発生しました",
    "unauthorized": "認証が必要です",
    "rate_limit": "再送信は{{seconds}}秒後に可能です"
  }
}
```

#### **4. 共通型定義ファイル作成**

**作成ファイル:** `/types/auth.ts`

```typescript
export interface AuthError {
  code: string;
  message: string;
  type: string;
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

export type MagicLinkState = 'idle' | 'loading' | 'success' | 'error_invalid' | 'error_network';
export type PasskeyState = 'idle' | 'loading' | 'success' | 'error_unauthorized' | 'error_network';

export interface MagicLinkError extends AuthError {
  type: MagicLinkState;
}

export interface PasskeyError extends AuthError {
  type: PasskeyState;
}
```

---

### 🟢 Medium (実装中に対応)

#### **5. エラーハンドリングの強化**

**PasskeyButton のエラー処理追加:**

```typescript
// app/api/session/route.ts
export async function GET(req: Request) {
  try {
    const shortSession = req.cookies.get('cbo_short_session')?.value;
    
    if (!shortSession) {
      return NextResponse.json(
        { error: 'No session cookie' },
        { status: 401 }
      );
    }

    const user = await corbado.sessions().validateToken(shortSession);
    
    if (!user) {
      return NextResponse.json(
        { error: 'Invalid session token' },
        { status: 401 }
      );
    }

    // Supabase連携...
    
    return NextResponse.json({ user });
  } catch (error: any) {
    console.error('Session validation error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

#### **6. レート制限の実装（MagicLinkForm）**

**実装例（前述の通り）:**
- localStorage で最終送信時刻を記録
- 60秒のクールダウン期間を設定
- 残り秒数をユーザーに表示

#### **7. Corbado Origin設定の確認**

**確認手順:**
1. Corbado管理画面にログイン
2. Project Settings → General → RP ID / Origin を確認
3. 開発環境と本番環境の設定を分離

**設定例:**
```
開発: rpId = localhost, origin = http://localhost:3000
本番: rpId = harmonet.app, origin = https://harmonet.app
```

#### **8. テストケース追加**

**必要なテスト:**

**MagicLinkForm:**
- ✅ 正常系: メールアドレス入力 → 送信成功
- ✅ 異常系: 無効なメールアドレス → エラー表示
- ✅ 異常系: Supabase APIエラー → ネットワークエラー
- ✅ レート制限: 連続送信 → クールダウンメッセージ

**PasskeyButton v1.3:**
- ✅ 正常系: CorbadoAuth認証 → /api/session → /mypage遷移
- ✅ 異常系: セッションCookie不在 → 401エラー
- ✅ 異常系: Corbado JWT無効 → 401エラー
- ✅ 異常系: Supabase連携失敗 → エラー表示

**モック実装例:**
```typescript
// Corbado Node SDK モック
jest.mock('@corbado/node-sdk', () => ({
  SDK: jest.fn().mockImplementation(() => ({
    sessions: () => ({
      validateToken: jest.fn().mockResolvedValue({
        id: 'user-123',
        email: 'test@example.com',
      }),
    }),
  })),
}));

// Supabase モック
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => ({
    auth: {
      signInWithIdToken: jest.fn().mockResolvedValue({ error: null }),
    },
  })),
}));
```

---

## 次のアクション

### **即時対応（本日中）**

1. ✅ **PasskeyButton v1.3 レビュー完了**
   - Corbado公式構成に準拠していることを確認
   - 実装可能と判定

2. **layout.tsx の Providers 分離**
   - `app/providers.tsx` を作成
   - layout.tsx から `'use client'` を削除

### **Phase9完了前（1週間以内）**

3. **Supabase連携方法の確定**
   - `signInWithIdToken({ provider: 'corbado' })` の動作確認
   - または代替実装（Admin API）を採用

4. **i18n辞書ファイル作成**
   - `/public/locales/ja/common.json` 作成
   - 他言語版（en/zh）も作成

5. **共通型定義ファイル作成**
   - `/types/auth.ts` 作成
   - 両コンポーネントで import

### **実装フェーズ（2週間以内）**

6. **コンポーネント実装**
   - MagicLinkForm v1.1 実装（軽微な修正を反映）
   - PasskeyButton v1.3 実装（Providers分離版）

7. **統合テスト**
   - Corbado ↔ Supabase 連携動作確認
   - エラーハンドリング確認
   - レート制限動作確認

8. **セキュリティテスト**
   - Origin検証テスト
   - セッションCookie検証
   - RLS Policy適用確認

---

## 参考資料

### **公式ドキュメント**

1. **Supabase JS SDK v2.43**
   - signInWithOtp: https://supabase.com/docs/reference/javascript/auth-signinwithotp
   - signInWithIdToken: https://supabase.com/docs/reference/javascript/auth-signinwithidtoken

2. **Corbado SDK**
   - 公式ブログ: https://www.corbado.com/blog/nextjs-passkeys
   - GitHub: https://github.com/corbado/example-passkeys-nextjs
   - npm (@corbado/react): https://www.npmjs.com/package/@corbado/react
   - npm (@corbado/node): https://www.npmjs.com/package/@corbado/node

3. **Next.js 16**
   - 公式ブログ: https://nextjs.org/blog/next-16
   - useRouter (App Router): https://nextjs.org/docs/app/api-reference/functions/use-router
   - Breaking Changes: https://nextjs.org/docs/app/building-your-application/upgrading/version-16

### **技術スタック参照**

- HarmoNet技術スタック定義書 v3.9
- HarmoNet命名規則マトリクス v2.0
- 共通デザインシステム v1.1
- 共通i18n仕様 v1.0

---

## 改訂履歴

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v1.0 | 2025-11-10 | Claude | 初版作成。PasskeyButton v1.2レビュー実施。Corbado API不整合を検出し実装不可と判定。 |
| **v1.1** | **2025-11-10** | **Claude** | **PasskeyButton v1.3レビュー実施。Corbado公式構成（@corbado/react + @corbado/node）に準拠し、実装可能と判定。layout.tsx改善とSupabase連携確認を推奨。** |

---

**Document Status:** ✅ Complete  
**Review Status:** 🟢 **両コンポーネント実装可能**  
- MagicLinkForm v1.1: 軽微な修正推奨
- PasskeyButton v1.3: 中程度の修正推奨（Providers分離、Supabase連携確認）

**Approved by:** (Pending - TKD Review Required)

---

*PasskeyButton v1.3はCorbado公式構成に準拠しており、技術的に実装可能です。layout.txの構造改善とSupabase連携の確認を実施してください。*
