# MagicLinkBackend-integration_v1.0

**Document ID:** HARMONET-LOGIN-BE-MAGICLINK
**Version:** v1.0
**Supersedes:** -
**Created:** 2025-11-17
**Author:** Tachikoma / TKD
**保存場所（規定）:** /01_docs/04_詳細設計/01_ログイン画面/

---

> **概要（本書の位置づけ）**
>
> 本詳細設計書は、HarmoNet の MagicLink 認証（Supabase OTP）に関するサーバ側（バックエンド）設計を定義する。
> 本書は Login Backend Basic Design v1.0 の方式（方式選定・責務分離）を踏襲し、実装可能な API 契約・処理フロー・エラー仕様・テスト観点を提供する。DB モデルの詳細（Prisma フィールド）は別途 schema.prisma_migration_plan_v1.0 で扱う。

---

## ch01 目的／対象範囲

### 1.1 目的

* MagicLink（メール OTP）を用いたパスワードレス認証フローのバックエンド実装指針を定義する。
* セキュリティ、可用性、エラーハンドリング、運用上の注意点を明確にする。

### 1.2 対象範囲

* Next.js（App Router）上の API Route / Edge Function を含むサーバ実装
* Supabase Auth の `signInWithOtp` / セッション確立 / callback 処理
* Mail 配信設定（開発: Mailpit／本番: SMTP/SendGrid）
* LoginPage（A-00）と MagicLinkForm（A-01）との契約（コール/リダイレクト）

### 1.3 非対象

* Prisma スキーマの細部（schema.prisma_migration_plan_v1.0 に委譲）
* UI 文言（LoginPage_MSG_Catalog に委譲）
* Passkey 固有ロジック（別設計書に委譲）

---

## ch02 前提・参照資料

* HarmoNet 技術スタック定義 v4.3（認証方式・Supabase 利用方針）
* Login Backend Basic Design v1.0（方式の上位定義）
* HarmoNet 非機能要件定義（NFR）

（実装時は上記参照ドキュメントに従い、Env 設定・Secrets を適切に管理すること）

---

## ch03 構成概要（責務分離）

### 3.1 コンポーネント責務

* **Frontend (A-01 MagicLinkForm)**

  * email 入力・送信トリガー
  * 送信状態の UI 表示（sent / error）
  * callback 受領後の画面遷移

* **Next.js API / Edge Function**

  * `/api/auth/magiclink/send` — メール送信要求受け取り（フロントから POST）
  * `/auth/callback` — メール内リンク到達時の共通 callback（Supabase セッション確認）
  * 必要に応じて `/api/auth/magiclink/verify`（補助的：OTP 検証／デバッグ用、運用限定）

* **Supabase Auth**

  * `signInWithOtp({ email })` を実行し、MagicLink をユーザに送信
  * callback 時にセッション Cookie を確立

### 3.2 動作方針（要点）

* クライアントは email を送信して即座に `202 Accepted`（処理キューイング）を受け取る。
* 実際のメール送信は Supabase 側が行うため、API は送信要求の成否（Supabase 呼出しの OK/NOK）とレート制御・ログを管理する。
* callback は `/auth/callback` に統一し、Supabase セッションの有無を確認してフロントへリダイレクト（必要なクエリパラメータを付加）する。
* セキュリティ要件により、Service Role Key の漏洩を回避するため、`signInWithOtp` は原則フロント経由で Supabase SDK を直接呼ぶ方式とし、サーバ経由が必要な場合は Edge Function 内で Service Role Key を安全に保持する（実運用では可能な限りクラウドシークレットを使用）。

---

## ch04 API 仕様（候補・実装ガイド）

> 本章では Next.js 上に実装する API Route / Edge Function の最小セットを示す。Windsurf の実装タスクはこの契約に準拠すること。

### 4.1 POST /api/auth/magiclink/send

**役割**: フロントから受け取った email を元に Supabase の `signInWithOtp` を呼び出し、MagicLink を発行する。

**Method**: POST

**Path**: `/api/auth/magiclink/send`

**Request** (JSON)

```json
{
  "email": "user@example.com",
  "redirectTo": "https://app.harmonet.example/auth/callback"
}
```

**Headers**

* `Content-Type: application/json`
* Authorization: なし（匿名呼出しを許容）

**Behavior / 実装ノート**

* サーバは受け取った email の形式チェックを行う（正規表現）。
* レート制御: 同一 IP / email に対して 60 秒間に 1 回の制限（詳細は運用パラメータ化）。
* ログ: 送信試行は INFO レベルで記録（PII はログに直書きしない。ハッシュ化して記録するか、イベントのみ記録）。
* Supabase の呼出しは client サイドでも可能。サーバ経由を選択する場合は `SUPABASE_SERVICE_ROLE_KEY` を Edge Secrets から取得して呼び出す（ただしセキュリティ・運用コストを考慮）。

**Success Response**

* HTTP 202 Accepted

```json
{ "status": "sent" }
```

**Error Responses**

* 400 Bad Request — email フォーマット不正
* 429 Too Many Requests — レート制限超過
* 502 Bad Gateway — Supabase 呼出しエラー

