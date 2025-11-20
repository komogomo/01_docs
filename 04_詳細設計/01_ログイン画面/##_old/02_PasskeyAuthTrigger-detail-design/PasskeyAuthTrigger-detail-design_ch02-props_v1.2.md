# PasskeyAuthTrigger 詳細設計書 - 第2章：Props・State・Event 定義（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH02**
**Version:** 1.2
**Supersedes:** v1.1（旧仕様・MagicLink統合前提）
**Status:** A-01 MagicLinkForm v1.3 と完全対称に再構築

---

# 2. Props / State / Event 定義

A-02 PasskeyAuthTrigger は **UI + ロジックを併せ持つ独立カードタイル**であり、旧仕様（非UIロジック / MagicLink 内統合）は完全廃止する。
本章では、A-01 MagicLinkForm と対称の形式で Props / State / Event を定義する。

---

## 2.1 Props 定義

PasskeyAuthTrigger は LoginPage（A-00）内で単一カードとして表示されるため、Props は最小かつ A-01 構造に揃える。

```ts
export interface PasskeyAuthTriggerProps {
  /** レイアウト調整用の追加クラス（任意） */
  className?: string;

  /** 認証成功時の通知コールバック（任意） */
  onSuccess?: () => void;

  /** 重要なエラー発生時の通知コールバック（任意） */
  onError?: (error: PasskeyAuthError) => void;

  /** テストID（任意） */
  testId?: string;
}
```

### ✔ Props の特徴

* MagicLinkForm と同様、**UI レイヤの補助的な Props のみ**を保持する。
* ログイン処理・状態遷移は内部で完結する。
* `passkeyEnabled`（旧仕様）は削除。

---

## 2.2 State 定義

PasskeyAuthTrigger の内部状態（A-01 の Idle / Sending / Sent / Error_* と対称構造）。

```ts
export type PasskeyAuthState =
  | 'idle'            // 初期状態
  | 'processing'      // WebAuthn / Corbado認証中
  | 'success'         // 認証成功
  | 'error_denied'    // NotAllowed（キャンセル）
  | 'error_origin'    // Origin mismatch
  | 'error_network'   // 通信障害
  | 'error_auth'      // Supabase 認証エラー
  | 'error_unexpected'; // 想定外エラー
```

### ✔ A-01 と揃えるポイント

* A-01 が `error_input` を持つのはメール入力があるため。
  → A-02 は入力 UI がないので **error_input は持たない**。
* それ以外の異常系はすべて **error_* 系**で統一。

---

## 2.3 Passkey 認証エラー型

MagicLinkForm の `MagicLinkError` と対称の構造で Passkey 用エラーを定義。

```ts
export type PasskeyAuthErrorType =
  | 'error_network'
  | 'error_denied'
  | 'error_origin'
  | 'error_auth'
  | 'error_unexpected';

export interface PasskeyAuthError {
  code: string;
  message: string; // UI表示用（i18n済文言）
  type: PasskeyAuthErrorType;
}
```

### ✔ 表示メッセージは i18n キーで決定

例：

```
auth.login.passkey.error_denied
auth.login.passkey.error_network
auth.login.passkey.error_origin
```

これらは ch06-i18n にて定義される。

---

## 2.4 Event（状態遷移トリガ）

PasskeyAuthTrigger の主なトリガとイベントは以下。

| Event名             | 発火条件            | 説明                           |
| ------------------ | --------------- | ---------------------------- |
| `start`            | カードタイル押下        | WebAuthn 認証開始（processingへ遷移） |
| `success`          | 認証成功            | Supabase セッション確立 → `/mypage` |
| `error_denied`     | NotAllowedError | OS側キャンセル                     |
| `error_origin`     | Origin mismatch | セキュリティチェック失敗                 |
| `error_network`    | 通信失敗            | fetch / SDK 通信失敗             |
| `error_auth`       | Supabase 認証失敗   | id_token 検証不可                |
| `error_unexpected` | 想定外             | その他例外                        |

ログ出力は共通ログユーティリティを使用し、event 名は A-01 と統一する。

---

## 2.5 Event → State 対応表

| Event              | 次状態              | 使用メッセージ                               | ログ出力                                 |
| ------------------ | ---------------- | ------------------------------------- | ------------------------------------ |
| `start`            | processing       | なし                                    | `auth.login.start`                   |
| `success`          | success          | なし（即リダイレクト）                           | `auth.login.success.passkey`         |
| `error_denied`     | error_denied     | `auth.login.passkey.error_denied`     | `auth.login.fail.passkey.denied`     |
| `error_origin`     | error_origin     | `auth.login.passkey.error_origin`     | `auth.login.fail.passkey.origin`     |
| `error_network`    | error_network    | `auth.login.passkey.error_network`    | `auth.login.fail.passkey.network`    |
| `error_auth`       | error_auth       | `auth.login.passkey.error_auth`       | `auth.login.fail.passkey.auth`       |
| `error_unexpected` | error_unexpected | `auth.login.passkey.error_unexpected` | `auth.login.fail.passkey.unexpected` |

---

## 2.6 UT 観点（A-01 と対称に設計）

| UT ID         | シナリオ            | 期待結果                                            |
| ------------- | --------------- | ----------------------------------------------- |
| **UT-A02-01** | 正常系：認証成功        | state=`success`、ログ `auth.login.success.passkey` |
| **UT-A02-02** | キャンセル           | state=`error_denied`、バナー表示                      |
| **UT-A02-03** | Origin mismatch | state=`error_origin`                            |
| **UT-A02-04** | 通信障害            | state=`error_network`                           |
| **UT-A02-05** | Supabase 認証エラー  | state=`error_auth`                              |
| **UT-A02-06** | 想定外例外           | state=`error_unexpected`                        |
| **UT-A02-07** | 言語切替（i18n）      | メッセージ文言が言語に応じて切替                                |

---

## 2.7 本章のまとめ

* 旧仕様の「passkeyEnabled」「非UIモジュール」「MagicLink統合」は完全に排除
* PasskeyAuthTrigger は **独立 UI + 認証ロジック** のコンポーネント
* A-01 と対称の Props/State/Event 体系へ統一
* テスト観点も A-01 とミラー構造で揃える

---

## 2.8 ChangeLog

| Version | Date       | Summary                                                             |
| ------- | ---------- | ------------------------------------------------------------------- |
| 1.1     | 2025-11-12 | MagicLink統合方式（旧仕様）                                                  |
| **1.2** | 2025-11-16 | **A-01 と同じ Props/State/Event 体系に完全刷新。旧 passkeyEnabled / 非UI構成を削除。** |
