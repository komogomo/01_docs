# HarmoNet 機能要件定義書 第5章（外部API・認証・環境構成） v1.7

（MagicLink + Google 翻訳 + VOICEVOX + Next.js API Routes 方式）

**準拠:** HarmoNet Technical Stack Definition v4.3
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式版（MagicLink / Google 翻訳 / VOICEVOX 構成）
**Updated:** 2025-11-19

---

# 1. 目的と適用範囲

本章は HarmoNet における **外部API連携・認証方式・環境変数構成** を定義する。
構成要素は次である：

* Next.js 16.x（App Router）
* Supabase Auth（MagicLink + PKCE）
* Supabase PostgreSQL / Storage / Realtime
* Google Translation API v3（動的翻訳）
* VOICEVOX API（音声変換）
* Next.js API Routes（翻訳 / 音声のバックエンド処理）
* Docker Desktop（開発環境）

---

# 2. 外部API連携要件

## 2.1 翻訳 API（Google Translation API v3）

| 項目    | 内容                                          |
| ----- | ------------------------------------------- |
| サービス  | Google Cloud Translation API v3             |
| 呼出方法  | Next.js API Route `/api/translate`（サーバーサイド） |
| キャッシュ | `translation_cache`（Supabase）＋ Redis（任意）    |
| 対応言語  | 日本語・英語・中国語（簡体）                              |
| 認証方式  | Google API Key（Vercel Secrets 保持）           |

### 処理方針

```
1. Next.js API Route が受信
2. translation_cache を確認
3. キャッシュ無し → Google Translate API 呼出
4. Supabase に結果保存
5. 翻訳結果を返却
```

---

## 2.2 音声変換 API（VOICEVOX）

| 項目    | 内容                            |
| ----- | ----------------------------- |
| サービス  | VOICEVOX API（ローカル or 外部サーバー）  |
| 呼出方法  | Next.js API Route `/api/tts`  |
| 音声形式  | mp3 / wav                     |
| キャッシュ | Supabase Storage（`tts_cache`） |
| 利用範囲  | 掲示板投稿・お知らせ本文の読み上げ             |

### 処理フロー

```
1. Next.js API Route が TTS リクエストを受信
2. tts_cache を参照
3. なければ VOICEVOX API へリクエスト
4. Supabase Storage に保存
5. 音声URLを返却
```

---

## 2.3 AI 連携 API（Gemini / Windsurf）

| 項目   | 内容                                |
| ---- | --------------------------------- |
| サービス | Gemini / Windsurf の AI Proxy      |
| 呼出方式 | Next.js API Route `/api/ai-proxy` |
| 用途   | 翻訳補完・整合確認・設計生成支援                  |
| 認証   | JWT + HarmoNet 内部キー               |
| ログ   | Supabase `audit_logs` へ必要に応じて記録   |

---

# 3. 認証方式要件（MagicLink）

## 3.1 構成

| 項目   | 内容                                    |
| ---- | ------------------------------------- |
| 認証方式 | Supabase MagicLink（OTP + PKCE）        |
| 利用画面 | `/login` → `/auth/callback` → `/home` |

### 認証フロー（確定）

```
/login (MagicLinkForm)
  ↓ signInWithOtp(email)
メールリンク
  ↓
/auth/callback (Client Component)
  createBrowserClient が URL フラグメントを検出
  PKCE Exchange → セッション確立
  ↓
/home (Server Component)
  認可チェック（user + user_tenants）
```

## 3.2 Supabase Auth 要件

* PKCE を有効化（`detectSessionInUrl=true`）
* ブラウザ側でセッション維持
* Server Component では認可のみ実行
* `public.users` は `auth.users` と同期
* RLS は tenant_id + sub のハイブリッド方式

---

# 4. 環境変数・秘密情報構成

## 4.1 必須環境変数

| 環境変数名                           | 用途                   | 管理場所           |
| ------------------------------- | -------------------- | -------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Supabase 接続 URL      | .env.local     |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 匿名キー                 | .env.local     |
| `SUPABASE_SERVICE_ROLE_KEY`     | サーバー用 Service Role   | Vercel Secrets |
| `GOOGLE_TRANSLATE_API_KEY`      | 翻訳 API Key           | Vercel Secrets |
| `VOICEVOX_API_URL`              | VOICEVOX エンドポイント     | .env.local     |
| `REDIS_URL`                     | キャッシュ用 Redis 接続先     | .env.local     |
| `NEXT_PUBLIC_APP_URL`           | CORS 制御 / Redirect 用 | .env.local     |

## 4.2 配置ルール

* `.env*` は Git 追跡対象外（`.gitignore`）
* Secrets は Vercel Secrets / GitHub Secrets で管理
* クライアント公開値（`NEXT_PUBLIC_*`）以外はブラウザに露出しない

---

# 5. 開発環境（Docker Desktop）

| 項目        | 内容                                                       |
| --------- | -------------------------------------------------------- |
| DB        | Supabase CLI（PostgreSQL 17）                              |
| メール       | Mailpit（[http://localhost:8025）](http://localhost:8025）) |
| API       | Next.js API Routes（翻訳 / TTS）                             |
| 起動        | `supabase start`                                         |
| 停止        | `supabase stop`                                          |
| Migration | `supabase db push` / `supabase db reset`                 |

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

# 7. 非機能品質要件（概要）

| 区分   | 要件                                  |
| ---- | ----------------------------------- |
| 応答速度 | 翻訳 API：1〜3 秒、TTS：5 秒以内              |
| 可用性  | Supabase / Vercel の標準 SLA に準拠       |
| 保守性  | Prisma Migrate / Supabase Migration |
| 拡張性  | Next.js API Routes により機能追加が容易       |
| 分離性  | RLS によりテナント境界を完全分離                  |

---

# 8. ChangeLog

| Date       | Version | Summary                                  |
| ---------- | ------- | ---------------------------------------- |
| 2025-11-19 | 1.7     | MagicLink / Google 翻訳 / VOICEVOX 構成に全面刷新 |
| 2025-11-17 | 1.6     | 旧構成（Passkey / EdgeFunction）による定義         |

---

**Directory:** `/01_docs/01_requirements/01_機能要件定義/`
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式要件（MagicLink 構成整合）
