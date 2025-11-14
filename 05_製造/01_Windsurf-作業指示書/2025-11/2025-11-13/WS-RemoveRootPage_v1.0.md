# WS-RemoveRootPage v1.0

**Task:** `/app/page.tsx` を物理削除し、旧UI（PasskeyButton・logo.svg・旧Header）が表示される問題を永続的に解消する。
**Agent:** Windsurf
**目的:** HarmoNet 正式仕様（v4.2）ではトップページは未定義のため、`/app/page.tsx` を保持すると UI 汚染が発生する。これを完全に排除する。

---

## 1. 対象ファイル

* **削除:** `app/page.tsx`
* **確認のみ:** `app/layout.tsx`
* **変更禁止:** `app/login/page.tsx`, `app/auth/callback/page.tsx`

---

## 2. 作業内容（安全ステップ）

### Step 1: page.tsx 存在確認

`app/page.tsx` が存在する場合のみ削除。

### Step 2: 物理削除（rename禁止）

* rename, コメントアウトは **禁止**。
* 必ずファイルを削除（unlink）する。

### Step 3: import 残骸チェック

削除後、以下がプロジェクト内に残っていないこと：

* `PasskeyButton` の import（旧A-02）
* `logo.svg` の参照
* 旧Header（黒バー + HarmoNet テキスト）
* MagicLinkForm 以外の旧ログインUI

### Step 4: TypeCheck / Lint / DevServer / Storybook

すべてエラーなしで起動すること。

### Step 5: ルート挙動確認

* `http://localhost:3000/` アクセス時は **404** または空で問題なし。
* ログイン画面 `http://localhost:3000/login` が正式UIで正常表示されること。

---

## 3. 禁止事項

* `/app/login/page.tsx` の内容変更禁止
* 新規UIの追加禁止
* 推測補完による JSX 自動追加禁止
* `page.tsx` の rename（例: `page_old.tsx`）禁止
* 旧PasskeyButtonの復活禁止
* Storybookロゴ（logo.svg）の参照禁止

---

## 4. Acceptance Criteria

* `/app/page.tsx` が存在しない
* DevServer / Storybook すべてエラーなし
* `/login` が正式HarmoNet UIで表示される
* 「保存」ボタン（旧A-02）が完全に消える
* Storybookロゴ（logo.svg）が出ない
* SelfScore 9.0 以上

---

## 5. CodeAgent_Report 保存先

```
/01_docs/05_品質チェック/CodeAgent_Report_RemoveRootPage_v1.0.md
```

Windsurf は実行完了後、このパスへレポートを保存すること。

---

## 6. 参照（公式フロントエンド構成 v1.0）

```
src/
  components/
    common/
      AppHeader/
      AppFooter/
      LanguageSwitch/
      StaticI18nProvider/
      FooterShortcutBar/

    auth/
      MagicLinkForm/
      PasskeyButton/
      AuthCallbackHandler/

app/
  layout.tsx
  login/page.tsx
  auth/callback/page.tsx
```

* 未定義ディレクトリ作成禁止
* import は `@/src/...` に統一

---

以上が `/app/page.tsx` を削除し、UI汚染を完全排除するための Windsurf 正式指示書である。
