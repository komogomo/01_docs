# HarmoNet 基本設計書 - PasskeyAuthTrigger (A-02) v1.0

---

## 0. ドキュメント情報

* 文書名: HarmoNet 基本設計書 - PasskeyAuthTrigger (A-02)
* Document ID: HARMONET-BASIC-A02-PASSKEYAUTHTRIGGER
* Version: v1.0
* Status: Draft（TKD レビュー前）
* 対象システム: HarmoNet（マルチテナント型コミュニティ OS）
* 対象コンポーネント:

  * A-02 PasskeyAuthTrigger

    * Passkey ログイン用カードタイル＋ボタン UI
    * Corbado / Supabase 連携ロジック
  * A-01 MagicLinkForm（A-02 の表示・併用条件を制御するオーケストレータ）
* 作成日: 2025-11-15
* 作成者: Tachikoma
* レビュー: TKD

---

## 1. 目的・背景

### 1.1 目的

本書の目的は、HarmoNet における **Passkey ログイン機能（A-02 PasskeyAuthTrigger）** の基本設計を定義することである。

PasskeyAuthTrigger は、

* ログイン画面内に「Passkey でログイン」用のカードタイル＋ボタン UI を提供し、
* ボタン押下をきっかけに Corbado Web SDK / Supabase Auth を使った Passkey 認証フローを実行し、
* 成功／失敗／ユーザー拒否などの結果を MagicLinkForm (A-01) と共有する

ためのコンポーネントとして設計する。

### 1.2 背景

* HarmoNet のログイン画面は、基本のログイン方法として MagicLink（メール認証）を提供しつつ、
  **視覚的にわかりやすい「Passkey ログイン用カードタイル」** を並べて、
  「端末登録済みの人はこっちから入れる」と示すレイアウトを採用している。
* Passkey は MagicLink よりも強い保護を提供するが、対応端末・ブラウザなどの制約もある。
* そのため、PasskeyAuthTrigger には次の役割が求められる。

  * UI 上で「Passkey でログイン」の入口を明示する（カードタイル＋ボタン）
  * 押下時に Passkey 認証フローを実行し、結果を MagicLinkForm／ログイン全体と整合を取って扱う
  * Passkey が利用できない場合の挙動（非表示／無効化／メッセージ）を制御できるようにする

---

## 2. 対象範囲と非対象

### 2.1 対象範囲

本基本設計書で扱う対象は次の通り。

* `/login` 画面における Passkey ログイン用カードタイル＋ボタン UI
* Passkey ログインの開始トリガ（ボタン押下）から、結果が返るまでのフロントエンド処理
* Corbado Web SDK・Supabase Auth との連携方針（概念レベル）
* エラー分類（例: `error_network` / `error_denied` / `error_origin` / `error_auth`）の意味付け
* MagicLinkForm / LoginPage 全体との役割分担

### 2.2 非対象

以下は本書の対象外とし、別ドキュメントで扱う。

* MagicLink 認証（メールリンク送信）フローの詳細（A-01 MagicLinkForm の責務）
* `/auth/callback` 以降のトークン検証・画面遷移（将来の A-03 AuthCallbackHandler の責務）
* Supabase / Corbado のサーバ側内部実装

---

## 3. 業務要件・ユースケース

### 3.1 想定ユーザー

* Passkey を登録済みの居住者／管理者
* スマホ・PC いずれからも、端末側に登録された認証情報を利用してログインするユーザー

### 3.2 代表ユースケース

#### UC-01: Passkey カードタイルからのログイン

1. ユーザーが `/login` を表示する。
2. 画面中央付近に MagicLink フォーム、その隣または下に「Passkey でログイン」カードタイルが表示される。
3. ユーザーが Passkey カードタイルのボタンを押下する。
4. PasskeyAuthTrigger が Corbado Web SDK を用いて Passkey 認証を開始する。
5. 認証が成功すると、Supabase Auth にログイン要求が行われ、セッションが確立される。
6. ログイン完了後、AuthCallbackHandler などの後続処理に引き渡される。

#### UC-02: Passkey ダイアログをユーザーがキャンセルする

