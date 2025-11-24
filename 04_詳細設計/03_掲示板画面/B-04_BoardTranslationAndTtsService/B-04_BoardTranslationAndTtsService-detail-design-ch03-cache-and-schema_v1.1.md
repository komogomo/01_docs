# B-04 BoardTranslationAndTtsService 詳細設計書 ch03 キャッシュ構造・DB スキーマ設計 v1.1

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH03
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-21
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板専用 翻訳＋音声読み上げサービス B-04 BoardTranslationAndTtsService が利用する

* 翻訳キャッシュテーブル群
* それに紐づく DB スキーマ
* テナント設定・保持期間との関係

を定義する。

v1.1 では、従来の **掲示板投稿用キャッシュ** `board_post_translations` に加えて、

* **返信（コメント）用キャッシュ** `board_comment_translations`

を正式に定義し、投稿・返信の両方を翻訳キャッシュの対象とする。

---

## 3.2 対象テーブル一覧

本コンポーネントで直接利用するテーブルは以下とする。

1. `board_posts`

   * 掲示板の元投稿（原文）を保持するテーブル。
2. `board_comments`

   * 掲示板投稿に対する返信（コメント）の原文を保持するテーブル。
3. `board_post_translations`

   * 投稿本文の翻訳済みキャッシュを言語別に保持するテーブル。
4. `board_comment_translations`（本章で新規定義）

   * 返信本文の翻訳済みキャッシュを言語別に保持するテーブル。
5. `tenant_settings`

   * テナント単位の設定値を保持する JSON 設定テーブル。

`board_posts` / `board_comments` / `tenant_settings` 自体の詳細定義は DB 詳細設計書（掲示板・テナント設定）に譲り、本章では翻訳キャッシュ部分にフォーカスする。

---

## 3.3 `tenant_settings.config_json` による保持期間設定

翻訳キャッシュの保持期間は、各テナントの `tenant_settings.config_json` 内で設定する。

```jsonc
{
  "board": {
    "translation_retention_days": 90
  }
}
```

* `translation_retention_days`

  * 型: number
  * 意味: 翻訳キャッシュ（投稿＋返信）を保持する日数。
  * デフォルト値: 90 日
  * 設定可能範囲: 60〜120 日（範囲外の場合はデフォルトにフォールバック）

Supabase Edge Function により、`translation_retention_days` を超えた翻訳キャッシュレコードは定期的に削除される（ch05 参照）。

---

## 3.4 `board_post_translations`（投稿用翻訳キャッシュ）

### 3.4.1 役割

掲示板投稿（`board_posts`）の本文を、多言語に翻訳した結果をキャッシュとして格納するテーブル。

* 単位: **投稿 ID × 言語** で 1 レコード
* 想定言語: `ja`（原文）、`en`、`zh` など
* 利用箇所:

  * B-03 BoardPostForm からの新規投稿／編集時
  * B-02 BoardDetail / BoardTop での表示（翻訳済み本文の取得）

### 3.4.2 論理設計

| カラム名       | 型         | 必須  | 説明                          |
| ---------- | --------- | --- | --------------------------- |
| id         | uuid      | YES | 翻訳レコード ID（主キー）              |
| tenant_id  | uuid      | YES | テナント ID（`tenants.id`）       |
| post_id    | uuid      | YES | 投稿 ID（`board_posts.id`）     |
| lang       | text      | YES | 言語コード（`ja` / `en` / `zh` 等） |
| title      | text      | NO  | 翻訳済みタイトル                    |
| content    | text      | YES | 翻訳済み本文                      |
| created_at | timestamp | YES | 登録日時（デフォルト: now）            |
| updated_at | timestamp | YES | 更新日時（自動更新）                  |

* 主キー: `id`
* ユニーク制約: `UNIQUE (post_id, lang)`

### 3.4.3 インデックス

1. `IDX_board_post_translations_post_lang`

   * 対象: `(post_id, lang)`
   * 用途: B-02 / B-01 での投稿本文取得。
2. `IDX_board_post_translations_tenant_lang_created`

   * 対象: `(tenant_id, lang, created_at)`
   * 用途: 翻訳キャッシュ削除バッチでの範囲指定。

### 3.4.4 RLS 方針

* `board_posts` と同等の RLS ポリシーを適用する。
* 読み取り:

  * ログイン中のユーザが所属する `tenant_id` に紐づくレコードのみ参照可能。
* 書き込み:

  * B-04 TranslationAndTtsService（Route Handler / Edge Function）からのみ INSERT/UPDATE を許可。
* 具体的なポリシー SQL は DB セキュリティ設計書にて定義する。

---

## 3.5 `board_comment_translations`（返信用翻訳キャッシュ）

### 3.5.1 役割

