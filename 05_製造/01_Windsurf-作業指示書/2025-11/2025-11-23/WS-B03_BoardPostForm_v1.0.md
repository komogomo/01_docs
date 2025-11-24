# WS-B03_BoardPostForm_v1.0

## 0. Task Overview

### 0.1 Goal

Implement the **B-03 BoardPostForm** (掲示板投稿フォーム画面) so that:

1. ユーザが `/board/new` から掲示板投稿（タイトル＋本文＋カテゴリ＋公開範囲など）を新規作成できる。
2. 投稿成功時に `board_posts`（および必要な `board_attachments`）へレコードをINSERTし、AIモデレーション＋翻訳キャッシュ生成(B-04)まで一連の処理を実行する。
3. 投稿完了後に適切な画面（`/board/[postId]` または `/board`）へ遷移し、エラー時はフォーム上にメッセージを表示する。
4. MagicLink認証・テナントコンテキスト・RLS・i18n の既存仕組みを利用し、**既存のログイン・掲示板設計と整合する**実装とする。

### 0.2 Scope

* 対象ルート:

  * `app/board/new/page.tsx`（新規投稿画面）
* 対象機能:

  * フォーム UI（タイトル／本文／カテゴリ／公開範囲など、B-03 ch02/ch05 基準）
  * クライアント側バリデーション
  * 投稿API 呼び出し（`/api/board/posts` 想定）
  * AIモデレーション結果のハンドリング（`errorCode = "ai_moderation_blocked"` 等）
  * 翻訳キャッシュ生成トリガ（B-04 呼び出し）
  * 成功／失敗メッセージの表示、遷移

**Out of scope（このタスクでは触らない）**

* `/board`（B-01 BoardTop）の実装・修正
* `/board/[postId]`（B-02 BoardDetail）の実装・修正
* 翻訳/TTS コンポーネント本体の実装（既に実装済み前提）
* DB スキーマ・RLS 設定の変更（`schema.prisma` と Supabase 側は済み）

---

## 1. References

### 1.1 Design Documents

* B-03 BoardPostForm 詳細設計 (PJ ナレッジ)

  * `/01_docs/04_詳細設計/02_掲示板/`
  * `B-03_BoardPostForm-detail-design-ch01-overview_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch02-layout_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch03-data-model_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch04-logic_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch05-messages-and-ui_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch06-test-and-quality_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch07-references-and-traceability_v1.1.md`
  * `B-03_BoardPostForm-detail-design-ch08-ai-moderation_v1.1.md`

* B-02 BoardDetail 詳細設計（参照のみ）

* B-01 BoardTop 詳細設計（参照のみ）

* B-04 BoardTranslationAndTtsService 詳細設計（翻訳キャッシュ仕様）

* スキーマ:

  * `D:\Projects\HarmoNet\supabase\schema.prisma`
  * `board_posts`, `board_attachments`, `board_post_translations`, `moderation_logs` 等

### 1.2 i18n Dictionaries

* 英語: `/src/locales/en/common.json`
* 日本語: `/src/locales/ja/common.json`
* 中国語: `/src/locales/zh/common.json`

掲示板投稿フォーム用のキーは `board.postForm.*`（または `board.post.*`）の形で定義されている前提。足りないキーがあれば **TKD が辞書更新** するので、タスク内で辞書ファイルを書き換えないこと。

---

## 2. Environment & Constraints

### 2.1 Tech Stack

* Next.js 16 (App Router)
* React 19
* TypeScript
* Supabase JS Client（Auth + Postgres）
* Prisma（DB スキーマ定義のみ / マイグレーション済み）
* Jest + React Testing Library
* Tailwind CSS
* StaticI18nProvider（ローカル辞書ベースの i18n）

### 2.2 Directory Structure (Frontend)

* Root: `D:\Projects\HarmoNet`
* App router:

  * `src/app/board/new/page.tsx` （新規投稿ページを新規作成）
* Components (例):

  * `src/components/board/BoardPostForm/BoardPostForm.tsx`
  * `src/components/board/BoardPostForm/__tests__/BoardPostForm.test.tsx`

※ 上記パスは目安。既存のコンポーネント配置ルール（PJ の frontend-directory-guideline）に従い、Board 系のコンポーネントフォルダに統一。

### 2.3 Constraints

1. **スキーマ変更禁止**

   * `schema.prisma` の改変・マイグレーション追加はこのタスクでは行わない。

2. **RLS・Supabase セットアップ変更禁止**

   * Supabase のポリシー・設定の変更は行わない。

3. **i18n 辞書ファイル不変更**

   * `common.json` など辞書ファイルを編集しない（キーが足りない場合はエラーを報告）。

4. **ディレクトリ構成・ルーティング構造の変更禁止**

   * 既存の `/login` や auth 周りのルートを変更しない。
   * `/board` や `/board/[postId]` 既存実装があれば触らない。

5. **スタイルガイド順守**

   * App 全体のトーンに合わせ、「やさしい・自然・控えめ」な UI。Tailwind のトークンは既存ホーム・ログイン画面と合わせる。

---

## 3. Functional Specification (Implementation View)

### 3.1 Route `/board/new`

