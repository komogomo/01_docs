# WS-A00_LoginPageIntegration_v1.0

## 目的

LoginPage（A-00）を詳細設計 v1.3 に基づき、MagicLinkForm（A-01）と PasskeyAuthTrigger（A-02）を UI として正しく統合する。i18n キーが画面上にそのまま表示される問題を解消し、設計書と同じ文言・レイアウトが `/login` に再現される状態を実現する。

## 作業範囲

1. `/app/login/page.tsx` の UI レイアウトを設計書どおりに構築する。
2. 画面タイトル「Harmony Network」、サブ説明文「入居者様専用コミュニティアプリ」を配置。
3. 中央にカードコンテナ（white / rounded-2xl / shadow-sm）を配置し、その内部に MagicLinkForm を組み込む。
4. MagicLinkForm 内の i18n キー（auth.login.magiclink.* / auth.login.passkey.*）が実文言になるよう、`/locales/ja/en/zh/common.json` を更新し、必要キーを追加する。
5. UI 位置調整（余白・中央寄せ・max-w-md・レスポンシブ）を LoginPage 側で実施。
6. MagicLinkForm / PasskeyAuthTrigger のロジック・Tailwind・状態管理には手を入れない。

## 禁止事項

* Supabase / Corbado ロジックの変更
* MagicLinkForm.tsx / PasskeyAuthTrigger.tsx の編集
* ディレクトリ移動・rename
* Jest/Vitest 設定変更
* i18n 構造変更（キー追加のみ可）

## 参照資料（必須パス）

* /01_docs/04_詳細設計/01_ログイン画面/A-00LoginPage-detail-design_v1.3.md
* /01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_v1.3.md
* /01_docs/04_詳細設計/01_ログイン画面/PasskeyAuthTrigger-detail-design_v1.4.md
* /01_docs/04_詳細設計/00_共通部品/01_ログイン画面/共通部品詳細設計/ch03_StaticI18nProvider_v1.1.md
* /public/locales/ja/common.json
* /public/locales/en/common.json
* /public/locales/zh/common.json
* /app/login/page.tsx
* /01_docs/06_品質チェック/CodeAgent_Report_LoginPageIntegration_v1.1.md

## 成果物

* `app/login/page.tsx`（更新）
* `locales/ja/common.json` / `en/common.json` / `zh/common.json`（必要キー追加）
* `/01_docs/06_品質チェック/CodeAgent_Report_LoginPageIntegration_v1.0.md`
