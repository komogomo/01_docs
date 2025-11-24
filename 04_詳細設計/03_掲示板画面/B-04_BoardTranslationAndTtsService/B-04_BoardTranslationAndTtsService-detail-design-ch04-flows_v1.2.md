# B-04 BoardTranslationAndTtsService 詳細設計書 ch04 掲示板詳細画面との連携（翻訳・TTS 利用フロー） v1.3

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH04
**Version:** 1.3
**Supersedes:** v1.2
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 4.1 本章の目的

本章では、B-04 BoardTranslationAndTtsService と掲示板画面（B-02 BoardDetail / B-03 BoardPostForm）との連携フローを定義する。

* 投稿時の初回翻訳フロー（B-03 → B-04）
* **返信（コメント）投稿時の初回翻訳フロー（B-02/B-03 → B-04）**
* 掲示板詳細画面におけるオンデマンド翻訳フロー（投稿・返信）
* 掲示板詳細画面における音声読み上げ（TTS）フロー
* Route Handler / Supabase Edge Function の責務分担

本章では、掲示板投稿（board_posts）と返信（board_comments）の双方について、翻訳キャッシュを用いた連携フローと、翻訳失敗時にも投稿・返信処理を継続可能とするフェイルソフト設計を定義する。

* 返信（board_comments）用キャッシュ `board_comment_translations` を利用したフロー
* 投稿・返信いずれも「翻訳失敗は投稿／返信の失敗としない」フェイルソフト設計

を明示する。

---

## 4.2 投稿時翻訳フロー（B-03 → B-04）

### 4.2.1 新規投稿時の初回翻訳

新規投稿時の処理フローは、掲示板投稿テーブル `board_posts` と投稿用翻訳キャッシュ `board_post_translations` を対象とし、以下の通りとする。`board_post_translations` を対象とする。

1. 利用者が B-03 BoardPostForm から投稿内容を入力し、「投稿する」を押下。

2. クライアント側で入力バリデーション → 確認ダイアログ表示。

3. 確認後、投稿作成 API（例: `POST /api/board/posts`）を呼び出す。

4. Route Handler 内で以下を実行。

   1. 原文（タイトル／本文）を `board_posts` に保存し、`postId` を確定。

   2. 次のパラメータを用いて `BoardPostTranslationService.translateAndCacheForPost` を呼び出す。

      * `tenantId`
      * `postId`
      * `sourceLang`（例: 'ja'）
      * `targetLangs`（例: ['en', 'zh']）
      * `originalTitle` / `originalBody`

   3. 翻訳処理は `try / catch` でラップし、失敗時は:

      * Logger に WARN または ERROR として記録（例: `"board.translation.failed"`）。
      * 投稿 API のレスポンスは **成功（200/201）** として返す。

5. B-03 は `postId` を受け取り、B-02 BoardDetail (`/board/[postId]`) に遷移する。

6. 翻訳成功時は B-02/B-01 から `board_post_translations` を参照して翻訳済み本文を表示できる。失敗時は、後述のオンデマンド翻訳フローにより補完される。

> 翻訳失敗は投稿本体のロールバック条件としない。掲示板本体の可用性を優先する。

---

## 4.3 返信投稿時翻訳フロー（B-02/B-03 → B-04）

### 4.3.1 返信投稿 API の前提

返信投稿は、掲示板詳細画面（B-02）または別フォームから、以下のような API を通じて行う想定とする。

* `POST /api/board/posts/{postId}/comments`

Request には少なくとも次を含む。

* `tenantId`
* `postId`
* `authorId`
* `content`（返信本文・原文）

### 4.3.2 返信投稿時の翻訳フロー

1. 利用者が B-02 BoardDetail 上の返信入力欄に本文を入力し、「返信を投稿」ボタンを押下。

2. クライアント側で入力バリデーション（空チェック等）を実施。

3. `POST /api/board/posts/{postId}/comments` を呼び出す。

4. Route Handler 内で以下を実行。

   1. `board_comments` に返信の原文本文を保存し、`commentId` を確定。

   2. 次のパラメータを用いて `BoardPostTranslationService.translateAndCacheForComment` を呼び出す。

      * `tenantId`
      * `commentId`
      * `sourceLang`
      * `targetLangs`
      * `originalBody`（返信本文）

   3. 翻訳処理は `try / catch` でラップし、失敗時は:

      * Logger に WARN/ERROR を記録（event 例: `"board.comment.translation.failed"`）。
      * 返信投稿 API のレスポンスは **成功** として返し、返信本文（原文）のみが即時表示される。

5. B-02 はレスポンス内の `commentId` を受け取り、画面上に返信を追加表示する。

6. 翻訳が成功していれば、次回以降の表示時に `board_comment_translations` から翻訳済み本文を取得できる。

> 返信の翻訳も投稿と同様、「失敗しても返信自体は成功」とするフェイルソフト設計とする。

---

## 4.4 オンデマンド翻訳フロー（投稿・返信）

### 4.4.1 投稿のオンデマンド翻訳（復習）

投稿本文のオンデマンド翻訳フローは v1.2 と同様であり、以下の通りとする。

1. B-02 初期表示時、`board_post_translations` に `postId + displayLang` のキャッシュがあるか確認。
2. 無い場合のみ、翻訳アイコンを有効状態で表示。
3. 翻訳アイコン押下時:

   * `POST /api/board/posts/{postId}/translate` を呼び、
   * Route Handler 内で `translateAndCacheForPost` を `targetLangs = [displayLang]` で呼び出す。
   * 成功時は翻訳結果を返し、B-02 で本文を差し替え。
   * 失敗時は原文のままとし、UI には汎用エラーを表示（文言は B-02 側）。

