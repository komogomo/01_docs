# MagicLinkForm 詳細設計書 - 第4章：UI設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH04
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Passkey自動統合・1ボタン構成）

---

## 第4章 UI設計

### 4.1 コンポーネント構成概要

MagicLinkForm は、ユーザーの入力操作から結果通知までを **単一のログインボタンで完結**させる統合UIとして設計する。
従来の Magic Link 専用送信UIを改訂し、パスキー認証が有効な場合には同ボタンから自動的に WebAuthn フローを起動する。

UIは HarmoNet 共通の **Appleカタログ風・やさしく・自然・控えめ** スタイルを踏襲し、フォントは **BIZ UDゴシック** を採用する。

```tsx
<form
  onSubmit={(e) => {
    e.preventDefault();
    handleLogin(); // MagicLink or Passkey を自動選択
  }}
  className={`w-full flex flex-col gap-3 ${className || ''}`}
>
  <input
    type="email"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    placeholder={t('auth.magiclink.enter_email')}
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
        ? t('auth.passkey.success')
        : state === 'sending'
        ? t('auth.magiclink.sending')
        : state === 'passkey_auth'
        ? t('auth.passkey.login')
        : state.startsWith('error')
        ? t('auth.retry')
        : t('auth.login')}
    </span>
  </button>

  {state === 'sent' && (
    <p className="text-sm text-gray-500 mt-1" aria-live="polite">
      {t('auth.magiclink.check_email')}
    </p>
  )}
</form>
```

---

### 4.2 レイアウト仕様

| 項目     | 内容                                 |
| ------ | ---------------------------------- |
| 配置     | 垂直1カラム構成（Input → Button → Message） |
| 横幅     | `w-full`（親要素幅に追従）                  |
| 余白     | 要素間 `gap-3`、フォーム下マージン16px          |
| 入力欄    | 高さ48px、角丸2xl、左右パディング12px           |
| ボタン    | 高さ48px、角丸2xl、左右パディング16px、フォント太さ500 |
| テキスト   | 16px、BIZ UDゴシック、`text-gray-800`    |
| レスポンシブ | モバイル〜デスクトップ共通、幅自動調整                |

---

### 4.3 カラースキーム

| 状態             | 背景      | テキスト    | アクション   | アイコン    |
| -------------- | ------- | ------- | ------- | ------- |
| `idle`         | #FFFFFF | #111827 | #2563EB | #6B7280 |
| `sending`      | #EFF6FF | #1E40AF | #3B82F6 | #2563EB |
| `passkey_auth` | #E0F2FE | #1E40AF | #3B82F6 | #2563EB |
| `success`      | #ECFDF5 | #065F46 | #10B981 | #059669 |
| `error_*`      | #FEF2F2 | #B91C1C | #DC2626 | #DC2626 |

* **配色基準:** WCAG 2.1 AA 適合（コントラスト比4.5:1以上）。
* **Corbado状態:** passkey_auth時に背景を淡青 (#E0F2FE) として処理中を視覚的に明示。

---

### 4.4 状態アイコン仕様

| 状態           | アイコン        | ライブラリ        | サイズ  | カラー                               | 補足         |
| ------------ | ----------- | ------------ | ---- | --------------------------------- | ---------- |
| idle         | Mail        | lucide-react | 18px | 継承                                | 初期状態       |
| sending      | Loader2     | lucide-react | 18px | `text-blue-600` + `animate-spin`  | メール送信中     |
| passkey_auth | KeyRound    | lucide-react | 18px | `text-blue-300` + `animate-pulse` | Passkey認証中 |
| success      | CheckCircle | lucide-react | 18px | `text-green-600`                  | 成功         |
| error        | AlertCircle | lucide-react | 18px | `text-red-500`                    | エラー        |

---

### 4.5 i18n キー構成

```json
{
  "auth": {
    "login": "ログイン",
    "retry": "再試行",
    "passkey": {
      "login": "パスキー認証を実行中...",
      "success": "パスキー認証が完了しました",
      "denied": "パスキー認証が拒否されました"
    },
    "magiclink": {
      "enter_email": "メールアドレスを入力",
      "sending": "メールリンクを送信中...",
      "sent": "メールを送信しました",
      "check_email": "メールをご確認ください"
    }
  }
}
```

* `auth.login` を基軸キーとして統合。
* Passkey関連キーを MagicLinkForm 内で共通管理。
* StaticI18nProvider (C-03) により多言語辞書を即時反映。

---

### 4.6 アクセシビリティ設計

| 項目       | 内容                                                 |
| -------- | -------------------------------------------------- |
| キーボード操作  | Enter/Tab対応。全要素に `focus-visible` 適用。               |
| ARIA属性   | 成功／失敗メッセージに `aria-live="polite"` 適用。               |
| フォーカス可視化 | `focus-visible:ring-2 ring-blue-500 ring-offset-2` |
| 入力エラー    | `role="alert"` によりスクリーンリーダー読み上げ対応。                 |
| 視覚設計     | 状態色＋アイコンで意味を明示。色覚多様性対応済み。                          |

---

### 4.7 アニメーション / 遷移設計

* **トランジション:** `transition-all duration-200 ease-in-out`
* **アニメーション:** `animate-spin`（送信中） / `animate-pulse`（Passkey認証）
* **背景フェード:** 状態遷移に応じて `opacity` と `bg-*` を同時変更。
* **ホバー:** `hover:bg-blue-500` による軽いインタラクション演出。

---

### 4.8 UIプレビュー（論理構成図）

```
┌──────────────────────────────────────┐
│ [📧 メールアドレス入力欄]                            │
│ [🔐 ログイン] ← 状態: idle / sending / passkey_auth / success / error │
│ （メールをご確認ください）← sent 状態時のみ表示                   │
└──────────────────────────────────────┘
```

---

### 🧾 Change Log

| Version  | Date           | Summary                                      |
| -------- | -------------- | -------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（MagicLink専用UI）                            |
| **v1.1** | **2025-11-12** | **Passkey統合対応。ログインボタン1本化・i18nキー統合・UI色設計改訂。** |
