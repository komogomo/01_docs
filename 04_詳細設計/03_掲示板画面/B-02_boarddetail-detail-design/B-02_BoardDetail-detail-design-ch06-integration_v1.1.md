# B-02 BoardDetail 詳細設計書 ch06 結合構成・インタフェース v1.1

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH06
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 6.1 本章の目的

本章では、掲示板詳細画面コンポーネント **BoardDetail（B-02）** が他コンポーネント・サービスとどのように結合するかを定義する。
対象は主に以下を含む。

* レイアウト／共通 UI コンポーネントとの結合
* 翻訳/TTS サービス（B-04）との結合
* 掲示板投稿/コメント API との結合
* BoardTop（B-01）・BoardPostForm（B-03）との画面遷移
* Logger 等の共通基盤との結合

BoardDetail はあくまで「閲覧＋コメント投稿 UI」を担う画面であり、投稿・編集・AI モデレーションのロジックは B-03 BoardPostForm および API 側の責務とする。

---

## 6.2 結合対象一覧

BoardDetail が結合する主なコンポーネント・サービスを一覧として示す。

| ID   | 結合先                           | 種別        | 役割/備考                                                            |
| ---- | ----------------------------- | --------- | ---------------------------------------------------------------- |
| C-01 | AppHeader                     | UIコンポーネント | 画面上部の共通ヘッダー。タイトルやグローバルナビを表示。                                     |
| C-02 | AppFooter                     | UIコンポーネント | 画面下部の共通フッター。コピーライト等。                                             |
| C-03 | LanguageSwitch                | UIコンポーネント | 言語切替 UI。BoardDetail 自身は props を受け取るのみ。                           |
| C-04 | StaticI18nProvider            | i18n基盤    | 文言辞書の提供。`board.detail.*` プレフィックスのキーを使用。                          |
| B-01 | BoardTop                      | 画面        | 一覧画面。BoardDetail への遷移元/削除後の戻り先。                                  |
| B-03 | BoardPostForm                 | 画面        | 投稿・編集フォーム。返信/編集ボタンから遷移。AI モデレーション含め投稿ロジックを担当。                    |
| B-04 | BoardTranslationAndTtsService | サービス      | 翻訳/TTS 処理およびキャッシュ管理。                                             |
| S-01 | BoardDetailDataService        | サービス      | `fetchBoardDetailPage` / `postBoardComment` / 削除 API などデータアクセス層。 |
| S-02 | PdfViewer                     | UIコンポーネント | PDF プレビューモーダルで利用するビューアコンポーネント。                                   |
| S-03 | Logger                        | 共通サービス    | 重要イベントのログ出力（fetch失敗、コメント送信失敗など）。                                 |

---

## 6.3 レイアウト・共通コンポーネントとの結合

### 6.3.1 画面レイアウト

BoardDetail はアプリ共通レイアウト内の 1 画面として配置される。

* `RootLayout`

  * `AppHeader`
  * `Main`（画面ごとのコンテンツ）

    * `BoardDetailPage`（本コンポーネント）
  * `AppFooter`

LanguageSwitch / StaticI18nProvider は RootLayout 側で適用済みとし、
BoardDetail 側では i18n キーとテキストのみを扱う。

### 6.3.2 認証・ロールとの結合

* 認証コンテキストから、以下の情報を取得し BoardDetail に渡す。

  * `tenantId: string`
  * `userId: string`
  * `viewerRole: string`（共通ロール定義。例: `"management"` / `"resident"` 等）
* コメント投稿可否（`canPostComment: boolean`）は、ロール・テナント設定・掲示板設定（コメント機能 ON/OFF）等を総合した判定結果として、親コンポーネントから渡される前提とする。

BoardDetail はこれらの値を「表示制御（ボタン表示/非表示）と送信可否チェック」にのみ利用し、
新たなロール判定ロジックは持たない。

---

## 6.4 データアクセス層との結合

データアクセスは `BoardDetailDataService` を介して行う。実際には React Query やカスタムフックとして実装される想定だが、本章では論理インタフェースのみ定義する。

