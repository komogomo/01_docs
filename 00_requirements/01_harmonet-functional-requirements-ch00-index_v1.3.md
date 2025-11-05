# HarmoNet 機能要件定義書（v1.3）  
作成日：2025年10月31日  
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
| 第1章 | [harmonet-functional-requirements-ch01-document-scope_v1.3.md](./00_requirements/harmonet-functional-requirements-ch01-document-scope_v1.3.md) | 文書目的・背景・関連ドキュメント |
| 第2章 | [harmonet-functional-requirements-ch02-system-overview_v1.3.md](./00_requirements/harmonet-functional-requirements-ch02-system-overview_v1.3.md) | システム全体構成・RLS構造・技術スタック |
| 第3章 Part1 | [harmonet-functional-requirements-ch03-functional-req-part1_v1.3.md](./00_requirements/harmonet-functional-requirements-ch03-functional-req-part1_v1.3.md) | ホーム・掲示板・お知らせ機能 |
| 第3章 Part2 | [harmonet-functional-requirements-ch03-functional-req-part2_v1.3.md](./00_requirements/harmonet-functional-requirements-ch03-functional-req-part2_v1.3.md) | 施設予約・マイページ・共通機能 |
| 第4章 | [harmonet-functional-requirements-ch04-nonfunctional-req_v1.3.md](./00_requirements/harmonet-functional-requirements-ch04-nonfunctional-req_v1.3.md) | セキュリティ・性能・スケーラビリティ要件 |
| 第5章 | [harmonet-functional-requirements-ch05-config-env_v1.3.md](./00_requirements/harmonet-functional-requirements-ch05-config-env_v1.3.md) | 開発／運用環境構成（Vercel + Supabase）+ データ移行計画 |
| 第6章 | [harmonet-functional-requirements-ch06-limits-future_v1.3.md](./00_requirements/harmonet-functional-requirements-ch06-limits-future_v1.3.md) | 制約条件・Phase別拡張・開発ロードマップ |
| 第7章 | [harmonet-functional-requirements-ch07-appendix_v1.3.md](./00_requirements/harmonet-functional-requirements-ch07-appendix_v1.3.md) | 用語集・参照資料・リスク管理・履歴 |

---

## 🧩 関連リファレンス
- [HarmoNet Technical Stack Definition v3.2](../00_architecture/HarmoNet-Technical-Stack-Definition-v3.2.md)
- [HarmoNet Design Guidelines v1.1](../01_basic_design/harmonet-design-guidelines-v1.1.md)
- [HarmoNet Database Schema v1.0](../02_db_design/harmonet-database-schema-v1.0.md)

---

## 🤖 AI協調開発体制（v1.3 追記）
本プロジェクトは、AI間連携によるドキュメント整合を前提としています。  

| 役割 | 担当AI | 主な責務 |
|------|---------|-----------|
| UI/UX設計 | Claude | 画面構造・設計レビュー |
| 環境構築／アーキテクチャ | Gemini | インフラ／バックエンド環境設計 |
| ドキュメント統合／整合 | GPT | 要件定義・設計ドキュメント統合、バージョン管理 |

---

## 🔖 保守ポリシー
- 章単位でAI整合（Claude:設計確認、Gemini:コード検証、GPT:ドキュメント統合）  
- ファイル命名規則：`harmonet-functional-requirements-chXX-<section-name>-v1.Y.md`  
- バージョンアップ時は章ごとに更新可。  
- `merge/` フォルダにClaude登録用の統合版を保持。  

---

*Document generated collaboratively by GPT (PMO AI) — HarmoNet Project, 2025*
