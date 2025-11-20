# HarmoNet 機能要件定義書（INDEX）v1.5

**整合基準:** HarmoNet Technical Stack Definition v4.3（Next.js 16 / React 19 / Supabase / Corbado / Google Translate / VOICEVOX）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✨ 最新仕様（翻訳・音声・外部API構成）完全整合版
**Updated:** 2025-11-19

---

## 📘 概要

本ドキュメントは HarmoNet プロジェクトの **正式要件定義 INDEX** であり、以下の最新版構造に基づいて章単位で管理を行う。

* MagicLink / Passkey の独立認証方式
* 翻訳（Google Translate v3 + translation_cache）
* 音声（VOICEVOX + tts_cache + Edge Function）
* 外部API構成（翻訳 / 音声 / AI / Supabase / Vercel）
* Supabase Pro 前提の運用制約とコスト要件

本 INDEX は、機能要件 v1.4 / 技術スタック v4.3 / コスト要件 v1.4 と完全整合するよう再構成した最新版である。

---

## 📂 章構成一覧

| 章       | ファイル名（最新版参照）                                          | 内容概要                                            |                                                 |                                                        |
| ------- | ----------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------ |
| **第1章** | functional-requirements-ch01-document-scope_*.*.md    | 文書目的・背景・関連文書                                    |                                                 |                                                        |
| **第2章** | functional-requirements-ch02-system-overview_*.*.md   | システム全体構成・AI体制・技術基盤概要                            |                                                 |                                                        |
| **第3章** | functional-requirements-ch03-functional-req_*.*.md    | 掲示板 / お知らせ / 翻訳 / 音声TTS / 認証（MagicLink）など機能要件全般 |                                                 |                                                        |
| **第4章** | functional-requirements-ch04-nonfunctional-req_*.*.md | 非機能（性能・可用性・RLS・セキュリティ）                          |                                                 |                                                        |
| **第5章** | functional-requirements-ch05-config-env_*.*.md        | 外部API（翻訳 / TTS / Supabase）・環境変数構成               |                                                 |                                                        |
| **第6章** | functional-requirements-ch06-limits-cost_*.*.md       | 制約条件・コスト要件（Supabase / Vercel / Google API）      | functional-requirements-ch06-limits-cost_*.*.md | **制約条件・コスト要件（Supabase / Vercel / Google API / Redis）** |

---

## 🔊 翻訳・音声カテゴリ（v4.3 新構成）

### 翻訳（Translation）

* Google Cloud Translation API v3
* translation_cache に保持
* Redis キャッシュ併用（任意）
* StaticI18nProvider による UI 翻訳（JA/EN/ZH）

### 音声（TTS: Text-to-Speech）

* VOICEVOX API
* Supabase Edge Function `/api/tts`
* tts_cache + Storage MP3 キャッシュ
* 非必須（TTS 障害時はアプリ継続）

---

## 🤖 AI統合開発体制（v4.3）

| 役割         | 担当          | 主な責務                       |
| ---------- | ----------- | -------------------------- |
| PMO / 要件統合 | タチコマ（GPT-5） | 全体系整合・INDEX管理              |
| 品質保証 / 検証  | Gemini      | 非機能品質 / Lint / 論理整合性検証     |
| 実装 / 自動テスト | Windsurf    | 実装・Vitest・CodeAgent_Report |
| 最終承認       | TKD         | HarmoNet の唯一の正             |

---

## 🔖 運用ポリシー

* すべての章リンクは `*.*` 指定により常に最新版を参照
* Supabase Pro を本番必須とする（Sleep 回避）
* 翻訳/TTS 障害時はフォールバック運用を許容
* AI（タチコマ・Gemini・Windsurf）は INDEX を基準に整合性チェックを行う

---

**End of Document**
