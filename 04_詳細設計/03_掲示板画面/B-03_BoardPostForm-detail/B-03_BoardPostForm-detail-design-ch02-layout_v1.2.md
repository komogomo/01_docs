# B-03 BoardPostForm 詳細設計書 ch02 画面構造・コンポーネント構成 v1.2

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH02
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-27
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 2.1 レイアウト全体構成

### 2.1.1 画面レイアウト概要

BoardPostForm は、掲示板投稿の作成・編集を行う単一画面フォームであり、以下の構造を共通とする。

* 画面上部：

  * AppHeader（共通部品）
  * BoardPostForm タイトル行（「掲示板に投稿」「投稿編集」など）
* メインコンテンツ：

  1. 投稿者区分・表示名セクション
  2. 投稿カテゴリ／公開範囲セクション
  3. 投稿本文入力セクション（TipTap リッチテキスト）
  4. 添付ファイルセクション
  5. 回覧板・オプションセクション
* 画面下部：

  * 送信ボタン／キャンセルボタンを含むフッター

### 2.1.2 PC レイアウト

* 幅 1024px 以上を PC とみなし、以下を前提とする。

  * メインコンテンツは中央寄せ 1 カラムレイアウト（最大幅 ~720〜800px 想定）。
  * 投稿本文エリアはタイトル／メタ情報よりも縦方向に大きな領域を確保する。
  * TipTap のツールバーは本文エリア上部に横一列で表示し、PC では「フル版」ツールバー（段落／見出し／太字／斜体／リスト／リンクなど）を使用する。

### 2.1.3 スマートフォンレイアウト

* 幅 768px 未満をスマートフォンとみなす。

  * 画面全体は縦スクロール 1 カラム構成。
  * 投稿本文エリアは初期表示で 6〜8 行程度の高さを確保し、入力中は必要に応じて伸びる。
  * TipTap のツールバーはアイコン数を絞った 1 行の簡易バーとし、太字／箇条書き／リンク程度に限定する。

---

## 2.2 メインコンテンツ構造

メインコンテンツは以下のセクション単位で構成する。

1. `BoardPostFormAuthorSection` … 投稿者区分／表示名セクション
2. `BoardPostFormCategorySection` … カテゴリ・公開範囲セクション
3. `BoardPostFormContentSection` … 投稿本文入力セクション（全ユーザ TipTap）
4. `BoardPostFormAttachmentSection` … 添付ファイルセクション
5. `BoardPostFormOptionsSection` … 回覧板・その他オプション
6. `BoardPostFormFooter` … 送信・キャンセルボタン

本章では、特に TipTap 対応の中心となる `BoardPostFormContentSection` を主に定義する。

---

## 2.3 BoardPostFormContentSection（投稿本文入力）

### 2.3.1 役割

* 全ユーザ（管理組合・一般利用者）が使用する投稿本文の入力 UI を提供するセクション。
* デバイス種別（PC / スマホ）に応じて、同一の TipTap エディタを

  * PC: フルツールバー版
  * スマホ: 簡易ツールバー版
    として出し分ける。
* 投稿区分（管理組合／一般）は本文エディタの種別には影響せず、表示スタイル・権限制御のみで扱う。

### 2.3.2 コンポーネント構成

#### (1) BoardPostFormContentSection

* **役割**

  * セクションタイトル（例：「本文」「お知らせ内容」）と TipTap エディタコンポーネントをまとめる親コンポーネント。
  * `isDesktop` に応じて Desktop / Mobile 用 TipTap コンポーネントを切り替える。

* **主な props（論理レベル）**

  * `isDesktop: boolean`
  * `content: string`        … テキスト正（プレーンテキスト）
  * `contentHtml: string | null` … リッチ用 HTML（null 可）
  * `onChangeContentHtml: (nextHtml: string) => void`
  * `validationState: { hasError: boolean; message?: string }`

* **内部構造（擬似コードイメージ）**

```tsx
if (isDesktop) {
  return (
    <section>
      <SectionHeader label="本文" />
      <ManagementPostRichEditorDesktop
        value={contentHtml ?? ""}
        onChange={onChangeContentHtml}
      />
      {validationState.hasError && <ErrorText message={validationState.message} />}
    </section>
  );
}

return (
  <section>
    <SectionHeader label="本文" />
    <ManagementPostRichEditorMobile
      value={contentHtml ?? ""}
      onChange={onChangeContentHtml}
    />
    {validationState.hasError && <ErrorText message={validationState.message} />}
  </section>
);
```

#### (2) ManagementPostRichEditorDesktop（PC 用 TipTap）

