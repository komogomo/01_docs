# Windsurf 実行指示書 テンプレート v1.2

**Document:** Windsurf 実行指示書（汎用）
**Version:** v1.2
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Template

---

## 1. 目的 / ゴール

本書は、HarmoNet プロジェクトにおいて **Windsurf を用いて実装タスクを実行するための共通テンプレート** である。

* 対象コンポーネントや画面ごとに、本書をコピーして内容を具体化する。
* タスクごとに「ゴール」「スコープ」「参照設計書」「編集可能ファイル」「テスト条件」を明確にすることを目的とする。

### 1.1 タスク識別情報（記入欄）

* **Task ID:** `<TaskID>`

  * 例：`H00-UI-HomePage-Layout` / `A01-Logic-MagicLink-ErrorHandling`
* **Component ID:** `<ComponentID>`

  * 例：`H-00 HomePage` / `A-01 MagicLinkForm` / `C-01 AppHeader`
* **Task Name:** `<TaskName>`

  * 例：`HomePage UI 実装（/home スケルトン）`
* **担当 AI:** `Windsurf`
* **実行ブランチ:** `<branch-name>`

---

## 2. スコープ定義（UI / Logic / Data / Test）

本タスクで **実装・修正してよい範囲** を、UI / Logic / Data / Test の 4 軸で明示する。

### 2.1 UI スコープ

* **含める:**

  * `<具体的な UI スコープを記載>`
    例：`/home` レイアウト構成、セクションタイトル、カード・タイルの表示、Tailwind による余白・配置調整
* **含めない:**

  * 共通部品（AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider）の仕様変更
  * デザインガイドライン自体の変更

### 2.2 ロジック（Logic）スコープ

* **含める:**

  * `<対象コンポーネント内部ロジックの範囲>`
    例：表示件数の切り詰め、`isEnabled` によるクリック制御 など
* **含めない:**

  * 認証・認可・RLS ロジック
  * 新たなビジネスルールの追加・仕様変更

### 2.3 データ（Data）スコープ

* **含める:**

  * ダミーデータ／静的定義（mock 配列、定数）のみ
  * 既存型定義に沿ったデータ構造の受け渡し
* **含めない:**

  * Supabase クライアントコードの追加・変更
  * 新規 API エンドポイントの作成

### 2.4 テスト（Test）スコープ

* **含める:**

  * `Jest + React Testing Library` による対象コンポーネントのテスト追加・修正
  * 対象タスクに関係するテストスイートの整備
* **含めない:**

  * 無関係な既存テストの削除
  * E2E テスト（Playwright / Cypress など）の追加

---

## 3. 参照設計書

Windsurf が **必ず参照すべき設計書** を、カテゴリ別に列挙する。

### 3.1 基本設計（上位仕様）

* `/01_docs/03_基本設計/<カテゴリ>/<画面名>/...`

  * 例：`/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch01_v1.2.md`
  * 例：`/01_docs/03_基本設計/01_ログイン画面/A-00_LoginPage-basic-design-ch02_v1.4.md`

### 3.2 詳細設計（実装指針の「憲法」）

* `/01_docs/04_詳細設計/<カテゴリ>/<画面名>/...`

  * 例：`/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch02_v1.0.md`
  * 例：`/01_docs/04_詳細設計/01_ログイン画面/A-00_LoginPage-detail-design-ch03_v1.2.md`

> **ルール:** 実装は必ず「詳細設計書」の仕様に従うこと。
> 基本設計に書かれた内容が詳細設計と矛盾する場合、詳細設計を優先し、
> 詳細設計の仕様を AI 側で変更・補完してはならない。

### 3.3 その他参照資料（必要に応じて追記）

* 技術スタック定義書: `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.4.md`
* 非機能要件定義書: `/01_docs/01_要件定義/Nonfunctional-requirements_v1.0.md`
* 機能要件定義書: `/01_docs/01_要件定義/functional-requirements-all_v1.6.md`

---

## 4. 実装対象ファイル / 参照専用ファイル

### 4.1 編集してよいファイル（Writeable）

このタスクで **新規作成・編集を許可するファイルのみ** を列挙する。

