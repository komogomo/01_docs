# B-03 BoardPostForm 詳細設計書 ch03 データモデル・入出力仕様 v1.2

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH03
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-27
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板投稿画面コンポーネント **BoardPostForm（B-03）** が利用する **データモデル** と **入出力仕様** を定義する。

DB スキーマは `schema.prisma` を唯一の正とし、その上に立つフロントエンド側の入力 DTO（フォーム値）と、投稿作成/更新 API のリクエスト/レスポンス仕様、投稿区分タグの定義を明文化する。

BoardPostForm は、新規投稿 `/board/new` および 編集モード `/board/[postId]/edit` を対象とし、次の要件を満たす。

* 管理組合ユーザが「管理組合として」または「一般利用者として」投稿できること。
* 一般利用者が自グループ向けの投稿や、質問・要望・その他を投稿できること。
* 全ユーザが「匿名」または「ニックネーム」の表示モードを選択できること。

本文については、TipTap によるリッチテキスト入力を **全ユーザ共通** とし、

* 検索・翻訳・TTS・モデレーション用の **テキスト正（プレーンテキスト）** は `board_posts.content` に保持する。
* 表示用の **リッチ HTML** は `board_posts.content_html` に保持する。

すべてのロジック（翻訳／TTS／モデレーション／検索）はテキスト正のみを参照し、HTML は表示用途にだけ使用する。

---

## 3.2 投稿区分タグ定義（論理レベル）

### 3.2.1 GLOBAL 系投稿区分

全住民向け（GLOBAL）投稿区分を以下のように定義する。UI ラベルと内部タグを対応づける。

| UIラベル | 内部タグ               | 説明                 | 回覧板対象 |
| ----- | ------------------ | ------------------ | ----- |
| 重要    | `GLOBAL_IMPORTANT` | 重要なお知らせ・緊急度の高い情報   | ○     |
| お知らせ  | `GLOBAL_NOTICE`    | 通常のお知らせ            | ○     |
| ルール   | `GLOBAL_RULES`     | ゴミ出し・集会所利用などの運用ルール | ×     |
| 質問    | `GLOBAL_QUESTION`  | 全体向けの質問            | ×     |
| 要望    | `GLOBAL_REQUEST`   | 全体向けの要望・改善提案       | ×     |
| その他   | `GLOBAL_OTHER`     | 上記に当てはまらないフリー投稿    | ×     |

* 「回覧板」フィルタの対象は `GLOBAL_IMPORTANT` と `GLOBAL_NOTICE` のみとする。
* `GLOBAL_RULES` は「ルール」専用タブ・フィルタで扱う（回覧板とは別扱い）。

### 3.2.2 GROUP 系投稿区分

グループ向け投稿は、`audienceType = "GROUP"` とグループIDにより表現する。UI 上のラベルはグループ名とし、内部的にはグループマスタに従った ID を使用する。

---

## 3.3 本文格納方針（テキスト正 + HTML）

掲示板投稿本文は、テーブル `board_posts` 上で次の二重構造で保持する。

* **テキスト正（既存カラム）**

  * プレーンテキストとして本文を格納する（`board_posts.content`）。
  * 翻訳キャッシュ生成、TTS、モデレーション、検索など、すべてのロジックはこのテキスト正のみを参照する。

* **リッチ用 HTML（新カラム）**

  * TipTap で編集したリッチテキストを HTML 文字列として格納する（`board_posts.content_html`）。
  * 本文の様式・体裁（改行・見出し・箇条書き・リンクなど）を表現するために使用し、BoardDetail でのリッチ表示に用いる。
  * 機能要件上、一般・管理組合どちらの投稿でも保持してよいが、TipTap で装飾を行っていない場合はシンプルな HTML になる。

この方針により、既存のプレーンテキスト前提の処理を変更せずに、全ユーザでリッチテキスト入力を実現する。

---

## 3.4 入力・出力 DTO 定義

### 3.4.1 フォーム内部状態 DTO（`BoardPostFormInput`）

BoardPostForm 内部で扱う入力値を論理型として定義する。編集モードにも対応する。

