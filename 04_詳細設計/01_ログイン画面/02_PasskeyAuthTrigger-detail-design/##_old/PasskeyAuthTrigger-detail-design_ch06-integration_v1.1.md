# HarmoNet 詳細設計書 - PasskeyAuthTrigger (A-02) 第6章 結合・運用 v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH06-INTEGRATION
**Version:** 1.1
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Directory:** /01_docs/04_詳細設計/01_ログイン画面/
**Status:** ✅ Phase9正式統合仕様（MagicLink + Passkey自動認証対応）

---

## 第6章 結合・運用

### 6.1 他コンポーネント結合ポイント

PasskeyAuthTrigger (A-02) は、MagicLinkForm (A-01) と統合されたパスワードレス認証フローの中核要素であり、StaticI18nProvider (C-03)・AppFooter (C-04) と密接に連携する。

#### (1) コンポーネント依存関係

```mermaid
graph TD
    A[MagicLinkForm (A-01)] --> B[PasskeyAuthTrigger (A-02)]
    B --> C[StaticI18nProvider (C-03)]
    B --> D[Supabase Auth]
    B --> E[Corbado SDK]
    F[AppFooter (C-04)] --> A
```

| 結合対象                      | 種別       | 内容                                                   |
| ------------------------- | -------- | ---------------------------------------------------- |
| MagicLinkForm (A-01)      | 親        | PasskeyTriggerを子要素として統合。メール送信前に自動Passkey判定を行う。       |
| StaticI18nProvider (C-03) | Provider | `t('auth.passkey.*')` の翻訳キーを提供。                      |
| Supabase                  | 外部API    | `signInWithOtp()` および `signInWithIdToken()` による統合認証。 |
| Corbado SDK               | 外部SDK    | `Corbado.passkey.login()` によりPasskey処理を実行。           |
| AppFooter (C-04)          | UI共通部品   | レイアウト統一・下端固定配置。                                      |

#### (2) 結合条件

* `MagicLinkForm` は `passkey_enabled` が true の場合、`PasskeyAuthTrigger` を優先的に起動する。
* `StaticI18nProvider` が未提供の場合、警告ログを出力し `t()` はフォールバック（キー文字列返却）する。
* Corbado SDKは `Corbado.load({ projectId })` の初期化完了を前提として動作する。

---

### 6.2 環境依存要素

| 区分       | 変数名 / 設定項目                                                   | 内容                               |
| -------- | ------------------------------------------------------------ | -------------------------------- |
| Supabase | `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 認証・ストレージ統合APIの接続設定。              |
| Corbado  | `NEXT_PUBLIC_CORBADO_PROJECT_ID` / `CORBADO_API_SECRET`      | Passkeyログインに必要なCorbadoプロジェクト識別子。 |
| 環境       | `.env.local`                                                 | 開発時にローカル環境でのみ参照される。              |
| RLS      | `tenant_id`                                                  | Supabase内のテナント境界識別。              |

* HTTPS通信を必須とし、WebAuthn仕様（RP ID制約）を満たす。
* 開発環境ではlocalhostでもCorbadoのsandboxモードで認証可能。
* Supabase Edge Functionsは `auth.verify()` によりCorbadoトークンを再検証する。

---

### 6.3 ログ・監視・障害対応方針

| 出力先               | 対象イベント                   | ログ内容                                  |
| ----------------- | ------------------------ | ------------------------------------- |
| **Console (dev)** | 認証失敗 / Corbado未初期化       | `console.error('Corbado init error')` |
| **Supabase Log**  | `signInWithIdToken()` 失敗 | エラーコード・HTTPステータス・tenant_id            |
| **Sentry**        | 未捕捉例外（ネットワーク断・SDK異常）     | StackTrace + user_context             |

* UI層では ErrorHandlerProvider (C-16) が例外を受け取り、国際化されたエラーメッセージを表示。
* クリティカル障害時は FallbackView を表示し、再試行可能なUIを提供する。

---

### 6.4 Storybook / Jest / E2E 結合設計

#### (1) Storybook結合構成

* `MagicLinkForm + PasskeyAuthTrigger` を1つのストーリーとして登録。
* 状態別（idle / sending / success / error）をコンポーネント境界で再現。
* `StaticI18nProvider`をDecoratorとして包み、翻訳が反映されることを確認。

#### (2) Jest + RTLテスト

| テストID        | シナリオ          | 期待結果                     |
| ------------ | ------------- | ------------------------ |
| **T-A02-06** | Supabase連携テスト | `signInWithIdToken`が呼ばれる |
| **T-A02-07** | Corbado未初期化   | ErrorHandlerが呼出される       |
| **T-A02-08** | i18n切替動作      | 表示文言が即時切替される             |
| **T-A02-09** | 結合描画          | Storybook構成とDOM一致        |

#### (3) E2Eテスト

* 環境: Playwright
* 対象: `/login` ページ上の統合動作（MagicLink送信 + Passkey成功遷移）
* 成功基準: `/mypage` に遷移し、Supabaseセッションが確立していること。

---

### 6.5 リスク・制約事項

| 項目                  | 内容                                                          |
| ------------------- | ----------------------------------------------------------- |
| **Corbado SDKの互換性** | v2.x 系は頻繁なマイナーバージョン更新があるため、CIで月次検証を実施。                      |
| **ブラウザ差異**          | SafariではRP IDの一致要件が厳格。開発環境ではlocalhost許可設定が必要。               |
| **多言語キャッシュ**        | StaticI18nProviderで辞書ロードエラー時にjaへフォールバックするため、翻訳の遅延が生じる場合がある。 |
| **RLS再検証**          | Supabase JWT内の`tenant_id`と一致しない場合、`auth.verify()` で弾かれる。    |
| **UI依存**            | MagicLinkFormの統合状態により、PasskeyTrigger単独では描画されない。             |

---

**改訂履歴**

| Version | Date       | Author          | Summary                                                                      |
| ------- | ---------- | --------------- | ---------------------------------------------------------------------------- |
| 1.1     | 2025-11-12 | Tachikoma / TKD | 第6章を「ロジック仕様」から「結合・運用」へ修正。StaticI18nProvider / Supabase / Corbadoとの結合内容を正式定義。 |
