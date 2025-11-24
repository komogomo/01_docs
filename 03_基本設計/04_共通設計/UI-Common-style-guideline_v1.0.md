はい、ここは「シンプルさ」をそのまま設計書に固定しておいた方がいいところですね。
新規画面のWS指示書から参照しやすいように、**1枚もののUIスタイル雛形**を用意します。

---

## 格納場所とファイル名（提案）

**パス（共通UIガイドライン用）**

`/01_docs/03_基本設計/02_共通設計/UI-Common-style-guideline_v1.0.md`

* 「基本設計」配下
* 共通部品・デザインをまとめる「共通設計」ディレクトリ
* 今後、ヘッダー・フッター・ボタン・カードなど全画面共通に効かせる前提

WS 指示書側では：

> 参照: `/01_docs/03_基本設計/02_共通設計/UI-Common-style-guideline_v1.0.md`

と書くだけで済ませるイメージです。

---

## 雛形（そのままMDとして保存できます）

````markdown
# UI-Common-style-guideline_v1.0

**Document ID:** UI-COMMON-STYLE-GUIDE  
**Version:** 1.0  
**Scope:** HarmoNet 全画面共通の UI トーン・スタイル指針  
**Target:** すべてのフロントエンド実装（Windsurf 指示書／画面詳細設計の参照用）

---

## 1. カラートーン

### 1.1 ベースカラー

- 背景（ページ全体）
  - `#F5F7FB` ~ `#F7F9FC` のごく薄いグレー系
- カード／フォーム背景
  - `#FFFFFF` 固定（純白）
- ボーダー（アウトライン）
  - 標準: `#E2E8F0` 相当（淡いグレー）
  - 強調: `#93C5FD` 相当（淡いブルー）

### 1.2 文字色

- 見出し（タイトル）
  - `text-gray-900` レベル（はっきりした黒に近いグレー）
- 本文
  - `text-gray-800` ～ `text-gray-700`
- サブテキスト／説明
  - `text-gray-500`
- リンク／強調（プライマリブルー）
  - `text-blue-500` ～ `text-blue-600`

※ Tailwind レベルでは `text-gray-900 / 800 / 500`、`text-blue-500` を基準とし、  
　それ以外の色を画面単位で増やさない。

---

## 2. カード（ボックス）スタイル

### 2.1 共通カード

- 背景: `bg-white`
- 枠線: `border border-gray-200`
- 角丸: `rounded-2xl`
- 影:
  - 基本: `shadow-sm`
  - クリック可能なカード（HOME のタイル・掲示板カードなど）:
    - 通常: `shadow-sm`
    - ホバー: `shadow-md` + `translate-y-[1px]` 程度

Tailwind 例:

```tsx
<div className="rounded-2xl border border-gray-200 bg-white shadow-sm">
  ...
</div>
````

---

## 3. タグ／バッジ（pill）

### 3.1 フィルタ用タグ（カテゴリ）

* レイアウト:

  * pill 型、左右 `px-3`、高さ `h-8` 程度
  * `inline-flex items-center justify-center rounded-full`
* 配色:

  * 非選択:

    * `bg-white text-gray-600 border border-gray-200`
  * 選択中:

    * `bg-blue-50 text-blue-600 border border-blue-400`
* 配置:

  * タブバーは `flex gap-2 overflow-x-auto flex-nowrap`

### 3.2 カテゴリバッジ（カード左上）

* `bg-blue-50 text-blue-600 text-xs font-medium`
* `rounded-full px-3 py-1`

---

## 4. ボタンスタイル

### 4.1 プライマリボタン（例：投稿画面「投稿する」）

* 背景: `bg-blue-500`
* 文字: `text-white`
* 角丸: `rounded-full` or `rounded-xl`
* 影: `shadow-sm`（ホバーで `shadow-md`）

Tailwind 例:

```tsx
<button className="
  inline-flex items-center justify-center
  rounded-full px-5 py-2.5
  bg-blue-500 text-white text-sm font-medium
  shadow-sm
  hover:bg-blue-600 hover:shadow-md
  focus:outline-none focus:ring-2 focus:ring-blue-300 focus:ring-offset-2
">
  投稿する
</button>
```

### 4.2 セカンダリボタン（例：キャンセル）

* 背景: `bg-white`
* 枠線: `border border-gray-300`
* 文字: `text-gray-700`

---

## 5. 新規投稿ボタン（BoardTop用）

### 5.1 位置

* 右下固定:

  * `position: fixed`
  * `bottom-16 right-4`
* フッターと重ならないよう、一覧ラッパーに `pb-28` 程度の余白を必ず追加する。

### 5.2 見た目（透明FAB）

* 背景: `bg-transparent`
* 枠線: `border border-blue-400`
* 文字: `text-blue-500`
* 影: `shadow-lg shadow-blue-200/60`
* アイコン: `Plus`（`h-6 w-6`, `strokeWidth ≈ 2.6`）
* ホバー: `hover:bg-blue-50/40`
* アクティブ: `active:bg-blue-100/40`

Tailwind 例:

```tsx
<button
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
>
  <Plus className="h-6 w-6" strokeWidth={2.6} />
</button>
```

---

## 6. タイポグラフィ

### 6.1 見出し

* 画面タイトル: `text-xl font-semibold`（例：「掲示板」）
* セクションタイトル: `text-base font-semibold`
* カードタイトル: `text-sm font-semibold` または `text-base font-semibold`

### 6.2 本文・サブテキスト

* 本文: `text-sm text-gray-800`
* サブ説明: `text-xs text-gray-500`

---

## 7. 余白・レイアウト

* 画面左右の余白（SP想定）:

  * `px-4`
* コンテンツ縦方向の基本ギャップ:

  * 要素間: `space-y-4` / `gap-4`
* フッターと FAB のための下余白:

  * 一覧系: `pb-24` ～ `pb-28`

---

## 8. 適用ルール

1. **新規画面・新規コンポーネント** は、可能な限り本ガイドラインのスタイルを採用する。
2. 既存スタイルと異なる表現を入れたい場合は、基本設計書側で明示的に理由を記載し、
   「例外」として扱う。
3. Windsurf 向け実装指示書では、本書を「共通UIスタイル参照」としてリンクし、
   色・枠・文字色などを画面ごとに勝手に増やさない。

---

```

---

この雛形をそのまま `UI-Common-style-guideline_v1.0.md` にしておけば、  
以後の WS 指示書では

> 共通スタイルは `/01_docs/03_基本設計/02_共通設計/UI-Common-style-guideline_v1.0.md` に従うこと。

の一行で「枠の太さ・色・文字色・FAB の見た目」まで統一できます。
::contentReference[oaicite:0]{index=0}
```
