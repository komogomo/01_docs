# SA-01 システム管理者向けテナント管理・テナント管理者管理 詳細設計書 v1.3

**Document ID:** SA-01-SysAdmin-Tenant-Management-Detail-Design
**Version:** 1.3
**Supersedes:** v1.2
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft（要 TKD 確認）
**Related Docs:**

* HarmoNet 詳細設計書アジェンダ標準 v1.0
* SysAdmin テナント管理・テナント管理者管理 基本設計書 v1.1
* テナント管理者用ユーザ登録画面 詳細設計書 ch01 v1.0（/t-admin/users）
* schema.prisma.20251128-1124（最新版）
* 認証基盤詳細設計書（harmonet-auth-guard-detail-design_v1.0.md）

---

## 第1章 概要

### 1.1 対象画面・コンポーネント

本書は、**システム管理者専用の 1 画面構成**によるテナント管理コンソールの詳細設計を定義する。

* 画面 ID: **SA-01 SysAdmin Tenant Management Console**
* 画面パス: `/sys-admin/tenants`（1 画面のみ）
* 対象ロール: `system_admin` のみ

本 v1.2 では、v1.1 で定義していた以下の 5 画面構成を廃止し、**1 画面内のセクション切替**に統合する。

* SA-01: テナント一覧画面 `/sys-admin/tenants`
* SA-02: テナント詳細・編集画面 `/sys-admin/tenants/{tenantId}`
* SA-03: テナント管理者一覧画面 `/sys-admin/tenants/{tenantId}/admins`
* SA-04: テナント管理者新規登録画面 `/sys-admin/tenants/{tenantId}/admins/new`
* SA-05: テナント管理者編集画面 `/sys-admin/tenants/{tenantId}/admins/{userId}`

これらはすべて **SA-01 画面内のセクションとして統合**し、画面遷移を発生させない。

### 1.2 目的

* **1 画面で完結するテナント管理 UI** を提供する。
* system_admin が、以下の操作を 1 画面上で行えるようにする。

  * テナント一覧の参照
  * テナントの新規登録 / 編集 / 無効化 / 再有効化
  * 各テナントに紐づくテナント管理者ユーザの一覧表示
  * テナント管理者ユーザの新規登録 / 編集 / 管理者ロール付与・解除
* 既存 `t-admin`（テナント管理者用ユーザ管理 `/t-admin/users`）の仕様と整合しつつ、**「物件全体のライフサイクル管理」専用のコンソール**として位置づける。

### 1.3 前提・制約

* 認証は既存 MagicLink フロー（Supabase Auth）を利用する。
* SysAdmin ログイン入口は `/sys-admin/login` とし、通常ログイン `/login` とは分離する（別仕様書参照）。
* `/sys-admin/*` にアクセスできるのは `system_admin` ロールを持つユーザのみとする。
* **認証・認可ガードには、共通基盤（Middleware + Server Helper）を利用する。** 詳細は `harmonet-auth-guard-detail-design_v1.0.md` を参照。
* DB スキーマは `schema.prisma.20251128-1124` を正とし、本機能で直接利用するテーブルは以下とする。

  * `tenants`
  * `users`
  * `roles`
  * `user_roles`
* ユーザとテナントの関係は **1ユーザ=1テナント**（`users.tenant_id`）とし、system_admin は専用のダミーテナントを持つ。
* **画面は 1 ページ構成**とし、モーダル・サイドパネル・フォーム表示切替で状態を切り替える。別ページへの遷移は行わない。

---

  * 必須、英数字 + `-` `_` のみ、最大 32 文字、システム全体で一意
* テナント名

  * 必須、最大 80 文字
* タイムゾーン

  * 必須、IANA TZ から選択

#### 2.3.3 メッセージ

* 保存成功: 「テナント情報を保存しました。」
* 無効化成功: 「テナントを無効化しました。このテナントの利用者はログインできなくなります。」
* 再有効化成功: 「テナントを再有効化しました。」

### 2.4 SEC-03 テナント管理者管理パネル

#### 2.4.1 表示要素

* セクションタイトル: 「テナント管理者」
* サブタイトル: 「テナント: {テナント名}」
* 管理者一覧テーブル

  * 列

    * メールアドレス
    * 表示名（ニックネーム）
    * 氏名
    * 最終ログイン（任意、取得できる場合のみ）
    * 操作（編集 / 管理者解除）
* 管理者登録フォーム

  * メールアドレス
  * 表示名
  * 氏名
* ボタン

  * 「管理者ユーザ登録」

#### 2.4.2 操作仕様

* 管理者一覧行の「編集」

  * 下部フォームに選択ユーザの表示名 / 氏名を読み込み、編集モードにする。
  * 「管理者ユーザ更新」ボタンで `users` を更新。
