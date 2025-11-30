# SA-01 システム管理者向けテナント管理・テナント管理者管理 詳細設計書 v1.1

* Document ID: SA-01-SysAdmin-Tenant-Management-Detail-Design
* Version: 1.1
* Author: Tachikoma
* Reviewer: TKD
* Status: Draft
* Related Docs:

  * HarmoNet 詳細設計書アジェンダ標準 v1.0
  * システム管理者向けテナント管理・テナント管理者管理 基本設計書 v1.1
  * schema.prisma.20251128-1124

---

## 第1章 概要

### 1.1 対象コンポーネント・画面

本書は、システム管理者（system_admin）専用の以下画面群の詳細設計を定義する。

* SA-01: テナント一覧画面 `/sys-admin/tenants`
* SA-02: テナント詳細・編集画面 `/sys-admin/tenants/{tenantId}`
* SA-03: テナント管理者一覧画面 `/sys-admin/tenants/{tenantId}/admins`
* SA-04: テナント管理者新規登録画面 `/sys-admin/tenants/{tenantId}/admins/new`
* SA-05: テナント管理者編集画面 `/sys-admin/tenants/{tenantId}/admins/{userId}`

### 1.2 目的

* テナント単位のライフサイクル管理（作成・論理削除・再有効化）を system_admin のみが実行できるようにする。
* 各テナントに対して、最低 1 名以上のテナント管理者（tenant_admin ロールを持つ users）を system_admin が登録・更新・管理者ロール解除できるようにする。
* 既存 t-admin（テナント管理画面）のユーザ管理ロジック（users / roles / user_roles）との整合を保つ。

### 1.3 前提・制約

* 認証は既存の MagicLink 認証フローを利用し、Supabase Auth の `auth.users` と連携する。

* ログイン入口は以下の 2 系統に分離する。

  * 一般利用者・テナント管理者向け: `/login`
  * システム管理者向け: `/sys-admin/login`

* `/login` からのログインセッションでは `/sys-admin/*` にアクセスできない（リンクもメニューも表示しない）。

* `/sys-admin/login` からのログインセッションでは、MagicLink 認証成功後に `/sys-admin/tenants`（SA-01）へ遷移し、本書で定義する `/sys-admin/*` 画面のみを利用する。

* 権限管理は `roles` / `user_roles` で行う。

* 権限管理は `roles` / `user_roles` で行う。

  ```prisma
  enum role_scope {
    system_admin
    tenant_admin
    general_user
  }

  model roles {
    id       String   @id @default(uuid())
    role_key String   @unique
    name     String
    scope    role_scope
  }

  model user_roles {
    user_id   String
    tenant_id String
    role_id   String
    assigned_at DateTime @default(now())

    user   users   @relation(fields: [user_id], references: [id])
    tenant tenants @relation(fields: [tenant_id], references: [id])
    role   roles   @relation(fields: [role_id], references: [id])

    @@unique([user_id, tenant_id, role_id])
  }
  ```

  * system_admin 権限:

    * `roles.scope = system_admin`
    * `roles.role_key = 'SYSTEM_ADMIN'`（キー名は schema.prisma に合わせる）
  * tenant_admin 権限:

    * `roles.scope = tenant_admin` の role を持つ。

* system_admin ユーザは、システム管理専用のダミーテナント（例: `tenant_code = 'SYSTEM'`）に所属させる。

  * `user_roles.tenant_id` にはこのダミーテナントの `tenants.id` を設定する。
  * system_admin 権限の判定では tenant_id を参照せず、`roles.scope` / `roles.role_key` のみを用いる。

* DB スキーマは `schema.prisma.20251128-1124` を正とする。

  * 本機能で直接参照するテーブルは `tenants` / `users` / `roles` / `user_roles`。
  * `user_tenants` は掲示板既読管理等で利用されるが、本機能では参照・更新を行わない（テナント所属は `users.tenant_id` を正とする）。

* ユーザとテナントの関係は「1ユーザ = 1テナント」とする。

  * `users.tenant_id` は必須かつ 1 つのテナントを指す。
  * 別テナントに所属している users を本機能から管理者として追加することはできない。

* テナントの削除は status による論理削除とする（`tenants.status = inactive`）。物理削除は行わない。

