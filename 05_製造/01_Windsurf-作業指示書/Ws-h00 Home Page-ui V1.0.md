# Windsurf 実行指示書 WS-H00_HomePage-UI_v1.0

**Task ID:** H00-UI-HomePage-Layout
**Component ID:** H-00 HomePage
**Task Name:** HomePage UI 実装（/home スケルトン＋セクション構成）
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Ready for Execution
**Tool:** Windsurf

---

## 1. 目的 / ゴール

本タスクのゴールは、HarmoNet のログイン後トップ画面 **HomePage（/home）** について、
**詳細設計書 H-00 に従った UI スケルトンを実装し、ダミーデータで画面全体の構造とレイアウトを確定すること** である。

* ログイン後 `/home` にアクセスした際に、以下を表示できる状態にする：

  * 上部：最新のお知らせセクション（NOTICE ハイライト、ダミーデータ 1〜2 件）
  * 下部：機能タイル 2×3（お知らせ／掲示板／施設予約／運用ルール／通知設定／ダミー、すべてリンク無効）
* Supabase 連携・実データ取得・実際の画面遷移は本タスクの対象外とする。

---

## 2. スコープ定義（UI / Logic / Data / Test）

### 2.1 UI スコープ

* **含める:**

  * `/home` ページの JSX 構造（AppHeader / Home コンテンツ / AppFooter の 3 分割）
  * Home コンテンツ領域の 2 セクション構成：

    * HomeNoticeSection（最新のお知らせ）
    * HomeFeatureTiles（機能タイル 2×3）
  * お知らせカードおよび機能タイルの基本レイアウト（SP 縦向き前提）
  * Tailwind による余白・グリッド・フォントサイズなど、基本的な見た目調整
* **含めない:**

  * AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider 自体の UI 変更
  * 新しい共通 UI コンポーネントの追加

### 2.2 ロジック（Logic）スコープ

* **含める:**

  * HomeNoticeSection における表示件数の切り詰めロジック（1〜3件の clamp）
  * HomeFeatureTile における `isEnabled` フラグに基づくクリック制御（無効時は noop）
* **含めない:**

  * 認証・認可・RLS ロジック
  * 掲示板フィルタに関するビジネスロジック（ALL/NOTICE/RULES の URL 解釈など）

### 2.3 データ（Data）スコープ

* **含める:**

  * HomePage 内に定義するダミーお知らせ配列 `MOCK_HOME_NOTICE_ITEMS`
  * 静的タイル定義 `HOME_FEATURE_TILES`（NOTICE/BOARD/FACILITY/RULES/NOTIFICATION/DUMMY）
* **含めない:**

  * Supabase クライアントコードの追加・変更
  * 新規 API エンドポイントの作成

### 2.4 テスト（Test）スコープ

* **含める:**

  * HomePage / HomeNoticeSection / HomeFeatureTiles / HomeFeatureTile に対する Jest + RTL テスト追加・修正
  * HomePage 詳細設計 ch07 のテスト観点 No.1〜No.10 の範囲
* **含めない:**

  * 無関係コンポーネントのテスト修正・削除
  * E2E テスト（Playwright / Cypress 等）の追加

---

## 3. 参照設計書

### 3.1 基本設計

HomePage UI 実装に関する上位仕様は、以下の基本設計書を参照すること。

* `/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch01_v1.2.md`
* `/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch02_v1.2.md`
* `/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch03_v1.2.md`
* `/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch04_v1.2.md`
* `/01_docs/03_基本設計/03_画面設計/02_ホーム画面/home-feature-design-ch05_v1.2.md`

### 3.2 詳細設計（HomePage 憲法）

実装は、以下の HomePage 詳細設計書の仕様に **厳密に従うこと**。

* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch00-index_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch01_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch02_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch03_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch04_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch05_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch06_v1.0.md`
* `/01_docs/04_詳細設計/02_ホーム画面/HomePage-detail-design-ch07_v1.0.md`

> **ルール:** 基本設計と詳細設計に矛盾がある場合、詳細設計を唯一の正とする。
> Windsurf は詳細設計の仕様を勝手に変更・補完してはならない。

### 3.3 共通・関連資料（Read-only）

* `/01_docs/02_技術スタック/harmonet-technical-stack-definition_v4.4.md`
* `/01_docs/01_要件定義/functional-requirements-all_v1.6.md`
* `/01_docs/01_要件定義/Nonfunctional-requirements_v1.0.md`
* AppHeader / AppFooter / StaticI18nProvider / LanguageSwitch の詳細設計書（Read-only）

---

## 4. 実装対象ファイル / 参照専用ファイル

### 4.1 編集してよいファイル（Writeable）

本タスクで編集・新規作成を許可するファイルは、以下に限定する。

* `app/home/page.tsx`
* `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
* `src/components/home/HomeNoticeSection/HomeNoticeSection.types.ts`
* `src/components/home/HomeFeatureTiles/HomeFeatureTiles.tsx`
* `src/components/home/HomeFeatureTiles/HomeFeatureTiles.types.ts`
* `src/components/home/HomeFeatureTiles/HomeFeatureTile.tsx`
* `src/components/home/HomeFeatureTiles/HomeFeatureTile.types.ts`
* （必要に応じて）HomePage 専用のテストファイル：

  * `src/__tests__/home/HomePage.test.tsx`
  * `src/__tests__/home/HomeNoticeSection.test.tsx`
  * `src/__tests__/home/HomeFeatureTiles.test.tsx`

