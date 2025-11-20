# 第2章 システム概要（v1.5 改訂版）

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
HarmoNetは **Next.js 16.x / React 19.0 / Supabase / Corbado SDK（React + Node） / Prisma ORM / TailwindCSS 3.4 / shadcn/ui / Vercel** を中核とする、クラウドネイティブなマルチテナント型SaaS基盤上に構築される。

---

## 2.1 開発目的

HarmoNetは、マンション・自治会・地域コミュニティにおける**「安心・つながり・効率」**を実現するデジタル共助プラットフォームである。
従来の紙媒体・掲示板中心の運用をクラウド化し、多言語・多デバイス対応のオンライン基盤へ転換することを目的とする。

### 主な目的

* **情報伝達の確実化**：お知らせ・掲示板を多言語配信し、既読確認を自動化
* **施設運用の効率化**：駐車場・集会所・設備予約をオンライン化
* **住民コミュニケーションの促進**：掲示板・アンケート・リアクションで交流を可視化
* **管理業務の省力化**：通知・翻訳・ログ記録をAIが自動補助
* **国際化対応**：日本語・英語・中国語を標準提供し、翻訳キャッシュを最適化

---

## 2.2 利用対象者

| 区分 | 対象 | 特徴 |
|------|------|------|
| 一般ユーザー | 住民（日本語・英語・中国語話者） | スマートフォン中心の利用、Magic Linkログイン |
| テナント管理者 | 管理組合理事・管理会社担当者 | お知らせ配信・施設管理・利用者登録（Passkey対応） |
| システム管理者 | 運用保守担当者 | テナント登録・ロール設定・監査管理（Supabase管理画面） |

---

## 2.3 システム全体構成

### 技術スタック（v4.3準拠）

| レイヤー | 技術 | バージョン | 概要 |
|---------|------|-----------|------|
| フロントエンド | Next.js 16.x + React 19.0 + TailwindCSS 3.4 + shadcn/ui | App Router構成、PWA対応 | Appleカタログ風UI |
| バックエンド（開発） | Supabase Docker (Edge Function) + PostgreSQL 17 | Docker Desktop環境 | ローカル開発・テスト |
| バックエンド（本番） | Supabase Cloud (Edge Function) + PostgreSQL 17 | Pro Plan | 本番運用 |
| 認証 | Supabase MagicLink + Corbado Passkey | @corbado/react v2.x + @corbado/node v2.x | 完全パスワードレス（独立ボタン方式） |
| ORM | Prisma | v6.x | スキーマ管理・マイグレーション |
| キャッシュ | Redis（翻訳・音声・セッション） | - | Supabase連携キャッシュ層 |
| 翻訳 | StaticI18nProvider v1.0 + Google Cloud Translate v3 | JSON辞書 + API補完 | 多言語対応 |
| 通知 | Supabase Realtime + Email (SMTP) | - | リアルタイム既読通知 |
| 音声 | VOICEVOX API + Supabase Edge `/api/tts` | - | 掲示板投稿音声化 |
| ホスティング（本番） | Vercel + Supabase Cloud | - | CI/CD + 自動デプロイ |
| テスト | Vitest + React Testing Library | 最新 | 単体・結合テスト |
| バージョン管理 | GitHub + Windsurf / Gemini協調開発 | - | AI主導型コードレビュー |

---

### アーキテクチャ概要

```
[Frontend: Next.js 16.x + React 19.0 + shadcn/ui]
   ↓ HTTPS / JWT認証 / Supabase SDK
[Backend: Supabase Edge Function]
   ├─ 開発環境: Docker Desktop (PostgreSQL 17)
   └─ 本番環境: Supabase Cloud (PostgreSQL 17)
   ↓
[External Services]
   ├─ Corbado Auth (Passkey / short_session)
   ├─ Supabase Auth (Magic Link)
   ├─ Google Translation API v3
   ├─ VOICEVOX / TTS Cache
   ├─ AI Proxy (Gemini / Windsurf)
   └─ Cloudflare CDN / Redis Cache
```

---

