# テナント管理者用ユーザ登録画面 詳細設計書 ch01（画面＋ロジック統合版） v1.3

**Document ID:** HARMONET-DD-TADMIN-USER-REGIST-CH01
**Version:** 1.3
**Screen ID:** T-01 TenantUserManagement
**Path:** `/t-admin/users`

---

## 変更履歴

| Version | 日付         | 変更内容                                                                                                   |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------ |
| 1.3     | 2025-12-05 | users スキーマの氏名分割（full_name → last_name / first_name）および `group_leader` ロール追加に合わせて、画面項目・API I/O・テスト観点を更新 |
| 1.2     | 2025-12-01 | 認証ガード導入に伴い、認証・認可ロジックの記述を更新。                                                                            |
| 1.1     | 2025-xx-xx | `/t-admin/users` の実装内容に合わせて、画面仕様・API・テーブル利用を更新                                                         |
| 1.0     | 2025-xx-xx | 初版作成                                                                                                   |

---

## 1. 画面概要

### 1.1 目的

* `tenant_admin` が、自テナントに所属する利用者（一般ユーザ／テナント管理者／班長）を登録・更新・削除する。

### 1.2 前提

* 認証は Supabase Auth（MagicLink）を利用する。fileciteturn5file12L3-L4
* 認証コールバック後、`user_tenants` をもとに有効な `tenant_id` が 1 つに確定している。fileciteturn5file12L3-L5
* 本画面にアクセスできるのは、現在テナントに対して `tenant_admin` ロールを持つユーザのみとする。fileciteturn5file12L5-L5
* 認証・認可ガードには、共通基盤（Middleware + Server Helper）を利用する。詳細は `harmonet-auth-guard-detail-design_v1.0.md` を参照。fileciteturn5file12L6-L6
* 一時停止／復活／audit／論理削除は扱わない。退会・退去・所属解除は `user_tenants`／`user_roles`／`users`／`auth.users` の **行 DELETE** で対応する。fileciteturn5file12L7-L8
* 関連テーブルは以下に限定する。

  * `tenants` … テナントマスタ
  * `users` … アプリユーザマスタ（姓・名・ふりがな・ニックネーム・住居番号等を保持）
  * `user_tenants` … ユーザ×テナント所属
  * `roles` / `user_roles` … ロール情報（`tenant_admin` / `general_user` / `group_leader`）

### 1.3 機能範囲

* 自テナントユーザ一覧表示
* フィルタ（キーワード検索）
* ユーザ登録（入力項目）fileciteturn5file12L18-L28

  * メールアドレス
  * 姓・名
  * 姓：ふりがな・名：ふりがな
  * ニックネーム
  * グループID
  * 住居番号
  * ロール（`tenant_admin` / `general_user` / `group_leader`）
  * 言語（ベース言語）
* 自テナントユーザ情報の更新
* 自テナントからのユーザ削除（他テナント所属との分岐は従来どおり）fileciteturn5file12L30-L35

### 1.4 画面遷移・入口

* 本画面 `/t-admin/users` は、ログイン後ホーム画面に表示される「テナント管理」カードから遷移する。fileciteturn5file15L22-L25
* ホーム画面の「テナント管理」カード表示条件は従来どおり `tenant_admin` ロールのみとし、本書では変更しない。fileciteturn5file15L26-L32

---

## 2. 画面構成

### 2.1 レイアウト

* PC 向け画面。`/t-admin` レイアウト配下に配置。fileciteturn5file15L40-L45
* 左: テナント管理メニュー（「テナント管理」セクションに「ユーザ管理」項目）。
* 右: 本画面コンテンツ。
* 右コンテンツは以下 3 セクションで構成する。fileciteturn5file15L48-L52

  1. SEC-01: テナント名表示エリア
  2. SEC-02: ユーザ登録・更新フォーム
  3. SEC-03: ユーザ一覧テーブル（検索・ソート・ページネーションを含む）

### 2.2 SEC-01 テナント名表示

* 要素: テナント名 `{tenant_name}` を中央に表示するテキスト。fileciteturn5file15L54-L59
* 取得元: セッションの `tenant_id` を用い `tenants` から `tenant_name` を取得し、画面に渡す。fileciteturn5file15L60-L63

### 2.3 SEC-02 ユーザ登録・更新フォーム

#### 2.3.1 フォーム項目（v1.3 修正版）

