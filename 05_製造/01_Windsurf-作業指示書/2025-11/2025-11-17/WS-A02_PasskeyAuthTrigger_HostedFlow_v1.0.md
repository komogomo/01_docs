# WS-A02_PasskeyAuthTrigger_HostedFlow_v1.0

## 1. Task Summary（タスク概要）

* **目的**: PasskeyAuthTrigger（A-02）を Corbado Hosted Passkey Flow 方式へ全面移行する。
* **対象コンポーネント**: `src/components/auth/PasskeyAuthTrigger/*`
* **修正範囲**:

  * Hosted Flow 初期化処理の追加
  * Passkey ログイン実行処理の置き換え
  * id_token を `/api/auth/passkey` に送信するフローの実装
  * 状態遷移（idle / processing / success / error）の更新
  * デバッグログ（passkey-debug）の追加
* **注意**:

  * UI / Tailwind / JSX 構造を変更してはならない
  * Hosted Flow 呼び出しのみを正しく実装すること

---

## 2. Target Files（編集対象ファイル）

* `src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.tsx`
* `src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.types.ts`
* `src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.test.tsx`

---

## 3. Import & Directory Rules（公式ルール）

* 本タスクは **Frontend Directory Guideline v1.0** に完全準拠すること。
* import パスは以下のみ使用可能：

```
@/src/components/...  （UI / Hooks / Utils）
/app/...               （Next.js App Router）
```

* VSCode 相対パスは禁止。

---

## 4. References（参照ドキュメント）

* PasskeyAuthTrigger 詳細設計 v1.5（Hosted Flow 対応）
* login-feature-design（A-00）
* MagicLinkForm 詳細設計（A-01）
* Login Backend 基本設計書 v1.0
* Corbado Hosted Flow 仕様（Dashboard 最新 UI）

---

## 5. Implementation Rules（実装ルール）

### 5.1 必須ロジック

* Hosted Flow 初期化：

```ts
import { Corbado } from "@corbado/web-js";
await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
```

* Passkey ログイン（Hosted Flow）:

```ts
const result = await Corbado.openPasskeyLogin();
const idToken = result?.id_token;
```

* サーバへ送信:

```ts
await fetch("/api/auth/passkey", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ idToken }),
});
```

### 5.2 禁止事項

* UIレイアウト変更、Tailwind変更
* Props変更（追加・削除）
* Passkey UI を自作する行為（Hosted Flow の UI をそのまま使用）
* 外部ライブラリ追加

### 5.3 状態制御

* `idle → processing → success → redirect` のみ許可
* エラーは `error_unexpected` へ集約

### 5.4 デバッグログ

```ts
console.log("[passkey-debug] result", result);
```

---

## 6. Acceptance Criteria（受入基準）

* TypeCheck / Lint / Test がすべて PASS
* Hosted Flow の呼び出しが正常に 1 回だけ実行される
* id_token を正常に `/api/auth/passkey` へ送信
* 成功時 `/mypage` へ遷移
* UI崩れゼロ（Before / After 同一）
* SelfScore 9.0 以上

---

## 7. Backup Rules（バックアップ規則）

修正前のファイルを同一ディレクトリに以下形式で保存：

```
<元ファイル名>_<YYYYMMDD>_v0.1.bk
```

例：

```
PasskeyAuthTrigger.tsx_20251117_v0.1.bk
```

---

## 8. CodeAgent_Report（必須）

Windsurf は作業完了後に以下を生成：

```
[CodeAgent_Report]
Agent: Windsurf
Task: A02_PasskeyAuthTrigger_HostedFlow
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed
Lint: Passed
Tests: <pass率>
References:
 - WS-A02_PasskeyAuthTrigger_HostedFlow_v1.0
 - PasskeyAuthTrigger-detail-design_v1.5
[Generated_Files]
 - 更新されたファイル一覧
Summary:
 - 実施内容の概要
 - 注意点
```

保存先：

```
/01_docs/06_品質チェック/CodeAgent_Report_A02_PasskeyAuthTrigger_HostedFlow_v1.0.md
```

---
