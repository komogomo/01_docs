# WS-A00_LoginPageIntegration_v1.0

（TKD確認前の初期ドラフト。内容確認後に修正します）

---

## 1. Task Summary

**目的:** A-00 LoginPage の JSX 構造と import を、A-01 / A-02 / C-01 / C-03 / C-04 各設計書に基づき正規化し、HarmoNet の正式ログイン画面構造へ統合する。
**期待値:** Windsurf の実行後、`app/login/page.tsx` が設計書の「正しい画面構成」と完全一致し、ヘッダーとフッター配置、MagicLinkForm 統合、PasskeyTrigger 統合が破綻なく成立していること。

### Windsurf が行う作業（正確性のみ / 独自判断禁止）

1. `app/login/page.tsx` の JSX を **A-00 設計書の画面構成に完全一致**させる。
2. import パスを **AST で `@/src/...` に正規化**する。
3. MagicLinkForm + PasskeyTrigger の **並び・責務・JSX 構造を壊さず**統合する。
4. AppHeader / AppFooter の配置は **LoginLayout（app/layout.tsx）側で行われるため page.tsx には追加しない**。
5. Storybook / Jest / TypeCheck / Lint のエラーが **import / JSX 不整合由来のもののみ**解消されていること。

### Windsurf 禁止事項

* UI の変更 / デザイン最適化 全面禁止
* 新規ファイル生成禁止（CodeAgent_Report を除く）
* ディレクトリ移動禁止
* Tailwind クラス変更禁止
* ロジック変更禁止
* MagicLinkForm / PasskeyTrigger のコード改変禁止（import 除く）

---

## 2. Target Files（編集のみ許可された既存ファイル）

以下 **以外は一切触ってはならない**。

### ■ 編集対象（A-00 LoginPage 統合）

1. `app/login/page.tsx`

   * JSX を A-00 設計書どおりに構成
   * `MagicLinkForm` と PasskeyTrigger（MagicLinkForm 内）統合
   * import 正規化

### ■ import 修正のみ許可

* `src/components/pages/LoginPage/*`
* `src/components/login/MagicLinkForm/*`
* `src/components/auth/*`
* `src/components/common/AppHeader/*`
* `src/components/common/AppFooter/*`
* `src/components/common/StaticI18nProvider/*`

### ■ Storybook / Jest（import のみ）

* `*.stories.tsx`
* `*.test.tsx`
* `index.ts`

---

## 3. References（唯一の正 / Windsurf はここ以外を参照しない）

* `/01_docs/04_詳細設計/01_ログイン画面/A-00_LoginPage-detail-design_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_v1.1.md`
* `/01_docs/04_詳細設計/01_ログイン画面/PasskeyAuthTrigger-detail-design_v1.1.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch01_AppHeader_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch02_LanguageSwitch_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch03_StaticI18nProvider_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch04_AppFooter_v1.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/ch05_FooterShortcutBar_v1.0.md`

---

## 4. Expected Final Structure（完成後の正しい JSX / Windsurf が守るべき状態）

LoginPage は **純粋に MagicLinkForm を中央に配置するだけ**の stateless ページとする。
AppHeader / AppFooter は `app/layout.tsx` でラップ済みのため page.tsx に含めない。

```tsx
// app/login/page.tsx
'use client';
import { MagicLinkForm } from '@/src/components/auth/MagicLinkForm';

export default function LoginPage() {
  return (
    <main className="flex flex-col items-center justify-center min-h-screen bg-white px-4 py-10 gap-6">
      <MagicLinkForm />
    </main>
  );
}
```

### 重要ポイント（破壊禁止）

* Passkey 認証は MagicLinkForm 内で自動的に処理される（A-01/A-02 設計仕様）。
* LoginPage には PasskeyButton を置かない（撤廃済）。
* LoginPage にヘッダー/フッターは置かない（layout.tsx にて統合済）。

---

## 5. Implementation Rules

* import はすべて `@/src/...` に統一する。
* LoginPage は常に **pure component** とし、状態管理を追加しない。
* A-00/A-01/A-02 各仕様の JSX 構造を壊してはならない。
* MagicLinkForm の state や handler には手を触れない。
* UI トーン（やさしく・自然・控えめ）に関わる要素は絶対に変更しない。

---

## 6. Acceptance Criteria

* TypeCheck Passed
* Lint 0 エラー
* Jest 全テスト PASS
* Storybook レンダリング崩れなし
* SelfScore 9.0 以上
* 最終 JSX / import が本指示書の Expected Final Structure と完全一致

---

## 7. Backup Rules

編集対象ファイルは以下形式でバックアップを必ず作成：

```
<ファイル名>_YYYYMMDD_v0.1.bk
```

保存場所は元ファイルと同一ディレクトリ。

---

## 8. CodeAgent_Report（必須）

Windsurf は完了後、以下形式でレポートを出力する。

```
[CodeAgent_Report]
Agent: Windsurf
Task: LoginPageIntegration
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - WS-A00_LoginPageIntegration_v1.0
 - harmonet-frontend-directory-guideline_v1.0
[Generated_Files]
 - <編集・生成されたファイル一覧>
Summary:
 - 実施した処理の概要
 - 注意点
```

出力先パス：

```
/01_docs/06_品質チェック/CodeAgent_Report_LoginPageIntegration_v1.0.md
```

---

## 9. 改訂履歴

* v1.0 (2025-11-14): 初期ドラフト
