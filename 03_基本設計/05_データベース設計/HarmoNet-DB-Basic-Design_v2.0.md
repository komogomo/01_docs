# HarmoNet データベース基本設計書 v2.0

**Document ID:** HARMONET-DB-BASIC-DESIGN-V2
**Version:** 2.0
**Date:** 2025-12-02
**Scope:** HarmoNet アプリケーションで使用する全テーブルの基本設計（論理/物理定義）

---

## 1. 概要

本ドキュメントは、HarmoNet アプリケーションのデータベース（PostgreSQL）のスキーマ定義をまとめたものである。
`prisma/schema.prisma` を正とし、最新のテーブル構造、リレーション、インデックス、および RLS（Row Level Security）の方針を記載する。

### 1.1 設計方針
*   **UUID採用**: 主キーには原則として UUID (`uuid_generate_v4()`) を使用する。
*   **論理削除なし**: データの削除は物理削除 (`DELETE`) を基本とし、論理削除フラグ (`is_deleted`) は持たない。
*   **マルチテナント**: ほぼ全てのテーブルに `tenant_id` を持ち、RLS によりテナント間のデータ分離を強制する。
*   **Supabase連携**: 認証は Supabase Auth (`auth.users`) を利用し、`public.users` と 1:1 で同期する。

---

## 2. テーブル定義 (Models)

### 2.1 テナント管理 (Tenant Management)

#### 2.1.1 tenants
テナント（マンション・コミュニティ）の基本情報。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | テナントID |
| tenant_code | String | Unique | テナントコード（表示用ID） |
| tenant_name | String | | テナント名 |
| timezone | String | | タイムゾーン |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: None (PK/Uniqueのみ)

#### 2.1.2 tenant_settings
テナントごとの設定情報（JSON形式）。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 設定ID |
| tenant_id | String | FK | テナントID |
| config_json | Json | | 設定JSON |
| default_language | String | Default("ja") | デフォルト言語 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: `@@index([tenant_id])`

#### 2.1.3 tenant_features
テナントごとの機能フラグ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| feature_key | String | | 機能キー |
| enabled | Boolean | Default(true) | 有効/無効 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: `@@index([tenant_id])`

#### 2.1.4 tenant_shortcut_menu
フッターショートカットメニューの設定。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| feature_key | Enum | | 機能キー |
| label_key | String | | ラベルキー(i18n) |
| icon | String | | アイコン名 |
| display_order | Int | | 表示順 |
| enabled | Boolean | Default(true) | 有効/無効 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: `@@unique([tenant_id, feature_key])`, `@@index([tenant_id, display_order])`

---

### 2.2 ユーザ・認証 (Users / Auth)

#### 2.2.1 users
アプリケーションユーザマスタ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ユーザID (auth.usersと同期) |
| tenant_id | String | FK | 所属テナントID (1ユーザ1テナント) |
| email | String | Unique | メールアドレス |
| display_name | String | Unique | 表示名 |
| full_name | String | | 氏名 |
| full_name_kana | String? | | 氏名カナ |
| group_code | String | | グループコード（街区等） |
| residence_code | String | | 住戸番号 |
| phone_number | String? | | 電話番号 |
| language | String | Default("JA") | 言語設定 |
| note | String? | | 備考 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

*   **Indexes**: `@@index([tenant_id])`

#### 2.2.2 tenant_residents
住民基本台帳情報。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| user_id | String? | FK | 紐づくユーザID |
| residence_code | String | | 住戸番号 |
| real_name | String | | 実名 |
| real_name_kana | String | | 実名カナ |
| phone_number | String? | | 電話番号 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: `@@unique([tenant_id, residence_code])`, `@@index([tenant_id])`, `@@index([user_id])`

#### 2.2.3 user_tenants
ユーザとテナントの所属関係（中間テーブル）。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| user_id | String | PK, FK | ユーザID |
| tenant_id | String | PK, FK | テナントID |
| board_last_seen_at | DateTime? | | 掲示板最終閲覧日時 |

*   **PK**: `@@id([user_id, tenant_id])`
*   **Indexes**: `@@index([tenant_id])`

#### 2.2.4 user_roles
ユーザへのロール割り当て。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| user_id | String | PK, FK | ユーザID |
| tenant_id | String | PK, FK | テナントID |
| role_id | String | PK, FK | ロールID |
| assigned_at | DateTime | Default(now) | 割り当て日時 |

