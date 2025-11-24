# WS-B02-01 BoardDetailPage（閲覧専用）実装指示書 v1.0

## 0. メタ情報

* Task ID: WS-B02-01
* Component: B-02 BoardDetailPage（掲示板詳細画面）
* Scope: **閲覧専用機能のみ実装**（DB書き込みなし）
* Target files (例):

  * `app/board/[postId]/page.tsx`
  * `src/components/board/BoardDetail/BoardDetailPage.tsx` 他 BoardDetail 用コンポーネント一式
  * `src/server/board/getBoardPostById.ts`（既存 server 関数の利用）
* Out of scope（別タスク扱い）:

  * コメント投稿・削除
  * 投稿削除（確認ダイアログ含む）
  * お気に入りトグル
  * 翻訳ボタン（キャッシュ再生成）
  * 音声読み上げ（TTS）

## 1. 目的

掲示板詳細画面 `/board/[postId]` を **閲覧専用** の状態で実装し、以下を満たすことが目的です。

* BoardTop からの遷移先として、1件の投稿詳細を表示できること
* 翻訳キャッシュ（`board_post_translations`）を利用して、JA/EN/ZH で本文を切り替えて閲覧できること
* 添付ファイルの一覧表示とダウンロード入口があること
* PDF プレビュー UI の骨格があること（モーダル表示）
* AppHeader / AppFooter 含め、HarmoNet 共通レイアウトに準拠していること
* エラー／404／権限エラー時に、安全にハンドリングされていること

**このタスクでは DB 書き込みは一切行わない** ことが重要です。コメント投稿・削除、お気に入り、翻訳ボタン、TTS は後続タスクに分割します。

## 2. 参照設計書

実装時は以下の設計書を唯一の正として参照してください。

* `B-02_BoardDetail-detail-design-ch01-overview_v1.1.md`
* `B-02_BoardDetail-detail-design-ch02-layout V1.1.md`
* `B-02_BoardDetail-detail-design-ch03-data-model V1.2.md`
* `B-02_boarddetail-detail-design-ch04-state-event_v1.1.md`
* `B-02_BoardDetail-detail-design-ch05-ui-spec V1.2.md`
* `B-02_BoardDetail-detail-design-ch06-integration_v1.1.md`
* `B-02_BoardDetail-detail-design-ch07-test-plan_v1.1.md`

※ 設計書の仕様と異なる実装は行わないでください。疑問点があればコメントで質問し、勝手な拡張は避けてください。

## 3. スコープ（今回やること）

### 3-1. ルーティングとページ骨格

* Next.js App Router で `/board/[postId]` を実装し、`page.tsx` をサーバコンポーネントとして作成。
* やること:

  * URL パラメータから `postId`（UUID文字列）を取得。
  * `createSupabaseServerClient()` を使い、

    * `auth.getUser()` でログインユーザを取得
    * `user_tenants` からアクティブな `tenantId` を解決（BoardTop と同じロジックを踏襲）
  * 認証エラー or tenant 未所属の場合:

    * HOME など既存の挙動に合わせて `redirect('/login')` or エラーページに遷移（BoardTop と同じ扱い）
  * 正常に `tenantId` が取れた場合:

    * `getBoardPostById({ tenantId, postId, currentUserId })` を呼び出し、`BoardDetailPageData` を取得
    * データが null（存在しない or 閲覧権限なし）の場合は `notFound()` を返し、Next.js の 404 を表示
  * 正常取得できた場合のみ、`<BoardDetailPage data={...} />` を描画。

### 3-2. BoardDetailPage（閲覧専用）の UI 構成

`BoardDetailPage` はクライアントコンポーネントとし、次のようなセクション構成とします（設計書 ch02/ch05 に準拠）。

* AppHeader（既存コンポーネント）
* メインコンテンツ:

  1. 投稿ヘッダー

     * カテゴリ名・ラベル
     * タイトル
     * 投稿者表示名（`authorDisplayName`：翻訳しない）
     * 投稿日時
  2. 本文エリア

     * 現在の UI 言語向けの本文（翻訳キャッシュ or 原文）
  3. 添付ファイルリスト

     * PDF を含む添付ファイル名の一覧
     * 各項目に「ダウンロード」リンク／ボタン（`href` で Supabase Storage 等へ遷移するのみ）
     * PDF については、クリックで PDF プレビューモーダルを開ける UI の土台だけ作る（中身は簡易で可）
  4. コメント一覧（閲覧のみ）

     * コメント一覧をカード／リストで表示
     * 今回は **コメント投稿フォームは非表示 or disabled 表示** にしてよい（後続タスクで有効化）
  5. 戻り導線

     * 「掲示板一覧へ戻る」ボタン／リンク（`/board`）
* AppFooter（既存コンポーネント）

#### 3-2-1. 翻訳キャッシュの利用（post）

* `BoardDetailPageData` には少なくとも以下の情報が含まれている前提とします（設計書 ch03 に準拠）。

  ```ts
  type BoardPostDetail = {
    id: string;
    categoryKey: string;
    categoryName: string | null;
    originalTitle: string;
    originalContent: string;
    translations: {
      lang: 'ja' | 'en' | 'zh';
      title: string | null;
      content: string;
    }[];
    authorDisplayName: string;
    createdAt: string;
    // ...その他メタ情報
  };
  ```

