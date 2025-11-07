HarmoNet 技術スタック定義書 v3.7

Phase9.8 安定版（現行構成）

第1章　目的と適用範囲

本書は HarmoNet プロジェクト Phase9.8 における技術構成を定義するものであり、
実際に稼働している開発・検証環境を正として記録する。
記載対象は Supabase・Next.js・Prisma・外部API連携・認証・環境構成に限定し、
将来構想・監視・商用運用要素は含めない。

第2章　技術スタック概要
| 区分      | 採用技術                                 | 用途                       |
| ------- | ------------------------------------ | ------------------------ |
| フロントエンド | Next.js 15 / React 19 / TypeScript   | UI実装・API呼出し・多言語UI        |
| スタイル    | Tailwind CSS / BIZ UD ゴシック           | HarmoNet共通デザイン体系         |
| バックエンド  | Supabase OSS v2025.10                | DB・認証・API統合              |
| ORM     | Prisma 6.19.0                        | Supabase(PostgreSQL)接続管理 |
| データベース  | PostgreSQL 15.6.1                    | テナント分離構成(RLS有効)          |
| ストレージ   | Supabase Storage API (S3互換)          | PDF・画像・音声ファイル保存          |
| 認証      | Supabase Auth (Magic Link / Passkey) | パスワードレス認証                |
| 通知・検証   | Mailpit (開発用メールサーバ)                  | Magic Link受信検証           |
| 言語変換    | Google Translate API v3              | 翻訳API呼び出し                |
| 音声変換    | Voicebox / VOICEVOX                  | 音声読み上げ(TTS)              |
| 実行環境    | Docker Desktop + Supabase CLI        | ローカル実行構成                 |
| 開発環境    | VS Code / Node.js 22 LTS             | アプリ開発・ビルド・検証             |

第3章　Supabase 構成（実機構成）

実機 supabase status 出力を基にした8モジュール構成とする。
| モジュール             | イメージ                        | ポート       | 役割                   |
| ----------------- | --------------------------- | --------- | -------------------- |
| supabase-db       | supabase/postgres:15.6.1    | 54322     | PostgreSQL + RLS管理   |
| supabase-kong     | kong:3.8                    | 54321     | API Gateway／ルーティング統合 |
| supabase-rest     | supabase/postgrest:11.2.1   | 統合(54321) | DB自動REST API         |
| supabase-auth     | supabase/gotrue:2.139.0     | 統合(54321) | MagicLink・Passkey認証  |
| supabase-realtime | supabase/realtime:2.31.1    | 統合(54321) | 投稿・コメント更新通知          |
| supabase-storage  | supabase/storage-api:1.43.0 | 統合(54321) | PDF・画像・音声保存          |
| supabase-studio   | supabase/studio:0.23.4      | 54323     | 管理UI                 |
| supabase-mailpit  | axllent/mailpit:1.15.0      | 54324     | Magic Link メール確認     |

本構成は Docker Compose で起動し、
環境変数を切り替えることで Supabase Cloud へ移行可能である。

第4章　アプリケーション構成（Next.js + Prisma）
・フロントエンド層：Next.js 15 を採用。
/src/app/ 配下に画面コンポーネントを配置し、国際化対応UIを実装。

・データアクセス層：Prisma ORM を採用。
　/prisma/ ディレクトリでスキーマとマイグレーションを管理し、Supabase DB と1対1で同期する。
　接続設定は .env 内 DATABASE_URL を使用し、環境切替に対応。

・API層：Next.js API Routes に /api/translate・/api/tts・/api/ai-proxy 等を配置。
　外部API呼び出しおよび Supabase 操作を中継する。

第5章　外部API構成
| 分類      | 役割              | サービス／仕様                       |
| ------- | --------------- | ----------------------------- |
| 翻訳API   | 多言語変換           | Google Cloud Translate API v3 |
| 音声API   | 読み上げ(TTS)       | Voicebox / VOICEVOX           |
| AI連携API | Claude・Gemini統合 | `/api/ai-proxy`（内部中継API）      |
| メール検証   | MagicLink送信     | Mailpit (開発環境)                |
| ファイル保存  | PDF／画像          | Supabase Storage API          |

外部APIキーは .env 内に格納し、
クライアント側 (NEXT_PUBLIC_) では参照しない構成とする。

第6章　環境変数と接続仕様（現物反映）
現行環境 D:\Projects\HarmoNet の .env / .env.local を正として定義。
.env.local
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DIRECT_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

.env
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DIRECT_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
SHADOW_DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres?schema=shadow"
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz

補足:
本構成では .env をサーバー用、.env.local をクライアント参照用とし、
src/ 配下への .env 配置は禁止。
CLIコマンドは必ずプロジェクトルートで実行する。

第7章　認証構成（Magic Link + Passkey）
HarmoNet は Supabase Auth を用いた完全パスワードレス認証で構成される。

| 種類            | 技術                               | 主用途        |
| ------------- | -------------------------------- | ---------- |
| Magic Link 認証 | Supabase GoTrue (OTPリンク)         | 一般ユーザー（住民） |
| Passkey 認証    | Supabase Auth + WebAuthn / FIDO2 | 管理者・運用担当   |

第8章　セキュリティ・運用ルール
・Supabase は RLS を全テーブルで有効化し、tenant_id によりデータ分離を実現。
・サービスロールキー（Service Role Key）は .env 内でのみ保持し、クライアントには公開しない。
・env / .env.local はプロジェクトルート直下に統一し、src 配下での生成は禁止。
・コマンド実行は常に D:\Projects\HarmoNet をカレントディレクトリとする。
・HarmoNet は Supabase OSS 構成を前提としつつ、Supabase Cloud / AWS / Vercel への移行可能構成として設計されている。
・監視・商用運用機能は現段階では対象外とし、必要時に別途設計書を策定する。

第9章　ChangeLog
| Version | Date           | Author        | Summary                                      |
| ------- | -------------- | ------------- | -------------------------------------------- |
| 3.5     | 2025-11-03     | Tachikoma     | Supabaseローカル構成導入                             |
| 3.6     | 2025-11-05     | Tachikoma     | 実機Supabase 8モジュール構成化                         |
| **3.7** | **2025-11-07** | **Tachikoma** | **現物環境・MagicLink＋Passkey認証・クラウド移行可能構成として確定** |

Created: 2025-11-07
Last Updated: 2025-11-07
Version: 3.7
Document ID: HN-TECH-STACK-V3.7