掲示板返信（コメント）（`board_comments`）の本文を、多言語に翻訳した結果をキャッシュとして格納する新規テーブル。

* 単位: **コメント ID × 言語** で 1 レコード
* 想定言語: 投稿と同様に `ja` / `en` / `zh` 等
* 利用箇所:

  * 返信投稿時（B-02 / B-03 からのコメント投稿 API）
  * B-02 BoardDetail での返信一覧表示（翻訳済みコメントの取得）

返信にはタイトルが存在しないため、`title` カラムは持たず、`content` のみを保持する。

### 3.5.2 論理設計

| カラム名       | 型         | 必須  | 説明                           |
| ---------- | --------- | --- | ---------------------------- |
| id         | uuid      | YES | 翻訳レコード ID（主キー）               |
| tenant_id  | uuid      | YES | テナント ID（`tenants.id`）        |
| comment_id | uuid      | YES | コメント ID（`board_comments.id`） |
| lang       | text      | YES | 言語コード（`ja` / `en` / `zh` 等）  |
| content    | text      | YES | 翻訳済み本文                       |
| created_at | timestamp | YES | 登録日時（デフォルト: now）             |
| updated_at | timestamp | YES | 更新日時（自動更新）                   |

* 主キー: `id`
* ユニーク制約: `UNIQUE (comment_id, lang)`

### 3.5.3 インデックス

1. `IDX_board_comment_translations_comment_lang`

   * 対象: `(comment_id, lang)`
   * 用途: B-02 での「コメント ID＋表示言語」での翻訳取得。

2. `IDX_board_comment_translations_tenant_lang_created`

   * 対象: `(tenant_id, lang, created_at)`
   * 用途: 翻訳キャッシュ削除バッチでの範囲指定。

### 3.5.4 RLS 方針

* `board_comments` と整合する RLS ポリシーを適用する。
* 読み取り:

  * ログイン中ユーザがアクセス可能な掲示板投稿に紐づくコメントの翻訳のみ参照可能とする。
* 書き込み:

  * B-04 TranslationAndTtsService からのみ INSERT/UPDATE を許可（アプリケーション経由）。
* 具体的なポリシー SQL は DB セキュリティ設計書にて定義する。

---

## 3.6 Prisma モデル定義

Prisma の `schema.prisma` では、翻訳キャッシュテーブルを以下のように定義する。

### 3.6.1 `board_post_translations` モデル

```prisma
model board_post_translations {
  id        String   @id @default(uuid())
  tenant_id String
  post_id   String
  lang      String
  title     String?
  content   String   @db.Text

  created_at DateTime @default(now())
  updated_at DateTime @updatedAt

  tenant tenants     @relation(fields: [tenant_id], references: [id])
  post   board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)

  @@unique([post_id, lang])
  @@index([tenant_id, lang, created_at])
}
```

### 3.6.2 `board_comment_translations` モデル

```prisma
model board_comment_translations {
  id         String   @id @default(uuid())
  tenant_id  String
  comment_id String
  lang       String
  content    String   @db.Text

  created_at DateTime @default(now())
  updated_at DateTime @updatedAt

  tenant  tenants        @relation(fields: [tenant_id], references: [id])
  comment board_comments @relation(fields: [comment_id], references: [id], onDelete: Cascade)

  @@unique([comment_id, lang])
  @@index([tenant_id, lang, created_at])
}
```

### 3.6.3 逆リレーション

`tenants` / `board_posts` / `board_comments` には、以下のような逆リレーションを定義する。

```prisma
model tenants {
  // ...既存フィールド...

  board_post_translations    board_post_translations[]
  board_comment_translations board_comment_translations[]
}

model board_posts {
  // ...既存フィールド...

  translations board_post_translations[]
}

model board_comments {
  // ...既存フィールド...

  translations board_comment_translations[]
}
```

これにより、Prisma Client から

* 投稿: `prisma.board_posts.findMany({ include: { translations: true } })`
* 返信: `prisma.board_comments.findMany({ include: { translations: true } })`

といった形で翻訳キャッシュを同時取得できる。

---

## 3.7 まとめ

本章では、B-04 BoardTranslationAndTtsService が利用する翻訳キャッシュ構造として

* `board_post_translations`（投稿用）
* `board_comment_translations`（返信用）

の 2 テーブルを定義し、`tenant_settings.config_json.board.translation_retention_days` と連動させる形で設計した。

この設計により、

* 投稿／返信いずれも「原文は `board_posts` / `board_comments`、翻訳済み本文は専用キャッシュテーブル」という一貫した構造
* テナント単位でのキャッシュ保持期間制御と、バッチ削除（Edge Function）との連携

が可能となる。B-04 のフロー設計（ch04）および非機能設計（ch06）は、本章のスキーマを前提として記述される。