* `useI18n()` / `useStaticI18n()` から `currentLocale`（`'ja' | 'en' | 'zh'`）を取得し、本文表示ロジックを BoardTop と同じにします。

  ```ts
  const translation = post.translations.find(tr => tr.lang === currentLocale);

  const effectiveTitle =
    translation && translation.title && translation.title.trim().length > 0
      ? translation.title
      : post.originalTitle;

  const effectiveContent = translation?.content ?? post.originalContent;
  ```

* 表示仕様:

  * タイトル: `effectiveTitle`
  * 本文: `effectiveContent`
  * 投稿者名: 常に `authorDisplayName`（翻訳しない）

#### 3-2-2. コメント一覧（閲覧のみ）

* `BoardDetailPageData` 内の `comments` を、簡易なカード／リストで表示します。
* 各コメントも、現時点では **原文のみ** 表示とし、翻訳キャッシュ利用は後続タスクで対応します。
* コメント投稿フォームは UI 上用意する場合でも:

  * 送信ボタンを disabled にする
  * もしくはコンポーネント自体を一旦非表示にする

※ コメントの投稿・削除・翻訳キャッシュ更新は **別タスク** のため、今回の実装では API 呼び出しを入れないでください。

### 3-3. PDF プレビュー UI の骨格

* 添付ファイル一覧のうち PDF に対しては、クリック時にモーダルで簡易プレビューを表示する UI の枠だけ用意します（設計書の PDF プレビュー仕様に準拠）。
* このタスクでは、PDF.js の詳細設定や細かい UI は簡略でも構いませんが、以下は満たしてください。

  * モーダルの開閉状態をローカル state で管理
  * モーダル内に `<iframe>` や簡易ビューコンポーネントを置けるようにする（実装が後から差し替え可能な形に）
  * 画面全体タップで閉じる／上部に閉じるアイコン配置など、共通仕様に沿った UX の土台を作る

### 3-4. エラー・ローディング・404

* `BoardDetailPage`（クライアント側）では、以下の状態表示を持たせてください。

  * `isLoading`: 初回描画時のローディング状態（サーバ側でデータ取得済みなら軽微で可）
  * `hasError`: データ不整合時や予期せぬエラー発生時にエラーメッセージを表示
* サーバ側で `getBoardPostById` が null を返した場合は `notFound()` を使い、Next.js の標準 404 に任せます。
* 例外が発生した場合は、`error.js`（App Router のエラーハンドラ）に処理を委ねて構いませんが、可能であれば BoardDetailPage 内で簡易なエラーバナーを表示する実装も検討してください。

## 4. スコープ外（やらないこと）

このタスク WS-B02-01 では、以下は **絶対に実装しないでください**。

* コメント投稿／削除（API 呼び出し含む）
* 投稿削除（確認ダイアログ + DELETE/PATCH API）
* お気に入りトグル
* 翻訳ボタン（翻訳再実行 & キャッシュ更新）
* TTS（音声読み上げボタンと API 呼び出し）
* RLS や DB スキーマの変更

これらは B-02 系の後続タスク（WS-B02-02 以降）で扱います。閲覧専用の BoardDetail を安全に完成させることが今回のゴールです。

## 5. テスト観点（今回カバーする範囲）

B-02 ch07 のうち、今回スコープに入る観点だけをテスト対象とします。

* 正常系

  * BoardTop から `/board/[postId]` に遷移したとき、対象投稿の詳細が表示される
  * JA/EN/ZH の UI 言語切り替えで、タイトル・本文が翻訳キャッシュに応じて切り替わる
  * 投稿者表示名は常に原文表示であること
  * 添付ファイル一覧が正しく表示され、クリックでダウンロード or PDF プレビューモーダルが開く
* 異常系

  * 存在しない `postId` の場合は 404 になる
  * tenant 未所属ユーザがアクセスした場合は BoardTop と同等の扱い（ログインへリダイレクト等）になる
  * `getBoardPostById` がエラーを返した場合に、画面レベルのエラーメッセージが表示される or 標準エラーハンドラが機能する

テスト実装は、既存の BoardTop Page や Home Page のテスト構成に揃えてください。

## 6. 受け入れ条件（Done の定義）

* `/board/[postId]` にアクセスしたとき、仕様どおりのレイアウトで投稿詳細が表示されること
* BoardTop と同様、UI 言語切り替えで本文表示が翻訳キャッシュを優先して切り替わること
* 添付ファイルリストが表示され、PDF についてはプレビューモーダルが開くこと
* 投稿者表示名が翻訳されず、常に原文表示であること
* コメント投稿・削除・お気に入り・翻訳ボタン・TTS の UI が誤って動作していないこと（あっても disabled / 非表示）
* RLS や DB スキーマに対する変更を一切行っていないこと
* B-02 ch01〜ch07 の仕様と矛盾する挙動がないこと

この条件をすべて満たしたら、WS-B02-01 は完了とみなします。
