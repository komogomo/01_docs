# Windsurf実行指示書 - LoginPage v1.0

**Document ID:** HARMONET-WINDSURF-LOGINPAGE-V1.0
**Component ID:** A-00
**Created:** 2025-11-11
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ 実行準備完了（Phase9 最終タスク）

---

## 第1章 タスク概要

### 1.1 目的

本指示書は、HarmoNet ログイン画面の統合コンポーネント **LoginPage** を実装・検証するための Windsurf 実行仕様を定義する。
LoginPage は既存の MagicLinkForm（A-01）・PasskeyButton（A-02）・AppHeader（C-01）・AppFooter（C-04）を統合し、UI/UX トーンを HarmoNet Design System に準拠させた実際の画面を構築する。
本タスクの目的は、**ログイン機能群の統合UIを確認可能な状態に仕上げること**である。

---

## 第2章 参照ドキュメント

| 種別    | ファイル名                                            | 用途                         |
| ----- | ------------------------------------------------ | -------------------------- |
| 詳細設計書 | `LoginPage-detail-design_v1.0.md`                | 本タスクの仕様定義元                 |
| 詳細設計書 | `MagicLinkForm-detail-design_v1.0.md`            | メール認証フォーム依存                |
| 詳細設計書 | `PasskeyButton-detail-design_v1.4.md`            | パスキー認証依存                   |
| 詳細設計書 | `AuthCallbackHandler-detail-design_v1.0.md`      | コールバック遷移先確認                |
| 共通部品  | `ch01_AppHeader_v1.0.md`                         | ヘッダー構成・言語切替                |
| 共通部品  | `ch04_AppFooter_v1.0.md`                         | フッター構成                     |
| 技術基盤  | `harmonet-technical-stack-definition_v4.0.md`    | Next.js16 + Tailwind4 基盤確認 |
| 設計標準  | `harmonet-detail-design-agenda-standard_v1.0.md` | 構成・品質基準整合                  |

---

## 第3章 実装対象

| コンポーネント   | パス                                | 主要依存                                               |
| --------- | --------------------------------- | -------------------------------------------------- |
| LoginPage | `src/components/pages/LoginPage/` | MagicLinkForm, PasskeyButton, AppHeader, AppFooter |

---

## 第4章 実装指示

### 4.1 実装方針

* `'use client'` を明示。
* TypeScript strict モードでエラーゼロを維持。
* TailwindCSS による白基調ミニマルレイアウト。
* MagicLinkForm（A-01）と PasskeyButton（A-02）を中央縦配置。
* StaticI18nProvider により言語切替対応。
* AppHeader / AppFooter を含む完全ページ構成。
* i18n 辞書は既存キーのみを使用。
* 状態管理は子コンポーネントに委譲。LoginPage 自体は stateless。

### 4.2 デザイン要件

| 項目   | 値                                                  |
| ---- | -------------------------------------------------- |
| 背景色  | `#FFFFFF`                                          |
| フォント | BIZ UD ゴシック                                        |
| 配置   | 縦並び中央揃え (flex-col / items-center / justify-center) |
| 余白   | `py-10 px-4`                                       |
| ギャップ | `gap-6`                                            |
| 高さ   | min-h-screen                                       |

### 4.3 コード出力構成

* `src/components/pages/LoginPage/LoginPage.tsx`
* `src/components/pages/LoginPage/LoginPage.test.tsx`
* `src/components/pages/LoginPage/LoginPage.types.ts`
* `src/components/pages/LoginPage/index.ts`

### 4.4 ページ統合

* `app/login/page.tsx` にて LoginPage を描画。
* `app/auth/callback/page.tsx` では既存 AuthCallbackHandler を Suspense + fallback 表示。
* StaticI18nProvider を layout.tsx に適用済み。
* 言語切替ボタンは AppHeader 内の LanguageSwitch を使用。

---

## 第5章 禁止事項

* schema.prisma / DB / RLS の変更禁止。
* CSS ファイルや Styled Components の追加禁止。
* 新規依存ライブラリ追加禁止（Corbado SDK 以外）。
* i18n 辞書キーの追加禁止（Phase10で拡張予定）。
* ディレクトリ・命名規則の変更禁止。

---

## 第6章 Acceptance Criteria

| 項目                | 基準                      |
| ----------------- | ----------------------- |
| TypeCheck         | エラーゼロ                   |
| ESLint / Prettier | エラー・警告ゼロ                |
| UT                | 100%パス（UT01〜UT04）       |
| i18n              | ja/en/zh 切替動作確認（既存キー）   |
| UIトーン             | 白基調・控えめデザイン（HarmoNet標準） |
| SelfScore         | 平均 ≥ 9.0 / 10           |

---

## 第7章 CodeAgent_Report 仕様

完了後、以下に出力すること。

```
/01_docs/05_品質チェック/CodeAgent_Report_LoginPage_v1.0.md
```

フォーマット:

```
[CodeAgent_Report]
Agent: Windsurf
Component: LoginPage
Attempt: 1
AverageScore: 9.x/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 仕様準拠。UI統合・言語切替・認証動作確認済み。
```

---

## 第8章 実行順序

1. `npm ci`（依存確認）
2. `npm run lint`（エラーゼロ確認）
3. `npm run test`（UT全通過）
4. `npm run build`（Next.js16ビルド）
5. CodeAgent_Report 出力確認。

---

## 第9章 備考

* 固定英語文言は Phase10 i18n 辞書拡張で対応予定。
* LoginPage 実装後、UIスクリーンショットを Gemini レビュー用に取得予定。
* 本タスク完了をもって Phase9「ログイン画面」工程を正式完結とする。

---

**End of Instruction**
