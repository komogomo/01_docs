# HarmoNet データベーステーブル定義書

**Phase**: 5  
**Version**: 1.0  
**Document ID**: HNM-DB-DEF-20251104  
**Created**: 2025-11-04  
**Last Updated**: 2025-11-04  
**Author**: Claude (HarmoNet Design Specialist)  
**Status**: Phase5 完了成果物

---

## 📘 概要

本書は、HarmoNetのデータベーススキーマを定義した正式なテーブル定義書である。

### 使用技術
- **Database**: Supabase (PostgreSQL 15.x)
- **ORM**: Prisma ORM 5.x
- **Architecture**: Multi-Tenant with Row-Level Security (RLS)

### 生成元
- **ER定義**: `03_harmonet-er-entity-definition_v1.2.yaml`
- **Prismaスキーマ**: `04_harmonet-prisma-schema_v1.0.prisma`

---

## 🏗️ 共通方針

### Multi-Tenant設計
- 全テーブルに`tenant_id`カラムを配置
- Row-Level Security (RLS)によるテナント分離
- JWTトークンの`tenant_id`クレームに基づくアクセス制御

### データ型と制約
- **UUID**: 主キーおよび外部キーに使用(`gen_random_uuid()`でデフォルト生成)
- **Timestamp**: `created_at`, `updated_at`は`@default(now())`
- **updated_at**: アプリケーション層で更新制御
- **Enum**: Prisma簡略化方針に準拠(Status, ReactionType, DecisionType等)
- **JSON**: 柔軟な設定保持のため活用(nullable許容)

### RLS適用
全テーブルに対してRLSポリシーを設定し、`tenant_id`に基づくデータ分離を実現する。

