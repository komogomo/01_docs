# WS-B01_BoardTop_v1.1

**Task ID:** B01-BoardTop-UI-Rev1
**Component ID:** B-01 BoardTop
**Task Name:** 掲示板TOP画面（/board） UI 実装修正
**担当AI:** Windsurf
**対象ブランチ:** TKD 指定の作業ブランチ

---

## 1. ゴール / スコープ

### 1.1 ゴール

既に実装済みの掲示板TOP画面 `/board` について、以下の設計どおりの挙動・UI に修正する。

1. HOME と同じレイアウト配下で表示され、AppHeader / AppFooter / FooterShortcutBar が正しく表示されていること。
2. 新規投稿ボタンが「画面右下の丸い `＋` フローティングボタン（FAB）」として表示され、クリックで `/board/new` へ遷移すること。
3. カテゴリタブ（すべて / お知らせ / 規約・ルール）が **常に 3 つ表示される** こと。
4. タブと投稿カテゴリ (`categoryKey`) の絞り込み挙動が設計どおりであること。
5. タブ UI が将来タグが増えても破綻しない構造（配列定義 + map 描画）になっていること。

### 1.2 スコープ

**含める:**

* `/board` ページの JSX 構造と配置（AppLayout の children 部分）
* BoardTopPage コンポーネントの内部状態・タブ切替ロジック・ダミーデータによるカテゴリフィルタ
* 右下 FAB（新規投稿ボタン）の配置・スタイリング・遷移処理
* カテゴリタブ UI（3 つ固定）と選択中タブの視覚的強調

**含めない:**

* Supabase からの実データ取得（現状のダミーデータを前提とする）
* 翻訳ボタン / 読み上げボタンの内部処理（必要なら UI プレースホルダのみ）
* BoardDetail `/board/[postId]` の実装・修正
* BoardPostForm `/board/new` のロジック変更

---

## 2. 参照設計書

Windsurf は以下の設計書を **読み取り専用** として参照すること。

* 掲示板 TOP 詳細設計書 B-01 ch01〜ch07（最新版）
* 掲示板機能 最終案サマリ（Board Top / Board Detail / Board New）fileciteturn14file12
* HarmoNet フロントエンドディレクトリガイドライン v1.0fileciteturn14file2
* StaticI18nProvider / AppFooter 詳細設計書（C-03 / C-04）fileciteturn14file5turn14file3
* 技術スタック定義書 v4.5（Next.js 16 / React 19 / Tailwind / StaticI18nProvider / OpenAI Moderation）fileciteturn14file13
* Windsurf 実行指示書テンプレート v1.2（本書はこれに準拠）fileciteturn14file11

CodeAgent_Report の保存先:

* `/01_docs/06_品質チェック/CodeAgent_Report_B01-BoardTop_v1.1.md`

---

## 3. 実装対象ファイル / 参照専用ファイル

### 3.1 編集してよいファイル（Writeable）

このタスクで新規作成・編集を許可するのは次のファイルのみとする。

* `app/(tenant)/board/page.tsx`
* `src/components/board/BoardTop/BoardTopPage.tsx`
* `src/components/board/BoardTop/BoardTopPage.types.ts`（存在しない場合は新規作成可）
* `src/components/board/BoardTop/BoardTabBar.tsx`
* `src/components/board/BoardTop/BoardTabBar.types.ts`（任意）
* `src/components/board/BoardTop/BoardPostSummaryList.tsx`
* `src/components/board/BoardTop/BoardPostSummaryCard.tsx`
* `src/components/board/BoardTop/BoardEmptyState.tsx`
* `src/components/board/BoardTop/BoardErrorState.tsx`
* `src/components/board/BoardTop/BoardNewPostFab.tsx`（FAB を切り出す場合）
* `src/components/board/BoardTop/__tests__/BoardTopPage.test.tsx`

これ以外のファイル（特に AppHeader / AppFooter / StaticI18nProvider / FooterShortcutBar / BoardPostForm）は **変更禁止**。挙動を変えたい場合はコメントとして CodeAgent_Report に提案のみ記載すること。

### 3.2 参照専用ファイル（Read-only）

* `app/layout.tsx`
* `app/login/page.tsx`（レイアウトや AppFooter の使い方の参考）
* `src/components/common/AppHeader/*`
* `src/components/common/AppFooter/*`
* `src/components/common/FooterShortcutBar/*`
* `src/components/common/StaticI18nProvider/*`

