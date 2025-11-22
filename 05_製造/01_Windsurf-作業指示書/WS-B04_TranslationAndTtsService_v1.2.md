# WS-B04 TranslationAndTtsService 実装指示書 v1.2

**Task ID:** WS-B04
**Component:** B-04 BoardTranslationAndTtsService（掲示板専用 翻訳＋TTS サービス）
**Target Repo:** `D:\Projects\HarmoNet`
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** 差分実装タスク / Patch
**CodeAgent_Report 保存先:** `/01_docs/06_品質チェック/CodeAgent_Report_WS-B04_TranslationAndTtsService_v1.2.md`

---

## 1. ゴール

既に実装済みの B-04 Translation & TTS サービスについて、以下の項目を設計書に完全準拠させること。

1. 翻訳失敗時も「投稿・返信自体は成功」とするフェイルソフト実装（例外が Route Handler を突き抜けない）
2. 複数言語翻訳を `Promise.all` 等で並列実行する構造
3. 編集時（PATCH）の「タイトル／本文に変更がある場合のみ翻訳を実行する」最適化
4. 投稿用 `board_post_translations` と返信用 `board_comment_translations` の両方を前提にした翻訳フロー
5. `board_post_translations` / `board_comment_translations` の削除一貫性：`board_posts` / `board_comments` 削除時に Cascade で消える前提に合わせたコード整理

新しい API エンドポイントの追加は行わず、既存の Route / サービス実装を差分修正する。

---

## 2. スコープ

### 2.1 対象

* Next.js Route Handler（App Router）:

  * `app/api/board/posts/route.ts`

    * 新規投稿（POST）と編集（PATCH）が同一ファイルであればその両方
  * `app/api/board/posts/[postId]/comments/route.ts` など、返信投稿用 Route（存在する名称に合わせる）
  * `app/api/board/posts/[postId]/translate/route.ts`（投稿オンデマンド翻訳）
  * `app/api/board/comments/[commentId]/translate/route.ts`（返信オンデマンド翻訳、存在する場合）
  * `app/api/board/posts/[postId]/tts/route.ts`（投稿 TTS）
  * `app/api/board/comments/[commentId]/tts/route.ts`（返信 TTS、存在する場合）

* サービス層:

  * `src/server/board/BoardPostTranslationService.ts`（名称は実ファイルに合わせる）
  * `src/server/board/BoardPostTtsService.ts`（TTS 用サービス）

* Prisma モデル:

  * `prisma/schema.prisma` 内 `board_post_translations` / `board_comment_translations` / `board_posts` / `board_comments` リレーション

* テストコード:

  * B-04 関連のユニットテスト／統合テスト（存在する分だけでよい）

### 2.2 非対象

* B-02 BoardDetail / B-03 BoardPostForm の UI 実装（呼び出し元）はスコープ外
* Supabase Edge Function（翻訳キャッシュ削除バッチ）の新規実装は本タスクでは行わない
* 新しい API エンドポイント定義は行わない（既存 Route 内の処理だけを調整）

---

## 3. 参照設計書

以下を **唯一の正** として参照し、齟齬があれば設計書側を優先すること。

* `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch02-api-and-auth_v1.*.md`
* `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch03-cache-and-schema_v1.*.md`
* `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch04-flows_v1.*.md`
* `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch06-nonfunctional_v1.*.md`

特に本タスクでは ch04 4.2〜4.6 / ch06 6.2〜6.4 の内容を厳密に反映すること。

---

## 4. 実装要件（差分内容）

### 4.1 フェイルソフト実装（例外を突き抜けさせない）

#### 4.1.1 新規投稿 `/api/board/posts`（POST）

* フロー:

  1. `board_posts` への INSERT が成功した時点で `postId` を確定する。
  2. 翻訳呼び出し:

```ts
try {
  await boardPostTranslationService.translateAndCacheForPost({
    tenantId,
    postId,
    sourceLang,
    targetLangs,
    originalTitle,
    originalBody,
  });
} catch (error) {
  // Logger に WARN/ERROR を記録し、投稿 API のレスポンスは成功とする
}
```

* 例外が Route Handler まで伝播して HTTP 500 になる実装を残さないこと。

#### 4.1.2 返信投稿 Route（POST）

* 返信投稿用 Route でも同様に、`board_comments` への INSERT 後に

```ts
try {
  await boardPostTranslationService.translateAndCacheForComment({
    tenantId,
    commentId,
    sourceLang,
    targetLangs,
    originalBody,
  });
} catch (error) {
  // Logger に記録のみ。返信投稿 API は成功として返す。
}
```

とし、翻訳失敗で 500 を返さないこと。

#### 4.1.3 TTS Route

* `/tts` 系 Route では、TTS 失敗時に `try/catch` で例外を捕捉し、

  * Logger にエラーを出力
  * 呼び出し元仕様に合わせて適切なステータス（例: 500 + 汎用メッセージ）を返す
* 掲示板本体の閲覧 API（/board/[postId] 等）には影響を与えないこと。

---

### 4.2 翻訳の並列実行（Promise.all 前提）

#### 4.2.1 投稿・返信共通

* `translateAndCacheForPost` / `translateAndCacheForComment` 内で複数言語（例: `['en', 'zh']`）を翻訳する場合、以下のように並列化する。

