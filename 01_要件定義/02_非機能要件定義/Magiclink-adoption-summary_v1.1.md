# HarmoNet：MagicLink 認証仕様

**Document ID:** HARMONET-MAGICLINK-ADOPTION-SUMMARY-V1.1
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-19
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink専用／Passkey完全廃止版

---

# 第1章 目的

MagicLink（メール OTP 認証）は、HarmoNet における ** パスワードレス認証方式** である。
本ドキュメントは MagicLink の採用理由・動作原則・UI/UX・非機能要件について記載する。

---

# 第2章 MagicLink の動作原則

MagicLink は以下の 4 ステップで認証を完了する。

1. ユーザーがメールアドレスを入力
2. Supabase Auth が OTP（MagicLink）を送信
3. ユーザーがメール内の MagicLink をクリック
4. `/auth/callback` でセッションを確立してログイン完了

MagicLink はサインアップ（登録）とログインを区別せず、既存ユーザ・初回ユーザのどちらも同じ操作でログイン可能である。

---

# 第3章 HarmoNet における MagicLink の役割

MagicLink は HarmoNet において次の役割を持つ。

## 3.1 唯一のパスワードレス認証方式

HarmoNet は認証方式を MagicLink のみに一本化し、他方式（Passkey 等）は採用しない。

理由：

* デバイス依存がない（PC / スマホ / 古い端末でも利用可能）
* メールだけで本人確認が完結する
* Supabase Auth が標準サポートしており、追加 SDK や API 管理が不要
* サーバレス構成に完全適合（Next.js + Supabase のみで完結）

## 3.2 初回ログインの本人確認手段

HarmoNet の運用モデルは“ユーザマスタ事前登録制”。
MagicLink は初回ログインにおける唯一の本人確認手段であり、確実な本人性検証を行う。

## 3.3 運用コスト極小の基盤方式

MagicLink は Supabase が認証処理を完全に担うため、以下が不要：

* 独自 API サーバ
* セッション管理コード
* 認証用秘密鍵管理

そのため MVP 〜 本番運用まで安定して利用できる。

---

# 第4章 サーバ構成上の位置づけ

MagicLink は **Supabase Auth のネイティブ機能**として実装され、以下のみで構成される。

* Supabase Auth（MagicLink）
* Next.js フロントエンド（Vercel）

## 4.1 サーバレスで実現できる理由

MagicLink は認証処理のすべてを Supabase が担うため、以下が不要：

* 常時稼働 API
* 認証器管理・署名鍵保護
* WebAuthn の RP ID 設定
* 外部認証サービス

**HarmoNet のサーバレス方針（Next.js + Supabaseのみ）に完全準拠する。**

---

# 第5章 UI / UX 仕様（A-01 MagicLinkForm と整合）

MagicLink はログイン画面において **中央カードタイル UI（A-01）** として提供する。

## 5.1 UI 要素

* メールアイコン
* タイトル（例："メールでログイン"）
* 説明文
* メール入力フィールド
* 「ログイン」ボタン
* メッセージ領域（成功／失敗）

## 5.2 状態遷移（技術スタック v4.4 / 詳細設計と整合）

* `idle`（初期）
* `sending`（MagicLink送信中）
* `sent`（送信完了）
* `error_input`（入力形式エラー）
* `error_network`（通信失敗）
* `error_auth`（認証エラー）
* `error_unexpected`（想定外エラー）

## 5.3 UX ポイント

* 入力欄は `type="email"` のみ
* 送信中はボタン `disabled`
* 送信後、過度な情報を表示しない（UI トーン：やさしい・自然・控えめ）
* A1 基本設計のカードタイル UI と完全整合

---

# 第6章 セキュリティ / 非機能要件（NFR）

MagicLink は HarmoNet のセキュリティ方針（Login Security Policy v1.1）と完全一致する。

## 6.1 セキュリティ

* MagicLink の有効期限は Supabase 標準（短時間）
* セッションは Supabase の HttpOnly/Secure Cookie
* トークン値をクライアントに露出しない
* 認証エンドポイント（redirect URL）は HarmoNet の許可ドメインのみに限定

## 6.2 可用性

* Supabase がサービスレベル維持
* フロントエンドは Vercel 上でサーバレス稼働

## 6.3 運用性

* Supabase Auth のみ利用するため、認証に関する追加運用なし
* メールテンプレートは Supabase 既定を使用（必要に応じて後日カスタム可）

---

# 第7章 他方式との比較（Passkey 廃止済のため簡易版）

MagicLink は HarmoNet における唯一の方式であり、比較対象は存在しない。

ただし「なぜ MagicLink のみで十分か」というメモとして以下を示す：

* すべての環境で確実に利用可能
* ユーザマスタ登録制と相性が良く、初回本人確認が確実
* 運用負荷が最小（外部 RP / WebAuthn 不要）
* サーバレス構成に最適化

（Passkey との比較表は v1.0 から削除済）

---

# 第8章 最終結論

MagicLink は HarmoNet における：

* **唯一の認証方式であり、最も互換性が高い方式**
* **サーバレス構成で安全に運用可能な方式**
* **ユーザマスタ登録制（管理者登録制）と完全整合する本人確認手段**
* **初回ログイン〜継続利用まで一貫して利用できる方式**

として正式採用される。

MagicLink により、HarmoNet は追加 SDK なし・極小運用負荷で、安全かつ確実な認証基盤を維持する。

---

# 第9章 改訂履歴

| Version  | Date       | Summary                                           |
| -------- | ---------- | ------------------------------------------------- |
| **v1.1** | 2025-11-19 | Passkey 全削除、MagicLink 専用に全面再構築。技術スタック v4.4 に完全整合。 |
| v1.0     | 2025-11-17 | 初版（MagicLink/Passkey 並列前提）。                       |

---

**End of Document**
