# MagicLinkForm 詳細設計書 - 第5章：エラー仕様（v1.3）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH05**
**Version:** 1.3
**Supersedes:** v1.2
**Updated:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink 専用カードタイル方式 / 技術スタック v4.3 / ログ仕様 v1.1 整合版

---

## 5.1 目的

本章では **MagicLinkForm（A-01）** の **エラーハンドリング仕様** を定義する。
対象は MagicLink 認証（Supabase signInWithOtp）のみとし、**Passkey に関する UI・ロジック・エラー分類は含めない**（A-02 に委譲）。

本章は以下を明確化する：

* 状態別エラー型 (`error_*`) の定義
* エラー発生時の UI 表示位置・形式
* i18n キー体系（`auth.login.error.*`）
* ログ出力仕様（auth.login.fail.*）
* Windsurf が誤解しない粒度での表示条件

---

## 5.2 エラー分類（MagicLink 専用）

MagicLinkForm のエラー分類は、A-00 LoginPage の MSG-03〜MSG-09 とログ仕様 v1.1 に完全準拠し、以下の 4 種類に限定する。

| 種類                   | 説明                 | 表示形式         | UI位置   |
| -------------------- | ------------------ | ------------ | ------ |
| **error_input**      | メール形式不正（空/不正形式）    | Inline Error | 入力欄直下  |
| **error_network**    | ネットワーク断 / fetch 例外 | Banner（赤）    | フォーム下部 |
| **error_auth**       | Supabase 認証エラー     | Banner（赤）    | フォーム下部 |
| **error_unexpected** | 上記分類不能の例外          | Banner（赤）    | フォーム下部 |

※ Passkey 系エラー（denied/origin など）は **A-02** で扱うため、A-01 では一切扱わない。

---

## 5.3 エラーメッセージ（i18n キー仕様）

使用するメッセージは A-00 詳細設計の MSG-〇 と整合。

| 状態               | i18nキー                           | メッセージ例（ja）          | 備考        |
| ---------------- | -------------------------------- | ------------------- | --------- |
| error_input      | `auth.login.error.email_invalid` | メールアドレスの形式が正しくありません | Inline 表示 |
| error_network    | `auth.login.error.network`       | 通信エラーが発生しました        | Banner    |
| error_auth       | `auth.login.error.auth`          | 認証に失敗しました           | Banner    |
| error_unexpected | `auth.login.error.unexpected`    | 予期しないエラーが発生しました     | Banner    |

※ 文言は A-00 と A1 基本設計の方針により一貫した簡潔・中立表現を使用。

---

## 5.4 エラーハンドリング仕様（処理フロー）

MagicLinkForm 内部では以下の順序で例外処理を行う。

### 5.4.1 メール形式エラー（error_input）

* 形式チェックに失敗した時点で送信処理を行わない
* `error_input` 状態へ遷移
* Inline 表示（入力欄直下）
* ログ: `auth.login.fail.input`

### 5.4.2 Supabase 通信エラー（error_network）

* `signInWithOtp()` 実行時の fetch 例外を包含
* 状態: `error_network`
* ログ: `auth.login.fail.supabase.network`

### 5.4.3 認証エラー（error_auth）

* Supabase が認証エラー (`error.code`) を返した場合
* 状態: `error_auth`
* ログ: `auth.login.fail.supabase.auth`

### 5.4.4 想定外エラー（error_unexpected）

* 上記以外の例外（JS例外など）
* 状態: `error_unexpected`
* ログ: `auth.login.fail.unexpected`

---

## 5.5 UI表示仕様

UI 表示は `MagicLinkFormState` に基づく。

### 5.5.1 Inline 表示（error_input）

```tsx
{state === 'error_input' && error && (
  <p className="text-xs text-red-600" role="alert">{error.message}</p>
)}
```

* 入力欄直下に薄い赤文字で表示
* 再入力時に `idle` へ戻る

### 5.5.2 Banner 表示（error_network / error_auth / error_unexpected）

```tsx
{['error_network','error_auth','error_unexpected'].includes(state) && error && (
  <p className="text-xs md:text-sm text-red-600" role="alert" aria-live="assertive">{error.message}</p>
)}
```

* フォーム下部に表示
* `aria-live="assertive"` を付与

---

## 5.6 エラーオブジェクト構造

`ch02` の定義をここでも再掲。

```ts
export interface MagicLinkError {
  code: string;       // Supabase error.code
  message: string;    // i18n 済テキスト
  type: MagicLinkErrorType; // error_input / error_network / error_auth / error_unexpected
}
```

---

## 5.7 ログ出力仕様（ログ詳細設計 v1.1 準拠）

MagicLinkForm から出力するログは以下。

| タイミング | event                              | レベル   |
| ----- | ---------------------------------- | ----- |
| 入力不正  | `auth.login.fail.input`            | ERROR |
| 通信エラー | `auth.login.fail.supabase.network` | ERROR |
| 認証エラー | `auth.login.fail.supabase.auth`    | ERROR |
| 想定外   | `auth.login.fail.unexpected`       | ERROR |

※ Passkey関連ログは A-02 側で定義し、A-01 が出力することはない。

---

## 5.8 UT観点（error 系）

Windsurf が誤解しないよう、最小・明確なテスト観点のみ定義する。

| テストID     | 条件            | 期待状態             | 表示     | ログ                               |
| --------- | ------------- | ---------------- | ------ | -------------------------------- |
| UT-ERR-01 | 空文字入力         | error_input      | Inline | auth.login.fail.input            |
| UT-ERR-02 | 不正形式          | error_input      | Inline | auth.login.fail.input            |
| UT-ERR-03 | Supabase通信断   | error_network    | Banner | auth.login.fail.supabase.network |
| UT-ERR-04 | Supabase認証エラー | error_auth       | Banner | auth.login.fail.supabase.auth    |
| UT-ERR-05 | 予期しない例外       | error_unexpected | Banner | auth.login.fail.unexpected       |
| UT-ERR-06 | 再入力           | idle             | 表示なし   | ログなし                             |

---

## 5.9 ChangeLog

| Version | Date       | Summary                                                                                                                                                                                        |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.3** | 2025-11-16 | A-01 v1.3 に合わせ、MagicLink 専用エラー仕様へ全面更新。Passkey 系エラー・統合認証関連の記述を全削除し、`error_input` / `error_network` / `error_auth` / `error_unexpected` の 4 種に統一。i18n キー・ログ仕様・UI 表示形式を A-00 / ログ詳細設計 v1.1 と完全整合。 |
| 1.2     | 2025-11-14 | ch05 の構造整理・旧テスト章統合。                                                                                                                                                                            |

---

**End of Document**
