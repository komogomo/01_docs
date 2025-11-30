# SA-01 システム管理者向けテナント管理・テナント管理者管理 詳細設計書 v1.0

* Document ID: SA-01-SysAdmin-Tenant-Management-Detail-Design
* Version: 1.0
* Author: Tachikoma
* Reviewer: TKD
* Status: Draft
* Related Docs:

  * HarmoNet 詳細設計書アジェンダ標準 v1.0
  * システム管理者向けテナント管理・テナント管理者管理 基本設計書（本書の上位）
  * HarmoNet Prisma Schema v1.7-clean（schema.prisma.20251128-1124）

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
* 各テナントに対して、最低 1 名以上のテナント管理者（tenant_admin ロールを持つ users）を system_admin が登録・更新・削除できるようにする。
* 既存 t-admin（テナント管理画面）のユーザ管理ロジック（users / user_roles）との整合を保つ。

### 1.3 前提・制約

* 認証は既存の MagicLink 認証フローを利用し、Supabase Auth の `auth.users` と連携する。
* system_admin 権限は TKD が DB 上で直接付与する。UI 上から system_admin を付与・削除する機能は提供しない。
* system_admin 権限は `roles` / `user_roles` で管理する。

  * `roles.scope = system_admin` かつ `roles.role_key = 'SYSTEM_ADMIN'`（名称は運用定義に従う）
  * `user_roles` が (user_id, tenant_id, role_id) を持つことで、当該ユーザがそのテナントで system_admin／tenant_admin などの権限を有することを示す。
* 本詳細設計では、システム管理画面にアクセス可能なユーザを「system_admin ユーザ」と呼ぶ。
* DB スキーマは `schema.prisma.20251128-1124` を正とする。

  * tenants / users / roles / user_roles を直接参照する。
  * `user_tenants` は掲示板既読管理用であり、本機能では使用しない。
* テナントの削除は status による論理削除とする（`tenants.status = inactive`）。物理削除は行わない。
* テナント管理者ユーザの削除は、当該テナントに対する tenant_admin ロールの解除とする。

  * users レコード自体は削除しない。
  * 他テナントで利用中の場合は、そのテナント側のロール・状態に影響を与えない。

### 1.4 対象外

* 一般ユーザ（general_user）の登録・編集・削除。
* 掲示板・翻訳・ショートカット等のテナント設定。
* system_admin 自身のユーザ情報編集 UI。

---

## 第2章 画面要件・UI仕様

本章では、論理項目名とメッセージ仕様を中心に、各画面の UI 要件を定義する。最終レイアウト（余白・幅・細かい配置）は実装後に TKD が画面を確認しながら調整する前提とする。

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
    * 状態（有効／無効）
    * 作成日時

#### 2.1.2 操作仕様

* 行クリック（テナントコード or テナント名）

  * 対象テナントの SA-02 へ遷移。
* 「新規テナント作成」ボタン

  * SA-02 を新規モードで表示。

#### 2.1.3 メッセージ仕様

* データなし時:

  * テーブル部に「テナントが登録されていません。」を控えめなトーンで表示。
* 取得失敗時:

  * 画面上部にエラーアラート「テナント一覧の取得に失敗しました。時間をおいて再度お試しください。」

---

### 2.2 テナント詳細・編集画面（SA-02）

#### 2.2.1 表示要素

* 画面タイトル: 「テナント詳細」
* 対象モード:

  * 新規モード: 「テナント新規登録」サブタイトル
  * 更新モード: 「テナント詳細」サブタイトル＋テナントコード表示
* ボタン:

  * 「保存」
  * 状態が active の場合: 「無効化」
  * 状態が inactive の場合: 「再有効化」
  * 「管理者一覧へ」
  * 「一覧に戻る」
* 入力項目（論理名称）

  * テナントコード（新規時のみ入力可）
  * テナント名
  * タイムゾーン
  * 状態（有効／無効）

#### 2.2.2 バリデーション

* テナントコード

  * 必須
  * 文字種: 英数字 + `-` `_` のみ
  * 最大桁数: 32 桁（仮。詳細は DB 設計に合わせる）
  * システム全体で一意であること（重複時は「このテナントコードは既に使用されています。」）
* テナント名

  * 必須
  * 最大桁数: 80 文字程度
* タイムゾーン

  * 必須
  * IANA TZ からの選択（例: Asia/Tokyo）
* 状態

  * 「有効」「無効」の 2 値のみ選択可

#### 2.2.3 メッセージ仕様

* 保存成功時

  * 画面上部に「テナント情報を保存しました。」
* 無効化成功時

  * 「テナントを無効化しました。このテナントの利用者はログインできなくなります。」
* 再有効化成功時

  * 「テナントを再有効化しました。」
* バリデーションエラー

  * 各フィールド直下にエラーメッセージを表示。

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
  * 状態（有効／無効）
  * 最終ログイン（任意）

#### 2.3.2 メッセージ仕様

* データなし

  * 「このテナントの管理者ユーザは登録されていません。」
* 削除（ロール解除）成功

  * 「管理者ユーザを削除しました。（一般ユーザとしての情報は残ります）」

---

### 2.4 テナント管理者新規登録画面（SA-04）

#### 2.4.1 入力項目（論理名称）

* メールアドレス
* 表示名
* 氏名
* 状態（有効／無効）

※ t-admin のユーザ登録仕様と同一のバリデーションルールを用いる。詳細は第5章データ仕様で users モデルと紐付けて定義する。

#### 2.4.2 メッセージ

* 保存成功

  * 「管理者ユーザを登録しました。」
* 既存メールアドレスの場合

  * 成功時メッセージに「既存ユーザをこのテナントの管理者として登録しました。」などの文言を追加するかは後続で調整。

