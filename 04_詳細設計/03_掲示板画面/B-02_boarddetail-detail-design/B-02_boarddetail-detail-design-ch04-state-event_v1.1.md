# B-02 BoardDetail 詳細設計書 ch04 状態管理・イベントフロー v1.1

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH04
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 4.1 本章の目的

本章では、掲示板詳細画面コンポーネント **BoardDetail（B-02）** の

* 画面状態（State）
* ユーザ操作および内部処理に伴うイベント（Event）
* 状態遷移ルール

を定義する。
BoardDetail は閲覧画面として、単一投稿の本文・添付・翻訳/TTS・コメントを表示し、コメント投稿・翻訳リクエスト・音声読み上げ・PDF プレビュー等の操作を提供する。
投稿・コメントの作成/編集/モデレーションは **B-03 BoardPostForm および API 側の責務** とし、本コンポーネントは「保存済みデータの表示」と「コメント投稿 API とのやりとり」のみに責務を限定する。

AI モデレーションの結果（allow/block 等）は API 内部および `moderation_logs` に閉じ込められ、BoardDetail は直接参照しない。
コメント投稿時に AI モデレーションによりブロックされた場合も、本コンポーネントから見ると「コメント送信エラーの一種」として扱う。

---

## 4.2 状態モデル

### 4.2.1 ルート状態 `BoardDetailState`

```ts
export type BoardDetailState = {
  // 取得対象
  postId: string;             // 現在表示している投稿 ID

  // 認証・ロール
  tenantId: string;           // 現在のテナント ID
  userId: string;             // 現在のユーザ ID
  viewerRole: string;         // 現在の閲覧者ロール（管理組合 / 一般利用者 等、共通ロール定義を利用）
  canPostComment: boolean;    // コメント投稿権限

  // ローディング・エラー
  isInitialLoading: boolean;  // 初期ロード中かどうか
  isRefreshing: boolean;      // 再取得中かどうか
  errorType: "none" | "notFound" | "forbidden" | "network" | "unknown";
  errorMessage?: string;      // エラー詳細（ユーザ向けメッセージではなく内部用）

  // メインデータ
  data?: BoardDetailPageData; // 投稿本体 + 添付 + コメント + i18n 状態 + viewerRole 等

  // コメント関連
  commentInput: string;       // コメント入力欄の内容
  isCommentSubmitting: boolean; // コメント送信中フラグ
  commentError?: string;      // コメント送信エラー（モデレーションブロック含む）

  // 翻訳/TTS 関連
  isTranslationPanelOpen: boolean; // 翻訳結果表示領域の開閉状態
  // data.i18nState に翻訳/TTS 状態の詳細を保持

  // PDF プレビュー
  isPdfPreviewOpen: boolean;  // PDF プレビューモーダルが開いているか
  previewAttachmentId?: string; // 現在プレビュー中の添付 ID
};
```

* `viewerRole` はアプリ全体で定義されるロール（例: `"management"` / `"resident"` 等）をそのまま使用し、BoardDetail 固有のロール値は定義しない。
* コメント投稿可否（`canPostComment`）は、ロール・テナント設定・掲示板種別などを総合した結果として、上位コンポーネントから渡される前提とする。

### 4.2.2 初期状態

```ts
const initialBoardDetailState: BoardDetailState = {
  postId: "", // ルーティングから設定
  tenantId: "",
  userId: "",
  viewerRole: "",
  canPostComment: false,

  isInitialLoading: true,
  isRefreshing: false,
  errorType: "none",

  data: undefined,

  commentInput: "",
  isCommentSubmitting: false,
  commentError: undefined,

  isTranslationPanelOpen: false,

  isPdfPreviewOpen: false,
  previewAttachmentId: undefined,
};
```

* 実装上は、ルーティングと認証コンテキストから `postId` / `tenantId` / `userId` / `viewerRole` / `canPostComment` を設定した上で初期ロードを開始する想定とする。

---

## 4.3 イベントモデル

### 4.3.1 イベント型定義

