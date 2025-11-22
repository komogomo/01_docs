# B-01 BoardTop 詳細設計書 ch03 データモデル・入出力仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH03
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板TOP画面コンポーネント BoardTop（B-01）が利用するデータモデルと入出力仕様を定義する。
DB スキーマは `schema.prisma` を唯一の正とし、本章ではその上に立つ **アプリケーション側の DTO（表示用データ構造）** と **取得条件（WHERE / ORDER / LIMIT/OFFSET）** を明文化する。

BoardTop は、掲示板投稿テーブル `board_posts` を中心に、カテゴリ `board_categories` およびテナント・ユーザ情報の一部を参照して投稿一覧を構築する。コメント・リアクション・承認履歴などは本画面では集計や表示を行わず、必要に応じて概要情報を別画面（詳細・管理画面）で扱う。

---

## 3.2 関連テーブルと関係

### 3.2.1 参照テーブル一覧

BoardTop が直接または間接的に参照するテーブルは次の通りとする。

* `board_posts`
* `board_categories`
* `tenants`
* `users`
* `board_attachments`（添付ファイル有無判定のみ）

### 3.2.2 `board_posts`（掲示板投稿）

`schema.prisma` に定義された `board_posts` は以下の通りとする（抜粋）。

```prisma
/// 掲示板投稿
model board_posts {
  id          String            @id @default(uuid())
  tenant_id   String
  category_id String
  author_id   String
  title       String
  content     String            @db.Text
  status      board_post_status @default(draft)
  created_at  DateTime          @default(now())
  updated_at  DateTime          @updatedAt

  // Relations
  tenant        tenants          @relation(fields: [tenant_id], references: [id])
  author        users            @relation(fields: [author_id], references: [id])
  category      board_categories @relation(fields: [category_id], references: [id])
  comments      board_comments[]
  reactions     board_reactions[]
  attachments   board_attachments[]
  approval_logs board_approval_logs[]
}
```

* `status` は enum `board_post_status`（`draft` / `pending` / `published` / `archived`）であり、BoardTop は **`published` のみ表示対象** とする（設計決定サマリに準拠）。
* `content` はリッチ／プレーン双方を含む本文テキストであり、BoardTop ではサマリ表示（先頭数行）にのみ利用する。

### 3.2.3 `board_categories`（掲示板カテゴリ）

```prisma
/// 掲示板カテゴリ
model board_categories {
  id            String   @id @default(uuid())
  tenant_id     String
  category_key  String
  category_name String
  display_order Int      @default(0)
  created_at    DateTime @default(now())
  updated_at    DateTime @updatedAt
  status        status   @default(active)

  // Relations
  tenant tenants       @relation(fields: [tenant_id], references: [id])
  posts  board_posts[]

  @@unique([tenant_id, category_key])
}
```

* BoardTop では、カテゴリの `category_name` をカード上のタグラベルとして表示する。
* ALL / NOTICE / RULES タブの切替は、本基本設計で定義したカテゴリ体系（例: `NOTICE`, `RULES` など）と `category_key` の対応により実現する（マッピングは ch04/ch05 で定義）。

### 3.2.4 `users`（投稿者情報）

```prisma
model users {
  id           String   @id @default(uuid())
  tenant_id    String?
  email        String   @unique
  display_name String
  language     String   @default("ja")
  created_at   DateTime @default(now())
  updated_at   DateTime @updatedAt
  status       status   @default(active)

  // Relations
  board_posts     board_posts[]
  board_comments  board_comments[]
  board_reactions board_reactions[]
  board_approval_logs board_approval_logs[]
  ...
}
```

* BoardTop では、`display_name` を直接表示せず、「投稿者種別」（管理組合 / 一般利用者 等）を示すための判定に利用する想定とする。
  実際の種別ラベルへの変換ロジックは、ユーザロール情報と組み合わせた共通ロジック（認証・ロール管理側）で定義し、本章では詳細を扱わない。

### 3.2.5 `board_attachments`（添付ファイル）

```prisma
/// 添付ファイル（PDFプレビュー対応）
model board_attachments {
  id         String   @id @default(uuid())
  tenant_id  String
  post_id    String
  file_url   String
  file_name  String
  file_type  String
  file_size  Int
  created_at DateTime @default(now())

  // Relations
  tenant tenants     @relation(fields: [tenant_id], references: [id])
  post   board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)
}
```

* BoardTop では、`post_id` 単位に **添付ファイルが 1 件以上存在するかどうか** のみを判定し、カード上に「クリップアイコン」を表示するトリガとして利用する。
* 添付ファイルの詳細（ファイル名・サイズ・PDF プレビュー）は、詳細画面（B-02）側で扱う。

---

## 3.3 BoardTop 表示用 DTO 定義

