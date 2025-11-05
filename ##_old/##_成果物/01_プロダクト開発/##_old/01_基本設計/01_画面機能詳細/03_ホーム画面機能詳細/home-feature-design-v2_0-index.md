# 🏠 HOME画面 機能設計書 v2.0 - 目次

**Document ID:** SEC-APP-HOME-FEATURE-001  
**Version:** 2.0  
**Created:** 2025/10/27  
**Purpose:** HOME画面のコンテンツ領域における画面固有機能の詳細設計  
**Status:** Draft

---

## 📖 本設計書の目的

本設計書は、HOME画面の**コンテンツ領域に含まれる画面固有部分**の機能設計を定義します。

**対象範囲:**
- ✅ ウェルカムセクション（ユーザー情報表示）
- ✅ お知らせセクション（最新3件表示）
- ✅ 機能タイルセクション（各機能への導線）

**対象外（別紙参照）:**
- ❌ ヘッダー領域（共通部品設計書を参照）
- ❌ フッター領域（共通部品設計書を参照）
- ❌ データ設計・API仕様（技術設計書を参照）
- ❌ 実装詳細・パフォーマンス（実装ガイドを参照）

---

## 📚 目次

### [第1章: 概要と目的](home-feature-design-v2_0-ch01.md)
- 1.1 HOME画面の役割
- 1.2 設計の基本方針

### [第2章: コンテンツ領域構成](home-feature-design-v2_0-ch02.md)
- 2.1 コンテンツ領域の3つのセクション
- 2.2 各セクションの概要

### [第3章: ウェルカムセクション](home-feature-design-v2_0-ch03.md)
- 3.1 表示内容
- 3.2 多言語対応
- 3.3 デザイン仕様

### [第4章: お知らせセクション](home-feature-design-v2_0-ch04.md)
- 4.1 表示内容
- 4.2 表示項目
- 4.3 インタラクション
- 4.4 カテゴリバッジの色分け

### [第5章: 機能タイルセクション](home-feature-design-v2_0-ch05.md)
- 5.1 レイアウト
- 5.2 機能タイル一覧(MVP)
- 5.3 タイルの多言語対応
- 5.4 タイルのデザイン仕様

---

## 📄 関連ドキュメント

### 共通設計書
- `common-header-design-v1_0.md` - ヘッダー機能詳細設計書（予定）
- `common-footer-design-v1_0.md` - フッター機能詳細設計書（予定）
- `common-3layer-structure-v1_0.md` - 3層構造設計書（予定）

### デザインシステム
- `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.md` - デザイン哲学
- `02_DESIGN_SYSTEM_Tailwind_Specification_v1_0.md` - Tailwind仕様
- `02_DESIGN_SYSTEM_Design_Tokens_v1_0.json` - デザイントークン

### プロジェクト標準
- `naming-conventions-v2_1_EN.md` - 命名規則
- `code-generation-rules-v2_1_EN.md` - コード生成ルール
- `05_Project-Structure-v3_3_EN.md` - プロジェクト構造

---

## 📝 変更履歴

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0 | 2025/10/27 | TKD + Claude | 共通設計書から画面固有部分を分離・章分割 |
| 1.1 | 2025/10/27 | TKD + Claude | home-screen-design-v1_1.md（統合版） |

---

**End of Index**
