# 第3章 機能要件定義（Part 1）v1.4

**準拠:** HarmoNet Technical Stack Definition v4.1（Next.js 16.1 / React 19 / Supabase Cloud / Corbado SDK / Prisma ORM / TailwindCSS 4.0）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet正式要件定義（v4.1整合）
**Updated:** 2025-11-12

---

## 3.1 概要

本章では、HarmoNetの主要画面である「ホーム」「お知らせ」「掲示板（基礎機能）」の要件を定義する。
本機能群はユーザーが最初に接する領域であり、UX・多言語対応・パフォーマンスが最も重視される。
すべての機能は Supabase Cloud + Corbado SDK + StaticI18nProvider の統合構成を前提とする。

---

## 3.2 ホーム画面機能

### 3.2.1 目的

* ログイン後のトップ画面として、ユーザーに必要な情報を集約表示する。
* 各種モジュール（お知らせ、掲示板、施設予約、アンケート等）へのナビゲーションを統一デザインで提供する。

### 3.2.2 主な要件

| 機能          | 内容                                                               |
| ----------- | ---------------------------------------------------------------- |
| ログイン状態検知    | Supabase AuthセッションまたはCorbado Cookieを自動検知し、未ログイン時は`/login`へリダイレクト |
| お知らせ概要表示    | `announcements` テーブルから有効期間中のデータを取得し、タイトル・抜粋を表示                   |
| 掲示板概要表示     | 最新3件を一覧で表示（翻訳済みテキストを優先）                                          |
| メニューショートカット | FooterShortcutBar（C-05）と同期したナビゲーション表示                            |
| 多言語切替       | StaticI18nProviderにより即時切替（再レンダー不要）                               |

### 3.2.3 非機能要件リンク

* 初回ロード：2秒以内（Next.js App Router + CDNキャッシュ利用）
* 翻訳切替遅延：1秒以内
* 表示整合性：Corbado short_session 失効時は即座に再ログイン誘導

---

## 3.3 お知らせ機能

### 3.3.1 機能概要

* 管理者（tenant_admin）が投稿し、住民が閲覧する。
* 各お知らせは `announcements` テーブルで管理し、配信対象は `announcement_targets` により制御。
* 既読管理は `announcement_reads` により記録。
* 翻訳／音声化は掲示板機能と共通モジュールを利用。

### 3.3.2 機能一覧

| 機能     | 説明                                  |
| ------ | ----------------------------------- |
| お知らせ一覧 | 公開中データを降順で表示（翻訳済みタイトル）              |
| お知らせ詳細 | 本文をStaticI18nProvider経由で多言語表示       |
| 既読処理   | 表示時に `announcement_reads` に記録       |
| 添付ファイル | Supabase Storage に保存し、PDF.js でプレビュー |
| 通知連携   | 新規投稿時に Supabase Realtime 経由で通知送信    |
| 音声読み上げ | VOICEVOX API 呼出（翻訳結果優先）             |

### 3.3.3 パフォーマンス要件

* 一覧取得：1秒以内（RLS適用クエリ + Supabase Cache）
* 既読更新：300ms以内（Edge Functionで非同期化）
* 音声生成：5秒以内（Redisキャッシュ再利用時1秒）

---

## 3.4 掲示板（一覧・詳細）基礎機能

### 3.4.1 概要

* テナント共通の情報共有掲示板として運用。
* 投稿（board_posts）、コメント（board_comments）、添付（board_attachments）を基本構成とする。
* Part2で定義される「施設・翻訳・音声」機能と統合運用。

### 3.4.2 要件

| 機能    | 概要                                         |
| ----- | ------------------------------------------ |
| 掲示板一覧 | テナントスコープで投稿を取得。検索・タグ・並び替え対応                |
| 投稿詳細  | 翻訳済み本文をStaticI18nProviderで表示し、音声化可         |
| コメント  | board_comments テーブルに保存。親子スレッド対応            |
| 投稿作成  | エディタ（Markdown/WYSIWYG）対応、Draft保存可          |
| 添付    | PDF / 画像ファイルをSupabase Storage管理            |
| 通報    | board_reactions（reaction_type='report'）に記録 |
| 翻訳    | 翻訳キャッシュ translation_cache を参照し即時切替         |

### 3.4.3 通信仕様

* 通信は Supabase SDK 経由（`from('board_posts').select('*')`）。
* テナント分離は JWT 内の `tenant_id` により自動適用。
* Edge Function `/api/board` により投稿・削除操作を制御。

---

## 3.5 共通UI・アクセシビリティ要件

### 3.5.1 共通部品依存

| コンポーネントID | 名称                | 役割                           |
| --------- | ----------------- | ---------------------------- |
| C-01      | AppHeader         | ロゴ・言語切替・通知アイコン表示             |
| C-02      | LanguageSwitch    | 言語切替UI（StaticI18nProvider対応） |
| C-04      | AppFooter         | コピーライト表示（翻訳対応）               |
| C-05      | FooterShortcutBar | 主要機能ショートカット（権限別表示）           |
| C-09      | TranslateButton   | 手動翻訳トリガー（掲示板・お知らせ共通）         |
| C-12      | VoiceReader       | 音声読み上げ（TTS連携）                |

### 3.5.2 アクセシビリティ仕様

* WCAG 2.2 AA準拠。
* タブ移動順の一貫性保持。
* `aria-label` と `role` をすべてのボタンに明示。
* 翻訳切替時の `aria-live="polite"` 属性付与。
* Passkeyログイン時の状態変化も音声リーダーで通知。

---

## 3.6 データ構造（主要テーブル）

| テーブル                 | 用途      | 主キー                        | 備考                        |
| -------------------- | ------- | -------------------------- | ------------------------- |
| announcements        | お知らせ本体  | id                         | 有効期間・配信範囲を保持              |
| announcement_targets | 配信対象    | id                         | group / role / user単位で紐付け |
| announcement_reads   | 既読管理    | (announcement_id, user_id) | Supabase RLS適用            |
| board_posts          | 掲示板投稿   | id                         | 翻訳・音声連携対象                 |
| board_comments       | 掲示板コメント | id                         | parent_comment_id で階層化    |
| board_attachments    | 添付ファイル  | id                         | Supabase Storage連携        |

---

## 3.7 KPI / 成果指標

| 指標          | 目標値   | 備考                                      |
| ----------- | ----- | --------------------------------------- |
| ホーム初期ロード時間  | 2秒以内  | CDNキャッシュ込み                              |
| お知らせ既読率     | 95%以上 | Supabase Realtime監視                     |
| 掲示板投稿翻訳成功率  | 98%以上 | StaticI18nProvider / Google Translate連携 |
| アクセシビリティ適合率 | 100%  | WCAG 2.2 AA基準                           |

---

## 3.8 参照リンク

* **functional-requirements-ch03-functional-req-part2_*.*.md**（掲示板・翻訳・音声・通知機能詳細）
* **functional-requirements-ch04-nonfunctional-req_*.*.md**（非機能要件）
* **harmonet-technical-stack-definition_v4.1.md**（技術基盤仕様）
* **harmonet-security-spec_v4.1.md**（セキュリティ仕様）

---

**Document ID:** HNM-REQ-CH03-PART1-V1.4
**Version:** 1.4
**Created:** 2025-11-12
**Updated:** 2025-11-12
**Supersedes:** v1.3
**Status:** ✅ HarmoNet正式要件（技術スタックv4.1整合）
