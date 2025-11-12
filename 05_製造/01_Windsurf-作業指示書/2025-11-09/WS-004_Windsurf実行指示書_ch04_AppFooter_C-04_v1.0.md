# Windsurf実行指示書 - AppFooter (C-04) v1.0

**Document ID:** HN-WINDSURF-C04-APPFOOTER  
**Component ID:** C-04  
**Component Name:** AppFooter  
**Category:** 共通部品（Common Components）  
**Version:** 1.0  
**Created:** 2025-11-09  
**Author:** Tachikoma  
**Approver:** TKD  

---

## 🎯 1. 実行目的

本タスクは、Claudeが作成した詳細設計書  
[`ch04_AppFooter_v1.0.md`](/01_docs/04_詳細設計/00_共通部品/01_ログイン画面共通部品詳細設計/ch04_AppFooter_v1.0.md)  
をもとに、**HarmoNet 共通部品 AppFooter (C-04)** を実装・テスト・自己採点し、  
成果を [CodeAgent_Report] として出力する。

---

## 🧩 2. 実装対象

| 項目 | 内容 |
|------|------|
| コンポーネント名 | AppFooter |
| Component ID | C-04 |
| 難易度 | 1（容易） |
| Safe Steps | 2 |
| 依存コンポーネント | StaticI18nProvider (C-03) |
| 参照設計書 | ch04_AppFooter_v1.0.md |
| 技術基盤 | harmonet-technical-stack-definition_v3.7.md |

---

## 🏗️ 3. ファイル構成
src/
└── components/
└── common/
└── AppFooter/
├── AppFooter.tsx
├── AppFooter.types.ts
├── AppFooter.test.tsx
├── AppFooter.stories.tsx
└── index.ts


---

## ⚙️ 4. 実装タスク内容

1. 設計書に従い以下のファイルを生成する：
   - `AppFooter.tsx`  
   - `AppFooter.types.ts`  
   - `AppFooter.test.tsx`  
   - `AppFooter.stories.tsx`  
   - `index.ts`

2. 翻訳参照  
   - `useI18n()` を StaticI18nProvider (C-03) から呼び出す。  
   - 翻訳キーは `t('common.copyright')`。

3. スタイリング  
   - Tailwind CSS のみ使用（外部CSSやstyled-components禁止）。  
   - 背景白・高さ48px・中央揃え・固定配置。

4. テスト  
   - Jest + React Testing Library  
   - 設計書の T-C04-01〜T-C04-05 を全通過。  
   - Lint, TypeCheck も同時実施。

---

## ✅ 5. 成果物条件（Acceptance Criteria）

| 項目 | 基準 |
|------|------|
| TypeCheck | Passed |
| ESLint / Prettier | エラーゼロ |
| Unit Tests | 100% Passed |
| Storybook | ja/en/zh 表示確認可能 |
| 構造整合性 | C-01〜C-03 と同一レベルで統一 |
| 自己採点平均 | 9.0/10 以上 |
| Report | CodeAgent_Report_AppFooter_v1.0.md 形式で出力 |

---

## 🚫 6. 禁止事項

- StaticI18nProvider の実装改変（参照のみ）  
- schema.prisma / Supabase 構成変更  
- CSS ファイル・外部ライブラリ追加  
- ディレクトリ構造変更・リネーム  
- next-intl 使用  

---

## 🧪 7. テスト仕様

| テストID | 内容 | 期待結果 |
|----------|------|----------|
| T-C04-01 | コピーライト文言表示 | 翻訳文言がDOMに表示される |
| T-C04-02 | セマンティックHTML | `<footer role="contentinfo">` 存在 |
| T-C04-03 | className適用 | カスタムクラス反映 |
| T-C04-04 | testId適用 | data-testidが正しく設定 |
| T-C04-05 | スタイル適用 | fixed/bottom-0/bg-white 等が存在 |

---

## 🧾 8. CodeAgent_Report 出力形式

```markdown
[CodeAgent_Report]
Agent: Windsurf
Component: AppFooter (C-04)
Attempt: 1
AverageScore: 9.x/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 仕様準拠。StaticI18nProvider連携・翻訳・スタイル・テスト全項目クリア。

[Generated_Files]
- src/components/common/AppFooter/AppFooter.tsx
- src/components/common/AppFooter/AppFooter.types.ts
- src/components/common/AppFooter/AppFooter.test.tsx
- src/components/common/AppFooter/AppFooter.stories.tsx
- src/components/common/AppFooter/index.ts
- public/locales/ja/common.json
- public/locales/en/common.json
- public/locales/zh/common.json
- jest.config.mjs
- setupTests.ts
- .eslintrc.json
- .prettierrc
- .storybook/main.ts
- .storybook/preview.ts

出力後、ファイルを保存：
/01_docs/05_品質チェック/CodeAgent_Report_AppFooter_v1.0.md

📘 9. 参照規約
・/01_docs/00_project/01_運用ガイドライン/harmonet-coding-standard_v1.1.md
・/01_docs/03_基本設計/01_共通部品/common-footer_v1.1.md
・/01_docs/03_基本設計/01_共通部品/common-design-system_v1.1.md
