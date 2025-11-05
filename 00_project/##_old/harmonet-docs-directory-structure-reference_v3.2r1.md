# HarmoNet Docs ディレクトリ構成とフォルダ説明書 v3.2r1
**Document Category:** PJ共通ドキュメント  
**Location:** `/01_docs/00_project/`  
**Status:** 承認済（Phase 7 完了）  
**Target:** Claude / Gemini / Tachikoma 共通参照用

---

## 📘 目的
本書は、HarmoNetプロジェクトの全AIメンバー（Claude・Gemini・Tachikoma）が参照する  
公式ドキュメント構成（v3.2r1）を定義する。  

AIチームは本構成に従い、各フェーズ文書の生成・監査・整合確認を行うこと。

---

## 🧭 ディレクトリ構成一覧（v3.2r1）

```
01_docs/
├─ 00_project/
│   ├─ docs/
│   ├─ scripts/
│   ├─ harmonet_dir_sync_v3.2r1.ps1
│   ├─ harmonet-docs-directory-definition_v3.2.md
│   ├─ harmonet-document-policy_latest.md
│   ├─ Phase関連ドキュメント（例：phase6, phase7, phase8 など）
│
├─ 00_requirements/
│   ├─ harmoNet 機能要件書群（ch00〜ch07）
│   ├─ HarmoNet_Technical_Stack_Definition_v3.2.md
│   └─ ##_old（旧版アーカイブ）
│
├─ 01_basic_design/
│   ├─ 00_common_components/
│   ├─ 01_design_system/
│   ├─ 02_screens/
│   │   ├─ 01_login/
│   │   ├─ 02_home/
│   │   ├─ 03_board/
│   │   ├─ 03_board-detail/
│   │   └─ 04_facility-booking/
│   ├─ 03_nonfunctional/
│   └─ 04_architecture/
│
├─ 02_integration/
│
├─ 03_operation_preparation/
│   └─ assets/
│       ├─ html/
│       └─ ui-images/
│
├─ 04_tenant/
│   ├─ tenant-config-schema・設定仕様群
│   └─ ##_old（旧スキーマ）
│
├─ 05_implementation/
│
├─ 06_audit/
│   ├─ BAG-lite / Full 監査・品質報告書
│   └─ quality-approval-report群
│
├─ 99_archive/
│   └─ 01_project_YYYYMMDD-HHMMSS/
│
├─ common/
│
└─ merge/
    ├─ Claude向け統合ファイル
    └─ ##_old（旧統合版）
```

---

## 🗂 各ディレクトリの説明

| ディレクトリ | 用途・説明 | 管理AI | 補足 |
|---------------|-------------|---------|------|
| **00_project** | HarmoNet全体の方針・承認文書・スクリプト群。AIメンバー共通の「運用・管理レイヤー」。 | Tachikoma | PJルール・Phase管理・運用スクリプトはここに格納。 |
| **00_requirements** | 要件定義書群（ch00〜ch07）。Phase 2で確定した機能／非機能要件を管理。 | Claude | Claudeが一次生成し、Tachikomaが整合監査。 |
| **01_basic_design** | 基本設計・UI設計・共通設計。各画面（login / home / board 等）の機能設計書を含む。 | Claude → Tachikoma | デザインガイドライン準拠。Geminiは整合監査担当。 |
| **02_integration** | 結合試験設計・API結合仕様等を配置予定。現時点ではプレースホルダ（空）。 | Tachikoma | Phase 8で利用予定。 |
| **03_operation_preparation** | 運用準備資料。UI資産（HTMLテンプレート・画像）を含む。 | Gemini | UIテスト・多言語確認用。 |
| **04_tenant** | テナント設定関連ドキュメント。スキーマ、ロール、設定仕様書など。 | Claude | Phase 4〜5の主文書群。`##_old` に旧版を保存。 |
| **05_implementation** | 実装ドキュメント・開発手順書など。Phase 8以降で使用予定。 | Tachikoma | v3.2方針で新設。現在は空でOK。 |
| **06_audit** | BAG-lite / Full 監査報告書。品質承認レポート。 | Gemini | 監査結果と品質承認記録を保存。 |
| **99_archive** | 自動退避領域。旧 `01_project` や廃止文書を日付付きで保存。 | Tachikoma | 削除禁止領域。ロールバック用バックアップ。 |
| **common** | 共通議事録・会議メモ・AI協議ログ。 | Tachikoma | PJ共通の軽量ドキュメント置き場。 |
| **merge** | Claudeが生成する統合ファイル（例：`_merged_for_Claude.md`）。 | Claude | 過去版は `##_old` に保存。 |

---

## 🧩 命名ルール補足
- 章番号（00〜06）は文書階層と連動。  
- フォルダ名はすべて **小文字＋アンダースコア形式**。  
- 一時退避フォルダ・旧版は **`##_old` または `99_archive/`** に保存。  
- 最新ドキュメント参照は `_latest.md` シンボリック形式を採用。

---

## 🔄 運用ルール（AIチーム共通）

| 項目 | 内容 |
|------|------|
| **Claude** | 新規文書生成・統合・Phase設計主導 |
| **Tachikoma** | 構造監査・整合性維持・ドキュメント命名統制 |
| **Gemini** | BAG-lite監査・品質・Drive整合性確認 |
| **TKD（人間オーナー）** | 最終承認およびGitバックアップ管理 |

---

## 🧭 構成更新履歴

| Version | Date | Description |
|----------|------|-------------|
| v3.2 | 2025-11-01 | Claude分析版ディレクトリ構成をベース確定 |
| v3.2r1 | 2025-11-02 | Tachikoma監査・自動整合スクリプト完了（Phase 7） |
| v3.3 | （予定） | ClaudeによるPhase 7最終反映版生成予定 |

---

**Document ID:** HNM-DIR-STRUCTURE-REF-20251102  
**Version:** 3.2r1  
**Created:** 2025-11-02  
**Author:** Tachikoma (PMO / Architect)  
**For:** Claude / Gemini / TKD 共通参照  
**Next Review:** Phase 8開始時（2025-11予定）
