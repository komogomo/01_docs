````markdown
# WS-B01_B03_BoardTopAndPostFormFix_v1.0

**Task ID:** B01-B03-BoardTop-And-PostForm-Fix  
**Components:**  
- B-01 BoardTop（/board）  
- B-03 BoardPostForm（/board/new）  
**Task Name:** 掲示板TOP タグ・投稿ボタン／投稿フォームカテゴリ（グループ）修正  
**担当AI:** Windsurf  

---

## 1. ゴール / スコープ

### 1.1 ゴール

1. 掲示板TOP `/board` のタグフィルタが  
   - 「すべて」＋テナント定義済みの全カテゴリ（重要なお知らせ／回覧板／イベント／ルール・規約／質問／要望／グループ／その他）  
   を表示し、カテゴリに応じて一覧が正しく絞り込まれること。
2. `/board` の新規投稿ボタンが  
   - 画面右下の **透明ベースの円形 FAB** として表示され  
   - クリックで `/board/new` に遷移すること。
3. 投稿フォーム `/board/new` のカテゴリ選択が  
   - 一般利用者投稿時：一般向けカテゴリ＋「グループ」が表示される  
   - 管理組合投稿時：管理組合向けカテゴリのみ（グループは非表示）  
   となること。
4. BoardTop のタグ表示と BoardPostForm のカテゴリ候補が論理的に整合していること。

### 1.2 スコープ

**含める**

- `app/(tenant)/board/page.tsx` と BoardTop 関連コンポーネントの修正
- `/board` のタグバー・フィルタロジック・右下 FAB のスタイル／挙動修正
- `/board/new` の BoardPostForm カテゴリ選択ロジック修正（管理組合／一般利用者）
- カテゴリ表示に使用する i18n キー `board.postForm.category.*` の利用（キーそのものは TKD 管理）

**含めない**

- Supabase スキーマ変更（`board_categories` など）
- RLS ポリシー変更
- BoardPostForm のバリデーション仕様変更

---

## 2. 対象ファイル

### 2.1 変更してよいファイル

- `app/(tenant)/board/page.tsx`
- `src/components/board/BoardTop/BoardTopPage.tsx`
- `src/components/board/BoardTop/BoardTabBar.tsx`
- `src/components/board/BoardTop/BoardPostSummaryList.tsx`
- `src/components/board/BoardTop/BoardPostSummaryCard.tsx`
- `src/components/board/BoardTop/BoardEmptyState.tsx`
- `src/components/board/BoardTop/BoardErrorState.tsx`
- `src/components/board/BoardTop/BoardNewPostFab.tsx`（存在しない場合は新規作成可）
- `src/components/board/BoardPostForm/BoardPostForm.tsx`（名称は現状に合わせる）
- 上記に対応する `*.types.ts`、`__tests__/*.test.tsx`

### 2.2 参照専用ファイル（変更禁止）

- `app/(tenant)/layout.tsx`  
- `src/components/common/AppHeader/*`  
- `src/components/common/AppFooter/*`  
- `src/components/common/FooterShortcutBar/*`  
- `src/components/common/StaticI18nProvider/*`  

---

## 3. 掲示板TOP：レイアウトとタグフィルタ

### 3.1 レイアウト前提

- `/board` は `app/(tenant)/board/page.tsx` とし、HOME と同じ Layout 配下で表示する。
- AppHeader / FooterShortcutBar / AppFooter は Layout 側のものをそのまま使用する（専用 layout は作成しない）。

```tsx
// app/(tenant)/board/page.tsx

import { BoardTopPage } from '@/src/components/board/BoardTop/BoardTopPage';

export default function BoardPage() {
  return <BoardTopPage />;
}
````

### 3.2 カテゴリタグ定義

BoardTopPage 内で、カテゴリタグを次のように管理する（将来 `board_categories` から差し替え可能とする）。

```ts
export type BoardCategoryKey =
  | 'important'
  | 'circular'
  | 'event'
  | 'rules'
  | 'question'
  | 'request'
  | 'group'
  | 'other';

export type BoardCategoryTag = {
  id: BoardCategoryKey;
  labelKey: string; // i18n キー
};

export type BoardTab = 'all' | BoardCategoryKey;

