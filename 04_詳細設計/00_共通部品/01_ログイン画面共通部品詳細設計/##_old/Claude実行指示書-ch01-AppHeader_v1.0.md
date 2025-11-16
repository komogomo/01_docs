# ch01: AppHeader コンポーネント詳細設計書 v1.0

**Document ID:** HNM-LOGIN-COMMON-C01-APPHEADER  
**Version:** 1.0  
**Created:** 2025-11-09  
**Component ID:** C-01  
**Component Name:** AppHeader  
**Design System:** HarmoNet Design System v1  

---

## 1. 概要

### 1.1 目的

ログイン画面およびログイン後の全画面で使用する共通ヘッダーコンポーネント。  
ログイン画面では「ロゴ + 言語切替」のシンプルな構成、認証後画面では通知アイコン等を追加表示する。

### 1.2 配置位置

- **位置**: 画面最上部（固定表示）
- **高さ**: 60px（固定）
- **z-index**: 1000（最前面）

### 1.3 表示バリエーション

| バリエーション | 表示要素 | 適用画面 |
|--------------|---------|---------|
| **login** | ロゴ + 言語切替 | ログイン画面 |
| **authenticated** | ロゴ + 通知アイコン + 言語切替 | 認証後の全画面 |

---

## 2. 技術仕様

### 2.1 技術スタック

| 項目 | 技術 | バージョン |
|------|------|-----------|
| **フレームワーク** | Next.js | 15.5.x |
| **UIライブラリ** | React | 19.0.0 |
| **スタイリング** | Tailwind CSS | 3.4.x |
| **多言語対応** | next-intl | 3.x |

### 2.2 ファイル構成

```
src/
├── components/
│   ├── common/
│   │   ├── AppHeader/
│   │   │   ├── AppHeader.tsx          # メインコンポーネント
│   │   │   ├── AppHeader.types.ts     # 型定義
│   │   │   ├── AppHeader.test.tsx     # テストコード
│   │   │   └── index.ts               # エクスポート
```

---

## 3. Props定義

### 3.1 インターフェース

```typescript
/**
 * AppHeader コンポーネントのProps
 */
export interface AppHeaderProps {
  /**
   * 表示バリエーション
   * @default 'login'
   */
  variant?: 'login' | 'authenticated';

  /**
   * 追加CSSクラス
   */
  className?: string;

  /**
   * テスト用ID
   */
  testId?: string;
}
```

### 3.2 デフォルト値

```typescript
const defaultProps: Partial<AppHeaderProps> = {
  variant: 'login',
  testId: 'app-header',
};
```

---

## 4. コンポーネント構造

### 4.1 レイアウト構成

```
┌─────────────────────────────────────────────────┐
│  [HarmoNetロゴ]              [🔔] [言語切替▼]   │  60px
└─────────────────────────────────────────────────┘
```

### 4.2 要素配置

| 要素 | 位置 | 表示条件 |
|------|------|---------|
| **HarmoNetロゴ** | 左端（padding-left: 20px） | 常時表示 |
| **通知アイコン** | 右端から2番目 | `variant='authenticated'` のみ |
| **LanguageSwitch** | 右端（padding-right: 20px） | 常時表示 |

---

## 5. 実装例

### 5.1 コンポーネント本体

```typescript
// src/components/common/AppHeader/AppHeader.tsx

import React from 'react';
import { LanguageSwitch } from '../LanguageSwitch';
import type { AppHeaderProps } from './AppHeader.types';

export const AppHeader: React.FC<AppHeaderProps> = ({
  variant = 'login',
  className = '',
  testId = 'app-header',
}) => {
  return (
    <header
      className={`
        fixed top-0 left-0 right-0
        h-[60px]
        bg-white
        border-b border-gray-200
        z-[1000]
        flex items-center justify-between
        px-5
        ${className}
      `}
      data-testid={testId}
      role="banner"
    >
      {/* ロゴ */}
      <div className="flex items-center">
        <img
          src="/images/logo.svg"
          alt="HarmoNet"
          className="h-8"
          data-testid={`${testId}-logo`}
        />
      </div>

      {/* 右側要素 */}
      <div className="flex items-center gap-4">
        {/* 通知アイコン（認証後のみ） */}
        {variant === 'authenticated' && (
          <button
            className="
              relative
              w-10 h-10
              flex items-center justify-center
              text-gray-600
              hover:bg-gray-100
              rounded-lg
              transition-colors
            "
            aria-label="通知を表示"
            data-testid={`${testId}-notification`}
          >
            <span className="text-2xl">🔔</span>
            {/* 未読バッジ（将来実装） */}
            {/* <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" /> */}
          </button>
        )}

        {/* 言語切替 */}
        <LanguageSwitch testId={`${testId}-language-switch`} />
      </div>
    </header>
  );
};

AppHeader.displayName = 'AppHeader';
```

### 5.2 型定義ファイル

```typescript
// src/components/common/AppHeader/AppHeader.types.ts

export interface AppHeaderProps {
  variant?: 'login' | 'authenticated';
  className?: string;
  testId?: string;
}
```

### 5.3 エクスポート

```typescript
// src/components/common/AppHeader/index.ts

export { AppHeader } from './AppHeader';
export type { AppHeaderProps } from './AppHeader.types';
```

---

## 6. スタイリング仕様

### 6.1 基本スタイル（HarmoNet準拠）

