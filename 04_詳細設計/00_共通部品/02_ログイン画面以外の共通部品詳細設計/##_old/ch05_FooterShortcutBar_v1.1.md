# HarmoNet 詳細設計書 - FooterShortcutBar (C-05) v1.1

**Document ID:** HARMONET-COMPONENT-C05-FOOTERSHORTCUTBAR**
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-09
**Updated:** 2025-11-16
**Component ID:** C-05
**Component Name:** FooterShortcutBar
**Category:** 共通部品（Common Components）
**Design System:** HarmoNet Design System v1.1

---

## ch01 概要

### 1.1 目的

FooterShortcutBar（C-05）は、HarmoNet ログイン後画面の最下部に固定表示され、ユーザー権限に応じた主要機能への **ショートカットナビゲーション** を提供する共通 UI コンポーネントである。

本 v1.1 は以下の最新仕様に完全準拠した全面更新版である：

* 技術スタック v4.3（Next.js 16 / React 19）への整合
* StaticI18nProvider v1.1（C-03）との翻訳仕様統一
* AppHeader / AppFooter / LanguageSwitch v1.1 と密度を揃えた UI 設計
* Logger 設計 v1.1 に基づき「C-05 はログ対象外」方針を明示
* ディレクトリ構成 v1.0（`@/src/components/...`）へ統一
* 旧 v1.0 の全行精査による記述補正

### 1.2 適用範囲

* ログイン後画面の全ページ（Dashboard / Board / Facility / MyPage 等）
* 未認証状態（ログイン画面・メンテナンス画面）には表示しない

### 1.3 UI トーン

```
✓ やさしく・自然・控えめ
✓ Apple カタログ風のミニマル
✓ Rounded / small shadow / gray を基調
```

---

## ch02 依存関係

### 2.1 コンポーネント階層

```
MainLayout
 ├─ AppHeader (C-01)
 ├─ {children}
 ├─ AppFooter (C-04)
 └─ FooterShortcutBar (C-05)
```

### 2.2 外部依存

| 依存先                       | 利用機能                     |
| ------------------------- | ------------------------ |
| StaticI18nProvider (C-03) | t(key) による翻訳取得           |
| next/navigation           | usePathname() によるアクティブ判定 |
| next/link                 | 画面遷移（クライアントサイド）          |

### 2.3 Logger 方針（v1.1 追加）

FooterShortcutBar は **UI ナビゲーションのみ** を担当し、API 呼び出し・内部状態・副作用を持たないため、
共通ログユーティリティ（logInfo / logError）を直接呼び出さない。

ログが必要な場合（例：Analytics に送信など）は、**親コンテナ側で実行**する。

---

## ch03 Props 定義

### 3.1 型定義

```ts
export interface FooterShortcutBarProps {
  /** 表示するユーザー権限（必須） */
  role: 'system_admin' | 'tenant_admin' | 'general_user';

  /** 追加スタイルクラス（任意） */
  className?: string;

  /** E2E / RTL 用の識別子 */
  testId?: string;
}
```

### 3.2 デフォルト値

* `testId`: `'footer-shortcut-bar'`
* `className`: ''

---

## ch04 UI 構成

### 4.1 レイアウト

```
┌────────────────────────────────────────────┐
│  📄 掲示板   │  📅 施設予約   │   ⚙️ 設定（例） │
└────────────────────────────────────────────┘
```

| 仕様      | 値                                  |
| ------- | ---------------------------------- |
| 高さ      | 64px                               |
| 配置      | `fixed bottom-0 left-0 right-0`    |
| 背景      | 白（#FFFFFF）                         |
| ボーダー    | 上側 1px Gray-200                    |
| レイアウト   | `flex justify-around items-center` |
| z-index | 950（AppFooter: 900 < C-05 < C-01）  |

### 4.2 ボタン仕様

