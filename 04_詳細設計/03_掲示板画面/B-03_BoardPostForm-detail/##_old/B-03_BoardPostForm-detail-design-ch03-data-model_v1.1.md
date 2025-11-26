# B-03 BoardPostForm 詳細設計書 ch03 データモデル・入出力仕様 v1.1

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH03  
**Version:** 1.1  
**Supersedes:** v1.0  
**Created:** 2025-11-22  
**Updated:** 2025-11-23  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** Draft  

---

## 3.1 本章の目的

本章では、掲示板投稿画面コンポーネント BoardPostForm（B-03）が利用する **データモデル** と **入出力仕様** を定義する。

DB スキーマは `schema.prisma` を唯一の正とし、その上に立つフロントエンド側の入力 DTO（フォーム値）と、投稿作成/更新 API のリクエスト/レスポンス仕様、投稿区分タグの定義を明文化する。

BoardPostForm は、新規投稿 `/board/new` および 編集モード `/board/[postId]/edit` を対象とし、

* 管理組合ユーザが「管理組合として」または「一般利用者として」投稿できること
* 一般利用者が自グループ向けの投稿や、質問・要望・その他を投稿できること
* **全ユーザが「匿名」または「ニックネーム」の表示モードを選択すること**

を前提とする。また、本章では **投稿・保存時に Google Translate API を呼び出して翻訳キャッシュを生成する** という設計方針を明示する（閲覧時には翻訳 API を呼ばない）。

---

## 3.2 投稿区分タグ定義（論理レベル）

### 3.2.1 GLOBAL 系投稿区分

掲示板基本設計に基づき、全住民向け（GLOBAL）投稿区分を以下のように定義する。UI ラベルと内部タグを対応づける。

| UIラベル | 内部タグ               | 説明                       | 回覧板対象 |
|---------|------------------------|----------------------------|-----------|
| 重要    | `GLOBAL_IMPORTANT`     | 重要なお知らせ・緊急度の高い情報   | ○         |
| お知らせ| `GLOBAL_NOTICE`        | 通常のお知らせ              | ○         |
| ルール  | `GLOBAL_RULES`         | ゴミ出し・集会所利用などの運用ルール | ×         |
| 質問    | `GLOBAL_QUESTION`      | 全体向けの質問              | ×         |
| 要望    | `GLOBAL_REQUEST`       | 全体向けの要望・改善提案        | ×         |
| その他  | `GLOBAL_OTHER`         | 上記に当てはまらないフリー投稿    | ×         |

* 「回覧板」フィルタの対象は `GLOBAL_IMPORTANT` と `GLOBAL_NOTICE` のみとする。
* `GLOBAL_RULES` は「ルール」専用タブ・フィルタで扱う（回覧板とは別扱い）。

### 3.2.2 GROUP 系投稿区分

グループ向け投稿は、`audienceType = "GROUP"` とグループIDにより表現する。UI 上のラベルはグループ名とし、内部的にはグループマスタに従った ID を使用する。

* UIラベル例: 「北-A」「北-B」「南-A」「南-B」
* 内部ID例: `group_id` として DB 上で管理（`GROUP_NORTH_A` などの論理タグはビュー用の概念とする）。

一般利用者は、自分が所属しているグループの投稿区分のみ選択可能とする。

---

## 3.3 ロール別の投稿者区分・投稿区分ルール

### 3.3.1 投稿者区分 (postAuthorRole)

管理組合権限を持つユーザは、「管理組合として」または「一般利用者として」投稿できる。一般利用者は一般利用者としてのみ投稿する。

```ts
export type PostAuthorRole = "admin" | "user";
```

#### 投稿者ロール関連フィールド

- `viewerRole: "admin" | "user"`
  - 現在の画面閲覧ロールを表す。
  - 認証コンテキストから決定される。

- `hasManagementRole: boolean`
  - ログインユーザが管理組合ロールを保持しているかどうか。
  - `true` の場合、少なくとも 1 つのテナントで管理組合ロールを持つ。

- `hasGeneralRole: boolean`
  - ログインユーザが一般利用者ロールを保持しているかどうか。
  - `true` の場合、少なくとも 1 つのテナントで一般利用者ロールを持つ。