* **役割**

  * PC 向けの TipTap リッチテキスト編集 UI。管理組合・一般どちらの投稿でも共通で使用する。
  * 機能（例）：

    * 段落（Paragraph）
    * 見出し（Heading h2/h3）
    * 太字 / 斜体
    * 箇条書きリスト / 番号付きリスト
    * リンク挿入・編集

* **主な props**

  * `value: string` … 初期 HTML 文字列
  * `onChange: (nextHtml: string) => void` … `editor.getHTML()` の結果を渡す

* **補足**

  * 選択中のフォーマットをツールバーのボタン状態で示す。
  * キーボード操作でツールバーにフォーカス移動できるなど、最低限のアクセシビリティを確保する。

#### (3) ManagementPostRichEditorMobile（スマホ用 TipTap）

* **役割**

  * スマートフォン向け簡易 TipTap 編集 UI。管理組合・一般どちらの投稿でも共通で使用する。

* **機能（例）**

  * 太字
  * 箇条書きリスト
  * リンク挿入

* **主な props**

  * `value: string` … 初期 HTML 文字列
  * `onChange: (nextHtml: string) => void`

* **UI 要件**

  * ツールバーは 1 行に収まる最小限のアイコン構成とする。
  * ソフトキーボード表示時でも本文エリアが極端に狭くならないように配慮する。

---

## 2.4 BoardPostForm のその他セクション（概要）

本文以外のセクションは、v1.1 と同様の構造を維持する。TipTap 導入に伴う変更点はない（本文の型・ロジックの詳細は ch03/ch04 を参照）。

### 2.4.1 BoardPostFormAuthorSection（投稿者区分・表示名）

* 管理組合ロール／一般ロールの有無に応じて、

  * 「管理組合として投稿」「一般利用者として投稿」の選択ラジオを表示する。
  * `postAuthorRole` を決定し、カテゴリ候補や表示名の扱いに反映する。
* 表示名モード（匿名／ニックネーム）は全ユーザ共通で選択必須。

### 2.4.2 BoardPostFormCategorySection（カテゴリ・公開範囲）

* `categoryTag`／`audienceType`／`audienceGroupId` を選択するセクション。
* 管理組合投稿では GLOBAL 系カテゴリ（重要／お知らせ／ルール 等）が選択可能。
* 一般投稿では GLOBAL 系の質問／要望／その他、および自グループ向け投稿のみ選択可能（詳細は ch03/ch04）。

### 2.4.3 BoardPostFormAttachmentSection（添付）

* 添付ファイル（PDF/Office/画像 最大5件）を一覧で表示し、追加・削除を行う。
* TipTap 導入による仕様変更はなく、従来どおりの動作を維持する。

### 2.4.4 BoardPostFormOptionsSection（回覧板・その他）

* 回覧板フラグ、回覧対象グループ、回覧期限など、追加オプションを配置するセクション。
* TipTap 導入による変更はなし。

### 2.4.5 BoardPostFormFooter（送信・キャンセル）

* 投稿ボタン／キャンセルボタン、および送信中インジケータ等をまとめる。
* 送信活性条件（必須項目入力、本文の非空など）は ch04 で定義する。

---

## 2.5 コンポーネント一覧と外部依存

### 2.5.1 コンポーネント一覧（抜粋）

* `BoardPostForm`（画面全体コンテナ）
* `BoardPostFormAuthorSection`
* `BoardPostFormCategorySection`
* `BoardPostFormContentSection`

  * `ManagementPostRichEditorDesktop`（PC 向け TipTap）
  * `ManagementPostRichEditorMobile`（スマホ向け TipTap）
* `BoardPostFormAttachmentSection`
* `BoardPostFormOptionsSection`
* `BoardPostFormFooter`

### 2.5.2 BoardPostForm の props（論理レベル）

* `viewerRole`, `hasManagementRole`, `hasGeneralRole`
* `postAuthorRole`
* `content`, `contentHtml`
* `attachments`
* 回覧板関連フラグ／グループ／期限  など

（詳細は ch03 データモデルおよび ch04 ロジックにて定義）

### 2.5.3 外部依存

BoardPostForm は、次の外部要素に依存するが、その具体実装は本章では扱わない（該当章・別文書で定義）。

* 認証コンテキスト（現在ユーザ・tenantId・viewerRole・所属グループ等）
* 掲示板カテゴリ・範囲のマスタ取得 API
* 掲示板投稿作成 API（`board_posts` への INSERT / UPDATE 等）
* 添付アップロードコンポーネント／API（Supabase Storage 等）
* Logger（投稿開始/成功/失敗ログ）
* 翻訳／TTS／モデレーション用のユーティリティ

  * これらはテキスト正 `content` のみを入力として使用し、HTML `contentHtml` は使用しない。

以上により、全ユーザ TipTap 前提の BoardPostForm 画面構造とコンポーネント構成を定義する。
