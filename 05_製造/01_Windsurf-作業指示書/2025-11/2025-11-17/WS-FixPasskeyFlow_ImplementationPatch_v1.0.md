# WS-FixPasskeyFlow — 実装パッチ（検証用）

> 内容: サーバ API Route とクライアント側の最小差分パッチ（デバッグログ付き）。
> 目的: `/api/auth/passkey` 未実装のため、設計どおりにフローを切り替え、短時間で再現・切り分けを行う。

---

## ファイル1 — サーバ (上書き可)

**パス**: `app/api/auth/passkey/route.ts`

**概要**: 到達確認・JWKS 検証（Corbado）・Supabase signInWithIdToken 呼び出し試行。ログはトークンの長さのみ出力。

```ts
// app/api/auth/passkey/route.ts
import { NextResponse } from "next/server";
import { createRemoteJWKSet, jwtVerify } from "jose";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const CORBADO_ISSUER = process.env.CORBADO_ISSUER; // 例: https://api.corbado.io/<tenant>
const CORBADO_AUD = process.env.CORBADO_AUD; // Corbado の audience (project id)

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  : null;

async function verifyIdTokenJWKS(idToken: string) {
  if (!CORBADO_ISSUER || !CORBADO_AUD) {
    throw new Error("CORBADO_ISSUER or CORBADO_AUD is not set");
  }
  const jwks = createRemoteJWKSet(new URL(`${CORBADO_ISSUER}/.well-known/jwks.json`));
  return await jwtVerify(idToken, jwks, { issuer: CORBADO_ISSUER, audience: CORBADO_AUD });
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    console.log("[passkey-debug] req.keys:", Object.keys(body));
    const idToken = body?.idToken;
    console.log("[passkey-debug] idToken present:", !!idToken, "len:", idToken ? idToken.length : 0);
    console.log("[passkey-debug] env CORBADO_ISSUER:", !!process.env.CORBADO_ISSUER, "CORBADO_AUD:", !!process.env.CORBADO_AUD);
    console.log("[passkey-debug] env SUPABASE_SERVICE_ROLE_KEY:", !!process.env.SUPABASE_SERVICE_ROLE_KEY);

    if (!idToken) {
      return NextResponse.json({ status: "error", code: "NO_IDTOKEN" }, { status: 400 });
    }

    // 1) verify via JWKS (Corbado)
    let payload;
    try {
      const res = await verifyIdTokenJWKS(idToken);
      payload = res.payload;
      console.log("[passkey-debug] verify ok claims:", Object.keys(payload || {}));
    } catch (e) {
      console.error("[passkey-debug] verify failed:", String(e));
      return NextResponse.json({ status: "error", code: "INVALID_IDTOKEN", message: String(e) }, { status: 401 });
    }

    // 2) If supabase client configured, attempt sign in
    if (!supabase) {
      console.warn("[passkey-debug] supabase client not configured (service role missing)");
      return NextResponse.json({ status: "ok", note: "verified_but_no_supabase" });
    }

    try {
      const { data, error } = await supabase.auth.signInWithIdToken({
        provider: "corbado",
        token: idToken,
      });
      console.log("[passkey-debug] supabase signIn result:", { dataExists: !!data, error: error?.message });
      if (error) throw error;
      return NextResponse.json({ status: "ok", data: !!data });
    } catch (e) {
      console.error("[passkey-debug] supabase failure:", String(e));
      return NextResponse.json({ status: "error", code: "SUPABASE_FAILED", message: String(e) }, { status: 500 });
    }
  } catch (e) {
    console.error("[passkey-debug] unexpected:", e);
    return NextResponse.json({ status: "error", code: "UNEXPECTED", message: String(e) }, { status: 500 });
  }
}
```

---

## ファイル2 — クライアント（差分）

**パス**: `src/components/auth/PasskeyAuthTrigger/...` の該当ハンドラ

**概要**: 既存実装で直接 `supabase.auth.signInWithIdToken` を呼んでいる場合に、本 API を叩くように最小差分で置換する。デバッグログを残す。

```ts
// クライアント側ハンドラ（差し替え例）
async function onClickPasskey(event?: React.MouseEvent) {
  if (event?.preventDefault) event.preventDefault();
  console.log("[passkey-debug] button clicked");
  try {
    const Corbado = await import("@corbado/web-js");
    await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
    const result = await Corbado.passkey.login();
    const idToken = result?.id_token;
    console.log("[passkey-debug] idToken length:", idToken ? idToken.length : 0);

    // 設計どおり API を呼ぶ
    const resp = await fetch("/api/auth/passkey", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken }),
    });
    const j = await resp.json();
    console.log("[passkey-debug] /api/auth/passkey:", resp.status, j);

    if (resp.ok && j.status === "ok") {
      console.log("[passkey-debug] login succeeded");
      // 必要に応じて UI 更新やリダイレクト
    } else {
      console.error("[passkey-debug] server returned error", j);
      throw new Error(j.message || j.code || "server_error");
    }
  } catch (e) {
    console.error("[passkey-debug] client error:", e);
    throw e; // 既存の classifyError に渡す等の呼び出し元処理に任せる
  }
}
```

---

## 依存・インストール

```
cd D:\Projects\HarmoNet
npm install jose @supabase/supabase-js
```

---

## 必要な `.env.local`（検証用）

```
NEXT_PUBLIC_CORBADO_PROJECT_ID=pro-7248593760809448075
CORBADO_ISSUER=https://api.corbado.io/<tenant>
CORBADO_AUD=pro-7248593760809448075
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxxxx_service_role_key   # server-only
```

**注意**: `SUPABASE_SERVICE_ROLE_KEY` / `CORBADO_API_SECRET` 等の秘密は **絶対にクライアントへ露出しない**。

---

## 実行手順（短く）

1. `cd D:\Projects\HarmoNet`
2. 上記依存インストール（初回のみ）
3. `git add -A && git commit -m "WIP: add passkey debug route"`（バックアップ運用の場合は別ブランチで）
4. `npm run dev` を起動しターミナルログを保存
5. ブラウザで `http://localhost:3000/login` を開き DevTools の Console/Network を有効にして Passkey を押す
6. 取得ログ（Console とサーバ端末の `[passkey-debug]` 出力）を収集し共有する

---

## 期待される観測パターン（切り分け）

* **A**: idToken が取得され `/api/auth/passkey` に到達 → サーバで `verify failed` → Corbado issuer/aud の整合を確認
* **B**: idToken が取得できない（`Corbado.passkey.login()` が throw）→ ブラウザで origin, WebAuthn 条件を確認
* **C**: POST が出ない（クライアント例外）→ Console の最上位エラーを解析（process 参照等）
* **D**: Supabase が失敗 → `SUPABASE_SERVICE_ROLE_KEY` の確認

---

## 収集して共有してほしいログ（必ずマスク）

1. ブラウザ Console（Passkey クリック直後の赤エラー全文）
2. Network の `POST /api/auth/passkey` の Request payload（idToken はマスクして長さだけ）と Response status/body
3. サーバ端末ログ（`[passkey-debug]` 行）
4. Corbado ダッシュボード情報: プロジェクト ID（先頭 `pro-`）、Allowed origins に `http://localhost:3000` が入っているか

---

このドキュメントは検証用パッチです。実運用移行前に TKD の承認を得てください。
