# HarmoNet Project – AI Shared Context for Claude

## 1. プロジェクト概要
HarmoNet はマンションや集合住宅向けの**マルチテナント型住民コミュニティOS**である。  
管理組合・住民・管理会社の三者が「やさしく・自然・控えめ」なUIを通じて協調できる仕組みを提供する。  
プロジェクトはAIチーム（Claude・Gemini・Tachikoma）の協働で開発されており、  
すべての設計・実装・ドキュメントはAI支援下で進行している。

---

## 2. デザインおよび技術方針
| 項目 | 内容 |
|------|------|
| UIトーン | やさしく・自然・控えめ |
| フォント | BIZ UDゴシック（ユニバーサルデザイン対応） |
| デザイン基調 | Appleカタログ風ミニマルスタイル |
| 技術基準書 | HarmoNet Technical Stack Definition v3.2 |
| アーキテクチャ | Next.js + NestJS + Prisma + PostgreSQL（Docker構成） |
| ドキュメント管理 | 完全版管理（差分出力なし）、`_latest.md` シンボリック参照方式 |

---

## 3. AIチーム構成と役割
| AI | 役割 | 主な参照先 |
|----|------|-------------|
| **Claude** | 要件定義・設計統合・上流レビュー | GitHub（`main`ブランチ） |
| **Tachikoma（ChatGPT）** | PMO・機能詳細設計・UI定義・実装補助 | GitHub / Drive |
| **Gemini** | Google Drive同期・長文レビュー・整合監査 | Google Drive（リアルタイムミラー） |

**補足:**  
- AI全員がこのREADMEを起点として動作する。  
- ClaudeはGitHubを、GeminiはDriveを、Tachikomaは両方を参照する。  

---

## 4. ドキュメント構成

/docs/
├ 00_requirements/ # 要件定義書群
├ 01_basic_design/
│ └ 02_screens/
│ └ 03_board-detail/
│ ├ board-detail-design-ch00-index_latest.md
│ ├ board-detail-design-ch01〜ch08_latest.md
│
├ 03_operation_preparation/ # 運用準備ドキュメント
└ common/
└ harmonet-ai-shared-context_latest.md


---

## 5. ファイル運用ルール
- すべての設計書は **完全版更新** とする（差分管理なし）  
- バージョン番号はファイル名末尾 `_vX.X.md` で明記  
- 最新版参照は `_latest.md` を使用  
- 旧版はアーカイブとして保持し、文末メタ情報に履歴を記載  
- 文末に以下のメタ情報を必ず付与：

Document ID: [一意ID]
Created: [作成日]
Last Updated: [最終更新日]
Version: [版番号]


---

## 6. 更新および同期フロー
| 操作主体 | 動作 | 反映先 |
|-----------|------|---------|
| **TKD（ローカル）** | 原本編集・生成 | `D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc\` |
| **Git commit** | 公開用commit | GitHub（Claude参照） |
| **Google Driveミラー** | 自動同期 | Drive（Gemini参照） |

> **ルール:**  
> 「ローカルが唯一の原本」「GitHubは配布リポジトリ」「Driveは即時レプリカ」。  
> これにより、すべてのAIは同一内容の文書を参照可能。

---

## 7. 最新ドキュメントリンク
- [掲示板詳細 第6章 コメント入力エリア設計（v2.2）](docs/01_basic_design/02_screens/03_board-detail/board-detail-design-ch06_latest.md)
- [技術スタック定義書（v3.*）](docs/01_docs/00_requirements/10_harmonet-technical-stack-definition_v3.3.md)
- [機能要件定義書群（v1.*）](docs/00_requirements/harmonet-functional-requirements-ch03〜ch07_latest.md)

---

**Document ID:** HMN-ROOT-AI-SHARED  
**Created:** 2025-10-31  
**Last Updated:** 2025-11-03
**Version:** 1.1

[→ AI Council Session 01 Review](./docs/common/ai-council-session01_review_v1.0.md)