```ts
export type BoardPostFormInput = {
  // 動作モード
  mode: "create" | "edit";          // 新規作成か編集か
  editPostId?: string;              // 編集時の対象投稿ID

  // コンテキスト
  tenantId: string;                 // 認証コンテキストから取得
  userId: string;                   // 認証コンテキストから取得
  viewerRole: "admin" | "user";     // ログインユーザのロール

  // 投稿者設定
  postAuthorRole: PostAuthorRole;   // 管理組合として / 一般利用者として
  displayNameMode: DisplayNameMode | null; // 匿名 / ニックネーム（初期値 null）

  // 投稿区分
  categoryTag: string;              // 上記 3.2 のタグ（例: GLOBAL_NOTICE 等）
  audienceType: "GLOBAL" | "GROUP"; // 全体向け or グループ向け
  audienceGroupId?: string;         // GROUP の場合のみ指定（所属グループID）

  // 入力項目
  title: string;                    // タイトル

  /**
   * 本文（テキスト正）。
   *
   * TipTap で編集した内容から抽出したプレーンテキストを保持・保存する。
   * 翻訳／TTS／モデレーション／検索など、すべてのロジックはこの content のみを参照する。
   */
  content: string;

  /**
   * 本文（リッチ用 HTML）。
   *
   * TipTap で編集した HTML 文字列を保持・保存する。
   * BoardDetail でのリッチ表示など、表示用途にのみ利用し、翻訳/TTS/モデレーションには使用しない。
   */
  contentHtml: string | null;

  // 添付ファイル（フォーム上の一時情報）
  attachments: {
    id: string;        // フロント側一時ID
    fileName: string;
    fileSize: number;
    fileType: string;
    status: "selected" | "uploading" | "uploaded" | "error" | "existing"; // existing: 編集時の既存ファイル
    fileObject?: File; // 新規アップロード用（既存ファイルの場合は undefined）
    fileUrl?: string;  // Storage 上の URL（アップロード完了または既存）
  }[];

  // 回覧板設定
  isCirculation: boolean;           // 回覧板として扱うか
  circulationGroupIds: string[];    // 回覧対象グループID（必要な場合）
  circulationDueDate?: string;      // 回覧期限（YYYY-MM-DD）
};
```

### 3.4.2 API リクエスト DTO

バックエンドの投稿作成 API (POST) および更新 API (PATCH) に渡すリクエスト DTO を定義する。

#### 共通リクエストボディ (`UpsertBoardPostRequest`)

```ts
export type UpsertBoardPostRequest = {
  tenantId: string;
  authorId: string;                 // 実際の投稿者ユーザID（userId）
  authorRole: PostAuthorRole;       // 管理組合として / 一般利用者として
  displayNameMode: DisplayNameMode; // 匿名 / ニックネーム（必須）

  categoryTag: string;              // GLOBAL_IMPORTANT 等
  audienceType: "GLOBAL" | "GROUP";
  audienceGroupId?: string;         // GROUP の場合のみ

  title: string;

  /**
   * 投稿者が入力した原文本文（テキスト正）。
   * TipTap から抽出したプレーンテキストを保持する。
   * 翻訳済み本文は含めない。
   */
  content: string;

  /**
   * 投稿者が入力した原文本文のリッチHTML。TipTap の HTML をそのまま渡す。
   *
   * DB 側の HTML 用カラム（`board_posts.content_html`）に保存し、表示用途にのみ使用する。
   */
  contentHtml?: string | null;

  // 回覧板
  isCirculation: boolean;
  circulationGroupIds: string[];
  circulationDueDate?: string;

  // 添付ファイル
  attachments: {
    id?: string;            // 既存添付のID（編集時）
    fileName: string;
    fileSize: number;
    fileType: string;
    fileUrl: string;        // Storage 上のURL
    isNew: boolean;         // 新規添付かどうか
    isRemoved?: boolean;    // 編集時に削除対象かどうか
  }[];
};
```

### 3.4.3 API レスポンス DTO

投稿作成/更新 API のレスポンス DTO は、処理された投稿の ID を含む。

```ts
export type UpsertBoardPostResponse = {
  postId: string;     // 生成または更新された board_posts.id
};
```

投稿成功後、BoardPostForm は `postId` を用いて `/board/[postId]` へ遷移する（BoardDetail 画面）。

---

## 3.5 バリデーション仕様（論理）

### 3.5.1 必須項目

以下の項目は必須とし、条件を満たさない場合はエラーとする。