* 例：

  * `app/home/page.tsx`
  * `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
  * `src/components/home/HomeNoticeSection/HomeNoticeSection.types.ts`
  * `src/components/home/HomeFeatureTiles/HomeFeatureTiles.tsx`
  * `src/components/home/HomeFeatureTiles/HomeFeatureTiles.types.ts`
  * `src/components/home/HomeFeatureTiles/HomeFeatureTile.tsx`
  * `src/components/home/HomeFeatureTiles/HomeFeatureTile.types.ts`

> **ルール:** 上記に記載のないファイルの編集・新規作成は禁止とする。

### 4.2 参照専用ファイル（Read-only）

このタスクで **内容の参考にしてよいが、変更してはならないファイル** を列挙する。

* 例：

  * `app/login/page.tsx`（レイアウト参考用）
  * 共通部品群（AppHeader / AppFooter / StaticI18nProvider など）の実装ファイル
  * 既存のテストユーティリティ

> **ルール:** Read-only ファイルに対する変更提案はコメントとしてのみ記述し、
> 実装として反映してはならない（別タスクとする）。

---

## 5. 実装タスク詳細（やることリスト）

### 5.1 実装タスク一覧（例）

1. `<Task-1>`: `/app/<path>/page.tsx` にページコンポーネントの JSX 構造を実装する。

   * 詳細設計 ch02 の画面構成に従うこと。
2. `<Task-2>`: `...ComponentA...` を詳細設計 ch03/ch04 に従って実装する。
3. `<Task-3>`: `...ComponentB...` の UI と Props を実装する。
4. `<Task-4>`: 対象コンポーネントの Jest/RTL テストを ch07 のテスト観点に従って追加・修正する。
5. `<Task-5>`: ESLint / TypeScript チェックがエラー無しで通るように調整する。

### 5.2 実装時の補足方針

* コンポーネント構造・Props 名・型定義は、詳細設計書に記載されたものから逸脱しないこと。
* Tailwind クラスは、既存画面（LoginPage 等）とトーンが揃うように実装する。
* ロジックは必要最小限に留め、余計な抽象化やパターン導入（Redux, Zustand 等）は行わない。

---

## 6. 禁止事項・制約

本タスクでは、以下の行為を禁止する。

1. **設計書の無断変更**

   * 詳細設計・基本設計に記載されていない仕様を勝手に追加・変更しないこと。
2. **スキーマ・RLS・Auth フローの変更**

   * Supabase のテーブル定義・RLS ポリシー・MagicLink 認証フローを変更しないこと。
3. **共通部品の仕様変更**

   * AppHeader / AppFooter / StaticI18nProvider などの共通部品の Props 変更・挙動変更を行わないこと。
4. **新規ライブラリの導入**

   * `package.json` に新しい依存ライブラリを追加しないこと。
5. **不要なリファクタリング**

   * タスクと無関係なファイルのリファクタリングやディレクトリ構成の変更を行わないこと。

---

## 7. テスト・完了条件

### 7.1 実行すべきテスト

* `npm test` または対象パッケージの Jest テスト

  * 対象コンポーネントに関するテストがすべて PASS していること。
* TypeScript チェック

  * `npm run type-check`（存在する場合）がエラー無しで完了すること。
* Lint

  * `npm run lint` がエラー無しで完了すること。

### 7.2 受け入れ条件

* 詳細設計書（ch02〜ch07）の要件を満たしていること。
* 画面の見た目が基本設計のワイヤーフレームと大きく乖離していないこと。
* AI 自己評価で 10 段階中 9 点以上と判断できること。

---

## 8. CodeAgent_Report の出力

本タスク完了時、Windsurf（または実行 AI）は **CodeAgent_Report** を作成し、以下のパスに保存する。

* `/01_docs/06_品質チェック/CodeAgent_Report_<TaskID>_v1.0.md`

### 8.1 CodeAgent_Report に含める内容

* Task ID / Component ID / 実行日時
* 参照した設計書とバージョン
* 実装したファイル一覧
* 実施したテストと結果（Jest / Lint / Type-check）
* 自己評価スコア（10 段階）
* 気づいた問題点・今後の改善候補（任意）

---

## 9. テンプレートの使い方

1. 本ファイルをコピーし、タスク固有のファイル名にリネームする。

   * 例：`WS-H00_HomePage-UI_v1.0.md`
2. `<TaskID>` `<ComponentID>` `<TaskName>` `<具体的なスコープ>` などのプレースホルダを埋める。
3. 参照設計書・実装対象ファイル・禁止事項をタスク内容に合わせて具体化する。
4. 完成した指示書を Windsurf に渡し、実装タスクを実行する。

---

**End of Template**
