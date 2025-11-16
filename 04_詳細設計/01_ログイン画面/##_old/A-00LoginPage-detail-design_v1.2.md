# HarmoNet 詳細設計書 - LoginPage (A-00) v1.2

**Document ID:** HARMONET-COMPONENT-A00-LOGINPAGE-DESIGN
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-11
**Updated:** 2025-11-15
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ A1 基本設計（カードタイル UI）反映版 / 技術スタック v4.2 準拠

---

## 第1章 概要

### 1.1 目的

LoginPage (A-00) は、HarmoNet における認証フローの入口となる **ログイン画面のトップレベルページコンポーネント** の詳細設計を示す。
本書では、基本設計書 **「HarmoNet 基本設計書（A1）- ログイン画面 v1.0」** で定義された以下の要件を、Next.js 16 (App Router) + React 19 + TypeScript + Tailwind CSS 環境で実現するための仕様に落とし込む。

* 画面上部に AppHeader、下部に AppFooter を配置することによる **HarmoNet 全体のトーン統一**。
* 画面中央に A-01 MagicLinkForm を配置し、

  * メールアドレス入力欄
  * **左右 2 枚のカードタイル型ログインボタン（MagicLink / Passkey）**
    を提供する UI を構成する。
* 認証ロジック（MagicLink 送信 / Passkey 認証）は A-01 / A-02 側の責務とし、LoginPage 自身は **レイアウトと画面構造の制御のみに徹する**。

### 1.2 スコープ

本詳細設計書のスコープは以下とする。

* 対象コンポーネント

  * `app/login/page.tsx` に実装される LoginPage (A-00)
* 対象外（別詳細設計書のスコープ）

  * MagicLinkForm (A-01): メール入力・バリデーション・メッセージ表示・カードタイル UI 実装
  * PasskeyAuthTrigger (A-02): Corbado SDK / WebAuthn を用いた Passkey 認証ロジック
  * 共通ヘッダー / フッター / i18n:

    * AppHeader (C-01)
    * AppFooter (C-04)
    * StaticI18nProvider

LoginPage は、これらコンポーネントを **一つの画面として束ねるコンテナ** として機能する。

### 1.3 前提条件

* 技術スタックは `harmonet-technical-stack-definition_v4.2` に準拠する。
* フロントエンドのディレクトリ構造は `harmonet-frontend-directory-guideline_v1.0` に準拠する。
* 認証挙動（MagicLink / Passkey のフロー、OS ネイティブダイアログ挙動など）は、`HarmoNet_Passkey認証の仕組みと挙動_v1.0` に準拠する。
* 本書では、Supabase プロジェクト設定・Corbado テナント設定などインフラレベルの事項は扱わない（該当する非機能設計書・インフラ設計書を参照）。

### 1.4 対象読者

* UI / フロントエンド実装担当（Windsurf / Cursor を含む）
* ログイン機能のレビュー担当（Gemini / TKD）
* 要件定義・基本設計担当者（Login 関連変更のインパクト確認用）

---

## 第2章 機能設計

### 2.1 機能要約

LoginPage は、ユーザーが HarmoNet にログインするための **トップレベル画面コンポーネント** として、以下の責務のみを持つ。

* 画面レイアウトの構成

  * 上部に AppHeader (C-01)
  * 中央に A-01 MagicLinkForm（メール入力 + カードタイル UI）
  * 下部に AppFooter (C-04)
* A-01 MagicLinkForm による **ログイン方式の提示**

  * 1つのメールアドレス入力欄
  * 左右に並ぶ 2 枚のカードタイル型ログインボタン：

    * 📩 ログイン（メール / MagicLink）
    * 🔐 ログイン（Passkey）
* 認証フローの委譲

  * ログインの実処理（MagicLink 送信・Passkey 認証）は A-01 / A-02 に委譲し、LoginPage は **成功／失敗の詳細な制御を行わない**。

ログイン成功後の遷移（`/auth/callback` → `/mypage` 等）は、A-01 / A-02 側の詳細設計およびルーティング設計の責務とする。LoginPage は Next.js App Router の `app/login/page.tsx` から、これらのコンポーネントを構成するだけである。

### 2.2 入出力仕様

#### 表示トリガ

* ユーザーが `/login` にアクセスしたタイミングで表示される。
* セッションが無効になった場合のリダイレクト先画面としても利用される想定（詳細はセッション管理設計書を参照）。

#### 主な入出力

