# 第3章 機能要件定義（Part 2）v1.5（MagicLink + Google 翻訳 + VOICEVOX 構成）

**準拠:** HarmoNet Technical Stack Definition v4.3（Next.js 16.x / React 19 / Supabase Cloud / Prisma ORM / TailwindCSS / shadcn/ui / StaticI18nProvider / Google Translation API v3 / VOICEVOX）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式要件（MagicLink + Google 翻訳 + VOICEVOX 構成整合）
**Updated:** 2025-11-19

---

## 3.1 概要

本章では、HarmoNet アプリケーションのコア機能である **掲示板、通知、施設予約、翻訳、音声化** の要件を定義する。
すべての機能は、**Supabase Cloud（認証・DB・ストレージ・Realtime）＋ Next.js API Routes（翻訳・音声処理）＋ StaticI18nProvider（静的翻訳）＋ Google Translation API v3（動的翻訳）＋ VOICEVOX（TTS）** を前提とする。

---

## 3.2 掲示板機能

### 3.2.1 機能概要

* 住民／管理者が投稿・閲覧・コメントを行う情報共有機能。
* PDF プレビュー、翻訳、音声化に対応。
* 投稿は `board_posts`、コメントは `board_comments`、添付は `board_attachments` に格納。
* テナント分離は `tenant_id` により Supabase RLS で制御。

### 3.2.2 主な機能

| 機能     | 概要                                                       |
| ------ | -------------------------------------------------------- |
| 投稿作成   | Markdown / WYSIWYG 入力、Draft 保存可                          |
| PDF 添付 | PDF.js によるプレビュー、Storage 保存                               |
| コメント   | 親子スレッド対応。削除時は論理保持                                        |
| リアクション | いいね・通報・ブックマーク（`board_reactions`）                         |
| 承認フロー  | tenant_admin による承認制（`board_approval_logs`）               |
| 翻訳     | Google Translation API v3 + translation_cache による動的翻訳    |
| 音声化    | VOICEVOX API による TTS 生成（Next.js API Route `/api/tts` 経由） |

### 3.2.3 非機能要件リンク

* 翻訳応答：1〜3 秒（キャッシュ命中時 1 秒未満）
* PDF プレビュー：1MB を 2 秒以内表示
* 投稿数：テナントあたり最大 1 万件（RLS による分離）

---

## 3.3 通知機能

### 3.3.1 構成

通知は Supabase Realtime（WebSocket）を中心としたアプリ内通知で構成する。

| 通知区分   | 内容                                        |
| ------ | ----------------------------------------- |
| お知らせ通知 | 新規掲示板投稿・承認完了・管理者告知。Realtime チャネル送信        |
| システム通知 | 翻訳エラー・音声生成エラー等。`error_logs` に記録して UI 通知   |
| メール通知  | SMTP 経由。Next.js API Route `/api/mail` で送信 |
| プッシュ通知 | 必要時に実装（FCM）                               |

### 3.3.2 通知テンプレート管理

* 翻訳対応テンプレートは `/public/locales/{lang}/mail.json` に保存。
* Supabase Storage 経由で送信ログ（`audit_logs`）を保存。

---

## 3.4 施設予約機能

### 3.4.1 機能概要

* 共用施設（集会所・駐車場等）の予約管理。
* テーブル構造は `facilities` / `facility_slots` / `facility_reservations` に基づく。
* 排他制御は Next.js API Route で実装（EdgeFunction 非使用）。

### 3.4.2 処理要件

| 処理    | 内容                                                 |
| ----- | -------------------------------------------------- |
| 新規予約  | 空き状況確認 → 予約確定 → 通知                                 |
| キャンセル | `reservation_id` 指定で論理削除                           |
| 重複検知  | `start_at`〜`end_at` の重複チェックを Next.js API Route で実行 |
| 承認    | 管理者承認オプション（施設設定依存）                                 |
| 料金計算  | `fee_unit` / `fee_per_day` により計算（任意）               |

### 3.4.3 パフォーマンス要件

* 予約登録 API 応答：2 秒以内
* 予約競合チェック：Next.js API Route により高速化
* キャッシュ TTL：10 分（Redis）

---

## 3.5 翻訳・音声機能

### 3.5.1 概要

* 静的翻訳は `StaticI18nProvider`（common.json）
* 動的翻訳は `Google Translation API v3`（Next.js API Route `/api/translate`）
* 音声化は `VOICEVOX API`（Next.js API Route `/api/tts`）
* 結果は `translation_cache` / `tts_cache` に保存
* Redis キャッシュ併用

### 3.5.2 処理フロー

```
1. 投稿本文取得（tenant_id）
2. translation_cache にヒット確認
3. キャッシュなし → Google Translation API v3 呼出
4. 結果を保存 + キャッシュ登録
5. 音声化要求 → VOICEVOX API 呼出
6. 音声URL を tts_cache に保存
```

### 3.5.3 i18n 翻訳キー仕様

* `/public/locales/{lang}/common.json`
* key プレフィックス：`board.*`, `announcement.*`, `facility.*` など
* 翻訳 API 失敗時は日本語にフォールバック

---

## 3.6 認証・セッション管理（MagicLink のみ）

### 3.6.1 認証

| 区分      | 実装方式                                          |
| ------- | --------------------------------------------- |
| 一般ユーザー  | Supabase MagicLink（OTP メール）                   |
| セッション確立 | PKCE + `detectSessionInUrl=true` によるクライアント側認証 |
| 認可      | `/home` Server Component で user + tenant を確認  |

### 3.6.2 セキュリティ

* HTTPS（TLS1.3）必須
* JWT 有効期限：60 分（自動更新）
* RLS：`tenant_id = jwt.tenant_id` または `user_id = jwt.sub`
* Service Role Key はサーバ内部のみで使用

---

## 3.7 KPI / 成果指標

| 指標           | 目標値     | 備考                   |
| ------------ | ------- | -------------------- |
| 翻訳キャッシュヒット率  | 90%以上   | Redis 利用時            |
| 予約登録成功率      | 99%以上   | Next.js API Route 基準 |
| 通知配信成功率      | 99.5%以上 | Realtime / SMTP      |
| 認証成功率        | 99.9%以上 | MagicLink PKCE       |
| Supabase 稼働率 | 99.5%以上 | SLA                  |

---

## 3.8 参照資料

* functional-requirements-ch03-functional-req-part1_v1.5.md
* functional-requirements-ch04-nonfunctional-req_v1.4.md
* functional-requirements-ch05-config-env_v1.6.md
* harmoNet-technical-stack-definition_v4.3.md
* harmoNet-security-spec_v4.1.md

---

**Document ID:** HNM-REQ-CH03-PART2-V1.5
**Version:** 1.5
**Created:** 2025-11-12
**Updated:** 2025-11-19
**Supersedes:** v1.4
**Status:** ✅ HarmoNet 正式要件（MagicLink + Google 翻訳 + VOICEVOX 整合）
