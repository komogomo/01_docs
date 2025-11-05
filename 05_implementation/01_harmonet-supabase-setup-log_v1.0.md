# HarmoNet Supabase環境構築 作業記録

**作成日**: 2025年11月04日  
**バージョン**: v1.0  
**プロジェクト**: HarmoNet  
**作業者**: TKE

---

## 📊 作業サマリー

### ✅ 完了済みPhase
- **Phase 1**: 基盤ツールインストール
- **Phase 2**: 開発環境構築
- **Phase 3**: プロジェクト準備
- **Phase 4**: Supabase環境構築 ← 本日完了

### ⬜ 次回作業（Phase 5）
- データベーススキーマ設計
- 基本テーブル作成

---

## ✅ Phase 1: 基盤ツールインストール

### 完了項目
| ツール | バージョン | 確認コマンド |
|--------|-----------|-------------|
| Git | 2.51.1.windows.1 | `git --version` |
| Node.js | v22.20.0 | `node --version` |
| npm | 10.9.3 | `npm --version` |
| Python | 3.14.0 | `python --version` |

---

## ✅ Phase 2: 開発環境構築

### 完了項目

#### Docker Desktop
- **バージョン**: 28.5.1 (208700)
- **構成**: Hyper-V（WSL完全削除済み）
- **Docker Compose**: v2.40.2

#### Docker設定
```
Client API version: 1.51
Server API version: 1.51
Context: default (Hyper-V構成)
```

#### VSCode拡張機能
- Docker
- Prettier
- ESLint
- GitLens
- Japanese Language Pack

---

## ✅ Phase 3: プロジェクト準備

### プロジェクト構造

```
D:\projects\HarmoNet\
├── docs/          # ドキュメント
├── src/           # ソースコード
└── supabase/      # Supabase設定（Phase 4で作成）
    ├── .temp/
    └── config.toml
```

### Git設定確認
```bash
git config --global user.name
git config --global user.email
```

---

## ✅ Phase 4: Supabase環境構築

### 4-1. Supabase CLI インストール

```bash
npx supabase --version
# 初回実行時に自動インストール
```

### 4-2. プロジェクト初期化

```bash
npx supabase init
```

**対話形式の回答**:
- Generate VS Code settings for Deno? → `N`
- Generate IntelliJ Settings for Deno? → `N`

**作成されたファイル**:
- `supabase/config.toml`
- `supabase/.temp/`

### 4-3. トラブルシューティング

#### 問題1: Docker Context エラー

**エラー内容**:
```
failed to inspect docker image: 
request returned 500 Internal Server Error for API route 
http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/...
```

**原因**:
- Docker Contextが `desktop-linux`（WSL2用）になっていた
- WSL削除後も設定が残っていた

**解決方法**:
```bash
# 現在のContext確認
docker context ls

# defaultに切り替え
docker context use default

# Linux残骸を削除
docker context rm desktop-linux
```

**修正後の状態**:
```
NAME       DESCRIPTION                               DOCKER ENDPOINT
default *  Current DOCKER_HOST based configuration   npipe:////./pipe/docker_engine
```

### 4-4. Supabaseローカル環境起動

```bash
npx supabase start
```

**処理内容**:
1. Dockerイメージのダウンロード（約551MB）
2. 12個のコンテナ起動
3. 接続情報の表示

**起動時間**: 約10-13分（初回）

---

## 🔗 接続情報

### URL
```
Studio URL:      http://127.0.0.1:54323
API URL:         http://127.0.0.1:54321
GraphQL URL:     http://127.0.0.1:54321/graphql/v1
S3 Storage URL:  http://127.0.0.1:54321/storage/v1/s3
Database URL:    postgresql://postgres:postgres@127.0.0.1:54322/postgres
Mailpit URL:     http://127.0.0.1:54324
```

### APIキー
```
Publishable key: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
Secret key:      sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz
```

### S3認証情報
```
Access Key: 625729a08b95bf1b7ff351a663f3a23c
Secret Key: 850181e4652dd023b7a98c58ae0d2d34bd487ee0cc3254aed6eda37307425907
Region:     local
```

---

## 🐋 起動中のDockerコンテナ

### コンテナ一覧（12個）

| コンテナ名 | イメージ | ポート | 状態 |
|-----------|---------|-------|------|
| supabase_db_HarmoNet | postgres:17.6.1.029 | 54322→5432 | healthy |
| supabase_studio_HarmoNet | studio:2025.10.27 | 54323→3000 | healthy |
| supabase_kong_HarmoNet | kong:2.8.1 | 54321→8000 | healthy |
| supabase_auth_HarmoNet | gotrue:v2.180.0 | 9999 | healthy |
| supabase_rest_HarmoNet | postgrest:v13.0.7 | 3000 | running |
| supabase_realtime_HarmoNet | realtime:v2.57.3 | 4000 | healthy |
| supabase_storage_HarmoNet | storage-api:v1.28.2 | 5000 | healthy |
| supabase_inbucket_HarmoNet | mailpit:v1.22.3 | 54324→8025 | healthy |
| supabase_pg_meta_HarmoNet | postgres-meta:v0.93.1 | 8080 | healthy |
| supabase_edge_runtime_HarmoNet | edge-runtime:v1.69.15 | 8081 | running |
| supabase_analytics_HarmoNet | logflare:1.23.2 | 54327→4000 | healthy |
| supabase_vector_HarmoNet | vector:0.28.1-alpine | - | running |

