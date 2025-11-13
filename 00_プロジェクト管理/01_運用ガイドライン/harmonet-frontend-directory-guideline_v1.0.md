# HarmoNet Frontend Directory Guideline v1.0

**Document ID:** HARMONET-FRONTEND-DIR-GUIDE-V1.0
**Version:** 1.0
**Created:** 2025-11-13
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ HarmoNet 公式ルール（永続規約）

---

## 第1章 概要

HarmoNet プロジェクトのフロントエンド（Next.js App Router）の **公式ディレクトリ構成ルール v1.0** を定義する。
本規約は以下の目的を持つ：

* 実装・設計者（Windsurf / Cursor / Claude / Gemini / Tachikoma）が **迷いなく参照できる統一階層** を提供する
* UI コンポーネント・ページ・フック・ユーティリティの **役割境界を明確化** し、破壊的な混在を防ぐ
* A-01 / A-02 / C-01〜C-05 などの共通コンポーネントを **安全に再利用** できる環境を維持する
* import パスが安定し、Windsurf が安定した実装を行えるようにする

本ファイルは HarmoNet の **恒久ルール** として `/01_docs/00_プロジェクト管理/01_運用ガイドライン/` に保管され、
以後すべての実装タスクは本ガイドラインに従うことを必須とする。

---

## 第2章 フロントエンド公式ディレクトリ構成 v1.0

以下の構成を **HarmoNet 公式ディレクトリ構成** として採用する。
この構成以外の階層・分類は禁止とする。

```
src/
  components/
    common/                 ← C-01〜C-05 の共通 UI 部品
      AppHeader/
      AppFooter/
      LanguageSwitch/
      FooterShortcutBar/
      StaticI18nProvider/

    auth/                   ← A-01〜A-03 のログイン・認証機能
      MagicLinkForm/
      PasskeyButton/
      AuthCallbackHandler/

    ui/                     ← 汎用 UI（Button / Card / Modal など）
    hooks/                  ← 再利用可能な React Hooks
    utils/                  ← Utility functions
      _deprecated/          ← 旧ファイルの保管場所（削除禁止）

app/
  layout.tsx                ← ルートレイアウト
  globals.css

  login/
    page.tsx                ← ログイン画面（A-01 + A-02）

  auth/
    callback/
      page.tsx              ← MagicLink/Passkey の共通 callback

  board/
  facility/
  tenant/
  mypage/
  ... 機能別画面
```

本構成は「機能部品は src/components、画面は app/」という
Next.js App Router のベストプラクティスに準拠している。

---

## 第3章 ルール（禁止事項・必須事項）

### 3.1 Windsurf / 開発者が行ってはいけないこと

* ❌ 公式構成に存在しない階層の新規作成（例：`components/login`）
* ❌ 共通部品を機能別フォルダに移動
* ❌ UI コンポーネントのロジックを変更
* ❌ Tailwind クラスの変更
* ❌ ファイル削除（移動のみ許可）
* ❌ 命名規則の勝手な変更
* ❌ utils 内の統廃合（公式作業指示書以外）

### 3.2 Windsurf / 開発者が必ず守るべきこと

* ✔ 画面（page.tsx）と UI コンポーネントは必ず分離
* ✔ すべての UI コンポーネントは `/src/components/` に配置
* ✔ 共通部品は `components/common/` に置く
* ✔ ログイン系部品は `components/auth/` に統一
* ✔ Deprecated ファイルは `_deprecated` に移動し、削除しない
* ✔ import パスは `@/src/...` で統一

---

## 第4章 import パスルール

Next.js + TypeScript の安定性のため、以下のパス形式を絶対ルールとする。

### 4.1 ルート

```
@/src/...   ← components / utils / hooks
@/app/...   ← Next.js の page / layout
```

### 4.2 共通部品（C-01〜C-05）

```
@/src/components/common/AppHeader/AppHeader
@/src/components/common/AppFooter/AppFooter
@/src/components/common/LanguageSwitch/LanguageSwitch
@/src/components/common/StaticI18nProvider/StaticI18nProvider
@/src/components/common/FooterShortcutBar/FooterShortcutBar
```

### 4.3 認証系部品（A-01〜A-03）

```
@/src/components/auth/MagicLinkForm/MagicLinkForm
@/src/components/auth/PasskeyButton/PasskeyButton
@/src/components/auth/AuthCallbackHandler/AuthCallbackHandler
```

### 4.4 UI 汎用（Button など）

```
@/src/components/ui/Button
```

### 4.5 hooks / utils

```
@/src/components/hooks/useXxx
@/src/components/utils/yyy
```

---

## 第5章 責務境界（絶対に混在してはいけない）

### 5.1 app/ の役割

* 画面遷移
* レイアウト配置
* ルーティング
* i18n Provider の root 設置

### 5.2 src/components/ の役割

* すべての UI コンポーネント
* ロジックを持つ Presenter コンポーネント
* Supabase や Corbado を使う login ロジック（A-01/A-02）

### 5.3 utils の役割

* 共通ロジック（UI ではない）
* 認証 SDK ラッパー（Corbado loader など）

### 5.4 例外

* app/ に UI を置く行為は禁止
* components/ 内に page.tsx を置く行為は禁止

---

## 第6章 ディレクトリ命名規則

### 6.1 コンポーネントのディレクトリ命名

```
ComponentName/
  ComponentName.tsx
  ComponentName.test.tsx
  ComponentName.stories.tsx
  index.ts
```

### 6.2 フォルダ名の一貫性

* 先頭大文字（PascalCase）
* ファイル名も PascalCase

### 6.3 Deprecated の扱い

```
src/components/utils/_deprecated/*
```

* 削除は行わず、履歴保存のみ

---

## 第7章 Windsurf 実行タスクでの利用方法

Windsurf に作業を指示するときは、以下を **毎回冒頭に明記**する。

```
※ 本タスクは HarmoNet 公式フロントエンドディレクトリ規則
   /01_docs/00_プロジェクト管理/01_運用ガイドライン/
   harmonet-frontend-directory-guideline_v1.0.md
   に完全準拠すること。
```

この一文により、

* Windsurf が勝手に階層を変更する
* login / auth / common の混在を発生させる
* ファイル移動ミスを起こす

といった事故を **すべて防止**できる。

---

## 第8章 改訂履歴（ChangeLog）

| Version | Date |
