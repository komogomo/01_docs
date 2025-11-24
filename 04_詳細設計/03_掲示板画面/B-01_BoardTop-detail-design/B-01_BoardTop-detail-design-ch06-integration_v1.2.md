# B-01 BoardTop 詳細設計書 ch06 結合・依存関係 v1.2

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH06
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-24
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 6.1 本章の目的

本章では、BoardTop コンポーネント（B-01）が他の共通部品・画面・サービス層とどのように結合するかを定義する。
対象はフロントエンド内の結合関係に限定し、DB スキーマや Supabase 設定そのものは他設計書に委ねる。

BoardTop は、掲示板機能の「TOP 一覧画面」として、以下の役割を持つ。

* 投稿一覧の取得・表示
* **カテゴリタブ（タグ）による絞り込み**
* 新規投稿画面（B-03 BoardPostForm）への入口
* 翻訳キャッシュ済みサマリの表示、およびキャッシュ未取得時の翻訳要求
* 読み上げ（TTS）のトリガ

投稿の作成・編集・削除・AI モデレーションのロジックは B-03 BoardPostForm および API 側の責務とし、BoardTop では持たない。

本 v1.2 では、HOME 画面およびフッターからの遷移仕様に合わせ、BoardTop の絞り込みを「カテゴリタブ（全て／お知らせ／運用ルール）のみ」に整理し、`scope` 関連の記述を削除した。

---

## 6.2 結合対象一覧

v1.1 から翻訳/TTS サービスを明示し、ロールの扱いを共通仕様に合わせて整理する。

| 種別      | コンポーネント / 機能名                        | 詳細設計書 / 参照元                   | BoardTop 側の扱い                 |
| ------- | ------------------------------------ | ----------------------------- | ----------------------------- |
| 共通レイアウト | AppHeader (C-01)                     | AppHeader 詳細設計書 ch02/03       | 画面上部に常時表示（read-only）          |
| 共通レイアウト | AppFooter (C-02)                     | AppFooter 詳細設計書 ch02/03       | 画面下部に常時表示（read-only）          |
| 共通部品    | LanguageSwitch (C-03)                | LanguageSwitch 詳細設計書 ch02     | RootLayout 配下で利用              |
| 共通部品    | StaticI18nProvider (C-04)            | StaticI18nProvider 詳細設計書 ch03 | `t()` による文言取得のみ               |
| 認証基盤    | Supabase Auth + MagicLink            | Login 関連基本設計 / 詳細設計           | `tenantId` / `userId` / ロール供給 |
| データアクセス | BoardTopDataService                  | 本詳細設計 ch03 / 共通データアクセス設計      | `fetchBoardTopPage` による一覧取得   |
| 翻訳/TTS  | BoardTranslationAndTtsService (B-04) | B-04 詳細設計 ch02〜ch04           | 翻訳ボタン／TTS ボタンから呼び出し           |
| ログ      | 共通 Logger                            | 共通 Logger 詳細設計書               | fetch start/success/error を記録 |

BoardTop 自身は、上記コンポーネント・機能を **参照のみ** とし、API や仕様を変更しない。

---

## 6.3 レイアウトとの結合

### 6.3.1 RootLayout との関係

* BoardTop は、`app/(tenant)/board/page.tsx`（仮）内でレンダリングされ、RootLayout から提供される以下の要素の内側に配置される。

  * AppHeader
  * AppFooter
  * StaticI18nProvider
  * 認証コンテキスト（現在ユーザ・tenantId・viewerRole 等）

* BoardTop の実装では、これら共通部品を直接 import せず、Layout から渡される props / context に依存する。

### 6.3.2 認証との結合

* BoardTop へのアクセス前に MagicLink 認証が完了している前提。未認証の場合のリダイレクトは Layout またはルーティング層の責務とする。
* BoardTop は props として、少なくとも以下を受け取る想定とする。

  * `tenantId: string`
  * `userId: string`
  * `viewerRole: string`   // 共通ロール定義（例: "management" / "resident" 等）
  * `canPost: boolean`

これらは、BoardTop 内部では書き換えず、UI 制御（新規投稿ボタン表示など）とロギングのみに利用する。

---

## 6.4 データアクセスとの結合

### 6.4.1 一覧取得フロー

* BoardTop は、共通データアクセス層の関数またはフック（例: `useBoardTopQuery`）を利用して投稿一覧を取得する。
* BoardTop 内で直接 Supabase クライアントのインスタンス生成や SQL 文を記述しない方針とする（実装上やむを得ない場合は、共通層の設計と整合させる）。

### 6.4.2 共通データアクセス API（論理イメージ）

```ts
export type BoardTopQueryInput = {
  tenantId: string;
  userId: string;
  viewerRole: string;

  // カテゴリタブ（BoardTop 内部状態と 1:1 対応）
  tab: "all" | "notice" | "rules";

  currentLanguage: string;
};

export async function fetchBoardTopPage(
  input: BoardTopQueryInput
): Promise<BoardTopPageData> {
  // 実装は共通データアクセス層で定義
}
```

* `BoardTopQueryInput` / `BoardTopPageData` は ch03 で定義した DTO を参照する。
* BoardTop 側は、`fetchBoardTopPage` を呼び出し、成功時/失敗時の状態遷移（`FETCH_SUCCEEDED` / `FETCH_FAILED`）のみを実装する。

