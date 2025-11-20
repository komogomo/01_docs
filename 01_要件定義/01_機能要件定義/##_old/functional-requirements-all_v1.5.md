# HarmoNet 機能要件定義書 v1.5
**技術スタック準拠:** HarmoNet Technical Stack Definition v4.3（修正版）

---

# 第1章 ドキュメント概要
本書は HarmoNet の機能要件を最上流で定義する唯一の正である。

---

# 第2章 システム概要

## 2.1 技術構成（改訂版）

* **フロントエンド**：Next.js 16 / React 19 / TailwindCSS
* **バックエンド**：Supabase Auth + PostgreSQL 17（RLS）
* **認証**：MagicLink のみ
* **翻訳（動的）**：Google Translation API v3（Next.js API Route 経由）
* **翻訳（静的ラベル）**：StaticI18nProvider
* **音声**：VOICEVOX API（Next.js API Route 経由）
* **ストレージ**：Supabase Storage（PDF・画像）
* **通知**：Supabase Realtime
* **RLS**：tenant_id によるデータ分離

---

# 第3章 機能要件定義

## 3.1 認証

### 3.1.1 方式

* **MagicLink（メール OTP 認証）**

  * Supabase Auth `signInWithOtp()` を使用
  * `/auth/callback` でセッション確立

### 3.1.2 非採用

* Passkey（WebAuthn / Corbado）→ v1.5 より完全廃止
* Corbado Node/Web SDK → 廃止

---

## 3.2 多言語対応

### 3.2.1 静的翻訳（UI ラベル）

* `public/locales/{ja,en,zh}/common.json`
* StaticI18nProvider にて即時切替

### 3.2.2 動的翻訳（掲示板投稿・お知らせ本文）

* **Google Translation API v3 を継続使用**
* 呼出方式：Next.js Route Handler（例：`/api/translate`）
* 翻訳結果は Supabase の `translation_cache` テーブルに保存

---

## 3.3 掲示板

* 投稿・コメント・添付（PDF / 画像）
* 動的翻訳（Google）および音声生成（VOICEVOX）に対応
* モーダル PDF プレビュー（PDF.js）
* Realtime による新規投稿通知

---

## 3.4 お知らせ

* 管理者による投稿
* 動的翻訳（Google）
* PDF 添付プレビュー
* 既読管理
* Realtime 通知

---

## 3.5 音声読み上げ（VOICEVOX）

### 3.5.1 方式

* VOICEVOX サーバーへ直接 HTTP POST
* Next.js Route Handler（例：`/api/tts`）でラップ

### 3.5.2 用途

* 掲示板投稿
* お知らせ本文

### 3.5.3 キャッシュ

* Supabase Storage にキャッシュ保存（`tts_cache`）

---

## 3.6 通知

* Supabase Realtime による新規投稿通知
* メール通知（将来拡張）
* プッシュ通知（将来拡張）

---

# 第4章 非機能要件

## 4.1 性能

* 初期表示：2〜3 秒
* 翻訳 API 応答：1 秒以内（Google）
* 音声生成：5 秒以内（VOICEVOX）

## 4.2 可用性

* 個人開発前提のため SLA なし
* 障害時の復旧は手動

## 4.3 セキュリティ

* MagicLink + Supabase Auth
* HTTPS 必須
* JWT + RLS によるデータ保護
* 外部 API 秘密鍵は env / Vercel Secrets

---

# 第5章 外部API連携要件

## 5.1 Google Translate API v3（継続）

* 翻訳元：投稿本文 / お知らせ本文
* 翻訳先：`ja` / `en` / `zh`
* 呼出方法：Next.js Route Handler 経由

## 5.2 VOICEVOX API（継続）

* スタイル：ずんだもん（デフォルト）
* 音声形式：mp3 / wav
* 呼出方法：Next.js Route Handler 経由

## 5.3 Supabase

* Auth / RLS / Storage / Realtime
* EdgeFunction は使用しない

---

# 第6章 制約条件

* パスワードレスログインは MagicLink のみ
* Passkey（Corbado）機能は削除
* 翻訳・音声は Next.js API Route 経由とし、Supabase EdgeFunction を使わない
* i18n 字句は StaticI18nProvider の静的辞書に限定

---

# 第7章 付録

* Supabase RLS 設計
* translation_cache / tts_cache テーブル仕様
* Next.js API Route の基本構造

---

# 第8章 ChangeLog

| Version | Date       | Summary                                               |
| ------- | ---------- | ----------------------------------------------------- |
| v1.5    | 2025-11-19 | Corbado削除 / EdgeFunction削除 / Google翻訳・VOICEVOX継続方式へ更新 |
| v1.4    | 2025-11-17 | Corbado + EdgeFunction 前提の構成                          |
