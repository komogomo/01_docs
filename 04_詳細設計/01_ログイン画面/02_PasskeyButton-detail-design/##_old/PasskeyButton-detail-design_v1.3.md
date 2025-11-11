# HarmoNet 詳細設計書 - PasskeyButton (A-02) v1.3

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-DESIGN  
**Version:** 1.3  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** Phase9 技術統合版（Next.js 16 / Supabase v2.43 / React 19 / Corbado公式構成）  

---

## 📚 参照文書
- /01_docs/00_project/harmonet-technical-stack-definition_v3.9.md  
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch03_v1.3.1.md  
- /01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md  
- schema.prisma, 20251107000000_initial_schema.sql, 20251107000001_enable_rls_policies.sql  

---

## 第1章 概要

### 1.1 目的
本書は、HarmoNetログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** の最新版設計を定義する。  
v1.3では、**Corbado公式推奨構成（@corbado/react + @corbado/node）** を採用し、  
`@corbado/web-js` を直接呼び出す旧方式を完全に廃止する。

---

### 1.2 方針
- Next.js 16 (App Router) / React 19 / TypeScript 5.6  
- 認証基盤：Corbado Passkey SDK（React/Node構成）  
- サーバー側で `@corbado/node` によりセッション取得  
- SupabaseはRLSおよびアプリケーションセッション管理のみ  
- UIトーン：Appleカタログ風ミニマル、BIZ UDゴシック  

---

## 第2章 構造設計

### 2.1 構成図

```mermaid
graph TD
  A[User] -->|WebAuthn認証| B[CorbadoProvider + <Auth />]
  B --> C[Corbado Cloud]
  C --> D[CorbadoService (@corbado/node)]
  D --> E[Supabase Session Store]

・CorbadoがWebAuthn認証とセッション確立を担う。
・SupabaseはRLS制御を含むアプリ内認可層として利用。

2.2 依存パッケージ
| パッケージ                   | バージョン   | 用途                    |
| ----------------------- | ------- | --------------------- |
| @corbado/react          | ^2.x    | 認証UI（Provider / Auth） |
| @corbado/node           | ^2.x    | サーバーセッション処理           |
| @supabase/supabase-js   | ^2.43.0 | データ層セッション管理           |
| next                    | ^16.0.1 | App Router            |
| react                   | ^19.0.0 | UI                    |
| tailwindcss             | ^3.4    | スタイル                  |
| shadcn/ui, lucide-react | 最新      | ボタン・アイコン              |

第3章 実装構成
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

CorbadoProvider はアプリ全体に認証コンテキストを提供する。
NEXT_PUBLIC_CORBADO_PROJECT_ID はCorbadoダッシュボード発行値を設定。

3.2 PasskeyButton（app/page.tsx）
'use client';
import { Auth } from '@corbado/react';
import { useI18n } from '@/components/common/StaticI18nProvider';

export default function LoginPage() {
  const { t } = useI18n();
  return (
    <main className="flex flex-col items-center justify-center h-screen bg-white">
      <h1 className="text-2xl font-bold text-gray-700 mb-6">{t('auth.title')}</h1>
      <div className="w-80">
        <Auth />
      </div>
    </main>
  );
}

<Auth /> コンポーネントはCorbado提供UIを描画し、
Passkey／MagicLinkいずれの方式も自動的に処理。

3.3 セッション取得API（app/api/session/route.ts）
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

・サーバーでセッション情報を取得し、Supabase認可と整合。
・CORBADO_API_SECRET はサーバー専用環境変数。

第4章 Supabase連携方針
| 項目          | 内容                                 |
| ----------- | ---------------------------------- |
| **目的**      | Corbadoセッションをアプリ内認可層へ統合            |
| **方式**      | Supabase側でユーザーIDを照合し、RLSを適用        |
| **JWTトークン** | Corbadoセッションから受領                   |
| **利点**      | CorbadoをIdP、Supabaseをデータガードとして明確分離 |

第5章 UI仕様
| 項目      | 値                 |
| ------- | ----------------- |
| 背景      | #FFFFFF           |
| フォント    | BIZ UDゴシック        |
| フォントサイズ | 16px              |
| ボタン角丸   | rounded-2xl       |
| シャドウ    | shadow-sm         |
| 配置      | 中央揃え              |
| トーン     | Appleカタログ風・控えめ・自然 |

第6章 アクセシビリティ・UX
・aria-busy / aria-live="polite" 属性で動的状態を通知
・フォーカスリングを明示しキーボード操作に対応
・多言語メッセージ：common.json にキー auth.passkey, auth.success, auth.retry, error.* を追加

第7章 セキュリティ
・HTTPS必須（WebAuthn仕様）
・Origin, RP ID, Attestation は Corbado 側で検証済み
・Corbado の JWT セッションは短期（<1h）有効
・Supabase 側セッションは signInWithIdToken で更新管理

第8章 テスト仕様（概要）
| テストID    | 内容                  | 成否条件          |
| -------- | ------------------- | ------------- |
| T-A02-01 | `<Auth />` でログイン成功  | `/mypage` へ遷移 |
| T-A02-02 | 認証拒否時               | 再試行ボタン表示      |
| T-A02-03 | `/api/session` 正常応答 | JSONセッション返却   |
| T-A02-04 | 未認証アクセス             | 401応答         |
| T-A02-05 | i18n動作              | 言語切替でUI反映     |

第9章 保守・監視
・Corbado SDK / Supabase SDK の更新を月次監視
・Corbado側ログでWebAuthn成功率・異常統計を取得
・Supabaseログと突合し、整合性を監査
・Sentryで/api/sessionエラー捕捉

第10章 参考URL
・Corbado公式 GitHub: passkeys-nextjs
・Qiita: Next.jsとCorbadoを使用したパスキー実装 #TypeScript
・Corbado Docs
・NPM: @corbado/react
・NPM: @corbado/node

第11章 ChangeLog
| Version  | Date           | Author              | Description                                                              |
| -------- | -------------- | ------------------- | ------------------------------------------------------------------------ |
| v1.0     | 2025-11-10     | TKD / Claude        | 初版（Supabase直呼び出し案）                                                       |
| v1.1     | 2025-11-10     | TKD / Tachikoma     | Next.js16適合修正版                                                           |
| v1.2     | 2025-11-10     | TKD / Tachikoma     | Corbado SDK導入試験版（@corbado/web-js）                                        |
| **v1.3** | **2025-11-10** | **TKD / Tachikoma** | **Corbado公式構成（@corbado/react + @corbado/node）へ完全移行。@corbado/web-jsを廃止。** |

Author: Tachikoma
Reviewer: TKD
Version: 1.3
Updated: 2025-11-10
Purpose: Corbado公式構成への最終移行版