* 管理者一覧行の「管理者解除」

  * 対象ユーザの `tenant_admin` ロールに紐づく `user_roles` レコードを削除する。
  * `users` レコード自体は削除しない。
* 管理者登録フォーム
## 第3章 構造設計

### 3.1 コンポーネント構成

* ページコンポーネント

  * `SysAdminTenantManagementPage`（/sys-admin/tenants）
* 内部セクションコンポーネント（例）

  * `TenantListPanel`（SEC-01）
  * `TenantDetailForm`（SEC-02）
  * `TenantAdminPanel`（SEC-03、一覧＋登録フォーム）
* 共通レイアウト

  * `SysAdminLayout`（AppHeader / AppFooter / サイドメニュー）

### 3.2 状態管理

* ページ内で保持する主な状態

  * `selectedTenantId` … SEC-01 の選択行に応じて更新
  * `tenantList` … `tenants` 一覧
  * `tenantDetail` … 選択テナントの詳細情報
  * `tenantAdmins` … 選択テナントの管理者一覧
  * `adminFormMode` … `'create' | 'edit'`
  * `adminFormValues` … メールアドレス / 表示名 / 氏名

状態遷移はすべて 1 ページ内で完結させ、ページ遷移は発生させない。

---

## 第4章 ロジック仕様

### 4.1 system_admin 判定

* `/sys-admin/tenants` 初期表示時、共通認証ヘルパーを利用して権限チェックを行う。

```ts
import { getSystemAdminContext } from "@/src/lib/auth/systemAdminAuth";

// Server Component 内での利用
const { adminClient, user } = await getSystemAdminContext();
// 権限がない場合は自動的にリダイレクトされるため、ここでの分岐処理は不要。
```

* API ルート (`/app/api/sys-admin/*`) においても同様に API 用ヘルパーを利用する。

```ts
import { getSystemAdminApiContext } from "@/src/lib/auth/systemAdminAuth";

// Route Handler 内での利用
const { adminClient, user } = await getSystemAdminApiContext();
// 権限がない場合は例外がスローされ、自動的に 401/403 レスポンスが返却される。
```

### 4.2 テナント一覧取得

```ts
const tenants = await prisma.tenants.findMany({
  orderBy: { created_at: 'desc' },
});
```

### 4.3 テナント登録・更新

* 新規登録

```ts
await prisma.tenants.create({
  data: {
    tenant_code,
    tenant_name,
    timezone,
    status: 'active',
  },
});

// デフォルト掲示板カテゴリの作成 (board_categories)
// - 重要なお知らせ
// - 回覧板
// - 議事録
// - イベント
// - メンテナンス
// - その他
// - 管理組合からのお知らせ
```

* 更新

```ts
await prisma.tenants.update({
  where: { id: tenantId },
  data: {
    tenant_name,
    timezone,
    status, // 'active' | 'inactive'
  },
});

### 4.4 テナント削除

テナント削除時は、以下の関連テーブルのデータも削除する（外部キー制約および論理削除の考慮）。

1.  **アプリケーションデータ**
    *   `board_posts` (Cascade: `board_comments`, `board_attachments`, `board_approval_logs`, `board_post_translations`, `board_comment_translations`)
    *   `board_categories`
    *   `board_reactions` (明示的削除)
    *   `board_favorites` (明示的削除)
    *   `announcements` (Cascade: `announcement_reads`, `announcement_targets`)
    *   `facilities` (Cascade: `facility_settings`, `facility_slots`, `facility_reservations`, `facility_blocked_ranges`)
    *   `audit_logs`
    *   `moderation_logs`
    *   `tenant_settings`
    *   `tenant_features`
    *   `tenant_shortcut_menu`
    *   `tenant_residents`
    *   `translation_cache`
    *   `tts_cache`
    *   `notifications`
    *   `user_notification_settings`

2.  **ユーザ関連データ**
    *   `user_profiles`
    *   `user_roles`
    *   `user_tenants`
    *   `users` (Supabase Authユーザ削除含む)

3.  **テナント本体**
    *   `tenants`
```

### 4.4 テナント管理者一覧取得

```ts
const admins = await prisma.users.findMany({
  where: {
    tenant_id: tenantId,
    user_roles: {
      some: {
        role: { scope: 'tenant_admin' },
      },
    },
  },
  include: {
    user_roles: {
      include: { role: true },
    },
  },
});
```

### 4.5 テナント管理者登録

1. メールアドレスで `users` を検索。
2. 既存ユーザが存在する場合:

   * `users.tenant_id !== tenantId` の場合はエラー。
   * 同一テナントであれば、そのユーザに `tenant_admin` ロールを付与。
