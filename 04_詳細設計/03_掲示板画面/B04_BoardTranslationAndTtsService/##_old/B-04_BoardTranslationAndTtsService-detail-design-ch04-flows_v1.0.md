# B-04 BoardTranslationAndTtsService 詳細設計書 ch04 掲示板詳細画面との連携（翻訳・TTS 利用フロー） v1.0

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH04
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 4.1 本章の目的

本章では、B-04 BoardTranslationAndTtsService と掲示板画面（B-02 BoardDetail / B-03 BoardPostForm）との連携フローを定義する。

* 投稿時の初回翻訳フロー（B-03 → B-04）
* 掲示板詳細画面におけるオンデマンド翻訳フロー（B-02 → B-04）
* 掲示板詳細画面における音声読み上げ（TTS）フロー（B-02 → B-04）
* Route Handler / Supabase Edge Function の責務分担

を時系列・状態遷移として整理し、Windsurf がフロントエンド／バックエンド双方を実装できる粒度で明示する。

---

## 4.2 翻訳フロー（B-02 / B-03 視点）

### 4.2.1 投稿時初回翻訳フロー（B-03 → B-04）

新規投稿時の処理フローを以下に定義する。ここでは原文言語を `sourceLang`、翻訳先言語リストを `targetLangs` とする。

1. 利用者が B-03 BoardPostForm から投稿内容を入力し、「投稿する」ボタンを押下。
2. クライアント側で入力バリデーション実行。
3. 確認ダイアログで内容確認後、投稿作成 API（例: `POST /api/board/posts`）を呼び出す。
4. 投稿作成 API 内で以下を実行する。

   1. 原文本文（`title` / `body`）を `board_posts` に保存。
   2. 生成された `postId` と原文情報を用いて、`BoardPostTranslationService.translateAndCacheForPost` を呼び出す。

      * `tenantId`
      * `postId`
      * `sourceLang`（例: 'ja'）
      * `targetLangs`（例: ['en', 'zh']）
      * `originalTitle` / `originalBody`
   3. 翻訳処理の成功／失敗にかかわらず、投稿作成 API は `postId` をレスポンスとして返す。
5. B-03 は `postId` を受け取り、B-02 BoardDetail への遷移（`/board/[postId]`）を行う。
6. 翻訳に成功した場合、B-02 / B-01 は `board_post_translations` から翻訳済み本文を取得して表示できる。翻訳に失敗した場合は、後述のオンデマンド翻訳フローで補完される。

> ポイント:
>
> * 翻訳失敗は投稿自体のロールバック条件としない。
> * v1.0 では投稿作成 API の内部で同期的に翻訳を実行してもよいが、将来的に非同期キュー方式へ変更可能な設計とする（本書では同期を前提に記述）。

---

### 4.2.2 B-02 でのオンデマンド翻訳フロー（翻訳アイコン押下時）

掲示板詳細画面では、翻訳キャッシュが存在しない場合に限り、利用者の明示操作（翻訳アイコン押下）をトリガとして翻訳を実行する。

1. B-02 BoardDetail 初期表示時:

   1. 原文投稿（`board_posts`）と、現在の表示言語 `displayLang` を取得。
   2. `board_post_translations` に `postId + displayLang` のレコードが存在するか確認する（`BoardPostTranslationService.hasCachedTranslation` または直接クエリ）。
   3. キャッシュが存在する場合:

      * 翻訳済み本文を表示する。
   4. キャッシュが存在しない場合:

      * 原文のみ表示し、翻訳アイコンを有効状態で表示する。

2. 利用者が翻訳アイコンを押下した場合:

   1. B-02 は翻訳 API 用の Route Handler（例: `POST /api/board/posts/{postId}/translate`）を呼び出す。
   2. Route Handler 内で以下を実行する。

      * `BoardPostTranslationService.translateAndCacheForPost` を呼び出し、`targetLangs` に現在の `displayLang` のみを指定する。
      * 処理成功時:

        * 直近の翻訳結果を `board_post_translations` から取得し、レスポンスとして返す。
      * 処理失敗時:

        * エラーコードとメッセージ（汎用）を返す。
   3. B-02 はレスポンスに応じて以下を行う。

      * 成功時: 画面上の本文を翻訳済み本文に切り替え、翻訳アイコンの状態（「翻訳済み」など）を更新する。
      * 失敗時: 原文表示を維持しつつ、画面上にエラートースト／メッセージを表示する（文言は B-02 側で定義）。

> ポイント:
>
> * オンデマンド翻訳は「キャッシュが無い場合のみ」実行する。
> * API 呼び出し中は翻訳アイコンのスピナー表示など、B-02 側で読み込み状態を表現する。

---

### 4.2.3 キャッシュ有無判定と取得ロジック

