# WS-B01_BoardTop_v1.2

**Task ID:** B01-BoardTop-UI-Rev2
**Component ID:** B-01 BoardTop
**Task Name:** 掲示板TOP画面（/board） タグフィルタ＆FAB 修正実装
**担当AI:** Windsurf

---

## 1. ゴール / スコープ

### 1.1 ゴール

掲示板TOP画面 `/board` を、設計どおりの UI / 挙動に修正する。

1. HOME と同じレイアウト配下で表示され、AppHeader / FooterShortcutBar / AppFooter が正しく表示されること。
2. 新規投稿ボタンが「画面右下の丸い `＋` フローティングボタン（FAB）」になっていること。
3. フィルタリング用タグが **「すべて + テナント定義済みの全カテゴリ」** を表示し、選択したカテゴリに応じて投稿一覧が絞り込まれること。
4. タグ UI は将来カテゴリ数が増えても破綻しない構造（配列定義 + map 描画 + 横スクロール）になっていること。

### 1.2 スコープ

含める:

* `/board` のページ構造（AppLayout 配下）
* BoardTopPage コンポーネントの状態管理・タグフィルタロジック
* タグバー UI（全カテゴリ + "すべて"）
* 右下 FAB の配置・遷移

含めない:

* Supabase 実データの接続（現状のダミーデータ前提）
* BoardDetail `/board/[postId]`、BoardPostForm `/board/new` のロジック変更
* 翻訳/TTS の内部処理

---

## 2. 前提 / 参照

* B-01 BoardTop 詳細設計 ch01〜ch07（タグ=カテゴリでフィルタする前提）
* 掲示板機能サマリ（BoardTop/BoardDetail/BoardNew）
* フロントエンドディレクトリガイドライン / 技術スタック定義書
* 既存実装（現在の `/board`）は「たたき台」とし、本指示書の仕様を優先する。

CodeAgent_Report の保存先:

* `/01_docs/06_品質チェック/CodeAgent_Report_B01-BoardTop_v1.2.md`

---

## 3. ルーティング / レイアウト

### 3.1 ルート定義

* ルート: `/board`
* ページファイル: `app/(tenant)/board/page.tsx`

要件:

* `/board` は HOME と同じレイアウト配下（`app/(tenant)/layout.tsx`）に置くこと。
* `app/board/layout.tsx` 等の専用 layout は作成しない。既に存在する場合は削除し共通レイアウトに統合する。
* `/board` を開いたとき、AppHeader / FooterShortcutBar / AppFooter が HOME と同じ見え方で表示されていること。

### 3.2 page.tsx

`page.tsx` は BoardTopPage をレンダリングするだけのコンテナとする。

```tsx
import { BoardTopPage } from '@/src/components/board/BoardTop/BoardTopPage';

export default function BoardPage() {
  return <BoardTopPage />;
}
```

---

## 4. タグ（カテゴリ）フィルタ仕様

### 4.1 用語

* 「タグ」= `board_categories` テーブルに登録されているカテゴリ。
* 本画面では、**カテゴリ全件 + 仮想カテゴリ "すべて"** をフィルタ用タグとして表示する。

### 4.2 タグリスト

BoardTopPage 内で、タグリストを次のように管理する（Supabase 連携前のダミー実装）。

```ts
export type BoardCategoryTag = {
  id: string;           // カテゴリID（ダミー時は key でも可）
  key: string;          // 'notice' | 'rules' | 'event' ...
  labelKey: string;     // i18n キー（例: 'board.postForm.category.important'）
};

export type BoardTab = 'all' | BoardCategoryTag['id'];

const [activeTab, setActiveTab] = useState<BoardTab>('all');

const CATEGORY_TAGS: BoardCategoryTag[] = [
  { id: 'important', key: 'important', labelKey: 'board.postForm.category.important' },
  { id: 'circular',  key: 'circular',  labelKey: 'board.postForm.category.circular' },
  { id: 'event',     key: 'event',     labelKey: 'board.postForm.category.event' },
  { id: 'rules',     key: 'rules',     labelKey: 'board.postForm.category.rules' },
  { id: 'question',  key: 'question',  labelKey: 'board.postForm.category.question' },
  { id: 'request',   key: 'request',   labelKey: 'board.postForm.category.request' },
  { id: 'other',     key: 'other',     labelKey: 'board.postForm.category.other' },
];
```

本番では Supabase の `board_categories` から取得した配列に差し替え可能な構造にすること（今は固定配列でよい）。

### 4.3 タグバー描画

BoardTabBar コンポーネントの props 例:

```ts
interface BoardTabBarProps {
  activeTab: BoardTab;
  onChange: (tab: BoardTab) => void;
  categoryTags: BoardCategoryTag[];
}
```

描画ルール:

