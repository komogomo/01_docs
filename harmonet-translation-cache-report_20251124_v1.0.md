# HarmoNet B04 翻訳キャッシュ・UI 改善 作業レポート

日付: 2025-11-24
担当: Windsurf AI（Cascade）

---

## 1. 対象範囲 (Scope)

本レポートは、掲示板機能 B04 の以下の要素についての実装・調整内容をまとめたものです。

- 掲示板投稿 (`board_posts`) の **翻訳キャッシュ**（Google Translate API）
- 翻訳キャッシュを利用した **BoardTop / Home の表示ロジック**
- Supabase RLS / service_role / スキーマ調整
- 投稿画面・ナビゲーション・i18n 周りの UX 改善

※ 掲示板詳細画面・再翻訳ボタン等は **今後のタスク** とし、本レポートでは扱いません。

---

## 2. サーバーサイド実装

### 2.1 GoogleTranslationService

**ファイル:** `src/server/services/translation/GoogleTranslationService.ts`

- `SupportedLang` 型: `'ja' | 'en' | 'zh'`
- 既存の `translateOnce` に加え、以下を追加:

```ts
async detectLanguageOnce(text: string): Promise<SupportedLang | null>;
```

- Google Cloud Translation API の `detectLanguage` を呼び出し、
  - `ja` / `en` / `zh` のいずれかであればそのコードを返す
  - それ以外またはエラー時は `null` を返す（フェイルソフト）
- ログ出力:
  - 成功: `board.translation.detect.success`
  - 非対応言語: `board.translation.detect.unsupported`
  - 失敗: `board.translation.detect.error`

### 2.2 BoardPostTranslationService

**ファイル:** `src/server/services/translation/BoardPostTranslationService.ts`

- `translateAndCacheForPost` を **タイトル＋本文の両方を翻訳キャッシュ** するように拡張:

  - 入力:
    - `tenantId`, `postId`, `sourceLang`, `targetLangs[]`, `originalTitle?`, `originalBody`
  - 処理:
    - `targetLangs` ごとに Google Translate API でタイトル・本文を翻訳
    - Supabase の `board_post_translations` に `upsert(post_id, lang)` で保存
    - 既存レコードがあれば上書き（id は DB 側で自動採番）
  - ログ:
    - Supabase upsert エラー: `board.translation.cache_error.post`
    - 例外発生時: `board.translation.cache_exception.post`
  - フェイルソフト: 1言語の失敗は握りつぶし、他言語の処理を継続

### 2.3 /api/board/posts (GET/POST)

**ファイル:** `app/api/board/posts/route.ts`

#### POST: 掲示板投稿作成 & 翻訳キャッシュ

- リクエストボディ（主要項目）:
  - `tenantId`, `authorId`, `categoryKey`, `title`, `content`
  - `forceMasked?`（AIモデレーション再送信用）
  - `uiLanguage?: SupportedLang`（クライアント側 UI 言語）
- 認証・権限チェック:
  - Supabase Auth で `user.email` を取得
  - `users` テーブルで `authorId` + `email` の整合性を確認
  - `user_tenants` で `tenantId` 所属を確認
  - `board_categories` で `categoryKey` の妥当性を検証
- AI モデレーション（OpenAI）:
  - `TenantModerationConfig` を `tenant_settings.config_json.board.moderation` から解釈
  - `decision` が `block` の場合は投稿拒否
  - `decision` が `mask` で `forceMasked = false` の場合はマスク済みテキストを返して再確認
- 投稿 INSERT:
  - Prisma の `board_posts.create` で `status = 'published'` で作成
  - `postId` を返却
- 翻訳キャッシュ:
  - `GoogleTranslationService.detectLanguageOnce` で `sourceLang` を推定し、
    - 失敗時は `uiLanguage`（`en`/`zh`/`ja`）を採用
  - `['ja','en','zh']` から `sourceLang` を除いた 2 言語を `targetLangs` として、
    `BoardPostTranslationService.translateAndCacheForPost` に委譲
  - **翻訳キャッシュ書き込みには service_role クライアントを使用**（後述）
  - エラー時は `board.post.api.translation_error` にログのみ出し、投稿自体は成功とする

#### GET: 掲示板一覧取得（BoardTop / Home 共通ソース）

