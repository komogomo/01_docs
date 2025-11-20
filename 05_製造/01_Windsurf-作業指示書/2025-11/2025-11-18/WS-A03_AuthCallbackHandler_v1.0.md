# WS-A03_AuthCallbackHandler_v1.0

## 1. Task Summary（タスク概要）

* **目的**: MagicLink 認証後の `/auth/callback` における **認可処理（ユーザマスタ照合・テナント判定）** を実装し、HarmoNet の正式ログイン方式を完成させる。
* **対象コンポーネント**: AuthCallbackHandler (A-03)
* **修正範囲**: `app/auth/callback/page.tsx`
* **注意**: Edge Function は使用禁止。Next.js App Router（Server Component）内で完結させること。UI は最小限。ロジックの責務は “認証後の認可処理のみ”。

---

## 2. Target Files（編集対象ファイル）

* `app/auth/callback/page.tsx`
* （必要に応じて）`src/lib/supabase/server.ts` ※ 既存の server client を利用するのみ

---

## 3. Import & Directory Rules（公式ルール）

本タスクは **HarmoNet フロントエンド構成 v1.0** に完全準拠する。

```
src/
  components/
    common/
    auth/
  lib/
    supabase/
app/
  auth/
    callback/
      page.tsx
```

* import パスは `@/src/...` 形式に統一
* 新規ディレクトリ・新規コンポーネントの作成は禁止
* Edge Function / Route Handler（POST エンドポイント）新設禁止

---

## 4. References（参照ドキュメント）

Windsurf は以下を唯一の正として扱う：

* AuthCallbackHandler 詳細設計書 v1.0
* HarmoNet 技術スタック定義書 v4.3
* MagicLinkForm 詳細設計書 v1.3
* LoginPage 詳細設計書 v1.3
* schema.prisma（users / user_tenants）

---

## 5. Implementation Rules（実装ルール）

* **認証（MagicLink）後の認可処理のみ実装する**
* DB 照会は Supabase Server Client で実施
* UI は簡易な Loading 表示だけ（数行テキスト）
* 以下を必ず実施：

  1. Supabase セッション取得（session.user.email 必須）
  2. users テーブルで email 検索
  3. user_tenants で tenant_id 存在確認
  4. 失敗 → signOut → `/login?error=unauthorized`
  5. 成功 → `/home` へ redirect
* **shouldCreateUser:false** を前提とした設計（未登録ユーザーの許可禁止）
* RLS 用 tenant_id の付与処理は実装しない（既存 Supabase 仕様に委譲）
* console.log は禁止。共通 logger（logInfo/logError）が存在する場合のみ使用可。

### 5.1 Test Environment Data Prerequisites（テスト環境データ前提条件）

Windsurfのコード生成と、TKDによる最終的な機能検証は、以下のデータベース状態を前提とします。このデータは、開発環境（Docker）の初期シードデータとして手動で投入されることを想定します。

### 5.6 Test Environment Data Prerequisites（テスト環境データ前提条件）

Windsurfのコード生成と、TKDによる最終的な機能検証は、以下のデータベース状態を前提とします。

| 項目 | 値 | DBテーブル | 備考 |
| :--- | :--- | :--- | :--- |
| **テストユーザーメール** | `ttakeda43@gmail.com` | `auth.users` | MagicLink認証でセッションを取得するユーザー。 |
| **テナント内部ID** | `tenant_id`: **`12345678-ABCD-0000-0000-000000000001`** | `user_roles`, `tenants`.`id` | RLSキー。システムが自動生成したUUID形式。 |
| **テナント識別コード** | `tenant_code`: **`HARM01`** | `tenants`.`tenant_code` | 管理者が入力した6桁コード。 |
| **ロール** | `role`: `tenant_admin` | `user_roles` | 認可で判定するロール。 |

---

## 6. Acceptance Criteria（受入基準）

* TypeCheck: **0 エラー**
* ESLint: **0 エラー**
* Build: **成功**
* `/auth/callback` 直アクセス → `/login?error=no_session`
* 認証後、ユーザマスタ未登録 → `/login?error=unauthorized`
* 認証後、tenant 紐付けなし → `/login?error=unauthorized`
* 管理者登録済ユーザー → `/home` へ即時遷移
* SelfScore: **9.0 以上**

