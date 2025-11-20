# MagicLinkForm 詳細設計書 — 第3章：ロジック設計

本章では MagicLinkForm（A-01）の実装方式について記載する。

---

## 3.1 処理全体像

MagicLinkForm の処理フローは以下の 4 段階で構成する：

1. 入力メールアドレスの形式チェック
2. MagicLink 送信要求（Supabase `signInWithOtp`）
3. 成功時の状態更新とメッセージ表示
4. エラー分類と表示

本コンポーネントは MagicLink の送信処理のみを担当し、
認証後のセッション確立・認可処理は担当しない。

---

## 3.2 入力値検証

### 3.2.1 バリデーション

```ts
const EMAIL_RE = /.+@.+\..+/;
function validateEmail(value: string): boolean {
  return EMAIL_RE.test(value);
}
```

### 3.2.2 判定ルール

| 条件         | 動作                                     |
| ---------- | -------------------------------------- |
| 空文字または形式不正 | `error_input` へ遷移し、入力欄直下に Inline エラー表示 |
| 正常形式       | 送信処理へ進む                                |

---

## 3.3 MagicLink 送信処理

### 3.3.1 handleSubmit（概要）

```ts
const handleSubmit = async () => {
  if (!validateEmail(email)) {
    setState('error_input');
    setError({
      code: 'INVALID_EMAIL',
      message: t('auth.login.error.email_invalid'),
      type: 'error_input',
    });
    return;
  }

  try {
    setState('sending');
    logInfo('auth.login.start');

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: false,
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) throw error;

    setState('sent');
    logInfo('auth.login.success.magiclink');
  } catch (err: any) {
    const mapped = mapError(err, t);
    setState(mapped.type);
    setError(mapped);
    logError(`auth.login.fail.${mapped.type}`);
  }
};
```

---

## 3.4 エラーマッピング

MagicLink送信中に発生する例外を状態へ統一的に変換する。

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

  if (msg.includes('Network') || msg.includes('fetch')) {
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

### 3.4.1 分類基準

| 種別               | 判定条件                          |
| ---------------- | ----------------------------- |
| error_input      | メール形式不正                       |
| error_network    | 通信エラー（fetch 例外等）              |
| error_auth       | Supabase 認証エラー（error.code あり） |
| error_unexpected | 上記以外の例外                       |

---

## 3.5 状態遷移

| 現在状態    | イベント  | 遷移先              |
| ------- | ----- | ---------------- |
| idle    | 送信要求  | sending          |
| sending | 成功    | sent             |
| sending | 通信断   | error_network    |
| sending | 認証エラー | error_auth       |
| sending | 例外    | error_unexpected |
| error_* | 入力変更  | idle             |

---

## 3.6 ログ出力

MagicLink送信処理の主要イベントを共通ログユーティリティへ記録する。

| タイミング   | イベント ID                            |
| ------- | ---------------------------------- |
| 送信開始    | `auth.login.start`                 |
| 送信成功    | `auth.login.success.magiclink`     |
| 入力形式エラー | `auth.login.fail.error_input`      |
| 通信エラー   | `auth.login.fail.error_network`    |
| 認証エラー   | `auth.login.fail.error_auth`       |
| 想定外エラー  | `auth.login.fail.error_unexpected` |

---

## 3.7 補助処理

| 項目              | 内容                                  |
| --------------- | ----------------------------------- |
| Supabase クライアント | 事前初期化済みのインスタンスを使用する                 |
| i18n            | StaticI18nProvider の t() を使用        |
| 副作用             | handleSubmit は useCallback 等で安定化させる |

---

**End of Document**
