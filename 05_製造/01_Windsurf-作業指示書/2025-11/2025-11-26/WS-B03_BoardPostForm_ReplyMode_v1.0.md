# WS-B03 BoardPostForm ReplyMode 実装指示書 v1.0

**Category:** 製造 / Windsurf 実装タスク
**Component ID:** B-03
**Component Name:** BoardPostForm 返信モード対応
**Doc ID:** WS-B03_BoardPostForm_ReplyMode_v1.0
**Target Branch:** `feature/board-reply-mode`（名称は必要に応じて変更可）
**CodeAgent_Report 保存先:** `/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_ReplyMode_v1.0.md`

---

## 1. 目的 / ゴール

掲示板詳細画面からの「返信投稿」において、以下を実現する。

1. `board_comments` に投稿時点の表示名（管理組合 / 匿名 / ニックネーム）を焼き付ける `author_display_name` カラムを利用する。
2. `BoardPostForm` を新規投稿と返信の両方で共通利用しつつ、返信時のみ UI と送信ペイロードを切り替える。
3. 管理組合ロールのみ「投稿者区分（管理組合 / 一般利用者）」を選択可能とし、一般利用者は投稿者区分 UI を表示しない。
4. 返信コメント一覧の表示名として、`author_display_name` を優先的に利用する。

本タスク完了後、管理組合・一般利用者ともに「投稿（/board/new）」と同じ世界観で返信が行えることをゴールとする。

---

## 2. スコープ

### 2.1 対象

* フロントエンド

  * `BoardPostForm` コンポーネント
  * Board 詳細画面（コメント一覧表示部）
  * `/app/board/new/page.tsx`（ルーティングとモード判定）
* バックエンド

  * 返信コメントの作成 API（`board_comments` への INSERT を行うエンドポイント）
* DB / Prisma

  * 既に追加済みの `board_comments.author_display_name` カラムを利用する前提（本タスクでは schema 変更は行わない）

### 2.2 非スコープ

* 返信における添付ファイル機能の追加
* コメントスレッド（コメント同士の親子関係）の実装
* 管理画面からのコメント編集・削除機能
* AI モデレーションや翻訳キャッシュの仕様変更

---

## 3. 事前条件 / 参照資料

### 3.1 前提

* 開発環境

  * ローカル Supabase（Docker）と `D:\Projects\HarmoNet` の Next.js プロジェクトが起動可能な状態であること。
* DB 状態

  * `prisma db push` 済みで、`board_comments` に下記カラムが存在すること。

```prisma
model board_comments {
  id                  String         @id @default(uuid())
  tenant_id           String
  post_id             String
  author_id           String
  content             String         @db.Text
  parent_comment_id   String?
  created_at          DateTime       @default(now())
  updated_at          DateTime       @updatedAt
  status              comment_status @default(active)

  author_display_name String?        @db.VarChar(100)
  // 既存リレーションは変更しない
}
```

### 3.2 参照資料（Read-only）

* 詳細設計

  * `/01_docs/04_詳細設計/03_掲示板画面/` 配下の Board 関連詳細設計書（board_posts / board_comments 表示仕様など）
* 既存 Windsurf 指示書

  * `WS-B03_BoardPostForm_RichText_v1.0.md`（BoardPostForm リッチテキスト化）
* 技術スタック

  * `/01_docs/01_要件定義/01_技術スタック/harmonet-technical-stack-definition_v4.5.md`

※ 参照のみであり、本タスクでこれら文書を変更してはならない。

---

## 4. 実装タスク詳細

### 4.1 API: 返信コメント作成処理の拡張

**対象:** 返信コメントを作成する API Route（例: `app/api/board/comments/route.ts` など。実在ファイルを自動検出して編集すること）。

1. リクエストボディ仕様を以下のように拡張する。

   ```ts
   type CreateCommentRequest = {
     postId: string;               // 返信対象の board_posts.id
     content: string;              // コメント本文
     authorType?: "admin" | "user";     // 管理組合のみ有効
     displayMode: "anonymous" | "nickname"; // 匿名 or ニックネーム
   };
   ```

2. セッションユーザ情報からロールと表示名を取得する。

   * `isTenantAdmin`: 現在のユーザが管理組合（tenant_admin 相当ロール）かどうか
   * `display_name`: `users.display_name`

3. `authorType` の最終値を決定する。

   ```ts
   const isTenantAdmin = /* ロール判定 */;
   const requestedAuthorType = body.authorType; // "admin" | "user" | undefined

   const finalAuthorType: "admin" | "user" =
     isTenantAdmin && requestedAuthorType === "admin" ? "admin" : "user";
   ```

