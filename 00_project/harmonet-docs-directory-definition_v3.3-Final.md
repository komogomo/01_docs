# HarmoNet Docs Directory Definition v3.3-Final  
**（Phase 9 最終版 ディレクトリ構成定義書）**

---

## 🎯 目的

HarmoNetプロジェクト全体のドキュメント構造をPhase9仕様として最終確定する。  
Claude（設計担当）・Gemini（監査担当）・タチコマ（PMO／アーキテクト）の3AI体制下で、  
フェーズをまたぐAI間参照およびDrive連携を保証するための唯一の正準構成とする。

---

## 🏗️ ルート構成

/01_docs/
├─ 00_project/ ← プロジェクト統括・運用ルール・WBS
├─ 01_requirements/ ← 要件定義・機能要件・非機能要件
├─ 02_design/ ← 機能詳細設計・UI設計・スキーマ設計
├─ 03_detail_design/ ← 実装寄り詳細設計・画面別設計書
├─ 04_tenant/ ← テナント設定・管理スキーマ
├─ 05_implementation/ ← 実装資料（※欠番許容、Phase9は未使用）
├─ 06_audit/ ← 監査・品質保証・BAG解析レポート
├─ 07_release/ ← リリース手順・配布物
├─ 99_archive/ ← アーカイブ・旧版
│
├─ 02_assets/ ← 画像・UI素材・HTMLモック等
├─ 03_rules/ ← 命名規則・デザインガイドライン等
├─ ##_old/ ← 一時退避・ローカルバックアップ（例外扱い）
└─ tools/ ← スクリプト・補助ツール類


---

## 📘 ディレクトリ詳細

### 00_project/（プロジェクト運営・統括）
| ファイル例 | 内容 |
|-------------|------|
| harmonet-team-collaboration-guideline_v1.0.md | AIチーム運用方針（Claude／Gemini／タチコマ連携） |
| harmonet-document-policy_latest.md | 命名・更新ルール・文書管理規約 |
| harmonet-dev-shared-summary_2025-11-01.md | 開発共有メモ・意思決定履歴 |
| harmonet-docs-directory-definition_v3.3-Final.md | 本定義書（Phase9確定版） |
| project-wbs-outline.md | WBS概要・AI担当フェーズ表 |

---

### 01_requirements/（要件定義）
| ファイル例 | 内容 |
|-------------|------|
| harmonet-functional-requirements-ch03〜ch07_v1.3.txt | 機能要件書群（締結済） |
| harmonet-functional-requirements_latest.md | 統合版（AI参照用） |
| harmonet-nonfunctional-requirements_v1.0.md | 非機能要件（SLA／RPO等） |
| harmonet-additional-requirements_v1.0.md | 追加要件（テナント・管理機能など） |

---

### 02_design/（設計）
| ファイル例 | 内容 |
|-------------|------|
| ui-common-spec_latest.md | UI共通設計仕様書（Appleカタログ風トーン準拠） |
| harmonet-style-guideline_latest.md | デザインガイドライン |
| board-detail-design-ch01〜ch08_v2.x.md | 掲示板詳細画面設計書群 |
| facility-booking-design-ch01〜ch07_v1.x.md | 施設予約画面設計書群 |
| schema-definition-overview_v1.0.md | スキーマ設計方針定義 |
| schema-template-reference.md | YAML／ER定義テンプレート |

---

### 03_detail_design/（画面別・機能別詳細設計）
| ファイル例 | 内容 |
|-------------|------|
| 01_login/ch00〜ch03/ | ログイン画面詳細設計（A型構造） |
| 02_home/ch00〜ch03/ | ホーム画面詳細設計（A型構造） |
| 03_board/ch00〜ch08/ | 掲示板画面（章別サブディレクトリ構造＝B型） |
| 03_board-detail/ch00〜ch08/ | 掲示板詳細画面（B型へ統一予定） |
| 04_facility-booking/ch00〜ch07/ | 施設予約（B型へ統一予定） |

> **注記:** Phase10以降、screens配下は案B（章別サブディレクトリ方式）へ統一予定。  
> 現行は混在構造を許容するが、UI共通仕様上の参照は `_latest.md` 経由で行う。

---

### 04_tenant/（テナント設定・スキーマ）
| ファイル例 | 内容 |
|-------------|------|
| harmonet-tenant-config-schema_v1.0.md | テナントスキーマ（正式版） |
| tenant-config-guideline_v1.0.md | 設定方針・運用ガイド |
| bag-pre-impl-report.yaml | Gemini監査（BAG-lite） |
| tenant-setting-list_v0.1.md | Claude構造化リスト（初期） |
| tenant-setting-idea_v0.1.md | TKD構想メモ（起点） |