*   **PK**: `@@id([user_id, tenant_id, role_id])`
*   **Indexes**: `@@index([tenant_id])`, `@@index([role_id])`

---

### 2.3 ロール・権限 (Roles / Permissions)

#### 2.3.1 roles
ロールマスタ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ロールID |
| role_key | String | Unique | ロールキー |
| name | String | | ロール名 |
| scope | Enum(role_scope) | | スコープ |
| permissions_ref | String? | | 権限参照 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

#### 2.3.2 role_inheritances
ロール継承関係。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| parent_role_id | String | PK, FK | 親ロールID |
| child_role_id | String | PK, FK | 子ロールID |

*   **PK**: `@@id([parent_role_id, child_role_id])`
*   **Indexes**: `@@index([child_role_id])`

#### 2.3.3 permissions
権限マスタ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 権限ID |
| permission_key | String | Unique | 権限キー |
| resource | String | | リソース |
| action | String | | アクション |
| description | String? | | 説明 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

#### 2.3.4 role_permissions
ロールと権限の紐付け。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| role_id | String | PK, FK | ロールID |
| permission_id | String | PK, FK | 権限ID |

*   **PK**: `@@id([role_id, permission_id])`
*   **Indexes**: `@@index([permission_id])`

---

### 2.4 掲示板 (Board)

#### 2.4.1 board_categories
掲示板カテゴリ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | カテゴリID |
| tenant_id | String | FK | テナントID |
| category_key | String | | カテゴリキー |
| category_name | String | | カテゴリ名 |
| display_order | Int | Default(0) | 表示順 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum(status) | Default(active) | ステータス |

*   **Indexes**: `@@unique([tenant_id, category_key])`

#### 2.4.2 board_posts
掲示板投稿。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 投稿ID |
| tenant_id | String | FK | テナントID |
| category_id | String | FK | カテゴリID |
| author_id | String | FK | 投稿者ID |
| author_display_name | String? | | 投稿者表示名（スナップショット） |
| author_role | Enum | Default(general) | 投稿時のロール |
| title | String | | タイトル |
| content | String | Text | 本文 |
| status | Enum | Default(draft) | ステータス |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([category_id])`, `@@index([author_id])`

#### 2.4.3 board_comments
投稿へのコメント。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | コメントID |
| tenant_id | String | FK | テナントID |
| post_id | String | FK | 投稿ID |
| author_id | String | FK | 投稿者ID |
| content | String | Text | 本文 |
| parent_comment_id | String? | | 親コメントID |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |
| status | Enum | Default(active) | ステータス |
| author_display_name | String? | | 投稿者表示名 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([post_id])`, `@@index([author_id])`

#### 2.4.4 board_reactions
リアクション（いいね等）。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| post_id | String | FK | 投稿ID |
| user_id | String | FK | ユーザID |
| reaction_type | Enum | | リアクション種別 |
| created_at | DateTime | Default(now) | 作成日時 |

*   **Indexes**: `@@unique([post_id, user_id, reaction_type])`, `@@index([tenant_id])`, `@@index([post_id])`, `@@index([user_id])`

#### 2.4.5 board_attachments
添付ファイル。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| post_id | String | FK | 投稿ID |
| file_url | String | | ファイルURL |
| file_name | String | | ファイル名 |
| file_type | String | | ファイルタイプ |
| file_size | Int | | サイズ |
| created_at | DateTime | Default(now) | 作成日時 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([post_id])`

#### 2.4.6 board_approval_logs
承認履歴。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| post_id | String | FK | 投稿ID |
| approver_id | String | FK | 承認者ID |
| action | Enum | | アクション |
| comment | String | Text | コメント |
| acted_at | DateTime | Default(now) | 実行日時 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([post_id])`, `@@index([approver_id])`

#### 2.4.7 board_favorites
お気に入り。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| tenant_id | String | FK | テナントID |
| user_id | String | FK | ユーザID |
| post_id | String | FK | 投稿ID |
| created_at | DateTime | Default(now) | 作成日時 |

*   **Indexes**: `@@unique([tenant_id, user_id, post_id])`, `@@index([tenant_id])`, `@@index([user_id])`, `@@index([post_id])`

#### 2.4.8 board_post_translations / board_comment_translations
翻訳データ（投稿・コメント）。

