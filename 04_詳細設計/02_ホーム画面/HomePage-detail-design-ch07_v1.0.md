# HomePage 詳細設計書 ch07：テスト観点・Jest/RTL ケース一覧

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 7 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 7.1 本章の目的

本章では、H-00 HomePage（/home）に対する **単体テスト・コンポーネントテスト（Jest + React Testing Library）** の観点と、
主要なテストケース一覧を定義する。

* HomePage（/home ページ）
* HomeNoticeSection
* HomeFeatureTiles / HomeFeatureTile

を対象とし、UI 構造・挙動・メッセージ仕様が詳細設計通りであることを確認する。

---

## 7.2 テスト前提

* テストフレームワーク：Jest
* UI テスト：React Testing Library（@testing-library/react）
* i18n：StaticI18nProvider のテスト用ラッパ、もしくは `t()` をモックするヘルパを利用
* ルーティング：Next.js App Router に対しては、Router をモックし、
  HomePage では遷移呼び出しが発生しない（MVP）ことを前提とする。

MVP 段階では、Supabase 連携・テナント設定連携は行わず、
ダミーデータ・静的定義を前提としたテストのみ実施する。

---

## 7.3 HomePage コンポーネントのテスト観点

### 7.3.1 レンダリング構造

1. `/home` レンダリング時に、以下の要素が描画されること。

   * AppHeader
   * HomeNoticeSection
   * HomeFeatureTiles
   * AppFooter

2. Home コンテンツ領域が `<main>` 要素内に存在し、
   `HomeNoticeSection` → `HomeFeatureTiles` の順に描画されること。

3. HomePage レンダリング時に、致命的なエラー・例外が発生しないこと。

### 7.3.2 ダミーデータの適用（MVP）

4. HomePage レンダリング時、`MOCK_HOME_NOTICE_ITEMS` の内容に基づいて
   お知らせカードが 1〜2 件（デフォルト 2 件）表示されること。

5. HomePage レンダリング時、`HOME_FEATURE_TILES` の内容に基づいて
   機能タイルが 6 枚表示されること。

---

## 7.4 HomeNoticeSection のテスト観点

### 7.4.1 件数別表示

6. `items` が空配列のとき：

   * セクションタイトル（`home.noticeSection.title`）が表示されること。
   * 「0件時メッセージ」（`home.noticeSection.emptyMessage`）が表示されること。
   * お知らせカード（button 要素）が 0 件であること。

7. `items` が 1件で `maxItems=2` のとき：

   * タイトルが表示されること。
   * カードが 1件のみ表示されること。

8. `items` が 3件以上、`maxItems=2` のとき：

   * カードは 2件のみ表示されること。

9. `maxItems` が未指定のとき：

   * `DEFAULT_HOME_NOTICE_COUNT`（2）件まで表示されること。

10. `maxItems` に 0 や 4 が渡された場合でも、
    `clampNoticeCount` により 1〜3件の範囲に収まっていること（ユーティリティ単体テスト）。

### 7.4.2 カード内容

11. カード内に、

    * バッジ（「お知らせ」相当のテキスト）
    * 公開日（`publishedAt`）
    * タイトル
      が表示されること。

12. 各カードが `button` 要素としてレンダリングされていること。

13. カードの `aria-label` またはテキストとして、
    スクリーンリーダーがタイトル＋日付を読み上げられる構成になっていること（必要に応じて snapshot ベースで確認）。

### 7.4.3 クリック挙動（MVP）

14. MVP 段階では、カードをクリックしても Router の遷移関数が呼ばれていないこと。

将来、遷移ロジックを実装する際には、
「クリックで Router.push が呼ばれること」を別途追加テストとして定義する。

---

## 7.5 HomeFeatureTiles / HomeFeatureTile のテスト観点

### 7.5.1 タイル一覧表示

15. `HomeFeatureTiles` に `HOME_FEATURE_TILES` を渡したとき、
    タイルが 6 件レンダリングされること。

16. タイルの並び順が、配列順（お知らせ／掲示板／施設予約／運用ルール／通知設定／ダミー）と一致していること。

### 7.5.2 タイル内容

17. 各タイルに対して、ラベル（`t(labelKey)`）が表示されること。

18. 各タイルに対して、説明文（`t(descriptionKey)`）が表示されること。

19. 各タイルにアイコンコンポーネントが描画されていること（`svg` 要素存在確認など）。

### 7.5.3 isEnabled フラグの挙動

20. `isEnabled=false` のタイル：

    * `aria-disabled="true"` が設定されていること。
    * クリック時に `onClick` が呼ばれないこと（モック関数で確認）。

21. `isEnabled=true` のタイル：

    * `aria-disabled` が `false` または未設定であること。
    * クリック時に `onClick` が 1回だけ呼ばれること。

### 7.5.4 アクセシビリティ

22. 機能タイルセクションに `aria-labelledby` が設定され、タイトル要素と関連付けられていること。

23. キーボード操作（Tab キー）で、全タイルにフォーカスが移動できること（RTL の `userEvent.tab()` で確認）。

---

## 7.6 i18n・メッセージのテスト観点

24. HomePage レンダリング時、

    * `home.noticeSection.title`
    * `home.features.title`
      のキーに対応する文言が表示されていること（テスト用 i18n モックを利用）。

25. お知らせ 0件時に、`home.noticeSection.emptyMessage` に対応する文言が表示されること。

26. 各タイルラベル・説明について、指定した i18n キーの文言が表示されていること。

※ 実際の文言内容は i18n 設計書側でテスト対象とし、本テストでは「キーが正しく使用されているか」を主に確認する。

---

## 7.7 負荷・非機能観点（簡易）

27. HomePage レンダリング時に重大なパフォーマンスボトルネックがないこと。

* 初期描画で重い計算や不要な再レンダリングが発生していないこと（Profiler／簡易計測）。
* 機能タイル・お知らせ件数が少数である前提のため、本画面単体での負荷は軽微であること。

---

## 7.8 テストケース一覧（サマリ）

上記観点を、Jest テストケースとして整理したサマリ。

| No. | 対象                | シナリオ                              |
| --- | ----------------- | --------------------------------- |
| 1   | HomePage          | Header/Notice/Tiles/Footer が描画される |
| 2   | HomePage          | ダミーお知らせ 2件が表示される                  |
| 3   | HomePage          | 機能タイル 6件が表示される                    |
| 4   | HomeNoticeSection | 0件時に空メッセージが表示される                  |
| 5   | HomeNoticeSection | 3件中2件のみ表示される（maxItems=2）          |
| 6   | HomeNoticeSection | カードが button として描画される              |
| 7   | HomeFeatureTiles  | タイルが配列順で表示される                     |
| 8   | HomeFeatureTile   | isEnabled=false で onClick が呼ばれない  |
| 9   | HomeFeatureTile   | isEnabled=true で onClick が呼ばれる    |
| 10  | i18n メッセージ        | タイトル・ラベル・メッセージが i18n キー経由         |

詳細テストケースの記述（Given/When/Then 形式）は、Jest テストファイル側の責務とし、
本章では観点とシナリオの一覧に留める。

---

**End of Document**
