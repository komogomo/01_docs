# B-01 BoardTop 詳細設計書 ch04 状態管理・イベント遷移 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH04
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 4.1 本章の目的

本章では、掲示板TOP画面コンポーネント BoardTop（B-01）における **状態管理** と **ユーザインタラクションイベント** を定義する。
対象はフロントエンドの状態のみとし、DB スキーマ（`schema.prisma`）はすでに正として確定している前提で扱う。Windsurf は本章を参照して、React コンポーネント内の `useState` / `useReducer` / カスタムフックの実装を行う。

---

## 4.2 状態モデル（State）

### 4.2.1 画面全体の状態構造

BoardTopPage が保持する状態を論理型として定義する。実際の実装では、`useState` や `useReducer` など適切な方法で管理する。

```ts
// BoardTop 画面全体の状態
export type BoardTopState = {
  // クエリ・フィルタ関連
  tab: "all" | "notice" | "rules";   // 現在選択中タブ
  scope: "all" | "global" | "group"; // 表示範囲
  page: number;                          // 現在ページ（1 起算）
  perPage: number;                       // 1ページあたり件数（10 / 20 / 50）

  // ロール・権限関連（認証コンテキストから供給される値）
  viewerRole: "admin" | "user";       // 管理組合 or 一般利用者
  canPost: boolean;                      // 新規投稿権限（管理組合ロール等から導出済み）

  // データ関連
  items: BoardPostSummary[];             // 現在ページの投稿一覧
  totalCount: number;                    // 条件に合致する総件数

  // ローディング・エラー
  isLoading: boolean;                    // 一覧取得中フラグ
  isError: boolean;                      // 一覧取得失敗フラグ

  // UI メッセージ
  lastUpdatedAt: Date | null;            // 最終取得時刻（画面上の"最終更新"表示用）
};
```

`BoardPostSummary` は ch03 で定義した DTO を参照する。
`lastUpdatedAt` は、ユーザに対して「いつの状態か」を明示するための任意項目であり、MVP で不要と判断された場合は削除可能である。

### 4.2.2 初期状態

BoardTopPage の初期状態は、URL クエリおよびアプリ共通設定に基づき次のように決定する。

* `tab`: URL クエリ `tab` が `all` / `notice` / `rules` のいずれかならその値、そうでなければ `"all"`
* `scope`: URL クエリ `scope` が `all` / `global` / `group` のいずれかならその値、そうでなければ `"all"`
* `page`: URL クエリ `page` が 1 以上の整数ならその値、そうでなければ `1`
* `perPage`: URL クエリ `perPage` が 10 / 20 / 50 のいずれかならその値、そうでなければ `20`
* `items`: `[]`（初期は空）
* `totalCount`: `0`
* `isLoading`: `true`（初期表示時に 1 回目の取得を行う想定）
* `isError`: `false`
* `lastUpdatedAt`: `null`

---

## 4.3 イベントモデル（Event）

### 4.3.1 イベント一覧

BoardTop で発生する主なイベントを次のとおり定義する。

```ts
export type BoardTopEvent =
  | { type: "INIT"; payload: { tab?: string; scope?: string; page?: string; perPage?: string } }
  | { type: "TAB_CHANGED"; payload: { tab: "all" | "notice" | "rules" } }
  | { type: "SCOPE_CHANGED"; payload: { scope: "all" | "global" | "group" } }
  | { type: "PAGE_CHANGED"; payload: { page: number } }
  | { type: "PER_PAGE_CHANGED"; payload: { perPage: number } }
  | { type: "RELOAD_REQUESTED" }
  | { type: "FETCH_STARTED" }
  | { type: "FETCH_SUCCEEDED"; payload: { items: BoardPostSummary[]; totalCount: number; fetchedAt: Date } }
  | { type: "FETCH_FAILED" };
```

ここで `INIT` は、URL クエリを受け取って初期状態を決定するためのイベントであり、Next.js App Router の `searchParams` から取得した値（string）を引数として受け取るイメージである。

### 4.3.2 イベント発生源

* `INIT`

  * BoardTopPage マウント時に 1 回だけ発生。URL クエリを読み取り、初期状態を決定する。
* `TAB_CHANGED`

  * `BoardTabBar` からのユーザ操作（タブ押下）。
* `SCOPE_CHANGED`

  * `BoardScopeFilter` からのユーザ操作（範囲切替）。
* `PAGE_CHANGED`

  * `BoardPagination` からのユーザ操作（ページ番号押下）。
* `PER_PAGE_CHANGED`

  * `BoardPagination` からのユーザ操作（件数セレクタ変更）。
* `RELOAD_REQUESTED`

  * `BoardErrorState` の「再読み込み」ボタン押下、または AppHeader 等からのリロード操作。
* `FETCH_STARTED` / `FETCH_SUCCEEDED` / `FETCH_FAILED`

  * Supabase からの一覧取得フロー内で発生する内部イベント。

---

## 4.4 状態遷移

### 4.4.1 初期化〜初回取得

1. BoardTopPage マウント時に `INIT` イベントが発行される。
2. `INIT` により URL クエリから `tab`, `scope`, `page`, `perPage` を解釈し、`BoardTopState` を初期化する。
3. 初期化完了後、`FETCH_STARTED` を発行し、`isLoading = true`, `isError = false` に設定する。
4. Supabase への一覧取得が成功した場合、`FETCH_SUCCEEDED` により:

   * `items` / `totalCount` / `lastUpdatedAt` を更新
   * `isLoading = false`, `isError = false`
