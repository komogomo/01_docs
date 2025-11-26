# B-03 BoardPostForm 詳細設計書 ch04 状態管理・イベント処理設計 v1.2

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH04
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-27
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

を定義する。ch03 で定義したデータモデル / DTO を前提としつつ、画面側のロジック構造を記述する。

本文については TipTap によるリッチテキスト入力を **全ユーザ共通** で使用し、

* テキスト正（プレーンテキスト）は `BoardPostFormState.content` として保持し、`board_posts.content` に保存する。
* リッチ用 HTML は `BoardPostFormState.contentHtml` として保持し、`board_posts.content_html` に保存する。

翻訳キャッシュ生成・TTS・モデレーション・検索など、すべてのロジックはテキスト正のみを参照し、HTML は表示用途にのみ利用する。

---

## 4.2 状態モデル

### 4.2.1 フォーム入力状態 `BoardPostFormState`

フォームの入力値と UI 状態を一括で表現する状態オブジェクトを `BoardPostFormState` として管理する。

```ts
export type BoardPostFormState = {
  // 動作モード
  mode: "create" | "edit";          // 新規作成か編集か
  editPostId?: string;              // 編集時の対象投稿ID

  // 投稿者・閲覧者コンテキスト（読み取り専用）
  tenantId: string;           // 現在テナント ID
  viewerUserId: string;       // ログインユーザ ID
  viewerRole: "admin" | "user";
  viewerGroupIds: string[];   // 所属グループ ID 一覧

  hasManagementRole: boolean; // 管理組合ロールを持つか
  hasGeneralRole: boolean;    // 一般利用者ロールを持つか

  // 投稿メタ情報
  postAuthorRole: "admin" | "user";  // 「管理組合として投稿」か「一般利用者として投稿」か
  displayNameMode: "anonymous" | "nickname" | null; // 投稿者表示モード（必須選択）

  // 投稿区分
  categoryTag: string | null; // 選択されたタグ（GLOBAL_*/GROUP 系）
  audienceType: "GLOBAL" | "GROUP";
  audienceGroupId: string | null;          // GROUP の場合のみ有効

  // 入力項目
  title: string;

  /**
   * 本文（テキスト正）。
   *
   * TipTap で編集した内容から抽出したプレーンテキストを保持する。
   * 翻訳/TTS/モデレーション/検索など、あらゆるロジックはこの content を正として参照する。
   */
  content: string;

  /**
   * 本文（リッチ用 HTML）。
   *
   * TipTap で編集した HTML 文字列を保持する。BoardDetail でのリッチ表示など、表示用途にのみ利用する。
   */
  contentHtml: string | null;

  // 添付
  attachments: {
    tempId: string;                        // クライアント側一意キー
    fileName: string;
    fileSize: number;
    fileType: string;
    status: "selected" | "uploading" | "uploaded" | "error" | "existing"; // existing: 編集時の既存ファイル
    fileObject?: File;                     // アップロード前の File オブジェクト
    fileUrl?: string;                      // Storage へのアップロード完了後 URL（または既存URL）
  }[];

  // 回覧板設定
  isCirculation: boolean;
  circulationGroupIds: string[];           // 回覧対象グループ（管理組合のみ複数可）
  circulationDueDate: string | null;       // YYYY-MM-DD

  // UI 状態
  isDirty: boolean;                        // 一度でも入力が変更されたか
  isSubmitConfirmOpen: boolean;           // 投稿確認ダイアログ（プレビュー）表示状態
  isSubmitting: boolean;                  // 投稿 API 呼び出し中か
  submitError: string | null;             // 投稿失敗メッセージ（i18n キー）
};
```

### 4.2.2 初期状態

BoardPostForm 初期表示時の状態は、以下のルールで構成する。

* モード・コンテキスト・ロール・投稿区分の初期化は v1.1 と同様とする（詳細は ch02/ch03 を参照）。
* 本文:

  * 新規投稿時:

    * `content = ""`（空文字）。
    * `contentHtml = ""`（TipTap 初期値として空HTMLを渡してよい）。
  * 編集時:

    * テキスト正カラム `board_posts.content` の値を `content` にセットする。
    * HTML カラム `board_posts.content_html` の値を `contentHtml` にセットする（null の場合は空文字として TipTap に渡す）。
* 添付・回覧板・UI 状態は従来どおり（新規時は空、編集時は既存値を展開）。

---

## 4.3 イベント一覧とハンドラ責務

BoardPostForm で扱う主なイベントと、それに対応するハンドラを定義する。

### 4.3.1 入力値変更系イベント

