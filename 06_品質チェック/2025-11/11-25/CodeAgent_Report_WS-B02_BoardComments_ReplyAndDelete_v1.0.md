# CodeAgent 作業報告書

- ドキュメント種別: 作業報告書（CodeAgent）
- 対象タスク ID: WS-B02_BoardComments_ReplyAndDelete_v1.0
- 日付: 2025-11-25
- 担当: CodeAgent（Cascade）

---

## 1. 対象ドキュメント／機能概要

- 対象指示書:
  - `D:\AIDriven\01_docs\05_製造\01_Windsurf-作業指示書\WS-B02_BoardComments_ReplyAndDelete_v1.0.md`
- 対象画面／機能:
  - 掲示板詳細画面（BoardDetail）
  - 掲示板一覧画面（BoardTop）
  - 掲示板投稿フォーム（BoardPostForm）
  - コメント投稿・削除 API
  - 関連するホーム画面コンポーネント（レイアウト調整のみ）

機能概要:
- 掲示板の各投稿に対して「コメント（返信）」を投稿できるようにする。
- 自分が投稿したコメントを削除できるようにする（ソフトデリート）。
- コメント数の表示、投稿画面での「返信モード」対応、文言・ボタン・カードの UI 統一を行う。

---

## 2. 実装／修正内容

### 2-1. コメント投稿 API の実装

**対象ファイル**
- `app/api/board/comments/route.ts`

**主な内容**
- `POST /api/board/comments` を新規実装。
- Supabase Auth を用いて認証し、`users`・`user_tenants` テーブルでテナント所属を確認。
- リクエストボディから `postId` と `content` を受け取り、以下を検証:
  - `tenantId` と `authorId` がログインユーザと一致していること。
  - 対象 `board_posts` が `status = 'published'` で存在すること。
  - 管理組合専用カテゴリ（`important` / `circular` / `event` / `rules`）にはコメントを作成できないこと。
- `board_comments` に `status = 'active'` でレコードを作成。
- 作成後、`BoardPostTranslationService` と `GoogleTranslationService` を利用し、コメント本文を他言語に翻訳して `board_comment_translations` にキャッシュ。

### 2-2. コメント削除 API の実装

**対象ファイル**
- `app/api/board/comments/[commentId]/route.ts`

**主な内容**
- `DELETE /api/board/comments/[commentId]` を新規実装。
- Supabase Auth でユーザを特定し、`users`・`user_tenants` でテナント所属を検証。
- URL パラメータまたはパス解析から `commentId` を取得し、該当コメントを検索。
- 以下の条件を満たす場合のみ削除を許可:
  - コメントの `tenant_id` がユーザのテナントと一致。
  - `author_id` がログインユーザと一致（本人のみ削除可）。
- 実際の削除はソフトデリート方式:
  - `status` を `'deleted'` に更新。
  - 更新に失敗した場合のみ `delete` による物理削除をフォールバックとして試行。

### 2-3. 投稿詳細取得ロジックの拡張

**対象ファイル**
- `src/server/board/getBoardPostById.ts`

**主な内容**
- `BoardCommentDto` に以下のフィールドを追加:
  - `isDeletable: boolean`（`author_id === currentUserId` のとき `true`）
  - `translations: { lang, content }[]`（`board_comment_translations` から取得）
- `BoardPostDetailDto` を拡張:
  - 既存の `isFavorite` に加え、`isDeletable`（親投稿自体を削除可能か）を追加。
  - `isDeletable` は `post.author_id === currentUserId` で判定。
- Prisma クエリでコメントを取得する際、`status = 'active'` のみ対象とし、
  `author.display_name` と翻訳テーブルを `select` で取得。

### 2-4. 掲示板詳細画面（BoardDetailPage）の拡張

**対象ファイル**
- `src/components/board/BoardDetail/BoardDetailPage.tsx`

**主な内容**
1. **コメント一覧と返信ボタン**
   - 投稿本文カード下に「返信する」ボタンを配置。
     - 一般カテゴリのみ表示（`important` / `circular` / `event` / `rules` は返信不可）。
     - クリックで `/board/new?replyTo={postId}` に遷移。
   - コメント一覧を表示:
     - 表示項目: `authorDisplayName`・投稿日・本文。
     - コメント本文は `currentLocale` に一致する翻訳があればそれを優先し、なければ元の `content` を表示。

