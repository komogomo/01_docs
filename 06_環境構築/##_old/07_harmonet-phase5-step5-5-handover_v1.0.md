# HarmoNet Phase 5 Step 5-5以降 引き継ぎ資料

**作成日**: 2025-11-04  
**バージョン**: v1.0  
**前回終了ステップ**: Step 5-4 完了  
**次回開始ステップ**: Step 5-5  
**Document ID**: HNM-PHASE5-HANDOVER-20251104

---

## 🎯 前回までの完了状況

### ✅ 完了済み作業

| Step | 作業内容 | 成果物 | 状態 |
|------|---------|--------|------|
| Step 5-1 | 事前確認 | - | ✅ 完了 |
| Step 5-2 | 要件定義確認 | エンティティ抽出結果 | ✅ 完了 |
| Step 5-3 | ER図作成 | `05_harmonet-er-diagram_v1.0.png` | ✅ 完了 |
| Step 5-4 | テーブル定義書作成 | `06_harmonet-db-table-definition_v1.0.md` | ✅ 完了 |

### 📁 完成済み成果物

1. **ER図**
   - ファイル: `/mnt/user-data/outputs/05_harmonet-er-diagram_v1.0.png`
   - 内容: 全30テーブルのエンティティ関連図
   - 形式: PNG画像(300dpi)

2. **テーブル定義書**
   - ファイル: `/mnt/user-data/outputs/06_harmonet-db-table-definition_v1.0.md`
   - 内容: 全テーブル詳細定義、ENUM定義、制約、インデックス、RLSポリシー例
   - 形式: Markdown

---

## 📋 次回作業内容 (Step 5-5以降)

### Step 5-5: マイグレーションファイル作成

**目的**: Supabaseに適用するSQLマイグレーションファイルを作成

#### 作業手順

1. **マイグレーションファイル生成**
   ```bash
   cd D:\projects\HarmoNet
   npx supabase migration new create_initial_schema
   ```
   
   生成されるファイル:
   ```
   supabase/migrations/20251104XXXXXX_create_initial_schema.sql
   ```

