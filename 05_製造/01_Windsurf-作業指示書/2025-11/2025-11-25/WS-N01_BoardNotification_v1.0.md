# WS-N01 BoardNotification 実装修正指示書 v1.0

## 1. ゴール / 概要

* 管理組合ロールによる掲示板投稿が公開された際に、テナント利用者へ「新着お知らせ」を通知できるようにする。
* 通知チャネルは以下 3 つとし、すべて同じイベント（管理組合投稿の published）をトリガとする。

  * HOME 画面のお知らせ表示（未読フラグ）
  * AppHeader のベルアイコン＋未読バッジ
  * メール通知（テナント利用者宛）
* Supabase Realtime は使用せず、「DB＋API＋メール」で完結させる。

CodeAgent_Report 保存先：

* `/01_docs/06_品質チェック/CodeAgent_Report_WS-N01_BoardNotification_v1.0.md`

---

## 2. スコープ

### 2.1 対象

* リポジトリ：`D:/Projects/HarmoNet`
* 対象機能：掲示板通知（BoardNotification）
* 対象箇所（想定パス）：

  * DB スキーマ：`schema.prisma`（`user_tenants` または `users`）
  * API ルート：

    * `app/api/board/notifications/has-unread/route.ts`（新規）
    * `app/api/board/notifications/mark-seen/route.ts`（新規）
  * フロントエンド：

    * AppHeader コンポーネント（ベルアイコン＋バッジ表示部）
    * HOME 画面コンポーネント（新着お知らせ表示部）
  * メール送信：

    * 掲示板投稿の作成処理（既存 API or server action 内にフックを追加）

### 2.2 非スコープ

* 管理組合投稿ワークフロー（複数承認 → published）は別 WS（B-11）で扱う。
* 通知対象の細かいフィルタ（特定カテゴリだけ通知など）は本 WS では実装しない。
* Web プッシュ通知 / モバイルアプリ通知は範囲外。
* Supabase Realtime を用いたリアルタイム更新は範囲外。

---

## 3. 前提条件 / 定義

### 3.1 通知対象イベント

* 通知対象は **管理組合ロールによる掲示板投稿** のうち、以下条件を満たすものとする：

  * `board_posts.status = 'published'`
  * 投稿者が管理組合ロール（詳細なロール判定は既存実装に合わせる）
* 将来ワークフローが導入された場合も、**最終的に `status = 'published'` になったタイミング**を通知トリガとする。

### 3.2 未読フラグの定義

* 各ユーザに対して「掲示板通知の最終既読時刻」を持つ。
* あるユーザについて、

  * `last_seen_board_notification_at` より後に、
  * 同一テナント内で条件を満たす管理組合 `published` 投稿が 1 件以上存在する場合、
  * そのユーザには「未読の掲示板お知らせがある」とみなす。

---

## 4. DB 変更

### 4.1 カラム追加

* 対象テーブルは **`user_tenants`** とする（ユーザ×テナント単位で既読管理できるようにするため）。
* `schema.prisma` に以下カラムを追加する：

```prisma
model user_tenants {
  // 既存フィールドは省略

  last_seen_board_notification_at DateTime? @db.Timestamptz(6)
}
```

* Prisma マイグレーション（ローカル Supabase 用）を追加し、`supabase` ローカル環境に適用すること。
* 既存レコードの初期値は `NULL` とし、`NULL` は「まだ一度もお知らせを開いていない」と解釈する。

---

## 5. サーバロジック / API

### 5.1 未読有無チェック API

* 新規エンドポイント：`GET /api/board/notifications/has-unread`
* 役割：

  * 現在ログイン中のユーザについて、「未読のお知らせが 1 件以上あるか」を判定し、`hasUnread: boolean` を返す。

#### 5.1.1 処理フロー

1. Supabase Auth から現在ユーザを取得（未ログインなら 401）。
2. `user_tenants` から、そのユーザの **現在のテナント** のレコードを 1 件取得する。

   * HarmoNet 内での「現在テナント」の取得方法は既存実装に合わせる（例：middleware で `tenant_id` をコンテキストに持っている場合、それを利用）。
3. `last_seen_board_notification_at` を変数 `lastSeen` に保持（`NULL` なら「過去なし」として扱う）。
4. Prisma または Supabase を用いて、以下条件を満たす `board_posts` の存在を確認する：

   * `tenant_id` = 現在テナント
   * `status = 'published'`
   * 投稿者が管理組合ロール（ロール判定は既存ロジックに合わせる）
   * かつ、`created_at > lastSeen` または `lastSeen IS NULL`
5. 1 件でも存在すれば `hasUnread = true`、なければ `false`。
6. JSON レスポンス：

```json
{
  "hasUnread": true
}
```

### 5.2 既読マーク API

* 新規エンドポイント：`POST /api/board/notifications/mark-seen`
* 役割：

  * 現在テナントに対する掲示板通知を「既読」にし、以降の未読判定の基準時刻を更新する。

#### 5.2.1 処理フロー

1. Supabase Auth から現在ユーザとテナントを取得（未ログインなら 401）。
2. `user_tenants` の該当行（`user_id`＋`tenant_id`）を UPDATE：

   * `last_seen_board_notification_at = now()`（UTC）
3. 成功時は 204 No Content または `{ ok: true }` を返す。

---

## 6. フロントエンド実装

### 6.1 AppHeader（ベルアイコン＋バッジ）