| イベント ID                       | 発火トリガー                     | ハンドラ                         | 主な処理内容                                                                   |
| ----------------------------- | -------------------------- | ---------------------------- | ------------------------------------------------------------------------ |
| EVT_INPUT_TITLE_CHANGE        | タイトルテキスト入力変更               | `onChangeTitle`              | `state.title` 更新 + `isDirty = true`                                      |
| EVT_INPUT_CONTENT_HTML_CHANGE | TipTap HTML 変更             | `onChangeContentHtml`        | `state.contentHtml` 更新 + テキスト正抽出して `state.content` 更新 + `isDirty = true` |
| EVT_SELECT_CATEGORY           | 投稿区分タグ選択                   | `onChangeCategory`           | `categoryTag` / `audienceType` / `audienceGroupId` 更新 + ロール制約バリデーション     |
| EVT_TOGGLE_AUTHOR_ROLE        | 投稿者区分ラジオ切り替え（※両ロール保有者のみ表示） | `onToggleAuthorRole`         | `postAuthorRole` 更新 + 表示カテゴリ再計算                                          |
| EVT_CHANGE_DISPLAY_NAME_MODE  | 投稿者表示モード選択                 | `onChangeDisplayNameMode`    | `displayNameMode` 更新                                                     |
| EVT_TOGGLE_CIRCULATION        | 「回覧板として扱う」チェックボックス切り替え     | `onToggleCirculation`        | `isCirculation` 更新 + 回覧板用入力制約適用                                          |
| EVT_CHANGE_CIRC_GROUPS        | 回覧対象グループ選択                 | `onChangeCirculationGroups`  | `circulationGroupIds` 更新                                                 |
| EVT_CHANGE_CIRC_DUE           | 回覧期限日付入力変更                 | `onChangeCirculationDueDate` | `circulationDueDate` 更新                                                  |
| EVT_ATTACHMENT_ADD            | 添付ファイル選択                   | `onAddAttachment`            | `attachments` への追加 + サイズ/拡張子バリデーション                                      |
| EVT_ATTACHMENT_REMOVE         | 添付ファイル行の削除ボタン              | `onRemoveAttachment`         | `attachments` からの削除 or `isRemoved` フラグ立て                                 |

### 4.3.2 送信・キャンセル系イベント

| イベント ID               | 発火トリガー             | ハンドラ                | 主な処理内容                                     |
| --------------------- | ------------------ | ------------------- | ------------------------------------------ |
| EVT_CLICK_SUBMIT      | 「投稿する」ボタンクリック      | `onClickSubmit`     | フロントバリデーション → プレビューダイアログ表示                 |
| EVT_CONFIRM_SUBMIT    | プレビューダイアログで「はい」選択  | `onConfirmSubmit`   | API 呼び出し → 成功時に BoardDetail へ遷移            |
| EVT_CANCEL_SUBMIT     | プレビューダイアログで「いいえ」選択 | `onCancelSubmit`    | `isSubmitConfirmOpen = false` にしてダイアログを閉じる |
| EVT_CLICK_CANCEL_FORM | 画面下部キャンセルボタンクリック   | `onClickCancelForm` | 入力破棄の確認 → BoardTop など元の画面に戻る               |

---

## 4.4 主要ハンドラのロジック

### 4.4.1 `onChangeContentHtml`

```ts
function onChangeContentHtml(nextHtml: string) {
  const html = nextHtml ?? "";

  // テキスト正を抽出（最小限のタグ除去）
  const plain = html
    .replace(/<p><br\/?><\/p>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/\n+/g, "\n")
    .trim();

  setState((prev) => ({
    ...prev,
    contentHtml: html,
    content: plain,
    isDirty: true,
  }));
}
```

* TipTap エディタからは `editor.getHTML()` の結果を `nextHtml` として渡す。
* `contentHtml` には HTML をそのまま保持しつつ、`content` にはタグ除去後のプレーンテキストを格納する。
* これにより、投稿保存・翻訳/TTS/モデレーション・検索は常に `content` のみを参照すればよい。

### 4.4.2 `onToggleAuthorRole`

```ts
function onToggleAuthorRole(role: "admin" | "user") {
  setState((prev) => ({
    ...prev,
    postAuthorRole: role,
    isDirty: true,
  }));
}
```

* `hasManagementRole && hasGeneralRole` の場合のみ UI が表示される。
* 投稿者区分の変更はカテゴリ候補や表示名の扱いに影響するが、本文のエディタ種別やロジックには影響しない。

### 4.4.3 `validateForm`

```ts
function validateForm(state: BoardPostFormState): ValidationResult {
  const errors: string[] = [];

  if (!state.title.trim()) {
    errors.push("board.postForm.error.titleRequired");
  }

  // 本文（テキスト正）チェック
  if (!state.content.trim()) {
    errors.push("board.postForm.error.contentRequired");
  }

  if (!state.categoryTag) {
    errors.push("board.postForm.error.categoryRequired");
  }

  if (!state.displayNameMode) {
    errors.push("board.postForm.error.displayNameModeRequired");
  }

  if (state.audienceType === "GROUP" && !state.audienceGroupId) {
    errors.push("board.postForm.error.groupRequired");
  }

  if (state.isCirculation) {
    // 期限必須とする場合はここでチェック
    // if (!state.circulationDueDate) {
    //   errors.push("board.postForm.error.circulationDueDateRequired");
    // }
  }

  return {
    isValid: errors.length === 0,
    errorMessages: errors,
  };
}
```