- `postAuthorRole: "admin" | "user"`
  - 「今回の投稿をどの立場として行うか」を表す。
  - 決定ルール:
    - `hasManagementRole && hasGeneralRole === true` の場合:
      - 画面上で「管理組合として投稿する／一般利用者として投稿する」の二者択一を必須で選択させる。
      - ユーザの選択結果を `postAuthorRole` に保持する。
    - `hasManagementRole === true` かつ `hasGeneralRole === false` の場合:
      - 画面上に投稿者区分の UI は表示しない。
      - 内部的に `postAuthorRole = "admin"` を固定する。
    - `hasGeneralRole === true` かつ `hasManagementRole === false` の場合:
      - 画面上に投稿者区分の UI は表示しない。
      - 内部的に `postAuthorRole = "user"` を固定する。

### 3.3.2 投稿者表示モード (displayNameMode)

全ユーザ（管理組合・一般問わず）、投稿時に名前の表示方法を選択する必要がある。

```ts
export type DisplayNameMode = "anonymous" | "nickname";
```

- **anonymous**: 画面上は「匿名」等の固定表記となる（実データには `user_id` は紐づくが、表示を伏せる）。
- **nickname**: プロフィールに登録された `display_name` を表示する。
- フォーム初期状態では `null`（未選択）とし、バリデーションで選択を強制する。

### 3.3.3 ロール別に選択可能な投稿区分

投稿者区分 `postAuthorRole` に応じて、BoardPostForm 上で選択可能なカテゴリを明確に分離する。

#### (1) 管理組合として投稿する場合（postAuthorRole = "admin"）

- 選択可能なカテゴリ（管理組合専用）:
  - 重要なお知らせ … `GLOBAL_IMPORTANT`
  - 回覧板 … `GLOBAL_CIRCULAR`（回覧板専用カテゴリ）
  - イベント … `GLOBAL_EVENT`
  - 運用ルール … `GLOBAL_RULES`
- 一般利用者向けカテゴリ（質問・要望・その他・自グループ）は **表示しない／選択不可**。

#### (2) 一般利用者として投稿する場合（postAuthorRole = "user"）

- 選択可能なカテゴリ（一般利用者向け）:
  - 質問 … `GLOBAL_QUESTION`
  - 要望 … `GLOBAL_REQUEST`
  - その他 … `GLOBAL_OTHER`
  - 自グループ … `audienceType = "GROUP"` かつ `audienceGroupId = 自分の所属グループ`
- 管理組合専用カテゴリ（重要／回覧板／イベント／運用ルール）は **表示しない／選択不可**。

#### (3) ロールの組み合わせとの関係

- 一般利用者ロールのみ保持しているユーザ:
  - 投稿者区分 UI は表示されない。
  - `postAuthorRole = "user"` 固定となり、上記 (2) のカテゴリのみ選択可能。
- 管理組合ロールのみ保持しているユーザ:
  - 投稿者区分 UI は表示されない。
  - `postAuthorRole = "admin"` 固定となり、上記 (1) のカテゴリのみ選択可能。
- 管理組合ロールと一般利用者ロールを両方保持しているユーザ:
  - 投稿者区分 UI が表示され、ユーザが `"admin"` または `"user"` を明示的に選択する。
  - 選択結果に応じて、上記 (1) または (2) に従ってカテゴリ候補をフィルタリングする。

---

## 3.4 入力 DTO 定義

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
  displayNameMode: DisplayNameMode | null; // 匿名 / ニックネーム（初期値null）

  // 投稿区分
  categoryTag: string;              // 上記 3.2 のタグ（例: GLOBAL_NOTICE 等）
  audienceType: "GLOBAL" | "GROUP"; // 全体向け or グループ向け
  audienceGroupId?: string;         // GROUP の場合のみ指定（所属グループID）

  // 入力項目
  title: string;                    // タイトル
  content: string;                  // 本文。postAuthorRole="admin" のときはリッチテキスト（HTML 等）、"user" のときはプレーンテキスト。いずれも string として保持し、翻訳済み本文は含めない。

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

