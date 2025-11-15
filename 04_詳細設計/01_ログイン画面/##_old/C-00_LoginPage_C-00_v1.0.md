# HarmoNet Windsurf実行指示書 - LoginPage統合 (C-00)

**Document ID:** HARMONET-COMPONENT-C00-LOGINPAGE-INTEGRATION
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Directory:** `/01_docs/04_詳細設計/01_ログイン画面/`
**Target Agent:** Windsurf
**Status:** ✅ 実行指示準備完了（UI統合フェーズ）

---

## 🎯 目的

本指示書は、HarmoNet ログイン画面（A-00: LoginPage）を構成する以下の6コンポーネントを結合し、
Next.js 16 (App Router) 上に統合ページ `app/page.tsx` を構築するための Windsurf 実行タスクを定義する。

統合対象:

* **A-01 MagicLinkForm** — Supabase OTPによるメール認証フォーム【50†source】
* **A-02 PasskeyButton** — Corbado Passkey認証ボタン【48†source】
* **C-01 AppHeader** — 画面共通ヘッダー【38†source】
* **C-02 LanguageSwitch** — 言語切替コンポーネント【37†source】
* **C-03 StaticI18nProvider** — 多言語Provider【40†source】
* **C-04 AppFooter** — 固定フッター【42†source】

---

## 第1章 統合方針

### 1.1 構成概要

```
app/layout.tsx
└─ StaticI18nProvider (C-03)
    ├─ AppHeader (C-01)
    │   └─ LanguageSwitch (C-02)
    ├─ main
    │   ├─ MagicLinkForm (A-01)
    │   └─ PasskeyButton (A-02)
    └─ AppFooter (C-04)
```

### 1.2 スタイルポリシー

* HarmoNet UIトーン: 「やさしく・自然・控えめ」＋ Appleカタログ風ミニマル。
* 基本フォント: **BIZ UD ゴシック**。
* 背景: `bg-gray-50`。余白多め。角丸2xl。影は最小限。
* 主要配色: `#2563EB`（blue-600）を基調。

### 1.3 表示構造（PC/モバイル共通）

```
┌──────────────────────────────┐
│ AppHeader（ロゴ＋言語切替）             │
│──────────────────────────────│
│ [MagicLinkForm]                      │
│ [PasskeyButton]                      │
│──────────────────────────────│
│ AppFooter（©2025 HarmoNet）          │
└──────────────────────────────┘
```

---

## 第2章 ファイル生成仕様

### 2.1 対象ファイル

| 出力先            | ファイル名                   | 目的              |
| -------------- | ----------------------- | --------------- |
| `app/`         | `page.tsx`              | LoginPage本体     |
| `src/stories/` | `LoginPage.stories.tsx` | Storybook統合テスト用 |
| `src/tests/`   | `LoginPage.test.tsx`    | Jest結合テスト用      |

### 2.2 `app/page.tsx` 生成仕様

```tsx
'use client';
import React from 'react';
import { AppHeader } from '@/components/common/AppHeader';
import { LanguageSwitch } from '@/components/common/LanguageSwitch';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';
import { MagicLinkForm } from '@/components/login/MagicLinkForm';
import { PasskeyButton } from '@/components/login/PasskeyButton';
import { AppFooter } from '@/components/common/AppFooter';

export default function LoginPage() {
  return (
    <StaticI18nProvider>
      <div className="flex flex-col justify-between items-center min-h-screen bg-gray-50">
        <header className="w-full max-w-md px-4 pt-6">
          <AppHeader />
          <div className="mt-4 flex justify-end">
            <LanguageSwitch />
          </div>
        </header>

        <main className="flex flex-col gap-6 w-full max-w-md px-4 py-8">
          <MagicLinkForm />
          <PasskeyButton />
        </main>

        <AppFooter />
      </div>
    </StaticI18nProvider>
  );
}
```

### 2.3 Storybook構成

```tsx
import type { Meta, StoryObj } from '@storybook/react';
import LoginPage from '@/app/page';

const meta: Meta<typeof LoginPage> = {
  title: 'Login/LoginPage',
  component: LoginPage,
};

export default meta;
type Story = StoryObj<typeof LoginPage>;

export const Default: Story = {
  render: () => <LoginPage />,
};
```

### 2.4 Jestテスト構成

```tsx
import { render, screen } from '@testing-library/react';
import LoginPage from '@/app/page';

describe('LoginPage Integration', () => {
  it('renders MagicLinkForm and PasskeyButton', () => {
    render(<LoginPage />);
    expect(screen.getByPlaceholderText(/@/)).toBeInTheDocument();
    expect(screen.getByText(/passkey/i)).toBeInTheDocument();
  });

  it('includes AppFooter and Header', () => {
    render(<LoginPage />);
    expect(screen.getByText(/HarmoNet/)).toBeInTheDocument();
    expect(screen.getByText(/© 2025 HarmoNet/)).toBeInTheDocument();
  });
});
```

---

## 第3章 テスト条件

| 項目    | 条件                                     |
| ----- | -------------------------------------- |
| 動作確認  | `npm run dev` で `/` アクセス時にログイン画面表示     |
| 翻訳切替  | LanguageSwitch操作でja/en/zh切替            |
| 結合確認  | MagicLinkForm + PasskeyButton 両コンポ動作確認 |
| レイアウト | AppHeaderとAppFooterの間にmain配置されること      |

---

## 第4章 Windsurfタスク設定

* Task Name: `HarmoNet_LoginPage_Build_C00`
* Safe Steps: 4
* Target Score: 9.5/10
* 禁止事項:

  * 既存ファイル削除・移動
  * 任意CSS追加（Tailwind以外）
  * 新規依存パッケージ追加

---

## 第5章 成果物検証基準

| 観点        | 合格条件                    |
| --------- | ----------------------- |
| Lint      | 0エラー（ESLint / Prettier） |
| UT        | Jest全通過（結合観点）           |
| Storybook | UIが整合し、i18n切替動作確認       |
| SelfScore | 平均9.5/10以上              |

---

## 第6章 ChangeLog

| Version | Date       | Author    | Summary                                            |
| ------- | ---------- | --------- | -------------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版。LoginPage結合仕様を定義し、AppHeader〜AppFooter間の統合構成を指定。 |

---

**Approved by:** TKD
**Ready for Execution:** ✅ Windsurf実行可能
