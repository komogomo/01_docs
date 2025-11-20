# HarmoNet 共通部品 詳細設計書 - Index（C-01〜C-05）v1.1

**Document ID:** HARMONET-COMPONENTS-C00-INDEX
**Version:** 1.1
**Supersedes:** v1.0（初版未作成のため実質初版）
**Updated:** 2025-11-16
**Scope:** C-01 / C-02 / C-03 / C-04 / C-05（全5コンポーネント）

---

## 1. 本書の目的

本書は、HarmoNet のログイン画面および認証後画面で使用される **共通 UI コンポーネント（C-01〜C-05）** の詳細設計書群を横断的に管理するための **公式インデックス** である。
各コンポーネントの役割・依存関係・配置位置・詳細設計書へのリンクを体系的にまとめ、Windsurf / Cursor / Gemini / Claude が迷わず参照できる状態を作ることを目的とする。

本 Index は、以下の共通部品 5 点で構成される：

* **C-01 AppHeader**
* **C-02 LanguageSwitch**
* **C-03 StaticI18nProvider**
* **C-04 AppFooter**
* **C-05 FooterShortcutBar**

これらはすべて **技術スタック v4.3** に準拠し、**詳細設計アジェンダ標準 v1.0** に従って記述されている。

---

## 2. コンポーネント全体構成（俯瞰図）

```
app/layout.tsx
 └─ StaticI18nProvider (C-03)
      ├─ AppHeader (C-01)
      │    └─ LanguageSwitch (C-02)
      ├─ {children}
      ├─ AppFooter (C-04)
      └─ FooterShortcutBar (C-05)  ※ログイン後のみ
```

### 共通ルール（v1.1）

* すべての共通部品は **src/components/common/** 配下に配置する。
* import パスは **@/src/components/common/** で統一。
* 翻訳は必ず **StaticI18nProvider（C-03）→ useI18n()** 経由で取得。
* Logger（共通ログユーティリティ v1.1）は **C-01 と C-05 の UI 操作では使用しない**（親側が出力）。
* デザインは **HarmoNet Design System v1.1** に準拠し、"やさしく・自然・控えめ" を基調とする。

---

## 3. コンポーネント一覧（C-01〜C-05）

### C-01 AppHeader（v1.1）

| 項目     | 内容                           |
| ------ | ---------------------------- |
| 役割     | 画面最上部の共通ヘッダー（ロゴ・言語切替・通知アイコン） |
| 画面     | ログイン／認証後共通                   |
| 依存     | C-02 LanguageSwitch          |
| 状態     | Stateless                    |
| Logger | 直接使用しない                      |
| 詳細設計   | **ch01_AppHeader_v1.1.md**   |

---

### C-02 LanguageSwitch（v1.1）

| 項目     | 内容                              |
| ------ | ------------------------------- |
| 役割     | JA／EN／ZH の 3 言語切替ボタン            |
| 画面     | 全画面（ログイン含む）                     |
| 依存     | C-03 StaticI18nProvider         |
| 状態     | Stateless                       |
| Logger | 直接使用しない                         |
| 詳細設計   | **ch02_LanguageSwitch_v1.1.md** |

---

### C-03 StaticI18nProvider（v1.1）

| 項目     | 内容                                  |
| ------ | ----------------------------------- |
| 役割     | 翻訳辞書ロード／locale 管理／t(key) 提供         |
| 画面     | すべて（ルートレイアウトに配置）                    |
| 依存     | public/locales/... の JSON 静的辞書      |
| 状態     | locale / translations を内部保持         |
| Logger | 使用しない（辞書ロード失敗は console のみ）          |
| 詳細設計   | **ch03_StaticI18nProvider_v1.1.md** |

---

### C-04 AppFooter（v1.1）

| 項目     | 内容                         |
| ------ | -------------------------- |
| 役割     | 画面最下部のコピーライト表示             |
| 画面     | 全画面共通                      |
| 依存     | C-03 StaticI18nProvider    |
| 状態     | Stateless                  |
| Logger | 使用しない                      |
| 詳細設計   | **ch04_AppFooter_v1.1.md** |

---

### C-05 FooterShortcutBar（v1.1）

| 項目     | 内容                                                    |
| ------ | ----------------------------------------------------- |
| 役割     | ログイン後の主要画面へのショートカットナビゲーション                            |
| 画面     | 認証後画面のみ                                               |
| 依存     | C-03 StaticI18nProvider / next/navigation / next/link |
| 状態     | Stateless（role に応じて表示分岐）                              |
| Logger | 直接使用しない（MainLayout側で出力）                               |
| 詳細設計   | **ch05_FooterShortcutBar_v1.1.md**                    |

---

## 4. バージョン管理方針（共通部品セット v1.1）

* 共通部品群は **必ずセットでバージョン管理**する。
* 個別コンポーネントの更新が発生した場合でも、Index は最新の整合状態を必ず反映する。
* Windsurf 実装タスクで参照する際は、この Index を起点としてすべての関連設計書へ到達できることを保証する。

---

## 5. 参照関係（Windsurf / Cursor / Gemini 用）

```
C-03 StaticI18nProvider → 全ての UI コンポーネント
C-01 AppHeader → C-02 LanguageSwitch
C-04 AppFooter → 単独
C-05 FooterShortcutBar → role情報（親から）、i18n
```

Windsurf の作業指示書では、必ず本 Index を **参照ドキュメント一覧の先頭**に置くこと。

---

## 6. 注意事項（共通セット運用ルール）

* Design System v1.1 の色・角丸・余白・影の基準を統一して適用する。
* i18n キーは "common.*", "shortcut.*" など命名規則に従う。
* 共通部品は **認証ロジックやビジネスロジックを持たない**。
* props で受け取る値は UI 設計上必要な最小限に制限する（C-05 の role など）。
* すべての詳細設計書は **HarmoNet 詳細設計アジェンダ標準 v1.0** に準拠する。

---

## 7. 改訂履歴

| Version | Date       | Summary                               |
| ------- | ---------- | ------------------------------------- |
| 1.1     | 2025-11-16 | C-01〜C-05 最新版（v1.1）に基づく正式 Index を初作成。 |

---

**End of Document**
