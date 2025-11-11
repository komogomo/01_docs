# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch05 UI仕様 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH05
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.0 / Design System 準拠）

---

## 第5章 UI仕様

### 5.1 JSX構造（UIツリー）

```tsx
<button
  type="button"
  onClick={handleLogin}
  disabled={state === 'loading'}
  aria-busy={state === 'loading'}
  aria-live="polite"
  className="w-full h-12 rounded-2xl bg-blue-600 text-white font-medium flex items-center justify-center gap-2 hover:bg-blue-500 disabled:opacity-60 transition"
>
  {state === 'loading' && <Loader2 className="animate-spin" aria-hidden />}
  {state === 'success' && <CheckCircle className="text-green-500" aria-hidden />}
  {state === 'error' && <AlertCircle className="text-red-500" aria-hidden />}
  {state === 'idle' && <KeyRound aria-hidden />}
  <span>
    {state === 'success' ? t('auth.passkey.success')
      : state === 'loading' ? t('auth.passkey.progress')
      : state === 'error' ? t('auth.retry')
      : t('auth.passkey.login')}
  </span>
</button>
```

#### DOM階層

```
button (ルート)
├─ SVGアイコン（lucide-react）
└─ span（テキストラベル）
```

---

### 5.2 スタイリング（Tailwind 構成）

#### 5.2.1 ベーススタイル

| 要素     | クラス                                                                                                                | 内容         |
| ------ | ------------------------------------------------------------------------------------------------------------------ | ---------- |
| ルートボタン | `w-full h-12 rounded-2xl flex items-center justify-center gap-2 font-medium shadow-sm transition-all duration-200` | 共通構造       |
| 通常状態   | `bg-blue-600 text-white hover:bg-blue-500`                                                                         | Primaryトーン |
| 成功状態   | `bg-green-600 hover:bg-green-500`                                                                                  | 成功通知       |
| エラー状態  | `bg-red-600 hover:bg-red-500`                                                                                      | 失敗通知       |
| ローディング | `cursor-wait opacity-80`                                                                                           | 操作中表示      |

#### 5.2.2 デザイン基準

* **角丸:** `rounded-2xl`（16px相当）
* **影:** `shadow-sm`（浮遊感）
* **トーン:** 白ベース／青アクセント（HarmoNet Design System準拠）
* **フォント:** BIZ UDゴシック（全画面統一）
* **配色:** Appleカタログ風・落ち着いたトーン（#2563EB基調）

---

### 5.3 アイコン仕様

| 状態      | アイコン        | ライブラリ        | サイズ  | カラー              |
| ------- | ----------- | ------------ | ---- | ---------------- |
| idle    | KeyRound    | lucide-react | 20px | 継承               |
| loading | Loader2     | lucide-react | 20px | `animate-spin`   |
| success | CheckCircle | lucide-react | 20px | `text-green-500` |
| error   | AlertCircle | lucide-react | 20px | `text-red-500`   |

---

### 5.4 i18n 表示仕様（StaticI18nProvider）

| キー                      | ja        | en                   | zh       |
| ----------------------- | --------- | -------------------- | -------- |
| `auth.passkey.login`    | パスキーでログイン | Sign in with Passkey | 使用通行密钥登录 |
| `auth.passkey.progress` | 認証中...    | Authenticating...    | 正在验证...  |
| `auth.passkey.success`  | ログイン成功    | Login Successful     | 登录成功     |
| `auth.retry`            | 再試行       | Retry                | 重试       |
| `error.network`         | 通信エラー     | Network Error        | 网络错误     |

> **翻訳管理:** `public/locales/{lang}/common.json` に定義し、`useI18n()` にてリアルタイム反映。

---

### 5.5 アクセシビリティ

* **ARIA属性:** `aria-busy`, `aria-live="polite"`, `aria-hidden` を状態別で設定。
* **フォーカス:** `focus-visible:ring-2 focus:ring-blue-300`。
* **コントラスト:** WCAG 2.1 AA 準拠 (最低4.5:1)。
* **操作:** Tab / Enter / Space で完全操作可能。

---

### 5.6 トランジション・アニメーション

| 対象   | クラス                                       | 効果           |
| ---- | ----------------------------------------- | ------------ |
| 背景色  | `transition-all duration-200 ease-in-out` | 状態変化時の滑らかな遷移 |
| スピナー | `animate-spin`                            | 認証中の動作強調     |

---

### 5.7 デザイン意図

* UIは MagicLinkForm と統一スタイル。
* 状態視覚化は4段階（idle / loading / success / error）。
* 色調は Calm & Natural（青／白／緑／赤）。
* アイコンは直感的かつ軽量（lucide-react）。
* 多言語文言は StaticI18nProvider によるリアルタイム反映を保証。

---

### 5.8 テスト観点（UI／アクセシビリティ）

| テストID   | 観点    | 手順          | 期待結果              |
| ------- | ----- | ----------- | ----------------- |
| T-UI-01 | 初期表示  | ページ描画時      | 「パスキーでログイン」が表示される |
| T-UI-02 | 状態遷移  | クリック→成功     | 成功アイコン＋緑背景に変化     |
| T-UI-03 | 通信失敗  | エラー時        | 赤背景＋エラー文言表示       |
| T-UI-04 | 多言語切替 | 言語切替操作      | 翻訳文言が即時反映         |
| T-UI-05 | A11y  | Tab/Enter操作 | ボタンがフォーカス・実行可能    |

---

### 5.9 ChangeLog

| Version | Date       | Author    | Summary                                     |
| ------- | ---------- | --------- | ------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版。UI状態4種・i18n・ARIA対応。MagicLinkFormスタイルと統一。 |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch05_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