```sql
-- RLSポリシー例
CREATE POLICY tenant_isolation_policy
ON public.{table_name}
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

---

## 📊 ENUM定義

### Status
```sql
CREATE TYPE "Status" AS ENUM ('active', 'inactive', 'archived');
```
- **用途**: レコードの有効状態管理
- **適用テーブル**: tenants, users, tenant_features, board_categories, facility_slots等

### ReactionType
```sql
CREATE TYPE "ReactionType" AS ENUM ('like', 'report', 'bookmark');
```
- **用途**: 掲示板投稿へのリアクション種別
- **適用テーブル**: board_reactions

### ApprovalAction
```sql
CREATE TYPE "ApprovalAction" AS ENUM ('approve', 'reconsider');
```
- **用途**: 承認フロー操作種別
- **適用テーブル**: board_approval_logs

### FacilityFeeUnit
```sql
CREATE TYPE "FacilityFeeUnit" AS ENUM ('day', 'hour');
```
- **用途**: 施設利用料金の単位
- **適用テーブル**: facility_settings

### DecisionType
```sql
CREATE TYPE "DecisionType" AS ENUM ('allow', 'mask', 'block');
```
- **用途**: AIモデレーション判定結果
- **適用テーブル**: moderation_logs

### DecisionSource
```sql
CREATE TYPE "DecisionSource" AS ENUM ('system', 'human');
```
- **用途**: モデレーション判定実施者
- **適用テーブル**: moderation_logs

---

## 🗂️ テーブル定義一覧

---

## 1. Tenant Management (テナント管理)

### 1.1 tenants

**論理名**: テナントマスタ  
**用途**: 管理組合・管理会社などのテナント基本情報を管理

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_code | text | ✔ | - | テナントコード(一意) |
| tenant_name | text | ✔ | - | テナント名称 |
| timezone | text | - | - | タイムゾーン(例: Asia/Tokyo) |
| is_active | boolean | ✔ | true | 有効フラグ |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (tenant_code)

**備考**:
- RLS有効化対象
- 全テーブルの親エンティティ

---

### 1.2 tenant_settings

**論理名**: テナント設定  
**用途**: テナント固有の設定情報をJSON形式で保持

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| config_json | json | - | - | 設定情報(JSON) |
| default_language | text | ✔ | 'ja' | デフォルト言語 |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- tenants 1:N tenant_settings

---

### 1.3 tenant_features

**論理名**: テナント機能フラグ  
**用途**: テナント単位での機能ON/OFF制御

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| feature_key | text | ✔ | - | 機能キー(例: bbs, parking) |
| enabled | boolean | ✔ | true | 有効フラグ |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- tenants 1:N tenant_features

---

## 2. Users / Auth (ユーザー・認証)

### 2.1 users

**論理名**: ユーザーマスタ  
**用途**: システム利用者の基本情報

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | - | - | 所属テナントID(FK) |
| email | text | ✔ | - | メールアドレス(一意) |
| display_name | text | ✔ | - | 表示名 |
| language | text | ✔ | 'ja' | 表示言語(ja/en/zh) |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (email)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**備考**:
- Supabase Auth連携
- Magic Link認証を使用

**リレーション**:
- tenants 1:N users
- users 1:1 user_profiles
- users 1:N user_roles

---

### 2.2 user_tenants

**論理名**: ユーザー・テナント紐付け  
**用途**: ユーザーとテナントのN:M関係を管理

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| user_id | uuid | ✔ | - | ユーザーID(PK, FK) |
| tenant_id | uuid | ✔ | - | テナントID(PK, FK) |
| joined_at | timestamp | ✔ | now() | 参加日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (user_id, tenant_id)
- FOREIGN KEY (user_id) REFERENCES users(id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- users N:M tenants (中間テーブル)

---

### 2.3 user_roles

**論理名**: ユーザーロール割当  
**用途**: ユーザーへのロール割当を管理

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| user_id | uuid | ✔ | - | ユーザーID(FK) |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| role_id | uuid | ✔ | - | ロールID(FK) |
| assigned_at | timestamp | ✔ | now() | 割当日時 |

**制約**:
- UNIQUE (user_id, tenant_id, role_id)
- FOREIGN KEY (user_id) REFERENCES users(id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (role_id) REFERENCES roles(id)

**リレーション**:
- users 1:N user_roles
- roles 1:N user_roles

---

### 2.4 user_profiles

**論理名**: ユーザープロフィール  
**用途**: ユーザーの拡張情報・個人設定

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| user_id | uuid | ✔ | - | ユーザーID(PK, FK) |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| preferences | json | - | - | ユーザー設定(JSON) |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (user_id)
- FOREIGN KEY (user_id) REFERENCES users(id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- users 1:1 user_profiles

---

## 3. Roles / Permissions (ロール・権限)

### 3.1 roles

**論理名**: ロールマスタ  
**用途**: システム内のロール定義

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| role_key | text | ✔ | - | ロールキー(一意) |
| name | text | ✔ | - | ロール名 |
| scope | text | ✔ | 'tenant' | スコープ(global/tenant) |
| permissions_ref | text | - | - | 権限参照 |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (role_key)

**備考**:
- 3階層ロール: system_admin, tenant_admin, general_user

---

### 3.2 role_inheritances

**論理名**: ロール継承  
**用途**: ロール間の継承関係を定義

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| parent_role_id | uuid | ✔ | - | 親ロールID(PK, FK) |
| child_role_id | uuid | ✔ | - | 子ロールID(PK, FK) |

**制約**:
- PRIMARY KEY (parent_role_id, child_role_id)
- FOREIGN KEY (parent_role_id) REFERENCES roles(id)
- FOREIGN KEY (child_role_id) REFERENCES roles(id)

---

### 3.3 permissions

**論理名**: 権限マスタ  
**用途**: システム内の権限定義

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| permission_key | text | ✔ | - | 権限キー(一意) |
| resource | text | ✔ | - | リソース名 |
| action | text | ✔ | - | アクション(create/read/update/delete) |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (permission_key)

---

### 3.4 role_permissions

**論理名**: ロール権限紐付け  
**用途**: ロールと権限のN:M関係

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| role_id | uuid | ✔ | - | ロールID(PK, FK) |
| permission_id | uuid | ✔ | - | 権限ID(PK, FK) |

**制約**:
- UNIQUE (role_id, permission_id)
- FOREIGN KEY (role_id) REFERENCES roles(id)
- FOREIGN KEY (permission_id) REFERENCES permissions(id)

---

## 4. Board (掲示板)

### 4.1 board_categories

**論理名**: 掲示板カテゴリ  
**用途**: 投稿カテゴリの定義

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| category_key | text | ✔ | - | カテゴリキー |
| category_name | text | ✔ | - | カテゴリ名 |
| requires_approval | boolean | ✔ | false | 承認必要フラグ |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- tenants 1:N board_categories
- board_categories 1:N board_posts

---

### 4.2 board_posts

**論理名**: 掲示板投稿  
**用途**: 掲示板への投稿データ

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| author_id | uuid | ✔ | - | 投稿者ID(FK) |
| category_id | uuid | ✔ | - | カテゴリID(FK) |
| title | text | ✔ | - | タイトル |
| content | text | ✔ | - | 本文 |
| tags | text[] | ✔ | - | タグ配列 |
| status | text | ✔ | 'draft' | ステータス(draft/published/archived) |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (author_id) REFERENCES users(id)
- FOREIGN KEY (category_id) REFERENCES board_categories(id)

**備考**:
- tags: 「重要」「イベント」「防災」「ルール」等
- AIモデレーション対象

**リレーション**:
- users 1:N board_posts
- board_categories 1:N board_posts
- board_posts 1:N board_comments
- board_posts 1:N board_reactions
- board_posts 1:N board_attachments

---

### 4.3 board_comments

**論理名**: 掲示板コメント  
**用途**: 投稿へのコメント

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| post_id | uuid | ✔ | - | 投稿ID(FK) |
| author_id | uuid | ✔ | - | コメント投稿者ID(FK) |
| content | text | ✔ | - | コメント本文 |
| parent_comment_id | uuid | - | - | 親コメントID(FK、ネスト構造用) |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (post_id) REFERENCES board_posts(id)
- FOREIGN KEY (author_id) REFERENCES users(id)
- FOREIGN KEY (parent_comment_id) REFERENCES board_comments(id)

**リレーション**:
- board_posts 1:N board_comments
- users 1:N board_comments
- board_comments 1:N board_comments (自己参照)

---

### 4.4 board_reactions

**論理名**: 掲示板リアクション  
**用途**: 投稿へのいいね・通報・ブックマーク

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| post_id | uuid | ✔ | - | 投稿ID(FK) |
| user_id | uuid | ✔ | - | ユーザーID(FK) |
| reaction_type | ReactionType | ✔ | - | リアクション種別 |
| created_at | timestamp | ✔ | now() | 作成日時 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (post_id, user_id, reaction_type)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (post_id) REFERENCES board_posts(id)
- FOREIGN KEY (user_id) REFERENCES users(id)

**備考**:
- ReactionType: like, report, bookmark

**リレーション**:
- board_posts 1:N board_reactions
- users 1:N board_reactions

---

### 4.5 board_attachments

**論理名**: 掲示板添付ファイル  
**用途**: 投稿への画像・PDF添付

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| post_id | uuid | ✔ | - | 投稿ID(FK) |
| file_url | text | ✔ | - | ファイルURL(Supabase Storage) |
| file_name | text | ✔ | - | ファイル名 |
| file_type | text | ✔ | - | MIMEタイプ |
| file_size | integer | ✔ | - | ファイルサイズ(byte) |
| created_at | timestamp | ✔ | now() | 作成日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (post_id) REFERENCES board_posts(id)

**備考**:
- Supabase Storageに格納
- 署名付きURL発行

**リレーション**:
- board_posts 1:N board_attachments

---

### 4.6 board_approval_logs

**論理名**: 掲示板承認ログ  
**用途**: 投稿承認フローの記録

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| post_id | uuid | ✔ | - | 投稿ID(FK) |
| approver_id | uuid | ✔ | - | 承認者ID(FK) |
| action | ApprovalAction | ✔ | - | アクション(approve/reconsider) |
| comment | text | - | - | コメント |
| acted_at | timestamp | ✔ | now() | 実行日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (post_id) REFERENCES board_posts(id)
- FOREIGN KEY (approver_id) REFERENCES users(id)

**備考**:
- 管理組合専用カテゴリ投稿に適用

**リレーション**:
- board_posts 1:N board_approval_logs
- users 1:N board_approval_logs (承認者)

---

## 5. Announcements (お知らせ)

### 5.1 announcements

**論理名**: お知らせ  
**用途**: 管理者からのお知らせ配信

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| title | text | ✔ | - | タイトル |
| content | text | ✔ | - | 本文 |
| target_mode | text | ✔ | 'all' | 配信対象(all/group/individual) |
| valid_from | timestamp | ✔ | now() | 公開開始日時 |
| valid_until | timestamp | - | - | 公開終了日時 |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- tenants 1:N announcements
- announcements 1:N announcement_reads

---

### 5.2 announcement_reads

**論理名**: お知らせ既読管理  
**用途**: ユーザーごとの既読状態を追跡

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| announcement_id | uuid | ✔ | - | お知らせID(PK, FK) |
| user_id | uuid | ✔ | - | ユーザーID(PK, FK) |
| read_at | timestamp | ✔ | - | 既読日時 |

**制約**:
- UNIQUE (announcement_id, user_id)
- FOREIGN KEY (announcement_id) REFERENCES announcements(id)
- FOREIGN KEY (user_id) REFERENCES users(id)

**リレーション**:
- announcements 1:N announcement_reads
- users 1:N announcement_reads

---

## 6. Facilities / Reservations (施設・予約)

### 6.1 facilities

**論理名**: 施設マスタ  
**用途**: 共用施設の定義

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| facility_name | text | ✔ | - | 施設名 |
| facility_type | text | ✔ | - | 施設種別(parking/hall等) |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**備考**:
- MVP: ゲスト駐車場を対象

**リレーション**:
- tenants 1:N facilities
- facilities 1:1 facility_settings
- facilities 1:N facility_slots
- facilities 1:N facility_reservations

---

### 6.2 facility_settings

**論理名**: 施設設定  
**用途**: 施設の利用ルール・料金設定

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| facility_id | uuid | ✔ | - | 施設ID(FK) |
| fee_per_day | decimal | - | - | 1日あたり利用料金 |
| fee_unit | FacilityFeeUnit | ✔ | 'day' | 料金単位(day/hour) |
| max_consecutive_days | integer | ✔ | 3 | 最大連続予約日数 |
| reservable_until_months | integer | ✔ | 1 | 予約可能期間(月数) |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (facility_id) REFERENCES facilities(id)

**備考**:
- **fee_per_day**: テナント単位で設定可能(例: 100円/日)
- **fee_unit**: day(日単位)またはhour(時間単位)
- **reservable_until_months**: 予約可能な先の期間(デフォルト1ヶ月先まで)

**リレーション**:
- facilities 1:1 facility_settings

---

### 6.3 facility_slots

**論理名**: 施設区画  
**用途**: 駐車場区画など施設の細分化単位

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| facility_id | uuid | ✔ | - | 施設ID(FK) |
| slot_key | text | ✔ | - | 区画キー(例: F1, B2) |
| slot_name | text | ✔ | - | 区画名(例: 表F1, 裏B2) |
| status | Status | ✔ | 'active' | レコード状態 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (facility_id) REFERENCES facilities(id)

**リレーション**:
- facilities 1:N facility_slots

---

### 6.4 facility_reservations

**論理名**: 施設予約  
**用途**: 施設・区画の予約データ

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| facility_id | uuid | ✔ | - | 施設ID(FK) |
| slot_id | uuid | - | - | 区画ID(FK) |
| user_id | uuid | ✔ | - | 予約者ID(FK) |
| start_at | timestamp | ✔ | - | 利用開始日時 |
| end_at | timestamp | ✔ | - | 利用終了日時 |
| status | text | ✔ | 'pending' | 予約ステータス |
| created_at | timestamp | ✔ | now() | 作成日時 |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (facility_id) REFERENCES facilities(id)
- FOREIGN KEY (user_id) REFERENCES users(id)

**備考**:
- 排他制御: Supabase Function内でFOR UPDATE使用

**リレーション**:
- facilities 1:N facility_reservations
- users 1:N facility_reservations

---

## 7. Translation / TTS Cache (翻訳・TTS キャッシュ)

### 7.1 translation_cache

**論理名**: 翻訳キャッシュ  
**用途**: 投稿・コメントの翻訳結果をキャッシュ

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| content_type | text | ✔ | - | コンテンツ種別(post/comment) |
| content_id | text | ✔ | - | コンテンツID |
| language | text | ✔ | - | 翻訳先言語(ja/en/zh) |
| translated_text | text | ✔ | - | 翻訳結果 |
| expires_at | timestamp | - | - | 有効期限 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (tenant_id, content_type, content_id, language)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**備考**:
- **キャッシュ保持期間**: 30日(アプリ層で設定)
- Redisキー: `translation:{post_id}:{lang}`
- TTL: 72時間(Phase1)

**リレーション**:
- tenants 1:N translation_cache

---

### 7.2 tts_cache

**論理名**: TTS音声キャッシュ  
**用途**: Text-to-Speech音声ファイルのキャッシュ

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| content_type | text | ✔ | - | コンテンツ種別 |
| content_id | text | ✔ | - | コンテンツID |
| language | text | ✔ | - | 言語(ja/en/zh) |
| voice_type | text | ✔ | 'default' | 音声タイプ |
| audio_url | text | ✔ | - | 音声ファイルURL |
| duration_sec | decimal | - | - | 音声長(秒) |
| expires_at | timestamp | - | - | 有効期限 |
| created_at | timestamp | ✔ | now() | 作成日時 |

**制約**:
- PRIMARY KEY (id)
- UNIQUE (tenant_id, content_type, content_id, language)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**備考**:
- **キャッシュ保持期間**: 30日(アプリ層で設定)
- Phase 2以降で実装予定

**リレーション**:
- tenants 1:N tts_cache

---

## 8. Notifications (通知)

### 8.1 notifications

**論理名**: 通知履歴  
**用途**: ユーザーへの通知送信履歴

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| user_id | uuid | ✔ | - | 宛先ユーザーID(FK) |
| type | text | ✔ | - | 通知種別(announcement/board/reservation) |
| title | text | ✔ | - | 通知タイトル |
| content | text | ✔ | - | 通知本文 |
| sent_at | timestamp | ✔ | now() | 送信日時 |
| read_at | timestamp | - | - | 既読日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (user_id) REFERENCES users(id)

**備考**:
- Phase1: SendGridメール通知
- Phase2: FCMプッシュ通知追加

**リレーション**:
- tenants 1:N notifications
- users 1:N notifications

---

### 8.2 user_notification_settings

**論理名**: ユーザー通知設定  
**用途**: ユーザーごとの通知ON/OFF設定

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| user_id | uuid | ✔ | - | ユーザーID(FK) |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| notification_type | text | ✔ | - | 通知種別 |
| enabled | boolean | ✔ | true | 有効フラグ |
| updated_at | timestamp | ✔ | now() | 更新日時 |

**制約**:
- UNIQUE (user_id, tenant_id, notification_type)
- FOREIGN KEY (user_id) REFERENCES users(id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**リレーション**:
- users 1:N user_notification_settings
- tenants 1:N user_notification_settings

---

## 9. Audit / Moderation (監査・モデレーション)

### 9.1 audit_logs

**論理名**: 監査ログ  
**用途**: ユーザーアクションの監査証跡

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| user_id | uuid | ✔ | - | 実行ユーザーID(FK) |
| action_type | text | ✔ | - | アクション種別 |
| target_resource | text | ✔ | - | 対象リソース種別 |
| target_id | text | - | - | 対象リソースID |
| ip_address | text | - | - | IPアドレス |
| user_agent | text | - | - | ユーザーエージェント |
| timestamp | timestamp | ✔ | now() | 実行日時 |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)
- FOREIGN KEY (user_id) REFERENCES users(id)

**備考**:
- **用途**: 重要操作の記録(投稿削除、ロール変更、承認等)
- **保持期間**: 365日
- 不可変監査テーブルとして運用

**リレーション**:
- tenants 1:N audit_logs
- users 1:N audit_logs

---

### 9.2 moderation_logs

**論理名**: モデレーションログ  
**用途**: AIモデレーション判定結果の記録

| カラム名 | 型 | Not Null | デフォルト | 説明 |
|---------|-----|---------|-----------|------|
| id | uuid | ✔ | gen_random_uuid() | 主キー |
| tenant_id | uuid | ✔ | - | テナントID(FK) |
| content_type | text | ✔ | - | コンテンツ種別(post/comment) |
| content_id | text | ✔ | - | コンテンツID |
| ai_score | decimal | - | - | AIスコア(0.0-1.0) |
| flagged_reason | text | - | - | フラグ理由 |
| decision | DecisionType | ✔ | 'allow' | 判定結果(allow/mask/block) |
| decided_by | DecisionSource | ✔ | 'system' | 判定実施者(system/human) |
| decided_at | timestamp | ✔ | now() | 判定日時 |
| reviewed_by | text | - | - | レビュー担当者ID |

**制約**:
- PRIMARY KEY (id)
- FOREIGN KEY (tenant_id) REFERENCES tenants(id)

**備考**:
- **用途**: 不適切投稿検出・通報処理記録
- AIモデレーション結果と人間判断の突合に使用

**リレーション**:
- tenants 1:N moderation_logs

---

## 📊 補足情報

### 外部キー制約一覧

| 子テーブル | 子カラム | 親テーブル | 親カラム |
|-----------|---------|-----------|---------|
| tenant_settings | tenant_id | tenants | id |
| tenant_features | tenant_id | tenants | id |
| users | tenant_id | tenants | id |
| user_tenants | user_id | users | id |
| user_tenants | tenant_id | tenants | id |
| user_roles | user_id | users | id |
| user_roles | tenant_id | tenants | id |
| user_roles | role_id | roles | id |
| user_profiles | user_id | users | id |
| user_profiles | tenant_id | tenants | id |
| role_permissions | role_id | roles | id |
| role_permissions | permission_id | permissions | id |
| board_categories | tenant_id | tenants | id |
| board_posts | tenant_id | tenants | id |
| board_posts | author_id | users | id |
| board_posts | category_id | board_categories | id |
| board_comments | tenant_id | tenants | id |
| board_comments | post_id | board_posts | id |
| board_comments | author_id | users | id |
| board_reactions | tenant_id | tenants | id |
| board_reactions | post_id | board_posts | id |
| board_reactions | user_id | users | id |
| board_attachments | tenant_id | tenants | id |
| board_attachments | post_id | board_posts | id |
| board_approval_logs | tenant_id | tenants | id |
| board_approval_logs | post_id | board_posts | id |
| board_approval_logs | approver_id | users | id |
| announcements | tenant_id | tenants | id |
| announcement_reads | announcement_id | announcements | id |
| announcement_reads | user_id | users | id |
| facilities | tenant_id | tenants | id |
| facility_settings | tenant_id | tenants | id |
| facility_settings | facility_id | facilities | id |
| facility_slots | tenant_id | tenants | id |
| facility_slots | facility_id | facilities | id |
| facility_reservations | tenant_id | tenants | id |
| facility_reservations | facility_id | facilities | id |
| facility_reservations | user_id | users | id |
| translation_cache | tenant_id | tenants | id |
| tts_cache | tenant_id | tenants | id |
| notifications | tenant_id | tenants | id |
| notifications | user_id | users | id |
| user_notification_settings | user_id | users | id |
| user_notification_settings | tenant_id | tenants | id |
| audit_logs | tenant_id | tenants | id |
| audit_logs | user_id | users | id |
| moderation_logs | tenant_id | tenants | id |

---

### インデックス推奨

以下のカラムにインデックスを設定することを推奨:

```sql
-- テナント検索用
CREATE INDEX idx_tenants_code ON tenants(tenant_code);
CREATE INDEX idx_tenants_active ON tenants(is_active);

