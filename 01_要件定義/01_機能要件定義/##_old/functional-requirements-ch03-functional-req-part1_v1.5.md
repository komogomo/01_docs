# 第3章 機能要件定義（Part 1）v1.6（MagicLink + Google 翻訳 + Google Cloud TTS 対応版）

**準拠:** HarmoNet Functional Requirements v1.6（MagicLink / Google Translation API v3 / Google Cloud TTS）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式要件（v1.6 完全整合）
**Updated:** 2025-11-19

---

## 3.1 概要

本章では、HarmoNet の主要画面である **「ホーム」「お知らせ」「掲示板（基礎機能）」** の要件を定義する。
これらの機能は住民が最初に利用するコア領域であり、**多言語化（Google 翻訳）・音声化（Google Cloud TTS）・通知（Realtime）・RLS（テナント分離）** を中心に記載する。

---

## 3.2 ホーム画面機能

### 3.2.1 目的

* ログイン後のトップ画面として、住民が必要な情報に素早くアクセスできる UI を提供する。
* 「お知らせ」「掲示板」「施設予約」「アンケート」へのエントリーポイントとして機能する。

### 3.2.2 主な要件

| 機能       | 内容                                                |
| -------- | ------------------------------------------------- |
| ログイン状態検知 | Supabase Auth のセッションを検出し、未ログイン時は `/login` へリダイレクト |
| お知らせ概要表示 | 有効期間中のデータを取得し、タイトル／抜粋（翻訳済み優先）を表示                  |
| 掲示板概要表示  | 最新 3 件を表示。翻訳キャッシュ `translation_cache` を参照         |
| 多言語切替    | StaticI18nProvider により JA/EN/ZH を即時切替（再レンダー不要）    |
| 主要機能ナビ   | FooterShortcutBar（C-05）と UI 統一した操作導線              |

### 3.2.3 非機能要件リンク

* 初期ロード：2 秒以内（CDN + App Router）
* 翻訳切替：1 秒以内（Translation API + キャッシュ）
* セッション失効時挙動：即 `/login` へ誘導

---

## 3.3 お知らせ機能

### 3.3.1 機能概要

* 管理者（tenant_admin）が投稿し、住民が閲覧する公式情報配信機能。
* データは `announcements` テーブル、配信対象は `announcement_targets`、既読管理は `announcement_reads` に保持。
* 翻訳（Google）・音声化（Google Cloud TTS）をサポート。

### 3.3.2 機能一覧

| 機能     | 説明                                  |
| ------ | ----------------------------------- |
| お知らせ一覧 | 公開中データを降順表示。翻訳済みタイトルを優先表示           |
| お知らせ詳細 | 本文を StaticI18nProvider + 動的翻訳で多言語表示 |
| 既読処理   | 表示時に `announcement_reads` へ登録       |
| 添付ファイル | Supabase Storage に格納／PDF.js でプレビュー  |
| 通知連携   | 新規投稿を Supabase Realtime で push 通知   |
| 音声読み上げ | Google Cloud TTS により 3 言語で読み上げ対応    |

### 3.3.3 パフォーマンス要件

* 一覧取得：1 秒以内（RLS + キャッシュ）
* 既読更新：300ms 以内（非同期）
* 音声生成：1〜2 秒（Google TTS）

---

## 3.4 掲示板（一覧・詳細）基礎機能

### 3.4.1 概要

HarmoNet のコミュニケーション基盤であり、以下を中心に構成される：

* 投稿（`board_posts`）
* コメント（`board_comments`）
* 添付（`board_attachments`）
* 翻訳（Google Translation API）
* 音声化（Google Cloud TTS）

### 3.4.2 要件

| 機能    | 説明                                           |
| ----- | -------------------------------------------- |
| 掲示板一覧 | テナントスコープで投稿抽出。検索・タグ・並び替えに対応                  |
| 投稿詳細  | 翻訳済み本文を表示し、音声読み上げボタンを提供                      |
| コメント  | スレッド構造対応（`parent_comment_id`）                |
| 投稿作成  | Markdown/WYSIWYG、ドラフト保存対応                    |
| 添付    | PDF/画像を Supabase Storage 管理                  |
| 通報    | `board_reactions`（reaction_type='report'）で記録 |
| 翻訳    | 高速化のため `translation_cache` を参照し即時切替          |

