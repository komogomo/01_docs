# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch06 ロジック仕様 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH06
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.0 / アジェンダ標準準拠）

---

## 第6章 ロジック仕様

### 6.1 処理フロー詳細（Mermaid）

```mermaid
sequenceDiagram
  participant U as User
  participant PB as PasskeyButton
  participant API as /api/corbado/session
  participant S as Supabase Auth

  U->>PB: クリック
  PB->>PB: state=loading
  note over PB: 二重起動防止 (if loading return)
  PB->>API: POST /api/corbado/session
  API-->>PB: 200 + id_token （※本番は204でも可）
  PB->>S: signInWithIdToken({ provider:'corbado', token })
  alt 成功
    S-->>PB: session
    PB->>PB: state=success; onSuccess?.()
  else 失敗
    S-->>PB: error
    PB->>PB: state=error; classifyError→notifyError; onError?.(e)
  end
```

> 推奨: Corbado検証は **サーバ側（/api/corbado/session）** に集約し、フロントはセッション確立のみ実行。互換として `@corbado/web-js` 直接呼び出し方式も後述。

---

### 6.2 主要ロジック（擬似コード）

```ts
const handleLogin = useCallback(async () => {
  if (state === 'loading') return; // 二重起動防止
  setState('loading');
  try {
    // 方針A: サーバ検証方式（推奨）
    const res = await fetch('/api/corbado/session', { method:'POST' });
    if (!res.ok) throw new Error('NETWORK');
    const token = await res.text(); // or 204 成功→サーバ内で直接セッション確立

    const { error } = await supabase.auth.signInWithIdToken({ provider:'corbado', token });
    if (error) throw error;

    setState('success');
    onSuccess?.();
  } catch (err) {
    const e = classifyError(err, t);
    setState('error');
    notifyError(e.message);
    onError?.(e);
  }
}, [state, supabase, t, notifyError, onSuccess, onError]);

function classifyError(err:any, t: (k:string)=>string): PasskeyError {
  if (err?.name === 'NotAllowedError')
    return { code:'NOT_ALLOWED', message:t('error.passkey_denied'), type:'error_denied' };
  const msg = String(err?.message || '')
  if (msg.includes('ORIGIN'))
    return { code:'ORIGIN_MISMATCH', message:t('error.origin_mismatch'), type:'error_origin' };
  if (msg.includes('NETWORK') || err?.code === 'ECONNABORTED')
    return { code:'NETWORK', message:t('error.network'), type:'error_network' };
  return { code:'AUTH_ERROR', message:t('error.network'), type:'error_auth' };
}
```

> 方針B（互換）: `@corbado/web-js` を用いる場合は `Corbado.load({projectId}) → Corbado.passkey.login()` で `id_token` を取得し、同様に `signInWithIdToken()` へ委譲。

---

### 6.3 エラー構造と分類

| code            | type          | 表示文言(i18n)              | 代表例          | 対処    |
| --------------- | ------------- | ----------------------- | ------------ | ----- |
| NOT_ALLOWED     | error_denied  | `error.passkey_denied`  | 生体認証取消       | 再試行可能 |
| ORIGIN_MISMATCH | error_origin  | `error.origin_mismatch` | RP/Origin不整合 | 設定修正  |
| NETWORK         | error_network | `error.network`         | 通信断/タイムアウト   | リトライ  |
| AUTH_ERROR      | error_auth    | `error.network`         | Supabase連携失敗 | 再認証   |
| UNKNOWN         | error_unknown | `error.network`         | 想定外          | ログ送出  |

---

### 6.4 再試行設計

* **ユーザー操作**: エラー表示後の再クリックで `loading` に即時復帰。
* **自動復帰**: 自動リセットは行わず、**明示操作**を優先（誤ループ防止）。

---

### 6.5 状態遷移表

| 現在      | 入力   | 遷移先     | 挙動                |
| ------- | ---- | ------- | ----------------- |
| idle    | クリック | loading | 認証開始・二重起動抑止       |
| loading | 成功   | success | セッション確立・onSuccess |
| loading | 失敗   | error   | 例外分類・通知・onError   |
| error   | クリック | loading | 再試行開始             |

---

### 6.6 APIコントラクト（/api/corbado/session）

* **POST**: Cookie `cbo_short_session` を前提に Corbado 検証。
* **200(text/plain)**: `id_token` を返却（UI側で Supabase 連携）。
* **204**: サーバ側で Supabase セッション確立済（UI側は成功応答のみ確認）。
* **401/500**: `NETWORK` 相当として分類し UI 通知。
* **セキュリティ**: `HttpOnly/Secure/SameSite=Lax`、HTTPS必須、CORSは `NEXT_PUBLIC_APP_URL` 限定。

---

### 6.7 セキュリティ考慮事項

* `CORBADO_API_SECRET` は**サーバ専用**で保管（フロント露出禁止）。
* `id_token` の **永続化禁止**（localStorage等）。
* Supabase RLS は `tenant_id` クレームで境界維持。
* クリック1回＝1認証リクエスト、**CSRF影響なし**（RESTless）。

---

### 6.8 パフォーマンス最適化

* SDK/検証は **Lazy実行**（押下時のみ）。
* `useCallback` でハンドラ安定化、再描画最小化。
* 成功/失敗後の不要な連続呼出しを `disabled` 制御で抑止。

---

### 6.9 テスト設計（ロジック観点）

| テストID      | 観点        | 手順                                                      | 期待結果                          |
| ---------- | --------- | ------------------------------------------------------- | ----------------------------- |
| T-LOGIC-01 | 正常系       | `POST /api/corbado/session` → `signInWithIdToken` 成功モック | state: `idle→loading→success` |
| T-LOGIC-02 | 通信断       | fetch 失敗モック                                             | `error_network` 分類・通知         |
| T-LOGIC-03 | 取消        | `NotAllowedError` モック                                   | `error_denied` 分類             |
| T-LOGIC-04 | Origin不整合 | エラーメッセージ含有モック                                           | `error_origin` 分類             |
| T-LOGIC-05 | 二重起動抑止    | loading中に連打                                             | 追加リクエスト無し                     |

---

### 6.10 ChangeLog

| Version | Date       | Author    | Summary                                 |
| ------- | ---------- | --------- | --------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版。/api 経由のロジック仕様、分類/再試行、API契約、UT観点を定義。 |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch06_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
