# WS-B02-01 BoardDetailPage（閲覧専用） 実装レポート v1.0

日付: 2025-11-24
担当: Windsurf AI（Cascade）
対象タスク: WS-B02-01 BoardDetailPage（閲覧専用）

---

## 1. スコープと前提

- 対象画面: `/board/[postId]`（掲示板詳細）
- スコープ（本タスクで実装した範囲）
  - 掲示板詳細画面の **閲覧専用 UI**
  - BoardTop / Home から 1 件の投稿詳細への遷移
  - 翻訳キャッシュ（`board_post_translations`）を使用した JA/EN/ZH の本文切り替え
  - 添付ファイル一覧表示＆PDF プレビューモーダルの骨格
  - コメント一覧（閲覧のみ）
  - 共通フッター（HomeFooterShortcuts）を使ったナビゲーション
- スコープ外（未実装・後続タスク）
  - コメント投稿・削除・返信
  - 投稿削除
  - お気に入りトグル
  - 翻訳再実行ボタン（キャッシュ更新）
  - TTS（音声読み上げ）
  - RLS や DB スキーマの変更

WS-B02-01 の目的どおり、「DB 書き込みを伴わない閲覧専用 BoardDetail」を安全に完成させることを優先しました。

---

## 2. サーバーサイド実装

### 2.1 getBoardPostById（詳細取得）

**ファイル:** `src/server/board/getBoardPostById.ts`

- 役割: テナント + 投稿 ID に紐づく 1 件の掲示板投稿を、詳細 DTO 形式で返却。
- 追加・変更点:
  - 戻り値 DTO を `BoardPostDetailDto` として拡張。

```ts
export interface BoardPostDetailDto {
  id: string;
  categoryKey: string;
  categoryName: string | null;
  originalTitle: string;
  originalContent: string;
  authorDisplayName: string;
  authorDisplayType: 'management' | 'user'; // 現状 'user' 固定
  createdAt: string;                         // ISO 文字列
  hasAttachment: boolean;
  translations: BoardPostTranslationDto[];   // ja/en/zh
  attachments: BoardAttachmentDto[];         // 添付ファイル一覧
  comments: BoardCommentDto[];               // コメント一覧（閲覧のみ）
}
```

- Prisma クエリ:
  - `board_posts.findFirst` で以下を include:
    - `category`（`category_key`, `category_name`）
    - `translations`（`lang`, `title`, `content`）
    - `attachments`（`id`, `file_url`, `file_name`, `file_type`, `file_size`）
    - `comments`
      - `status = 'active'` のみ（where は Prisma の型制約の都合で `as any` キャスト）
      - `id`, `content`, `created_at`, `author.display_name`
    - `author.display_name`

- マッピングロジック:
  - 翻訳: `lang` が `ja/en/zh` のものだけフィルタして DTO に変換。
  - 添付: `BoardAttachmentDto { id, fileName, fileUrl, fileType, fileSize }` に変換。
  - コメント: `BoardCommentDto { id, content, authorDisplayName, createdAt }` に変換し、作成日時昇順で返却。

この DTO が BoardDetailPage の唯一のデータソースになっています。

### 2.2 `/board/[postId]` ルート

**ファイル:** `app/board/[postId]/page.tsx`

- Next.js 16 の App Router に対応した Server Component。
- `params` が Promise である仕様に従い、以下のように実装:

```ts
interface BoardDetailRouteProps {
  params: Promise<{ postId: string }>;
}

export default async function BoardDetailRoute(props: BoardDetailRouteProps) {
  const { params } = props;
  const { postId } = await params;  // ← Promise を unwrap

  if (!postId) {
    notFound();
  }

  const supabase = await createSupabaseServerClient();

  // Home / BoardTop / BoardNew と同様の認証・ユーザ解決
  // 1) auth.getUser で user.email を取得
  // 2) public.users から appUser.id を取得
  // 3) user_tenants から tenantId を解決
  // 4) 失敗時は /login?error=... に redirect

  const tenantId = membership.tenant_id as string;

  const post = await getBoardPostById({
    tenantId,
    postId,
    currentUserId: appUser.id,
  });

  if (!post) {
    notFound(); // 存在しない or 権限外投稿 → 404
  }

  return <BoardDetailPage data={post} />;
}
```

- これにより、Next.js 16 特有の `params is a Promise` 警告は解消済み。

### 2.3 グローバル 404 ページ

**ファイル:** `app/not-found.tsx`

