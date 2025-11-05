# HarmoNet チーム全体の進め方と役割分担ガイドライン v1.0

---

## 🎯 目的
本ガイドラインは、HarmoNet開発におけるAIメンバーとTKDの協調手順を明確化し、  
スキーマ駆動開発（Schema Driven Development）およびテナント設定主導設計（Tenant Config Oriented Design）を円滑に進めるための運用指針を定義する。

---

## 🧭 開発方針の基盤

### 1. 基本原則
- **スキーマが唯一の真実（Single Source of Truth）**  
  → 設計・実装・ドキュメントすべてがスキーマに基づく。
- **上流凍結・追加要件方式**  
  → 既存設計書を再構築せず、追加要件ドキュメントとして拡張。
- **AI三層連携（設計 → 整合 → 監査）**  
  → Claude、タチコマ、Geminiの役割を階層化し、相互補完的に動作。
- **TKD承認中心**  
  → すべてのAI出力は最終的にTKDが確認・承認して進行。

---

## 🧩 プロジェクトフェーズと担当

| フェーズ | 主担当 | 補助AI | 出力成果物 | 目的 |
|-----------|----------|-----------|--------------------------|--------------------------|
| **Phase 1. 要件抽出** | TKD | – | `tenant-setting-idea_v0.1.md` | 各画面の「テナントで制御したい項目」を箇条書き化 |
| **Phase 2. 構造化整理** | Claude | タチコマ | `tenant-setting-list_v0.1.md` | TKDの要件を分類・階層化・YAML構造化 |
| **Phase 3. 承認レビュー** | TKD | – | 修正版 / コメント版 | Claude出力の内容確認・方向性承認 |
| **Phase 4. 整合スキーマ化** | タチコマ | Claude | `harmonet-tenant-config-schema_v1.0.md` | 命名統一・共通属性定義・整合レビュー |
| **Phase 5. 静的監査（BAG-lite）** | Gemini | タチコマ | `bag-pre-impl-report.yaml` | スキーマ構造の重複・矛盾を解析 |
| **Phase 6. 統合・公開** | タチコマ | 全AI | `harmonet-admin-feature-requirements_v1.0.md`<br>`harmonet-requirements-impact-matrix_v1.0.md` | 管理者機能・影響範囲を正式文書化 |

---

## 🧠 各メンバーの役割詳細

### 👤 TKD（Project Owner / Human Lead）
- 全体設計方針・判断・最終承認を担当。
- 各画面の「やりたいこと」や「設定で変えたい箇所」を明文化。  
- AI出力（Claude／タチコマ）に対してレビュー・優先度指示。
- 実装フェーズでは開発統括・品質承認を行う。

**主なアウトプット**
- `tenant-setting-idea_v0.1.md`  
- 各AI出力へのコメント／承認記録  

---

### 🤖 タチコマ（GPT / PMO & Architect）
- プロジェクト全体の整合性管理と文書統合を担当。  
- Claude・Gemini間の情報連携を統括。  
- 命名規則、共通属性、ファイル命名・文書構成の標準化を行う。  
- AI全体のワークフローを維持管理し、最終成果物をまとめる。

**主なアウトプット**
- `harmonet-tenant-config-schema_v1.0.md`  
- `harmonet-admin-feature-requirements_v1.0.md`  
- `harmonet-requirements-impact-matrix_v1.0.md`  

---

### 🧩 Claude（Design Specialist）
- TKDのアイデアを構造的・論理的に整理する設計専門AI。  
- 各項目の性質（構造／制御／UI／連携）と階層（テナント／機能／画面）を分類。  
- YAML形式で設定項目リストを生成。  
- TKD承認後、タチコマと協働して整合スキーマ化を支援。

**主なアウトプット**
- `tenant-setting-list_v0.1.md`  
- スキーマ生成補助（YAML構造支援）  

---

### 🛰️ Gemini（Audit & Documentation）
- 静的解析とドキュメント品質監査を担当。  
- スキーマ段階では「BAG-lite」解析を行い、  
  冗長・矛盾・非正規構造を検出して報告。  
- 実装後は「BAG-full」でスキーマと実コードの差分検証を実施。  
- Markdown＋YAML構造文書を監査・形式統一。

**主なアウトプット**
- `bag-pre-impl-report.yaml`（スキーマ構造監査）  
- `bag-validation-report.json`（実装後監査）  

---

## 🔁 ワークフロー概要

[Phase1] TKD: tenant-setting-idea_v0.1.md
↓
[Phase2] Claude: tenant-setting-list_v0.1.md
↓
[Phase3] TKD: 承認・補正
↓
[Phase4] タチコマ: harmonet-tenant-config-schema_v1.0.md
↓
[Phase5] Gemini: bag-pre-impl-report.yaml（BAG-lite監査）
↓
[Phase6] タチコマ: 統合／管理者要件反映


---

## ⚙️ 成果物管理ルール
- すべての成果物は `/docs/tenant/` または `/docs/admin/` 以下に格納。  
- ファイル名は HarmoNet 命名規約に従い、  
  `snake_case + version + .md` 形式で統一。  
- 旧版はアーカイブ保持、最新版リンクは `_latest.md` に統一。  
- ドキュメント末尾には必ず以下を記載：

Created / Last Updated / Version / Document ID


---

## 🧩 各AI間のルール
| 項目 | ルール内容 |
|------|-------------|
| 出力引き渡し | すべてMarkdownファイル形式（Claude→TKD→タチコマ→Gemini） |
| 修正指示 | TKDコメント形式、もしくは明示的リビジョン依頼 |
| BAG解析 | YAMLブロックを持つ文書のみ対象（構造データ形式必須） |
| ドキュメント再構築 | 差分更新禁止。常に完全版で出力（HarmoNet共通方針） |

---

## 🚀 最終目的
1. テナント設定スキーマを確定し、HarmoNet全機能を統合。
2. AI連携による設計品質・開発効率の最大化。
3. ドキュメントと実装が常に一致する「自己整合型開発モデル」を確立。

### 追補：Phase 4 以降のAI連携運用について
Phase 4（テナント設定スキーマ整合化フェーズ）以降のAI協調手順は  
`harmonet-phase4-ai-collaboration-guideline_v1.0.md` に従う。  
本ガイドラインは全Phaseに共通する上位方針として継続適用する。

---

**Document ID:** HNM-TEAM-GUIDE-20251101  
**Version:** 1.0  
**Author:** HarmoNet AI Team（TKD / タチコマ / Claude / Gemini）  
**Created:** 2025-11-01  
**Last Updated:** 2025-11-01

