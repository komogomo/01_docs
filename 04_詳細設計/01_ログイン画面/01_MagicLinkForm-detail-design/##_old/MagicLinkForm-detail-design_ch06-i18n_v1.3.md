# MagicLinkForm 詳細設計書 - 第6章：i18n仕様（v1.3）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH06-I18N
**Version:** 1.3
**Supersedes:** v1.2
**Status:** 正式版（MagicLink 専用フォーム / Passkey 統合廃止版）

---

## 6.1 目的

本章では、MagicLinkForm（A-01）の **i18n（多言語対応）仕様** を定義する。

v1.3 では、以下の変更点を反映した最新仕様とする：

* 技術スタック定義 v4.3 に基づき、**MagicLink と Passkey を独立カードタイルとして扱う正式仕様** に統一。
* MagicLinkForm は **MagicLink 専用フォーム** とし、Passkey 認証に関する UI・メッセージ・状態は一切扱わない。
* ログイン画面基本設計（A1）および MagicLinkForm 詳細設計 v1.3 の状態遷移・メッセージ仕様・ログ出力仕様と **完全整合** する。

本章の目的は、Windsurf が `MagicLinkForm.tsx` / Storybook / Test を実装する際に迷いなく利用できるよう、翻訳キー構成・JSON 構造・状態別 UI と i18n の対応関係・テスト観点を明確化することである。

---

## 6.2 翻訳キー仕様

### 6.2.1 カードタイル本文（`auth.login.magiclink.*`）

MagicLink 専用カードタイルの文言は、`auth.login.magiclink.*` 名前空間に集約する。

| キー                                    | 用途           | 説明                                |
| ------------------------------------- | ------------ | --------------------------------- |
| `auth.login.magiclink.title`          | カードタイトル      | 「メールでログイン」など、MagicLink ログイン方式の名称。 |
| `auth.login.magiclink.description`    | カード説明文       | MagicLink ログイン方式の簡潔な説明文。          |
| `auth.login.magiclink.button_login`   | ログインボタン（通常）  | Idle 状態のボタンラベル。例: 「ログイン」。         |
| `auth.login.magiclink.button_sending` | ログインボタン（送信中） | 送信中状態のボタンラベル。例: 「送信中…」。           |

> 備考: テキスト内容はログイン画面基本設計（A1）の UI トーン（やさしい・自然・控えめ、Apple カタログ風）に合わせて翻訳ファイル側で管理する。

---

### 6.2.2 メール入力フィールド（`auth.login.email.*`）

メール入力フィールドに関するラベルは、`auth.login.email.*` に定義する。

| キー                       | 用途            | 説明                         |
| ------------------------ | ------------- | -------------------------- |
| `auth.login.email.label` | メールアドレス入力欄ラベル | 例: 「メールアドレス」。フォームラベルとして使用。 |

---

### 6.2.3 成功メッセージ（`auth.login.magiclink_sent`）

MagicLink 送信成功時に表示するメッセージは、単一キーで管理する。

| キー                          | 用途        | 説明                          |
| --------------------------- | --------- | --------------------------- |
| `auth.login.magiclink_sent` | 送信成功メッセージ | 「ログイン用リンクを送信しました。」等、送信完了通知。 |

MagicLinkForm の `state = 'sent'` のとき、情報バナーとして表示する。

---

### 6.2.4 エラーメッセージ（`auth.login.error.*`）

MagicLinkForm v1.3 のエラー分類に対応するキーを以下の通り定義する。

| キー                               | 対応する状態             | 用途 / 表示位置                 |
| -------------------------------- | ------------------ | ------------------------- |
| `auth.login.error.email_invalid` | `error_input`      | メール形式不正時のインラインエラー文言。      |
| `auth.login.error.network`       | `error_network`    | ネットワーク障害時のバナーエラー文言。       |
| `auth.login.error.auth`          | `error_auth`       | Supabase 認証エラー時のバナーエラー文言。 |
| `auth.login.error.unexpected`    | `error_unexpected` | 想定外例外時のバナーエラー文言。          |

> 補足:
>
> * `error_input` は **必須入力欠落 / 形式不正** をまとめて `auth.login.error.email_invalid` で扱う。
> * Supabase のエラーコード種別はロジック側で判定し、`error_network` / `error_auth` 等にマッピングする。

---

## 6.3 翻訳 JSON 構造

### 6.3.1 `common.json` の構造（例：`ja`）

StaticI18nProvider (C-03) により、`/public/locales/{locale}/common.json` が読み込まれる。

