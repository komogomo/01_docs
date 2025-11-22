# CodeAgent_Report_WS-B04_TranslationAndTtsService_v1.2

- **Task ID**: WS-B04
- **Component**: B-04 BoardTranslationAndTtsService（掲示板専用 翻訳＋TTS サービス）
- **Target Repo**: `D:/Projects/HarmoNet`
- **Spec**: `WS-B04_TranslationAndTtsService 実装指示書 v1.2`

---

## 1. 実装済み差分一覧

### 1.1 翻訳サービス層（投稿）

**ファイル**: `src/server/services/translation/GoogleTranslationService.ts`

- 既存実装のまま、以下を満たす構造を維持。
  - `SupportedLang = 'ja' | 'en' | 'zh'`
  - `TranslationService.translateOnce(params)` による 1 回翻訳 API 呼び出し。
  - 認証: `GCP_TRANSLATE_CREDENTIALS_JSON` 優先 / フォールバックで `GOOGLE_APPLICATION_CREDENTIALS`。
  - ログ: `logInfo('board.translation.success', ...)` / `logError('board.translation.error', ...)`。
- **v1.2 対応として追加した点**:
  - Google Cloud Translation v3 呼び出しに 3 秒タイムアウトを付与。

    ```ts
    const [response] = await this.client.translateText(request as any, { timeout: 3000 } as any);
    ```

---

**ファイル**: `src/server/services/translation/BoardPostTranslationService.ts`

- 既存の `hasCachedTranslation`（投稿向けキャッシュ確認）はそのまま利用。
- **v1.2 対応として実装した点**:

1. **投稿向け翻訳の Promise.all 並列化＋フェイルソフト**

   - メソッド: `translateAndCacheForPost(params)`
   - 変更前: `for...of` による直列 `await`。
   - 変更後: `targetLangs.filter(lang !== sourceLang)` を **Promise.all** で並列実行。
   - 各言語ごとに `try/catch` を設け、単一言語の失敗は握りつぶして他言語処理を継続。

   振る舞い:
   - 1 言語で翻訳/API/upsert が失敗しても、**メソッド全体は例外を投げない**。
   - 呼び出し側 Route で `try/catch` すれば、「投稿自体は成功」フェイルソフトを実現可能。

2. **返信用翻訳キャッシュ API の追加**

   - メソッド: `hasCachedCommentTranslation({ tenantId, commentId, lang })`
     - テーブル: `board_comment_translations`
     - 条件: `tenant_id`, `comment_id`, `lang` で `select('id').limit(1)` → 存在確認。
     - エラー発生時は `false` 返却（キャッシュ無し扱い）。

3. **返信用翻訳の Promise.all 並列化＋フェイルソフト**

   - メソッド: `translateAndCacheForComment({ tenantId, commentId, sourceLang, targetLangs, originalBody })`
   - 投稿用と同様に、`Promise.all` でターゲット言語を並列実行。
   - 各言語ごとに `try/catch` 内で翻訳＋`board_comment_translations` への upsert。
   - `onConflict: 'comment_id,lang'` を使用し、**言語ごとに 1 レコードを upsert**。
   - 1 言語の失敗は握りつぶし、他言語は継続（フェイルソフト）。


### 1.2 TTS サービス層

**ファイル**: `src/server/services/tts/GoogleTtsService.ts`

- 既存の `TtsService.synthesize(params)` インターフェース・ロギングは維持。
- **v1.2 対応として追加した点**:
  - Google Cloud Text-to-Speech 呼び出しに 3 秒タイムアウトを付与。

    ```ts
    const [response] = await this.client.synthesizeSpeech(request as any, { timeout: 3000 } as any);
    ```

- 失敗時は既存どおり `logError('board.tts.error', ...)` を出した上で例外再スローするため、
  Route 側で `try/catch` すればフェイルソフトにできます（Route は未実装のため TODO 扱い）。

**ファイル**: `src/server/services/tts/BoardPostTtsService.ts`

