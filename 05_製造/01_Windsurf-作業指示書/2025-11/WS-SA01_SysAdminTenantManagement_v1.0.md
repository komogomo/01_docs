# WS-SA01 SysAdmin テナント管理コンソール 実装作業指示書 v1.0

* Task ID: WS-SA01
* Title: SysAdmin テナント管理・テナント管理者管理コンソール実装
* Target: `/sys-admin/tenants` 配下の画面・API 一式（SA-01〜SA-05）
* For: Windsurf
* Source of Truth:

  * `Sa-01 Sys Admin Tenant Management-detail-design v1.1`（本チャット Canvas）
  * `Sys-admin-tenant-management-basic-design_v1.1.md`
  * `schema.prisma.20251128-1124`
* CodeAgent_Report 保存先:

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-SA01_SysAdminTenantManagement_v1.0.md`

---

## 1. ゴール

システム管理者専用のテナント管理コンソールを実装する。

* system_admin ロールを持つユーザのみがアクセス可能な `/sys-admin/*` 配下の UI とロジックを追加。
* 以下の機能を Sa-01 詳細設計書 v1.1 に沿って実装する。

  * テナント一覧（SA-01）
  * テナント詳細・編集（SA-02）
  * テナント管理者一覧（SA-03）
  * テナント管理者新規登録（SA-04）
  * テナント管理者編集・管理者ロール解除（SA-05）
* 既存 t-admin / auth ロジック（users / roles / user_roles / tenants）と整合を保つこと。

---

## 2. スコープ

### 2.1 UI / ルーティング

* App Router に `/sys-admin/tenants` 以下のページを追加する。

  * `/sys-admin/tenants`               → SA-01 テナント一覧
  * `/sys-admin/tenants/[tenantId]`    → SA-02 テナント詳細
  * `/sys-admin/tenants/[tenantId]/admins`        → SA-03 管理者一覧
  * `/sys-admin/tenants/[tenantId]/admins/new`    → SA-04 管理者新規
  * `/sys-admin/tenants/[tenantId]/admins/[userId]` → SA-05 管理者編集
* レイアウトは `SysAdminLayout`（仮称）を新規追加し、AppHeader / AppFooter を利用。
* 見た目は HarmoNet 共通 UI 方針（白ベース・控えめ・Apple カタログ風）に合わせるが、細かい余白・幅は TKD 調整前提で最低限で良い。

### 2.2 ロジック

* system_admin 判定:

  * `user_roles` JOIN `roles` で `scope = 'system_admin'` ＋ `role_key = 'SYSTEM_ADMIN'` を持つレコードの有無で判定。
  * `/sys-admin/*` アクセス前に必ず判定し、NG の場合は 403 または別画面へリダイレクト（詳細設計に従う）。
* テナント一覧・詳細:

  * `tenants` テーブルから取得・更新（status による論理削除／再有効化）。
* テナント管理者一覧:

  * `users.tenant_id = tenantId` かつ `user_roles` に tenant_admin ロールを持つユーザのみ表示。
* テナント管理者登録:

  * 既存ユーザ:

    * `users.tenant_id` が異なる場合はエラー。
    * 同一テナントなら `user_roles` に tenant_admin ロールを追加。
  * 新規ユーザ:

    * Supabase Auth にユーザ作成。
    * `users` に INSERT（`tenant_id = tenantId`、表示名等）。
    * `group_code` / `residence_code` には固定値 `SYSADMIN`（大文字）を設定。
    * `user_roles` に tenant_admin ロールを追加。
* テナント管理者編集:

  * `users.display_name` / `users.full_name` のみ更新。
  * 「管理者ロール解除」押下で、当該テナントの tenant_admin ロールの `user_roles` レコードを DELETE。

### 2.3 データ

* Prisma モデルは `schema.prisma.20251128-1124` を正とする（変更禁止）。
* DB マイグレーションは本タスクでは行わない。既存 schema に合わせて実装のみ行う。

---

## 3. 実装詳細

### 3.1 依存・前提

* Next.js 16 App Router / TypeScript / Prisma / Supabase クライアントは既存プロジェクト設定を利用。
* 認証情報（currentUserId 取得ロジック）は既存実装を流用。
* RLS は既存ポリシーに合わせて動作する前提で、サーバ側は `system_admin` 判定を行った上でクエリを実行する。

### 3.2 コンポーネント構成（例）

* `app/sys-admin/tenants/page.tsx`      → SA-01
* `app/sys-admin/tenants/[tenantId]/page.tsx` → SA-02
* `app/sys-admin/tenants/[tenantId]/admins/page.tsx` → SA-03
* `app/sys-admin/tenants/[tenantId]/admins/new/page.tsx` → SA-04
* `app/sys-admin/tenants/[tenantId]/admins/[userId]/page.tsx` → SA-05
* `app/sys-admin/layout.tsx` → SysAdminLayout（ヘッダー・フッター共通）

ファイル名・ディレクトリ名は既存ガイドライン（ReorganizeFrontendStructure）に合わせて、必要であれば調整してよい。

### 3.3 エラーハンドリング・メッセージ

* 画面メッセージは Sa-01 詳細設計書 第2章の文言に合わせる。
* サーバエラーは画面上部に汎用メッセージ（例: 「処理に失敗しました。時間をおいて再度お試しください。」）を表示。

---

## 4. テスト観点（最低限）

※ 単体・結合テストは別途 UT 設計で詳細化する前提。ここでは Windsurf 実装時のセルフチェック観点だけ記載。

1. system_admin 判定

   * system_admin ロールあり → `/sys-admin/tenants` にアクセス可。
   * system_admin ロールなし → `/sys-admin/tenants` にアクセス不可。
2. テナント一覧

   * tenants のレコードが一覧に表示される。
   * status = inactive のテナントが「無効」として表示される。
3. テナント新規・編集

   * 新規テナント作成が DB に反映される。
   * テナント名／タイムゾーン／状態の更新が反映される。
4. テナント管理者一覧

   * tenantId に紐づく tenant_admin ロール保持ユーザのみ表示される。
5. 管理者新規登録

   * 既存ユーザ同一テナント → tenant_admin ロールが追加される。
   * 新規ユーザ → users / user_roles が作成され、group_code / residence_code = `SYSADMIN` となる。
6. 管理者編集

   * 表示名／氏名の更新が反映される。
7. 管理者ロール解除

   * `user_roles` の当該レコードが削除され、一覧から消える。

---

## 5. 制約・禁止事項

* schema.prisma に変更を加えない（新規マイグレーション禁止）。
* 既存 t-admin / 住民向け画面の挙動を変更しない（/sys-admin 配下のみ修正対象）。
* ログインフロー（`/login` 側）の変更は行わない。
* Sa-01 詳細設計書に明記されていない仕様追加を勝手に行わない。

---

## 6. 完了条件

* Sa-01 詳細設計書 v1.1 に記載された画面・ロジックが `/sys-admin/tenants` 配下に実装されていること。
* `npm run lint` / `npm run type-check` でエラーがないこと。
* 手動動作確認で、テナント作成〜管理者登録〜管理者ロール解除までが一通り動作すること。
* CodeAgent_Report を `/01_docs/06_品質チェック/CodeAgent_Report_WS-SA01_SysAdminTenantManagement_v1.0.md` に作成し、自己スコア・実施内容を記載すること。