* タイトル: 空文字禁止。
* 本文（テキスト正）:

  * `content.trim().length > 0` を必須とする（管理組合投稿・一般投稿とも同じ）。
* 投稿区分: `categoryTag` 必須。
* 投稿者表示: `displayNameMode` 必須（null 不可）。
* audienceType:

  * GLOBAL 系カテゴリの場合 → `audienceType = "GLOBAL"` 固定。
  * GROUP 投稿の場合 → `audienceType = "GROUP"` 必須。
* GROUP 投稿時: `audienceGroupId` 必須。

### 3.5.2 ロール・投稿者区分制約

* `viewerRole = "user"` の場合:

  * `postAuthorRole` は常に "user"。
  * `categoryTag` は `GLOBAL_QUESTION` / `GLOBAL_REQUEST` / `GLOBAL_OTHER` / 自グループ投稿のみに限定する。
* `viewerRole = "admin"` かつ `postAuthorRole = "admin"` の場合:

  * `categoryTag` に GLOBAL 系全カテゴリが選択可能。
* `viewerRole = "admin"` かつ `postAuthorRole = "user"` の場合:

  * `categoryTag` 制約は一般利用者と同じとする（質問/要望/その他/自グループ）。

### 3.5.3 回覧板設定

* `isCirculation = true` の場合:

  * `circulationDueDate` が指定されていることが望ましい（必須とするかどうかは掲示板基本設計に従う）。
  * `circulationGroupIds` の指定ルール（管理組合のみ複数グループ選択可等）は、掲示板基本設計の決定に合わせて BoardPostForm 実装で反映する。

### 3.5.4 添付ファイル

添付ファイルについては、次の制約を設ける。

* 許可する形式:

  * PDF: `.pdf`
  * Excel: `.xls`, `.xlsx`
  * Word: `.doc`, `.docx`
  * PowerPoint: `.ppt`, `.pptx`
  * 画像: `.jpg`, `.jpeg`, `.png`
* 上限値（デフォルト）:

  * 1 ファイルあたり最大サイズ: 5MB
  * 最大添付ファイル数: 5 ファイル
* テナント設定との連動:

  * 実際に適用する上限値は `tenant_settings` テーブルに保持された値（例: `maxAttachmentSizeMB`, `maxAttachmentCount`）に従う。
* チェック:

  * ファイル選択時に拡張子および MIME タイプを検証し、許可リスト外の場合はエラーとする。
  * 新規追加するファイルについて、ファイルサイズが `maxAttachmentSizeMB` を超える場合はエラーとする。
  * `status !== "removed"` の添付ファイル数が `maxAttachmentCount` を超える場合はエラーとする。
* 権限との関係:

  * 投稿内容の編集権限があるユーザのみ、添付ファイルの追加および削除を行える。

---

## 3.6 翻訳・TTS・モデレーションとの関係

### 3.6.1 テキスト正の利用

* 翻訳キャッシュ生成、TTS、モデレーション、検索など、すべてのロジックはテキスト正カラム（`board_posts.content`）だけを参照する。
* リッチ用 HTML カラム（`board_posts.content_html`）は、これらのロジックには一切使用しない。

### 3.6.2 翻訳済み本文の扱い

* `BoardPostFormInput.content` および `UpsertBoardPostRequest.content` には常にオリジナル本文のみを保持し、翻訳済み本文は保持しない。
* 翻訳済み本文は翻訳キャッシュテーブル（例: `board_post_translations`）側で管理する。

---

## 3.7 まとめ

本章では、BoardPostForm のデータモデルおよび入出力仕様を定義し、次の点を明確にした。

* 本文は「テキスト正」と「リッチ用HTML」を分離し、テキスト正は `board_posts.content` にプレーンテキストとして保持すること。
* TipTap によるリッチ本文は `board_posts.content_html` に HTML として保持すること。
* 翻訳／TTS／モデレーション／検索はテキスト正のみを参照し、HTML は表示用途に限定すること。
* フロントエンド DTO (`BoardPostFormInput` / `UpsertBoardPostRequest`) では、テキスト正とHTMLを別フィールド（`content` / `contentHtml`）で扱うこと。

BoardPostForm の実装および Windsurf 向け作業指示書は、本 ch03 を参照してデータモデルの整合を取る。
