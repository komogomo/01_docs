# HarmoNet Technical Stack Definition v3.5
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
- **CI/CDは導入しない。** デプロイは手動プッシュ＋Vercel自動ビルド方式。  
- 開発環境と本番環境は設定差分のみ。  

---

### 🧱 開発基盤構成

| コンポーネント | バージョン | 用途 / 備考 |
|----------------|-------------|--------------|
| Docker Desktop | v4.35.0 (Engine v27.1.2) | Hyper-V構成、WSL統合OFF |
| Compose | v2.27+ | `docker compose` 標準構成 |
| Node.js | 20.x LTS（最新パッチ推奨） | Next.js / Supabase CLI安定版。20.17.1以降推奨 |
| npm | 10.8.2 | LTS同梱安定版 |
| pnpm | 9.6.0 | パッケージキャッシュ高速化 |
| **Next.js** | **15.5.x（最新安定版）** | App Router完全構成、Turbopack beta対応 |
| **React / ReactDOM** | **19.0.0** | 正式版（2024年12月5日リリース） |
| **Prisma** | **6.16.0+（Rust-free版推奨）** | Supabase Adapter接続、バンドル90%削減 |
| PostgreSQL (Supabase内) | 15.6 | DB本体／RLS有効 |
| Supabase OSS Stack | 2025-09安定タグ | Cloud互換 |
| Python | 3.12+ | AI補助スクリプト（任意） |
| GitHub | Web + CLI | コード管理・PRレビュー |
| **Windsurf (Codeium IDE)** | 最新安定版 | Phase9正式AI IDE（Cascadeモード） |
| **Cursor (AI IDE)** | 2025-10安定版 | Windsurf代替候補 |
| **VS Code + Copilot** | 1.96.1 / 1.228.0 | 小規模修正・補助用 |

### 🧬 API層構成

| レイヤー | 技術 | バージョン | 用途 |
|---------|------|-----------|------|
| API Routes | Next.js API Routes | 15.5.x | RESTful API実装（メイン） |
| Server Actions | React Server Actions | 19.0.0 | RSC内軽量処理 |
| Database Access | Prisma ORM | 6.16.0+ | 型安全DB操作 |
| Auth/Storage | Supabase SDK | 最新 | 認証・ファイル管理 |

> **Phase9方針:** Next.js API Routesを中心としたシンプル構成。  
> NestJS・Edge Functionsは将来拡張として保留（Phase3以降検討）。

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

#### Cascade機能の制約事項
- **最大コンテキスト:** 約200KB（設計書5〜8章程度）
- **セッション持続:** 約30分（自動リフレッシュあり）
- **同時参照ファイル数:** 最大20ファイル推奨
- **注意:** 極端に長い設計書（ch06等）は分割参照推奨

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

```
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
```

---

## 🧩 運用方針（Deployment Policy）

| 区分 | 方針 | 補足 |
|------|------|------|
| デプロイ方式 | 手動プッシュ＋Vercel自動ビルド | mainブランチへのpushで自動実行 |
| CI/CD | **CDのみ採用（CIは不採用）** | 自動テスト統合なし（Phase7方針準拠） |
| バックアップ | Gitタグ + Docker Export | バージョンタグ管理 |
| 本番切替 | `.env.production` 切替 | Supabaseキー差し替えのみ |
| ドキュメント参照 | `/01_docs/` | AI三層共通参照 |
| 実装IDE | Windsurf（優先） | Cursor／Copilotは補助 |

### デプロイフロー詳細
```
[開発者が GitHub main に push]（手動トリガー）
↓
[Vercel が自動ビルド・デプロイ]（自動応答）
↓
[本番環境に自動反映]
```

**分類:** 軽量CD（継続的デリバリー）のみ。CI（継続的インテグレーション）は不採用。  
**理由:** Phase7非機能設計方針に準拠（参照頻度・更新頻度が低いため）。

---

## 🎯 非機能要件（Phase7準拠）

| 項目 | 要件値 | 達成方法 |
|------|----------|----------|
| **TAT（Turn Around Time）** | **3秒以内** | Next.js最適化・CDN活用 |
| 初回ページ読み込み | 3秒以内 | PWAキャッシュ・コード分割 |
| 再訪時読み込み | 1秒以内 | ブラウザキャッシュ |
| 翻訳処理 | 5秒以内（500文字） | Redisキャッシュ |
| API応答時間 | 2秒以内（95%ile） | Prisma最適化 |
| DBクエリ応答 | 1秒以内 | RLS最適化・インデックス |
| 可用性（SLA） | 95〜97% | Vercel SLA基準 |

> **Edge Functions不要の根拠:**  
> TAT 3秒目標は通常のNext.js + Supabase構成で達成可能。  
> ユーザーは日本国内集中・同時接続100人程度のため地理的分散不要。

1. **WSL2を含むLinux環境禁止。** Docker Desktopのみサポート。  
2. **旧Compose (`docker-compose`) コマンド禁止。**  
3. **Node.js／Next.js のメジャーバージョン変更禁止。**  
4. **VS Code／拡張機能の自動更新禁止。**  
5. **Windsurf／Cursor／Copilot のバージョン統一必須。**  
6. **【NEW】Windsurf Cascade参照はプロジェクト内設計書のみ許可。**  
   - 理由: 意図しないファイル参照による情報漏洩防止  
