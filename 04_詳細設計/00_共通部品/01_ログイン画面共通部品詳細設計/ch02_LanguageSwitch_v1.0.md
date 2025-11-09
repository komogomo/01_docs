# ch02: LanguageSwitch コンポーネント詳細設計書 v1.0

**Document ID:** HNM-LOGIN-COMMON-C02-LANGUAGESWITCH  
**Version:** 1.0  
**Created:** 2025-11-09  
**Component ID:** C-02  
**Component Name:** LanguageSwitch  
**Design System:** HarmoNet Design System v1  

---

## 1. 概要

### 1.1 目的

ログイン画面およびログイン後の全画面で使用する言語切替UIコンポーネント。  
ユーザーが日本語(JA) / 英語(EN) / 中国語(ZH)を選択でき、画面全体の翻訳を即座に切り替える。

### 1.2 主要機能

1. **現在言語の表示**: JA / EN / CN の表示
2. **ドロップダウンメニュー**: 3言語の選択肢を表示
3. **言語切替処理**: next-intl による静的翻訳辞書の切替
4. **状態永続化**: localStorage + user_profiles への保存

### 1.3 配置位置

- **位置**: AppHeader右端（通知アイコンの右隣）
- **表示**: 全画面共通（ログイン画面含む）

---

## 2. 依存関係

### 2.1 親コンポーネント

| コンポーネント | 関係 | 備考 |
|--------------|------|------|
| **AppHeader** (C-01) | 親 | ヘッダー内に配置 |

### 2.2 連携コンポーネント

| コンポーネント | 関係 | 備考 |
|--------------|------|------|
| **StaticI18nProvider** (C-03) | 協調 | 翻訳コンテキスト提供 |

### 2.3 外部ライブラリ

| ライブラリ | バージョン | 用途 |
|-----------|-----------|------|
| **next-intl** | 3.x | 静的翻訳管理 |
| **@headlessui/react** | 2.x | アクセシブルなドロップダウンUI |

---

## 3. Props定義

### 3.1 インターフェース

```typescript
/**
 * LanguageSwitch コンポーネントのProps
 */
export interface LanguageSwitchProps {
  /**
   * 追加CSSクラス
   */
  className?: string;

  /**
   * テスト用ID
   */
  testId?: string;

  /**
   * 言語変更時のコールバック
   * @param locale - 新しい言語コード (ja | en | zh)
   */
  onLanguageChange?: (locale: Locale) => void;
}

/**
 * サポートする言語
 */
export type Locale = 'ja' | 'en' | 'zh';

/**
 * 言語オプション定義
 */
export interface LanguageOption {
  /**
   * 言語コード
   */
  code: Locale;

  /**
   * 表示名（短縮形）
   */
  label: string;

  /**
   * 表示名（完全形）
   */
  fullName: string;

  /**
   * アイコン（絵文字）
   */
  icon: string;
}
```

### 3.2 デフォルト値

```typescript
const defaultProps: Partial<LanguageSwitchProps> = {
  testId: 'language-switch',
  onLanguageChange: undefined,
};
```

### 3.3 言語オプション定義

```typescript
const LANGUAGE_OPTIONS: LanguageOption[] = [
  {
    code: 'ja',
    label: 'JA',
    fullName: '日本語',
    icon: '🇯🇵',
  },
  {
    code: 'en',
    label: 'EN',
    fullName: 'English',
    icon: '🇬🇧',
  },
  {
    code: 'zh',
    label: 'CN',
    fullName: '中文',
    icon: '🇨🇳',
  },
];
```

---

## 4. UI構成

### 4.1 レイアウト構造

```
┌─────────────────┐
│  JA ▼           │  ← ボタン（現在言語 + 下矢印）
└─────────────────┘
        ↓ クリック時
┌─────────────────┐
│ ✓ 日本語 (JA)   │  ← 選択中（チェックマーク + 背景色）
├─────────────────┤
│   English (EN)  │
├─────────────────┤
│   中文 (CN)     │
└─────────────────┘
```

### 4.2 ボタン仕様

| 項目 | 値 |
|------|-----|
| **幅** | 70px |
| **高さ** | 40px |
| **背景色** | 透明（hover時: `#F9FAFB`） |
| **ボーダー** | なし |
| **角丸** | 8px (rounded-lg) |
| **フォントサイズ** | 14px |
| **フォントウェイト** | 600 (Semibold) |
| **テキスト色** | `#6B7280` (gray-600) |