2. **コメント削除 UI**
   - コメントごとに、`isDeletable === true` の場合のみ削除アイコン（`Trash2`）を表示。
   - アイコンクリックでフローティングの削除確認モーダルを表示。
     - オーバーレイ: `bg-transparent`（背面を暗くしない）。
     - カード本体: `rounded-lg border-2 border-gray-200 bg-white/90 shadow-lg`。
     - 文言はすべて i18n キー（`board.detail.comment.deleteConfirmMessage` 等）で管理。
   - 「削除する」押下で `DELETE /api/board/comments/{commentId}` をコールし、成功時にローカル state から該当コメントを削除。

3. **親投稿の削除機能**
   - `data.isDeletable` が `true` の場合のみ、ヘッダーのスターの下に「投稿を削除」ボタンを表示。
   - クリックでコメントと同様のスタイルの確認モーダルを表示（文言は投稿用の i18n キー）。
   - 「削除する」で `DELETE /api/board/posts/{postId}` をコールし、成功時に `/board` へリダイレクト。
   - サーバ側は `status = 'archived'` への更新でソフトデリートを実施し、一覧・詳細のいずれにも表示されなくなるようにした。

4. **読み上げ（TTS）との共存**
   - TTS 機能との競合が起きないよう、既存の状態管理を維持しつつ、返信ボタン・削除ボタンを追加。
   - 読み上げボタンもカードや他ボタンに合わせた角丸・配色に調整。

5. **デザイン統一（詳細画面内）**
   - 本文カード・添付ファイルカードを `rounded-lg border-2 border-gray-200` で統一。
   - 「返信する」「読み上げる」「プレビュー」「ダウンロード」などのボタンを、
     `rounded-md border-2` ベースの四角ボタンで統一し、青系の配色に揃えた。

### 2-5. 掲示板投稿フォーム（返信モード対応）

**対象ファイル**
- `src/components/board/BoardPostForm/BoardPostForm.tsx`

**主な内容**
- `useSearchParams` で `replyTo` クエリを読み取り、存在する場合は「返信モード」として動作させる。
- 返信モード時の仕様:
  - カテゴリ選択 UI を非表示＆バリデーション対象外。
  - 投稿者区分（管理組合／一般）の選択 UI を非表示。
  - 表示名選択（ニックネーム／匿名）を非表示にし、プロフィールの `display_name` をそのまま使用。
  - `onSubmit` では `/api/board/posts` ではなく `/api/board/comments` をコールし、
    `postId = replyTo` と本文を送信。
  - 投稿成功後は `/board/{replyTo}` の詳細画面へリダイレクト。
- 既存の新規投稿（通常モード）の挙動は変更なし。

### 2-6. 掲示板一覧へのコメント数表示

**対象ファイル**
- `app/api/board/posts/route.ts`
- `src/components/board/BoardTop/types.ts`
- `src/components/board/BoardTop/BoardTopPage.tsx`
- `src/components/board/BoardTop/BoardPostSummaryCard.tsx`

**主な内容**
- API DTO `BoardPostSummaryDto` に `replyCount: number` を追加し、
  Prisma の `_count.comments` から値を取得。
- `BoardPostSummary` 型に `replyCount` を追加し、`BoardTopPage` で API 応答からマッピング。
- `BoardPostSummaryCard` で、右下の添付アイコン横に返信アイコン＋返信数を表示:
  - `MessageCircle` と `replyCount` を並べて表示。
  - ツールチップは `board.top.reply.tooltip` を使用。

### 2-7. UI のスタイル統一（掲示板／ホーム共通）

