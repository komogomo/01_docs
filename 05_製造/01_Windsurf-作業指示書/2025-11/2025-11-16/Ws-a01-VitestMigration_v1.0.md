# WS-A01_VitestMigration_v1.0

## 1. Task Summary（タスク概要）

* **目的:** MagicLinkForm（A-01）のテスト環境を Jest → Vitest へ移行し、ESM 時代に適合したテスト実行基盤へ置き換える。
* **対象コンポーネント:** A-01 MagicLinkForm（※ UI/ロジック本体は変更禁止）
* **修正範囲:** テスト基盤・設定・セットアップファイル・テスト runner のみ。
* **注意:** UI / ロジック / コンポーネント内容を一切変更してはならない。MagicLinkForm.test.tsx の require → import 置換も含むが、WindSurf には慎重な AST ベース処理を要求する。

---

## 2. Target Files（編集対象ファイル）

* `package.json`（scripts と devDependencies の追記）
* `vitest.config.ts`（新規作成）
* `setupTests.ts`（既存を流用 or 調整）
* `MagicLinkForm.test.tsx`（ESM import へ置換）

---

## 3. Import & Directory Rules（公式ルール）

本タスクは **HarmoNet フロントエンド構成 v1.0** に完全準拠すること。

* すべての import パスは `@/src/...` を維持。
* ディレクトリ追加は `vitest.config.ts` 以外禁止。
* `src/components/auth/MagicLinkForm/` 以下のコンポーネント本体を変更しない。

---

## 4. References（参照ドキュメント）

* MagicLinkForm-detail-design_v1.3
* harmonet-frontend-directory-guideline_v1.0
* Windsurf 実行指示書テンプレート v1.1

---

## 5. Implementation Rules（実装ルール）

### ✔ 必須作業

1. **Vitest 導入（package.json 更新）**

   * devDependencies に以下を追加：

     * `vitest`
     * `jsdom`
     * `@testing-library/react`
     * `@testing-library/jest-dom`

2. **scripts に以下を追加：**

```json
"test:unit": "vitest --run"
```

3. **vitest.config.ts の新規作成**

```ts
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./setupTests.ts'],
  },
  resolve: {
    alias: {
      '@/src': path.resolve(__dirname, './src'),
    },
  },
});
```

4. **MagicLinkForm.test.tsx の ESM 化**

   * `require('./MagicLinkForm')` を **import 方式**に統一。
   * named / default export は Windsurf が実際のファイルを解析して自動選択。

### ❌ 禁止事項

* コンポーネント本体（MagicLinkForm.tsx）の変更
* UI スタイル・ロジック・Tailwind クラスの変更
* Jest 設定の削除（併存は可、最終的に不要なら TKD が判断する）
* ファイル rename / ディレクトリ移動

---

## 6. Acceptance Criteria（受入基準）

* `npm run test:unit` が **全件 PASS** すること。
* TypeCheck: Passed
* Lint: Passed
* MagicLinkForm.tsx 本体に一切の変更が無いこと。
* require → import への置換が正しく動作すること。
* Vitest 実行時に ESM 問題（モジュール解決）が発生しないこと。
* Windsurf SelfScore 9.0 以上。

---

## 7. CodeAgent_Report（必須）

Windsurf は以下形式で CodeAgent_Report を作成し、TKD 指定パスへ保存する：

```
[CodeAgent_Report]
Agent: Windsurf
Task: MagicLinkForm-VitestMigration
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 * WS-A01_VitestMigration_v1.0
 * MagicLinkForm-detail-design_v1.3
 * harmonet-frontend-directory-guideline_v1.0

[Generated_Files]
 * vitest.config.ts
 * package.json（変更）
 * MagicLinkForm.test.tsx（変更）

Summary:
 * Vitest migration completed.
 * MagicLinkForm test passes with ESM.
```

### ■ Report Export（保存先：必須）

```
/01_docs/06_品質チェック/CodeAgent_Report_MagicLinkForm-VitestMigration_v1.0.md
```

---

## 8. Forbidden Actions（禁止事項）

* UI / ロジック改変
* コンポーネント本体の修正
* 追加ライブラリの導入（Vitest 必要最小限のみ）
* Tailwind 変更
* Jest の削除（併存は許可、削除は TKD の判断）

---

## 9. 改訂履歴

| Version | Date       | Summary                         |
| ------- | ---------- | ------------------------------- |
| v1.0    | 2025-11-16 | Vitest 導入による A-01 テスト基盤移行タスク 初版 |

---

**End of Document**