1. UC-01 と同様に Passkey カードタイルからログインを開始する。
2. ブラウザの認証ダイアログ（顔認証・指紋認証など）でユーザーが「キャンセル」を選択する。
3. PasskeyAuthTrigger は、この結果を `error_denied` として扱い、MagicLinkForm／画面側に通知する。
4. 画面側は、設計方針に従い、

   * そのまま何もせずログイン前状態に戻す
   * MagicLink の利用を案内する（「メールアドレスでログインできます」など）
     などの挙動を行う。

#### UC-03: Passkey が技術的理由で利用できない

1. Passkey カードタイルのボタンを押下する。
2. 対応していないブラウザ／Origin ミスマッチ／ネットワーク障害などにより、Passkey 認証が実行できない。
3. PasskeyAuthTrigger はエラー内容を分類し、

   * `error_network`
   * `error_origin`
   * `error_auth`
     のいずれかとして扱う。
4. 画面側は、種別に応じてメッセージ表示や MagicLink 利用の提案を行う。

PasskeyAuthTrigger 自体は画面全体を管理せず、**Passkey ログイン用カードタイル＋ボタンと、その裏側の認証処理**を担当するコンポーネントとして振る舞う。

---

## 4. 機能要件（基本設計レベル）

### 4.1 コンポーネントの役割

#### A-02 PasskeyAuthTrigger

* UI:

  * ログイン画面の中に配置される「Passkey ログイン用カードタイル」を構成する。
  * カード内にアイコン・タイトル・説明テキスト・「Passkey でログイン」ボタンを含む。
* ロジック:

  * ボタン押下をきっかけに、Passkey 認証処理を開始する。
  * 認証成功時、Supabase Auth にログイン要求を行い、その結果を呼び出し側に返す。
  * 認証失敗／キャンセルなどの結果を、種別付きで呼び出し側に返す。

#### A-01 MagicLinkForm との関係

* MagicLinkForm は、以下を担当する。

  * `/login` 内でのレイアウトにおける A-02 の配置（カードの上下・左右など）
  * Passkey カードタイルを表示するかどうかの条件（ブラウザ・端末・設定など）
  * Passkey 成功／失敗時の状態遷移やメッセージ表示
* PasskeyAuthTrigger 自身は「UI付きの認証手段の 1 つ」として動作し、
  MagicLinkForm と協調してログイン画面の UX を構成する。

### 4.2 入出力（概念）

PasskeyAuthTrigger のインタフェースは、概念的に次の情報を扱う。

**入力（例）**

```ts
interface PasskeyAuthTriggerProps {
  disabled?: boolean;                 // 利用不可時にカード・ボタンを無効化するためのフラグ
  onSuccess?: () => void;             // 認証成功時のコールバック
  onError?: (error: PasskeyAuthError) => void; // 認証失敗時のコールバック
}
```

* `disabled` は、ブラウザ非対応・設定で無効などの条件でカードタイルごと無効化するために利用する。
* `onSuccess` / `onError` は、MagicLinkForm や LoginPage がログイン全体の状態を管理するために利用する。

**出力（エラー型のイメージ）**

```ts
type PasskeyAuthErrorType =
  | 'error_network'
  | 'error_denied'
  | 'error_origin'
  | 'error_auth';

interface PasskeyAuthError {
  type: PasskeyAuthErrorType;
  code: string;    // 内部識別用
  message: string; // 表示用メッセージ（i18n 済み想定）
}
```

### 4.3 エラー分類の意味付け

* `error_network`

  * 通信エラー、Corbado/Supabase への到達不能など。
* `error_denied`

  * ユーザーがブラウザの認証ダイアログをキャンセルした場合。
* `error_origin`

  * WebAuthn の Origin 不一致など、前提条件が満たされない場合。
* `error_auth`

  * 上記以外の Passkey 認証エラー（Corbado からの汎用エラーなど）。

これらは MagicLink 側のエラー分類と意味を揃えて扱う。

---

## 5. UX 方針（Passkey カードタイル）

### 5.1 画面内での位置づけ