**主な対象ファイル**
- `src/components/board/BoardDetail/BoardDetailPage.tsx`
- `src/components/board/BoardTop/BoardPostSummaryCard.tsx`
- `src/components/board/BoardTop/BoardTabBar.tsx`
- `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
- `src/components/home/HomeFeatureTiles/HomeFeatureTile.tsx`

**主な内容**
- 角丸の統一:
  - カード類（掲示板詳細本文カード、添付カード、掲示板TOPカード、ホームのお知らせカード、ホーム機能タイル）をすべて `rounded-lg` に統一。
  - カテゴリタブ（BoardTabBar）のタブボタンを `rounded-lg` に変更。
  - カテゴリバッジ／お知らせバッジを `rounded-lg` に変更。
  - 小ボタン類（返信、読み上げる、プレビュー、ダウンロード）は `rounded-md` に統一。
- ボーダー・透過の統一:
  - カードは基本 `border-2 border-gray-200`。
  - 削除確認モーダルのカードは `border-2 border-gray-200 bg-white/90` で半透明。
  - オーバーレイは `bg-transparent` とし、背面の暗転を行わない。

---

## 3. バグ修正・仕様調整

### 3-1. コメント削除時の 500 エラー解消

**現象**
- コメント削除時に `id: undefined` が Prisma に渡され、500 エラーが発生していた。
- 翻訳テーブルとの FK 制約により、物理削除でもエラーになるケースがあった。

**対応**
- ルートパラメータまたは URL パス解析により、必ず `commentId` を特定し、
  取得できない場合は 400 (`validation_error`) を返すように修正。
- 物理削除ではなく `status = 'deleted'` への更新を基本とし、
  更新に失敗した場合のみ `delete` をフォールバックで実行するように変更。

### 3-2. 返信モード時の UI/仕様不整合

**現象**
- 管理組合が投稿した記事にも返信ボタンが表示されていた。
- 返信モードで、投稿者区分やカテゴリ選択、表示名選択が表示されていた。
- 匿名チェックをつけても、コメントではニックネームが表示されるなど、意図しない挙動があった。

**対応**
- 管理組合投稿カテゴリには返信ボタンを表示しないように制御。
- 返信モード時は、投稿者区分・カテゴリ・表示名の選択 UI をすべて非表示＆バリデーション対象外とした。
- コメントは常にユーザの `display_name` を使用する挙動に統一し、
  匿名フラグはコメントには影響しない仕様とした。

### 3-3. コメント本文の動的翻訳対応

**現象**
- 投稿本文は UI 言語に応じて翻訳表示されていたが、コメント本文は原文固定で表示されていた。

**対応**
- コメント作成時に `BoardPostTranslationService` を通じて翻訳を生成・キャッシュ。
- 詳細画面で表示する際、`currentLocale` に一致する翻訳があればそれを使用するように変更。

### 3-4. 削除確認 UI の改善

**現象**
- ブラウザ標準の `window.confirm` を使用しており、見た目・体験ともに不統一だった。
- 言語切替時にモーダルが閉じる挙動や、透過度・枠線の太さなどが要望と合っていなかった。

**対応**
- `window.confirm` を廃止し、画面内のカスタムモーダルに置き換え。
- 背景は透過 (`bg-transparent`)、モーダル本体は `bg-white/90` + `border-2 border-gray-200` + `shadow-lg` に調整。
- ボタン文言・メッセージをすべて i18n キー経由に変更し、多言語対応を完了。
- 言語切替ボタン押下時にモーダルが閉じる点については、
  仕組み上ページ再レンダリングが入るため、
  「先に言語を切り替えてから削除操作を行う」という運用前提で整理。

---

## 4. 確認結果

- 返信ボタン:
  - 管理組合カテゴリ以外の投稿にのみ表示されることを確認。
  - クリックで `/board/new?replyTo={postId}` に遷移し、返信モード UI となることを確認。
- 返信モード UI:
  - カテゴリ／投稿者区分／表示名の選択が表示されないことを確認。
  - 投稿時に `/api/board/comments` が呼ばれ、親投稿の詳細画面に戻ることを確認。
- コメント表示:
  - ログインユーザが投稿したコメントのみ削除アイコンが表示されることを確認。
  - UI 言語を切り替えた際、コメント本文も翻訳テキストに切り替わることを確認。
- コメント削除:
  - 削除アイコンクリックでカスタムモーダルが表示されることを確認。
  - 「削除する」押下で API が 200 を返し、一覧から当該コメントが消えることを確認。
- 親投稿削除:
  - 自分が投稿した記事のみ「投稿を削除」ボタンが表示されることを確認。
  - 確認モーダル経由で削除し、一覧から該当記事が消えることを確認。
- コメント数表示:
  - 掲示板TOPカードで、返信が 1 件以上ある投稿に `MessageCircle` アイコンと件数が表示されることを確認。
- スタイル統一:
  - 掲示板TOP／詳細／ホーム画面のカード・タブ・バッジ・ボタンの角丸・枠線が、指示されたデザイン方針に沿って統一されていることを目視確認。

---

## 5. 残課題・補足

- 言語切替時に開いている削除確認モーダルを維持するには、
  ルーティングや状態管理の仕組みをより大きく変更する必要があるため、
  現段階では「言語を切り替えてから削除操作を行う」ことを前提とした。
- コメント削除・投稿削除はいずれもソフトデリート（`status` 更新／`archived`）で実装しており、
  物理削除や履歴参照などの要件が将来追加される場合は、
  別途要件定義が必要となる。

以上。