バックエンドの投稿作成 API (POST) および更新 API (PATCH) に渡すリクエスト DTO を論理的に定義する。

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
  content: string;                  // 投稿者が入力した原文。postAuthorRole="admin" のときはリッチテキスト（HTML 等）、"user" のときはプレーンテキスト。

  // 回覧板
  isCirculation: boolean;
  circulationGroupIds: string[];
  circulationDueDate?: string;

  // 添付（アップロード済みの場合）
  attachments: {
    fileUrl: string;                // Storage 上の URL
    fileName: string;
    fileSize: number;
    fileType: string;
  }[];
};
```

- **Create (POST)**: `/api/board/posts` に上記ボディを送信。  
- **Update (PATCH)**: `/api/board/posts/{postId}` に上記ボディ（変更差分または全量）を送信。

#### 3.4.3 API レスポンス DTO

投稿作成/更新 API のレスポンス DTO は、処理された投稿の ID を含む。

```ts
export type UpsertBoardPostResponse = {
  postId: string;     // 生成または更新された board_posts.id
};
```

投稿成功後、BoardPostForm は `postId` を用いて `/board/[postId]` へ遷移する（BoardDetail 画面）。

### 3.4.4 翻訳キャッシュとの関係（外部仕様）

#### 3.4.4.1 キャッシュ保有期間

- 翻訳キャッシュ（例：`board_post_translations`）には、テナント単位で「保有日数」を設定できるものとする。  
- 初期値（デフォルト値）は **90日** とする。  
- テナント管理者画面から、保有日数を **60〜120日の範囲** で変更可能とする。

#### 3.4.4.2 翻訳キャッシュ生成フロー

BoardPostForm から見た「API の振る舞い」を、翻訳処理を含めた外部仕様として定義する。

1. `UpsertBoardPostRequest` 受信後、原文本文 `content` を含む投稿レコードを保存する。  
2. 保存した投稿の `postId` をキーとして、共通翻訳サービス（Google Translate API ラッパ）を呼び出す。  
   - **新規投稿時**: 原文を元に翻訳を実行しキャッシュ生成。  
   - **編集時**: タイトルまたは本文に変更があった場合のみ、翻訳を実行しキャッシュを更新する。  
3. 翻訳結果を翻訳キャッシュテーブル（例: `board_post_translations`）に保存する。  
4. フロントエンドには `postId` を返却するのみとし、翻訳結果は返さない。

---

## 3.5 バリデーション仕様（論理）

### 3.5.1 必須項目

- タイトル: 空文字禁止  
- 本文: 空文字禁止  
- 投稿区分: `categoryTag` 必須  
- **投稿者表示**: `displayNameMode` 必須（null 不可）  
- audienceType:
  - `categoryTag` が GLOBAL 系の場合 → `audienceType = "GLOBAL"` 固定
  - GROUP 投稿の場合 → `audienceType = "GROUP"` 必須
- GROUP 投稿時:
  - `audienceGroupId` 必須  

### 3.5.2 ロール・投稿者区分制約

- `viewerRole = "user"` の場合:
  - `postAuthorRole` は常に `"user"` でなければならない。
  - `categoryTag` は `GLOBAL_QUESTION` / `GLOBAL_REQUEST` / `GLOBAL_OTHER` / 自グループのみに限定される。
- `viewerRole = "admin"` かつ `postAuthorRole = "admin"` の場合:
  - `categoryTag` に GLOBAL 系全カテゴリが選択可能。
- `viewerRole = "admin"` かつ `postAuthorRole = "user"` の場合:
  - `categoryTag` 制約は一般利用者と同じとする（質問/要望/その他/自グループ）。

### 3.5.3 回覧板設定

- `isCirculation = true` の場合:
  - `circulationDueDate` が指定されていることが望ましい（必須とするかどうかは掲示板基本設計に従う）。
  - `circulationGroupIds` の指定ルール（管理組合のみ複数グループ選択可等）は、掲示板基本設計の決定に合わせて BoardPostForm 実装で反映する。

### 3.5.4 添付ファイル

- **許可する形式**:
  - PDF: `.pdf`
  - Excel: `.xls`, `.xlsx`
  - Word: `.doc`, `.docx`
  - PowerPoint: `.ppt`, `.pptx`
  - 画像: `.jpg`, `.jpeg`, `.png`
- **上限値（デフォルト）**:
  - 1 ファイルあたり最大サイズ: 5MB
  - 最大添付ファイル数: 5 ファイル
- **テナント設定との連動**:
  - 実際に適用する上限値は `tenant_settings` テーブルに保持された値  
    （例: `maxAttachmentSizeMB`, `maxAttachmentCount`）に従う。
- **チェック**:
  - ファイル選択時に拡張子および MIME タイプを検証し、許可リスト外の場合はエラーとする。
  - 新規追加するファイルについて、ファイルサイズが `maxAttachmentSizeMB` を超える場合はエラーとする。
  - `status !== "removed"` の添付ファイル数が `maxAttachmentCount` を超える場合はエラーとする。
- **権限との関係**:
  - 投稿内容の編集権限があるユーザのみ、添付ファイルの追加および削除を行える。

以上で、本章における BoardPostForm のデータモデル・入出力仕様、および翻訳キャッシュとの関係定義を完了とする。
