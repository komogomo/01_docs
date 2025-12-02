# HarmoNet DB設計書 - 認証ユーザ / テナント / ユーザ所属 v1.0

**Document ID:** HARMONET-DB-AUTH-USERS-TENANTS
**Version:** 1.0
**Scope:** ログイン認証・テナント所属に関わる中核3テーブルのDB設計

* `tenants`
* `users`（publicスキーマ側）
* `user_tenants`
* 付属: Supabase `auth.users` との関係、およびユーザ登録/削除時の対象テーブル

> 本書では掲示板テーブル（`board_*`）は扱わない。認証・テナント所属モデルの設計に限定する。

---

## 1. 全体構成と前提

### 1.1 テナント / ユーザ / 所属の基本モデル

* Supabase `auth.users`

  * 認証（メールアドレス・パスワードレス）を管理する Supabase 管理テーブル。
  * `id` は UUID。HarmoNet 側 `public.users.id` と 1:1 で対応。
* `public.users`

  * HarmoNet アプリケーション内部で利用するユーザマスタ。
  * 表示名・言語・デフォルトテナント等を保持。
* `public.tenants`

  * 物件・コミュニティ（マンション等）のマスタ。
  * ほぼすべての業務テーブルは `tenant_id` で本テーブルに紐づく。
* `public.user_tenants`

  * 1ユーザがどのテナントに所属しているかを表す中間テーブル。
  * 「テナント境界の真実」はこのテーブルに持たせる。

### 1.2 運用方針の前提

* 一時停止／復活／論理削除は行わない。

  * 退去・退会・解約が発生した場合は、関連レコードを DELETE で削除する。
  * 過去住民の履歴・audit は保持しない。
* テナント件数は 1〜数十件規模を想定しており、履歴やアーカイブ用の複雑な構造は不要。
* Prisma Migrate の migration ファイルは運用しない。

  * スキーマ変更は `schema.prisma` を直接編集し、`npx prisma db push` で反映する。

---

## 2. tenants テーブル

### 2.1 役割

* マンション・団地など、HarmoNet の対象となる物件/コミュニティを管理するマスタ。
* ほぼ全ての業務データは `tenant_id` で本テーブルに紐づく。

### 2.2 カラム定義

| カラム名        | 型(長さ)        | PK/FK | NULL | UNIQUE | DEFAULT              | INDEX               | 説明                                       |
| ----------- | ------------ | ----- | ---- | ------ | -------------------- | ------------------- | ---------------------------------------- |
| id          | uuid         | PK    | NO   | YES    | `uuid_generate_v4()` | PRIMARY KEY (id)    | テナントID。全システムで一意。                         |
| tenant_code | varchar(64)  |       | NO   | YES    |                      | UNIQUE(tenant_code) | 物件コード。人間が扱いやすい識別子。                       |
| tenant_name | varchar(255) |       | NO   |        |                      |                     | テナント表示名。画面上に表示。                          |
| timezone    | varchar(64)  |       | NO   |        | `'Asia/Tokyo'`       |                     | テナントの標準タイムゾーン。投稿日時等の表示基準。                |
| status      | status enum  |       | NO   |        | `'active'`           | INDEX(status)       | テナント状態。`active / inactive / archived` 等。 |
| created_at  | timestamptz  |       | NO   |        | `now()`              |                     | レコード作成日時。                                |
| updated_at  | timestamptz  |       | NO   |        | `now()` (ON UPDATE)  |                     | 最終更新日時。                                  |

> `tenants.is_active` は `status` と完全重複しており、不要なため削除済みとする。

### 2.3 制約・インデックス

* PK: `PRIMARY KEY (id)`
* UNIQUE: `UNIQUE (tenant_code)`
* INDEX: `INDEX (status)`（運用上必要であれば追加）

### 2.4 RLS 方針概要

* `tenants` は、一般ユーザが直接参照するケースは限定的。
* 方針：

  * `system_admin` ロール: 全テナント `SELECT` 可能。
  * `tenant_admin` ロール: 自テナントのみ `SELECT` 可能。
  * 一般ユーザ: 原則として直接 `SELECT` させず、API 経由で必要情報のみ返す。
* 具体的な `CREATE POLICY` は RLS設計書側に記載する。

---

## 3. users テーブル（public.users）

### 3.1 役割

* HarmoNet 内の「人」を表すユーザマスタ。
* Supabase `auth.users` と 1:1 で紐づく。

### 3.2 カラム定義

| カラム名         | 型(長さ)        | PK/FK | NULL | UNIQUE | DEFAULT              | INDEX            | 説明                                 |
| ------------ | ------------ | ----- | ---- | ------ | -------------------- | ---------------- | ---------------------------------- |
| id           | uuid         | PK    | NO   | YES    | `uuid_generate_v4()` | PRIMARY KEY (id) | Supabase `auth.users.id` と一致。      |
| email        | varchar(255) |       | NO   | YES    |                      | UNIQUE(email)    | ログイン用メールアドレス。全テナント横断で一意。           |
| display_name | varchar(255) |       | NO   |        |                      |                  | 掲示板等での表示名。ニックネーム。                  |
| language     | varchar(5)   |       | NO   |        | `'ja'`               |                  | 利用者のベース言語。`ja/en/zh` 等。            |
| tenant_id    | uuid         | FK    | YES  |        |                      | INDEX(tenant_id) | 最後に利用したテナントIDのキャッシュ用途。所属判定には使用しない。 |
| created_at   | timestamptz  |       | NO   |        | `now()`              |                  | 作成日時。                              |
| updated_at   | timestamptz  |       | NO   |        | `now()` (ON UPDATE)  |                  | 更新日時。                              |

