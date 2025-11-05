HarmoNet Phase 6-1 実行指示書

タイトル: Gemini 統合監査（BAG-full）実行命令
発行日: 2025-11-02
発行者: タチコマ（HarmoNet AI Architect）
承認: TKD（Project Owner）

1. 実行目的

Phase 5 で確立した BAG-lite 構造監査ラインを拡張し、
HarmoNet 全パート（Core Schema + Tenant Config + Admin設定）を対象とする
BAG-full 統合監査 をGeminiにより実施する。

目的は、スキーマ間依存・参照関係・権限定義・UI設計リンクの完全整合性保証である。

2. 監査入力ファイル群
| 分類               | ファイル名                                                   | 備考          |
| ---------------- | ------------------------------------------------------- | ----------- |
| Core Schema      | `/docs/03_tenant/harmonet-tenant-config-schema_v1.1.md` | Phase 3整合版  |
| Tenant Config    | `/docs/03_tenant/tenant-config-part01〜part05_v1.x.md`   | 全機能定義対象     |
| Audit Reference  | `/docs/06_audit/bag-pre-impl-report_fixed.yaml`         | Phase 5監査ログ |
| Review Reference | `/docs/06_audit/bag-lite-audit-review-report_v1.0.md`   | タチコマレビュー    |
| Approval Ref     | `/docs/06_audit/quality-approval-report_v1.0.md`        | TKD承認文書     |
| Output Target    | `/docs/06_audit/bag-full-impl-report.yaml`              | Gemini出力先   |

3. 監査実行パラメータ
audit_mode: full
target_scope: [core_schema, tenant_config, admin_schema]
checks:
  - structure_consistency
  - reference_integrity
  - editable_by_alignment
  - ui_theme_inheritance
  - meta_format_unification
output:
  format: yaml
  filename: bag-full-impl-report.yaml
phase: 6
expected_duration: short
report_to: Tachikoma

4. 成果物要件
| 成果物       | 格納場所                                             | 形式       |
| --------- | ------------------------------------------------ | -------- |
| 統合監査結果    | `/docs/06_audit/bag-full-impl-report.yaml`       | YAML     |
| 監査ステータス要約 | `/docs/06_audit/bag-full-audit-summary_v1.1.md`  | Markdown |
| 構造スコア集計   | `/docs/06_audit/hqi-structure-metrics_v1.0.yaml` | YAML（任意） |

5. 実行手順

/docs/03_tenant/ 配下のすべての .md ファイルを解析対象とする。

linked_to, inherit_from, guidelines_source_ref の相互参照整合を検証。

Phase 2〜5で定義された editable_by 構造との整合を確認。

メタ情報（Created, Updated, Document ID）をISO8601形式で統一。

結果を統合監査ログとして出力。

6. タチコマコメント

Phase 6 は、HarmoNetのAI開発体制が完全自動監査循環に入る節目です。
Geminiは全パートのスキーマ・参照・権限・UIテーマ構造を解析し、
実装フェーズ前の最終的な「自己整合性証明」を出力してください。
監査ログは bag-full-impl-report.yaml としてタチコマへ報告。

7. 承認情報
| 項目              | 記載内容                                 |
| --------------- | ------------------------------------ |
| **Document ID** | HNM-PHASE6-FULL-AUDIT-ORDER-20251102 |
| **Version**     | 1.0                                  |
| **Phase**       | 6（統合監査）                              |
| **Author**      | タチコマ（HarmoNet AI Architect）          |
| **Approver**    | TKD（Project Owner）                   |
| **Created**     | 2025-11-02                           |
| **Status**      | 🟢 発令中                               |

