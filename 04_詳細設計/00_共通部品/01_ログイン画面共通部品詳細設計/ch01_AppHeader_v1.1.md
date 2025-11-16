# ch01: AppHeader コンポーネント詳細設計書 v1.1

**Document ID:** HNM-LOGIN-COMMON-C01-APPHEADER
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-09
**Updated:** 2025-11-16
**Component ID:** C-01
**Component Name:** AppHeader
**Design System:** HarmoNet Design System v1

---

## 1. 概要

### 1.1 目的

AppHeader（C-01）は、HarmoNet アプリケーションの **全画面共通ヘッダーコンポーネント** である。
ログイン画面および認証後画面の両方で利用され、画面上部にロゴと言語切替（LanguageSwitch）を配置し、認証後画面では通知アイコンを追加表示することで、

* アプリケーション全体のブランド一貫性
* 多言語対応の入口
* 将来の通知機能との連携

を担う。

本コンポーネントは **レイアウトと簡易なインタラクションのみ** を担当し、認証状態の取得・通知件数の取得などのビジネスロジックは親レイアウトまたは他コンポーネントに委譲する。

### 1.2 配置位置

* **位置**: 画面最上部（固定表示）
* **高さ**: 60px（固定）
* **z-index**: 1000（AppFooter・FooterShortcutBar より上位）
* **レイアウト**: ルートレイアウト（`app/layout.tsx`） または各ページレイアウトの直下に配置

### 1.3 表示バリエーション

| バリエーション           | 表示要素               | 適用画面    |
| ----------------- | ------------------ | ------- |
| **login**         | ロゴ + 言語切替          | ログイン画面  |
| **authenticated** | ロゴ + 通知アイコン + 言語切替 | 認証後の全画面 |

### 1.4 関連ドキュメント（最新確認）

* `Harmonet-technical-stack-definition_v4.3.md`
* `HarmoNet 詳細設計書 - LoginPage (A-00) v1.2`
* `HarmoNet 詳細設計書 - MagicLinkForm (A-01) v1.3`
* `HarmoNet 詳細設計書 - PasskeyAuthTrigger (A-02) v1.3`
* `HarmoNet 詳細設計書 - StaticI18nProvider (C-03) v1.0`
* `HarmoNet 共通ログユーティリティ 詳細設計書 v1.1`

本 v1.1 は上記ドキュメントとの整合を前提としており、技術スタック・ディレクトリ構成・ログ設計に関する記述を最新仕様に合わせて更新している。

---

## 2. 技術仕様

### 2.1 技術スタック

| 項目       | 技術                        | バージョン / 備考      |
| -------- | ------------------------- | --------------- |
| フレームワーク  | Next.js                   | 16.x            |
| UI ライブラリ | React                     | 19.x            |
| スタイリング   | Tailwind CSS              | 3.4.x           |
| 多言語対応    | StaticI18nProvider (C-03) | 独自 i18n Context |
| アイコン     | （暫定）絵文字 / lucide-react    | 通知アイコン置き換え余地あり  |

> v1.0 で記載されていた `next-intl` 依存は廃止し、HarmoNet 共通部品である StaticI18nProvider (C-03) を前提とする。AppHeader 自身は翻訳文言を直接扱わないため、i18n との結合は最小限である。

### 2.2 ファイル構成

フロントエンド公式ディレクトリガイドライン v1.0 に準拠する。

```text
src/
  components/
    common/
      AppHeader/
        AppHeader.tsx          # メインコンポーネント
        AppHeader.types.ts     # 型定義
        AppHeader.test.tsx     # テストコード
        AppHeader.stories.tsx  # Storybook
        index.ts               # エクスポート
```

import パス規約：

```ts
import { AppHeader } from '@/src/components/common/AppHeader/AppHeader';
```

---

## 3. Props 定義

### 3.1 インターフェース

```ts
// src/components/common/AppHeader/AppHeader.types.ts

/**
 * AppHeader コンポーネントの Props
 */
export interface AppHeaderProps {
  /**
   * 表示バリエーション
   * - `login`: ログイン画面用（通知アイコン非表示）
   * - `authenticated`: 認証後画面用（通知アイコン表示）
   * @default 'login'
   */
  variant?: 'login' | 'authenticated';

  /**
   * 追加 CSS クラス
   * 画面レイアウト側で上書き・拡張したい Tailwind クラスを指定可能。
   */
  className?: string;

  /**
   * テスト用 data-testid
   * E2E / RTL で要素を特定するための ID。
   * @default 'app-header'
   */
  testId?: string;
}
```

### 3.2 デフォルト値

```ts
const DEFAULT_TEST_ID = 'app-header';
```

* `variant` はコンポーネント引数のデフォルト値で `login` を指定する。
* `testId` が未指定の場合は `DEFAULT_TEST_ID` を使用する。

---

## 4. コンポーネント構造

