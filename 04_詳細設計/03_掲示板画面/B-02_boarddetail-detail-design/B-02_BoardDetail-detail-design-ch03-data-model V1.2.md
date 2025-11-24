# B-02 BoardDetail 詳細設計書 ch03 データモデル・入出力仕様 v1.2

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH03
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板詳細画面コンポーネント **BoardDetail（B-02）** が利用する **データモデル** と **入出力仕様** を定義する。
DB スキーマは `schema.prisma` を唯一の正とし、その上に立つフロントエンド側の DTO（画面表示用データ構造）と、投稿本文・コメント・添付・翻訳/TTS キャッシュ取得の条件を明文化する。

BoardDetail は単一投稿の詳細表示画面であり、BoardTop（一覧）よりも広いデータ範囲（コメント・添付・翻訳/TTS 状態など）を扱う。
**投稿・表示名モード・ロール判定・回覧板関連などの業務的な意味付けは、B-03 BoardPostForm 詳細設計 v1.1 系列を「正」とし、その仕様に従う。**

また、掲示板投稿およびコメントは、BoardPostForm（B-03）およびコメント投稿 API 内で **AI モデレーション処理を経た上で `board_posts` / `board_comments` に保存される** 前提とする。
BoardDetail は、保存済み（必要に応じてマスク済み）のデータのみを取得・表示し、モデレーション結果そのもの（スコアや判定理由）は参照しない。

---

## 3.2 関連テーブルと関係

### 3.2.1 参照テーブル一覧

BoardDetail が直接または間接的に参照する主なテーブルは次の通りとする。

* `board_posts`（掲示板投稿本体）
* `board_categories`（カテゴリ情報）
* `board_comments`（コメント）
* `board_attachments`（添付ファイル）
* 翻訳/TTS キャッシュ関連テーブル（命名は `schema.prisma` の定義に従う）
* `users`（投稿者・コメント投稿者情報）

これらのテーブル・カラム定義はすべて `schema.prisma` を参照し、本章では「BoardDetail がどのような目的でどの項目を使用するか」のみを記載する。新たなテーブル・カラムを提案することはしない。

AI モデレーションの結果（allow / block など）は `moderation_logs` テーブルに記録されるが、本章の DTO・取得条件では直接扱わない。
`board_posts` / `board_comments` に保存されているデータは、すでにモデレーションの対象となり、保存可と判断された内容であることを前提とする。

### 3.2.2 `board_posts`（掲示板投稿）

投稿本体は `board_posts` に格納される。本文（`content`）は全文表示に利用し、`status` は `published` のみ表示対象とする前提は BoardTop と同一とする。

BoardDetail では、BoardTop よりも詳細なメタ情報（回覧板種別、既読状態など）を UI に反映するが、取得するカラムは `schema.prisma` に存在する項目のみとし、B-03 BoardPostForm が前提としている項目に整合する範囲で DTO に含める。

### 3.2.3 `board_comments`（コメント）

コメントテーブルの定義は `schema.prisma` に従う。本章では論理的な構造のみ整理する。

* 主なカラム（論理イメージ）

  * `id`: コメント ID
  * `tenant_id`: テナント ID
  * `post_id`: コメント対象の投稿 ID（`board_posts.id`）
  * `author_id`: コメント投稿者ユーザ ID（`users.id`）
  * `content`: コメント本文
  * `parent_comment_id`: 親コメント ID（スレッド化する場合に使用）
  * `created_at`: 作成日時
  * `updated_at`: 更新日時

BoardDetail では、指定された投稿 ID に紐づくコメントをすべて取得し、表示順や表示形式のみを画面側で制御する。
コメントの公開／非公開や不適切表現のブロックは、BoardPostForm 側の AI モデレーションおよび API の判定に委ねる。

### 3.2.4 `board_attachments`（添付ファイル）

添付ファイルは `board_attachments` を利用する。

* 主なカラム（論理イメージ）

  * `id`: 添付 ID
  * `tenant_id`: テナント ID
  * `post_id`: 紐付く投稿 ID
  * `file_url`: Supabase Storage 等へのファイル URL
  * `file_name`: ファイル名
  * `file_type`: MIME タイプ（例: `application/pdf`）
  * `file_size`: バイト数

BoardDetail では、添付一覧表示と PDF プレビューのためにこれらを取得し、UI 用 DTO に変換する。

### 3.2.5 翻訳/TTS キャッシュ関連テーブル

