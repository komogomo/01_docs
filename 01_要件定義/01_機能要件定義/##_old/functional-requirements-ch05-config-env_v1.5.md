# HarmoNet 機能要件定義書 第5章（外部API・認証・環境構成要件） v1.5

**技術スタック準拠:** HarmoNet Technical Stack Definition v4.0（Supabase Cloud + Corbado SDK公式構成 + Next.js 16）
**Document ID:** HNM-REQ-CH05-20251112
**Version:** 1.5
**Author:** Tachikoma / TKD
**Status:** ✅ 正式版（v4.0整合）

---

## 第1章　目的と適用範囲

本章は、HarmoNetにおける **外部API連携・認証方式・環境変数構成** を定義する。
Next.js 16 + Supabase v2.43 + Corbado SDK（React + Node構成）を前提とし、Phase10以降のクラウド実運用を見据えたセキュアな構成要件を示す。

---

## 第2章　外部API連携要件

### 2.1 翻訳API

| 項目    | 内容                                                    |
| ----- | ----------------------------------------------------- |
| サービス  | Google Cloud Translation API v3（公式利用）                 |
| 呼出方法  | Supabase Edge Function `/api/translate` 経由（サーバーサイドのみ） |
| キャッシュ | Redisキー：`translation:{tenant_id}:{lang}:{hash}`       |
| 言語対応  | 日本語・英語・中国語（簡体）                                        |
| 非同期処理 | 禁止。同期呼出でUI整合性維持                                       |
| 認証方式  | Supabase Service Role Key（Edge内限定）                    |

### 2.2 音声変換（TTS）API

| 項目    | 内容                                                |
| ----- | ------------------------------------------------- |
| サービス  | VoiceVox（オープン）＋ Supabase Edge Function `/api/tts` |
| 音声形式  | MP3（64kbps以上）                                     |
| 言語対応  | 日本語（Phase10で英語・中国語拡張予定）                           |
| キャッシュ | Supabase Storage に音声キャッシュ格納（`tts_cache` テーブル連携）   |
| 認可    | JWT認証済ユーザーのみ（Auth Header経由）                       |

### 2.3 AI協調エージェントAPI

| 項目   | 内容                                          |
| ---- | ------------------------------------------- |
| サービス | Claude / Gemini / Windsurf AI Proxy         |
| 呼出方式 | `/api/ai-proxy` にてNext.jsサーバーから代理実行         |
| 用途   | 翻訳補完・UI生成支援・ドキュメント整合化                       |
| 認証   | Supabase JWT + `X-HarmoNet-Agent-Key` ヘッダ併用 |
| ログ管理 | Supabase `audit_logs` に自動保存                 |

---

## 第3章　認証構成要件

### 3.1 認証方式構成

HarmoNetは **パスワードレス構成** を採用し、以下の二方式を統合運用する。

| 認証方式       | 対象          | 実装                            | 概要                     |
| ---------- | ----------- | ----------------------------- | ---------------------- |
| Magic Link | 一般ユーザー      | Supabase Auth (signInWithOtp) | メール認証による即時ログイン         |
| Passkey    | 管理者・テナント運用者 | Corbado SDK + Supabase Auth連携 | FIDO2/WebAuthn による生体認証 |

### 3.2 Corbado構成

| 層      | ライブラリ               | 役割                                |
| ------ | ------------------- | --------------------------------- |
| フロント   | `@corbado/react`    | `<CorbadoAuth />` によりPasskey認証を実施 |
| サーバ    | `@corbado/node`     | `/api/session` にてJWT検証を実行         |
| Cookie | `cbo_short_session` | Secure + SameSite=Lax（短期有効）       |

**認証フロー概要（Passkey）**

1. `<CorbadoAuth />` にてWebAuthn認証を開始
2. Corbadoが `short_session` Cookie を発行
3. Next.jsサーバーが `/api/session` を通じCorbado JWTを検証
4. Supabaseが `signInWithIdToken({ provider: 'corbado' })` を実行しセッション確立
5. `tenant_id`・`role` をJWTクレームに付与してRLSへ伝搬

### 3.3 Supabase構成

* `signInWithOtp()` によるMagicLinkメール送信
* `signInWithIdToken()` によるCorbado連携
* Service Role Keyは **APIサーバー内のみ利用可**（クライアント利用禁止）
* `auth.jwt()` 内クレーム構造：

```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "role": "general_user | tenant_admin | system_admin",
  "lang": "ja",
  "provider": "supabase | corbado"
}
```

---

## 第4章　環境変数・秘密情報構成

### 4.1 環境変数一覧

| 環境変数名                            | 用途                | 配置             | 機密度 |
| -------------------------------- | ----------------- | -------------- | --- |
| `NEXT_PUBLIC_SUPABASE_URL`       | Supabase接続URL     | .env.local     | 公開可 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY`  | 匿名アクセスキー          | .env.local     | 公開可 |
| `SUPABASE_SERVICE_ROLE_KEY`      | サービスロールキー（管理API用） | Vercel Secrets | 高機密 |
| `NEXT_PUBLIC_CORBADO_PROJECT_ID` | Corbadoプロジェクト識別子  | .env.local     | 公開可 |
| `CORBADO_API_SECRET`             | Corbado APIシークレット | Vercel Secrets | 高機密 |
| `NEXT_PUBLIC_APP_URL`            | フロントURL（CORS制御用）  | .env.local     | 公開可 |
| `GOOGLE_TRANSLATE_API_KEY`       | 翻訳APIキー           | Vercel Secrets | 高機密 |
| `VOICEVOX_API_URL`               | 音声APIエンドポイント      | .env.local     | 中機密 |
| `REDIS_URL`                      | 翻訳・TTSキャッシュ接続先    | .env.local     | 中機密 |

### 4.2 配置ルール

| 項目       | 内容                                             |
| -------- | ---------------------------------------------- |
| 設置ディレクトリ | プロジェクトルート直下に限定（例：`D:\Projects\HarmoNet\.env`）  |
| 禁止事項     | `src/` 以下への .env 配置禁止                          |
| 環境区分     | `development` / `staging` / `production` で切替運用 |
| バージョン管理  | `.env*` は Git 追跡対象外 (`.gitignore` 登録済み)        |
| Secret管理 | 機密値は Vercel Secrets または GitHub Secrets で一元管理   |

---

## 第5章　非機能品質要件

| 分類   | 要件                               | 基準                  |
| ---- | -------------------------------- | ------------------- |
| 応答速度 | API応答500ms以内（翻訳除く）               | Edge Function処理基準   |
| 可用性  | Supabase Cloud SLA 99.5%以上       | Vercel + Supabase構成 |
| 安全性  | Corbado Cookieは短期有効 + JWT60分     | 双方の再認証ループを防止        |
| 保守性  | Prisma + Supabase Migration統一    | DB変更管理容易化           |
| 拡張性  | Supabase Edge分散構成・Corbado Node統合 | Phase10対応設計         |
| 分離性  | RLSによりtenant_id単位で完全独立           | マルチテナント保証           |

---

## 第6章　ChangeLog

| Date       | Version | Summary                                         | Author              |
| ---------- | ------- | ----------------------------------------------- | ------------------- |
| 2025-11-07 | 1.3     | Phase9.8版（旧構成）                                  | Tachikoma           |
| 2025-11-12 | **1.5** | **v4.0対応：Corbado公式構成＋Supabase Cloud連携／環境変数再定義** | **Tachikoma / TKD** |

---

**Directory:** `/01_docs/01_requirements/01_機能要件定義/`
**Reviewer:** TKD
**Status:** ✅ HarmoNet正式要件（技術スタックv4.0整合）