| No | UI項目ID              | ラベル     | 型      | 必須 | 備考                                               |
| -- | ------------------- | ------- | ------ | -- | ------------------------------------------------ |
| 1  | input_email         | メールアドレス | email  | ○  | ログイン用メールアドレス                                     |
| 2  | input_lastName      | 性       | text   | ○  | `users.last_name`（苗字）                            |
| 3  | input_firstName     | 名       | text   | ○  | `users.first_name`（名前）                           |
| 4  | input_lastNameKana  | 性：ふりがな  | text   | ○  | `users.last_name_kana`（苗字ふりがな）                   |
| 5  | input_firstNameKana | 名：ふりがな  | text   | ○  | `users.first_name_kana`（名前ふりがな）                  |
| 6  | input_displayName   | ニックネーム  | text   | ○  | 掲示板等での表示名                                        |
| 7  | input_groupCode     | グループID  | text   | 任意 | 任意文字列（例: 北A, 南B 等）                               |
| 8  | input_residence     | 住居番号    | text   | 任意 | 例: 101, A-1203 等                                 |
| 9  | select_role         | ロール     | select | ○  | `tenant_admin` / `general_user` / `group_leader` |
| 10 | select_language     | 言語      | select | 任意 | `ja/en/zh`。未選択時は `ja` を使用                        |

#### 2.3.2 画面上の挙動

* 新規登録モード・編集モード・メールアドレス存在チェックは v1.2 と同一で、`fullName` / `fullNameKana` を上記 4 項目に読み替える。fileciteturn5file4L14-L31

### 2.4 SEC-03 ユーザ一覧テーブル

#### 2.4.1 列定義（氏名分割に合わせて更新）

| No | 表示ラベル   | 項目ID            | 内容                                                       |   |     |   |                        |
| -- | ------- | --------------- | -------------------------------------------------------- | - | --- | - | ---------------------- |
| 1  | メールアドレス | `email`         | `users.email`                                            |   |     |   |                        |
| 2  | ニックネーム  | `displayName`   | `users.display_name`                                     |   |     |   |                        |
| 3  | 氏名      | `fullName`      | `users.last_name                                         |   | ' ' |   | users.first_name`      |
| 4  | ふりがな    | `fullNameKana`  | `users.last_name_kana                                    |   | ' ' |   | users.first_name_kana` |
| 5  | グループID  | `groupCode`     | `users.group_code`                                       |   |     |   |                        |
| 6  | 住居番号    | `residenceCode` | `users.residence_code`                                   |   |     |   |                        |
| 7  | 言語      | `language`      | `users.language` (`ja/en/zh` → JA/EN/ZH ラベル表示)           |   |     |   |                        |
| 8  | ロール     | `roleKey`       | `roles.role_key`（tenant_admin/general_user/group_leader） |   |     |   |                        |
| 9  | 操作      | `actions`       | 「編集」「削除」ボタン                                              |   |     |   |                        |

#### 2.4.2 検索・ソート・ページネーション

* 検索対象は v1.2 と同様で、氏名・ふりがなについては `last_name/first_name`・`last_name_kana/first_name_kana` を連結して扱う。fileciteturn5file14L17-L29

---

## 3. 入出力仕様

### 3.1 入力バリデーション（画面・API共通）

* 必須チェック:fileciteturn5file11L7-L10

  * メールアドレス
  * 性 (`last_name`)
  * 名 (`first_name`)
  * 性：ふりがな (`last_name_kana`)
  * 名：ふりがな (`first_name_kana`)
  * ニックネーム (`display_name`)
  * ロール (`roleKey`)
* 任意項目: グループID・住居番号・言語。言語未指定時は `"ja"` を利用。fileciteturn5file11L9-L10
* 一意性チェック（サーバ側）は v1.2 と同一（email / display_name 全テナント横断で一意）。fileciteturn5file11L12-L16

### 3.2 出力

* 正常終了時は成功メッセージ表示と一覧再読み込み。エラー時はメッセージ表示＋入力値保持（v1.2 と同一）。fileciteturn5file11L19-L22

---

## 4. API 詳細

共通事項および `/api/t-admin/users` 系 API の構造は v1.2 を踏襲し、DTO の `fullName` / `fullNameKana` を「姓・名＋ふりがな」4項目に置き換える。

### 4.1 共通事項

* Supabase Auth セッション前提、`getTenantAdminApiContext` 利用などは v1.2 の記述をそのまま継承。fileciteturn5file7L5-L15

### 4.2 ユーザ一覧取得 API

* メソッド: `GET`
* パス: `/api/t-admin/users`
* クエリ: `q=キーワード`（任意）fileciteturn5file7L19-L25

#### 4.2.1 挙動

* `user_tenants` から現在テナント所属ユーザを取得し、`users` / `user_roles` と結合して一覧 DTO を構成する。キーワード指定時は email / display_name / 姓名 / ふりがな等に部分一致フィルタを適用する。fileciteturn5file7L52-L55

#### 4.2.2 レスポンス DTO（v1.3）

