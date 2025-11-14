# PasskeyAuthTrigger 詳細設計書 - 第6章：結合・運用（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH06-INTEGRATION**
**Version:** 1.2
**Supersedes:** v1.1
**Status:** MagicLinkForm v1.2 整合（必要最小限更新）

---

## 6.1 他コンポーネント結合ポイント

PasskeyAuthTrigger (A-02) は MagicLinkForm (A-01) と統合され、パスワードレス認証フローの **ロジック中核** を担う。StaticI18nProvider (C-03)・ErrorHandlerProvider (C-16)・Supabase Auth・Corbado SDK と連携して動作する。

#### (1) コンポーネント依存関係

```mermaid
graph TD
    A[MagicLinkForm (A-01)] --> B[PasskeyAuthTrigger (A-02)]
    B --> C[StaticI18nProvider (C-03)]
    B --> D[Supabase Auth]
    B --> E[Corbado SDK]
    F[AppFooter (C-04)] --> A
```

| 結合対象                      | 種別       | 内容                                              |
| ------------------------- | -------- | ----------------------------------------------- |
| MagicLinkForm (A-01)      | 親        | PasskeyAuthTrigger を内部で使用。UI・状態管理を担当            |
| StaticI18nProvider (C-03) | Provider | **最新 i18n キー（success.* / error.*）を提供**          |
| Supabase                  | 外部API    | `signInWithOtp()` / `signInWithIdToken()` による認証 |
| Corbado SDK               | 外部SDK    | `Corbado.passkey.login()` による Passkey 認証        |
| AppFooter (C-04)          | UI部品     | 統合画面の下端固定レイアウト                                  |

#### (2) 結合条件

* `passkey_enabled = true` の場合は PasskeyAuthTrigger を最優先で起動。
* StaticI18nProvider が無い場合、`t()` はキー文字列をフォールバック返却。
* Corbado SDK 初期化 (`Corbado.load`) 完了後のみ認証実行。

---

## 6.2 環境依存要素

| 区分       | 設定項目                                                         | 内容            |
| -------- | ------------------------------------------------------------ | ------------- |
| Supabase | `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 認証API設定       |
| Corbado  | `NEXT_PUBLIC_CORBADO_PROJECT_ID` / `CORBADO_API_SECRET`      | Passkeyログイン設定 |
| 環境       | `.env.local`                                                 | ローカル環境設定      |
| RLS      | `tenant_id`                                                  | テナント境界識別      |

* WebAuthn の RP ID 制約により HTTPS 必須。開発時は Corbado sandbox が localhost を許可。
* Supabase Edge Functions にて `auth.verify()` によるトークン再検証を実施。

---

## 6.3 ログ・監視・障害対応

| 出力先           | 対象イベント         | ログ内容                 |
| ------------- | -------------- | -------------------- |
| Console (dev) | 認証失敗 / 未初期化    | `Corbado init error` |
| Supabase Log  | id_token 認証失敗  | ステータス・tenant_id      |
| Sentry        | 例外（SDK異常・通信障害） | StackTrace           |

* ErrorHandlerProvider (C-16) が例外を受け取り翻訳済みメッセージを表示。
* 致命的障害時は FallbackView を表示し再試行可能にする。

---

## 6.4 Storybook / Jest / E2E 結合設計

### (1) Storybook

* MagicLinkForm + PasskeyAuthTrigger を統合ストーリーとして登録。
* idle / sending / success / error の状態ごとの描画を確認。
* StaticI18nProvider を Decorator として使用。

### (2) Jest + RTL

| テストID    | 内容          | 期待結果                    |
| -------- | ----------- | ----------------------- |
| T-A02-06 | Supabase 連携 | `signInWithIdToken` が発火 |
| T-A02-07 | Corbado未初期化 | ErrorHandler が呼ばれる      |
| T-A02-08 | i18n 切替     | 文言が即時切替                 |
| T-A02-09 | 描画整合        | Storybook と DOM が一致     |

### (3) E2E（Playwright）

* `/login` にて MagicLink + Passkey の統合動作を検証。
* 認証成功後 `/mypage` に遷移し Supabase セッションが存在すること。

---

## 6.5 リスク・制約

| 項目          | 内容                                    |
| ----------- | ------------------------------------- |
| Corbado SDK | バージョン更新頻度が高いため月次検証が必要                 |
| ブラウザ差異      | Safari は RP ID 要件が厳格                  |
| 多言語キャッシュ    | 辞書ロード失敗時は ja へフォールバック                 |
| RLS         | `tenant_id` 不一致時は `auth.verify()` で拒否 |
| UI依存        | MagicLinkForm 統合構成のため単体描画不可           |

---

## 6.6 ChangeLog

| Version | Date       | Summary                                                 |
| ------- | ---------- | ------------------------------------------------------- |
| 1.2     | 2025-11-14 | StaticI18nProvider の翻訳キー記述を最新体系（success.* / error.*）へ更新 |
| 1.1     | 2025-11-12 | 結合・運用章の正式定義（A-02 統合構成）                                  |
