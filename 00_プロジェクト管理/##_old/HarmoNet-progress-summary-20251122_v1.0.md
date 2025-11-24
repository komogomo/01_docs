# HarmoNet 開発進捗サマリ（〜 2025-11-22）

本メモは、TKD / 各コードエージェント / Gemini 用の「進捗共有用サマリ」です。
正式な仕様は各設計書（FR/NFR/技術スタック/画面別基本設計・詳細設計）を正とします。

---

## 1. ホーム画面（HOME）まわり

### 1.1 設計状況

* HOME 画面の役割

  * ログイン後の最初の画面として、各機能へのダッシュボード的な導線を提供。
  * 掲示板／施設予約などの「最新サマリ」をカード形式で表示。
* 設計レベル

  * HOME の詳細な基本設計書（単体）はまだ未作成。fileciteturn13file0L7-L18
  * 掲示板との関係は `board-design-ch02`（画面一覧と導線）で定義済み。

    * HOME 内掲示板サマリセクション

      * タイトル例: 「掲示板からのお知らせ」
      * タブ: ALL / NOTICE / RULES（表示中タブを強調）
      * 各タブごとの最新投稿 3 件（最大）を表示
      * 「もっと見る」ボタン → `/board?tab=<現在のタブ>` に遷移
    * HOME では閲覧のみ、投稿や詳細操作は `/board` 側に集約する方針。
* 今後の予定

  * HOME 画面単体の基本設計書を作成（ロゴ・共通ヘッダー・カードレイアウト・掲示板以外のカードを整理）。
  * HOME 実装は、ログイン画面／掲示板基本設計が固まり、BoardTop/Detail の仕様が確定した後に着手。

### 1.2 実装状況

* AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider は実装済み。fileciteturn13file0L53-L60
* HOME 専用のコンポーネント構成は骨組みレベル。
* ログイン → HOME への遷移は動作するが、HOME のカード内容はこれから詰める段階。

---

## 2. 上位仕様（FR/NFR/技術スタック）

### 2.1 要件・技術スタック

* 機能要件：`functional-requirements-all_v1.6.md`
* 非機能要件：`Nonfunctional-requirements_v1.0.md`
* 技術スタック：`harmonet-technical-stack-definition_v4.4.md`
* 掲示板設計決定サマリ：`HarmoNet-bbs-board Design-decision-summary_v1.0.md`fileciteturn13file0L62-L71

→ 掲示板を含む現行スコープの FR/NFR/Tech は、この組み合わせで確定済み。

### 2.2 共通方針

* 認証：Supabase Auth の MagicLink（メール OTP のみ）。Passkey はペンディング。
* 多言語：StaticI18nProvider による JA/EN/ZH の静的辞書 + 掲示板投稿時の 3 言語自動翻訳。
* バックエンド：Next.js App Router + Supabase（PostgreSQL + RLS）構成。fileciteturn13file0L73-L80

---

## 3. ログイン・共通部品

### 3.1 ログイン・AuthCallback

* ログイン画面 基本設計／詳細設計：完了（MagicLink のみ）。
* MagicLink Backend 基本設計：完了。fileciteturn13file0L82-L97

  * `/login` でメールを入力 → マジックリンク発行。
  * `/auth/callback` でセッション確立 → HOME などへ遷移。
  * `redirect` パラメータによる遷移制御は設計済み（掲示板ショートカットURLと連携予定）。
* Windsurf によるコードチェック済み（重大な問題なし）。

### 3.2 共通コンポーネント

* AppHeader / AppFooter：

  * 基本・詳細設計あり。実装済み（UIトーンは HarmoNet 共通ルール）。
* LanguageSwitch / StaticI18nProvider：

  * 基本・詳細設計あり。3 言語（JA/EN/ZH）の切り替え動作確認済み。fileciteturn13file0L99-L108
* 共通ログ／共通メッセージ：

  * ロガー基本・詳細設計あり（Supabase / Vercel ログ出力）。
  * メッセージキー仕様は掲示板を含めた共通方針として設計進行中。

---

## 4. 掲示板 基本設計（BoardTop / Detail / 投稿 / 共通）

### 4.1 掲示板 index（ch00）