* 認証済みユーザのみアクセス可能（Auth レイアウト側で制御済み）。
* ページ内容:

  * 画面タイトル: `board.postForm.title` （例: "New post" / "新規投稿"）
  * BoardPostForm コンポーネント本体

### 3.2 BoardPostForm Props & State

* Props（初期版はシンプルでよい）

  * `tenantId: string`
  * `userId: string`
  * `viewerRole: string`  // management / resident など
  * `onSubmitted?(postId: string): void`  // 投稿成功時のコールバック（なくても良い）

* フォーム項目（B-03 ch02/ch03 に準拠）

  * タイトル（必須）
  * 本文（必須）
  * カテゴリ（ドロップダウン）
  * 公開範囲（全体 / グループなど必要なもの）
  * 表示名モード（実名 / ニックネーム / 匿名）

* 状態

  * 入力値（`title`, `content`, etc.）
  * バリデーションエラー（フィールド単位）
  * 送信中フラグ `isSubmitting`
  * 送信結果メッセージ `submitError`, `submitSuccess`

### 3.3 Submission Flow

1. フォーム提出（ボタン押下）

   * 必須項目のクライアントバリデーション。
   * OKなら `POST /api/board/posts`（仮）を呼び出し。

2. API レスポンス（B-03 ch08 に準拠）

* 正常系

  * `201 Created` + `postId` を返す。
  * フロント側:

    * `isSubmitting = false` に戻す。
    * `/board/[postId]` へ `router.push` する。

* モデレーションブロック

  * `4xx` + `errorCode = "ai_moderation_blocked"`。
  * フロント側:

    * 入力内容はそのまま残す。
    * `submitError` に `board.postForm.error.moderationBlocked` キーを設定し、フォーム上部にメッセージ表示。

* その他エラー

  * `4xx/5xx` + `errorCode = "network_error"` / `"unknown"` 等。
  * フロント側:

    * `submitError` に汎用エラーキー `board.postForm.error.generic` を設定。

3. 翻訳・TTS

* **このタスクでは** 翻訳/TTS 自体の実装は行わない。
* 投稿API 側で翻訳キャッシュを作る前提のため、フロントは成功レスポンスを待つだけとする。

---

## 4. Non-functional Requirements (Implementation View)

* バリデーション

  * タイトル・本文は必須。文字数制限は B-03 ch03 に準拠。
* UX

  * 送信中はボタンを無効化し、スピナーまたは「送信中…」表示。
  * エラー時はフォーム上部に控えめなアラートコンポーネントでメッセージ表示。
* ログ

  * 送信開始/成功/失敗時に共通 Logger を呼ぶ（B-03 ch06 に記載のイベント名に従う）。

---

## 5. Tests

### 5.1 Unit Tests (Jest + RTL)

* `src/components/board/BoardPostForm/__tests__/BoardPostForm.test.tsx`

必須テストケース（詳細は B-03 ch06 に準拠）:

1. 初期表示

   * すべての必須フィールドが表示されていること。

2. バリデーション

   * 空のまま送信すると、タイトル・本文のエラーが表示されること。

3. 正常送信

   * 正しい入力で送信すると、`fetch` / API モックが 1 回呼ばれること。
   * モックが `postId = xxx` を返したとき、`router.push('/board/xxx')` が呼ばれること。

4. モデレーションブロック

   * API モックが `errorCode = "ai_moderation_blocked"` を返す場合、

     * 入力値は保持されること。
     * `board.postForm.error.moderationBlocked` に対応するメッセージが表示されること。

5. その他エラー

   * API モックがネットワークエラーを throw した場合、

     * `board.postForm.error.generic` に対応するメッセージが表示されること。

### 5.2 Integration Tests (Optional)

* 実際の `/board/new` ページに BoardPostForm をマウントし、

  * ダミー Supabase クライアント or モックでエンドツーエンド風に 1 投稿流すテストが書ければベストだが、
  * 時間が厳しければ UT のみでも可（TKD 側で判断）。

---

## 6. Output Expectations

### 6.1 Files to Touch

* 新規作成（想定）

  * `src/app/board/new/page.tsx`
  * `src/components/board/BoardPostForm/BoardPostForm.tsx`
  * `src/components/board/BoardPostForm/__tests__/BoardPostForm.test.tsx`

* 既存ファイルの修正（必要に応じて）

  * `src/lib/supabaseClient.ts` など Supabase クライアント取得ヘルパ
  * `src/lib/logger.ts` など共通ロガー

### 6.2 Files NOT to Touch

* `schema.prisma`
* Supabase の設定ファイル（`supabase/config.toml` 等）
* i18n 辞書（`src/locales/**`）
* `/board` や `/board/[postId]` のページファイル

---

## 7. Notes for Windsurf

* このタスクは「掲示板投稿画面の初回実装」に限定してください。TOP/詳細は別タスクで扱います。
* 迷った場合は **B-03 詳細設計 ch01〜ch08** を正として挙動を決めてください。
* i18n キーが見つからない場合は、新規キーを提案せず、エラーとして報告してください（TKD が辞書を更新します）。
* コミットメッセージ例: `feat(board): add BoardPostForm /board/new page`