* 対象：AppHeader コンポーネント（既存のヘッダーメニューにベルアイコンを追加）。

#### 6.1.1 UI 仕様

* アイコン：Lucide `Bell` を使用。
* 配置：ヘッダー右側のアイコン群に追加。
* 未読がある場合：

  * ベルの右上に小さな赤丸バッジを表示し、中に `!` またはドットを表示。
  * 文言は不要。ARIA ラベルで「新しいお知らせがあります」を付与する。
* 未読がない場合：

  * バッジは表示しない。

#### 6.1.2 挙動

* コンポーネントマウント時に `GET /api/board/notifications/has-unread` を 1 回だけ呼び、`hasUnread` を state に保持する。
* ヘッダーのベルアイコンをクリックしたとき：

  * MVP では `/board` に遷移するだけで良い。
  * `/board` に遷移したタイミングで `mark-seen` API を呼ぶ（詳細は 6.2）。

### 6.2 HOME 画面（新着お知らせ表示）

* HOME 画面でも同じ `hasUnread` 情報を利用する。

#### 6.2.1 UI 仕様（MVP）

* HOME の「お知らせ」もしくは「機能メニュー」付近に、次のような表示を追加：

  * 未読あり：

    * 「新しいお知らせがあります」
    * 小さなバッジやアイコンで強調（HarmoNet のUIトーンに合わせて控えめに）
  * 未読なし：

    * なにも表示しないか、「新しいお知らせはありません」のどちらか（現行デザインに合わせてよい）。
* 文言は i18n 対応する（JA/EN/ZH）。

#### 6.2.2 挙動

* HOME もヘッダーと同じ `hasUnread` を参照する。

  * 実装的には、共通フック or React Query / SWR などで `hasUnread` を共有してもよい。
* ユーザが HOME から `/board` へ遷移した場合も、`mark-seen` API を呼ぶことで既読扱いとする。

### 6.3 既読マークのトリガ

* 既読マーク（`mark-seen`）は以下タイミングのいずれかで呼び出す：

  * `/board` の BoardTop 画面がマウントされたとき
  * もしくは、ユーザが明示的に「お知らせを開く」UI（将来導入）を操作したとき
* MVP では **BoardTop のマウント時に一度だけ `mark-seen` を呼ぶ**実装でよい。

---

## 7. メール通知

### 7.1 送信タイミング

* 管理組合ロールのユーザが掲示板投稿を行い、その投稿が `status = 'published'` になったタイミングでメール通知を送信する。
* 現状のフローで「published 状態」に遷移する箇所（API or server action）にフックを追加する。

### 7.2 宛先

* 対象テナントの `user_tenants` で `status = 'active'` のユーザすべて（MVP）。
* 将来、ユーザごとの「メール通知 ON/OFF」を導入する場合は、そのフラグでさらにフィルタできるようにしておく（本 WS では実装不要）。

### 7.3 メール内容（最小）

* 件名（日本語例）：

  * `【HarmoNet】管理組合から新しいお知らせが投稿されました`
* 本文（日本語例）：

  * 冒頭挨拶（固定文）
  * 掲示板タイトル
  * カテゴリ
  * 投稿日時
  * HarmoNet へのリンク（例：`https://<tenant-domain>/board/<postId>`）
* 英語・中国語対応は、将来の i18n メールテンプレ導入時に拡張する前提とし、本 WS では日本語テンプレートのみでもよい。

### 7.4 実装方針

* 既存のメール送信ユーティリティがあればそれを利用する。
* なければ、Nonfunctional 要件・技術スタックで採用済みのメール送信手段に従う（例：SMTP / 外部メールサービスの SDK）。
* 1 投稿につき 1 回、ループで各ユーザへ送信する実装で良い（キューやバッチ処理は将来拡張）。

---

## 8. テスト / 受け入れ条件

### 8.1 手動確認シナリオ

1. 管理組合ユーザでログインし、新規掲示板投稿（`status = published`）を行う。

   * 同テナントの一般ユーザ宛てにメールが届くこと。
2. 一般ユーザでログインし、HOME とヘッダーを確認。

   * ベルアイコンに赤バッジが表示されること。
   * HOME に「新しいお知らせがあります」表示が出ること。
3. 一般ユーザが `/board` を開く。

   * `POST /api/board/notifications/mark-seen` が呼ばれること（Network タブで確認）。
   * 以降、ヘッダーのバッジと HOME の未読表示が消えること。
4. もう一度管理組合ユーザが新しい投稿を行い、同様に通知が再度動作すること。

### 8.2 自動テスト（あれば）

* API 単位で最低限のテストを追加してもよい：

  * `has-unread` が条件通り true/false を返すこと。
  * `mark-seen` が `last_seen_board_notification_at` を更新すること。

### 8.3 受け入れ条件

* 未読があるときだけ、ヘッダーのベルに赤バッジが表示されること。
* `/board` を開いた後は、未読がない限りバッジが表示されないこと。
* 管理組合投稿時に、対象テナントのユーザへメール通知が送信されること（ローカル環境ではログ出力でも可）。
* 既存の掲示板機能（投稿／返信／削除／翻訳／TTS／添付／お気に入り）に影響がないことを確認すること。
* CodeAgent_Report を `/01_docs/06_品質チェック/CodeAgent_Report_WS-N01_BoardNotification_v1.0.md` に作成し、対象ファイルとテスト結果を記載すること。
