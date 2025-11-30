# テナント管理者用ユーザ登録画面 詳細設計書 ch01（画面＋ロジック統合版） v1.0

**Document ID:** HARMONET-DD-TADMIN-USER-REGIST-CH01
**Version:** 1.0
**Screen ID:** T-01 TenantUserManagement
**Path:** `/t-admin/users`

本書は、テナント管理者用ユーザ登録画面 `/t-admin/users` の画面仕様・入出力・ロジック・API・メッセージ・テスト観点について記載する。

---

## 1. 画面概要

### 1.1 目的

* `tenant_admin` が、自テナントに所属する利用者（一般ユーザ／管理担当）を登録・所属解除する。
* `system_admin` が、新規テナント立ち上げ時に最初の `tenant_admin` を登録する。

### 1.2 前提

* 認証は Supabase Auth（MagicLink）。
* 認証コールバック後、`user_tenants` をもとに `tenant_id` が 1つに確定済みである。
* 一時停止／復活／audit／論理削除は扱わない。退会・退去・所属解除は **行 DELETE** で対応する。
* 関連テーブルは以下に限定する。

  * `tenants` … テナントマスタ
  * `users` … アプリユーザマスタ
  * `user_tenants` … ユーザ×テナント所属
  * `tenant_residents` … 住民情報（氏名・ふりがな・住居番号・グループID）
  * `roles` / `user_roles` … ロール情報（tenant_admin / general_user 等）

### 1.3 機能範囲

* 自テナントユーザ一覧表示
* フィルタ（キーワード検索）
* ユーザ登録

  * メールアドレス
  * 氏名・ふりがな
  * ニックネーム
  * グループID
  * 住居番号
  * ロール
  * 言語（ベース言語）

* 自テナントからのユーザ削除

  * 当該ユーザが複数テナント（複数物件）に紐づいている場合  
    → 本画面では「自テナントからの削除（所属解除）」のみを行い、  
      他テナントに関する情報は残す。
  * 当該ユーザが本テナントにのみ紐づいている場合  
    → 本画面からの削除操作により、**削除対象ユーザIDに紐づく**以下のレコードをすべて削除する。  
      - `auth.users`  
      - `users`  
      - `user_tenants`  
      - `user_roles`  
      - `tenant_residents`（当該テナント分）

### 1.4 画面遷移・入口

* 本画面 `/t-admin/users` は、ログイン後ホーム画面に表示される
  「テナント管理」カードから遷移する。
* ホーム画面の「テナント管理」カード仕様:
  * 表示ラベル: 「テナント管理」
  * 遷移先パス: `/t-admin/users`
  * 表示条件:
    * ログインユーザが、現在選択中テナントに対して
      `tenant_admin` ロールを持つ場合のみ表示する。
    * `tenant_admin` ロールを持たないユーザにはカードを表示しない。

---

## 2. 画面構成

### 2.1 レイアウト

* PC 専用画面。左に `/t-admin` 共通メニュー、右に本画面コンテンツ。
* 右コンテンツは以下の 3 セクションで構成する。

1. SEC-01: ヘッダエリア

   * タイトル: 「テナントユーザ管理」
   * 現在テナント名表示
2. SEC-02: ユーザ登録フォーム
3. SEC-03: ユーザ一覧テーブル

### 2.2 SEC-01 ヘッダ

* 要素:

  * 見出し: `テナントユーザ管理`
  * サブテキスト: `現在のテナント: {tenant_name}`
* 取得元:

  * セッションの `tenant_id` を用い `tenants` から `tenant_name` を取得。

### 2.3 SEC-02 ユーザ登録フォーム

| No | UI項目ID          | ラベル     | 型      | 必須 | 備考                                |
| -- | --------------- | ------- | ------ | -- | --------------------------------- |
| 1  | input_email     | メールアドレス | text   | ○  | ログイン用メールアドレス                      |
| 2  | input_realName  | 氏名      | text   | ○  | 住民氏名（フルネーム）                       |
| 3  | input_realKana  | ふりがな    | text   | ○  | 氏名のふりがな（全角かな）                     |
| 4  | input_display   | ニックネーム  | text   | ○  | 掲示板等での表示名                         |
| 5  | input_groupId   | グループID  | text   | 任意 | 任意文字列（例: 北A, 南B 等）                |
| 6  | input_residence | 住居番号    | text   | 任意 | 例: 101, A-1203 等                  |
| 7  | select_role     | ロール     | select | ○  | `tenant_admin` / `general_user` 等 |
| 8  | select_language | 言語      | select | 任意 | `ja/en/zh`。未選択時は `ja`             |
| 9  | button_submit   | ユーザ登録   | button | -  | クリックで登録処理実行                       |

