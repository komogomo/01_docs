# PasskeyAuthTrigger 詳細設計書 - 第5章：エラー仕様（v1.3）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH05**
**Version:** 1.3
**Supersedes:** v1.2（非UIロジック前提 / MagicLink統合残存）
**Status:** A-01（MagicLinkForm）と完全対称のエラー仕様

---

# 5.1 目的

本章は、PasskeyAuthTrigger（A-02）における **エラーの種類・発生条件・UI表示・ログ出力・再試行挙動** を定義する。

A-01 MagicLinkForm の第5章（error）と **同じ構造・粒度で完全左右対称**となるよう再構築する。

---

# 5.2 エラー種別（A-01 と対称構造）

Passkey 認証のエラーは、WebAuthn / Corbado / Supabase が返す例外を分類し、
**UIでのメッセージ表示に用いる5分類**へ正規化する。

```ts
enum PasskeyAuthErrorType {
  error_denied = 'error_denied',        // キャンセル
  error_origin = 'error_origin',        // Origin mismatch
  error_network = 'error_network',      // ネットワーク障害
  error_auth = 'error_auth',            // 認証エラー
  error_unexpected = 'error_unexpected' // 想定外
}
```

A-01 の `error_input` のような **入力エラーは存在しない**（Passkey は入力UIを持たないため）。

---

# 5.3 エラー → UI 表示仕様

A-02 の UI はカードタイル上に表示される **AuthErrorBanner** を使用する。

| エラー種別            | 表示種別         | 表示内容（i18n）                            | 表示位置   |
| ---------------- | ------------ | ------------------------------------- | ------ |
| error_denied     | Error Banner | `auth.login.passkey.error_denied`     | カード内下部 |
| error_origin     | Error Banner | `auth.login.passkey.error_origin`     | 同上     |
| error_network    | Error Banner | `auth.login.passkey.error_network`    | 同上     |
| error_auth       | Error Banner | `auth.login.passkey.error_auth`       | 同上     |
| error_unexpected | Error Banner | `auth.login.passkey.error_unexpected` | 同上     |

成功時（success）は A-01 と同様 **バナーを表示しない**。即座に遷移（/mypage）する。

---

# 5.4 エラー分類ロジック（classifyError）

A-01 の error mapping と対称構造で定義する。

```ts
function classifyError(err: any, t: (key: string) => string): PasskeyAuthError {
  if (err?.name === 'NotAllowedError') {
    return {
      code: 'NOT_ALLOWED',
      type: 'error_denied',
      message: t('auth.login.passkey.error_denied')
    };
  }

  if (String(err?.message ?? '').includes('ORIGIN')) {
    return {
      code: 'ORIGIN_MISMATCH',
      type: 'error_origin',
      message: t('auth.login.passkey.error_origin')
    };
  }

  if (String(err?.message ?? '').includes('NETWORK')) {
    return {
      code: 'NETWORK',
      type: 'error_network',
      message: t('auth.login.passkey.error_network')
    };
  }

  if (err?.code) {
    return {
      code: err.code,
      type: 'error_auth',
      message: t('auth.login.passkey.error_auth')
    };
  }

  return {
    code: 'UNEXPECTED',
    type: 'error_unexpected',
    message: t('auth.login.passkey.error_unexpected')
  };
}
```

分類基準は A-01 の `isSupabaseAuthError` / `isNetworkError` などと同様の思想で統一。

---

# 5.5 ログ出力仕様

エラー発生時は、A-01 と完全に同じ命名規約で **共通ログユーティリティ** を使用する。

| エラー種別            | 出力イベント                               | レベル   |
| ---------------- | ------------------------------------ | ----- |
| error_denied     | `auth.login.fail.passkey.denied`     | ERROR |
| error_origin     | `auth.login.fail.passkey.origin`     | ERROR |
| error_network    | `auth.login.fail.passkey.network`    | ERROR |
| error_auth       | `auth.login.fail.passkey.auth`       | ERROR |
| error_unexpected | `auth.login.fail.passkey.unexpected` | ERROR |

ログ構造は A-01 と同一：

```ts
logError('auth.login.fail.passkey.network', {
  screen: 'LoginPage',
  code: error.code,
});
```

---

# 5.6 状態遷移（A-01 エラー遷移と対称）

| 現状態        | 入力              | 次状態              |
| ---------- | --------------- | ---------------- |
| processing | キャンセル           | error_denied     |
| processing | Origin mismatch | error_origin     |
| processing | 通信断             | error_network    |
| processing | 認証エラー           | error_auth       |
| processing | 想定外例外           | error_unexpected |
| error_*    | 再試行操作           | processing       |

再試行設計は A-01 と揃えており、
ユーザー操作（カード再押下）で Idle → processing に戻る。

---

# 5.7 UT 観点（A-01 と同じ構造）

| UT ID         | シナリオ            | 期待状態             | チェック内容         |
| ------------- | --------------- | ---------------- | -------------- |
| UT-A02-ERR-01 | キャンセル           | error_denied     | バナー表示 / ログ一致   |
| UT-A02-ERR-02 | Origin mismatch | error_origin     | メッセージキー一致      |
| UT-A02-ERR-03 | 通信エラー           | error_network    | ログ：network     |
| UT-A02-ERR-04 | 認証失敗            | error_auth       | Supabase系エラー分類 |
| UT-A02-ERR-05 | 想定外             | error_unexpected | fallback分類     |
| UT-A02-ERR-06 | i18n切替          | —                | 文言切替正常         |
| UT-A02-ERR-07 | 再試行             | processing       | 状態リセット         |

---

# 5.8 本章まとめ

* 旧仕様の “MagicLink 内部の非UI Trigger” という構造は **完全に廃止**。
* A-02 PasskeyAuthTrigger は **独立カードタイル**であり、
  A-01 MagicLinkForm と **完全対称の error 設計**を持つ。
* i18n / ログ / 状態遷移 / UT観点まで **一貫した構造へ刷新**。

---

# 5.9 ChangeLog

| Version | Summary                                          |
| ------- | ------------------------------------------------ |
| 1.2     | 非UIロジック方式（旧仕様）。i18nキー最小反映のみ。                     |
| **1.3** | **UIコンポーネント版として全面刷新。A-01 と完全対称の error 章として再設計。** |
