# MagicLinkForm 詳細設計書 - 第4章：UI設計（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH04
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式整合版（技術スタック v4.0 準拠）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第4章 UI設計

### 4.1 コンポーネント構成概要

MagicLinkForm は、ユーザーの入力操作から結果通知までを 1 画面で完結させるミニマル UI として設計される。
デザインは HarmoNet 共通の「Appleカタログ風・やさしく・自然・控えめ」トーンに統一し、**BIZ UDゴシック**を使用する。

```tsx
<form
  onSubmit={(e) => { e.preventDefault(); handleSendMagicLink(); }}
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
    disabled={state === 'sending'}
    className="h-12 rounded-2xl flex items-center justify-center gap-2 font-medium transition-all duration-200 ease-in-out shadow-sm bg-blue-600 text-white hover:bg-blue-500 disabled:opacity-60"
  >
    {state === 'sending' && <Loader2 className="animate-spin" size={18} />}
    {state === 'sent' && <CheckCircle className="text-green-600" size={18} />}
    {state.startsWith('error') && <AlertCircle className="text-red-500" size={18} />}
    {state === 'idle' && <Mail size={18} />}
    <span>
      {state === 'sent'
        ? t('auth.magiclink.sent')
        : state.startsWith('error')
        ? t('auth.magiclink.retry')
        : t('auth.magiclink.send')}
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

| 項目     | 内容                                             |
| ------ | ---------------------------------------------- |
| 配置     | 垂直方向の1カラム構成（Input → Button → Message）          |
| 横幅     | `w-full`（親コンテナ幅に追従）                            |
| 余白     | 各要素間 `gap-3`、ボトムマージン 16px                      |
| 入力欄    | 高さ `48px`、角丸 `2xl`、左右パディング `12px`              |
| ボタン    | 高さ `48px`、角丸 `2xl`、左右パディング `16px`、フォント太さ `500` |
| テキスト   | 16px / BIZ UDゴシック / `text-gray-800`            |
| レスポンシブ | モバイル〜デスクトップまで共通、横幅自動調整                         |

---

### 4.3 カラースキーム

| 状態        | 背景      | テキスト    | アクションカラー | アイコン    |
| --------- | ------- | ------- | -------- | ------- |
| `idle`    | #FFFFFF | #111827 | #2563EB  | #6B7280 |
| `sending` | #EFF6FF | #1E40AF | #3B82F6  | #2563EB |
| `sent`    | #ECFDF5 | #065F46 | #10B981  | #059669 |
| `error_*` | #FEF2F2 | #B91C1C | #DC2626  | #DC2626 |

* **配色根拠:** WCAG 2.1 AA のコントラスト比 4.5:1 以上を満たす。
* **リンクやアイコンは色覚多様性を考慮**し、彩度差・明度差で区別可能な配色を採用。

---

### 4.4 状態アイコン仕様

| 状態      | アイコン        | ライブラリ        | サイズ  | カラー                              | 補足         |
| ------- | ----------- | ------------ | ---- | -------------------------------- | ---------- |
| idle    | Mail        | lucide-react | 18px | 継承                               | 初期状態       |
| sending | Loader2     | lucide-react | 18px | `text-blue-600` + `animate-spin` | 処理中アニメーション |
| sent    | CheckCircle | lucide-react | 18px | `text-green-600`                 | 成功表示       |
| error   | AlertCircle | lucide-react | 18px | `text-red-500`                   | エラー表示      |

---

### 4.5 i18n キー構成

```json
{
  "auth": {
    "magiclink": {
      "enter_email": "メールアドレスを入力",
      "send": "Magic Linkを送信",
      "sending": "送信中...",
      "sent": "メールを送信しました",
      "retry": "再試行",
      "check_email": "メールをご確認ください"
    }
  }
}
```

* 翻訳キーは `auth.magiclink.*` に統一し、StaticI18nProvider (C-03) から提供される。
* 各キーは ja / en / zh の3言語に対応し、UTF-8 JSONとして `/public/locales/` 配下に格納。

---

### 4.6 アクセシビリティ設計

| 項目       | 内容                                                 |
| -------- | -------------------------------------------------- |
| キーボード操作  | Enter / Tab 対応、全フォーカス可能要素に `focus-visible` 適用      |
| ARIA 属性  | `aria-live="polite"` による送信結果読み上げ                   |
| ランドマーク   | form要素を `role="form"` として自動認識                      |
| フォーカス可視化 | `focus-visible:ring-2 ring-blue-500 ring-offset-2` |
| 入力エラー    | `role="alert"` による音声リーダー通知                         |
| コントラスト比  | 4.5:1 以上（背景と前景の差）                                  |

---

### 4.7 アニメーション / 遷移設計

* **トランジション:** `transition-all duration-200 ease-in-out`
* **アニメーション:** `animate-spin`（送信中アイコン）
* **ボタンカラー遷移:** hover時の `bg-blue-600 → bg-blue-500`（滑らかに変化）
* **背景フェード:** 状態変更時に `opacity` と `bg-*` の同時トランジションで自然な切替を実現。

---

### 4.8 UIプレビュー（論理構成図）

```
┌──────────────────────────────┐
│ [📧 メールアドレス入力欄]                     │
│ [📨 Magic Linkを送信] ← 送信中: 🔄 / 成功: ✅ / エラー: ⚠ │
│ （メールをご確認ください）← sent状態時のみ表示          │
└──────────────────────────────┘
```

---

### 🧾 Change Log

| Version | Date       | Summary                                   |
| ------- | ---------- | ----------------------------------------- |
| v1.0    | 2025-11-11 | 初版（Phase9仕様：UI統合・WCAG適合・Appleカタログ風デザイン準拠） |
