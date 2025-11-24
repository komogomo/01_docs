
---

### 依頼先タスク案（WS向け）

**タスク名（例）**
`WS-B03_BoardPostForm_BackendInsertError_v1.0`

**目的**

* `/api/board/posts` に POST すると 500 (Internal Server Error) になり、
  `board.post.create_failed / errorCode: "insert.failed"` が出ている原因を特定し、修正する。

**前提/コンテキスト**

* フロント側 BoardPostForm は、設計どおりに投稿者区分・カテゴリ棲み分け・添付 UI まで実装済み。
* POST 時のリクエスト先: `app/api/board/posts/route.ts`
* 500 発生時のログ（コンソール側）:

  * `event:"board.post.submit_click"` → その後 `event:"board.post.create_failed"` / `errorCode:"insert.failed"`

**WS に見てほしいファイル**

* `app/api/board/posts/route.ts`
* `src/components/board/BoardPostForm/BoardPostForm.tsx`
* `prisma/schema.prisma`
* `prisma/seed.ts`（board_categories 定義確認用）
* 必要なら `log.util.ts`（ロガーの出力）

**やってほしいこと**

1. `route.ts` で実際に投げている `INSERT`/`UPSERT` の内容と、
   `UpsertBoardPostRequest` の validation ロジックを確認。
2. 500 の原因になっているエラー（必須カラム不足／category_key 不整合／FK制約など）を特定。
3. 既存設計書（B-03 ch03/ch04）に合わせて、

   * リクエスト DTO
   * DB への INSERT 部分
     を最低限の修正で整合させる。
4. 修正後に

   * 一般利用者投稿（カテゴリ: その他）
   * 管理組合投稿（カテゴリ: 重要/回覧板など）
     の両方が成功し、DB にレコードが入ることを確認。

**禁止事項**

* スキーマ変更（テーブル追加/削除・カラム構造変更）は行わない。
  必要な場合は TODO コメントと提案に留める。
* RLS ポリシーの追加・変更はしない。

---