4. `displayMode` と `finalAuthorType` から `author_display_name` を決定する。

   * `finalAuthorType === "admin"` → `"管理組合"`
   * `finalAuthorType === "user"` かつ `displayMode === "anonymous"` → `"匿名"`
   * `finalAuthorType === "user"` かつ `displayMode === "nickname"` → `sessionUser.display_name ?? "匿名"`

   ```ts
   let authorDisplayName: string;

   if (finalAuthorType === "admin") {
     authorDisplayName = "管理組合";
   } else if (body.displayMode === "anonymous") {
     authorDisplayName = "匿名";
   } else {
     authorDisplayName = sessionUser.display_name ?? "匿名";
   }
   ```

5. `prisma.board_comments.create()` 呼び出し時に `author_display_name` を含めて保存する。

   ```ts
   await prisma.board_comments.create({
     data: {
       tenant_id: sessionUser.tenant_id,
       post_id: body.postId,
       author_id: sessionUser.id,
       content: body.content,
       author_display_name: authorDisplayName,
       // parent_comment_id は必要に応じて既存仕様どおり
     },
   });
   ```

6. RLS / 認可ロジックは既存仕様（board_comments の INSERT 可否判定）を変更しないこと。

---

### 4.2 BoardPostForm: 返信モード対応

**対象:** `src/components/board/BoardPostForm/BoardPostForm.tsx`（ディレクトリ名は現物を確認して修正）。

1. Props に `mode` と `replyToPostId` を追加する。

   ```ts
   type BoardPostFormProps = {
     mode?: "create" | "reply"; // 既定値は "create"
     replyToPostId?: string;      // 返信対象の投稿ID
     // 既存の props は変更しない
   };
   ```

2. コンポーネント内部でモードとロールを判定する。

   ```ts
   const isReply = mode === "reply";
   const { currentUser } = useCurrentUser(); // 既存のユーザ取得ロジックを利用
   const isTenantAdmin =
     !!currentUser?.roles?.includes("tenant_admin"); // 実際のロール名に合わせる
   ```

3. 返信モード専用のローカル state を追加する。

   ```ts
   const [authorType, setAuthorType] = useState<"admin" | "user">(
     isTenantAdmin ? "admin" : "user",
   );

   const [displayMode, setDisplayMode] = useState<"anonymous" | "nickname">(
     "nickname",
   );
   ```

4. フォーム項目の表示制御ルールを実装する。

   * `isReply === false`（新規投稿）

     * 既存の UI（投稿者区分・カテゴリ・タイトル・添付など）を変更しない
   * `isReply === true`（返信）

     * タイトル入力欄：非表示
     * カテゴリ選択：非表示
     * 添付ファイル関連 UI：非表示
     * 本文入力欄：必須（既存の本文編集 UI をそのまま利用）

5. 返信モード時の「投稿者区分 / 表示名」UI を実装する。

   * 管理組合ロール (`isTenantAdmin === true`):

     ```tsx
     {isReply && isTenantAdmin && (
       <section>
         {/* 投稿者区分 */}
         <RadioGroup
           value={authorType}
           onValueChange={(v) => setAuthorType(v as "admin" | "user")}
         >
           <Radio value="admin" label="管理組合として返信する" />
           <Radio value="user" label="一般利用者として返信する" />
         </RadioGroup>
       </section>
     )}

     {isReply && (
       <section>
         {authorType === "admin" ? (
           <p>表示名：管理組合</p>
         ) : (
           <RadioGroup
             value={displayMode}
             onValueChange={(v) =>
               setDisplayMode(v as "anonymous" | "nickname")
             }
           >
             <Radio value="anonymous" label="匿名で返信する" />
             <Radio value="nickname" label="ニックネームで返信する" />
           </RadioGroup>
         )}
       </section>
     )}
     ```

   * 一般利用者ロール (`isTenantAdmin === false`):

     ```tsx
     {isReply && !isTenantAdmin && (
       <section>
         <RadioGroup
           value={displayMode}
           onValueChange={(v) =>
             setDisplayMode(v as "anonymous" | "nickname")
           }
         >
           <Radio value="anonymous" label="匿名で返信する" />
           <Radio value="nickname" label="ニックネームで返信する" />
         </RadioGroup>
       </section>
     )}
     ```

6. `handleSubmit` 内で `isReply` に応じて送信先とペイロードを切り替える。

   * 新規投稿 (`isReply === false`): 既存の投稿 API をそのまま利用し、既存挙動を変えない。
   * 返信 (`isReply === true`): 4.1 で拡張したコメント作成 API を呼び出す。

   ```ts
   if (isReply) {
     await fetch("/api/board/comments", {
       method: "POST",
       headers: { "Content-Type": "application/json" },
       body: JSON.stringify({
         postId: replyToPostId,
         content: formValues.content,
         authorType,
         displayMode,
       }),
     });
   } else {
     // 既存の新規投稿ロジック
   }
   ```

