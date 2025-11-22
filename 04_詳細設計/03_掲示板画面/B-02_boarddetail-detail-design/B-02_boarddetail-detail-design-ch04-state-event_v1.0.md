# B-02 BoardDetail 詳細設計書 ch04 状態管理・イベント遷移 v1.0

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH04  
**Version:** 1.0  
**Supersedes:** -  
**Created:** 2025-11-22  
**Updated:** 2025-11-22  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** Draft

---

## 4.1 本章の目的

本章では、掲示板詳細画面コンポーネント BoardDetail（B-02）における **状態管理** と **ユーザインタラクションイベント** を定義する。  
対象はフロントエンドの状態のみとし、DB スキーマ（`schema.prisma`）はすでに正として確定している前提で扱う。Windsurf は本章を参照して、React コンポーネント内の `useState` / `useReducer` / カスタムフックの実装を行う。

扱う主な状態は次の通り。

- 投稿本体（BoardPostDetail）
- 添付一覧
- コメント一覧・入力中コメント
- 翻訳/TTS 状態
- PDF プレビューモーダルの開閉・対象ファイル
- ローディング状態・エラー状態・権限不足状態

---

## 4.2 状態モデル（State）

### 4.2.1 画面全体の状態構造

BoardDetailPage が保持する状態を論理型として定義する。

```ts
export type BoardDetailState = {
  // ベース情報
  postId: string;                    // URL パラメータ [postId]

  // ロール・権限（認証コンテキストから供給）
  viewerRole: "admin" | "user";    // 管理組合 or 一般利用者
  canPostComment: boolean;           // コメント投稿権限

  // データ本体
  post: BoardPostDetail | null;      // 投稿詳細（未取得時は null）
  attachments: BoardAttachmentItem[];// 添付一覧
  comments: BoardCommentItem[];      // コメント一覧

  // 翻訳/TTS 状態
  i18nState: BoardPostI18nState;     // ch03 で定義した翻訳/TTS 状態 DTO

  // コメント入力
  commentInput: string;              // 入力中コメント本文
  isCommentSubmitting: boolean;      // コメント送信中フラグ

  // PDF プレビュー
  isPdfPreviewOpen: boolean;         // PDF プレビューモーダル表示中かどうか
  activeAttachmentId: string | null; // 現在プレビュー中の添付ID

  // ローディング・エラー
  isLoading: boolean;                // 画面全体の初回/再取得中フラグ
  isError: boolean;                  // 取得エラーフラグ
  errorType: "none" | "notFound" | "forbidden" | "network" | "unknown"; // エラー種別
};
```

`BoardPostDetail` / `BoardAttachmentItem` / `BoardCommentItem` / `BoardPostI18nState` は ch03 で定義した DTO を参照する。

### 4.2.2 初期状態

BoardDetailPage の初期状態は、URL パラメータおよび認証コンテキストに基づき次のように決定する。

- `postId`: ルーティングから受け取った `[postId]` をそのまま格納。
- `viewerRole`: 認証コンテキストから供給されたロール値。
- `canPostComment`: ロール/権限情報から導出済みの値（BoardDetail 内では判定しない）。
- `post`: `null`
- `attachments`: `[]`
- `comments`: `[]`
- `i18nState`: 初期値として、原文言語/対象言語をアプリ共通設定から設定。`hasTranslation = false`, `isTranslating = false`, TTS 関連フラグも `false` とする。
- `commentInput`: 空文字列
- `isCommentSubmitting`: `false`
- `isPdfPreviewOpen`: `false`
- `activeAttachmentId`: `null`
- `isLoading`: `true`（初回取得中）
- `isError`: `false`
- `errorType`: `"none"`

---

## 4.3 イベントモデル（Event）

### 4.3.1 イベント一覧

BoardDetail で発生する主なイベントを次のとおり定義する。