```ts
export type BoardDetailEvent =
  // 初期ロード / 再取得
  | { type: "FETCH_REQUESTED" }
  | { type: "FETCH_SUCCEEDED"; payload: BoardDetailPageData }
  | { type: "FETCH_FAILED"; payload: { errorType: BoardDetailState["errorType"]; errorMessage?: string } }

  // コメント入力
  | { type: "COMMENT_INPUT_CHANGED"; payload: { value: string } }
  | { type: "COMMENT_SUBMIT_REQUESTED" }
  | { type: "COMMENT_SUBMIT_SUCCEEDED"; payload: { comments: BoardCommentItem[] } }
  | { type: "COMMENT_SUBMIT_FAILED"; payload: { errorMessage?: string } }

  // 翻訳/TTS
  | { type: "TRANSLATION_PANEL_TOGGLED" }
  | { type: "TRANSLATION_REQUESTED" }
  | { type: "TRANSLATION_SUCCEEDED"; payload: { translatedText: string } }
  | { type: "TRANSLATION_FAILED"; payload: { errorMessage?: string } }
  | { type: "TTS_PLAY_REQUESTED" }
  | { type: "TTS_STOP_REQUESTED" }
  | { type: "TTS_STATE_UPDATED"; payload: { isPlaying: boolean; isLoading: boolean; errorMessage?: string } }

  // PDF プレビュー
  | { type: "PDF_PREVIEW_OPENED"; payload: { attachmentId: string } }
  | { type: "PDF_PREVIEW_CLOSED" }

  // その他
  | { type: "CLEAR_ERROR" };
```

### 4.3.2 COMMENT_SUBMIT_FAILED と AI モデレーション

`COMMENT_SUBMIT_FAILED` は、以下を含む「コメント送信に失敗した全てのケース」を表す。

* ネットワークエラー / API エラー（5xx 等）
* バリデーションエラー（コメント本文が空など）
* **AI モデレーションによるブロック**（コメント投稿 API が `errorCode = "ai_moderation_blocked"` を返却したケース）

BoardDetail は、errorCode の詳細には依存せず、`COMMENT_SUBMIT_FAILED` と `commentError` によって UI 上にメッセージを表示する。
具体的なメッセージ内容および i18n キーは ch05 で定義する。

---

## 4.4 状態遷移

### 4.4.1 初期ロード

1. 画面マウント時に `FETCH_REQUESTED` を発行する。
2. データ取得処理が成功した場合、`FETCH_SUCCEEDED` に `BoardDetailPageData` を載せて発行する。
3. 取得に失敗した場合、エラー種別に応じて `FETCH_FAILED` を発行する。

#### 4.4.1.1 `FETCH_REQUESTED`

* 目的: 投稿・コメント・添付・翻訳/TTS 状態の初期取得・再取得を開始する。
* 適用前提: `postId` / `tenantId` / `userId` / `viewerRole` / `canPostComment` が設定済みであること。

状態変化（擬似コード）：

```ts
case "FETCH_REQUESTED":
  return {
    ...state,
    isInitialLoading: state.data ? false : true,
    isRefreshing: !!state.data,
    errorType: "none",
    errorMessage: undefined,
  };
```

#### 4.4.1.2 `FETCH_SUCCEEDED`

* 目的: 取得した `BoardDetailPageData` を状態に反映し、ローディング状態を解除する。

```ts
case "FETCH_SUCCEEDED":
  return {
    ...state,
    isInitialLoading: false,
    isRefreshing: false,
    errorType: "none",
    errorMessage: undefined,
    data: action.payload,
    // コメント入力は維持 or クリア（設計方針により選択）
  };
```

#### 4.4.1.3 `FETCH_FAILED`

* 目的: エラー種別を状態に反映し、エラー画面/メッセージを表示できるようにする。

```ts
case "FETCH_FAILED":
  return {
    ...state,
    isInitialLoading: false,
    isRefreshing: false,
    errorType: action.payload.errorType,
    errorMessage: action.payload.errorMessage,
  };
```

`errorType` は少なくとも `"notFound"` / `"forbidden"` / `"network"` / `"unknown"` を想定し、それぞれに対応する UI 表現は ch05 で定義する。

---

### 4.4.2 コメント入力・送信

#### 4.4.2.1 `COMMENT_INPUT_CHANGED`