```json
[
  {
    "userId": "uuid",
    "email": "string",
    "displayName": "string",
    "lastName": "string",
    "firstName": "string",
    "lastNameKana": "string",
    "firstNameKana": "string",
    "groupCode": "string|null",
    "residenceCode": "string|null",
    "roleKey": "tenant_admin|general_user|group_leader",
    "language": "ja|en|zh"
  }
]
```

### 4.3 ユーザ登録 API

* メソッド: `POST`
* パス: `/api/t-admin/users`fileciteturn5file7L53-L57

#### 4.3.1 リクエストボディ（v1.3）

```json
{
  "email": "string",
  "lastName": "string",
  "firstName": "string",
  "lastNameKana": "string",
  "firstNameKana": "string",
  "displayName": "string",
  "groupCode": "string|null",
  "residenceCode": "string|null",
  "roleKey": "tenant_admin|general_user|group_leader",
  "language": "ja|en|zh|null"
}
```

#### 4.3.2 挙動

* v1.2 の手順（メール・ニックネーム一意性チェック、`auth.users` upsert、`users` upsert、`user_roles` / `user_tenants` 登録）を踏襲し、`users` upsert のフィールドのみ以下に変更する。fileciteturn5file8L1-L8

  * `last_name = lastName`
  * `first_name = firstName`
  * `last_name_kana = lastNameKana`
  * `first_name_kana = firstNameKana`

レスポンス構造は v1.2 と同一。fileciteturn5file8L12-L19

### 4.4 ユーザ更新 API

* メソッド: `PUT`
* パス: `/api/t-admin/users`fileciteturn5file2L8-L12

#### 4.4.1 リクエストボディ（v1.3）

```json
{
  "userId": "string",
  "email": "string",
  "lastName": "string",
  "firstName": "string",
  "lastNameKana": "string",
  "firstNameKana": "string",
  "displayName": "string",
  "groupCode": "string|null",
  "residenceCode": "string|null",
  "roleKey": "tenant_admin|general_user|group_leader",
  "language": "ja|en|zh|null"
}
```

#### 4.4.2 挙動

* v1.2 の手順（必須チェック、一意性チェック、`user_tenants` 存在確認、`auth.users` 更新、`users` 更新、`user_roles` 更新）と同一で、`users` 更新の対象カラムを姓・名・ふりがな 4 項目に置き換える。fileciteturn5file2L29-L38

### 4.5 ユーザ削除 API / 4.6 メールアドレス存在チェック API

* 仕様は v1.2 から変更なし。リクエスト・レスポンス形式もそのまま。fileciteturn5file0L8-L21

---

## 5. メッセージ仕様（日本語案）

メッセージコード・文言は v1.2 と同一。`fullName` → 「氏名」表現への読み替えのみ。

fileciteturn5file5L54-L66

---

## 6. テスト観点

### 6.1 前提データ・共通前提

* `tenant_admin` ロールを現在テナントに対して持つユーザ A が存在すること。fileciteturn5file6L5-L7
* テスト用ユーザについて、`last_name` / `first_name` / `last_name_kana` / `first_name_kana` に値が入っていること。

### 6.2 認証・権限

* `/t-admin/users` へのアクセスガード仕様は v1.2 と同一。fileciteturn5file6L10-L16

### 6.3 HOME 画面からの遷移

* 「テナント管理」タイルからの遷移条件・挙動は v1.2 と同一。fileciteturn5file6L18-L25

### 6.4 ユーザ一覧表示

* 一覧の列表示が、本書 2.4.1 で定義した内容になっていること。

  * 氏名列: 姓＋名が空白区切りで表示されること。
  * ふりがな列: 姓かな＋名かなが空白区切りで表示されること。
* 既存のテスト観点（0件時メッセージ、複数件時の表示、言語ラベル、ロールラベル）は v1.2 を踏襲。fileciteturn5file6L28-L35

### 6.5 ユーザ登録・更新

* 新規登録／更新時に、姓・名・ふりがな 4 項目が必須となっていること。
* 登録・更新後、`users.last_name` / `first_name` / `last_name_kana` / `first_name_kana` に正しく保存されていること。
* 既存のテスト観点（メアド・ニックネーム一意性、キャンセル挙動など）は v1.2 を踏襲。fileciteturn5file10L7-L19

### 6.6 ロール

* ロール選択肢に `group_leader` が追加されていること。
* `group_leader` を選択して登録したユーザに対し、`roles.role_key = 'group_leader'` の `role_id` が `user_roles` に紐づいていること。

### 6.7 ユーザ削除

* v1.2 と同一（multi-tenant 所属時の分岐を含む）。fileciteturn5file3L7-L16

---
