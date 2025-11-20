# HarmoNet Login Security Policy

**Document ID:** HARMONET-LOGIN-SECURITY-POLICY-V1.1
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-19
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink専用／技術スタックv4.4準拠版

---

# 第1章 目的

本ドキュメントは、HarmoNet のログイン認証に関する **非機能セキュリティ方針** を定義する。
MagicLink 認証方式のみを公式方式とし、画面構造・認証フロー・ログ・セッション管理・UI セキュリティに関する横断的な安全基準を示す。

本書は **技術スタック定義書 v*.*.md **（MagicLink専用／Google Cloud TTS 採用）に完全準拠する。

---

# 第2章 適用範囲

本ポリシーは次の領域に適用する：

* MagicLink 認証（Supabase Auth）
* 認証画面（A-00 LoginPage）
* 認証コンポーネント（A-01 MagicLinkForm）
* 認証後セッション管理
* UI 表示に関するセキュリティ

---

# 第3章 セキュリティ設計の基本原則

## 3.1 最小権限（Least Privilege）

* 認証後のユーザー情報は必要最小限のみ取得する。
* Supabase RLS による `tenant_id` 分離を完全適用する。

## 3.2 パスワードレス原則（MagicLinkのみ）

* HarmoNet は **パスワード無しログイン**を唯一方式とする。
* MagicLink（OTP メール）のみを公式認証方式とする。

## 3.3 外部API依存の最小化

* 認証処理は Supabase Auth のみ利用する。
* 外部認証 SDK（Corbado/WebAuthn等）は利用しない。

## 3.4 セッションの安全性

* セッションは Supabase Auth が発行する **HttpOnly/Secure Cookie** を使用する。
* ブラウザ JS は Cookie を直接参照しない。

## 3.5 UI/UX と安全性の両立

* エラーメッセージは必要最低限の情報のみ表示し、内部情報を露出しない。
* MagicLink の送信成功／失敗メッセージは控えめに表示する。

---

# 第4章 MagicLink に関するセキュリティ方針

MagicLink は HarmoNet の認証方式とし以下の仕様とする

## 4.1 OTP リンクの安全性

* OTP リンクは Supabase 標準の **短時間有効**（期限付き）。
* Redirect URL は HarmoNet の許可ドメインのみ。
* OTP は **1 回のみ有効**で再利用不可。

## 4.2 メールアドレスの取り扱い

* 入力時に形式チェックを行う。
* メールアドレスそのものをログに残さない（必要時はマスキング）。

## 4.3 Replay（再利用）対策

* Supabase の OTP 設計により自動的に再利用不可。

## 4.4 過剰送信の抑制

* ログインボタンは送信中 `disabled` とする。
* 短時間での連続送信は UI 側で抑制する。

---

# 第5章 Passkey に関する方針（本バージョンでは非採用）

supabaeが正式公開した際に検討を行う。

---

# 第6章 セッション管理（Supabase Auth 準拠）

## 6.1 セッション形式

* Supabase Auth のセッション Cookie（HttpOnly + Secure）を採用。
* クライアントでは token を保持しない（ブラウザに保持させない）。

## 6.2 セッション保持

* Supabase Auth が再訪時にセッションを自動復元する。
* HarmoNet 側でトークンを保存・管理する処理は持たない。

## 6.3 セッション期限

* セッションの期限・延長は Supabase 標準設計に従う。

---

# 第7章 UI に関するセキュリティ方針

## 7.1 エラーメッセージの情報露出制限

* 「認証に失敗しました」「メールを確認してください」など、抽象化されたメッセージとする。
* 「このメールアドレスは登録されていません」など、悪用可能な詳細文言は出さない。

## 7.2 操作制御

* MagicLink 送信中は UI を `disabled` にし、多重送信を防止。
* `/login` 画面では MagicLink を表示する。

---

# 第8章 ログ出力ポリシー

ログはすべて「HarmoNet 共通ログユーティリティ」を通じて記録する。

## 8.1 個人情報の排除

* メールアドレスはマスキングして記録する。
* トークン値は絶対にログ出力しない。

## 8.2 重要イベントのみログ化

以下のイベントのみ記録する：

* `auth.login.start`
* `auth.login.success.magiclink`
* `auth.login.fail.input`
* `auth.login.fail.supabase.network`
* `auth.login.fail.supabase.auth`
* `auth.login.fail.unexpected`

## 8.3 デバッグログの禁止

* 認証処理内での `console.log` は禁止。
* 例外は共通ログユーティリティ経由で記録する。

---

# 第9章 ログ要件（非機能要件としての明文化）

MagicLink 認証に求められるログ要件を抽象的に定義する。

## 9.1 記録するフィールド（抽象仕様）

* timestamp
* tenant_id
* ip_address
* method = `magiclink`
* error_code（失敗時）

## 9.2 禁止フィールド

* パスワード
* トークン値
* 個人情報（メールアドレスなど生値）

## 9.3 保存先

* Vercel ログ、および Supabase Auth ログを活用する。

---

# 第10章 セキュリティ上の UI ガイドライン

* 不必要なナビゲーション要素をログイン画面に置かない。
* メールアドレス入力欄は HTML5 `type="email"` を使用。
* 画面遷移は `/auth/callback` を介して安全に行う。
* ダークパターン（誤クリック誘導）は作らない。

---

# 第11章 改訂履歴

| Version  | Date       | Summary                                          |
| -------- | ---------- | ------------------------------------------------ |
| **v1.1** | 2025-11-19 | Passkey 全削除。MagicLink専用に全面再構築。技術スタック v4.4 へ完全整合。 |
| v1.0     | 2025-11-17 | 初版。MagicLink + Passkey 併用モデルとして作成。               |

---

**End of Document**
