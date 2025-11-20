# MagicLink Backend 詳細設計書（統合版） v1.1

この文書は、MagicLinkのバックエンドの実装方式について記載する。

---

## 第1章 概要

MagicLink Backend は、HarmoNet のログイン方式「MagicLink（Supabase OTP）」を成立させるための
 **バックエンド技術仕様** を定義する。Next.js App Router + Supabase Auth（PKCE）を前提に、メール送信、
 セッション確立、認可 (/home) までの一連のバックエンド動作と責務境界を明確にする。

---

## 第2章 機能設計

### 2.1 役割

* MagicLink 発行（signInWithOtp）に必要な技術仕様
* セッション確立の条件（PKCE / detectSessionInUrl）
* /auth/callback の取り扱い（server ではなく client）
* /home での認可チェック（users / user_tenants）

### 2.2 入出力

| 入力    | 内容                    |
| ----- | --------------------- |
| email | MagicLink 送信対象メールアドレス |

| 出力    | 内容                              |
| ----- | ------------------------------- |
| error | Supabase エラーを UI にそのまま返却（UIで分類） |

### 2.3 認証フロー（高レベル）

```
/login → MagicLinkForm → signInWithOtp
↓
ユーザがメール内リンクを押す
↓
/auth/callback → (PKCE) → セッション確立
↓
/home → 認可チェック（users / user_tenants）
```

---

## 第3章 構造設計

### 3.1 バックエンドの責務

* MagicLinkForm による signInWithOtp 呼び出しの技術仕様
* Supabase Auth がセッション Cookie を確立する流れ
* /home で認可判定（Server Component）

### 3.2 コンポーネント境界

| 層                        | 責務                         |
| ------------------------ | -------------------------- |
| A-01 MagicLinkForm       | signInWithOtp 呼び出し（クライアント） |
| A-03 AuthCallbackHandler | PKCE セッション確立検知（クライアント）     |
| /home（Server Component）  | 認可（users / user_tenants）   |

---

## 第4章 実装設計

### 4.1 MagicLink 送信ロジック

```ts
import { createBrowserClient } from '@supabase/ssr';

export async function sendMagicLink(email: string) {
  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  return await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: false,
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  });
}
```

* Backend は変換・加工を行わない。Supabase エラーをそのまま UI に返す。

### 4.2 /auth/callback（クライアント）

* PKCE 採用により、セッション確立は **クライアント側のみ成立**。
* サーバ側でセッション確立する構造は不可（URLフラグメントが読めないため）。
* `supabase.auth.onAuthStateChange` と `auth.getSession()` の併用でログイン確定。

### 4.3 /home（Server Component）での認可

1. `auth.getUser()` で認証チェック
2. `public.users` でメール一致ユーザー取得
3. `public.user_tenants` で active membership を取得
4. 不一致時は `/login?error=unauthorized` へリダイレクト

---

## 第5章 エラー仕様

### 5.1 Supabase エラー分類（UI側で処理）

| 状態               | 代表例           |
| ---------------- | ------------- |
| error_input      | 入力形式不正        |
| error_network    | fetch例外・通信断   |
| error_auth       | Supabase認証エラー |
| error_unexpected | その他例外         |

Backend は分類せず、**生の error を返却**する。

### 5.2 MagicLinkBackend が返すエラー構造

```ts
{ data: null, error: SupabaseAuthError | null }
```

---

## 第6章 セキュリティ

* NEXT_PUBLIC_SUPABASE_URL / ANON_KEY のみ参照
* Service Role Key は API Route で使用しない（MVPではフロント直呼び）
* セッション Cookie は Supabase Auth が管理（HttpOnly / Secure）
* 認可は `/home` の RLS / DB クエリで実施

---

## 第7章 環境変数

```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
```

※ emailRedirectTo はコード内で `/auth/callback` に固定。

---

## 第8章 結合・運用

### 8.1 結合関係

* A-01（MagicLinkForm） → signInWithOtp
* A-03（AuthCallbackHandler） → PKCE セッション確立
* /home → 認可

### 8.2 運用

* MagicLink 発行は Supabase 側のメール送信に依存
* Mailpit（開発）／SMTP（本番）

---

## 第9章 テスト仕様（Backend 観点）

* signInWithOtp が正しいパラメータで呼ばれる
* emailRedirectTo が `/auth/callback` である
* shouldCreateUser = false
* Supabase error がそのまま UI に渡る

---

**End of Document**