---

### 2.5 テナント管理者編集画面（SA-05）

* メールアドレスは表示のみ（変更不可）。
* 表示名／氏名／状態のみ編集可。
* 「管理者ロール解除」ボタンを配置し、押下すると当該テナントにおける tenant_admin ロールを削除する（ユーザ自体は残す）。

---

## 第3章 構造設計

### 3.1 Next.js ルーティング

* ベースパス: `/sys-admin`
* App Router 構成（例示）

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
            page.tsx        // SA-04 テナント管理者新規
          [userId]/
            page.tsx        // SA-05 テナント管理者編集
```

※ 実際のディレクトリ名・ファイル名は既存フロント構成ガイドライン（ReorganizeFrontendStructure）に合わせて Windsurf 指示書で最終決定する。

### 3.2 コンポーネント構成

* 共通レイアウト

  * `SysAdminLayout`（仮）

    * AppHeader / AppFooter を内包
    * system_admin 専用ナビゲーション（必要最小限）
* 各ページコンポーネント

  * `TenantListPage`（SA-01）
  * `TenantDetailPage`（SA-02）
  * `TenantAdminListPage`（SA-03）
  * `TenantAdminCreatePage`（SA-04）
  * `TenantAdminEditPage`（SA-05）

### 3.3 サーバコンポーネント／クライアントコンポーネント境界

* 一覧・詳細のデータ取得は原則サーバコンポーネントで行う。
* 編集フォーム部分は、バリデーションと UX のためにクライアントコンポーネントを利用。
* Supabase／Prisma を直接呼び出すのはサーバコンポーネントまたは server actions に限定する。

---

## 第4章 ロジック仕様

### 4.1 system_admin 判定

* ログイン後、共通ロジックで `currentUserId` を取得。
* `user_roles` / `roles` を JOIN し、以下条件を満たすか判定：

  * `roles.scope = 'system_admin'`
* 満たさない場合、`/sys-admin/*` へのアクセスは 403 または HOME にリダイレクトする。

### 4.2 テナント一覧取得ロジック（SA-01）

* Prisma クエリ（擬似コード）

```ts
const tenants = await prisma.tenants.findMany({
  orderBy: { created_at: "desc" },
});
```

* status が archived のものを一覧に含めるかは TKD と相談。初期案では active / inactive のみ表示とし、archived は別途運用とする。

### 4.3 テナント登録・更新ロジック（SA-02）

* 新規登録時:

  * tenants.create({ data: { tenant_code, tenant_name, timezone, status: 'active' } })
* 更新時:

  * tenants.update({ where: { id }, data: { tenant_name, timezone, status } })
* 無効化／再有効化:

  * status フィールドのみ active / inactive に更新。

### 4.4 テナント管理者一覧ロジック（SA-03）

* 対象テナント ID を指定し、以下条件を満たす users を取得：

  * users.tenant_id = {tenantId}
  * user_roles において、roles.scope = tenant_admin の role_id を持つ

擬似クエリ:

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
2. 存在する場合:

   * tenant_id が異なる場合はエラーとし、「別テナントに所属しているユーザは管理者として追加できません。」等のメッセージを返す（1ユーザ=1テナントの前提を維持）。
   * tenant_id が同一なら users はそのまま利用。
3. 存在しない場合:

   * Supabase Auth にユーザ作成（メールアドレス）
   * users.create で新規レコード作成（tenant_id = 対象テナント、表示名等）
4. user_roles に tenant_admin ロールを付与：

```ts
await prisma.user_roles.create({
  data: {
    user_id: user.id,
    tenant_id: tenantId,
    role_id: tenantAdminRoleId,
  },
});
```

※ tenantAdminRoleId は roles テーブルから `scope = 'tenant_admin'` のレコードを事前取得しておき、キャッシュして使う。

### 4.6 テナント管理者編集ロジック（SA-05）

* users テーブルの display_name / full_name / full_name_kana / note などを更新。
* 状態変更を行う場合は、users 側に status カラムがないため、将来的に `users_status` などを設けるか、別テーブルで管理する。

  * 現時点では「管理者ロール解除」により実質的な無効化とする案とし、詳細は DB 設計側で詰める。
* 管理者ロール解除時:

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

* 物理定義（抜粋）

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

* 本機能での利用カラム:

  * tenant_code / tenant_name / timezone / status / created_at

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

* 本機能での利用カラム:

  * tenant_id（テナント紐付け）
  * email / display_name / full_name / full_name_kana / note

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
  // ...
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

* system_admin 判定:

  * roles.scope = system_admin の role_id を保持している user_roles を持つユーザ。
* tenant_admin 判定:

  * roles.scope = tenant_admin の role_id を保持している user_roles を持つユーザ。

---

## 第6章 メッセージ・エラー処理

* 正常系メッセージは第2章に定義した文言を共通利用。
* エラー系共通方針:

  * バリデーションエラー: 各項目直下に赤字テキストで表示。
  * サーバエラー: 画面上部に一般エラー「処理に失敗しました。時間をおいて再度お試しください。」
  * 権限エラー: 「この機能にアクセスする権限がありません。」を表示し HOME へリダイレクト。

---

## 第7章 UT 観点（抜粋）

* UT01: テナント新規登録（正常）
* UT02: テナントコード重複エラー
* UT03: テナント無効化・再有効化
* UT04: テナント管理者新規登録（既存メール／新規メール）
* UT05: 他テナント所属ユーザを管理者に追加しようとした場合のエラー
* UT06: 管理者ロール解除後、一覧から消えること
* UT07: system_admin 以外が /sys-admin/* にアクセスした場合の拒否

詳細なテストケースは別途 UT 設計書で定義する。
