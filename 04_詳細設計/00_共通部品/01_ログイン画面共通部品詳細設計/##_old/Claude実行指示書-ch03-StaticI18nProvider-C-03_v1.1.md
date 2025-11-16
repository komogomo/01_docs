# Claude実行指示書-ch03-StaticI18nProvider-C-03_v1.1.md

**Document ID:** HNM-DIR-C03-INSTRUCTION  
**Component ID:** C-03  
**Component Name:** StaticI18nProvider  
**Target:** Claude  
**Author:** Tachikoma  
**Created:** 2025-11-09  
**Purpose:** C-03 StaticI18nProvider の詳細設計書（`ch03_StaticI18nProvider_v1.0.md`）を作成するための正式実行指示書。  
**Status:** 🟩 Ready for Execution  

---

## 🎯 1. 目的

本タスクは、HarmoNet共通部品「StaticI18nProvider (C-03)」の**詳細設計書初版**を作成するためのものである。  
本Providerはアプリ全体の**静的多言語辞書ローディングおよびロケールコンテキスト提供**を担う。  
Phase9環境のNext.js 16 + React 19 構成において、  
`LanguageSwitch (C-02)` からのロケール変更に追従できる設計を求める。

---

## ⚙️ 2. 技術前提

| 項目 | 内容 |
|------|------|
| **フレームワーク** | Next.js 16.0.1（App Router） |
| **言語** | TypeScript（strictモード） |
| **UIライブラリ** | React 19 / shadcn/ui（DropdownMenu利用済） |
| **i18n方式** | next-intl 非採用。独自Provider（StaticI18nProvider）による辞書読込。 |
| **ルーティング** | next/navigation の useRouter / usePathname を使用。 |
| **辞書形式** | `/public/locales/{locale}/common.json` を静的importまたはfetch。 |
| **依存関係** | LanguageSwitch (C-02) から currentLocale props を受け取る。 |
| **環境** | Supabase構成依存なし（UI層のみ） |

> 📝 **補足:**  
> 現行の `harmonet-technical-stack-definition_v3.7.md` は Next.js 15 を記載しているが、  
> 実環境は Next.js **v16.0.1** に移行済み。  
> この差分は開発環境差として許容し、Phase10 開始時に v3.8 で更新予定。

---

## 🧩 3. 構成概要

### 3.1 コンポーネント階層関係
AppHeader (C-01)
└─ LanguageSwitch (C-02)
└─ StaticI18nProvider (C-03)
└─ <children>（各画面）


### 3.2 役割
| 層 | 役割 |
|----|------|
| **AppHeader** | UIの親（C-02を配置） |
| **LanguageSwitch** | ロケール切替イベントを発火 |
| **StaticI18nProvider** | 辞書を読み込み、React Contextで配布 |

---

## 🧠 4. 設計方針（Claudeが準拠すべき項目）

| 分類 | 指針 |
|------|------|
| **ロジック構成** | useEffectでロケール変更を検知し、辞書を再ロード。Contextに格納。 |
| **Context構造** | `I18nContext = { locale: string; t: (key: string) => string }` |
| **辞書ロード方法** | JSON import (`/public/locales/${locale}/common.json`) |
| **フォールバック** | 辞書読み込み失敗時は `ja` をデフォルトに使用 |
| **永続化** | localStorage に locale を保存（任意） |
| **型定義** | `StaticI18nProviderProps` と `I18nContextType` を別ファイルに分離 |
| **依存** | LanguageSwitch の `currentLocale` props で初期ロケール設定 |
| **連携方針** | C-02 とは props 経由でのみ連携し、Context共有は行わない。 |
| **テスト観点** | locale変更 → Context更新 / フォールバック発火 / t()動作確認 |
| **アクセシビリティ** | Provider内は表示要素を持たず、A11y影響なし |

---

## 📚 5. 参照資料

| 分類 | ファイル名 | 用途 |
|------|-------------|------|
| 詳細設計（参照元） | `ch02_LanguageSwitch_v1.1.md` | 呼出元構造とprops仕様の確認 |
| 技術スタック | `harmonet-technical-stack-definition_v3.7.md` | Next.js / Tailwind 環境整合性確認 |
| 共通仕様 | `common-i18n_v1.0.md` | i18n全体方針 |
| 命名規則 | `harmonet-naming-matrix_v2.0_final.md` | コンポーネント命名整合性 |
| コーディング規約 | `harmonet-coding-standard_v1.1.md` | Lint / コメント / 型宣言指針 |

---

## 🧪 6. 出力要件（Claudeの成果物条件）

Claudeは以下の要件を満たす  
**`ch03_StaticI18nProvider_v1.0.md`（1枚完結Markdown）**  
を作成すること。

### 出力条件:
1. ドキュメント構成は ch01/ch02 に準拠（章立て `ch01〜ch08`）  
2. Props定義・UI構成・ロジック構成・テスト観点をすべて含む  
3. 言語: 日本語  
4. コード例: TypeScript で実装例を記述  
5. 最後に関連ドキュメント一覧を掲載  

---

## 🚫 7. 禁止事項
- next-intl の import / useLocale の使用  
- Supabase / Prisma などの外部依存を追加  
- ディレクトリ構成の変更  
- JSON辞書を外部API化する記述（静的ロードのみ）  
- i18nContext 内に副作用を持たせる  

---

## 🧩 8. 成果物仕様（Claude出力フォーマット）
HarmoNet 詳細設計書 - StaticI18nProvider (C-03) v1.0

Document ID: HARMONET-COMPONENT-C03-STATICI18NPROVIDER
Version: 1.0
Created: 2025-11-09
Component ID: C-03
Component Name: StaticI18nProvider
Category: 共通部品（Common Components）
Difficulty: 3
Safe Steps: 4
