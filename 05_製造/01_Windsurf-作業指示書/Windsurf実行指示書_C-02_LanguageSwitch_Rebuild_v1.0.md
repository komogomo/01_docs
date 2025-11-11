# LanguageSwitch 実装ファイル一式 — v1.0

**Purpose:** `ch02_LanguageSwitch_v1.0.md` に完全準拠する実装ファイル群。Windsurf へそのまま適用可能。

---

## 1) ファイル: `src/components/common/LanguageSwitch/LanguageSwitch.types.ts`

```ts
export type Locale = 'ja' | 'en' | 'zh';

export interface LanguageSwitchProps {
  className?: string;
  testId?: string;
}
```

---

## 2) ファイル: `src/components/common/LanguageSwitch/LanguageSwitch.tsx`

```tsx
'use client';
import React from 'react';
import type { LanguageSwitchProps, Locale } from './LanguageSwitch.types';
import { useI18n } from '@/components/common/StaticI18nProvider';

export const LanguageSwitch: React.FC<LanguageSwitchProps> = ({
  className = '',
  testId = 'language-switch',
}) => {
  const { locale, setLocale } = useI18n();

  const buttons: { code: Locale; label: string }[] = [
    { code: 'ja', label: 'JA' },
    { code: 'en', label: 'EN' },
    { code: 'zh', label: '中文' },
  ];

  return (
    <div className={`flex gap-2 ${className}`} data-testid={testId}>
      {buttons.map(({ code, label }) => {
        const active = locale === code;
        return (
          <button
            key={code}
            type="button"
            onClick={() => setLocale(code)}
            aria-label={`${label}に切り替え`}
            aria-pressed={active}
            className={`min-w-[48px] min-h-[48px] rounded-lg border text-sm font-semibold px-3 py-2 transition-colors focus-visible:ring-2 focus-visible:ring-blue-600 ${
              active
                ? 'bg-blue-50 text-blue-600 border-blue-600'
                : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
};

export default LanguageSwitch;
```

---

## 3) ファイル: `src/components/common/LanguageSwitch/LanguageSwitch.test.tsx`

```tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LanguageSwitch } from './LanguageSwitch';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';

describe('LanguageSwitch (v1.0)', () => {
  test('初期表示と切替', async () => {
    const user = userEvent.setup();
    render(
      <StaticI18nProvider initialLocale="ja">
        <LanguageSwitch />
      </StaticI18nProvider>
    );

    const jaBtn = screen.getByRole('button', { name: /JAに切り替え/i });
    const enBtn = screen.getByRole('button', { name: /ENに切り替え/i });
    const zhBtn = screen.getByRole('button', { name: /中文に切り替え/i });

    // 初期はJAがアクティブ
    expect(jaBtn).toHaveAttribute('aria-pressed', 'true');

    // ENに切替
    await user.click(enBtn);
    expect(enBtn).toHaveAttribute('aria-pressed', 'true');

    // ZHに切替
    await user.click(zhBtn);
    expect(zhBtn).toHaveAttribute('aria-pressed', 'true');

    // JAに戻す
    await user.click(jaBtn);
    expect(jaBtn).toHaveAttribute('aria-pressed', 'true');
  });
});
```

---

## 4) ファイル: `src/components/common/LanguageSwitch/LanguageSwitch.stories.tsx`

```tsx
import React from 'react';
import { Meta, Story } from '@storybook/react';
import LanguageSwitch from './LanguageSwitch';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';

export default {
  title: 'Common/LanguageSwitch',
  component: LanguageSwitch,
} as Meta;

const Template: Story = (args) => (
  <StaticI18nProvider initialLocale={args.initialLocale}>
    <LanguageSwitch />
  </StaticI18nProvider>
);

export const JA = Template.bind({});
JA.args = { initialLocale: 'ja' };

export const EN = Template.bind({});
EN.args = { initialLocale: 'en' };

export const ZH = Template.bind({});
ZH.args = { initialLocale: 'zh' };
```

---

## 5) 適用手順（Windsurf 実行手順短縮版）

1. `src/components/common/LanguageSwitch/` をワークツリーに追加（上記ファイル）。
2. `StaticI18nProvider` の `useI18n()` が `locale` と `setLocale()` を提供することを確認。未実装なら補完パッチを適用。
3. `pnpm -w lint` / `pnpm -w test` / `pnpm -w build` を実行し、全てパスを確認。
4. Storybook を立ち上げて `Common/LanguageSwitch` を目視確認。

---

## 6) 注意事項（厳守）

* **バージョンは1.0のまま**。ファイルは初版として配置すること（`_v1.0` の命名規約に従う必要がある場合は別途指示）。
* 既存の `ch02_LanguageSwitch_v1.0.md` を上書きしてはならない（正書はすでにCanvasにある）。
* 余計なUIライブラリ、挙動変更、翻訳キー変更を行わないこと。

---

以上。Windsurf に貼ってそのまま実行できる形になっています。必要なら私がパッチ差分（git patch）を作ります。