* 目的: コメント入力欄の内容を状態に反映する。

```ts
case "COMMENT_INPUT_CHANGED":
  return {
    ...state,
    commentInput: action.payload.value,
    commentError: undefined,
  };
```

#### 4.4.2.2 `COMMENT_SUBMIT_REQUESTED`

* 目的: コメント送信処理を開始する。
* 前提: `canPostComment = true` の場合のみ有効（UI 側でボタン非活性などの制御を行う）。

```ts
case "COMMENT_SUBMIT_REQUESTED":
  return {
    ...state,
    isCommentSubmitting: true,
    commentError: undefined,
  };
```

#### 4.4.2.3 `COMMENT_SUBMIT_SUCCEEDED`

* 目的: コメント送信成功時にコメント一覧を更新し、入力欄をクリアする。

```ts
case "COMMENT_SUBMIT_SUCCEEDED":
  if (!state.data) return state;
  return {
    ...state,
    isCommentSubmitting: false,
    commentInput: "",
    commentError: undefined,
    data: {
      ...state.data,
      comments: action.payload.comments,
    },
  };
```

`payload.comments` は、送信後に最新状態を取得したコメント一覧とする。
ローカルで 1 件追加する方式でもよいが、実装では API レスポンスを優先する。

#### 4.4.2.4 `COMMENT_SUBMIT_FAILED`

* 目的: コメント送信に失敗した場合に、エラーメッセージを状態に保持する。

```ts
case "COMMENT_SUBMIT_FAILED":
  return {
    ...state,
    isCommentSubmitting: false,
    commentError: action.payload.errorMessage ?? "comment_submit_failed",
  };
```

ここでの `errorMessage` には、AI モデレーションによるブロック (`errorCode = "ai_moderation_blocked"`) を含む、あらゆる送信失敗理由が含まれうる。
ユーザ向けの最終的な文言は ch05 のメッセージ仕様で定義し、本状態では識別用のキーまたは簡易メッセージを保持する。

---

### 4.4.3 翻訳/TTS

翻訳/TTS の詳細なロジックは B-04 BoardTranslationAndTtsService および共通フックに委譲し、BoardDetail 側では UI 状態の管理のみを行う。

#### 4.4.3.1 `TRANSLATION_PANEL_TOGGLED`

* 目的: 翻訳結果表示領域の開閉状態をトグルする。

```ts
case "TRANSLATION_PANEL_TOGGLED":
  return {
    ...state,
    isTranslationPanelOpen: !state.isTranslationPanelOpen,
  };
```

#### 4.4.3.2 `TRANSLATION_REQUESTED` / `TRANSLATION_SUCCEEDED` / `TRANSLATION_FAILED`

* 目的: 翻訳要求とその結果を `data.i18nState` に反映する。

```ts
case "TRANSLATION_REQUESTED":
  if (!state.data) return state;
  return {
    ...state,
    data: {
      ...state.data,
      i18nState: {
        ...state.data.i18nState,
        isTranslating: true,
        translationError: undefined,
      },
    },
  };

case "TRANSLATION_SUCCEEDED":
  if (!state.data) return state;
  return {
    ...state,
    data: {
      ...state.data,
      i18nState: {
        ...state.data.i18nState,
        isTranslating: false,
        hasTranslation: true,
        translatedText: action.payload.translatedText,
        translationError: undefined,
      },
    },
  };

case "TRANSLATION_FAILED":
  if (!state.data) return state;
  return {
    ...state,
    data: {
      ...state.data,
      i18nState: {
        ...state.data.i18nState,
        isTranslating: false,
        translationError: action.payload.errorMessage ?? "translation_failed",
      },
    },
  };
```

#### 4.4.3.3 `TTS_PLAY_REQUESTED` / `TTS_STOP_REQUESTED` / `TTS_STATE_UPDATED`

* 目的: TTS の再生状態を `data.i18nState` に反映する。

```ts
case "TTS_STATE_UPDATED":
  if (!state.data) return state;
  return {
    ...state,
    data: {
      ...state.data,
      i18nState: {
        ...state.data.i18nState,
        isTtsPlaying: action.payload.isPlaying,
        isTtsLoading: action.payload.isLoading,
        ttsError: action.payload.errorMessage,
      },
    },
  };
```

