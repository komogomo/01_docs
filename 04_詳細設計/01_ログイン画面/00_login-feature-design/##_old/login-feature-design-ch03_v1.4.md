# HarmoNet 詳細設計書 - ログイン機能 第3章 Passkey認証設計書 v1.4

**Document ID:** HARMONET-LOGIN-CH03-PASSKEY  
**Version:** 1.4  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Supersedes:** v1.3.1  
**Related Tech Spec:** harmonet-technical-stack-definition_v4.0.md  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** ✅ Phase9 完成版（技術スタックv4.0準拠）

---

## 第1章 概要

本章では、HarmoNetログイン機能における **Passkey認証（Corbado連携）** の詳細設計を示す。  
本v1.4では、従来の `@corbado/web-js` + `loginWithPasskey()` 構成を廃止し、  
**Corbado公式構成（@corbado/react + @corbado/node）** へ移行する。

---

### 1.1 改訂目的

| 改訂項目 | 内容 |
|-----------|------|
| SDK構成 | `@corbado/react` + `@corbado/node` へ変更 |
| 認証方式 | `<Auth />` コンポーネントによる公式UI運用 |
| 認証フロー | `/api/session` によるセッション検証方式 |
| Supabase連携 | `signInWithIdToken` → JWT検証＋RLS |
| セキュリティ | HTTPS必須、Origin固定、Cookie Secure化 |
| UI方針 | Appleカタログ風・BIZ UDゴシック |

---

## 第2章 構成概要

### 2.1 コンポーネント構成

```mermaid
graph TD
  A[User] -->|WebAuthn| B[CorbadoProvider]
  B --> C[Auth Component]
  C --> D[Corbado Cloud]
  D --> E[CorbadoService (Node SDK)]
  E --> F[Supabase Session Store]

・@corbado/react による <CorbadoProvider> ＋ <Auth /> UI構成
・@corbado/node によりサーバーセッションを検証
・SupabaseはRLS＋データ認可に限定使用

2.2 ファイル構成
src/
├─ app/
│   ├─ layout.tsx                # CorbadoProvider 適用
│   ├─ page.tsx                  # Passkey認証UI
│   └─ api/
│       └─ session/
│           └─ route.ts          # Corbadoセッション検証API
├─ lib/
│   └─ supabase/
│       └─ client.ts             # Supabaseクライアント
└─ components/
    └─ login/
        └─ PasskeyButton/
            ├─ PasskeyButton.tsx
            ├─ PasskeyButton.types.ts
            └─ index.ts

第3章 フロントエンド設計
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

・アプリ全体に認証コンテキストを供給
・NEXT_PUBLIC_CORBADO_PROJECT_ID はダッシュボード発行値を設定

3.2 認証UI（app/page.tsx）
'use client';
import { Auth } from '@corbado/react';
import { useI18n } from '@/components/common/StaticI18nProvider';

export default function LoginPage() {
  const { t } = useI18n();
  return (
    <main className="flex flex-col items-center justify-center h-screen bg-white">
      <h1 className="text-2xl mb-6 font-bold text-gray-700">{t('auth.title')}</h1>
      <div className="w-80">
        <Auth />
      </div>
    </main>
  );
}

・<Auth /> がCorbado提供の公式UIを表示。
・パスキーまたはメールリンク認証を自動処理。
・旧 loginWithPasskey() は不要。

第4章 サーバー設計
4.1 セッション検証API（app/api/session/route.ts）
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

・Corbadoセッションをサーバーで検証。
・JWTの検証に成功すればSupabase側でセッション確立。

4.2 Supabase連携方式
| 項目     | 内容                                   |
| ------ | ------------------------------------ |
| 方式     | Supabase認可をCorbadoセッション検証で代替         |
| トークン受渡 | `/api/session` から返却されたCorbado JWTを使用 |
| 認可制御   | Supabase RLSでCorbadoユーザーIDを参照        |
| メリット   | トークン交換不要、セッション再利用可                   |

第5章 UI仕様（HarmoNet共通）
| 項目      | 値                 |
| ------- | ----------------- |
| 背景      | #FFFFFF           |
| フォント    | BIZ UDゴシック        |
| フォントサイズ | 16px              |
| ボタン角丸   | rounded-2xl       |
| シャドウ    | shadow-sm         |
| 配置      | 中央揃え              |
| トーン     | Appleカタログ風・控えめ・自然 |

第6章 アクセシビリティ・UX考慮
・aria-live による状態通知対応
・キーボード操作・フォーカスリング保持
・多言語表示（StaticI18nProvider連携）
・セッション未確立時の自動リトライ（Corbado側UIに委譲）

第7章 セキュリティ仕様
・HTTPS通信必須
・Corbado側でRP ID／Originを固定
・Cookie属性：Secure, SameSite=Lax
・Supabase側RLSを全テーブルで適用
・環境変数 CORBADO_API_SECRET はサーバー専用管理

第8章 テスト観点
| テストID     | 項目                  | 期待結果           |
| --------- | ------------------- | -------------- |
| T-CH03-01 | Passkeyでログイン成功      | `/mypage` へ遷移  |
| T-CH03-02 | 未登録ユーザー             | Corbado登録UIへ誘導 |
| T-CH03-03 | `/api/session` 正常応答 | JWTセッション返却     |
| T-CH03-04 | 無効トークン              | 401応答          |
| T-CH03-05 | HTTPS無効環境           | 警告表示           |
| T-CH03-06 | 多言語切替               | UI更新確認         |

第9章 参考URL
・Corbado GitHub: passkeys-nextjs
・Qiita: Next.jsとCorbadoを使用したパスキー実装 #TypeScript
・Corbado Docs
・Supabase Docs: Auth SignInWithIdToken

第10章 ChangeLog
| Version  | Date           | Author              | Description                                                                     |
| -------- | -------------- | ------------------- | ------------------------------------------------------------------------------- |
| v1.3.1   | 2025-11-09     | TKD / Tachikoma     | @corbado/web-js構成                                                               |
| **v1.4** | **2025-11-10** | **TKD / Tachikoma** | **技術スタックv4.0対応：@corbado/react + @corbado/node構成へ完全移行。`loginWithPasskey()`を廃止。** |

Document Status: ✅ 完成（Phase9最終仕様）
Approved by: TKD