### 4.1 レイアウト構成

```
┌─────────────────────────────────────────────────┐
│  [HarmoNetロゴ]              [🔔] [言語切替 JA/EN/中文] │  高さ: 60px
└─────────────────────────────────────────────────┘
```

### 4.2 要素配置

| 要素             | 位置                      | 表示条件                          |
| -------------- | ----------------------- | ----------------------------- |
| HarmoNet ロゴ    | 左端（padding-left: 20px）  | 常時表示                          |
| 通知アイコン         | 右端から 2 番目               | `variant === 'authenticated'` |
| LanguageSwitch | 右端（padding-right: 20px） | 常時表示                          |

---

## 5. 実装例

### 5.1 コンポーネント本体

```tsx
// src/components/common/AppHeader/AppHeader.tsx

'use client';

import React from 'react';
import { LanguageSwitch } from '@/src/components/common/LanguageSwitch/LanguageSwitch';
import type { AppHeaderProps } from './AppHeader.types';

export const AppHeader: React.FC<AppHeaderProps> = ({
  variant = 'login',
  className = '',
  testId = 'app-header',
}) => {
  return (
    <header
      className={[
        'fixed top-0 left-0 right-0',
        'h-[60px]',
        'bg-white',
        'border-b border-gray-200',
        'z-[1000]',
        'flex items-center justify-between',
        'px-5',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      data-testid={testId}
      role="banner"
    >
      {/* ロゴ領域 */}
      <div className="flex items-center">
        <img
          src="/images/logo.svg"
          alt="HarmoNet"
          className="h-8"
          data-testid={`${testId}-logo`}
        />
      </div>

      {/* 右側要素群 */}
      <div className="flex items-center gap-4">
        {/* 通知アイコン（認証後のみ） */}
        {variant === 'authenticated' && (
          <button
            type="button"
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
            <span className="text-2xl" aria-hidden="true">
              🔔
            </span>
            {/* 未読バッジ（将来拡張） */}
            {/* <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" /> */}
          </button>
        )}

        {/* 言語切替（C-02） */}
        <LanguageSwitch testId={`${testId}-language-switch`} />
      </div>
    </header>
  );
};

AppHeader.displayName = 'AppHeader';
```

### 5.2 エクスポート

```ts
// src/components/common/AppHeader/index.ts

export { AppHeader } from './AppHeader';
export type { AppHeaderProps } from './AppHeader.types';
```

---

## 6. スタイリング仕様

### 6.1 基本スタイル

| 項目      | 値                   | 備考                         |
| ------- | ------------------- | -------------------------- |
| 高さ      | 60px                | スマートフォン・PC 共通              |
| 背景色     | `#FFFFFF`           | HarmoNet 基本背景色             |
| 下部ボーダー  | 1px solid `#E5E7EB` | Tailwind `border-gray-200` |
| 左右パディング | 20px (`px-5`)       |                            |
| z-index | 1000                | AppFooter (900) より上        |

### 6.2 ロゴスタイル

| 項目     | 値            |
| ------ | ------------ |
| 高さ     | 32px (`h-8`) |
| 幅      | 自動調整         |
| alt 属性 | "HarmoNet"   |

### 6.3 通知アイコンスタイル

| 項目       | 値                                  |
| -------- | ---------------------------------- |
| 要素サイズ    | 40px × 40px (`w-10 h-10`)          |
| アイコンフォント | `text-2xl`                         |
| ホバー時背景色  | `#F9FAFB` (`hover:bg-gray-100` 近似) |
| 角丸       | 8px (`rounded-lg`)                 |

### 6.4 レスポンシブ対応

* ルートレイアウト側で `max-w-[768px]` などを指定し、コンテンツ幅を制御する。
* AppHeader 自体は幅いっぱいに伸びるが、アプリ全体のコンテナで中央寄せレイアウトとする。

---

## 7. アクセシビリティ

### 7.1 セマンティック HTML

```html
<header role="banner">
  <!-- ヘッダー内容 -->
</header>
```

* 画面ランドマークとして `role="banner"` を付与し、スクリーンリーダーによるナビゲーションを容易にする。

### 7.2 ARIA 属性

| 要素     | 属性            | 値       | 意味           |
| ------ | ------------- | ------- | ------------ |
| 通知ボタン  | `aria-label`  | "通知を表示" | ボタン用途の明示     |
| 通知アイコン | `aria-hidden` | true    | 装飾目的であることを明示 |

### 7.3 キーボード操作

* Tab キーで通知ボタン → LanguageSwitch の順にフォーカスが移動する。
* Enter / Space キーで通知ボタンを押下できる。

---

## 8. 状態管理

AppHeader は **Stateless な Presentational Component** として実装し、内部状態を持たない。

* 表示切替は Props `variant` によってのみ制御する。
* 通知件数・未読状態など、ビジネスロジックに関わる情報は親側で管理し、将来的に必要になった場合は別コンポーネント（例：NotificationBell）として差し替える。