5. 取得が失敗した場合、`FETCH_FAILED` により:

   * `items = []`, `totalCount = 0`
   * `isLoading = false`, `isError = true`

### 4.4.2 タブ変更時

1. ユーザが `BoardTabBar` でタブを変更する。
2. `TAB_CHANGED` イベントが発生し、`state.tab` が更新される。
3. ページ番号は 1 にリセットする（`state.page = 1`）。
4. URL クエリ `tab` / `page` を更新する（router.push 等）。
5. `FETCH_STARTED` → Supabase 取得 → `FETCH_SUCCEEDED` or `FETCH_FAILED` のフローを再実行する。

### 4.4.3 範囲変更時

1. ユーザが `BoardScopeFilter` で `scope` を変更する。
2. `SCOPE_CHANGED` イベントが発生し、`state.scope` が更新される。
3. ページ番号は 1 にリセットする。
4. URL クエリ `scope` / `page` を更新する。
5. 再度一覧取得を行う（`FETCH_STARTED` → ...）。

### 4.4.4 ページ変更時

1. ユーザが `BoardPagination` でページ番号をクリックする。
2. `PAGE_CHANGED` イベントが発生し、`state.page` が更新される。
3. URL クエリ `page` を更新する。
4. 再度一覧取得を行う。

### 4.4.5 件数変更時

1. ユーザが 1 ページあたり件数セレクタを変更する。
2. `PER_PAGE_CHANGED` イベントが発生し、`state.perPage` が更新される。
3. ページ番号は 1 にリセットする。
4. URL クエリ `perPage` / `page` を更新する。
5. 再度一覧取得を行う。

### 4.4.6 再読み込み

1. `BoardErrorState` の「再読み込み」ボタン押下、または AppHeader のリロード操作により `RELOAD_REQUESTED` イベントが発生する。
2. 現在の `tab` / `scope` / `page` / `perPage` を維持したまま、`FETCH_STARTED` → 一覧取得 → `FETCH_SUCCEEDED` or `FETCH_FAILED` を再実行する。

---

## 4.5 URL 同期ポリシー

BoardTop は、URL クエリと内部状態を常に同期させる方針とする。これにより、

* ブックマークした URL から同じ状態で復元できる
* ブラウザの「戻る」「進む」で状態遷移が自然に行える

ようにする。

### 4.5.1 同期対象

* `tab`
* `scope`
* `page`
* `perPage`

### 4.5.2 実装方針

* Next.js App Router の `useSearchParams` / `useRouter`（もしくは専用のフック）を利用し、状態更新時に URL を更新する。
* URL 更新は、画面全体再ロードを伴わないクライアントサイドナビゲーションで行う（`router.replace` など）。
* 連続操作時に URL 更新が過剰に発生しないよう、必要に応じてまとめて更新する。

---

## 4.6 状態管理実装方針（Windsurf 向けガイド）

Windsurf が実装する際のガイドラインとして、以下の方針を示す。

1. BoardTopPage 内に状態管理を閉じ込めるか、`useBoardTopState` のようなカスタムフックに切り出すかは、実装時に判断してよい。ただし、型・イベント定義は本章に準拠すること。

2. フェッチ処理は、Supabase クライアントを用いたクライアントサイド取得、または Server Components + クライアントコンポーネントの組み合わせなど、技術スタック定義書に沿った方法とする。いずれの場合も、本章で定義した状態遷移（`FETCH_STARTED` / `FETCH_SUCCEEDED` / `FETCH_FAILED`）を再現すること。

3. `isLoading` / `isError` / `items.length` の組み合わせにより、

   * ローディングスケルトン
   * 空状態
   * エラー状態
   * 通常一覧

   の出し分けを ch05 UI 仕様に従って実装する。

4. 将来、検索条件や追加フィルタ（期間、キーワードなど）が増えた場合は、`BoardTopState` / `BoardTopEvent` にフィールドを追加し、本章を v1.1 以降として更新する。既存のフィールドやイベントの破壊的変更は極力避ける。

---

## 4.7 ログ出力仕様

BoardTop におけるログ出力は、共通 Logger 詳細設計書（別文書）で定義された API（例: `logInfo`, `logError`）を利用し、以下のイベントで出力する。

### 4.7.1 ログ出力対象イベント

| タイミング                        | レベル   | event 名                     | context 例                                               |
| ---------------------------- | ----- | --------------------------- | ------------------------------------------------------- |
| 初回 / 再取得開始 (`FETCH_STARTED`) | INFO  | `"board.top.fetch.start"`   | `{ tab, scope, page, perPage, viewerRole }`             |
| 取得成功 (`FETCH_SUCCEEDED`)     | INFO  | `"board.top.fetch.success"` | `{ tab, scope, page, perPage, viewerRole, totalCount }` |
| 取得失敗 (`FETCH_FAILED`)        | ERROR | `"board.top.fetch.error"`   | `{ tab, scope, page, perPage, viewerRole, errorType }`  |

* `errorType` は、Supabase クライアントまたは共通データアクセス層で分類されたエラー種別（ネットワークエラー/認可エラー/不明エラーなど）を利用する。
* ユーザ入力操作（タブ切替・ページングなど）のログは、MVP では上記に含めず、必要になった時点で拡張する。

### 4.7.2 実装上の注意

* 実際の logger 呼び出しコードは BoardTopPage または関連フック内に実装し、各 UI コンポーネント（`BoardTabBar` 等）から直接 logger を呼び出さない。
* ログ出力の具体的な形式（JSON 構造、タイムスタンプ、出力先）は共通 Logger 詳細設計書に従う。本章では event 名と context に含めるべき項目のみを定義する。
