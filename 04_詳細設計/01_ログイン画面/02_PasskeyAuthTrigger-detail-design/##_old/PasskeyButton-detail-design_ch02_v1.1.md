# HarmoNet 詳細設計書（共通部品）  
## PasskeyButton 詳細設計書 ch02 - Corbado構成対応版 v1.1

| 属性 | 値 |
|------|----|
| **Document ID** | HNM-PASSKEY-BUTTON-CH02 |
| **Version** | 1.1 |
| **Created** | 2025-11-10 |
| **Updated** | 2025-11-10 |
| **Updated by** | Tachikoma (AI Engineer) + TKD |
| **Supersedes** | v1.0 |
| **Target Environment** | Next.js 16.0.1 / React 19 / Corbado SDK v2.x |
| **Linked Docs** | login-feature-design-ch03_v1.4.md, ch04_v1.2.md |

---

## 第1章 概要

本章は、HarmoNetログイン画面における  
**PasskeyButton（Corbado公式認証UI統合部品）** の詳細仕様を定義する。  

Phase9以降、パスキー認証は Supabase API を経由せず、  
Corbado公式SDK（`@corbado/react`, `@corbado/node`）を採用する。  
本コンポーネントは、従来の「ボタン押下型UI」から、  
Corbado `<Auth />` コンポーネント内の一要素へ統合された。

---

## 第2章 技術前提

| 項目 | 内容 |
|------|------|
| フレームワーク | Next.js 16.0.1（App Router構成） |
| ライブラリ | React 19 / TypeScript 5.6 |
| 認証基盤 | Corbado WebAuthn SDK（React + Node統合） |
| 通信基盤 | HTTPS / JWT（Corbado Session） |
| 翻訳 | StaticI18nProvider（C-03） |
| UI設計 | shadcn/ui + Tailwind 3.4 |
| アクセシビリティ | WCAG 2.1 AA / `aria-live`対応 |

---

## 第3章 コンポーネント構造
AppLayout
└── CorbadoProvider
└── LoginPage
└── <Auth /> ← Corbado公式コンポーネント
├─ MagicLinkForm（内部統合）
├─ PasskeySection（本仕様対象）
├─ Divider (“または”)
└─ LocalizedText群（i18n対応）


- **CorbadoProvider**  
  プロジェクト単位の設定（`projectId`）をコンテキストとして提供。
- **PasskeySection**  
  Corbado公式UI上でパスキー認証を実行する領域。  
  独自の`PasskeyButton`コンポーネントは廃止され、  
  `<Auth />` 内で自動的にボタン表示・認証が行われる。

---

## 第4章 実装定義

### 4.1 コード構成（抜粋）

```tsx
// app/layout.tsx
import { CorbadoProvider } from "@corbado/react";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <CorbadoProvider projectId={process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!}>
      {children}
    </CorbadoProvider>
  );
}

// app/login/page.tsx
"use client";
import { Auth } from "@corbado/react";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-white">
      <Auth appearance={{ theme: "light" }} />
    </main>
  );
}

4.2 セッション連携（Next.js Server側）
// app/api/session/route.ts
import { CorbadoService } from "@corbado/node";

export async function GET(request: Request) {
  const service = new CorbadoService(process.env.CORBADO_BACKEND_API_KEY!);
  const session = await service.sessions().getCurrent(request);
  return Response.json({ session });
}

第5章 状態・イベント仕様
| 区分 | 状態             | トリガー         | 処理内容                    |
| -- | -------------- | ------------ | ----------------------- |
| 表示 | idle           | ページ表示        | `<Auth />` 初期化          |
| 認証 | authenticating | ボタン押下        | WebAuthn開始（Corbado内部）   |
| 成功 | success        | 認証完了         | Corbado Session確立・JWT返却 |
| 失敗 | error          | ネットワーク／登録不一致 | 内部`<Auth />`が自動表示処理     |

第6章 UIデザイン仕様
| 要素   | スタイル           | 内容               |
| ---- | -------------- | ---------------- |
| 背景   | `bg-white`     | 余白広めの中央配置        |
| ロゴ   | HarmoNetロゴ上部固定 | 認証UIの上           |
| ボタン  | Corbado組み込みテーマ | Apple風グレー＋アイコン付き |
| テキスト | BIZ UDゴシック     | “パスキーでログイン”多言語対応 |
| 角丸   | `rounded-2xl`  | コンテナと統一感維持       |
| 影    | `shadow-sm`    | 浅め、柔らかい印象        |

第7章 i18nキー
| キー                     | 日本語       | 英語                   | 中国語      |
| ---------------------- | --------- | -------------------- | -------- |
| `login.passkey_button` | パスキーでログイン | Sign in with Passkey | 使用通行密钥登录 |
| `login.or`             | または       | or                   | 或者       |
| `login.auth_title`     | ログイン      | Sign In              | 登录       |

第8章 テスト観点
| 観点      | 内容                           |
| ------- | ---------------------------- |
| 初期表示    | `<Auth />` が正しくレンダリングされる     |
| 認証完了    | Corbadoダッシュボード上でログインが反映される   |
| 失敗処理    | Origin mismatch時の自動メッセージ表示   |
| 翻訳検証    | `ja/en/zh` のUI切替が正常動作        |
| セッション検証 | `/api/session` でJWTが正しく返却される |

第9章 改訂履歴
| Version  | Date           | Author              | Summary                                                             |
| -------- | -------------- | ------------------- | ------------------------------------------------------------------- |
| **v1.1** | **2025-11-10** | **TKD + Tachikoma** | Corbado公式UI構成（`@corbado/react` + `@corbado/node`）対応、Supabase直接呼出し廃止 |
| v1.0     | 2025-11-03     | TKD + Tachikoma     | Supabase直接構成、`signInWithPasskey()`実装版                               |