```ts
const tasks = targetLangs.map((lang) =>
  translateAndInsertSingleLanguage({
    tenantId,
    postId, // 返信の場合は commentId など、呼び出し側で渡す
    sourceLang,
    targetLang: lang,
    originalTitle,
    originalBody,
  })
);

await Promise.all(tasks);
```

* 直列 `await` になっている箇所（`await translateJaToEn(); await translateJaToZh();` のような構造）があれば、上記のように修正する。
* 外部 API 呼び出しに対するアプリケーション側タイムアウト（3 秒程度）の実装があればそのパターンに合わせ、なければ最小限のタイムアウト処理を追加してもよい。

---

### 4.3 編集時の「変更有りの場合のみ翻訳」

#### 4.3.1 投稿編集 API

* `PATCH /api/board/posts/{postId}` などの編集 Route が存在する場合、以下のロジックにする。

```ts
const current = await prisma.board_posts.findUnique({ where: { id: postId } });

const hasBodyChanged = current?.content !== newBody;
const hasTitleChanged = current?.title !== newTitle;

if (hasBodyChanged || hasTitleChanged) {
  try {
    await boardPostTranslationService.translateAndCacheForPost({
      tenantId,
      postId,
      sourceLang,
      targetLangs,
      originalTitle: newTitle,
      originalBody: newBody,
    });
  } catch (error) {
    // ログのみ。PATCH 自体は成功扱い。
  }
}
```

* タイトル/本文ともに変更がない場合、翻訳サービスを呼び出さない。

#### 4.3.2 返信編集 API

* 返信に対する編集 API が存在する場合も、同様に `board_comments` から現行値を取得し、

  * 本文が変わっている場合のみ `translateAndCacheForComment` を呼び出す。
  * 本文が変わらない編集（公開範囲変更等）では翻訳を呼び出さない。

---

### 4.4 Prisma リレーションと Cascade

* `prisma/schema.prisma` で、翻訳キャッシュモデルが以下のようになっていることを確認する。

```prisma
model board_post_translations {
  // ...
  post board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)
}

model board_comment_translations {
  // ...
  comment board_comments @relation(fields: [comment_id], references: [id], onDelete: Cascade)
}
```

* アプリケーションコード側に「投稿削除時に translations を手動で DELETE する処理」がある場合、

  * DB の Cascade と二重になっていないか確認し、不要であれば削除する。

---

## 5. テスト方針

### 5.1 テスト対象

* `/api/board/posts`（POST/必要なら PATCH）
* `/api/board/posts/{postId}/comments`（返信投稿）
* 翻訳サービス呼び出し部
* Prisma リレーション（Integration テストとして確認できれば十分）

### 5.2 必須テストケース（概要）

1. **翻訳失敗時も投稿が成功すること**

   * 条件: 翻訳サービスをモックして例外を投げる。
   * 期待: HTTP 200/201 が返り、`board_posts` に投稿が作成される。

2. **翻訳失敗時も返信が成功すること**

   * 条件: 返信投稿 Route から翻訳サービスをモックして例外を投げる。
   * 期待: HTTP 200/201 が返り、`board_comments` に返信が作成される。

3. **複数言語翻訳が並列で呼び出されていること**

   * 条件: 翻訳モックの呼び出しを記録し、直列 `await` に依存しない構造であることを確認する。

4. **編集時の変更有無判定**

   * 条件1: タイトル／本文に変更がある PATCH

     * 期待: 翻訳サービスが呼ばれる。
   * 条件2: タイトル／本文に変更がない（カテゴリのみ変更）

     * 期待: 翻訳サービスが呼ばれない。

5. **Cascade 削除**（Integration レベル）

   * 条件: ある `postId` または `commentId` のレコードを削除する。
   * 期待: 対応する `board_post_translations` / `board_comment_translations` 行がすべて削除される。

既存テストがある場合は必要なケースを追加、なければ最小限のテストを新規追加する。

---

## 6. 受け入れ基準

* [ ] すべての Route Handler で、翻訳/TTS 例外が直接 HTTP 500 を生成しないこと（翻訳失敗でも投稿/返信/閲覧は継続可能）。
* [ ] 翻訳処理が `Promise.all` などで並列実行されていること。
* [ ] 編集 API で、本文に変更がない場合に翻訳サービスが呼ばれていないこと。
* [ ] Prisma スキーマが `onDelete: Cascade` で `board_posts` / `board_comments` と接続され、不要な手動削除コードが残っていないこと。
* [ ] 追加・変更したテストがすべて成功していること。
* [ ] Type エラー / lint エラー / build エラーなし。

---

## 7. 禁止事項 / 注意事項

* スキーマの新規テーブル追加やカラム追加は行わない（`board_post_translations` / `board_comment_translations` の既存設計の範囲に限定する）。
* 新しい API エンドポイントの追加は禁止。本タスクは既存 Route の振る舞い修正のみとする。
* ログ出力の形式や共通 Logger API を変更しない（呼び出し追加のみ許可）。
* B-02 / B-03 の UI 実装は変更しない。

---

## 8. CodeAgent_Report 要求

タスク完了時、以下の情報を含む `CodeAgent_Report_WS-B04_TranslationAndTtsService_v1.2.md` を `/01_docs/06_品質チェック/` に作成すること。

* 実施した差分一覧（ファイル単位・関数単位）
* 追加・修正したテストケースの一覧と結果
* 自己評価スコア（型安全性・設計準拠度・テスト網羅感など、10 点満点）
* 残課題があれば TODO リストとして明示
