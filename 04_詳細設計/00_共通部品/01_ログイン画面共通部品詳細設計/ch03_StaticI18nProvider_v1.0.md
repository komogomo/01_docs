# HarmoNet 詳細設計書 - StaticI18nProvider (C-03) v1.0

**Document ID:** HARMONET-COMPONENT-C03-STATICI18NPROVIDER  
**Version:** 1.0  
**Created:** 2025-11-09  
**Component ID:** C-03  
**Component Name:** StaticI18nProvider  
**Category:** 共通部品（Common Components）  
**Difficulty:** 3（中）  
**Safe Steps:** 4  

---

## ch01 概要

### 1.1 目的

StaticI18nProviderは、HarmoNetアプリケーション全体で使用される**静的多言語辞書ローダおよびロケールコンテキスト提供**コンポーネントです。next-intlに依存せず、独自のReact Contextで翻訳機能を提供します。

### 1.2 役割

| 役割 | 内容 |
|------|------|
| **辞書ロード** | `/public/locales/{locale}/common.json`から静的に辞書を読み込み |
| **Context提供** | `I18nContext`で`locale`と`t(key)`関数を配布 |
| **フォールバック** | 辞書読み込み失敗時は日本語（ja）をデフォルト使用 |
| **永続化** | localStorage へのロケール保存（任意） |

### 1.3 前提条件

- **親コンポーネント:** ルートレイアウト（`app/layout.tsx`）
- **連携コンポーネント:** LanguageSwitch (C-02) から `currentLocale` props を受け取る
- **フレームワーク:** Next.js 16.0.1（App Router）
- **依存ライブラリ:** なし（React標準機能のみ）

### 1.4 設計方針

```
✅ next-intl完全非依存
✅ 独自I18nContext提供
✅ C-02とはprops連携のみ（Context共有なし）
✅ JSON静的インポートによる辞書ロード
✅ フォールバック機能（ja優先）
```

---

## ch02 依存関係

### 2.1 コンポーネント階層

```
app/layout.tsx（ルート）
└─ StaticI18nProvider (C-03) ← 本コンポーネント
    └─ AppHeader (C-01)
        └─ LanguageSwitch (C-02)
```

### 2.2 データフロー

```
LanguageSwitch (C-02)
    ↓ ユーザーが言語選択
AppHeader (C-01)
    ↓ currentLocale props
StaticI18nProvider (C-03)
    ↓ useEffect で辞書再ロード
    ↓ I18nContext 更新
全子コンポーネント
    ↓ useI18n() で t(key) 使用
```

### 2.3 外部依存

| ライブラリ | バージョン | 用途 |
|-----------|-----------|------|
| `react` | ^19.0.0 | Context / useState / useEffect |
| （なし） | - | next-intl不使用、独自実装 |

---

## ch03 Props定義

### 3.1 TypeScript型定義

```typescript
// src/components/common/StaticI18nProvider/StaticI18nProvider.types.ts

export type Locale = 'ja' | 'en' | 'zh';

export interface StaticI18nProviderProps {
  /**
   * 初期ロケール
   * LanguageSwitch から渡される現在の選択言語
   */
  currentLocale?: Locale;

  /**
   * 子コンポーネント
   */
  children: React.ReactNode;
}

export interface I18nContextType {
  /**
   * 現在のロケール
   */
  locale: Locale;

  /**
   * 翻訳関数
   * @param key - 翻訳キー（例: "common.submit"）
   * @returns 翻訳済み文字列
   */
  t: (key: string) => string;
}

export interface Translations {
  [key: string]: string | Translations;
}
```

### 3.2 Context構造

```typescript
export const I18nContext = React.createContext<I18nContextType>({
  locale: 'ja',
  t: (key: string) => key, // フォールバック
});
```

### 3.3 カスタムHook

```typescript
export const useI18n = (): I18nContextType => {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error('useI18n must be used within StaticI18nProvider');
  }
  return context;
};
```

---

## ch04 UI構成

### 4.1 視覚要素

StaticI18nProviderは**視覚要素を持たない**ロジック専用コンポーネントです。

```typescript
// UIなし、Providerのみ
<StaticI18nProvider currentLocale={locale}>
  {children}
</StaticI18nProvider>
```

### 4.2 アクセシビリティ

- 表示要素がないため、ARIA属性は不要
- 翻訳後のコンテンツは各子コンポーネントで適切にマークアップ

---

## ch05 ロジック構造

### 5.1 実装コード

