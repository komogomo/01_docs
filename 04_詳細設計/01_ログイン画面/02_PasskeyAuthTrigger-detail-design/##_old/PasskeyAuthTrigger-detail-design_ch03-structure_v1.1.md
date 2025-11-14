# HarmoNet 詳細設計書 - PasskeyAuthTrigger (A-02) ch03 v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH03
**Version:** 1.1
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.2 / MagicLinkForm 統合対応）

---

## 第3章 構造設計

### 3.1 モジュール構成概要

PasskeyAuthTrigger は **MagicLinkForm (A-01)** 内で呼び出される非UIモジュールであり、Hook として定義される。
本章では、内部モジュール構成・依存関係・データフロー・責務分離を定義する。

```
MagicLinkForm (A-01)
 └─ usePasskeyAuthTrigger (A-02)
     ├─ StaticI18nProvider (C-03)
     ├─ ErrorHandlerProvider (C-16)
     ├─ Supabase Auth (signInWithIdToken)
     └─ Corbado SDK (passkey.login / verify)
```

PasskeyAuthTrigger は上位層からの状態やUIを一切持たず、**Promiseベースで結果のみを返す純ロジック関数**として設計される。
UI表示（ローディング・完了・再試行など）は MagicLinkForm 側で処理する。

---

### 3.2 Hook構造

```typescript
// src/hooks/auth/usePasskeyAuthTrigger.ts
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
      const { error } = await supabase.auth.signInWithIdToken({ provider: 'corbado', token: result.id_token });
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

### 3.3 データフロー構造

#### 3.3.1 フロントエンド処理フロー

```mermaid
flowchart TD
  A[MagicLinkForm] -->|ログイン要求| B[usePasskeyAuthTrigger]
  B --> C[Corbado.passkey.login()]
  C --> D{id_token 取得?}
  D -->|Yes| E[Supabase.signInWithIdToken()]
  D -->|No| F[ErrorHandlerProvider]
  E -->|Success| G[onSuccess()]
  E -->|Failure| H[onError()]
```

#### 3.3.2 サーバサイド処理フロー

```mermaid
flowchart LR
  A[/api/corbado/session/] --> B[verify(token)]
  B --> C{id_token valid?}
  C -->|Yes| D[NextResponse.json({id_token})]
  C -->|No| E[Error 400]
```

---

### 3.4 外部依存関係

| 区分                   | 依存モジュール                     | 役割                               |
| -------------------- | --------------------------- | -------------------------------- |
| **Corbado SDK**      | `@corbado/web-js`           | WebAuthn認証・id_token取得            |
| **Corbado Node SDK** | `@corbado/node`             | トークン検証（サーバーサイド）                  |
| **Supabase Auth**    | `@supabase/auth-js`         | `signInWithIdToken()` によりセッション確立 |
| **i18n基盤**           | StaticI18nProvider (C-03)   | 翻訳文言の取得                          |
| **例外処理**             | ErrorHandlerProvider (C-16) | 例外通知・UI表示連携                      |

---

### 3.5 内部関数構造

| 関数名                 | 役割             | 備考                        |
| ------------------- | -------------- | ------------------------- |
| **execute()**       | 認証処理のメイン関数     | Corbado呼出〜Supabase連携を一括処理 |
| **classifyError()** | 例外分類関数         | エラーの型・原因・文言を変換し UI側に渡す    |
| **handleError()**   | C-16のハンドラを呼び出す | ログ・通知連携                   |

---

### 3.6 エラー分類構造

| 例外タイプ         | 条件                       | 対応メッセージキー               | 通知方法                    |
| ------------- | ------------------------ | ----------------------- | ----------------------- |
| error_network | ネットワーク断・タイムアウト           | `error.network`         | ErrorHandlerProvider 経由 |
| error_denied  | `NotAllowedError`        | `error.passkey_denied`  | 同上                      |
| error_origin  | Origin / RP ID 不整合       | `error.origin_mismatch` | 同上                      |
| error_auth    | Supabase / Corbado 内部エラー | `error.network`         | 同上                      |

---

### 3.7 MagicLinkFormとの結合ポイント

| 結合対象                        | 内容                                            |
| --------------------------- | --------------------------------------------- |
| MagicLinkForm (A-01)        | `usePasskeyAuthTrigger()` を内部呼出し、状態管理とUI表示を担当 |
| StaticI18nProvider (C-03)   | t(key) による文言取得                                |
| ErrorHandlerProvider (C-16) | 通知UI（Banner / Toast）を発火                       |

---

### 3.8 責務境界定義

| 層     | 主体                     | 責務                         |
| ----- | ---------------------- | -------------------------- |
| UI層   | MagicLinkForm          | UI表示・状態更新・再試行ボタン制御         |
| ロジック層 | PasskeyAuthTrigger     | 認証・例外分類・通知実行               |
| SDK層  | Corbado / Supabase     | 認証実行・トークン交換                |
| サーバ層  | `/api/corbado/session` | Corbado Token検証・Supabase中継 |

---

### 3.9 関連ドキュメント

| ファイル                                                           | 用途       |
| -------------------------------------------------------------- | -------- |
| `/01_docs/04_詳細設計/01_ログイン画面/01_MagicLinkForm-detail-design/`   | 呼出元構成    |
| `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md`     | i18n基盤参照 |
| `/01_docs/04_詳細設計/00_共通部品/ch16_ErrorHandlerProvider_v1.0.md`   | 例外通知構成   |
| `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.2.md` | 技術基盤準拠   |

---

### 3.10 ChangeLog

| Version | Date           | Author              | Summary                                                   |
| ------- | -------------- | ------------------- | --------------------------------------------------------- |
| 1.0     | 2025-11-11     | Tachikoma           | 旧 PasskeyButton 構成（UIコンポーネント版）                            |
| **1.1** | **2025-11-12** | **Tachikoma / TKD** | **MagicLinkForm 統合対応。非UIモジュール構造・技術スタックv4.2準拠・責務分離構成を確立。** |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyAuthTrigger-detail-design/PasskeyAuthTrigger-detail-design_ch03_v1.1.md`
**Compliance:** harmoNet-detail-design-agenda-standard_v1.0