| 項目 | 値 | 備考 |
|------|-----|------|
| **高さ** | 60px | 固定 |
| **背景色** | `#FFFFFF` | HarmoNet白色 |
| **下部ボーダー** | 1px solid `#E5E7EB` | グレー200 |
| **左右パディング** | 20px | - |
| **z-index** | 1000 | 最前面 |

### 6.2 ロゴスタイル

| 項目 | 値 |
|------|-----|
| **高さ** | 32px (h-8) |
| **幅** | 自動調整 |
| **alt属性** | "HarmoNet" |

### 6.3 通知アイコンスタイル

| 項目 | 値 |
|------|-----|
| **サイズ** | 40px × 40px |
| **アイコンサイズ** | 24px (text-2xl) |
| **hover時背景色** | `#F9FAFB` (gray-100) |
| **角丸** | 8px (rounded-lg) |

### 6.4 レスポンシブ対応

```css
/* スマートフォン（〜767px） */
@media (max-width: 767px) {
  .app-header {
    height: 56px;
    padding: 0 16px;
  }
  
  .app-header__logo {
    height: 28px;
  }
}

/* タブレット以上（768px〜） */
@media (min-width: 768px) {
  .app-header {
    max-width: 768px;
    left: 50%;
    transform: translateX(-50%);
  }
}
```

---

## 7. アクセシビリティ

### 7.1 セマンティックHTML

```html
<header role="banner">
  <!-- ヘッダー内容 -->
</header>
```

### 7.2 ARIA属性

| 要素 | ARIA属性 | 値 |
|------|---------|-----|
| 通知ボタン | `aria-label` | "通知を表示" |
| ロゴ画像 | `alt` | "HarmoNet" |

### 7.3 キーボード操作

- **Tab**: 言語切替ボタンへフォーカス移動
- **Shift + Tab**: 前の要素へフォーカス移動
- **Enter/Space**: 通知ボタン・言語切替ボタンを実行

### 7.4 スクリーンリーダー対応

```html
<!-- 通知ボタン -->
<button aria-label="通知を表示">
  <span aria-hidden="true">🔔</span>
</button>
```

---

## 8. 状態管理

### 8.1 コンポーネント状態

AppHeaderはStateless Componentとして実装する。

- **状態なし**: 表示のみを担当
- **イベントハンドリング**: 子コンポーネント（LanguageSwitch）に委譲

### 8.2 依存コンポーネント

| コンポーネント | 役割 |
|--------------|------|
| **LanguageSwitch** (C-02) | 言語切替UI |

---

## 9. テスト仕様

### 9.1 ユニットテスト

```typescript
// src/components/common/AppHeader/AppHeader.test.tsx

import { render, screen } from '@testing-library/react';
import { AppHeader } from './AppHeader';

describe('AppHeader', () => {
  it('ログインバリアントでロゴと言語切替のみ表示', () => {
    render(<AppHeader variant="login" />);
    
    expect(screen.getByAltText('HarmoNet')).toBeInTheDocument();
    expect(screen.getByTestId('app-header-language-switch')).toBeInTheDocument();
    expect(screen.queryByTestId('app-header-notification')).not.toBeInTheDocument();
  });

  it('認証バリアントで通知アイコンも表示', () => {
    render(<AppHeader variant="authenticated" />);
    
    expect(screen.getByAltText('HarmoNet')).toBeInTheDocument();
    expect(screen.getByTestId('app-header-notification')).toBeInTheDocument();
    expect(screen.getByTestId('app-header-language-switch')).toBeInTheDocument();
  });

  it('セマンティックHTMLが適切に設定されている', () => {
    render(<AppHeader />);
    
    const header = screen.getByRole('banner');
    expect(header).toBeInTheDocument();
  });
});
```

### 9.2 ビジュアルリグレッションテスト

```typescript
// Storybook Stories
export const LoginVariant: Story = {
  args: {
    variant: 'login',
  },
};

export const AuthenticatedVariant: Story = {
  args: {
    variant: 'authenticated',
  },
};
```

---

## 10. パフォーマンス考慮

### 10.1 最適化ポイント

1. **画像最適化**:
   - ロゴはSVG形式を使用
   - Next.js Image コンポーネント使用

2. **レンダリング最適化**:
   - `React.memo` 不要（props変更頻度低い）
   - Stateless Componentで実装

3. **CSSインライン化**:
   - Tailwind CSSのJIT（Just-In-Time）モード活用

---

## 11. エラーハンドリング

### 11.1 画像読み込みエラー

```typescript
<img
  src="/images/logo.svg"
  alt="HarmoNet"
  onError={(e) => {
    e.currentTarget.src = '/images/logo-fallback.png';
  }}
/>
```

### 11.2 コンポーネント境界

```typescript
// 親コンポーネントでErrorBoundaryを設定
<ErrorBoundary fallback={<HeaderErrorFallback />}>
  <AppHeader />
</ErrorBoundary>
```

---

## 12. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-header_v1.1.md` | ヘッダー領域の共通仕様 |
| `common-design-system_v1.1.md` | HarmoNetデザインシステム |
| `common-layout_v1.1.md` | 3層レイアウト構造 |
| `common-i18n_v1.0.md` | 多言語対応仕様 |
| `common-accessibility_v1.0.md` | アクセシビリティ基準 |

---

## 13. 改訂履歴

| バージョン | 日付 | 更新者 | 更新内容 |
|-----------|------|--------|---------|
| v1.0 | 2025-11-09 | Claude | 新規作成 |

---

**Document ID:** HNM-LOGIN-COMMON-C01-APPHEADER  
**Status:** ✅ Draft  
**Next Review:** Phase9実装開始時