### 6.4.1 投稿詳細取得 `fetchBoardDetailPage`

```ts
export type BoardDetailQueryInput = {
  tenantId: string;
  userId: string;
  viewerRole: string;
  postId: string;
};

export type BoardDetailDataService = {
  fetchBoardDetailPage: (input: BoardDetailQueryInput) => Promise<BoardDetailPageData>;
};
```

* BoardDetail は `FETCH_REQUESTED` イベントに応じて `fetchBoardDetailPage` を呼び出し、
  成功時に `FETCH_SUCCEEDED`, 失敗時に `FETCH_FAILED` をディスパッチする（詳細は ch04）。
* 取得対象は B-02 ch03 で定義した `BoardDetailPageData`（投稿本体 + 添付 + コメント + i18n 状態 + viewerRole 等）。

### 6.4.2 コメント投稿 `postBoardComment`

```ts
export type PostBoardCommentInput = {
  tenantId: string;
  userId: string;
  postId: string;
  content: string;
};

export type PostBoardCommentResult =
  | { ok: true; comments: BoardCommentItem[] }
  | { ok: false; errorCode: string; message?: string };

export type BoardDetailDataService = {
  // ...
  postBoardComment: (input: PostBoardCommentInput) => Promise<PostBoardCommentResult>;
};
```

* BoardDetail は `COMMENT_SUBMIT_REQUESTED` イベントに応じて `postBoardComment` を呼び出す。
* `ok: true` の場合、`comments` を `COMMENT_SUBMIT_SUCCEEDED` の payload として dispatch し、コメント一覧を更新する。
* `ok: false` の場合、`errorCode` に応じて `COMMENT_SUBMIT_FAILED` を dispatch する。

  * 一般的な送信失敗: `errorCode = "network_error"` 等
  * AI モデレーションによるブロック: `errorCode = "ai_moderation_blocked"`
* BoardDetail 側では、`errorCode` をメッセージキーにマッピングして `commentError` として保持し、
  表示文言は ch05 の `board.detail.comment.submit.*` を利用する。

### 6.4.3 投稿・コメント削除 API

BoardDetail は、投稿およびコメント削除操作のトリガとして、論理削除 API を呼び出す。

```ts
export type DeleteBoardPostResult = { ok: boolean; errorCode?: string };
export type DeleteBoardCommentResult = { ok: boolean; errorCode?: string };

export type BoardDetailDataService = {
  // ...
  deleteBoardPost: (params: { tenantId: string; postId: string }) => Promise<DeleteBoardPostResult>;
  deleteBoardComment: (params: { tenantId: string; commentId: string }) => Promise<DeleteBoardCommentResult>;
};
```

* `deleteBoardPost`

  * バックエンド側では物理削除ではなく、`status` を `archived` / `deleted` 等に変更する論理削除を行う。
  * `ok: true` の場合、BoardDetail は BoardTop (`/board`) へ遷移し、削除成功メッセージ表示は BoardTop 側に委譲する。
  * `ok: false` の場合、`board.detail.post.delete.error` を表示し、画面は BoardDetail のままとする。

* `deleteBoardComment`

  * バックエンド側ではコメントの `status` 更新やフラグ更新により論理削除を行う。
  * `ok: true` の場合、コメント一覧を再取得するか、該当コメントをローカルから除外する。
  * `ok: false` の場合、`board.detail.comment.delete.error` を表示する。

削除 API の URL や HTTP メソッド（DELETE vs POST）はバックエンド設計に委ね、BoardDetail からは抽象化されたサービスインタフェースとして扱う。

---

## 6.5 BoardTop / BoardPostForm との連携

### 6.5.1 BoardTop から BoardDetail への遷移

* BoardTop の投稿一覧カードから、`/board/[postId]` に遷移する。
* 遷移時に必要な情報:

  * URL パラメータ: `postId`
  * テナントコンテキスト: `tenantId`
* BoardDetail 側で再度 `fetchBoardDetailPage` を実行し、最新データを取得する。

