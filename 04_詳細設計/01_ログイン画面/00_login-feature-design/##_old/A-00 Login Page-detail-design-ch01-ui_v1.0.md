# A-00 LoginPage 詳細設計書 ch01：UI構成 v1.1

**Document ID:** HARMONET-COMPONENT-A00-LOGINPAGE-CH01-UI
**Component ID:** A-00
**Screen Name:** LoginPage
**Based On:** login-feature-design-ch01-ui_v1.0（再編成・A-00命名へ統合）
**Standard:** harmonet-detail-design-agenda-standard_v1.0

---

## 第1章 概要

### 1.1 目的

本章は、HarmoNet ログイン画面 **A-00 LoginPage** の UI 構成を定義する。画面レイアウト・共通部品の配置・レスポンシブ挙動・状態別 UI・アクセシビリティを明示し、A-01 MagicLinkForm および A-02 PasskeyAuthTrigger（ロジック）の詳細設計と矛盾なく結合できることを目的とする。

LoginPage はあくまで「画面レイアウトと認証 UI コンテナ」の責務に限定し、認証処理そのものは A-01 / A-02 / /api/session に委譲する。これにより、

* UI とロジックの責務分離
* MagicLink と Passkey の自然な共存
* Windsurf による安全な自動生成

を実現する。

### 1.2 表示対象パス

| パス               | 役割               | A-00 関与 | 備考                             |
| ---------------- | ---------------- | ------- | ------------------------------ |
| `/login`         | ログイン画面ルート        | 〇       | 本章の対象                          |
| `/auth/callback` | MagicLink コールバック | △       | レイアウトのみ共通（AppHeader/AppFooter） |
| `/mypage`        | 認証後マイページ         | ×       | 別画面設計書の対象                      |

---

## 第2章 画面レイアウト構成

### 2.1 全体レイアウト

```text
┌──────────────────────────────────────┐
│ AppHeader (C-01)                   │ fixed top, z=1000
├──────────────────────────────────────┤
│                                    │
│  Main Content                      │
│  ┌──────────────────────────────┐  │
│  │  Logo Area                   │  │
│  │  Title / Lead Text           │  │
│  │  MagicLinkForm (A-01)        │  │
│  │  Status / Helper text        │  │
│  └──────────────────────────────┘  │
│                                    │
├──────────────────────────────────────┤
│ AppFooter (C-04)                   │ fixed bottom, z=900
└──────────────────────────────────────┘
```

※ v1.1 では **Passkey 専用ボタン UI を LoginPage から廃止** し、Passkey 利用有無は A-01 MagicLinkForm 内部のロジックに統合される（技術スタック v4.2 / MagicLinkForm-detail-design v1.1 / PasskeyAuthTrigger v1.1 に整合）。

### 2.2 DOM ツリー（簡略版）

```tsx
<html lang="ja">
  <body>
    <StaticI18nProvider>
      <div className="min-h-screen flex flex-col bg-white">
        <AppHeader variant="login" />
        <main className="flex-1 flex items-center justify-center px-4 py-10">
          <section
            aria-labelledby="login-title"
            className="w-full max-w-md bg-white rounded-2xl shadow-sm border border-gray-100 px-6 py-8 flex flex-col gap-6"
          >
            {/* ロゴ */}
            {/* タイトル・リード文 */}
            {/* MagicLinkForm (A-01) */}
            {/* 状態メッセージ領域（成功・失敗） */}
          </section>
        </main>
        <AppFooter />
      </div>
    </StaticI18nProvider>
  </body>
</html>
```

### 2.3 レイアウト要件

| 項目    | 要件                                                        |
| ----- | --------------------------------------------------------- |
| 画面背景  | `bg-white` 固定。ログイン画面はブランドの「玄関」として常に白基調                    |
| 最大幅   | ログインカードは `max-w-md`（約 420px）に制限                           |
| 垂直配置  | `min-h-screen` + `flex items-center justify-center` で中央寄せ |
| 余白    | 上下 `py-10` / 左右 `px-4`、カード内は `px-6 py-8`                  |
| 角丸    | カードは `rounded-2xl`（24px 程度）                               |
| シャドウ  | `shadow-sm`、主張しすぎない控えめな陰影                                 |
| 枠線    | `border border-gray-100` でカード境界を軽く強調                      |
| スクロール | ビューポートがカード高さより小さい場合、全体スクロール許可                             |

---

## 第3章 コンポーネント構造（A-00 視点）

### 3.1 構造図（Mermaid）

```mermaid
graph TD
  Root[app/login/page.tsx (A-00)] --> Header[AppHeader C-01]
  Root --> Main[LoginMainContainer]
  Root --> Footer[AppFooter C-04]

  Main --> Card[LoginCard]
  Card --> Logo[LogoArea]
  Card --> Title[LoginTitleBlock]
  Card --> Form[A-01 MagicLinkForm]
  Card --> Status[LoginStatusMessage]
```