`TTS_PLAY_REQUESTED` / `TTS_STOP_REQUESTED` は、実際には共通フックやサービスへのトリガとして利用される想定であり、BoardDetailState 自体には直接の変更を伴わない場合もある。

---

### 4.4.4 PDF プレビュー

#### 4.4.4.1 `PDF_PREVIEW_OPENED`

* 目的: 指定された添付ファイルの PDF プレビューモーダルを開く。

```ts
case "PDF_PREVIEW_OPENED":
  return {
    ...state,
    isPdfPreviewOpen: true,
    previewAttachmentId: action.payload.attachmentId,
  };
```

#### 4.4.4.2 `PDF_PREVIEW_CLOSED`

* 目的: PDF プレビューモーダルを閉じる。

```ts
case "PDF_PREVIEW_CLOSED":
  return {
    ...state,
    isPdfPreviewOpen: false,
    previewAttachmentId: undefined,
  };
```

PDF ビューア自体のスクロールや操作は共通コンポーネントに委譲し、BoardDetail は「どの添付をプレビュー中か」と「モーダルの開閉状態」のみを管理する。

---

## 4.5 エラークリア

### 4.5.1 `CLEAR_ERROR`

* 目的: 一時的なエラーをクリアし、再操作を可能にする。

```ts
case "CLEAR_ERROR":
  return {
    ...state,
    errorType: "none",
    errorMessage: undefined,
    commentError: undefined,
  };
```

`CLEAR_ERROR` は、ユーザがエラー表示部分をタップしたり、「再読み込み」ボタンを押下したタイミングなどで発行される想定とする。

---

## 4.6 ログ・監視との関係

BoardDetail は、logger 共通コンポーネントを通じて主要イベントのみをログ出力する。
ログの設計詳細は共通ロガー詳細設計に従い、本章では「どのタイミングでログを呼ぶか」のみを整理する。

* 初期ロード失敗時（`FETCH_FAILED`）

  * イベント種別: `board.detail.fetch.failed`
  * 属性: `postId`, `tenantId`, `errorType`
* コメント送信失敗時（`COMMENT_SUBMIT_FAILED`）

  * イベント種別: `board.detail.comment.submit_failed`
  * 属性: `postId`, `tenantId`, エラー種別（モデレーションブロックを含む）
* 翻訳/TTS エラー時（`TRANSLATION_FAILED` / `TTS_STATE_UPDATED` with error）

  * イベント種別: `board.detail.translation.failed`, `board.detail.tts.failed` 等

AI モデレーションの詳細ログ（スコア/理由）は、API 側で `moderation_logs` に記録される前提とし、BoardDetail からは一切アクセスしない。

---

## 4.7 トレースと他章との関係

* ch01 概要

  * BoardDetail が「閲覧専用画面」であること、および B-03 との責務分担を定義。
* ch02 レイアウト

  * 本章で定義した状態/イベントに対応する UI 構造（ヘッダー／本文／添付／翻訳/TTS／コメント／フッター／PDF モーダル）を定義。
* ch03 データモデル

  * `BoardDetailPageData` / `BoardPostDetail` / `BoardAttachmentItem` / `BoardCommentItem` / `BoardPostI18nState` 等、本章の状態/イベントが利用する DTO を定義。
* B-03 BoardPostForm ch08 AI モデレーション

  * コメント投稿・編集時の AI モデレーションロジックは B-03＋API 側の責務とし、BoardDetail は送信結果のみを扱うことを明示。
* B-04 BoardTranslationAndTtsService

  * 翻訳/TTS の実行およびキャッシュは B-04 側の責務とし、本章は UI 状態の反映に限定する。

本章 v1.1 は、B-02 ch01〜ch03 v1.1/1.2 および B-03/B-04 系詳細設計、AI モデレーション仕様に整合する形で定義されている。
今後、コメント機能の拡張や翻訳/TTS・モデレーション仕様の変更が発生した場合は、本章のイベント・状態に必要な差分を反映し、バージョンを 1.2 以降に引き上げて履歴を管理する。