---

### 05_implementation/（実装関連・技術仕様）  
※本ディレクトリは**欠番許容**。Phase9では直接使用しないが、将来拡張用に保持。  

| ファイル例 | 内容 |
|-------------|------|
| harmonet-technical-stack-definition_v3.3.md | 技術スタック定義書（正ファイル） |
| api-endpoints-reference_v1.0.md | API一覧（REST／GraphQL） |
| prisma-schema_latest.prisma | Prismaスキーマ |
| docker-compose-config_v1.0.yaml | Docker開発環境構成 |
| deployment-flow_v1.0.md | デプロイ手順書 |
| test-scenarios_v1.0.md | テストシナリオ |
| data-migration-guide_v1.0.md | データマイグレーション手順 |

---

### 06_audit/（監査・品質保証）
| ファイル例 | 内容 |
|-------------|------|
| bag-pre-impl-report.yaml | BAG-lite監査（構造監査） |
| bag-validation-report.json | 実装監査（BAG-full） |
| qa-checklist_v1.0.md | 品質確認チェックリスト |
| release-review-log_v1.0.md | リリース前レビュー記録 |
| anomaly-analysis-log_v1.0.md | 不具合分析・逸脱ログ |

---

### 07_release/（リリース・配布）
| ファイル例 | 内容 |
|-------------|------|
| release-procedure_v1.0.md | リリース手順書 |
| release-package-list_v1.0.md | 配布ファイル一覧 |
| release-approval-record_v1.0.md | 承認記録書 |
| changelog-summary_latest.md | 全体更新履歴要約 |

---

### 99_archive/（アーカイブ）
- 各ディレクトリの旧版・バックアップを集約  
- 命名例：  
  - `/99_archive/design/board-detail-design-ch06_v2.1.md`  
  - `/99_archive/tenant/harmonet-tenant-config-schema_v1.0.md`  

---

## 🧩 補助ディレクトリ

| ディレクトリ | 内容 |
|---------------|------|
| 02_assets/ | 画像、SVG、HTMLモック、UI素材 |
| 03_rules/ | 命名規則、デザインガイドライン、開発ルール |
| ##_old/ | 一時バックアップ。命名規則外として除外 |
| tools/ | スクリプト群（PowerShell, Node, Python など） |

---

## ⚙️ 運用ルール（Phase9基準）

1. **ファイル命名**
   - `{name}_v{version}.md` を基本形式とする  
   - 最新版は `_latest.md` シンボリック参照を設ける  
   - 日本語名ファイルは禁止  

2. **バージョン管理**
   - 差分出力は禁止。常に**完全版で更新**。  
   - 旧版は `/99_archive/` に退避し、メタ情報で履歴管理。

3. **文書末尾メタ情報**

Created: YYYY-MM-DD
Last Updated: YYYY-MM-DD
Version: x.x
Document ID: HNM-xxxx-yyyy


4. **AI三層連携ルール**
| AI | 主担当領域 | 主なファイル |
|----|-------------|--------------|
| Claude | 設計・構造化 | `/02_design/`, `/03_detail_design/` |
| タチコマ | PMO・整合管理 | 全階層（統合・最終承認） |
| Gemini | 監査・品質保証 | `/06_audit/` |

5. **Phase別運用**
- Phase7〜8: 設計完了・スキーマ確定  
- Phase9: 実装着手（Windsurf優先）  
- Phase10以降: 統一構造監査・screens案B統合

---

## 🧠 注意事項

- 章番号の欠番（05_implementation）は正式許容とする。  
- `tenant` と `audit` はPhase6完了済みのためリネーム対象外。  
- Drive／GitHub間のミラーリングは手動運用とする。  
- Claude・Gemini・タチコマはすべて `/01_docs/` 以下を共通参照。  

---

## ✅ Phase9承認事項

| 項目 | 承認者 | コメント |
|------|----------|----------|
| ディレクトリ構造 | タチコマ | `/01_docs/` 構成を正式採用 |
| 欠番05許容 | TKD | Phase9の要件外のため保留 |
| screens統一時期 | TKD | 実装完了後（Phase10で対応） |
| Document Policy整合 | Claude | v1.0に整合済み |
| 構造監査実施 | Gemini | BAG-lite適用済み（Phase6承認） |

---

**Document ID:** HNM-DIR-DEF-20251103-FINAL  
**Version:** 3.3-Final  
**Created:** 2025-11-03  
**Last Updated:** 2025-11-03  
**Author:** タチコマ（HarmoNet AI Architect）  
**Status:** ✅ Phase9確定・正式版  
