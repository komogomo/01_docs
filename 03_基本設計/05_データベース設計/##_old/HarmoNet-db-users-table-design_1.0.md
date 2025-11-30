# HarmoNet DB 設計書: public.users テーブル定義 v1.1

## 1. 目的

HarmoNet アプリにおける **居住者（世帯）ユーザ情報** を一元管理するためのテーブル定義を示す。

前提:

* ドメインは「分譲マンション／大規模住宅街」の管理組合アプリ。
* **1アカウント = 1世帯 = 1住戸**。
* ユーザの属性はすべて `public.users` から参照する（board / home / t-admin など全画面共通）。
* 認証は Supabase `auth.users` を利用し、`auth.users.id = public.users.id` が 1:1 となる。

## 2. 設計方針

1. ユーザ属性は原則として **`public.users` の単一テーブルに集約** する。
2. ロールは `public.roles` および `public.user_roles` で管理し、`public.users` はロールを持たない。
3. 型・桁数・NULL 可否は、ドメイン要件および現実的な利用シナリオに基づいて決定する。

## 3. テーブル定義: public.users

### 3.1 テーブル概要

* テーブル名: `public.users`
* 役割: 住民（世帯）ユーザの属性を管理する中核テーブル。
* 関連: `auth.users` と 1:1 で対応し、ID を共有する。

### 3.2 制約定義

* **PK**: `(id)`
* **FK1**: `tenant_id → public.tenants.id`
* **UK1**: `(email)`
* **IDX1**: `(tenant_id)`

### 3.3 カラム定義

| カラム名           | 型           | 桁数  | NULL可    | 説明                                              |
| -------------- | ----------- | --- | -------- | ----------------------------------------------- |
| id             | uuid        | 36  | NOT NULL | ユーザID。`auth.users.id` と 1:1 で対応する主キー。           |
| tenant_id      | uuid        | 36  | NOT NULL | テナントID。`public.tenants.id` への外部キー。1ユーザ=1テナント前提。 |
| email          | varchar     | 255 | NOT NULL | メールアドレス。アカウント識別用。UK1 で一意。                       |
| display_name   | varchar     | 32  | NOT NULL | アプリ上の表示名（ニックネーム）。例: 「山田家」「山田太郎」。                |
| full_name      | varchar     | 32  | NOT NULL | 正式氏名。全角16文字相当。                                  |
| full_name_kana | varchar     | 32  | NULL     | 氏名ヨミ。不要な場合は NULL。                               |
| group_code     | varchar     | 8   | NOT NULL | グループコード（街区/棟など）。例: `N-A`, `S-01`。               |
| residence_code | varchar     | 8   | NOT NULL | 住戸番号。例: `101`, `1205A`。                         |
| phone_number   | varchar     | 16  | NULL     | 電話番号。E.164 形式想定（最大 15 桁＋先頭 `+`）。                |
| language       | char        | 2   | NOT NULL | UI 表示言語コード。`'JA'`, `'EN'`, `'ZH'`。              |
| note           | varchar     | 200 | NULL     | 備考。ユーザに関する補足情報を記載する。                            |
| created_at     | timestamptz | —   | NOT NULL | 登録日時。`DEFAULT now()`。                           |
| updated_at     | timestamptz | —   | NOT NULL | 更新日時。                                           |

---

本テーブルをユーザ属性の唯一の正とし、ユーザ属性の追加は原則として `public.users` に対して行う。