2. **SQLの記述内容**

   以下の順序でSQLを記述:
   
   ```sql
   -- ==========================================
   -- HarmoNet Initial Schema Migration
   -- Phase 5 - v1.0
   -- Created: 2025-11-04
   -- ==========================================
   
   -- ========== SECTION 1: ENUM定義 ==========
   CREATE TYPE "Status" AS ENUM ('active', 'inactive', 'archived');
   CREATE TYPE "ReactionType" AS ENUM ('like', 'report', 'bookmark');
   CREATE TYPE "ApprovalAction" AS ENUM ('approve', 'reconsider');
   CREATE TYPE "FacilityFeeUnit" AS ENUM ('day', 'hour');
   CREATE TYPE "DecisionType" AS ENUM ('allow', 'mask', 'block');
   CREATE TYPE "DecisionSource" AS ENUM ('system', 'human');
   
   -- ========== SECTION 2: テーブル作成 ==========
   -- 2.1 Tenant Management
   CREATE TABLE tenants (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_code TEXT NOT NULL UNIQUE,
       tenant_name TEXT NOT NULL,
       timezone TEXT,
       is_active BOOLEAN NOT NULL DEFAULT true,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   CREATE TABLE tenant_settings (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       config_json JSONB,
       default_language TEXT NOT NULL DEFAULT 'ja',
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   CREATE TABLE tenant_features (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       feature_key TEXT NOT NULL,
       enabled BOOLEAN NOT NULL DEFAULT true,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   -- 2.2 Users / Auth
   CREATE TABLE users (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID REFERENCES tenants(id),
       email TEXT NOT NULL UNIQUE,
       display_name TEXT NOT NULL,
       language TEXT NOT NULL DEFAULT 'ja',
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   CREATE TABLE user_tenants (
       user_id UUID NOT NULL REFERENCES users(id),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active',
       PRIMARY KEY (user_id, tenant_id)
   );
   
   CREATE TABLE user_profiles (
       user_id UUID PRIMARY KEY REFERENCES users(id),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       preferences JSONB,
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   -- 2.3 Roles / Permissions
   CREATE TABLE roles (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       role_key TEXT NOT NULL UNIQUE,
       name TEXT NOT NULL,
       scope TEXT NOT NULL DEFAULT 'tenant',
       permissions_ref TEXT,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE user_roles (
       user_id UUID NOT NULL REFERENCES users(id),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       role_id UUID NOT NULL REFERENCES roles(id),
       assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       UNIQUE (user_id, tenant_id, role_id)
   );
   
   CREATE TABLE role_inheritances (
       parent_role_id UUID NOT NULL REFERENCES roles(id),
       child_role_id UUID NOT NULL REFERENCES roles(id),
       PRIMARY KEY (parent_role_id, child_role_id)
   );
   
   CREATE TABLE permissions (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       permission_key TEXT NOT NULL UNIQUE,
       resource TEXT NOT NULL,
       action TEXT NOT NULL
   );
   
   CREATE TABLE role_permissions (
       role_id UUID NOT NULL REFERENCES roles(id),
       permission_id UUID NOT NULL REFERENCES permissions(id),
       UNIQUE (role_id, permission_id)
   );
   
   -- 2.4 Board
   CREATE TABLE board_categories (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       category_key TEXT NOT NULL,
       category_name TEXT NOT NULL,
       requires_approval BOOLEAN NOT NULL DEFAULT false,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   CREATE TABLE board_posts (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       author_id UUID NOT NULL REFERENCES users(id),
       category_id UUID NOT NULL REFERENCES board_categories(id),
       title TEXT NOT NULL,
       content TEXT NOT NULL,
       tags TEXT[] NOT NULL DEFAULT '{}',
       status TEXT NOT NULL DEFAULT 'draft',
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE board_comments (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       post_id UUID NOT NULL REFERENCES board_posts(id),
       author_id UUID NOT NULL REFERENCES users(id),
       content TEXT NOT NULL,
       parent_comment_id UUID REFERENCES board_comments(id),
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE board_reactions (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       post_id UUID NOT NULL REFERENCES board_posts(id),
       user_id UUID NOT NULL REFERENCES users(id),
       reaction_type "ReactionType" NOT NULL,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       UNIQUE (post_id, user_id, reaction_type)
   );
   
   CREATE TABLE board_attachments (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       post_id UUID NOT NULL REFERENCES board_posts(id),
       file_url TEXT NOT NULL,
       file_name TEXT NOT NULL,
       file_type TEXT NOT NULL,
       file_size INTEGER NOT NULL,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE board_approval_logs (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       post_id UUID NOT NULL REFERENCES board_posts(id),
       approver_id UUID NOT NULL REFERENCES users(id),
       action "ApprovalAction" NOT NULL,
       comment TEXT,
       acted_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   -- 2.5 Announcements
   CREATE TABLE announcements (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       title TEXT NOT NULL,
       content TEXT NOT NULL,
       target_mode TEXT NOT NULL DEFAULT 'all',
       valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
       valid_until TIMESTAMPTZ,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE announcement_reads (
       announcement_id UUID NOT NULL REFERENCES announcements(id),
       user_id UUID NOT NULL REFERENCES users(id),
       read_at TIMESTAMPTZ NOT NULL,
       UNIQUE (announcement_id, user_id)
   );
   
   -- 2.6 Facilities / Reservations
   CREATE TABLE facilities (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       facility_name TEXT NOT NULL,
       facility_type TEXT NOT NULL,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE facility_settings (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       facility_id UUID NOT NULL REFERENCES facilities(id),
       fee_per_day NUMERIC,
       fee_unit "FacilityFeeUnit" NOT NULL DEFAULT 'day',
       max_consecutive_days INTEGER NOT NULL DEFAULT 3,
       reservable_until_months INTEGER NOT NULL DEFAULT 1,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE facility_slots (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       facility_id UUID NOT NULL REFERENCES facilities(id),
       slot_key TEXT NOT NULL,
       slot_name TEXT NOT NULL,
       status "Status" NOT NULL DEFAULT 'active'
   );
   
   CREATE TABLE facility_reservations (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       facility_id UUID NOT NULL REFERENCES facilities(id),
       slot_id UUID REFERENCES facility_slots(id),
       user_id UUID NOT NULL REFERENCES users(id),
       start_at TIMESTAMPTZ NOT NULL,
       end_at TIMESTAMPTZ NOT NULL,
       status TEXT NOT NULL DEFAULT 'pending',
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   -- 2.7 Translation / TTS Cache
   CREATE TABLE translation_cache (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       content_type TEXT NOT NULL,
       content_id TEXT NOT NULL,
       language TEXT NOT NULL,
       translated_text TEXT NOT NULL,
       expires_at TIMESTAMPTZ,
       UNIQUE (tenant_id, content_type, content_id, language)
   );
   
   CREATE TABLE tts_cache (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       content_type TEXT NOT NULL,
       content_id TEXT NOT NULL,
       language TEXT NOT NULL,
       voice_type TEXT NOT NULL DEFAULT 'default',
       audio_url TEXT NOT NULL,
       duration_sec NUMERIC,
       expires_at TIMESTAMPTZ,
       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       UNIQUE (tenant_id, content_type, content_id, language)
   );
   
   -- 2.8 Notifications
   CREATE TABLE notifications (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       user_id UUID NOT NULL REFERENCES users(id),
       type TEXT NOT NULL,
       title TEXT NOT NULL,
       content TEXT NOT NULL,
       sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       read_at TIMESTAMPTZ
   );
   
   CREATE TABLE user_notification_settings (
       user_id UUID NOT NULL REFERENCES users(id),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       notification_type TEXT NOT NULL,
       enabled BOOLEAN NOT NULL DEFAULT true,
       updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       UNIQUE (user_id, tenant_id, notification_type)
   );
   
   -- 2.9 Audit / Moderation
   CREATE TABLE audit_logs (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       user_id UUID NOT NULL REFERENCES users(id),
       action_type TEXT NOT NULL,
       target_resource TEXT NOT NULL,
       target_id TEXT,
       ip_address TEXT,
       user_agent TEXT,
       timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   
   CREATE TABLE moderation_logs (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       tenant_id UUID NOT NULL REFERENCES tenants(id),
       content_type TEXT NOT NULL,
       content_id TEXT NOT NULL,
       ai_score NUMERIC,
       flagged_reason TEXT,
       decision "DecisionType" NOT NULL DEFAULT 'allow',
       decided_by "DecisionSource" NOT NULL DEFAULT 'system',
       decided_at TIMESTAMPTZ NOT NULL DEFAULT now(),
       reviewed_by TEXT
   );
   
   -- ========== SECTION 3: インデックス作成 ==========
   -- Tenant
   CREATE INDEX idx_tenants_code ON tenants(tenant_code);
   CREATE INDEX idx_tenants_active ON tenants(is_active);
   
   -- Users
   CREATE INDEX idx_users_email ON users(email);
   CREATE INDEX idx_users_tenant ON users(tenant_id);
   
   -- Board
   CREATE INDEX idx_board_posts_tenant ON board_posts(tenant_id);
   CREATE INDEX idx_board_posts_category ON board_posts(category_id);
   CREATE INDEX idx_board_posts_author ON board_posts(author_id);
   CREATE INDEX idx_board_posts_created ON board_posts(created_at DESC);
   CREATE INDEX idx_board_posts_tags ON board_posts USING GIN(tags);
   
   -- Facilities
   CREATE INDEX idx_facility_reservations_facility_date ON facility_reservations(facility_id, start_at);
   CREATE INDEX idx_facility_reservations_user ON facility_reservations(user_id);
   
   -- Translation Cache
   CREATE INDEX idx_translation_cache_lookup ON translation_cache(tenant_id, content_type, content_id, language);
   
   -- Notifications
   CREATE INDEX idx_notifications_user_unread ON notifications(user_id, read_at) WHERE read_at IS NULL;
   
   -- Audit
   CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
   CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
   
   -- ========== SECTION 4: コメント追加 ==========
   COMMENT ON TABLE tenants IS 'テナントマスタ';
   COMMENT ON TABLE users IS 'ユーザーマスタ';
   COMMENT ON TABLE board_posts IS '掲示板投稿';
   COMMENT ON TABLE facilities IS '施設マスタ';
   COMMENT ON TABLE translation_cache IS '翻訳キャッシュ(30日保持)';
   COMMENT ON TABLE tts_cache IS 'TTS音声キャッシュ(30日保持)';
   COMMENT ON TABLE audit_logs IS '監査ログ(365日保持)';
   COMMENT ON TABLE moderation_logs IS 'AIモデレーションログ';
   
   -- ========== SECTION 5: updated_at自動更新トリガー ==========
   CREATE OR REPLACE FUNCTION update_updated_at_column()
   RETURNS TRIGGER AS $$
   BEGIN
       NEW.updated_at = now();
       RETURN NEW;
   END;
   $$ language 'plpgsql';
   
   -- 各テーブルにトリガー設定
   CREATE TRIGGER update_tenants_updated_at 
       BEFORE UPDATE ON tenants
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_tenant_settings_updated_at 
       BEFORE UPDATE ON tenant_settings
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_tenant_features_updated_at 
       BEFORE UPDATE ON tenant_features
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_users_updated_at 
       BEFORE UPDATE ON users
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_board_categories_updated_at 
       BEFORE UPDATE ON board_categories
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_board_posts_updated_at 
       BEFORE UPDATE ON board_posts
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_board_comments_updated_at 
       BEFORE UPDATE ON board_comments
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_announcements_updated_at 
       BEFORE UPDATE ON announcements
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_facilities_updated_at 
       BEFORE UPDATE ON facilities
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_facility_settings_updated_at 
       BEFORE UPDATE ON facility_settings
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   
   CREATE TRIGGER update_facility_reservations_updated_at 
       BEFORE UPDATE ON facility_reservations
       FOR EACH ROW
       EXECUTE FUNCTION update_updated_at_column();
   ```