- Next.js App Router の `notFound()` に対応するカスタム 404 ページを追加。
- 構成:
  - 中央に 404 メッセージ（英語 + 簡単な日本語説明）
  - 画面下部に `HomeFooterShortcuts` を表示
- 目的:
  - `/board/[postId]` で 404 になった場合でも、Home/Board などに戻る導線を確保。

---

## 3. フロントエンド: BoardDetailPage（閲覧専用）

**ファイル:** `src/components/board/BoardDetail/BoardDetailPage.tsx`

### 3.1 基本構成

- Client Component（`"use client"`）。
- レイアウト:
  - 他画面と同じく `max-w-md`・`pt-28` / `pb-28` のスマホ縦長レイアウト。
  - 下部に `HomeFooterShortcuts` を表示（ナビゲーション統一）。
- セクション構成:
  1. 投稿ヘッダー
  2. 本文カード
  3. 添付ファイルリスト + PDF プレビューモーダル
  4. コメント一覧（閲覧専用）

### 3.2 投稿ヘッダー

- 表示要素:
  - カテゴリバッジ
    - `BoardCategoryKey` に正規化し、`board.postForm.category.*` の i18n キーで表示。
  - タイトル
    - 翻訳キャッシュを利用:

```ts
const translation = data.translations.find((tr) => tr.lang === currentLocale);

const effectiveTitle =
  translation && translation.title && translation.title.trim().length > 0
    ? translation.title
    : data.originalTitle;

const effectiveContent = translation?.content ?? data.originalContent;
```

  - 投稿者表示名
    - 常に `authorDisplayName`（翻訳なし）。
  - 投稿日時
    - `formatDateTime(iso, currentLocale)` で JA/EN/ZH ごとのロケール表示。

### 3.3 本文カード

- クラス: `rounded-2xl border-2 border-gray-200 bg-white p-4`
- 中身: `effectiveContent` を `whitespace-pre-wrap` で改行保持表示。
- BoardTop / Home のカード群と同じ太さ・色の枠（`border-2` + `gray-200`）で統一。

### 3.4 添付ファイルリスト + PDF プレビュー

- `data.attachments.length > 0` のときのみセクションを表示。
- ラベル・文言は i18n キー（ja/en/zh 共通）:
  - `board.detail.section.attachments`
  - `board.detail.attachments.title`
  - `board.detail.attachments.preview`
  - `board.detail.attachments.download`
  - `board.detail.attachments.closePreview`
- リスト行:
  - クラス: `rounded-lg border-2 border-gray-200 bg-white px-3 py-2 text-xs`
  - ファイル名・サイズ（KB 表示）
  - PDF 判定:

```ts
const isPdfAttachment = (fileType: string, fileName: string): boolean => {
  const lowerType = (fileType || "").toLowerCase();
  const lowerName = (fileName || "").toLowerCase();
  if (lowerType.includes("pdf")) return true;
  return lowerName.endsWith(".pdf");
};
```

- PDF の場合のみ「プレビュー」ボタンを表示し、クリックで `pdfPreview` state をセット。
- すべての添付に「ダウンロード」リンク（`href=fileUrl`, `target="_blank"`）。
- プレビューモーダル:
  - `fixed inset-0 bg-black/50` のオーバーレイ
  - 中央カードにファイル名 + 閉じるボタン + `<iframe src={fileUrl}>`
  - オーバーレイクリック or × ボタンで `pdfPreview = null`。

※ 現時点では添付のアップロード／Storage 連携は未実装のため、多くの投稿では `attachments` は空で、このセクションは非表示となります。

### 3.5 コメント一覧（閲覧のみ）

- セクションラベル・文言（i18n）:
  - `board.detail.section.comments`
  - `board.detail.comments.title`
  - `board.detail.comments.readonly`
  - `board.detail.comments.empty`
- 表示ロジック:
  - `data.comments.length === 0`
    - 「表示できるコメントはありません。」等の空メッセージ
  - それ以外
    - `BoardCommentDto[]` の各要素をカード表示
      - 投稿者名（`authorDisplayName`）
      - 投稿日時（`formatDateTime(comment.createdAt, currentLocale)`）
      - 本文（`whitespace-pre-wrap`）
    - カード枠は `border-2 border-gray-200` で統一。
- コメント投稿・返信ボタンは **一切表示していない**（WS-B02-01 のスコープ外）。

### 3.6 ナビゲーション

- 画面下部に `HomeFooterShortcuts` を常時表示。
- 当初は「掲示板一覧へ戻る」ボタンを本文下に置いていたが、
  フッターにショートカットがあるため **二重導線は削除**。

