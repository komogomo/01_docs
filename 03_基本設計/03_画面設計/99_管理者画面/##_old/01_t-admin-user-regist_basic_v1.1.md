# テナント管理者用ユーザ登録画面 基本設計書 v1.1

**Document ID:** HARMONET-BD-TADMIN-USER-REGIST
**Version:** 1.1
**Screen ID:** T-01 TenantUserManagement
**Path:** `/t-admin/users`

---

## 1. 目的・スコープ

### 1.1 目的

本画面は、テナント管理者（`tenant_admin`）およびシステム管理者（`system_admin`）が、
HarmoNet における「テナント所属ユーザ」を管理するための入口となる画面である。

* 新規テナント立ち上げ時に、`system_admin` が最初の `tenant_admin` を登録する。
* 運用フェーズでは、`tenant_admin` が自テナントに一般ユーザ／追加管理者を登録・削除（所属解除）する。

### 1.2 スコープ

本基本設計書の対象は以下とする。

* 画面: `/t-admin/users`

  * 現在操作中テナント名表示
  * 自テナント所属ユーザ一覧表示
  * 自テナントへの新規ユーザ登録
  * 自テナントからの所属解除（削除ボタン）
* 対応テーブル（DB論理モデル）

  * `tenants`
  * `public.users`
  * `public.user_tenants`

以下は本書のスコープ外とし、別途設計する。

* 掲示板・他機能の画面設計
* 完全退会（`auth.users` / `public.users` / `user_tenants` / `tenant_residents` の全削除）
* ロール詳細設計（`user_roles`）
* RLS ポリシーの SQL 詳細（別途 RLS 設計書にて定義）

### 1.3 前提

* 認証は Supabase Auth（MagicLink）で行う。
* ログイン後、認証コールバックで `user_tenants` をもとに「現在の `tenant_id`」が確定している。
* **認証・認可ガードには、共通基盤（Middleware + Server Helper）を利用する。**
  * Middleware (`proxy.ts`) による一次ガードで、未認証・未認可ユーザをリダイレクトする。
  * Server Helper (`tenantAdminAuth.ts`) による二次ガードで、API や Server Component 内での厳密な権限チェックを行う。
* 一時停止／復活／論理削除は行わない。

  * 退去・退会・所属解除が必要な場合は **行 DELETE** で対応する。
* Prisma Migrate の migration ファイルは使用しない。

  * スキーマ変更は `schema.prisma` を直接編集し、`npx prisma db push` でDBに反映する。

---

## 2. ロールと利用者像

### 2.1 ロール定義（概要）

* `system_admin`

  * 全テナントに対する管理権限を持つ。
  * 新規テナントの立ち上げ時に、最初の `tenant_admin` を登録する。
* `tenant_admin`

  * 自テナントに対する管理権限を持つ。
  * 自テナントのユーザ登録／所属解除を `/t-admin/users` 画面で行う。
* `general_user`

  * 一般利用者。`/t-admin` 配下の画面は利用不可。

### 2.2 /t-admin/users の利用者

* メイン利用者: `tenant_admin`

  * 自テナント内の住民／管理担当を登録する。
* サポート利用者: `system_admin`

  * 初期テナント立ち上げ時に最初の `tenant_admin` を登録する。
  * 将来的に、全テナント横断の確認・補正用途で利用する可能性はあるが、本書では `tenant_admin` 利用を主とする。

---

## 3. 画面構成

### 3.1 レイアウト

* レイアウト前提

  * PC での利用を主対象とする（スマートフォンは想定しない）。
  * 左側に `/t-admin` 共通ナビゲーション（今後拡張予定）。
  * 右側のメインエリアに `/t-admin/users` のコンテンツを表示。

* `/t-admin/users` メインエリア構成

  1. 画面タイトル＋テナント名

     * タイトル: 「テナントユーザ管理」
     * サブテキスト: 現在操作中のテナント名

       * 例: `セキュレアシティ学園の森 A街区 管理画面`
  2. ユーザ一覧

     * 自テナントに所属しているユーザを一覧表示
     * キーワード検索（email / display_name）
  3. ユーザ登録フォーム

     * email / display_name / language の入力欄
     * [ユーザ登録] ボタン
  4. メッセージ表示領域

     * 登録成功／削除成功／エラー等のメッセージを表示

### 3.2 テナント名の表示仕様

* 画面上部に「現在操作中テナント名」を必ず表示する。

* 取得方法:

  * ログイン後のセッションから `tenant_id` を取得
  * API または server component 内で `tenants` を参照
  * `tenant_name` を表示

* `tenant_admin` の場合:

  * テナント選択 UI は表示しない（自テナント固定）。

* `system_admin` の場合（将来拡張）:

  * 画面右上などにテナント選択プルダウンを追加し、選択中テナント名を表示する想定。

---

## 4. ユーザ一覧機能

### 4.1 表示対象

* 自テナントに所属しているユーザのみを表示する。
* ベースとなるテーブル:

  * `user_tenants` … 自テナントの所属レコード
  * `users` … ユーザ情報本体
  * `tenants` … テナント名表示用（自テナントのみ）

### 4.2 一覧カラム案

| 表示項目    | 内容                                  | 取得元            |
| ------- | ----------------------------------- | -------------- |
| メールアドレス | `users.email`                       | `users`        |
| 表示名     | `users.display_name`                | `users`        |
| 言語      | `users.language` (`ja/en/zh`をラベル表示) | `users`        |
| 所属テナント  | 現在のテナント名（固定）                        | `tenants`      |
| 最終掲示板閲覧 | `user_tenants.board_last_seen_at`   | `user_tenants` |
| 削除操作    | 「削除」ボタン（所属解除）                       | -              |