3. **ファイル保存**
   
   上記SQLを生成されたマイグレーションファイルに記述

---

### Step 5-6: マイグレーション実行

**目的**: 作成したマイグレーションをSupabaseに適用

#### 作業手順

1. **マイグレーション適用**
   ```bash
   cd D:\projects\HarmoNet
   npx supabase db push
   ```

2. **適用結果確認**
   ```bash
   npx supabase db diff
   ```
   
   期待結果: `No schema changes detected.`

3. **Studio UIでテーブル確認**
   - ブラウザで `http://127.0.0.1:54323` を開く
   - 左メニュー「Table Editor」をクリック
   - 全30テーブルが表示されることを確認

4. **SQL Editorで確認**
   ```sql
   -- テーブル一覧
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public'
   ORDER BY table_name;
   
   -- テーブル構造確認
   \d tenants
   \d users
   \d board_posts
   ```

#### トラブルシューティング

**エラーが発生した場合**:
```bash
# データベースをリセット
npx supabase db reset

# マイグレーションを再実行
npx supabase db push
```

---

### Step 5-7: Row Level Security (RLS) 設定

**目的**: テナント分離のためのRLSポリシーを設定

#### 作業手順

1. **RLS設定用マイグレーション作成**
   ```bash
   npx supabase migration new enable_rls_policies
   ```

