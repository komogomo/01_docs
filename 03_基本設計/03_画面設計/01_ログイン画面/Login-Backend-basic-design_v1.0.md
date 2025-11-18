# ログイン画面 バックエンド基本設計書 v1.0

## 第1章 概要

### 1.1 文書の目的

本書は、HarmoNet におけるログイン機能（MagicLink 認証・Passkey 認証）のバックエンド構造および方式を統合的に定義する。認証に関わる各レイヤ（Next.js App Router、Corbado、Supabase Auth、RLS、DB）の役割分担を明確化し、後続の詳細設計書群および実装（Windsurf）に対して統一された上流仕様を提供することを目的とする。

### 1.2 対象範囲

* LoginPage（A-00）が利用するバックエンド
* MagicLinkForm（A-01）が発行する OTP 認証処理
* PasskeyAuthTrigger（A-02）が利用する Passkey 認証処理
* `/auth/callback` を中心とするセッション確立処理
* Corbado → Supabase Auth 統合方式
* ユーザー・テナント境界（RLS）と認証の関係

### 1.3 非対象

* UI の詳細・文言・エラーメッセージ仕様
* Prisma のフィールド定義、migration SQL
* 関数シグネチャ・API の JSON スキーマ
* テスト仕様（UT/IT/E2E）

### 1.4 関連文書

* 機能要件定義書 v1.4
* 非機能要件定義書 v1.0
* 技術スタック定義 v4.3
* LoginPage / MagicLinkForm / PasskeyAuthTrigger 詳細設計書
* Passkey 認証の仕組みと挙動 v1.0
* schema.prisma

---

## 第2章 認証方式とアーキテクチャ

### 2.1 認証方式の構成

HarmoNet のログインは次の 2 系統で構成する：

* **MagicLink 認証**：Supabase Auth の signInWithOtp を用いたメール OTP 認証
* **Passkey 認証**：Corbado による WebAuthn 認証 → Supabase Auth の signInWithIdToken によるセッション確立

両方式は LoginPage 上で独立した UI（A-01/A-02）として提示し、ユーザーが選択可能とする。

### 2.2 アーキテクチャ要素

* **Next.js App Router**：認証フローの入口（/login）および callback 処理
* **Corbado**：Passkey 登録・認証のオーケストレーション
* **Supabase Auth**：MagicLink / Passkey 双方の最終的なセッション提供者
* **RLS (Row Level Security)**：テナント境界を強制

### 2.3 認証フロー（概要）

**MagicLink**：

1. A-01 から email を受け取る
2. Supabase Auth が OTP を送信
3. メール内リンク → `/auth/callback`
4. Supabase セッション確立 → アプリへ遷移

**Passkey**：

1. A-02 から Corbado SDK を起動
2. WebAuthn 認証成功 → Corbado が ID Token 発行
3. ID Token を API Route へ送信
4. Supabase の signInWithIdToken によりセッション確立

### 2.4 Corbado Webhook（A/B）検討と採用方針

Corbado は Passkey の作成・更新・削除を通知する Webhook を提供するが、HarmoNet MVP では以下理由により **A：Webhook 不採用** とする。

**理由**：

* MVP は単一テナント・ログイン機能のみ要求され、Passkey 一覧・管理機能が不要
* Passkey の同期精度がなくても Supabase は認証時に最新状態を検証でき、ログイン品質に影響しない
* Webhook 署名検証・秘密鍵管理の導入コストを避け、安全性を確保
* 後から管理機能要件が発生した際に B 方式へ拡張可能（改修規模は小）

**結果（設計方針）**：

> HarmoNet MVP では Corbado Webhook を採用しない。Passkey 認証は Corbado → Supabase Auth の統合で成立し、同期精度は将来拡張とする。

---

## 第3章 バックエンド API・エンドポイント方式（概要）

### 3.1 バックエンドの主要エンドポイント

* `/auth/callback`：MagicLink と Passkey 共通のセッション確立ポイント
* `/api/auth/passkey`：Corbado からの ID Token を Supabase 認証へ橋渡し
* Supabase Auth（外部）：OTP 発行 / ID Token 認証

### 3.2 MagicLink 用エンドポイント方式

* A-01 から email を受信し、Supabase Auth の signInWithOtp を呼び出す
* Supabase 側でユーザー未登録なら自動作成
* 認証完了後、callback URL にリダイレクト

### 3.3 Passkey 用エンドポイント方式

* A-02 → Corbado → WebAuthn デバイス
* 認証成功後に Corbado が ID Token を返却
* API Route が Supabase signInWithIdToken を呼び出し、セッション確立

### 3.4 エラーハンドリング（方式レベル）

### 3.3.1 Passkey 未登録時のログイン制御（UI ガード）

#### 【本方式が必要となる理由】