### マルチテナント構造（RLS + JWT）

Supabase PostgreSQLの**Row Level Security (RLS)** により、各テナント（管理組合単位）のデータを完全分離する。
JWTには `tenant_id` / `role` / `lang` が含まれ、Supabase AuthまたはCorbado Auth経由で発行される。

#### RLSポリシー例

```sql
CREATE POLICY tenant_isolation_policy
ON public.board_posts
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

#### 主要テーブル構造

| テーブル | 用途 |
|---------|------|
| tenants | テナント基本情報 |
| users | ユーザー基本情報（Supabase Auth連携） |
| user_roles | ロール割当（system_admin / tenant_admin / general_user） |
| board_posts | 掲示板投稿（翻訳・音声キャッシュ連携） |
| facilities | 施設予約情報 |
| translation_cache | 翻訳キャッシュ（Redis連携） |

---

## 2.4 運用基盤および前提条件

| 項目 | 内容 |
|------|------|
| 開発環境 | Docker Desktop + Supabase CLI + Mailpit（メールテスト） |
| 本番稼働基盤 | Supabase Cloud（Pro Plan）＋Vercel（Hobby/Pro） |
| 稼働率目標 | 99.5%以上（Supabase SLA） |
| 監視 | Sentry + UptimeRobot + Supabase Logs |
| バックアップ | Supabase自動スナップショット（1日1回保持7日） |
| スケーラビリティ | SupabaseプランアップまたはCloudflare CDN拡張で対応 |
| セキュリティ | Corbado Cookie Secure/Lax + JWT署名 + TLS1.3通信 |
| デプロイ | GitHub Actions → Vercel 自動CI/CD構成 |
| 言語対応 | 日本語・英語・中国語（簡体） StaticI18nProviderにて動的切替 |

---

## 2.5 開発方針とAI協調体制

### 開発体制

HarmoNet開発は「AI協調型アジャイル」を採用し、人間（TKD）とAIエージェント（タチコマ・Gemini・Windsurf）が役割分担する。

| 区分 | 主担当 | 役割 |
|------|--------|------|
| 要件定義・設計統合 | タチコマ (GPT-5) | 要件ドキュメント・ディレクトリ統合 |
| 詳細設計生成・品質保証 | Gemini | 詳細設計レビュー・Lint検証・論理整合性維持 |
| コード実装 | Windsurf | Next.js + Supabase 実装／テスト生成／自己採点レポート出力 |
| 最終承認 | TKD | 設計・運用・方針決定者（唯一の正） |

### 開発プロセス

1. タチコマが要件・仕様整合を統合して出力。
2. Gemini が論理検証・テストカバレッジを確認。
3. Windsurf がコード生成・自己採点を実施。
4. TKD が承認後、ドキュメントとコードを正式反映。

### 継続運用方針

* すべての設計書は `/01_docs/` ディレクトリにMarkdown形式で保存。
* GitHubリポジトリ `01_docs` と `Projects-HarmoNet` を同期管理。
* Google Drive `/01_docs/00_project/` を全AIの共通参照領域とする。

---

## 2.6 将来拡張ロードマップ（カテゴリ別）

| カテゴリ | 拡張予定 | 対応時期 |
|---------|---------|---------|
| 認証 | Corbado公式構成完全統合（Node API層拡張） | 2026年上期 |
| AI支援 | Windsurf＋Gemini連携による自己補完開発 | 2026年上期 |
| 通知 | FCMプッシュ通知／SMS通知対応 | 2026年中期 |
| 国際化 | 動的翻訳キャッシュ（Redis完全対応） | 2026年中期 |
| 監査 | BAG-Lite監査レポート生成自動化 | 2026年下期 |
| IoT | 共用設備遠隔制御API連携 | 2027年以降 |

---

**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Version:** 1.5
**Created:** 2025-11-12
**Updated:** 2025-11-17
**Supersedes:** v1.4
**Directory:** /01_docs/01_requirements/01_機能要件定義/
**Status:** ✅ HarmoNet正式要件（技術スタックv4.3準拠）