2. **RLS SQLの記述**

   ```sql
   -- ==========================================
   -- HarmoNet RLS Policies Migration
   -- Phase 5 - v1.0
   -- Created: 2025-11-04
   -- ==========================================
   
   -- ========== RLS有効化 ==========
   ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
   ALTER TABLE tenant_settings ENABLE ROW LEVEL SECURITY;
   ALTER TABLE tenant_features ENABLE ROW LEVEL SECURITY;
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_tenants ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_categories ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_posts ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_comments ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_reactions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_attachments ENABLE ROW LEVEL SECURITY;
   ALTER TABLE board_approval_logs ENABLE ROW LEVEL SECURITY;
   ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
   ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;
   ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
   ALTER TABLE facility_settings ENABLE ROW LEVEL SECURITY;
   ALTER TABLE facility_slots ENABLE ROW LEVEL SECURITY;
   ALTER TABLE facility_reservations ENABLE ROW LEVEL SECURITY;
   ALTER TABLE translation_cache ENABLE ROW LEVEL SECURITY;
   ALTER TABLE tts_cache ENABLE ROW LEVEL SECURITY;
   ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;
   ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
   ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;
   
   -- ========== テナント分離ポリシー(tenants) ==========
   CREATE POLICY tenant_select_own
   ON tenants
   FOR SELECT
   USING (id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   -- ========== テナント分離ポリシー(全テーブル共通パターン) ==========
   -- tenant_settings
   CREATE POLICY tenant_settings_select
   ON tenant_settings FOR SELECT
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_settings_insert
   ON tenant_settings FOR INSERT
   WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_settings_update
   ON tenant_settings FOR UPDATE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_settings_delete
   ON tenant_settings FOR DELETE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   -- tenant_features
   CREATE POLICY tenant_features_select
   ON tenant_features FOR SELECT
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_features_insert
   ON tenant_features FOR INSERT
   WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_features_update
   ON tenant_features FOR UPDATE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY tenant_features_delete
   ON tenant_features FOR DELETE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   -- users
   CREATE POLICY users_select
   ON users FOR SELECT
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY users_insert
   ON users FOR INSERT
   WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY users_update
   ON users FOR UPDATE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   -- board_posts
   CREATE POLICY board_posts_select
   ON board_posts FOR SELECT
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY board_posts_insert
   ON board_posts FOR INSERT
   WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY board_posts_update
   ON board_posts FOR UPDATE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   CREATE POLICY board_posts_delete
   ON board_posts FOR DELETE
   USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   
   -- 以下、同様のパターンで全テーブルにRLSポリシーを設定
   -- (board_comments, board_reactions, announcements, facilities等)
   
   -- ========== 特殊ポリシー ==========
   -- audit_logs: 読み取り専用(管理者のみ)
   CREATE POLICY audit_logs_select_admin
   ON audit_logs FOR SELECT
   USING (
       tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
       AND (auth.jwt() ->> 'role') IN ('tenant_admin', 'system_admin')
   );
   
   CREATE POLICY audit_logs_insert_all
   ON audit_logs FOR INSERT
   WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
   ```

