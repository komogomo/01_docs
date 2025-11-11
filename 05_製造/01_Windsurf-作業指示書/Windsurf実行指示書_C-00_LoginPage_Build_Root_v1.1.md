# Windsurf実行指示書 - LoginPage構築（ルート統合版）

**Document ID:** HARMONET-WINDSURF-INSTRUCTION-C00-LOGINPAGE-BUILD
**Version:** 1.1
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Target:** Windsurf
**Directory:** `/01_docs/05_製造/01_Windsurf-作業指示書/`
**Status:** ✅ 実行準備完了（ルート構成確定）

---

## 🎯 目的

HarmoNet ログイン画面（C-00 LoginPage）を正式ルート `/` に統合する。
すでに設計済みの A-01（MagicLinkForm）・A-02（PasskeyButton）を中心に、
共通UI（C-01〜C-04）を組み合わせ、ルート画面として構築する。

---

## 📁 対象ディレクトリ

```
/app/page.tsx
/app/login/page.tsx      ← リダイレクトのみ
/app/layout.tsx          ← StaticI18nProvider適用済み
/src/stories/LoginPage.stories.tsx
/src/tests/LoginPage.test.tsx
```

---

## 🧩 構築仕様

### 1. `/app/page.tsx`（LoginPage本体）

```tsx
'use client';
import React from 'react';
import { AppHeader } from '@/components/common/AppHeader';
import { LanguageSwitch } from '@/components/common/LanguageSwitch';
import { MagicLinkForm } from '@/components/login/MagicLinkForm';
import { PasskeyButton } from '@/components/login/PasskeyButton';
import { AppFooter } from '@/components/common/AppFooter';

export default function LoginPage() {
  return (
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
  );
}
```

---

### 2. `/app/login/page.tsx`（リダイレクト専用）

```tsx
import { redirect } from 'next/navigation';
export default function RedirectLogin() {
  redirect('/');
}
```

---

### 3. Storybook登録

`src/stories/LoginPage.stories.tsx`

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

---

### 4. 結合UT

`src/tests/LoginPage.test.tsx`

```tsx
import { render, screen } from '@testing-library/react';
import LoginPage from '@/app/page';

describe('LoginPage Integration', () => {
  it('renders MagicLinkForm and PasskeyButton', () => {
    render(<LoginPage />);
    expect(screen.getByPlaceholderText(/@/)).toBeInTheDocument();
    expect(screen.getByText(/passkey/i)).toBeInTheDocument();
  });

  it('includes header and footer', () => {
    render(<LoginPage />);
    expect(screen.getByText(/HarmoNet/)).toBeInTheDocument();
    expect(screen.getByText(/© 2025 HarmoNet/)).toBeInTheDocument();
  });
});
```

---

## ⚙️ 実行条件

| 項目           | 内容                              |
| ------------ | ------------------------------- |
| Node         | v20 以降                          |
| Next.js      | 16.0.1                          |
| React        | 19                              |
| Supabase SDK | v2.43                           |
| Corbado SDK  | v2.x                            |
| TailwindCSS  | v3.4                            |
| Provider     | layout.tsx に StaticI18nProvider |

---

## ✅ 成果物検証項目

| 検証項目      | 判定条件                                                |
| --------- | --------------------------------------------------- |
| Lint      | 0 エラー                                               |
| UnitTest  | 100% Pass                                           |
| Storybook | i18n切替含め正常表示                                        |
| Browser   | `http://localhost:3000/` でヘッダー・フッター付きログイン画面が表示されること |

---

## 🚫 禁止事項

* 既存ディレクトリ削除・移動
* CSSフレームワーク追加
* MagicLinkForm / PasskeyButtonの改変
* Corbado / Supabase設定変更

---

## 📜 ChangeLog

| Version | Date           | Author        | Summary                                         |
| ------- | -------------- | ------------- | ----------------------------------------------- |
| 1.0     | 2025-11-11     | Tachikoma     | 初版（C-00仕様に基づく統合指示）                              |
| **1.1** | **2025-11-11** | **Tachikoma** | **StaticI18nProviderをlayout側に限定、ルート `/` へ正式統合** |

---

**Approved by:** TKD
**Execution Ready:** ✅ Windsurf実行可能（Phase9・ルート統合版）