### 4.3 ドロップダウンメニュー仕様

| 項目 | 値 |
|------|-----|
| **幅** | 160px |
| **背景色** | `#FFFFFF` |
| **ボーダー** | 1px solid `#E5E7EB` |
| **影** | `0 4px 6px -1px rgba(0, 0, 0, 0.1)` |
| **角丸** | 8px (rounded-lg) |
| **各項目の高さ** | 40px |
| **ホバー時の背景色** | `#F9FAFB` |
| **選択中の背景色** | `#DBEAFE` (blue-100) |
| **選択中のテキスト色** | `#2563EB` (blue-600) |

---

## 5. ロジック構造

### 5.1 状態管理

```typescript
/**
 * コンポーネント内部状態
 */
interface LanguageSwitchState {
  /**
   * ドロップダウンの開閉状態
   */
  isOpen: boolean;

  /**
   * 現在選択中の言語
   */
  currentLocale: Locale;
}
```

### 5.2 言語切替フロー

```
1. ユーザーがメニューから言語選択
   ↓
2. useRouter().push() でロケール切替
   ↓
3. next-intlが翻訳辞書を切替
   ↓
4. localStorage に保存
   ↓
5. （ログイン中の場合）user_profiles更新
   ↓
6. onLanguageChangeコールバック実行
   ↓
7. 画面全体が新しい言語で再レンダリング
```

### 5.3 永続化処理

```typescript
/**
 * 言語設定を保存
 */
const saveLanguagePreference = async (locale: Locale) => {
  // localStorage に保存（即座）
  localStorage.setItem('selectedLanguage', locale);

  // ログイン中の場合、user_profiles に保存（非同期）
  if (session?.user?.id) {
    try {
      await fetch('/api/users/preferences', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          preferences: {
            language: locale,
          },
        }),
      });
    } catch (error) {
      console.error('Failed to save language preference:', error);
      // エラーは無視（localhostorageには保存済み）
    }
  }
};
```

---

## 6. 実装例

### 6.1 コンポーネント本体

```typescript
// src/components/common/LanguageSwitch/LanguageSwitch.tsx

'use client';

import React, { useState } from 'react';
import { useLocale } from 'next-intl';
import { useRouter, usePathname } from 'next/navigation';
import { Menu } from '@headlessui/react';
import { ChevronDownIcon } from '@heroicons/react/20/solid';
import type { LanguageSwitchProps, Locale, LanguageOption } from './LanguageSwitch.types';

const LANGUAGE_OPTIONS: LanguageOption[] = [
  { code: 'ja', label: 'JA', fullName: '日本語', icon: '🇯🇵' },
  { code: 'en', label: 'EN', fullName: 'English', icon: '🇬🇧' },
  { code: 'zh', label: 'CN', fullName: '中文', icon: '🇨🇳' },
];

export const LanguageSwitch: React.FC<LanguageSwitchProps> = ({
  className = '',
  testId = 'language-switch',
  onLanguageChange,
}) => {
  const locale = useLocale() as Locale;
  const router = useRouter();
  const pathname = usePathname();

  const currentLanguage = LANGUAGE_OPTIONS.find((lang) => lang.code === locale);

  const handleLanguageChange = (newLocale: Locale) => {
    // 1. next-intl でロケール切替
    const newPathname = pathname.replace(`/${locale}`, `/${newLocale}`);
    router.push(newPathname);

    // 2. localStorage に保存
    localStorage.setItem('selectedLanguage', newLocale);

    // 3. コールバック実行
    onLanguageChange?.(newLocale);

    // 4. HTML lang属性更新
    document.documentElement.lang = newLocale;
  };

  return (
    <Menu as="div" className={`relative ${className}`} data-testid={testId}>
      {/* ボタン */}
      <Menu.Button
        className="
          flex items-center gap-1
          px-3 py-2
          text-sm font-semibold text-gray-600
          hover:bg-gray-50
          rounded-lg
          transition-colors
        "
        aria-label="言語を選択"
        data-testid={`${testId}-button`}
      >
        <span>{currentLanguage?.label}</span>
        <ChevronDownIcon className="w-4 h-4" aria-hidden="true" />
      </Menu.Button>

      {/* ドロップダウンメニュー */}
      <Menu.Items
        className="
          absolute right-0 mt-2
          w-40
          bg-white
          border border-gray-200
          rounded-lg
          shadow-lg
          overflow-hidden
          z-50
        "
        data-testid={`${testId}-menu`}
      >
        {LANGUAGE_OPTIONS.map((language) => (
          <Menu.Item key={language.code}>
            {({ active }) => (
              <button
                className={`
                  w-full px-4 py-2
                  text-left text-sm
                  flex items-center justify-between
                  ${active ? 'bg-gray-50' : ''}
                  ${language.code === locale ? 'bg-blue-50 text-blue-600 font-semibold' : 'text-gray-700'}
                `}
                onClick={() => handleLanguageChange(language.code)}
                data-testid={`${testId}-option-${language.code}`}
              >
                <span className="flex items-center gap-2">
                  <span>{language.icon}</span>
                  <span>{language.fullName} ({language.label})</span>
                </span>
                {language.code === locale && (
                  <span className="text-blue-600">✓</span>
                )}
              </button>
            )}
          </Menu.Item>
        ))}
      </Menu.Items>
    </Menu>
  );
};

LanguageSwitch.displayName = 'LanguageSwitch';
```

