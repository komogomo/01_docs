# MagicLinkForm 詳細設計書 - 第3章：ロジック設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH03**
**Version:** 1.2
**Supersedes:** v1.1
**Updated:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink 専用カードタイル方式 / 技術スタック v4.3 整合版

---

## 第3章 ロジック設計

本章では **MagicLinkForm（A-01）** における **メールログイン処理（MagicLink / OTP 認証）** のロジックを定義する。
現行仕様では MagicLinkForm は **MagicLink のみを扱う**。Passkey 認証処理は A-02 PasskeyAuthTrigger に完全分離されているため、本章には Passkey 処理は一切記載しない。

---

## 3.1 ロジック全体像

MagicLinkForm が行う処理は以下の 4 ステップで構成される：

1. **メール入力値の検証（形式チェック）**
2. **Supabase Auth `signInWithOtp()` の呼び出し**
3. **送信成功時の状態更新・メッセージ表示・ログ出力**
4. **通信 / 認証 / 想定外エラーの分類と状態反映**

MagicLinkForm は LoginPage（A-00）の中で「左側カードタイル」として配置され、押下時にこの MagicLink 処理が実行される。
Passkey については A-02 が独自に `Corbado.passkey.login()` を実行するため、本章は完全に MagicLink 専用である。

---

## 3.2 入力値（メール）の検証

MagicLink 実行前に、メールアドレスの簡易バリデーションを行う。

```ts
const EMAIL_RE = /.+@.+\..+/;
function validateEmail(value: string): boolean {
  return EMAIL_RE.test(value);
}
```

### 検証基準

| 条件         | 動作                                |
| ---------- | --------------------------------- |
| 空文字 / 不正形式 | `error_input` に遷移し、Inline メッセージ表示 |
| 正しい形式      | 送信処理へ進む                           |

検証は **handleSubmit() 実行直前** に行う。
入力変更時には、`error_input` 状態を解除して再入力可能とする。

---

## 3.3 メイン処理ハンドラ（MagicLink 実行）

MagicLink 送信処理を実行するハンドラは以下のとおり。

```ts
const handleSubmit = async () => {
  if (!validateEmail(email)) {
    const e: MagicLinkError = {
      code: 'INVALID_EMAIL',
      message: t('auth.login.error.email_invalid'),
      type: 'error_input',
    };
    setState('error_input');
    setError(e);
    onError?.(e);
    return;
  }

  try {
    setState('sending');
    logInfo('auth.login.start', {
      screen: 'LoginPage',
      method: 'magiclink',
    });

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: false,
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) throw error;

    setState('sent');
    logInfo('auth.login.success.magiclink', {
      screen: 'LoginPage',
    });
    onSent?.();
  } catch (err: any) {
    const mapped = mapError(err, t);
    setState(mapped.type);
    setError(mapped);
    logError(`auth.login.fail.${mapped.type.replace('error_', '')}`, {
      screen: 'LoginPage',
      code: mapped.code,
    });
    onError?.(mapped);
  }
};
```

---

## 3.4 エラーマッピング

MagicLink 実行時に発生する例外を分類し、状態（error_*）へ統一的に反映する。

```ts
function mapError(err: any, t: (key: string) => string): MagicLinkError {
  const msg = String(err?.message || '');

  if (msg.includes('Invalid email')) {
    return {
      code: 'INVALID_EMAIL',
      message: t('auth.login.error.email_invalid'),
      type: 'error_input',
    };
  }

  if (msg.includes('NETWORK') || msg.includes('fetch') || msg.includes('Network')) {
    return {
      code: 'NETWORK_ERROR',
      message: t('auth.login.error.network'),
      type: 'error_network',
    };
  }

  if (err?.code) {
    return {
      code: err.code,
      message: t('auth.login.error.auth'),
      type: 'error_auth',
    };
  }

  return {
    code: 'UNEXPECTED',
    message: t('auth.login.error.unexpected'),
    type: 'error_unexpected',
  };
}
```

### 分類基準

| 種類               | 判定条件                                  |
| ---------------- | ------------------------------------- |
| error_input      | メール形式不正（Supabase側の Invalid email を含む） |
| error_network    | fetch / Network 例外全般                  |
| error_auth       | Supabase `code` を返す認証エラー              |
| error_unexpected | 上記に該当しない例外                            |

---

## 3.5 状態遷移

MagicLinkForm が遷移する状態とトリガーを示す。

| 現在状態    | トリガー   | 遷移先              | 結果        |
| ------- | ------ | ---------------- | --------- |
| idle    | ログイン押下 | sending          | 送信処理開始    |
| sending | 成功     | sent             | メール送信成功   |
| sending | 通信失敗   | error_network    | Bannerエラー |
| sending | 認証エラー  | error_auth       | Bannerエラー |
| sending | 想定外    | error_unexpected | Bannerエラー |
| error_* | 入力変更   | idle             | 再入力へ復帰    |

※ Passkey 関連状態（passkey_auth / success）は本章から削除済み。MagicLinkForm の責務外。

---

## 3.6 ログ出力仕様（MagicLink 用）

MagicLinkForm は共通ログユーティリティを使用し、以下のイベントを出力する。

| タイミング       | イベント                           | レベル   |
| ----------- | ------------------------------ | ----- |
| ログイン開始      | `auth.login.start`             | INFO  |
| MagicLink成功 | `auth.login.success.magiclink` | INFO  |
| 入力不正        | `auth.login.fail.input`        | ERROR |
| 通信エラー       | `auth.login.fail.network`      | ERROR |
| 認証エラー       | `auth.login.fail.auth`         | ERROR |
| 想定外         | `auth.login.fail.unexpected`   | ERROR |

※ Passkey 関連ログ（passkey.*）は本コンポーネントでは扱わず、A-02 側で記録する。

---

## 3.7 補助関数 / 副作用

| 項目              | 内容                                       |
| --------------- | ---------------------------------------- |
| Supabase クライアント | `createClient()` で初期化し再生成はしない            |
| i18n            | `useI18n()` から t(key) を取得、翻訳は即時反映        |
| 副作用の最小化         | handleSubmit は useCallback 化し、依存配列を適切に保つ |

---

**End of Document**