- `synthesizePostBody` は v1.0 時点の薄いラッパー実装のまま。
- TTS のフェイルソフトは Route 側で `try/catch` する前提のため、サービス層に追加ロジックは不要と判断。


### 1.3 Prisma スキーマ（翻訳テーブルと Cascade）

**ファイル**: `prisma/schema.prisma`

- B-04 関連のモデルを、v1.2 の要件に合わせて整理済です。

1. **投稿翻訳: `board_post_translations`**

   ```prisma
   model board_post_translations {
     id        String  @id @default(uuid())
     tenant_id String
     post_id   String
     lang      String
     title     String?
     content   String  @db.Text

     created_at DateTime @default(now())
     updated_at DateTime @updatedAt

     tenant tenants     @relation(fields: [tenant_id], references: [id])
     post   board_posts @relation(fields: [post_id], references: [id], onDelete: Cascade)

     @@unique([post_id, lang])
     @@index([tenant_id, lang, created_at])
   }
   ```

   - 要件どおり `onDelete: Cascade` を指定し、`board_posts` 削除時に翻訳が自動削除されるようにしました。

2. **返信翻訳: `board_comment_translations`**

   ```prisma
   model board_comment_translations {
     id         String @id @default(uuid())
     tenant_id  String
     comment_id String
     lang       String
     content    String @db.Text

     created_at DateTime @default(now())
     updated_at DateTime @updatedAt

     tenant  tenants        @relation(fields: [tenant_id], references: [id])
     comment board_comments @relation(fields: [comment_id], references: [id], onDelete: Cascade)

     @@unique([comment_id, lang])
     @@index([tenant_id, lang, created_at])
   }
   ```

   - `board_comments` 削除時に関連翻訳が Cascade で削除される設計に揃えています。

3. **関連モデル**

   - `tenants` に `board_post_translations[]` / `board_comment_translations[]` リレーション追加済み。
   - `board_comments` に `boardCommentTranslations board_comment_translations[]` を追加済み。

---

## 2. テスト・ビルド状況

### 2.1 Lint / Build

- `npm run lint`
  - 新規追加/変更した B-04 関連ファイルには ESLint エラーなし。
  - 既存コンポーネント `HomeFooterShortcuts.tsx` に `react/jsx-key` エラー 2 件が残存
    （本 WS-B04 のスコープ外のため、そのまま）。

- `npm run build`
  - Next.js 16 (Turbopack) によるビルドは成功。
  - TypeScript チェックも完走済み。

### 2.2 自動テスト

- 本 WS-B04 では、B-04 サービス専用の Jest/Vitest テストは **新規追加していません**。
- 代わりに、型エラー・lint・build ベースでの検証に留めています。
  - 設計書 v1.2 5.2 の詳細テストケースは、board API 実装タスク時に
    Route 単位の統合テストとして追加することを推奨します。

---

## 3. 未対応（TODO）項目

### 3.1 Route レイヤのフェイルソフト・PATCH 最適化・TTS Route

現時点の `D:/Projects/HarmoNet` リポジトリには、以下の board 関連 Route が **まだ存在しません**。

- `/api/board/posts`（POST / PATCH）
- `/api/board/posts/[postId]/comments`（返信投稿）
- `/api/board/posts/[postId]/translate`
- `/api/board/comments/[commentId]/translate`
- `/api/board/posts/[postId]/tts`
- `/api/board/comments/[commentId]/tts`

設計書 v1.2 の 4.1〜4.3 は、上記 Route が既に存在している前提で
「既存 Route に対して差分パッチを当てる」内容になっていますが、
**新しい API エンドポイント定義は行わない**という禁止事項に従い、
本 WS-B04 では Route の新規作成は行っていません。

そのため、以下は **未着手の TODO** として残します。

