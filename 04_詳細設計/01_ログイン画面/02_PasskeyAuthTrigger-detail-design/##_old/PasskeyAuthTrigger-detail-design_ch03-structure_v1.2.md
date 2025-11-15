# PasskeyAuthTrigger 詳細設計書 - 第3章：構造設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH03
**Version:** 1.2
**Supersedes:** v1.1
**Status:** MagicLinkForm v1.2 仕様整合（必要最小限更新）

---

## 3.1 モジュール構成概要

PasskeyAuthTrigger は **MagicLinkForm (A-01)** 内で呼び出される非UIロジックモジュールであり、Hook（`usePasskeyAuthTrigger`）として提供される。UIは保持せず、Promise ベースで成功／失敗を通知する純ロジック構造である。

```
MagicLinkForm (A-01)
 └─ usePasskeyAuthTrigger (A-02)
     ├─ StaticI18nProvider (C-03)
     ├─ ErrorHandlerProvider (C-16)
     ├─ Supabase Auth
     └─ Corbado SDK
```

MagicLinkForm 側は UI 表示・状態管理を担当し、本モジュールは認証ロジックにのみ責務を限定する。

---

## 3.2 Hook構造

```ts
export const usePasskeyAuthTrigger = ({ passkeyEnabled, onSuccess, onError }: PasskeyAuthTriggerOptions) => {
  const supabase = createClient();
  const { t } = useI18n();
  const handleError = useErrorHandler();

  const execute = async (): Promise<void> => {
    if (!passkeyEnabled) return; // MagicLink fallback
    try {
      await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
      const result = await Corbado.passkey.login();
      if (!result?.id_token) throw new Error('NO_TOKEN');

      const { error } = await supabase.auth.signInWithIdToken({
        provider: 'corbado',
        token: result.id_token,
      });

      if (error) throw error;
      onSuccess?.();
    } catch (err: any) {
      const error = classifyError(err, t);
      handleError(error.message);
      onError?.(error);
    }
  };

  return { execute };
};
```

---

## 3.3 データフロー構造

### 3.3.1 フロントエンド処理フロー

```mermaid
flowchart TD
  A[MagicLinkForm] -->|ログイン要求| B[usePasskeyAuthTrigger]
  B --> C[Corbado.passkey.login()]
  C --> D{id_token 取得?}
  D -->|Yes| E[Supabase.signInWithIdToken]
  D -->|No| F[ErrorHandlerProvider]
  E -->|Success| G[onSuccess]
  E -->|Failure| H[onError]
```

### 3.3.2 サーバサイド処理フロー

```mermaid
flowchart LR
  A[/api/corbado/session/] --> B[verify(token)]
  B --> C{id_token valid?}
  C -->|Yes| D[return id_token]
  C -->|No| E[400 Error]
```

---

## 3.4 外部依存関係

| 区分                   | モジュール               | 役割                             |
| -------------------- | ------------------- | ------------------------------ |
| Corbado SDK          | `@corbado/web-js`   | Passkey認証実行（id_token取得）        |
| Corbado Node         | `@corbado/node`     | トークン検証（サーバサイド）                 |
| Supabase Auth        | `@supabase/auth-js` | `signInWithIdToken` によるセッション確立 |
| StaticI18nProvider   | (C-03)              | 翻訳キー取得（`success.*` `error.*`）  |
| ErrorHandlerProvider | (C-16)              | 例外通知UIとの連携                     |

---

## 3.5 内部関数構造

| 関数名             | 役割                                                                      |
| --------------- | ----------------------------------------------------------------------- |
| execute()       | Corbado → Supabase の一連処理を実行                                             |
| classifyError() | 例外分類（error.network / error.denied / error.origin_mismatch / error.auth） |
| handleError()   | C-16 経由で UI 通知を発火                                                       |

---

## 3.6 エラー分類構造（最新版）

MagicLinkForm v1.2 と整合した最新 i18n 体系に統一する。

| タイプ           | 条件                       | 翻訳キー                    |
| ------------- | ------------------------ | ----------------------- |
| error_network | ネットワーク断・タイムアウト           | `error.network`         |
| error_denied  | `NotAllowedError`        | `error.denied`          |
| error_origin  | RP ID / Origin 不整合       | `error.origin_mismatch` |
| error_auth    | Supabase / Corbado 内部エラー | `error.auth`            |

---

## 3.7 MagicLinkFormとの結合ポイント

| 対象                   | 内容                     |
| -------------------- | ---------------------- |
| MagicLinkForm (A-01) | 認証結果に基づく UI 表示と状態管理を担当 |
| StaticI18nProvider   | `t(key)` による文言取得       |
| ErrorHandlerProvider | 通知 UI を表示              |

---

## 3.8 責務境界

| 層     | 主体                     | 責務               |
| ----- | ---------------------- | ---------------- |
| UI層   | MagicLinkForm          | UI表示・状態管理・再試行    |
| ロジック層 | PasskeyAuthTrigger     | 認証処理・例外分類・通知実行   |
| SDK層  | Corbado / Supabase     | 認証実行・トークン交換      |
| サーバ層  | `/api/corbado/session` | id_token検証・安全な中継 |

---

## 3.9 関連ドキュメント

* MagicLinkForm-detail-design_v1.2（A-01）
* StaticI18nProvider_v1.0（C-03）
* ErrorHandlerProvider_v1.0（C-16）
* harmoNet-technical-stack-definition_v4.2

---

## 3.10 ChangeLog

| Version | Date       | Summary                                           |
| ------- | ---------- | ------------------------------------------------- |
| 1.2     | 2025-11-14 | MagicLinkForm v1.2 の i18n体系に準拠。エラー分類構造の最新化・最小限修正。 |
| 1.1     | 2025-11-12 | MagicLinkForm 統合対応・非UI構造確立。                       |