### 停止中のサービス
- supabase_imgproxy_HarmoNet
- supabase_pooler_HarmoNet

---

## ⬜ Phase 5: NEXT作業（データベース構築）

### 5-1. データベーススキーマ設計

#### 作業内容
1. **要件定義の確認**
   - プロジェクトナレッジの確認
   - テーブル設計書の作成

2. **ER図作成**
   - エンティティの洗い出し
   - リレーションの定義

3. **テーブル設計**
   - カラム定義
   - 制約条件
   - インデックス設計

#### 推奨ツール
- Supabase Studio（ブラウザ）
- draw.io（ER図作成）

### 5-2. 基本テーブル作成

#### 作成方法（2通り）

**方法1: Studio UIから作成**
```
1. http://127.0.0.1:54323 を開く
2. 左メニュー「Table Editor」をクリック
3. 「New table」ボタンをクリック
4. テーブル定義を入力
```

**方法2: SQLマイグレーション作成**
```bash
# マイグレーションファイル作成
npx supabase migration new create_basic_tables

# 生成されるファイル
# supabase/migrations/20251104XXXXXX_create_basic_tables.sql
```

#### 基本テーブル例（想定）
- `users` - ユーザー情報
- `tenants` - テナント情報
- `roles` - ロール定義
- `permissions` - 権限定義

### 5-3. マイグレーション実行

```bash
# ローカル環境に適用
npx supabase db push

# 確認
npx supabase db diff
```

### 5-4. 認証設定

#### Auth設定の確認
```
1. Studio を開く
2. 左メニュー「Authentication」をクリック
3. 「Providers」で認証方法を設定
```

#### 設定可能な認証方法
- Email/Password
- Magic Link
- OAuth（Google, GitHub等）

---

## 🔧 よく使うSupabaseコマンド

### 環境管理
```bash
# ステータス確認
npx supabase status

# 起動
npx supabase start

# 停止
npx supabase stop

# 完全削除（データも削除）
npx supabase stop --no-backup

# 再起動
npx supabase restart
```

### マイグレーション
```bash
# 新規マイグレーション作成
npx supabase migration new <migration_name>

# マイグレーション一覧
npx supabase migration list

# ローカルDBに適用
npx supabase db push

# 差分確認
npx supabase db diff
```

### データベース操作
```bash
# psqlで接続
npx supabase db reset

# リセット（マイグレーション再実行）
npx supabase db reset
```

---

## 📝 重要事項

### 環境情報
- **OS**: Windows 11
- **プロジェクトディレクトリ**: `D:\projects\HarmoNet`
- **Cドライブ容量**: 500GB（拡張済み）
- **Docker構成**: Hyper-V（WSL削除済み）

### Docker Context設定
```
使用Context: default
Endpoint: npipe:////./pipe/docker_engine
```

### トラブルシューティング記録

#### Docker Contextエラーの場合
```bash
# Context確認
docker context ls

# defaultに切り替え
docker context use default
```

#### Supabase起動失敗の場合
```bash
# Docker Desktop再起動
# 1. Docker Desktopを完全終了
# 2. 30秒待つ
# 3. Docker Desktop再起動

# Supabase再起動
npx supabase stop
npx supabase start
```

#### ポート競合の場合
```bash
# 使用中のポートを確認
netstat -ano | findstr :54321
netstat -ano | findstr :54322
netstat -ano | findstr :54323
```

---

## 📚 参考リンク

### Supabase公式ドキュメント
- **CLI Reference**: https://supabase.com/docs/reference/cli
- **Local Development**: https://supabase.com/docs/guides/cli/local-development
- **Migrations**: https://supabase.com/docs/guides/cli/managing-environments

### Docker
- **Docker Desktop**: https://docs.docker.com/desktop/

---

## 📅 次回チャット開始時の伝達事項

```
HarmoNet Supabase環境構築の続きです。

✅ Phase 1-4完了済み
  - Supabaseローカル環境起動完了
  - Studio URL: http://127.0.0.1:54323

⬜ Phase 5: データベース構築
  - スキーマ設計から開始お願いします
  
作業記録: harmonet-supabase-setup-log_v1_0.md 参照
```

---

## 🎯 今後の展開

### Phase 5以降の予定
1. **Phase 5**: データベース構築
   - スキーマ設計
   - 基本テーブル作成
   - 認証設定

2. **Phase 6**: フロントエンド環境構築
   - Next.js/React環境
   - Supabaseクライアント設定

3. **Phase 7**: バックエンドAPI実装
   - Edge Functions
   - Row Level Security (RLS)

4. **Phase 8**: 統合テスト
   - 認証フロー確認
   - API動作確認

---

**📌 このファイルは、次回チャット開始時の引き継ぎ資料として使用してください。**