MagicLinkForm 関連キーは、以下のように `auth.login` 配下に定義する。

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
        "label": "メールアドレス"
      },
      "magiclink_sent": "ログイン用リンクを送信しました。",
      "error": {
        "email_invalid": "メールアドレスの形式が正しくありません。",
        "network": "通信エラーが発生しました。時間をおいて再度お試しください。",
        "auth": "認証に失敗しました。入力内容をご確認のうえ、再度お試しください。",
        "unexpected": "予期しないエラーが発生しました。しばらくしてから再度お試しください。"
      }
    }
  }
}
```

### 6.3.2 呼び出しパターン

MagicLinkForm 内での `t()` 呼び出しは、以下のパターンに統一する。

* タイトル: `t('auth.login.magiclink.title')`
* 説明文: `t('auth.login.magiclink.description')`
* メールラベル: `t('auth.login.email.label')`
* ボタン（通常）: `t('auth.login.magiclink.button_login')`
* ボタン（送信中）: `t('auth.login.magiclink.button_sending')`
* 成功メッセージ: `t('auth.login.magiclink_sent')`
* 入力エラー: `t('auth.login.error.email_invalid')`
* 認証エラー: `t('auth.login.error.auth')`
* ネットワークエラー: `t('auth.login.error.network')`
* 想定外エラー: `t('auth.login.error.unexpected')`

これにより、Windsurf は設計書どおりのキー名で i18n 実装を行える。

---

## 6.4 状態遷移と i18n 文言対応表

MagicLinkForm v1.3 の状態マシンと、各状態で表示する文言は以下の通り。

| 状態                 | 説明               | メイン UI 要素                | 使用する翻訳キー                                                                      |
| ------------------ | ---------------- | ------------------------ | ----------------------------------------------------------------------------- |
| `idle`             | 初期状態。入力待ち。       | 入力欄 + 「ログイン」ボタン（通常ラベル）   | タイトル/説明: `auth.login.magiclink.*`  / ボタン: `auth.login.magiclink.button_login` |
| `sending`          | MagicLink 送信中。   | 入力欄 disabled + ボタン「送信中…」 | ボタン: `auth.login.magiclink.button_sending`                                    |
| `sent`             | 送信成功。            | 情報バナーで送信完了メッセージを表示。      | バナー: `auth.login.magiclink_sent`                                              |
| `error_input`      | 入力バリデーションエラー。    | 入力欄下部にインラインエラー表示。        | インライン: `auth.login.error.email_invalid`                                       |
| `error_network`    | Supabase との通信障害。 | 上部/下部にエラーバナー表示。          | バナー: `auth.login.error.network`                                               |
| `error_auth`       | Supabase 認証エラー。  | 上部/下部にエラーバナー表示。          | バナー: `auth.login.error.auth`                                                  |
| `error_unexpected` | 想定外例外。           | 上部/下部にエラーバナー表示。          | バナー: `auth.login.error.unexpected`                                            |

> 重要:
>
> * Passkey に関連する状態（`passkey_auth` / `success_passkey` / `error_origin` 等）は、本章では一切扱わない。Passkey 用の i18n 仕様は A-02 PasskeyAuthTrigger 詳細設計書側で定義する。

---

## 6.5 Storybook 状態一覧

Storybook では、MagicLinkForm の UI と i18n が正しく連携しているか確認するため、以下の状態を個別ストーリーとして定義する。

### 6.5.1 基本状態ストーリー

| ストーリー名              | 想定状態               | 表示確認ポイント                                           |
| ------------------- | ------------------ | -------------------------------------------------- |
| `IdleJa`            | `idle` (ja)        | タイトル・説明・ボタン「ログイン」が日本語で表示されている。                     |
| `SendingJa`         | `sending`          | ボタンが disabled となり、「送信中…」に変化している。                   |
| `SentJa`            | `sent`             | 情報バナーに `auth.login.magiclink_sent` が表示されている。       |
| `ErrorInputJa`      | `error_input`      | インラインエラーに `auth.login.error.email_invalid` が表示される。 |
| `ErrorNetworkJa`    | `error_network`    | バナーに `auth.login.error.network` が表示される。            |
| `ErrorAuthJa`       | `error_auth`       | バナーに `auth.login.error.auth` が表示される。               |
| `ErrorUnexpectedJa` | `error_unexpected` | バナーに `auth.login.error.unexpected` が表示される。         |

### 6.5.2 多言語ストーリー

| ストーリー名           | ロケール | 確認内容                     |
| ---------------- | ---- | ------------------------ |
| `IdleEn`         | `en` | タイトル・説明・ボタンラベルが英語化されている。 |
| `IdleZh`         | `zh` | 同上（中国語表示）。               |
| `SentEn`         | `en` | 送信完了メッセージが英語で表示される。      |
| `ErrorNetworkEn` | `en` | ネットワークエラー文言が英語で表示される。    |

Storybook デコレータでは、StaticI18nProvider の `currentLocale` に応じて辞書を切り替える。

---

## 6.6 i18n 実装要件

### 6.6.1 Provider / Hook

* すべての翻訳は StaticI18nProvider (C-03) が提供する `useI18n()` Hook を通じて取得する。
* MagicLinkForm 内では以下のように利用する。

```ts
const { t } = useI18n();

