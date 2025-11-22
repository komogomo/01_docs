# B-01 BoardTop 詳細設計書 ch06 結合・依存関係 v1.0

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH06
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 6.1 本章の目的

本章では、BoardTop コンポーネント（B-01）が他の共通部品・画面・インフラ層とどのように結合するかを定義する。
対象はフロントエンド内の結合関係に限定し、DB スキーマや Supabase 設定そのものは他設計書に委ねる。

---

## 6.2 結合対象一覧

| 種別      | コンポーネント / 機能名             | 詳細設計書 / 参照元                   | BoardTop 側の扱い                 |
| ------- | ------------------------- | ----------------------------- | ----------------------------- |
| 共通レイアウト | AppHeader (C-01)          | AppHeader 詳細設計書 ch02/03       | 画面上部に常時表示（read-only）          |
| 共通レイアウト | AppFooter (C-02)          | AppFooter 詳細設計書 ch02/03       | 画面下部に常時表示（read-only）          |
| 共通部品    | LanguageSwitch (C-03)     | LanguageSwitch 詳細設計書 ch02     | RootLayout 配下で利用              |
| 共通部品    | StaticI18nProvider (C-04) | StaticI18nProvider 詳細設計書 ch03 | `t()` による文言取得のみ               |
| 認証基盤    | Supabase Auth + MagicLink | Login 関連基本設計 / 詳細設計           | `tenantId`/`userId`/ロール供給     |
| データアクセス | Supabase クライアント           | 技術スタック定義 / 共通データアクセス設計        | `board_posts` 一覧取得            |
| ログ      | 共通 Logger                 | 共通 Logger 詳細設計書               | fetch start/success/error を記録 |

BoardTop 自身は、上記コンポーネント・機能を **参照のみ** とし、API や仕様を変更しない。

---

## 6.3 レイアウトとの結合

### 6.3.1 RootLayout との関係

* BoardTop は、`app/(tenant)/board/page.tsx`（仮）内でレンダリングされ、RootLayout から提供される以下の要素の内側に配置される。

  * AppHeader
  * AppFooter
  * StaticI18nProvider
  * 認証コンテキスト（現在ユーザ・tenantId・viewerRole 等）

BoardTop の実装では、これら共通部品を直接 import せず、Layout から渡される props / context に依存する。

### 6.3.2 認証との結合

* BoardTop へのアクセス前に、MagicLink 認証が完了している前提。未認証の場合のリダイレクトは Layout またはルーティング層の責務とする。
* BoardTop は props として、少なくとも以下を受け取る想定とする。

  * `tenantId: string`
  * `userId: string`
  * `viewerRole: "admin" | "user"`
  * `canPost: boolean`

これらは、BoardTop 内部では書き換えず、UI 制御（新規投稿ボタン表示など）とロギングのみに利用する。

---

## 6.4 データアクセスとの結合

### 6.4.1 一覧取得フロー

* BoardTop は、共通データアクセス層の関数またはフック（例: `useBoardPostsQuery`）を利用して投稿一覧を取得する。
* BoardTop 内で直接 Supabase クライアントのインスタンス生成や SQL 文を記述しない方針とする（実装上やむを得ない場合は、共通層の設計と整合させる）。

### 6.4.2 共通データアクセス API（論理イメージ）

```ts
// BoardTop から利用するデータ取得 API の論理イメージ
export async function fetchBoardTopPage(
  input: BoardTopQueryInput
): Promise<BoardPostSummaryPage> {
  // 実装は共通データアクセス層で定義
}
```

* `BoardTopQueryInput` / `BoardPostSummaryPage` は ch03 で定義した DTO を参照する。
* BoardTop 側は、`fetchBoardTopPage` を呼び出し、成功時/失敗時の状態遷移（`FETCH_SUCCEEDED` / `FETCH_FAILED`）のみを実装する。

---

## 6.5 画面遷移との結合

### 6.5.1 HOME から BoardTop への遷移

* HOME 画面の「掲示板」カードまたはメニューから、`/board` への遷移リンクを提供する。
* 遷移時に特定タブ・範囲を指定したい場合は、URL クエリを付与する。

  * 例: 重要なお知らせタブを開いた状態: `/board?tab=notice`

### 6.5.2 BoardTop から BoardDetail への遷移

* `BoardPostSummaryCard` のクリック／タップ時に、投稿詳細画面 `/board/[id]` へ遷移する。
* 遷移方法は Next.js App Router の `Link` コンポーネントまたは `router.push` を利用する。
* URL パラメータ:

  * `/board/[postId]`

BoardDetail 側では、`postId` を元に `board_posts` および関連テーブルから詳細情報を取得する。BoardTop からはサマリ情報のみを渡し、詳細情報のキャリーは行わない。

---

## 6.6 ログ出力との結合

* ログ出力仕様は ch04 `4.7 ログ出力仕様` に従う。
* BoardTop 実装では、以下のポイントで共通 Logger を呼び出す。

  * 一覧取得開始 (`FETCH_STARTED` 発行時)
  * 一覧取得成功 (`FETCH_SUCCEEDED` 処理内)
  * 一覧取得失敗 (`FETCH_FAILED` 処理内)
* Logger の API 仕様・出力先は共通 Logger 詳細設計書に従い、BoardTop からは event 名と context のみを指定する。

---

## 6.7 Windsurf 実装時の制約

1. BoardTop 実装では、AppHeader/AppFooter/LanguageSwitch/StaticI18nProvider の API や props 仕様を変更しないこと（read-only）。
2. 認証・ロール判定・tenantId の取得ロジックは BoardTop 内に書かず、Layout または共通フックから渡される値をそのまま利用すること。
3. Supabase クライアントの設定値（URL, anon key 等）や `schema.prisma` の内容は Windsurf の変更対象外とすること。
4. 画面遷移のパス（`/board`, `/board/[id]`）は基本設計と整合させ、勝手に変更しないこと。