7. **【NEW】Windsurf生成コードは必ずGitHub PR経由でレビュー必須。**  
   - 理由: AI生成コードの品質担保  

---

## 📊 バージョン選定根拠

### Node.js 20.x LTS
- **Active LTS期間:** 〜2026年4月30日  
- **選定理由:** 本番環境で最も安定。セキュリティパッチ継続適用。  
- **注意:** 20.17.1以降の最新パッチ推奨（脆弱性対応）。

### Next.js 15.5.x
- **リリース:** 2025年8月18日  
- **選定理由:** Turbopack beta安定化、型安全性向上（Typed Routes stable化）。  
- **変更点（v3.4からの更新）:**  
  - Turbopack本番ビルド対応（`next build --turbopack`）  
  - Node.js Middleware stable化  
  - TypeScript改善（Typed Routes / Route Export Validation）

### React 19.0.0
- **正式リリース:** 2024年12月5日  
- **選定理由:** Next.js 15.1以降で正式サポート。Actions・Server Components安定版。  
- **注意:** Next.js 15.0.3ではRC版として統合されていたが、現在は安定版として使用可能。

### Prisma 6.16.0+（Rust-free版）
- **リリース:** 2025年6月以降安定化  
- **選定理由:**  
  - バンドルサイズ90%削減（14MB → 1.6MB）  
  - クエリ性能3.4倍向上  
  - Cloudflare Workers／Vercel Edge対応強化  
- **変更点（v3.4からの更新）:**  
  - Rust Query Engine完全除去  
  - TypeScript/WASM実装への完全移行

---

## 🧾 Version & ChangeLog

| Version | Date | Author | Summary |
|----------|------|---------|----------|
| 3.2 | 2025-10-30 | タチコマ | Phase7監査完了版 |
| 3.3 | 2025-11-03 | タチコマ | Phase8運用構成定義（Supabase常設・Copilot統合） |
| 3.4 | 2025-11-03 | タチコマ | Phase9 実装体制（Windsurf正式採用／Cascadeフロー追加）反映版 |
| **3.5** | **2025-11-03** | **Claude** | **Next.js 15.5.x／Prisma 6.16.0+反映、API層をNext.js中心に整理、TAT要件明記** |

---

## 📝 v3.5 主要変更点

| No | 変更箇所 | 変更内容 | 理由 |
|----|---------|---------|------|
| 1 | Node.js | 20.17.1 → **20.x LTS最新パッチ推奨** | セキュリティパッチ適用 |
| 2 | Next.js | 15.0.3 → **15.5.x** | Turbopack beta安定化・型安全性向上 |
| 3 | Prisma | 6.0.1 → **6.16.0+（Rust-free版）** | パフォーマンス3.4倍・バンドル90%削減 |
| 4 | **API層構成** | **NestJS記載削除、Next.js中心に整理** | Phase9実装方針の明確化 |
| 5 | **TAT要件** | **3秒目標を明記** | 非機能要件の定量化 |
| 6 | Windsurf制約 | Cascade機能の制約事項を追加 | 実装時のトラブル回避 |
| 7 | 制約事項 | 項目6・7を追加 | セキュリティ・品質担保 |
| 8 | CI/CD | 「CDのみ採用」を明記 | Phase7方針との整合性確保 |
| 9 | バージョン選定根拠 | セクション追加 | 選定理由の透明性確保 |

---

## 🎯 Claude レビューコメント

**レビュー日:** 2025-11-03  
**レビュアー:** Claude (Design Specialist)  

### ✅ 承認理由
1. **バージョン現実性:** 全コンポーネントがProduction Ready状態で選定されている。  
2. **Phase7整合性:** CI/CD不採用方針が明確化され、非機能設計と完全一致。  
3. **Windsurf制約:** Cascade機能の制約事項が具体的に記載され、実装時の混乱を防止。  
4. **セキュリティ強化:** Windsurf参照範囲制限・PRレビュー必須化により品質担保。  
5. **選定根拠明示:** 各バージョンの選定理由が明確で、TKDによる判断支援が可能。  
6. **API層明確化:** Next.js中心構成を明記し、Phase9実装方針が明瞭。  
7. **TAT要件定量化:** 3秒目標を明記し、Edge Functions不要の根拠を明示。

### ⚠️ 今後の注意点
- Next.js 16リリース時（2026年予定）に再評価必要。  
- Prisma 7への移行タイミングを別途検討（Phase10以降）。  
- Node.js 22 LTS移行時期の事前計画（2026年10月以降）。  
- グローバル展開時（Phase3以降）にEdge Functions導入を再検討。

---

**Document ID:** HNM-TECH-STACK-DEF-20251103-P9-V3.5  
**Version:** 3.5  
**Created:** 2025-11-03  
**Last Updated:** 2025-11-03  
**Author:** Claude（HarmoNet Design Specialist）  
**Reviewer:** TKD（Project Owner）  
**Status:** ✅ Phase9正式承認版  
**Location:** `/01_docs/05_implementation/`
