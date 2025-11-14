📂 ディレクトリ構成（既存PJ基準）
D:\Projects\HarmoNet\
├─ src/
│   ├─ components/
│   │   ├─ common/
│   │   │   └─ AppHeader/
│   │   │       ├─ AppHeader.tsx
│   │   │       ├─ AppHeader.types.ts
│   │   │       ├─ AppHeader.test.tsx
│   │   │       └─ index.ts
│   ├─ app/
│   ├─ lib/
│   └─ tests/
├─ prisma/
│   ├─ schema.prisma
│   └─ seed.ts
├─ supabase/
│   └─ migrations/
│       ├─ 20251107000000_initial_schema.sql
│       └─ 20251107000001_enable_rls_policies.sql
└─ package.json

🧩 実装対象

コンポーネント名: AppHeader
対応Component ID: C-01
難易度: 2（安全ステップ数:3）
依存: LanguageSwitch (C-02)

🧠 参照すべき設計情報
| 種別       | ファイル名                                                      | 用途                                 |
| -------- | ---------------------------------------------------------- | ---------------------------------- |
| 詳細設計書    | `ch01_AppHeader_v1.0.md`                                   | 実装仕様の直接参照元                         |
| 技術基盤     | `harmonet-technical-stack-definition_v3.7.md`              | Next.js / Supabase / Tailwind 環境構成 |
| DB構造     | `HarmoNet_Phase9_DB_Construction_Report_v1_0.md`           | RLSとテナント分離の方針確認（非依存）               |
| 機能一覧     | `機能コンポーネント一覧.md`                                           | コンポーネント粒度・優先度定義                    |
| コーディング規約 | `00_プロジェクト管理/01_運用ガイドライン/harmonet-coding-standard_v1.1.md` | 命名・Lint・型定義ルール                     |

⚙️ 実装タスク内容

1.設計書のコードをベースに下記ファイルを生成：
・AppHeader.tsx
・AppHeader.types.ts
・AppHeader.test.tsx
・index.ts

2.テスト実行環境: Jest + React Testing Library
・テストコードは設計書9章に記載済み。
・npm test src/components/common/AppHeader 実行可能であること。

3.Tailwind CSSクラスを含めたスタイルはJIT対応済。CSSファイルは不要。

✅ 成果物条件（Acceptance Criteria）
| 項目                | 基準                                       |
| ----------------- | ---------------------------------------- |
| 型定義               | TypeScript strictモードで警告ゼロ                |
| ESLint / Prettier | エラーゼロ                                    |
| UT通過率             | 100%（設計書9章基準）                            |
| Storybook         | Login / Authenticated variant の2種ストーリー生成 |
| ファイル配置            | 設計書2.2構成どおり生成                            |
| 自己採点              | 3項目平均9/10以上（精度・再現性・保守性）                  |

🚫 禁止事項
・schema.prisma や Supabase構成への変更
・新規CSSファイルの追加
・ディレクトリ構造・命名規則の変更
・ファイル分割・リネーム

📊 [CodeAgent_Report] 出力条件
タスク完了後、以下のフォーマットで自動評価結果を出力すること。
[CodeAgent_Report]
Agent: Windsurf
Component: AppHeader (C-01)
Attempt: 1
AverageScore: 9.4/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 実装仕様完全一致。LanguageSwitch 依存正常。

### 📘 参照規約
- /01_docs/00_project/01_運用ガイドライン/harmonet-coding-standard_v1.1.md  
  （命名・コメント・構文・i18nキー・アクセシビリティ記法ルール）

### 🧪 テスト仕様と初回検証に関する補足
- 本タスクは HarmoNet Phase9 における Windsurf 実行精度の初回評価を目的とします。
- Claude設計書（ch09章）に記載されているテスト項目は **仕様定義** であり、
  **テストコードは存在しません。**
- Windsurf はこの仕様をもとに **新規に Jest + React Testing Library のテストコードを生成・実行** してください。
- この実行はテスト品質そのものよりも、生成・依存解決・自己採点・CodeAgent_Report出力までの一連の工程確認を目的とします。
- 初回の受入基準は **平均スコア 8.0 以上** とし、リトライは最大3回まで許可します。

### 🧩 改善タスク：ESLint警告(@next/next/no-img-element)対応
- `<img>` タグを Next.js 標準の `<Image>` コンポーネントに置き換えてください。
- alt 属性は必須です。幅と高さを適切に指定し、Lighthouse推奨に準拠してください。
- 修正後、`npm run lint` を実行し、警告ゼロを確認。
- 成果を再度 CodeAgent_Report として出力してください。

### 🗃️ Report Export
After generating CodeAgent_Report, save it to:
`/01_docs/05_品質チェック/CodeAgent_Report_<Component>_v<Version>.md`

### 📂 Generated File Summary (Re-output Task)
Re-open the previous CodeAgent_Report for AppHeader (C-01) and regenerate it,
including the list of all generated and updated files in a [Generated_Files] section.

Each path must be relative to the project root (D:\Projects\HarmoNet).

Expected format:
[Generated_Files]
- src/components/common/AppHeader/AppHeader.tsx
- src/components/common/AppHeader/AppHeader.types.ts
- src/components/common/AppHeader/AppHeader.test.tsx
- src/components/common/AppHeader/index.ts
- src/components/common/LanguageSwitch/index.tsx
- public/images/logo.svg
- jest.config.mjs
- setupTests.ts
- .eslintrc.json
- .prettierrc
- .storybook/main.ts
- .storybook/preview.ts
- src/components/common/AppHeader/AppHeader.stories.tsx

### 🗃️ Report Export
After regeneration, save the updated report to the following path and filename:
`/01_docs/05_品質チェック/CodeAgent_Report_AppHeader_v1.1.md`
(Do not overwrite v1.0 — treat this as a revision containing the [Generated_Files] addition.)

