# B-03 BoardPostForm 詳細設計書 ch04 状態管理・イベント処理設計 v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH04
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 4.1 本章の目的

本章では、掲示板投稿画面コンポーネント **BoardPostForm（B-03）** の

* クライアントサイド状態管理モデル
* イベント種別とハンドラ
* 投稿 API 呼び出しフロー
* バリデーション・エラーハンドリング
* ローディング・再送戦略
* ログ出力ポイント

を定義する。ch03 で定義したデータモデル / DTO を前提としつつ、画面側の具体的なロジック構造を記述する。

翻訳キャッシュ生成および TTS は B-04（TranslationAndTtsService）の責務とし、本章では

* 「投稿 API 呼び出し時に翻訳サービスが裏側で動作する」

前提のみを記載し、BoardPostForm 内で翻訳/TTS の直接呼び出しは行わない。

---

## 4.2 状態モデル

### 4.2.1 フォーム入力状態 `BoardPostFormState`

フォームの入力値と UI 状態を一括で表現する状態オブジェクトを `BoardPostFormState` として管理する。

```ts
export type BoardPostFormState = {
  // 投稿者・閲覧者コンテキスト（読み取り専用）
  tenantId: string;           // 現在テナント ID
  viewerUserId: string;       // ログインユーザ ID
  viewerRole: "admin" | "user";
  viewerGroupIds: string[];   // 所属グループ ID 一覧

  // 投稿メタ情報
  postAuthorRole: "admin" | "user";  // 「管理組合として投稿」か「一般利用者として投稿」か

  // 投稿区分
  categoryTag: BoardPostCategoryTag | null;
  audienceType: "GLOBAL" | "GROUP";
  audienceGroupId: string | null;          // GROUP の場合のみ有効

  // 本文
  title: string;
  content: string;                         // リッチテキスト or シンプルテキスト（利用者別）

  // 添付
  attachments: {
    tempId: string;                        // クライアント側一意キー
    fileName: string;
    fileSize: number;
    fileType: string;
    status: "selected" | "uploading" | "uploaded" | "error";
    fileObject?: File;                     // アップロード前の File オブジェクト
    fileUrl?: string;                      // Storage へのアップロード完了後 URL
  }[];

  // 回覧板設定
  isCirculation: boolean;
  circulationGroupIds: string[];           // 回覧対象グループ（管理組合のみ複数可）
  circulationDueDate: string | null;       // YYYY-MM-DD

  // UI 状態
  isDirty: boolean;                        // 一度でも入力が変更されたか
  isSubmitConfirmOpen: boolean;           // 投稿確認モーダル表示状態
  isSubmitting: boolean;                  // 投稿 API 呼び出し中か
  submitError: string | null;             // 投稿失敗メッセージ（i18n キー）
};
```

### 4.2.2 初期状態

BoardPostForm 初期表示時の状態は、以下のルールで構成する。

* `tenantId` / `viewerUserId` / `viewerRole` / `viewerGroupIds` は認証コンテキストから取得し、初期化時に埋め込む。
* `postAuthorRole`

  * デフォルトは `"user"`（一般利用者として投稿）
  * 管理組合ロールを持つユーザの場合のみ、UI 上のトグルで `"admin"` へ切り替え可能。
* `categoryTag`

  * 初期値は `null`（未選択）。
* `audienceType`

  * 初期値は `"GLOBAL"`。
* `audienceGroupId`

  * 初期値は `null`。
* `title` / `content`

  * 空文字列で初期化。
* `attachments`

  * 空配列。
* `isCirculation`

  * 初期値は `false`。
* `circulationGroupIds`

  * 初期値は空配列。
* `circulationDueDate`

  * 初期値は `null`。
* `isDirty`

  * 初期値は `false`。
* `isSubmitConfirmOpen`

  * 初期値は `false`。
* `isSubmitting`

  * 初期値は `false`。
* `submitError`

  * 初期値は `null`。