### 6.2 型定義ファイル

```typescript
// src/components/common/LanguageSwitch/LanguageSwitch.types.ts

export type Locale = 'ja' | 'en' | 'zh';

export interface LanguageOption {
  code: Locale;
  label: string;
  fullName: string;
  icon: string;
}

export interface LanguageSwitchProps {
  className?: string;
  testId?: string;
  onLanguageChange?: (locale: Locale) => void;
}
```

### 6.3 エクスポート

```typescript
// src/components/common/LanguageSwitch/index.ts

export { LanguageSwitch } from './LanguageSwitch';
export type { LanguageSwitchProps, Locale, LanguageOption } from './LanguageSwitch.types';
```

---

## 7. テスト観点

### 7.1 ユニットテスト

```typescript
// src/components/common/LanguageSwitch/LanguageSwitch.test.tsx

import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { LanguageSwitch } from './LanguageSwitch';

// next-intl のモック
jest.mock('next-intl', () => ({
  useLocale: () => 'ja',
}));

jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
  }),
  usePathname: () => '/ja/home',
}));

describe('LanguageSwitch', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('現在の言語を表示', () => {
    render(<LanguageSwitch />);
    expect(screen.getByText('JA')).toBeInTheDocument();
  });

  it('ボタンクリックでメニューを表示', () => {
    render(<LanguageSwitch />);
    
    const button = screen.getByRole('button', { name: /言語を選択/ });
    fireEvent.click(button);

    expect(screen.getByText('日本語 (JA)')).toBeInTheDocument();
    expect(screen.getByText('English (EN)')).toBeInTheDocument();
    expect(screen.getByText('中文 (CN)')).toBeInTheDocument();
  });

  it('選択中の言語にチェックマークを表示', () => {
    render(<LanguageSwitch />);
    
    const button = screen.getByRole('button', { name: /言語を選択/ });
    fireEvent.click(button);

    const jaOption = screen.getByTestId('language-switch-option-ja');
    expect(jaOption).toHaveTextContent('✓');
  });

  it('言語選択時にlocalStorageに保存', async () => {
    render(<LanguageSwitch />);
    
    const button = screen.getByRole('button', { name: /言語を選択/ });
    fireEvent.click(button);

    const enOption = screen.getByTestId('language-switch-option-en');
    fireEvent.click(enOption);

    await waitFor(() => {
      expect(localStorage.getItem('selectedLanguage')).toBe('en');
    });
  });

  it('onLanguageChangeコールバックを実行', async () => {
    const onLanguageChange = jest.fn();
    render(<LanguageSwitch onLanguageChange={onLanguageChange} />);
    
    const button = screen.getByRole('button', { name: /言語を選択/ });
    fireEvent.click(button);

    const enOption = screen.getByTestId('language-switch-option-en');
    fireEvent.click(enOption);

    await waitFor(() => {
      expect(onLanguageChange).toHaveBeenCalledWith('en');
    });
  });
});
```

### 7.2 統合テスト観点

| テスト項目 | 確認内容 |
|-----------|---------|
| **言語切替の即時反映** | 選択後、画面全体の翻訳が変更される |
| **永続化** | ページリロード後も選択言語が保持される |
| **user_profiles連携** | ログイン中、user_profilesに保存される |
| **next-intl連携** | ロケール切替でURLが変更される |