* `/login` 画面中央に MagicLink フォーム、その近くに Passkey カードタイルを配置する。
* カードタイルは、「別のログイン手段」ではなく「推奨されるセキュアな手段」として認識されるように、
  MagicLink フォームに対して過度に主張しないトーンで配置する。

### 5.2 カードタイルの構成イメージ

* アイコン: 鍵アイコンなど、Passkey を想起しやすいもの。
* タイトル: 「Passkey でログイン」など。
* 説明文: 「この端末の顔認証・指紋認証でログインできます」程度の短い説明。
* ボタン: 「Passkey を使う」などのラベルで、タップしやすいサイズ（高さの目安は 44〜48px 程度）。

### 5.3 操作感

* カードタイル全体、またはボタンのみが押下対象となる（詳細は詳細設計側で定義）。
* 押下後は、Passkey 認証ダイアログが表示され、ユーザーは端末側の操作でログインを完了する。
* 認証中は、ボタンを再押下できないようにするなど、重複操作を防ぐ。
* エラーやキャンセル発生時は、MagicLink を案内するなど、次のアクションが理解しやすいメッセージとする。

---

## 6. 外部インターフェース（概要）

### 6.1 Corbado Web SDK との連携

* PasskeyAuthTrigger は Corbado Web SDK を利用して Passkey 認証を開始する。
* 成功時には ID トークン等を受け取り、Supabase Auth へのログインに利用する。
* 失敗時にはエラー内容を解釈し、前述の `PasskeyAuthErrorType` に分類する。

### 6.2 Supabase Auth との連携

* Corbado から取得したトークンを Supabase Auth に渡し、ログインを行う。
* Supabase 側でセッションが確立されたかどうかを確認し、成功／失敗を呼び出し元に返す。

### 6.3 i18n とメッセージ

* ボタンラベル・説明文・エラーメッセージは StaticI18nProvider を通じて取得する。
* メッセージキーは `login.passkey.*` のように、MagicLink 側と同じ名前空間で整理する。

---

## 7. セキュリティ・非機能（Passkey 関連）

### 7.1 セキュリティ

* Passkey 認証は HTTPS・適切な Origin を前提とする。
* トークン等は Supabase Auth へのログインに利用した後は保持しない。
* ログ出力時には、トークンや生体情報などの秘匿情報を記録しない。

### 7.2 可用性

* Passkey が利用できない環境では、カードタイルを非表示にするか無効化し、MagicLink のみでログインできるようにする。
* Passkey 認証の失敗が続く場合でも、MagicLink によるログイン手段が常に残っている状態とする。

---

## 8. ログ出力方針（Passkey 関連）

* Passkey に関するログは、ログインフローの把握と不具合調査に必要な最低限にとどめる。
* 想定するイベント例:

  * `auth.login.passkey.start` — Passkey ログイン開始
  * `auth.login.passkey.success` — Passkey ログイン成功
  * `auth.login.passkey.error` — Passkey ログイン失敗（`error_type` をメタとして付与）

個人特定につながる情報は最小限とし、詳細なログ形式は共通ロガー設計に従う。

---

## 9. MagicLinkForm / LoginPage との関係

* LoginPage (A-00)

  * 画面全体レイアウトを管理し、MagicLinkForm と PasskeyAuthTrigger カードタイルを配置する。
* MagicLinkForm (A-01)

  * ログイン画面の中心フォームとしてメールログインを提供しつつ、PasskeyAuthTrigger の結果に応じて状態を更新する。
* PasskeyAuthTrigger (A-02)

  * Passkey ログイン入口（カードタイル）と、その裏側の認証処理を担当する。

---

## 10. 今後の検討事項

* テナント単位での Passkey 利用方針（必須／任意／無効）をどのレイヤで制御するか。
* Passkey カードタイルを、どの程度目立たせるか（MagicLink とのバランス）。
* 「この端末に Passkey が登録されていない場合」の案内文や遷移先（マイページなどから登録するのか等）。

---

## 11. 改訂履歴

| Version | Date       | Summary                            |
| ------- | ---------- | ---------------------------------- |
| 1.0     | 2025-11-15 | 初版作成。Passkey ログイン用カード＋ロジックの基本設計を定義 |
