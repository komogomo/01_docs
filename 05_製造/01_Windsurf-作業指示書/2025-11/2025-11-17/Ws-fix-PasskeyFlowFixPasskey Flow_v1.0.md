# WS-Task: Fix Passkey flow — POST /api/auth/passkey が発生せず auth.login.fail.passkey.unexpected が出る問題

**対象ファイル**

* `src/components/auth/PasskeyAuthTrigger/*`（フロントのボタン/ハンドラ）
* `app/api/auth/passkey/route.ts`（Next.js App Router API）
* `next.config.js`, `package.json`（ビルド設定）
* ローカル `.env.local`（値はマスクして参照）

---

## Goal (目的)

Passkey ボタン押下でクライアントが `idToken` を取得し、`POST /api/auth/passkey` が送信され、サーバで `idToken` を検証（Corbado）→ Supabase `signInWithIdToken` が成功する流れを正常化する。

---

## Scope (作業範囲)

1. フロント：Passkey ボタンのイベントハンドラ確認・確実な `idToken` 取得と `fetch('/api/auth/passkey',...)` の発行。
2. サーバ：`/api/auth/passkey` の受信処理の到達確認・トークン検証フロー（Corbado SDK または JWKS + jose）・Supabase 呼び出し。
3. 環境：`NEXT_PUBLIC_*` のクライアント利用と `CORBADO_API_SECRET` 等のサーバ専用 env の取り扱い（Turbopack 回避/webpack polyfill の有無は問わないがサーバシークレットをクライアントに露出しないこと）。
4. バンドル設定：問題がある `process` 参照箇所の修正／polyfill（最小）または DefinePlugin による限定埋め込み。

---

## Minimal Repro（再現手順） — Windsurf が必ず実行すること

1. ローカル作業フォルダを用意（TKD の環境: `D:\Projects\HarmoNet` を想定）
2. `package.json` の dev スクリプトを確認 (`next dev` または `next dev --webpack`)。
3. 以下を実行して動作ログを取得：

```powershell
cd D:\Projects\HarmoNet
npm ci
npm run dev  # コンソールログを録る
```

4. ブラウザで `http://localhost:3000/login` を開き DevTools → Console + Network (XHR) を有効にする。
5. Passkey ボタンを押し、以下を観察する：

   * `POST /api/auth/passkey` が Network に現れるか（Y/N）
   * 出る場合：Request Payload（idToken が存在するか、長さ）と Response status / body を保存
   * 出ない場合：Console の最上位エラーを収集

---

## 必要ログ / アーティファクト

* Browser: Console のスクリーンショット、Network HAR（/api/auth/passkey にフィルタ）
* Server: `npm run dev` のターミナル出力（Passkey 押下前後のログ、最後 200 行）
* マスク済み `.env.local`（キー名のみ、値はマスク）

---

## Investigation checklist（順序）

1. クライアント JS が動作しているか確認（`console.log('passkey-func-ok')`）
2. Passkey ハンドラが呼ばれ `idToken` が取得できているか（長さのみログ）
3. Network に POST が出ない場合は、イベントバインド／フォーム submit により処理が中断されていないかを確認。必要なら一時的テストボタンを挿入して POST を強制。
4. POST が届くが 4xx/5xx の場合はサーバ側のログで以下を確認：

   * `process.env.CORBADO_API_SECRET` の存在
   * Corbado verify のエラーメッセージ（issuer/aud/signature エラー等）
   * Supabase の `signInWithIdToken` の戻り値（error.message）
5. クライアント側で `process is not defined` のようなエラーがある場合、`process` 参照を削るか DefinePlugin で `process.env.NEXT_PUBLIC_*` のみ埋める。

---

## 具体的なコード修正案（コピペ可能）

### フロント（例: Passkey handler のデバッグ追加）

```ts
async function onClickPasskey(event?: React.MouseEvent) {
  if (event?.preventDefault) event.preventDefault();
  console.log('[passkey-debug] clicked');
  try {
    const idToken = await startPasskeyAndGetIdToken(); // 既存実装に置換
    console.log('[passkey-debug] got idToken length:', idToken ? idToken.length : 0);
    const resp = await fetch('/api/auth/passkey', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken }),
    });
    console.log('[passkey-debug] response status:', resp.status);
    console.log('[passkey-debug] response body:', await resp.text());
  } catch (e) {
    console.error('[passkey-debug] client error:', e);
  }
}
```

### サーバ（デバッグ版 route.ts - 到達確認用）

```ts
// app/api/auth/passkey/route.ts (デバッグ用)
import { NextResponse } from 'next/server';
export async function POST(req: Request) {
  try {
    const body = await req.json().catch(()=>({}));
    console.log('[passkey-debug] req keys:', Object.keys(body));
    const idToken = body?.idToken;
    console.log('[passkey-debug] idToken present:', !!idToken, 'len:', idToken ? idToken.length : 0);
    console.log('[passkey-debug] env CORBADO_API_SECRET present:', !!process.env.CORBADO_API_SECRET);
    return NextResponse.json({ ok: true, received: !!idToken });
  } catch(e) {
    console.error('[passkey-debug] handler error', e);
    return NextResponse.json({ ok: false, error: String(e) }, { status:500 });
  }
}
```

---

## Acceptance criteria（受け入れ基準）

**Functional**

1. Passkey 押下で 2 秒以内に `POST /api/auth/passkey` が Network に出る。
2. Request payload に `idToken`（長さ > 100）が含まれる。
3. サーバログ上で `idToken present: true` が出力され、Corbado 検証成功または明確なエラーコードが返る。
4. Supabase による sign-in が成功し session が返る／または 200 レスポンスを返す。

**Non-functional**

* クライアント Console に `ReferenceError: process is not defined` が出ない。
* サーバシークレットがクライアントバンドルに露出しない。

---

## Tests

* Manual: ローカルでフローを実行し HAR とサーバログを収集。
* Optional Unit: `/api/auth/passkey` に対する integration テスト（モック verify）を追加。

---

## Bans / Constraints

* `CORBADO_API_SECRET` 等のサーバ秘密をクライアントへ露出しない。
* DB スキーマ変更や外部設定変更は TKD の承認が必要。
* Windsurf の試行は最大 3 回。失敗時は CodeAgent_Report を出す。

---

## Output required from Windsurf

* Save CodeAgent_Report to: `/01_docs/06_品質チェック/CodeAgent_Report_FixPasskeyFlow_v1.0.md`

  * Include: Agent name, Task, Attempts, AverageScore, TypeCheck, Lint, Tests, Modified files, Summary, Logs (masked), HAR

---

## Quick checklist (for immediate execution)

1. `cd D:\Projects\HarmoNet && git status && git rev-parse --abbrev-ref HEAD`
2. `npm ci` then `npm run dev` and monitor terminal logs
3. Open `http://localhost:3000/login` and reproduce
4. If no request, insert front debug logs + test button and re-run
5. If server not reached, replace API route with debug handler and re-run
6. Implement fix, capture HAR + server logs, and produce CodeAgent_Report

---

**Notes**

* このタスクは TKD（プロジェクト設計者）の指示に基づくため、実装・修正は TKD 承認後に本番反映してください。
* ログや HAR を公開する際はシークレットを必ずマスクしてください。

---

*Prepared for Windsurf by Tachikoma.*