### 3.3.1 一覧行 DTO（`BoardPostSummary`）

BoardTop が UI レイヤに渡す 1 投稿分の表示用データ構造を、論理 DTO として以下のように定義する。

```ts
// BoardTop 一覧用サマリ DTO（フロントエンド内部型のイメージ）
export type BoardPostSummary = {
  id: string;                 // board_posts.id
  tenantId: string;           // board_posts.tenant_id
  categoryId: string;         // board_posts.category_id
  categoryKey: string;        // board_categories.category_key
  categoryName: string;       // board_categories.category_name
  title: string;              // board_posts.title
  contentPreview: string;     // board_posts.content から生成したサマリ（2〜3行）
  authorId: string;           // board_posts.author_id
  authorDisplayType: string;  // "管理組合" / "一般利用者" 等（ロール情報から導出）
  createdAt: string;          // ISO 文字列 or Date（表示フォーマットは UI 仕様で定義）
  hasAttachment: boolean;     // board_attachments.exist(post_id)
  status: "published";        // board_posts.status（BoardTop では published のみ）
  // ロール・権限関連（閲覧時点のコンテキスト）
  viewerRole: "admin" | "user"; // 現在の閲覧者ロール（テナント管理者=管理組合 or 一般利用者）
  canPost: boolean;           // 現在の閲覧者が新規投稿権限を持つかどうか
  // 将来拡張用フィールド
  isPinned?: boolean;         // 重要投稿フラグ（UI ソートに利用）
  isCirculation?: boolean;    // 回覧板フラグ（既読管理対象かどうか）
  circulationStatus?: "unread" | "read"; // ユーザ別既読状態（MVPでは未実装可）
};
```

* `contentPreview` は本文の冒頭から一定文字数（例: 80〜120 文字程度）を抽出し、改行をスペースに変換したうえで省略記号 `…` を付与するルールとする（具体値は ch05 で定義）。
* `authorDisplayType` は、`users` とロール情報を元に変換するが、BoardTop の責務は「ラベルを受け取って表示する」こととし、変換ロジックは別コンポーネント／フックで実装する想定とする。

### 3.3.2 一覧レスポンス DTO（`BoardPostSummaryPage`）

ページングされた一覧レスポンス全体は、次のような構造を想定する。

```ts
export type BoardPostSummaryPage = {
  items: BoardPostSummary[]; // 1ページ分の投稿サマリ
  totalCount: number;        // 検索条件に合致する全件数
  page: number;              // 現在ページ番号（1 起算）
  perPage: number;           // 1ページあたり件数
};
```

BoardTopPage は、この DTO をもとに `BoardPostSummaryList` および `BoardPagination` に必要な情報を渡す。

---

## 3.4 入力条件（フィルタ・タブ・範囲）と DB 条件の対応

BoardTop の一覧取得は、以下の入力条件を受け取り、`board_posts` への検索条件に変換する。
viewerRole および canPost は UI 制御・ログ出力に利用し、DB の WHERE 条件には直接は使用しない。

### 3.4.1 入力パラメータ（論理レベル）

```ts
export type BoardTopQueryInput = {
  tenantId: string;                // 認証コンテキストから取得
  userId: string;                  // 認証コンテキストから取得
  viewerRole: "admin" | "user";   // 管理組合 or 一般利用者（認証・ロール管理から取得）
  canPost: boolean;                // 新規投稿権限（管理組合ロール等から導出済み）
  tab: "all" | "notice" | "rules"; // URL クエリ tab
  scope: "all" | "global" | "group"; // URL クエリ scope
  page: number;                    // URL クエリ page（1 以上）
  perPage: number;                 // URL クエリ perPage（10 / 20 / 50）
};
```

### 3.4.2 基本 WHERE 条件

すべてのクエリに共通する WHERE 条件は次の通りとする。

* `tenant_id = :tenantId`
* `status = 'published'`

これにより、

* 他テナントの投稿
* `draft` / `pending` / `archived` の投稿

は BoardTop からは一切見えない。

### 3.4.3 タブ（ALL / NOTICE / RULES）による絞り込み

タブとカテゴリの対応は、`board_categories.category_key` および掲示板設計決定サマリで定義されたカテゴリ体系に依存する。初版では次のような方針とする。

* `tab = "all"` の場合

  * 追加のカテゴリ絞り込みは行わず、すべてのカテゴリを対象とする。
* `tab = "notice"` の場合

  * 管理組合からのお知らせカテゴリに限定する。
  * 具体的な条件例: `category_key IN ('NOTICE')`（複数キーになる場合は別途定義）。
* `tab = "rules"` の場合

  * 規約・ルールカテゴリに限定する。
  * 条件例: `category_key IN ('RULES')`。

