# HarmoNet 詳細設計書 - LoginPage (A-00) v1.0

**Document ID:** HARMONET-COMPONENT-A00-LOGINPAGE-DESIGN
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ Phase9 最終設計書（正式版）

---

## 第1章 概要

### 1.1 目的

本設計書は、HarmoNet ログイン画面の統合コンポーネント **A-00: LoginPage** の詳細設計を定義する。
A-00 は A-01（MagicLinkForm）および A-02（PasskeyButton）を統合し、ユーザーが初回アクセス時に自然にログイン方式を選択できる画面を提供する。
UI トーンは HarmoNet Design System の原則「やさしく・自然・控えめ」に従い、Apple カタログ風の余白と白基調デザインを採用する。

### 1.2 対象範囲

* ログイン画面 `/login` の UI 全体設計
* MagicLink・Passkey の統合構成
* StaticI18nProvider, AppHeader, AppFooter のレイアウト統合
* 非機能要件: 多言語対応, アクセシビリティ, 保守性

### 1.3 前提条件

| 項目        | 内容                                             |
| --------- | ---------------------------------------------- |
| フレームワーク   | Next.js 16.0.1 (App Router)                    |
| UIライブラリ   | React 19 + TailwindCSS 4.0                     |
| デザイン指針    | HarmoNet Design System v1                      |
| コンポーネント依存 | A-01, A-02, C-01 (AppHeader), C-04 (AppFooter) |
| i18n      | StaticI18nProvider (C-03)                      |
| テスト環境     | Jest + React Testing Library                   |

---

## 第2章 機能設計

### 2.1 機能要約

LoginPage は、ログイン手段（MagicLink または Passkey）を選択・実行できる統合画面である。
ユーザーは同一ページ内で認証方法を選び、成功時には `/auth/callback`（A-03）に遷移してセッションを確立する。
UI と機能は Stateless 構成であり、状態管理は各子コンポーネント（A-01 / A-02）に委譲される。

### 2.2 入出力仕様

```typescript
export interface LoginPageProps {
  /** 任意の追加クラス名 */
  className?: string;
  /** テストID */
  testId?: string;
}
```

出力：JSX構造（AppHeader・Main・AppFooter）

### 2.3 処理フロー

```mermaid
graph TD
  U[ユーザー] --> A[LoginPage表示]
  A --> B[MagicLinkForm入力 or PasskeyButtonクリック]
  B --> C[A-01/A-02 内で認証処理]
  C --> D[/auth/callback (A-03)]
  D --> E[セッション確立 → /mypage遷移]
```

### 2.4 依存関係

| 区分   | コンポーネント / ライブラリ           | 用途           |
| ---- | ------------------------- | ------------ |
| 内部依存 | MagicLinkForm (A-01)      | メール認証フォーム    |
| 内部依存 | PasskeyButton (A-02)      | パスキー認証ボタン    |
| 内部依存 | AppHeader (C-01)          | ページ上部固定ヘッダー  |
| 内部依存 | AppFooter (C-04)          | ページ下部固定フッター  |
| 内部依存 | StaticI18nProvider (C-03) | 多言語辞書提供      |
| 外部依存 | @supabase/supabase-js     | 認証処理基盤（既存）   |
| 外部依存 | @corbado/web-js           | Passkey認証SDK |

### 2.5 副作用と再レンダー設計

* LoginPage 自体は状態を持たない Pure Component。
* 子コンポーネントの再レンダーのみ発生。
* StaticI18nProvider で辞書が切り替わると、再描画が伝搬。
* useCallback / memo を利用する子側設計でパフォーマンスを担保。

### 2.6 UT観点

| 観点ID | 操作              | 期待結果                                 | テスト目的                  |
| ---- | --------------- | ------------------------------------ | ---------------------- |
| UT01 | ページ描画           | MagicLinkForm / PasskeyButton が表示される | レイアウト構成検証              |
| UT02 | 言語切替            | 全ラベルが選択言語に切り替わる                      | StaticI18nProvider動作確認 |
| UT03 | PasskeyButton押下 | Corbado 認証呼び出しが実行される                 | イベント伝達確認               |
| UT04 | MagicLink送信     | Supabase signInWithOtp() が呼ばれる       | イベント伝達確認               |
| UT05 | レスポンシブ確認        | スマホ／PCで整った配置                         | レイアウト品質確認              |

---

## 第3章 構造設計

### 3.1 コンポーネント構成図

```mermaid
graph TD
  A[LoginPage] --> B[AppHeader]
  A --> C[Main (MagicLinkForm + PasskeyButton)]
  A --> D[AppFooter]
```

