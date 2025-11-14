# WS-A01_MagicLinkForm_v1.0

**カテゴリ:** Windsurf実行指示書（製造）
**対象コンポーネント:** A-01 MagicLinkForm
**配置パス:** `/src/components/auth/MagicLinkForm/`
**対応仕様書:** `/01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_*.*.md`
**関連技術:** React 19, Next.js 16, Tailwind CSS 4, Supabase Auth, StaticI18nProvider

---

## 1. Goal（目的）

本指示書の目的は、HarmoNetログイン画面における
**MagicLink認証フォームのUI・ロジック・多言語対応・単体テスト**を
Windsurf が自動生成・修正できるよう、実装仕様を完全に明示することである。

MagicLinkFormは、メールリンク認証を行うフォームであり、
将来的にPasskey認証を統合するA-01/A-02複合コンポーネントの中核を担う。

---

## 2. Scope（範囲）

| 項目    | 適用範囲                                       |
| ----- | ------------------------------------------ |
| UI    | JSX構造、Tailwindクラス、状態別UIの描画                 |
| Logic | Supabase Auth連携、送信処理、エラーハンドリング             |
| Data  | メールアドレス入力値、状態フラグ（idle/sending/sent/error）  |
| i18n  | StaticI18nProviderコンテキスト利用による文言切替          |
| Test  | React Testing Library による状態別UT、スナップショットテスト |

除外範囲: PasskeyButtonの実装本体（A-02側）、Storybookデモコード、Supabase設定ファイル。

---

## 3. Contract（契約仕様）

### Props

| 名称               | 型            | 必須 | 説明                        |
| ---------------- | ------------ | -- | ------------------------- |
| `passkeyEnabled` | `boolean`    | 任意 | true時は送信後にPasskey自動判定を実行  |
| `onSent`         | `() => void` | 任意 | MagicLink送信完了時に呼ばれるコールバック |

### State

| 名称             | 型                                          | 説明              |
| -------------- | ------------------------------------------ | --------------- |
| `email`        | `string`                                   | 入力中のメールアドレス     |
| `status`       | `'idle' \| 'sending' \| 'sent' \| 'error'` | フォーム状態          |
| `errorMessage` | `string \| null`                           | エラーメッセージ（必要時のみ） |

### Events

| イベント             | トリガー                   | 動作                                       |
| ---------------- | ---------------------- | ---------------------------------------- |
| `onSubmit`       | フォーム送信時                | Supabase `signInWithOtp()` 実行、結果に応じて状態遷移 |
| `onLocaleChange` | StaticI18nProviderより発火 | 文言自動更新                                   |

---

## 4. References（参照ファイル）

* `/01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_*.*.md`
* `/01_docs/04_詳細設計/01_ログイン画面/PasskeyButton-detail-design_*.*.md`
* `/src/components/common/StaticI18nProvider/StaticI18nProvider.tsx`
* `/public/locales/{ja,en,zh}/common.json`
* `/lib/supabaseClient.ts`

---

## 5. UI構造仕様

```tsx
<form onSubmit={handleSubmit} className="flex flex-col gap-4">
  <label htmlFor="email" className="text-sm font-medium text-gray-700">
    {t("auth.enter_email")}
  </label>
  <input
    id="email"
    type="email"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    placeholder="name@example.com"
    className="h-12 px-3 border rounded-2xl border-gray-300 focus:ring-2 focus:ring-blue-500"
    required
  />
  <button
    type="submit"
    disabled={status === "sending"}
    className="h-12 rounded-2xl bg-blue-600 text-white font-medium disabled:opacity-60 transition"
  >
    {status === "sending" ? t("auth.sending") : t("auth.send_magic_link")}
  </button>

  {status === "sent" && (
    <p className="text-green-600 text-sm">{t("auth.link_sent")}</p>
  )}
  {status === "error" && (
    <p className="text-red-600 text-sm">{t("auth.error_generic")}</p>
  )}
</form>
```

---

## 6. Logic仕様

1. `handleSubmit`で`preventDefault()`後に`status="sending"`へ遷移。
2. `supabase.auth.signInWithOtp({ email })`を実行。
3. 成功時：`status="sent"` → `onSent?.()` を呼ぶ。
4. エラー時：`status="error"`、`errorMessage`を設定。
5. `passkeyEnabled === true` の場合、送信後に
   `window.__CORBADO_MODE === "success"` 時は `signInWithIdToken()` を実行。
6. 全処理終了後は`aria-live="polite"`領域にメッセージ表示。

---

## 7. i18n仕様

* 翻訳キー: `/public/locales/*/common.json` に以下を登録。

```json
{
  "auth": {
    "enter_email": "メールアドレスを入力してください",
    "send_magic_link": "マジックリンクを送信",
    "sending": "送信中...",
    "link_sent": "送信しました。メールをご確認ください。",
    "error_generic": "送信に失敗しました。再度お試しください。"
  }
}
```

* `useStaticI18n()` から `t("auth.xxx")` 形式で参照。

---

## 8. Unit Test Spec（単体テスト仕様）

**使用:** React Testing Library + Jest

* 初期状態: input空、button有効、メッセージ非表示。
* 入力→送信: `status="sending"` に変化。
* 成功モック時: `status="sent"` に変化、緑メッセージ表示。
* 失敗モック時: `status="error"` に変化、赤メッセージ表示。
* i18n切替時: `t()`文言が全localeで切替確認。

---

## 9. Acceptance Criteria（受入基準）

| 項目                | 条件                              |
| ----------------- | ------------------------------- |
| ESLint / Prettier | エラー0、警告0                        |
| Storybook表示       | JA/EN/ZHすべて切替確認                 |
| RTLテスト            | 100%パス                          |
| 状態遷移              | idle→sending→sent / error が再現可能 |
| i18nキー            | `common.json`と完全一致              |
| UI統一              | Tailwind spacingと角丸2xlを保持       |

---

## 10. Bans（禁止事項）

* 新規CSSファイルやSCSS導入は禁止（Tailwindのみ使用）
* Supabase以外の認証呼び出しは禁止
* Props名・関数名のリネーム禁止
* 外部依存追加禁止（特にaxios, react-query等）
* UIトーンの変更禁止（Appleカタログ風：やさしく・控えめ）

---

## 11. Meta Output（Windsurf出力フォーマット）

Windsurfは完了後に以下の形式で自己評価を返すこと。

```
[CodeAgent_Report]
Agent: Windsurf
Target: MagicLinkForm
Attempts: 1
SelfScore: 9.6/10
LintErrors: 0
TestPassRate: 100%
References:
 - MagicLinkForm-detail-design_*.*.md
 - StaticI18nProvider_v1.0
[/CodeAgent_Report]
```

---

**Document ID:** WS-A01
**Version:** 1.0
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewed by:** TKD
**Approved:** ✅