```ts
export type BoardDetailEvent =
  // 初期化・取得
  | { type: "INIT"; payload: { postId: string } }
  | { type: "FETCH_STARTED" }
  | { type: "FETCH_SUCCEEDED"; payload: BoardDetailPageData }
  | { type: "FETCH_FAILED"; payload: { errorType: BoardDetailState["errorType"] } }

  // コメント入力・送信
  | { type: "COMMENT_INPUT_CHANGED"; payload: { value: string } }
  | { type: "COMMENT_SUBMIT_REQUESTED" }
  | { type: "COMMENT_SUBMIT_SUCCEEDED"; payload: { comment: BoardCommentItem } }
  | { type: "COMMENT_SUBMIT_FAILED" }

  // 翻訳/TTS
  | { type: "TRANSLATION_REQUESTED" }
  | { type: "TRANSLATION_SUCCEEDED"; payload: { translatedText: string } }
  | { type: "TRANSLATION_FAILED"; payload: { error: string } }
  | { type: "LANGUAGE_SWITCHED"; payload: { targetLanguage: string } }
  | { type: "TTS_PLAY_REQUESTED" }
  | { type: "TTS_PLAY_STARTED" }
  | { type: "TTS_PLAY_STOPPED" }
  | { type: "TTS_FAILED"; payload: { error: string } }

  // PDF プレビュー
  | { type: "PDF_PREVIEW_OPENED"; payload: { attachmentId: string } }
  | { type: "PDF_PREVIEW_CLOSED" };
```

### 4.3.2 イベント発生源

- `INIT`
  - BoardDetailPage マウント時に 1 回だけ発生。URL から `postId` を受け取り、初回取得を開始する。
- `FETCH_STARTED` / `FETCH_SUCCEEDED` / `FETCH_FAILED`
  - 単一投稿・コメント・添付・翻訳/TTS 状態をまとめて取得する処理の中で発火。
- `COMMENT_INPUT_CHANGED`
  - コメント入力欄の onChange で発火。
- `COMMENT_SUBMIT_REQUESTED`
  - 「コメントを投稿」ボタン押下時に発火。
- `COMMENT_SUBMIT_SUCCEEDED` / `COMMENT_SUBMIT_FAILED`
  - コメント投稿 API の結果に応じて発火。
- `TRANSLATION_REQUESTED` / `TRANSLATION_SUCCEEDED` / `TRANSLATION_FAILED`
  - 翻訳ボタン押下および翻訳処理完了時に発火。
- `LANGUAGE_SWITCHED`
  - 言語切替操作（原文/翻訳文タブ、または表示言語変更）で発火。
- `TTS_PLAY_REQUESTED` / `TTS_PLAY_STARTED` / `TTS_PLAY_STOPPED` / `TTS_FAILED`
  - TTS 再生ボタンの押下や再生完了/失敗時に発火。
- `PDF_PREVIEW_OPENED` / `PDF_PREVIEW_CLOSED`
  - 添付一覧の行クリック、および PDF プレビューモーダルの閉じる操作で発火。

---

## 4.4 状態遷移

### 4.4.1 初期化〜初回取得

1. BoardDetailPage マウント時に `INIT` イベントが発行される。
2. `INIT` により `postId` を `BoardDetailState.postId` に設定し、`FETCH_STARTED` を発行する。
3. `FETCH_STARTED` により、`isLoading = true`, `isError = false`, `errorType = "none"` に設定する。
4. 単一投稿・添付・コメント・翻訳/TTS 状態を取得する。
   - 成功時: `FETCH_SUCCEEDED` により `post` / `attachments` / `comments` / `i18nState` を更新し、`isLoading = false` とする。
   - 失敗時: `FETCH_FAILED` により `isLoading = false`, `isError = true`, `errorType` をエラー種別に設定する。

### 4.4.2 コメント入力・送信

- 入力中
  1. コメント入力欄の変更で `COMMENT_INPUT_CHANGED` が発生し、`commentInput` を更新する。

- 送信時
  1. 「コメントを投稿」ボタン押下で `COMMENT_SUBMIT_REQUESTED` が発生し、`isCommentSubmitting = true` とする。
  2. コメント投稿 API を呼び出す。
     - 成功時: `COMMENT_SUBMIT_SUCCEEDED` により、`comments` リストに新しいコメントを追加し、`commentInput` を空文字列にリセットする。`isCommentSubmitting = false`。
     - 失敗時: `COMMENT_SUBMIT_FAILED` により、`isCommentSubmitting = false` とし、エラーメッセージは ch05 のメッセージ仕様に従って表示する。

### 4.4.3 翻訳・言語切替

- 翻訳要求
  1. 翻訳ボタン押下で `TRANSLATION_REQUESTED` が発生し、`i18nState.isTranslating = true`, `translationError = undefined` とする。
  2. 翻訳 API 呼び出しが成功した場合は `TRANSLATION_SUCCEEDED` により `translatedText` を更新し、`hasTranslation = true`, `isTranslating = false` とする。
  3. 失敗した場合は `TRANSLATION_FAILED` により `isTranslating = false`, `translationError` を設定する。