### 6.5.2 BoardDetail から BoardTop への遷移

* フッターの「掲示板に戻る」ボタン、および投稿削除成功時の戻り先として BoardTop (`/board`) を使用する。
* ブラウザバックには依存せず、常に `/board` を明示的に指定する。

### 6.5.3 BoardDetail から BoardPostForm への遷移（返信・編集）

* 返信ボタン押下時:

  * B-03 BoardPostForm を「返信モード」で呼び出す。
  * 遷移先の例: `/board/new?replyTo={postId}`
  * 実際の URL・クエリパラメータは B-03 側の詳細設計およびルーティング設計に従う。

* 編集ボタン押下時:

  * B-03 BoardPostForm を「編集モード」で呼び出す。
  * 遷移先の例: `/board/{postId}/edit`

返信・編集完了後の戻り先は BoardDetail (`/board/{postId}`) とし、編集結果を反映した状態で再表示されるようにする。
BoardPostForm 側で成功時に `postId` を返却し、それを使って BoardDetail に遷移する想定とする。

---

## 6.6 翻訳/TTS・PDF ビューアとの結合

### 6.6.1 翻訳/TTS サービス（B-04）

* BoardDetail からは、共通フック／サービスを通じて B-04 BoardTranslationAndTtsService を呼び出す。
* 主な I/F（論理レベル）:

  * `requestBoardPostTranslation(postId, targetLanguage)`
  * `requestBoardPostTts(postId, targetLanguage)`
* BoardDetail は、翻訳開始/完了/失敗、TTS 再生/停止/エラーなどの状態を `BoardPostI18nState` に反映し、UI のみに反映する。
* 翻訳結果や TTS キャッシュの保存先（`board_post_translations` など）は B-04 側の責務とし、BoardDetail は関知しない。

### 6.6.2 PDF ビューア

* 添付一覧から PDF ファイルを選択した場合、`BoardDetailPdfPreviewModal` を開き、`PdfViewer` コンポーネントに `fileUrl` を渡す。
* PDF ビューアは、スクロール・ズームなどの操作を内部で処理し、BoardDetail は「どのファイルをプレビューしているか」と「開閉状態」のみを状態として管理する。

---

## 6.7 Logger・監視との結合

* BoardDetail からは共通 Logger を利用して、以下のタイミングでログを出力する。

  * 初期ロード失敗（`FETCH_FAILED`）
  * コメント送信失敗（`COMMENT_SUBMIT_FAILED`、AI モデレーションブロックを含む）
  * 翻訳/TTS エラー（`TRANSLATION_FAILED` / `TTS_STATE_UPDATED` with error）
* ログのフォーマット・出力先（Vercel ログ、Supabase ログ等）は共通ロガー詳細設計に従う。
  本章では「どのタイミングでログを呼ぶか」のみを定義する。

AI モデレーションの詳細な結果（スコア・理由）は、API 側で `moderation_logs` に記録される前提とし、BoardDetail からは参照しない。

---

## 6.8 トレースと整合性

* B-02 ch01〜ch05

  * 役割・レイアウト・データモデル・状態管理・UI 仕様と、本章の結合関係が相互に整合することを前提とする。
* B-03 BoardPostForm ch01〜ch08

  * 投稿/編集/AI モデレーションのロジックと、BoardDetail からの遷移・メッセージ表示の境界を定義。
* B-04 BoardTranslationAndTtsService ch01〜ch07

  * 翻訳/TTS 呼び出しに関する I/F と責務分担。
* `schema.prisma`

  * `board_posts` / `board_comments` / `board_attachments` / 翻訳キャッシュ / `moderation_logs` など、DB 側の唯一の正。

本章 v1.1 は、B-03/B-04 および AI モデレーション仕様（B-03 ch08）、最新の B-02 ch01〜ch05 と整合するように結合構成を定義している。
今後、API の URL やレスポンス形式に変更が入った場合は、本章のインタフェース定義を v1.2 以降で更新し、履歴を管理する。
