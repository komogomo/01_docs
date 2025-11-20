# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch03 構造設計 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH03
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（アジェンダ標準準拠）

---

## 第3章 構造設計

### 3.1 コンポーネント構成図（層・依存）

```mermaid
flowchart TD
  LP[LoginPage] --> ML[MagicLinkForm (A-01)]
  LP --> PB[PasskeyButton (A-02)]
  PB --> I18N[StaticI18nProvider (C-03)]
  PB --> ERR[ErrorHandlerProvider (C-16)]
  PB --> API[/api/corbado/session]
  API --> CB[@corbado/node]
  PB --> SBA[@supabase/supabase-js]
  style PB fill:#E8F1FF,stroke:#2563EB
```

* **役割境界:** PasskeyButton は **UIトリガ** と **最小ロジック（セッション確立呼出）** に限定。検証とCookie・JWT処理は `/api/corbado/session` に委譲。

---

### 3.2 Props 定義・型仕様

```ts
export interface PasskeyButtonProps {
  /** TailwindCSSクラス拡張（レイアウト系のみ） */
  className?: string;
  /** 認証成功時コールバック（Supabaseセッション確立後） */
  onSuccess?: () => void;
  /** 失敗時（分類後）コールバック */
  onError?: (error: PasskeyError) => void;
}

export type PasskeyState = 'idle'|'loading'|'success'|'error';

export interface PasskeyError {
  code: string; // NOT_ALLOWED | ORIGIN_MISMATCH | NETWORK | AUTH_ERROR | UNKNOWN
  message: string; // i18n済み文言
  type: 'error_network'|'error_denied'|'error_origin'|'error_auth'|'error_unknown';
}
```

#### 3.2.1 デフォルト・制約

* `className`: **色指定の上書き禁止**（レイアウト補助のみ許可：`mt-*`, `mx-auto`, `max-w-*` など）。
* `onSuccess` / `onError`: **同期関数**推奨（遷移やトースト表示に限定）。

---

### 3.3 Props 制約仕様（表）

| Prop      |  必須 | 型                        | 既定   | 使用範囲    | 禁則                    |
| --------- | :-: | ------------------------ | ---- | ------- | --------------------- |
| className |  -  | string                   | `''` | レイアウト   | `text-*`, `bg-*` の上書き |
| onSuccess |  -  | `() => void`             | -    | 遷移/トースト | 非同期での長時間処理            |
| onError   |  -  | `(e:PasskeyError)=>void` | -    | 例外通知    | 例外の再throw             |

---

### 3.4 イベント・ハンドラ設計

```ts
const handleLogin = useCallback(async () => {
  try {
    setState('loading');
    // 方式A: 推奨（サーバ検証経由）
    const token = await fetch('/api/corbado/session', { method: 'POST' })
      .then(r => r.ok ? r.text() : Promise.reject(new Error('NETWORK')));

    const { error } = await supabase.auth.signInWithIdToken({ provider:'corbado', token });
    if (error) throw error;

    setState('success');
    onSuccess?.();
  } catch (err:any) {
    const e = classifyError(err, t);
    setState('error');
    notifyError(e.message);
    onError?.(e);
  }
}, [supabase, t, notifyError, onSuccess, onError]);
```

* **副作用最小化:** 認証押下時のみ通信。不要再生成は `useCallback` / 依存配列で抑制。
* **例外分類:** `NotAllowedError → error_denied` / Origin相違 → `error_origin` / 通信 → `error_network` / 既定 → `error_auth`。

---

### 3.5 Provider 連携

| Provider                    | 役割             | PBからの参照                     |
| --------------------------- | -------------- | --------------------------- |
| StaticI18nProvider (C-03)   | `t(key)` で文言取得 | `auth.passkey.*`, `error.*` |
| ErrorHandlerProvider (C-16) | 例外通知・ロギング      | `notifyError(message)`      |

---

### 3.6 i18n キー仕様（抜粋）

| キー                      | 用途        | 既定文（ja）          |
| ----------------------- | --------- | ---------------- |
| `auth.passkey.login`    | 初期ボタンラベル  | パスキーでログイン        |
| `auth.passkey.progress` | 認証中ラベル    | 認証中...           |
| `auth.passkey.success`  | 成功ラベル     | ログイン成功           |
| `auth.retry`            | 再試行       | 再試行              |
| `error.network`         | 通信エラー     | ネットワークエラーが発生しました |
| `error.origin_mismatch` | Origin不整合 | セキュリティ検証に失敗しました  |
| `error.passkey_denied`  | ユーザー取消    | 認証がキャンセルされました    |

---

### 3.7 DOMツリー（JSX抜粋）

```tsx
<button
  type="button"
  onClick={handleLogin}
  className="w-full h-12 rounded-2xl bg-blue-600 text-white font-medium flex items-center justify-center gap-2 hover:bg-blue-500 disabled:opacity-60 transition"
  disabled={state==='loading'}
  aria-live="polite"
>
  {/* state別アイコン + ラベル */}
</button>
```

* **A11y:** `aria-live="polite"`、フォーカスリングはグローバル（Design System）で適用。

---

### 3.8 パフォーマンス設計

* Lazy初期化（押下でリクエスト）。
* 依存モジュールはトップレベル import、関数は `useCallback` 固定。
* 1クリック＝1リクエスト。**二重起動は `disabled` 制御**で抑止。

---

### 3.9 テスト観点（構造）

| 観点ID  | 目的         | 期待結果                             |
| ----- | ---------- | -------------------------------- |
| ST-01 | Prop型整合    | TSエラー0                           |
| ST-02 | Provider結合 | `t()` 取得・`notifyError` 呼出の有無     |
| ST-03 | 再レンダー抑制    | 連続クリックで余計な再描画が発生しない              |
| ST-04 | 禁則遵守       | `className` で色上書き不許可（Lint/UTで検出） |

---

### 3.10 決定事項（Design Decisions）

| Version | Date       | Summary                                                                                   |
| ------- | ---------- | ----------------------------------------------------------------------------------------- |
| 1.0     | 2025-11-11 | UIはボタン単体、セッション確立は `/api/corbado/session` 経由。Propsは `className/onSuccess/onError` の3点に最小化。 |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch03_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