- パラメータ: `tenantId` (クエリ)
- 認証・権限:
  - Supabase Auth で `user.email`
  - `users` → `user_tenants` で当該テナントへの所属を確認
- 取得データ:

```ts
BoardPostSummaryDto = {
  id: string;
  categoryKey: string;
  categoryName: string | null;
  originalTitle: string;
  originalContent: string;
  authorDisplayName: string;
  authorDisplayType: 'management' | 'user'; // 現状すべて 'user'
  createdAt: string; // ISO 文字列
  hasAttachment: boolean;
  translations: { lang: 'ja' | 'en' | 'zh'; title: string | null; content: string }[];
}
```

- 実装:
  - Prisma で `board_posts` を `category`, `translations`, `attachments`, `author` と一括取得
  - `created_at` 降順、最大 50 件
  - `translations` は `board_post_translations` テーブル由来

### 2.4 Supabase service_role クライアント

**ファイル:** `src/lib/supabaseServiceRoleClient.ts`

- `SUPABASE_SERVICE_ROLE_KEY` を使用するサーバー専用クライアント:

```ts
export function createSupabaseServiceRoleClient(): SupabaseClient;
```

- 用途:
  - /api/board/posts の翻訳キャッシュ部分のみ、このクライアントで `board_post_translations` に upsert
  - RLS ポリシー `insert_board_post_translations_service` / `update_board_post_translations_service` を利用
- セッション永続化は無効 (`persistSession: false`)

### 2.5 単一投稿取得（詳細画面用）

**ファイル:** `src/server/board/getBoardPostById.ts`

- `getBoardPostById({ tenantId, postId, currentUserId })` を実装（現時点では主に将来の詳細画面用）。
- `board_posts` + `category` + `translations` + `attachments` + `author.display_name` をまとめて取得。
- DTO 形式は BoardTop とほぼ同じ。

---

## 3. DB / RLS / スキーマ調整

### 3.1 board_post_translations / board_comment_translations の RLS

**ポリシー一覧（抜粋）:** `harmonet-RLS-policy_20251124_v1.0.md`

- 既存:
  - `insert_board_post_translations_service` (roles: `{service_role}`, cmd: INSERT)
  - `update_board_post_translations_service` (roles: `{service_role}`, cmd: UPDATE)
  - SELECT は `authenticated` に `tenant_id` ベースで許可
- 今回の方針:
  - 翻訳キャッシュは **service_role クライアント** 経由に統一
  - そのため、authenticated 用の INSERT/UPDATE ポリシーは **必須ではない**（あってもよいが、最終的には service_role のみ利用）

### 3.2 board_post_translations.id の自動採番

- Prisma モデルでは `@default(uuid())` 指定済みだったが、実 DB 上で `id` に DEFAULT がなく、
  upsert 時に `null value in column "id" ...` エラーが発生。
- 対応 SQL（Supabase Studio にて実行）:

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE public.board_post_translations
ALTER COLUMN id SET DEFAULT gen_random_uuid();
```

### 3.3 board_post_translations.updated_at の DEFAULT

- 同様に、`updated_at` が NOT NULL だが DEFAULT がなく、INSERT 時に
  `null value in column "updated_at" ...` エラーが発生。
- 対応 SQL:

```sql
ALTER TABLE public.board_post_translations
ALTER COLUMN updated_at SET DEFAULT now();

