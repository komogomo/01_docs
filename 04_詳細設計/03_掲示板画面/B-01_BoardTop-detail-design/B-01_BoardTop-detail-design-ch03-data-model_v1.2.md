# B-01 BoardTop 詳細設計書 ch03 データモデル・入出力仕様 v1.2

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH03
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-24
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 3.1 本章の目的

本章では、掲示板 TOP 画面コンポーネント **BoardTop（B-01）** が利用する **データモデル** と **入出力仕様** を定義する。
DB スキーマは `schema.prisma` を唯一の正とし、その上に立つフロントエンド側の DTO（一覧表示用データ構造）と、投稿一覧取得・絞り込み条件などを明文化する。

BoardTop は、掲示板詳細（B-02）や投稿フォーム（B-03）と異なり、**1 件の投稿をすべて表示するのではなく、「一覧カード」として必要なサマリ情報を表示する画面**である。
本文全文や PDF プレビューは BoardDetail 側の責務とし、BoardTop では要約・翻訳済みサマリ・読上げボタンなど、一覧に必要な情報のみに絞って扱う。

翻訳および TTS については、B-04 BoardTranslationAndTtsService により投稿時にキャッシュされた結果を利用し、**一覧表示時はキャッシュ済みの翻訳結果を表示することを基本とする**。
キャッシュが存在しない場合に限り、投稿単位で翻訳を再実行する UI（翻訳ボタン）を提供する。

本 v1.2 では、HOME 画面およびフッターからの遷移仕様に合わせ、BoardTop の絞り込み条件を「カテゴリタブ（タグ）のみ」に整理し、`scope` 関連の入出力項目を削除した。

---

## 3.2 関連テーブルと関係

### 3.2.1 参照テーブル一覧

BoardTop が直接または間接的に参照する主なテーブルは次の通りとする。

* `board_posts`（掲示板投稿本体）
* `board_categories`（カテゴリ情報）
* `board_attachments`（添付ファイル）
* 翻訳/TTS キャッシュ関連テーブル

  * `board_post_translations`（投稿本文の翻訳キャッシュ）
  * 必要に応じて TTS 用キャッシュ（詳細は B-04 を参照）
* `users`（投稿者情報）

BoardTop は一覧表示用の API を介して、これらのテーブルに基づいたサマリ情報を取得する。
テーブル・カラム定義そのものは `schema.prisma` を参照し、本章では BoardTop がどのような目的でどの項目を利用するかのみを記載する。

### 3.2.2 `board_posts`（掲示板投稿）

* 一覧表示に利用する主なカラム（論理イメージ）

  * `id`: 投稿 ID
  * `tenant_id`: テナント ID
  * `category_id`: カテゴリ ID
  * `title`: タイトル
  * `content`: 本文（日本語原文）
  * `author_id`: 投稿者ユーザ ID
  * `created_at`: 投稿日時
  * `updated_at`: 更新日時
  * `status`: 投稿ステータス（`published` のみ対象）

BoardTop は `status = 'published'` の投稿のみを一覧対象とし、`content` の一部をサマリとして使用する。
回覧板・既読状態などの詳細表現は BoardDetail 側の責務とし、本画面では必要に応じて「回覧板アイコン」程度の簡易表示に留める。

### 3.2.3 `board_post_translations`（投稿翻訳キャッシュ）

* 一覧表示に利用する主なカラム（論理イメージ）

  * `id`
  * `post_id`: 対象投稿 ID（`board_posts.id`）
  * `base_language`: 原文言語コード
  * `target_language`: 翻訳先言語コード
  * `translated_content`: 翻訳済み本文テキスト
  * `created_at` / `updated_at`

BoardTop は、現在の UI 言語（LanguageSwitch の選択言語）に応じて、`target_language` に一致する翻訳キャッシュを参照する。
翻訳キャッシュが存在する場合、本文サマリは翻訳済みテキストから生成する。
翻訳キャッシュが存在しない場合は、日本語原文サマリを表示し、「翻訳」ボタンを表示する（詳細は ch05）。

### 3.2.4 添付・ユーザ情報

* 添付ファイルは `board_attachments` の存在有無のみを一覧に表示する（クリップアイコンなど）。
* 投稿者表示名・ロールラベルは B-03 BoardPostForm の表示名モード仕様に従い、表示名・種別ラベルを DTO として受け取る。
  BoardTop 自身は表示名ロジックを持たず、B-03 で定義された規則に沿った値を表示するのみとする。

---

## 3.3 BoardTop 表示用 DTO 定義

BoardTop では、一覧表示に必要な情報のみをまとめたサマリ DTO を利用する。

### 3.3.1 投稿サマリ DTO（`BoardPostSummary`）

```ts
export type BoardPostSummary = {
  id: string;                 // board_posts.id
  tenantId: string;           // board_posts.tenant_id

  categoryId: string;         // board_posts.category_id
  categoryKey: string;        // board_categories.category_key
  categoryName: string;       // board_categories.category_name

  title: string;              // board_posts.title

  // 本文サマリ（原文/翻訳は currentLanguage に応じて解釈）
  contentPreview: string;     // 一覧用サマリテキスト

  // 翻訳関連
  baseLanguage: string;       // 原文言語コード（例: "ja"）
  currentLanguage: string;    // 現在の UI 言語コード（例: "ja" / "en" / "zh"）
  hasTranslation: boolean;    // currentLanguage に対応する翻訳キャッシュが存在するか
  translatedPreview?: string; // 翻訳済みサマリ（hasTranslation=true の場合に利用）

  // TTS 関連
  isTtsAvailable: boolean;    // currentLanguage での TTS が利用可能か

  // 投稿者表示
  authorDisplayName: string;  // 表示名（B-03 の表示名モード適用後）
  authorDisplayType: string;  // 管理組合 / 一般利用者 等のラベル

  createdAt: string;          // 投稿日時（ISO 文字列）
  updatedAt: string;          // 更新日時（ISO 文字列）

  // 添付の有無
  hasAttachment: boolean;     // 添付ファイルが存在するか
};
```

