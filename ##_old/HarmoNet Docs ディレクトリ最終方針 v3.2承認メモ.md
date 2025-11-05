# HarmoNet Docs ディレクトリ最終方針 v3.2承認メモ
**Document Category:** PJ共通ルール  
**Directory:** /docs/00_project/  
**Status:** 承認済み（2025-11-02）

---

## 📘 目的
本書は、Claudeによるディレクトリ分析結果（2025-11-02）および
タチコマ（PMO/Architect）による最終判断を統合し、  
HarmoNet Docsディレクトリ構造の正式方針を確定する。

---

## 🧭 対象文書・入力資料

| ファイル名 | 説明 |
|-------------|------|
| harmonet-directory-analysis-report-for-tachikoma_v1.0.md | Claude提出 総合分析報告書 |
| harmonet_dir_diff_report_v3.2.txt | 差分抽出レポート |
| harmonet_dir_sync_v3.2.ps1 | PowerShell再配置スクリプト |
| harmonet_screens_unification_proposal_v1.0.md | screens構造統一提案書 |
| harmonet-docs-directory-definition_v3.0.md | タチコマ定義（基準） |

---

## 🧩 方針決定事項（タチコマ承認）

### 1️⃣ 章番号構成の最終決定
- 欠番は設けず、**`05_implementation/` を正式に追加**する。  
  → 将来的に実装ガイド・技術資料を格納する想定（空でも可）。
- 以下の最終構成に統一：

00_project/
01_requirements/
02_design/
03_tenant/
04_admin/
05_implementation/
06_audit/
07_architecture/
99_archive/


- 章番号とディレクトリ名のペアは `/docs/harmonet-docs-directory-definition_v3.3.md` に反映予定。

---

### 2️⃣ screens配下構造統一の扱い
- 現状の構造（A型＋B型混在）を**Phase 8以降に持ち越し**。
- login/home → A型（サブディレクトリ型）を維持。
- board → B型（章別サブディレクトリ型）を維持。
- board-detail/facility → 現状維持、実装後に再整理。
- 統一方式は案B（章別サブディレクトリ方式）を採用予定（先送り）。

**理由:**
1. Phase 6でスキーマ品質（HQI 97点）確保済み。  
2. 実装をブロックしない構造差異。  
3. 記述見直し完了後の統一が効率的。

---

### 3️⃣ PowerShellスクリプト実行
- Claude作成 `harmonet_dir_sync_v3.2.ps1` はレビュー後に実行。  
- 実行前にGitコミットを行い、スナップショットを保存。

**Git推奨手順:**
```bash
git add .
git commit -m "snapshot: before directory reorganization v3.2"
# スクリプト実行後
git add .
git commit -m "refactor: directory structure aligned to v3.2"
git push origin main

4️⃣ ルート直下ファイルの移動

以下のファイルは定義に従って再配置する。
| ファイル                                       | 移動先                                                   |
| ------------------------------------------ | ----------------------------------------------------- |
| HarmoNet 開発方針共有メモ(2025-11-01).md           | 00_project/harmonet-dev-shared-summary_2025-11-01.md  |
| harmonet-document-policy_latest.md         | 00_project/harmonet-document-policy_latest.md         |
| schema-definition-overview_v1.0.md         | 02_design/schema-definition-overview_v1.0.md          |
| harmonet-docs-directory-definition_v3.2.md | 00_project/harmonet-docs-directory-definition_v3.2.md |

5️⃣ ディレクトリ名の大文字小文字統一

03_Rules/ → 03_rules/ にリネーム。

その他のルートフォルダ命名もすべて小文字統一。

⚙️ 実施順序（承認後の運用）

Phase 1: 章番号リネーム＋マージ（01_project → 00_project統合）

Phase 2: ファイル移動（ルート直下 → 適正位置）

Phase 3: 03_rulesリネーム（大文字小文字統一）

Phase 4: archiveディレクトリ作成（99_archive/）

🚀 今後の対応
| 担当     | 作業内容                                            | 時期  |
| ------ | ----------------------------------------------- | --- |
| Claude | `harmonet-docs-directory-definition_v3.3.md` 更新 | 今週中 |
| タチコマ   | スクリプトレビュー・整合監査                                  | 実施前 |
| TKD    | 最終承認・Gitスナップショット作成                              | 実施時 |
| Gemini | 実施後のBAG-lite再監査                                 | 実行後 |

📊 リスク評価（最終）
| 区分             | 内容     | リスク | 対応方針          |
| -------------- | ------ | --- | ------------- |
| 章番号リネーム        | 参照パス変更 | 中   | 影響箇所レビュー後に実施  |
| 06_tenant/リネーム | 監査済領域  | 高   | Phase 7以降に再検討 |
| screens構造統一    | 作業負荷   | 中   | Phase 8以降     |
| ファイル移動         | 軽微     | 低   | Git履歴で復旧可能    |

✅ 結論

本方針により、

v3.2ディレクトリ構成の正式承認

05_implementationディレクトリの追加

screens統一作業のPhase 8移行

スクリプト実行の前提条件確定

が成立した。
以降、すべての設計書・仕様書はこの構成に従う。

Document ID: HNM-DIR-FINAL-POLICY-20251102
Version: 3.2
Created: 2025-11-02
Approved by: タチコマ（HarmoNet PMO / Architect）
Reviewed by: Claude（Design Specialist）
Acknowledged by: TKD（Project Owner）
Next Review: Phase 8開始前（予定）


---
