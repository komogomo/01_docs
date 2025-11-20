# MagicLinkForm 詳細設計書 v1.4

---

## 第1章 概要

MagicLinkForm（A-01）は HarmoNet ログイン画面における **MagicLink（Supabase OTP メール認証）専用フォームコンポーネント**。
本コンポーネントは **唯一のログイン方式となり、UI/ロジックを提供する。

**主な責務**：

* メールアドレス入力欄の提供
* MagicLink送信（signInWithOtp）
* 状態管理（idle / sending / sent / error_*）
* エラーメッセージ表示
* 共通ログユーティリティによるログ出力

---

## 第2章 機能設計

### 2.1 機能要約

MagicLinkForm は以下を行う：

1. メール形式チェック
2. Supabase `signInWithOtp` による OTP 認証開始
3. 成功時メッセージ表示
4. 通信/認証/想定外エラーの分類と表示

### 2.2 Props（最新版）

```ts
export interface MagicLinkFormProps {
  className?: string;
  testId?: string;
}
```

### 2.3 State

```
'idle' | 'sending' | 'sent'
'error_input' | 'error_network' | 'error_auth' | 'error_unexpected'
```

### 2.4 入出力

* 入力：email（文字列）
* 出力：UI表示のみ（外部コールバックなし）
* 副作用：MagicLink送信、ログ出力のみ

---

## 第3章 構造設計

### 3.1 ディレクトリ

```
src/components/auth/MagicLinkForm/
```

### 3.2 ファイル構成

* MagicLinkForm.tsx
* MagicLinkForm.types.ts
* MagicLinkForm.test.tsx
* MagicLinkForm.stories.tsx

### 3.3 依存関係

* Supabase JS SDK v2.43
* StaticI18nProvider
* 共通ログユーティリティ
* TailwindCSS（Appleカタログ風UIトーン）

---

## 第4章 実装設計

### 4.1 MagicLink送信フロー

```
validateEmail → NGなら error_input
↓
signInWithOtp({ shouldCreateUser:false, emailRedirectTo:'/auth/callback' })
↓
成功 → sent / 失敗 → error_*
```

### 4.2 handleSubmit（概要）

```
1) validateEmail
2) state='sending'
3) signInWithOtp
4) 成功→ state='sent'
5) 失敗→ mapError
```

### 4.3 エラー分類

* error_input：形式不正
* error_network：通信例外 / fetch失敗
* error_auth：Supabase認証エラー（error.codeあり）
* error_unexpected：上記以外

### 4.4 ログ仕様

* 開始：`auth.login.start`
* 成功：`auth.login.success.magiclink`
* 失敗：`auth.login.fail.*`

---

## 第5章 UI仕様

### 5.1 カードスタイル

* rounded-2xl
* shadow-sm
* bg-white
* gap-3 / p-4
* シンプル・静か・控えめ（HarmoNet UIトーン）

### 5.2 状態別 UI

* sending：ボタン disabled + Loader2
* sent：成功メッセージ
* error_input：Inlineエラー
* error_network / error_auth / error_unexpected：赤バナー

### 5.3 メイン構造

* タイトル（メールでログイン）
* 説明文
* メール入力欄
* ログインボタン
* メッセージ領域

---

## 第6章 ロジック仕様

### 6.1 状態遷移

```
idle → sending → sent
sending → error_input | error_network | error_auth | error_unexpected
```

### 6.2 mapError

* Supabase error.code あり → error_auth
* fetch例外 → error_network
* JS例外 → error_unexpected

---

## 第7章 結合・運用

### 結合ポイント

* LoginPage (A-00) に単独カードとして配置
* /auth/callback は AuthCallbackHandler が担当
* 認可（ユーザマスタ / テナント判定）は /home Server Component 側で実施

MagicLinkForm は「送信」だけを担当し、ログイン後の状態判定は **一切行わない**。

---

## 第8章 メタ情報

### 8.1 i18n キー

```
auth.login.magiclink.title
auth.login.magiclink.description
auth.login.magiclink.button_login
auth.login.magiclink.button_sending
auth.login.magiclink_sent
auth.login.error.email_invalid
auth.login.error.network
auth.login.error.auth
auth.login.error.unexpected
```

### 8.2 Version

v1.4（2025-11-19）

---

# ChangeLog

* **v1.4**：Passkey記述完全削除。MagicLink単独方式へ再構成。Props簡素化。UI/ロジック/i18n/ログを最新技術スタック v4.4 に完全整合。