3. **RLSマイグレーション適用**
   ```bash
   npx supabase db push
   ```

4. **ポリシー確認**
   - Studio UIから「Authentication」→「Policies」で確認
   - 各テーブルにポリシーが設定されていることを確認

---

### Step 5-8: 初期データ投入

**目的**: システム動作に必要な初期マスタデータを投入

#### 作業手順

1. **シードデータファイル編集**
   
   ファイル: `supabase/seed.sql`

2. **初期データSQL記述**

   ```sql
   -- ==========================================
   -- HarmoNet Seed Data
   -- Phase 5 - v1.0
   -- Created: 2025-11-04
   -- ==========================================
   
   -- ========== 1. テナント初期データ ==========
   INSERT INTO tenants (tenant_code, tenant_name, timezone) VALUES
   ('SYSTEM', 'システム管理', 'Asia/Tokyo'),
   ('DEMO', 'デモテナント', 'Asia/Tokyo');
   
   -- ========== 2. ロール初期データ ==========
   INSERT INTO roles (role_key, name, scope, permissions_ref) VALUES
   ('system_admin', 'システム管理者', 'global', 'system_admin_permissions'),
   ('tenant_admin', 'テナント管理者', 'tenant', 'tenant_admin_permissions'),
   ('general_user', '一般ユーザー', 'tenant', 'general_user_permissions');
   
   -- ========== 3. 権限初期データ ==========
   INSERT INTO permissions (permission_key, resource, action) VALUES
   -- テナント管理
   ('tenant.create', 'tenant', 'create'),
   ('tenant.read', 'tenant', 'read'),
   ('tenant.update', 'tenant', 'update'),
   ('tenant.delete', 'tenant', 'delete'),
   
   -- ユーザー管理
   ('user.create', 'user', 'create'),
   ('user.read', 'user', 'read'),
   ('user.update', 'user', 'update'),
   ('user.delete', 'user', 'delete'),
   
   -- 掲示板
   ('board.post', 'board', 'create'),
   ('board.read', 'board', 'read'),
   ('board.update_own', 'board', 'update'),
   ('board.delete_own', 'board', 'delete'),
   ('board.approve', 'board', 'approve'),
   
   -- お知らせ
   ('announcement.create', 'announcement', 'create'),
   ('announcement.read', 'announcement', 'read'),
   
   -- 施設予約
   ('facility.reserve', 'facility', 'create'),
   ('facility.read', 'facility', 'read'),
   ('facility.cancel_own', 'facility', 'delete');
   
   -- ========== 4. ロール-権限紐付け ==========
   -- system_admin: 全権限
   INSERT INTO role_permissions (role_id, permission_id)
   SELECT r.id, p.id
   FROM roles r
   CROSS JOIN permissions p
   WHERE r.role_key = 'system_admin';
   
   -- tenant_admin: テナント内管理権限
   INSERT INTO role_permissions (role_id, permission_id)
   SELECT r.id, p.id
   FROM roles r, permissions p
   WHERE r.role_key = 'tenant_admin'
   AND p.permission_key IN (
       'user.create', 'user.read', 'user.update',
       'board.post', 'board.read', 'board.approve',
       'announcement.create', 'announcement.read',
       'facility.reserve', 'facility.read', 'facility.cancel_own'
   );
   
   -- general_user: 基本権限
   INSERT INTO role_permissions (role_id, permission_id)
   SELECT r.id, p.id
   FROM roles r, permissions p
   WHERE r.role_key = 'general_user'
   AND p.permission_key IN (
       'board.post', 'board.read', 'board.update_own', 'board.delete_own',
       'announcement.read',
       'facility.reserve', 'facility.read', 'facility.cancel_own'
   );
   
   -- ========== 5. 掲示板カテゴリ初期データ ==========
   -- DEMOテナント用
   INSERT INTO board_categories (tenant_id, category_key, category_name, requires_approval)
   SELECT id, 'general', '一般', false
   FROM tenants WHERE tenant_code = 'DEMO';
   
   INSERT INTO board_categories (tenant_id, category_key, category_name, requires_approval)
   SELECT id, 'important', '重要', true
   FROM tenants WHERE tenant_code = 'DEMO';
   
   INSERT INTO board_categories (tenant_id, category_key, category_name, requires_approval)
   SELECT id, 'circular', '回覧板', true
   FROM tenants WHERE tenant_code = 'DEMO';
   
   INSERT INTO board_categories (tenant_id, category_key, category_name, requires_approval)
   SELECT id, 'rule', 'ルール', true
   FROM tenants WHERE tenant_code = 'DEMO';
   
   -- ========== 6. 施設初期データ(駐車場) ==========
   -- DEMOテナント用
   INSERT INTO facilities (tenant_id, facility_name, facility_type)
   SELECT id, 'ゲスト駐車場', 'parking'
   FROM tenants WHERE tenant_code = 'DEMO';
   
   -- 施設設定
   INSERT INTO facility_settings (tenant_id, facility_id, fee_per_day, fee_unit, max_consecutive_days, reservable_until_months)
   SELECT t.id, f.id, 100, 'day', 3, 1
   FROM tenants t
   JOIN facilities f ON f.tenant_id = t.id
   WHERE t.tenant_code = 'DEMO' AND f.facility_type = 'parking';
   
   -- 駐車場区画(表F1〜F6、裏B1〜B6)
   INSERT INTO facility_slots (tenant_id, facility_id, slot_key, slot_name)
   SELECT t.id, f.id, 'F' || i, '表F' || i
   FROM tenants t
   JOIN facilities f ON f.tenant_id = t.id
   CROSS JOIN generate_series(1, 6) AS i
   WHERE t.tenant_code = 'DEMO' AND f.facility_type = 'parking';
   
   INSERT INTO facility_slots (tenant_id, facility_id, slot_key, slot_name)
   SELECT t.id, f.id, 'B' || i, '裏B' || i
   FROM tenants t
   JOIN facilities f ON f.tenant_id = t.id
   CROSS JOIN generate_series(1, 6) AS i
   WHERE t.tenant_code = 'DEMO' AND f.facility_type = 'parking';
   ```

