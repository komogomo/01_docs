# MagicLinkForm 詳細設計書 — 第4章：UI設計

本章では MagicLinkForm（A-01）の実装方式について記載する。

---

## 4.1 コンポーネント構成

MagicLinkForm は LoginPage（A-00）に配置される単一カード UI として構成される。
構成要素は以下の通り：

* タイトル
* 説明文
* メールアドレス入力欄
* 送信ボタン（MagicLink）
* 成功メッセージ
* エラーメッセージ（Inline／バナー）

---

## 4.2 JSX 構造（概要）

```tsx
<section className="rounded-2xl border bg-white shadow-sm p-4 flex flex-col gap-4" data-testid={testId}>
  <header className="flex items-start gap-3">
    <Mail className="w-6 h-6 text-gray-500" aria-hidden="true" />
    <div className="flex-1">
      <h2 className="text-base font-semibold text-gray-900">{t('auth.login.magiclink.title')}</h2>
      <p className="mt-1 text-sm text-gray-600">{t('auth.login.magiclink.description')}</p>
    </div>
  </header>

  <form className="flex flex-col gap-3" onSubmit={handleSubmit} noValidate>
    <label htmlFor="magiclink-email" className="text-sm font-medium text-gray-700">
      {t('auth.login.email.label')}
    </label>
    <input id="magiclink-email" type="email" value={email} onChange={onChangeEmail}
      className="h-11 rounded-2xl border px-3 text-sm text-gray-900 placeholder:text-gray-400
                 focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:border-transparent"
      placeholder={t('auth.login.email.placeholder')} disabled={state==='sending'} />

    {state === 'error_input' && error && (
      <p className="text-xs text-red-600" role="alert">{error.message}</p>
    )}

    <button type="submit" disabled={state==='sending'}
      className={`h-11 rounded-2xl flex items-center justify-center gap-2 text-sm font-semibold shadow-sm
                  ${state === 'sending' ? 'bg-blue-400 text-white cursor-wait' : 'bg-blue-600 text-white hover:bg-blue-500'}`}>
      {state === 'sending' ? <Loader2 className="w-4 h-4 animate-spin" /> : <Mail className="w-4 h-4" />}
      {state === 'sending' ? t('auth.login.magiclink.button_sending') : t('auth.login.magiclink.button_login')}
    </button>

    {state === 'sent' && (
      <p className="text-xs text-gray-600" aria-live="polite">{t('auth.login.magiclink_sent')}</p>
    )}

    {['error_network','error_auth','error_unexpected'].includes(state) && error && (
      <p className="text-xs text-red-600" role="alert" aria-live="assertive">{error.message}</p>
    )}
  </form>
</section>
```

---

## 4.3 レイアウト仕様

| 項目 | 内容                                       |
| -- | ---------------------------------------- |
| 外枠 | `rounded-2xl` + `shadow-sm` + `bg-white` |
| 余白 | `p-4`（モバイル） / `p-6`（タブレット以上）             |
| 幅  | `w-full max-w-md`（LoginPage の中央配置に従う）    |
| 行間 | 要素間 `gap-3`                              |

---

## 4.4 カラースキーム

| 要素    | 状態      | スタイル                                 |
| ----- | ------- | ------------------------------------ |
| カード   | 常時      | `bg-white` / `border-gray-200`       |
| 入力欄   | idle    | `border-gray-300`                    |
| 入力欄   | focus   | `ring-2 ring-blue-500`               |
| ボタン   | idle    | `bg-blue-600 text-white`             |
| ボタン   | hover   | `bg-blue-500`                        |
| ボタン   | sending | `bg-blue-400 text-white cursor-wait` |
| メッセージ | sent    | `text-gray-600`                      |
| メッセージ | error_* | `text-red-600`                       |

---

## 4.5 タイポグラフィ

| 項目    | スタイル                                |
| ----- | ----------------------------------- |
| タイトル  | `text-base font-semibold`           |
| 説明文   | `text-sm text-gray-600`             |
| 入力ラベル | `text-sm font-medium text-gray-700` |
| 入力値   | `text-sm text-gray-900`             |
| ボタン   | `text-sm font-semibold text-white`  |
| メッセージ | `text-xs md:text-sm`                |

---

## 4.6 状態別 UI

| 状態                                            | ボタン表示          | メッセージ        |
| --------------------------------------------- | -------------- | ------------ |
| idle                                          | ログイン           | 表示なし         |
| sending                                       | 送信中（Loader 表示） | 表示なし         |
| sent                                          | ログイン           | 成功メッセージ（バナー） |
| error_input                                   | ログイン           | Inline エラー   |
| error_network / error_auth / error_unexpected | ログイン           | バナーエラー       |

---

## 4.7 i18n キー

* `auth.login.magiclink.title`
* `auth.login.magiclink.description`
* `auth.login.email.label`
* `auth.login.email.placeholder`
* `auth.login.magiclink.button_login`
* `auth.login.magiclink.button_sending`
* `auth.login.magiclink_sent`
* `auth.login.error.email_invalid`
* `auth.login.error.network`
* `auth.login.error.auth`
* `auth.login.error.unexpected`

---

## 4.8 アクセシビリティ

* `label` と `htmlFor` による対応づけ
* エラーは `role="alert"`
* 成功メッセージは `aria-live="polite"`
* フォーカスリング：`focus-visible:ring-2 ring-blue-500`
* 全要素が Tab / Enter により操作可能

---

**End of Document**