---

## 4.3 イベント一覧とハンドラ責務

BoardPostForm で扱う主なイベントと、それに対応するハンドラを以下に定義する。

### 4.3.1 入力値変更系イベント

| イベント ID                  | 発火トリガー                 | ハンドラ                         | 主な処理内容                                                               |
| ------------------------ | ---------------------- | ---------------------------- | -------------------------------------------------------------------- |
| EVT_INPUT_TITLE_CHANGE   | タイトルテキスト入力変更           | `onChangeTitle`              | `state.title` 更新 + `isDirty = true`                                  |
| EVT_INPUT_CONTENT_CHANGE | 本文入力変更                 | `onChangeContent`            | `state.content` 更新 + `isDirty = true`                                |
| EVT_SELECT_CATEGORY      | 投稿区分タグ選択               | `onChangeCategory`           | `categoryTag` / `audienceType` / `audienceGroupId` 更新 + ロール制約バリデーション |
| EVT_TOGGLE_AUTHOR_ROLE   | 「管理組合として投稿」トグル切り替え     | `onToggleAuthorRole`         | `postAuthorRole` 更新 + 選択可能カテゴリ再計算                                    |
| EVT_TOGGLE_CIRCULATION   | 「回覧板として扱う」チェックボックス切り替え | `onToggleCirculation`        | `isCirculation` 更新 + 回覧板用入力制約適用                                      |
| EVT_CHANGE_CIRC_GROUPS   | 回覧対象グループ選択             | `onChangeCirculationGroups`  | `circulationGroupIds` 更新                                             |
| EVT_CHANGE_CIRC_DUE      | 回覧期限日付変更               | `onChangeCirculationDueDate` | `circulationDueDate` 更新                                              |

### 4.3.2 添付ファイル関連イベント

| イベント ID                | 発火トリガー                    | ハンドラ                     | 主な処理内容                                                         |
| ---------------------- | ------------------------- | ------------------------ | -------------------------------------------------------------- |
| EVT_ATTACH_FILE_SELECT | 「ファイルを選択」ボタンで PDF を選択     | `onSelectAttachmentFile` | `attachments` に `status = "selected"` で追加。非 PDF の場合はエラー表示。     |
| EVT_ATTACH_FILE_UPLOAD | ファイル選択後、自動 or 明示的アップロード開始 | `onUploadAttachmentFile` | Storage アップロード開始。`status = "uploading"` に変更。完了時に `fileUrl` 設定。 |
| EVT_ATTACH_FILE_REMOVE | 添付リスト上の×ボタン               | `onRemoveAttachment`     | 対象 `tempId` の添付要素を配列から削除。                                      |

Storage へのアップロード処理自体は、別コンポーネントまたはカスタムフックに切り出し可能とし、BoardPostForm からは「成功時に URL を受け取る」インタフェースで扱う。

### 4.3.3 送信・キャンセル関連イベント

| イベント ID                   | 発火トリガー           | ハンドラ              | 主な処理内容                                 |
| ------------------------- | ---------------- | ----------------- | -------------------------------------- |
| EVT_CLICK_SUBMIT          | 「投稿する」ボタン押下      | `onClickSubmit`   | 入力値バリデーション実行 → 問題なければ確認モーダルを開く。        |
| EVT_CONFIRM_SUBMIT_OK     | 確認モーダルで「はい」選択    | `onConfirmSubmit` | `isSubmitting = true` にし、投稿 API を呼び出す。 |
| EVT_CONFIRM_SUBMIT_CANCEL | 確認モーダルで「キャンセル」選択 | `onCancelSubmit`  | モーダルを閉じる。`isSubmitting` は変更しない。        |
| EVT_CLICK_CANCEL          | 「キャンセル」ボタン押下     | `onClickCancel`   | 親コンポーネント経由で画面遷移（例: BoardTop に戻る）を依頼する。 |

---

## 4.4 バリデーション設計