| 種別 | 項目               | 内容 / 型                          | 備考                            |
| -- | ---------------- | ------------------------------- | ----------------------------- |
| 入力 | URL パス           | `/login`                        | App Router のルーティングにより表示       |
| 入力 | i18n Locale      | `ja` / `en` / `zh`              | StaticI18nProvider から取得       |
| 出力 | 画面描画             | LoginPage のレイアウトツリー             | Header / Main / Footer の 3 領域 |
| 委譲 | メールアドレス入力        | `string`                        | MagicLinkForm (A-01) に完全委譲    |
| 委譲 | MagicLink ログイン実行 | Supabase Auth (`signInWithOtp`) | A-01 / A-02 で処理               |
| 委譲 | Passkey ログイン実行   | Corbado Web SDK / WebAuthn      | A-02（PasskeyAuthTrigger）で処理   |
| 委譲 | エラーメッセージ表示       | i18n メッセージキー                    | A-01 の UI メッセージ仕様に従う          |

LoginPage 自体は、フォーム値・エラー内容などの状態を保持せず、**すべて子コンポーネント側の責務として扱う**。

### 2.3 画面構成（ゾーニング）

* ヘッダー領域

  * AppHeader (C-01) をそのまま配置。
* メイン領域

  * 画面中央に、BIZ UD ゴシックを前提としたシンプルなカード調コンテナを置き、その中に A-01 MagicLinkForm を配置する。
  * A-01 内の構成（メール入力欄＋2枚のカードタイル）は本詳細設計では定義しないが、**A1 基本設計の 5章・6章の UI 要件を満たす**ことが前提となる。
* フッター領域

  * AppFooter (C-04) をそのまま配置。

### 2.4 非機能要件との関係

* パフォーマンス

  * LoginPage 自体はロジックを持たないため、描画コストは主に A-01 / C-01 / C-04 に依存する。
  * 必要に応じて Next.js の `dynamic` import や `Suspense` を検討するが、本詳細設計では採用しない（別途パフォーマンス設計で扱う）。
* セキュリティ

  * CSRF / XSS 対策、Cookie 設定などは Supabase / Next.js 側の設定に依存し、本コンポーネントでは直接扱わない。
  * ただし、**HTTP 以外のプロトコル (tel:, mailto:) を画面内から発行しない**など、不要なリンクは設置しない。

### 2.5 副作用と再レンダー設計

* LoginPage は **状態を持たない Pure Component** として実装する。
* 再レンダー要因

  * StaticI18nProvider によるロケール変更
  * A-01 MagicLinkForm 内の状態変化（入力値、送信状態、エラーメッセージなど）
* 副作用

  * 認証フロー開始（Supabase / Corbado 呼び出し）
  * OS の Passkey ダイアログ表示
    これらはすべて A-01 / A-02 の責務とし、LoginPage は副作用を発生させるコードを持たない。

### 2.6 UT 観点

LoginPage 単体として確認すべき観点は、**レイアウトと依存コンポーネントの配置・表示条件** に限定する。

| 観点ID      | 観点                  | 操作内容                        | 期待結果                                                   |
| --------- | ------------------- | --------------------------- | ------------------------------------------------------ |
| UT-A00-01 | Header / Footer の表示 | `/login` にアクセス              | AppHeader / AppFooter が表示される。                          |
| UT-A00-02 | MagicLinkForm の表示   | `/login` にアクセス              | メイン領域に A-01 MagicLinkForm が表示される。                      |
| UT-A00-03 | カードタイル UI の存在       | `/login` にアクセス              | A-01 内に「ログイン（メール）」と「ログイン（Passkey）」の 2 タイルが表示されていること。   |
| UT-A00-04 | レスポンシブ表示（スマホ）       | 幅 360px 程度で `/login` を表示    | 2 枚のカードタイルが縦並び表示になる（A1 基本設計に準拠）。                       |
| UT-A00-05 | i18n 切替の影響範囲        | Locale を `ja`→`en`→`zh` に切替 | AppHeader / AppFooter / MagicLinkForm 内文言が切り替わり、構造は不変。 |

A-01 / A-02 の詳細な UT は、各コンポーネントの詳細設計書で別途定義する。

---

## 第3章 構造設計

### 3.1 コンポーネント構成図

```mermaid
graph TD
  A[app/login/page.tsx (LoginPage)] --> B[AppHeader (C-01)]
  A --> C[Main コンテナ]
  C --> D[MagicLinkForm (A-01)]
  A --> E[AppFooter (C-04)]
```

* A-02 PasskeyAuthTrigger は MagicLinkForm (A-01) の内部ロジックとして利用されるため、画面構造図では省略する。

### 3.2 Props / 依存関係

LoginPage 自体は外部から Props を受け取らず、以下の依存コンポーネントを直接 import する。