const title = t('auth.login.magiclink.title');
```

### 6.6.2 辞書ファイル配置

* 翻訳辞書は **HarmoNet 共通ルール** に従い、以下に配置する：

  * `/public/locales/ja/common.json`
  * `/public/locales/en/common.json`
  * `/public/locales/zh/common.json`
* MagicLinkForm 専用の個別 JSON ファイルは作成せず、**共通 `common.json` の一部として管理する**。

### 6.6.3 プレースホルダー / フォーマット

* StaticI18nProvider v1.0 はプレースホルダー展開（`{name}` など）を未サポートとする。
* MagicLinkForm の文言はすべて単純な文字列とし、パラメータ展開は行わない。

### 6.6.4 ログ出力との関係

* ログ出力（共通ログユーティリティ）は **英数字のイベント名 / コード** を用いるため、i18n 文言とは直接連携しない。
* ユーザーに表示するメッセージは本章の翻訳キーに従い、ログにはキー名ではなくイベント ID・種別のみを記録する。

---

## 6.7 例外時の文言ポリシー

### 6.7.1 翻訳キー不在時

* StaticI18nProvider の仕様に従い、存在しないキーを指定した場合は **キー文字列自体を返却** する。
* MagicLinkForm ではこの挙動をそのまま利用し、例外的な状況として開発時に検知する（本番では発生しない前提）。

### 6.7.2 辞書ロード失敗時

* `common.json` のロードに失敗した場合、StaticI18nProvider は `ja` へのフォールバックを試みる。
* それでも失敗した場合はキー文字列をそのまま表示する。MagicLinkForm 側で追加のエラーメッセージ表示は行わない。

---

## 6.8 UT（テスト観点：i18n）

MagicLinkForm v1.3 のユニットテストでは、i18n 観点を以下のように確認する。

| テストID     | 観点              | 操作 / 条件                  | 期待結果                                               |
| --------- | --------------- | ------------------------ | -------------------------------------------------- |
| UT-A01-01 | 送信成功メッセージ（ja）   | 有効なメールで送信成功。             | `auth.login.magiclink_sent` が情報バナーとして表示される。        |
| UT-A01-02 | 入力形式エラー文言（ja）   | 空文字 / 不正形式メールで送信。        | インラインエラーに `auth.login.error.email_invalid` が表示される。 |
| UT-A01-03 | 認証エラー文言（ja）     | Supabase 認証エラーをモック。      | エラーバナーに `auth.login.error.auth` が表示される。            |
| UT-A01-04 | ネットワークエラー文言（ja） | ネットワークエラーをモック。           | エラーバナーに `auth.login.error.network` が表示される。         |
| UT-A01-05 | 想定外エラー文言（ja）    | 例外 throw をモック。           | エラーバナーに `auth.login.error.unexpected` が表示される。      |
| UT-A01-06 | ロケール切替（en）      | `locale = 'en'` でレンダリング。 | タイトル・説明・ボタン・メッセージが英語に切り替わる。                        |
| UT-A01-07 | ロケール切替（zh）      | `locale = 'zh'` でレンダリング。 | 同上（中国語表示）。                                         |

> 実装上は、テストコード内で StaticI18nProvider / useI18n をモックし、指定ロケール時に期待テキストが描画されることを検証する。

---

## 6.9 改訂履歴

| Version | Date       | Summary                                                                                                         |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------- |
| 1.1     | 2025-11-12 | 初期の i18n 仕様（MagicLink のみ、簡易キー構成）。                                                                               |
| 1.2     | 2025-11-14 | Passkey 統合版として success/error に Passkey 関連キーを追加し、共通状態表・Storybook 状態を拡張（**現行仕様では廃止**）。                            |
| 1.3     | 2025-11-16 | 技術スタック定義 v4.3 / MagicLinkForm v1.3 に合わせ、MagicLink 専用 i18n 仕様として再定義。Passkey 関連キーを完全削除し、状態・Storybook・UT を最新仕様に整合。 |