---

## 4. ルーティングとレイアウト

### 4.1 ルート定義

* ルート: `/board`
* ページファイル: `app/(tenant)/board/page.tsx`

要件:

* `/board` は HOME と同じレイアウト配下（`app/(tenant)/layout.tsx` 相当）に配置すること。
* `app/board/layout.tsx` のような専用 layout を新規作成してはならない。既に存在する場合は削除し、共通レイアウト配下に統合する。
* `/board` をブラウザで開いたとき、HOME と同じ `AppHeader` / `AppFooter` / `FooterShortcutBar` が表示されることを確認すること。

### 4.2 page.tsx の役割

* `page.tsx` は **ページコンテナ** として BoardTopPage を呼び出すだけとする。
* ビジネスロジックや状態管理は `BoardTopPage.tsx` 側に集約し、`page.tsx` には書かない。

擬似コード:

```tsx
// app/(tenant)/board/page.tsx

import { BoardTopPage } from '@/src/components/board/BoardTop/BoardTopPage';

export default function BoardPage() {
  return <BoardTopPage />;
}
```

---

## 5. BoardTopPage ロジック仕様

### 5.1 タブ状態と絞り込み

BoardTopPage は、カテゴリタブと投稿絞り込みの最小状態として次を持つ。

```ts
export type BoardTab = 'all' | 'notice' | 'rules';

const [tab, setTab] = useState<BoardTab>('all');
const [isLoading, setIsLoading] = useState(false);
const [isError, setIsError] = useState(false);
```

**カテゴリタブと絞り込みのルール:**

* `tab === 'all'`     → すべての投稿を表示
* `tab === 'notice'`  → `categoryKey === 'notice'` の投稿のみ表示
* `tab === 'rules'`   → `categoryKey === 'rules'` の投稿のみ表示

テストデータが「お知らせ」カテゴリだけの場合でも、挙動は次のようになること:

* 「すべて」タブ → 1件表示
* 「お知らせ」タブ → 1件表示
* 「規約・ルール」タブ → 0件表示（BoardEmptyState を表示）

現状ダミーデータでよいが、将来 Supabase 連携時もこのロジックを前提とする。

### 5.2 タブ定義配列

タブ UI は将来カテゴリが増えても破綻しないよう、配列から map する形で実装すること。

```ts
const BOARD_TABS: { key: BoardTab; labelKey: string }[] = [
  { key: 'all',    labelKey: 'board.top.tab.all' },
  { key: 'notice', labelKey: 'board.top.tab.notice' },
  { key: 'rules',  labelKey: 'board.top.tab.rules' },
];
```

BoardTabBar はこの配列を props として受け取り、`BOARD_TABS.map` でタブを描画する。

### 5.3 BoardTabBar コンポーネント

* props 例:

```ts
export interface BoardTabBarProps {
  tabs: { key: BoardTab; labelKey: string }[];
  activeTab: BoardTab;
  onChange: (next: BoardTab) => void;
}
```

* 描画:

  * `tabs` 配列の順に pill 風ボタンを横並びで表示する。
  * 選択中タブは背景色 or 下線で強調表示する。
  * 横幅を超える場合に備え、`overflow-x-auto` を付与しておくこと（将来カテゴリ増加に備える）。

### 5.4 投稿一覧フィルタ

BoardTopPage 内で `dummyPosts`（または将来の fetchedPosts）をフィルタする処理を実装する。

```ts
const filteredPosts = useMemo(() => {
  switch (tab) {
    case 'notice':
      return posts.filter((p) => p.categoryKey === 'notice');
    case 'rules':
      return posts.filter((p) => p.categoryKey === 'rules');
    case 'all':
    default:
      return posts;
  }
}, [posts, tab]);
```

* `BoardPostSummaryList` には `filteredPosts` を渡すこと。
* `filteredPosts.length === 0` のときは BoardEmptyState を表示し、リストは表示しない。

---

## 6. UI 要件（BoardTop 部分）

### 6.1 全体レイアウト

* スマホ優先 1 カラムレイアウト。
* 上から順に:

  1. 画面タイトル（"掲示板"）
  2. カテゴリタブバー
  3. （将来）ソート・件数指定エリア（今回 UI のみで可）
  4. 一覧カード
  5. 空/エラー状態
* FooterShortcutBar と AppFooter は Layout 側で下部に固定表示されるため、BoardTop 内では高さ/余白で干渉しないようにする（下部に余白 `pb-20` 程度を追加して FAB とフッターが重ならないようにする）。

