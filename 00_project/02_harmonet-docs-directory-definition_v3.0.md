# HarmoNet Docs Directory Definition v3.0
HarmoNetプロジェクト全体のドキュメント構造定義。

目的：  
・フェーズごと／役割ごとに明確な格納先を持たせ、  
　AI間での文書参照・連携を容易にする。  
・ファイル種別を階層で整理し、設計〜実装〜監査を通して一貫性を保つ。  

---

## 🏗️ ルート構成
/docs
├─ 00_project/ ← プロジェクト統括・運用ルール
├─ 01_requirements/ ← 要件定義・機能要件書
├─ 02_design/ ← 機能詳細・UI・スキーマ設計
├─ 03_tenant/ ← テナント設定・管理設計
├─ 04_admin/ ← 管理者機能設計
├─ 05_implementation/ ← 実装関連・技術仕様
├─ 06_audit/ ← 監査・BAG解析・品質レポート
├─ 07_architecture/ ← 技術スタック・システム構成
└─ 99_archive/ ← 過去バージョン・アーカイブ


---

## 📘 ディレクトリ詳細

### 00_project/（PJ運営基盤）
| ファイル例 | 説明 |
|-------------|------|
| harmonet-team-collaboration-guideline_v1.0.md | チーム運用ガイドライン（現行） |
| harmonet-dev-shared-summary_2025-11-01.md | 開発方針・共有メモ |
| harmonet-requirements-impact-matrix_v1.0.md | 既存×追加要件の影響マップ |
| harmonet-document-policy_latest.md | 文書ルール・命名規則・更新手順 |
| project-wbs-outline.md | WBS概要・AIタスク分担表 |

---

### 01_requirements/（要件定義）
| ファイル例 | 説明 |
|-------------|------|
| harmonet-functional-requirements-ch03〜ch07_v1.3.txt | 既存の機能要件群（締結済み） |
| harmonet-functional-requirements_latest.md | 統合版（AI参照用） |
| harmonet-nonfunctional-requirements_v1.0.md | 非機能要件（SLA・RPO・運用体制等） |
| harmonet-additional-requirements_v1.0.md | 追加要件（テナント設定・管理者機能など） |

---

### 02_design/（設計）
| ファイル例 | 説明 |
|-------------|------|
| board-detail-design-ch01〜ch08_v2.x.md | 掲示板機能設計書群 |
| facility-booking-design-ch01_v1.3.md | 施設予約機能設計書 |
| ui-common-spec_latest.md | UI共通設計仕様書 |
| harmonet-style-guideline_latest.md | デザインガイドライン |
| schema-definition-overview_v1.0.md | スキーマ設計方針定義 |
| schema-template-reference.md | YAML/ER定義テンプレート |

---

### 03_tenant/（テナント設定）
| ファイル例 | 説明 |
|-------------|------|
| tenant-setting-idea_v0.1.md | TKD作成中ファイル |
| tenant-setting-list_v0.1.md | Claude出力（構造化リスト） |
| harmonet-tenant-config-schema_v1.0.md | タチコマ出力（正式スキーマ） |
| bag-pre-impl-report.yaml | Gemini監査（BAG-lite） |
| tenant-config-guideline_v1.0.md | テナント設定方針・ルール定義 |

---

### 04_admin/（管理者機能）
| ファイル例 | 説明 |
|-------------|------|
| harmonet-admin-feature-requirements_v1.0.md | 管理者機能要件書 |
| harmonet-admin-schema_v1.0.md | 管理者機能スキーマ |
| admin-ui-spec_v1.0.md | 管理画面UI設計 |
| admin-operation-flow_v1.0.md | 運用手順書（承認・バックアップなど） |

---

### 05_implementation/（実装）
| ファイル例 | 説明 |
|-------------|------|
| harmonet-technical-stack-definition_v3.2.md | 技術スタック定義（正ファイル） |
| api-endpoints-reference_v1.0.md | API定義一覧（REST/GraphQL） |
| prisma-schema_latest.prisma | Prismaスキーマ |
| docker-compose-config_v1.0.yaml | 開発環境構成 |
| deployment-flow_v1.0.md | デプロイ手順 |
| test-scenarios_v1.0.md | テストシナリオ定義 |
| data-migration-guide_v1.0.md | DBマイグレーション手順 |

---

### 06_audit/（監査・品質）
| ファイル例 | 説明 |
|-------------|------|
| bag-pre-impl-report.yaml | Gemini静的監査（設計段階） |
| bag-validation-report.json | Gemini実装監査（BAG-full） |
| qa-checklist_v1.0.md | 品質確認チェックリスト |
| release-review-log_v1.0.md | リリース前レビュー記録 |
| anomaly-analysis-log_v1.0.md | 不具合・逸脱分析ログ |

---

### 07_architecture/（システム構成・技術資料）
| ファイル例 | 説明 |
|-------------|------|
| system-architecture-diagram_v1.0.drawio | 全体構成図（フロント・API・DB） |
| environment-definition_v1.0.md | 開発／検証／本番環境の仕様 |
| network-topology_v1.0.md | ネットワーク設計（DNS・証明書・LBなど） |
| backup-policy_v1.0.md | バックアップ方針・周期・対象 |
| security-architecture_v1.0.md | 認証・鍵管理・脆弱性対策 |
| sso-integration-design_v1.0.md | シングルサインオン設計 |
| api-gateway-policy_v1.0.md | APIゲートウェイ設計方針 |

---

### 99_archive/（履歴管理）
- 各ディレクトリの旧版ファイルをここに退避。  
- 例: `board-detail-design-ch06_v2.1.md → /99_archive/design/board-detail-design-ch06_v2.1.md`

---

## 🧩 運用ルール
- すべての最新版リンクは `_latest.md` 形式で保持。
- 各文書末尾に必ず以下を記載：

Created / Last Updated / Version / Document ID

- 差分更新は禁止、常に完全版を出力。
- Claude・Gemini・タチコマすべてが `/docs` を共通参照ディレクトリとする。
- `.md` ファイルがAI間の唯一の受け渡し形式。

---

## 🔧 補足
- **Claude** → `/03_tenant` および `/02_design` の構造化担当。  
- **Gemini** → `/06_audit` 管轄。BAG解析結果格納先。  
- **タチコマ** → 全階層を横断し、統合／整合性レビューを担当。  
- **TKD** → `/00_project` および `/01_requirements` の人間承認権限保持者。

---

**Document ID:** HNM-DIR-DEF-20251101  
**Version:** 3.0  
**Created:** 2025-11-01  
**Author:** タチコマ（HarmoNet AI Architect）