3. **シードデータ投入**
   ```bash
   npx supabase db reset
   ```
   
   ※ `db reset` はマイグレーション再実行 + seed.sql実行

4. **データ確認**
   ```sql
   -- テナント確認
   SELECT * FROM tenants;
   
   -- ロール確認
   SELECT * FROM roles;
   
   -- カテゴリ確認
   SELECT * FROM board_categories;
   
   -- 施設・区画確認
   SELECT f.facility_name, fs.slot_name 
   FROM facilities f
   JOIN facility_slots fs ON fs.facility_id = f.id
   ORDER BY fs.slot_key;
   ```

---

## 🔍 確認ポイント

### Step 5-5完了時
- [ ] マイグレーションファイルが生成されている
- [ ] SQL構文エラーがない
- [ ] 全30テーブルのCREATE文が記述されている
- [ ] ENUM定義が記述されている
- [ ] インデックスが記述されている
- [ ] トリガーが記述されている

### Step 5-6完了時
- [ ] `npx supabase db push` が成功
- [ ] `npx supabase db diff` で差分なし
- [ ] Studio UIで全30テーブルが表示される
- [ ] 各テーブルの構造が定義書通り

### Step 5-7完了時
- [ ] RLSが全テーブルで有効化されている
- [ ] Studio UIのPoliciesで各ポリシーが表示される
- [ ] テナント分離ポリシーが正しく設定されている

