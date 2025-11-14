# MagicLinkForm 詳細設計書 - 第4章：UI設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH04**
**Version:** 1.2
**Supersedes:** v1.1
**Status:** 最新 i18n 体系（form.* / success.* / error.*）へ完全整合

---

## 4.1 コンポーネント構成概要

MagicLinkForm は **MagicLink + Passkey を 1 ボタンで統合処理** する HarmoNet の認証 UI コンポーネントである。
ユーザーはメール入力後、単一の「ログイン」ボタンを押すだけで、MagicLink または Passkey のどちらかが自動的に選択される。

UI トーンは **やさしく・自然・控えめ（Apple カタログ風）** を基準とし、フォントは **BIZ UDゴシック** を使用する。

```tsx
<form
  onSubmit={(e) => {
    e.preventDefault();
    handleLogin();
  }}
  className={`w-full flex flex-col gap-3 ${className || ''}`}
>
  <input
    type="email"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    placeholder={t('form.email')}
    className="h-12 rounded-2xl border border-gray-300 px-3 text-base font-medium focus-visible:ring-2 ring-blue-500"
    required
  />

  <button
    type="submit"
    disabled={state === 'sending' || state === 'passkey_auth'}
    className="h-12 rounded-2xl flex items-center justify-center gap-2 font-medium transition-all duration-200 ease-in-out shadow-sm bg-blue-600 text-white hover:bg-blue-500 disabled:opacity-60"
  >
    {state === 'sending' && <Loader2 className="animate-spin" size={18} />}
    {state === 'passkey_auth' && <KeyRound className="animate-pulse text-blue-300" size={18} />}
    {state === 'success' && <CheckCircle className="text-green-600" size={18} />}
    {state.startsWith('error') && <AlertCircle className="text-red-500" size={18} />}
    {state === 'idle' && <Mail size={18} />}

    <span>
      {state === 'success'
        ? t('success.passkey_success')
        : state === 'sending'
        ? t('success.magiclink_sent')
        : state === 'passkey_auth'
        ? t('success.passkey_success')
        : state.startsWith('error')
        ? t('error.auth')
        : t('form.login')}
    </span>
  </button>

  {state === 'sent' && (
    <p className="text-sm text-gray-500 mt-1" aria-live="polite">
      {t('success.magiclink_sent')}
    </p>
  )}
</form>
```

---

## 4.2 レイアウト仕様

| 項目      | 内容                                  |
| ------- | ----------------------------------- |
| 配置      | Input → Button → Message の縦並び 1 カラム |
| 横幅      | `w-full`（親要素に追従）                    |
| 余白      | 各要素 `gap-3`、フォーム下 16px              |
| 入力欄     | 高さ48px、角丸2xl、左右12px                 |
| ボタン     | 高さ48px、角丸2xl、フォント中量、影付き             |
| タイポグラフィ | BIZ UDゴシック、16px、`text-gray-800`     |

---

## 4.3 カラースキーム

| 状態           | 背景      | テキスト    | アクション   | アイコン      |
| ------------ | ------- | ------- | ------- | --------- |
| idle         | #FFFFFF | #111827 | #2563EB | gray-500  |
| sending      | #EFF6FF | #1E40AF | #3B82F6 | blue-600  |
| passkey_auth | #E0F2FE | #1E40AF | #3B82F6 | blue-300  |
| success      | #ECFDF5 | #065F46 | #10B981 | green-600 |
| error_*      | #FEF2F2 | #B91C1C | #DC2626 | red-500   |

---

## 4.4 状態アイコン仕様

| 状態           | アイコン            | 説明           |
| ------------ | --------------- | ------------ |
| idle         | Mail            | 初期状態         |
| sending      | Loader2（spin）   | MagicLink送信中 |
| passkey_auth | KeyRound（pulse） | Passkey認証中   |
| success      | CheckCircle     | 認証成功         |
| error        | AlertCircle     | エラー発生        |

---

## 4.5 i18n キー構成（v1.2 最新体系）

MagicLinkForm は **form.* / success.* / error.*** の 3 階層で統一する。
旧体系（auth.magiclink.* / auth.passkey.*）はすべて廃止。

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
    "network": "通信エラーが発生しました。",
    "auth": "認証に失敗しました。",
    "origin_mismatch": "認証元が正しくありません。",
    "denied": "パスキー認証が拒否されました。"
  }
}
```

---

## 4.6 アクセシビリティ設計

| 項目      | 内容                                   |
| ------- | ------------------------------------ |
| キーボード操作 | Enter / Tab 全対応                      |
| ARIA    | 成功・失敗メッセージに `aria-live="polite"`     |
| フォーカス表示 | `focus-visible:ring-2 ring-blue-500` |
| エラー表示   | `role="alert"` により読み上げ可能             |

---

## 4.7 アニメーション / 遷移設計

* `transition-all duration-200 ease-in-out`
* 状態に応じた `animate-spin` / `animate-pulse`
* 背景・opacity を組み合わせた自然な変化

---

## 4.8 UI プレビュー

```
┌─────────────────────────────┐
│ [📧 メールアドレス入力]              │
│ [🔐 ログイン]（状態別UI）            │
│ （メール送信完了メッセージ）          │
└─────────────────────────────┘
```

---

## Change Log

| Version | Date       | Summary                                                 |
| ------- | ---------- | ------------------------------------------------------- |
| 1.2     | 2025-11-14 | 全 i18n キーを最新 form.* / success.* / error.* に統合。UIロジック整合。 |
| 1.1     | 2025-11-12 | Passkey統合UI化、1ボタン構成、色とアイコン更新。                           |
