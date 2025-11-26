# WS-B03 BoardPostForm RichText 実装作業指示書 v1.2

**Task ID:** WS-B03_BoardPostForm_RichText
**Target Component:** B-03 BoardPostForm
**Version:** 1.2
**CodeAgent_Report:** `/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_RichText_v1.2.md`
**Location (implementation):** `src/components/board/BoardPostForm/` 配下

---

## 1. ゴール / Scope

### 1.1 ゴール

掲示板投稿画面 **BoardPostForm** において、

* 全ユーザ（管理組合・一般利用者とも）について、投稿本文入力を **TipTap を用いたリッチテキストエディタ** に統一し、
* 本文を

  * 検索・翻訳・TTS・モデレーション用の **テキスト正（プレーンテキスト）** として `board_posts.content` に保存し、
  * 表示用の **リッチ HTML** として `board_posts.content_html` に保存する

ように実装する。

既存の翻訳/TTS/モデレーション/検索は `board_posts.content` のみを参照し続け、今回の変更による退行がないことを保証する。

### 1.2 Scope

**含める範囲**

* BoardPostForm 内の投稿本文入力エリアの実装変更

  * 全ユーザ TipTap（PC=フルツールバー、SP=簡易ツールバー）
* `BoardPostFormState` / DTO の調整

  * `content` … テキスト正（プレーンテキスト）
  * `contentHtml` … TipTap HTML
* 送信ロジックの調整

  * `UpsertBoardPostRequest` に `content` / `contentHtml` を分けて渡す
  * バックエンドで `content` → `board_posts.content`、`contentHtml` → `board_posts.content_html` に保存できる前提で送信する
* バリデーションロジック

  * テキスト正 `content` が空の場合はエラーとする（管理組合/一般共通）

**含めない範囲（今回はやらない）**

* BoardDetail 側の HTML レンダリング実装
* 翻訳/TTS/モデレーション/検索ロジックの変更

  * これらは今後も `board_posts.content`（テキスト正）のみを参照する前提とする
* DB スキーマ変更

  * `board_posts.content_html` は TKD により schema.prisma / db push 済み前提とし、ここでは触らない

---

## 2. 参照ドキュメント

実装前に必ず以下を確認すること。

* B-03 BoardPostForm 詳細設計 ch02 レイアウト v1.2

  * `BoardPostFormContentSection` の構成
  * 全ユーザ TipTap（Desktop / Mobile）の出し分け
* B-03 BoardPostForm 詳細設計 ch03 データモデル v1.2

  * `BoardPostFormInput` / `UpsertBoardPostRequest` の `content` / `contentHtml` 定義
  * テキスト正と HTML の二重保持方針
* B-03 BoardPostForm 詳細設計 ch04 ロジック v1.2

  * `BoardPostFormState.content` / `contentHtml`
  * `onChangeContentHtml` / `validateForm` / `onConfirmSubmit` の処理フロー
* HarmoNet フロントエンドディレクトリガイドライン

  * コンポーネント配置規約・命名規約
* Windsurf 実行指示テンプレート v1.2

  * テスト・レポートの書き方、禁止事項など

※ 設計書に記載されていない仕様を「良かれと思って」追加しないこと。必ず設計に合わせる。

---

## 3. 実装対象ファイル（想定）

※ 実際のファイル構成に合わせて微調整してよいが、ディレクトリ構成を勝手に変えないこと。

* `src/components/board/BoardPostForm/BoardPostForm.tsx`
* `src/components/board/BoardPostForm/BoardPostFormContentSection.tsx`（存在する場合）
* `src/components/board/BoardPostForm/RichTextEditorDesktop.tsx`（新規）
* `src/components/board/BoardPostForm/RichTextEditorMobile.tsx`（新規）
* `src/components/board/BoardPostForm/hooks/useBoardPostForm.ts` などのフック類（存在する場合）

既存ファイル名と異なる場合は、設計の意図（本文エリアを分割する）を保ったまま、最小限の調整に留めること。

---

## 4. ロジック仕様（要約・契約）

### 4.1 投稿本文入力の出し分け

* `isDesktop` を用いて、本文エディタを PC / SP で切り替える。

```tsx
if (isDesktop) {
  return (
    <RichTextEditorDesktop
      value={contentHtml ?? ""}
      onChange={onChangeContentHtml}
    />
  );
}

return (
  <RichTextEditorMobile
    value={contentHtml ?? ""}
    onChange={onChangeContentHtml}
  />
);
```

* `RichTextEditorDesktop`

  * TipTap を使用する PC 向けリッチテキストエディタ。
  * 機能: 段落、見出し(h2/h3)、太字、斜体、箇条書き、番号付きリスト、リンク挿入など。
  * `value: string` には HTML を渡し、初期化時に `editor.setContent(value)` 相当で読み込む。
  * `onChange(value: string)` には `editor.getHTML()` の結果を渡す。

* `RichTextEditorMobile`

  * TipTap を使用するスマホ向け簡易リッチテキストエディタ。
  * 機能: 太字、箇条書き、リンク程度に限定（ツールバーをコンパクトに）。
  * `value` / `onChange` の仕様は Desktop と同じ（HTML）。

