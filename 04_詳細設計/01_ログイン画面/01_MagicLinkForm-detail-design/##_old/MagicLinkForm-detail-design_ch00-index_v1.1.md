# MagicLinkForm 詳細設計書 - Index（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-INDEX  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Component ID:** A-01  
**Component Name:** MagicLinkForm  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** Phase9 技術統合版（Next.js 16 / Supabase v2.43 / React 19）  

---

## 📘 概要

本ドキュメントは、HarmoNet ログイン画面コンポーネント群のうち、  
**MagicLinkForm（A-01）** の詳細設計を章構成で分割管理するものである。  
MagicLinkForm は、ユーザーがメールアドレスを入力して送信することで  
Supabase Auth が **Magic Link（ワンタップログイン）** を発行する機能を担う。  

---

## 🧩 技術基準
- **Next.js 16.0.1 (App Router)**  
- **React 19 / TypeScript 5.6**  
- **Supabase JS SDK v2.43+（auth.signInWithOtp）**  
- **StaticI18nProvider (共通部品)** によるi18n対応  
- **BIZ UDゴシック + Appleカタログ風UI** デザインルール準拠  
- **RLS・メールリンク有効期限短期化** によるセキュリティ強化  

---

## 📂 章構成一覧

| 章番号 | ファイル名 | 内容概要 |
|--------|-------------|----------|
| 第1章 | [MagicLinkForm-detail-design_ch01_v1.1.md](./MagicLinkForm-detail-design_ch01_v1.1.md) | 概要 |
| 第2章 | MagicLinkForm-detail-design_ch02_v1.1.md | 構造設計（Props / State / 型定義） |
| 第3章 | MagicLinkForm-detail-design_ch03_v1.1.md | ロジック設計（イベント・状態遷移） |
| 第4章 | MagicLinkForm-detail-design_ch04_v1.1.md | UI設計（レイアウト / コンポーネント構造） |
| 第5章 | MagicLinkForm-detail-design_ch05_v1.1.md | テスト仕様（単体 / 結合 / E2E） |
| 第6章 | MagicLinkForm-detail-design_ch06_v1.1.md | セキュリティ考慮事項 |
| 第7章 | MagicLinkForm-detail-design_ch07_v1.1.md | 環境設定 |
| 第8章 | MagicLinkForm-detail-design_ch08_v1.1.md | 監査・保守指針 |
| 第9章 | MagicLinkForm-detail-design_ch09_v1.1.md | ChangeLog |

---

## 🔗 参照文書
- /01_docs/00_project/harmonet-technical-stack-definition_v4.0.md  
- /01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md  
- schema.prisma  
- 20251107000000_initial_schema.sql  
- 20251107000001_enable_rls_policies.sql  

---

## 🧾 ChangeLog

| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様ベース） |
| v1.1 | 2025-11-10 | Phase9準拠。技術スタックv4.0反映、章構成分割化、index新設。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第1章 概要（ch01）を参照