### 4.4.1 バリデーションの基本方針

* BoardPostForm のバリデーションは **フロントエンドで完結** させる。
* 入力エラーがある状態では、投稿確認モーダルを開かない。
* エラーメッセージは i18n キーで管理し、UI では StaticI18nProvider を経由して表示する。

### 4.4.2 フィールド別バリデーション

最低限、以下の条件を満たさない場合はエラーとする。

1. 投稿区分 / 対象範囲

   * `categoryTag` が `null` の場合はエラー。
   * `audienceType = "GROUP"` の場合、`audienceGroupId` が `null` であればエラー。
   * `viewerRole` / `postAuthorRole` の組み合わせに対して、ch03 3.5.1 に定義された選択制約を満たさない場合はエラー。

2. タイトル / 本文

   * `title` が空文字列、またはトリム後 0 文字の場合はエラー。
   * `content` が空文字列、またはエディタのダミー値（例: `<p><br/></p>` のみ）であればエラー。

3. 回覧板設定

   * `isCirculation = true` かつ `categoryTag` が回覧板対象外（例: `GLOBAL_OTHER` 等）の場合はエラー。
   * `isCirculation = true` の場合、`circulationGroupIds` が空配列であれば警告扱いとし、必要に応じてエラーに昇格できるようにしておく。

4. 添付

   * 必須ではないが、選択済みファイルがすべて `status = "error"` の場合は投稿前にユーザへ警告ダイアログを表示する。

### 4.4.3 エラー状態の保持と表示

* 各フィールドごとのエラーは、内部的には以下のようなマップで管理する。

```ts
export type BoardPostFormErrors = {
  title?: string;          // i18n キー
  content?: string;
  categoryTag?: string;
  audienceGroupId?: string;
  circulation?: string;
  attachments?: string;
};
```

* `validateForm(state): BoardPostFormErrors` を定義し、

  * `onClickSubmit` 内で実行
  * 1 つでもエラーがあれば

    * `submitError` に総括メッセージ（例: `"board.post.validation_failed"`）を設定
    * 確認モーダルは開かない

---

## 4.5 投稿 API 呼び出しフロー

### 4.5.1 API インタフェース

投稿 API は ch03 3.4 で定義した DTO を用い、Next.js App Router の `POST /api/board/posts` を想定する。

```ts
async function createBoardPost(request: CreateBoardPostRequest): Promise<CreateBoardPostResponse> {
  const response = await fetch("/api/board/posts", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    // ステータスコード別のエラー処理は 4.6.2 参照
    throw new Error("board.post.create_failed");
  }

  return (await response.json()) as CreateBoardPostResponse;
}
```

BoardPostForm は、親コンポーネントから `onSubmit` コールバックを受け取る形でもよいが、本設計では以下のように扱う。

* BoardPostForm 内で `createBoardPost` を直接呼び出す。
* 投稿成功時には、`postId` を用いて `/board/[postId]` に遷移する処理を親コンポーネントへ委譲する。

### 4.5.2 `onConfirmSubmit` の処理手順

`onConfirmSubmit` は以下の手順で処理を行う。

1. `isSubmitting = true` に設定。
2. 直前の `BoardPostFormState` から `CreateBoardPostRequest` を構築。
3. `createBoardPost` を呼び出し。
4. 成功時:

   * `isSubmitting = false`。
   * `submitError = null`。
   * 親コンポーネントに `onSubmitSuccess(postId)` をコールバック。
5. 失敗時:

   * `isSubmitting = false`。
   * エラー種別に応じて `submitError` を i18n キーで設定。
   * 確認モーダルは閉じる（ユーザに再編集を促す）。

---

## 4.6 エラーハンドリング・ローディング・再送

### 4.6.1 ローディング制御

* 投稿 API 呼び出し中は `isSubmitting = true` とし、

  * 「投稿する」ボタンを disabled にする。
  * ボタンラベルを `"送信中..."` に切り替える（i18n）。
  * 二重送信防止のため、確認モーダルのボタンも disabled にする。