* `board-design-ch00-index_v2.x`：

  * 旧セキュレアシティ版を廃止し、HarmoNet 版 index を再作成。
  * 掲示板に関する画面仕様の「唯一の正」は ch01〜07 と定義。
  * 上位仕様（FR v1.6 / NFR v1.0 / TechStack v4.4 / BBS Design-decision-summary v1.0）との関係を明示。fileciteturn13file0L110-L120

### 4.2 第1〜7章（Board 基本設計）

* ch01 概要・方針：掲示板の目的・背景（安心感・管理負担軽減・多文化共生）。
* ch02 画面一覧と導線：HOME／BoardTop／BoardDetail の役割と遷移。
* ch03 BoardTop 一覧：タブ（ALL/NOTICE/RULES）＋範囲（GLOBAL/GROUP）の一覧仕様。
* ch04 BoardDetail：タイトル／カテゴリ／本文／PDF プレビュー／コメント一覧。
* ch05 投稿作成：カテゴリ／タイトル／本文／公開範囲／添付／回覧板フラグ／文字数上限／添付上限。
* ch06 共通仕様（翻訳・音声・モデレーション）：3 言語翻訳＋TTS＋任意導入モデレーション。
* ch07 補助機能（既読・通報・アンケート拡張）：既読管理・通報・将来のアンケート／議決拡張。fileciteturn13file0L122-L171

→ 掲示板の基本設計（BoardTop / Detail / 投稿 / 共通仕様）は ch00〜07 で一通り定義済み。

---

## 5. 掲示板 詳細設計（B-03 投稿フォーム / B-04 翻訳・TTS）

### 5.1 B-03 BoardPostForm（投稿フォーム）

**状態:** ch00〜ch07 までの詳細設計 v1.1 系列が揃い、Gemini レビュー済み。

* 機能スコープ

  * `/board/new` の新規投稿フォーム。
  * BoardDetail 上でのインライン編集時に再利用されるフォームロジック（mode: `create` / `edit`）。

* 主要仕様ポイント

  * 投稿者名表示モード：

    * 匿名 / ニックネームの二択。
    * 投稿時にどちらかの選択が必須（未選択はバリデーションエラー）。
  * 編集／削除ポリシー：

    * 編集・削除できるのは「自分が投稿した」投稿・返信のみ。
    * 編集は BoardDetail 上のインライン編集で行い、PATCH API を呼び出す前提。
    * 投稿削除時は親投稿＋全返信＋翻訳キャッシュが Cascade で削除され、UI 上は「この投稿は削除されました。」を表示。
    * 返信削除時は返信＋翻訳キャッシュのみ削除し、「この返信は削除されました。」を表示（子返信は残す）。
  * 添付ファイル：

    * 許可形式は PDF＋Office 系（Word/Excel/PowerPoint 等）。
    * PDF は掲示板詳細画面でプレビュー可能、それ以外はダウンロードのみ。
    * 最大添付数／最大サイズは非機能要件・テナント設定に従う。
  * 投稿確認ダイアログ：

    * 「投稿者名の表示方法」「カテゴリ」「タイトル」「本文（要約）」「添付一覧」をプレビュー表示。
    * 住民全体への公開であることを明示する注意喚起文を含める。

* テスト・品質

  * ch06 で Vitest＋React Testing Library によるテスト観点を定義済み。
  * 初期表示／バリデーション／確認ダイアログ／成功・失敗時の挙動／ログ出力をカバー。

### 5.2 B-04 BoardTranslationAndTtsService（翻訳・TTS）

**状態:** ch02〜ch06 の詳細設計 v1.2 系列が揃い、B-03 と整合する形で確定。

* API・認証（ch02）

  * `TranslationService` / `BoardPostTranslationService` / `TtsService` / `BoardPostTtsService` のインタフェース定義。
  * Google Cloud Translation / Text-to-Speech を利用し、ローカルは `GOOGLE_APPLICATION_CREDENTIALS`、本番は `GCP_TRANSLATE_CREDENTIALS_JSON` による資格情報注入。fileciteturn13file0L62-L80

