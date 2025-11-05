# 第5章 構成管理・環境要件（v1.2）

---

## 5.1 開発環境

### 5.1.1 技術構成
| レイヤー | 技術 | バージョン | 概要 |
|-----------|------|-------------|------|
| バックエンド | NestJS (Node.js) + Prisma ORM | 10.x / 5.x | REST API／RLS対応 |
| フロントエンド | React (PWA) + Tailwind CSS | 18.x / 3.x | ミニマルUI |
| データベース | Supabase PostgreSQL | 15.x | RLS有効／テナント分離 |
| 認証 | Supabase Auth + NextAuth | - | Magic Link + JWT方式 |
| キャッシュ | Redis | 7.x | 翻訳・セッションキャッシュ |
| コンテナ環境 | Docker Desktop + Compose | 24.x / 2.x | 開発統一環境 |
| 開発エディタ | Visual Studio Code | 最新 | GitHub Copilot対応 |

---

### 5.1.2 ローカル開発手順
1. Docker Desktop を起動  
2. プロジェクトをクローン  
   ```bash
   git clone https://github.com/harmonet/harmonet-app.git
   ```
3. `.env` ファイルを設定（Supabase接続情報を記載）  
4. コンテナ起動  
   ```bash
   docker-compose up -d
   ```
5. 初期データ投入  
   ```bash
   npm run migration:run && npm run seed
   ```
6. 開発サーバー起動  
   ```bash
   npm run dev
   ```

---

### 5.1.3 開発規約
- コーディング規約：Airbnb JavaScript Style Guide  
- コミットルール：Conventional Commits  
- ブランチ戦略：Git Flow  
- コードレビュー：Pull Requestによるピアレビュー必須  
- ドキュメント形式：Markdown統一（.md / .txt）  

---

## 5.2 運用環境

### 5.2.1 ホスティング構成（正式採用）
| 層 | サービス | 役割 |
|----|-----------|------|
| フロントエンド | **Vercel** | PWAホスティング・SSL自動更新 |
| バックエンドAPI | **Supabase Edge Functions** | 認証・API・DBアクセス |
| データベース | **Supabase PostgreSQL (RLS)** | データ格納・テナント分離 |
| 認証 | **Supabase Auth** | Magic Link + JWT |
| ストレージ | **Supabase Storage** | 画像・ファイル管理 |
| 通知 | **SendGrid / FCM** | メール通知・プッシュ通知 |
| CDN | **Cloudflare（任意）** | 静的資産配信 |
| モニタリング | **Sentry + UptimeRobot** | 障害検知・稼働監視 |

---

### 5.2.2 デプロイパイプライン
```
[GitHub push]
   ↓
[Vercel Build & Deploy]
   ↓
[Supabase Migration Step (Prisma CI)]
   ↓
[自動HTTPS設定・SSL証明書更新]
```

- GitHub連携により、`main` ブランチへのマージで自動デプロイ。  
- Vercelダッシュボードからロールバック可能。  
- SupabaseマイグレーションはGitHub Actions経由で自動実行。

---

### 5.2.3 環境構成
| 環境 | 用途 | ドメイン | 備考 |
|------|------|----------|------|
| 開発環境 | ローカルDocker環境 | localhost:3000 | テスト用DB使用 |
| ステージング | 検証用 | staging.harmonet.app | Supabase Staging |
| 本番環境 | 住民利用 | app.harmonet.jp | Supabase Production |

---

## 5.3 バックアップ・監視

### 5.3.1 バックアップ設計
| 対象 | 頻度 | 保管期間 | 保管場所 |
|------|------|----------|-----------|
| データベース | 1日1回 | 7日間 | Supabase自動バックアップ |
| ストレージ（画像） | 随時 | 30日間 | Supabase Versioning |
| コードリポジトリ | コミットごと | 永続 | GitHub |
| 翻訳キャッシュ | 毎週初回再生成 | - | Redis再構築 |

リストア手順はSupabaseコンソールからワンクリックで実行可能。

---

### 5.3.2 監視設計
| 監視対象 | ツール | アラート条件 |
|-----------|--------|---------------|
| サーバ稼働 | UptimeRobot | 応答なし3分継続 |
| エラー検知 | Sentry | 例外発生時Slack通知 |
| DB接続数 | Supabase Monitor | 80%以上で警告 |
| Translation API | Google Cloud Console | 月50万文字の80%超で警告 |

---

## 5.4 稼働率・保守体制

| 項目 | 内容 |
|------|------|
| 稼働率目標 | 99%以上（Vercel SLA基準） |
| メンテナンス | 月1回（深夜2:00〜4:00） |
| リリース管理 | Semantic Versioning（例：v1.2.0） |
| 保守担当 | TKD + GPT（自動ドキュメント整合） |

---

*by GPT (HarmoNet PMO AI)*