* ソート: デフォルトは `users.email` 昇順（後で変更可能）。
* フィルタ: 画面上部にキーワード検索欄（メール／表示名を部分一致）。

### 4.3 バックエンド取得ロジック（概要）

* 入力: セッション上の `user_id`, `tenant_id`

* 処理:

  1. `user_tenants` から `tenant_id = セッションの tenant_id` の行を取得
  2. そこから `user_id` を抽出
  3. `users` から `id IN (抽出した user_id)` のレコードを取得
  4. `user_tenants.board_last_seen_at` を JOIN して一覧用データを構築

* 出力: 一覧表示用のユーザ配列

---

## 5. ユーザ登録機能

### 5.1 画面上の入力項目

| 項目名     | 必須 | 型 / 制約                    | 保存先                               |
| ------- | -- | ------------------------- | --------------------------------- |
| メールアドレス | 必須 | email形式, 255文字以内          | `auth.users.email`, `users.email` |
| 表示名     | 必須 | 255文字以内                   | `users.display_name`              |
| 言語      | 任意 | 固定候補（`ja`, `en`, `zh` など） | `users.language`                  |

* テナント選択項目はフォームには表示しない。

  * `tenant_admin`: セッションの `tenant_id` を使用。
  * `system_admin` の場合は将来的にテナント選択 UI を追加するが、本書では範囲外。

### 5.2 バリデーション（概要）

* メールアドレス

  * 必須
  * email形式（`@` を含む、一般的な形式チェック）
  * 255文字以内
* 表示名

  * 必須
  * 255文字以内
* 言語

  * 未入力時は `ja` をデフォルトとする
  * 許容値: `ja`, `en`, `zh` など（DB側は varchar(5)）

### 5.3 登録フロー（バックエンド）

1. 入力検証
2. Supabase `auth.users` の確認

   * `email` で既存ユーザを検索
   * 存在しない場合: 新規 `auth.users` レコードを作成（MagicLink用ユーザ）
   * 存在する場合: 既存 `auth.users.id` を再利用
3. `public.users` の upsert

   * `id = auth.users.id` をキーとして upsert
   * `email`, `display_name`, `language` を保存/更新
4. `public.user_tenants` の upsert

   * 主キー: `(user_id, tenant_id)`
   * `user_id = users.id`
   * `tenant_id = セッションの tenant_id`
   * 既に所属がある場合は何もしない（エラーにしない）
5. 一覧の再取得

   * 登録後にユーザ一覧を再取得し、画面に反映する。

### 5.4 正常時メッセージ（案）

* ユーザ登録成功時: 「ユーザを登録しました。」
* 既存ユーザに自テナント所属だけ追加した場合も同じメッセージでよい（区別しない）。

---

## 6. 所属解除（削除）機能

### 6.1 削除の意味

* `/t-admin/users` の「削除」ボタンは、

  * **自テナントからの所属解除** を意味する。
* 完全退会（`auth.users` / `public.users` / `user_tenants` / `tenant_residents` の全削除）は、

  * `system_admin` 用の別画面・別オペレーションで扱う前提とし、本書では対象外とする。

### 6.2 処理概要

1. 対象ユーザの `user_id` を受け取る。
2. `public.user_tenants` から、

  * `user_id = 対象ユーザ` AND `tenant_id = セッションの tenant_id`
    のレコードを DELETE。
3. 削除後、同ユーザが他テナントに所属している場合は `users` レコードは残る。
4. 一覧を再取得し、画面から当該ユーザ行を除外する。

### 6.3 メッセージ（案）

* 所属解除成功時: 「ユーザをテナントから削除しました。」

---

## 7. RLS・認可（概要）

RLS の SQL 詳細は別途 RLS設計書で定義する。本書では方針のみ記載する。

**アプリケーション層でのガード（Middleware + Server Helper）を主とし、RLS は補助的な役割とする。**

### 7.1 tenants

* `tenant_admin`:

  * 自テナント (`tenant_id = セッションの tenant_id`) のみ `SELECT` 可能。
* `system_admin`:

  * 全テナントを `SELECT` 可能。
* 一般ユーザ:`/t-admin` 画面にはアクセス不可（UI／ルーティングで遮断）。

### 7.2 users

* `tenant_admin`:

  * 自テナントに所属する `user_tenants` 経由で `users` を参照する。
  * 直接 `users` をフルスキャンすることはさせない。
* `system_admin`:

  * 管理画面用 API 経由で `users` を参照可能。

### 7.3 user_tenants

* 一般ユーザ:

  * `auth.uid() = user_id` の行のみ `SELECT` 可能。
* `tenant_admin`:

  * `tenant_id = セッションの tenant_id` の全ユーザに対して `SELECT/INSERT/DELETE` 可能。
* `system_admin`:

  * 全テナントに対して `SELECT` 可能。

---

## 8. ユーザ削除（完全退会）との関係

* 本画面は「自テナントからの所属解除」を扱うに留める。
* 完全退会（アカウント自体の削除）は、今後 `system_admin` 用の上位管理画面で以下を行う前提とする。

  * `user_tenants`（全テナント分）DELETE
  * `tenant_residents`（あれば）DELETE
  * `public.users` DELETE
  * `auth.users` DELETE
* 完全退会の設計は別文書で定義する。

---

## 9. 変更履歴

| Version | 日付       | 変更内容                                                                 |
| ------- | ---------- | ------------------------------------------------------------------------ |
| 1.1     | 2025-12-01 | 認証ガード導入に伴い、認証・認可方針を更新。                             |
| 1.0     | 2025-xx-xx | 初版作成。                                                               |