---

## 9. テスト仕様

### 9.1 単体テスト（Jest + React Testing Library）

主なテスト観点：

1. **login バリアント**

   * ロゴと言語切替が表示されること。
   * 通知アイコンが表示されないこと。
2. **authenticated バリアント**

   * ロゴ・通知アイコン・言語切替がすべて表示されること。
3. **セマンティック HTML**

   * `role="banner"` を持つ `<header>` が 1 つ存在すること。
4. **testId**

   * `testId` で指定した data-testid が適切に付与されていること。

テストコード例（概略）：

```ts
import { render, screen } from '@testing-library/react';
import { AppHeader } from './AppHeader';

describe('AppHeader', () => {
  it('login バリアントでは通知アイコンを表示しない', () => {
    render(<AppHeader variant="login" />);

    expect(screen.getByAltText('HarmoNet')).toBeInTheDocument();
    expect(screen.getByTestId('app-header-language-switch')).toBeInTheDocument();
    expect(screen.queryByTestId('app-header-notification')).toBeNull();
  });

  it('authenticated バリアントでは通知アイコンを表示する', () => {
    render(<AppHeader variant="authenticated" />);

    expect(screen.getByTestId('app-header-notification')).toBeInTheDocument();
  });

  it('セマンティック HTML が設定されている', () => {
    render(<AppHeader />);
    expect(screen.getByRole('banner')).toBeInTheDocument();
  });
});
```

---

## 10. ログ出力方針（Logger 考慮）

AppHeader 自体は「画面の共通レイアウト要素」であり、通常はログ出力を行わない。
ログ設計 v1.1 におけるイベント ID は主に **ログイン処理や API 呼び出し** に対して定義されており、ヘッダー表示そのものはログ対象外である。

ただし、将来的に通知アイコンから直接アクション（お知らせ一覧表示・既読処理等）を行う場合には、

* `auth.login.*` ではなく `ui.header.notification_*` 系のイベントとして
* 共通ログユーティリティ `logInfo` / `logError` を通じて

ログ出力を行う。

設計上の方針：

* v1.1 時点では **AppHeader 内から共通ログユーティリティを直接呼び出さない**。
* 通知アイコン押下に紐づくビジネスイベントは、親コンポーネント（例：`NotificationMenu` コンテナ）でハンドリングし、そちら側でログを出力する。
* これにより AppHeader は UI レイアウト責務に限定され、ログロジックと密結合しない。

---

## 11. エラーハンドリング

AppHeader が直接外部 API を呼び出すことはないため、エラー発生ポイントは限定的である。

1. **ロゴ画像読み込みエラー**

   * `onError` ハンドラでフォールバック画像に差し替える。
2. **LanguageSwitch / StaticI18nProvider の例外**

   * これらはそれぞれの詳細設計に従い、上位の ErrorBoundary で捕捉する。

推奨実装例：

```tsx
<img
  src="/images/logo.svg"
  alt="HarmoNet"
  onError={(e) => {
    e.currentTarget.src = '/images/logo-fallback.png';
  }}
/>
```

アプリケーション全体としては、ルートレイアウトやページレベルで ErrorBoundary を設置し、
AppHeader を含む共通部品の例外を一括で捕捉・ログ出力（共通ログユーティリティ経由）する。

---

## 12. 関連ドキュメント

| ドキュメント名                                           | 説明                   |
| ------------------------------------------------- | -------------------- |
| `common-header_v1.1.md`                           | ヘッダー領域の共通仕様          |
| `HarmoNet 詳細設計書 - StaticI18nProvider (C-03) v1.0` | i18n コンテキスト提供コンポーネント |
| `HarmoNet 詳細設計書 - LanguageSwitch (C-02) v1.0`     | 言語切替 UI コンポーネント      |
| `harmonet-frontend-directory-guideline_v1.0.md`   | フロントエンド公式ディレクトリ構成    |
| `harmonet-technical-stack-definition_v4.3.md`     | 技術スタック定義             |
| `HarmoNet 共通ログユーティリティ 詳細設計書_v1.1.md`              | フロントエンド共通ログ出力仕様      |

---

## 13. 改訂履歴

| バージョン    | 日付         | 更新者       | 更新内容                                                                           |
| -------- | ---------- | --------- | ------------------------------------------------------------------------------ |
| v1.0     | 2025-11-09 | Claude    | 初版作成                                                                           |
| **v1.1** | 2025-11-16 | Tachikoma | 技術スタック v4.3 / StaticI18nProvider / ログ設計 v1.1 に整合するよう全面確認・必要箇所を更新。Logger 方針を追記。 |

---

**Document ID:** HNM-LOGIN-COMMON-C01-APPHEADER
**Status:** Draft（v1.1 更新案／TKD レビュー待ち）