| コンポーネント              | 役割                      | 備考                       |
| -------------------- | ----------------------- | ------------------------ |
| AppHeader (C-01)     | 画面上部の共通ヘッダー             | ロゴ・アプリ名・共通操作など           |
| AppFooter (C-04)     | 画面下部の共通フッター             | コピーライト・サービス名など           |
| MagicLinkForm (A-01) | メール入力 + ログイン方式カードタイル UI | 認証ロジックは A-01 / A-02 側にある |

### 3.3 レイアウトコンテナ構造

* `<main>` 要素を中心に、縦方向にヘッダー / コンテンツ / フッターを並べる。
* コンテンツ中央は以下のような構造を取る。

```tsx
<main className="min-h-screen flex flex-col bg-white">
  <AppHeader />
  <div className="flex-1 flex items-center justify-center px-4 py-8">
    <section className="w-full max-w-md">
      <MagicLinkForm />
    </section>
  </div>
  <AppFooter />
</main>
```

* MagicLinkForm 内で、メール入力＋カードタイル UI を構成する前提とする。

### 3.4 依存モジュール・ライブラリ

* `react`
* `next`
* 共通 UI コンポーネント群

  * `@/src/components/common/AppHeader/AppHeader`
  * `@/src/components/common/AppFooter/AppFooter`
  * `@/src/components/auth/MagicLinkForm/MagicLinkForm`

LoginPage 自体は Supabase / Corbado などのライブラリを直接 import しない。

---

## 第4章 実装設計

### 4.1 ファイル配置

`harmonet-frontend-directory-guideline_v1.0` に従い、ログイン画面は Next.js App Router の `app/` 配下に配置する。

```text
app/
  layout.tsx               # ルートレイアウト（StaticI18nProvider をラップ）
  login/
    page.tsx              # LoginPage (A-00)
```

### 4.2 コード構成（例）

```tsx
// app/login/page.tsx
'use client';

import React from 'react';
import { AppHeader } from '@/src/components/common/AppHeader/AppHeader';
import { AppFooter } from '@/src/components/common/AppFooter/AppFooter';
import { MagicLinkForm } from '@/src/components/auth/MagicLinkForm/MagicLinkForm';

const LoginPage: React.FC = () => {
  return (
    <main className="min-h-screen flex flex-col bg-white">
      <AppHeader />
      <div className="flex-1 flex items-center justify-center px-4 py-8">
        <section className="w-full max-w-md">
          <MagicLinkForm />
        </section>
      </div>
      <AppFooter />
    </main>
  );
};

export default LoginPage;
```

* Tailwind クラスは A1 基本設計で定義されたトーン（やさしい・自然・控えめ、Apple カタログ風）を前提とする。
* `MagicLinkForm` 内部で、カードタイル UI の詳細な Tailwind クラスを実装する。

### 4.3 i18n との連携

* `app/layout.tsx` 側で StaticI18nProvider をルートに適用する前提とし、LoginPage では i18n Provider を再ラップしない。
* 文言リソースは A-01 / C-01 / C-04 各コンポーネント側の i18n キー定義に従う。

### 4.4 アクセシビリティ配慮

* `<main>` / `<header>` / `<footer>` のランドマーク要素を適切に使用することで、スクリーンリーダー利用者のナビゲーションを支援する。
* MagicLinkForm 内のカードタイルは、ボタン (`<button>`) 要素として実装されることを前提とし、LoginPage 側では追加の ARIA 属性を付与しない。

---

## 第5章 UI仕様（概要）

LoginPage 自体は UI レイアウトの骨組みのみを担当するため、本章では **A1 基本設計に対する整合性** を中心に記述する。カードタイルの詳細なスタイル・状態変化は A-01 の詳細設計書に委譲する。

### 5.1 レイアウト

* PC 幅

  * ヘッダーは画面上部に固定表示。
  * メイン領域中央に最大幅 `max-w-md` のフォーム領域を配置。
  * フッターは画面下部に配置。
* モバイル幅

  * 同じく縦一列構成だが、MagicLinkForm 内のカードタイルが縦並びになる（A1 基本設計準拠）。

### 5.2 トーン & スタイル

* 背景色は `bg-white` を基本とし、全体としてフラットで控えめなトーンとする。
* 余白は `px-4 py-8` 程度を基本とし、窮屈さを避ける。
* フォントは BIZ UD ゴシック相当（システムフォントで代替）を想定。

### 5.3 エラー / メッセージ表示位置

* メール入力エラー、MagicLink 送信結果、Passkey エラーなどのメッセージ表示位置は **すべて MagicLinkForm 内** に配置される。
* LoginPage 側ではメッセージ用の領域や状態は持たない。

### 5.4 レスポンシブ挙動

* 幅 768px 未満では、MagicLinkForm 内のカードタイルは縦並びになる仕様を前提とする。
* LoginPage は、単に中央のフォームコンテナを `max-w-md` でセンタリングする役割に限定する。