-- ユーザー検索用
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_tenant ON users(tenant_id);

-- 掲示板検索用
CREATE INDEX idx_board_posts_tenant ON board_posts(tenant_id);
CREATE INDEX idx_board_posts_category ON board_posts(category_id);
CREATE INDEX idx_board_posts_author ON board_posts(author_id);
CREATE INDEX idx_board_posts_created ON board_posts(created_at DESC);
CREATE INDEX idx_board_posts_tags ON board_posts USING GIN(tags);

-- 施設予約検索用
CREATE INDEX idx_facility_reservations_facility_date ON facility_reservations(facility_id, start_at);
CREATE INDEX idx_facility_reservations_user ON facility_reservations(user_id);

-- 翻訳キャッシュ検索用
CREATE INDEX idx_translation_cache_lookup ON translation_cache(tenant_id, content_type, content_id, language);

-- 通知検索用
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, read_at) WHERE read_at IS NULL;

-- 監査ログ検索用
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
```

---

## 🔐 RLSポリシー設定例

全テーブルに対して以下のRLSポリシーを設定:

```sql
-- テナント分離ポリシー(参照)
CREATE POLICY tenant_isolation_select
ON public.{table_name}
FOR SELECT
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- テナント分離ポリシー(挿入)
CREATE POLICY tenant_isolation_insert
ON public.{table_name}
FOR INSERT
WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- テナント分離ポリシー(更新)
CREATE POLICY tenant_isolation_update
ON public.{table_name}
FOR UPDATE
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- テナント分離ポリシー(削除)
CREATE POLICY tenant_isolation_delete
ON public.{table_name}
FOR DELETE
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
```

**適用例**:
```sql
ALTER TABLE board_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_select
ON public.board_posts
FOR SELECT
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
```

---

## ChangeLog

### v1.0 (2025-11-04)

**初版**: ER定義 v1.2 + Prisma v1.0 に基づく完全テーブル定義書

- 全30テーブルの定義を完了
- Multi-Tenant構造(RLS)を明記
- ENUM定義を追加
- 外部キー制約一覧を追加
- インデックス推奨を追加
- RLSポリシー設定例を追加
- Phase5 Step5-4成果物

---

**Document End**
