# HarmoNet 詳細設計書 - AppFooter (C-04) v1.0

**Document ID:** HARMONET-COMPONENT-C04-APPFOOTER  
**Version:** 1.0  
**Created:** 2025-11-09  
**Component ID:** C-04  
**Component Name:** AppFooter  
**Category:** 共通部品（Common Components）  
**Difficulty:** 1（容易）  
**Safe Steps:** 2  

---

## ch01 概要

### 1.1 目的

AppFooterは、HarmoNetアプリケーション全画面で使用される**固定フッターコンポーネント**です。画面最下部にコピーライト表記を表示し、アプリケーションの一貫性と信頼性を提供します。

### 1.2 役割

| 役割 | 内容 |
|------|------|
| **コピーライト表示** | `© 2025 HarmoNet. All rights reserved.` を表示 |
| **多言語対応** | StaticI18nProvider経由で翻訳文言を取得 |
| **固定配置** | 画面最下部に常に固定表示 |
| **シンプル性** | 状態を持たないstatelessコンポーネント |

### 1.3 前提条件

- **配置位置:** すべての画面レイアウト最下部
- **依存コンポーネント:** StaticI18nProvider (C-03)
- **フレームワーク:** Next.js 16.0.1（App Router）
- **スタイル:** Tailwind CSS のみ

### 1.4 設計方針

```
✅ Stateless（状態なし）
✅ イベントハンドラなし
✅ StaticI18nProvider の useI18n() で翻訳取得
✅ セマンティックHTML（<footer role="contentinfo">）
✅ HarmoNet Design System v1.1 準拠
```

---

## ch02 依存関係

### 2.1 コンポーネント階層

```
app/layout.tsx（ルート）
└─ StaticI18nProvider (C-03)
    └─ AppHeader (C-01)
    └─ {children}（各画面コンテンツ）
    └─ AppFooter (C-04) ← 本コンポーネント
```

### 2.2 データフロー

```
StaticI18nProvider (C-03)
    ↓ I18nContext 提供
AppFooter (C-04)
    ↓ useI18n() で取得
    ↓ t('common.copyright')
DOM表示
    ↓ 「© 2025 HarmoNet. All rights reserved.」
```

### 2.3 外部依存

| ライブラリ | バージョン | 用途 |
|-----------|-----------|------|
| `react` | ^19.0.0 | useContext（useI18n内部で使用） |
| `tailwindcss` | ^3.4.0 | スタイリング |

---

## ch03 Props定義

### 3.1 TypeScript型定義

```typescript
// src/components/common/AppFooter/AppFooter.types.ts

export interface AppFooterProps {
  /**
   * カスタムクラス名（任意）
   * Tailwind CSSユーティリティクラスを追加可能
   */
  className?: string;

  /**
   * テストID（任意）
   * E2Eテスト、統合テストで要素特定に使用
   */
  testId?: string;
}
```

### 3.2 デフォルト値

```typescript
// デフォルト値なし（すべて任意Props）
```

---

## ch04 UI構成

### 4.1 視覚要素

```
┌────────────────────────────────────────┐
│                                        │
│        （画面コンテンツ）                  │
│                                        │
└────────────────────────────────────────┘
┌────────────────────────────────────────┐
│  © 2025 HarmoNet. All rights reserved. │ ← AppFooter
└────────────────────────────────────────┘
```

### 4.2 ビジュアル仕様（HarmoNet Design System準拠）

| 項目 | 値 |
|------|-----|
| **背景色** | `#FFFFFF`（白） |
| **テキスト色** | `#9CA3AF`（gray-400） |
| **高さ** | 48px |
| **配置** | fixed bottom-0 left-0 right-0 |
| **z-index** | 900（ヘッダーより下） |
| **フォントサイズ** | 12px (0.75rem) |
| **フォントウェイト** | 400 (Regular) |
| **行の高さ** | 1.5 |
| **テキスト整列** | 中央揃え |
| **上部ボーダー** | 1px solid `#E5E7EB` |

### 4.3 レスポンシブ対応

| デバイス | スタイル調整 |
|---------|-------------|
| **スマートフォン** | 高さ48px、パディング12px |
| **タブレット** | 高さ48px、パディング16px |
| **デスクトップ** | 高さ48px、パディング16px |