* テナント管理者ユーザの「有効／無効」状態フラグは設けず、「管理者である／ない」は tenant_admin ロールの有無（該当 `user_roles` レコードの存在）で表現する。

  * 管理者から外す操作 = tenant_admin ロールの削除（`user_roles` DELETE）。
  * users レコード自体は削除しない。

### 1.4 対象外

* 一般ユーザ（general_user）の登録・編集・削除。
* 掲示板・翻訳・ショートカット等のテナント設定。
* system_admin 自身のユーザ情報編集 UI。

---

## 第2章 画面要件・UI仕様

### 2.1 テナント一覧画面（SA-01）

#### 2.1.1 表示要素

* 画面タイトル: 「テナント一覧」
* ボタン:

  * 「新規テナント作成」（右上配置）
* テナント一覧テーブル:

  * 列（論理名称）

    * テナントコード
    * テナント名
    * タイムゾーン
    * 状態（有効／無効）※ `tenants.status`
    * 作成日時

#### 2.1.2 操作仕様

* 行クリック（テナントコード or テナント名）

  * 対象テナントの SA-02 へ遷移。
* 「新規テナント作成」ボタン

  * SA-02 を新規モードで表示。

#### 2.1.3 メッセージ仕様

* データなし:

  * 「テナントが登録されていません。」
* 取得失敗:

  * 「テナント一覧の取得に失敗しました。時間をおいて再度お試しください。」

---

### 2.2 テナント詳細・編集画面（SA-02）

#### 2.2.1 表示要素

* 画面タイトル: 「テナント詳細」
* モード:

  * 新規: 「テナント新規登録」
  * 更新: 「テナント詳細」＋テナントコード表示
* 入力項目（論理名称）

  * テナントコード（新規時のみ編集可）
  * テナント名
  * タイムゾーン
  * 状態（有効／無効）
* ボタン:

  * 「保存」
  * 状態が有効のとき: 「無効化」
  * 状態が無効のとき: 「再有効化」
  * 「管理者一覧へ」
  * 「一覧に戻る」

#### 2.2.2 バリデーション

* テナントコード

  * 必須
  * 英数字＋`-` `_` のみ
  * 最大 32 文字
  * システム全体でユニーク
* テナント名

  * 必須
  * 最大 80 文字
* タイムゾーン

  * 必須
  * IANA TZ から選択（例: Asia/Tokyo）
* 状態

  * 「有効」「無効」の 2 値のみ

#### 2.2.3 メッセージ仕様

* 保存成功:

  * 「テナント情報を保存しました。」
* 無効化成功:

  * 「テナントを無効化しました。このテナントの利用者はログインできなくなります。」
* 再有効化成功:

  * 「テナントを再有効化しました。」

---

### 2.3 テナント管理者一覧画面（SA-03）

#### 2.3.1 表示要素

* 画面タイトル: 「テナント管理者一覧」
* サブタイトル: 「テナント：{テナント名}」
* ボタン:

  * 「新規管理者登録」（右上）
  * 「テナント詳細へ戻る」
* テーブル列（論理名称）

  * メールアドレス
  * 表示名
  * 最終ログイン（任意）

※ 「状態」列は持たず、tenant_admin ロールを持つユーザのみを一覧表示する。

#### 2.3.2 メッセージ仕様

* データなし

  * 「このテナントの管理者ユーザは登録されていません。」
* 管理者ロール解除成功

  * 「管理者ユーザを削除しました。（一般ユーザとしての情報は残ります）」

---

### 2.4 テナント管理者新規登録画面（SA-04）

#### 2.4.1 入力項目（論理名称）

* メールアドレス
* 表示名
* 氏名

※ t-admin のユーザ登録仕様と同一のバリデーションルールを用いる。

#### 2.4.2 メッセージ

* 保存成功

  * 「管理者ユーザを登録しました。」
* 既存メールアドレスの場合

  * 「既存ユーザをこのテナントの管理者として登録しました。」と表示してもよい。

---

### 2.5 テナント管理者編集画面（SA-05）

* メールアドレスは表示のみ（変更不可）。
* 表示名／氏名のみ編集可。
* 「管理者ロール解除」ボタンを配置し、押下すると当該テナントにおける tenant_admin ロールを削除する（ユーザ自体は残す）。