| 状態          | スタイル                           |
| ----------- | ------------------------------ |
| **通常**      | gray-500 / hover:bg-gray-50    |
| **アクティブ**   | blue-600 + border-t-2 blue-600 |
| **アイコンサイズ** | 24px                           |
| **ラベル**     | 12px / BIZ UD ゴシック             |
| **配置**      | `flex flex-col items-center`   |

### 4.3 権限別表示（最新仕様）

#### system_admin

* 設定 (`/settings`)
* テナント管理 (`/admin/tenants`)
* ログ (`/admin/logs`)

#### tenant_admin

* 掲示板 (`/board`)
* 施設予約 (`/facility`)
* 設定 (`/settings`)

#### general_user

* 掲示板 (`/board`)
* アンケート (`/survey`)
* マイページ (`/mypage`)

### 4.4 アクセシビリティ

* `role="navigation"` を付与
* `aria-label` に翻訳済みラベルを設定
* アクティブな項目には `aria-current="page"`
* アイコンは `aria-hidden="true"`
* Tab / Shift+Tab による自然なフォーカス移動

---

## ch05 ロジック構造

### 5.1 アクティブ判定

```ts
const pathname = usePathname();
const isActive = (href: string) => pathname.startsWith(href);
```

### 5.2 翻訳取得

```ts
const { t } = useI18n();
```

### 5.3 JSX 構造（最新）

```tsx
<nav
  role="navigation"
  aria-label={t('common.shortcut_navigation')}
  data-testid={testId}
  className={cn(
    'fixed bottom-0 left-0 right-0',
    'h-16 bg-white border-t border-gray-200',
    'flex justify-around items-center z-[950]',
    className,
  )}
>
  {items.map((item) => (
    <Link
      key={item.href}
      href={item.href}
      aria-label={t(item.labelKey)}
      aria-current={isActive(item.href) ? 'page' : undefined}
      className={cn(
        'flex flex-col items-center justify-center',
        'px-4 py-2 rounded-md transition-colors duration-150',
        isActive(item.href)
          ? 'text-blue-600 font-semibold border-t-2 border-blue-600'
          : 'text-gray-500 hover:bg-gray-50',
      )}
    >
      <span aria-hidden="true" className="text-2xl mb-1">
        {item.icon}
      </span>
      <span className="text-xs">{t(item.labelKey)}</span>
    </Link>
  ))}
</nav>
```

### 5.4 エラーハンドリング

FooterShortcutBar は API を持たず、例外発生ポイントは UI 遷移のみ：

* 翻訳キー未存在 → StaticI18nProvider 側でフォールバック
* usePathname がエラー → Next.js 側の責務

---

## ch06 テスト観点

### 6.1 単体テスト（Jest + RTL）

| ID       | 観点           | 期待結果                   |
| -------- | ------------ | ---------------------- |
| T-C05-01 | system_admin | 設定/テナント管理/ログ の 3 項目表示  |
| T-C05-02 | tenant_admin | 掲示板/施設予約/設定 の 3 項目表示   |
| T-C05-03 | general_user | 掲示板/アンケート/マイページ表示      |
| T-C05-04 | アクティブ判定      | 現在パスのリンクに active class |
| T-C05-05 | 翻訳表示         | 翻訳済みラベルを表示             |
| T-C05-06 | aria-label   | ラベルが正しく設定              |
| T-C05-07 | aria-current | アクティブリンクに page 設定      |
| T-C05-08 | className    | 追加 class が反映           |

---

## ch07 ログ方針（v1.1 追加）

FooterShortcutBar は UI 表示部品であり、**ログを直接出力しない**。
行動ログ・分析が必要な場合は、親の MainLayout などでイベントを捕捉し、
共通ログユーティリティ（logInfo / logError）を呼び出す。

---

## ch08 注意事項

* SSR/CSR 両モードでの動作保証（usePathname の制約に注意）
* フォント・色は共通デザインシステム v1.1 に従う
* 追加 props による position/z-index の変更は非推奨

---

## ch09 改訂履歴

| Version | Date    | Summary |
| ------- | ------- | ------- |
| 1.0     | 2025-11 |         |
