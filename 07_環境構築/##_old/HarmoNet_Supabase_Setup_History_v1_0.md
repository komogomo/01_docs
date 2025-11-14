# HarmoNet Supabase セットアップ作業履歴

**Document ID**: HNM-SUPABASE-SETUP-20251105  
**Version**: 1.0  
**Created**: 2025-11-05  
**Author**: Claude (Design Specialist)  
**Reviewed by**: Tachikoma (Architect)  
**Project**: HarmoNet Phase 6 準備作業

---

## 📋 作業概要

### **目的**
- Supabase CLIのセットアップ
- `schema_migrations` テーブルの作成
- 既存マイグレーションの履歴管理開始
- 今後のDB変更を追跡可能にする

### **作業日時**
- 2025-11-05

### **作業者**
- TKE（実作業）
- Claude（技術サポート）

---

## 🎯 作業前の状況

### **Phase 5 完了状態**
- ✅ 29テーブル作成済み
- ✅ RLSポリシー 34件設定済み
- ✅ 以下の4つのマイグレーションSQL適用済み:
  1. `20251104090633_create_initial_schema.sql`
  2. `20251104094921_enable_rls_policies.sql`
  3. `20251104102551_remove_updated_at_triggers.sql`
  4. `20251104105155_add_role_inheritances_rls_policy.sql`

### **問題点**
- ❌ `schema_migrations` テーブルが存在しない
- ❌ マイグレーション履歴が管理されていない
- ❌ 今後の変更追跡ができない

---

## 🔧 実施した作業

### **Step 1: Supabase CLI インストール**

#### **環境**
- OS: Windows
- PowerShell: 通常ユーザー権限

#### **実行コマンド**

```powershell
# 1. PowerShell実行ポリシー変更
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# → 確認プロンプトで "Y" を入力

# 2. Scoopパッケージマネージャーインストール
irm get.scoop.sh | iex
# → "Scoop was installed successfully!" と表示

# 3. Supabaseリポジトリ追加
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git

# 4. Supabase CLIインストール
scoop install supabase

# 5. インストール確認
supabase --version
# → バージョン番号が表示されれば成功
```

#### **結果**
- ✅ Supabase CLI インストール成功

---

### **Step 2: プロジェクト初期化確認**

#### **実行コマンド**

```powershell
cd D:\Projects\HarmoNet
supabase init
```

#### **結果**

```
failed to create config file: open supabase\config.toml: The file exists.
Run supabase init --force to overwrite existing config file.
```

→ 既に `supabase/` フォルダが存在していた（Phase 5で作成済み）

#### **確認した構成**

```
D:\Projects\HarmoNet\
└── supabase/
    ├── config.toml
    └── migrations/
        ├── 20251104090633_create_initial_schema.sql
        ├── 20251104094921_enable_rls_policies.sql
        ├── 20251104102551_remove_updated_at_triggers.sql
        └── 20251104105155_add_role_inheritances_rls_policy.sql
```

---

### **Step 3: schema_migrations テーブル作成**

#### **環境**
- Supabase Studio (ローカル): http://127.0.0.1:54323
- Docker コンテナで稼働中

#### **実行SQL**

```sql
-- Supabase Studio の SQL Editor で実行

-- schema_migrations テーブル作成
CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 既存マイグレーションを「適用済み」として記録
INSERT INTO schema_migrations (version) VALUES 
('20251104090633_create_initial_schema'),
('20251104094921_enable_rls_policies'),
('20251104102551_remove_updated_at_triggers'),
('20251104105155_add_role_inheritances_rls_policy');
```

#### **実行結果**

```
Success. No rows returned
```

#### **確認SQL**

```sql
SELECT * FROM schema_migrations ORDER BY version;
```

#### **確認結果**

| version | applied_at |
|---------|------------|
| 20251104090633_create_initial_schema | 2025-11-05 ... |
| 20251104094921_enable_rls_policies | 2025-11-05 ... |
| 20251104102551_remove_updated_at_triggers | 2025-11-05 ... |
| 20251104105155_add_role_inheritances_rls_policy | 2025-11-05 ... |

✅ 4件のマイグレーション履歴が正しく記録された

---

## ✅ 作業完了状態

### **達成事項**

1. ✅ **Supabase CLIインストール完了**
   - Scoop経由でインストール
   - バージョン確認済み

2. ✅ **schema_migrations テーブル作成完了**
   - マイグレーション履歴管理テーブル作成
   - 既存4件のマイグレーションを記録

3. ✅ **既存データ保持**
   - 29テーブル保持
   - RLSポリシー34件保持
   - 全データ保持

4. ✅ **マイグレーション管理体制確立**
   - 今後の変更追跡が可能に
   - Supabase CLI による管理開始

---

## 🚀 今後のマイグレーション管理手順

### **新しいDB変更を加える場合**

#### **Step 1: マイグレーションファイル作成**

```powershell
cd D:\Projects\HarmoNet
supabase migration new add_new_feature
```

