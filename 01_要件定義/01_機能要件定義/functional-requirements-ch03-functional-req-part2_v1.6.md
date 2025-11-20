# 第3章 機能要件定義（Part 2）v1.6（掲示板拡張・通知・施設予約・翻訳・音声・認証）

**準拠:** HarmoNet Functional Requirements v1.6（MagicLink / Google Translation API v3 / Google Cloud TTS）
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式要件（v1.6 完全整合）
**Updated:** 2025-11-19

---

## 3.1 概要

本章では、HarmoNet アプリケーションのコア機能である **掲示板（拡張機能）、通知、施設予約、翻訳、音声化、認証（MagicLink）** の要件を定義する。

* 認証: **Supabase MagicLink（OTP メール）**
* 翻訳: **Google Translation API v3**（Next.js API Route `/api/translate` 経由）
* 音声化: **Google Cloud Text-to-Speech**（Next.js API Route `/api/tts` 経由）
* キャッシュ: `translation_cache` / `tts_cache`（Supabase DB + Storage。Redis は任意）
* 通知: Supabase Realtime（WebSocket）

本章は Part 1 で定義した「ホーム／お知らせ／掲示板基礎機能」を前提とし、それらを支える **横断機能（通知・翻訳・音声・予約・認証）」の要件** を補完する位置付けとする。

---

## 3.2 掲示板機能（拡張要件）

### 3.2.1 機能概要

* 住民・管理者が投稿・閲覧・コメント・通報を行う情報共有機能。
* PDF プレビュー、翻訳、音声化に対応する。
* 投稿は `board_posts`、コメントは `board_comments`、添付は `board_attachments` に格納する。
* テナント境界は `tenant_id` により Supabase RLS で強制される。

### 3.2.2 主な機能

| 機能      | 概要                                                              |
| ------- | --------------------------------------------------------------- |
| 投稿作成    | Markdown / WYSIWYG 入力、ドラフト保存に対応。投稿者種別（一般／管理者）を保持する。             |
| 投稿編集・削除 | 投稿者本人または管理者が実行可能。削除は論理削除とし、履歴を保持する。                             |
| PDF 添付  | 添付ファイルは Supabase Storage に保存し、PDF.js によるプレビューをサポートする。           |
| コメント    | 親子スレッド構造（`parent_comment_id`）に対応し、最大 2 階層までを想定する。               |
| リアクション  | 「いいね」「通報」「ブックマーク」等を `board_reactions` に記録する。                    |
| 承認フロー   | （オプション）`board_approval_logs` により管理者承認フローを実現する。                  |
| 翻訳      | 翻訳ボタン操作時に `/api/translate` を呼び出し、結果を `translation_cache` に保存する。 |
| 音声化     | 音声ボタン操作時に `/api/tts` を呼び出し、生成音声を Storage にキャッシュする。              |

### 3.2.3 非機能要件リンク

* 翻訳応答: 1〜3 秒（キャッシュ命中時 1 秒未満）
* 音声生成: 1〜2 秒（Google Cloud TTS）
* 投稿数目安: テナントあたり最大 1 万件（RLS により分離）

---

## 3.3 通知機能

### 3.3.1 機能構成

通知機能は Supabase Realtime とメール通知を組み合わせた **軽量なアプリ内通知** とする。
監視・アラート用途の高度な監視システムは導入しない（非機能要件 v1.0 に準拠）。

| 通知種別   | 内容                                                                        |
| ------ | ------------------------------------------------------------------------- |
| お知らせ通知 | 新規お知らせ投稿、重要なお知らせ更新などを Realtime で購読し、対象ユーザーに未読バッジ等で通知する。                   |
| 掲示板通知  | 新規掲示板投稿・コメント・管理者からの pinned 投稿などを Realtime で通知する。                          |
| システム通知 | 翻訳・音声生成エラーなどを UI 上のトーストやバナーで通知する。DB には `error_logs` または audit 系テーブルで任意保存。 |
| メール通知  | 重要なお知らせについては SMTP を用いたメール送信を行う（Next.js API Route `/api/mail`）。            |
| プッシュ通知 | 将来拡張（FCM 等）。本 v1.6 では要件に含めない。                                             |

### 3.3.2 通知テンプレート管理

* メール・アプリ内通知の文言テンプレートは `/public/locales/{lang}/mail.json` もしくは専用 JSON で管理する。
* 多言語対応が必要な場合、StaticI18nProvider によるキー参照で文言取得を行う。

### 3.3.3 非機能要件

* 通知配信成功率: 99.5%以上（Supabase Realtime / SMTP ベース）
* 通知遅延: 通常 1〜3 秒以内

---

## 3.4 施設予約機能

### 3.4.1 機能概要

* 共用施設（集会所・駐車場等）の予約管理を行う。
* テーブル構造は `facilities` / `facility_slots` / `facility_reservations` を使用する。
* 予約の排他制御は Next.js API Route を用いたサーバサイドロジックで実装する。

