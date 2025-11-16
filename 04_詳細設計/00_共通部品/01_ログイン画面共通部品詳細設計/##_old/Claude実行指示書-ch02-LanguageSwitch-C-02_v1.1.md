## Claude実行指示書-ch02-LanguageSwitch-C-02_v1.1

### 🎯 目的
C-02「LanguageSwitch」コンポーネントの**詳細設計書（ch01〜ch08構成）**をClaudeで作成する。
本バージョン（v1.1）は、Gemini指摘およびHarmoNet UI統一方針を反映し、shadcn/ui DropdownMenuベースでの設計に改訂する。

---

### 📘 出力物
- **ファイル名**: `ch02_LanguageSwitch_v1.1.md`
- **格納先**: `/01_docs/04_詳細設計/00_共通部品/`
- **構成**: ch01〜ch08の章立て構成（HarmoNet標準設計書形式）

---

### 📚 参照資料（Claude実行時にPJナレッジへアップロード）
| No | 資料名 | 用途 |
|----|----------|------|
| 1 | 機能コンポーネント一覧.md | コンポーネント識別と依存定義 |
| 2 | harmonet-technical-stack-definition_v3.7.md | 技術スタック確認（Next.js / React / Tailwind / next-intl） |
| 3 | common-i18n_v1.0.md | 翻訳構造・辞書仕様参照 |
| 4 | CodeAgent_Report_AppHeader_v1.1.md | C-01依存関係および生成成果参照 |
| 5 | common-design-system_v1.1.md | UIデザイン・スタイル一貫性確認 |

---

### 🧩 設計範囲
**対象:** ログイン画面共通部品「LanguageSwitch」（C-02）
- 言語切替UIコンポーネント
- `StaticI18nProvider`（C-03）とのContext連携インタフェース
- `AppHeader` からの呼び出しを前提とした props / event 設計
- `DropdownMenu`（shadcn/ui）を用いたUI構成（HeadlessUI非使用）
- 言語切替イベントは **UIイベント通知のみ** とし、永続化は上位層（AppHeader）で実施
- i18nコンテキストは `next-intl/navigation` APIによる安全な切替実装を採用

---

### 📐 出力フォーマット（Claude作成対象）
以下の章構成で出力。

1. **ch01 概要** – コンポーネントの目的、役割、前提条件
2. **ch02 依存関係** – AppHeader, StaticI18nProvider, next-intl/navigation
3. **ch03 Props定義** – TypeScript型、イベント定義（`onLanguageChange(newLocale)`）
4. **ch04 UI構成** – DropdownMenu構造（shadcn/ui）、ARIA属性、アクセシビリティ
5. **ch05 ロジック構造** – router.replace(pathname, { locale }) を使用した安全な切替
6. **ch06 テスト観点** – Jest + RTL での動作確認項目（クリック切替、emitイベント）
7. **ch07 Storybook構成** – 3言語ストーリー、`IntlProvider` デコレータを使用
8. **ch08 今後の拡張** – 自動翻訳・キャッシュ設計への展望メモ

---

### 🧠 Claudeへの依頼要領
Claudeは以下を順守して生成すること。
- **AppHeader (C-01)** 設計書と完全整合（Props命名・型定義・設計トーン）
- **UI実装:** `DropdownMenu`（shadcn/ui）を使用し、HeadlessUIは利用しない
- **ロケール切替:** `pathname.replace()` 禁止。`next-intl/navigation` の router.replace(pathname, { locale }) を使用
- **責務分離:** LanguageSwitchは永続化処理（localStorage/API）を持たない
- **Storybook:** `IntlProvider` またはモックDecoratorによるロケール切替テストを可能にする
- **コード記述量:** 約2,000トークン以内（Windsurf実装に適合）
- **ファイル命名:** `ch02_LanguageSwitch_v1.1.md`
- **出力先:** `/01_docs/04_詳細設計/00_共通部品/`

---

### 🧩 次工程（Windsurf工程）
本設計書の承認後、次の指示書で実装工程を実行する：
- **Windsurf実行指示書_ch02_LanguageSwitch_C-02_v1.1.md**
  - 保存先: `/01_docs/05_製造/01_Windsurf-作業指示書/`
  - 実装対象: `src/components/common/LanguageSwitch/`
  - 出力レポート: `/01_docs/05_品質チェック/CodeAgent_Report_LanguageSwitch_v1.1.md`

---

### ✅ 出力要件まとめ
| 要件 | 内容 |
|------|------|
| 設計粒度 | 1コンポーネント=1タスク単位 |
| 難易度 | 3（中） |
| 安全ステップ数 | 3ステップ（設計→レビュー→実装指示） |
| 言語 | TypeScript / React / Next.js |
| テスト | Jest + RTL / Storybook3構成 |
| UIライブラリ | shadcn/ui（DropdownMenu）|
| 命名規則 | harmoNet-naming-matrix_v2.0.md に準拠 |

---

### 🗒 改訂理由
- Gemini指摘によるロケール切替の安全化
- HeadlessUI依存の撤廃と HarmoNet UI 方針への統一（shadcn/ui採用）
- LanguageSwitch の責務境界明確化（UIイベント発火のみ）
- Storybook 構成の簡素化とテスト現実性の確保

---

**指示完了。Claudeは上記要件を満たす設計書（Markdown形式）を生成し、HarmoNet標準命名規則に従いファイルを出力すること。**