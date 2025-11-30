# WS-SA01 SysAdmin テナント管理コンソール 実装作業指示書 v1.1

* **Task ID:** WS-SA01
* **Title:** SysAdmin テナント管理・テナント管理者管理コンソール実装（1画面統合版）
* **Target:** `/sys-admin/tenants` 配下の画面・API 一式（**1画面のみ**）
* **For:** Windsurf
* **CodeAgent_Report 保存先:**

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-SA01_SysAdminTenantManagement_v1.1.md`

---

## 1. 目的 / ゴール

システム管理者専用の **テナント管理コンソール（1画面構成）** を実装する。

* URL は **`/sys-admin/tenants` の 1 画面のみ** とし、画面遷移は発生させない。
* 1 画面の中で、以下の 3 セクションを表示・連携させる。

  1. **テナント一覧パネル（左）**
  2. **テナント詳細フォーム（右上）**
  3. **テナント管理者管理パネル（右下）**
* system_admin ロールを持つユーザが、1画面上で次の操作を完結できることをゴールとする。

  * テナント一覧の参照
  * テナント新規作成 / 編集 / 有効・無効切替
  * テナントに紐づく管理者ユーザの一覧表示
  * 管理者ユーザの新規登録 / 編集 / 管理者ロール解除

---

## 2. スコープ

### 2.1 対象機能

* `/sys-admin/tenants` ページコンポーネントの新規実装または改修
* ページ内セクションコンポーネントの実装

  * `TenantListPanel`（テナント一覧）
  * `TenantDetailForm`（テナント詳細・新規登録フォーム）
  * `TenantAdminPanel`（テナント管理者一覧＋登録フォーム）
* system_admin 判定ロジックの実装（サーバサイド）
* Prisma 経由での以下テーブルへのアクセスロジック実装

  * `tenants`
  * `users`
  * `roles`
  * `user_roles`
* 画面上のバリデーション / メッセージ表示（成功・エラー）

### 2.2 非スコープ

* `schema.prisma` の変更（新規テーブル・カラム追加、型変更など）は禁止。
* 既存 `/login` や `/t-admin/*` など、システム管理者以外の画面の仕様変更は行わない。
* ログインフロー、認証方式の変更（MagicLink 以外の導入）は行わない。

---

## 3. 参照設計書・リポジトリ

### 3.1 設計書

* **Sa-01 SysAdminTenantManagement-detail-design v1.2（本チャット Canvas 上の最新版）**

  * `/sys-admin/tenants` 1画面構成、3セクション仕様を定義した詳細設計書
* システム管理者向けテナント管理・テナント管理者管理 基本設計書 v1.1
* HarmoNet 詳細設計書アジェンダ標準 v1.0

### 3.2 リポジトリ・コード

* GitHub: `https://github.com/komogomo/Projects-HarmoNet.git`
* ローカルパス: `D:\Projects\HarmoNet`

---

## 4. 実装・修正内容

### 4.1 画面構成 / レイアウト

#### 4.1.1 ページレイアウト

* ページコンポーネント（例）：`app/sys-admin/tenants/page.tsx`
* レイアウトは以下の 3 セクションとする。

```text
┌─────────────────────────────────────────────┐
│ [共通ヘッダー AppHeader]                                            │
├─────────────────────────────────────────────┤
│ 左: TenantListPanel             │ 右上: TenantDetailForm                │
│                                 │ 右下: TenantAdminPanel                │
├─────────────────────────────────────────────┤
│ [共通フッター AppFooter]                                            │
└─────────────────────────────────────────────┘
```

* レイアウトは既存の管理画面・HarmoNet 共通 UI ガイドラインに従い、過度な装飾は行わない。
* 画面遷移（SA-02〜SA-05）は一切実装しない。URL は `/sys-admin/tenants` のみ。

#### 4.1.2 状態管理

ページレベルで以下の状態を保持し、3セクション間で共有する。

* `selectedTenantId: string | null`
* `tenantList: Tenant[]`
* `tenantDetail: TenantDetail | null`
* `tenantAdmins: TenantAdminUser[]`
* `adminFormMode: 'create' | 'edit'`
* `adminFormValues: { email: string; displayName: string; fullName: string; }`

実装は React Hooks / Server Components のプロジェクト方針に従うこと。既存画面（t-admin 等）と同じパターンを優先採用する。

---

### 4.2 テナント一覧パネル（TenantListPanel）

#### 4.2.1 機能要件

* 全テナントを一覧表示する。
* 列（論理名）

  * テナントコード
  * テナント名
  * タイムゾーン
  * 状態（有効 / 無効）
  * 作成日時
* 行クリックで `selectedTenantId` を更新し、右側の **TenantDetailForm / TenantAdminPanel** に反映させる。
* 「新規テナント作成」ボタンを配置し、クリックでフォームを新規モードにする。

#### 4.2.2 実装ポイント

* 初期表示時に `tenants` テーブルから全件取得し、`created_at` 降順で表示。
* 行選択時：

  * `selectedTenantId` に対象 ID を設定
  * 対象テナントの詳細情報を取得して `tenantDetail` に反映
  * 対象テナントの管理者一覧を取得して `tenantAdmins` に反映
* 「新規テナント作成」クリック時：

  * `selectedTenantId = null`
  * `tenantDetail` を新規用の初期値（空）に設定
  * `tenantAdmins` は空配列

---

### 4.3 テナント詳細フォーム（TenantDetailForm）

#### 4.3.1 入力項目

* テナントコード（新規時のみ編集可）
* テナント名
* タイムゾーン（IANA TZ プルダウン）
* 状態（有効 / 無効 切替。既存テナントのみ編集可）

#### 4.3.2 バリデーション

* テナントコード

  * 必須
  * 英数字 + `-` `_` のみ
  * 最大 32 文字
  * システム全体でユニーク
* テナント名

  * 必須
  * 最大 80 文字
* タイムゾーン

  * 必須
  * IANA TZ の候補から選択

#### 4.3.3 操作・メッセージ

* 「保存」ボタン

  * 新規モード: `tenants.create` を実行
  * 編集モード: `tenants.update` を実行
  * 成功時メッセージ: `sysadmin.tenants.save.success`
* 「無効化」ボタン

  * 現在 `status = active` の場合のみ表示
  * 実行時に `status = inactive` に更新
  * 成功時メッセージ: `sysadmin.tenants.deactivate.success`
* 「再有効化」ボタン

  * 現在 `status = inactive` の場合のみ表示
  * 実行時に `status = active` に更新
  * 成功時メッセージ: `sysadmin.tenants.activate.success`

バリデーションエラー時は `sysadmin.tenants.error.validation` を表示する。

---

### 4.4 テナント管理者管理パネル（TenantAdminPanel）

#### 4.4.1 一覧表示

* カラム

  * メールアドレス
  * 表示名
  * 氏名
  * 最終ログイン（取得できる場合のみ）
  * 操作（編集 / 管理者解除）

#### 4.4.2 管理者登録フォーム

* 入力項目

  * メールアドレス
  * 表示名
  * 氏名
* ボタン

  * 新規モード: 「管理者ユーザ登録」
  * 編集モード: 「管理者ユーザ更新」

#### 4.4.3 登録ロジック

1. 入力されたメールアドレスで `users` テーブルを検索。
2. 見つかった場合：

   * `users.tenant_id !== selectedTenantId` の場合はエラー。

     * メッセージ: `sysadmin.tenants.admin.crossTenant`
   * `users.tenant_id === selectedTenantId` の場合：

     * 既存ユーザに `tenant_admin` ロールを付与（`user_roles` に INSERT）。
     * メッセージ: `sysadmin.tenants.admin.create.success`（既存ユーザ昇格として文言は設計書準拠）。
3. 見つからない場合：

   * Supabase Auth にユーザ作成
   * `users` に INSERT（`tenant_id = selectedTenantId`）

     * NOT NULL カラム（例: `group_code`, `residence_code`）は設計書に従ったダミー値（例: `SYSADMIN`）を設定
   * `user_roles` に `tenant_admin` ロールを付与

#### 4.4.4 編集・管理者解除ロジック

* 編集

  * 一覧行の「編集」クリックでフォームに値を読み込み、`adminFormMode = 'edit'` に設定
  * 保存時に `users.update` で `display_name` / `full_name` を更新
  * 成功時メッセージ: `sysadmin.tenants.admin.update.success`

* 管理者解除

  * 一覧行の「管理者解除」クリックで該当ユーザの `user_roles` から `tenant_admin` ロールを削除
  * `users` レコードは削除しない
  * 成功時メッセージ: `sysadmin.tenants.admin.remove.success`

---

### 4.5 system_admin 判定

* `/sys-admin/tenants` へのアクセス時、必ず system_admin かどうかをサーバ側で判定する。
* 判定は `user_roles` / `roles` を用いて行い、`role.scope = 'system_admin'` かつ `role.role_key = 'SYSTEM_ADMIN'` を満たすロールを持っている場合のみ許可する。
* 非該当の場合は 403 相当のレスポンス、またはログイン画面等へのリダイレクトを行う（既存実装パターンに合わせる）。

---

### 4.6 メッセージ仕様

I18n キーと表示文言は Sa-01 詳細設計書に従うこと。代表例のみ再掲：

* 成功系

  * `sysadmin.tenants.save.success`
  * `sysadmin.tenants.deactivate.success`
  * `sysadmin.tenants.activate.success`
  * `sysadmin.tenants.admin.create.success`
  * `sysadmin.tenants.admin.update.success`
  * `sysadmin.tenants.admin.remove.success`
* エラー系

  * `sysadmin.tenants.error.validation`
  * `sysadmin.tenants.error.code.duplicate`
  * `sysadmin.tenants.admin.crossTenant`
  * `sysadmin.tenants.error.unauthorized`
  * `sysadmin.tenants.error.internal`

I18n ファイルの追加・更新は、既存の命名規則と構造に合わせて行うこと。

---

## 5. 制約・禁止事項

* `schema.prisma` に変更を加えない（新規マイグレーション禁止）。
* 既存 t-admin / 住民向け画面の挙動を変更しない（`/sys-admin/*` 配下のみ修正対象）。
* ログインフロー（`/login` 側）の変更は行わない。
* Sa-01 詳細設計書に明記されていない仕様追加を勝手に行わない。
* 画面数・URL は **`/sys-admin/tenants` 1画面のみ** とし、新規 URL（SA-02〜SA-05 相当）を追加しない。

---

## 6. 完了条件

* Sa-01 詳細設計書 v1.2 に記載された 1 画面 3 セクション構成の仕様が `/sys-admin/tenants` に実装されていること。
* system_admin ロールを持つユーザでログインした場合のみ `/sys-admin/tenants` へアクセスできること。
* テナント一覧・詳細・管理者管理の機能が、設計書のユースケース通りに動作すること。
* `npm run lint` / `npm run test`（該当テストのみ）のエラーが 0 件であること。
* CodeAgent_Report（`/01_docs/06_品質チェック/CodeAgent_Report_WS-SA01_SysAdminTenantManagement_v1.1.md`）が作成されていること。

---

## 7. 実行手順（ローカル）

1. リポジトリ取得

   * `cd D:\Projects\HarmoNet`
   * `git pull` で最新化
2. 開発サーバ起動

   * Supabase ローカルが必要な場合は、既存手順に従って起動（`supabase start` など）
   * アプリ起動: `npm run dev`
3. 実装

   * `/sys-admin/tenants` ページと関連コンポーネントを実装・修正
   * Prisma クライアントを用いた DB アクセスロジックを実装
4. 動作確認

   * system_admin アカウントでログインし、テナント一覧〜管理者管理まで一通りの操作を確認
5. テスト・Lint

   * `npm run lint`
   * 必要に応じて `npm run test`（該当テスト）
6. CodeAgent_Report 作成

   * タスク完了後、以下フォーマットで CodeAgent_Report を作成し、指定パスに保存

---

## 8. CodeAgent_Report フォーマット

```markdown
# CodeAgent_Report WS-SA01 SysAdminTenantManagement v1.1

- Task ID: WS-SA01
- Target Branch: <作業ブランチ名>
- Agent: Windsurf
- Attempts: <試行回数>

## 1. 実装内容サマリ
- [ ] Sa-01 詳細設計書 v1.2 に基づく `/sys-admin/tenants` 画面 1 ページ実装
- [ ] テナント一覧／詳細／管理者管理のロジック実装
- [ ] system_admin 判定ロジック実装

## 2. 変更ファイル一覧
- `app/sys-admin/tenants/page.tsx`
- `src/components/sys-admin/TenantListPanel.tsx`
- `src/components/sys-admin/TenantDetailForm.tsx`
- `src/components/sys-admin/TenantAdminPanel.tsx`
- `...`（実際に変更したファイルを列挙）

## 3. テスト結果
- ESLint: OK / NG（詳細）
- 単体テスト: OK / NG（対象と結果）

## 4. 自己評価
- 機能要件充足度:  /10
- コード品質（可読性・保守性）:  /10
- UI 再現度（設計書との一致度）:  /10

総合スコア（平均）:  /10

## 5. 残課題 / メモ
- 残タスクや懸念点があれば記載
```
