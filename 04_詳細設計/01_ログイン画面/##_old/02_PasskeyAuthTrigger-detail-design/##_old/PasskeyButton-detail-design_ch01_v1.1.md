# HarmoNet 詳細設計書 - PasskeyButton (A-02) v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-DESIGN  
**Version:** 1.1  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Difficulty:** 4（高）  
**Safe Steps:** 5  
**Status:** Phase9 承認仕様準拠（Corbado構成に統合）  

---

## 第1章 概要

### 1.1 目的

本設計書は、HarmoNetログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** コンポーネントの改訂詳細設計を定義する。  
v1.0で使用していた非公式API（`loginWithPasskey()` / `new Corbado()`）は廃止し、  
**Corbado公式構成（@corbado/react + @corbado/node）** に準拠する。

---

### 1.2 適用範囲

| 区分 | 内容 |
|------|------|
| **対象** | Next.js 16 (App Router) + React 19 環境下で動作する認証UI |
| **認証方式** | Corbado Passkey (WebAuthn Level 2) |
| **構成要素** | `@corbado/react`（フロント）＋`@corbado/node`（バックエンド） |
| **対応環境** | HTTPS必須、WebAuthn対応ブラウザ (Safari / Chrome / Edge 最新版) |
| **非対象** | MyPage内のPasskey登録UI、MagicLinkForm、AuthCallbackHandler |

---

## 第2章 構造設計

### 2.1 コンポーネント構成図

```mermaid
graph TD
  A[app/layout.tsx] --> B[CorbadoProvider]
  B --> C[Auth Component (@corbado/react)]
  C --> D[Corbado Cloud]
  D --> E[CorbadoService (@corbado/node)]
  E --> F[Supabase Session Store]

ポイント:
・認証UIはCorbadoが提供する <Auth /> コンポーネントを利用。
・認証成功後、@corbado/node の CorbadoService によりセッション情報を取得。
・SupabaseはRLS・JWTセッションストアとして連携（相互非依存構成）。

2.2 ファイル構成
src/
├─ app/
│   ├─ layout.tsx               # CorbadoProvider適用
│   ├─ page.tsx                 # Auth UIコンポーネント
│   └─ api/
│       └─ session/
│           └─ route.ts         # サーバーセッション取得API
├─ lib/
│   └─ supabase/
│       └─ client.ts            # Supabaseクライアント
└─ components/
    └─ login/
        └─ PasskeyButton/
            ├─ PasskeyButton.tsx
            ├─ PasskeyButton.types.ts
            └─ index.ts

第3章 フロントエンド構成
3.1 Provider設定（app/layout.tsx）
'use client';
import { CorbadoProvider } from '@corbado/react';
import React from 'react';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        <CorbadoProvider projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}>
          {children}
        </CorbadoProvider>
      </body>
    </html>
  );
}

・CorbadoProvider がアプリ全体に認証コンテキストを提供。
・NEXT_PUBLIC_CORBADO_PROJECT_ID はCorbadoダッシュボードで発行された値を設定。

3.2 認証UIコンポーネント（app/page.tsx）
'use client';
import { Auth } from '@corbado/react';

export default function LoginPage() {
  return (
    <main className="flex flex-col items-center justify-center h-screen bg-white">
      <h1 className="text-2xl mb-6 font-bold text-gray-700">HarmoNet Login</h1>
      <Auth />
    </main>
  );
}

・<Auth /> コンポーネントが Corbado のホストUIを呼び出し、
　Passkeyまたはメールリンクによるログイン処理を自動的に管理。
・loginWithPasskey() の直接呼び出しは不要。

第4章 バックエンド構成
4.1 セッション取得API（app/api/session/route.ts）
import { NextResponse } from 'next/server';
import { CorbadoService } from '@corbado/node';

const corbado = new CorbadoService({
  projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!,
  apiSecret: process.env.CORBADO_API_SECRET!,
});

export async function GET() {
  try {
    const session = await corbado.sessions().getCurrent();
    return NextResponse.json(session);
  } catch {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  }
}

・Corbado Node SDKを利用してサーバー側でセッション状態を検証。
・JWTなどのSupabaseセッションと併用可能。

第5章 Supabase連携補足
| 項目         | 内容                                                        |
| ---------- | --------------------------------------------------------- |
| **目的**     | Corbado認証後にSupabase側でRLS制御を行う                             |
| **トークン連携** | CorbadoのセッションJWTを `supabase.auth.signInWithIdToken()` に渡す |
| **備考**     | SupabaseはCorbadoを「外部IdP」として扱う形になる                         |

第6章 UIデザイン仕様（HarmoNet準拠）
| 項目       | 値                 |
| -------- | ----------------- |
| 背景       | #FFFFFF           |
| フォント     | BIZ UDゴシック        |
| フォントサイズ  | 16px              |
| アクセントカラー | #2563EB           |
| ボタン角丸    | rounded-2xl       |
| 影        | shadow-sm         |
| 配置       | 中央揃え              |
| スタイル     | Appleカタログ風・控えめ・自然 |

第7章 セキュリティ・UX考慮事項
・HTTPS環境必須（passkeyはセキュアコンテキストでのみ動作）
・NEXT_PUBLIC_ 変数はクライアント公開可、CORBADO_API_SECRET はサーバー専用。
・成功後はマイページ /mypage に遷移。
・Passkey未登録時は <Auth /> 内で登録誘導を自動表示。
・Supabaseとの二重セッション状態を防ぐため、Corbadoが主導となる。

第8章 テスト観点
| テストID    | 内容                        | 想定結果           |
| -------- | ------------------------- | -------------- |
| T-A02-01 | Passkeyでログイン成功            | マイページへ遷移       |
| T-A02-02 | 未登録ユーザー                   | Corbado登録画面へ誘導 |
| T-A02-03 | API `/api/session` 正常呼び出し | セッションJSONを返却   |
| T-A02-04 | 認証無効状態                    | 401レスポンス       |
| T-A02-05 | HTTPSでない環境                | passkey動作せず警告  |

第9章 参考URL
Corbado 公式 GitHub: passkeys-nextjs
・Qiita: Next.jsとCorbadoを使用したパスキー実装 #TypeScript
・Corbado Docs: https://docs.corbado.com
・NPM: @corbado/react
・NPM: @corbado/node

Author: Tachikoma
Reviewer: TKD
Version: 1.1
Updated: 2025-11-10
Purpose: Corbado公式構成準拠によるPasskeyButton再設計