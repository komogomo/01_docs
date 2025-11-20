# HarmoNet 新規テーブル追加手順書 v1.0

**Document ID:** HARMONET-NEW-TABLE-GUIDE-V1.0  
**Version:** 1.0  
**Created:** 2025-11-20  
**Author:** Claude (HarmoNet Design Specialist)  
**Reviewer:** TKD (Project Owner)  
**Status:** Phase 9 以降の全テーブル追加に適用  
**対象読者:** Claude, Gemini, Tachikoma, Windsurf, Cursor, TKD

---

## 📋 目次

1. [概要](#1-概要)
2. [事前準備](#2-事前準備)
3. [作業フロー全体像](#3-作業フロー全体像)
4. [詳細手順](#4-詳細手順)
5. [検証チェックリスト](#5-検証チェックリスト)
6. [よくある質問](#6-よくある質問)
7. [トラブルシューティング](#7-トラブルシューティング)
8. [付録](#8-付録)

---

## 1. 概要

### 1.1 目的

本書は、HarmoNetプロジェクトに新規テーブルを追加する際の **完全な手順書** である。
以下を保証する:

- ✅ RLSポリシーの正しい適用（Linter警告ゼロ）
- ✅ マルチテナント分離の完全性
- ✅ Prisma/Supabase/Next.jsの整合性
- ✅ AI開発メンバーによる自動実装時の品質統一

---

### 1.2 前提知識

本手順を実施する前に、以下のドキュメントを必ず読むこと:

- `RLS_Policy_Standard_v1.0.md` - RLSポリシー標準
- `schema.prisma` (v1.7) - データベーススキーマ定義
- `harmonet-technical-stack-definition_v4.4.md` - 技術スタック
- `ai-driven-development-guide_v1.0.md` - AI駆動開発の基本

---

### 1.3 所要時間

| 作業 | 所要時間（目安） |
|------|------------------|
| Step 1-3: スキーマ定義 | 10分 |
| Step 4-6: マイグレーション | 15分 |
| Step 7-9: RLSポリシー | 20分 |
| Step 10-12: 検証 | 15分 |
| **合計** | **約60分** |

※ 初回実施時は追加で30分程度かかる場合があります。

---

## 2. 事前準備

### 2.1 必要なツール

- [ ] Docker Desktop が起動している
- [ ] Supabase ローカル環境が起動している (`npx supabase start`)
- [ ] Node.js 20.x がインストールされている
- [ ] VS Code がインストールされている
- [ ] 必要なnpmパッケージがインストール済み

---

### 2.2 環境変数の確認

`.env` ファイルに以下が設定されていることを確認:

```env
# Supabase Local
DATABASE_URL="postgresql://postgres:postgres@localhost:54322/postgres"
DIRECT_URL="postgresql://postgres:postgres@localhost:54322/postgres"

# Supabase Auth
NEXT_PUBLIC_SUPABASE_URL="http://localhost:54321"
NEXT_PUBLIC_SUPABASE_ANON_KEY="eyJhbGc..."
```

---

### 2.3 作業ディレクトリ

```
D:\Projects\HarmoNet\
```

このディレクトリで作業を行います。

---

## 3. 作業フロー全体像

```
┌─────────────────────────────────────────┐
│ Step 1: 要件整理                          │
│ ・テーブル名決定                           │
│ ・カラム設計                              │
│ ・リレーション設計                         │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 2: schema.prisma 編集                │
│ ・モデル定義追加                           │
│ ・ENUM定義（必要に応じて）                  │
│ ・リレーション定義                         │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 3: マイグレーション生成               │
│ ・npx prisma migrate dev --create-only   │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 4: マイグレーションファイル確認        │
│ ・SQL構文確認                             │
│ ・BOM削除（必要に応じて）                  │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 5: RLSポリシーSQL作成                │
│ ・RLS_Policy_Standard に準拠              │
│ ・Subquery Wrap 適用                     │
│ ・Split Policies 適用                    │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 6: Linter 実行                       │
│ ・npx supabase db lint                   │
│ ・警告ゼロを確認                          │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 7: データベースリセット                │
│ ・npx supabase db reset                  │
│ ・マイグレーション適用確認                 │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 8: Prisma Client 再生成              │
│ ・npx prisma generate                    │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 9: 動作確認                          │
│ ・Prisma Studio で確認                    │
│ ・RLSポリシー動作確認                      │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 10: Seedデータ追加（必要に応じて）     │
│ ・prisma/seed.ts 編集                    │
│ ・npx prisma db seed                     │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 11: 最終検証                         │
│ ・チェックリスト確認                       │
│ ・TKD承認                                │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Step 12: Git コミット                     │
│ ・git add .                              │
│ ・git commit                             │
│ ・git push                               │
└─────────────────────────────────────────┘
```

---

## 4. 詳細手順

### Step 1: 要件整理

#### 1-1: テーブル名決定

**命名規則:**
- 複数形（例: `posts`, `comments`, `reservations`）
- スネークケース（例: `board_posts`, `facility_reservations`）

**例:**
```
新機能: イベント管理
→ テーブル名: events
```

---

#### 1-2: カラム設計

**必須カラム:**
- `id` (UUID, Primary Key)
- `tenant_id` (UUID, Foreign Key to tenants) - マルチテナント分離必須
- `created_at` (DateTime)
- `updated_at` (DateTime)
- `status` (ENUM: active/inactive/archived) - 論理削除用

**任意カラム:**
- `user_id` (UUID) - ユーザー分離が必要な場合
- `XXX_id` (UUID) - 他テーブルへの外部キー
- ビジネスロジック固有のカラム

**例:**
```
events テーブルのカラム:
- id (UUID)
- tenant_id (UUID) ← 必須
- user_id (UUID) - 作成者
- title (String)
- description (Text)
- start_at (DateTime)
- end_at (DateTime)
- location (String, nullable)
- max_participants (Int, nullable)
- created_at (DateTime)
- updated_at (DateTime)
- status (ENUM: active/inactive/archived)
```

---

#### 1-3: リレーション設計

**基本パターン:**
```
events
├── belongs_to: tenants (tenant_id)
├── belongs_to: users (user_id)
└── has_many: event_participants
```

**注意点:**
- 循環参照を避ける
- カスケード削除を適切に設定
- N+1問題を考慮

---

### Step 2: schema.prisma 編集

#### 2-1: ファイルを開く

```
D:\Projects\HarmoNet\prisma\schema.prisma
```

---

#### 2-2: ENUM定義追加（必要に応じて）

**既存ENUMを確認:**
```prisma
// 既存ENUM（再利用推奨）
enum status {
  active
  inactive
  archived
}
```

**新規ENUMが必要な場合:**
```prisma
/// イベント参加ステータス
enum event_participation_status {
  pending
  confirmed
  canceled
}
```

**配置場所:**
```prisma
// ===== Unified Enums (PostgreSQL snake_case standard) =====

/// 共通ステータス
enum status {
  active
  inactive
  archived
}

// ↓ ここに追加 ↓
/// イベント参加ステータス
enum event_participation_status {
  pending
  confirmed
  canceled
}
```

---

#### 2-3: モデル定義追加

**配置場所:**
```prisma
// ===== Models =====

// --- 1. Tenant Management ---
// ...

// --- 10. Events (NEW!) ---

/// イベント情報
model events {
  id              String   @id @default(uuid())
  tenant_id       String
  user_id         String
  title           String
  description     String   @db.Text
  start_at        DateTime
  end_at          DateTime
  location        String?
  max_participants Int?
  created_at      DateTime @default(now())
  updated_at      DateTime @updatedAt
  status          status   @default(active)

  // Relations
  tenant       tenants              @relation(fields: [tenant_id], references: [id])
  user         users                @relation(fields: [user_id], references: [id])
  participants event_participants[]
}

/// イベント参加者
model event_participants {
  id           String                      @id @default(uuid())
  tenant_id    String
  event_id     String
  user_id      String
  status       event_participation_status  @default(pending)
  registered_at DateTime                   @default(now())

  // Relations
  tenant tenants @relation(fields: [tenant_id], references: [id])
  event  events  @relation(fields: [event_id], references: [id], onDelete: Cascade)
  user   users   @relation(fields: [user_id], references: [id])

  @@unique([event_id, user_id])
}
```

---

#### 2-4: 既存モデルにリレーション追加

```prisma
model tenants {
  id          String   @id @default(uuid())
  // ...

  // Relations
  // ... (既存リレーション)
  events               events[] // ← 追加
  event_participants   event_participants[] // ← 追加
}

model users {
  id           String   @id @default(uuid())
  // ...

  // Relations
  // ... (既存リレーション)
  events               events[] // ← 追加
  event_participants   event_participants[] // ← 追加
}
```

---

#### 2-5: schema.prisma 保存

```
Ctrl + S で保存
```

---

### Step 3: マイグレーション生成

#### 3-1: コマンド実行

```powershell
npx prisma migrate dev --name add_events_table --create-only
```

**オプション説明:**
- `--name add_events_table` - マイグレーション名（わかりやすい名前にする）
- `--create-only` - マイグレーションファイルのみ生成（DB適用はしない）

---

#### 3-2: 生成されるファイル

```
prisma/migrations/20251120HHMMSS_add_events_table/migration.sql
```

**ファイル名の構造:**
```
20251120HHMMSS_add_events_table
├── 20251120HHMMSS ← タイムスタンプ
└── add_events_table ← マイグレーション名
```

---

### Step 4: マイグレーションファイル確認

#### 4-1: ファイルを開く

```
prisma/migrations/20251120HHMMSS_add_events_table/migration.sql
```

---

#### 4-2: 内容確認

**期待される内容:**

```sql
-- CreateEnum
CREATE TYPE "event_participation_status" AS ENUM ('pending', 'confirmed', 'canceled');

-- CreateTable
CREATE TABLE "events" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "start_at" TIMESTAMP(3) NOT NULL,
    "end_at" TIMESTAMP(3) NOT NULL,
    "location" TEXT,
    "max_participants" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "status" "status" NOT NULL DEFAULT 'active',

    CONSTRAINT "events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "event_participants" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "event_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "status" "event_participation_status" NOT NULL DEFAULT 'pending',
    "registered_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_participants_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "event_participants_event_id_user_id_key" ON "event_participants"("event_id", "user_id");

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_participants" ADD CONSTRAINT "event_participants_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_participants" ADD CONSTRAINT "event_participants_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_participants" ADD CONSTRAINT "event_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
```

---

#### 4-3: BOM削除（必要に応じて）

**確認方法:**
```powershell
# PowerShellでBOMをチェック
$bytes = [System.IO.File]::ReadAllBytes("prisma/migrations/20251120HHMMSS_add_events_table/migration.sql")
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "⚠ BOM detected!"
} else {
    Write-Host "✅ No BOM"
}
```

**BOMが検出された場合:**
1. VS Code でファイルを開く
2. 右下の「UTF-8」をクリック
3. 「エンコード付きで保存」→「UTF-8」を選択
4. 保存

---

### Step 5: RLSポリシーSQL作成

#### 5-1: 新規ファイル作成

```
supabase/migrations/20251120HHMMSS_enable_rls_events.sql
```

**ファイル名の構造:**
```
20251120HHMMSS_enable_rls_events
├── 20251120HHMMSS ← 同じタイムスタンプ（または +1秒）
└── enable_rls_events ← RLSポリシー適用を示す
```

---

#### 5-2: RLSポリシーSQL記述

**`RLS_Policy_Standard_v1.0.md` のテンプレートを使用:**

```sql
-- ============================================
-- RLS Policies for events
-- ============================================

-- Enable RLS
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- SELECT Policy
CREATE POLICY "events_select_authenticated"
ON events
FOR SELECT
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- INSERT Policy
CREATE POLICY "events_insert_authenticated"
ON events
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- UPDATE Policy
CREATE POLICY "events_update_authenticated"
ON events
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
CREATE POLICY "events_delete_authenticated"
ON events
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- ============================================
-- RLS Policies for event_participants
-- ============================================

-- Enable RLS
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- SELECT Policy
CREATE POLICY "event_participants_select_authenticated"
ON event_participants
FOR SELECT
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
);

-- INSERT Policy
CREATE POLICY "event_participants_insert_authenticated"
ON event_participants
FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);

-- UPDATE Policy
CREATE POLICY "event_participants_update_authenticated"
ON event_participants
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
CREATE POLICY "event_participants_delete_authenticated"
ON event_participants
FOR DELETE
TO authenticated
USING (
  (select auth.jwt()) ->> 'tenant_id' = tenant_id
  AND
  (select auth.uid()) = user_id
);
```

---

#### 5-3: 重要ポイント確認

**✅ Subquery Wrap:**
```sql
(select auth.jwt()) ->> 'tenant_id'  // ← 必ずサブクエリで囲む
```

**✅ Split Policies:**
```sql
CREATE POLICY "..." FOR SELECT ...;
CREATE POLICY "..." FOR INSERT ...;
CREATE POLICY "..." FOR UPDATE ...;
CREATE POLICY "..." FOR DELETE ...;
```

**✅ WITH CHECK:**
```sql
FOR SELECT → USING のみ
FOR INSERT → WITH CHECK のみ
FOR UPDATE → USING + WITH CHECK 両方
FOR DELETE → USING のみ
```

---

### Step 6: Linter 実行

#### 6-1: コマンド実行

```powershell
npx supabase db lint
```

---

#### 6-2: 期待される結果

```
✅ No issues found
```

---

#### 6-3: 警告が出た場合

**`auth_rls_initplan` 警告:**
```
⚠ auth_rls_initplan: Policy uses auth.jwt() without subquery wrap
```

**対応:**
```sql
-- ❌ 修正前
USING (auth.jwt() ->> 'tenant_id' = tenant_id)

-- ✅ 修正後
USING ((select auth.jwt()) ->> 'tenant_id' = tenant_id)
```

---

**`multiple_permissive_policies` 警告:**
```
⚠ multiple_permissive_policies: Multiple permissive policies for same role and command
```

**対応:**
- 重複しているポリシーを削除または統合

---

### Step 7: データベースリセット

#### 7-1: コマンド実行

```powershell
npx supabase db reset
```

---

#### 7-2: 期待される結果

```
Applying migration 20251107000000_initial_schema.sql...
Applying migration 20251107000001_enable_rls_policies.sql...
...
Applying migration 20251120HHMMSS_add_events_table.sql...
Applying migration 20251120HHMMSS_enable_rls_events.sql...
✅ Finished supabase db reset on branch main.
```

---

#### 7-3: エラーが発生した場合

**構文エラー:**
```
ERROR: syntax error at or near "..."
```

**対応:**
- マイグレーションファイルのSQL構文を確認
- `RLS_Policy_Standard_v1.0.md` のテンプレートと照合

---

**型変換エラー:**
```
ERROR: operator does not exist: text = uuid
```

**対応:**
```sql
-- ❌ 不要な型変換を削除
(select auth.jwt()) ->> 'tenant_id'::uuid

-- ✅ 型変換不要
(select auth.jwt()) ->> 'tenant_id'
```

---

### Step 8: Prisma Client 再生成

#### 8-1: コマンド実行

```powershell
npx prisma generate
```

---

#### 8-2: 期待される結果

```
✔ Generated Prisma Client (v6.19.0) to .\node_modules\@prisma\client
```

---

### Step 9: 動作確認

#### 9-1: Prisma Studio 起動

```powershell
npx prisma studio
```

---

#### 9-2: ブラウザで確認

```
http://localhost:5555
```

---

#### 9-3: 確認項目

**✅ テーブルが表示される:**
- `events`
- `event_participants`

**✅ カラムが正しい:**
- `id`, `tenant_id`, `user_id`, `title`, `description`, ...

**✅ リレーションが正しい:**
- `events` → `tenants`
- `events` → `users`
- `event_participants` → `events`

---

#### 9-4: データ挿入テスト

**手順:**
1. `events` テーブルを開く
2. 「Add record」をクリック
3. 以下のデータを入力:
   ```
   tenant_id: （既存テナントのID）
   user_id: （既存ユーザーのID）
   title: "テストイベント"
   description: "これはテストです"
   start_at: 2025-12-01T10:00:00.000Z
   end_at: 2025-12-01T12:00:00.000Z
   ```
4. 「Save」をクリック

**期待される結果:**
- ✅ データが正常に保存される
- ✅ `id` が自動生成される
- ✅ `created_at` / `updated_at` が自動設定される

---

#### 9-5: RLSポリシー動作確認

**確認方法:**

```sql
-- Supabase SQL Editor で実行

-- テナントAのユーザーとしてログイン（JWT設定）
SET request.jwt.claims = '{"tenant_id": "tenant-a-uuid", "sub": "user-a-uuid"}';

-- SELECT: テナントAのイベントのみ取得できる
SELECT * FROM events;

-- INSERT: テナントAのイベントのみ挿入できる
INSERT INTO events (id, tenant_id, user_id, title, description, start_at, end_at)
VALUES (gen_random_uuid(), 'tenant-a-uuid', 'user-a-uuid', 'Test', 'Test', now(), now() + interval '1 hour');

-- テナントBのイベントは取得できない（0件）
SET request.jwt.claims = '{"tenant_id": "tenant-b-uuid", "sub": "user-b-uuid"}';
SELECT * FROM events;
```

**期待される結果:**
- ✅ テナントAのユーザーは、テナントAのデータのみアクセス可能
- ✅ テナントBのユーザーは、テナントBのデータのみアクセス可能
- ✅ テナント間のデータは完全に分離されている

---

### Step 10: Seedデータ追加（必要に応じて）

#### 10-1: prisma/seed.ts を開く

```
D:\Projects\HarmoNet\prisma\seed.ts
```

---

#### 10-2: Seedデータ追加

```typescript
// ===== Events =====
console.log('Creating events...');

const event1 = await prisma.events.create({
  data: {
    tenant_id: demoTenant.id,
    user_id: adminUser.id,
    title: '【重要】定期総会のお知らせ',
    description: '2025年12月15日（日）10:00より、集会室にて定期総会を開催いたします。',
    start_at: new Date('2025-12-15T10:00:00Z'),
    end_at: new Date('2025-12-15T12:00:00Z'),
    location: '集会室',
    max_participants: 50,
    status: 'active',
  },
});

const event2 = await prisma.events.create({
  data: {
    tenant_id: demoTenant.id,
    user_id: adminUser.id,
    title: '防災訓練のご案内',
    description: '2025年11月30日（土）9:00より、防災訓練を実施します。',
    start_at: new Date('2025-11-30T09:00:00Z'),
    end_at: new Date('2025-11-30T11:00:00Z'),
    location: '駐車場',
    max_participants: 100,
    status: 'active',
  },
});

console.log('✅ Events created:', event1.title, event2.title);
```

---

#### 10-3: Seed実行

```powershell
npx prisma db seed
```

---

#### 10-4: 期待される結果

```
Creating events...
✅ Events created: 【重要】定期総会のお知らせ 防災訓練のご案内
```

---

### Step 11: 最終検証

#### 11-1: チェックリスト実行

**[5. 検証チェックリスト](#5-検証チェックリスト)** を参照し、全項目をチェックする。

---

#### 11-2: TKD承認

- TKD様に以下を報告:
  1. 追加したテーブル名
  2. カラム構成
  3. RLSポリシー適用状況
  4. Linter結果（警告0件）
  5. 動作確認結果

- TKD様の承認を得る

---

### Step 12: Git コミット

#### 12-1: 変更ファイル確認

```powershell
git status
```

**期待される結果:**
```
modified:   prisma/schema.prisma
new file:   prisma/migrations/20251120HHMMSS_add_events_table/migration.sql
new file:   supabase/migrations/20251120HHMMSS_enable_rls_events.sql
modified:   prisma/seed.ts (必要に応じて)
```

---

#### 12-2: コミット

```powershell
git add .
git commit -m "feat: add events and event_participants tables with RLS policies

- Add events table with tenant isolation
- Add event_participants table
- Add RLS policies following RLS_Policy_Standard_v1.0
- Linter warnings: 0
- All tests passed"
```

---

#### 12-3: プッシュ

```powershell
git push origin main
```

---

## 5. 検証チェックリスト

新規テーブル追加時の最終確認チェックリスト:

### 5.1 スキーマ定義

- [ ] `schema.prisma` にモデル定義を追加した
- [ ] `tenant_id` フィールドを追加した（必須）
- [ ] `user_id` フィールドを追加した（必要に応じて）
- [ ] `created_at` / `updated_at` フィールドを追加した
- [ ] `status` フィールドを追加した（論理削除用）
- [ ] リレーションを正しく定義した
- [ ] ENUM型を定義した（必要に応じて）
- [ ] 既存モデルにリレーションを追加した

---

### 5.2 マイグレーション

- [ ] `npx prisma migrate dev --create-only` を実行した
- [ ] マイグレーションファイルが生成された
- [ ] SQL構文を確認した
- [ ] BOMを削除した（必要に応じて）
- [ ] 外部キー制約が正しい

---

### 5.3 RLSポリシー

- [ ] RLSポリシーSQLファイルを作成した
- [ ] Subquery Wrap を適用した（`(select auth.jwt())`）
- [ ] Split Policies を適用した（FOR ALL禁止）
- [ ] Naming Convention に準拠した
- [ ] WITH CHECK 使用ルールに準拠した
- [ ] `npx supabase db lint` で警告0件を確認した

---

### 5.4 データベース

- [ ] `npx supabase db reset` を実行した
- [ ] マイグレーションが正常に適用された
- [ ] エラーが発生していない
- [ ] `npx prisma generate` を実行した
- [ ] Prisma Client が再生成された

---

### 5.5 動作確認

- [ ] Prisma Studio でテーブルが表示される
- [ ] カラムが正しい
- [ ] リレーションが正しい
- [ ] データ挿入テストが成功した
- [ ] RLSポリシーが正しく動作している
- [ ] テナント分離が機能している

---

### 5.6 Seedデータ（必要に応じて）

- [ ] `prisma/seed.ts` にSeedデータを追加した
- [ ] `npx prisma db seed` を実行した
- [ ] Seedデータが正常に投入された

---

### 5.7 最終確認

- [ ] TKD様の承認を得た
- [ ] Git コミットを実施した
- [ ] Git プッシュを実施した
- [ ] ドキュメントを更新した（必要に応じて）

---

## 6. よくある質問

### Q1: テーブル名は単数形・複数形どちらですか？

**A:** 複数形を使用します。

例:
- ✅ `events`
- ✅ `event_participants`
- ❌ `event`
- ❌ `event_participant`

---

### Q2: `tenant_id` は必須ですか？

**A:** はい、必須です。

HarmoNetは完全マルチテナント設計のため、すべての業務テーブルに `tenant_id` が必要です。

例外:
- `roles` (ロールマスタ - 全テナント共通)
- `permissions` (権限マスタ - 全テナント共通)

---

### Q3: `user_id` はいつ必要ですか？

**A:** ユーザー分離が必要な場合に追加します。

例:
- ✅ 掲示板投稿 (`board_posts`) - 作成者を記録
- ✅ 予約 (`facility_reservations`) - 予約者を記録
- ❌ カテゴリマスタ - ユーザーと無関係

---

### Q4: RLSポリシーの `USING` と `WITH CHECK` の違いは？

**A:**

| 句 | 用途 | タイミング |
|----|------|-----------|
| `USING` | 読み取り権限 | SELECT/UPDATE/DELETE時 |
| `WITH CHECK` | 書き込み権限 | INSERT/UPDATE時 |

例:
```sql
-- SELECT: 読み取りのみ
FOR SELECT USING (...)

-- INSERT: 書き込みのみ
FOR INSERT WITH CHECK (...)

-- UPDATE: 読み取り + 書き込み
FOR UPDATE USING (...) WITH CHECK (...)

-- DELETE: 読み取りのみ
FOR DELETE USING (...)
```

---

### Q5: マイグレーションファイルのタイムスタンプはどう決めますか？

**A:** Prismaが自動生成します。

手動で変更する必要はありません。

---

### Q6: BOMとは何ですか？

**A:** Byte Order Mark の略。UTF-8ファイルの先頭に付与される特殊文字。

SupabaseはBOM付きUTF-8を正しく処理できないため、BOMを削除する必要があります。

---

### Q7: Linterで警告が出た場合はどうすればいいですか？

**A:** [7. トラブルシューティング](#7-トラブルシューティング) を参照してください。

---

### Q8: Seedデータは必須ですか？

**A:** いいえ、任意です。

ただし、以下の場合は推奨:
- デモ環境構築
- 開発時の動作確認
- テストデータ準備

---

## 7. トラブルシューティング

### 問題1: `auth_rls_initplan` 警告

**症状:**
```
⚠ auth_rls_initplan: Policy uses auth.jwt() without subquery wrap
```

**原因:**
```sql
-- ❌ Subquery Wrap なし
USING (auth.jwt() ->> 'tenant_id' = tenant_id)
```

**解決策:**
```sql
-- ✅ Subquery Wrap あり
USING ((select auth.jwt()) ->> 'tenant_id' = tenant_id)
```

---

### 問題2: `multiple_permissive_policies` 警告

**症状:**
```
⚠ multiple_permissive_policies: Multiple permissive policies for same role and command
```

**原因:**
```sql
-- ❌ 重複ポリシー
CREATE POLICY "policy1" ON events FOR SELECT TO authenticated USING (...);
CREATE POLICY "policy2" ON events FOR SELECT TO authenticated USING (...);
```

**解決策:**
```sql
-- ✅ 統合または削除
CREATE POLICY "events_select_authenticated" ON events
FOR SELECT
TO authenticated
USING (...);
```

---

### 問題3: 構文エラー（`FOR INSERT, UPDATE`）

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

### 問題4: 型変換エラー

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
-- ✅ 型変換不要
(select auth.jwt()) ->> 'tenant_id' = tenant_id
```

---

### 問題5: マイグレーションエラー

**症状:**
```
ERROR: relation "events" already exists
```

**原因:**
- マイグレーションが既に適用されている
- データベースが不整合状態

**解決策:**
```powershell
# データベースをリセット
npx supabase db reset

# 再度適用
npx supabase start
```

---

### 問題6: Prisma Client 生成エラー

**症状:**
```
Error: Schema parsing failed
```

**原因:**
- `schema.prisma` の構文エラー
- ENUM定義の誤り

**解決策:**
```powershell
# schema.prisma を確認
npx prisma validate

# エラー箇所を修正
```

---

## 8. 付録

### 8.1 参考ドキュメント

- `RLS_Policy_Standard_v1.0.md` - RLSポリシー標準
- `schema.prisma` (v1.7) - データベーススキーマ定義
- `harmonet-technical-stack-definition_v4.4.md` - 技術スタック
- `ai-driven-development-guide_v1.0.md` - AI駆動開発ガイド
- `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` - Phase 9 DB構築報告書

---

### 8.2 コマンド一覧

```powershell
# マイグレーション生成
npx prisma migrate dev --name add_events_table --create-only

# Linter実行
npx supabase db lint

# データベースリセット
npx supabase db reset

# Prisma Client再生成
npx prisma generate

# Prisma Studio起動
npx prisma studio

# Seed実行
npx prisma db seed

# Git操作
git status
git add .
git commit -m "feat: add events table"
git push origin main
```

---

### 8.3 ディレクトリ構造

```
D:\Projects\HarmoNet\
├── prisma/
│   ├── schema.prisma           # Prismaスキーマ定義
│   ├── seed.ts                 # Seedデータ
│   └── migrations/             # Prismaマイグレーション（参考用）
├── supabase/
│   ├── config.toml             # Supabase設定
│   └── migrations/
│       ├── 20251107000000_initial_schema.sql
│       ├── 20251107000001_enable_rls_policies.sql
│       └── 20251120HHMMSS_add_events_table.sql ← 新規追加
│       └── 20251120HHMMSS_enable_rls_events.sql ← 新規追加
├── app/                        # Next.js App Router
├── node_modules/
├── .env
├── package.json
└── tsconfig.json
```

---

### 8.4 テンプレートファイル

#### schema.prisma テンプレート

```prisma
/// テーブル説明
model table_name {
  id         String   @id @default(uuid())
  tenant_id  String   // 必須
  user_id    String   // 必要に応じて
  // ビジネスロジック固有のカラム
  created_at DateTime @default(now())
  updated_at DateTime @updatedAt
  status     status   @default(active)

  // Relations
  tenant tenants @relation(fields: [tenant_id], references: [id])
  user   users   @relation(fields: [user_id], references: [id])
}
```

#### RLSポリシーテンプレート

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
  AND
  (select auth.uid()) = user_id
);

-- UPDATE Policy
CREATE POLICY "{table_name}_update_authenticated"
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

-- DELETE Policy
CREATE POLICY "{table_name}_delete_authenticated"
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

## 改訂履歴

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| v1.0 | 2025-11-20 | Claude | 初版作成。RLS_Policy_Standard準拠の完全版手順書 |

---

**End of Document**
