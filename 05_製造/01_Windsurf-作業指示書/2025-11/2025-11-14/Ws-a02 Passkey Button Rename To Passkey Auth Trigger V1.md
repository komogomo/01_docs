# WS-A02_PasskeyButtonRenameToPasskeyAuthTrigger_v1.0

## 1. Task Summary（タスク概要）

* **目的:** 旧 *PasskeyButton* を正式名称 *PasskeyAuthTrigger* へリネームし、A-02 正式仕様へ統合する。
* **対象コンポーネント:** A-02 PasskeyAuthTrigger（旧 PasskeyButton）
* **修正範囲:** コンポーネント名・ファイル名のリネーム、関連 import の置換（ロジック変更なし）
* **注意:** UI は完全廃止済み（A-02 はロジック専用）。機能改変禁止。

---

## 2. Target Files（編集対象ファイル）

* `src/components/login/PasskeyButton.tsx`
* `src/components/login/PasskeyButton.types.ts`
* `src/components/login/PasskeyButton.test.tsx`
* `src/components/login/index.ts`
* `src/components/login/MagicLinkForm.tsx`（import のみ置換）

---

## 3. Import & Directory Rules

```
src/
  components/
    auth/        ← A-01〜A-03
    common/
    ui/
```

* import パスは **@/src/...** に統一。
* rename は本タスクでのみ許可。
* UI ファイル新規追加は禁止。

---

## 4. References（参照ドキュメント）

* MagicLinkForm-detail-design_v1.1（A-01）
* PasskeyAuthTrigger-detail-design_v1.1（A-02）
* StaticI18nProvider_v1.0（C-03）

---

## 5. Implementation Rules（実装ルール）

* ロジック改変禁止。
* Tailwind クラスの変更禁止。
* Props 追加・削除禁止。
* rename と import 差替えのみ行う。
* UI は削除済みのため生成不可。
* harmonet-coding-standard_v1.1 に準拠。

---

## 6. Acceptance Criteria（受入基準）

* TypeCheck: 0 エラー
* ESLint: 0 エラー
* Build: 成功
* Jest: 100% PASS
* SelfScore: 9.0 以上
* 参照の整合性：A-01 / A-02 仕様と一致

---

## 6.5 Backup Rules（バックアップルール）

```
<元ファイル名>_YYYYMMDD_v0.1.bk
例: PasskeyButton.tsx_20251114_v0.1.bk
```

* 保存場所：元ファイルと同一ディレクトリ
* 条件：既存ファイル上書き・削除が発生する場合

---

## 7. Forbidden Actions（禁止事項）

* UI追加
* ロジック変更
* ディレクトリ改変
* 外部ライブラリ追加
* Props変更

---

## 8. CodeAgent_Report（必須）

Windsurf はタスク完了後、**PJナレッジ既定フォーマットに従い、以下の内容でレポートを必ず生成すること。

### ■ 保存パス（必須）

```
/01_docs/05_品質チェック/CodeAgent_Report_A02_Rename_v1.0.md
```

### ■ レポート構成（PJナレッジ準拠）

```
[CodeAgent_Report]
Agent: Windsurf
Task: A02_Rename_PasskeyButtonToPasskeyAuthTrigger
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - WS-A02_PasskeyButtonRenameToPasskeyAuthTrigger_v1.0
 - PasskeyAuthTrigger-detail-design_v1.1
 - MagicLinkForm-detail-design_v1.1
 - StaticI18nProvider_v1.0
 - 該当する実装ファイル一式
[Generated_Files]
 - <rename されたファイル一覧>
Summary:
 - 実行内容の要約
 - 置換箇所の整合
 - 注意点および補足
```

---

## 9. Testing Method

### UI / Layout

* Storybook：該当なし（A-02 UI非保持）

### Jest / RTL

* A-02 の test ファイル rename 後も PASS すること。

### Build / TypeCheck

```
npm run build
npm run type-check
npm run lint
```

---

## 10. 作業内容（Windsurf 実行手順）

1. `src/components/login/PasskeyButton*.tsx` を下記名称に rename：

   * `PasskeyButton.tsx` → `PasskeyAuthTrigger.tsx`
   * `PasskeyButton.types.ts` → `PasskeyAuthTrigger.types.ts`
   * `PasskeyButton.test.tsx` → `PasskeyAuthTrigger.test.tsx`
2. すべての import を `PasskeyAuthTrigger` に置換。
3. MagicLinkForm 内の旧 PasskeyButton import を削除（または未使用除去）。
4. index.ts の export を更新。
5. Jest / TypeCheck / Lint / Build を実行し、全て PASS。

---

## 11. 改訂履歴

* **v1.0（2025-11-14）**: 初版作成（PasskeyButton → PasskeyAuthTrigger リネーム専用タスク）