> **ルール:** 上記に記載のないファイルの編集・新規作成は禁止とする。

### 4.2 参照専用ファイル（Read-only）

* `app/login/page.tsx`（レイアウト・余白の参考用）
* AppHeader / AppFooter / StaticI18nProvider / LanguageSwitch 実装ファイル群
* 既存のテストユーティリティ（カスタム render など）

> **ルール:** Read-only ファイルに対して仕様変更が必要と判断した場合は、
> 実装ではなく CodeAgent_Report に「改善候補」として記述する。

---

## 5. 実装タスク詳細（やることリスト）

### 5.1 実装タスク一覧

1. **Task-1:** `/app/home/page.tsx` に HomePage の JSX 構造を実装する。

   * 詳細設計 ch02 の画面構成に従い、AppHeader / `<main>` / AppFooter の 3分割構造とする。
   * `<main>` 内に `HomeNoticeSection` と `HomeFeatureTiles` をこの順で配置する。

2. **Task-2:** `HomeNoticeSection` コンポーネントを ch03/ch04/ch05 に従って実装する。

   * Props: `items: HomeNoticeItem[]`, `maxItems?: number`。
   * 1〜3件の表示件数制御（`clampNoticeCount`）と 0件時メッセージ表示を実装する。

3. **Task-3:** `HomeFeatureTiles` / `HomeFeatureTile` を ch03/ch04/ch05 に従って実装する。

   * `HomeFeatureTiles` は `tiles: HomeFeatureTileDefinition[]` を受け取り、2×3 グリッドで描画する。
   * `HomeFeatureTile` は `isEnabled` に応じてクリック可否と `aria-disabled` を制御する。
   * 本タスクでは `HOME_FEATURE_TILES` の `isEnabled` はすべて `false` とする。

4. **Task-4:** HomePage 関連の Jest/RTL テストを ch07 のテスト観点 No.1〜No.10 に従って追加する。

   * HomePage レンダリング構造（Header/Notice/Tiles/Footer）。
   * お知らせ 0件/複数件の表示パターン。
   * 機能タイル 6件の表示と `isEnabled` の挙動。

5. **Task-5:** ESLint / TypeScript チェックを実行し、エラー無しの状態にする。

   * `npm run lint`
   * `npm run type-check`（存在する場合）

### 5.2 実装時の補足

* コンポーネント名・Props 名・型定義は、詳細設計書の記載から変更しないこと。
* Tailwind クラスは LoginPage とのトーン整合を優先しつつ、SP 縦向きでの視認性を確保する。

---

## 6. 禁止事項・制約

1. **設計書の無断変更禁止**

   * 詳細設計・基本設計に記載のない仕様を勝手に追加・変更しないこと。
2. **Supabase / Auth フローの変更禁止**

   * Supabase クライアントコード・テーブル定義・RLS ポリシー・MagicLink フローに手を入れないこと。
3. **共通部品の仕様変更禁止**

   * AppHeader / AppFooter / StaticI18nProvider / LanguageSwitch の Props 変更・挙動変更を行わないこと。
4. **新規ライブラリ導入禁止**

   * `package.json` に新しい依存ライブラリを追加しないこと。
5. **無関係なリファクタリング禁止**

   * タスクと無関係なファイルのリファクタリングやディレクトリ構成変更を行わないこと。

---

## 7. テスト・完了条件

### 7.1 実行すべきテスト

* `npm test`（または対象パッケージのテスト）

  * HomePage 関連テストがすべて PASS していること。
* Lint / Type-check

  * `npm run lint` がエラー無し。
  * `npm run type-check`（存在する場合）がエラー無し。

### 7.2 受け入れ条件

* HomePage 詳細設計 ch02〜ch07 の要件を満たしていること。
* `/home` 表示時に、

  * 上部に「最新のお知らせ」セクション（ダミー 1〜2件または 0件時メッセージ）、
  * 下部に機能タイル 2×3 が表示されること。
* AI 自己評価で 10 段階中 9 点以上と判断できること。

---

## 8. CodeAgent_Report の出力

本タスク完了時、Windsurf は CodeAgent_Report を作成し、以下のパスに保存すること。

* `/01_docs/06_品質チェック/CodeAgent_Report_H00-UI-HomePage-Layout_v1.0.md`

### 8.1 CodeAgent_Report に含める内容

* Task ID / Component ID / 実行日時
* 参照した設計書とバージョン
* 変更・追加したファイル一覧
* 実行したテストコマンドと結果（Jest / Lint / Type-check）
* 自己評価スコア（10 段階）
* 設計との乖離・注意点・今後の改善候補（任意）

---

**End of Document**
