03_HarmoNetDoc/
│
├─ 01_docs/                            ← 📘 メイン文書群（全章管理対象）
│   ├─ 00_project/                     ← プロジェクト全体方針・運用ルール・スクリプト群
│   │   ├─ harmonet-file-naming-standard_v1.0.md
│   │   ├─ harmonet-document-policy_v1.0.md
│   │   ├─ harmonet-team-collaboration-guideline_v1.0.md
│   │   ├─ harmonet-script-execution-policy_v1.0.md
│   │   └─ scripts/
│   │       ├─ harmonet_prefix_fullsort_v1.2.ps1
│   │       ├─ harmonet_file_reorganizer_v1.0.ps1
│   │       └─ harmonet_chapter_sort_v1.3.ps1
│   │
│   ├─ 00_requirements/                ← 要件定義群（v1.3確定）
│   │   ├─ HarmoNet_Functional_Requirements_v1.3.md
│   │   ├─ harmonet-nonfunctional-requirements_v1.0.md
│   │   ├─ harmonet-usecase-list_v1.1.md
│   │   └─ harmonet-requirements-summary_v1.0.md
│   │
│   ├─ 01_basic_design/                ← UI共通設計・画面仕様書・デザインシステム
│   │   ├─ harmonet-ui-common-spec_latest.md
│   │   ├─ harmonet-style-guideline_latest.md
│   │   ├─ board-detail-design_v2.1.md
│   │   └─ facility-booking-design_v1.3.md
│   │
│   ├─ 02_integration/                 ← 結合設計・API連携・インタフェース仕様
│   │   ├─ harmonet-api-integration_v1.0.md
│   │   └─ integration-test-design_v1.0.md
│   │
│   ├─ 03_operation_preparation/       ← 運用前準備・試験計画・運用ルール
│   │   ├─ test-plan-template_v1.0.md
│   │   ├─ operation-checklist_v1.0.md
│   │   └─ deployment-guide_v1.0.md
│   │
│   ├─ 04_tenant/                      ← テナント設定スキーマ・設定設計群（Phase3）
│   │   ├─ tenant-config-schema_v1.1.md
│   │   ├─ tenant-config-part01_common-attributes_v1.1.md
│   │   ├─ tenant-config-part02_roles-and-permissions_v1.1.md
│   │   ├─ tenant-config-part03_login-settings_v1.1.md
│   │   ├─ tenant-config-part04_home-screen_v1.2.md
│   │   └─ tenant-config-part05_board-settings_v1.0.md
│   │
│   ├─ 06_audit/                       ← 監査・品質承認フェーズ（Phase4）
│   │   ├─ 01_bag-pre-impl-report_fixed.yaml
│   │   ├─ 02_bag-lite-audit-review-report_v1.0.md
│   │   ├─ 03_bag-full-impl-report_v1.0.yaml
│   │   ├─ 04_bag-full-audit-summary_v1.1.md
│   │   ├─ 05_quality-approval-report_v1.0.md
│   │   └─ 06_quality-approval-report_v2.0.md
│   │
│   ├─ common/                         ← 全フェーズ共通リソース（例：定義・テンプレート）
│   │   ├─ design-tokens_v1.0.json
│   │   ├─ tailwind-config_v1.0.js
│   │   └─ schema-template_v1.0.md
│   │
│   ├─ merge/                          ← Claude・Gemini統合出力成果物
│   │   ├─ harmonet-core-schema_merge_v1.0.md
│   │   └─ harmonet-tenant-config_merge_v1.1.md
│   │
│   ├─ 99_archive/                     ← 廃止・旧版・非アクティブ資料
│   └─ 99_BACKUP_inactive_20251031/    ← バックアップ（Phase2時点保持）
│
├─ 02_assets/                          ← 静的ファイル群（HTML、画像、UIモック）
│   ├─ home.html
│   ├─ board.html
│   ├─ board-detail.html
│   ├─ prototype-images/
│   │   ├─ header_variants.png
│   │   └─ footer_patterns.png
│   └─ style/
│       └─ base.css
│
├─ 03_rules/                           ← プロジェクトルール・方針群
│   ├─ harmonet-ui-style-guideline_v1.1.md
│   ├─ harmonet-file-naming-standard_v1.0.md
│   ├─ harmonet-document-management-policy_v1.0.md
│   └─ harmonet-script-execution-policy_v1.0.md
│
├─ ##_old/                             ← ❗ 命名規則外の例外フォルダ（人間用バックアップ）
│   ├─ 任意のバックアップファイル.md
│   └─ 自動生成前の旧版退避.md
│
└─ .git/