```typescript
// src/components/common/StaticI18nProvider/StaticI18nProvider.tsx

'use client';

import React, { useState, useEffect, useMemo } from 'react';
import type {
  StaticI18nProviderProps,
  I18nContextType,
  Locale,
  Translations,
} from './StaticI18nProvider.types';

export const I18nContext = React.createContext<I18nContextType>({
  locale: 'ja',
  t: (key: string) => key,
});

export const StaticI18nProvider: React.FC<StaticI18nProviderProps> = ({
  currentLocale = 'ja',
  children,
}) => {
  const [locale, setLocale] = useState<Locale>(currentLocale);
  const [translations, setTranslations] = useState<Translations>({});

  // 辞書ロード関数
  const loadTranslations = async (targetLocale: Locale) => {
    try {
      const response = await fetch(`/locales/${targetLocale}/common.json`);
      if (!response.ok) {
        throw new Error(`Failed to load ${targetLocale} translations`);
      }
      const data = await response.json();
      setTranslations(data);
      setLocale(targetLocale);

      // localStorageに保存（任意）
      if (typeof window !== 'undefined') {
        localStorage.setItem('selectedLanguage', targetLocale);
      }
    } catch (error) {
      console.error(`Translation load error: ${targetLocale}`, error);
      
      // フォールバック: 日本語を試行
      if (targetLocale !== 'ja') {
        loadTranslations('ja');
      }
    }
  };

  // 初回マウント時
  useEffect(() => {
    // localStorage から復元（優先）
    const savedLocale =
      (typeof window !== 'undefined' &&
        localStorage.getItem('selectedLanguage')) ||
      currentLocale;

    loadTranslations(savedLocale as Locale);
  }, []);

  // currentLocale props 変更検知
  useEffect(() => {
    if (currentLocale !== locale) {
      loadTranslations(currentLocale);
    }
  }, [currentLocale]);

  // 翻訳関数
  const t = useMemo(() => {
    return (key: string): string => {
      const keys = key.split('.');
      let result: any = translations;

      for (const k of keys) {
        if (result && typeof result === 'object' && k in result) {
          result = result[k];
        } else {
          console.warn(`Translation key not found: ${key}`);
          return key; // フォールバック: キーをそのまま返す
        }
      }

      return typeof result === 'string' ? result : key;
    };
  }, [translations]);

  const contextValue = useMemo(
    () => ({ locale, t }),
    [locale, t]
  );

  return (
    <I18nContext.Provider value={contextValue}>
      {children}
    </I18nContext.Provider>
  );
};
```

### 5.2 処理フロー

```
1. 初回マウント
   ↓
2. localStorage から言語取得（あれば）
   ↓
3. fetch(`/locales/${locale}/common.json`)
   ↓
4. 成功 → setTranslations() → Context更新
   ↓
5. 失敗 → ja でリトライ（フォールバック）
   ↓
6. currentLocale props 変更時
   ↓
7. useEffect 発火 → 辞書再ロード → Context更新
   ↓
8. 子コンポーネントで useI18n() → t(key) 使用
```

### 5.3 エラーハンドリング

| エラーケース | 対応 |
|------------|------|
| **辞書ファイル404** | コンソール警告 + ja でリトライ |
| **JSON parse失敗** | catch節で ja フォールバック |
| **翻訳キー不在** | コンソール警告 + キーをそのまま返す |

---

## ch06 テスト観点

### 6.1 Jest + RTL テストケース

| テストID | テスト内容 | 期待結果 |
|---------|-----------|---------|
| **T-C03-01** | 初期表示：デフォルトロケール | locale='ja'、translations読み込み完了 |
| **T-C03-02** | currentLocale変更：ja→en | useEffect発火 → en辞書ロード → Context更新 |
| **T-C03-03** | t()関数：正常キー | 正しい翻訳文字列を返す |
| **T-C03-04** | t()関数：存在しないキー | キーをそのまま返す + 警告ログ |
| **T-C03-05** | 辞書ロード失敗 | ja でフォールバック試行 |
| **T-C03-06** | localStorage保存 | 言語変更時にlocalStorageが更新される |
| **T-C03-07** | useI18n()：Provider外使用 | Error throw |

### 6.2 テストコード例

```typescript
// src/components/common/StaticI18nProvider/StaticI18nProvider.test.tsx

import { render, screen, waitFor } from '@testing-library/react';
import { StaticI18nProvider, useI18n } from './StaticI18nProvider';

// fetch モック
global.fetch = jest.fn((url) => {
  if (url.includes('ja')) {
    return Promise.resolve({
      ok: true,
      json: async () => ({ 'common.submit': '送信' }),
    });
  }
  if (url.includes('en')) {
    return Promise.resolve({
      ok: true,
      json: async () => ({ 'common.submit': 'Submit' }),
    });
  }
  return Promise.reject(new Error('Not found'));
}) as jest.Mock;

const TestComponent = () => {
  const { locale, t } = useI18n();
  return (
    <div>
      <span data-testid="locale">{locale}</span>
      <span data-testid="translation">{t('common.submit')}</span>
    </div>
  );
};

describe('StaticI18nProvider', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  it('T-C03-01: 初期表示デフォルトロケール', async () => {
    render(
      <StaticI18nProvider>
        <TestComponent />
      </StaticI18nProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('locale')).toHaveTextContent('ja');
      expect(screen.getByTestId('translation')).toHaveTextContent('送信');
    });
  });

  it('T-C03-03: t()関数正常動作', async () => {
    render(
      <StaticI18nProvider currentLocale="en">
        <TestComponent />
      </StaticI18nProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('translation')).toHaveTextContent('Submit');
    });
  });
});
```