実際のカテゴリキー一覧とマッピングは、掲示板カテゴリマスタ設計および BoardPostForm 詳細設計と整合させる必要があるため、ch04/ch05 で最終確定とする。

### 3.4.4 範囲（scope）による絞り込み

`scope` は、タブとは独立した「GLOBAL / GROUP 表示範囲」の切り替えであり、`board_categories`（将来的には `category_type`）または別テーブルによって表現される。初版の論理仕様は次の通りとする。

* `scope = "all"`

  * GLOBAL + ユーザ所属グループの投稿をすべて表示する（ALL タブの全体像を把握しやすくするための標準）。
* `scope = "global"`

  * GLOBAL 向けカテゴリのみを対象とする。
* `scope = "group"`

  * ユーザが所属するグループ向け投稿のみを対象とする。

実際の SQL 条件は、

* `board_categories` に `category_type` が導入された場合:

  * `category_type = 'GLOBAL'` / `category_type = 'GROUP'`
* もしくはカテゴリキー命名規則に基づくプレフィックス判定（`'NORTH-A'` 等）

などで実現する。DB 実装詳細は掲示板カテゴリ設計および RLS 設計側で扱い、本章では「BoardTop が scope に応じて GLOBAL / GROUP を切り替える」という論理仕様のみを定義する。

---

## 3.5 ソート・ページング仕様（DB レベル）

### 3.5.1 ORDER BY

BoardTop のソート順は、掲示板基本設計 ch03 で定義された以下の優先順位に従う。

1. ピン留め（重要投稿）
2. 投稿日時（新しい順）

ただし現行スキーマ `board_posts` には `is_pinned` や `pinned_at` カラムが存在しないため、次のように扱う。

* 現時点（スキーマ追加前）の実装:

  * `ORDER BY created_at DESC`
* 将来 `pinned_at` などが追加された場合:

  * `ORDER BY (pinned_at IS NOT NULL) DESC, pinned_at DESC NULLS LAST, created_at DESC`

本章では、スキーマに存在しないカラムを前提とした仕様は確定させない。ピン留め機能を実装する際は、DB 差分設計（GPT-DB-Standard）に従って `board_posts` 拡張を行い、本章を v1.1 以降で更新する。

### 3.5.2 LIMIT / OFFSET

ページングは次の式で算出する。

* `LIMIT :perPage`
* `OFFSET (:page - 1) * :perPage`

`perPage` は 10 / 20 / 50 のいずれかとし、URL クエリの値を検証したうえで設定する。
`page` は 1 以上の整数とし、不正値の場合は 1 に丸める（ch02/ch04 で定義済み）。

### 3.5.3 `totalCount` 取得

ページネーション UI に総ページ数を表示するため、`totalCount` を次のように取得する。

* `SELECT COUNT(*) FROM board_posts ...`
  （WHERE 条件は一覧取得と同一。ただし LIMIT/OFFSET は付与しない）

フロントエンドでは、

* `totalPage = ceil(totalCount / perPage)`

を計算し、`BoardPagination` へ渡す。

---

## 3.6 エラー・空状態時のデータ仕様

### 3.6.1 空状態

* 取得クエリが正常終了し `items.length = 0` の場合、`totalCount = 0` とする。
* BoardTopPage は `items.length === 0 && !isError` のときに `BoardEmptyState` を表示する。

### 3.6.2 エラー状態

* DB / ネットワークエラーなどで一覧取得に失敗した場合、DTO 生成は行わず、

  * `items = []`
  * `totalCount = 0`
  * `isError = true`

といったステータスフラグを状態管理側で持つ。
エラー内容の詳細（HTTP ステータスなど）は、ロギング／デバッグ用として保持しつつ、UI には共通メッセージ仕様に従った汎用的なエラーメッセージのみを表示する（文言は ch05 で定義）。

---

## 3.7 今後の拡張余地（データモデル観点）

本章 v1.0 では、BoardTop の MVP 実装に必要な最小限のデータモデルと入出力仕様のみを定義した。今後の拡張候補として、次のような項目を想定する。

1. ピン留め機能用カラムの追加

   * `board_posts` に `is_pinned` / `pinned_at` を追加し、基本設計 ch03 のソート方針と整合させる。
2. 回覧板既読管理との連携

   * 既読状態を BoardTop のカード上に簡易表示する場合、既読テーブル（別途設計）との JOIN or サブクエリを検討する。
3. 検索・高度フィルタ

   * タイトル・本文のキーワード検索、期間絞り込み、カテゴリ複数選択などを実現するためのインデックス設計や WHERE 条件の追加。

これらを実装する際は、先に DB 差分設計（GPT-DB-Standard）と掲示板基本設計を更新し、その後本章のバージョンを 1.1 以降に引き上げて整合させる。
