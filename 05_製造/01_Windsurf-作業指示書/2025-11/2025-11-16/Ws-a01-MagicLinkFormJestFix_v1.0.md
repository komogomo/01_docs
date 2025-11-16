# WS-A01_MagicLinkForm_JestFix_v1.0

## 1. Task Summary（タスク概要）

* **目的:** MagicLinkForm.test.tsx のモジュール解決バグ（ESM/CJS 互換問題）を修正し、Jest テストを全件 PASS させる。
* **対象コンポーネント:** A-01 MagicLinkForm
* **修正範囲:** `MagicLinkForm.test.tsx` の import 方式の置換・補正のみ。
* **注意:** UI / ロジック / CSS / コンポーネント内容には一切触れない。**テストファイルのみ**を修正対象とする。

---

## 2. Target Files（編集対象ファイル）

* `src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx`

※ TKD がアップロードした最新版のみを対象とする。

---

## 3. Import & Directory Rules（公式ルール）

本タスクは **HarmoNet フロントエンド構成 v1.0** に完全準拠すること。fileciteturn0file2

```
src/
  components/
    auth/
      MagicLinkForm/
        MagicLinkForm.tsx
        MagicLinkForm.test.tsx
```

### 重要ルール

* import パスは `@/src/...` を維持。
* `require()` を使用しない。Next.js 16 + React19 + Turbopack は **ESM Only** のため、Jest から require するとモジュール構造が破壊される。
* **テストコードから default / named import を正式に扱うよう修正する。**
* コンポーネント本体には一切手を触れない。

---

## 4. References（参照ドキュメント）

* MagicLinkForm-detail-design_v1.3.md fileciteturn0file10
* LoginPage-detail-design_v1.2.md fileciteturn0file7
* HarmoNet Frontend Directory Guideline v1.0 fileciteturn0file2
* HarmoNet 詳細設計アジェンダ標準 v1.0 fileciteturn0file0
* Windsurf 実行指示書テンプレート v1.1 fileciteturn0file4

---

## 5. Implementation Rules（実装ルール）

* **UI 改変禁止**
* **ロジック改変禁止**
* **MagicLinkForm.tsx の編集禁止**
* **import / require の改善のみ許可**
* Tailwind クラス変更禁止
* コンポーネント責務の追加・削除禁止
* moduleNameMapper への追加など Jest 設定の変更は禁止
* 必要なのは **require → import** の一本化のみ

---

## 6. 修正内容（Windsurf が実施すべき変更）

### ❌ 現状（問題部分）

MagicLinkForm.test.tsx 内：

```
const MagicLinkFormModule = require('./MagicLinkForm');
const MagicLinkForm =
  MagicLinkFormModule.default ?? MagicLinkFormModule.MagicLinkForm;
```

### ✅ 修正後（ESM 正式対応）

MagicLinkForm.test.tsx 冒頭へ置換：

```ts
import MagicLinkForm from './MagicLinkForm';
```

または named export であれば：

```ts
import { MagicLinkForm } from './MagicLinkForm';
```

（Windsurf は実ファイルを解析の上、実際の export 方式に合わせて選択すること。）

### 📌 補足

* これ以外の require（supabaseClient モック）などはそのままでよい。
* Jest の ESM トランスパイルは next/jest が自動対応済み。fileciteturn1file1
* したがってテストファイル側の require() のみが障害。

---

## 7. Acceptance Criteria（受入基準）

* TypeCheck: 0 エラー
* ESLint: 0 エラー
* Prettier: 0 エラー
* Jest: MagicLinkForm.test.tsx **全テスト PASS（7件すべて）**
* コンポーネント UI / ロジックへ一切の変更なし
* SelfScore: **9.0 以上**
* 出力には CodeAgent_Report を必ず生成・保存すること

---

## 8. CodeAgent_Report（必須）

Windsurf 完了後、以下形式で出力する：

```
[CodeAgent_Report]
Agent: Windsurf
Task: MagicLinkForm-JestFix
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - WS-A01_MagicLinkForm_JestFix_v1.0
 - MagicLinkForm-detail-design_v1.3
 - LoginPage-detail-design_v1.2
 - harmonet-frontend-directory-guideline_v1.0

[Generated_Files]
 - src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx

Summary:
 - require → import への置換
 - ESM モジュール解決の修正
 - Jest 全テスト PASS
```

### ■ Report Export（保存先：必須）

```
/01_docs/06_品質チェック/CodeAgent_Report_MagicLinkForm-JestFix_v1.0.md
```

---

## 9. Forbidden Actions（禁止事項）

* MagicLinkForm.tsx の修正
* ロジック・UI の変更
* ファイル削除・rename
* 新規 CSS の追加
* Jest 設定ファイルの編集
* import パス変更（require の削除以外）
* Windsurf の推測による自動改善や最適化

---

## 10. 改訂履歴

| Version | Date       | Summary                                  |
| ------- | ---------- | ---------------------------------------- |
| v1.0    | 2025-11-16 | MagicLinkForm Jest モジュール解決バグ修正タスクとして初版作成 |

---

**End of Document**