---

## 4. Home / BoardTop との連携

### 4.1 Home → BoardDetail への遷移

**ファイル:** `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`

- 「最新のお知らせ」のカードクリックで、該当投稿の詳細へ遷移するように変更:

```tsx
<button
  key={item.id}
  type="button"
  ...
  onClick={() => {
    router.push(`/board/${item.id}`);
  }}
>
  ...
</button>
```

- これにより、Home 上部の管理組合投稿をタップ → BoardDetail へ遷移、という想定どおりの動きになります。

### 4.2 BoardTop → BoardDetail への遷移

**ファイル:** `src/components/board/BoardTop/BoardPostSummaryCard.tsx`

- 投稿カードのクリックで BoardDetail に遷移するように修正:

```tsx
const router = useRouter();

const handleClick = () => {
  router.push(`/board/${post.id}`);
};
```

- 以前は `console.log("open detail", post.id);` のみだったため、今回のタスクで正式な遷移ロジックに変更しました。

---

## 5. i18n（BoardDetail 用ラベルの追加）

BoardDetailPage で使用している `board.detail.*` 系のキーを、ja/en/zh の `common.json` に追加しました。

### 5.1 追加した主なキー

- `board.detail.section.content` — 本文 / Content / 正文
- `board.detail.section.attachments` — 添付ファイル / Attachments / 附件
- `board.detail.section.comments` — コメント / Comments / 评论
- `board.detail.attachments.title` — 添付ファイル / Attachments / 附件
- `board.detail.attachments.preview` — プレビュー / Preview / 预览
- `board.detail.attachments.download` — ダウンロード / Download / 下载
- `board.detail.attachments.closePreview` — プレビューを閉じる / Close preview / 关闭预览
- `board.detail.comments.title` — コメント一覧 / Comments / 评论一览
- `board.detail.comments.readonly` — 閲覧専用 / Read-only / 仅限查看
- `board.detail.comments.empty` — 表示できるコメントはありません。/ There are no comments to display. / 暂无可显示的评论。
- `board.detail.actions.backToList` — 掲示板一覧へ戻る / Back to board list / 返回公告列表
  - UI からは削除したが、将来別位置で使う可能性もあるため辞書には残しています。

### 5.2 見た目への影響

- 以前は `board.detail.comments.title` などのキー文字列そのものが画面下部に表示されていたが、
  それぞれ自然な文言（日本語／英語／中国語）に置き換わりました。

---

## 6. スタイル統一（ボーダー太さ・色）

- BoardTop / Home / Footer に合わせて、BoardDetail でもカード枠を `border-2 border-gray-200` で統一。
- 対象:
  - 本文カード
  - 添付ファイル行
  - コメントカード
- これにより、アプリ全体でカード枠の太さ・色が揃い、フッターアイコンとの一体感が出ています。

---

## 7. 既知の仕様・今後のタスク

- **添付ファイルの保存**
  - 現時点では、投稿時にファイルを Supabase Storage へアップロードする処理は未実装です。
  - `board_attachments` テーブルと BoardDetail の UI は「土台のみ」存在し、
    実際のファイル連携は後続タスクで実装予定です。

- **コメント投稿・返信**
  - 詳細画面ではコメント一覧のみ表示し、投稿・削除・返信 UI は提供していません。
  - WS-B02-02 以降で、API・RLS を含めたコメント機能を実装予定です。

- **翻訳ボタン・TTS**
  - BoardDetail における翻訳再実行ボタンや音声読み上げボタンは未実装。
  - 仕様書 B-02 ch05/ch06 に従い、後続タスクで段階的に追加する方針です。

---

## 8. 本日のまとめ

- `/board/[postId]` の **閲覧専用詳細画面** を実装し、
  - BoardTop / Home からの遷移
  - JA/EN/ZH の翻訳キャッシュを使った本文表示
  - 添付・コメントの閲覧
  - PDF プレビューモーダルの骨格
  - 共通フッターによるナビゲーション
  を一通り動作する状態にしました。
- Next.js 16 の `params` 仕様変更に伴う警告を解消し、
  404 時にもフッターから安全に戻れる 404 ページを追加しました。
- BoardDetail 用の i18n キーを 3 言語分整備し、キー文字列が画面に露出しないようにしました。
- UI 面では、Home / BoardTop / BoardDetail / フッターでカード枠の太さ・色を統一し、
  画面間の一貫性を確保しました。

以上が WS-B02-01（閲覧専用 BoardDetail）の本日分作業レポートです。