### 3.4.3 通信仕様

* Supabase SDK 経由の直接通信が基本
* JWT の `tenant_id` により自動 RLS 適用
* 必要に応じ API Route を利用（翻訳／音声など）

---

## 3.5 共通 UI・アクセシビリティ要件

### 3.5.1 共通部品依存

| ID   | 名称                | 役割                                                                   |                                                      |                                 |             |                    |
| ---- | ----------------- | -------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------- | ----------- | ------------------ |
| C-01 | AppHeader         | ロゴ・言語切替・共通ナビ                                                         |                                                      |                                 |             |                    |
| C-02 | LanguageSwitch    | 多言語切替（JA/EN/ZH）                                                      |                                                      |                                 |             |                    |
| C-04 | AppFooter         | コピーライト表示                                                             |                                                      |                                 |             |                    |
| C-05 | FooterShortcutBar | 権限別ショートカット                                                           |                                                      |                                 |             |                    |
| C-09 | TranslateButton   | 動的翻訳トリガー                                                             |                                                      |                                 |             |                    |
| C-01 | AppHeader         | ロゴ・言語切替・共通ナビ                                                         |                                                      |                                 |             |                    |
| C-02 | LanguageSwitch    | 多言語切替（JA/EN/ZH）                                                      |                                                      |                                 |             |                    |
| C-04 | AppFooter         | コピーライト表示                                                             |                                                      |                                 |             |                    |
| C-05 | FooterShortcutBar | 権限別ショートカット                                                           |                                                      |                                 |             |                    |
| C-09 | TranslateButton   | 動的翻訳トリガー                                                             |                                                      |                                 |             |                    |
| C-12 | VoiceReader       | Google TTS 読み上げ UI                                                   |                                                      |                                 |             |                    |
| C-20 | Logger            | システムログを **Vercel 標準ログ / Supabase 標準ログ** に出力するための共通ロジック部品（UI 機能とは無関係） | アプリ共通のログユーティリティ（logInfo / logError）。 | 共通ログユーティリティ（logInfo / logError） |

### 3.5.2 アクセシビリティ仕様

* WCAG 2.2 AA 相当
* `aria-label` の必須指定
* 言語切替時 `aria-live="polite"`
* フォーカス順の一貫性

---

## 3.6 データ構造（主要テーブル）

| テーブル                 | 用途      | 主キー                        | 備考                 |
| -------------------- | ------- | -------------------------- | ------------------ |
| announcements        | お知らせ    | id                         | 配信範囲／有効期間          |
| announcement_targets | 配信対象    | id                         | group/role/user 単位 |
| announcement_reads   | 既読管理    | (announcement_id, user_id) | RLS あり             |
| board_posts          | 掲示板投稿   | id                         | 翻訳／音声連携            |
| board_comments       | 掲示板コメント | id                         | 階層構造対応             |
| board_attachments    | 添付      | id                         | Storage 連携         |

---

## 3.7 KPI / 成果指標

| 指標          | 目標    | 備考                |
| ----------- | ----- | ----------------- |
| ホーム初期ロード    | 2 秒以内 | CDN + App Router  |
| お知らせ既読率     | 95%以上 | Realtime 監視       |
| 掲示板翻訳成功率    | 98%以上 | Google 翻訳 + キャッシュ |
| 音声生成成功率     | 98%以上 | Google TTS        |
| アクセシビリティ適合率 | 100%  | WCAG 2.2 AA       |

---

## 3.8 参照リンク

* functional-requirements-ch03-functional-req-part2_*.*.md（翻訳／音声／通知の詳細）
* functional-requirements-ch04-nonfunctional-req_*.*.md
* harmoNet-technical-stack-definition_v*.*.md
* harmonet-security-spec_v*.*.md

---

**Document ID:** HNM-REQ-CH03-PART1-V1.6

**Version:** 1.6
**Created:** 2025-11-19
**Updated:** 2025-11-19
**Supersedes:** v1.5
**Status:** ✅ HarmoNet 正式要件（MagicLink + Google 翻訳 + Google Cloud TTS 版）
