# MagicLinkForm 詳細設計書 - Index（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-INDEX
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式仕様（技術スタック v4.0 対応）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 📘 概要

本ドキュメントは HarmoNet ログイン画面コンポーネント群のうち、
**MagicLinkForm (A-01)** の詳細設計を章構成で管理するインデックスである。
MagicLinkForm は Supabase Auth の `signInWithOtp()` を用いて Magic Link （ワンタップ ログイン）を送信する。
Phase9 では Passkey ( A-02 ) と併用し、完全パスワードレス認証を構成する。

---

## 🧩 技術基準

* **Next.js 16 (App Router)**
* **React 19 / TypeScript 5.6**
* **Supabase JS SDK v2.43 (auth.signInWithOtp)**
* **StaticI18nProvider (C-03)** による i18n 対応
* **BIZ UD ゴシック + Apple カタログ風 UI** 準拠
* **Corbado SDK (@corbado/react)** との整合性確保（共通認証基盤）
* **RLS 適用済み PostgreSQL 17 / tenant_id 分離**

---

## 📂 章構成一覧

| 章番号 | ファイル名                                    | 内容概要                     |
| :-- | :--------------------------------------- | :----------------------- |
| 第1章 | MagicLinkForm-detail-design_ch01_v1.0.md | 概要・責務・前提技術               |
| 第2章 | MagicLinkForm-detail-design_ch02_v1.0.md | 機能設計（Props／State／イベント定義） |
| 第3章 | MagicLinkForm-detail-design_ch03_v1.0.md | 処理ロジック設計                 |
| 第4章 | MagicLinkForm-detail-design_ch04_v1.0.md | UI／スタイル仕様                |
| 第5章 | MagicLinkForm-detail-design_ch05_v1.0.md | テスト仕様（UT／結合／E2E）         |
| 第6章 | MagicLinkForm-detail-design_ch06_v1.0.md | セキュリティ／UX考慮事項            |
| 第7章 | MagicLinkForm-detail-design_ch07_v1.0.md | 環境設定・依存構成                |
| 第8章 | MagicLinkForm-detail-design_ch08_v1.0.md | 監査・保守方針                  |
| 第9章 | MagicLinkForm-detail-design_ch09_v1.0.md | Change Log               |

---

## 🔗 参照文書

* `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.0.md`
* `/01_docs/04_詳細設計/01_ログイン画面/PasskeyButton-detail-design_v1.4.md`
* `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md`
* `schema.prisma` （RLS スキーマ v1.7）
* `20251107000000_initial_schema.sql` / `20251107000001_enable_rls_policies.sql`
* `HarmoNet_Phase9_DB_Construction_Report_v1_0.md`
* `harmonet-detail-design-agenda-standard_v1.0.md`

---

## 🧾 Change Log

| Version | Date       | Summary                                           |
| :------ | :--------- | :------------------------------------------------ |
| v1.0    | 2025-11-11 | Phase9 正式化 。v1.1 (Phase8) を全面再編 。技術スタック v4.0 反映 。 |

---

**文書ステータス:** ✅ Phase9 正式整合版
**次のアクション:** 第1章 「概要・責務・前提技術」 へ 続く。