*   **Indexes**: `@@unique([post_id/comment_id, lang])`, `@@index([tenant_id, lang, created_at])`

---

### 2.5 お知らせ (Announcements)

#### 2.5.1 announcements
お知らせ本体。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | お知らせID |
| tenant_id | String | FK | テナントID |
| title | String | | タイトル |
| content | String | Text | 本文 |
| target_mode | Enum | Default(all) | 配信対象モード |
| valid_from | DateTime | Default(now) | 公開開始日時 |
| valid_until | DateTime? | | 公開終了日時 |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

*   **Indexes**: `@@index([tenant_id])`

#### 2.5.2 announcement_reads
既読管理。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| announcement_id | String | PK, FK | お知らせID |
| user_id | String | PK, FK | ユーザID |
| read_at | DateTime | | 既読日時 |

*   **PK**: `@@id([announcement_id, user_id])`
*   **Indexes**: `@@index([user_id])`

#### 2.5.3 announcement_targets
配信対象詳細。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ID |
| announcement_id | String | FK | お知らせID |
| target_type | String | | 対象種別 |
| target_id | String | | 対象ID |

*   **Indexes**: `@@index([announcement_id])`

---

### 2.6 施設予約 (Facilities)

#### 2.6.1 facilities
施設マスタ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 施設ID |
| tenant_id | String | FK | テナントID |
| facility_name | String | | 施設名 |
| facility_type | String | | 施設タイプ |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

*   **Indexes**: `@@index([tenant_id])`

#### 2.6.2 facility_settings
施設設定。

*   **Indexes**: `@@index([tenant_id])`

#### 2.6.3 facility_slots
施設区画。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 区画ID |
| tenant_id | String | FK | テナントID |
| facility_id | String | FK | 施設ID |
| slot_key | String | | 区画キー |
| slot_name | String | | 区画名 |
| status | Enum | Default(active) | ステータス |

*   **Indexes**: `@@index([tenant_id])`, `@@index([facility_id])`

#### 2.6.4 facility_reservations
施設予約。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | 予約ID |
| tenant_id | String | FK | テナントID |
| facility_id | String | FK | 施設ID |
| slot_id | String? | FK | 区画ID |
| user_id | String | FK | ユーザID |
| start_at | DateTime | | 開始日時 |
| end_at | DateTime | | 終了日時 |
| status | Enum | Default(pending) | ステータス |
| created_at | DateTime | Default(now) | 作成日時 |
| updated_at | DateTime | UpdatedAt | 更新日時 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([facility_id])`, `@@index([user_id])`, `@@index([slot_id])`

#### 2.6.5 facility_blocked_ranges
予約不可期間。

*   **Indexes**: `@@index([tenant_id])`, `@@index([facility_id])`

---

### 2.7 監査・モデレーション (Audit / Moderation)

#### 2.7.1 audit_logs
監査ログ。

| カラム名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| id | String (UUID) | PK | ログID |
| tenant_id | String | FK | テナントID |
| user_id | String | FK | ユーザID |
| action_type | String | | アクション種別 |
| target_resource | String | | 対象リソース |
| target_id | String? | | 対象ID |
| ip_address | String | | IPアドレス |
| user_agent | String | | UserAgent |
| timestamp | DateTime | Default(now) | 日時 |

*   **Indexes**: `@@index([tenant_id])`, `@@index([user_id])`

#### 2.7.2 moderation_logs
AIモデレーションログ。

*   **Indexes**: `@@index([tenant_id])`, `@@index([reviewed_by])`

---

## 3. RLS (Row Level Security) 方針

全テーブルに対して RLS を有効化 (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) し、以下の基本ポリシーを適用する。

1.  **テナント分離**:
    *   原則として `tenant_id = (select auth.uid() -> tenant_id)` の条件により、自テナントのデータのみアクセス可能とする。
    *   `system_admin` は全テナントへのアクセス権を持つ。

2.  **ロールベース制御**:
    *   `tenant_admin`: 自テナント内の管理操作（ユーザ管理、掲示板管理など）が可能。
    *   `general_user`: 自テナント内の公開情報の閲覧、自身のデータの作成・編集が可能。

3.  **パフォーマンス最適化**:
    *   `auth.uid()` 関数の呼び出しコストを考慮し、可能な限り `(select auth.uid())` として呼び出すか、JWTクレームを利用した高速な判定を行う。
