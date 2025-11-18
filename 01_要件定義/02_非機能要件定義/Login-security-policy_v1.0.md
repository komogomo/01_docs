# HarmoNet：Login Security Policy（ログインセキュリティ方針）_v1.0

## 1. 目的

本ドキュメントは、HarmoNet における **ログイン認証のセキュリティ方針（Login Security Policy）** を統一するための非機能仕様である。MagicLink・Passkey の 2 方式が共存する HarmoNet 認証設計に対し、攻撃手法・誤利用・不正アクセス・運用リスクを包括的に管理するための原則と具体方針を定義する。

本ポリシーは、UI/UX、認証フロー、非機能要件、将来的な Supabase Passkey 対応を含む、長期的な認証基盤の安全性を確保する目的で作成する。

---

## 2. 適用範囲

本ポリシーは HarmoNet の **全ログイン手段** に適用される。

* MagicLink（メール送信型ワンタイムリンク）
* Passkey（WebAuthn 生体認証：Corbado 利用）
* 認証後のセッション管理（Supabase Auth）
* 認証画面（A-00 LoginPage）
* 認証コンポーネント（A-01 / A-02）

※ Supabase Edge Functions は HarmoNet 方針として **利用しない**。

---

## 3. セキュリティ設計の基本原則

以下 6 つの原則に基づき設計する。

### ● 3.1 最小権限（Least Privilege）

* 認証直後は最低限の情報のみを扱う
* tenant_id に基づく RLS 分離を厳格適用

### ● 3.2 パスワードレス原則

* HarmoNet はパスワードを一切扱わない
* MagicLink / Passkey の 2 方式のみ許可

### ● 3.3 外部 API 依存の最小化

* Passkey は Corbado を暫定利用
* 将来的に Supabase が Passkey 実装した場合は切替
* 外部サービス停止に備えて MagicLink を常にバックアップ経路として維持

### ● 3.4 OS/デバイス依存の安全性

* Passkey の本人性は OS (FaceID/TouchID/PIN) に委譲
* OSレベルのセキュリティを前提とした安全モデルを採用

### ● 3.5 セッションの安全性

* セッションは Supabase Auth の HTTP Only Cookie を利用
* クライアントで token を直接扱わない

### ● 3.6 UI/UX と安全性の両立

* エラー表示は控えめにしつつ、悪用されにくいメッセージ設計
* 初回登録／ログインの区別が不要なシンプル UX を維持

---

## 4. MagicLink に関するセキュリティ方針

MagicLink（メール認証）は普遍的かつ安全な認証方式として以下を遵守する。

### ● 4.1 OTP リンクの安全性

* リンクは時間制限付き（Supabase 標準）
* Redirect URL は HarmoNet の許可済みドメインのみ

### ● 4.2 メールアドレスの取り扱い

* 入力バリデーションによる形式チェック
* メールアドレスのログ出力は禁止（必要時はマスキング）

### ● 4.3 Replay 対策

* OTP は 1 回のみ有効
* 再利用できない仕組みを Supabase が担保

### ● 4.4 濫用対策

* Supabase Auth が提供するレートリミットを活用
* 過剰な連続要求を UI 側でも制限（ボタン disable）

---

## 5. Passkey（WebAuthn）に関するセキュリティ方針

Passkey は OS/ハードウェア側の User Verification に依存し、MagicLink より強固な本人認証を提供する。

### ● 5.1 初回登録とログインの一体化

* Passkey は登録とログインを同一操作で行う
* 初回も 2 回目以降も同じ UI ボタンでよい

### ● 5.2 Credential の取り扱い

* 秘密鍵はデバイスの Secure Enclave 等に保持され、HarmoNet 側には送信されない
* 公開鍵・credential_id のみがサーバー側に保持される

### ● 5.3 Origin / RP ID の厳格検証

* Corbado が RP として検証を担う
* HarmoNet では RP ID を保持しない構造

### ● 5.4 初回登録時の安全性

* OS レベルの生体認証 / PIN を必須とする（WebAuthn 標準）

