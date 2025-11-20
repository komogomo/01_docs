# Claude 用アイコン比較ページ生成指示書 v1.0

本書は、Claude に **本物SVGアイコンを使用したアイコン比較HTML** を生成させるための正式な作業指示書である。
HarmoNet に最適なアイコンセット選定のため、Lucide / Heroicons / Feather / Tabler の**実物SVG**を用いた正確な比較を行うことを目的とする。

---

## 1. Task Summary（タスク概要）

HarmoNet の UI アイコン選定のため、以下 4 種類のアイコンセットを**本物SVG**で比較するHTMLファイルを作成する：

* **Lucide**
* **Heroicons**
* **Feather Icons**
* **Tabler Icons**

比較対象アイコン（用途）:

* Calendar（施設予約）
* Document / File（回覧板）
* Chat / Message（掲示板）
* Bell（通知）
* Camera（監視カメラ）
* Wrench / Tool（メンテナンス）

**出力ファイル:**

* `iconset_comparison.html`

---

## 2. Output Requirements（出力要件）

Claude は以下を満たした HTML を生成する：

* 本物SVG を使用する（※AIが生成したSVGは禁止）
* 各アイコンセットごとにセクションを分ける
* アイコンサイズは 48×48 に統一
* SVG の stroke-width などは公式のまま改変禁止
* 名前（Lucide / Heroicons / Feather / Tabler）とアイコンラベルを明示
* ローカルで開くだけで比較できるシンプル構成の HTML

---

## 3. SVG 取得元（必須）

Claude は必ず以下の公式サイトから SVG を取得すること：

* **Lucide**
  [https://lucide.dev/icons](https://lucide.dev/icons)

* **Heroicons**
  [https://heroicons.com/](https://heroicons.com/)

* **Feather Icons**
  [https://feathericons.com/](https://feathericons.com/)

* **Tabler Icons**
  [https://tabler-icons.io/](https://tabler-icons.io/)

※ 公式から取得した SVG の path / stroke / rect / circle を絶対に改変しないこと。

---

## 4. HTML レイアウト仕様

HTML 構造（例）：

```
<h1>Icon Set Comparison</h1>

<section>
  <h2>Lucide</h2>
  <div class="row">
    <!-- Calendar -->
    <!-- Document -->
    <!-- Chat -->
    <!-- Camera -->
    <!-- Wrench -->
    <!-- Bell -->
  </div>
</section>

<section>
  <h2>Heroicons</h2>
  ...
</section>
```

CSS（最低限で良い）：

```
.row {
  display: flex;
  gap: 32px;
  margin-bottom: 48px;
  align-items: center;
}
svg {
  width: 48px;
  height: 48px;
  stroke: #111;
}
```

---

## 5. Forbidden Actions（禁止事項）

Claude は以下を行ってはならない：

* AI が新規にSVGを生成する
* path / stroke-width を勝手に変更する
* Heroicons solid を使用する（outline版のみ）
* Tailwind / React / TypeScript 化（今回は純HTML）
* Feather / Tabler の代替アイコンで誤魔化す

---

## 6. Acceptance Criteria（受入基準）

* 4セット×6アイコンすべてが **実物SVG** である
* stroke / path が公式と完全一致
* セットごとの差異が視覚的に明確
* HTML をローカルで開くだけで比較可能
* アイコン名とセット名が明記されている

---

## 7. 作業開始方法

Claude へ次を提示する：

> 「本指示書に従って `iconset_comparison.html` を生成してください。」

---

以上。
