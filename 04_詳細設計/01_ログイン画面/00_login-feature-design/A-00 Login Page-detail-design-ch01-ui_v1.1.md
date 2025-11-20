# A-00 LoginPage 詳細設計書 ch01：UI構成 v1.1

**Document ID:** HARMONET-A00-CH01-UI**
**Version:** 1.1
**Supersedes:** v1.0
**Status:** MagicLink専用

---

# 第1章 概要

本章では **A-00 LoginPage** の UI 構成を定義する。対象は `/login` 画面であり、

* AppHeader（C-01）
* MagicLinkForm（A-01）
* AppFooter（C-04）

の 3 要素で構成される **純粋なレイアウト画面** として設計する。
LoginPage は認証ロジックを一切保持せず、MagicLinkForm に完全委譲する。

---

# 第2章 画面レイアウト構成

LoginPage は **1 カラム・中央配置・白基調** の Apple カタログ風 UI とする。

```
┌──────────────────────────────┐
│ AppHeader (固定表示)                     │
├──────────────────────────────┤
│                              │
│   ┌──────────────────────┐   │
│   │  Logo / Title        │   │
│   │  MagicLinkForm (A-01)│   │
│   │  StatusMessage       │   │
│   └──────────────────────┘   │
│                              │
├──────────────────────────────┤
│ AppFooter (固定表示)                     │
└──────────────────────────────┘
```

---

# 第3章 DOM構造（実装準拠）

```tsx
<main className="min-h-screen flex flex-col bg-white">
  <AppHeader variant="login" />

  <div className="flex-1 flex items-center justify-center px-4 py-10">
    <section
      aria-labelledby="login-title"
      className="w-full max-w-md bg-white rounded-2xl shadow-sm border border-gray-100 px-6 py-8 flex flex-col gap-6"
    >
      {/* Logo / Title / Lead */}

      {/* MagicLinkForm */}

      {/* StatusMessage */}
    </section>
  </div>

  <AppFooter />
</main>
```

---

# 第4章 UI要素仕様（MagicLink専用）

| 要素ID          | 種別        | 内容                     |
| ------------- | --------- | ---------------------- |
| login-logo    | 画像        | HarmoNet ロゴ（SVG）を中央表示  |
| login-title   | h1        | ログイン画面タイトル（i18n対応）     |
| login-lead    | p         | 補助説明文（システム案内）          |
| MagicLinkForm | Component | メール入力・送信・メッセージ表示（A-01） |
| login-status  | 文言        | 成功/失敗時の画面レベルメッセージ（任意）  |

### 4.1 レイアウト要件

* カード幅： **max-w-md（約420px）**
* 角丸： **rounded-2xl**
* シャドウ： **shadow-sm（控えめ）**
* 配色：白基調、余白多め、Apple カタログ風
* タイトル：`text-xl font-semibold`
* リード：`text-sm text-gray-600`

---

# 第5章 i18n（画面レベル文言）

| キー                   | 日本語                    | 英語                        | 中国語       |
| -------------------- | ---------------------- | ------------------------- | --------- |
| login.title          | ログイン                   | Sign in                   | 登录        |
| login.lead           | メールアドレスでログインできます       | You can sign in by email. | 可通过邮箱登录   |
| login.status.success | 認証に成功しました。画面を切り替えています… | Signed in. Redirecting... | 已登录，正在跳转… |
| login.status.error   | ログインに失敗しました。           | Sign in failed.           | 登录失败      |

※ MagicLinkForm 内の詳細メッセージは A-01 側で管理する。

---

# 第6章 レスポンシブ設計

### モバイル（〜640px）

* カードは画面幅 − 32px
* 余白：`px-4 py-10`

### タブレット（641〜1024px）

* max-w-md 中央固定
* 余白をやや広めに

### PC（1025px〜）

* 画面中央配置（max-w-md）
* 背景白のみ

---

# 第7章 アクセシビリティ

* `<section aria-labelledby="login-title">`
* 状態メッセージ領域は `aria-live="polite"`
* Header と Footer のランドマーク構造を維持
* LoginPage 自体は `tabIndex` を持たず、余計なフォーカス制御をしない

---

# 第8章 状態別 UI（LoginPage の扱い）

LoginPage は **状態を保持しない**。
MagicLinkForm（A-01）の状態を受けて、以下のように画面表示が変化する。

| 状態      | 表示                                  |
| ------- | ----------------------------------- |
| idle    | 通常表示                                |
| sending | ボタンは A-01 内でローディング。A-00は変化なし        |
| sent    | `login.status.success` を画面下部に表示（任意） |
| error_* | エラーメッセージを A-01 内で表示、A-00は補助表示のみ     |

---

# 第9章 Windsurf 実装上の注意

* LoginPage では **レイアウトのみ修正対象**
* MagicLinkForm のロジック・スタイル・Propsは編集不可
* AppHeader/AppFooter の import path を統一
* Tailwind クラスの追加は最小限にする（UIトーン保持のため）

---

# 第10章 改訂履歴

| Version | Summary                               |
| ------- | ------------------------------------- |
| v1.1    | Passkey 痕跡を全削除。MagicLink専用の UI に完全整合。 |
| v1.0    | 初版。旧仕様（MagicLink + Passkey UI）を含む構成。  |

---

**End of Document**