### 4.4 アクセシビリティ

```typescript
<footer 
  role="contentinfo" 
  aria-label="フッター領域"
  className="..."
>
  <p>{t('common.copyright')}</p>
</footer>
```

| ARIA属性 | 値 |
|---------|-----|
| **role** | contentinfo |
| **aria-label** | "フッター領域" |

---

## ch05 ロジック構造

### 5.1 実装コード

```typescript
// src/components/common/AppFooter/AppFooter.tsx

'use client';

import React from 'react';
import { useI18n } from '@/components/common/StaticI18nProvider';
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

### 5.2 型定義ファイル

```typescript
// src/components/common/AppFooter/AppFooter.types.ts

export interface AppFooterProps {
  className?: string;
  testId?: string;
}
```

### 5.3 index.ts

```typescript
// src/components/common/AppFooter/index.ts

export { AppFooter } from './AppFooter';
export type { AppFooterProps } from './AppFooter.types';
```

### 5.4 処理フロー

```
1. コンポーネントマウント
   ↓
2. useI18n() で I18nContext から t 関数取得
   ↓
3. t('common.copyright') で翻訳文言取得
   ↓
4. JSX レンダリング
   ↓
5. 固定位置（bottom-0）に表示
```

### 5.5 エラーハンドリング

| エラーケース | 対応 |
|------------|------|
| **useI18n()がProvider外** | StaticI18nProviderがthrow（上位で対処） |
| **翻訳キー不在** | t()関数がキーをそのまま返す（フォールバック） |

---

## ch06 テスト観点

### 6.1 Jest + RTL テストケース

| テストID | テスト内容 | 期待結果 |
|---------|-----------|---------|
| **T-C04-01** | 初期表示：コピーライト文言 | `t('common.copyright')`の値が表示される |
| **T-C04-02** | セマンティックHTML | `<footer role="contentinfo">`が存在 |
| **T-C04-03** | className適用 | カスタムクラスが反映される |
| **T-C04-04** | testId適用 | data-testid属性が正しく設定される |
| **T-C04-05** | スタイル適用 | fixed/bottom-0/bg-white等のクラスが存在 |

### 6.2 テストコード例

```typescript
// src/components/common/AppFooter/AppFooter.test.tsx

import { render, screen } from '@testing-library/react';
import { AppFooter } from './AppFooter';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';

// useI18n モック
jest.mock('@/components/common/StaticI18nProvider', () => ({
  ...jest.requireActual('@/components/common/StaticI18nProvider'),
  useI18n: () => ({
    locale: 'ja',
    t: (key: string) => {
      if (key === 'common.copyright') {
        return '© 2025 HarmoNet. All rights reserved.';
      }
      return key;
    },
  }),
}));

describe('AppFooter', () => {
  it('T-C04-01: コピーライト文言が表示される', () => {
    render(<AppFooter />);
    expect(
      screen.getByText('© 2025 HarmoNet. All rights reserved.')
    ).toBeInTheDocument();
  });

  it('T-C04-02: セマンティックHTMLが使用される', () => {
    render(<AppFooter />);
    const footer = screen.getByRole('contentinfo');
    expect(footer).toBeInTheDocument();
    expect(footer).toHaveAttribute('aria-label', 'フッター領域');
  });

  it('T-C04-03: カスタムクラスが適用される', () => {
    render(<AppFooter className="custom-class" />);
    const footer = screen.getByRole('contentinfo');
    expect(footer).toHaveClass('custom-class');
  });

  it('T-C04-04: testIdが適用される', () => {
    render(<AppFooter testId="custom-footer" />);
    expect(screen.getByTestId('custom-footer')).toBeInTheDocument();
  });

  it('T-C04-05: 固定スタイルが適用される', () => {
    render(<AppFooter />);
    const footer = screen.getByRole('contentinfo');
    expect(footer).toHaveClass('fixed', 'bottom-0', 'bg-white');
  });
});
```

---

## ch07 Storybook構成

### 7.1 ストーリー構成

| ストーリー名 | 内容 |
|------------|------|
| **Default** | デフォルト状態（日本語） |
| **English** | 英語表示 |
| **Chinese** | 中国語表示 |
| **CustomClass** | カスタムクラス適用例 |

### 7.2 Storybookコード例

```typescript
// src/components/common/AppFooter/AppFooter.stories.tsx

