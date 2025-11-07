# HarmoNet Phase 9 データベース構築作業報告書

**プロジェクト名**: HarmoNet（マルチテナント型コミュニティOS）  
**作業フェーズ**: Phase 9.7 - 認証拡張（Invitations統合）  
**作業日**: 2025年11月7日  
**作業者**: Claude (AI Development Assistant) + TKD (Project Owner)  
**監督**: Tachikoma (PMO / Architect)  
**ドキュメントバージョン**: v1.1

---

## 📋 目次

1. [作業概要](#作業概要)
2. [作業範囲](#作業範囲)
3. [実施内容](#実施内容)
4. [成果物](#成果物)
5. [データベース構成](#データベース構成)
6. [発生した問題と対応](#発生した問題と対応)
7. [次のステップ](#次のステップ)
8. [付録](#付録)
9. [変更履歴](#変更履歴)

---

## 1. 作業概要

### 1.1 目的

Phase 9.7の認証拡張対応として、テナント管理者によるユーザー招待制登録を可能にする  
`invitations` テーブルを導入する。これにより Magic Link／Passkey 認証に加え、  
招待コードによる安全なユーザーオンボーディングを実現する。

### 1.2 背景

- Phase 9.6で基本スキーマ（31テーブル）構築完了
- セキュリティ強化のため招待コードベースの登録機能を追加
- ハッシュ化による平文コード保存の回避
- テナント境界を保証するRLSポリシー適用

### 1.3 作業環境

| 項目 | 詳細 |
|------|------|
| OS | Windows 11 |
| プロジェクトパス | `D:\Projects\HarmoNet` |
| Node.js | LTS v20.x |
| Prisma | 6.19.0 |
| Supabase CLI | 2.54.11 |
| Docker Desktop | 最新版（Supabaseコンテナ実行用） |
| PostgreSQL | 15.6 (Supabase Docker) |

---

## 2. 作業範囲

### 2.1 対象範囲

✅ **実施対象**
- `invitations` テーブルの追加
- `invitation_status` ENUMの追加
- Prisma schema.prisma更新
- RLSポリシー追加（3ポリシー）
- マイグレーションファイル生成
- データベース構造検証

❌ **対象外**
- 招待API実装（アプリケーション層）
- フロントエンド実装
- ハッシュ化ロジック実装

### 2.2 前提条件

- Phase 9.6環境が正常稼働中
- Docker Desktopが起動している
- Supabaseローカル環境が稼働中
- Prisma schema.prisma v1.7が存在

---

## 3. 実施内容

### 3.1 作業フロー

```
STEP 0-1: schema.prisma更新
  ├─ invitation_status ENUM追加
  ├─ invitationsモデル追加
  ├─ usersモデル リレーション追加
  └─ tenantsモデル リレーション追加

STEP 0-2: マイグレーションSQL作成
  ├─ 20251107000006_add_invitation_status_enum.sql
  ├─ 20251107000007_create_invitations_table.sql
  └─ 20251107000008_enable_rls_invitations.sql

STEP 0-3: 適用と検証
  ├─ Prisma Generate実行
  ├─ マイグレーション適用（supabase migration up）
  └─ Supabase Studioでの動作確認
```

### 3.2 詳細手順

#### STEP 0-1: schema.prisma更新

**実施内容:**
1. `invitation_status` ENUMを追加（17行目付近）
2. `invitations` モデルを追加（629行目・ファイル末尾）
3. `users` モデルに `invitations_sent` リレーション追加
4. `tenants` モデルに `invitations` リレーション追加

**追加ENUM:**
```prisma
enum invitation_status {
  pending
  accepted
  expired
  revoked
}
```

**追加モデル:**
```prisma
model invitations {
  id                   String             @id @default(uuid())
  tenant_id            String
  email                String
  invitation_code_hash String
  role                 role_scope         @default(general_user)
  expires_at           DateTime
  used_at              DateTime?
  status               invitation_status  @default(pending)
  invited_by_user_id   String
  created_at           DateTime           @default(now())
  updated_at           DateTime           @updatedAt

  tenant  tenants @relation(fields: [tenant_id], references: [id])
  inviter users   @relation("invitations_inviter", fields: [invited_by_user_id], references: [id])

  @@unique([tenant_id, email])
  @@index([email])
  @@index([expires_at])
}
```

#### STEP 0-2: マイグレーションファイル生成

**生成ファイル:**

1. **20251107000006_add_invitation_status_enum.sql**
   - `invitation_status` ENUM定義

2. **20251107000007_create_invitations_table.sql**
   - `invitations` テーブル作成
   - UNIQUE制約: `(tenant_id, email)`
   - インデックス: `email`, `expires_at`

3. **20251107000008_enable_rls_invitations.sql**
   - RLS有効化
   - SELECT / INSERT / UPDATE ポリシー追加

**重要な修正箇所:**
- `role` 列の型を `text` から `role_scope` に修正（既存ENUMとの整合性）

#### STEP 0-3: Prisma Generate実行

**コマンド:**
```powershell
cd D:\Projects\HarmoNet
npx prisma generate
```

**結果:**
- ✅ Prisma Client生成成功

#### STEP 0-4: マイグレーション適用

**コマンド:**
```powershell
supabase migration up
```

**結果:**
```
Connecting to local database...
Applying migration 20251107000006_add_invitation_status_enum.sql...
Applying migration 20251107000007_create_invitations_table.sql...
Applying migration 20251107000008_enable_rls_invitations.sql...
Local database is up to date.
```

- ✅ 3つのマイグレーション適用成功

#### STEP 0-5: Supabase Studioでの確認

**確認項目:**
1. ✅ `invitations` テーブル存在確認（11カラム）
2. ✅ `invitation_status` ENUM確認
3. ✅ RLSポリシー確認（3ポリシー）

---

## 4. 成果物

### 4.1 生成ファイル一覧

| ファイルパス | 説明 |
|-------------|------|
| `prisma/schema.prisma` | Prismaスキーマ定義（v1.8 - invitations追加） |
| `supabase/migrations/20251107000006_add_invitation_status_enum.sql` | ENUM追加マイグレーション |
| `supabase/migrations/20251107000007_create_invitations_table.sql` | テーブル作成マイグレーション |
| `supabase/migrations/20251107000008_enable_rls_invitations.sql` | RLSポリシー設定 |
| `node_modules/@prisma/client/` | Prisma Client（再生成済み） |

---

## 5. データベース構成

### 5.1 テーブル一覧（30テーブル → 30テーブル）

**Phase 9.6からの変更:**
- テーブル数: 29 → **30** (+1: invitations)

#### 招待管理（1テーブル）**NEW**
32. `invitations` - 招待管理

*その他のテーブル構成はv1.0と同様（1〜31番）*

### 5.2 ENUM型定義（11種類 → 12種類）

**Phase 9.6からの変更:**
- ENUM数: 11 → **12** (+1: invitation_status)

| ENUM名 | 値 | 用途 |
|--------|---|------|
| **`invitation_status`** | **pending, accepted, expired, revoked** | **招待ステータス（NEW）** |

*その他のENUM定義はv1.0と同様*

### 5.3 RLSポリシー

**Phase 9.6からの変更:**
- ポリシー数: 104 → **107** (+3)

**新規追加ポリシー:**
1. `invitations_select` - SELECT権限（同一テナントのみ）
2. `invitations_insert` - INSERT権限（同一テナントのみ）
3. `invitations_update` - UPDATE権限（同一テナントのみ）

**適用ルール:**
```sql
tenant_id::text = (auth.jwt() ->> 'tenant_id')
```

### 5.4 invitationsテーブル詳細

| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | text | PRIMARY KEY | UUID |
| tenant_id | text | NOT NULL | テナントID |
| email | text | NOT NULL | 招待先メールアドレス |
| invitation_code_hash | text | NOT NULL | ハッシュ化された招待コード |
| role | role_scope | NOT NULL, DEFAULT 'general_user' | 付与ロール |
| expires_at | timestamptz | NOT NULL | 有効期限 |
| used_at | timestamptz | NULL | 使用日時 |
| status | invitation_status | NOT NULL, DEFAULT 'pending' | ステータス |
| invited_by_user_id | text | NOT NULL | 招待者ID |
| created_at | timestamptz | NOT NULL, DEFAULT now() | 作成日時 |
| updated_at | timestamptz | NOT NULL, DEFAULT now() | 更新日時 |

**インデックス:**
- UNIQUE: `(tenant_id, email)` - 同一テナント・同一メールへの多重招待防止
- INDEX: `email` - メールアドレス検索
- INDEX: `expires_at` - 期限切れチェック

---

## 6. 発生した問題と対応

### 問題1: role列の型不整合

**発生タイミング**: マイグレーションSQL作成時

**問題内容:**
- タチコマ案では `role text` と定義
- 既存schema.prismaでは `role_scope` ENUMを使用

**対応:**
- マイグレーションSQL内の `role` 列を `role_scope` 型に修正

**教訓:**
- 既存スキーマとの整合性を最優先
- 作業指示書の内容も現行構成に合わせて修正が必要

---

## 7. 次のステップ

### 7.1 Phase 9.7 実装フェーズ（今後の作業）

#### 優先度: 高
1. **招待API実装**
   - 招待コード発行API
   - 招待コード検証API
   - ハッシュ化ロジック実装

2. **監査連携**
   - `audit_auth_events` への記録
   - invitation_issued / invitation_accepted イベント

3. **期限管理**
   - 期限切れ招待の自動処理
   - バッチ処理またはクエリ時判定

#### 優先度: 中
4. **管理UI実装**
   - 招待一覧画面
   - 招待再送機能
   - 招待失効機能

---

## 8. 付録

### 8.1 使用したコマンド一覧

```powershell
# Prisma Client生成
cd D:\Projects\HarmoNet
npx prisma generate

# マイグレーション適用
supabase migration up

# データベース構造確認
# Supabase Studio: http://localhost:54323
```

### 8.2 ディレクトリ構造

```
D:\Projects\HarmoNet\
├── prisma/
│   └── schema.prisma           # v1.8（invitations追加）
├── supabase/
│   └── migrations/
│       ├── 20251107000000_initial_schema.sql
│       ├── 20251107000001_enable_rls_policies.sql
│       ├── 20251107000006_add_invitation_status_enum.sql    # NEW
│       ├── 20251107000007_create_invitations_table.sql      # NEW
│       └── 20251107000008_enable_rls_invitations.sql        # NEW
└── node_modules/@prisma/client/
```

### 8.3 参考資料

- [HarmoNet Technical Stack Definition v3.6](プロジェクトナレッジ参照)
- [Claude Work Instructions Phase9.7 v1.0.2](作業指示書)
- [HarmoNet Phase9 DB Construction Report v1.0](前版報告書)

---

## 9. 変更履歴

| Version | Date | Author | Summary |
|---------|------|---------|----------|
| v1.0 | 2025-11-06 | Claude + TKD | Phase 9初期構築（31テーブル・104ポリシー） |
| **v1.1** | **2025-11-07** | **Claude + TKD** | **invitationsテーブル追加（+1テーブル・+3ポリシー・+1ENUM）** |

---

## 作業完了確認

✅ **Phase 9.7 認証拡張（Invitations統合）完了**

| 項目 | 状態 |
|------|------|
| Prisma schema.prisma | ✅ 更新完了（v1.8） |
| invitation_status ENUM | ✅ 追加完了 |
| invitationsテーブル | ✅ 作成完了 |
| マイグレーションファイル | ✅ 3ファイル生成・適用完了 |
| RLSポリシー | ✅ 3ポリシー追加（計107ポリシー） |
| Prisma Client | ✅ 再生成完了 |
| データベース構造 | ✅ 検証完了（Supabase Studio確認済み） |

---

**報告書作成日**: 2025年11月7日  
**最終更新**: 2025年11月7日  
**承認者**: TKD (Project Owner)  
**監督**: Tachikoma (PMO / Architect)  
**文書管理番号**: HNM-REPORT-PHASE9-DB-002

---

**End of Document**
