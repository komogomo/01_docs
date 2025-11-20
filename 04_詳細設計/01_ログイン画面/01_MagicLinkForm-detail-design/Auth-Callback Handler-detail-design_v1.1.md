# AuthCallbackHandler 詳細設計書 — 第1章：概要

本章では AuthCallbackHandler（A-03）の実装方式について記載する。

---

## 1.1 目的

AuthCallbackHandler は、MagicLink 認証後に遷移する `/auth/callback` において、
**認証済みユーザーの認可判定を行い、適切な画面へ遷移させるコンポーネント** である。

本コンポーネントは以下を担う：

* Supabase セッション取得
* ユーザマスタ（users）の存在確認
* user_tenants の紐付け確認
* 認可成功時のアプリ内部への遷移
* 認可失敗時のセッション破棄とログイン画面への戻り

UI 表示は最小限とし、ページ遷移制御を主目的とする。

---

## 1.2 スコープ

本設計書が対象とする範囲：

**対象コンポーネント**

* `/auth/callback` ページ
* AuthCallbackHandler（A-03）単体

**本コンポーネントが行うこと**

* Supabase セッションの確認
* users テーブルでの対象ユーザーの取得
* user_tenants での有効テナント確認
* 認可成功時の `/home` への遷移
* 認可失敗時の `/login?error=unauthorized` への遷移

**対象外（別設計書）**

* MagicLinkForm（A-01）の送信処理
* LoginPage（A-00）の UI
* DB スキーマ詳細（schema.prisma で管理）
* RLS 詳細定義（DB 設計書で管理）

---

## 1.3 前提条件

* 認証方式は MagicLink（Supabase signInWithOtp）を使用する。
* `/auth/callback` では認証後のセッションが存在することを前提とする。
* HarmoNet の利用はユーザマスタに登録されたユーザーのみに限定される。
* 有効なテナント（user_tenants.status = 'active'）の存在を必須とする。
* ログイン遷移先は `/home` とする。

---

## 1.4 認可フロー概要

AuthCallbackHandler は以下の順で認可処理を行う：

1. Supabase セッション取得
2. セッションが存在しない場合：`/login?error=no_session` へ遷移
3. users テーブルを email で照会
4. 該当するユーザーがいない場合：セッション破棄 → `/login?error=unauthorized`
5. user_tenants に active な紐付けがない場合：同様に unauthorized
6. 認可成功 → `/home` へ遷移

---

## 1.5 コンポーネント構成

```text
app/
  auth/
    callback/
      page.tsx   # AuthCallbackHandler (A-03)
```

AuthCallbackHandler はページコンポーネントとして動作し、Props を受け取らない。

---

## 1.6 ログ出力

主要イベントのみを共通ログユーティリティに記録する：

| タイミング    | イベントID                                      |
| -------- | ------------------------------------------- |
| セッションなし  | `auth.callback.no_session`                  |
| ユーザ未登録   | `auth.callback.unauthorized.user_not_found` |
| テナント未紐付け | `auth.callback.unauthorized.no_tenant`      |
| 認可成功     | `auth.callback.authorized`                  |

---

## 1.7 参照ドキュメント

* LoginPage 詳細設計（A-00）
* MagicLinkForm 詳細設計（A-01）
* 共通ログユーティリティ詳細設計
* schema.prisma（users / user_tenants / tenants）
* 技術スタック定義書 v4.4

---

## 1.8 本章の位置付け

以降の章にて以下を詳述する：

* 第2章：機能設計
* 第3章：構造設計
* 第4章：実装設計
* 第5章：UI仕様
* 第6章：ロジック仕様
* 第7章：結合・運用
* 第8章：メタ情報

---

**End of Document**
