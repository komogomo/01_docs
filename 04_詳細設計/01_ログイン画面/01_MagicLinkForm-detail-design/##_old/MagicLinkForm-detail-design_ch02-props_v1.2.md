# MagicLinkForm 詳細設計書 - 第2章：Props / State 定義（v1.2）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH02
**Version:** 1.2
**Supersedes:** v1.1
**Updated:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink 専用カードタイル方式 / 技術スタック v4.3 整合版

---

## 第2章 Props / State 定義

本章では **A-01 MagicLinkForm** の UI・ロジックを構成するために必要な Props / State / エラー型を定義する。
本コンポーネントは **MagicLink（メール OTP 認証）専用**であり、Passkey に関する Props・State は一切保持しない。認証方式の選択は行わず、MagicLink のみを確実に実行するための最小構成とする。

---

## 2.1 Props 定義

MagicLinkForm は LoginPage（A-00）内で自己完結し、外部へ通知するための必要最小限の Props のみを持つ。

```ts
export interface MagicLinkFormProps {
  /** レイアウト調整用の追加クラス（任意） */
  className?: string;

  /** MagicLink 送信が完了した際に親へ通知 */
  onSent?: () => void;

  /** 認証・バリデーション・通信エラー発生時の通知 */
  onError?: (error: MagicLinkError) => void;

  /** test用ID（任意） */
  testId?: string;
}
```

### Props 方針

* **責務分離の徹底**：MagicLinkForm は MagicLink のみを扱うため、`passkeyEnabled` 等の旧 Props は削除済み。
* **外部通知は「成功」または「エラー」のみ**に絞り、内部状態や UI 制御は外部へ漏らさない。
* **UI カスタマイズは className のみに限定**し、Tailwind トークン構成を崩さない。

---

## 2.2 State 定義

MagicLinkForm が内部で管理する状態を以下に定義する。

```ts
type MagicLinkFormState =
  | 'idle'           // 初期状態
  | 'sending'        // MagicLink 送信中
  | 'sent'           // MagicLink 送信成功
  | 'error_input'    // メール形式不正
  | 'error_network'  // 通信障害（Supabase unreachable 等）
  | 'error_auth'     // Supabase 認証エラー
  | 'error_unexpected'; // その他例外
```

### State 方針

* **MagicLink ログインに必要な状態のみを保持**し、Passkey 認証状態は一切持たない。
* 状態とメッセージ（i18n キー）は 1 対 1 対応し、Windsurf が迷わない構造にする。
* UI の表示条件（ボタン disable / メッセージ表示）は state ベースで統一。

---

## 2.3 Error 構造

MagicLinkForm が外部へ通知するエラー型を定義する。

```ts
export interface MagicLinkError {
  code: string;            // Supabase error.code など
  message: string;         // i18n 済みメッセージ
  type: MagicLinkFormState; // 状態分類と一致（error_*）
}
```

### エラー分類の基準

| 種類               | 発生要因           | 例                   | 備考        |
| ---------------- | -------------- | ------------------- | --------- |
| error_input      | メール形式不正        | 空文字 / 不正Email       | Inline 表示 |
| error_network    | 通信断            | fetch例外             | Banner表示  |
| error_auth       | Supabase 認証エラー | invalid_credentials | Banner表示  |
| error_unexpected | 想定外例外          | JS例外                | Banner表示  |

※ Passkey に起因するエラーは A-02 PasskeyAuthTrigger 側で扱うため、本コンポーネントでは発生しない。

---

## 2.4 入力・イベント定義

MagicLinkForm が扱うイベントは以下の 2 種類のみとする。

### 2.4.1 メール入力

```ts
const [email, setEmail] = useState("");
```

* 形式チェックは `/.*@.*\..*/` の簡易バリデーション。
* 入力変更時は error_input 状態をリセット。

### 2.4.2 ログインボタン押下

```ts
const handleSubmit = async () => {
  // validate → sending → Supabase → sent / error_*
}
```

* `logInfo('auth.login.start')` を送信前に記録。
* 成功時：`sent` → onSent()
* エラー時：分類して onError(error)

---

## 2.5 依存関係（明示）

| 種別   | 依存先                     | 用途              |
| ---- | ----------------------- | --------------- |
| 認証   | Supabase JS SDK         | signInWithOtp() |
| i18n | StaticI18nProvider      | t(key) 取得       |
| UI   | TailwindCSS / shadcn/ui | ボタン・入力のレンダリング   |
| ログ   | 共通ログユーティリティ             | auth.login.* 出力 |

※ Corbado / Passkey SDK への依存は一切保持しない。

---

## 2.6 UT観点（Props / State 検証軸）

| 観点ID      | 観点         | 期待結果                             |
| --------- | ---------- | -------------------------------- |
| UT-A01-01 | 初期状態       | state=idle、入力空、エラーなし             |
| UT-A01-02 | 入力不正       | state=error_input、Inline メッセージ表示 |
| UT-A01-03 | Supabase成功 | state=sent、onSent() 呼び出し         |
| UT-A01-04 | 通信断        | state=error_network、Banner表示     |
| UT-A01-05 | 認証エラー      | state=error_auth、Banner表示        |
| UT-A01-06 | 想定外エラー     | state=error_unexpected、Banner表示  |
| UT-A01-07 | 言語切替       | 各メッセージが t(key) で即時反映             |

---

**End of Document**