### 4.6.2 ステータスコード別エラー処理方針

API の HTTP ステータスコードに応じて、以下のようにハンドリングする。

| ステータス     | 想定ケース           | ハンドリング方針                                                    |
| --------- | --------------- | ----------------------------------------------------------- |
| 400       | バリデーションエラー      | サーバからのエラーメッセージを優先して `submitError` に反映。必要に応じてフィールドエラーへマッピング。 |
| 401 / 403 | 認証・権限エラー        | ログイン画面へのリダイレクト、またはグローバルエラーバナーを表示。                           |
| 404       | API 終了・URL 誤りなど | `submitError = "board.post.api_not_found"` を設定。             |
| 409       | 重複投稿・状態競合など     | `submitError = "board.post.conflict"` を設定し、再送を促す。           |
| 500       | サーバ内部エラー        | `submitError = "common.error.server"` を設定。                  |
| ネットワーク例外  | オフライン／タイムアウト 等  | `submitError = "common.error.network"` を設定し、再送用ボタンを表示。      |

### 4.6.3 再送戦略

* 投稿失敗時、フォームの入力内容は破棄しない。
* エラー表示領域に「再送する」ボタンを表示し、`onRetrySubmit` ハンドラで直前の `CreateBoardPostRequest` を再送できるようにする。
* `onRetrySubmit` は内部的に `onConfirmSubmit` と同等の処理を呼び出す。

---

## 4.7 ログ出力ポイント

共通ロガー（Logger）詳細設計に従い、以下のイベントでログ出力を行う。

| タイミング    | ログレベル | event 値                       | context 例                                      |
| -------- | ----- | ----------------------------- | ---------------------------------------------- |
| フォーム表示時  | INFO  | `"board.post.form_open"`      | `{ tenantId, viewerUserId }`                   |
| 投稿ボタン押下時 | INFO  | `"board.post.submit_click"`   | `{ categoryTag, audienceType, isCirculation }` |
| 投稿成功時    | INFO  | `"board.post.create_success"` | `{ postId, categoryTag, audienceType }`        |
| 投稿失敗時    | ERROR | `"board.post.create_failed"`  | `{ errorCode, httpStatus }`                    |

BoardPostForm 自体はログ出力用のラッパ関数 `logInfo` / `logError` を呼ぶだけとし、
実際の出力先（console / Supabase Logs 等）は Logger 実装に委譲する。

---

## 4.8 ユニットテスト観点（ch04 対応分）

本章で定義したロジックに対する主要な UT 観点を列挙する。実際のテストケース定義は ch06 で詳細化する。

1. 初期状態

   * `viewerRole` / `viewerGroupIds` に応じて、初期のカテゴリ選択肢が期待通りか。
   * 初期表示で `isDirty = false`、`isSubmitting = false`、`submitError = null` になっているか。

2. バリデーション

   * `categoryTag` 未選択で投稿ボタン押下 → 確認モーダルが開かず、エラー表示されること。
   * `content` 空で投稿ボタン押下 → 同上。
   * 管理組合ロール／一般ロールの組み合わせが制約を満たさない場合、POST が実行されないこと。

3. 投稿フロー

   * 正常系: バリデーション OK → 確認モーダル → `onConfirmSubmit` → API 成功 → `onSubmitSuccess` が呼ばれること。
   * 異常系: API が 400/500 を返した場合、`submitError` に適切な i18n キーが設定されること。

4. 再送

   * ネットワーク例外発生後に「再送する」ボタンを押すと、同じリクエスト内容で再度 API が呼ばれること。

5. ログ

   * フォーム表示 / 投稿クリック / 成功 / 失敗の各タイミングで、Logger が期待どおりの event 名・context で呼ばれていること。

以上により、BoardPostForm（B-03）の状態管理およびイベント処理設計を定義する。