HarmoNet は「不特定多数が自らアカウント登録できない」運用モデルであり、Passkey が本来必要とする *Account Binding（既知アカウントとの紐付け）* を満たすためには、以下の厳密な前提が必要となる。このフローは WebAuthn/FIDO2 の性質および HarmoNet のユーザ管理方式と完全整合し、本システムで Passkey を安全に利用するための唯一成立する手順である。

---

#### 【HarmoNet における Passkey 利用フロー（唯一成立する手順）】

**1. 利用者 → 書面にて利用者登録申請**
**管理者 → ユーザマスタへ登録**

* HarmoNet の根本要件（不特定多数の登録不可）。
* この時点で初めて「アカウントの存在」が確定する。
* Passkey は“既知アカウント”が前提のため、この工程が必須となる。

**2. 利用者 → メールアドレス入力 → MagicLink による初回ログイン**

* 初回は MagicLink が「唯一成立する」本人確認手段。
* Passkey は初回ログインでは成立しない（誰のアカウントか識別できないため）。

**3. ログイン状態でマイページへ遷移 → 「Passkey 利用を ON」**

* ここで“ユーザID と本人が初めて確実に一致”する。
* Passkey 登録の必要条件（本人確認済・既知アカウント）が満たされる。

**4. この時点で初めて Passkey が生成される（Corbado）**

* Corbado は Passkey 生成時に「アカウント識別子（email/userId）」を要求する。
* MagicLink による本人認証後でなければ Passkey を安全に紐付けできない。
* ログイン画面での“初回 Passkey 生成”が構造的に不可能な理由がここにある。

**5. Passkey 生成済 → 次回ログインから Passkey が使用可能**

* この時点で初めて Account Binding（認証器とユーザの結びつき）が完了する。
* 認証器（Passkey）が「既存ユーザのものである」ことが保証される。

---

#### 【結論】

上記 1〜5 のフローは HarmoNet の運用要件（ユーザマスタ登録制）と WebAuthn の技術仕様の双方から導かれる **唯一成立する Passkey 利用モデル** である。このため、ログイン画面の Passkey ログインボタンは「Passkey を既に登録済みの利用者のみ使用可能」となり、未登録時には UI 側でメッセージ表示し、Corbado 認証を開始しない方式とする。

#### 【本方式が必要となる理由】

HarmoNet は「不特定多数が自らアカウント登録できない」運用モデルであり、ユーザマスタに事前登録された利用者のみがサービスを利用する。このため、Passkey は以下の制約により **初回ログイン前には生成できない**。

* Passkey（WebAuthn）は「既知のユーザ ID に紐付けて生成する」特性があるため、ログイン前は利用者を特定できない。
* HarmoNet では本人確認を MagicLink のみで行う設計であり、初回ログイン＝MagicLink が必須となる。
* よって、Passkey 新規登録は MagicLink ログイン後のマイページでのみ可能となる。

この構造的制約により、ログイン画面の Passkey ボタンは **“すでに Passkey を紐付け済みの利用者専用のショートカット”** となり、未登録時は UI 側でメッセージを提示して処理を終了させる必要がある。
HarmoNet の運用要件上、Passkey は初回 MagicLink ログイン後にマイページで有効化されるため、ログイン画面における Passkey ログインボタンは「登録済みユーザ専用」となる。

**方式方針：**

* Passkey 未登録ユーザがボタンを押下した場合、Corbado 認証は開始せず、UI でメッセージ表示して終了する。
* 未登録かどうかの判定は、UI 側の前処理（メールアドレス入力状態など）にて行い、バックエンドロジックには影響させない。
* 文言仕様は LoginPage_MSG_Catalog にて定義し、詳細設計に委譲する。

---

### 3.4 エラーハンドリング（方式レベル）

* Corbado エラー（NotAllowedError / DeviceError）は API Route で共通フォーマットに変換
* Supabase 側エラーは HTTP 401/400 にマッピング
* UI での表示文言は詳細設計に委譲

### 3.5 セキュリティ方式

* すべての認証関連通信は HTTPS/TLS を前提とする。
* Supabase セッション Cookie は HttpOnly / Secure / SameSite=Lax 以上を推奨とし、ブラウザ JS からの直接参照を禁止する。
* Corbado の short_session Cookie は Passkey フローの補助としてのみ利用し、HarmoNet 側の認可・認証判断には使用しない。
* CSRF 対策は Next.js 側の標準機構＋ Origin/Referer チェックを採用し、認証リクエストは同一オリジンからのみ受け付ける。

---

## 第4章 データモデルおよび RLS 設計（ログイン関連・概要）

### 4.1 ログイン関連テーブル

ログイン機能に直接関係するテーブルを以下に整理する（詳細なカラム定義は schema.prisma および DB 詳細設計に委譲）。

