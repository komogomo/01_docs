# Windsurf実行指示書_ch02_LanguageSwitch_C-02_v1.1.md

**Document ID:** HNM-LOGIN-COMMON-C02-LANGUAGESWITCH  
**Component ID:** C-02  
**Component Name:** LanguageSwitch  
**Version:** 1.1  
**Created:** 2025-11-09  
**Author:** Tachikoma  
**Status:** ✅ Ready for Implementation  

---

## 📂 ディレクトリ構成（既存PJ基準）
D:\Projects\HarmoNet\
├─ src/
│   ├─ components/
│   │   ├─ common/
│   │   │   └─ LanguageSwitch/
│   │   │       ├─ LanguageSwitch.tsx
│   │   │       ├─ LanguageSwitch.types.ts
│   │   │       ├─ LanguageSwitch.test.tsx
│   │   │       └─ index.ts
│   ├─ app/
│   ├─ lib/
│   └─ tests/
├─ prisma/
│   └─ schema.prisma
└─ package.json

---

## 🧩 実装対象
コンポーネント名: **LanguageSwitch**  
対応Component ID: **C-02**  
難易度: **3（安全ステップ数: 4）**  
依存: **AppHeader (C-01)**  
呼出先: **StaticI18nProvider (C-03)**

---

## 🧠 参照すべき設計情報
| 種別 | ファイル名 | 用途 |
|------|-------------|------|
| 詳細設計書 | `ch02_LanguageSwitch_v1.1.md` | 本指示書の直接参照元 |
| 技術基盤 | `harmonet-technical-stack-definition_v3.7.md` | Next.js / Supabase / Tailwind構成 |
| 機能一覧 | `機能コンポーネント一覧.md` | コンポーネント粒度・安全ステップ定義 |
| 依存元設計 | `ch01_AppHeader_v1.0.md` | 呼出し構造・UI配置整合確認 |
| コーディング規約 | `00_プロジェクト管理/01_運用ガイドライン/harmonet-coding-standard_v1.1.md` | 命名・コメント・Lintルール |

---

## ⚙️ 実装タスク内容

### 1️⃣ ファイル生成
以下のファイルを設計書に基づき新規作成：
- `LanguageSwitch.tsx`
- `LanguageSwitch.types.ts`
- `LanguageSwitch.test.tsx`
- `index.ts`

### 2️⃣ 実装仕様
- UIライブラリ: **shadcn/ui DropdownMenu**
- 依存パッケージ: `next-intl`, `@radix-ui/react-dropdown-menu`, `lucide-react`
- 使用API: `useRouter`, `usePathname`, `useLocale`
- 実装関数: `handleLanguageChange(newLocale: Locale)`
- 呼出構造:  
  `AppHeader (C-01)` → `LanguageSwitch (C-02)` → `StaticI18nProvider (C-03)`

### 3️⃣ スタイル仕様（Tailwind準拠）
- **TriggerButton:** `flex items-center gap-1 px-3 py-2 rounded-lg border border-gray-300 bg-white hover:bg-gray-50 transition-colors`
- **MenuContent:** `w-[140px] bg-white border border-gray-200 rounded-lg shadow-md`
- **ActiveItem:** `bg-blue-50 text-blue-600 font-semibold`
- **InactiveItem:** `text-gray-900 hover:bg-gray-50`

### 4️⃣ テスト仕様
フレームワーク: Jest + React Testing Library  
テスト対象ファイル: `LanguageSwitch.test.tsx`

テスト観点（詳細設計 ch06 参照）：
- T-C02-01 現在ロケール表示
- T-C02-02 メニュー展開
- T-C02-03 言語選択時 router.replace() 呼出
- T-C02-04 onLanguageChange イベント発火
- T-C02-05 チェックマーク表示
- T-C02-06 キーボード操作
- T-C02-07 aria属性設定確認

---

## ✅ 成果物条件（Acceptance Criteria）

| 項目 | 基準 |
|------|------|
| **型定義** | TypeScript strictモードで警告ゼロ |
| **ESLint / Prettier** | エラーゼロ |
| **UT通過率** | 100%（全7テストパス） |
| **Storybook** | Default / English / Chinese / WithCallback ストーリー作成 |
| **ファイル配置** | 設計書の構成通り生成 |
| **自己採点** | 平均スコア 9.0 以上（精度・再現性・保守性） |

---

## 🚫 禁止事項
- Supabase / Prisma / DB構造への変更
- 新規CSSファイル追加
- ファイル分割・リネーム
- 命名規則・構文・ディレクトリ構造の変更

---

## 📊 [CodeAgent_Report] 出力条件
タスク完了後、以下の形式で評価結果を出力すること：

[CodeAgent_Report]
Agent: Windsurf
Component: LanguageSwitch (C-02)
Attempt: 1
AverageScore: 9.3/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 設計仕様完全一致。AppHeader依存正常。


---

## 📘 参照規約
- `/01_docs/00_project/01_運用ガイドライン/harmonet-coding-standard_v1.1.md`  
- `/01_docs/03_基本設計/01_共通部品/common-i18n_v1.0.md`

---

## 🧪 テスト補足
- Jestモックを使用して `next-intl/navigation` の router動作を模擬。  
- Supabase環境は利用しない（Mockベースで完結）。  
- `npm test src/components/common/LanguageSwitch` 実行可能状態であること。

---

## 🗃️ Report Export
作成後、以下のファイル名で保存：
/01_docs/05_品質チェック/CodeAgent_Report_LanguageSwitch_v1.1.md


---

## 🗂️ [Generated_Files]
- src/components/common/LanguageSwitch/LanguageSwitch.tsx  
- src/components/common/LanguageSwitch/LanguageSwitch.types.ts  
- src/components/common/LanguageSwitch/LanguageSwitch.test.tsx  
- src/components/common/LanguageSwitch/index.ts  
- src/components/common/LanguageSwitch/LanguageSwitch.stories.tsx  
- .storybook/main.ts  
- .storybook/preview.ts  
- jest.config.mjs  
- setupTests.ts  
- .eslintrc.json  
- .prettierrc

---

### 改訂履歴
| バージョン | 日付 | 更新者 | 内容 |
|-----------|------|--------|------|
| v1.1 | 2025-11-09 | Tachikoma | 初版作成（AppHeader指示書準拠） |

---
**Next Step:**  
→ Windsurf に投入し、C-02 LanguageSwitch 実装・自己採点・CodeAgent_Report生成を実施。