* 管理組合投稿か一般投稿かに関係なく、内容の有無はテキスト正 `content` だけで判定する。

### 4.4.4 カテゴリ候補フィルタリング

（ロジック自体は v1.1 と同様。略）

---

## 4.5 投稿 API 呼び出しフロー

### 4.5.1 API インタフェース

投稿 API は ch03 3.4 で定義した DTO を用い、Next.js App Router の API を想定する。

```ts
async function upsertBoardPost(
  mode: "create" | "edit",
  postId: string | undefined,
  request: UpsertBoardPostRequest,
): Promise<UpsertBoardPostResponse> {
  const url = mode === "create" ? "/api/board/posts" : `/api/board/posts/${postId}`;
  const method = mode === "create" ? "POST" : "PATCH";

  const response = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    throw new Error("board.post.create_failed");
  }

  return (await response.json()) as UpsertBoardPostResponse;
}
```

### 4.5.2 `onClickSubmit` と確認ダイアログ

`onClickSubmit` は以下の手順で処理を行う。

1. バリデーション実行 (`validateForm`)。エラーがあればエラーメッセージを表示して中断。
2. プレビューデータの構築:

   * `title`, `categoryTag`, テキスト正 `content` の要約（先頭数十文字）, 添付ファイル名一覧などをまとめる。
3. 確認メッセージの準備:

   * i18n キー `board.postForm.confirm.submit.body`（「下記の内容で投稿します。」等）を取得。
4. `isSubmitConfirmOpen = true` に設定し、プレビューデータと共に確認ダイアログを表示する。

### 4.5.3 `onConfirmSubmit` の処理手順

```ts
async function onConfirmSubmit(state: BoardPostFormState, dispatch: Dispatch) {
  const validation = validateForm(state);
  if (!validation.isValid) {
    dispatch({ type: "SET_SUBMIT_ERROR_FROM_VALIDATION", payload: validation.errorMessages });
    return;
  }

  dispatch({ type: "SET_SUBMITTING", payload: true });

  try {
    const request: UpsertBoardPostRequest = {
      tenantId: state.tenantId,
      authorId: state.viewerUserId,
      authorRole: state.postAuthorRole,
      displayNameMode: state.displayNameMode!,
      categoryTag: state.categoryTag!,
      audienceType: state.audienceType,
      audienceGroupId: state.audienceType === "GROUP" ? state.audienceGroupId! : undefined,
      title: state.title,
      content: state.content,                     // テキスト正
      contentHtml: state.contentHtml ?? null,     // リッチHTML（空文字はnullに正規化してよい）
      isCirculation: state.isCirculation,
      circulationGroupIds: state.circulationGroupIds,
      circulationDueDate: state.circulationDueDate || undefined,
      attachments: convertAttachmentsForRequest(state.attachments),
    };

    const response = await upsertBoardPost(state.mode, state.editPostId, request);

    // 成功時: BoardDetail へ遷移
    navigateToBoardDetail(response.postId);
  } catch (error) {
    dispatch({ type: "SET_SUBMIT_ERROR", payload: "board.postForm.error.submitFailed" });
  } finally {
    dispatch({ type: "SET_SUBMITTING", payload: false });
    dispatch({ type: "SET_SUBMIT_CONFIRM_OPEN", payload: false });
  }
}
```

* API にはテキスト正 `content` と HTML `contentHtml` を別フィールドで渡す。
* バックエンド側では `content` を既存のテキスト正カラムに保存し、`contentHtml` を HTML 用カラムに保存することを前提とする。

---

## 4.6 エラーハンドリング・ロギング

* バリデーションエラー:

  * `validateForm` で検出したエラーはフィールド別エラーまたは `submitError` として表示し、API 呼び出しは行わない。
* API エラー:

  * `upsertBoardPost` で `response.ok` が false の場合、`submitError` に `"board.postForm.error.submitFailed"` を設定する。
* ログ出力:

  * 送信成功時に共通 Logger へ `board.post.submit_success` を INFO レベルで出力。
  * エラー発生時に `board.post.submit_failed` を ERROR レベルで出力（必要に応じてスタックトレースも含める）。

---

## 4.7 まとめ

本章では、BoardPostForm の状態管理およびイベント処理設計を定義し、特に本文について TipTap を全ユーザ共通で使用する前提で、

* `BoardPostFormState.content` をテキスト正（プレーンテキスト）として扱うこと。
* `BoardPostFormState.contentHtml` に TipTap HTML を保持し、表示用途にのみ使用すること。
* `onChangeContentHtml` で HTML とテキスト正を同時に更新すること。
* 投稿 API 呼び出し時に、テキスト正 `content` と HTML `contentHtml` を別フィールドで渡すこと。
* バリデーションはテキスト正 `content` のみを対象とし、HTML 有無には依存しないこと。

を明確にした。

BoardPostForm の実装および Windsurf 向け作業指示書は、本 ch04 を参照してロジック整合を取る。
