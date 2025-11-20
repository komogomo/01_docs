# PasskeyAuthTrigger 詳細設計書 - 第7章：セキュリティ設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH07**
**Version:** 1.2
**Supersedes:** v1.1（旧仕様・MagicLink統合前提）
**Status:** A-01 と完全対称のクライアント側セキュリティ設計

---

## 7.1 目的

本章では、PasskeyAuthTrigger（A-02）がクライアント側で遵守すべき **セキュリティ要件・ブラウザ要件・外部SDK使用条件** を定義する。

MagicLinkForm（A-01）と同粒度で、UI コンポーネントが保持すべき範囲に限定し、
**サーバ側・インフラ側の非機能要件は扱わない**（該当部分は全て上位のセキュリティ設計書へ委譲）。

---

## 7.2 Passkey（WebAuthn）の前提条件

Passkey 認証は **WebAuthn Level 2** の仕様に基づき、ブラウザ・OS のネイティブ機能を利用して行われる。
クライアント側の passkey UI コンポーネントが担う要件は以下の通り。

### 7.2.1 HTTPS 必須

* WebAuthn API（`navigator.credentials.create` / `.get`）は **HTTPS でのみ動作**する。
* localhost は開発用に例外として許可される（Corbado sandbox）。

### 7.2.2 RP ID / Origin 一致

* Corbado Web SDK が内部で WebAuthn を起動する際、
  **`rpId` と `window.location.origin` が完全一致していることが必須条件**。
* 不一致の場合は `error_origin` に分類される（第5章参照）。

### 7.2.3 生体認証／PIN の OS 設定

* OS 側で FaceID／TouchID／PIN が設定されていない場合、OS が自動的に登録画面を要求し、認証は失敗する。
* 本コンポーネントはそれを制御できないため、「エラーの分類と UI 表示」のみを担当する。

---

## 7.3 外部 SDK・API のセキュリティ要件

PasskeyAuthTrigger は **Corbado Web SDK + Supabase Auth** を利用して認証を行う。

### 7.3.1 Corbado Web SDK

* `Corbado.load({ projectId })` に渡す projectId は **公開可能なクライアントID**（Public Key）。
* 認証成功時に返される `id_token` は **ブラウザメモリに保持せず、即 Supabase へ転送し破棄**すること。
* UI コンポーネントから `id_token` を永続化（localStorage/sessionStorage）してはならない。

### 7.3.2 Supabase Auth

* `signInWithIdToken()` は `provider:'corbado'` を指定し、Supabase 内部で署名検証が行われる。
* JWT が発行されるまでの間、UI 側は **例外処理と状態制御のみ**を担当する。

---

## 7.4 クライアント側で禁止される行為

A-02 が担ってはならない事項を明確にしておく。

| 禁止項目                           | 理由                            |
| ------------------------------ | ----------------------------- |
| `id_token` の保存（localStorage 等） | トークン露出リスク（攻撃者がリプレイ可能）         |
| WebAuthn の独自実装                 | OS ネイティブ挙動を壊すため不可             |
| Passkey の可否判定を独自実装             | SDK が提供する `isSupported()` に委譲 |
| Supabase ログイン後の JWT 解析         | A-02 の責務外（A-00 / A-xx が扱う）    |

---

## 7.5 UIコンポーネントとしての最低限の防御策

UI側で扱える範囲のセキュリティ対策を示す。

### 7.5.1 ボタン多重押下防止

* `processing` 状態では `pointer-events-none` とし、多重実行を防止する。

### 7.5.2 エラー文言の安全性

* 第6章の i18nキーを使用し、**内部エラーコード（例：invalid_jwt）などはユーザーに表示しない**。

### 7.5.3 Origin mismatch エラー

* このエラーはセキュリティ警告に直結するため、UI上は控えめな文言で通知し、
  「対応していない端末／ブラウザ」のニュアンスに変換して表示する。

### 7.5.4 認証失敗後の安全な遷移

* `error_*` 状態では UI のみ更新し、画面遷移は一切行わない。
* 再認証は必ず **ユーザーのタップ操作**で開始する。

---

## 7.6 ログ・監査との関係（クライアント側）

* ログ出力は **共通ログユーティリティ** を通して行う。
* 例外発生時、ログには以下のみを含める：

```
level: ERROR
screen: 'LoginPage'
event: auth.login.fail.passkey.*
code: (分類済エラーコード)
```

* 個人情報（メールアドレス等）は PasskeyAuthTrigger が扱わないため、
  マスキング処理も不要。

---

## 7.7 E2E / Storybook 観点でのセキュリティ確認

### 7.7.1 Storybook

* `processing` 状態で busy 属性が正しく付与されていること。
* `error_origin` の文言が OS 依存のエラー詳細にならないこと（一般化されていること）。

### 7.7.2 Playwright（E2E）

* HTTPS 環境でのみ WebAuthn ダイアログが表示されること。
* 成功後の `/mypage` 遷移が Supabase セッション存在時のみ成功すること。

---

## 7.8 本章まとめ

* PasskeyAuthTrigger は A-01 と同じく、**クライアント側だけが担当できる安全措置**に限定して記述する。
* WebAuthn / Corbado / Supabase による認証本体のセキュリティは **SDK側・サーバ側に委譲**する。
* “UIコンポーネントとして破ってはならない制約” を明示することで、Windsurf が安全な実装を行える状態を担保する。

---

## 7.9 ChangeLog

| Version | Summary                                        |
| ------- | ---------------------------------------------- |
| 1.1     | 旧 Phase9 仕様。MagicLink 統合方式。                    |
| **1.2** | **A-01 と対称のクライアントセキュリティ章として全面刷新。旧仕様の責務を完全廃止。** |