### ● 5.5 外部 API リスク管理

* Corbado 依存は暫定的なものとして扱う
* 将来 Supabase が Passkey を実装した際に切替可能な構造に限定

---

## 6. セッション管理

Supabase Auth によるセッション管理を採用する。

### ● 6.1 セッション形式

* HTTP Only Cookie を利用し、クライアント JS からトークンを扱わない

### ● 6.2 セッション保持

* ブラウザ再訪時は Supabase Auth がセッションを復元
* HarmoNet 側で token の再保存などは行わない

### ● 6.3 セッション期限

* Supabase のデフォルト設定に準拠（長期セッションと短期セッションのハイブリッド）

---

## 7. UI に関するセキュリティ方針

### ● 7.1 エラーメッセージの情報露出制限

* 「認証失敗」「デバイス未対応」などの中立的表現
* 「登録されていません」など、悪用されやすい詳細情報は避ける

### ● 7.2 ボタン多重押下の防止

* MagicLink 送信中は `disabled`
* Passkey 認証中は busy 表現

### ● 7.3 Passkey UI 文言

* 初回登録とログインを兼ねる UI として、文言は「Passkey を使う」等に統一

---

## 8. ログ出力ポリシー

ログはすべて **HarmoNet 共通ログユーティリティ** に統一し、以下を徹底する：

### ● 8.1 個人情報の排除

* メールアドレスは必ずマスキング
* credential_id を直接出力しない

### ● 8.2 重要イベントのみログ化

* `auth.login.start`
* `auth.login.success.*`
* `auth.login.fail.*`

### ● 8.3 デバッグログの禁止

* 認証まわりに console.log を残さない

---

## 9. 将来の Supabase Passkey 対応への考慮

Supabase が将来的に WebAuthn をネイティブ実装することを想定し、以下の指針とする：

### ● 9.1 Corbado は暫定採用

* 外部サービス依存は最小限
* Supabase 実装が来た時点で置換

### ● 9.2 UI / ロジックの抽象化

* PasskeyAuthTrigger は認証プロバイダ依存のロジックを局所化
* LoginPage はフロントの統合レイヤとして保持

### ● 9.3 移行コストの最小化

* 認証ロジックは分離（A-01 / A-02）
* 理想的には数行の書き換えで移行可能

---

## 9.1 ログ要件（非機能要件としての明文化）

ログは HarmoNet の認証セキュリティにおける必須非機能要件とし、以下を正式仕様とする。

### ● ログ要件（抽象仕様として定義）

ログは「認証開始・成功・失敗などの重要イベントを記録すること」を要件とする。

※ 要件定義段階では **具体的なイベント名（例：auth.login.success.magiclink などの識別子）は記述しない**。詳細なログキーは詳細設計書で定義する。

### ● 記録すべきフィールド

* timestamp
* user_email（マスキングなし）
* tenant_id
* ip_address
* method（magiclink / passkey）
* error_code（失敗時のみ）

### ● 禁止フィールド

* パスワード（扱わない）
* Passkey 秘密鍵（OS 管理のため取得不能）
* デバッグメッセージ（console.log 等）

### ● 保存および参照

* Supabase Auth ログ（基本保管）
* HarmoNet アプリ内ログは必要最小限とし、外部出力しない

---

## 10. 最終結論

本 Login Security Policy_v1.0 は、HarmoNet における認証（MagicLink／Passkey）の安全性を確保するための**非機能セキュリティ要件**を体系化したものである。

本書で定義した内容は以下を保証する：

* **パスワードレス基盤の安全性**（MagicLink／Passkey 並列運用）
* **外部サービス依存リスクを最小化した構成**（Corbado は暫定利用）
* **将来的な Supabase Passkey 公式対応への容易な移行性**
* **ログ・セッション・UI など横断的なセキュリティ要件の統一化**
* **詳細設計・実装フェーズでの逸脱防止**

本ポリシーは今後の認証方式の拡張（Supabase Passkey 対応時など）においても基盤となるため、変更が必要な場合は必ず TKD による承認のうえで版を更新する。