### 3.2 Props定義

```typescript
export interface LoginPageProps {
  className?: string;
  testId?: string;
}
```

### 3.3 Props制約

| 名称        | 型      | 必須 | デフォルト        | 説明       |
| --------- | ------ | -- | ------------ | -------- |
| className | string | ×  | ''           | 追加クラス指定  |
| testId    | string | ×  | 'login-page' | テスト識別用ID |

### 3.4 イベント設計

LoginPage は子コンポーネントのイベントを直接持たない。
A-01 / A-02 の onSuccess / onError が独立して動作。

### 3.5 Context連携

* StaticI18nProvider をルートで使用。
* 子要素に辞書を伝搬。
* useI18n() でラベル取得（既存キーのみ使用）。

### 3.6 i18nキー仕様

| 項目     | キー             | 備考             |
| ------ | -------------- | -------------- |
| ボタン文言  | `common.save`  | 「送信」ボタン共有キー    |
| エラー文言  | `common.error` | 共通エラーメッセージ     |
| 固定英語文言 | -              | Phase10で辞書拡張予定 |

---

## 第4章 実装設計

### 4.1 ディレクトリ構成

```
src/components/pages/LoginPage/
  ├─ LoginPage.tsx
  ├─ LoginPage.types.ts
  ├─ LoginPage.test.tsx
  └─ index.ts
```

### 4.2 コード抜粋

```tsx
// src/components/pages/LoginPage/LoginPage.tsx
'use client';
import React from 'react';
import { AppHeader } from '@/components/common/AppHeader';
import { AppFooter } from '@/components/common/AppFooter';
import { MagicLinkForm } from '@/components/login/MagicLinkForm';
import { PasskeyButton } from '@/components/login/PasskeyButton';

export const LoginPage: React.FC<LoginPageProps> = ({ className = '', testId = 'login-page' }) => {
  return (
    <div className={`min-h-screen flex flex-col bg-white ${className}`} data-testid={testId}>
      <AppHeader variant="login" />
      <main className="flex flex-col items-center justify-center flex-1 gap-6 py-10 px-4">
        <MagicLinkForm />
        <PasskeyButton />
      </main>
      <AppFooter />
    </div>
  );
};

LoginPage.displayName = 'LoginPage';
```

### 4.3 状態管理

* 状態を持たない stateless コンポーネント。
* 内部で useState 等は使用しない。

### 4.4 エラーハンドリング設計

* 子コンポーネントがエラー処理を担当（onError）。
* LoginPage は例外を握らず、UIに影響を与えない。

### 4.5 セキュリティ仕様

| 項目     | 対応                                          |
| ------ | ------------------------------------------- |
| CSRF対策 | Supabase Auth 機構依存                          |
| XSS対策  | React 自動エスケープ機能                             |
| 認証通信   | HTTPS + Supabase JWT + Corbado sessionToken |
| RLS    | tenant_id スコープ適用済                           |

### 4.6 パフォーマンス設計

* Tailwind の JIT コンパイルで不要CSS削減。
* コンポーネントは SSR/CSR 両対応。
* Suspense 未使用（A-03のみ利用）。

---

## 第5章 テスト設計

### 5.1 テスト構成

| 観点   | ケース      | 期待結果                                                         |
| ---- | -------- | ------------------------------------------------------------ |
| UT01 | ページ描画    | AppHeader / MagicLinkForm / PasskeyButton / AppFooter が表示される |
| UT02 | 言語切替     | StaticI18nProvider によりテキストが切り替わる                             |
| UT03 | スナップショット | 初期レンダリングの出力が一致する                                             |
| UT04 | アクセシビリティ | role="banner" / "contentinfo" / form 構造が正しい                  |

### 5.2 テストコード雛形

```tsx
// src/components/pages/LoginPage/LoginPage.test.tsx
import { render, screen } from '@testing-library/react';
import { LoginPage } from './LoginPage';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';

describe('LoginPage', () => {
  it('renders header, forms, and footer', () => {
    render(
      <StaticI18nProvider currentLocale="ja">
        <LoginPage />
      </StaticI18nProvider>
    );
    expect(screen.getByTestId('login-page')).toBeInTheDocument();
    expect(screen.getByTestId('app-header')).toBeInTheDocument();
    expect(screen.getByTestId('app-footer')).toBeInTheDocument();
  });
});
```

---

## 第6章 ChangeLog

| Version | Date       | Author    | Change           |
| ------- | ---------- | --------- | ---------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版作成（Phase9 完結版） |

---

**End of Document**
