# MagicLinkForm 詳細設計書 — 第5章：エラー仕様

本章では MagicLinkForm（A-01）の実装方式について記載する。

---

## 5.1 目的

MagicLinkForm 内で発生し得るエラーを分類し、UI 表示方法・ログ出力・i18n キーの対応を定義する。

---

## 5.2 エラー分類

MagicLinkForm は次の 4 種類のエラー状態を扱う。

| 種別                   | 説明      | 表示形式   | 表示位置   |
| -------------------- | ------- | ------ | ------ |
| **error_input**      | メール形式不正 | Inline | 入力欄直下  |
| **error_network**    | 通信エラー   | Banner | フォーム下部 |
| **error_auth**       | 認証エラー   | Banner | フォーム下部 |
| **error_unexpected** | 想定外例外   | Banner | フォーム下部 |

---

## 5.3 i18n キー

各エラーは以下の翻訳キーを用いて表示する。

| 状態               | i18n キー                          |
| ---------------- | -------------------------------- |
| error_input      | `auth.login.error.email_invalid` |
| error_network    | `auth.login.error.network`       |
| error_auth       | `auth.login.error.auth`          |
| error_unexpected | `auth.login.error.unexpected`    |

---

## 5.4 エラー処理フロー

MagicLinkForm はエラー発生時に以下の処理を行う。

### 5.4.1 入力形式エラー

* 送信処理を行わずに終了
* `error_input` を設定し、Inline 表示

### 5.4.2 通信エラー

* `signInWithOtp` 実行中の fetch 例外等
* `error_network` を設定し、Banner 表示

### 5.4.3 認証エラー

* Supabase が error.code を返した場合
* `error_auth` を設定し、Banner 表示

### 5.4.4 想定外エラー

* 上記に該当しない例外
* `error_unexpected` を設定し、Banner 表示

---

## 5.5 UI 表示仕様

### 5.5.1 Inline 表示（error_input）

```tsx
{state === 'error_input' && error && (
  <p className="text-xs text-red-600" role="alert">{error.message}</p>
)}
```

### 5.5.2 Banner 表示（error_network / error_auth / error_unexpected）

```tsx
{['error_network','error_auth','error_unexpected'].includes(state) && error && (
  <p className="text-xs md:text-sm text-red-600" role="alert" aria-live="assertive">{error.message}</p>
)}
```

---

## 5.6 エラーオブジェクト構造

```ts
export interface MagicLinkError {
  code: string;
  message: string;
  type: MagicLinkFormState;
}
```

---

## 5.7 ログ出力

各エラーは共通ログユーティリティへ以下のイベントを出力する。

| 状況     | イベント ID                      |
| ------ | ---------------------------- |
| 入力不正   | `auth.login.fail.input`      |
| 通信エラー  | `auth.login.fail.network`    |
| 認証エラー  | `auth.login.fail.auth`       |
| 想定外エラー | `auth.login.fail.unexpected` |

---

## 5.8 UT 観点

| テストID     | 条件      | 期待結果                       |
| --------- | ------- | -------------------------- |
| UT-ERR-01 | 空入力     | error_input、Inline 表示      |
| UT-ERR-02 | 不正メール形式 | error_input、Inline 表示      |
| UT-ERR-03 | 通信断     | error_network、Banner 表示    |
| UT-ERR-04 | 認証エラー   | error_auth、Banner 表示       |
| UT-ERR-05 | 想定外例外   | error_unexpected、Banner 表示 |
| UT-ERR-06 | 再入力     | idle、エラー非表示                |

---

**End of Document**
