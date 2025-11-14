# HarmoNet 詳細設計書 - LoginPage (A-00) v1.1

**Document ID:** HARMONET-COMPONENT-A00-LOGINPAGE-DESIGN
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-11
**Updated:** 2025-11-14
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ Passkey挙動ドキュメント／技術スタックv4.2反映版

---

## 第1章 概要

### 1.1 目的

本設計書は、HarmoNet ログイン画面の統合コンポーネント **A-00: LoginPage** の詳細設計を定義する。
v1.1 では、以下の設計変更を反映する：

* UI 上では **1つのログイン画面から MagicLink / Passkey を自然に利用できること** を重視する
* 画面レベルの構成要素はシンプルに保ち、実際の認証方式の切替は **A-01 MagicLinkForm 内部のロジック（A-02 PasskeyAuthTrigger を含む）** に集約する
* これにより、ログイン画面の設計は「レイアウトとコンポジション」に専念し、認証方式の詳細は下位コンポーネントに委譲する

### 1.2 対象範囲

* ログイン画面 `/login` の UI 全体レイアウト
* MagicLink + Passkey を同一画面で扱うためのコンポーネント構成
* StaticI18nProvider, AppHeader, AppFooter のレイアウト統合
* 非機能要件: 多言語対応, アクセシビリティ, 保守性

### 1.3 前提条件

| 項目        | 内容                                                                                       |
| --------- | ---------------------------------------------------------------------------------------- |
| フレームワーク   | Next.js 16.0.1 (App Router)                                                              |
| UIライブラリ   | React 19 + TailwindCSS 3.4                                                               |
| デザイン指針    | HarmoNet Design System v1                                                                |
| コンポーネント依存 | A-01 (MagicLinkForm), A-02 (PasskeyAuthTrigger ロジック), C-01 (AppHeader), C-04 (AppFooter) |
| i18n      | StaticI18nProvider (C-03)                                                                |
| テスト環境     | Jest + React Testing Library                                                             |
| Passkey仕様 | 「HarmoNet Passkey認証の仕組みと挙動」ドキュメントに準拠                                                     |

---

## 第2章 機能設計

### 2.1 機能要約

LoginPage は、ユーザーが HarmoNet にログインするための **トップレベル画面** である。
画面自体はシンプルな構成を保ち、以下の責務に限定する：

* 画面上部に AppHeader（C-01）、下部に AppFooter（C-04）を配置し、HarmoNet 全体のトーンを統一する
* 画面中央に A-01 MagicLinkForm を配置し、**メールアドレス入力 + MagicLink / Passkey ログイン** を単一フォームから利用できる状態にする
* 認証方式の「自動判定」および「Passkey利用可否の挙動」は、A-01 / A-02 の詳細設計に委譲する

ログイン成功時には `/auth/callback`（A-03）に遷移してセッションを確立し、その後 `/mypage` に遷移する。

### 2.2 入出力仕様

```typescript
export interface LoginPageProps {
  /** 任意の追加クラス名 */
  className?: string;
  /** テストID */
  testId?: string;
}
```

出力：AppHeader・Main・AppFooter から成る JSX 構造。

### 2.3 処理フロー

```mermaid
graph TD
  U[ユーザー] --> A[LoginPage表示]
  A --> B[MagicLinkForm表示 (A-01)]
  B --> C[MagicLink / Passkey ログイン処理 (A-01/A-02)]
  C --> D[/auth/callback (A-03)]
  D --> E[セッション確立 → /mypage遷移]
```

* LoginPage はあくまでレイアウトコンテナであり、C の認証処理には直接関与しない
* C の内部では、技術スタック v4.2 / Passkey 挙動ドキュメントに基づき、Passkey 利用可否や OS との対話が実行される

### 2.4 依存関係

| 区分   | コンポーネント / ライブラリ                 | 用途                                    |
| ---- | ------------------------------- | ------------------------------------- |
| 内部依存 | MagicLinkForm (A-01)            | メールアドレス入力 + MagicLink/Passkey 統合フォーム  |
| 内部依存 | AppHeader (C-01)                | ページ上部固定ヘッダー                           |
| 内部依存 | AppFooter (C-04)                | ページ下部固定フッター                           |
| 内部依存 | StaticI18nProvider (C-03)       | 多言語辞書提供                               |
| 内部依存 | PasskeyAuthTrigger ロジック (A-02)  | MagicLinkForm 内部から呼び出される Passkey 連携処理 |
| 外部依存 | @supabase/supabase-js (Auth)    | 認証処理基盤（MagicLink, IdToken）            |
| 外部依存 | @corbado/web-js + @corbado/node | Passkey/WebAuthn 連携 SDK               |