- **TODO-1**: board API Route 実装タスク着手時に、WS-B04 v1.2 4.1〜4.3 の要件を Route 側に適用すること。
  - 新規投稿 Route で、`boardPostTranslationService.translateAndCacheForPost` を `try/catch` し、
    失敗しても投稿 API の HTTP 200/201 を維持する（フェイルソフト）。
  - 返信投稿 Route で、`translateAndCacheForComment` を同様に `try/catch` し、
    返信作成自体は成功扱いとする。
  - `/tts` 系 Route で、TTS 失敗を `try/catch` で吸収し、
    エラーをロギングしたうえで 500 など適切な HTTP ステータスを返す。

- **TODO-2**: 投稿/返信編集 API における変更有無判定ロジックの実装。
  - `board_posts` / `board_comments` から現行値を取得し、
    - 投稿: `title` / `content`
    - 返信: `content`
  - 値が変わっている場合にのみ `translateAndCacheForPost` / `translateAndCacheForComment` を呼び出す。
  - 変更がない場合は翻訳サービスを呼ばない。

これらの TODO は、**将来の board API 実装タスク（WS-B02/WS-B03）で拾う前提**とします。

---

## 4. 将来タスクへの引き継ぎメモ

### 4.1 想定タスク ID 候補

- **WS-B02**（仮）: BoardDetail API / 閲覧系 Route 実装
  - 関連: B-04 設計書 ch04 4.2〜4.4 / ch06 6.2〜6.4
  - 拾うべき要件例:
    - 翻訳済みテキスト／TTS キャッシュの利用ポリシー
    - 翻訳/TTS 失敗時のフェイルソフト（閲覧 API は継続可能であること）

- **WS-B03**（仮）: BoardPostForm バックエンド（投稿・編集・返信 API）
  - 関連: B-04 設計書 ch04 4.3〜4.6 / ch06 6.2〜6.4
  - 拾うべき要件例:
    - 新規投稿・編集・返信時の翻訳呼び出しポイント
    - 変更有無判定（タイトル/本文のみ）による翻訳実行の最適化
    - 翻訳失敗時のフェイルソフト（投稿/返信 API は成功として返却）
    - TTS Route のエラー時挙動（ログ出力と HTTP ステータス）

### 4.2 参照すべき設計書

- `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch02-api-and-auth_v1.*.md`
- `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch03-cache-and-schema_v1.*.md`
- `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch04-flows_v1.*.md`
- `/01_docs/04_詳細設計/03_掲示板/B-04_BoardTranslationAndTtsService-detail-design-ch06-nonfunctional_v1.*.md`

board API 実装タスクでは、上記 ch04/ch06 の該当節と本レポートの TODO をセットで参照することで、
B-04 全体のフローと非機能要件（タイムアウト、フェイルソフト、ログ方針）を反映しやすくなります。

---

## 5. 自己評価（10 点満点）

- **型安全性**: **9/10**
  - サービス層は `SupportedLang`・明示的なパラメータ型・戻り値型を定義し、any の利用は Google TTS クライアント型周辺に限定。
  - Supabase 呼び出しは string ベースだが、型破綻を起こすような any キャストは行っていない。

- **設計準拠度（B-04 v1.2）**: **8/10**
  - サービス層／Prisma の要件（並列実行、タイムアウト、Cascade、投稿/返信両方の翻訳）は反映済み。
  - Route レイヤの要件（4.1〜4.3）は、board API 未実装のため TODO として残しており、ここが未達部分。

- **テスト網羅感**: **4/10**
  - 型チェック／lint／build ベースの確認に留まり、B-04 専用の自動テストは未追加。
  - Route 実装が入る段階で、設計書 5.2 のテストケースに沿った統合テストを追加することを推奨。

---

## 6. 残課題（TODO まとめ）

1. board API Route 実装タスク（WS-B02/WS-B03 想定）で、WS-B04 v1.2 4.1〜4.3 の要件を Route 側に実装すること。
2. B-04 関連の統合テスト（投稿・返信・翻訳・TTS・Cascade）を、Route 実装と合わせて追加すること。
3. 既存の `HomeFooterShortcuts.tsx` の `react/jsx-key` エラーは本タスク外だが、将来的に lint 完全クリアを目指す場合は対応が必要です。