### 4.4.2 返信のオンデマンド翻訳

返信に対しても、投稿と同様にオンデマンド翻訳を実行できるようにする。

1. B-02 初期表示時、各コメントに対して次を行う。

   1. 現在の表示言語 `displayLang` を取得。
   2. `board_comment_translations` に `commentId + displayLang` のキャッシュがあるか確認。
   3. キャッシュが存在する場合:

      * 翻訳済み本文を表示し、翻訳アイコンは「翻訳済み」状態とする（詳細表示仕様は B-02 にて定義）。
   4. キャッシュが存在しない場合:

      * 原文本文を表示し、各コメントの翻訳アイコンを有効にする。

2. 利用者が特定コメントの翻訳アイコンを押下した場合:

   1. B-02 は翻訳 API 用 Route Handler を呼び出す。

      * 例: `POST /api/board/comments/{commentId}/translate`
      * リクエストには `tenantId` と `displayLang` を含める。

   2. Route Handler 内で `BoardPostTranslationService.translateAndCacheForComment` を呼び出し、

      * `targetLangs = [displayLang]` とする。
      * 成功時: `board_comment_translations` に INSERT/UPDATE し、直近の翻訳結果をレスポンスとして返す。
      * 失敗時: エラーコードと汎用メッセージを返す。

   3. B-02 はレスポンスに応じてコメント本文を翻訳済みテキストに差し替え、翻訳アイコン表示を更新する。

> 投稿と返信で API パスは分けてもよいし、共通 Route で `entityType = 'post' | 'comment'` を受ける構造でもよい。設計書上は「投稿用・返信用に個別のエンドポイントを用意する」前提で記述する。

---

## 4.5 TTS フロー（B-02 視点）

### 4.5.1 投稿本文の TTS

投稿本文に対する TTS フローは v1.2 と同様とする。

1. B-02 初期表示時、本文と `displayLang` を保持し、音声読み上げボタンを表示。
2. ボタン押下時:

   * `POST /api/board/posts/{postId}/tts` を呼び出す。
   * Route Handler 内で `BoardPostTtsService.synthesizePostBody` を通じて TTS API を実行。
   * 成功時は音声バイナリを返却し、B-02 で再生。
   * 失敗時は汎用エラーメッセージのみ返し、再生は行わない。

### 4.5.2 返信本文の TTS

返信本文も投稿と同様に TTS 対象とする。

1. 各コメントに対して音声読み上げボタンを表示（B-02 側仕様）。
2. ボタン押下時:

   * `POST /api/board/comments/{commentId}/tts` を呼び出す。
   * Route Handler 内で `BoardPostTtsService.synthesizeCommentBody`（名称は任意）を呼び、

     * コメント本文（原文または翻訳済み）を読み上げ対象テキストとして渡す。
   * 成功時は音声バイナリを返し、クライアント側で再生。
   * 失敗時は投稿本文同様に汎用エラーとして扱う。

> v1.3 時点では、TTS 結果のキャッシュは行わず、毎回オンデマンドで TTS API を呼ぶ。

---

## 4.6 Route Handler / Edge Function の責務分担

### 4.6.1 Route Handler

オンライン処理（ユーザ操作に対する即時応答）はすべて Next.js Route Handler が担当する。

主なエンドポイント例:

* `POST /api/board/posts` … 新規投稿作成 + 投稿翻訳トリガ
* `PATCH /api/board/posts/{postId}` … 編集 + 必要時のみ再翻訳（タイトル／本文変更時）
* `POST /api/board/posts/{postId}/comments` … 返信投稿 + 返信翻訳トリガ
* `POST /api/board/posts/{postId}/translate` … 投稿本文オンデマンド翻訳
* `POST /api/board/comments/{commentId}/translate` … 返信オンデマンド翻訳
* `POST /api/board/posts/{postId}/tts` … 投稿本文 TTS
* `POST /api/board/comments/{commentId}/tts` … 返信本文 TTS

各 Route Handler は、翻訳/TTS 呼び出しを必ず `try / catch` でラップし、

* 失敗時は Logger に WARN/ERROR を出力
* 掲示板本体の投稿／返信／閲覧が継続できるよう、HTTP 500 にせずフェイルソフトに処理

することを基本方針とする（詳細は ch06）。

### 4.6.2 Edge Function

Supabase Edge Function は、翻訳キャッシュ削除バッチのみ担当する。

* 対象テーブル: `board_post_translations`, `board_comment_translations`
* 処理概要:

  * テナントごとに `translation_retention_days` を取得
  * `created_at` が閾値を超えた翻訳レコードを削除
* 翻訳実行・TTS 実行は Edge Function のスコープ外（Route Handler のみ）とする。

---

## 4.7 まとめ

本章 v1.3 では、既存の投稿用フローに加えて、

* 返信（コメント）投稿時の翻訳キャッシュ生成
* 返信のオンデマンド翻訳
* 返信に対する TTS

を追加で定義し、`board_post_translations` と `board_comment_translations` による二層構造を整理した。

翻訳／TTS はあくまで付加価値機能とし、失敗時にも掲示板本体の投稿・返信・閲覧が継続されるフェイルソフト設計を維持する。