* キャッシュ有無判定:

  * 原則として `board_post_translations` に対するクエリ、または `BoardPostTranslationService.hasCachedTranslation` によって行う。
  * 条件: `tenant_id = :tenantId AND post_id = :postId AND lang = :displayLang`

* 翻訳済み本文の取得:

  * B-02 / B-01 からは、以下のようなクエリを発行する（実装レイヤは任意）。

```sql
SELECT title, content
FROM board_post_translations
WHERE tenant_id = :tenantId
  AND post_id = :postId
  AND lang = :displayLang;
```

* キャッシュが存在しない場合の扱い:

  * B-01（一覧画面）:

    * 原文のみ表示とし、オンデマンド翻訳は B-02 に限定する（一覧画面での大量翻訳を避ける）。
  * B-02（詳細画面）:

    * 翻訳アイコン押下時にオンデマンド翻訳フローを実行する。

---

## 4.3 TTS フロー（B-02 視点）

### 4.3.1 音声読み上げボタン押下〜TTS API 呼び出し

掲示板詳細画面における音声読み上げの一連の流れを定義する。

1. B-02 BoardDetail 初期表示時:

   * 投稿本文（原文または翻訳済み）と現在の表示言語 `displayLang` を保持する。
   * 音声読み上げボタン（例: スピーカーアイコン）を表示する。

2. 利用者が音声読み上げボタンを押下した場合:

   1. B-02 は音声読み上げ API 用の Route Handler（例: `POST /api/board/posts/{postId}/tts`）を呼び出す。

      * リクエストパラメータ:

        * `tenantId`
        * `postId`
        * `lang`（`displayLang`）
        * 読み上げ対象テキスト（本文）
   2. Route Handler 内で `BoardPostTtsService.synthesizePostBody` を呼び出す。

      * `BoardPostTtsService` は `TtsService.synthesize` を利用して外部 TTS API を呼び出し、音声バイナリと MIME タイプを取得する。
   3. Route Handler は取得した `audioBuffer` と `mimeType` を HTTP レスポンスとして返す。

3. B-02 はレスポンス受信後、以下のいずれかの方法で再生する。

   * `Blob` を生成し、`URL.createObjectURL` で一時 URL を作成し、`HTMLAudioElement` で再生する。
   * もしくは `<audio>` タグの `src` にバイナリを直接指定する実装とする（詳細は B-02 側で定義）。

4. 再生終了後、ユーザは必要に応じて再度ボタンを押して再生できる。v1.0 では TTS 結果はキャッシュせず、その都度 API を呼び出す。

---

### 4.3.2 エラー時の UI 表示仕様（連携レベル）

* TTS API 呼び出しが失敗した場合、Route Handler はエラーレスポンスを返す。
* B-02 は以下の方針でエラーを扱う。

  * 再生は開始しない。
  * 画面上に汎用的なエラーメッセージを表示する（例: 「音声読み上げに失敗しました。しばらくしてから再度お試しください。」）。
  * 同メッセージ文言の詳細は B-02 のメッセージ仕様にて定義し、本書では文言キーのみを連携対象とする。
* エラー内容の詳細（HTTP ステータス、外部 API のエラーコード等）は、B-04 側で Logger を通じて記録する（ch07 参照）。

---

## 4.4 Route Handler / Edge Function の責務分担

### 4.4.1 Next.js Route Handler 経由での呼び出し

* 翻訳および TTS のオンライン処理（ユーザ操作に応じた即時処理）は、Next.js の Route Handler を経由して行う。
* 理由:

  * B-02 / B-03 との統合が容易であり、認証コンテキスト（テナントID・ユーザID）を扱いやすいため。
  * UI 操作に対するレスポンス時間要件（数秒以内）を満たすため。

Route Handler の想定エンドポイント例:

* `POST /api/board/posts`  … 新規投稿作成 + 初回翻訳トリガ
* `POST /api/board/posts/{postId}/translate`  … B-02 からのオンデマンド翻訳
* `POST /api/board/posts/{postId}/tts`  … B-02 からの音声読み上げ要求

これらの Route Handler 内で B-04 のサービスインターフェース（`BoardPostTranslationService` / `BoardPostTtsService`）を呼び出す。

### 4.4.2 Supabase Edge Function の役割（参考）

* Supabase Edge Function は **翻訳キャッシュ削除バッチ**専用とし、オンライン処理（ユーザ操作に対する即時応答）は担当しない。
* Edge Function は定期実行（Supabase Scheduler）により、以下を実行する。

  * 各テナントの `translation_retention_days` を読み取る。
  * `board_post_translations` から期限切れ行を削除する。
* 本章では Edge Function の詳細フローは扱わず、ch05 で詳細設計を行う。

---

本章では、B-04 BoardTranslationAndTtsService と掲示板画面（B-02 / B-03）との連携フローを定義した。
次章 ch05 では、翻訳キャッシュ保有期間および Supabase Edge Function による削除バッチの詳細設計を記述する。
