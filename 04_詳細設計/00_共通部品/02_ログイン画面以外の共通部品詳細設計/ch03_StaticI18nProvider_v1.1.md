# HarmoNet 詳細設計書 - StaticI18nProvider (C-03) v1.1

**Document ID:** HARMONET-COMPONENT-C03-STATICI18NPROVIDER**
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-09
**Updated:** 2025-11-16
**Component ID:** C-03
**Component Name:** StaticI18nProvider
**Design System:** HarmoNet Design System v1.1

---

## ch01 概要

### 1.1 目的

StaticI18nProvider（C-03）は、HarmoNet アプリケーション全体で使用される **静的多言語辞書ローダ + ロケール Context Provider** である。
next-intl に依存せず、**独自 JSON 辞書（public/locales/...）** を使用して UI 文言を即時切り替える仕組みを提供する。

本 v1.1 は、以下の最新仕様を反映した全面更新版となる：

* 技術スタック v4.3（Next.js 16 / React 19）への完全準拠
* LanguageSwitch v1.1（C-02）との双方向整合の確立
* currentLocale Props 方式を廃止し、**Provider 主導の locale 管理へ統一**
* Logger 設計 v1.1 に基づき「ログ非対象」方針を明文化
* ディレクトリ構成 v1.0 にあわせた import / ファイル体系の明確化

### 1.2 役割

| 役割            | 内容                                                   |
| ------------- | ---------------------------------------------------- |
| **辞書ロード**     | `/public/locales/{locale}/common.json` を fetch してロード |
| **Context提供** | `locale` / `setLocale` / `t()` を子コンポーネントへ提供          |
| **フォールバック**   | 辞書ロード失敗時は ja（日本語）へ自動フォールバック                          |
| **永続化**       | localStorage へ最終選択ロケールを保存                            |

### 1.3 設計方針

```
✓ next-intl 依存なし
✓ ルートレイアウト（app/layout.tsx）に静的配置する
✓ 多段キーの翻訳辞書に対応（common.submit など）
✓ フォールバックは ja を優先
✓ locale の更新は Provider 主導
```

---

## ch02 依存関係

### 2.1 コンポーネント階層（最新構成）

```
app/layout.tsx
└─ StaticI18nProvider (C-03)
    └─ AppHeader (C-01)
        └─ LanguageSwitch (C-02)
    └─ {children}
```

### 2.2 データフロー

```
LanguageSwitch
    ↓ setLocale()
StaticI18nProvider
    ↓ 辞書再ロード
全子コンポーネント
    ↓ useI18n() → t(key)
```

### 2.3 外部依存

| ライブラリ        | 用途                          |
| ------------ | --------------------------- |
| React 19     | 状態管理 / Context              |
| Tailwind CSS | UI側依存（本 Provider 自体は視覚要素なし） |

---

## ch03 Props 定義（v1.1 更新）

StaticI18nProvider は、**currentLocale props 方式を廃止**し、完全に Provider 主導で locale を管理する。

### 3.1 型定義（更新後）

```ts
export type Locale = 'ja' | 'en' | 'zh';

export interface StaticI18nProviderProps {
  children: React.ReactNode;
}
```

### 3.2 Context 型

```ts
export interface I18nContextType {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string) => string;
}
```

---

## ch04 UI 構成

StaticI18nProvider は視覚要素を持たないロジック部品であり、UI セクションは仕様のみ記載する。

```
<StaticI18nProvider>
  {children}
</StaticI18nProvider>
```

* アクセシビリティ属性は不要（DOM を生成しないため）
* 翻訳結果のマークアップは子コンポーネント側に委譲

---

## ch05 ロジック構造（v1.1 最新仕様）

### 5.1 実装コード（全面修正版）

```tsx
'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import type { Locale, StaticI18nProviderProps, I18nContextType, Translations } from './StaticI18nProvider.types';

export const I18nContext = React.createContext<I18nContextType | null>(null);

export const StaticI18nProvider: React.FC<StaticI18nProviderProps> = ({ children }) => {
  const fallbackLocale: Locale = 'ja';

  const [locale, setLocaleState] = useState<Locale>(fallbackLocale);
  const [translations, setTranslations] = useState<Translations>({});

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next);
    if (typeof window !== 'undefined') {
      localStorage.setItem('selectedLanguage', next);
    }
  }, []);

  /** 辞書ロード */
  const loadTranslations = async (target: Locale) => {
    try {
      const res = await fetch(`/locales/${target}/common.json`);
      if (!res.ok) throw new Error('LOAD_FAIL');
      const data = await res.json();
      setTranslations(data);
      setLocale(target);
    } catch (err) {
      console.error('[i18n] Failed to load dictionary:', target, err);
      if (target !== fallbackLocale) {
        await loadTranslations(fallbackLocale);
      }
    }
  };

  /** 初回マウント */
  useEffect(() => {
    const saved = (typeof window !== 'undefined' && localStorage.getItem('selectedLanguage')) as Locale | null;
    const initial = saved || fallbackLocale;
    loadTranslations(initial);
  }, []);

  /** locale の変更を監視して辞書再ロード */
  useEffect(() => {
    loadTranslations(locale);
  }, [locale]);

  /** 翻訳関数 */
  const t = useMemo(() => {
    return (key: string): string => {
      const path = key.split('.');
      let cur: any = translations;

      for (const k of path) {
        if (cur && typeof cur === 'object' && k in cur) {
          cur = cur[k];
        } else {
          console.warn('[i18n] Missing key:', key);
          return key;
        }
      }

      return typeof cur === 'string' ? cur : key;
    };
  }, [translations]);

  const ctx: I18nContextType = useMemo(
    () => ({ locale, setLocale, t }),
    [locale, t, setLocale]
  );

  return <I18nContext.Provider value={ctx}>{children}</I18nContext.Provider>;
};
```

### 5.2 処理フロー

```
1. 初期 locale を localStorage → fallback の順に決定
2. /locales/${locale}/common.json を fetch して辞書ロード
3. translations を Context にセット
4. t(key) による多段キー解決
5. setLocale(locale) で即時言語切替
6. AppHeader / LanguageSwitch / 全 UI が自動更新
```

### 5.3 エラーハンドリング

| ケース                   | 対応                                    |
| --------------------- | ------------------------------------- |
| 辞書ロード失敗               | console.error + fallbackLocale（ja）へ切替 |
| 翻訳キー未存在               | console.warn + key を返却                |
| Provider 外で useI18n() | Error throw（責務外使用防止）                  |

---

## ch06 テスト観点（v1.1 準拠）

### 6.1 Jest + RTL

| ID       | テスト観点 | 期待結果              |
| -------- | ----- | ----------------- |
| T-C03-01 | 初期表示  | locale=ja、辞書ロード完了 |