### 2.4 SEC-03 ユーザ一覧テーブル

| No | 表示ラベル   | 項目ID            | 内容                                          |
| -- | ------- | --------------- | ------------------------------------------- |
| 1  | メールアドレス | `email`         | `users.email`                               |
| 2  | ニックネーム  | `displayName`   | `users.display_name`                        |
| 3  | ロール     | `roleKey`       | `roles.role_key`（tenant_admin/general_user） |
| 4  | ユーザ氏名   | `realName`      | `tenant_residents.real_name`                |
| 5  | ふりがな    | `realNameKana`  | `tenant_residents.real_name_kana`           |
| 6  | グループID  | `groupId`       | `tenant_residents.group_id`                 |
| 7  | 住居番号    | `residenceCode` | `tenant_residents.residence_code`           |
| 8  | 削除      | `actions`       | 「削除」ボタン。クリックで自テナントからの所属解除                   |

* 一覧からの **編集**（ユーザ情報の更新）は本画面の対象外とし、「表示のみ」とする。
* 削除は「自テナントからの所属解除」のみ行う。

---

## 3. 入出力仕様

### 3.1 入力バリデーション

#### 3.1.1 メールアドレス

* 必須（空文字・null は不可）
* 最大長: 255 文字
* 形式チェック: 簡易正規表現 `^[^@\s]+@[^@\s]+\.[^@\s]+$`
* 禁止文字: 制御文字・スペース・全角スペース

#### 3.1.2 氏名 / ふりがな / ニックネーム

* 氏名 (`realName`): 1〜255 文字、前後空白トリム。
* ふりがな (`realNameKana`): 1〜255 文字、全角かなのみ（漢字・カナ混在は NG）。
* ニックネーム (`displayName`): 1〜255 文字、絵文字不可（一般的なマルチバイト文字は許容）。

#### 3.1.3 グループID / 住居番号

* 任意入力。
* 最大長: 64 文字程度（DB側 varchar(64) を想定）。

#### 3.1.4 ロール

* 必須。許可値は `tenant_admin`, `general_user` など `roles.role_key` に存在する値のみ。

#### 3.1.5 言語

* 任意。未指定の場合は `"ja"` に補完。
* 許可値: `"ja"`, `"en"`, `"zh"`。

### 3.2 出力

* 正常終了時は、画面上部のメッセージ領域に成功メッセージを表示し、ユーザ一覧を再読み込みする。
* エラー時は、エラー種別に応じたメッセージを表示し、入力値を保持したままにする。

---

## 4. API 詳細

### 4.1 共通事項

* すべての API は Supabase Auth のセッションを前提とする。
* セッションが取得できない場合は 401 を返し、フロント側でログイン画面に誘導する。

### 4.2 ユーザ登録 API

* メソッド: `POST`
* パス: `/api/t-admin/users`

#### 4.2.1 リクエストボディ（JSON）

```json
{
  "email": "string",
  "realName": "string",
  "realNameKana": "string",
  "displayName": "string",
  "groupId": "string|null",
  "residenceCode": "string|null",
  "roleKey": "tenant_admin|general_user",
  "language": "ja|en|zh|null"
}
```

#### 4.2.2 挙動

1. セッション確認

   * `auth.getUser()` 等で `user` を取得。存在しない場合は 401 を返す。
2. tenant_id 取得

   * 認証コールバックで確定済みの `tenant_id` を取得。
3. 入力バリデーション

   * 3章のルールに従ってサーバ側でも検証。NG の場合は `400 VALIDATION_ERROR` を返す。
4. `auth.users` 確認

   * Supabase Admin クライアントで該当 email のユーザを検索。
   * 存在しない場合は新規作成（MagicLink 用）。
5. `users` upsert

   * `id = authUser.id` で upsert。
   * `email`, `display_name`, `language` を保存/更新。
6. `tenant_residents` upsert

   * `(tenant_id, residence_code)` などの一意制約ルールに従い upsert。
   * `real_name`, `real_name_kana`, `group_id`, `residence_code`, `user_id` を保存/更新。
7. `user_roles` upsert

   * `(user_id, tenant_id, role_id)` をユニークとしてロールを付与。
8. `user_tenants` upsert

   * `(user_id, tenant_id)` を PK として upsert。既存の場合は何もしない。

#### 4.2.3 レスポンス

* 成功時 (200):

```json
{
  "ok": true,
  "message": "ユーザを登録しました。"
}
```

* バリデーションエラー時 (400):

```json
{
  "ok": false,
  "errorCode": "VALIDATION_ERROR",
  "message": "入力内容を確認してください。"
}
```

* 内部エラー時 (500):