* `users`：アプリケーション利用者アカウントの基本情報（メールアドレス等）
* `tenants`：管理組合・団地などテナント単位の情報
* `user_tenants`：ユーザとテナントの紐付け（1ユーザ複数テナント想定）
* `passkey_credentials`：Corbado によって登録された Passkey のメタ情報（credentialId など）
* `audit_logs`（名称は暫定）：ログイン成功・失敗等の監査ログを記録するテーブル（別途ログ設計書で詳細定義）

### 4.2 ユーザマスタ登録とログインの関係

* HarmoNet は「ユーザマスタに事前登録された利用者のみがログイン可能」という前提で設計する。
* 利用者は自らアカウント登録できず、管理者（管理組合）が書面申請を受けて `users` テーブルに登録する。
* MagicLink による初回ログインは、ユーザマスタ登録済であることを前提とした本人確認手段として扱う。

### 4.3 Passkey 情報の保持方針

* `passkey_credentials` テーブルには、credential の識別子や紐付く `user_id`、最終利用日時等のメタ情報のみを保持する。
* 実際の鍵素材やデバイス固有情報は Corbado 側で保持し、HarmoNet DB には保存しない。
* Corbado Webhook は MVP では利用せず、`passkey_credentials` の更新は主にログイン後の Passkey 登録フローで行われる。

### 4.4 RLS とテナント境界

* すべてのログイン後のデータアクセスは Supabase RLS を前提とし、JWT 内の `tenant_id`（もしくは user_tenants 経由で解決されるテナント情報）によりテナント境界を強制する。
* 認証成功後に発行される Supabase セッションには、ユーザが所属するテナント情報を特定できる情報を保持する。
* ログイン処理自体はテナント非依存としつつ、ログイン後の画面遷移時点でテナントを決定する方針とする（詳細は画面遷移・メニュー設計に委譲）。

---

## 第5章 セッションおよびトークン管理方式（概要）

### 5.1 Supabase セッション管理

* HarmoNet における「有効なログイン状態」は、Supabase Auth が発行するセッショントークンを唯一の根拠とする。
* MagicLink / Passkey いずれの方式でも最終的には Supabase がセッションを保持し、Next.js 側では Supabase クライアントを通じて現在のログイン状態を取得する。

### 5.2 MagicLink セッションフロー

* MagicLink 認証完了後、Supabase はブラウザにセッション Cookie を設定する。
* `/auth/callback` では Supabase セッションの有無と有効期限を確認し、ログイン後の遷移先（トップページ／マイページ等）を決定する。
* セッションの有効期限や更新ポリシーは Supabase の標準設定を用い、カスタムが必要な場合は別途詳細設計で定義する。

### 5.3 Passkey セッションフロー

* Corbado での WebAuthn 認証成功後、Corbado が ID Token（JWT）を発行する。
* `/api/auth/passkey` では、この ID Token を Supabase Auth の `signInWithIdToken` に引き渡し、Supabase セッションを確立する。
* Corbado の short_session Cookie は、Passkey 認証フローを簡略化するための補助的な一時セッションとみなし、HarmoNet 側の認可判断には使用しない。

### 5.4 ログアウトとセッション失効

* ログアウト操作は Supabase のセッション削除 API を呼び出し、ブラウザのセッション Cookie を無効化する方式とする。
* パスワードレス構成のため、セッション失効後の再ログインは MagicLink または Passkey により行う。
* 自動ログアウト（タイムアウト）の具体的な時間は NFR に基づき Supabase 側の設定で管理し、フロント側では残り時間表示等の UI は必須要件とはしない（必要であれば詳細設計で検討）。

---

## 第6章 エラーハンドリングおよびログ出力方式（バックエンド観点・概要）

### 6.1 想定される主なエラーカテゴリ

* MagicLink 発行失敗（メール送信エラー、レート制限など）
* MagicLink リンク無効（期限切れ、すでに使用済み）
* Passkey 認証エラー（ユーザキャンセル、NotAllowedError、対応デバイスなし等）
* Corbado 連携エラー（ID Token 検証失敗、設定不備）
* Supabase 認証エラー（`signInWithOtp` / `signInWithIdToken` 失敗）
* ネットワーク・一時障害（外部サービス応答遅延など）

### 6.2 HTTP ステータスおよびレスポンス方針

* 認証失敗（資格情報が正しくない、Passkey 不一致等）：HTTP 401 を基本とする。
* リクエスト不備（必須パラメータ欠如等）：HTTP 400。
* 外部サービスエラー（Corbado/Supabase 側障害）：HTTP 502/503 を状況に応じて利用。
* UI には技術的詳細を露出せず、ユーザ向けメッセージは LoginPage_MSG_Catalog で定義された文言にマッピングする。

### 6.3 ログ出力ポリシー（概要）

