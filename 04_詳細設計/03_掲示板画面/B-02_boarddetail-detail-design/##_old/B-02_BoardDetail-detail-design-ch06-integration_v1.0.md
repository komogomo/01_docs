# B-02 BoardDetail 詳細設計書 ch06 結合・依存関係 v1.0

**Document ID:** HARMONET-COMPONENT-B02-BOARDDETAIL-DETAIL-CH06
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 6.1 本章の目的

本章では、BoardDetail コンポーネント（B-02）が他の共通部品・画面・インフラ層とどのように結合するかを定義する。
対象はフロントエンド内の結合関係に限定し、DB スキーマや Supabase 設定そのものは他設計書に委ねる。

---

## 6.2 結合対象一覧

| 種別      | コンポーネント / 機能名             | 詳細設計書 / 参照元                 | BoardDetail 側の扱い                    |
| ------- | ------------------------- | --------------------------- | ----------------------------------- |
| 共通レイアウト | AppHeader (C-01)          | AppHeader 詳細設計書             | 画面上部に常時表示（read-only）                |
| 共通レイアウト | AppFooter (C-02)          | AppFooter 詳細設計書             | 画面下部に常時表示（read-only）                |
| 共通部品    | LanguageSwitch (C-03)     | LanguageSwitch 詳細設計書        | RootLayout 配下で利用                    |
| 共通部品    | StaticI18nProvider (C-04) | StaticI18nProvider 詳細設計書    | `t()` による文言取得のみ                     |
| 認証基盤    | Supabase Auth + MagicLink | Login 関連基本設計 / 詳細設計         | `tenantId` / `userId` / ロール供給       |
| データアクセス | 掲示板データ取得 API              | 共通データアクセス設計（board 系）        | 投稿詳細・コメント・添付の取得                     |
| 共通機能    | 翻訳/TTS 共通コンポーネント          | 共通翻訳/TTS 詳細設計書              | 翻訳/TTS 処理を委譲                        |
| 共通機能    | PDF ビューア（PDF.js ラッパー）     | 掲示板共通 PDF プレビュー仕様           | PDF プレビュー表示を委譲                      |
| ログ      | 共通 Logger                 | 共通 Logger 詳細設計書             | fetch/comment/translation/TTS のログ出力 |
| 他画面     | BoardTop (B-01)           | B-01 BoardTop 詳細設計          | 一覧画面からの遷移元                          |
| 他画面     | BoardPostForm (B-03)（予定）  | B-03 BoardPostForm 詳細設計（予定） | 返信・編集などの遷移先（将来）                     |

BoardDetail 自身は、上記コンポーネント・機能を **参照のみ** とし、API や仕様を変更しない。

---

## 6.3 レイアウトとの結合

### 6.3.1 RootLayout との関係

* BoardDetail は、`app/(tenant)/board/[postId]/page.tsx`（仮）内でレンダリングされ、RootLayout から提供される以下の要素の内側に配置される。

  * AppHeader
  * AppFooter
  * StaticI18nProvider
  * 認証コンテキスト（現在ユーザ・tenantId・viewerRole 等）

BoardDetail の実装では、これら共通部品を直接 import せず、Layout から渡される props / context に依存する。

### 6.3.2 認証との結合

* BoardDetail へのアクセス前に、MagicLink 認証が完了している前提。未認証の場合のリダイレクトは Layout またはルーティング層の責務とする。
* BoardDetail は props または context として、少なくとも以下を受け取る想定とする。

  * `tenantId: string`
  * `userId: string`
  * `viewerRole: "admin" | "user"`
  * `canPostComment: boolean`

これらは BoardDetail 内部では書き換えず、UI 制御（コメント投稿欄の表示など）とロギングのみに利用する。

---

## 6.4 データアクセスとの結合

### 6.4.1 詳細取得フロー

* BoardDetail は、共通データアクセス層の関数またはフック（例: `fetchBoardDetailPage`）を利用して投稿詳細・コメント・添付・翻訳/TTS 状態を取得する。
* BoardDetail 内で直接 Supabase クライアントのインスタンス生成や SQL 文を記述しない方針とする（実装上やむを得ない場合は、共通層の設計と整合させる）。

### 6.4.2 共通データアクセス API（論理イメージ）

```ts
// BoardDetail から利用するデータ取得 API の論理イメージ
export async function fetchBoardDetailPage(
  input: BoardDetailQueryInput
): Promise<BoardDetailPageData> {
  // 実装は共通データアクセス層で定義
}
```