---

## 第3章 構造設計

### 3.1 Next.js ルーティング

* ベースパス: `/sys-admin`

```text
app/
  sys-admin/
    tenants/
      page.tsx              // SA-01 テナント一覧
      [tenantId]/
        page.tsx            // SA-02 テナント詳細
        admins/
          page.tsx          // SA-03 テナント管理者一覧
          new/
            page.tsx        // SA-04 テナント管理者新規登録
          [userId]/
            page.tsx        // SA-05 テナント管理者編集
```

### 3.2 コンポーネント構成

* 共通レイアウト:

  * `SysAdminLayout`（仮）

    * AppHeader / AppFooter を内包
* ページコンポーネント:

  * `TenantListPage`（SA-01）
  * `TenantDetailPage`（SA-02）
  * `TenantAdminListPage`（SA-03）
  * `TenantAdminCreatePage`（SA-04）
  * `TenantAdminEditPage`（SA-05）

---

## 第4章 ロジック仕様

### 4.1 system_admin 判定

* `/sys-admin/login` からの MagicLink 認証後、`currentUserId` を取得し、以下を満たすか判定する。

```ts
const isSystemAdmin = await prisma.user_roles.findFirst({
  where: {
    user_id: currentUserId,
    role: {
      scope: "system_admin",
      role_key: "SYSTEM_ADMIN",
    },
  },
});
```

* 判定 NG の場合は `/sys-admin/*` へのアクセスを拒否する。

### 4.2 テナント一覧取得ロジック（SA-01）

テナント一覧取得ロジック（SA-01）

```ts
const tenants = await prisma.tenants.findMany({
  orderBy: { created_at: "desc" },
});
```

### 4.3 テナント登録・更新ロジック（SA-02）

* 新規登録:

```ts
await prisma.tenants.create({
  data: {
    tenant_code,
    tenant_name,
    timezone,
    status: "active",
  },
});
```

* 更新:

```ts
await prisma.tenants.update({
  where: { id: tenantId },
  data: {
    tenant_name,
    timezone,
    status, // "active" or "inactive"
  },
});
```

### 4.4 テナント管理者一覧ロジック（SA-03）

```ts
const admins = await prisma.users.findMany({
  where: {
    tenant_id: tenantId,
    user_roles: {
      some: {
        role: { scope: "tenant_admin" },
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

### 4.5 テナント管理者登録ロジック（SA-04）

1. メールアドレスで `users` を検索。
2. 既存ユーザが存在する場合:

   * `users.tenant_id !== tenantId` の場合はエラー。
   * 同一テナントであれば、users はそのまま利用。
3. 存在しない場合:

   * Supabase Auth にユーザ作成。
   * `users` に INSERT（`tenant_id = tenantId`、表示名等）。

     * `group_code` / `residence_code` 等の NOT NULL カラムには、sys-admin 固有のダミー値（例: `SYSADMIN`）を設定する。
4. tenant_admin ロールを付与:

```ts
await prisma.user_roles.create({
  data: {
    user_id: user.id,
    tenant_id: tenantId,
    role_id: tenantAdminRoleId,
  },
});
```

### 4.6 テナント管理者編集ロジック（SA-05）

* ユーザ情報の更新（UI で編集可能な項目のみ）:

```ts
await prisma.users.update({
  where: { id: userId },
  data: {
    display_name,
    full_name,
  },
});
```

* 管理者ロール解除:

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

## 第5章 データ仕様

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

### 5.2 users

```prisma
model users {
  id             String   @id @default(uuid())
  tenant_id      String
  email          String   @unique
  display_name   String
  full_name      String
  full_name_kana String?
  group_code     String
  residence_code String
  phone_number   String?
  language       String   @default("JA")
  note           String?
  created_at     DateTime @default(now())
  updated_at     DateTime @updatedAt
}
```

### 5.3 roles / user_roles

```prisma
enum role_scope {
  system_admin
  tenant_admin
  general_user
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

  user   users   @relation(fields: [user_id], references: [id])
  tenant tenants @relation(fields: [tenant_id], references: [id])
  role   roles   @relation(fields: [role_id], references: [id])

  @@unique([user_id, tenant_id, role_id])
}
```