---

## 6.5 Backup Rules（バックアップルール）

既存ファイルに上書きが発生する場合、以下を必ず行う：

```
page.tsx_<YYYYMMDD>_v0.1.bk
```

同一ディレクトリに保存すること。

---

## 7. Forbidden Actions（禁止事項）

* Edge Function の追加・利用
* 新規 Route Handler 作成（POST/GET エンドポイント）
* 新規ディレクトリ作成
* UI 追加・デザイン変更
* MagicLinkForm への改変
* Supabase Auth 設定値の変更
* 余計な抽象化・最適化の追加

---

## 8. CodeAgent_Report（必須）

Windsurf は完了後、以下形式でレポートを **/01_docs/06_品質チェック/** に保存すること：

```
/01_docs/06_品質チェック/CodeAgent_Report_AuthCallbackHandler_v1.0.md
```

形式：

```
[CodeAgent_Report]
Agent: Windsurf
Task: AuthCallbackHandler_v1.0
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - D:/AIDriven/01_docs/04_詳細設計/01_ログイン画面/01_MagicLinkForm-detail-design/Auth-Callback Handler-detail-design_v1.0.md
 - D:/AIDriven/01_docs/04_詳細設計/01_ログイン画面/01_MagicLinkForm-detail-design/harmonet-technical-stack-definition_v4.3
 - D:/AIDriven/01_docs/04_詳細設計/01_ログイン画面/MagicLinkForm-detail-design_v1.3
 - D:/AIDriven/01_docs/04_詳細設計/01_ログイン画面/MA-00LoginPage-detail-design_v1.3.md

[Generated_Files]
 - app/auth/callback/page.tsx

Summary:
 - 認証→認可ロジックの実装内容
 - 実施した処理
 - 注意点
```

---

## 9. Testing Method（検証手順）

### 9.1 認証前準備（テストデータ前提）

| 項目          | 値                                                                         | 役割                                          |
| ----------- | ------------------------------------------------------------------------- | ------------------------------------------- |
| テストユーザー (A) | `ttakeda43@gmail.com`                                              | 認可成功（tenant_admin ロールを持つ）                   |
| テストユーザー (B) | `unauthorized-user@harmonet.com`                                          | 認可失敗（auth.users には存在するが user_roles に紐づけがない） |
| 期待クレーム      | `tenant_id: 12345678-ABCD-0000-0000-000000000001`<br>`role: tenant_admin` | 認可成功時に JWT に付与されるべき値                        |

---

### 9.2 検証手順（正常系：認可成功と JWT クレーム付与）

| No. | アクション                                     | 期待結果                                  | 判定基準（必須）                                 |
| --- | ----------------------------------------- | ------------------------------------- | ---------------------------------------- |
| 1   | ユーザー (A) で MagicLink 認証を実行し、メール内リンクをクリック。 | `/auth/callback` 経由で `/home` へ遷移する。 | HTTP リダイレクト先が `/home` であること。           |
| 2   | 開発者ツールでセッション内容（クッキー/LocalStorage）を確認。     | 新しい JWT セッションが確立されている。                | `sb:token` が存在すること。                      |
| 3   | JWT デコーダーでセッション内容を確認。                     | カスタムクレームが正しく付与されている。                  | JWT に `tenant_id` と `role` が期待値通り存在すること。 |

---

### 9.3 検証手順（異常系：認可失敗とセキュリティクリーンアップ）

| No. | アクション                                     | 期待結果                                | 判定基準（必須）                                        |
| --- | ----------------------------------------- | ----------------------------------- | ----------------------------------------------- |
| 1   | ユーザー (B) で MagicLink 認証を実行し、メール内リンクをクリック。 | `/auth/callback` 処理後、ログイン画面へリダイレクト。 | リダイレクト先が `/login?error=unauthorized` であること。     |
| 2   | DevTools のクッキーを確認。                        | セッションが完全に破棄されている。                   | `sb:token` クッキーおよびローカルストレージのセッションデータが削除されていること。 |
