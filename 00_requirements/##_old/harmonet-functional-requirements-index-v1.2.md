# HarmoNet 機能要件定義書（v1.2）  
作成日：2025年10月30日  
整合基準：HarmoNet Technical Stack Definition v3.2  

---

## 📘 概要
本ドキュメント群は、HarmoNetアプリケーションのMVP版における  
**機能要件・非機能要件・環境構成・将来計画**をまとめた正式な要件定義セットです。  

構成は章単位で分割されており、個別に編集・AI整合が可能です。  
Claude／Gemini／GPT間の連携作業では本INDEXを基準とします。  

---

## 📂 章構成一覧

| 章 | ファイル名 | 内容概要 |
|----|-------------|-----------|
| 第1章 | [HarmoNet_Functional_Requirements-ch01_DocumentScope_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch01_DocumentScope_v1.2.txt) | 文書目的・背景・関連ドキュメント |
| 第2章 | [HarmoNet_Functional_Requirements-ch02_SystemOverview_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch02_SystemOverview_v1.2.txt) | システム全体構成・RLS構造・技術スタック |
| 第3章 前半 | [HarmoNet_Functional_Requirements-ch03a_FunctionalReq_Part1_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch03a_FunctionalReq_Part1_v1.2.txt) | ホーム・掲示板・お知らせ機能 |
| 第3章 後半 | [HarmoNet_Functional_Requirements-ch03b_FunctionalReq_Part2_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch03b_FunctionalReq_Part2_v1.2.txt) | 施設予約・マイページ・共通機能 |
| 第4章 | [HarmoNet_Functional_Requirements-ch04_NonFunctionalReq_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch04_NonFunctionalReq_v1.2.txt) | セキュリティ・性能・スケーラビリティ要件 |
| 第5章 | [HarmoNet_Functional_Requirements-ch05_ConfigEnv_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch05_ConfigEnv_v1.2.txt) | 開発／運用環境構成（Vercel + Supabase） |
| 第6章 | [HarmoNet_Functional_Requirements-ch06_LimitsFuture_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch06_LimitsFuture_v1.2.txt) | 制約条件・Phase別拡張・開発ロードマップ |
| 第7章 | [HarmoNet_Functional_Requirements-ch07_Appendix_v1.2.txt](./00_requirements/HarmoNet_Functional_Requirements-ch07_Appendix_v1.2.txt) | 用語集・参照資料・リスク管理・履歴 |

---

## 🧩 関連リファレンス
- [HarmoNet Technical Stack Definition v3.2](../00_architecture/HarmoNet-Technical-Stack-Definition_v3.2.md)
- [HarmoNet Design Guidelines v1.1](../01_basic_design/HarmoNet_Design_Guidelines_v1.1.md)
- [HarmoNet Database Schema v1.0](../02_db_design/HarmoNet_Database_Schema_v1.0.md)

---

## 🔖 保守ポリシー
- 章単位でAI整合（Claude:設計確認、Gemini:コード検証、GPT:ドキュメント統合）  
- ファイル命名規則：`HarmoNet_Functional_Requirements-chXX_<SectionName>_v1.Y.txt`  
- バージョンアップ時は章ごとに更新可。  
- `merge/` フォルダにClaude登録用の統合版を保持。  

---

*Document generated collaboratively by GPT (PMO AI) — HarmoNet Project, 2025*
