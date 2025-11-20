# HarmoNet 機能要件定義書

**最終更新:** 2025-11-19

---

# 第1章 ドキュメント概要

本章は HarmoNet 全体の要件体系において、**要件定義書がカバーする範囲（Scope）** を定義する最上流ドキュメントである。

---

## 1.1 目的

本書の目的は、HarmoNet プロジェクトの**機能要件・非機能要件が対象とする範囲**を明確化し、後続の基本設計・詳細設計・実装工程に対し一貫した上位指針を提供することである。

要件定義書は、HarmoNet のすべての設計書の上位に位置し、**唯一の正（Source of Truth）** として扱う。

---

## 1.2 適用範囲（Scope）

本要件定義書は、HarmoNet の以下の領域を対象とする：

### ✔ アプリケーション層（フロントエンド）

* Next.js 16 (App Router)
* React 19
* TailwindCSS
* shadcn/ui
* StaticI18nProvider（静的 JSON 辞書による UI 文言管理）

### ✔ 認証方式（最新版仕様）

* **MagicLink（Supabase Auth / signInWithOtp）**
* `/auth/callback` によるセッション確立

※ Passkey（WebAuthn / Corbado）は **v1.6 以降の要件において非採用**。

### ✔ 多言語化（i18n）

* **静的翻訳**：`public/locales/{ja,en,zh}/common.json`
* **動的翻訳**：Google Translation API v3（Next.js API Route `/api/translate` 経由）
* **対応言語**：日本語 / 英語 / 中国語（簡体）

### ✔ 音声読み上げ（Text-to-Speech）

* **Google Cloud Text-to-Speech API（最新仕様）**
* Next.js API Route（例：`/api/tts`）でのラップ
* **対応言語**：日本語（ja-JP）、英語（en-US / en-GB）、中国語（zh-CN / zh-TW）
* Supabase Storage に音声キャッシュ（`tts_cache`）を保存

### ✔ データ層（バックエンド）

* Supabase PostgreSQL 17
* RLS（Row Level Security）によるテナントデータ分離
* Supabase Storage（PDF / 画像 / 音声キャッシュ）
* translation_cache / tts_cache

### ✔ 通知

* Supabase Realtime（掲示板・お知らせ更新通知）

### ✔ 要件定義の対象機能

* ch02〜ch06 に記載される全機能要件
* 掲示板 / お知らせ / 施設予約
* 動的翻訳 / Google Cloud TTS
* 多言語 UI
* 認証（MagicLink）

---

## 1.3 関連文書

* functional-requirements-all_v*.*.md（最新版）
* functional-requirements-ch02-system-overview_v*.*.md
* functional-requirements-ch04-nonfunctional-req_v*.*.md
* functional-requirements-ch05-config-env_v*.*.md
* harmoNet-technical-stack-definition_v*.*.md

---

## 1.4 バージョン履歴

| Version  | Date       | Summary                                                            |
| -------- | ---------- | ------------------------------------------------------------------ |
| **v1.6** | 2025-11-19 | Google Translate + Google Cloud TTS に完全移行。Passkey を正式に Scope から除外。 |
| v1.5     | 2025-11-17 | MagicLink / Passkey（独立ボタン）方式の Scope 記載（現行仕様では廃止）                   |
| v1.4     | 2025-11-12 | 技術スタック v4.1 整合化                                                    |

---
