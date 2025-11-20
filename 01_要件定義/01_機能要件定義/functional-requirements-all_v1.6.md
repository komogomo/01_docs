# HarmoNet 機能要件定義書 v1.6

**技術スタック準拠:** HarmoNet Technical Stack Definition v*.*（Google 翻訳 + Google Cloud TTS 対応版）

---

# 第1章 ドキュメント概要

本書は HarmoNet の機能要件を最上流で定義する唯一の正である。

---

# 第2章 システム概要

## 2.1 技術構成（更新版）

* **フロントエンド**：Next.js 16 / React 19 / TailwindCSS
* **バックエンド**：Supabase Auth + PostgreSQL 17（RLS）
* **認証**：MagicLink（PKCE）
* **翻訳（動的）**：Google Translation API v3（Next.js API Route 経由）
* **翻訳（静的ラベル）**：StaticI18nProvider
* **音声**：Google Cloud Text-to-Speech（日本語・英語・中国語対応）
* **ストレージ**：Supabase Storage（PDF・画像・音声キャッシュ）
* **通知**：Supabase Realtime
* **RLS**：tenant_id によるデータ分離

---

# 第3章 機能要件定義

## 3.1 認証

### 3.1.1 方式

* **MagicLink（メール OTP 認証）**

  * Supabase Auth `signInWithOtp()` を使用
  * `/auth/callback`（PKCE）によりブラウザ側でセッション確立

### 3.1.2 非採用

* Passkey（WebAuthn / Corbado）
* Corbado Node/Web SDK

---

## 3.2 多言語対応

### 3.2.1 静的翻訳

* `public/locales/{ja,en,zh}/common.json`
* StaticI18nProvider にて UI ラベルを制御

### 3.2.2 動的翻訳

* Google Translation API v3
* サポート言語：**日本語・英語・中国語（簡体）**
* 翻訳キャッシュ：`translation_cache`

---

## 3.3 掲示板

* 投稿・コメント・添付（PDF/画像）
* **動的翻訳（Google）と音声読み上げ（Google Cloud TTS）に対応**
* PDF.js で添付プレビュー
* Realtime による投稿通知

---

## 3.4 お知らせ

* 管理者投稿
* 動的翻訳（Google）
* PDF プレビュー
* 既読管理
* Realtime
* **音声読み上げは日本語・英語・中国語で対応**

---

## 3.5 音声読み上げ（Google Cloud TTS）

### 3.5.1 方式

* Google Cloud Text-to-Speech API を使用
* Next.js API Route（例：`/api/tts`）でラップ

### 3.5.2 対応言語

* **日本語（ja-JP）**
* **英語（en-US / en-GB）**
* **中国語（zh-CN / zh-TW）**

### 3.5.3 キャッシュ

* Supabase Storage に音声ファイルを保存（`tts_cache`）

---

# 第4章 非機能要件

## 4.1 性能

* 初期表示：2〜3 秒
* 翻訳応答：1 秒以内
* **音声生成：1〜2 秒（Google TTS）**

## 4.2 可用性

* 個人開発前提（SLAなし）
* 障害時は手動復旧

## 4.3 セキュリティ

* MagicLink + Supabase Auth
* HTTPS 必須
* JWT + RLS

---

# 第5章 外部API連携要件

## 5.1 Google Translate API v3

* `/api/translate`
* 日本語・英語・中国語 対応

## 5.2 Google Cloud Text-to-Speech（TTS）

* `/api/tts`
* mp3 / wav
* 日本語・英語・中国語 対応
* Google API Key による認証

## 5.3 Supabase

* Auth / RLS / Storage / Realtime

---

# 第6章 制約条件

* 認証方式は MagicLink のみ
* 翻訳・音声は Next.js API Route 経由（Google API）
* 音声読み上げは日本語・英語・中国語をサポート

---

# 第7章 付録

* translation_cache / tts_cache テーブル仕様
* Next.js API Route の基本構造

---

# 第8章 ChangeLog

| Version | Date       | Summary                                            |
| ------- | ---------- | -------------------------------------------------- |
| v1.6    | 2025-11-19 | VOICEVOX → Google Cloud TTS へ全面移行。3言語対応（ja/en/zh）。 |
| v1.5    | 2025-11-19 | VOICEVOX 方式のまま翻訳統合バージョン                            |