### Step 5-8完了時
- [ ] テナントデータが2件登録されている
- [ ] ロールデータが3件登録されている
- [ ] 掲示板カテゴリが4件登録されている
- [ ] 駐車場区画が12件登録されている

---

## 📚 参照ファイル

### 必須参照
1. **テーブル定義書** (Step 5-4成果物)
   - `/mnt/user-data/outputs/06_harmonet-db-table-definition_v1.0.md`
   - 全テーブル定義の正式版

2. **Prismaスキーマ** (タチコマ作成)
   - `/mnt/project/04_harmonet-prisma-schema_v1.0.prisma`
   - Prisma ORM定義

### 補足参照
3. **ER図** (Step 5-3成果物)
   - `/mnt/user-data/outputs/05_harmonet-er-diagram_v1.0.png`
   - エンティティ関連図

4. **機能要件書**
   - プロジェクトナレッジ内の各種要件定義書

---

## 🚨 注意事項

### マイグレーション作成時
1. **SQL構文チェック**
   - CREATE文の順序(外部キー依存関係に注意)
   - ENUM定義を最初に記述
   - インデックスはテーブル作成後

2. **命名規則**
   - テーブル名: スネークケース小文字
   - カラム名: スネークケース小文字
   - ENUM: パスカルケース

3. **データ型**
   - UUIDは `gen_random_uuid()`
   - Timestampは `TIMESTAMPTZ`(タイムゾーン付き)
   - JSONは `JSONB`(バイナリJSON)

### RLS設定時
1. **ポリシー命名**
   - `{table}_{operation}_{condition}`形式
   - 例: `board_posts_select`, `users_update`

2. **JWTクレーム**
   - `tenant_id`: テナントID
   - `role`: ロール(system_admin/tenant_admin/general_user)
   - `lang`: 言語設定

3. **テスト**
   - 異なるテナントIDでアクセステスト
   - 適切に分離されていることを確認

### シードデータ投入時
1. **外部キー制約**
   - 親テーブルから順に投入
   - テナント→ユーザー→その他の順

2. **UUID参照**
   - SELECTで親IDを取得してINSERT
   - ハードコードしない

---

## 🎯 次回チャット開始時の指示

```
HarmoNet Phase 5 の続きです。

前回完了: Step 5-4 (ER図・テーブル定義書作成)
次回作業: Step 5-5 (マイグレーションファイル作成)

引き継ぎ資料: 07_harmonet-phase5-step5-5-handover_v1.0.md
参照ファイル: 
- 06_harmonet-db-table-definition_v1.0.md (テーブル定義書)
- 04_harmonet-prisma-schema_v1.0.prisma (Prismaスキーマ)

Step 5-5から作業を開始してください。
```

---

## ✅ Phase 5 完了チェックリスト

Phase 5完了時に以下を確認:

- [ ] Step 5-1: 事前確認完了
- [ ] Step 5-2: 要件定義確認完了
- [ ] Step 5-3: ER図作成完了
- [ ] Step 5-4: テーブル定義書作成完了
- [ ] Step 5-5: マイグレーションファイル作成完了
- [ ] Step 5-6: マイグレーション実行完了
- [ ] Step 5-7: RLS設定完了
- [ ] Step 5-8: 初期データ投入完了

---

## 📞 トラブルシューティング

### Supabaseが起動しない
```bash
# Docker Desktop再起動
# 1. Docker Desktopを完全終了
# 2. 30秒待つ
# 3. Docker Desktop再起動

# Supabase再起動
cd D:\projects\HarmoNet
npx supabase stop
npx supabase start
```

### マイグレーションエラー
```bash
# デバッグモードで実行
npx supabase db push --debug

# データベースリセット
npx supabase db reset
```

### RLS動作確認
```sql
-- 現在のJWTトークン確認
SELECT auth.jwt();

-- RLS有効化確認
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- ポリシー一覧確認
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

---

**Document End**
