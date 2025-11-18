# Corbado アカウント登録 → サンドボックスプロジェクト作成手順 v1.0

**目的**: HarmoNet の PasskeyBackend 実装のために Corbado の開発用アカウントとサンドボックスプロジェクトを作成し、フロント側で Passkey を動かして `idToken` を取得できる状態にする。

**想定実行者**: TKD（ローカル操作：ブラウザ・開発マシン）

**実行ディレクトリ**: `D:\Projects\HarmoNet`（必要ファイルはこの配下に置く想定）

---

## 1. 準備（事前確認）

* ブラウザ（Chromium / Chrome / Edge / Safari）と Passkey 対応デバイス（Touch ID, Windows Hello, セキュリティキー 等）を用意する。
* Corbado のアカウント作成に使うメールアドレスを用意する。

## 2. Corbado アカウント登録（手順）

1. Corbado の公式ドキュメントまたはトップ（Getting Started）にアクセスしてサインアップページへ移動。
2. メールアドレス／パスワード等でアカウントを作成し、メール確認を行う（メール内リンクでアクティベート）。
3. ダッシュボードにログイン後、画面の案内に従い新規プロジェクトを作成する（プロジェクト名は `harmonet-dev` など分かりやすい名称）。

   * プロジェクト作成時に「Web app / Fullstack / Connect など」選択肢が出る場合は **Web app** を選ぶ。

> 備考: Corbado の quick-start / Getting started に、プロジェクト作成〜フロント統合までの手順がまとまっている。実際の画面案内に従って進めてください。

## 3. プロジェクト設定で取得する情報（必須）

* **Project ID**（例: `NEXT_PUBLIC_CORBADO_PROJECT_ID` 相当） — フロントで使用
* **API シークレット / Server API key**（`CORBADO_API_SECRET`） — サーバ側での ID トークン検証に使用（**絶対に公開しない**）
* **Callback / Redirect URLs**（必要があればフロントの origin とコールバック URL を登録）

## 4. 環境変数設定（ローカル開発）

プロジェクトルートの `.env.local`（Next.js 想定）に下記を設定：

```
NEXT_PUBLIC_CORBADO_PROJECT_ID=<your_project_id>
CORBADO_API_SECRET=<your_server_secret>
NEXT_PUBLIC_SUPABASE_URL=https://<your_supabase>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your_supabase_service_role_key>  # server-only
```

* 注意: `CORBADO_API_SECRET` と `SUPABASE_SERVICE_ROLE_KEY` は**サーバ側専用**。本番では Vercel / Netlify 等の Secrets 機能を使う。

## 5. フロント側の簡易動作確認（手順）

1. HarmoNet フロント（ローカル）を起動し、PasskeyAuthTrigger（A-02）を表示する画面にアクセス。
2. Passkey の作成/ログインをユーザ操作で実行（Touch ID / Windows Hello 等）。
3. ブラウザの DevTools の Network タブ／Console で、フロントが受け取る `idToken` を確認。トークンはサーバへ送るため、一時的にコピーしておく。

## 6. サーバ側での検証（短手順）

1. 既存の `app/api/auth/passkey/route.ts` に `POST` 実装があることを確認。
2. 取得した `idToken` を `POST /api/auth/passkey` に投げて動作確認（例: `curl` または Postman）。
3. サーバ側で `verifyIdToken`（Corbado SDK または JWKS）→ `supabase.auth.signInWithIdToken` の流れで成功するか確認。

## 7. 次の推奨タスク（実施順）

1. Corbado トークンのクレーム内容を `jwt.decode` で確認（`iss`/`aud`/`exp`/`sub` 等）。
2. サーバ側で署名検証（SDK か `jose` + JWKS）を実装して正常系／異常系を確認する。
3. `passkey_credentials` への upsert をテスト。

## 8. セキュリティ注意点（必読）

* サーバで受け取った ID トークンや秘密情報をログに残さない。
* `CORBADO_API_SECRET` と `SUPABASE_SERVICE_ROLE_KEY` は厳密にサーバ限定で取り扱い、本番は環境シークレット管理を利用する。

## 9. 参照（実務上の補助）

* Corbado: Getting Started / Docs — フロント統合とプロジェクト作成の案内に従うこと。
* Corbado: Node SDK — サーバ側での検証用 SDK。

---

**End of onboarding doc**