> `users.status` は「一時停止／復活」運用を行わない前提のため削除済み。アカウント削除はレコード DELETE で対応する。

### 3.3 制約・インデックス

* PK: `PRIMARY KEY (id)`
* UNIQUE: `UNIQUE (email)`
* FK: `FOREIGN KEY (tenant_id) REFERENCES tenants(id)`（NULL 許容）

### 3.4 Supabase auth.users との関係

* `auth.users.id = public.users.id`
* 新規ユーザ登録時のフロー（現状想定）:

  1. MagicLink などで `auth.users` にレコードが作成される。
  2. DBトリガ or サーバ側処理により、`public.users` に同期レコードを作成する。

     * `id`, `email`, `created_at` などをコピー。
     * `display_name` / `language` は初回ログイン時またはユーザ登録画面で設定。
* 退会時:

  * `auth.users` / `public.users` / `user_tenants` / `tenant_residents` を削除する方針（論理削除なし）。
  * 具体的な削除順序・処理はアプリケーション側の仕様で定義する。

### 3.5 RLS 方針概要

* ユーザ自身:

  * `auth.uid() = users.id` の行について `SELECT/UPDATE` を許可。
* 管理者（system_admin / tenant_admin）:

  * 自テナントに紐づくユーザについて、管理画面から `SELECT` / 必要な `UPDATE` を許可。
* 他ユーザの `users` 行を一般ユーザが直接読むことはさせない（必要情報は API 経由で返す）。

---

## 4. user_tenants テーブル

### 4.1 役割

* 1ユーザがどのテナントに所属しているかを表す中間テーブル。
* テナント境界・権限制御の「真実」を持つテーブル。

### 4.2 カラム定義

| カラム名               | 型(長さ)       | PK/FK | NULL | UNIQUE | DEFAULT | INDEX                                | 説明                  |
| ------------------ | ----------- | ----- | ---- | ------ | ------- | ------------------------------------ | ------------------- |
| user_id            | uuid        | PK,FK | NO   |        |         | INDEX(user_id)                       | `users.id`。         |
| tenant_id          | uuid        | PK,FK | NO   |        |         | INDEX(tenant_id)                     | `tenants.id`。       |
| board_last_seen_at | timestamptz |       | YES  |        |         | INDEX(tenant_id, board_last_seen_at) | 掲示板未読バッジ判定用の最終閲覧時刻。 |

> 主キーは `PRIMARY KEY (user_id, tenant_id)` とする。`joined_at` / `status` カラムは採用せず、退去時は行削除で対応する。

### 4.3 制約・インデックス

* PK: `PRIMARY KEY (user_id, tenant_id)`
* FK:

  * `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
  * `FOREIGN KEY (tenant_id) REFERENCES tenants(id)`
* INDEX:

  * `INDEX (user_id)`
  * `INDEX (tenant_id)`
  * 必要に応じて `INDEX (tenant_id, board_last_seen_at)`（未読判定のクエリ次第で調整）

### 4.4 RLS 方針概要

* 一般ユーザ:

  * `auth.uid() = user_id` の行だけ `SELECT` を許可（自分がどのテナントに所属しているか）。
* tenant_admin:

  * 自テナント(`tenant_id`)の全ユーザについて `SELECT` / 必要な `INSERT/DELETE` を許可（ユーザ所属管理画面）。
* system_admin:

  * 全テナントに対する `SELECT` を許可。

具体的な `CREATE POLICY` は RLS設計書で詳細定義する。

---

## 5. ユーザ登録 / 削除時の対象テーブル

### 5.1 ユーザ登録時（新規作成）

1. `auth.users`

   * Supabase による認証ユーザレコードが作成される。
2. `public.users`

   * `auth.users` と同期して 1レコード作成。
   * 必須項目: `id`, `email`, `display_name`（初回ログイン時設定可）, `language`（申請書ベースの初期値）。
3. `public.user_tenants`

   * 初期所属テナント分のレコードを作成。
   * `(user_id, tenant_id)` の組み合わせを PRIMARY KEY とする。
4. `public.tenant_residents`（必要な場合）

   * 住戸番号・実名など、住民情報を別テーブルで管理する場合に作成。

### 5.2 ユーザ削除時（退会・完全削除）

退会時は次の順番で DELETE を行う（論理削除はしない）。

1. `public.user_tenants`

   * 該当ユーザの全テナント所属レコードを削除。
2. `public.tenant_residents`

   * 該当ユーザに紐づく住民情報があれば削除。
3. `public.users`

   * 該当ユーザレコードを削除。
4. `auth.users`

   * Supabase 側の認証ユーザレコードを削除。

> 退会処理の実装はアプリケーションコード側（API / サーバアクション）で制御し、DBトリガで自動連鎖させない方針とする。

---

## 6. RLS 詳細設計との関係

* 本書では各テーブルの RLS 方針を概要レベルで示した。
* 実際のポリシー定義（`CREATE POLICY` 文・`USING` / `WITH CHECK` 条件・ロールごとの設定）は、別ドキュメント `HarmoNet-RLS-Policy-design_users-tenants_v1.x.md` で詳細に定義する。
* DB設計とRLS設計は、

  * 主キー/外部キー/インデックス
  * `auth.uid()` と `users.id` の対応
    を共有前提として維持する。
