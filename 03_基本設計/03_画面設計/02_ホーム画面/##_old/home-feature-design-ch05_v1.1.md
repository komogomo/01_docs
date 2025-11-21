# HOME 基本設計書 ch05：付録・関連資料

**Document:** HOME画面 基本設計書（コンテンツ領域）
**Chapter:** 5 / 5
**Updated:** 2025/11/19

---

## 5.1 本書の位置づけ

本章では、HOME 基本設計書が参照する上位・下位文書を整理し、
詳細設計および実装フェーズへの橋渡し情報のみを簡潔にまとめる。

---

## 5.2 参照すべき関連資料一覧

HOME 基本設計書は以下の共通仕様・詳細設計書を参照する：

### ■ 共通UI部品（仕様は本書に記載しない）

* C-01 AppHeader 詳細設計書
* C-02 LanguageSwitch 詳細設計書
* C-03 StaticI18nProvider 詳細設計書
* C-04 AppFooter 詳細設計書
* C-05 FooterShortcutBar 詳細設計書

### ■ 技術・方式

* harmoNet-technical-stack-definition_v4.4
* 非機能要件定義書（NFR）
* 機能要件定義書 v1.6

### ■ HOME 詳細設計（後続で作成）

* HOME詳細設計 ch03：お知らせセクション詳細
* HOME詳細設計 ch04：機能タイル詳細
* HOME詳細設計 共通 UI 差し込み仕様（Header/Footer含む）

---

## 5.3 基本設計と詳細設計の境界

本書は **基本設計レベル** のため、以下は扱わない：

* Tailwind クラス（spacing/rounded/color 等）
* JSX 構造・DOM ツリーの最終形
* 状態管理・ロジック（useState/useEffect）
* Supabase 連携仕様
* i18n JSON 実体
* 画面遷移コード（Next.js Router）

これらはすべて HOME **詳細設計書** にて規定される。

---

## 5.4 今後の作成物（HOME詳細設計）

詳細設計で作成される主要アウトプット：

1. お知らせセクション UI 仕様（Tailwind + JSX）
2. 機能タイル UI 仕様（Lucideアイコン定義含む）
3. i18n キー表 + 翻訳 JSON（home.json 予定）
4. HOME レイアウト・状態遷移図
5. Windsurf 実装タスク WS-Axx_Home_xxx

---

## 5.5 本章まとめ

* 本章は HOME 基本設計の全体を補完する付録である
* 仕様重複を避け、共通部品はすべて共通設計書へ委譲
* HOME 詳細設計との境界を明確化し、実装フェーズへの指針を示す

---

**End of Document **
