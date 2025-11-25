# WS-B01 BoardTop 実装作業指示書 v1.0

**Document ID:** WS-B01-BoardTop-Implementation
**Target Component:** B-01 BoardTop (/board)
**Environment:** HarmoNet Frontend (Next.js 16, React 19, Supabase JS, Tailwind)
**Prepared by:** Tachikoma
**For Agent:** Windsurf
**Status:** Draft (MVP 実装用)

---

## 1. ゴール / スコープ

### 1.1 ゴール

ログイン済みユーザ向けの掲示板 TOP 画面 `/board` を実装する。
以下を満たせば完了とする。

* HOME およびフッターから `/board` に遷移できる
* BoardTop で、カテゴリタブ（全て/お知らせ/運用ルール）の切替ができる
* 現時点では **ダミーデータによる一覧表示** まででよい（Supabase 連携は後続タスク）
* 新規投稿ボタン押下で `/board/new` に遷移できる

### 1.2 スコープ

本タスクで実装する範囲:

* 画面ルーティング `/board`
* BoardTopPage コンポーネント
* カテゴリタブ UI（ALL/NOTICE/RULES）
* 投稿一覧カード（ダミーデータ）
* 空状態・エラー状態の UI（簡易版）
* 新規投稿ボタン（`/board/new` への遷移）

除外（別タスク）:

* Supabase からの実データ取得
* 翻訳ボタン / TTS ボタンの内部処理（UI のみ用意）
* BoardDetail `/board/[postId]` の実装

---

## 2. 参照資料

実装時には次の設計書を参照すること（読み取り専用）。

* B-01 BoardTop 詳細設計書 ch01〜ch07（最新版）
* HarmoNet フロントエンドディレクトリガイドライン（`harmonet-frontend-directory-guideline_v1.0.md`）
* 技術スタック定義書 `harmonet-technical-stack-definition_v4.5.md`
* B-03 BoardPostForm 詳細設計書 ch08（AI モデレーション）※画面遷移先の前提確認用

CodeAgent_Report の保存先:

* `/01_docs/06_品質チェック/CodeAgent_Report_B01-BoardTop_v1.0.md`

---

## 3. 実装対象とファイル構成

### 3.1 ルーティング

* ルート: `/board`
* ファイル（想定）:

  * `app/board/page.tsx`

`app/board/page.tsx` 内で BoardTopPage コンポーネントをレンダリングする。

### 3.2 コンポーネント構成（最小版）

ディレクトリ構成（既存規約に合わせること）:

* `src/components/board/BoardTop/BoardTopPage.tsx`
* `src/components/board/BoardTop/BoardTabBar.tsx`
* `src/components/board/BoardTop/BoardPostSummaryList.tsx`
* `src/components/board/BoardTop/BoardPostSummaryCard.tsx`
* `src/components/board/BoardTop/BoardEmptyState.tsx`
* `src/components/board/BoardTop/BoardErrorState.tsx`
* `src/components/board/BoardTop/BoardPagination.tsx`

本タスクでは **BoardTopPage / BoardTabBar / BoardPostSummaryList / BoardPostSummaryCard / BoardEmptyState / BoardErrorState** を主対象とし、Pagination はプレースホルダ実装（UI のみ）でよい。

---

## 4. ロジック仕様（今回タスクで必要な範囲）

### 4.1 状態管理

BoardTopPage 内で、次の状態を useState で管理する（Supabase 連携前提の簡易版）。

```ts
export type BoardTab = 'all' | 'notice' | 'rules';

const [tab, setTab] = useState<BoardTab>('all');
const [isLoading, setIsLoading] = useState(false);
const [isError, setIsError] = useState(false);
```

* URL クエリ `tab` の同期は **ここでは実装しない**（後続タスク）。
* 初期値は常に `'all'` でよい。

### 4.2 ダミーデータ

Supabase 実装までの間、BoardTopPage で以下のようなダミー配列を定義し、BoardPostSummaryList に渡す。

```ts
const dummyPosts: BoardPostSummary[] = [
  {
    id: '1',
    categoryKey: 'notice',
    categoryName: 'お知らせ',
    title: '共有部分清掃のお知らせ（11/25実施）',
    contentPreview: '共有部分の清掃を 11/25 に実施します。詳細は…',
    authorDisplayName: '管理組合',
    authorDisplayType: 'management',
    createdAt: '2025-11-20T10:00:00Z',
    hasAttachment: true,
  },
];
```

型は `src/components/board/BoardTop/types.ts` などに最低限定義すればよい。翻訳/TTS 関連のフィールドは今回は不要。

---

## 5. UI 要件（抜粋）

### 5.1 共通トーン

* 既存の HOME 画面・BoardPostForm と同じく、白ベース + 角丸カード + 最小限の影
* Tailwind Utility を使用し、独自 CSS ファイルは追加しない
* スマホ優先レイアウト（1 カラム）

### 5.2 タブ

* `BoardTabBar` で 3 つのタブを表示する:

  * 全て (`board.top.tab.all`)
  * お知らせ (`board.top.tab.notice`)
  * 運用ルール (`board.top.tab.rules`)
* 選択中タブにはボトムボーダー or 塗りつぶしで強調
* onClick 時に `setTab()` を呼ぶ

### 5.3 投稿カード

* カテゴリバッジ（左上）
* タイトル（太字、2 行まで）
* 本文サマリ（2〜3 行、`line-clamp` 可）
* 下部に投稿者名 + 投稿日時
* 右下にクリップアイコン（`hasAttachment=true` のとき）

カード全体がクリック可能で、現時点では `console.log('open detail', id)` だけでよい（リンクは後続タスク）。

### 5.4 空・エラー状態

* `dummyPosts.length === 0` なら BoardEmptyState を表示し、リストは非表示
* isError=true なら BoardErrorState を表示し、「再読み込み」ボタン押下で `console.log('retry')` のみ

---

## 6. テスト方針（最小）

Vitest + Testing Library によるコンポーネントテストを 1 本だけ用意する。

対象:

* `BoardTopPage` のレンダリングテスト

観点:

* デフォルトで "全て" タブがアクティブであること
* ダミーポストのタイトルが画面に表示されること

ファイル例:

* `src/components/board/BoardTop/__tests__/BoardTopPage.test.tsx`

---

## 7. 受け入れ条件

このタスクを完了とみなす条件:

1. `npm run lint` / `npm run test` がエラーなく通ること
2. `npm run dev` で起動し、ブラウザから `/board` を開いて以下が確認できること

   * ヘッダー下に「掲示板」タイトルと 3 つのタブが表示される
   * ダミーポストカードが 1 件以上表示される
   * タブ切替で選択状態が変わる（ダミーデータは絞り込まなくてよい）
   * 新規投稿ボタン押下で `/board/new` に遷移する
3. 翻訳/TTS/ページネーションは UI 要素が存在する必要はない（今回スコープ外）

---

## 8. CodeAgent_Report 要件

Windsurf 実行後、次の形式でレポートを作成し、所定パスに保存すること。

* 保存先: `/01_docs/06_品質チェック/CodeAgent_Report_B01-BoardTop_v1.0.md`
* 必須項目:

  * `[CodeAgent_Report]` ブロック
  * `agent_name: Windsurf`
  * `attempt_count`（実行試行回数）
  * `self_score_overall`（10点満点自己評価）
  * 変更したファイルパス一覧
  * 実装上のメモ（懸念点・TODO があれば記載）

この指示書のスコープから外れる改善提案がある場合は、レポートの「Suggestions」欄に記載するだけとし、実装には含めないこと。
