# Windsurf修正指示書 - Tailwind/PostCSS統合修正版 v1.0

**Document ID:** HARMONET-WINDSURF-FIX-TAILWIND-POSTCSS-V1.0
**Created:** 2025-11-11
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ 修正指示（Tailwind v4 + Next.js16 統合整備）

---

## 第1章 修正概要

### 1.1 目的

本指示書は、HarmoNet プロジェクト環境における **Tailwind CSS v4** と **Next.js 16** のビルド統合設定を整備し、CSS クラス未反映の問題を解消することを目的とする。
PostCSS 経路、依存パッケージ、および Tailwind の組み込み設定を Windsurf により自動再構築する。

---

## 第2章 対象環境

| 項目        | 値                           |
| --------- | --------------------------- |
| OS        | Windows 11                  |
| Framework | Next.js 16.0.1 (App Router) |
| Tailwind  | v4.x (JITモード)               |
| Node.js   | LTS v20.x                   |
| プロジェクトパス  | `D:\Projects\HarmoNet`      |

---

## 第3章 修正対象ファイル

| 操作      | パス                                        | 内容                                    |
| ------- | ----------------------------------------- | ------------------------------------- |
| ✅ 修正    | `D:\Projects\HarmoNet\app\globals.css`    | Tailwind宣言の補完・構文統一                    |
| ✅ 追加/修正 | `D:\Projects\HarmoNet\postcss.config.js`  | PostCSS統合設定の作成または補正                   |
| ✅ 検証    | `D:\Projects\HarmoNet\tailwind.config.ts` | `content` パスとJIT設定確認                  |
| ✅ 検証    | `D:\Projects\HarmoNet\app\layout.tsx`     | CSSインポート確認 (`import './globals.css'`) |

---

## 第4章 修正手順

### 4.1 Tailwind構成整備

1. **Tailwind宣言を明示的に記述**
   `app/globals.css` に以下の構文を自動挿入または確認：

   ```css
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   ```

2. **PostCSSプラグイン構成の補正**
   Tailwind v4 の正式仕様に準拠し、`postcss.config.js` を以下内容で作成：

   ```js
   module.exports = {
     plugins: {
       '@tailwindcss/postcss': {},
       autoprefixer: {},
     },
   };
   ```

3. **依存関係の調整**
   TailwindとNext.jsの依存解析後、必要な場合は自動で以下を導入：

   ```bash
   npm install @tailwindcss/postcss autoprefixer
   ```

4. **Tailwindビルド経路の検証**
   `tailwind.config.ts` の `content` が以下であることを確認：

   ```ts
   content: [
     './app/**/*.{ts,tsx}',
     './src/**/*.{ts,tsx}',
   ]
   ```

5. **再ビルド試験**
   以下コマンドでビルドを検証：

   ```bash
   npm run build
   npm run dev
   ```

---

## 第5章 受入基準

| 項目               | 基準                                             |
| ---------------- | ---------------------------------------------- |
| TypeCheck / Lint | エラー・警告ゼロ                                       |
| Build            | 成功 (`✓ Compiled ...` 表示)                       |
| UI確認             | `/login` ページでTailwindスタイル（白背景・中央配置・青ボタン）が反映される |
| i18n連携           | StaticI18nProvider 配下で表示崩れなし                   |
| SelfScore        | 平均 ≥ 9.0 / 10                                  |

---

## 第6章 CodeAgent_Report 出力先

```
/01_docs/05_品質チェック/CodeAgent_Report_tailwind-postcss統合_v1.0.md
```

---

## 第7章 備考

* 本修正は「環境構成修正」であり、既存コンポーネントへのコード改変を伴わない。
* 既存共通部品（C-01〜C-05）およびログインモジュール（A-00〜A-03）には影響しない。
* 修正完了後、UIをブラウザで確認し、Tailwindクラスがすべて有効化されていることを最終確認する。

---

**End of Instruction**
