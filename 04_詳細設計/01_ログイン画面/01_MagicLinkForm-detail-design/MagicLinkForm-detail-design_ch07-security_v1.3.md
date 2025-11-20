# MagicLinkForm 詳細設計書 — 第7章：環境設定・セキュリティ（v1.4）

本章では MagicLinkForm（A-01）が動作するために必要な **環境設定・環境変数・セキュリティ要件**の
実装方式について記載する。

---

## 7.1 目的

MagicLinkForm が使用する環境変数・設定ファイル構成・セキュリティ要件を定義し、
実行環境（本番 / ステージング / ローカル）において安定して動作させることを目的とする。

---

## 7.2 必須環境変数

MagicLinkForm が利用する環境変数は、**Supabase の MagicLink（OTP）認証に必要なもののみ** とする。

```bash
NEXT_PUBLIC_SUPABASE_URL=<Supabase Project URL>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<Supabase Anon Key>
```

**要件**

* クライアント側で利用するため、`NEXT_PUBLIC_` プレフィックスを必須とする。
* MagicLink のリダイレクト先は実装側が `/auth/callback` へ固定するため、本章では個別変数としない。

---

## 7.3 テナント設定

MagicLinkForm 自体はテナント設定を直接参照しないが、MagicLink のメール送信元設定はテナント構成に依存する。
これらはアプリ全体の `tenant_config` で管理される。

**tenant_config の例**（参照用途）

```ts
interface TenantConfig {
  tenant_id: string;
  smtp_domain: string;
  smtp_sender_name: string;
  magiclink_callback_url: string; // /auth/callback に統一可能
}
```

MagicLinkForm は上記設定を直接保持せず、Supabase 側設定に従って処理される。

---

## 7.4 環境ファイル構造

MagicLinkForm が参照するのは Public 変数のみである。
環境ファイル例は以下の通り。

```
.env.local
.env.staging
.env.production
.env.tenant.<tenant_id>
```

### `.env.production` 例

```bash
NEXT_PUBLIC_SUPABASE_URL=https://example.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxxxx
```

---

## 7.5 Supabase 認証設定

MagicLinkForm が利用する Supabase 認証 API は以下の通り。

| 設定項目             | 内容                  |
| ---------------- | ------------------- |
| API              | `signInWithOtp()`   |
| shouldCreateUser | false（管理者による事前登録方式） |
| emailRedirectTo  | `/auth/callback`    |

MagicLinkForm 側では追加の設定を保持しない。

---

## 7.6 i18n 設定

MagicLinkForm が使用する翻訳キーはすべて `common.json` に定義される。

```
/public/locales/ja/common.json
/public/locales/en/common.json
/public/locales/zh/common.json
```

MagicLinkForm 専用ファイルは作成しない。

---

## 7.7 CI/CD・Secrets 管理

MagicLinkForm が参照する値は全て Public Prefix のため、Secrets を直接使用しない。
Supabase 鍵は CI/CD 上で Secrets として管理し、`.env.production` に展開する。

**CI 生成例**

```bash
NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## 7.8 セキュリティ要件

MagicLinkForm は Public API を使用するため、以下を満たす必要がある。

### 7.8.1 クライアント側

* `.env*` は Git 管理対象外とする。
* Public Prefix のみ参照し、Secret Key を保持しない。
* MagicLink の OTP トークンはクライアント側で扱わない（Supabase 側で処理）。

### 7.8.2 サーバー・運用側

* Supabase SMTP / callback URL は tenant_config で管理する。
* 認証情報は Secrets 管理とし、アプリコードにハードコーディングしない。
* 認証キーは適切な周期でローテーションする。

---

## 7.9 テナント展開フロー（参照仕様）

MagicLink の設定はテナント単位（tenant_config）で管理される。
MagicLinkForm 自体はこの値を参照しないが、メール送信動作は以下の設定に基づく。

```
新規テナント登録
→ tenant_config へ SMTP / callback URL 登録
→ Supabase プロジェクト設定へ反映
→ .env.tenant.<ID> 作成
→ デプロイ
→ 動作確認
```

---

**End of Document**