7. 返信送信後の画面遷移は既存のコメント投稿フローに合わせる（例: Board 詳細画面への戻り、フォームのリセットなど）。

---

### 4.3 `/board/new` でのモード判定

**対象:** `app/board/new/page.tsx`

1. `searchParams.replyTo` の有無でモードを判定するように修正する。

   ```ts
   type BoardNewPageProps = {
     searchParams: {
       replyTo?: string;
     };
   };

   export default function BoardNewPage({ searchParams }: BoardNewPageProps) {
     const replyTo = searchParams.replyTo;

     return (
       <BoardPostForm
         mode={replyTo ? "reply" : "create"}
         replyToPostId={replyTo}
       />
     );
   }
   ```

2. 既存の新規投稿リンクに影響を与えないようにする（`/board/new` は `mode="create"` のまま）。

3. Board 詳細画面の「返信」ボタンからは `/board/new?replyTo=<postId>` 形式で遷移している前提とする。もし未実装の場合は、Board 詳細画面の JSX 内でリンクを修正する。

---

### 4.4 Board 詳細画面での表示名切り替え

**対象:** Board 詳細画面（コメント一覧）コンポーネント。`board_comments` の表示部分を変更する。

1. コメント表示時の表示名を以下の優先順位で決定するよう修正する。

   * `comment.author_display_name` が存在する場合 → それを表示
   * なければ既存の `comment.author.display_name`（Prisma の `include` 結果）を表示

   ```tsx
   const displayName =
     comment.author_display_name ?? comment.author?.display_name ?? "匿名";
   ```

2. それ以外の UI（本文・作成日時・ステータス表示など）は変更しない。

---

## 5. テスト観点

### 5.1 手動テスト項目

ブラウザは主にスマートフォン相当幅（DevTools で幅 390px 前後）で確認する。

1. 一般利用者としてログイン

   1. 掲示板詳細を開き、任意の投稿詳細に遷移
   2. 返信ボタンから `/board/new?replyTo=...` に遷移
   3. 返信フォームに「表示名（匿名/ニックネーム）」のみが表示され、「投稿者区分」が表示されていないこと
   4. 匿名を選択して返信 → コメント一覧に `表示名: 匿名` で表示されること
   5. ニックネームを選択して返信 → コメント一覧に `users.display_name` が表示されること

2. 管理組合ユーザとしてログイン

   1. 同様に掲示板詳細 → 返信画面へ遷移
   2. 「投稿者区分（管理組合として返信する / 一般利用者として返信する）」が表示されること
   3. 管理組合を選択して返信 → コメント一覧に `表示名: 管理組合` と表示されること
   4. 一般利用者を選択し、匿名/ニックネームを切り替えて返信 → それぞれ期待通りの表示名になること

3. 新規投稿への影響

   1. `/board/new` からの新規投稿が従来どおりに行えること
   2. 新規投稿フォームにおける UI（カテゴリ、タイトル、添付など）が変化していないこと

### 5.2 自動テスト（任意 / 可能な範囲）

* 既存の Board 関連テストが存在する場合、スナップショット等が崩れていないか確認する。
* 余力があれば、`BoardPostForm` のユニットテストで返信モード時の表示制御（admin / user の違い）を確認する。

---

## 6. 禁止事項・制約

1. 設計書にない仕様の追加・変更は禁止

   * 本指示書および既存詳細設計に記載されていない挙動を独自判断で追加しないこと。
2. Prisma スキーマの変更禁止

   * `board_comments.author_display_name` 以外の schema 変更は行わないこと。
3. RLS / 認可ロジックの変更禁止

   * Supabase 側の RLS ポリシーや認可ロジックを変更しないこと。
4. 共通部品の仕様変更禁止

   * AppHeader / AppFooter / StaticI18nProvider など、BoardPostForm 以外の共通部品の Props や挙動を変更しないこと。
5. ディレクトリ構成の変更禁止

   * 既存のディレクトリ構成・ファイル名を変更しないこと（新規ファイルの追加は最小限に留める）。

---

## 7. CodeAgent_Report 要求事項

Windsurf 実行後、以下の形式で `CodeAgent_Report` を `/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_ReplyMode_v1.0.md` に出力すること。

* `[CodeAgent_Report]` ブロックの必須項目

  * `task_id`: `WS-B03_BoardPostForm_ReplyMode_v1.0`
  * `agent_name`: Windsurf 実行エージェント名
  * `attempt`: 実行試行回数
  * `self_score`: 10 点満点での自己評価スコア（9 以上を目標）
  * `files_touched`: 変更したファイルパス一覧
  * `tests`: 実施したテスト内容と結果（手動・自動問わず）

以上。
