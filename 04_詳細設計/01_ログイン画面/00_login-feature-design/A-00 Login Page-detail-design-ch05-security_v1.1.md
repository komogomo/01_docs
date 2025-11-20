# A-00 LoginPage 詳細設計書 ch05：セキュリティ設計

**Document ID:** HARMONET-A00-CH05-SECURITY**
**Version:** 1.1
**Supersedes:** v1.0
**Status:** MagicLink専用・実装準拠

---

# 第1章：概要

本章では、**A-00 LoginPage に関係するセキュリティ要件（UI観点）** を定義する。
LoginPage は MagicLink 認証画面のレイアウト担当であり、**認証ロジック・セッション管理・暗号処理は保持しない**。
セキュリティ責務は下位レイヤ（A-01 MagicLinkForm / A-03 AuthCallbackHandler / Supabase Auth）が担う。

---

# 第2章：対象範囲（LoginPage の責務に限定）

| 領域            | LoginPage の扱い    | 備考                |
| ------------- | ---------------- | ----------------- |
| 認証（MagicLink） | UI配置・メッセージ表示のみ   | ロジックは A-01        |
| セッション         | 不保持（判定しない）       | A-03 / Supabase   |
| Cookie / JWT  | 不参照・不処理          | セキュリティ境界を保持       |
| エラー処理         | A-01 から渡された文言を表示 | 分類は A-01          |
| 通信保護          | UI レベルで HTTPS 前提 | 実処理はブラウザ＋Supabase |

---

# 第3章：脅威モデル（MagicLink画面に関係する部分）

LoginPage が直接関与する脅威のみを扱う。

| 脅威       | 内容              | LoginPage の対策                    |
| -------- | --------------- | -------------------------------- |
| XSS      | 文言挿入・スクリプト混入    | すべての文言は StaticI18nProvider、直書き禁止 |
| 認証情報露出   | メールアドレス表示・ログ漏えい | プレーン表示禁止、ログは A-01 側でマスキング        |
| フィッシング誘導 | 画面偽装・外部リンク誤誘導   | 外部リンク不使用、白基調 UI の統一              |
| 誤操作      | ローディング中の多重クリック  | A-01 側で disabled 管理              |
| HTTP利用   | HTTPS でないアクセス   | Vercel 側の強制 HTTPS 前提             |

---

# 第4章：防御設計（LoginPage が担う領域）

LoginPage が行う防御は **UIレイヤの最小限** に限定される。

## 4.1 UI/文言安全設計

* 文言は StaticI18nProvider から取得（XSS防止）
* `dangerouslySetInnerHTML` 禁止
* 外部スクリプト・外部CDNロード禁止

## 4.2 フォーム操作安全性

* ログインボタン多重押下防止（A-01 側で管理）
* 入力検証はすべて A-01 の `validateEmail()` が担当
* LoginPage はフォームのプレーン表示のみ

## 4.3 画面遷移安全性

* `/auth/callback` / `/mypage` への遷移は **A-03 が担当**
* LoginPage に `router.push()` を置かない（誤遷移防止）

---

# 第5章：セキュリティ非対象（A-00 の責務外）

LoginPage が扱わない領域を明確化する。
これにより責務境界を固定し Windsurf の誤実装を防ぐ。

| 領域              | 担当                        | 理由                  |
| --------------- | ------------------------- | ------------------- |
| MagicLink OTP発行 | A-01（MagicLinkForm）       | Supabase Auth 処理のため |
| セッション確立（PKCE）   | A-03（AuthCallbackHandler） | LoginPage は UI だけ扱う |
| Supabase JWT検証  | サーバ層 / Supabase           | クライアントでは扱わない        |
| Cookie管理        | ブラウザ + Supabase           | セキュリティ上の境界外         |
| RLS判定           | Supabase                  | DBレイヤの責務            |

---

# 第6章：画面レベル セキュリティ仕様

## 6.1 DOM/HTML

* `<section aria-labelledby="login-title">` により意味づけ保持
* Title は `<h1>`、安全なテキストノードのみ使用
* Form 内の input は type="email" のみ

## 6.2 レイアウト

* 白基調背景で UI 偽装の余地を減らす
* ボタン・入力欄は標準スタイル（Tailwind のみ）でカスタムJS無し

## 6.3 アクセシビリティ

* 状態メッセージは `aria-live="polite"`
* カード領域は keyboard focus の妨げをしない

---

# 第7章：エラー表示の方針（画面レベル）

LoginPage は **エラー分類しない**。
分類は A-01 が決定し、LoginPage はそのメッセージを受け取って表示する。

| 状態               | LoginPage の表示                 |
| ---------------- | ----------------------------- |
| sent             | 成功文言（login.status.success）    |
| error_input      | login.status.error（A-01 詳細文言） |
| error_network    | 同上                            |
| error_auth       | 同上                            |
| error_unexpected | 同上                            |

※ 技術的詳細（HTTPコード、Supabase例外）は LoginPage に露出しない。

---

# 第8章：禁止事項（セキュリティ観点）

LoginPage では以下の実装を禁止する：

* Cookie 読み取り (`document.cookie`)
* Supabase SDK の直接呼び出し
* 認証成功/失敗の判定
* Passkey / WebAuthn の記述追加
* 外部 script / iframe / 埋め込み要素

---

# 第9章：Windsurf 実装指針

* LoginPage は UI レイアウトに限定し、**ロジック追加禁止**
* A-01 / A-03 を変更しない（別タスク）
* i18n キーは LoginPage 用（login.*）のみ使用

---

# 第10章：改訂履歴

| Version | Summary                                                  |
| ------- | -------------------------------------------------------- |
| v1.1    | Passkey/Corbado/WebAuthn記述を全削除。MagicLink専用のセキュリティ仕様に再構築。 |
| v1.0    | 旧仕様（MagicLink + Passkey混在）。                              |

---

**End of Document**
