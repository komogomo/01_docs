# HarmoNet 機能要件定義書 第5章（外部API・認証・音声・翻訳要件）_latest  
**Phase9.8 対応版（技術スタック v3.7 準拠）**

---

## 第1章　目的と適用範囲

本章は、HarmoNetシステムにおける外部API連携、ユーザー認証、翻訳・音声読み上げ機能に関する非機能的要件を定義する。  
Phase9.8 時点の技術構成（Supabase OSS + Prisma + Next.js 15）を基準とし、実際に稼働中の開発環境を前提とする。

---

## 第2章　外部API連携要件

### 2.1 翻訳API要件

| 項目 | 内容 |
|------|------|
| サービス | Google Cloud Translate API v3 |
| 用途 | 掲示板投稿・コメントなどのユーザー生成テキストを多言語表示 |
| 言語対応 | 日本語・英語・中国語（簡体） |
| 呼出方式 | `/api/translate` 経由でサーバーサイドから呼び出す |
| キャッシュ | 翻訳結果をサーバー側でキャッシュ（Redis利用予定・Phase10以降） |
| 利用制約 | APIキーは `.env` にのみ保持、クライアント側での直接呼出禁止 |

### 2.2 音声変換API要件（Text-to-Speech）

| 項目 | 内容 |
|------|------|
| サービス | Voicebox（主系） / VOICEVOX（補助） |
| 用途 | 掲示板投稿内容・お知らせ本文の読み上げ |
| 呼出方式 | `/api/tts` エンドポイント経由（Next.js API Routes） |
| 音声形式 | MP3（64kbps以上） |
| 対応言語 | 日本語（Phase9時点） |
| キャッシュ | 同一入力文はサーバー側キャッシュを使用 |
| UI要件 | 投稿詳細画面に「▶︎読み上げ」ボタンを表示 |

### 2.3 AI連携API要件

| 項目 | 内容 |
|------|------|
| サービス | Claude / Gemini（AI協調エージェント） |
| 呼出方式 | `/api/ai-proxy` 経由でNext.jsサーバーが代理呼出 |
| 用途 | 翻訳補完、文体整形、要約生成、BAG解析の補助 |
| セキュリティ | 認証済みユーザーのみ利用可能（JWTトークン認証） |
| トランザクション | 1リクエスト=1レスポンス（非同期処理禁止） |

---

## 第3章　認証方式要件

### 3.1 Supabase Auth構成

HarmoNetの認証は **Supabase Auth** を中心に構成し、以下の2方式を併用する。

| 認証方式 | 対象ユーザー | 技術構成 | 概要 |
|-----------|--------------|------------|------|
| Magic Link 認証 | 一般ユーザー（住民） | Supabase GoTrue (OTPリンク) | メールでログインリンク送信 |
| Passkey 認証 | 管理者・運用担当 | Supabase Auth + WebAuthn / FIDO2 | 生体認証によるパスワードレス |

### 3.2 認証フロー（Passkey）

1. 管理者ログイン画面で「Passkeyでサインイン」を選択  
2. FIDO2認証をローカルデバイスで実行（指紋・FaceID等）  
3. Supabase AuthがWebAuthnを検証し、JWTを発行  
4. フロントエンドがJWTを受け取り、ユーザー情報を保持

### 3.3 認証フロー（Magic Link）

1. メールアドレス入力 → Supabase Auth (GoTrue) に送信  
2. 受信メールのMagic Linkをクリック → セッション確立  
3. SupabaseがJWTを発行し、クライアントが保存  
4. `tenant_id`をJWTに埋め込み、RLSポリシーと連携

### 3.4 共通制約

- `.env` 内に `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` を保持  
- クライアントでは **Service Role Keyを絶対に使用しない**  
- `tenant_id` によりRLSを有効化し、全データ分離を保証  
- 認証後JWTはAPI層で検証され、認可（Authorization）はロールベースで実行

---

## 第4章　セキュリティ・環境変数要件

| 要件項目 | 内容 |
|----------|------|
| 環境変数ファイル | `.env` および `.env.local` の2種類 |
| 配置位置 | プロジェクトルート直下のみ許可（例：`D:\Projects\HarmoNet\.env`） |
| 禁止事項 | `src/` 配下への .env ファイル配置 |
| APIキー管理 | `NEXT_PUBLIC_*` プレフィックスのキーは限定的用途のみ許可 |
| 実行ディレクトリ | Prisma / Supabase CLI コマンド実行時は常にルートディレクトリをカレントとする |
| 接続仕様 | `DATABASE_URL` に PostgreSQL 接続情報を統一 |
| 認証分離 | Magic Link / Passkey 双方で JWT に `tenant_id` を埋め込む |

---

## 第5章　非機能品質要件

| 分類 | 要件内容 |
|------|-----------|
| 応答速度 | API応答は 500ms 以内を目標（翻訳・音声除く） |
| 可用性 | Supabase OSS構成下で99.5%以上を目標 |
| 安全性 | Service Role Keyの露出禁止、JWT有効期限は1時間 |
| 拡張性 | Supabase Cloud / AWS / Vercel への移行可能構成 |
| 保守性 | Prisma ORMを介して全DBアクセスを統一 |
| テナント分離 | RLSポリシーによりtenant_id単位で完全分離 |

---

## 第6章　ChangeLog

| Date | Version | Summary | Author |
|------|----------|----------|--------|
| 2025-11-07 | 1.3 | Phase9.8対応：MagicLink＋Passkey併用構成・翻訳/音声API仕様を最新化 | タチコマ |

---

**Document ID:** HNM-REQ-CH05-20251107  
**Version:** 1.3  
**Created:** 2025-11-07  
**Last Updated:** 2025-11-07  
**Author:** タチコマ（HarmoNet AI Architect）  
**Approved:** TKD（Project Owner）