const CATEGORY_TAGS: BoardCategoryTag[] = [
  { id: 'important', labelKey: 'board.postForm.category.important' },
  { id: 'circular',  labelKey: 'board.postForm.category.circular' },
  { id: 'event',     labelKey: 'board.postForm.category.event' },
  { id: 'rules',     labelKey: 'board.postForm.category.rules' },
  { id: 'question',  labelKey: 'board.postForm.category.question' },
  { id: 'request',   labelKey: 'board.postForm.category.request' },
  { id: 'group',     labelKey: 'board.postForm.category.group' },   // ★ グループ
  { id: 'other',     labelKey: 'board.postForm.category.other' }
];
```

### 3.3 タグバー UI

BoardTabBar の props 例：

```ts
interface BoardTabBarProps {
  activeTab: BoardTab;
  onChange: (tab: BoardTab) => void;
  categoryTags: BoardCategoryTag[];
}
```

描画ルール：

* 先頭に「すべて」タブを表示（`labelKey = 'board.top.tab.all'`）。
* 続いて `categoryTags` を順に pill ボタンで表示。
* タブは必ず「すべて＋全カテゴリ（important〜other＋group）」が表示されること。
* レイアウトは横スクロール可能にする：

```tsx
<div className="flex gap-2 overflow-x-auto pb-2">
  {/* すべて */}
  {/* カテゴリ map */}
</div>
```

* 選択中タブは背景色と枠線で強調（例）：

  * 非選択: `bg-white text-gray-600 border border-gray-200`
  * 選択中: `bg-blue-50 text-blue-600 border border-blue-400`

### 3.4 絞り込みロジック

BoardTopPage で `activeTab` と投稿配列 `posts` から `filteredPosts` を作る。

```ts
const [activeTab, setActiveTab] = useState<BoardTab>('all');

const filteredPosts = useMemo(() => {
  if (activeTab === 'all') return posts;
  return posts.filter((p) => p.categoryKey === activeTab);
}, [posts, activeTab]);
```

要件：

* `activeTab === 'all'` → すべての投稿を表示。
* `activeTab === <categoryKey>` → `post.categoryKey` が一致する投稿のみ表示。
* `filteredPosts.length === 0` の場合は BoardEmptyState を表示し、リストは表示しない。

### 3.5 カテゴリバッジの翻訳表示

BoardPostSummaryCard のカテゴリバッジは、i18n キーから表示する。

```ts
const CATEGORY_LABEL_MAP: Record<BoardCategoryKey, string> = {
  important: 'board.postForm.category.important',
  circular:  'board.postForm.category.circular',
  event:     'board.postForm.category.event',
  rules:     'board.postForm.category.rules',
  question:  'board.postForm.category.question',
  request:   'board.postForm.category.request',
  group:     'board.postForm.category.group',
  other:     'board.postForm.category.other'
};

function CategoryBadge({ categoryKey }: { categoryKey: BoardCategoryKey }) {
  const { t } = useI18n();
  const labelKey = CATEGORY_LABEL_MAP[categoryKey] ?? CATEGORY_LABEL_MAP.other;
  return (
    <span className="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-xs font-medium text-blue-600">
      {t(labelKey)}
    </span>
  );
}
```

* DB の `category_name` や生文字列（"お知らせ" など）は使用しない。
* 言語を EN / ZH に切り替えた場合もタグが翻訳されることを受け入れ条件に含める。

---

## 4. 掲示板TOP：新規投稿ボタン（透明 FAB）

### 4.1 スタイル

* 画面右下に固定、背景は透明、○枠と影で存在感を出す。
* 投稿本文が隠れないよう、一覧コンテナには十分な `padding-bottom` を入れる。

```tsx
// BoardTopPage（一覧ラッパ）
<div className="flex flex-col gap-3 pb-28">
  {/* 投稿カード一覧 */}
</div>

// FAB
<button
  type="button"
  className="
    fixed bottom-16 right-4 z-[901]
    flex h-11 w-11 items-center justify-center
    rounded-full
    bg-transparent
    border border-blue-400
    text-blue-500
    shadow-lg shadow-blue-200/60
    hover:bg-blue-50/40
    active:bg-blue-100/40
    focus:outline-none
    focus:ring-2 focus:ring-blue-300/70 focus:ring-offset-2
  "
  aria-label={t('board.top.newPost.button')}
>
  <Plus className="h-6 w-6" strokeWidth={2.6} />
