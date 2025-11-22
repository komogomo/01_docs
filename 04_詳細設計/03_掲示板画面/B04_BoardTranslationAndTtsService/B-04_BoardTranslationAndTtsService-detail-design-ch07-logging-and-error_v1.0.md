# B-04 BoardTranslationAndTtsService 詳細設計書 ch07 ログ・監視・エラー設計 v1.0

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH07
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 7.1 本章の目的

本章では、掲示板専用 翻訳＋音声読み上げサービス B-04 BoardTranslationAndTtsService に関する

* ログ出力ポリシー
* 主要イベント（翻訳・TTS・バッチ）のログ項目
* エラー時の扱いと画面側への伝達方針

を定義する。共通 Logger の詳細設計書を前提としつつ、B-04 固有のイベント名と最低限記録すべき情報を明示し、Windsurf が実装時に迷わない状態を作ることを目的とする。

---

## 7.2 ログ出力ポリシー

### 7.2.1 共通方針

* ログは HarmoNet 共通 Logger を通じて出力する。
* ログレベルは以下を基本とする。

  * `INFO` : 正常系の完了ログ（翻訳成功・TTS 成功・バッチ成功など）
  * `WARN` : 軽微な失敗・リトライ不要のエラー（単一言語の翻訳失敗など）
  * `ERROR` : 処理全体の失敗（翻訳サービス全体の異常、バッチ処理失敗など）
* ログ内容は、**再現に必要なキー情報を残しつつ、投稿本文や個人情報を含めない** 方針とする。

### 7.2.2 情報マスキング

* 以下はログに含めない。

  * 投稿本文の全文
  * 翻訳結果の全文
  * ユーザの個人情報（メールアドレス、氏名 等）
* ログに含める主な共通項目:

  * `tenantId`
  * `postId`
  * `lang`（source / target）
  * 呼び出し元コンポーネント（`B-02` / `B-03` / `edge.cleanup` 等）
  * 外部 API のステータスコード・エラーコード（可能な範囲で）
  * 処理時間（ms）

---

## 7.3 翻訳ログ設計

### 7.3.1 翻訳成功ログ

* イベント名（例）: `board.translation.success`
* レベル: `INFO`
* 出力タイミング:

  * `BoardPostTranslationService.translateAndCacheForPost` が、指定されたターゲット言語すべてについて成功した場合。
* 主な項目:

  * `tenantId`
  * `postId`
  * `sourceLang`
  * `targetLangs`（配列）
  * `caller`（`B-03` or `B-02`）
  * `durationMs`（翻訳処理全体の所要時間）
  * `translatedCount`（成功した言語数）

### 7.3.2 翻訳失敗ログ

* イベント名（例）: `board.translation.error`
* レベル: `WARN` または `ERROR`

  * 一部言語のみ失敗: `WARN`
  * 全言語失敗、または外部 API の重大エラー: `ERROR`
* 出力タイミング:

  * `translateAndCacheForPost` 内で外部 API 呼び出しが失敗した場合。
* 主な項目:

  * `tenantId`
  * `postId`
  * `sourceLang`
  * `targetLangs`
  * `failedLangs`（失敗した言語の配列）
  * `caller`（`B-03` or `B-02`）
  * `errorCode` / `errorMessage`（外部 API または SDK の情報から取得可能な範囲）
  * `durationMs`

> UI 側には汎用エラーメッセージのみ返し、詳細なエラーはログにのみ記録する。

---

## 7.4 TTS ログ設計

### 7.4.1 TTS 成功ログ

* イベント名（例）: `board.tts.success`
* レベル: `INFO`
* 出力タイミング:

  * `BoardPostTtsService.synthesizePostBody` が正常に音声データを生成した場合。
* 主な項目:

  * `tenantId`
  * `postId`
  * `lang`
  * `caller`（`B-02`）
  * `durationMs`
  * `audioSizeBytes`（生成された音声データのサイズ）

### 7.4.2 TTS 失敗ログ

* イベント名（例）: `board.tts.error`
* レベル: `ERROR`
* 出力タイミング:

  * `TtsService.synthesize` または `BoardPostTtsService.synthesizePostBody` で例外が発生した場合。
* 主な項目:

  * `tenantId`
  * `postId`
  * `lang`
  * `caller`（`B-02`）
  * `errorCode` / `errorMessage`
  * `durationMs`

> TTS 失敗時も掲示板の閲覧自体は継続可能であるため、アラートではなくログでの検知に留める（ch06 可用性方針と整合）。

---

## 7.5 バッチ（Edge Function）ログ設計

### 7.5.1 実行成功ログ

* イベント名（例）: `board.translation.cleanup.success`
* レベル: `INFO`
* 出力タイミング:

  * Edge Function `cleanup-board-translations` が、全体として正常終了した場合。
* 主な項目:

  * `runId`（バッチ実行ID。UUID など）
  * `deletedTenantCount`（少なくとも 1 件以上削除が発生したテナント数）
  * `deletedRowTotal`（削除された行数の合計）
  * `durationMs`

### 7.5.2 実行エラーログ

* イベント名（例）: `board.translation.cleanup.error`
* レベル: `ERROR`
* 出力タイミング:

  * Edge Function 内で致命的な例外が発生し、処理全体を中断した場合。
* 主な項目:

  * `runId`
  * `tenantId`（エラー発生時に処理していたテナントが特定できる場合のみ）
  * `errorCode` / `errorMessage`
  * `durationMs`

> v1.0 では、部分的成功／失敗の詳細集計までは行わず、「全体として成功したか／途中で失敗したか」のログだけを残す。

---

## 7.6 画面側へのエラー伝播

### 7.6.1 B-03 BoardPostForm への伝播

* 投稿時翻訳の失敗:

  * 投稿作成 API は `postId` を返し、HTTP ステータスも成功とする。
  * 翻訳失敗は UI には通知せず、ログのみ記録する。
  * 利用者は、必要であれば B-02 から翻訳アイコンを押下してオンデマンド翻訳を実行できる。

### 7.6.2 B-02 BoardDetail（翻訳）への伝播

* オンデマンド翻訳 API が失敗した場合:

  * HTTP レスポンスはエラーコード（例: 5xx または 4xx + アプリ固有コード）を返す。
  * B-02 は汎用エラーメッセージを表示する（例: 「翻訳に失敗しました。しばらくしてから再度お試しください。」）。
  * 詳細なエラー内容はログのみに出力される。

### 7.6.3 B-02 BoardDetail（TTS）への伝播

* TTS API が失敗した場合:

  * HTTP レスポンスはエラーコードを返し、音声データは返さない。
  * B-02 は汎用エラーメッセージを表示する（例: 「音声読み上げに失敗しました。しばらくしてから再度お試しください。」）。
  * 再生開始は行わない。

---

## 7.7 監視・アラート（v1.0 の扱い）

* v1.0 では、B-04 単体に対する専用の監視・アラートは構成しない。
* 翻訳・TTS・バッチのエラー検知は、Logflare / Supabase 上のログを手動で確認する運用とする。
* 将来、監視システム（例: ログ集約 + 通知）を導入する場合:

  * 本章のイベント名・項目をもとに、

    * `board.translation.error`
    * `board.tts.error`
    * `board.translation.cleanup.error`
      の発生回数に対して閾値アラートを設定する。

以上で、B-04 BoardTranslationAndTtsService のログ・監視・エラー設計を定義した。