### 3.4.2 処理要件

| 処理    | 内容                                                          |
| ----- | ----------------------------------------------------------- |
| 新規予約  | 空き状況を確認し、予約確定後に `facility_reservations` へ登録する。必要に応じ通知を送信する。 |
| キャンセル | `reservation_id` を指定して論理削除（ステータス更新）を行う。                     |
| 重複検知  | `start_at`〜`end_at` の重複を API Route 側で検査し、重複時はエラー返却する。       |
| 承認    | 管理者承認が必要な施設については、予約ステータスを `pending` -> `approved` の二段階とする。  |
| 料金計算  | `fee_unit` / `fee_per_day` に基づき料金を算出（任意機能）。                 |

### 3.4.3 パフォーマンス要件

* 予約登録 API 応答: 2 秒以内
* 重複検知を含むバリデーション: 1 秒以内

---

## 3.5 翻訳・音声機能

### 3.5.1 概要

翻訳および音声化は、掲示板・お知らせ・施設予約などのコンテンツに対して **共通機能として提供** される。

* 静的翻訳: StaticI18nProvider（`common.json`）
* 動的翻訳: Google Translation API v3
* 音声化: Google Cloud Text-to-Speech
* キャッシュ: `translation_cache` / `tts_cache`（Supabase DB + Storage）

### 3.5.2 処理フロー（翻訳）

```
1. ユーザーが「翻訳」ボタンを押下
2. クライアント → `/api/translate` に原文・言語情報を送信
3. API Route で translation_cache を参照
4. キャッシュヒット: キャッシュ値を返却
5. キャッシュなし: Google Translate API v3 呼出
6. 結果を translation_cache に保存し、クライアントへ返却
7. StaticI18nProvider を通じて UI へ反映
```

### 3.5.3 処理フロー（音声化）

```
1. ユーザーが「音声読み上げ」ボタンを押下
2. クライアント → `/api/tts` にテキスト・対象言語を送信
3. API Route で tts_cache（DB/Storage）を参照
4. キャッシュヒット: 既存の音声 URL を返却
5. キャッシュなし: Google Cloud TTS を呼び出し音声生成
6. 生成した音声を Supabase Storage に保存し、URL を tts_cache に登録
7. 音声 URL をクライアントへ返却し、プレーヤーで再生
```

### 3.5.4 i18n 翻訳キー仕様

* 静的文言: `/public/locales/{lang}/common.json` に定義
* key プレフィックス例:

  * 掲示板: `board.*`
  * お知らせ: `announcement.*`
  * 施設: `facility.*`
* API 失敗時は日本語テキストにフォールバックし、UI 上に簡潔なエラーメッセージを表示する。

---

## 3.6 認証・セッション管理（MagicLink）

### 3.6.1 認証方式

| 区分     | 実装方式                        |
| ------ | --------------------------- |
| 一般ユーザー | Supabase MagicLink（OTP メール） |

* Passkey（WebAuthn）は v1.6 要件では非採用とする。

### 3.6.2 セッション確立

* Supabase が発行するセッション Cookie を唯一のログイン状態の根拠とする。
* `detectSessionInUrl=true` を利用して、MagicLink 経由のログイン完了時にクライアント側でセッションを検出する。

### 3.6.3 セキュリティ要件

* HTTPS（TLS1.3）必須
* JWT 有効期限目安: 60 分（Supabase 標準設定）
* RLS: `tenant_id = auth.jwt()->>'tenant_id'` によるテナント分離
* Service Role Key は API Route 内部のみで使用し、クライアントへ露出しない。

---

## 3.7 KPI / 成果指標

| 指標               | 目標値     | 備考                                |
| ---------------- | ------- | --------------------------------- |
| 翻訳キャッシュヒット率      | 90%以上   | translation_cache / tts_cache の活用 |
| 音声生成成功率          | 98%以上   | Google Cloud TTS                  |
| 施設予約登録成功率        | 99%以上   | API Route 実装品質                    |
| 通知配信成功率          | 99.5%以上 | Realtime / SMTP                   |
| 認証成功率（MagicLink） | 99.9%以上 | Supabase Auth                     |

---

## 3.8 参照資料

* functional-requirements-ch03-functional-req-part1_v*.*.md
* functional-requirements-ch04-nonfunctional-req_*.*.md
* functional-requirements-ch05-config-env_*.*.md
* harmonet-technical-stack-definition_v*.*.md
* harmonet-security-spec_v*.*.md

---

**Document ID:** HNM-REQ-CH03-PART2-V1.6
**Version:** 1.6
**Created:** 2025-11-19
**Updated:** 2025-11-19
**Supersedes:** v1.5
**Status:** ✅ HarmoNet 正式要件（MagicLink + Google 翻訳 + Google Cloud TTS 版）
