# HarmoNet AI Knowledge Sync Instruction v1.0

**Document ID:** HNM-AI-KNOWLEDGE-SYNC-20251105  
**Version:** 1.0  
**Created:** 2025-11-05  
**Author:** Tachikoma (PMO Architect)  
**Approved:** TKD (Project Owner)

---

## 🎯 目的

本書は、Phase9 以降の AI チーム（Claude／Gemini／Tachikoma）が  
**GitHub リポジトリ `/01_docs/`** を単一の参照ナレッジ（Single Source of Truth）として扱うための  
同期手順と更新方針を定義する。

Drive 連携を廃止し、GitHub リポジトリを中心とした AI 駆動型開発体制を確立することを目的とする。

---

## 🧭 対象リポジトリ

| 項目 | 値 |
|------|----|
| **Repository Name** | `01_docs` |
| **Owner** | `komogomo` |
| **Repository URL** | [https://github.com/komogomo/01_docs](https://github.com/komogomo/01_docs) |
| **Access Level** | Public (Read Only) |
| **Primary Branch** | `main` |
| **Synchronization Scope** | `/00_project/`, `/00_requirements/`, `/02_design/`, `/03_detail_design/` |

---

## 🧠 AIチームナレッジ同期対象

| AI名 | 役割 | 同期方法 | 備考 |
|------|------|----------|------|
| **Claude** | 設計レビュー・整合解析 | GitHub API / Public Read | Drive参照を廃止 |
| **Gemini** | BAG監査・長文解析 | GitHub Public URL | Google Drive経由参照を停止 |
| **Tachikoma** | PMO・構造統括 | GitHub Public + Local Mirror | リポジトリ管理責任を負う |

---

## 🔄 同期運用ルール

1. **参照ディレクトリ構成**
   - すべて `/01_docs/` 以下の正式構成に従う。  
   - 旧 `/03_HarmoNetDoc/` は参照禁止（Phase9以降廃止）。

2. **更新タイミング**
   - 新しいファイルを push した時点で、AIチームは最新版をナレッジへ反映する。  
   - ファイルの命名規則は `_vX.X` または `_latest.md` に統一。

3. **参照優先順位**
   1. GitHub リポジトリ `/01_docs/`
   2. Tachikoma ローカルキャッシュ
   3. TKD 承認済みアーカイブ `/99_archive/`

4. **禁止事項**
   - Drive 内の同名ファイルを参照しない。  
   - 外部URLから旧バージョンをロードしない。

---

## 🧩 確認対象ファイル一覧（Phase9時点）

| 種別 | ファイル名 | バージョン | 備考 |
|------|-------------|-------------|------|
| ディレクトリ構成 | `harmonet-docs-directory-definition_v3.4.md` | v3.4 | Phase9準拠構成 |
| 技術スタック | `harmonet-technical-stack-definition_v3.6.md` | v3.6 | Supabaseローカル構成対応 |
| 運用ガイドライン | `harmonet-document-policy_latest.md` | latest | ドキュメント共通規約 |
| AI開発ガイド | `ai-driven-development-guide_v1.0.md` | v1.0 | 開発方式統一指針 |

---

## 🧾 運用開始宣言

本書に基づき、2025年11月5日をもって  
**HarmoNet AIチーム（Claude／Gemini／Tachikoma）は GitHub `/01_docs/` リポジトリを唯一の公式参照元とする。**

---

**Document ID:** HNM-AI-KNOWLEDGE-SYNC-20251105  
**Version:** 1.0  
**Created:** 2025-11-05  
**Approved:** TKD  
**Status:** ✅ Phase9 運用開始

