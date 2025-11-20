# HarmoNet 詳細設計書 - LanguageSwitch (C-02) v1.1

**Document ID:** HNM-LOGIN-COMMON-C02-LANGUAGESWITCH
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-09
**Updated:** 2025-11-16
**Component ID:** C-02
**Component Name:** LanguageSwitch
**Design System:** HarmoNet Design System v1.1

---

## ch01 概要

### 1.1 目的

LanguageSwitch（C-02）は、HarmoNet 全画面共通で利用される **言語切替 UI コンポーネント**である。
StaticI18nProvider（C-03）によって提供される `locale` / `setLocale` を利用し、**JA／EN／ZH の 3 言語を即時切替**することを目的とする。

本 v1.1 は以下の最新仕様に整合した全面更新版である：

* 技術スタック v4.3（Next.js 16 / React 19 / StaticI18nProvider）への完全準拠
* AppHeader v1.1 と整合する構造・Props・配置仕様
* Logger 設計 v1.1 に基づく「ログ非対象」方針の明文化
* フロントエンド公式ディレクトリ構成 v1.0 の import ルール反映
* 全行レビューによる記述の精緻化

### 1.2 配置位置

LanguageSwitch は **AppHeader（C-01）右端**に固定して配置される。
ログイン画面・認証後画面の両方で必ず表示される、共通 UI の一部である。

### 1.3 設計方針

```
✓ 3 ボタン並列（JA／EN／中文）
✓ 選択中は青強調、非選択はグレー
✓ StaticI18nProvider による即時翻訳切替
✓ 48×48px 以上のタップ領域（スマホ最適化）
✓ フォーカスリング対応（アクセシビリティ準拠）
✓ HarmoNet の「やさしく・自然・控えめ」トーン
```

---

## ch02 依存関係

### 2.1 コンポーネント依存

| 依存先                         | 内容                                 |
| --------------------------- | ---------------------------------- |
| **C-01 AppHeader**          | LanguageSwitch を右端に配置する親コンポーネント    |
| **C-03 StaticI18nProvider** | `locale` / `setLocale` / `t()` の提供 |

### 2.2 外部依存

| ライブラリ              | 用途        |
| ------------------ | --------- |
| React 19           | コンポーネント構築 |
| TailwindCSS 3.4.x  | UI スタイリング |
| StaticI18nProvider | 多言語切替ロジック |

---

## ch03 Props 定義

### 3.1 型定義

```ts
export type Locale = 'ja' | 'en' | 'zh';

export interface LanguageSwitchProps {
  /** レイアウト調整用クラス名（任意） */
  className?: string;

  /** テスト識別子（任意） */
  testId?: string;
}
```

### 3.2 デフォルト値

* `className`: ''
* `testId`: `'language-switch'`

---

## ch04 UI 構成

### 4.1 レイアウト構造

```
[ JA ]   [ EN ]   [ 中文 ]
```

* 横並び（`flex-row`）
* ボタン間隔：`gap-2`

### 4.2 ボタン仕様（HarmoNet準拠）

| 状態      | 背景色       | 文字色        | 枠線                |
| ------- | --------- | ---------- | ----------------- |
| **選択中** | `blue-50` | `blue-600` | `border-blue-600` |
| **非選択** | `white`   | `gray-600` | `border-gray-300` |

* フォント：BIZ UD ゴシック相当
* 角丸：`rounded-lg`（8px）
* 最小タップ領域：48×48px（重要）
* hover：`bg-gray-50`（やさしい控えめ UI）

---

## ch05 ロジック構造

### 5.1 実装コード（Next.js 16 / React 19）

```tsx
'use client';

import React from 'react';
import { useI18n } from '@/src/components/common/StaticI18nProvider';
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
            aria-label={`${label} に切り替え`}
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

### 5.2 処理フロー

```
1. useI18n() で locale / setLocale を取得
2. 3 ボタンを描画
3. 押下されたボタンの locale に変更
4. StaticI18nProvider が辞書を再ロード
5. 全画面の翻訳が即時更新
```

### 5.3 エラーハンドリング

* setLocale は StaticI18nProvider 内で例外処理済み
* LanguageSwitch 自体は try/catch を持たない（UI コンポーネントの責務）

---

## ch06 テスト観点

### 6.1 Jest + RTL

| ID       | テスト観点 | 期待結果                                 |
| -------- | ----- | ------------------------------------ |
| T-C02-01 | 初期表示  | 現在 locale のボタンが青強調表示                 |
| T-C02-02 | 切替    | ボタン押下で locale が即変更される                |
| T-C02-03 | hover | hover 時に背景が gray-50 になる              |
| T-C02-04 | A11y  | aria-label / aria-pressed が正しく設定     |
| T-C02-05 | スタイル  | border / rounded / focus-ring が正しく適用 |

---

## ch07 ログ出力方針（Logger 準拠）

LanguageSwitch は UI レイアウト専用コンポーネントであり、ログイベントと結びつくアクション（API 呼び出し・認証・画面遷移）を持たないため、
**共通ログユーティリティ（logInfo / logError）は使用しない。**

将来的に「言語選択を Analytics 用に記録する」などの要件が出た場合でも、
**LanguageSwitch 自体ではなく、親コンテナ側でログ出力を行う**方針とする。
（AppHeader v1.1 / AppFooter v1.1 と同一設計思想）

---

## ch08 注意事項

* 外部 UI ライブラリ（shadcn/ui, HeadlessUI）へ依存しないこと
* SSR/CSR どちらでも locale が正しく復元されること（StaticI18nProvider の仕様に依存）
* flex 配置を変更しない（AppHeader のレイアウト前提）

---

## ch09 改訂履歴

| Version | Date    | Summary |
| ------- | ------- | ------- |
| 1.0     | 2025-11 |         |
