# HarmoNet 詳細設計書 - AppFooter (C-04) v1.1

**Document ID:** HARMONET-COMPONENT-C04-APPFOOTER
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-09
**Updated:** 2025-11-16
**Component ID:** C-04
**Component Name:** AppFooter
**Category:** 共通部品（Common Components）
**Design System:** HarmoNet Design System v1.1

---

## ch01 概要

### 1.1 目的

AppFooter（C-04）は、HarmoNet アプリケーション全画面で使用される **固定フッターコンポーネント** である。画面最下部でコピーライト表記を安定して提供し、アプリ全体の統一感・ブランド性を維持する役割を持つ。

本 v1.1 では、以下の最新仕様を反映する：

* **技術スタック定義 v4.3**（Next.js 16 / React 19 / StaticI18nProvider）との整合
* **Logger 設計 v1.1** を踏まえた「AppFooter はログ対象外」という方針の明文化
* **フロントエンド公式ディレクトリ構成 v1.0** との一致確認
* 一字一句全行確認による不要表現の修正・整合性調整

### 1.2 役割

| 役割            | 内容                                            |
| ------------- | --------------------------------------------- |
| **コピーライト表示**  | `© 2025 HarmoNet. All rights reserved.` を表示する |
| **多言語対応**     | StaticI18nProvider (C-03) の `t()` により翻訳文言取得   |
| **固定配置**      | 画面最下部に固定表示し、グローバルフッタとして振る舞う                   |
| **Stateless** | ロジックを持たず、UI 表示のみに責務を限定                        |

### 1.3 前提条件（最新仕様）

* **フレームワーク:** Next.js 16（App Router）
* **UI ライブラリ:** React 19
* **翻訳:** StaticI18nProvider（独自 JSON 辞書方式）
* **スタイリング:** Tailwind CSS 3.4.x
* **Logger:** 共通ログユーティリティ v1.1（※AppFooter では未使用）

### 1.4 設計方針

```
✓ Stateless（状態なし）
✓ 固定位置（bottom-0）に常時表示
✓ StaticI18nProvider の t() のみ使用
✓ セマンティック HTML（<footer role="contentinfo">）
✓ HarmoNet Design System v1.1 の最小・やさしい UI に準拠
```

---

## ch02 依存関係

### 2.1 コンポーネント階層（最新構成）

```
app/layout.tsx（ルート）
└─ StaticI18nProvider (C-03)
    └─ AppHeader (C-01)
    └─ {children}
    └─ AppFooter (C-04)
```

### 2.2 データフロー

```
StaticI18nProvider
      ↓ t('common.copyright')
AppFooter
      ↓ JSX レンダリング
      ↓ 固定フッターとして DOM 出力
```

### 2.3 外部依存

| 依存                        | 用途                           |
| ------------------------- | ---------------------------- |
| React 19                  | JSX / useContext（i18n 内部で使用） |
| StaticI18nProvider (C-03) | 翻訳辞書の提供                      |
| Tailwind CSS              | UI スタイリング                    |

---

## ch03 Props 定義

### 3.1 型定義

```ts
export interface AppFooterProps {
  /** カスタムクラス名（任意） */
  className?: string;

  /** テスト用 ID */
  testId?: string;
}
```

### 3.2 デフォルト値

* `className`: ''
* `testId`: `'app-footer'`

---

## ch04 UI 構成

### 4.1 ビジュアル構造

```
┌────────────────────────────────────────┐
│  © 2025 HarmoNet. All rights reserved. │ ← AppFooter
└────────────────────────────────────────┘
```

### 4.2 スタイリング仕様

| 項目      | 値                               |
| ------- | ------------------------------- |
| 背景色     | `#FFFFFF`                       |
| テキスト色   | `#9CA3AF`（gray-400）             |
| 高さ      | 48px                            |
| 位置      | `fixed bottom-0 left-0 right-0` |
| フォント    | BIZ UD ゴシック相当（システムフォントで代替）      |
| z-index | 900（AppHeader より下）              |
| 上部ボーダー  | 1px solid `#E5E7EB`（gray-200）   |

### 4.3 レスポンシブ

* スマートフォン：高さ 48px、パディング 12px
* タブレット／PC：高さ 48px、パディング 16px

### 4.4 アクセシビリティ

```html
<footer role="contentinfo" aria-label="フッター領域">…</footer>
```

* `role="contentinfo"` によりスクリーンリーダーがフッタ領域を認識
* 翻訳文言は StaticI18nProvider 内で自動切替

---

## ch05 ロジック構造

### 5.1 実装コード（最新技術スタック v4.3 準拠）

```tsx
'use client';

import React from 'react';
import { useI18n } from '@/src/components/common/StaticI18nProvider';
import type { AppFooterProps } from './AppFooter.types';

export const AppFooter: React.FC<AppFooterProps> = ({
  className = '',
  testId = 'app-footer',
}) => {
  const { t } = useI18n();

  return (
    <footer
      role="contentinfo"
      aria-label="フッター領域"
      className={`fixed bottom-0 left-0 right-0 z-[900] h-12 bg-white border-t border-gray-200 flex items-center justify-center ${className}`}
      data-testid={testId}
    >
      <p className="text-xs text-gray-400 leading-relaxed">
        {t('common.copyright')}
      </p>
    </footer>
  );
};
```

### 5.2 処理フロー

```
1. マウント
2. StaticI18nProvider から t() を取得
3. 翻訳文言を描画
4. 最下部に固定表示
```

### 5.3 エラーハンドリング

| ケース             | 対処                                               |
| --------------- | ------------------------------------------------ |
| 翻訳キー存在しない       | t() がキー名を返す（フォールバック）                             |
| Provider 外で呼ばれた | StaticI18nProvider が Throw（上位 ErrorBoundary で捕捉） |

---

## ch06 テスト観点

### 6.1 Jest + RTL

| ID       | 観点         | 結果         |
| -------- | ---------- | ---------- |
| T-C04-01 | コピーライト文言表示 | 翻訳文言が表示される |