- 言語切替
  1. 利用者が表示言語（原文/翻訳文）を切り替える操作を行うと、`LANGUAGE_SWITCHED` が発生する。
  2. `targetLanguage` を更新し、それに応じて表示テキスト（原文か翻訳文か）を UI 側で切り替える。

### 4.4.4 TTS（音声読み上げ）

1. 利用者が TTS ボタンを押下すると `TTS_PLAY_REQUESTED` が発生する。
2. TTS 実行開始時に `TTS_PLAY_STARTED` を発行し、`isTtsLoading = false`, `isTtsPlaying = true` に設定する。
3. 再生完了またはユーザによる停止操作で `TTS_PLAY_STOPPED` が発生し、`isTtsPlaying = false` とする。
4. エラー発生時には `TTS_FAILED` が発生し、`isTtsPlaying = false`, `isTtsLoading = false`, `ttsError` を設定する。

TTS の実際の音声生成・再生処理は共通コンポーネント側に委譲し、BoardDetail では状態の切り替えとメッセージ表示に集中する。

### 4.4.5 PDF プレビュー

1. 添付一覧の行クリックで `PDF_PREVIEW_OPENED` が発生し、`activeAttachmentId` に対象の添付IDを設定し、`isPdfPreviewOpen = true` とする。
2. モーダルの上部「閉じる」または下部「タップで閉じる」領域をタップした場合、`PDF_PREVIEW_CLOSED` が発生し、`isPdfPreviewOpen = false`, `activeAttachmentId = null` とする。

---

## 4.5 状態管理実装方針（Windsurf 向けガイド）

1. BoardDetailPage 内に状態管理を閉じ込めるか、`useBoardDetailState` のようなカスタムフックに切り出すかは実装時に判断してよい。ただし、型・イベント定義は本章に準拠すること。
2. データ取得は共通データアクセス API（例: `fetchBoardDetailPage`）を経由し、BoardDetail 内では Supabase クエリを直接記述しない方針とする（実装都合で例外が必要な場合は設計書側を更新）。
3. 翻訳/TTS に関する API 呼び出しは共通コンポーネント/フックに委譲し、BoardDetail では「ボタン押下 → 状態更新」までを実装する。
4. コメント送信時は二重送信防止のため `isCommentSubmitting` を用い、送信中はボタンを無効化する。
5. 将来、コメントのページングやソートなどが必要になった場合は、状態・イベントを拡張し、本章を v1.1 以降として更新する。

---

## 4.6 ログ出力仕様

BoardDetail におけるログ出力は、共通 Logger 詳細設計書（別文書）で定義された API（例: `logInfo`, `logError`）を利用し、以下のイベントで出力する。

### 4.6.1 ログ出力対象イベント

| タイミング                                | レベル | event 名                             | context 例                                                       |
|-------------------------------------------|--------|--------------------------------------|------------------------------------------------------------------|
| 詳細取得開始 (`FETCH_STARTED`)             | INFO   | `"board.detail.fetch.start"`       | `{ postId, viewerRole }`                                        |
| 詳細取得成功 (`FETCH_SUCCEEDED`)           | INFO   | `"board.detail.fetch.success"`     | `{ postId, viewerRole, hasAttachments, commentCount }`          |
| 詳細取得失敗 (`FETCH_FAILED`)              | ERROR  | `"board.detail.fetch.error"`       | `{ postId, viewerRole, errorType }`                             |
| コメント送信成功 (`COMMENT_SUBMIT_SUCCEEDED`) | INFO   | `"board.detail.comment.success"`   | `{ postId, viewerRole, commentId }`                             |
| コメント送信失敗 (`COMMENT_SUBMIT_FAILED`)   | ERROR  | `"board.detail.comment.error"`     | `{ postId, viewerRole }`                                        |
| 翻訳エラー (`TRANSLATION_FAILED`)          | ERROR  | `"board.detail.translation.error"` | `{ postId, viewerRole, targetLanguage }`                        |
| TTS エラー (`TTS_FAILED`)                  | ERROR  | `"board.detail.tts.error"`         | `{ postId, viewerRole, targetLanguage }`                        |

- `hasAttachments` は `attachments.length > 0` の真偽値。  
- `commentCount` は取得したコメント件数（`comments.length`）。

### 4.6.2 実装上の注意

- 実際の logger 呼び出しコードは BoardDetailPage または関連フック内に実装し、各 UI コンポーネント（コメント入力欄やボタン）から直接 logger を呼び出さない。
- ログ出力の具体的な形式（JSON 構造、タイムスタンプ、出力先）は共通 Logger 詳細設計書に従う。本章では event 名と context に含めるべき項目のみを定義する。

