# Windsurf実行指示書_ch03_StaticI18nProvider_C-03_v1.0.md

**Document ID:** HNM-LOGIN-COMMON-C03-STATICI18NPROVIDER  
**Component ID:** C-03  
**Component Name:** StaticI18nProvider  
**Version:** 1.0  
**Created:** 2025-11-09  
**Author:** Tachikoma  
**Status:** ✅ Ready for Implementation  

---

## 📂 ディレクトリ構成（既存PJ基準）
D:\Projects\HarmoNet\
├─ src/
│   ├─ components/
│   │   ├─ common/
│   │   │   └─ StaticI18nProvider/
│   │   │       ├─ StaticI18nProvider.tsx
│   │   │       ├─ StaticI18nProvider.types.ts
│   │   │       ├─ StaticI18nProvider.test.tsx
│   │   │       ├─ StaticI18nProvider.stories.tsx
│   │   │       └─ index.ts
│   ├─ app/
│   ├─ lib/
│   └─ tests/
├─ public/
│   └─ locales/
│       ├─ ja/common.json
│       ├─ en/common.json
│       └─ zh/common.json
└─ package.json

---

## 🧩 実装対象
コンポーネント名: **StaticI18nProvider**  
対応Component ID: **C-03**  
難易度: **3（安全ステップ数:4）**  
依存: **LanguageSwitch (C-02)**  
呼出元: **AppHeader (C-01)**  

---

## 🧠 参照すべき設計情報
| 種別 | ファイル名 | 用途 |
|------|-------------|------|
| 詳細設計書 | `ch03_StaticI18nProvider_v1.0.md` | 実装仕様の直接参照元 |
| 技術基盤 | `harmonet-technical-stack-definition_v3.7.md` | Next.js / Tailwind 構成（実環境はNext16.0.1） |
| 共通仕様 | `common-i18n_v1.0.md` | 辞書構造・i18n全体方針 |
| 機能一覧 | `機能コンポーネント一覧.md` | コンポーネント粒度・優先度定義 |
| コーディング規約 | `harmonet-coding-standard_v1.1.md` | Lint・型・コメントルール |

---

## ⚙️ 実装タスク内容

### 1️⃣ ファイル生成
以下のファイルを設計書に基づき新規作成：
- `StaticI18nProvider.tsx`
- `StaticI18nProvider.types.ts`
- `StaticI18nProvider.test.tsx`
- `StaticI18nProvider.stories.tsx`
- `index.ts`

### 2️⃣ 実装仕様
- 独自Context (`I18nContext`) により `locale` と `t(key)` を提供
- propsで受け取る `currentLocale` を監視し、辞書(`/public/locales/{locale}/common.json`)を再ロード
- `localStorage` に選択言語を保存・復元
- 辞書ロード失敗時は `ja` にフォールバック
- t() はネストキー対応（例: `"common.submit"`）
- fetchエラー・キー未検出時は警告出力＋キーをそのまま返却

---

## 🧠 3️⃣ ロジック構造
- useEffect：初期ロード + props変更検知
- useState：`locale`, `translations`
- useMemo：t()関数再生成 + Context値最適化
- Context構成：
  ```typescript
  I18nContext = { locale: 'ja', t: (key: string) => string }

💡 4️⃣ テスト仕様

フレームワーク: Jest + React Testing Library
対象: StaticI18nProvider.test.tsx
テストケース（設計書ch06に準拠）:
| テストID    | 検証内容                    |
| -------- | ----------------------- |
| T-C03-01 | 初期ロケール：ja辞書読込           |
| T-C03-02 | currentLocale変更による再ロード  |
| T-C03-03 | t()関数正常キー               |
| T-C03-04 | 存在しないキー警告               |
| T-C03-05 | 辞書ロード失敗フォールバック          |
| T-C03-06 | localStorage更新          |
| T-C03-07 | Provider外使用でError throw |

🧩 5️⃣ Storybook仕様
| ストーリー名         | 内容          |
| -------------- | ----------- |
| Default        | ja表示        |
| English        | en表示        |
| Chinese        | zh表示        |
| WithMissingKey | 存在しないキー挙動確認 |

✅ 成果物条件（Acceptance Criteria）
| 項目                  | 基準                |
| ------------------- | ----------------- |
| **TypeCheck**       | strictモード警告ゼロ     |
| **Lint / Prettier** | エラー・警告ゼロ          |
| **UT通過率**           | 100%（T-C03-01〜07） |
| **Storybook**       | 全4ストーリー動作確認       |
| **ファイル配置**          | 設計書準拠構成で生成        |
| **自己採点**            | 平均スコア9.0以上        |

🚫 禁止事項
・next-intl の使用
・Supabase / Prisma / DB変更
・JSON辞書の外部API化
・ディレクトリ変更・CSS追加・命名変更

📊 [CodeAgent_Report] 出力条件
タスク完了後、以下の形式で評価結果を出力すること：
[CodeAgent_Report]
Agent: Windsurf
Component: StaticI18nProvider (C-03)
Attempt: 1
AverageScore: 9.3/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 仕様完全一致。currentLocale props駆動でLanguageSwitch連携正常。辞書ロード・フォールバック動作確認済み。

📘 参照規約
・/01_docs/00_project/01_運用ガイドライン/harmonet-coding-standard_v1.1.md
・/01_docs/03_基本設計/01_共通部品/common-i18n_v1.0.md

🧪 テスト補足
・fetchをjest.mockでモック化。
・/public/locales/{locale}/common.json をテストリソースに同梱。
・Provider外でuseI18n()使用時はError throwを確認。
・npm test src/components/common/StaticI18nProvider 実行可能状態。

🗃️ Report Export
完了後、以下パスへ保存：
/01_docs/05_品質チェック/CodeAgent_Report_StaticI18nProvider_v1.0.md

改訂履歴
| バージョン | 日付         | 更新者       | 内容                          |
| ----- | ---------- | --------- | --------------------------- |
| v1.0  | 2025-11-09 | Tachikoma | 初版（Next16対応、next-intl非依存構成） |
