# MagicLinkForm 詳細設計書 - 第6章：i18n仕様（v1.2）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH06-I18N
**Version:** 1.2
**Supersedes:** v1.1
**Status:** 正式版（MagicLink + Passkey 統合対応）

---

## 6.1 目的

MagicLinkForm（A-01）における **i18n（多言語対応）仕様** を定義する。本章では、MagicLink・Passkey の統合後の状態遷移に基づき、文言キー構成、翻訳JSON構造、Storybook状態、UT観点を最新化する。

---

## 6.2 翻訳キー仕様（最新版）

MagicLinkForm v1.2 では **成功系・失敗系・フォーム系** を以下の名前空間へ統合する。

### 6.2.1 success.*

| キー                        | 用途            | 説明                |
| ------------------------- | ------------- | ----------------- |
| `success.magiclink_sent`  | MagicLink送信成功 | 「ログイン用リンクを送信しました」 |
| `success.passkey_success` | Passkey認証成功   | 「パスキー認証が完了しました」   |

---

### 6.2.2 error.*

| キー                      | 用途                | 説明                     |
| ----------------------- | ----------------- | ---------------------- |
| `error.invalid_email`   | 入力不正              | メールアドレス形式不正            |
| `error.network`         | 共通エラー             | ネットワーク・API エラー         |
| `error.auth`            | Passkey認証失敗       | Corbado認証・Supabase連携失敗 |
| `error.origin_mismatch` | WebAuthn Origin異常 | セキュリティ制約違反             |

---

### 6.2.3 form.*

| キー           | 用途            |
| ------------ | ------------- |
| `form.email` | メールアドレス入力欄ラベル |
| `form.login` | 「ログイン」ボタン     |

---

## 6.3 翻訳JSON構造（最新構成）

HarmoNet 全体のルールに従い、階層は以下の通り統一する。

```json
{
  "form": {
    "email": "メールアドレス",
    "login": "ログイン"
  },
  "success": {
    "magiclink_sent": "ログイン用リンクを送信しました。",
    "passkey_success": "パスキー認証が完了しました。"
  },
  "error": {
    "invalid_email": "メールアドレスの形式が正しくありません。",
    "network": "通信エラーが発生しました。時間をおいて再度お試しください。",
    "auth": "認証に失敗しました。",
    "origin_mismatch": "認証元が正しくありません (Origin mismatch)。"
  }
}
```

---

## 6.4 状態遷移と i18n 文言対応表

MagicLinkForm v1.2 の状態と文言対応は以下の通り。

| 状態              | 説明                | 使用する翻訳キー                                               |
| --------------- | ----------------- | ------------------------------------------------------ |
| `idle`          | 初期                | なし                                                     |
| `sending`       | MagicLink送信中      | なし（UIはローディング表示のみ）                                      |
| `sent`          | MagicLink送信成功     | `success.magiclink_sent`                               |
| `passkey_auth`  | Passkey認証中        | なし（ローディング）                                             |
| `success`       | 認証成功              | `success.passkey_success` または `success.magiclink_sent` |
| `error_invalid` | 入力不正              | `error.invalid_email`                                  |
| `error_network` | API/通信失敗          | `error.network`                                        |
| `error_auth`    | Passkey認証失敗       | `error.auth`                                           |
| `error_origin`  | WebAuthn Origin異常 | `error.origin_mismatch`                                |

---

## 6.5 Storybook 状態一覧（最新版）

Storybook は以下の状態をすべて個別ストーリーとして定義する。

### 6.5.1 MagicLink 系

* `Idle`
* `Sending`
* `Sent`
* `ErrorInvalid`
* `ErrorNetwork`

### 6.5.2 Passkey 系（v1.2 で追加）

* `PasskeyAuth`
* `SuccessPasskey`
* `ErrorAuth`
* `ErrorOrigin`

---

## 6.6 i18n 実装要件

### 6.6.1 t(key) の取得元

* StaticI18nProvider (C-03)
* 翻訳辞書は `/public/locales/{locale}/common.json`

### 6.6.2 翻訳キーの追加禁止

MagicLinkForm は **common.json のみから取得** し、
機能固有の辞書ファイルは作成しない。

---

## 6.7 例外時の文言ポリシー

* 翻訳キー不在時：キー文字列そのまま返却（C-03 仕様）
* JSON読み込み失敗時：日本語(`ja`)へフォールバック（C-03 仕様）

---

## 6.8 UT（テスト観点）

最新版 MagicLinkForm v1.2 に合わせ、テスト観点も更新する。

| テストID     | 観点              | 期待結果                             |
| --------- | --------------- | -------------------------------- |
| UT-A01-01 | MagicLink送信成功   | `success.magiclink_sent` が表示される  |
| UT-A01-02 | Passkey認証成功     | `success.passkey_success` が表示される |
| UT-A01-03 | メール形式不正         | `error.invalid_email` が表示される     |
| UT-A01-04 | Passkey認証失敗     | `error.auth` が表示される              |
| UT-A01-05 | Origin mismatch | `error.origin_mismatch` が表示される   |
| UT-A01-06 | ネットワーク失敗        | `error.network` が表示される           |
| UT-A01-07 | i18n切替          | 文言の即時反映                          |

---

## 6.9 改訂履歴

| Version | Date       | Summary                                        |
| ------- | ---------- | ---------------------------------------------- |
| 1.1     | 2025-11-12 | 初期のi18n仕様（MagicLinkのみ）                         |
| 1.2     | 2025-11-14 | Passkey対応のi18n最新化、成功/失敗キー統合、UT修正、Storybook状態追加 |