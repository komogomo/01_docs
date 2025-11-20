# HarmoNet 機能要件定義書 第5章（外部API・認証・環境構成） v1.8

**準拠:** HarmoNet Functional Requirements v1.6（MagicLink / Google Translation API v3 / Google Cloud TTS）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式版（v1.6 完全整合）
**Updated:** 2025-11-19

---

# 1. 目的と適用範囲

本章は HarmoNet における **外部API連携・認証方式・環境変数構成** を定義する。

* 認証：**Supabase MagicLink（OTP + PKCE）**
* 翻訳：**Google Translation API v3（/api/translate）**
* 音声化：**Google Cloud Text-to-Speech（/api/tts）**
* DB / Storage：Supabase PostgreSQL / Supabase Storage
* 通知：Supabase Realtime
* AI連携：Gemini / Windsurf（/api/ai-proxy）

旧仕様（VOICEVOX / Passkey / EdgeFunction / Redis 必須）はすべて廃止し、新構成へ統一する。

---

# 2. 外部API連携要件

## 2.1 翻訳 API（Google Translation API v3）

| 項目    | 内容                                               |
| ----- | ------------------------------------------------ |
| サービス  | Google Cloud Translation API v3                  |
| 呼出方法  | Next.js API Route `/api/translate`（サーバーサイド処理）    |
| キャッシュ | `translation_cache`（Supabase DB）、必要時のみ Redis（任意） |
| 対応言語  | 日本語・英語・中国語（簡体）                                   |
| 認証方式  | Google API Key（Vercel Secrets で管理）               |

### 処理方針

```
1. /api/translate が翻訳リクエストを受信
2. translation_cache を参照
3. キャッシュヒット → 即返却
4. キャッシュなし → Google Translate API 呼出
5. 結果を translation_cache に保存
6. 翻訳結果をクライアントに返却
```

---

## 2.2 音声変換 API（Google Cloud Text-to-Speech）

| 項目    | 内容                                     |
| ----- | -------------------------------------- |
| サービス  | Google Cloud Text-to-Speech            |
| 呼出方法  | Next.js API Route `/api/tts`           |
| 音声形式  | mp3                                    |
| キャッシュ | Supabase Storage（`tts_cache`）＋ DB メタ情報 |
| 対応言語  | 日本語 / 英語 / 中国語（簡体 / 繁体）                |

### 処理フロー

```
1. /api/tts が音声リクエストを受信
2. tts_cache（DB/Storage）を参照
3. キャッシュヒット → 音声 URL を返却
4. キャッシュなし → Google TTS 呼出
5. Storage に保存し、tts_cache テーブルへ登録
6. 音声 URL を返却
```

---

## 2.3 AI 連携 API（Gemini / Windsurf）

| 項目   | 内容                                |
| ---- | --------------------------------- |
| サービス | Gemini / Windsurf（AI Proxy）       |
| 呼出方法 | Next.js API Route `/api/ai-proxy` |
| 用途   | 翻訳補完・仕様整合チェック・設計支援                |
| 認証   | JWT + 内部キー                        |
| ログ   | Supabase `audit_logs` に必要時のみ保存    |

---

# 3. 認証方式要件（MagicLink）

## 3.1 構成

| 項目   | 内容                                    |
| ---- | ------------------------------------- |
| 認証方式 | Supabase MagicLink（OTP + PKCE）        |
| 画面遷移 | `/login` → `/auth/callback` → `/home` |

### 認証フロー（確定）

```
/login
  ↓ signInWithOtp(email)
メールリンク
  ↓
/auth/callback
  Supabase クライアントが URL フラグメントから PKCE 認証
  セッション確立
  ↓
/home
  Server Component で認可チェック（user + user_tenants）
```

## 3.2 認可・セッション

* Supabase のセッション Cookie を唯一のログイン状態とする
* Server Component 側では認可のみを実施
* `public.users` と `auth.users` は同期（Trigger）
* RLS：`tenant_id = auth.jwt()->>'tenant_id'`

---

# 4. 環境変数・秘密情報構成

## 4.1 必須環境変数（最新版）

| 環境変数名                           | 用途                        | 管理場所           |
| ------------------------------- | ------------------------- | -------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Supabase 接続 URL           | .env.local     |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 匿名キー                      | .env.local     |
| `SUPABASE_SERVICE_ROLE_KEY`     | Server 用 Service Role Key | Vercel Secrets |
| `GOOGLE_TRANSLATE_API_KEY`      | Google 翻訳 API Key         | Vercel Secrets |
| `GOOGLE_TTS_API_KEY`            | Google Cloud TTS API Key  | Vercel Secrets |
| `NEXT_PUBLIC_APP_URL`           | CORS 許可 / リダイレクト用         | .env.local     |
| `REDIS_URL`（任意）                 | Redis キャッシュ利用時のみ          | .env.local     |

## 4.2 配置ルール

* `.env*` は Git 管理外
* Secrets は Vercel / GitHub Secrets に保持
* `NEXT_PUBLIC_*` の値のみブラウザに露出

---

# 5. 開発環境（Docker Desktop）

| 項目        | 内容                               |
| --------- | -------------------------------- |
| DB        | Supabase CLI（PostgreSQL 17）      |
| メール       | Mailpit（テストメール）                  |
| API       | Next.js API Routes（翻訳 / 音声 / AI） |
| 起動        | `supabase start`                 |
| 停止        | `supabase stop`                  |
| Migration | Prisma + Supabase Migrate        |

---

# 6. 本番環境（Supabase Cloud + Vercel）

| 項目     | 内容                             |
| ------ | ------------------------------ |
| DB     | Supabase Cloud（PostgreSQL 17）  |
| ホスティング | Vercel Pro                     |
| バックエンド | Next.js API Routes             |
| デプロイ   | GitHub Actions → Vercel 自動デプロイ |
| バックアップ | Supabase 自動スナップショット（保持 7 日）    |

---

# 7. 非機能品質（外部 API 視点）

| 区分      | 要件                              |
| ------- | ------------------------------- |
| 翻訳応答    | 1〜2 秒以内（Google Translation API） |
| 音声生成    | 1〜2 秒以内（Google Cloud TTS）       |
| API エラー | Google API 障害時は日本語へフォールバック      |
| 可用性     | Supabase / Vercel の SLA に準拠     |

---

# 8. ChangeLog

| Date       | Version | Summary                                                  |
| ---------- | ------- | -------------------------------------------------------- |
| 2025-11-19 | 1.8     | Google TTS 対応 / VOICEVOX 完全廃止 / Redis 任意化 / v1.6 構成へ全面刷新 |
| 2025-11-19 | 1.7     | VOICEVOX 版最終リビルド                                         |

---

**Directory:** `/01_docs/01_requirements/01_機能要件定義/`