</button>
```

ポイント：

* **透明背景**：`bg-transparent`（ホバー時のみ薄く色付け）
* **輪郭＋影で存在感**：`border-blue-400` と `shadow-lg shadow-blue-200/60`
* **＋を太く・大きく**：`h-6 w-6` ＋ `strokeWidth={2.6}`

### 4.2 挙動

* クリックで `/board/new` に遷移する。

```ts
const router = useRouter();
const handleClick = () => router.push('/board/new');
```

* 投稿権限がないユーザの場合は FAB 自体を表示しない（既存 `canPost` があれば利用、それがなければ今回は常に表示でも可）。

---

## 5. BoardPostForm：カテゴリ候補（グループ含む）

### 5.1 前提

* 管理組合投稿（投稿者区分: 管理組合）と一般利用者投稿で、カテゴリ候補が異なる。
* 一般利用者投稿では「グループ」カテゴリが選択可能である必要がある。
* 管理組合投稿では「グループ」カテゴリは表示しない。

### 5.2 カテゴリグループ定義

BoardPostForm 内、または共通定義ファイルにカテゴリグループを定義する。

```ts
const MANAGEMENT_CATEGORIES: BoardCategoryKey[] = [
  'important', // 重要なお知らせ
  'event',     // イベント
  'circular',  // 回覧板
  'rules'      // ルール・規約
];

const GENERAL_CATEGORIES: BoardCategoryKey[] = [
  'question',  // 質問
  'request',   // 要望
  'group',     // グループ  ★ 一般利用者のみ
  'other'      // その他
];
```

※ 配列内容は既存設計に合わせて調整可だが、「group は GENERAL 側のみ」にすること。

### 5.3 ドロップダウン候補生成

投稿者区分の状態（例: `posterType` または `authorRole`）に応じて候補を切り替える。

```ts
type PosterRole = 'management' | 'general';

const categoryOptions = useMemo(() => {
  const source =
    posterRole === 'management' ? MANAGEMENT_CATEGORIES : GENERAL_CATEGORIES;

  return source.map((key) => ({
    value: key,
    labelKey: CATEGORY_LABEL_MAP[key] // 3.5 と同じ map を利用
  }));
}, [posterRole]);
```

* `CATEGORY_LABEL_MAP` は BoardTop と共通のものを利用し、i18n キーからラベルを取得する。
* ドロップダウン描画例：

```tsx
<select ...>
  <option value="">{t('board.postForm.field.category.placeholder')}</option>
  {categoryOptions.map((opt) => (
    <option key={opt.value} value={opt.value}>
      {t(opt.labelKey)}
    </option>
  ))}
</select>
```

### 5.4 受け入れ条件（カテゴリ）

* 投稿者区分 = 「管理組合として投稿する」のとき、カテゴリ候補に `group` が含まれていないこと。
* 投稿者区分 = 「一般利用者として投稿する」のとき、カテゴリ候補に `group` が含まれていること。
* BoardTop のタグバーと、BoardPostForm のカテゴリ候補に出てくるカテゴリキーの集合が一致していること（`important/circular/event/rules/question/request/group/other`）。

---

## 6. テスト / 完了条件

### 6.1 テスト観点（最低限）

* `/board` でタグバーに「すべて＋重要なお知らせ＋回覧板＋イベント＋ルール・規約＋質問＋要望＋グループ＋その他」が表示される。
* ダミーデータで `categoryKey='important'` の投稿がある場合:

  * 「すべて」タブ → その投稿が表示される。
  * 「重要なお知らせ」タブ → その投稿が表示される。
  * 「質問」等、別カテゴリタブ → その投稿は表示されない。
* FAB:

  * 画面右下の透明ボタンが表示される。
  * ボタン下にカードが隠れない（最下部カードが十分上に表示される）。
  * クリックで `/board/new` に遷移する（テストでは `router.push` 呼び出しをモックして検証）。
* `/board/new`:

  * 投稿者区分 = 一般利用者 → カテゴリ候補に「グループ」が含まれる。
  * 投稿者区分 = 管理組合 → カテゴリ候補に「グループ」が含まれない。

### 6.2 完了条件

* `npm run lint` / `npm run test` が成功。
* 上記テスト観点を手動確認し、期待どおりに動作していること。
* CodeAgent_Report_B01-BoardTopAndPostFormFix_v1.0.md を
  `/01_docs/06_品質チェック/` 配下に作成し、変更ファイル一覧・自己評価・補足メモを記載すること。

---

## 7. CodeAgent_Report 要件

`CodeAgent_Report_B01-BoardTopAndPostFormFix_v1.0.md` には少なくとも次を含める。

* `agent_name: Windsurf`
* `task_id: B01-B03-BoardTop-And-PostForm-Fix`
* `attempt_count`
* `self_score_overall`（10点満点）
* `typecheck / lint / test` の結果
* `changed_files`（編集・追加したファイル一覧）
* `notes`（気づいた問題、後続タスク候補）

本指示書に明記されていない仕様変更やリファクタリングは行わないこと。必要があれば `notes` に提案として記載するのみとする。

```
::contentReference[oaicite:0]{index=0}
```
