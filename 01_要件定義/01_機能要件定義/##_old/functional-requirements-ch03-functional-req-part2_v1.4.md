# 第3章 機能要件定義（Part 2）v1.4

**準拠:** HarmoNet Technical Stack Definition v4.1（Next.js 16.1 / React 19 / Supabase Cloud / Corbado SDK / Prisma ORM / TailwindCSS 4.0）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet正式要件定義（v4.1整合）
**Updated:** 2025-11-12

---

## 3.1 概要

本章では、HarmoNetアプリケーションにおける主要機能のうち「掲示板・通知・施設予約・翻訳・音声化」など、住民／管理者が日常的に利用するコア機能群の要件を定義する。
設計・実装はいずれも Supabase Cloud / Corbado SDK / StaticI18nProvider を前提とし、Phase表現を廃止してカテゴリ単位で管理する。

---

## 3.2 掲示板機能

### 3.2.1 機能概要

* 管理組合／住民が投稿・閲覧・コメントを行う。
* PDF添付・翻訳・音声読み上げ機能を統合。
* 投稿は `board_posts`、コメントは `board_comments`、添付は `board_attachments` テーブルに格納。
* テナント分離はすべて `tenant_id` により制御（RLS有効）。

### 3.2.2 主な機能

| 機能     | 概要                                          |
| ------ | ------------------------------------------- |
| 投稿作成   | Markdown / WYSIWYG入力対応、下書き保存可               |
| PDF添付  | PDF.js によるプレビュー + Supabase Storage保存        |
| コメント   | 親子スレッド構造対応、削除時も論理保持                         |
| リアクション | いいね・通報・ブックマーク（`board_reactions`）            |
| 承認フロー  | tenant_admin承認制（`board_approval_logs`）      |
| 翻訳     | StaticI18nProvider + translation_cache連携    |
| 音声化    | VOICEVOX APIによるTTS変換、Supabase `/api/tts` 呼出 |

### 3.2.3 非機能要件リンク

* 翻訳応答：3秒以内（Redisキャッシュ命中時1秒未満）
* PDFプレビュー：1MB以内ファイルを2秒以内描画
* 投稿件数：1テナントあたり最大1万件（RLS保証）

---

## 3.3 通知機能

### 3.3.1 構成

通知は Supabase Realtime と Supabase Storage を中心に実装し、メール通知・アプリ内通知を統合管理する。

| 通知区分   | 機能                 | 備考                                     |
| ------ | ------------------ | -------------------------------------- |
| お知らせ通知 | 新規掲示板投稿・承認完了・管理者告知 | Supabase Realtime `notifications` チャネル |
| システム通知 | 翻訳エラー・TTS失敗など自動検知  | Sentry連携 + `error_logs` テーブル           |
| メール通知  | SendGrid（SMTP経由）   | Supabase Edge Function `/api/mail` で送信 |
| プッシュ通知 | 将来拡張（FCM）          | Phase概念廃止。必要時カテゴリ拡張として対応               |

### 3.3.2 通知テンプレート管理

* 翻訳対応テンプレートを `/public/locales/{lang}/mail.json` に保存。
* Supabase Storage経由で配信ログを自動生成（`audit_logs` テーブルに記録）。
* テナントスコープは `tenant_id` により自動制御。

---

## 3.4 施設予約機能

### 3.4.1 機能概要

* 共用施設（集会所・駐車場等）の予約登録／キャンセルをオンライン管理。
* テーブル構造は `facilities` / `facility_slots` / `facility_reservations` に準拠。
* Supabase Edge Functionで排他制御を実装。

### 3.4.2 処理要件

| 処理    | 内容                                          |
| ----- | ------------------------------------------- |
| 新規予約  | 空き状況確認→予約確定→通知発行                            |
| キャンセル | 予約ID指定で削除フラグ付与（論理削除）                        |
| 重複検知  | `start_at`〜`end_at` 重複チェックをEdge Functionで実行 |
| 承認    | 管理者承認オプションあり（施設設定依存）                        |
| 料金    | `fee_unit` / `fee_per_day` に基づく計算（オプション）    |

### 3.4.3 パフォーマンス要件

* 予約登録API応答：2秒以内（DBトランザクション含む）
* Edge Function同時呼出：50リクエスト／秒まで対応
* キャッシュTTL：10分（Redis）

---

## 3.5 翻訳・音声機能

### 3.5.1 概要

* 翻訳は StaticI18nProvider を基盤とし、Google Translate v3 を補完利用。
* 音声変換は VOICEVOX API を Supabase Edge `/api/tts` 経由で呼び出す。
* 翻訳結果と音声URLはそれぞれ translation_cache / tts_cache テーブルに保持。
* Redis キャッシュを併用し、期限切れ（TTL 7日）で自動無効化。

### 3.5.2 処理フロー

```
1. 投稿データ取得（tenant_idスコープ）
2. 翻訳対象文字列を抽出
3. translation_cache にヒット確認
4. キャッシュなし → Google Translate API呼出
5. 結果保存 + Redis書込
6. 音声化要求時 → VOICEVOX呼出 → tts_cache 登録
```

### 3.5.3 i18n仕様

* 翻訳辞書：`/public/locales/{lang}/common.json` 形式（静的ロード）
* 翻訳キー：`auth.*`, `board.*`, `facility.*` などドメイン別プレフィックス管理
* 翻訳キャッシュキー：`translation:{content_id}:{lang}`
* 翻訳API失敗時は日本語にフォールバック。

---

## 3.6 認証・セッション管理

### 3.6.1 Supabase + Corbado連携構成

| 区分       | 実装方式                              | 備考                             |
| -------- | --------------------------------- | ------------------------------ |
| 一般ユーザー   | Supabase MagicLink                | OTPメールで即時ログイン                  |
| 管理者／運用担当 | Corbado Passkey                   | short_session Cookieで認証維持      |
| セッション確立  | Supabase Auth `signInWithIdToken` | Corbado JWTを検証しSupabaseセッション発行 |
| テナント分離   | RLSポリシーでtenant_idスコープ制御           | JWTクレームを直接参照                   |

### 3.6.2 セキュリティ仕様

* HTTPS通信必須（TLS 1.3）
* Corbado Cookie: `Secure + Lax`
* JWT有効期限: 60分（Supabase自動再発行）
* RLSポリシー: `tenant_id` 一致でアクセス許可
* Service Role Keyはサーバー内部でのみ使用可。

---

## 3.7 KPI / 成果指標

| 指標          | 目標値     | 備考                       |
| ----------- | ------- | ------------------------ |
| 翻訳キャッシュヒット率 | 90%以上   | Redis利用時                 |
| 予約登録成功率     | 99%以上   | Edge Function安定性基準       |
| 通知配信成功率     | 99.5%以上 | Supabase Realtime／SMTP統合 |
| 認証成功率       | 99.9%以上 | MagicLink + Passkey統合構成  |
| Supabase稼働率 | 99.5%以上 | SLA準拠                    |

---

## 3.8 リンク・参照

* **functional-requirements-ch04-nonfunctional-req_v1.4.md**（非機能要件）
* **functional-requirements-ch05-config-env_v1.5.md**（外部API・環境変数）
* **harmonet-technical-stack-definition_v4.1.md**（技術基盤仕様）
* **harmonet-security-spec_v4.1.md**（セキュリティ仕様）

---

**Document ID:** HNM-REQ-CH03-PART2-V1.4
**Version:** 1.4
**Created:** 2025-11-12
**Updated:** 2025-11-12
**Supersedes:** v1.3
**Status:** ✅ HarmoNet正式要件（技術スタックv4.1整合）
