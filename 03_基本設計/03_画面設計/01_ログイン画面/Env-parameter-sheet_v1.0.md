# HarmoNet 環境変数パラメータシート v1.0

**目的:** すべての認証・外部サービス・Next.js/Supabase/Corbado の環境依存値を一元管理し、設計書と切り離して安全に運用する。

**備考:** Corbado アカウント登録後、Corbado ダッシュボードにて発行される値をこのシートに更新するだけで良い。

---

## 1. Corbado（Passkey認証）関連

| key名                               | 用途                       | dev（ローカル）                             | prod（本番）                             | 備考                 |
| ---------------------------------- | ------------------------ | ------------------------------------- | ------------------------------------ | ------------------ |
| `NEXT_PUBLIC_CORBADO_PROJECT_ID`   | Corbado プロジェクト識別子        | `<未設定>`                               | `<未設定>`                              | **公開可**（React側で必要） |
| `NEXT_PUBLIC_CORBADO_BASE_URL`     | Corbado Hosted UI ベースURL | `<未設定>`                               | `<未設定>`                              | Corbado の提供値       |
| `NEXT_PUBLIC_CORBADO_API_ENDPOINT` | Corbado API エンドポイント      | `<未設定>`                               | `<未設定>`                              | 通常 `/api`          |
| `CORBADO_API_SECRET`               | Corbado Node Secret      | `<未設定>`                               | `<Vercel Secrets>`                   | **非公開・サーバ専用**      |
| `NEXT_PUBLIC_RP_ID`                | Passkey RP ID（= ドメイン）    | `localhost`                           | `harmonet.app`                       | WebAuthn 要件        |
| `NEXT_PUBLIC_CORBADO_REDIRECT_URL` | 認証後 redirect URL         | `http://localhost:3000/auth/callback` | `https://harmonet.app/auth/callback` | Corbado 設定で必要      |
| `CORBADO_WEBHOOK_SECRET`           | Webhook 用（将来B方式）         | `<未設定>`                               | `<未設定>`                              | MVP では未使用          |

---

## 2. Supabase（MagicLink / DB / Storage）関連

| key名                            | 用途           | dev（docker/.env）         | prod（Vercel環境）         | 備考                     |
| ------------------------------- | ------------ | ------------------------ | ---------------------- | ---------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Supabase URL | `http://localhost:54321` | `<Supabase提供値>`        | 公開可                    |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | anon key     | `<自動生成>`                 | `<Supabase提供値>`        | 公開可                    |
| `SUPABASE_SERVICE_ROLE_KEY`     | サービスロールキー    | `<docker/.env>`          | `<Vercel Secrets>`     | **非公開**                |
| `NEXT_PUBLIC_APP_URL`           | アプリURL       | `http://localhost:3000`  | `https://harmonet.app` | MagicLink redirect に必要 |
| `NEXT_PUBLIC_AUTH_CALLBACK_URL` | 認証 callback  | `/auth/callback`         | `/auth/callback`       | 相対パス運用も可               |

---

## 3. Next.js / App Router 共通

| key名                 | 用途              | dev                     | prod                   | 備考           |
| -------------------- | --------------- | ----------------------- | ---------------------- | ------------ |
| `NODE_ENV`           | 環境識別            | development             | production             | 自動設定         |
| `NEXT_PUBLIC_ORIGIN` | WebAuthn origin | `http://localhost:3000` | `https://harmonet.app` | RP ID と一致させる |
| `NEXT_PUBLIC_ENV`    | 任意の環境ラベル        | dev                     | prod                   | 画面側切替用（任意）   |

---

## 4. Google 翻訳 / 音声（VOICEVOX）

| key名                       | 用途          | dev                      | prod               | 備考               |
| -------------------------- | ----------- | ------------------------ | ------------------ | ---------------- |
| `GOOGLE_TRANSLATE_API_KEY` | 翻訳API       | `<local>`                | `<Vercel Secrets>` | 非公開              |
| `VOICEVOX_API_URL`         | TTS API URL | `http://localhost:50021` | `<本番URL>`          | devはローカルVOICEVOX |
| `REDIS_URL`                | 翻訳・TTSキャッシュ | `<未設定>`                  | `<未設定>`            | 将来導入             |

---

## 5. Windsurf / AI アクセスキー（必要なら）

| key名                   | 用途              | dev       | prod               | 備考                  |
| ---------------------- | --------------- | --------- | ------------------ | ------------------- |
| `X_HARMONET_AGENT_KEY` | AI Proxy API 呼出 | `<local>` | `<Vercel Secrets>` | Windsurf / Gemini 用 |

---

## 6. 設定者メモ（更新履歴欄）

| 日付         | 更新者 | 更新内容                   |
| ---------- | --- | ---------------------- |
| 2025-11-17 | TKD | 初回作成（Corbado未設定のため空欄）  |
| 2025-11-XX | TKD | Corbado プロジェクト作成後に値を反映 |

---

## 7. 今後の更新方法

1. Corbado で **プロジェクト作成** → Dashboard → Project Settings → API キー取得
2. 本シートの該当行を更新
3. `.env.local` および Vercel Secrets へ反映
4. Windsurf 実装タスクの参照ドキュメントに本シートを追加

これにより、**設計書を改版せずに環境値のみを安全に更新**できます。
