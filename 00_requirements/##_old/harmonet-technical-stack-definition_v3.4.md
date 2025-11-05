# HarmoNet Technical Stack Definition v3.4
**HarmoNet プロジェクト 技術スタック定義書（Phase9 実装構成対応版）**

---

## 🧭 Purpose（目的）

本書は Phase8 の安定運用構成を基に、**Phase9 実装フェーズにおける正式開発環境**を定義する。  
AI IDE（Windsurf／Cursor／Copilot）を含むマルチAI実装体制を確立し、  
Claude・Gemini・タチコマ間の設計〜実装〜監査フローを技術的に統合する。

目的は以下の通り：

1. Windsurf を正式な開発IDE（AI実装エージェント）として採用する。  
2. Cascade 機能を活用し、設計書（ch01〜ch08）を直接参照する実装を可能にする。  
3. GitHub PR を経由した Claude 設計レビュー／Gemini 監査体制を明確化する。  
4. Copilot／Cursor は補助・バックアップツールとして運用する。  
5. 実装〜レビュー〜監査を完全に Phase9 標準フローへ統一する。

---

## ⚙️ System Overview（全体構成）

### 🧩 基本方針
- 全ての環境は **Docker Desktop（Hyper-V構成）** 上で稼働。  
- **Supabase** を中核とし、DB／Auth／Storageを統合。  
- **AI IDE（Windsurf／Cursor／Copilot）** はコードエージェントとして機能。  
- **CI/CDは導入しない。** デプロイは手動で行う。  
- 開発環境と本番環境は設定差分のみ。  

---

### 🧱 開発基盤構成

| コンポーネント | バージョン | 用途 / 備考 |
|----------------|-------------|--------------|
| Docker Desktop | v4.35.0 (Engine v27.1.2) | Hyper-V構成、WSL統合OFF |
| Compose | v2.27+ | `docker compose` 標準構成 |
| Node.js | 20.17.1 LTS | Next.js / Supabase CLI安定版 |
| npm | 10.8.2 | LTS同梱安定版 |
| pnpm | 9.6.0 | パッケージキャッシュ高速化 |
| Next.js | 15.0.3 | App Router完全構成 |
| React / ReactDOM | 19.0.0 | Next.js 15対応 |
| Prisma | 6.0.1 | Supabase Adapter接続 |
| PostgreSQL (Supabase内) | 15.6 | DB本体／RLS有効 |
| Supabase OSS Stack | 2025-09安定タグ | Cloud互換 |
| Python | 3.12+ | AI補助スクリプト（任意） |
| GitHub | Web + CLI | コード管理・PRレビュー |
| **Windsurf (Codeium IDE)** | 最新安定版 | Phase9正式AI IDE（Cascadeモード） |
| **Cursor (AI IDE)** | 2025-10安定版 | Windsurf代替候補 |
| **VS Code + Copilot** | 1.96.1 / 1.228.0 | 小規模修正・補助用 |

---

### 🧬 Supabase Stack 内訳

| サービス | イメージ | バージョン | 用途 |
|-----------|-----------|-------------|------|
| Postgres | supabase/postgres | 15.6.1 | DB |
| GoTrue | supabase/gotrue | 2.139.0 | 認証 |
| PostgREST | supabase/postgrest | 11.2.1 | REST API |
| Realtime | supabase/realtime | 2.31.1 | 通知 |
| Storage API | supabase/storage-api | 1.43.0 | ファイル保存 |
| Studio | supabase/studio | 0.23.4 | 管理UI |
| Kong | kong | 3.8 | API Gateway |

> Supabase公式Compose（2025-09リリース）準拠。  
> `.env.production` 切替のみで本番対応可能。

---

## 💻 開発支援環境（AI IDE構成）

### 🧠 Windsurf（正式採用）
- **提供元:** Codeium  
- **主目的:** HarmoNet設計書（ch01〜ch08）を自動理解し、複数ファイル同時生成。  
- **主機能:** Cascade（大規模コンテキスト保持）／Flow（対話型実装補助）  
- **推奨用途:** 新画面・複数コンポーネントを跨ぐ実装。  
- **導入形態:** 個人ライセンス ($15/月)  

### 🧩 Cursor（代替IDE）
- **提供元:** Cursor AI  
- **主機能:** Composer（マルチファイル編集）  
- **用途:** Windsurfが不安定な場合の代替。  
- **特徴:** GPT-4連携・VSCode互換。  

### 🧩 VS Code + Copilot（補助IDE）
- **用途:** 小規模修正・バグ修正・テストコード生成。  
- **構成:** VS Code 1.96.1 / Copilot 1.228.0 / Chat 0.21.0。  
- **利用方針:** Windsurf／Cursor環境で生成したコードの微調整・コメント整備。

---

## 🔧 Implementation Workflow（Phase9 実装フロー）

[設計書確認 (Claude出力)]
↓
[Windsurf IDE で実装] ← TKD監督
├─ Cascade機能で ch01〜ch08 を参照
├─ マルチファイル同時生成
└─ 命名規則自動適用
↓
[GitHub PR 作成]
↓
[Claude 設計整合レビュー]
├─ 構造・命名・整合性を確認
↓
[Gemini BAG-lite 監査]
├─ コード構造・依存関係を解析
↓
[TKD 承認 → main 反映]


---

## 🧩 運用方針（Deployment Policy）

| 区分 | 方針 | 補足 |
|------|------|------|
| デプロイ方式 | 手動（Vercel GUI） | mainブランチを選択して実行 |
| CI/CD | 使用しない | 自動パイプラインは導入しない |
| バックアップ | Gitタグ + Docker Export | バージョンタグ管理 |
| 本番切替 | `.env.production` 切替 | Supabaseキー差し替えのみ |
| ドキュメント参照 | `/01_docs/` | AI三層共通参照 |
| 実装IDE | Windsurf（優先） | Cursor／Copilotは補助 |

---

## 🚫 制約事項（Unchangeable Constraints）

1. **WSL2を含むLinux環境禁止。** Docker Desktopのみサポート。  
2. **旧Compose (`docker-compose`) コマンド禁止。**  
3. **Node.js／Next.js のメジャーバージョン変更禁止。**  
4. **VS Code／拡張機能の自動更新禁止。**  
5. **Windsurf／Cursor／Copilot のバージョン統一必須。**

---

## 🧾 Version & ChangeLog

| Version | Date | Author | Summary |
|----------|------|---------|----------|
| 3.2 | 2025-10-30 | タチコマ | Phase7監査完了版 |
| 3.3 | 2025-11-03 | タチコマ | Phase8運用構成定義（Supabase常設・Copilot統合） |
| **3.4** | **2025-11-03** | **タチコマ** | **Phase9 実装体制（Windsurf正式採用／Cascadeフロー追加）反映版。** |

---

**Document ID:** HNM-TECH-STACK-DEF-20251103-P9  
**Version:** 3.4  
**Created:** 2025-11-03  
**Last Updated:** 2025-11-03  
**Author:** タチコマ（HarmoNet AI Architect）  
**Status:** ✅ Phase9正式承認版  
**Location:** `/01_docs/05_implementation/`