### 2.5 副作用と再レンダー設計

* LoginPage 自体は状態を持たない **Pure Component** として実装する（App Router の `app/login/page.tsx`）。
* 再レンダーは以下の要因で発生する：

  * StaticI18nProvider による辞書切替（画面の文言が変更された場合）
  * 子コンポーネント（MagicLinkForm）が内部状態を持つ場合の再描画
* 認証処理の副作用（OS の Passkey ダイアログ表示など）は、すべて A-01/A-02 側の責務とし、LoginPage は関与しない。

### 2.6 UT観点

| 観点ID | 操作                           | 期待結果                                               | テスト目的                   |
| ---- | ---------------------------- | -------------------------------------------------- | ----------------------- |
| UT01 | ページ描画                        | AppHeader / MagicLinkForm / AppFooter が表示される       | レイアウト構成検証               |
| UT02 | 言語切替（ヘッダー右上の LanguageSwitch） | 全ラベルが選択言語に切り替わる（MagicLinkForm 内文言含む）               | StaticI18nProvider 連携確認 |
| UT03 | MagicLinkForm でログイン          | MagicLinkForm 内のテスト仕様に従い、正常時に `/auth/callback` に遷移 | 認証フローの画面間連携確認           |
| UT04 | スマホ画面幅での表示                   | ログインフォームが縦長画面でも崩れず中央寄せで表示される                       | レスポンシブレイアウト確認           |
| UT05 | PC画面幅での表示                    | フォームの横幅・余白が HarmoNet Design System に準拠している         | デザイン一貫性確認               |

---

## 第3章 構造設計

### 3.1 コンポーネント構成図

```mermaid
graph TD
  A[app/login/page.tsx (LoginPage)] --> B[AppHeader (C-01)]
  A --> C[Mainコンテナ]
  C --> D[MagicLinkForm (A-01)]
  A --> E[AppFooter (C-04)]
```

* A-02 PasskeyAuthTrigger は MagicLinkForm (A-01) の内部ロジックとして利用されるため、画面構造図では省略している。

### 3.2 Props定義

```typescript
export interface LoginPageProps {
  className?: string;
  testId?: string;
}
```

実際の Next.js ページ (`app/login/page.tsx`) では props を受け取らないが、テストコードや将来の分離実装を見据えてインターフェースを定義しておく。

### 3.3 Props制約

| 名称        | 型      | 必須 | デフォルト        | 説明        |
| --------- | ------ | -- | ------------ | --------- |
| className | string | ×  | ''           | 追加クラス指定   |
| testId    | string | ×  | 'login-page' | テスト識別用 ID |

### 3.4 イベント設計

* LoginPage は子コンポーネントのイベントを **直接ハンドリングしない**。
* 認証成功/失敗イベントは A-01 MagicLinkForm（および A-02 ロジック）側で完結させる。

### 3.5 Context連携

* StaticI18nProvider (C-03) はアプリ全体のルートレイアウト `app/layout.tsx` で使用される。
* LoginPage は、`useI18n()` を直接呼び出さず、基本的には子コンポーネントに翻訳処理を委譲する。
* 必要に応じて、ヘッダーやフォーム文言は共通の `common.json` / `auth.json` などの辞書キーを利用する。

### 3.6 i18nキー仕様（画面レベル）

| 項目          | キー                       | 備考                    |
| ----------- | ------------------------ | --------------------- |
| ページタイトル     | `auth.login.title`       | ブラウザタブ・ヘッダー用タイトル      |
| フォーム説明文     | `auth.login.description` | MagicLinkForm 側で表示    |
| 画面下部補足メッセージ | `auth.login.help`        | 「ログインに関するお問合せは管理者まで」等 |

（具体的な文言と辞書ファイル構成は MagicLinkForm / 共通 i18n 設計書側で詳細定義する）

---

## 第4章 実装設計

### 4.1 ファイル配置

HarmoNet Frontend Directory Guideline v1.0 に従い、ログイン画面は Next.js App Router の `app/` 配下に配置する。