### 3.2 コンポーネント一覧

| ID   | 名称                 | 種別        | 説明                                 |
| ---- | ------------------ | --------- | ---------------------------------- |
| A-00 | LoginPage          | Page      | `/login` ページ全体を構成するルートコンポーネント      |
| C-01 | AppHeader          | Common    | ロゴ + LanguageSwitch を含むヘッダー        |
| C-02 | LanguageSwitch     | Common    | JA/EN/ZH 切替 UI（ヘッダー内）              |
| C-03 | StaticI18nProvider | Common    | i18n 辞書と `t()` を提供する Provider      |
| C-04 | AppFooter          | Common    | コピーライト表示用フッター                      |
| A-01 | MagicLinkForm      | Feature   | メールアドレス入力 + MagicLink/Passkey ロジック |
| -    | LoginCard          | Layout    | MagicLinkForm を包むカードレイアウトコンポーネント   |
| -    | LoginStatusMessage | Layout/UI | 成功/失敗メッセージ表示ブロック                   |

### 3.3 依存関係の方針

* A-00 は **A-01 の内部状態やロジックに依存しない**。`props` も渡さず、子コンポーネントとして配置のみ行う。
* Passkey に関する指定（有効/無効・UI文言）は A-01 / A-02 側の詳細設計に任せる。
* A-00 は **どの認証方式が成功したかを意識しない**。結果として `/auth/callback` / `/mypage` へ遷移すればよい。

---

## 第4章 UI 要素仕様

### 4.1 要素一覧

| 要素ID           | 種別   | 概要                           | 表示条件 |
| -------------- | ---- | ---------------------------- | ---- |
| `login-logo`   | 画像   | HarmoNet ロゴ（SVG）             | 常時   |
| `login-title`  | 見出し  | 「HarmoNet にログイン」などのタイトル文     | 常時   |
| `login-lead`   | テキスト | 補足リード文。「管理組合からのお知らせを確認できます」等 | 常時   |
| `login-form`   | コンテナ | MagicLinkForm を内包する領域        | 常時   |
| `login-status` | テキスト | 成功/エラー時のメッセージ表示              | 条件付き |

### 4.2 文言仕様（i18n キー）

| 用途       | キー                     | ja                              | en                                | zh          |
| -------- | ---------------------- | ------------------------------- | --------------------------------- | ----------- |
| タイトル     | `login.title`          | ログイン                            | Sign in                           | 登录          |
| リード文     | `login.lead`           | メールアドレスでログインできます                | You can sign in by email.         | 可通过邮箱登录     |
| ステータス成功  | `login.status.success` | 認証に成功しました。画面を切り替えています…          | Signed in. Redirecting...         | 已登录，正在跳转…   |
| ステータスエラー | `login.status.error`   | ログインに失敗しました。しばらく経ってから再度お試しください。 | Sign in failed. Please try again. | 登录失败，请稍后重试。 |

※ A-01 内で使用するエラーメッセージ詳細は MagicLinkForm 詳細設計書側に定義し、ここでは画面レベルのステータス文言のみを扱う。

---

## 第5章 レスポンシブ設計

### 5.1 ブレークポイント方針

* **モバイル（〜640px）**

  * カード幅は 100% - 32px（左右 16px 余白）
  * AppHeader/ Footer は幅一杯に表示
  * タップ領域は最小 44px 以上（フォーム・ボタンは A-01 側で担保）

* **タブレット（641〜1024px）**

  * カード幅は `max-w-md` で固定
  * 画面上下の余白をやや広めに（`py-16` 相当）

* **デスクトップ（1025px〜）**

  * カードは中央寄せのまま
  * 背景は白一色（追加のビジュアルは Phase10 以降の検討とし、本設計では追加しない）

### 5.2 余白・タイポグラフィ

| 要素      | Tailwind 指定例                          |
| ------- | ------------------------------------- |
| タイトル    | `text-xl font-semibold text-gray-900` |
| リード文    | `mt-1 text-sm text-gray-600`          |
| カード内縦間隔 | 子要素間 `gap-4〜6`（フォーム状態により A-01 側で微調整可） |

---

## 第6章 アクセシビリティ仕様

### 6.1 セマンティック構造

* ルートには `<main role="main">` 相当の構造（App Router の `<main>` を利用）。
* ログインカードは `<section aria-labelledby="login-title">` とし、スクリーンリーダーに画面目的を伝える。
* タイトルは `id="login-title"` を持つ `<h1>` とする。

### 6.2 フォーカス順序

1. ブラウザアドレスバー
2. AppHeader 内の LanguageSwitch（C-02）
3. LoginCard 内のメールアドレス入力欄（A-01 内）
4. ログインボタン（A-01 内）

