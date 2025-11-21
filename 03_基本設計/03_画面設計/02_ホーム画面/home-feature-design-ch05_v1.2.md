# HOME 基本設計書 ch05：付録・関連資料

**Document:** HOME画面 基本設計書（コンテンツ領域）
**Chapter:** 5 / 5
**Version:** v1.2
**Updated:** 2025/11/21
**Author:** TKD / Tachikoma
**Supersedes:** home-feature-design-ch05_v1.1.md

---

## 5.1 本書の位置づけ

本章は、HOME 基本設計書（ch01〜ch04）と他設計書・実装タスクとの関係を整理し、
詳細設計および Windsurf 実装フェーズへの橋渡し情報のみを簡潔にまとめる。

* ch01：HOME の役割と掲示板との関係（NOTICE/ALL/RULES フィルタ前提）
* ch02：コンテンツ領域構成（「最新のお知らせ」＋「機能タイル 2×3」）
* ch03：お知らせセクション仕様（NOTICE タグ付き掲示のハイライト表示）
* ch04：機能タイル仕様（お知らせ／掲示板／施設予約／運用ルール／通知設定／ダミー）

本章は、これらの内容を前提とした「参照関係」と「今後のアウトプット」を定義する。

---

## 5.2 参照すべき関連資料一覧

HOME 基本設計書が前提とする関連資料をカテゴリ別に整理する。

### 5.2.1 共通 UI 部品（仕様は本書に記載しない）

以下の共通部品は、HOME 画面でも利用するが、詳細仕様はそれぞれの設計書に委譲する。

* C-01 AppHeader 詳細設計書
* C-02 LanguageSwitch 詳細設計書
* C-03 StaticI18nProvider 詳細設計書
* C-04 AppFooter 詳細設計書

※ FooterShortcutBar は現仕様では独立コンポーネントとしては扱わず、
AppFooter 詳細設計書の中でフッター内要素として定義する想定とする。

### 5.2.2 技術・方式

* harmonet-technical-stack-definition_v4.4
* 非機能要件定義書（NFR 最新版）
* 機能要件定義書 v1.6
* Supabase / RLS 設計書（掲示板・テナント設定・通知関連）

### 5.2.3 掲示板・関連機能

HOME のお知らせ／掲示板連携は、掲示板機能仕様を前提とする。

* 掲示板 基本設計書
* 掲示板 詳細設計書（掲示板TOP／投稿詳細／投稿作成）
* 掲示板カテゴリ・タグ定義（ALL / NOTICE / RULES 等）
* テナント設定設計書（HOME 上のお知らせ件数など）

---

## 5.3 HOME 詳細設計への橋渡し

HOME 基本設計の内容を実装レベルに落とし込むため、以下の HOME 詳細設計書を想定する。

### 5.3.1 HOME 詳細設計（候補構成）

1. HOME 詳細設計 ch01：画面構成・コンポーネント構造

   * `app/home/page.tsx` の JSX 構造
   * `HomeNoticeSection` / `HomeFeatureTiles` などのコンポ分割
2. HOME 詳細設計 ch02：お知らせセクション詳細

   * Tailwind クラス・レイアウト
   * NOTICE 投稿の取得ロジック（フロント側）
   * 0件時表示／ローディング状態
3. HOME 詳細設計 ch03：機能タイル詳細

   * 各タイルの Tailwind／Lucide アイコン定義
   * `isEnabled` フラグによる無効状態の扱い
4. HOME 詳細設計 ch04：i18n・メッセージ仕様

   * `home.json` に定義する i18n キー一覧
   * お知らせ 0件時メッセージ、タイルラベル、説明文

実際の章構成は、他画面の詳細設計書との整合を見て確定する。

### 5.3.2 基本設計と詳細設計の境界

本 HOME 基本設計書では、以下を対象外とする。

* Tailwind クラス（spacing / rounded / color 等の具体値）
* JSX 構造・DOM ツリーの最終形
* React Hooks（useState/useEffect 等）による状態管理ロジック
* Supabase クライアントコード・クエリ実装
* i18n JSON 実体（`home.json` の具体キーと文言）
* 画面遷移コード（Next.js Router の具体呼び出し）

これらはすべて HOME 詳細設計書の範囲とし、
本書では「何を」「どのような目的で」表示・遷移させるかのみを定義する。

---

## 5.4 Windsurf 実装タスクとの関係

Windsurf で HOME 画面を実装する際は、本基本設計書の各章を直接参照する。

* 参照対象（例）：

  * home-feature-design-ch01_v1.2（役割・前提）
  * home-feature-design-ch02_v1.2（レイアウト構成）
  * home-feature-design-ch03_v1.2（お知らせセクション仕様）
  * home-feature-design-ch04_v1.2（機能タイル仕様）

Windsurf 用作業指示書（例：`WS-H00_HomeLayout_v1.0.md`）では、
これらのファイルを **パス指定で直接参照** し、
ch00 index は使用しない方針とする。

Windsurf 指示書に記載すべきポイント（例）：

* 対象コンポーネント／ページ：`app/home/page.tsx` ほか
* 参照設計書：上記 ch01〜ch04 のパスを列挙
* 実装スコープ：

  * 「最新のお知らせ」セクションの UI（ダミーデータでも可）
  * 機能タイル 2×3 の UI（リンク無効、`isEnabled = false`）
* 非スコープ：

  * Supabase 連携（実データ取得）
  * 掲示板・施設予約・通知設定側画面の実装

---

## 5.5 本章まとめ

* 本章は、HOME 基本設計（ch01〜ch04）と、共通部品・掲示板・テナント設定・詳細設計・
  Windsurf 実装タスクとの関係を整理する付録である。
* 共通部品の仕様はすべて各詳細設計書へ委譲し、HOME 側では「どう配置し、どう連携するか」のみを扱う。
* HOME 詳細設計では、

  * お知らせセクション（NOTICE ハイライト）
  * 機能タイル（お知らせ／掲示板／施設予約／運用ルール／通知設定／ダミー）
    の UI・ロジック・i18n を、本基本設計を前提に具体化する。
* Windsurf 実装タスクは、index ではなく ch01〜ch04 ファイルを直接参照する運用とし、
  HOME の実装はこれら設計書を唯一の根拠として進める。

---

**End of Document**