* 先頭に "すべて" タグを表示（`labelKey = 'board.top.tab.all'`）。
* 続けて `categoryTags` を map して pill ボタンを表示。
* 選択中タブは背景色/枠線/テキスト色で強調。
* 横スクロール可能にするため `overflow-x-auto` を付与し、タグ数が増えても崩れないようにする。

### 4.4 フィルタ挙動

BoardTopPage で投稿配列 `posts` に対し、`activeTab` で絞り込む。

```ts
const filteredPosts = useMemo(() => {
  if (activeTab === 'all') return posts;
  return posts.filter((p) => p.categoryId === activeTab);
}, [posts, activeTab]);
```

要件:

* `activeTab === 'all'`: すべての投稿を表示。
* `activeTab === <カテゴリID>`: `post.categoryId` がそのカテゴリIDの投稿だけ表示。
* `filteredPosts.length === 0` のときは BoardEmptyState を表示する（一覧は非表示）。

テストデータが「お知らせカテゴリのみ」の場合でも、

* すべて → 1件表示
* お知らせ → 1件表示
* その他タグ → 0件表示（空状態）

となること。

---

## 5. 新規投稿 FAB 仕様

### 5.1 配置 / スタイル

* 画面右下に固定配置。
* Tailwind の例:

```tsx
<button
  type="button"
  className="fixed bottom-20 right-4 z-[901] flex h-12 w-12 items-center justify-center rounded-full bg-blue-500 text-white shadow-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2"
  aria-label={t('board.top.newPost.button')}
>
  <Plus className="h-6 w-6" />
</button>
```

* スクロールしても常に表示されていること。
* フッターや FooterShortcutBar とかぶらないよう、コンテンツ側に `pb-20` 前後の余白を取ること。

### 5.2 挙動

* クリック / タップで `/board/new` に遷移する。
* `useRouter().push('/board/new')` または `<Link href="/board/new">` を使用。
* 投稿権限のないユーザは FAB 自体を表示しない（既存 `canPost` があれば利用、無ければ現時点では常に表示でも可）。

---

## 6. UI 要件（抜粋）

* タグバーはタイトル直下に横並びで表示する。
* pill ボタンデザイン（例）:

  * 非選択: `bg-white text-gray-500 border border-gray-200`
  * 選択中: `bg-blue-50 text-blue-600 border border-blue-400`
* タグ数が増えても折り返さず、横スクロールで対応 (`overflow-x-auto`, `flex-nowrap`)。

投稿カード / 空状態 / エラー状態の仕様は v1.1 と同じでよい（ここでは変更しない）。

---

## 7. テスト / 完了条件

### 7.1 テスト観点

* `/board` 表示時に AppHeader / FooterShortcutBar / AppFooter が表示されている。
* タグバーに "すべて" + 7カテゴリ（important/circular/event/rules/question/request/other）が表示されている。
* ダミーデータで、カテゴリIDを変えたときに `filteredPosts` の件数が期待どおりになる。
* FAB が右下に表示され、クリックで `/board/new` に遷移する（router.push のモックで検証）。

### 7.2 完了条件

* `npm run lint` / `npm run test` が成功。
* ブラウザで手動確認し、タグ表示・フィルタ挙動・FAB の位置/遷移が本書と一致していること。
* CodeAgent_Report_B01-BoardTop_v1.2.md が所定パスに作成されていること。

了解しました。
WS-B01_BoardTop_v1.2 の「最後の行」に追記する想定で、追加分だけ出します。

### 7.3 カテゴリバッジの表示ルール（翻訳対応）

`BoardPostSummaryCard` のカテゴリバッジは、必ず i18n 経由で表示すること。  
DB 上の `category_name`（日本語名）や文字列リテラル（"お知らせ" など）は使用しない。

実装方針の例:

```ts
const CATEGORY_LABEL_MAP: Record<string, string> = {
  important: 'board.postForm.category.important',
  circular: 'board.postForm.category.circular',
  event: 'board.postForm.category.event',
  rules: 'board.postForm.category.rules',
  question: 'board.postForm.category.question',
  request: 'board.postForm.category.request',
  other: 'board.postForm.category.other',
};

function CategoryBadge({ categoryKey }: { categoryKey: string }) {
  const { t } = useI18n();
  const labelKey =
    CATEGORY_LABEL_MAP[categoryKey] ?? 'board.postForm.category.other';
  return <span>{t(labelKey)}</span>;
}

* `categoryKey` は `board_categories.category_key` を想定する。
* EN / ZH でもタグが正しく翻訳されることを受け入れ条件に含める。

```
---

## 8. CodeAgent_Report 要件

* `agent_name: Windsurf`
* `task_id: B01-BoardTop-UI-Rev2`
* `attempt_count` / `self_score_overall` / `typecheck` / `lint` / `test`
* `changed_files`（今回編集・追加したファイル）
* `notes`（設計に関する気づき・後続タスク候補）

本指示書に明示されていない仕様変更・リファクタは行わず、必要な場合は `notes` に提案として記載するだけとする。
