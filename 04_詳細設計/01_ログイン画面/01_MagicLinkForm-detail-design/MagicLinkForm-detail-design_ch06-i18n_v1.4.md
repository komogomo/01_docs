# MagicLinkForm 詳細設計書 — 第6章：i18n仕様（v1.4）

本章では MagicLinkForm（A-01）が使用する **多言語（i18n）仕様**の実装方式について記載する。

---

## 6.1 目的

MagicLinkForm の UI に必要な翻訳キーを明確化し、
StaticI18nProvider（C-03）にて辞書を読み込むための統一仕様を定義する。

---

## 6.2 翻訳キー体系

MagicLinkForm の文言は `auth.login` 名前空間に統一する。

### 6.2.1 MagicLink 本体

| 用途       | キー                                    |
| -------- | ------------------------------------- |
| タイトル     | `auth.login.magiclink.title`          |
| 説明文      | `auth.login.magiclink.description`    |
| ボタン（通常）  | `auth.login.magiclink.button_login`   |
| ボタン（送信中） | `auth.login.magiclink.button_sending` |

### 6.2.2 入力欄

| 用途         | キー                             |
| ---------- | ------------------------------ |
| メールアドレスラベル | `auth.login.email.label`       |
| プレースホルダ    | `auth.login.email.placeholder` |

### 6.2.3 成功メッセージ

| 用途   | キー                          |
| ---- | --------------------------- |
| 送信成功 | `auth.login.magiclink_sent` |

### 6.2.4 エラーメッセージ

| 状態               | キー                               |
| ---------------- | -------------------------------- |
| error_input      | `auth.login.error.email_invalid` |
| error_network    | `auth.login.error.network`       |
| error_auth       | `auth.login.error.auth`          |
| error_unexpected | `auth.login.error.unexpected`    |

---

## 6.3 辞書ファイル構造

StaticI18nProvider は次のファイルを読み込む：

```
/public/locales/ja/common.json
/public/locales/en/common.json
/public/locales/zh/common.json
```

MagicLinkForm 専用ファイルは作成せず、すべて common.json にまとめて保持する。

---

## 6.4 翻訳 JSON（例：ja）

```json
{
  "auth": {
    "login": {
      "magiclink": {
        "title": "メールでログイン",
        "description": "ご登録のメールアドレス宛にログイン用リンクを送信します。",
        "button_login": "ログイン",
        "button_sending": "送信中…"
      },
      "email": {
        "label": "メールアドレス",
        "placeholder": "example@example.com"
      },
      "magiclink_sent": "ログイン用リンクを送信しました。",
      "error": {
        "email_invalid": "メールアドレスの形式が正しくありません。",
        "network": "通信エラーが発生しました。",
        "auth": "認証に失敗しました。",
        "unexpected": "予期しないエラーが発生しました。"
      }
    }
  }
}
```

---

## 6.5 状態別 UI との対応

| 状態               | 表示内容          | 使用キー                                  |
| ---------------- | ------------- | ------------------------------------- |
| idle             | タイトル・説明・通常ボタン | `auth.login.magiclink.*`              |
| sending          | 送信中ボタン表示      | `auth.login.magiclink.button_sending` |
| sent             | 成功メッセージ       | `auth.login.magiclink_sent`           |
| error_input      | Inline エラー    | `auth.login.error.email_invalid`      |
| error_network    | バナーエラー        | `auth.login.error.network`            |
| error_auth       | バナーエラー        | `auth.login.error.auth`               |
| error_unexpected | バナーエラー        | `auth.login.error.unexpected`         |

---

## 6.6 実装要件

### 6.6.1 Hook 使用

MagicLinkForm 内のすべての文言取得は StaticI18nProvider の `useI18n()` を使用する。

```ts
const { t } = useI18n();
```

### 6.6.2 プレースホルダ

本コンポーネントでは `{}` 形式の動的プレースホルダは使用しない。
すべて固定文言として定義する。

### 6.6.3 エラー時の動作

* 存在しないキーを指定した場合はキー名がそのまま表示される（Provider 仕様）。
* MagicLinkForm 側で追加の処理は行わない。

---

## 6.7 UT 観点

| テストID      | 条件      | 期待結果                                    |
| ---------- | ------- | --------------------------------------- |
| UT-i18n-01 | 送信成功    | `auth.login.magiclink_sent` が表示される      |
| UT-i18n-02 | 入力形式エラー | `auth.login.error.email_invalid` が表示される |
| UT-i18n-03 | 認証エラー   | `auth.login.error.auth` が表示される          |
| UT-i18n-04 | 通信エラー   | `auth.login.error.network` が表示される       |
| UT-i18n-05 | 想定外エラー  | `auth.login.error.unexpected` が表示される    |
| UT-i18n-06 | ロケール切替  | 文言が即時切り替わる                              |

---

**End of Document**