### 4.2 State と DTO との対応

* `BoardPostFormState`

  * `content: string` … テキスト正（プレーンテキスト）。管理組合・一般どちらもここに「読むべき本文」が入る。
  * `contentHtml: string | null` … TipTap HTML。空のときは `""` または `null`。

* `onChangeContentHtml(nextHtml: string)`

  * TipTap から呼ばれるハンドラ。
  * `state.contentHtml = nextHtml ?? ""` とし、同時に `state.content` には HTML からタグを除去したプレーンテキストを格納する（ch04 のロジック参照）。
  * これにより、翻訳/TTS/モデレーション/検索は常に `state.content` だけ見ればよい。

* `UpsertBoardPostRequest`

  * `content` … テキスト正（プレーンテキスト）。`state.content` をそのまま入れる。
  * `contentHtml` … リッチHTML。`state.contentHtml ?? null` を入れる。

### 4.3 バリデーション

`validateForm(state)` 内で以下を行う。

* 共通:

  * `title.trim().length > 0` を必須。
  * `categoryTag` が選択されていること。
  * `displayNameMode` が null でないこと。

* 本文（テキスト正）:

  ```ts
  if (!state.content.trim()) {
    errors.push("board.postForm.error.contentRequired");
  }
  ```

  * 管理組合/一般どちらも、内容の有無は `state.content` だけで判定する。

### 4.4 送信フロー

* `onClickSubmit`:

  * `validateForm` 実行。
  * エラーがあれば画面に表示し、送信ダイアログは開かない。
  * エラーがなければプレビュー兼確認ダイアログを開く。

* `onConfirmSubmit`:

  * 再度 `validateForm` を呼び、OK なら `UpsertBoardPostRequest` を組み立てて API 呼び出し。

  ```ts
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
  ```

  * 成功時は `postId` を受け取り、BoardDetail (`/board/[postId]`) に遷移。

---

## 5. テスト観点 / 確認項目

### 5.1 管理組合投稿（PC）

* 管理組合ユーザでログインし、BoardPostForm を開く。
* 本文エリアが TipTap リッチエディタになっていること。
* 太字/見出し/リスト/リンク等を使用して投稿し、

  * ネットワークタブまたはログで、リクエストボディの

    * `content` がプレーンテキスト
    * `contentHtml` が HTML
      になっていることを確認。
* 本文を完全に削除して「投稿する」と、「本文は必須です」相当のエラーで弾かれること（`state.content` が空判定になる）。

### 5.2 管理組合投稿（スマホ）

* スマホ幅で BoardPostForm を開く（ブラウザのレスポンシブモードでも可）。
* 本文エリアが簡易ツールバー付きの TipTap になっていること。
* 太字/箇条書き/リンクを使って投稿し、`content` / `contentHtml` が上記と同じルールで送信されること。

### 5.3 一般ユーザ投稿

* 一般ユーザでログインし、BoardPostForm を開く。
* 本文エリアが TipTap（簡易でも可）になっていること。
* 通常のテキスト投稿が問題なく行えること。
* リクエストボディで `content` がプレーンテキスト、`contentHtml` が簡素なHTMLになっていることを確認。

### 5.4 既存仕様のリグレッション

* カテゴリ選択・添付ファイル・回覧板フラグなど、本文以外の挙動が変わっていないことを確認。
* 既存の Jest / RTL テストがあれば、型エラー・テスト失敗がないこと。
* 翻訳/TTS/モデレーション/検索まわりの実装で、`post.content`（テキスト正）だけを参照していることをざっと確認する（新たに HTML 参照箇所を増やさない）。

---

## 6. 品質基準 / 完了条件

* TypeScript の型エラーなし。
* ESLint / Prettier による静的チェックでエラーなし。
* 本書 5 章の観点で手動確認を行い、すべて OK。
* 既存テスト（Jest / RTL）が全てパスすること（落ちている場合はレポートに明記）。
* CodeAgent_Report を `/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_RichText_v1.2.md` に作成し、

  * 実施内容
  * 変更したファイル一覧
  * セルフスコア（10点満点）
  * 残課題があれば列挙
    を記載すること。

---

## 7. 禁止事項 / 注意

* 設計書に存在しない新機能・新仕様を勝手に追加しないこと。

  * 通知仕様・既読管理・翻訳キャッシュ等に手を入れない。
* DB スキーマ（Prisma / Supabase）を変更しないこと。

  * `board_posts.content_html` は追加済み前提とし、触らない。
* 既存のディレクトリ構成・ファイル名を、必要以上に変更しないこと。
* CSS を大幅に変更せず、既存のデザインガイドラインに従うこと。

---

## 8. CodeAgent_Report に書いてほしいこと（メモ）

* どのコンポーネントに TipTap を導入したか。
* `BoardPostFormState.content` / `contentHtml` と `UpsertBoardPostRequest.content` / `contentHtml` の対応関係。
* 管理組合投稿と一般投稿で挙動が分かれる箇所（カテゴリ候補・権限など）の一覧。
* 自己評価スコア（10 点満点）と、その根拠。
