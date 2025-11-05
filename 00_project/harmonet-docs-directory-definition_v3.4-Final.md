# HarmoNet Docs Directory Definition v3.4

**Document ID:** HNM-DOCS-DIRECTORY-DEFINITION-20251105  
**Version:** 3.4  
**Created:** 2025-11-05  
**Last Updated:** 2025-11-05  
**Author:** Tachikoma (PMO Architect)  
**Approved:** TKD (Project Owner)

---

## 🏗️ 概要

本書は、HarmoNetプロジェクトにおける全設計・実装・監査・運用関連ドキュメントを体系的に管理するための**正式ディレクトリ定義書**である。  
Phase9（実装運用移行フェーズ）におけるリポジトリ再構築（2025-11-05）後の構成に基づき、  
本バージョン（v3.4）をもって、**統一運用ディレクトリ構成の確定版**とする。

---

## 🧭 ルート構成

/01_docs/
├─ 00_project/ ← プロジェクト統括・運用ルール・WBS・Phase文書群
├─ 00_requirements/ ← 要件定義・機能要件・非機能要件
├─ 01_basic_design/ ← 機能基本設計・UI設計・共通部品設計
├─ 02_design/ ← スキーマ設計・UI統合設計・データ連携設計
├─ 03_detail_design/ ← 実装寄り詳細設計・画面別設計書
├─ 04_tenant/ ← テナント設定・管理スキーマ・テナント別構成
├─ 05_implementation/ ← 実装関連資料・スクリプト・DB構成ファイル
├─ 06_audit/ ← 監査・品質保証・BAG解析レポート
├─ 07_release/ ← リリース手順・配布物・検収記録
├─ 99_archive/ ← アーカイブ・旧版・過去フェーズバックアップ
│
├─ 02_assets/ ← 画像・UI素材・静的HTML
├─ 02_integration/ ← 結合テスト・統合検証資料
├─ 03_operation_preparation/ ← 導入準備・運用マニュアル・教育資料
├─ 03_Rules/ ← 共通運用ルール・AIチーム規約・ドキュメント管理方針
│ ├─ 01-ALL-AI/ ← 全AIチーム共通ルール（運用・命名・変更管理）
│ ├─ 02-ForClaude/ ← Claude専用ルール（実行制約・整合化手順）
│ └─ 03-WorkFlow-Rules/ ← 新設：AI作業フロー・レビュー手順・承認ルート定義
│
├─ common/ ← 新設：AI横断的議事録・会議記録・分析メモ
├─ work/ ← 新設：作業中・提案中・調査資料などの一時保管領域
│
└─ merge/ ← 結合ファイル（Claude解析用統合版）


---

## 📘 各ディレクトリ詳細

### 00_project/
プロジェクト計画、WBS、Phase別ドキュメント、ルール・方針関連を格納。  
`harmonet-docs-directory-definition_*`, `harmonet-document-policy_latest.md` など管理の基幹文書を配置。

### 00_requirements/
要件定義フェーズ成果物。`harmonet-functional-requirements-ch**` 系を中心に構成。  
統合版 `HarmoNet_Functional_Requirements_v1.3_merged_for_Claude.md` を含む。

### 01_basic_design/
基本設計層（共通UI・デザインシステム・マルチテナント構造設計）。  
共通部品 (`common-*.md`)、デザインシステム、Tailwind設定、i18n仕様を含む。

### 02_design/
詳細設計・スキーマ・UI統合設計書・機能設計の派生要素を格納。  
`harmonet_screens_unification_proposal_v1.0.md` を含む。

### 03_detail_design/
画面別の詳細設計書（例：`board-detail-design-ch06_v2.2.md`）を中心とした構成。  
PDFプレビュー・翻訳・音声読み上げなどのUI仕様もここに属する。

### 04_tenant/
テナント設定構造および管理用スキーマ定義を格納。  
`harmonet-tenant-config-schema_v1.1.md` ほか、Phase3・4で策定した共通定義群を含む。

### 05_implementation/
実装工程関連資料。Supabase構築手順・ER定義・RLS設定・Prismaスキーマなど。  
Phase9では Cursor / Copilot 実装ログや SQL 生成ファイルもここに統合。

### 06_audit/
AI監査・BAG-lite・BAG-full解析・品質報告書などを格納。  
`harmonet_schema_consistency_report_YYYY-MM-DD.md` もこの層に保存。

### 07_release/
リリース手順書・チェックリスト・運用移管ドキュメントを格納。  
（Phase10で初使用予定）

### 99_archive/
フェーズ終了時点でのスナップショットを保持。  
例：`/99_archive/01_project_20251102-132115/`  
> アーカイブは「構造履歴」として保存し、過去文書は原則再利用せず参照専用。

---

### 02_assets/
画像・HTML・UI素材群を格納。UI検証や画面プレビュー用ファイルを管理。

### 02_integration/
システム結合試験・統合テスト用データおよび分析ログ。

### 03_operation_preparation/
導入準備段階の資料。運用マニュアル・研修用素材などを格納。

### 03_Rules/
AI開発体制の運用ルールをまとめる。  
v3.4では `03-WorkFlow-Rules/` を新設し、フェーズ間レビュー・承認フローを明示。

---

### 🆕 common/
AI横断的な議事録・チーム会議記録・考察メモを格納。  
主に「AI Council」などの意思決定ログを記録する領域。  
→ 旧 `/03_HarmoNetDoc/` 配下の議事録群をこちらに統合。

---

### 🆕 work/
タスク中の作業ファイル・実験・試作・一時調査資料を格納。  
命名ルールに従い、日付・作業種別でソート可能にする。  
例：`/work/20251105_environment_sync_notes.md`

---

## ❌ 廃止構成（Phase8以前）

| 廃止フォルダ | 対応方針 |
|---------------|-----------|
| `/03_HarmoNetDoc/` | すべて `/01_docs/` 構成へ移行済み。Phase9以降は使用禁止。 |
| `/##_成果物/` | `work/` および `99_archive/` に統合。 |
| `/03_HarmoNetDoc/docs/` | `/01_docs/00_project/` へ吸収。 |

---

## 🔒 命名・管理ポリシー

- ファイル名は `[prefix]_[subject]_v[major.minor].md` 形式を採用  
- 最新版参照は `_latest.md` 形式とし、過去版はアーカイブに移動  
- 各文書末尾には固定メタ情報（Created / Last Updated / Version / Document ID）を記載  
- 差分管理は行わず、**常に完全版を更新**する

---

## 🧾 ChangeLog

| Version | Date | Author | Summary |
|----------|------|---------|----------|
| v3.0 | 2025-10-25 | Tachikoma | 初版（Phase8設計反映） |
| v3.2 | 2025-10-30 | Tachikoma | Phase8構成統合・ルール整理 |
| v3.3 | 2025-11-03 | Tachikoma | Phase9準拠構成確定版 |
| **v3.4** | **2025-11-05** | **Tachikoma** | **リポジトリ再構築対応：`common`・`work` ディレクトリ追加、`03-WorkFlow-Rules` 追記、`03_HarmoNetDoc` 廃止** |

---

**Document ID:** HNM-DOCS-DIRECTORY-DEFINITION-20251105  
**Version:** 3.4  
**Created:** 2025-11-05  
**Approved:** TKD  
**Status:** ✅ Phase9正式採用

