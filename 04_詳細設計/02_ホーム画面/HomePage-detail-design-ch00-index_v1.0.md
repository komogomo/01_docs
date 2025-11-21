# HomePage 詳細設計書 ch00：Index v1.0

**Document ID:** HARMONET-H00-HOMEPAGE-INDEX
**Version:** 1.0
**Status:** Draft（MagicLink ログイン後 HOME 専用）

---

# 第1章：目的

HomePage 詳細設計（ch01〜ch08）の **全体像を示すインデックス**として、各章の役割・責務・依存関係を簡潔に整理する。
本章は仕様そのものを記述せず、**構造の俯瞰と章間の関係のみ**を示す。

対象は、ログイン完了後に遷移する `/home` 画面（H-00 HomePage）のうち、
コンテンツ領域（最新のお知らせ＋機能タイル）の詳細設計である。

---

# 第2章：章構成一覧（HomePage 8章構成）

H-00 HomePage の詳細設計は、以下 8 章で構成する想定とする。

* **ch01 概要**
  HomePage の役割、前提条件、関連コンポーネント（AppHeader/AppFooter との関係）、利用者視点での目的を整理する。

* **ch02 画面構成・コンポーネント構造**
  `/home` のレイアウト構成、`HomePage` / `HomeNoticeSection` / `HomeFeatureTiles` などのコンポーネントツリー、
  レスポンシブ方針（スマートフォン縦画面前提）を定義する。

* **ch03 コンポーネント仕様（Props / State / 型定義）**
  各コンポーネントの責務・Props・内部状態・型定義（`HomeNoticeItem` / `HomeFeatureTileDefinition` など）を定義する。

* **ch04 データ連携・状態管理**
  NOTICE タグ付きお知らせの取得方針（将来の Supabase 連携前提）、テナント設定に基づく表示件数、
  機能タイル定義（静的テーブル）と `isEnabled` フラグの扱いを整理する。

* **ch05 画面挙動・状態遷移・メッセージ仕様**
  `/home` 初期表示フロー、0件時表示、機能タイルの有効/無効挙動、
  HOME 固有のメッセージ・ラベル（「最新のお知らせ」「現在表示するお知らせはありません。」等）の仕様を定義する。

* **ch06 結合構成（共通部品・他画面との関係）**
  AppHeader/AppFooter/StaticI18nProvider との結合関係、LoginPage からの遷移、
  将来導線となる掲示板・施設予約・通知設定画面との関係を整理する。

* **ch07 テスト観点・Jest/RTL ケース一覧**
  HomePage の単体テスト方針、コンポーネント単位のテスト観点、
  お知らせ表示件数・0件時・タイル有効/無効などのテストケースを列挙する。

---

# 第3章：技術前提（現行仕様）

* **Next.js 16 / React 19 / TypeScript 5.6**
* **Supabase Auth（MagicLink 専用ログイン後の画面として /home を利用）**
* StaticI18nProvider（C-03）による 3 言語（ja/en/zh）切替
* 白基調・Appleカタログ風 UI、BIZ UD ゴシック前提
* 共通部品（C-01 AppHeader / C-04 AppFooter / C-02 LanguageSwitch）との整合
* 掲示板機能：NOTICE/ALL/RULES などのタグによるフィルタ表示を前提とする

HomePage は、ログイン後に最初に表示されるポータル画面として、
「最新のお知らせ」と「機能タイル 2×3」をコンテンツ領域に持つことを前提とする（HOME 基本設計 ch01〜ch04 参照）。

---

# 第4章：設計思想（H-00 全体指針）

HomePage は、以下の設計思想に基づいて設計する。

* **認証ロジックを持たない UI ポータルコンポーネント**
  ログイン状態・セッション確立は LoginPage / MagicLinkForm / AuthCallbackHandler 側の責務とし、
  HomePage は「ログイン後に利用者が最初に触れる情報と機能リンク」を提供することに専念する。

* **公式情報のハイライト＋機能ポータル**
  掲示板は雑談板を持たない「公式情報のハブ」として扱い、HomePage では NOTICE タグ付きのお知らせのハイライト表示と、
  掲示板／施設予約／運用ルール／通知設定などの入口をまとめる。

* **構造固定・責務分離**
  `/home` のレイアウト構造は、AppHeader／お知らせセクション／機能タイル／AppFooter の 4ブロックとして固定し、
  個々のコンポーネントは UI 表現と軽量な状態管理のみに責務を限定する。

* **将来のデータ連携・機能拡張を見据えた設計**
  初期実装（MVP）ではダミーデータ・リンク無効で実装しつつ、
  将来 Supabase 連携やテナント機能フラグ導入時に差し替えやすい構造を意識する。

---

# 第5章：関連ドキュメント（現行仕様のみ）

* **HomePage 基本設計 ch01〜ch05**（HOME コンテンツ領域の上位設計）
* **A-00 LoginPage 詳細設計 v1.x**（ログイン後遷移元の画面）
* **A-01 MagicLinkForm 詳細設計 v1.x**
* **A-03 AuthCallbackHandler 詳細設計 v1.x**（/auth/callback）
* **掲示板機能 詳細設計（BoardTop / BoardDetail）**
* **施設予約機能 詳細設計**
* **通知設定機能 詳細設計**
* **StaticI18nProvider / AppHeader / AppFooter 詳細設計**
* **harmonet-technical-stack-definition_v4.4**
* **機能要件定義書 v1.6 / 非機能要件定義書 v1.0**

HomePage 詳細設計は、上記ドキュメントとの整合を前提とし、
特に HOME 基本設計と LoginPage 詳細設計の構造・責務分離を尊重する。

---

# 第6章：改訂履歴

| Version | Summary                  |
| ------- | ------------------------ |
| v1.0    | 初版作成。HomePage 用 8章構成を定義。 |

---

**End of Document**