---

## ch07 Storybook構成

### 7.1 ストーリー構成

| ストーリー名 | 内容 |
|------------|------|
| **Default** | デフォルト状態（ja） |
| **English** | 英語状態（en） |
| **Chinese** | 中国語状態（zh） |
| **WithMissingKey** | 存在しないキーの動作確認 |

### 7.2 Storybookコード例

```typescript
// src/components/common/StaticI18nProvider/StaticI18nProvider.stories.tsx

import type { Meta, StoryObj } from '@storybook/react';
import { StaticI18nProvider, useI18n } from './StaticI18nProvider';

const TestDisplay = () => {
  const { locale, t } = useI18n();
  return (
    <div className="p-4 space-y-2">
      <p>Current Locale: <strong>{locale}</strong></p>
      <p>Translation: {t('common.submit')}</p>
      <p>Missing Key: {t('common.nonexistent')}</p>
    </div>
  );
};

const meta: Meta<typeof StaticI18nProvider> = {
  title: 'Common/StaticI18nProvider',
  component: StaticI18nProvider,
  parameters: {
    layout: 'centered',
  },
};

export default meta;
type Story = StoryObj<typeof StaticI18nProvider>;

export const Default: Story = {
  args: {
    currentLocale: 'ja',
  },
  render: (args) => (
    <StaticI18nProvider {...args}>
      <TestDisplay />
    </StaticI18nProvider>
  ),
};

export const English: Story = {
  args: {
    currentLocale: 'en',
  },
  render: (args) => (
    <StaticI18nProvider {...args}>
      <TestDisplay />
    </StaticI18nProvider>
  ),
};

export const Chinese: Story = {
  args: {
    currentLocale: 'zh',
  },
  render: (args) => (
    <StaticI18nProvider {...args}>
      <TestDisplay />
    </StaticI18nProvider>
  ),
};
```

---

## ch08 今後の拡張

### 8.1 Phase 2以降の拡張予定

| 拡張項目 | 内容 | 実装時期 |
|---------|------|---------|
| **動的翻訳連携** | 投稿本文など動的コンテンツの翻訳API統合 | Phase 2 |
| **翻訳キャッシュ** | Redis/Supabaseでの翻訳結果キャッシュ | Phase 2 |
| **画面別辞書** | `common.json`以外に画面固有辞書を追加 | Phase 2 |
| **プレースホルダー対応** | `t('key', { name: 'value' })`形式のサポート | Phase 2 |

### 8.2 辞書構造拡張の設計メモ

```typescript
// Phase 2: 画面別辞書対応イメージ

const loadTranslations = async (
  targetLocale: Locale,
  namespace: string = 'common'
) => {
  const response = await fetch(
    `/locales/${targetLocale}/${namespace}.json`
  );
  // ...
};

// 使用例
const { t } = useI18n('board'); // 掲示板専用辞書
t('board.post.title'); // → 「投稿タイトル」
```

### 8.3 プレースホルダー対応の設計メモ

```typescript
// Phase 2: プレースホルダー機能追加イメージ

t: (key: string, params?: Record<string, string>) => {
  let result = getTranslation(key);
  
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      result = result.replace(`{${k}}`, v);
    });
  }
  
  return result;
};

// 使用例
t('welcome.greeting', { name: '田中' }); 
// → 「こんにちは、田中さん」
```

### 8.4 制約事項

- 現在のMVP版では**静的辞書（common.json）のみ**対応
- 動的コンテンツ翻訳はPhase 2で実装
- プレースホルダー機能はPhase 2で実装

---

## 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `Claude実行指示書-ch03-StaticI18nProvider-C-03_v1.1.md` | 本設計書の作成指示書 |
| `ch02_LanguageSwitch_v1.1.md` | C-02 LanguageSwitch設計書 |
| `common-i18n_v1.0.md` | i18n全体設計書 |
| `harmonet-naming-matrix_v2.0.md` | 命名規則マトリクス |
| `harmonet-technical-stack-definition_v3.7.md` | 技術スタック定義（Next.js 15記載、実環境16.0.1） |

---

**文書管理**
- 文書ID: HARMONET-COMPONENT-C03-STATICI18NPROVIDER
- バージョン: 1.0
- 作成日: 2025-11-09
- 承認者: TKD
- 次工程: Windsurf実装指示書作成（`Windsurf実行指示書_ch03_StaticI18nProvider_C-03_v1.0.md`）
