# B-02 BoardDetail 詳細設計書 ch03 データモデル・入出力仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH03
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板詳細画面コンポーネント BoardDetail（B-02）が利用する **データモデル** と **入出力仕様** を定義する。
DB スキーマは `schema.prisma` を唯一の正とし、その上に立つフロントエンド側の DTO（画面表示用データ構造）と、投稿本文・コメント・添付・翻訳/TTS キャッシュ取得の条件を明文化する。

BoardDetail は単一投稿の詳細表示画面であるため、BoardTop（一覧）よりも広いデータ範囲（コメント・添付・翻訳/TTS 状態など）を扱う。

---

## 3.2 関連テーブルと関係

### 3.2.1 参照テーブル一覧

BoardDetail が直接または間接的に参照する主なテーブルは次の通りとする。

* `board_posts`（掲示板投稿本体）
* `board_categories`（カテゴリ情報）
* `board_comments`（コメント）
* `board_attachments`（添付ファイル）
* 翻訳/TTS キャッシュ関連テーブル（命名は schema.prisma の定義に従う）
* `users`（投稿者・コメント投稿者情報）

### 3.2.2 `board_posts`（掲示板投稿）

BoardTop と同様に、投稿本体は `board_posts` に格納される。本文（`content`）は全文表示に利用し、`status` は `published` のみ表示対象とする前提は BoardTop と同一である。

BoardDetail では、BoardTop よりも詳細なメタ情報（回覧板ステータス、承認履歴の一部など）を表示する可能性があるが、DB から取得するカラムは `schema.prisma` に従い、必要な範囲のみを DTO に含める。

### 3.2.3 `board_comments`（コメント）

コメントテーブルの定義は `schema.prisma` に従う。ここでは論理的な構造のみ整理する。

* 主なカラム（イメージ）

  * `id`: コメントID
  * `tenant_id`: テナントID
  * `post_id`: コメント対象の投稿ID（`board_posts.id`）
  * `author_id`: コメント投稿者ユーザID（`users.id`）
  * `content`: コメント本文
  * `created_at`: 作成日時
  * `status`: 表示状態（active / hidden 等）

BoardDetail では、`post_id = :postId` かつ `status = active` のコメントのみを表示対象とする。

### 3.2.4 `board_attachments`（添付ファイル）

添付ファイルの定義は BoardTop と同じく `board_attachments` を利用する。

* 主なカラム（再掲）

  * `id`: 添付ID
  * `tenant_id`: テナントID
  * `post_id`: 紐付く投稿ID
  * `file_url`: Supabase Storage 等へのファイル URL
  * `file_name`: ファイル名
  * `file_type`: MIME タイプ（例: `application/pdf`）
  * `file_size`: バイト数

BoardDetail では、添付一覧表示と PDF プレビューのためにこれらを取得し、UI 用 DTO に変換する。

### 3.2.5 翻訳/TTS キャッシュ関連テーブル

翻訳結果および TTS キャッシュを保存するテーブルは、掲示板共通翻訳/TTS 設計および `schema.prisma` に従う。
本章ではテーブル名・カラム名を直接は固定せず、論理的に「投稿ID + 言語コード + 翻訳テキスト/TTS 状態」を保持する構造として扱う。
BoardDetail は、これら共通テーブルを経由した結果 DTO を受け取り、翻訳表示・TTS 状態表示を行う。

---

## 3.3 BoardDetail 表示用 DTO 定義

BoardDetail では、一度の画面表示で「投稿本体」「添付」「コメント」「翻訳/TTS 状態」をまとめて扱うため、複数の DTO に分割する。

### 3.3.1 投稿詳細 DTO（`BoardPostDetail`）

```ts
export type BoardPostDetail = {
  id: string;                 // board_posts.id
  tenantId: string;           // board_posts.tenant_id
  categoryId: string;         // board_posts.category_id
  categoryKey: string;        // board_categories.category_key
  categoryName: string;       // board_categories.category_name
  title: string;              // board_posts.title
  content: string;            // board_posts.content（本文フルテキスト）
  authorId: string;           // board_posts.author_id
  authorDisplayType: string;  // "管理組合" / "一般利用者" 等（ロール情報から導出）
  createdAt: string;          // 投稿日時
  updatedAt: string;          // 更新日時
  status: "published";       // 表示対象は published のみ
  // 既読・回覧板関連（必要に応じて拡張）
  isCirculation?: boolean;    // 回覧板対象かどうか
  circulationStatus?: "unread" | "read"; // 現在ユーザの既読状態
};
```

### 3.3.2 添付 DTO（`BoardAttachmentItem`）

```ts
export type BoardAttachmentItem = {
  id: string;         // board_attachments.id
  fileName: string;   // board_attachments.file_name
  fileUrl: string;    // board_attachments.file_url
  fileType: string;   // board_attachments.file_type（例: application/pdf）
  fileSize: number;   // board_attachments.file_size
};
```

### 3.3.3 コメント DTO（`BoardCommentItem`）

```ts
export type BoardCommentItem = {
  id: string;                // board_comments.id
  authorId: string;          // board_comments.author_id
  authorDisplayName: string; // コメント投稿者の表示名
  authorDisplayType: string; // 管理組合 / 一般利用者 など
  content: string;           // コメント本文
  createdAt: string;         // 作成日時
};
```