-- 必要に応じてコメント翻訳も
ALTER TABLE public.board_comment_translations
ALTER COLUMN updated_at SET DEFAULT now();
```

### 3.4 users の重複レコード整理

- `public.users` において、同一 `email` （例: `admin@gmail.com`, `user01@gmail.com`）で複数行が存在していた。
- これにより `supabase.from('users').select('id').eq('email', ...)` が **どちらか一方を返す不安定な状態** となり、
  `/home` で `auth.callback.unauthorized.no_tenant` が発生（user_tenants に紐づいていない方が拾われる）。
- 手動対応（ユーザー側で実施）:
  - `user_tenants` / `user_roles` から参照されていない users レコード（迷子ユーザー）を削除
  - 正しい方のみ残すことで `/home` のテナント解決が安定
- 再発防止案（提案）:

```sql
ALTER TABLE public.users
ADD CONSTRAINT IF NOT EXISTS users_email_key UNIQUE (email);
```

---

## 4. フロントエンド: 掲示板 (Board)

### 4.1 BoardTopPage

**ファイル:** `src/components/board/BoardTop/BoardTopPage.tsx`

- Server コンポーネント `app/board/page.tsx` から `tenantId` を受け取る Client コンポーネント。
- 起動時に `/api/board/posts?tenantId=...` を fetch し、`BoardPostSummaryDto[]` を取得。
- 表示ロジック:
  - `useStaticI18n().currentLocale` を用いて、各投稿に対して
    - `translations.find(tr => tr.lang === currentLocale)` を探す
    - あれば `translated.title ?? originalTitle` / `translated.content ?? originalContent`
    - なければ `originalTitle` / `originalContent`
  - カテゴリタブ（All / Important / Circular / ...）によるフィルタ
  - カード表示には `BoardPostSummaryCard` を使用（カテゴリバッジ・日時・タイトル・冒頭テキスト・添付有無）
- 翻訳ボタンは **BoardTop には存在しない**（仕様どおり）。

### 4.2 BoardNewPage & BoardPostForm

**ファイル:** `app/board/new/page.tsx`, `src/components/board/BoardPostForm/BoardPostForm.tsx`

- `BoardNewPage`（Server）:
  - `/home` と同じパターンで Supabase Auth → `users` → `user_tenants` → `user_roles` を解決
  - 掲示板カテゴリを `board_categories` から取得し、テナントに紐づくもののみフィルタ
  - 取得結果を `BoardPostForm` に props として渡す
- `BoardPostForm`（Client）:
  - 投稿者区分 (`posterType`): `management` / `general`
    - 管理者 (`viewerRole === 'admin'`) かつ `posterType === 'management'` の場合のみ
      管理組合向けカテゴリ（important, circular, event, rules）を選択可能
  - フォーム送信時:
    - `uiLanguage: currentLocale` を `/api/board/posts` に渡す
    - エラー時:
      - レスポンスの `errorCode` に応じて i18n エラーメッセージキーを決定し、フォーム上に表示
      - 画面遷移はせず、投稿画面に留まる
    - 成功時:
      - 以前は `/board/{postId}` に遷移して 404 となっていたが、
        **現在は `/board`（掲示板TOP）に戻す** よう修正済み
- `/board/new` にも `HomeFooterShortcuts` を追加し、
  - エラー時もフッターから `/home` / `/board` 等に戻れるように UX を改善。

---

## 5. フロントエンド: Home

### 5.1 HomePage のデータソース切り替え

**ファイル:** `app/home/page.tsx`

- 以前は `MOCK_HOME_NOTICE_ITEMS` を使ったダミー表示だったが、
  **`board_posts`（+ `board_post_translations`）ベースに置き換え**。
- 処理の流れ:
  1. Supabase Auth → `users` → `user_tenants` で `tenantId` を解決
  2. `tenant_settings.config_json` を取得し、`config.home.notice.maxCount` を解釈
     - 指定が無ければ `DEFAULT_HOME_NOTICE_COUNT = 2`
     - `clampNoticeCount` で 1〜3 の範囲に丸め
  3. `HomeBoardNoticeContainer` に `tenantId` と `maxItems` を渡してレンダリング

### 5.2 HomeBoardNoticeContainer

**ファイル:** `src/components/home/HomeNoticeSection/HomeBoardNoticeContainer.tsx`

- Client コンポーネント。`tenantId` ベースで `/api/board/posts` を fetch。
- 取得した投稿から **Home 用のお知らせアイテム** を生成:

  - 対象投稿の条件:
    - カテゴリキーが `important` / `circular` / `event` / `rules` のいずれか
      - = 管理組合として投稿する想定のカテゴリ（BoardPostForm と整合）
    - `createdAt` が **現在から 60 日以内**
  - 並び順:
    - `createdAt` 降順（新しい投稿が上）
  - 言語:
    - `currentLocale`（`ja` / `en` / `zh`）を取得
    - `translations.find(tr => tr.lang === currentLocale)` を探し、
      - あれば: `title = tr.title || originalTitle`, `content = tr.content || originalContent`
      - なければ: `title = originalTitle`, `content = originalContent`
    - → **翻訳キャッシュが無い場合は元言語（通常は日本語）を表示**
  - 日付表示:
    - ロケール: `ja-JP` / `en-US` / `zh-CN`
    - フォーマット: `YYYY/MM/DD HH:MM`

- 変換後の型:

```ts
HomeNoticeItem = {
  id: string;
  title: string;      // 翻訳 or オリジナルのタイトル
  content?: string;   // 翻訳 or オリジナルの本文 (2行まで表示)
  publishedAt: string;
};
```

- `HomeNoticeSection` に `items` と `maxItems` を渡して描画。

### 5.3 HomeNoticeSection 表示仕様

**ファイル:** `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`

- 件数制御:
  - `clampNoticeCount(maxItems ?? DEFAULT_HOME_NOTICE_COUNT)` で 1〜3 件に制限
  - デフォルトは **2 件**・最大 **3 件**（テナント設定で変更可能）
- カード UI:
  - タイトル: `line-clamp-2`（2行まで）
  - 本文: `item.content` があれば `line-clamp-2`（2行まで）で表示
  - 上部にバッジ（i18n: `home.noticeSection.badge`）と日時
- アイテムが 0 件の場合:
  - タイトルのみ表示 (`home.noticeSection.title`)
  - `home.noticeSection.emptyMessage` を表示

---

## 6. i18n 修正

### 6.1 attachmentAllowed キー不足

- `BoardPostForm` で参照していた `t("board.postForm.note.attachmentAllowed")` が、
  実際の JSON 構造では `board.postForm.note.attachment.attachmentAllowed` となっており、
  コンソールに `[i18n] Missing key: board.postForm.note.attachmentAllowed` が大量発生。

- 対応:
  - `BoardPostForm` 側のキーを `"board.postForm.note.attachment.attachmentAllowed"` に修正。
  - 併せて、`public/locales/ja|en|zh/common.json` に該当キーを追加。

---

## 7. 動作確認サマリ

### 7.1 翻訳キャッシュ

- 日本語で投稿 → ログ:
  - `board.translation.detect.success (detectedLang: ja)`
  - `board.translation.success (sourceLang: ja, targetLang: en/zh)` 複数回
  - RLS / service_role / DEFAULT 設定後は `board.translation.cache_error.post` は発生しない
- Supabase Studio:
  - `board_post_translations` に `post_id = 新規投稿ID`, `lang = 'en' / 'zh'` の行が作成されていることを確認

### 7.2 BoardTop

- `/board` で JA/EN/ZH を切り替えると、タイトル・本文が言語に応じて変化
- 翻訳キャッシュが無い投稿は、いずれの言語でも日本語オリジナルが表示される

### 7.3 Home

- Home 上部の「最新のお知らせ」に、
  - 管理組合として投稿された掲示板記事が
  - 新しい順で 2 件（設定によっては 1〜3 件）
  - タイトル＋本文2行まで
  表示されることを確認
- 言語切り替え時:
  - BoardTop と同じ翻訳タイトル・本文が表示される
  - 翻訳キャッシュが無い場合は元言語（日本語）が表示される

### 7.4 UX / ナビゲーション

- `/board/new` でエラーが発生した場合:
  - 画面は投稿フォームのまま
  - エラーメッセージのみ表示（404 にならない）
- 投稿成功時:
  - `/board/{postId}` ではなく `/board` にリダイレクト
- `/board/new` にフッターを追加したことで、常に Home/Board などへ戻れる

---

## 8. 今後の課題・フォローアップ候補

1. **掲示板詳細画面**
   - `/board/{postId}` の実装
   - ここにのみ「翻訳ボタン」「再翻訳リクエスト」等を配置（仕様予定）

2. **テナント管理画面からの Home 表示件数設定 UI**
   - `tenant_settings.config_json.home.notice.maxCount` を編集する管理画面
   - バリデーション: 1〜3 の整数値に制限

3. **board_post_translations / board_comment_translations の運用監視**
   - エラー系ログ (`board.translation.cache_error.*`, `board.translation.cache_exception.*`) の監視
   - 翻訳 API 呼び出し回数・レイテンシの集計

4. **データ整合性の確認**
   - `users.email` の UNIQUE 制約が DB に確実に反映されているか再確認
   - 将来的なユーザーマイグレーション時に、`auth.users` と `public.users` の ID/メール対応が崩れないよう運用ルールを整理

以上が、2025-11-24 時点での B04 翻訳キャッシュおよび関連 UI の実装状況レポートです。