翻訳結果および TTS キャッシュを保存するテーブルは、掲示板共通翻訳/TTS 設計および `schema.prisma` に従う。
本章ではテーブル名・カラム名を直接は固定せず、論理的に「投稿 ID + 言語コード + 翻訳テキスト/TTS 状態」を保持する構造として扱う。BoardDetail は、これら共通テーブルを経由した結果 DTO を受け取り、翻訳表示・TTS 状態表示を行う。

---

## 3.3 BoardDetail 表示用 DTO 定義

BoardDetail では、一度の画面表示で「投稿本体」「添付」「コメント」「翻訳/TTS 状態」「閲覧者ロール」をまとめて扱うため、複数の DTO に分割する。
**ロール・表示名モードに関する列挙値やラベルは、B-03 BoardPostForm 詳細設計および認証・ロール管理共通仕様で定義されたものを再利用し、本章で独自定義しない。**

### 3.3.1 投稿詳細 DTO（`BoardPostDetail`）

```ts
export type BoardPostDetail = {
  id: string;                  // board_posts.id
  tenantId: string;            // board_posts.tenant_id
  categoryId: string;          // board_posts.category_id
  categoryKey: string;         // board_categories.category_key
  categoryName: string;        // board_categories.category_name
  title: string;               // board_posts.title
  content: string;             // board_posts.content（本文フルテキスト）

  authorId: string;            // board_posts.author_id
  authorDisplayName: string;   // 表示名モード適用後の名前（B-03 仕様に従う）
  authorDisplayType: string;   // 管理組合 / 一般利用者 等のラベル（B-03 仕様に従う）
  displayNameMode: string;     // 実名 / ニックネーム / 匿名 など（具体値は B-03 定義を参照）

  createdAt: string;           // 投稿日時（ISO 文字列）
  updatedAt: string;           // 更新日時（ISO 文字列）
  status: "published";        // 表示対象は published のみ

  // 回覧板関連（必要に応じて利用する）
  isCirculation?: boolean;     // 回覧板対象かどうか
  circulationStatus?: string;  // 現在ユーザの既読状態（具体値は回覧板仕様を参照）
};
```

`authorDisplayName` / `authorDisplayType` / `displayNameMode` の具体的な決定ロジックは B-03（投稿フォーム側）の仕様で定義し、BoardDetail はそれを参照して同じ表現となるようにする。

### 3.3.2 添付 DTO（`BoardAttachmentItem`）

```ts
export type BoardAttachmentItem = {
  id: string;        // board_attachments.id
  fileName: string;  // board_attachments.file_name
  fileUrl: string;   // board_attachments.file_url
  fileType: string;  // board_attachments.file_type（例: application/pdf）
  fileSize: number;  // board_attachments.file_size
};
```

### 3.3.3 コメント DTO（`BoardCommentItem`）

```ts
export type BoardCommentItem = {
  id: string;                // board_comments.id
  authorId: string;          // board_comments.author_id
  authorDisplayName: string; // コメント投稿者の表示名（B-03 と共通ルール）
  authorDisplayType: string; // 管理組合 / 一般利用者 など（B-03 と共通ルール）
  content: string;           // コメント本文
  createdAt: string;         // 作成日時（ISO 文字列）
};
```

コメントの順序は「作成日時の昇順（古い順）」を基本とし、必要に応じて UI 仕様（ch05）で別途変更可能とする。

### 3.3.4 翻訳/TTS 状態 DTO（`BoardPostI18nState`）

```ts
export type BoardPostI18nState = {
  // 言語コンテキスト
  baseLanguage: string;       // 原文の言語コード（例: "ja"）
  targetLanguage: string;     // 現在表示中の言語コード（例: "ja" / "en" / "zh"）

  // 翻訳
  hasTranslation: boolean;    // 翻訳結果がキャッシュ済みかどうか
  translatedText?: string;    // 翻訳済み本文
  isTranslating: boolean;     // 翻訳処理中フラグ
  translationError?: string;  // 翻訳エラー時の簡易エラーコード or メッセージ

  // TTS
  isTtsAvailable: boolean;    // TTS 対応言語かどうか
  isTtsPlaying: boolean;      // 再生中フラグ
  isTtsLoading: boolean;      // 音声生成中フラグ
  ttsError?: string;          // TTS エラー情報（簡易）
};
```

実際の翻訳/TTS 呼び出し処理は共通コンポーネント・フック側で扱い、BoardDetail はこの状態 DTO をもとに UI を制御するだけとする。

### 3.3.5 画面全体のレスポンス DTO（`BoardDetailPageData`）

