# MagicLinkForm 詳細設計書 — 第2章：Props / State 定義

本章では MagicLinkForm（A-01）の実装方式について記載する。

---

## 2.1 Props 定義

MagicLinkForm は LoginPage 内で完結するフォームとして動作する。
外部との連携は不要であるため、Props は最小構成とする。

```ts
export interface MagicLinkFormProps {
  /** レイアウト調整用（任意） */
  className?: string;

  /** テスト識別子（任意） */
  testId?: string;
}
```

**方針**

* 外部へ状態を通知する Props（onSent / onError）は使用しない。
* UI カスタマイズは className のみ許可する。

---

## 2.2 State 定義

MagicLinkForm が内部で保持する状態は以下の通り。

```ts
type MagicLinkFormState =
  | 'idle'            // 初期状態
  | 'sending'         // 送信処理中
  | 'sent'            // 送信完了
  | 'error_input'     // 入力形式エラー
  | 'error_network'   // 通信エラー
  | 'error_auth'      // 認証エラー
  | 'error_unexpected'; // その他例外
```

**方針**

* MagicLink の送信に必要な状態のみを保持する。
* UI の表示条件は state に基づいて統一的に制御する。

---

## 2.3 ローカル変数

```ts
const [email, setEmail] = useState("");
const [state, setState] = useState<MagicLinkFormState>('idle');
const [error, setError] = useState<MagicLinkError | null>(null);
```

---

## 2.4 エラー構造

MagicLinkForm 内で発生したエラーは統一された構造で保持する。

```ts
export interface MagicLinkError {
  code: string;       // Supabase error.code または内部分類コード
  message: string;    // i18n 済みメッセージ
  type: MagicLinkFormState; // error_* のいずれか
}
```

**分類基準**

| 種別               | 判定条件           |
| ---------------- | -------------- |
| error_input      | メール形式不正        |
| error_network    | fetch例外 / 通信断  |
| error_auth       | Supabase 認証エラー |
| error_unexpected | 上記に該当しない例外     |

---

## 2.5 イベント定義

MagicLinkForm が扱うイベントは次の 2 つのみ。

### 2.5.1 メール入力

```ts
onChange={(e) => setEmail(e.target.value)}
```

* 入力中に error_input は解除される。

### 2.5.2 MagicLink送信

```ts
const handleSubmit = async () => {
  // validate → sending → Supabase → sent / error_*
};
```

---

## 2.6 依存関係

| 種別   | 利用先                            |
| ---- | ------------------------------ |
| 認証   | Supabase JS SDK（signInWithOtp） |
| i18n | StaticI18nProvider（t()）        |
| UI   | TailwindCSS                    |
| ログ   | 共通ログユーティリティ                    |

---

## 2.7 UT 観点（Props / State 単位）

| 観点ID      | 条件     | 期待結果                      |
| --------- | ------ | ------------------------- |
| UT-A01-01 | 初期表示   | state=idle、email=""、エラーなし |
| UT-A01-02 | 不正形式入力 | error_input、Inlineエラー表示   |
| UT-A01-03 | 正常送信   | state=sent、成功メッセージ表示      |
| UT-A01-04 | 通信断    | error_network、バナー表示       |
| UT-A01-05 | 認証エラー  | error_auth、バナー表示          |
| UT-A01-06 | 想定外例外  | error_unexpected、バナー表示    |
| UT-A01-07 | ロケール切替 | t() による文言即時更新             |

---

**End of Document**
