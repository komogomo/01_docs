# HarmoNet Technical Stack Definition v3.6

**Document ID:** HNM-TECH-STACK-DEF-20251105  
**Version:** 3.6  
**Created:** 2025-11-05  
**Last Updated:** 2025-11-05  
**Author:** Tachikoma (PMO Architect)  
**Approved:** TKD (Project Owner)

---

## 🧭 概要

本書は、HarmoNet プロジェクトにおける **Phase9 実装・運用段階の技術スタック構成**を定義する。  
本バージョン（v3.6）は、リポジトリ再構築および Supabase ローカルコンテナ環境の確立を反映した最新版である。  
実装・検証・監査の三層（Claude／Tachikoma／Gemini）連携体制の技術基盤を確定する。

---

## 🏗️ 1. システム全体構成概要

### 1.1 環境種別
| 区分 | 実行環境 | 備考 |
|------|-----------|------|
| 開発環境 | **Supabase CLI ローカル環境（Docker）** | ローカルPC上で完全自立稼働 |
| ステージング環境 | VSCode + Cursor（Phase9実装用） | 開発確認用環境 |
| 本番相当環境 | Supabase Cloud（将来対応予定） | Phase10以降検討対象 |

### 1.2 環境識別情報

| 項目 | 値 | 備考 |
|------|----|------|
| **Project ID** | `HarmoNet` | ローカルSupabase用一意ラベル |
| **API URL** | `http://127.0.0.1:54321` | API Gateway (Kong) |
| **Database URL** | `postgres://postgres:postgres@127.0.0.1:54322/postgres` | Postgresコンテナ |
| **Studio URL** | `http://127.0.0.1:54323` | Web管理ツール |
| **Publishable Key (anon)** | `sb_publishable_********AaH` | Anonキー相当（末尾AaH） |
| **Secret Key (service_role)** | `sb_secret_********Pvz` | Service Roleキー相当（末尾Pvz） |
| **Storage URL** | `http://127.0.0.1:54321/storage/v1/s3` | Supabase Storage |
| **Storage Region** | `local` | ローカル固定領域 |

---

## ⚙️ 2. アプリケーション構成

### 2.1 実装レイヤー
| レイヤー | 実装要素 | 主な技術 |
|-----------|-----------|----------|
| **UI層** | React / TailwindCSS / Next.js | Cursor による自動生成（Phase9） |
| **ロジック層** | Node.js + Prisma ORM | Supabase経由でPostgres接続 |
| **DB層** | PostgreSQL 17 + RLS | Supabase CLI コンテナ実装 |

---

### 2.2 ローカル開発スタック構成図

┌────────────────────────────────────────────────────────────┐
│ HarmoNet Local Dev Environment │
├────────────────────────────────────────────────────────────┤
│ Frontend: Next.js + Tailwind (Cursor / VSCode) │
│ Backend : Node.js + Prisma ORM │
│ Database: Supabase PostgreSQL 17 (Docker) │
│ Storage : Supabase S3 (local) │
│ Auth : Supabase MagicLink (Email) │
│ RLS : Policy-based Row Security │
└────────────────────────────────────────────────────────────┘


---

## 🧩 3. AIチーム実装連携構成（Phase9）

### 3.1 実装ワークフロー
| 役割 | 担当AI / 人 | 主なタスク |
|------|--------------|-------------|
| 設計解析 | Claude | `.md`設計書の解析・構造整合性確認 |
| 実装統括 | Tachikoma | 実装方針・進捗管理・構造保証 |
| コード生成 | Cursor | 複数ファイルを参照した一括生成 |
| 監査・検証 | Gemini | BAG-lite / Schema整合検証 |
| 動作確認 | TKD | ローカル環境で画面単位のテスト |

### 3.2 実装パイプライン

Claude → Tachikoma → Cursor → Gemini → TKD


---

## 🧱 4. Supabase モジュール構成（Docker環境）

| モジュール | 役割 | ポート | 備考 |
|-------------|------|--------|------|
| supabase-db | Postgres + RLS | 54322 | DBコア |
| supabase-api | Kong Gateway | 54321 | API経由アクセス |
| supabase-studio | Web UI | 54323 | DBブラウザ |
| supabase-mailpit | メール検証 | 54324 | MagicLink検証用 |
| supabase-storage | S3エミュレーション | 54321経由 | ファイル保存領域 |

---

## 🔒 5. セキュリティ・アクセス管理

- APIキーは `.env` に保存せず、`supabase status` 実行時のみ参照可能  
- Anonキーはローカル限定、外部通信を伴わない構成  
- RLS（Row Level Security）は `enable_rls_policies.sql` に定義  
- DB初期化スクリプトは `create_initial_schema.sql` に保持  
- 外部通信・Webhookは Phase10 以降に限定的開放予定  

---

## 🧠 6. AIチームアクセス経路（Phase9）

| AIメンバー | 参照リポジトリ | 参照方法 |
|-------------|----------------|-----------|
| Claude | `https://github.com/komogomo/01_docs` | GitHub Public (Read) |
| Tachikoma | 同上（/01_docs） + ローカル同期 | Drive連携不要 |
| Gemini | 同上（Public経由） | Drive同期を廃止しGitHub参照へ移行 |
| TKD | VSCode + Cursor + Supabase Local | 開発実行環境 |

---

## 🔄 7. ローカル環境再構築手順

1. Supabase CLI の起動  
   ```powershell
   cd D:\Projects\HarmoNet
   supabase start

2.ステータス確認
supabase status

3.Postgres 接続テスト
psql -h 127.0.0.1 -p 54322 -U postgres

4.MagicLinkメール確認
http://127.0.0.1:54324 を開く（Mailpit）

| Version  | Date           | Author        | Summary                                                                         |
| -------- | -------------- | ------------- | ------------------------------------------------------------------------------- |
| v3.2     | 2025-10-30     | Tachikoma     | Supabase構成（Cloud想定）定義                                                           |
| v3.4     | 2025-11-02     | Tachikoma     | RLS / Prisma / Supabase連携追記                                                     |
| v3.5     | 2025-11-03     | Tachikoma     | Phase9構成定義・Cursor導入方針                                                           |
| **v3.6** | **2025-11-05** | **Tachikoma** | **リポジトリ再構築＋SupabaseローカルDocker構成に対応（project_id=HarmoNet, publishable_key末尾AaH）** |

Document ID: HNM-TECH-STACK-DEF-20251105
Version: 3.6
Created: 2025-11-05
Approved: TKD
Status: ✅ Phase9正式採用