### 6.2 カテゴリタブ UI

* pill 型ボタンで、「すべて」「お知らせ」「規約・ルール」の 3 つを常に表示。
* 選択中タブは Tailwind 例:

  * 非選択: `bg-white text-gray-500 border border-gray-200`
  * 選択中: `bg-blue-50 text-blue-600 border border-blue-300`
* キーは `t('board.top.tab.*')` で取得し、ラベル文字列は `common.json` に定義済み（JA/EN/ZH は TKD が管理）。

### 6.3 投稿カード

既存の BoardPostForm 詳細設計 / 掲示板サマリに沿って、最低限以下を表示する。fileciteturn14file12

* 上部左: カテゴリバッジ（例: `お知らせ` / `規約・ルール`）
* 中央: タイトル（2行まで、`line-clamp-2` 可）
* 下部左: 投稿者表示名（管理組合 / 一般利用者） + 投稿日時
* 下部右: 添付アイコン（`hasAttachment=true` の場合のみ）

カード全体はクリック可能とし、現時点では `console.log('open detail', id)` 程度でよい（BoardDetail 連携は別タスク）。

---

## 7. 新規投稿 FAB 仕様

### 7.1 位置とスタイル

* 画面右下にフローティング配置する。
* Tailwind のイメージ:

```tsx
<button
  type="button"
  className="fixed bottom-20 right-4 z-[901] flex h-12 w-12 items-center justify-center rounded-full bg-blue-500 text-white shadow-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2"
  aria-label={t('board.top.newPost.button')}
>
  <Plus className="h-6 w-6" />
</button>
```

* PC では `title="新規投稿"` を付与してもよい。
* スクロール位置に関わらず常に表示されること。

### 7.2 挙動

* クリック / タップで `/board/new` に遷移すること。
* Next.js App Router の `useRouter().push('/board/new')` または `<Link href="/board/new">` を用いる。
* 投稿権限のないユーザ（閲覧専用）は FAB 自体を表示しない。権限判定のロジックは既存の `canPost` 等があればそれを利用し、なければ今は常に表示で構わない（後続タスクで制御）。

---

## 8. テスト / 受け入れ条件

### 8.1 最低限のテスト観点（Vitest + RTL）

* BoardTopPage 初期表示で:

  * タイトル "掲示板" が表示されている
  * タブが「すべて / お知らせ / 規約・ルール」の3つ表示されている
  * デフォルトで "すべて" タブがアクティブになっている
* ダミーデータが 1 件（categoryKey = 'notice'）の場合:

  * 「すべて」タブ: 1件表示
  * 「お知らせ」タブ: 1件表示
  * 「規約・ルール」タブ: 0件表示 + 空状態メッセージ
* FAB:

  * 画面右下に丸い `＋` ボタンが表示されている
  * クリック時に `/board/new` へ遷移する（テストでは `router.push` 呼び出しのモックで検証）

### 8.2 完了条件

* `npm run lint` / `npm run test` がエラーなしで完了すること。
* `/board` をブラウザで開いたとき、以下が目視確認できること:

  * AppHeader / AppFooter / FooterShortcutBar が HOME と同様に表示されている
  * 画面上部に「掲示板」タイトルと 3 タブが表示されている
  * タブ切替に応じて投稿一覧の件数が変化する（"規約・ルール" で空表示）
  * 右下に丸い `＋` FAB が常に表示され、クリックで `/board/new` に遷移する

---

## 9. CodeAgent_Report 要件

Windsurf 実行完了後、次の形式で CodeAgent_Report を作成し、
`/01_docs/06_品質チェック/CodeAgent_Report_B01-BoardTop_v1.1.md` に保存すること。

* `agent_name: Windsurf`
* `task_id: B01-BoardTop-UI-Rev1`
* `attempt_count`: 実行試行回数
* `self_score_overall`: 10 点満点の自己評価（9 以上を目標）
* `typecheck: passed/failed`
* `lint: passed/failed`
* `test: passed/failed`
* `changed_files`: 今回編集・追加したファイル一覧
* `notes`: 気づいた問題、後続タスク候補（BoardDetail や Supabase 連携に関する提案など）

**重要:** 本指示書で明示していない改善案は、実装には含めず `notes` / `suggestions` に記載するだけとし、仕様変更は行わないこと。
