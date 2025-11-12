# Storybook × Tailwind v4 不具合レポート

## 概要
- 現象: Storybook で Tailwind のスタイルが反映されない。CSF indexing エラーやプレビュー起動失敗も発生。
- 主因:
  - [主因1] Tailwind v4 の CSS が Storybook で PostCSS 処理されていなかった。
  - [副因1] Storybook 既定 CSS ルールと自前ルールの二重処理衝突。
  - [副因2] `.stories.jsx` と `.stories.tsx` の重複で CSF indexer 失敗。
  - [副因3] Storybook パッケージのバージョン不整合やポート競合。

## 環境
- Storybook: 8.6.14（Webpack5）
- Tailwind: v4（`@import "tailwindcss"`, `@source`）
- PostCSS: 8.x
- Next.js: 16.0.1
- OS: Windows

## 症状
- スタイル未適用（素の HTML 見え）。
- `Unknown word import`（css-loader が style-loader 出力を再解釈）。
- `CSF: missing default export`、`Unable to index files`。
- `Error fetching /index.json` でプレビュー不能。
- ポート 6006 競合。

## 根本原因の解説
- Tailwind v4 は PostCSS による変換が必須。Storybook 既定設定では未処理。
- 既定 CSS ルールと自前ルールが同じファイルを処理 → 二重処理でビルドエラー。
- ストーリー拡張子の混在（JSX/TSX）で重複検出や default export 誤検出。
- Storybook モノレポのバージョン不一致は不安定化要因。

## 実施した対処
1) PostCSS パイプラインを追加（Storybook 側）
- `.storybook/main.js` の `webpackFinal` にて、`style-loader` → `css-loader` → `postcss-loader` を `app/`, `src/`, `components/` に適用。
- 既定 CSS ルールから上記パスを `exclude` して「二重処理」を回避。

2) 依存追加/整合
- `postcss` を dev 依存で導入。
- `storybook`, `@storybook/react`, `@storybook/react-webpack5`, `@storybook/test` を 8.6.14 に統一。

3) ストーリー探索の整理
- `stories: ['../src/**/*.stories.@(ts|tsx|mdx)']` に変更（JSX を探索対象外）。
- 重複ファイルを削除：`src/components/auth/MagicLinkForm/MagicLinkForm.stories.jsx`。

4) プレビューで CSS を取り込み
- `.storybook/preview.js` にて `import '../app/globals.css'` を実施。

5) ポート競合対応
- 6006 が埋まっていたため 6007 で起動。

## 変更後の要点（抜粋）
- preview.js
```js
import '../app/globals.css';
export default { parameters: { controls: { expanded: true } } };
```

- postcss.config.js
```js
module.exports = { plugins: { '@tailwindcss/postcss': {}, autoprefixer: {} } };
```

- .storybook/main.js（webpackFinal 抜粋）
```js
const includePaths = [
  path.resolve(__dirname, '../app'),
  path.resolve(__dirname, '../src'),
  path.resolve(__dirname, '../components'),
];

const addExclude = (rule) => {
  if (!rule) return;
  if (rule.test && rule.test.toString().includes('css')) {
    rule.exclude = Array.from(new Set([
      ...(Array.isArray(rule.exclude) ? rule.exclude : rule.exclude ? [rule.exclude] : []),
      ...includePaths,
    ]));
  }
  if (Array.isArray(rule.oneOf)) rule.oneOf.forEach(addExclude);
  if (Array.isArray(rule.rules)) rule.rules.forEach(addExclude);
};
(config.module.rules || []).forEach(addExclude);

config.module.rules.push({
  test: /\.css$/,
  include: includePaths,
  use: [
    require.resolve('style-loader'),
    { loader: require.resolve('css-loader'), options: { importLoaders: 1 } },
    { loader: require.resolve('postcss-loader'), options: { implementation: require('postcss') } },
  ],
});
```

- globals.css（Tailwind v4 の例）
```css
@import "tailwindcss";
@source "../src/**/*.{ts,tsx,js,jsx,mdx}",
        "../app/**/*.{ts,tsx,js,jsx,mdx}",
        "../components/**/*.{ts,tsx,js,jsx,mdx}",
        "../.storybook/**/*.{js,jsx,ts,tsx,mdx}";
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## 再発防止のベストプラクティス
- Tailwind v4 を使うなら Storybook でも PostCSS を必ず通す。
- 既定 CSS ルールと自前ルールの二重処理を避けるために `exclude` を設定。
- Storybook パッケージ群は同一バージョンで統一。
- ストーリー拡張子方針を統一（`.stories.tsx` 推奨）。重複ファイルは置かない。
- preview ファイルは 1 つに統一（`preview.js`/`preview.ts` どちらか）。
- ポート競合時の fallback ポリシーを決めておく（例: `-p 6007`）。

## トラブルシューティング早見表
- 見た目が素の HTML → PostCSS 未設定/未適用。`postcss-loader`、`globals.css` import、二重処理の除外を確認。
- `Unknown word import` → CSS 二重処理の兆候。既定 CSS ルールから対象ディレクトリを除外。
- `CSF: missing default export` / `Unable to index` → CSF default export と stories グロブ、重複ファイルを見直す。
- ポート競合 → 既存プロセス停止 or `-p` で別ポート。

## 成果
- Tailwind スタイルが Storybook 全体に反映。
- CSF indexer/プレビューのエラー解消。
- 不要ファイルを整理し、設定を一貫化。

## 補足（代替手段）
- `@storybook/react-vite`（Vite ビルダー）への切替で、PostCSS や変換周りが簡素化できることがあります。ただし既存 Webpack 設定資産があるなら、本レポートの設定で安定運用可能です。
