# HarmoNet RLS Policy Standard v1.0

**Document ID:** HARMONET-RLS-POLICY-STD-V1.0  
**Version:** 1.0  
**Created:** 2025-11-20  
**Author:** Claude (HarmoNet Design Specialist) + TKD (Project Owner)  
**Status:** 正式版（Phase 9 以降の全テーブルに適用）

---

## 📋 目次

1. [目的](#1-目的)
2. [適用範囲](#2-適用範囲)
3. [問題の背景](#3-問題の背景)
4. [必須ルール](#4-必須ルール)
5. [ポリシーテンプレート](#5-ポリシーテンプレート)
6. [新規テーブル追加時の手順](#6-新規テーブル追加時の手順)
7. [検証方法](#7-検証方法)
8. [トラブルシューティング](#8-トラブルシューティング)
9. [付録](#9-付録)

---

## 1. 目的

本書は HarmoNet プロジェクトにおける **Row Level Security (RLS) ポリシーの作成標準** を定義し、以下を実現する:

- ✅ Supabase Linter 警告ゼロの維持
- ✅ クエリパフォーマンスの最適化（非機能要件「DBクエリ：1秒以内」の遵守）
- ✅ マルチテナント分離の完全性保証
- ✅ AI開発メンバー（Claude/Gemini/Tachikoma/Windsurf/Cursor）による自動生成時の品質統一

---

## 2. 適用範囲

### 2.1 対象

- **全テーブル**（31テーブル + 今後追加される全テーブル）
- **全マイグレーションファイル**
- **AI生成コード**（RLSポリシー部分）

### 2.2 準拠必須ドキュメント

- `schema.prisma` (v1.7以降)
- `harmonet-technical-stack-definition_v4.4.md`
- `Nonfunctional-requirements_v1.0.md`

---

## 3. 問題の背景

### 3.1 発生していた問題

#### 問題1: パフォーマンス警告（`auth_rls_initplan`）

**症状:**
```sql
-- ❌ 問題のあるコード
CREATE POLICY "policy_name" ON table_name
FOR SELECT
USING (auth.jwt() ->> 'tenant_id' = tenant_id);
```

**原因:**
- `auth.jwt()` が行ごとに再評価される
- データ量増加時にクエリ速度が著しく低下

**影響:**
- 非機能要件「DBクエリ：1秒以内」を将来的に満たせない

#### 問題2: ポリシー重複警告（`multiple_permissive_policies`）

**症状:**
```sql
-- ❌ 問題のあるコード
CREATE POLICY "policy_all" ON table_name
FOR ALL
USING (condition)
WITH CHECK (condition);

-- 同じテーブル・同じロールで複数のポリシーが存在
```

**原因:**
- `FOR ALL` による一括定義
- 同一操作に対する複数ポリシー

**影響:**
- 評価コストの無駄
- ポリシー適用順序の不明確化

#### 問題3: 構文エラー（途中経過）

**症状:**
```sql
-- ❌ PostgreSQL非サポート構文
CREATE POLICY "policy_name" ON table_name
FOR INSERT, UPDATE, DELETE
USING (condition);
```

**エラー:**
```
ERROR: syntax error at or near ","
```

**原因:**
- PostgreSQLは `FOR INSERT, UPDATE, DELETE` という短縮構文を未サポート

---

## 4. 必須ルール

### 4.1 Subquery Wrap（最重要）

**ルール:**
すべての `auth.jwt()` / `auth.uid()` は **必ずサブクエリで囲む**

**理由:**
PostgreSQLがクエリ全体で関数を1回だけ実行するよう最適化される

**適用例:**

```sql
-- ❌ 禁止
auth.jwt() ->> 'tenant_id'
auth.uid()

-- ✅ 必須
(select auth.jwt()) ->> 'tenant_id'
(select auth.uid())
```

---

### 4.2 Split Policies（必須）

**ルール:**
操作ごとに個別のポリシーを定義する（`FOR ALL` 禁止）

**理由:**
- 重複警告の解消
- `WITH CHECK` が必要な操作とそうでない操作の明確な分離

**適用例:**

```sql
-- ❌ 禁止
CREATE POLICY "policy_all" ON table_name
FOR ALL
USING (condition)
WITH CHECK (condition);

-- ✅ 必須
CREATE POLICY "table_name_select_authenticated" ON table_name
FOR SELECT
USING (condition);

CREATE POLICY "table_name_insert_authenticated" ON table_name
FOR INSERT
WITH CHECK (condition);

CREATE POLICY "table_name_update_authenticated" ON table_name
FOR UPDATE
USING (condition)
WITH CHECK (condition);

CREATE POLICY "table_name_delete_authenticated" ON table_name
FOR DELETE
USING (condition);
```

---

### 4.3 Naming Convention（必須）

**フォーマット:**
```
{table_name}_{operation}_{role}
```

**例:**
- `board_posts_select_authenticated`
- `board_posts_insert_authenticated`
- `board_posts_update_authenticated`
- `board_posts_delete_authenticated`
- `users_select_public` (anonロール向け)

**ロール名:**
- `authenticated` - ログイン済みユーザー
- `public` - 匿名ユーザー（anonロール）
- `service_role` - サービスロール（管理者）

---

### 4.4 WITH CHECK 使用ルール

| 操作 | USING | WITH CHECK | 備考 |
|------|-------|------------|------|
| SELECT | ✅ 必須 | ❌ 不要 | 読み取り権限のみ |
| INSERT | ❌ 不要 | ✅ 必須 | 挿入データの検証 |
| UPDATE | ✅ 必須 | ✅ 必須 | 既存行の読み取り + 更新データの検証 |
| DELETE | ✅ 必須 | ❌ 不要 | 削除権限のみ |

---

## 5. ポリシーテンプレート

### 5.1 基本パターン（テナント分離）

```sql
-- ============================================
-- RLS Policies for {table_name}
-- ============================================

-- Enable RLS
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;

-- SELECT Policy
CREATE POLICY "{table_name}_select_authenticated"
ON {table_name}
FOR SELECT
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- INSERT Policy
CREATE POLICY "{table_name}_insert_authenticated"
ON {table_name}
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- UPDATE Policy
CREATE POLICY "{table_name}_update_authenticated"
ON {table_name}
FOR UPDATE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
)
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- DELETE Policy
CREATE POLICY "{table_name}_delete_authenticated"
ON {table_name}
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);
```

---

### 5.2 ユーザー自身のデータのみ（user_id分離）

```sql
-- SELECT Policy (自分のデータのみ)
CREATE POLICY "{table_name}_select_own"
ON {table_name}
FOR SELECT
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- INSERT Policy (自分のデータのみ)
CREATE POLICY "{table_name}_insert_own"
ON {table_name}
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- UPDATE Policy (自分のデータのみ)
CREATE POLICY "{table_name}_update_own"
ON {table_name}
FOR UPDATE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
)
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- DELETE Policy (自分のデータのみ)
CREATE POLICY "{table_name}_delete_own"
ON {table_name}
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);
```

---

### 5.3 マスタデータ（全員参照可能）

```sql
-- 例: roles, permissions

-- SELECT Policy (全員参照可能)
CREATE POLICY "roles_select_all"
ON roles
FOR SELECT
TO authenticated
USING (true);

-- INSERT/UPDATE/DELETE は system_admin のみ
CREATE POLICY "roles_insert_admin"
ON roles
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'role' = 'system_admin'
);

CREATE POLICY "roles_update_admin"
ON roles
FOR UPDATE
TO authenticated
USING (
  (select auth.jwt()) ->> 'role' = 'system_admin'
)
WITH CHECK (
  (select auth.jwt()) ->> 'role' = 'system_admin'
);

CREATE POLICY "roles_delete_admin"
ON roles
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'role' = 'system_admin'
);
```

---

### 5.4 匿名ユーザー向け（public/anon）

```sql
-- 例: お知らせの公開投稿

-- SELECT Policy (匿名も参照可能)
CREATE POLICY "announcements_select_public"
ON announcements
FOR SELECT
TO public
USING (
  status = 'published'
  AND
  valid_from <= now()
  AND
  (valid_until IS NULL OR valid_until >= now())
);

-- INSERT/UPDATE/DELETE は authenticated のみ
-- (上記の基本パターンを併用)
```

---

## 6. 新規テーブル追加時の手順

### 6.1 フロー

```
1. Prisma schema.prisma にテーブル定義追加
   ↓
2. マイグレーションファイル生成
   ↓
3. RLSポリシーSQL作成（本標準に準拠）
   ↓
4. Linter実行で検証
   ↓
5. ローカル環境で動作確認
   ↓
6. 本番環境へデプロイ
```

---

### 6.2 詳細手順

#### Step 1: schema.prisma 編集

```prisma
model new_table {
  id         String   @id @default(uuid())
  tenant_id  String   // ← テナント分離必須
  user_id    String   // ← ユーザー分離（必要に応じて）
  content    String   @db.Text
  created_at DateTime @default(now())
  updated_at DateTime @updatedAt
  status     status   @default(active)

  // Relations
  tenant tenants @relation(fields: [tenant_id], references: [id])
  user   users   @relation(fields: [user_id], references: [id])
}
```

**重要:**
- `tenant_id` は必須（マルチテナント分離）
- `user_id` はユーザー分離が必要な場合に追加
- リレーションを正しく定義

---

#### Step 2: マイグレーション生成

```powershell
npx prisma migrate dev --name add_new_table --create-only
```

**生成されるファイル:**
```
supabase/migrations/YYYYMMDDHHMMSS_add_new_table.sql
```

---

#### Step 3: RLSポリシーSQL作成

**3-1: マイグレーションファイルに追記**

または

**3-2: 別ファイルとして作成**

```powershell
# 例: 別ファイルとして作成
supabase/migrations/YYYYMMDDHHMMSS_enable_rls_new_table.sql
```

**内容:**

```sql
-- ============================================
-- RLS Policies for new_table
-- ============================================

-- Enable RLS
ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;

-- SELECT Policy
CREATE POLICY "new_table_select_authenticated"
ON new_table
FOR SELECT
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- INSERT Policy
CREATE POLICY "new_table_insert_authenticated"
ON new_table
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- UPDATE Policy
CREATE POLICY "new_table_update_authenticated"
ON new_table
FOR UPDATE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
)
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- DELETE Policy
CREATE POLICY "new_table_delete_authenticated"
ON new_table
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);
```

---

#### Step 4: Linter実行

```powershell
npx supabase db lint
```

**期待結果:**
```
✅ No issues found
```

**警告が出た場合:**
- `auth_rls_initplan` → Subquery Wrap が漏れている
- `multiple_permissive_policies` → ポリシーが重複している

→ [8. トラブルシューティング](#8-トラブルシューティング) 参照

---

#### Step 5: ローカル環境で動作確認

```powershell
# データベースリセット（マイグレーション適用）
npx supabase db reset

# Prisma Client 再生成
npx prisma generate

# 動作確認
npx prisma studio
```

**確認項目:**
- ✅ テーブルが作成されている
- ✅ RLSが有効になっている
- ✅ ポリシーが正しく適用されている
- ✅ データ挿入・参照・更新・削除が正しく動作する

---

#### Step 6: 本番環境へデプロイ

```powershell
# Supabase Cloud へマイグレーション適用
npx supabase db push

# または GitHub Actions 経由でデプロイ
git add .
git commit -m "feat: add new_table with RLS policies"
git push origin main
```

---

## 7. 検証方法

### 7.1 Linter実行

```powershell
npx supabase db lint
```

**目標:**
```
✅ No issues found
```

---

### 7.2 RLSポリシー確認

```sql
-- PostgreSQL で直接確認
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'new_table'
ORDER BY policyname;
```

---

### 7.3 動作確認

```typescript
// Next.js API Route または Prisma Studio で確認

// テナントAのユーザーでログイン
// → テナントAのデータのみ参照可能
// → テナントBのデータは参照不可

// テナントBのユーザーでログイン
// → テナントBのデータのみ参照可能
// → テナントAのデータは参照不可
```

---

## 8. トラブルシューティング

### 8.1 `auth_rls_initplan` 警告

**症状:**
```
⚠ auth_rls_initplan: Policy uses auth.jwt() without subquery wrap
```

**原因:**
```sql
-- ❌ 問題
USING (auth.jwt() ->> 'tenant_id' = tenant_id)
```

**解決策:**
```sql
-- ✅ 修正
USING ((select auth.jwt()) ->> 'tenant_id' = tenant_id)
```

---

### 8.2 `multiple_permissive_policies` 警告

**症状:**
```
⚠ multiple_permissive_policies: Multiple permissive policies for same role and command
```

**原因:**
```sql
-- ❌ 問題（重複）
CREATE POLICY "policy1" ON table_name FOR SELECT TO authenticated USING (...);
CREATE POLICY "policy2" ON table_name FOR SELECT TO authenticated USING (...);
```

**解決策:**
```sql
-- ✅ 修正（統合または分離）
CREATE POLICY "table_name_select_authenticated" ON table_name
FOR SELECT
TO authenticated
USING (...);
```

---

### 8.3 構文エラー（`FOR INSERT, UPDATE`）

**症状:**
```
ERROR: syntax error at or near ","
```

**原因:**
```sql
-- ❌ PostgreSQL非サポート
FOR INSERT, UPDATE, DELETE
```

**解決策:**
```sql
-- ✅ 個別に定義
CREATE POLICY "..." FOR INSERT ...;
CREATE POLICY "..." FOR UPDATE ...;
CREATE POLICY "..." FOR DELETE ...;
```

---

### 8.4 型変換エラー（`::uuid` / `::text`）

**症状:**
```
ERROR: operator does not exist: text = uuid
```

**原因:**
```sql
-- ❌ 不要な型変換
(select auth.jwt()) ->> 'tenant_id'::uuid = tenant_id
```

**解決策:**
```sql
-- ✅ 型変換不要（両方ともTEXT型）
(select auth.jwt()) ->> 'tenant_id' = tenant_id
```

**理由:**
- `auth.jwt() ->> 'xxx'` は TEXT 型を返す
- schema.prisma の id/tenant_id/user_id はすべて `String` (TEXT型)
- 型変換は不要

---

## 9. 付録

### 9.1 既存マイグレーションファイル

修正済みファイル一覧:

1. **`20251107000001_enable_rls_policies.sql`**
   - メインRLSポリシー（31テーブル）
   - 104ポリシー

2. **`20251107000008_enable_rls_invitations.sql`**
   - 招待機能テーブル

3. **`20251114000001_enable_rls_passkey_credentials.sql`**
   - 認証情報テーブル（廃止予定）

---

### 9.2 参考資料

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- `schema.prisma` (v1.7)
- `harmonet-technical-stack-definition_v4.4.md`
- `Nonfunctional-requirements_v1.0.md`

---

### 9.3 チェックリスト

新規テーブル追加時のチェックリスト:

- [ ] `schema.prisma` にテーブル定義追加
- [ ] `tenant_id` フィールド追加（必須）
- [ ] リレーション定義
- [ ] マイグレーションファイル生成
- [ ] RLSポリシーSQL作成
- [ ] Subquery Wrap 確認（`(select auth.jwt())`）
- [ ] Split Policies 確認（FOR ALL禁止）
- [ ] Naming Convention 確認
- [ ] WITH CHECK 使用ルール確認
- [ ] Linter実行（警告0件）
- [ ] ローカル環境で動作確認
- [ ] 本番環境へデプロイ

---

## 改訂履歴

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| v1.0 | 2025-11-20 | Claude + TKD | 初版作成。Supabase Linter警告対応を含む完全版 |

---

**End of Document**
