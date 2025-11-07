# HarmoNet BAG-lite チェックリスト v1.0
**Document Category:** 品質監査基準書（BAG-lite）  
**Location:** `/01_docs/06_audit/`  
**Status:** 承認済（Phase 8 準備完了）  
**Target:** Gemini（監査AI） / Tachikoma（補助監査）  
**Created:** 2025-11-02  

---

## 🎯 目的
本書は HarmoNet プロジェクトにおける軽量監査方式（BAG-lite）の基準と手順を定義する。  
Gemini は本チェックリストを基に、各ドキュメント群の構造整合性・品質・命名規則遵守状況を自動検証する。

---

## 🧩 監査対象範囲
| 区分 | 対象ディレクトリ | 主担当 |
|------|------------------|--------|
| PJ管理層 | `/01_docs/00_project/` | Tachikoma |
| 要件層 | `/01_docs/00_requirements/` | Claude |
| 設計層 | `/01_docs/01_basic_design/` | Claude / Tachikoma |
| 実装層 | `/01_docs/05_implementation/` | Tachikoma |
| テナント層 | `/01_docs/04_tenant/` | Claude |
| 監査層 | `/01_docs/06_audit/` | Gemini |

---

## 🧮 チェックカテゴリ

### 1. 構造整合性チェック
| チェック項目 | 目的 | 判定基準 |
|---------------|------|-----------|
| ディレクトリ構成 | `/01_docs/` 構造が Phase 7 基準と一致するか | OK = 一致、NG = 不一致 |
| 章番号順序 | フォルダおよびファイル先頭の番号が昇順で整列しているか | OK / NG |
| アーカイブ構成 | `99_archive` が存在し、旧版が適切に退避されているか | OK / NG |

### 2. メタ情報チェック
| チェック項目 | 内容 | 判定基準 |
|---------------|------|-----------|
| Document ID | 各ファイル末尾に存在するか | OK / NG |
| Version | バージョン番号が整合しているか | OK / NG |
| Created / Last Updated | メタ情報が記載されているか | OK / NG |
| Supersedes | 旧版参照が正しく明示されているか | OK / NG |

### 3. 命名規則チェック
| チェック項目 | 内容 | 判定基準 |
|---------------|------|-----------|
| プレ付き構成 | `/01_docs/` 形式を採用しているか | OK / NG |
| ファイル名形式 | `{章番号_文書名_vX.X.md}` 構成になっているか | OK / NG |
| `_latest.md` の使用 | 最新参照リンクが適切に定義されているか | OK / NG |

### 4. 内容整合チェック
| チェック項目 | 内容 | 判定基準 |
|---------------|------|-----------|
| ChangeLog | 各ファイルに変更履歴が存在するか | OK / NG |
| フェーズ整合 | 対応する Phase の内容と齟齬がないか | OK / NG |
| 外部参照 | 参照ファイルが存在しリンク切れがないか | OK / NG |

### 5. 品質・表現チェック
| チェック項目 | 内容 | 判定基準 |
|---------------|------|-----------|
| 表記統一 | 日本語・英語併記ルールに準拠しているか | OK / NG |
| トーン | 「やさしく・自然・控えめ」スタイルを維持しているか | OK / NG |
| 誤字脱字 | 言語校正で誤りがないか | OK / NG |

---

## 📄 監査レポート出力形式（Gemini用）

Geminiは監査実行時、以下フォーマットで結果を出力する。

```
# HarmoNet Quality Approval Report YYYYMMDD

## 概要
監査日: YYYY-MM-DD
監査対象: /01_docs/

## 監査結果サマリ
- 構造整合性: OK
- メタ情報: OK
- 命名規則: OK
- 内容整合: Minor Issue
- 品質・表現: OK

## 詳細結果
| カテゴリ | 結果 | コメント |
|-----------|------|-----------|
| 構造整合性 | OK | Phase 7基準と一致 |
| メタ情報 | OK | 全ファイル記載あり |
| 内容整合 | Minor Issue | tenant-schemaとaudit報告日差異あり |
| 品質表現 | OK | トーン統一確認済 |
```

---

## 🧭 運用ルール
- 本チェックリストは Phase 8 の初期監査に使用する。  
- Gemini は自動監査実行後、`06_harmonet-quality-approval-report_YYYYMMDD.md` を生成する。  
- Tachikoma は監査報告の整合確認を行い、必要に応じて Claude にフィードバックを返す。  
- 監査結果は `/01_docs/06_audit/` 内に保存し、他Phaseのドキュメントには直接修正を加えない。  

---

**Document ID:** HNM-AUDIT-BAGLITE-20251102  
**Version:** 1.0  
**Created:** 2025-11-02  
**Author:** Tachikoma (PMO / Architect)  
**For:** Gemini / Claude / TKD 共通参照  
**Next Review:** Phase 8 完了時（2025-12予定）