---

## 8. Storybook構成

### 8.1 ストーリー定義

```typescript
// src/components/common/LanguageSwitch/LanguageSwitch.stories.tsx

import type { Meta, StoryObj } from '@storybook/react';
import { LanguageSwitch } from './LanguageSwitch';

const meta: Meta<typeof LanguageSwitch> = {
  title: 'Common/LanguageSwitch',
  component: LanguageSwitch,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof meta>;

// 日本語選択中
export const Japanese: Story = {
  args: {},
};

// 英語選択中（モック）
export const English: Story = {
  args: {},
  parameters: {
    nextIntl: {
      locale: 'en',
    },
  },
};

// 中国語選択中（モック）
export const Chinese: Story = {
  args: {},
  parameters: {
    nextIntl: {
      locale: 'zh',
    },
  },
};

// コールバック付き
export const WithCallback: Story = {
  args: {
    onLanguageChange: (locale) => {
      console.log(`Language changed to: ${locale}`);
    },
  },
};
```

---

## 9. アクセシビリティ

### 9.1 ARIA属性

| 要素 | ARIA属性 | 値 |
|------|---------|-----|
| ボタン | `aria-label` | "言語を選択" |
| ボタン | `aria-haspopup` | "true" |
| ボタン | `aria-expanded` | "true" / "false" |
| メニュー | `role` | "menu" |
| 各オプション | `role` | "menuitem" |

### 9.2 キーボード操作

| キー | 動作 |
|------|------|
| **Enter / Space** | メニューを開く |
| **↓** | 次の言語へ移動 |
| **↑** | 前の言語へ移動 |
| **Enter** | 言語を選択してメニューを閉じる |
| **Esc** | メニューを閉じる |

### 9.3 スクリーンリーダー対応

```typescript
// 言語切替時の通知
<div role="status" aria-live="polite" className="sr-only">
  {`言語を${currentLanguage?.fullName}に切り替えました`}
</div>
```

---

## 10. パフォーマンス考慮

### 10.1 最適化ポイント

1. **メモ化**:
   - `LANGUAGE_OPTIONS`は定数として定義
   - `currentLanguage`は`useMemo`で計算

2. **遅延実行**:
   - user_profiles更新は非同期（画面表示をブロックしない）

3. **バンドルサイズ**:
   - `@headlessui/react`のみを使用（軽量）
   - アイコンは絵文字（外部ライブラリ不要）

---

## 11. エラーハンドリング

### 11.1 想定エラー

| エラー | 対処 |
|--------|------|
| **user_profiles更新失敗** | エラーログ出力、localStorageは保存済みなので継続可能 |
| **無効なlocale** | デフォルト（ja）にフォールバック |
| **next-intl未初期化** | エラー境界でキャッチ |

---

## 12. 今後の拡張

### 12.1 自動翻訳連携構想

将来的に、動的コンテンツ（投稿本文等）の自動翻訳機能と連携:

```typescript
// 言語切替時に動的コンテンツも翻訳
onLanguageChange={(locale) => {
  translateDynamicContent(locale);
}}
```

### 12.2 言語検出機能

初回訪問時、ブラウザ言語設定から自動判定:

```typescript
const detectLanguage = (): Locale => {
  const browserLang = navigator.language.split('-')[0];
  if (['ja', 'en', 'zh'].includes(browserLang)) {
    return browserLang as Locale;
  }
  return 'ja'; // デフォルト
};
```

---

## 13. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-i18n_v1.0.md` | 多言語対応全体仕様 |
| `common-header_v1.1.md` | AppHeader仕様 |
| `common-design-system_v1.1.md` | HarmoNetデザインシステム |
| `common-accessibility_v1.0.md` | アクセシビリティ基準 |
| `ch01_AppHeader_v1.0.md` | 親コンポーネント設計書 |

---

## 14. 改訂履歴

| バージョン | 日付 | 更新者 | 更新内容 |
|-----------|------|--------|---------|
| v1.0 | 2025-11-09 | Claude | 新規作成 |

---

**Document ID:** HNM-LOGIN-COMMON-C02-LANGUAGESWITCH  
**Status:** ✅ Draft  
**Next Review:** Phase9実装開始時