---

## 第6章 ロジック・状態設計

### 6.1 状態管理方針

* LoginPage は React の状態フック (`useState`, `useReducer` など) を使用しない。
* 認証フロー・フォーム入力値・ロード中フラグなどは、すべて MagicLinkForm (A-01) の内部状態として管理する。

### 6.2 イベントフロー

代表的なユーザー操作と、LoginPage 視点でのイベントフローは以下の通り。

1. ユーザーが `/login` にアクセスする。
2. LoginPage がレンダリングされ、AppHeader / MagicLinkForm / AppFooter が表示される。
3. ユーザーがメールアドレスを入力し、いずれかのカードタイルをタップする。
4. 以降のイベント処理（MagicLink 送信 or Passkey 認証開始）は MagicLinkForm / PasskeyAuthTrigger が処理する。
5. ログイン成功後の画面遷移は、A-01 / A-02 側の処理に従う。

LoginPage 自体は、3〜5 の処理にフックせず、**純粋に UI コンテナとして機能する**。

### 6.3 エラー処理ポリシー

* LoginPage ではエラー状態を保持しない。
* ネットワークエラー・Passkey OS エラーなどは A-01 / A-02 側で捕捉し、メッセージ表示を行う。

### 6.4 ログ出力方針

* LoginPage 単体でログ出力は行わない。
* 認証開始・成功・失敗などのログは、共通ログユーティリティを通じて A-01 / A-02 側で記録する（`harmonet-log-design_v1.1` を参照）。

---

## 第7章 テスト設計

### 7.1 単体テスト（Jest + React Testing Library）

LoginPage 単体では、以下の観点を Jest + RTL でテストする。

* `/login` レンダリング時に AppHeader / AppFooter / MagicLinkForm が揃って描画されること。
* i18n ロケールに応じて、MagicLinkForm 内のテキストが変化すること（スナップショットまたはキー存在確認）。

### 7.2 Storybook

* LoginPage は Storybook 上では **レイアウト確認用** として定義する。
* ストーリー例

  * `Default`（Locale = ja）
  * `LocaleEn`（Locale = en）
  * `Mobile`（Viewport を 375x812 程度に設定）

MagicLinkForm 内の状態別（Idle / Sending / Error / Success）は、A-01 の Storybook で詳細に定義する。

### 7.3 結合テスト

* `/login` → MagicLink 成功 → `/auth/callback` → `/mypage` の一連のフローは、E2E テスト（Playwright など）で定義する。
* `/login` → Passkey 成功 → `/mypage` も同様に E2E テストの対象とする。

LoginPage 詳細設計では、E2E のテストケース定義はスコープ外とし、フローの存在を明示するに留める。

---

## 第8章 メタ情報

### 8.1 用語定義

| 用語            | 定義                                                   |
| ------------- | ---------------------------------------------------- |
| LoginPage     | HarmoNet のログイン画面トップレベルコンポーネント (`app/login/page.tsx`) |
| MagicLinkForm | メール入力 + カードタイル UI を提供するフォームコンポーネント (A-01)            |
| Passkey       | WebAuthn / Corbado を利用したパスワードレス認証方式                  |
| カードタイル        | アイコン + テキストで構成される、角丸ボタン風の UI 要素                      |

### 8.2 関連資料

* HarmoNet 基本設計書（A1）- ログイン画面 v1.0
* MagicLinkForm 詳細設計書 (A-01) v1.1 以降
* PasskeyAuthTrigger 詳細設計書 (A-02) v1.1 以降
* harmonet-technical-stack-definition_v4.2.md
* harmonet-frontend-directory-guideline_v1.0.md
* HarmoNet_Passkey認証の仕組みと挙動_v1.0.md
* harmonet-log-design_v1.1.md

### 8.3 ChangeLog

| Version | Date       | Author    | Summary                                                                          |
| ------- | ---------- | --------- | -------------------------------------------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版作成（MagicLinkForm + PasskeyButton 二重構成）                                         |
| 1.1     | 2025-11-14 | Tachikoma | MagicLinkForm 内の Passkey ロジック統合に合わせて依存関係・構造を修正。App Router構成と Passkey挙動ドキュメントに整合。 |
| 1.2     | 2025-11-15 | Tachikoma | A1 基本設計（カードタイル UI）に合わせて、機能要約・UT 観点・構造記述を更新。MagicLinkForm が 2 枚のカードタイルを提供する前提に統一。 |

### 8.4 Reviewer / Author / Last Updated

| 項目           | 内容                  |
| ------------ | ------------------- |
| Reviewer     | TKD                 |
| Author       | Tachikoma (GPT Pro) |
| Last Updated | 2025-11-15          |

---

**End of Document**