```json
{
  "ok": false,
  "errorCode": "INTERNAL_ERROR",
  "message": "サーバーエラーが発生しました。"
}
```

---

### 4.3 ユーザ一覧取得 API

* メソッド: `GET`
* パス: `/api/t-admin/users`
* クエリパラメータ: `?q=キーワード`（任意）

#### 4.3.1 挙動

1. セッション・tenant_id を取得。
2. `user_tenants` から `tenant_id` 一致の行を取得。
3. `users` / `tenant_residents` / `user_roles` を JOIN して一覧 DTO を構成。
4. `q` が指定されている場合、email / display_name / real_name に対して部分一致フィルタ。

#### 4.3.2 レスポンス

```json
[
  {
    "userId": "uuid",
    "email": "string",
    "displayName": "string",
    "realName": "string",
    "realNameKana": "string",
    "groupId": "string|null",
    "residenceCode": "string|null",
    "roleKey": "tenant_admin|general_user",
    "language": "ja|en|zh",
    "boardLastSeenAt": "2025-11-27T09:00:00Z|null"
  }
]
```

---

### 4.4 ユーザ所属解除（削除） API

* メソッド: `DELETE`
* パス: `/api/t-admin/users`

#### 4.4.1 リクエストボディ

```json
{
  "userId": "<users.id>"
}
```

#### 4.4.2 挙動

* `tenant_admin`:

  * セッションの `tenant_id` を取得。
  * `DELETE FROM user_tenants WHERE user_id = :userId AND tenant_id = :tenantId;` を実行。
  * 対象行が 0 件でもエラーにしない（冪等）。
* `system_admin`:

  * SEC-01 で選択中のテナント `tenantId`（将来拡張）を使用し、同様に `user_tenants` を削除。

#### 4.4.3 レスポンス

```json
{
  "ok": true,
  "message": "ユーザをテナントから削除しました。"
}
```

---

## 5. メッセージ仕様（日本語案）

### 5.1 成功メッセージ

| コード                           | 文言                |
| ----------------------------- | ----------------- |
| `tadmin.users.create.success` | ユーザを登録しました。       |
| `tadmin.users.delete.success` | ユーザを削除しました。       |

### 5.2 エラーメッセージ

| コード                                 | 文言                   |
| ----------------------------------- | -------------------- |
| `tadmin.users.error.validation`     | 入力内容を確認してください。       |
| `tadmin.users.error.email.required` | メールアドレスを入力してください。    |
| `tadmin.users.error.email.format`   | メールアドレスの形式が正しくありません。 |
| `tadmin.users.error.name.required`  | 氏名と表示名を入力してください。     |
| `tadmin.users.error.unauthorized`   | 再度ログインし直してください。      |
| `tadmin.users.error.internal`       | サーバーエラーが発生しました。      |

---

## 6. テスト観点

### 6.1 前提

- メールアドレス `admin@gmail.com` に対して、現在テナント向けに `tenant_admin` ロールが付与されていること。
- `/t-admin/users` 画面の動作確認、および HOME 画面の「テナント管理」カード表示確認は、
  すべて `admin@gmail.com` でログインして実施する。
- 既存運用ユーザはテストに使用しない。
  本テストでは、以下のテスト用ユーザのみを対象とする。

  - 本テナント専用テストユーザ: `test-delete-1@example.com`

### 6.2 HOME からの遷移確認

1. `admin@gmail.com` でログインする。
   - HOME に「テナント管理」カードが表示されていること。
   - カード押下で `/t-admin/users` 画面が表示されること。
2. `tenant_admin` ロールを持たないテストユーザ（例: `test-general-01@example.com`）でログインする。
   - HOME に「テナント管理」カードが表示されていないこと。

### 6.3 ユーザ登録・削除とログイン可否

1. `admin@gmail.com` で `/t-admin/users` を開き、`test-delete-1@example.com` を画面から登録する。
   - 必須項目を入力し、登録ボタン押下。
   - 正常終了メッセージが表示され、一覧に `test-delete-1@example.com` が表示されること。
2. 別ブラウザ（またはシークレットウィンドウ）で、`test-delete-1@example.com` 宛ての MagicLink を使用してログインできることを確認する。
3. 再度 `admin@gmail.com` で `/t-admin/users` を開き、`test-delete-1@example.com` を画面から削除する。
   - 削除操作後、一覧から当該ユーザが消えていること。
4. 再度 `test-delete-1@example.com` で MagicLink ログインを試みる。
   - ログインできないこと（ユーザ不在）を確認する。
5. DB 確認:
   - `auth.users` / `users` / `user_tenants` / `user_roles` / `tenant_residents` に、
     `test-delete-1@example.com` に対応するユーザIDのレコードが **1件も存在しない** こと。
