# WS-SYSTEM ReorganizeFrontendStructure v1.0

※ 本タスクは HarmoNet 公式フロントエンドディレクトリ規則

```
/01_docs/00_プロジェクト管理/01_運用ガイドライン/harmonet-frontend-directory-guideline_v1.0.md
```

に完全準拠すること。

（ここに既存の作業指示書全文を後続更新で挿入します）


## 1. Execution Goal（目的）

HarmoNet フロントエンドのディレクトリ構成を正式仕様（v1.0）へ再整理し、
すべての import パスを **Windsurf による自動修正で完全一致**させる。

目的は以下の通り：

* 掲示板、施設予約、ログイン画面を含む **全 UI コンポーネントの階層を統一**
* MagicLinkForm（A-01）・PasskeyButton（A-02）を **同一機能階層で整理**
* Storybook・Jest test・index.ts のすべての import パスを **一括修正**
* Windsurf の後続実装タスクで **迷いゼロの環境**にする

本タスクは “構造再整理” であり、**UI やロジックの変更は禁止**。
コンポーネントの内容を編集してはならない。レイアウト・機能・UI トーンはすべて従来通りとする。

---

## 2. Scope（対象範囲）

### ✔ Windsurf が操作してよいもの

* `src/components/` 配下のディレクトリ移動
* import パスの自動置換（全 .tsx / .ts / .stories.tsx / .test.tsx）
* index.ts の export 参照修正
* Storybook / Test / Lint / TypeCheck のエラー解消

### ❌ Windsurf が編集してはいけないもの

* コンポーネント内容のロジック修正
* Tailwind クラスの変更
* UI・デザインの書き換え
* ファイル削除（移動のみ許可）
* ディレクトリを勝手に追加（一括指示内のみ許可）
* コーディング規約・命名規則の変更

---

## 3. Frontend Official Directory Structure v1.0（正式構成）

**HarmoNet のフロントエンドは以下構成に統一する。これ以外の階層作成は禁止。**

```
src/
  components/
    common/                 ← C-01〜C-05
      AppHeader/
      AppFooter/
      LanguageSwitch/
      FooterShortcutBar/
      StaticI18nProvider/

    auth/                   ← A-01〜A-03（ログイン系）
      MagicLinkForm/
      PasskeyButton/
      AuthCallbackHandler/

    ui/                     ← 汎用 UI
    hooks/                  ← 再利用 Hooks
    utils/                  ← Utility（旧ファイルは _deprecated へ）

app/
  layout.tsx                ← ルート
  login/                    ← ログイン画面
    page.tsx
  auth/
    callback/
      page.tsx
```

---

## 4. Before / After 移動マップ（必ずこの通りに移動する）

### 4.1 MagicLinkForm（A-01）

**Before**

```
src/components/auth/MagicLinkForm/MagicLinkForm.tsx
```

※ 正しい位置 → 変更不要

**After**

```
src/components/auth/MagicLinkForm/MagicLinkForm.tsx
```

### 4.2 PasskeyButton（A-02）

**Before**

```
src/components/login/PasskeyButton/PasskeyButton.tsx
```

**After**

```
src/components/auth/PasskeyButton/PasskeyButton.tsx
```

### 4.3 AuthCallbackHandler

（存在する場合）

```
src/components/auth/AuthCallbackHandler/*
```

→ unchanged

### 4.4 Deprecated Utility

```
src/components/auth/utils/#_old/*
```

→ `src/components/utils/_deprecated/` に移動

---

## 5. import パスの正規表現置換ルール

Windsurf は AST ベースで以下の置換を実行する。

### 5.1 PasskeyButton の参照置換

```
from "@/src/components/login/PasskeyButton/PasskeyButton"
→ from "@/src/components/auth/PasskeyButton/PasskeyButton"
```

### 5.2 MagicLinkForm の参照

```
from "@/src/components/auth/MagicLinkForm/MagicLinkForm"
```

※ 正しいため変更不要

### 5.3 Header / Footer / LanguageSwitch / StaticI18nProvider

```
from "@/src/components/common/..."
```

※ すべて `common/` 下で統一、変更不要

### 5.4 app 配下のファイル（login/page.tsx）

```
import { MagicLinkForm } from "@/src/components/auth/MagicLinkForm/MagicLinkForm";
import { PasskeyButton } from "@/src/components/auth/PasskeyButton/PasskeyButton";
```

### 5.5 Storybook / Test の修正

以下すべてを同一ルールで置換。

```
*.stories.tsx
*.test.tsx
index.ts
```

---

## 6. Windsurf 実行手順（安全ステップ）

### Step 1: ディレクトリ移動

* Before / After マップに従って、**移動のみ**を行う。
* 削除禁止。rename禁止。

### Step 2: import パスの AST 置換

* すべての TypeScript ファイルを静的解析し、旧パス → 新パスへ置換
* 正規表現置換は使用せず、必ず AST で解決する（誤置換防止）

### Step 3: index.ts の export を整合

### Step 4: Jest / Storybook / TypeCheck 実行

### Step 5: Lint (ESLint) 実行

### Step 6: エラーゼロになるまで自動修正

### Step 7: CodeAgent_Report を作成し提示

---

## 7. 禁止事項（Windsurf向け）

* UI コンポーネントのリファクタリング禁止
* コンポーネントロジックの改変禁止
* Tailwind className 変更禁止
* Props の追加/削除禁止
* ディレクトリ構成の“推測による”再整理禁止
* ユーティリティの統廃合禁止（指定範囲外）

唯一許可されるのは：

* ディレクトリ移動
* import パスの修正
* index.ts の export 修正
* Test/Storybook の import 整合調整

---

## 8. Acceptance Criteria（受け入れ基準）

Windsurf がタスクを完了したと判断できる条件：

* TypeScript エラー **0件**
* ESLint エラー **0件**
* Storybook がすべて正常に表示される
* Jest の全 test が通過
* app/login/page.tsx が正しく動作
* PasskeyButton / MagicLinkForm が正しく importされる
* 既存 UI が一切崩れない
* ディレクトリ構成が **本書の v1.0 と完全一致**
* Windsurf SelfScore が **9.0 以上**

---

## 9. CodeAgent_Report（Windsurf 出力フォーマット）

Windsurf は完了後、以下の形式でレポートを出力する：

```
[CodeAgent_Report]
Agent: Windsurf
Component: ReorganizeFrontendStructure
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed
Lint: Passed
TestPassRate: 100%
References:
 - WS-SYSTEM_ReorganizeFrontendStructure_v1.0
 - MagicLinkForm (A-01)
 - PasskeyButton (A-02)
 - AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider
Summary:
 - Directory structure reorganized
 - All imports updated
 - TypeCheck / Lint / Tests passed
```

---

## 10. 完了後の状態（期待成果）

* HarmoNet フロントエンドが正式構成 v1.0 に統一
* import パスの問題が **完全解消**
* 後続の A-01, A-02, A-03, C-01〜C-05 の実装精度が最大化
* Windsurf / Cursor / Claude すべてが **迷いなく参照できる環境** になる
* 今後の機能追加（掲示板・予約機能など）の負債がゼロ化

---

以上が Windsurf によるフロントエンド再構成タスクの正式指示書である。