* ログイン関連のイベント（成功・失敗）は、共通ログユーティリティを通じて INFO/ERROR レベルで記録する。
* セキュリティ上センシティブな情報（トークン値、メール本文、Passkey の内部情報など）はログに残さない。
* 外部監視サービス（SaaS 型エラートラッキング等）は導入せず、Vercel/Supabase 標準ログ＋アプリケーションログのみで運用する（詳細は非機能要件およびログ設計書参照）。

### 6.4 非機能要件との関係（ログイン観点）

* 認証処理時間は、MagicLink/Passkey ともにユーザ体感として許容される範囲（数秒以内）を目標とし、外部サービス障害時にはタイムアウトと簡潔なエラーメッセージ表示で復旧を促す。
* ログは障害解析と不正アクセス検知のために一定期間保持するが、MVP 段階ではシンプルな構成（アプリログ＋DBログ）にとどめる。
* 監視・アラートの詳細な設計は将来の運用要件に応じて別途検討し、本書ではログイン機能が依存する最小限の前提のみ定義する。

---

## 第7章 非機能要件とのトレース（ログインバックエンド観点）

### 7.1 性能要件との対応（認証処理）

* MagicLink／Passkey 認証は外部サービス（Supabase／Corbado）を利用するが、いずれも数秒以内に応答する設計を前提とする。
* 認証後のセッション確立は Supabase によって即時に行われ、Next.js 側での遷移はレイテンシ最小となる。
* 外部サービス障害時は UI 側で簡潔なエラー通知（MSG カタログ参照）を行い、再試行により復旧を促す。

### 7.2 セキュリティ要件との対応（パスワードレス構成）

* 認証はすべて HTTPS/TLS を前提とし、中間者攻撃を防止する。
* Supabase セッション Cookie は HttpOnly とし、JS からの参照を禁止する。
* Passkey 認証器情報（秘密鍵）はブラウザ・OS が保持し、HarmoNet／Supabase／Corbado のいずれにも保存されない。
* 認証結果の判定は Supabase Auth の JWT 検証に一本化することで、権限昇格などの不整合を防止する。

### 7.3 可用性・運用要件との対応

* 認証処理は Supabase と Corbado のマネージドサービスに依存するが、MVP フェーズでは SLA 未保証でも許容する方針。
* ログイン障害時の一次切り分けは Vercel／Supabase の標準ログを利用し、本番運用に移行するタイミングで監視強化を検討する。
* Webhook（Corbado → HarmoNet）は利用しないため、Webhook 落ちによる同期不整合は発生しない。

---

## 第8章 将来の詳細設計との関係整理

### 8.1 PasskeyBackend-detail-design_v1.0 との関係

* 本基本設計書で定義した Passkey フロー（MagicLink 初回 → マイページ登録 → 次回以降 Passkey 認証）に基づき、詳細設計では API 入出力、Corbado SDK の処理手順、エラー変換方式を定義する。

### 8.2 MagicLinkBackend-integration_v1.0 との関係

* MagicLink 発行／認証成功後の `/auth/callback` 処理の詳細は、当該詳細設計で API 契約レベルまで分解される。
* 本書では方式・責務の境界までに留める。

### 8.3 schema.prisma_migration_plan_v1.0 との関係

* 本書で規定した「必要なテーブル」「保持すべきメタ情報」に基づき、詳細設計では Prisma モデルと Migration SQL を定義する。

### 8.4 Login_API_Contracts_v1.0 との関係

* 本書は API の“存在と役割”までを定義し、具体的な入出力 JSON、フィールド型、 nullability などは API 契約書側で扱う。

---

## 第9章 メタ情報および ChangeLog

### 9.1 用語定義

* **MagicLink**：メールによるパスワードレス認証方式。
* **Passkey（WebAuthn）**：公開鍵認証を利用したパスワードレス認証器。
* **Account Binding**：Passkey を既知ユーザに紐付ける工程。
* **Supabase Auth**：MagicLink／Passkey の最終認証管理を行うバックエンド。
* **Corbado**：Passkey 登録／認証のオーケストレーションを提供する外部サービス。
* **short_session**：Corbado が Passkey 操作補助のため一時的に保持する Cookie セッション。

### 9.2 関連文書一覧

* 機能要件定義書 v1.4
* 非機能要件定義書 v1.0
* 技術スタック定義 v4.3
* LoginPage / MagicLinkForm / PasskeyAuthTrigger 詳細設計書
* schema.prisma
* Passkey 認証の仕組みと挙動 v1.0

### 9.3 ChangeLog

* **v1.0（初版）**：MagicLink／Passkey の二方式を統合し、HarmoNet のユーザマスタ運用モデルに基づく唯一成立する Passkey フローを記載。認証方式、エンドポイント方式、セッション、RLS、非機能対応、将来詳細設計との境界を確立。