* `BoardDetailQueryInput` / `BoardDetailPageData` は ch03 で定義した DTO を参照する。
* BoardDetail 側は、`fetchBoardDetailPage` を呼び出し、成功時/失敗時の状態遷移（`FETCH_SUCCEEDED` / `FETCH_FAILED`）のみを実装する。

### 6.4.3 コメント投稿 API との結合

* コメント投稿は、BoardDetail から共通 API（例: `postBoardComment`）を呼び出して行う。
* API の論理イメージ:

```ts
export async function postBoardComment(input: {
  tenantId: string;
  postId: string;
  userId: string;
  content: string;
}): Promise<BoardCommentItem> {
  // 実装は共通データアクセス層で定義
}
```

* BoardDetail は、`COMMENT_SUBMIT_REQUESTED` イベント発生時にこの API を呼び出し、成功時に返却された `BoardCommentItem` を `comments` に追加する。

---

## 6.5 画面遷移との結合

### 6.5.1 BoardTop から BoardDetail への遷移

* BoardTop（B-01）のカードタップにより、`/board/[postId]` への遷移が行われる。
* BoardDetail 側では、URL パラメータ `[postId]` を受け取り、該当する投稿詳細を取得する。

### 6.5.2 BoardDetail から BoardTop への戻り

* BoardDetailFooter の「掲示板に戻る」ボタン押下で `/board` へ遷移する。
* タブ・範囲・ページ番号などの復元は、初版ではシンプルに「BoardTop のデフォルト状態に戻る」前提とする。必要に応じて、クエリパラメータやナビゲーション状態を持ち回る設計は後続で拡張する。

### 6.5.3 BoardDetail から他画面への遷移（将来）

* 返信/編集機能などで投稿フォーム（B-03 BoardPostForm）に遷移する場合は、別途 B-03 詳細設計でルーティングパターンを定義する。

---

## 6.6 翻訳/TTS・PDF プレビューとの結合

### 6.6.1 翻訳/TTS 共通コンポーネント

* BoardDetail は、翻訳/TTS 共通コンポーネントまたはフック（例: `useTranslationTts`）を利用して、翻訳/TTS 処理を行う。
* 結合イメージ:

  * `TRANSLATION_REQUESTED` → 共通フックの `translate(content, targetLanguage)` 呼び出し
  * `TTS_PLAY_REQUESTED` → 共通フックの `playTts(text, targetLanguage)` 呼び出し
* 共通フックから返却される状態（処理中/成功/失敗）は、ch04 で定義した `BoardPostI18nState` にマッピングする。

### 6.6.2 PDF ビューアとの結合

* BoardDetail は、添付セクションから PDF ビューアコンポーネント（例: `PdfViewer`）をラップした `BoardDetailPdfPreviewModal` を呼び出す。
* `PdfViewer` コンポーネントの props 例:

```tsx
<PdfViewer fileUrl={attachment.fileUrl} />
```

* PDF ビューアコンポーネント自体の実装（Zoom/ページ送り等）は共通仕様に委ね、BoardDetail は「どのファイルを開くか」と「モーダルの開閉」のみ制御する。

---

## 6.7 ログ出力との結合

* ログ出力仕様は ch04 `4.6 ログ出力仕様` に従う。
* BoardDetail 実装では、以下のポイントで共通 Logger を呼び出す。

  * 詳細取得開始 (`FETCH_STARTED` 発行時)
  * 詳細取得成功 (`FETCH_SUCCEEDED` 処理内)
  * 詳細取得失敗 (`FETCH_FAILED` 処理内)
  * コメント送信成功/失敗
  * 翻訳エラー
  * TTS エラー
* Logger の API 仕様・出力先は共通 Logger 詳細設計書に従い、BoardDetail からは event 名と context のみを指定する。

---

## 6.8 Windsurf 実装時の制約

1. BoardDetail 実装では、AppHeader/AppFooter/LanguageSwitch/StaticI18nProvider の API や props 仕様を変更しないこと（read-only）。
2. 認証・ロール判定・tenantId の取得ロジックは BoardDetail 内に書かず、Layout または共通フックから渡される値をそのまま利用すること。
3. Supabase クライアントの設定値（URL, anon key 等）や `schema.prisma` の内容は Windsurf の変更対象外とすること。
4. 画面遷移のパス（`/board/[postId]`, `/board`）は基本設計と整合させ、勝手に変更しないこと。
5. 翻訳/TTS や PDF ビューアの共通コンポーネント/API を改変せず、指定されたインターフェースを利用すること。
