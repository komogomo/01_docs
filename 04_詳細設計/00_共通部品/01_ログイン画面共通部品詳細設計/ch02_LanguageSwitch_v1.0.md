# ch02: LanguageSwitch コンポーネント詳細設計書 v1.0

**Document ID:** HNM-LOGIN-COMMON-C02-LANGUAGESWITCH
**Version:** 1.0
**Created:** 2025-11-09
**Component ID:** C-02
**Component Name:** LanguageSwitch
**Design System:** HarmoNet Design System v1
**Status:** ✅ 初版

---

## 1. 概要

### 1.1 目的

HarmoNet 全画面（ログイン含む）で使用される **言語切替 UI コンポーネント**。
ユーザーが日本語（JA）・英語（EN）・中国語（ZH）の3言語を一目で認識・選択できるようにし、押下1回で即座に切り替えられることを目的とする。

### 1.2 設計方針

```
・3ボタン並列（JA／EN／中文）構成
・選択中言語を青強調、非選択をグレー表示
・StaticI18nProvider経由で即時翻訳反映
・48×48px以上のタップ領域確保（モバイル操作最適化）
・シンプル・自然・誤操作防止のHarmoNet UX準拠
```

### 1.3 配置位置

* **位置:** AppHeader（C-01）右端
* **表示:** 全画面共通（ログイン／認証後問わず）

---

## 2. 依存関係

| コンポーネント                   | 関係 | 備考                                        |
| ------------------------- | -- | ----------------------------------------- |
| AppHeader (C-01)          | 親  | ヘッダー右端に配置                                 |
| StaticI18nProvider (C-03) | 協調 | `useI18n()` による `locale` / `setLocale` 提供 |

---

## 3. Props 定義

```ts
export type Locale = 'ja' | 'en' | 'zh';

export interface LanguageSwitchProps {
  /** カスタムクラス名（任意） */
  className?: string;
  /** テストID（任意） */
  testId?: string;
}
```

---

## 4. UI構成

### 4.1 レイアウト

```
[ JA ] [ EN ] [ 中文 ]
```

* 横並び（`flex-row`）配置。
* 各ボタンの間隔：8px（`gap-2`）。

### 4.2 ビジュアル仕様（HarmoNet準拠）

| 状態 | 背景色 | 文字色 | 枠線 | 備考 |
|------|----------|----------|-------|
| 選択中 | `#DBEAFE`（blue-100） | `#2563EB`（blue-600） | 1px solid `#2563EB` | フォーカスリング有効 |
| 非選択 | `#FFFFFF` | `#6B7280`（gray-500） | 1px solid `#E5E7EB` | hover時 `#F9FAFB` |

フォント：BIZ UDゴシック（Semibold）
角丸：`rounded-lg`（8px）
最小タップ領域：48×48px

---

## 5. ロジック設計

```tsx
'use client';
import React from 'react';
import { useI18n } from '@/components/common/StaticI18nProvider';
import type { LanguageSwitchProps, Locale } from './LanguageSwitch.types';

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
            onClick={() => setLocale(code)}
            className={`min-w-[48px] min-h-[48px] rounded-lg border text-sm font-semibold px-3 py-2 transition-colors focus-visible:ring-2 focus-visible:ring-blue-600 ${
              active
                ? 'bg-blue-50 text-blue-600 border-blue-600'
                : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
            }`}
            aria-label={`${label}に切り替え`}
            aria-pressed={active}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
};
```

---

## 6. テスト観点

| テストID    | 観点    | 期待結果                               |
| -------- | ----- | ---------------------------------- |
| T-C02-01 | 初期表示  | 現在のロケールが青強調で表示される                  |
| T-C02-02 | 切替操作  | 押下で選択が即切り替わり、翻訳が即反映される             |
| T-C02-03 | 非選択状態 | 非選択ボタンがグレー表示、hoverで淡灰背景            |
| T-C02-04 | A11y  | `aria-pressed`・`aria-label` が適切に設定 |
| T-C02-05 | スタイル  | 枠線・角丸・フォーカスリングが正しく表示               |

---

## 7. アクセシビリティ

* 各ボタンに `aria-pressed` で選択状態を通知。
* `aria-label` によってスクリーンリーダーが「日本語に切り替え」などを読み上げる。
* フォーカスリングは `focus-visible:ring-blue-600` を標準。
* コントラスト比 7.2:1（WCAG AAA 準拠）。

---

## 8. 注意事項

* 外部UIライブラリ（shadcn/ui, HeadlessUI）への依存禁止。
* `setLocale()` は StaticI18nProvider (C-03) に実装必須。
* SSR/CSR 両環境で翻訳切替を正しく反映させること。
* レイアウト崩れ防止のため `flex` 配置は固定化。

---

## 9. 改訂履歴

| Version | Date       | Author          | Summary          |
| ------- | ---------- | --------------- | ---------------- |
| 1.0     | 2025-11-09 | TKD / Tachikoma | 正式3ボタン並列仕様として確定。 |
