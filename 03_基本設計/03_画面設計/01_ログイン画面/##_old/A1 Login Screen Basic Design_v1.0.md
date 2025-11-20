# HarmoNet 基本設計書（A1）- ログイン画面

**格納パス（想定）:** `D:\AIDriven\01_docs\03_基本設計\03_画面設計\01_ログイン画面`

---

# 1. 目的（Purpose）

ログイン画面の構造・UI・操作方式（MagicLink / Passkey）の基本要件を定義し、詳細設計に進むための基盤とする。この画面は HarmoNet の最初の接点であり、簡潔・安全・誤操作のない UI を提供することを目的とする。
本画面は認証ロジックの詳細を持たず、実処理は後続の A-01（MagicLinkForm）および A-02（PasskeyAuthTrigger）へ委譲する。

---

# 2. 前提条件（Prerequisites）

技術スタック・ライブラリ・構成要素については、**「harmonet-technical-stack-definition」** を参照する。本書には技術スタックの内容・バージョンを直接記載しない。

依存コンポーネント：

* MagicLinkForm（A-01）
* PasskeyAuthTrigger（A-02）
* StaticI18nProvider
* AppHeader / AppFooter

---

# 3. 画面全体概要（Overview）

本画面は以下の構造で構成される。

* ログインタイトル / サブ説明文
* メールアドレス入力欄
* **左右配置のカードタイル型ログインボタン（MagicLink / Passkey）**
* フッター部説明文

スマートフォンを最優先としたレイアウトで、視認性と誤タップ防止を重視する。

---

# 4. 機能概要（Functional Summary）

本画面が提供する主要機能は次の通り。

* MagicLink ログイン（メール入力 → ログイン）
* Passkey ログイン（OSによる自動認証 → セッション確立）
* 多言語切替（StaticI18nProvider）

認証処理そのものは後続コンポーネントへ委譲し、本画面は操作選択 UI を提供するに留める。

---

# 5. UI構造（UI Structure）

### 5.1 メール入力欄

* 単一行の email テキストフィールド。
* バリデーション・エラー表示は A-01 にて定義。

### 5.2 カードタイル型ログインボタン

配置：**左右に2枚のカードとして並べる（スマホ幅が狭い場合は縦並びにフォールバック）**。

内容：

```
📩  ログイン   （メール）
🔐  ログイン   （Passkey）
```

* アイコン左、テキスト右の横並び構成（案B）。
* 文言は「ログイン」のみ。助詞は使用しない。
* アイコンは 28px 前後、控えめな配色。

---

# 6. レイアウト・スタイル仕様（Layout / Style）

* カードタイルは **rounded-2xl**
* shadow は最小限（`shadow-[0_1px_2px_rgba(0,0,0,0.06)]`）
* 高さ：80〜92px 程度
* 横幅：grid-cols-2 基準（gap 12〜16px）
* テキスト：`font-medium text-base`
* アイコンは控えめに、色は gray ベース

レスポンシブ条件：横並び → スマホ最小幅で縦積みへ自動移行。

---

# 7. 認証方式選択 UX（MagicLink / Passkey）

* MagicLink と Passkey を **視覚的に“対等”なカード** として提示する。
* OS エラー（Passkey 未登録 / キャンセル）は OS に委譲し、本画面では自然に MagicLink に戻れる導線を確保する。
* 誤タップを避けるため、タップ領域は十分な高さを持つカード形式とする。

---

# 8. 決定木（Decision Tree）

MagicLink：

```
メールアドレス入力 → ログインタイルタップ → メール送信 → 完了 → /auth/callback
```

Passkey：

```
Passkeyタイル選択 → OS 認証UI → サイン成功 → /auth/callback
```

エラー時の詳細挙動は A-01 / A-02 にて定義する。

---

# 9. メッセージ出力仕様（正常系 / 異常系）

本章では概要のみ定義し、具体的メッセージ文言・i18nキー・表示条件は詳細設計書で定義する。

## 正常系（例）

* MagicLink 送信完了メッセージ
* Passkey ログイン成功時は原則メッセージを挟まない（即遷移）

## 異常系（例）

* MagicLink 送信エラー
* Passkey の OS エラー（キャンセル、NotAllowedError 等）
* 通信エラー

表示位置の基本方針、表示時間、i18n化ポリシーの概要を本章で示す。

---

# 10. 状態遷移（State Transition）

本画面で想定される状態の概要を示す。

```
idle → input → submitting → success → redirect
```

※ バリデーションロジック・API詳細は **詳細設計書（LoginPage 詳細設計）** にて定義する。

---

# 11. 非機能要件（NFR）

* スマホでの誤タップ防止（十分なタップ領域）
* 1秒以内の画面応答
* 視認性の高い配色
* 読み上げ機能は不要（ログイン画面の対象外）

---

# 12. 参照資料（References）

* harmoNet-technical-stack-definition
* MagicLinkForm（A-01）
* PasskeyAuthTrigger（A-02）
* Passkey挙動仕様書

※ 下位詳細設計書を参照リストには含めない。

---

# 13. 改訂履歴（ChangeLog）

* v1.0: 初版作成（UIタイル配置、文言簡素化、メッセージ仕様明確化）