翻訳キャッシュの取得は、`fetchBoardTopPage` の内部で `board_post_translations` を参照する形で行い、BoardTop からは意識しない。
キャッシュが存在しない場合に限り、投稿カード単位で翻訳ボタンから B-04 を呼び出す（ch05 参照）。

---

## 6.5 翻訳/TTS サービスとの結合

### 6.5.1 翻訳ボタンからの呼び出し

* 各投稿カードの「翻訳」ボタン押下時に、B-04 BoardTranslationAndTtsService を呼び出す。
* 論理的な I/F 例:

```ts
requestBoardPostTranslation({
  tenantId,
  postId,
  targetLanguage: currentLanguage,
}): Promise<void>;
```

* 成功時には翻訳キャッシュが更新され、`fetchBoardTopPage` の再取得、またはローカル状態更新により、
  `hasTranslation = true` / `translatedPreview` 反映済みの `BoardPostSummary` がカードに反映される。
* 失敗時には、BoardTop 側で控えめなエラーメッセージ（`board.top.i18n.error` 等）を表示し、原文サマリ表示を継続する。

### 6.5.2 TTS ボタンからの呼び出し

* 各投稿カードの TTS ボタン押下時に、B-04 経由で読み上げ処理を呼び出す。
* 読み上げ対象テキストは、`currentLanguage` と `hasTranslation` に応じて前段で決定（翻訳済みサマリ or 原文サマリ）。
* B-04 側で TTS の実行・停止・エラー処理を行い、BoardTop は

  * 再生中/停止中のボタン状態
  * エラー発生時のメッセージ表示

  のみを担当する。

---

## 6.6 画面遷移との結合

### 6.6.1 HOME から BoardTop / BoardDetail への遷移

HOME 画面から掲示板関連画面へ遷移する際の仕様を次の通りとする。

1. **機能メニュー「掲示板」**

   * 遷移先: `/board`
   * 初期タブ: `all`（すべて）

2. **機能メニュー「お知らせ」**

   * 遷移先: `/board?tab=notice`
   * 初期タブ: `notice`（お知らせ）

3. **機能メニュー「運用ルール」**

   * 遷移先: `/board?tab=rules`
   * 初期タブ: `rules`（運用ルール）

4. **「最新のお知らせ」カード（HOME 内の最新3件）**

   * 対象: 管理組合からの投稿かつ「お知らせ」カテゴリ、過去60日以内の最新3件。
   * 各カード押下時の遷移先: `/board/[postId]?tab=notice`
   * BoardTop は経由せず、直接 BoardDetail（B-02）を表示する。

HOME 側のリンクは上記 URL を使用し、BoardTop / BoardDetail は受け取った `tab` パラメータに応じて初期状態を構成する。

### 6.6.2 フッターから BoardTop への遷移

* フッターの「掲示板」タブ（ショートカット）押下時:

  * 遷移先: `/board`
  * 初期タブ: `all`

### 6.6.3 BoardTop から BoardDetail への遷移

* `BoardPostSummaryCard` のクリック／タップ時に、投稿詳細画面 `/board/[postId]` へ遷移する。
* 遷移方法は Next.js App Router の `Link` コンポーネントまたは `router.push` を利用する。
* URL パラメータ:

  * `/board/[postId]`

BoardDetail 側では、`postId` を元に `board_posts` および関連テーブルから詳細情報を取得する。BoardTop からはサマリ情報のみを渡し、詳細情報のキャリーは行わない。

### 6.6.4 BoardTop から BoardPostForm への遷移（新規投稿）

* 新規投稿ボタン押下時に、B-03 BoardPostForm へ遷移する。

  * 遷移先例: `/board/new`

* 遷移先 URL は B-03 詳細設計およびルーティング設計に従う。

---

## 6.7 ログ出力との結合

* BoardTop 実装では、以下のポイントで共通 Logger を呼び出す。

  * 一覧取得開始 (`FETCH_STARTED` 発行時): `board.top.fetch.start`
  * 一覧取得成功 (`FETCH_SUCCEEDED` 処理内): `board.top.fetch.success`
  * 一覧取得失敗 (`FETCH_FAILED` 処理内): `board.top.fetch.error`

* 翻訳/TTS エラーについては、必要に応じて以下のようなイベントを追加する。

  * 翻訳失敗: `board.top.translation.error`
  * TTS 失敗: `board.top.tts.error`

Logger の API 仕様・出力先は共通 Logger 詳細設計書に従い、BoardTop からは event 名と context のみを指定する。

---

## 6.8 Windsurf 実装時の制約

1. BoardTop 実装では、AppHeader/AppFooter/LanguageSwitch/StaticI18nProvider の API や props 仕様を変更しないこと（read-only）。
2. 認証・ロール判定・tenantId の取得ロジックは BoardTop 内に書かず、Layout または共通フックから渡される値をそのまま利用すること。
3. Supabase クライアントの設定値（URL, anon key 等）や `schema.prisma` の内容は Windsurf の変更対象外とすること。
4. 画面遷移のパス（`/board`, `/board/[postId]`, `/board/new`）は基本設計と整合させ、勝手に変更しないこと。
5. 翻訳/TTS の実装詳細は B-04 の仕様に従い、BoardTop 側で独自の翻訳/TTS ロジックを持たないこと。
6. 本章で定義した `BoardTopQueryInput.tab` / URL クエリ `tab` / ch04 の `BoardTopState.tab` の値集合（`all` / `notice` / `rules`）を一致させること。
