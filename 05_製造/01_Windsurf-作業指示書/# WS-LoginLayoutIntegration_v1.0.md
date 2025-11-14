# WS-LoginLayoutIntegration_v1.0

（TKD確認前の初期ドラフト。内容確認後に修正します）

## 1. Task Summary

* **目的:** HarmoNet ログイン画面を設計書どおりの正式構造へ統合し、UI 階層・import・レイアウトの不整合を 100% 解消すること。
* **期待値:** Windsurf が作業後に、`app/layout.tsx` と `app/login/page.tsx` が設計書の構造と完全一致し、動作・UI・Storybook・テストがすべて安定した状態に到達していること。

### Windsurf が行う作業（必要なことだけ明示）

1. **UI 構造の修正**

   * 設計書で定義された正しい構成：
     StaticI18nProvider → AppHeader → Main（MagicLinkForm + PasskeyAuth）→ AppFooter
   * `app/layout.tsx` / `app/login/page.tsx` をこの構造に“並べ直す”こと。

2. **import の正規化（AST ベース）**

   * 共通部品 → `@/src/components/common/...`
   * 認証部品 → `@/src/components/auth/...`

3. **Storybook / Jest / TypeCheck / Lint のエラーが“構造・import 由来のもののみ”解消されていること。**

### Windsurf に不要なもの（禁止事項）

* **UI 改善提案・最適化・自動補完の実施禁止**（要求された範囲外の変更は一切不可）
* **ファイル生成禁止（CodeAgent_Report を除く）**
* **ディレクトリ移動禁止**（指定された正式構成 v1.0 からの逸脱禁止）
* **新規フォルダ作成禁止**
* **コンポーネントロジック変更禁止**
* **Tailwind クラス変更禁止**

---

## 2. Target Files（Windsurf が **編集するだけ** の既存ファイル）

以下は Windsurf が **作成せず・移動せず・削除せずに、編集のみ** を許可された既存ファイル一覧です。これ以外のファイルは一切触ってはならない。

### ■ 編集対象（UI構造と import 整合のために修正可能）

1. `app/layout.tsx`

   * StaticI18nProvider → AppHeader → {children} → AppFooter の構造に整える。
   * import パスの正規化。

2. `app/login/page.tsx`

   * MagicLinkForm / PasskeyTrigger の配置を設計書どおりに整える。
   * import パスの正規化。

3. 共通部品（**編集は import のみ**）

   * `src/components/common/AppHeader/*`
   * `src/components/common/LanguageSwitch/*`
   * `src/components/common/StaticI18nProvider/*`
   * `src/components/common/AppFooter/*`

4. 認証部品（**編集は import のみ**）

   * `src/components/auth/MagicLinkForm/*`
   * `src/components/auth/PasskeyButton/*`（※統合後は参照されない可能性あり）
   * `src/components/auth/AuthCallbackHandler/*`

5. Storybook / Jest / TypeCheck 用ファイル（**import のみ**)

   * `*.stories.tsx`
   * `*.test.tsx`
   * `index.ts`

### ■ Windsurf が絶対に触ってはならないもの

* ディレクトリ構成
* ファイル名
* 新規ファイル追加
* フォルダ作成
* コンポーネントロジック変更
* Tailwind クラス変更
* UI トーンの変更

---

## 3. Import & Directory Rules

* import パスは `@/src/...` に統一すること。
* 既存ファイルの rename / 削除は禁止（指示がある場合のみ許可）。
* フロントエンド構成 v1.0 に準拠すること。

---

## 4. References

以下は Windsurf が参照する **唯一の正** とする設計書のファイルパス。

* `/01_docs/04_詳細設計/01_ログイン画面/A-00_LoginPage-detail-design_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_v1.1.md`
* `/01_docs/04_詳細設計/01_ログイン画面/PasskeyAuthTrigger-detail-design_v1.1.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch01_AppHeader_v1.1.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch02_LanguageSwitch_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch03_StaticI18nProvider_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch04_AppFooter_v1.0.md`

---

## 5. Implementation Rules

* Tailwind クラス改変禁止。
* UI レイアウトは HarmoNet 仕様書に完全準拠。
* Props の追加・削除禁止。
* フォルダ構成変更禁止。
* 外部ライブラリ追加禁止。

---

## 6. Acceptance Criteria

* TypeCheck 0 エラー
* ESLint 0 エラー
* Prettier 0 エラー
* Jest テスト PASS
* Storybook レンダリング崩れなし
* SelfScore 9.0 以上

---

## 6.5 Backup Rules

既存ファイル修正時:

```
<元ファイル名>_<YYYYMMDD>_v0.1.bk
```

保存場所: 元ファイルと同一ディレクトリ

---

## 7. Forbidden Actions

* 勝手な UI 変更
* ファイル名変更
* ディレクトリ構造変更
* 追加の最適化・改善

---

## 8. CodeAgent_Report（必須）

Windsurf 完了後、以下形式で出力:

```
[CodeAgent_Report]
Agent: Windsurf
Task: LoginLayoutIntegration
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
- <参照1>
- <参照2>
[Generated_Files]
- <生成/変更ファイル>
Summary:
- 実施概要
- 注意点
```

保存先:

```
/01_docs/05_品質チェック/CodeAgent_Report_LoginLayoutIntegration_v1.0.md
```

---

## 9. Testing Method

### UI / Layout

* Storybook で idle / sending / success を確認。
* Tailwind クラスの反映確認。

### Jest / RTL

```
npm test
```

### TypeCheck / Lint / Build

```
npm run type-check
npm run lint
npm run build
```

---

## 10. 改訂履歴

* v1.0 (2025-11-14): 初期ドラフト