→ `supabase/migrations/` に新しいSQLファイルが生成される  
例: `20251105120000_add_new_feature.sql`

#### **Step 2: SQLファイル編集**

生成されたファイルをVSCodeで開き、変更内容を記述:

```sql
-- 例: 新しいカラムを追加
ALTER TABLE board_posts 
ADD COLUMN view_count INTEGER DEFAULT 0;
```

#### **Step 3: マイグレーション適用**

```powershell
supabase db push
```

→ 新しいマイグレーションがデータベースに適用され、`schema_migrations` に自動記録される

---

## 📊 現在のマイグレーション一覧

| # | Version | ファイル名 | 内容 | 適用日 |
|---|---------|-----------|------|--------|
| 1 | 20251104090633 | create_initial_schema.sql | 全30テーブル + ENUM + インデックス作成 | 2025-11-04 |
| 2 | 20251104094921 | enable_rls_policies.sql | RLSポリシー33件設定 | 2025-11-04 |
| 3 | 20251104102551 | remove_updated_at_triggers.sql | トリガー11件削除（Gemini監査対応） | 2025-11-04 |
| 4 | 20251104105155 | add_role_inheritances_rls_policy.sql | role_inheritances ポリシー追加 | 2025-11-04 |

**総テーブル数**: 29 + schema_migrations = 30テーブル  
**RLSポリシー数**: 34件

---

## ⚠️ 重要な注意事項

### **絶対に実行してはいけないコマンド**

```powershell
# ❌ 危険: 全データ削除
supabase db reset
```

このコマンドは：
- 全テーブルを削除
- 全データを削除
- migrationsを最初から再適用

**Phase 5の成果が全て消えるため、絶対に実行しないこと**

### **安全なコマンド**

```powershell
# ✅ 安全: 新規マイグレーション作成
supabase migration new <名前>

# ✅ 安全: マイグレーション適用
supabase db push

# ✅ 安全: 状態確認
supabase status
```

---

## 🔍 トラブルシューティング

### **問題1: `supabase` コマンドが認識されない**

**症状:**
```
supabase : The term 'supabase' is not recognized...
```

**原因:**
- Supabase CLIがインストールされていない

**解決方法:**
```powershell
scoop install supabase
```

---

### **問題2: マイグレーション適用時にエラー**

**症状:**
```
ERROR: relation "xxx" already exists
```

**原因:**
- テーブルが既に存在している状態でCREATE TABLEを実行した

**解決方法:**
1. `schema_migrations` テーブルを確認
2. 既に適用済みのマイグレーションは再実行しない
3. 新しい変更は新規マイグレーションファイルで実施

---

### **問題3: Docker コンテナが起動していない**

**症状:**
```
Error: Cannot connect to database
```

**原因:**
- Supabase Docker コンテナが停止している

**解決方法:**
```powershell
# Supabase起動
npx supabase start

# 状態確認
npx supabase status
```

---

## 📝 環境情報

### **開発環境**

| 項目 | 値 |
|------|-----|
| OS | Windows |
| プロジェクトパス | D:\Projects\HarmoNet |
| Supabase | Docker コンテナ版（ローカル） |
| Supabase Studio | http://127.0.0.1:54323 |
| Database URL | postgresql://postgres:postgres@127.0.0.1:54322/postgres |

### **インストール済みツール**

| ツール | バージョン | インストール方法 |
|--------|-----------|----------------|
| Scoop | 最新 | PowerShell スクリプト |
| Supabase CLI | 最新 | scoop install supabase |
| Docker Desktop | 動作中 | 事前インストール済み |

---

## 📚 参考資料

### **Supabase CLI 公式ドキュメント**
- https://supabase.com/docs/guides/cli

### **マイグレーション管理**
- https://supabase.com/docs/guides/cli/local-development#database-migrations

### **HarmoNet プロジェクトドキュメント**
- Phase 5 最終引き継ぎ資料: `08_harmonet-phase5-final-handover_v1_0.md`
- Phase 5 RLS協議書: `HarmoNet_Phase5_RLS_Discussion_v1_0.md`

---

## ✅ チェックリスト

### **作業完了確認**

- [x] Supabase CLIインストール
- [x] プロジェクト初期化確認
- [x] schema_migrations テーブル作成
- [x] 既存マイグレーション4件を履歴登録
- [x] 既存テーブル・データ保持確認
- [x] マイグレーション管理手順確立

### **Phase 6 準備完了**

- [x] マイグレーション履歴管理開始
- [x] 今後の変更追跡が可能
- [x] Supabase CLI による管理体制確立

---

## 📅 変更履歴

### v1.0 (2025-11-05)
- 初版作成
- Supabase CLIセットアップ手順記録
- schema_migrations テーブル作成記録
- 今後のマイグレーション管理手順記載

---

## 🎉 Phase 6 準備完了

すべての作業が完了し、Phase 6（機能要件詳細設計）へ進む準備が整いました。

---

**Document End**