* キャッシュ構造（ch03）

  * 投稿用 `board_post_translations` と返信用 `board_comment_translations` を定義。
  * 単位: 投稿ID/コメントID × 言語。
  * `tenant_settings.config_json.board.translation_retention_days` による保持期間管理。
  * Prisma モデルと `onDelete: Cascade` の関係を明示。

* フロー（ch04）

  * 新規投稿／返信投稿時に、原文保存後 `translateAndCacheForPost` / `translateAndCacheForComment` を呼び出す。
  * 翻訳失敗時も投稿本体は成功とするフェイルソフト設計。
  * BoardDetail からのオンデマンド翻訳（投稿・返信）と TTS 呼び出しフローを定義。

* 非機能（ch06）

  * 翻訳: 3 秒タイムアウト＋`Promise.all` による並列実行。
  * TTS: 5 秒タイムアウト目安。
  * 翻訳・TTS失敗時はログ出力のみとし、掲示板本体の投稿／閲覧は成功させる方針。
  * 独自レート制限や監視・アラートは「現時点ではスコープ外」とし、必要になった段階で別途設計。

---

## 6. 実装状況（掲示板まわり）

### 6.1 DB スキーマ

* 掲示板関連テーブル（posts/comments/translations 他）は `schema.prisma` に反映済み。fileciteturn13file0L173-L181
* 新規追加:

  * `board_post_translations`（投稿翻訳キャッシュ）
  * `board_comment_translations`（返信翻訳キャッシュ）
* リレーション:

  * `board_post_translations.post` → `board_posts`（`onDelete: Cascade`）
  * `board_comment_translations.comment` → `board_comments`（`onDelete: Cascade`）

### 6.2 B-04 実装（Translation/TTS サービス）

* Windsurf タスク WS-B04 v1.2 にて、以下を実装・確認済み。

  * `translateAndCacheForPost` / `translateAndCacheForComment` の `Promise.all` 並列実行。
  * 翻訳失敗時に言語単位でスキップし、呼び出し側には例外を投げないフェイルソフト実装。
  * Google Translation / TTS クライアントの 3 秒タイムアウト実装。
  * Prisma の Cascade 設定との整合（手動 DELETE との二重削除なし）。
* Route Handler 側（`/api/board/...`）はまだ未実装のため、

  * 「翻訳/TTS 例外を HTTP 500 にしない」
  * 「PATCH 時にタイトル／本文変更有りの場合のみ翻訳を再実行」
    などは、Board API 実装タスクに TODO として引き継ぐ前提。

### 6.3 B-03 実装

* 現時点では、BoardPostForm コンポーネントの実装は未着手。

* Windsurf 用の実装指示書 WS-B03（新規投稿＋編集インライン再利用）を作成し、ログイン画面に続くメイン実装タスクとして着手予定。

* 依存関係:

  * B-03 は B-04 のサービスインタフェースを前提にするが、翻訳の成否は BoardPostForm 側では扱わない。
  * BoardDetail（B-02）・BoardTop（B-01）の設計がある程度固まり次第、B-03 と併走して実装を進める。

---

## 7. 掲示板画面（BoardTop / BoardDetail）実装状況

* BoardTop（/board）: 未実装。
* BoardDetail（/board/[id]）: 未実装。
* ただし、基本設計（ch00〜07）と B-03/B-04 の詳細設計は揃ったため、

  * 次のステップとして BoardTop / BoardDetail の詳細設計（B-01/B-02）と Windsurf 指示書を順次起こしていくフェーズ。

---

## 8. 一行まとめ（現状の立ち位置 / 2025-11-22 時点）

* ログイン・共通部品・上位仕様は安定し、掲示板については

  * 基本設計（BoardTop/Detail/投稿/共通仕様）
  * 詳細設計（B-03 BoardPostForm / B-04 Translation & TTS）
    が「実装可能な粒度」で揃った。fileciteturn13file0L183-L196
* DB スキーマは掲示板用テーブル＋翻訳キャッシュまで反映済みで、B-04 のサービス層実装も Windsurf により差分適用済み。
* 今後は、

  * WS-B03 による投稿フォーム（新規投稿＋インライン編集再利用）の実装、
  * BoardTop / BoardDetail（B-01 / B-02）の詳細設計と実装指示書作成、
  * board API Route（/api/board/...）の設計・実装
    を順次進めるフェーズに入っている。