3. 存在しない場合:

   * Supabase Auth にユーザ作成。
   * `users` に INSERT（`tenant_id = tenantId`、表示名など）。

     * NOT NULL カラム（`group_code` / `residence_code`）には、system_admin 用のダミー値（例: `SYSADMIN`）を設定。
4. `tenant_admin` ロール付与:

```ts
await prisma.user_roles.create({
  data: {
    user_id: user.id,
    tenant_id: tenantId,
    role_id: tenantAdminRoleId,
  },
});
```

### 4.6 テナント管理者編集

```ts
await prisma.users.update({
  where: { id: userId },
  data: {
    display_name,
    full_name,
  },
});
```

### 4.7 管理者ロール解除

```ts
await prisma.user_roles.delete({
  where: {
    user_id_tenant_id_role_id: {
      user_id: userId,
      tenant_id: tenantId,
      role_id: tenantAdminRoleId,
    },
  },
});
```

---

## 第5章 データ仕様（抜粋）

### 5.1 tenants

```prisma
model tenants {
  id          String   @id @default(uuid())
  tenant_code String   @unique
  tenant_name String
  timezone    String
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt
  status      status   @default(active)
}
```

### 5.2 users / user_roles / roles

本画面で利用するカラムは以下の通り（詳細は DB 設計書参照）。

```prisma
model users {
  id             String   @id @default(uuid())
  tenant_id      String
  email          String   @unique
  display_name   String
  full_name      String
  group_code     String
  residence_code String
  // ...
}

model roles {
  id       String   @id @default(uuid())
  role_key String   @unique
  name     String
  scope    role_scope
}

model user_roles {
  user_id     String
  tenant_id   String
  role_id     String
  assigned_at DateTime @default(now())

  @@unique([user_id, tenant_id, role_id])
}
```

---

## 第6章 メッセージ仕様

### 6.1 成功メッセージ

| コード                                     | 文言                                    |
| --------------------------------------- | ------------------------------------- |
| `sysadmin.tenants.save.success`         | テナント情報を保存しました。                        |
| `sysadmin.tenants.deactivate.success`   | テナントを無効化しました。このテナントの利用者はログインできなくなります。 |
| `sysadmin.tenants.activate.success`     | テナントを再有効化しました。                        |
| `sysadmin.tenants.admin.create.success` | 管理者ユーザを登録しました。                        |
| `sysadmin.tenants.admin.update.success` | 管理者ユーザ情報を更新しました。                      |
| `sysadmin.tenants.admin.remove.success` | 管理者ユーザを削除しました。（一般ユーザとしての情報は残ります）      |

### 6.2 エラーメッセージ

| コード                                        | 文言                              |
| ------------------------------------------ | ------------------------------- |
| `sysadmin.tenants.error.validation`        | 入力内容を確認してください。                  |
| `sysadmin.tenants.error.code.duplicate`    | テナントコードが既に存在します。他のコードを指定してください。 |
| `sysadmin.tenants.error.admin.crossTenant` | 他テナントに所属しているユーザは管理者として追加できません。  |
| `sysadmin.tenants.error.unauthorized`      | システム管理者権限がありません。                |
| `sysadmin.tenants.error.internal`          | サーバーエラーが発生しました。時間をおいて再度お試しください。 |

---

## 第7章 テスト観点（要約）

### 7.1 テナント一覧・詳細

* SA-UT-01: system_admin でログインし、全テナントが一覧表示されること。
* SA-UT-02: テナント行選択で SEC-02 / SEC-03 が選択テナントの情報に更新されること。
* SA-UT-03: 新規テナント登録→一覧に即時反映されること。

### 7.2 管理者管理

* SA-UT-10: 既存ユーザを管理者として追加した場合、`user_roles` にレコードが追加されること。
* SA-UT-11: 新規メールアドレスで管理者登録した場合、`auth.users` / `users` / `user_roles` にレコードが作成されること。
* SA-UT-12: 管理者解除で `user_roles` の該当レコードのみ削除されること。

---

## 第8章 ChangeLog

| Version | Date       | Author    | Summary                                        |
| ------- | ---------- | --------- | ---------------------------------------------- |
| 1.3     | 2025-12-01 | Antigravity | 認証ガード導入に伴い、system_admin 判定ロジックを更新。 |
| 1.2     | 2025-11-30 | Tachikoma | SysAdmin テナント管理画面を 5 画面構成から 1 画面 3 セクション構成に統合。 |
| 1.1     | 2025-11-28 | Tachikoma | 初版 5 画面構成案（SA-01〜05）を作成。                       |
| 1.0     | 2025-11-27 | Tachikoma | たたき台作成。                                        |