**Security**

* CSRF: POST は同一オリジン制約を厳守。API を公開する場合は CORS を明示的に制限。

---

### 4.2 GET /auth/callback

**役割**: メール内 MagicLink により到達する共通 callback。Supabase セッション状態を確認し、アプリ内のリダイレクト先に遷移させる。

**Method**: GET

**Path**: `/auth/callback` (フロントルートも同じパスを受け取る設計)

**Query**

* Supabase が付与するクエリ（`access_token` 等）は Supabase の仕様に従う。フロント側は `supabase.auth.onAuthStateChange` でセッション確定を検知する方式を推奨。

**Behavior / 実装ノート**

* サーバはリダイレクト先の検証（ホワイトリスト）を行う。
* セッションが有効であればアプリのトップページ、あるいはユーザが初回ログインであればマイページへリダイレクトする。
* Session 有無はサーバで確認できるが、Next.js App Router ではクライアント側での Supabase SDK 検知を中心とした UX 実装を優先する（SSR の場合は Cookie を読み取り判別可能）。

**Responses**

* 302 Redirect → `redirectTo` (クライアントが受け取り、必要な追加処理を行う)
* 401 Unauthorized — セッション確立失敗

---

### 4.3 補助: POST /api/auth/magiclink/health

* 実行状況と最近の送信メトリクス（短期）を返す（運用用）。
* このエンドポイントは認証済管理者のみアクセス可。内部ヘルスチェックのために実装。

---

## ch05 Supabase 呼出し方針（実装パターン）

### 5.1 フロント直接呼出し（推奨）

* フロントで `supabase.auth.signInWithOtp({ email, options: { redirectTo }})` を利用。
* 利点: Service Role Key のサーバ保管が不要で、実装がシンプル。
* 欠点: クライアント側からの濫用対策（レート制御）は別途必要。

### 5.2 サーバ経由呼出し（Edge Function）

* サーバで Service Role Key を保有して呼び出す場合は、Edge Function に限定して実装。
* 利点: レート制御・監査・送信ログの一元管理が可能。
* 欠点: Service Role Key の管理コストとセキュリティリスク。

**運用方針**: MVP はフロント直呼出しを基本とし、運用上の要件（監査／送信ログ一元化）が出た場合にサーバ経由へ切替を検討する。

---

## ch06 エラーハンドリング・ログ仕様

### 6.1 ログ出力方針

* 送信試行: INFO レベル（email はハッシュ化して記録）。
* 送信失敗: ERROR レベル（外部エラーコードを保持）。
* セキュリティ留意: PII を直接ログに出力しない。ログに残す場合は SHA256 等でハッシュ化する。

### 6.2 主なエラーコード設計

|    コード | HTTP | 説明                   |
| -----: | :--: | -------------------- |
| ML-001 |  400 | InvalidEmailFormat   |
| ML-002 |  429 | RateLimitExceeded    |
| ML-003 |  502 | SupabaseServiceError |
| ML-004 |  500 | InternalServerError  |

各エラーはフロントの MSG カタログにマッピングしてユーザ表示を制御する。

---

## ch07 セキュリティ要件

* 通信は TLS 1.2+（推奨 TLS1.3）を必須とする。
* Service Role Key は Edge Secrets またはクラウドシークレットマネージャで保護する。
* API は CORS ホワイトリストを厳格に設定する。
* ログに敏感情報（トークン、完全なメールアドレス、OTP 内容）を出力しない。

---

## ch08 環境変数

* NEXT_PUBLIC_SUPABASE_URL
* NEXT_PUBLIC_SUPABASE_ANON_KEY
* SUPABASE_SERVICE_ROLE_KEY (サーバ経由を採る場合のみ)
* NEXT_PUBLIC_APP_URL
* MAIL_FROM / MAIL_PROVIDER_CONFIG (開発: Mailpit / 本番: SendGrid 設定)

---

## ch09 テスト計画（概要）

### 9.1 ユニットテスト

* API Route 入力検証（email 形式、必須チェック）
* 受け取りロジックのレート制御関数

### 9.2 結合テスト

* Supabase のモックを利用して `signInWithOtp` 呼出しの正常系／異常系を検証
* callback シナリオ（有効な MagicLink → セッション確立）の E2E (ローカル Mailpit 経由)

### 9.3 受入基準

* `POST /api/auth/magiclink/send` が適切な入力で 202 を返し、Supabase へ送信要求が行われること。
* レート制御が働き、同一 email/IP の短期間連続送信をブロックすること。

---

## ch10 運用・監査・障害対応

* 送信失敗率が一定閾値（例: 5% / 1h）を超えた場合、運用チームへ通知する（現状は手動監視）。
* 重大な外部依存障害時は運用手順に従い、メール配信プロバイダ切替を実施する。

---

## ch11 付録（参考）

* 参照: Login Backend Basic Design v1.0
* 参照: HarmoNet 技術スタック定義 v4.3
* 参照: HarmoNet 非機能要件定義

---

## ChangeLog

* v1.0 - 2025-11-17 - 初版作成