コメントの順序は「作成日時の昇順（古い順）」または「降順（新しい順）」のどちらかを別途 UI 仕様で定義する。初版ではシンプルに「古い順」を想定し、必要に応じて変更する。

### 3.3.4 翻訳/TTS 状態 DTO（`BoardPostI18nState`）

```ts
export type BoardPostI18nState = {
  // 言語コンテキスト
  baseLanguage: string;      // 原文の言語コード（例: "ja"）
  targetLanguage: string;    // 現在表示中の言語コード（例: "ja" / "en" / "zh"）

  // 翻訳
  hasTranslation: boolean;   // 翻訳結果がキャッシュ済みかどうか
  translatedText?: string;   // 翻訳済み本文
  isTranslating: boolean;    // 翻訳処理中フラグ
  translationError?: string; // 翻訳エラー時の簡易エラーコード or メッセージ

  // TTS
  isTtsAvailable: boolean;   // TTS 対応言語かどうか
  isTtsPlaying: boolean;     // 再生中フラグ
  isTtsLoading: boolean;     // 音声生成中フラグ
  ttsError?: string;         // TTS エラー情報（簡易）
};
```

実際の翻訳/TTS 呼び出し処理は共通コンポーネント側で扱うため、BoardDetail はこの状態 DTO をもとに UI を制御する。

### 3.3.5 画面全体のレスポンス DTO（`BoardDetailPageData`）

```ts
export type BoardDetailPageData = {
  post: BoardPostDetail;                // 投稿本体
  attachments: BoardAttachmentItem[];   // 添付一覧
  comments: BoardCommentItem[];         // コメント一覧
  i18nState: BoardPostI18nState;        // 翻訳/TTS 状態
  viewerRole: "admin" | "user";      // 現在の閲覧者ロール
  canPostComment: boolean;             // コメント投稿権限
};
```

`viewerRole` / `canPostComment` は認証・ロール管理層で判定済みの値を受け取り、BoardDetail はそれに従って UI（コメント入力欄の表示など）を制御するだけとする。

---

## 3.4 入力条件と DB 条件の対応

### 3.4.1 入力パラメータ（論理レベル）

```ts
export type BoardDetailQueryInput = {
  tenantId: string;                // 認証コンテキストから取得
  userId: string;                  // 認証コンテキストから取得
  viewerRole: "admin" | "user"; // 管理組合 or 一般利用者（認証・ロール管理から取得）
  postId: string;                  // URL パラメータ [postId]
};
```

### 3.4.2 投稿本体の取得条件

* 基本 WHERE 条件

  * `tenant_id = :tenantId`
  * `id = :postId`
  * `status = 'published'`（非公開やドラフトは BoardDetail からは見えない）

権限制御については、RLS およびバックエンドロジックで担保される前提とし、BoardDetail 側は「取得できなかった場合（行が存在しない場合）」をエラー状態として扱う。

### 3.4.3 コメント一覧の取得条件

* WHERE 条件（論理）

  * `tenant_id = :tenantId`
  * `post_id = :postId`
  * `status = 'active'`（非表示コメントは除外）
* ORDER BY

  * 初版: `created_at ASC`（古い順）

### 3.4.4 添付一覧の取得条件

* WHERE 条件

  * `tenant_id = :tenantId`
  * `post_id = :postId`

ORDER BY は特に指定せず、`created_at ASC` または `file_name ASC` のいずれかを選択する。UI 上の必要に応じて、添付順序を固定する場合は本章を更新する。

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

  * データ取得レイヤから「NotFound」または「Forbidden」などのエラー種別を受け取り、

    * UI 上では「投稿が見つからない」または「閲覧権限がありません」のようなエラーメッセージを表示する（文言は ch05 で定義）。
  * DTO `BoardDetailPageData` は生成せず、状態管理側で `isError = true` かつ `errorType` を保持する前提とする。

### 3.5.2 コメント・添付のみ一部取得失敗した場合

* 原則として、投稿本体の取得に失敗した場合は「画面全体をエラー扱い」とし、コメントや添付だけが失敗するケースは異常系とみなす。
* 開発時の実装では、

  * 投稿本体 + コメント + 添付 + 翻訳/TTS を 1つの API で包括的に取得するか、
  * いずれかが失敗した時点で画面全体をエラー扱いにする
    方針とする（分割取得は将来拡張）。

---

## 3.6 今後の拡張余地（データモデル観点）

本章 v1.0 では、BoardDetail の MVP 実装に必要な最小限のデータモデルと入出力仕様のみを定義した。今後の拡張候補として、次のような項目を想定する。

1. 回覧板既読管理との連携強化

   * ユーザ別既読状態や既読日時を BoardDetail 上で詳細表示する場合、既読テーブルとの JOIN / 集計を追加する。
2. コメントのモデレーション情報

   * 通報フラグや管理者による非表示理由を、コメント DTO に含めるかどうか。
3. 添付種別の拡張

   * 画像・動画など PDF 以外のメディア種別を表示・プレビューする場合の DTO 拡張。
4. 翻訳/TTS 履歴の表示

   * いつ翻訳/音声生成が行われたかなどの履歴を UI に出す場合の情報追加。

これらを実装する際は、先に DB 差分設計と掲示板基本設計を更新し、その後本章のバージョンを 1.1 以降に引き上げて整合させる。
