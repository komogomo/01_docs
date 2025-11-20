# PasskeyAuthTrigger 詳細設計書 - 第6章：i18n仕様（v1.3）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH06**
**Version:** 1.3
**Supersedes:** v1.2（旧“結合・運用”章の完全廃止）
**Status:** MagicLinkForm（A-01）と完全対称の i18n 章

---

# 6.1 目的

PasskeyAuthTrigger（A-02）における **UI メッセージの多言語化仕様** を定義する。
本章は A-01 MagicLinkForm の第6章（i18n）と **構成・密度・翻訳キー体系を完全一致**させることを目的とする。

Passkey 認証は OS ネイティブの UI（FaceID／指紋認証など）を利用するため、
認証処理本体の翻訳は不要だが、**カードタイル UI とエラーメッセージ**はアプリ側で翻訳が必要となる。

---

# 6.2 翻訳キー体系（MagicLink と左右対称）

PasskeyAuthTrigger のすべての UI 文言は以下の名前空間に統一する：

```
auth.login.passkey.*
```

## 6.2.1 カードタイル本文

| キー                               | 用途                      | 説明                  |
| -------------------------------- | ----------------------- | ------------------- |
| `auth.login.passkey.title`       | カードタイトル                 | 「Passkeyでログイン」等の方式名 |
| `auth.login.passkey.description` | 方式説明文                   | デバイスの生体認証を用いる説明     |
| `auth.login.passkey.button`      | ボタンラベル（未使用：タイル押下全体がボタン） | 「ログイン」等（必要な場合）      |

## 6.2.2 エラーメッセージ

Passkey の UI エラーは A-01 と同様、バナー形式で表示する。

| キー                                    | 用途              | 説明                      |
| ------------------------------------- | --------------- | ----------------------- |
| `auth.login.passkey.error_denied`     | キャンセル           | NotAllowedError（ユーザー取消） |
| `auth.login.passkey.error_origin`     | Origin mismatch | RP ID / Origin 不一致      |
| `auth.login.passkey.error_network`    | 通信障害            | fetch / SDK error       |
| `auth.login.passkey.error_auth`       | 認証失敗            | Supabase 認証エラー          |
| `auth.login.passkey.error_unexpected` | 想定外             | 予期しない例外                 |

## 6.2.3 状態別使用メッセージ対応表

| Passkey 状態         | 使用メッセージ                               |
| ------------------ | ------------------------------------- |
| `idle`             | なし（静的UIのみ）                            |
| `processing`       | なし（OS側UI任せ）                           |
| `success`          | なし（即遷移）                               |
| `error_denied`     | `auth.login.passkey.error_denied`     |
| `error_origin`     | `auth.login.passkey.error_origin`     |
| `error_network`    | `auth.login.passkey.error_network`    |
| `error_auth`       | `auth.login.passkey.error_auth`       |
| `error_unexpected` | `auth.login.passkey.error_unexpected` |

---

# 6.3 翻訳 JSON 構造（common.json）

PasskeyAuthTrigger のキーは MagicLinkForm と同じく、
**`public/locales/{locale}/common.json`** に配置する。

### 6.3.1 日本語（ja）例

```json
{
  "auth": {
    "login": {
      "passkey": {
        "title": "Passkeyでログイン",
        "description": "デバイスの生体認証を使用してログインします。",
        "error_denied": "認証がキャンセルされました。",
        "error_origin": "デバイスまたはブラウザが対応していません。",
        "error_network": "通信エラーが発生しました。",
        "error_auth": "認証に失敗しました。",
        "error_unexpected": "予期しないエラーが発生しました。"
      }
    }
  }
}
```

### 6.3.2 英語（en）例

```json
{
  "auth": {
    "login": {
      "passkey": {
        "title": "Sign in with Passkey",
        "description": "Use your device's biometric authentication to continue.",
        "error_denied": "Authentication was canceled.",
        "error_origin": "This device or browser is not supported.",
        "error_network": "A network error occurred.",
        "error_auth": "Authentication failed.",
        "error_unexpected": "An unexpected error occurred."
      }
    }
  }
}
```

### 6.3.3 中国語（zh）例

```json
{
  "auth": {
    "login": {
      "passkey": {
        "title": "使用通行密钥登录",
        "description": "使用设备的生物识别认证进行登录。",
        "error_denied": "操作已取消。",
        "error_origin": "此设备或浏览器不受支持。",
        "error_network": "发生网络错误。",
        "error_auth": "认证失败。",
        "error_unexpected": "发生未知错误。"
      }
    }
  }
}
```

---

# 6.4 呼び出し例（コンポーネント側）

PasskeyAuthTrigger 内では、StaticI18nProvider（C-03）から t() を取得し、以下のように使用する。

```ts
const { t } = useI18n();

<h2>{t('auth.login.passkey.title')}</h2>
<p>{t('auth.login.passkey.description')}</p>

<AuthErrorBanner
  kind={banner.kind}
  message={t(`auth.login.passkey.${banner.key}`)}
/>
```

MagicLinkForm と同じ構造となるため、Windsurf が両方式を対称的に実装できる。

---

# 6.5 Storybook 状態一覧

| ストーリー名           | 状態               | 説明              |
| ---------------- | ---------------- | --------------- |
| `IdleJa`         | idle             | 日本語、通常状態        |
| `ProcessingJa`   | processing       | busy 表示のみ       |
| `DeniedJa`       | error_denied     | キャンセルバナー        |
| `OriginErrorJa`  | error_origin     | origin mismatch |
| `NetworkErrorJa` | error_network    | 通信断             |
| `AuthErrorJa`    | error_auth       | authエラー         |
| `UnexpectedJa`   | error_unexpected | 想定外エラー          |
| `IdleEn`         | idle             | 英語              |
| `IdleZh`         | idle             | 中国語             |

Storybook の Decorator には StaticI18nProvider（C-03）を必ず適用する。

---

# 6.6 UT 観点（i18n）

A-01 と対称のテスト観点とする。

| UT ID          | 観点        | 条件           | 期待結果                                       |
| -------------- | --------- | ------------ | ------------------------------------------ |
| UT-A02-I18N-01 | 通常文言      | locale=ja    | タイトル・説明が日本語                                |
| UT-A02-I18N-02 | エラーバナー    | error_denied | キー `auth.login.passkey.error_denied` の文言表示 |
| UT-A02-I18N-03 | 切替（en）    | locale=en    | 文言が英語に切替                                   |
| UT-A02-I18N-04 | 切替（zh）    | locale=zh    | 中国語に切替                                     |
| UT-A02-I18N-05 | Missingキー | 存在しないキー      | キー名をそのまま返す（StaticI18nProvider仕様）           |

---

# 6.7 本章まとめ

* 旧 ch06（結合・運用）は **完全に不要**なため廃止。
* PasskeyAuthTrigger の ch06 は、A-01 と同じく **i18n専用章** として再構築。
* 翻訳キー体系／JSON構造／UIメッセージ／UT観点を MagicLink と **完全左右対称**に統一。
* Windsurf が誤解なく実装できる密度に整理済み。

---

# 6.8 ChangeLog

| Version | Summary                                  |
| ------- | ---------------------------------------- |
| 1.2     | 旧「結合・運用」章。i18nキーの最小反映のみ。                 |
| **1.3** | **A-01 と対称構造の i18n 章として全面再構築。旧仕様を完全廃止。** |