```
app/
  layout.tsx              # ルートレイアウト（StaticI18nProvider, AppHeader/AppFooter 配置）
  login/
    page.tsx             # LoginPage (A-00)
```

### 4.2 コード構成（例）

```tsx
// app/login/page.tsx
'use client';

import React from 'react';
import { AppHeader } from '@/src/components/common/AppHeader/AppHeader';
import { AppFooter } from '@/src/components/common/AppFooter/AppFooter';
import { MagicLinkForm } from '@/src/components/auth/MagicLinkForm/MagicLinkForm';

export interface LoginPageProps {
  className?: string;
  testId?: string;
}

const LoginPage: React.FC<LoginPageProps> = ({
  className = '',
  testId = 'login-page',
}) => {
  return (
    <div
      className={`min-h-screen flex flex-col bg-white ${className}`}
      data-testid={testId}
    >
      <AppHeader variant="login" />
      <main className="flex flex-col items-center justify-center flex-1 gap-6 py-10 px-4">
        {/* A-01: MagicLink + Passkey 統合フォーム */}
        <MagicLinkForm />
      </main>
      <AppFooter />
    </div>
  );
};

export default LoginPage;
```

#### 実装上のポイント

* `AppHeader` / `AppFooter` は C-01/C-04 の詳細設計書に従って実装されていることを前提とする。
* MagicLinkForm 内で Passkey 利用可否や OS ダイアログ制御を行うため、LoginPage では余計な状態を持たない。
* `className` / `testId` は E2E / Storybook のための拡張ポイントとする（必須ではない）。

### 4.3 状態管理

* LoginPage は **Stateless** コンポーネントとして実装する。
* ログイン処理中の loading state やエラー表示は、MagicLinkForm 側の state と UI によって表現される。

### 4.4 エラーハンドリング設計

* HTTP レベルや Passkey レベルのエラーは、A-01/A-02 および共通の ErrorHandlerProvider (C-16) で処理される。
* LoginPage は例外を握らず、そのまま上位のエラーバウンダリに委譲する。

### 4.5 セキュリティ仕様（画面レベル）

| 項目     | 対応内容                                                  |
| ------ | ----------------------------------------------------- |
| CSRF対策 | Supabase Auth の CSRF 対策に依存                            |
| XSS対策  | React の自動エスケープ、および直接的な `dangerouslySetInnerHTML` 使用禁止 |
| 認証通信   | HTTPS + Supabase JWT + Corbado token による保護            |
| RLS    | login 後の画面では tenant_id ベースの RLS が有効                   |

### 4.6 パフォーマンス設計

* Tailwind JIT による不要 CSS 削減。
* 画面要素は最小限（ヘッダー・フォーム・フッター）のみとし、初期描画コストを抑える。
* Suspense は `/auth/callback` 側の処理に限定し、LoginPage では使用しない。

---

## 第5章 テスト設計

### 5.1 テスト構成

| 観点   | ケース        | 期待結果                                                  |
| ---- | ---------- | ----------------------------------------------------- |
| UT01 | ページ描画      | AppHeader / MagicLinkForm / AppFooter がすべて DOM 上に存在する |
| UT02 | 言語切替       | StaticI18nProvider を介して、ヘッダー・フッター・フォーム文言が切り替わる        |
| UT03 | スナップショット   | 初期レンダリングの出力がスナップショットと一致する                             |
| UT04 | アクセシビリティ構造 | `role="banner"` / `main` / `contentinfo` が正しく構成されている  |
| UT05 | モバイルレイアウト  | 幅 375px 前後でフォームが中央に表示され、上下に余白が確保されている                 |

### 5.2 テストコード雛形

```tsx
// app/login/LoginPage.test.tsx
import { render, screen } from '@testing-library/react';
import LoginPage from './page';
import { StaticI18nProvider } from '@/src/components/common/StaticI18nProvider/StaticI18nProvider';

describe('LoginPage', () => {
  it('renders header, form, and footer', () => {
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

| Version | Date       | Author    | Summary                                                                           |
| ------- | ---------- | --------- | --------------------------------------------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版作成（MagicLinkForm + PasskeyButton 二重構成）                                          |
| 1.1     | 2025-11-14 | Tachikoma | MagicLinkForm 内の Passkey ロジック統合に合わせて依存関係・構造を修正。App Router 構成と Passkey挙動ドキュメントに整合。 |

---

**End of Document**