```ts
export type BoardDetailPageData = {
  post: BoardPostDetail;               // 投稿本体
  attachments: BoardAttachmentItem[];  // 添付一覧
  comments: BoardCommentItem[];        // コメント一覧
  i18nState: BoardPostI18nState;       // 翻訳/TTS 状態

  viewerRole: string;                  // 現在の閲覧者ロール（具体値はロール管理仕様に従う）
  canPostComment: boolean;             // コメント投稿権限
};
```

`viewerRole` は認証・ロール管理層で定義された列挙値（例: 管理組合 / 一般利用者 等）をそのまま利用する。BoardDetail 側で新しいロール種別を定義しない。

---

## 3.4 入力条件と DB 条件の対応

### 3.4.1 入力パラメータ（論理レベル）

```ts
export type BoardDetailQueryInput = {
  tenantId: string;   // 認証コンテキストから取得
  userId: string;     // 認証コンテキストから取得
  viewerRole: string; // 管理組合 / 一般利用者 等（ロール管理から取得）
  postId: string;     // URL パラメータ [postId]
};
```

`tenantId` / `userId` / `viewerRole` はアプリ共通の認証・ロール管理コンテキストから取得し、BoardDetail 独自の判定ロジックは持たない。

### 3.4.2 投稿本体の取得条件

* WHERE 条件（論理）

  * `tenant_id = :tenantId`
  * `id = :postId`
  * `status = 'published'`

権限制御は RLS およびバックエンドロジックで担保される前提とし、BoardDetail 側は「行が取得できなかった場合」をエラー状態として扱う。

### 3.4.3 コメント一覧の取得条件

* WHERE 条件（論理）

  * `tenant_id = :tenantId`
  * `post_id = :postId`
  * `status = 'active'

コメントの公開／非公開や不適切表現のブロックは、BoardPostForm 側の AI モデレーションおよび API 判定に委ねる。
BoardDetail は、取得されたコメントをそのまま表示対象とする（UI 上の並び順のみ制御）。

### 3.4.4 添付一覧の取得条件

* WHERE 条件

  * `tenant_id = :tenantId`
  * `post_id = :postId`

ORDER BY は `created_at ASC` を基本とし、UI 上の要件に応じて `file_name ASC` などに変更する場合は本章を更新する。

### 3.4.5 翻訳/TTS キャッシュの取得条件

* WHERE 条件（論理）

  * `post_id = :postId`
  * `target_language = :targetLanguage`

BoardDetail は、現在表示中の言語に対する翻訳/TTS キャッシュを取得し、存在しない場合は「未翻訳」「未生成」として扱う。実際のテーブル名・カラム名は `schema.prisma` に従う。

---

## 3.5 エラー・権限不足時のデータ仕様

### 3.5.1 投稿が存在しない場合

* 条件

  * 指定 `postId` に対する `board_posts` レコードが存在しない、または RLS により取得不可となる。
* BoardDetail 側の扱い

  * データ取得レイヤから `NotFound` または `Forbidden` 等のエラー種別を受け取り、UI 上では「投稿が見つからない」または「閲覧権限がありません」のようなエラーメッセージを表示する（文言は ch05 で定義）。
  * DTO `BoardDetailPageData` は生成せず、状態管理側で `isError = true` かつ `errorType` を保持する前提とする。

### 3.5.2 コメント・添付のみ一部取得失敗した場合

* 原則として、投稿本体の取得に失敗した場合は「画面全体をエラー扱い」とし、コメントや添付だけが部分的に失敗するケースは異常系とみなす。
* 実装では、投稿本体 + コメント + 添付 + 翻訳/TTS を 1 つの API または 1 セットの呼び出しとして扱い、いずれかが致命的に失敗した場合は画面全体をエラー状態とする方針とする。

---

## 3.6 データモデル変更時の取り扱い

掲示板機能のデータモデル（`schema.prisma`）に変更が入る場合は、必ず次の順序で整合を取る。

1. 先に DB 差分設計および掲示板基本設計（board-design-ch0x 系）を更新する。
2. B-03 BoardPostForm 詳細設計を最新仕様に合わせて更新する。
3. その上で、本章（B-02 ch03）に反映すべき項目を洗い出し、DTO・条件式・エラー仕様を更新する。

本章 v1.2 は、現時点の `schema.prisma` と B-03 BoardPostForm 詳細設計 v1.1 系列、および B-03 ch08 AI モデレーション仕様に整合する形で定義されている。
データモデル変更時は、本章のバージョンを 1.3 以降に引き上げて差分を明示する。