import type { Meta, StoryObj } from '@storybook/react';
import { AppFooter } from './AppFooter';
import { StaticI18nProvider } from '@/components/common/StaticI18nProvider';

const meta: Meta<typeof AppFooter> = {
  title: 'Common/AppFooter',
  component: AppFooter,
  decorators: [
    (Story, context) => (
      <StaticI18nProvider currentLocale={context.args.locale || 'ja'}>
        <div className="min-h-screen bg-gray-50 pb-20">
          <div className="p-8">
            <p className="text-gray-600">
              画面コンテンツ（スクロールして下部のフッターを確認）
            </p>
          </div>
          <Story />
        </div>
      </StaticI18nProvider>
    ),
  ],
  parameters: {
    layout: 'fullscreen',
  },
};

export default meta;
type Story = StoryObj<typeof AppFooter>;

export const Default: Story = {
  args: {
    locale: 'ja',
  },
};

export const English: Story = {
  args: {
    locale: 'en',
  },
};

export const Chinese: Story = {
  args: {
    locale: 'zh',
  },
};

export const CustomClass: Story = {
  args: {
    className: 'bg-blue-50',
  },
};
```

### 7.3 翻訳辞書の準備

```json
// public/locales/ja/common.json
{
  "common": {
    "copyright": "© 2025 HarmoNet. All rights reserved."
  }
}

// public/locales/en/common.json
{
  "common": {
    "copyright": "© 2025 HarmoNet. All rights reserved."
  }
}

// public/locales/zh/common.json
{
  "common": {
    "copyright": "© 2025 HarmoNet. 版权所有。"
  }
}
```

---

## ch08 今後の拡張

### 8.1 Phase 2以降の拡張予定

| 拡張項目 | 内容 | 実装時期 |
|---------|------|---------|
| **バージョン表示** | アプリバージョン番号の追加表示 | Phase 2 |
| **リンク追加** | プライバシーポリシー・利用規約へのリンク | Phase 2 |
| **SNSリンク** | ソーシャルメディアアイコン追加 | Phase 3 |
| **多言語切替** | フッター内言語切替ボタン（オプション） | Phase 3 |

### 8.2 バージョン表示の設計メモ

```typescript
// Phase 2: バージョン表示追加イメージ

export const AppFooter: React.FC<AppFooterProps> = ({
  showVersion = false,
  version = '1.0.0',
}) => {
  const { t } = useI18n();

  return (
    <footer className="...">
      <div className="flex items-center gap-4">
        <p>{t('common.copyright')}</p>
        {showVersion && (
          <span className="text-xs text-gray-400">v{version}</span>
        )}
      </div>
    </footer>
  );
};
```

### 8.3 リンク追加の設計メモ

```typescript
// Phase 2: リンク追加イメージ

<footer className="...">
  <div className="flex items-center gap-4">
    <p>{t('common.copyright')}</p>
    <a href="/privacy" className="text-xs text-blue-600 hover:underline">
      {t('common.privacy')}
    </a>
    <a href="/terms" className="text-xs text-blue-600 hover:underline">
      {t('common.terms')}
    </a>
  </div>
</footer>
```

### 8.4 制約事項

- 現在のMVP版では**コピーライト表示のみ**
- バージョン表示・リンクはPhase 2で実装
- SNSリンクはPhase 3で実装

---

## 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `Claude実行指示書_ch04_AppFooter_C-04_v1.0.md` | 本設計書の作成指示書 |
| `ch03_StaticI18nProvider_v1.0.md` | C-03 StaticI18nProvider設計書 |
| `ch01_AppHeader_v1.1.md` | C-01 AppHeader設計書 |
| `common-design-system_v1.1.md` | HarmoNet Design System |
| `harmonet-naming-matrix_v2.0.md` | 命名規則マトリクス |
| `common-footer_v1.1.md` | フッター全体設計（参考） |

---

**文書管理**
- 文書ID: HARMONET-COMPONENT-C04-APPFOOTER
- バージョン: 1.0
- 作成日: 2025-11-09
- 承認者: TKD
- 次工程: Windsurf実装指示書作成（`Windsurf実行指示書_ch04_AppFooter_C-04_v1.0.md`）