※ 詳細なフォーカス制御は A-01 側実装に委譲するが、LoginCard は余計な `tabIndex` 指定を行わない。

### 6.3 ステータスメッセージ

* `login-status` 領域は `aria-live="polite"` を付与し、認証結果メッセージを読み上げる。
* エラー文言については、A-01 側で `role="alert"` を持つコンポーネントと連携する想定とし、LoginPage ではコンテナのみ提供する。

---

## 第7章 状態別 UI

LoginPage 自体は状態を持たないが、A-01 MagicLinkForm から通知される状態に応じて以下のような視覚的変化を許容する：

| 状態             | 変化内容                                                      |
| -------------- | --------------------------------------------------------- |
| idle           | 通常のフォーム表示。Status メッセージ非表示                                 |
| sending        | フォーム内ボタンがローディング状態（A-01）。LoginPage 側の見た目変化なし               |
| sent           | カード下部に `login.status.success` を表示                         |
| error_* 系      | カード下部、もしくはフォーム直下にエラーメッセージ。色は `text-red-600` を推奨           |
| success (認証完了) | `/auth/callback` や `/mypage` へ遷移するため、LoginPage としては一時的な状態 |

※ 状態遷移の定義は ch02（状態管理）側が正となり、本章は「どのような状態が画面上に現れるか」のガイドを提供するだけとする。

---

## 第8章 実装パターン（レイアウト抜粋）

```tsx
// app/login/page.tsx

import React from "react";
import { AppHeader } from "@/src/components/common/AppHeader";
import { AppFooter } from "@/src/components/common/AppFooter";
import { StaticI18nProvider } from "@/src/components/common/StaticI18nProvider";
import { MagicLinkForm } from "@/src/components/auth/MagicLinkForm";

export default function LoginPage() {
  return (
    <html lang="ja">
      <body className="bg-white text-gray-900 font-sans antialiased">
        <StaticI18nProvider>
          <div className="min-h-screen flex flex-col bg-white">
            <AppHeader variant="login" />
            <main className="flex-1 flex items-center justify-center px-4 py-10">
              <section
                aria-labelledby="login-title"
                className="w-full max-w-md bg-white rounded-2xl shadow-sm border border-gray-100 px-6 py-8 flex flex-col gap-6"
              >
                <div className="flex flex-col items-center gap-2">
                  <img
                    src="/images/logo.svg"
                    alt="HarmoNet"
                    className="h-10"
                  />
                  <h1
                    id="login-title"
                    className="text-xl font-semibold text-gray-900"
                  >
                    {/* t('login.title') */}
                  </h1>
                  <p className="text-sm text-gray-600">
                    {/* t('login.lead') */}
                  </p>
                </div>

                <div>
                  <MagicLinkForm />
                </div>

                <div
                  aria-live="polite"
                  className="min-h-[1.5rem] text-sm text-gray-700"
                >
                  {/* login-status メッセージ（任意） */}
                </div>
              </section>
            </main>
            <AppFooter />
          </div>
        </StaticI18nProvider>
      </body>
    </html>
  );
}
```

※ 実際の実装では App Router の `app/layout.tsx` で `<html><body>` を定義するため、上記は概念図として扱う。Windsurf 用指示書では、app/login/page.tsx のみを編集対象とし、レイアウト構造を本設計に合わせる。

---

## 第9章 Windsurf 利用時の注意点（UI 観点）

* A-00 LoginPage では **UI トーン（白・rounded-2xl・shadow-sm）と構造のみ修正対象** とし、MagicLinkForm や認証ロジックには手を触れない。
* AppHeader / AppFooter / StaticI18nProvider は共通部品設計書（C-01〜C-04）に従い、「読み込み位置の変更のみ」行う。
* CSS ファイルや Tailwind コンフィグの変更は別タスクとし、本タスクでは行わない。

---

## 第10章 メタ情報・改訂履歴

### 10.1 メタ情報

* 技術スタック整合先: `harmonet-technical-stack-definition.md`
* 参照詳細設計書:

  * `MagicLinkForm-detail-design.md`
  * `PasskeyAuthTrigger-detail-design.md`
  * `HarmoNet Passkey認証の仕組みと挙動.md`
  * 共通部品: `ch01_AppHeader.md`, `ch04_AppFooter.md` ほか

### 10.2 改訂履歴

| Version | Date       | Author          | Summary                                                                       |
| ------- | ---------- | --------------- | ----------------------------------------------------------------------------- |
| v1.0    | 2025-11-11 | TKD / Tachikoma | login-feature-design-ch01-ui_v1.0 として初版作成                                     |
| v1.1    | 2025-11-15 | TKD / Tachikoma | A-00 命名規則への統合。PasskeyButton UI を廃止し、MagicLinkForm 内ロジック統合方針へ更新。UI レイアウト仕様を再整理 |