`contentPreview` と `translatedPreview` は、実装上は同一フィールドに統合してもよいが、設計上は「原文サマリ」と「翻訳済みサマリ」を明示的に区別できるようにしている。
UI 側では `currentLanguage` と `hasTranslation` を見て、どちらを表示するかを決定する。

### 3.3.2 画面全体のレスポンス DTO（`BoardTopPageData`）

```ts
export type BoardTopPageData = {
  posts: BoardPostSummary[];  // 一覧に表示する投稿サマリ配列

  // フィルタ／タブの状態
  activeTab: "all" | "notice" | "rules"; // 現在のカテゴリタブ

  // 利用者権限
  viewerRole: string;         // 共通ロール定義（例: "admin" / "user"）
  canPost: boolean;           // 新規投稿ボタンを表示できるか
};
```

`activeTab` の値は、BoardTop ch02 / ch04 で定義したタブ仕様に従う。
`canPost` は、BoardPostForm（B-03）に遷移可能かどうかの判定結果として使用する。

---

## 3.4 入力条件と一覧取得条件

### 3.4.1 入力パラメータ（論理レベル）

```ts
export type BoardTopQueryInput = {
  tenantId: string;           // 認証コンテキストから取得
  userId: string;             // 認証コンテキストから取得
  viewerRole: string;         // 共通ロール定義（例: "admin" / "user"）

  // カテゴリタブ（BoardTop 内部状態と 1:1 対応）
  tab: "all" | "notice" | "rules";

  currentLanguage: string;    // 現在の UI 言語コード（例: "ja" / "en" / "zh"）
};
```

### 3.4.2 投稿一覧の取得条件

* 基本 WHERE 条件（論理）

  * `tenant_id = :tenantId`
  * `status = 'published'`

* タブ切替に応じたカテゴリ絞り込み

  * `tab = "all"`      : 追加条件なし（すべてのカテゴリ）
  * `tab = "notice"`   : `category_key = 'notice'` など、カテゴリキーに応じた条件を追加
  * `tab = "rules"`    : `category_key = 'rules'` など、カテゴリキーに応じた条件を追加

カテゴリキーとタブの対応関係は掲示板基本設計書およびカテゴリマスタ (`board_categories`) の定義に従う。
実装上は `category_id` ではなく `category_key` ベースで条件を記述した方が読みやすい場合は、そのように実装してよい。

### 3.4.3 翻訳キャッシュの取得

* `board_post_translations` から、以下の条件で翻訳キャッシュを取得する。

  * `post_id IN (:postIds)` かつ `target_language = :currentLanguage`

* 取得した翻訳キャッシュを `BoardPostSummary` にマージし、

  * 対応するレコードが存在する場合:

    * `hasTranslation = true`
    * `translatedPreview` に翻訳済み本文のサマリを格納
  * 存在しない場合:

    * `hasTranslation = false`
    * `contentPreview` のみを使用

翻訳キャッシュは投稿時 or 翻訳要求時に B-04 により生成される前提とし、BoardTop 側ではキャッシュの有無を判定するのみとする。
キャッシュが存在しない場合に翻訳ボタンを表示し、押下時に B-04 を呼び出してキャッシュ登録を行う（詳細は ch05）。

### 3.4.4 TTS 利用可否

TTS の利用可否は、技術スタックおよび B-04 の仕様に従い、少なくとも以下を前提とする。

* TTS 対応言語のみ `isTtsAvailable = true` とする（例: `ja`, `en`, `zh`）。
* 対応言語以外では TTS ボタンを表示しない。

実際の対応言語リストは B-04 側で管理し、BoardTop のデータ生成時に `isTtsAvailable` を判定した状態で DTO にセットする。

---

## 3.5 エラー・空状態のデータ仕様

### 3.5.1 投稿が 0 件の場合

* 条件

  * 上記条件で取得された `posts` が空配列。

* BoardTop 側の扱い

  * `BoardTopPageData.posts` を空配列とし、UI 側で「投稿がありません」メッセージを表示する（ch05 参照）。

### 3.5.2 翻訳キャッシュ取得エラー

* 条件

  * `board_post_translations` へのアクセスに失敗した場合。

* BoardTop 側の扱い

  * 原文サマリ（`contentPreview`）のみを使用して一覧表示を継続する。
  * `hasTranslation = false` とし、必要に応じて翻訳ボタンを表示する。
  * 翻訳キャッシュ取得エラー自体は Logger 側で記録し、ユーザには表示しない（BoardTop の UX を優先）。

---

## 3.6 データモデル変更時の取り扱い

掲示板機能のデータモデル（`schema.prisma`）に変更が入る場合は、必ず次の順序で整合を取る。

1. DB 差分設計および掲示板基本設計（board-design-ch0x 系）を更新する。
2. B-03 BoardPostForm および B-04 BoardTranslationAndTtsService 詳細設計を最新仕様に合わせて更新する。
3. その上で、本章（B-01 ch03）に反映すべき項目を洗い出し、DTO・条件式・エラー仕様を更新する。

本章 v1.2 は、現時点の `schema.prisma` と B-03/B-04 詳細設計、および BoardDetail（B-02）の翻訳/TTS 仕様に整合する形で定義されている。
一覧表示仕様や翻訳/TTS の扱いに変更が入った場合は、本章のバージョンを 1.3 以降に引き上げて差分を明示する。
