# WS-AuthCallbackHandler-Cleanup_v1.0

## 1. Task Summary（タスク概要）

* 目的: `src/components/login/AuthCallbackHandler/` 配下のファイルが **プロジェクト内で実際に使用されているか Windsurf が静的解析で判定** し、その結果に応じて移動または削除を行う。
* 対象コンポーネント: AuthCallbackHandler
* 修正範囲: import パス修正、ディレクトリ移動、バックアップ作成または削除
* 注意: UI/ロジックの変更は禁止。**構造とパスの修正のみ許可**。

---

## 2. Target Files（編集対象ファイル）

* `src/components/login/AuthCallbackHandler/AuthCallbackHandler.tsx`
* `src/components/login/AuthCallbackHandler/AuthCallbackHandler.test.tsx`

※ login 配下は非公式ディレクトリであり、使用されている場合のみ対応する。

---

## 3. Import & Directory Rules（公式ルール）

本タスクは HarmoNet フロントエンド構成 v1.0 に完全準拠すること。

```
src/
  components/
    auth/                  ← A-01〜A-03（ログイン系の正式配置）
      AuthCallbackHandler/
```

### 必須ルール

* import パスは `@/src/components/auth/...` に統一
* login/ 配下へコンポーネントを置くことは禁止
* ディレクトリの rename / 削除 / 改名は Windsurf が判断してはいけない（指示に従うこと）

---

## 4. References（参照ドキュメント）

* `harmonet-frontend-directory-guideline_v1.0.md`
* `WS-SYSTEM_ReorganizeFrontendStructure_v1.0.md`
* `app/auth/callback/page.tsx`
* `src/components/auth/AuthCallbackHandler/AuthCallbackHandler.tsx`

※ 必ず TKD が提供した最新版のみを参照すること。

---

## 5. Implementation Rules（実装ルール）

* Tailwind クラス変更禁止
* UI 改変禁止
* Props の追加・削除禁止
* コンポーネントロジックの変更禁止
* import パスの統一以外の変更禁止
* ディレクトリ構成の“推測による変更”禁止

---

## 6. Procedure（Windsurf 実行内容）

### Step 1: 参照状況調査（AST解析）

* プロジェクト全体（src/app, src/components, tests）を静的解析し、
  `login/AuthCallbackHandler/` 配下の 2 ファイルが **import されているか** を判定
* 全参照パスをリストアップし、CodeAgent_Report に記録する

### Step 2: 参照されている場合（移動する）

1. `src/components/auth/AuthCallbackHandler/` へ **移動のみ** を実施
2. import パスを `@/src/components/auth/AuthCallbackHandler/...` に統一
3. Storybook / Jest / TypeCheck / Lint を実行
4. エラーがあれば自動修正（構造関連のみ）

### Step 3: 参照されていない場合（削除する）

1. 以下の命名規則でバックアップを作成：

   ```
   <元ファイル名>_20251114_v0.1.bk
   ```
2. バックアップは **同一ディレクトリ内** に配置
3. 元ファイルを削除
4. TypeCheck / Lint を実行し、影響が無いことを確認

---

## 7. Acceptance Criteria（受入基準）

* TypeScript エラー: **0件**
* ESLint エラー: **0件**
* Storybook: 全表示正常
* Jest: 全テスト成功
* import パスが公式ルールに完全準拠
* 誤フォルダの除去または移動後の構成が正式構成と一致
* Windsurf SelfScore: **9.0以上**

---

## 8. CodeAgent_Report（必須）

Windsurf は完了後、以下形式でレポートを出力すること：

```
[CodeAgent_Report]
Agent: Windsurf
Task: AuthCallbackHandler-Cleanup
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - WS-AuthCallbackHandler-Cleanup_v1.0
 - harmonet-frontend-directory-guideline_v1.0
 - AuthCallbackHandler.tsx
 - login/AuthCallbackHandler/*.tsx
[Generated_Files]
 - <移動または削除されたファイル一覧>
Summary:
 - 参照状況の結果
 - 実施した処理の概要
 - 注意点
```

---

## 9. Backup Rules（削除が必要な場合）

バックアップ命名規則：

```
<元ファイル名>_20251114_v0.1.bk
```

保存場所：元ファイルと同一ディレクトリ。

削除後は `.bk` ファイルのみを残し、参照対象外とする。
