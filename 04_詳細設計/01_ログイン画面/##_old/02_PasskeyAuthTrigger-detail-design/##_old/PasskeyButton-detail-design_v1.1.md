# HarmoNet 詳細設計書 - PasskeyButton (A-02) v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-DESIGN  
**Version:** 1.1  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Difficulty:** 4（高）  
**Safe Steps:** 5  
**Status:** Phase9 技術統合版（Next.js 16 / Supabase v2.43 / React 19）  

---

## 📚 参照文書一覧
| 区分 | ファイル名 | 用途 |
|------|-------------|------|
| 親仕様書 | login-feature-design-ch06_v1.1.md | PasskeyButton要件定義 |
| 関連仕様 | login-feature-design-ch05_v1.1.md | セキュリティ対策仕様 |
| UI構成 | login-feature-design-ch03_v1.3.1.md | ログイン画面UI構成 |
| デザイン | common-design-system_v1.1.md | デザイントークン・UI統一 |
| 多言語 | common-i18n_v1.0.md | 翻訳・ロケール定義 |
| アクセシビリティ | common-accessibility_v1.0.md | ARIA規約・操作ガイドライン |
| DB構造 | schema.prisma | User / Tenant モデル定義 |

---

## 第1章 概要

### 1.1 目的
本設計書は、HarmoNetログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** コンポーネントの詳細設計を定義する。  
ユーザーが登録済みのWebAuthn Passkeyを用いてSupabase Authと連携し、**ワンタップでログイン**を実現する。

### 1.2 設計方針
- **Next.js 16.0.1（App Router）** + **React 19** 構成で動作  
- **Supabase JS SDK v2.43+** の `signInWithPasskey()` API に準拠  
- **StaticI18nProvider (C-03)** によりローカライズ  
- **自然で安心感のあるUI**（BIZ UDゴシック / Appleカタログ風 / 控えめトーン）  
- **エラー表示と成功状態の明確化**（Loader / Check / Alertアイコン利用）  
- **パスワードレス認証方式の1要素としてMagicLinkと併用可能**

---

---

## 第2章 構造設計

### 2.1 コンポーネント構成

```typescript
/**
 * PasskeyButton - パスキー認証ボタンコンポーネント
 *
 * @component A-02
 * @framework Next.js 16 (App Router)
 * @library Supabase JS SDK v2.43+
 * @depends useI18n / lucide-react / shadcn/ui / supabase client
 */
"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useI18n } from "@/components/common/StaticI18nProvider";
import { Button } from "@/components/ui/button";
import { KeyRound, Loader2, CheckCircle, AlertCircle } from "lucide-react";

2.2 Props定義
export interface PasskeyButtonProps {
  className?: string;
  /** 認証成功時のコールバック */
  onSuccess?: () => void;
  /** エラー発生時のコールバック */
  onError?: (error: PasskeyError) => void;
}

2.3 内部状態定義
type PasskeyState =
  | "idle"
  | "loading"
  | "success"
  | "error_not_found"
  | "error_origin"
  | "error_network";

interface PasskeyError {
  code: string;
  message: string;
  type: PasskeyState;
}

2.4 コンポーネント本体
export const PasskeyButton: React.FC<PasskeyButtonProps> = ({
  className,
  onSuccess,
  onError,
}) => {
  const [state, setState] = useState<PasskeyState>("idle");
  const [error, setError] = useState<PasskeyError | null>(null);
  const { t } = useI18n();
  const router = useRouter();
  const supabase = createClient();

  const handlePasskeyLogin = useCallback(async () => {
    try {
      setState("loading");
      setError(null);

      const { data, error: authError } = await supabase.auth.signInWithPasskey();

      if (authError) {
        handleAuthError(authError);
        return;
      }

      setState("success");
      onSuccess?.();
      setTimeout(() => router.push("/mypage"), 1500);
    } catch (err: any) {
      handleCatchError(err);
    }
  }, [supabase, router, onSuccess]);

  const handleAuthError = (authError: any) => {
    let e: PasskeyError = {
      code: "UNKNOWN",
      message: t("error.unknown"),
      type: "error_network",
    };
    if (authError.message?.includes("No passkey")) {
      e = { code: "PASSKEY_NOT_FOUND", message: t("error.passkey_not_found"), type: "error_not_found" };
    } else if (authError.message?.includes("Origin")) {
      e = { code: "ORIGIN_MISMATCH", message: t("error.origin_mismatch"), type: "error_origin" };
    }
    setError(e);
    setState(e.type);
    onError?.(e);
  };

  const handleCatchError = (err: any) => {
    const e = { code: "NETWORK", message: t("error.network"), type: "error_network" } as PasskeyError;
    setError(e);
    setState("error_network");
    onError?.(e);
  };

  return (
    <Button
      onClick={handlePasskeyLogin}
      disabled={state === "loading"}
      variant="outline"
      className={`w-full h-12 rounded-xl font-bold flex items-center justify-center gap-2 transition ${className}`}
      aria-busy={state === "loading"}
      aria-live="polite"
    >
      {state === "loading" && <Loader2 className="animate-spin" />}
      {state === "success" && <CheckCircle className="text-green-600" />}
      {state === "error_not_found" && <AlertCircle className="text-red-500" />}
      {state === "idle" && <KeyRound />}
      <span>
        {state === "success"
          ? t("auth.success")
          : state.startsWith("error")
          ? t("auth.retry")
          : t("auth.passkey")}
      </span>
    </Button>
  );
};

---

## 第3章 ロジック設計

### 3.1 状態遷移設計

PasskeyButton は以下の6状態を持つ。  
各状態は Supabase Auth の認証結果に応じて自動遷移する。

| 状態 | 説明 | 遷移トリガー |
|------|------|--------------|
| `idle` | 初期状態。ボタン待機 | コンポーネント初期化時 |
| `loading` | WebAuthn認証処理中 | ボタン押下（`handlePasskeyLogin`） |
| `success` | 認証成功。マイページ遷移前の成功表示 | Supabase `signInWithPasskey()` 成功 |
| `error_not_found` | Passkey未登録エラー | Supabaseエラーメッセージ `"No passkey"` |
| `error_origin` | Origin不一致 | Supabaseエラーメッセージ `"Origin"` |
| `error_network` | 通信・未知エラー | try/catch内例外またはネットワーク障害 |

#### 状態遷移図

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> loading: onClick
    loading --> success: Auth OK
    loading --> error_not_found: No passkey
    loading --> error_origin: Origin mismatch
    loading --> error_network: Exception
    success --> [*]: redirect /mypage
    error_not_found --> idle: retry
    error_origin --> idle: retry
    error_network --> idle: retry

3.2 エラーハンドリング仕様
| エラータイプ            | 表示メッセージ（多言語キー）            | 表示アイコン         | 回復方法     |
| ----------------- | ------------------------- | -------------- | -------- |
| `error_not_found` | `error.passkey_not_found` | 🔺 AlertCircle | 再登録誘導    |
| `error_origin`    | `error.origin_mismatch`   | ⚠️ AlertCircle | HTTPS再接続 |
| `error_network`   | `error.network`           | 🚫 AlertCircle | 再試行      |
| その他               | `error.unknown`           | ❔              | 再試行      |

翻訳キー例 (/public/locales/ja/common.json):
{
  "auth": {
    "passkey": "パスキーでログイン",
    "success": "ログイン成功",
    "retry": "再試行",
    "error": "エラーが発生しました"
  },
  "error": {
    "passkey_not_found": "登録済みのパスキーが見つかりません。",
    "origin_mismatch": "認証元が一致しません。",
    "network": "ネットワークエラーが発生しました。",
    "unknown": "予期しないエラーが発生しました。"
  }
}

3.3 成功時の遷移処理
・認証成功後 state = success へ遷移。
・setTimeout(() => router.push("/mypage"), 1500) により遅延遷移。
・遅延を入れる理由は、ユーザーが成功状態を視覚的に確認できるようにするため。
・成功音やモーションは将来的に拡張可能（motion.div対応想定）。

3.4 アクセシビリティ設計
| 要素              | 属性            | 値          | 説明               |
| --------------- | ------------- | ---------- | ---------------- |
| `<Button>`      | `aria-busy`   | true/false | ローディング状態表示       |
| `<Button>`      | `aria-live`   | polite     | 状態変化をスクリーンリーダー通知 |
| `<span>`        | `role`        | status     | ログイン結果の読み上げ対象    |
| `<AlertCircle>` | `aria-hidden` | true       | 装飾のみのアイコン        |

3.5 テストケース一覧
| No   | テスト内容               | 入力条件                | 期待結果                  |
| ---- | ------------------- | ------------------- | --------------------- |
| T-01 | 初期描画                | state=idle          | 「パスキーでログイン」表示         |
| T-02 | 認証成功                | signInWithPasskey成功 | 「ログイン成功」→`/mypage`遷移  |
| T-03 | Passkey未登録          | エラー "No passkey"    | 「登録済みのパスキーが見つかりません」表示 |
| T-04 | Origin不一致           | エラー "Origin"        | 「認証元が一致しません」表示        |
| T-05 | ネットワーク例外            | fetch失敗             | 「ネットワークエラー」表示         |
| T-06 | onSuccess / onError | Props経由             | コールバックが発火する           |

---

## 第4章 UI設計

### 4.1 レイアウト構造
┌───────────────────────────────┐
│ │
│ [🔑 パスキーでログイン] │ ← Button（state=idle）
│ [🔄 ローディング中…] │ ← Loader2（state=loading）
│ [✅ 成功しました] │ ← CheckCircle（state=success）
│ [⚠️ エラーが発生しました] │ ← AlertCircle（error_xx）
│ │
└───────────────────────────────┘


### 4.2 ビジュアル仕様（Design System v1.1準拠）

| 項目 | 値 |
|------|----|
| 背景 | `#FFFFFF` |
| フォント | BIZ UDゴシック / weight 500 |
| フォントサイズ | 16px |
| 角丸 | 12px（`rounded-xl`） |
| 高さ | 48px（`h-12`） |
| 配色 | メイン `#2563EB` / 成功 `#16A34A` / 警告 `#DC2626` |
| 影 | `shadow-sm` |
| ホバー | `hover:bg-gray-50` |
| トランジション | 0.25s ease-in-out |
| アイコン | lucide-react（KeyRound / Loader2 / CheckCircle / AlertCircle） |

### 4.3 多言語対応

- `useI18n()` により `auth.passkey` 等をリアルタイム取得。  
- StaticI18nProvider (C-03) を上位に配置するため、SSR/CSR問わず翻訳即時反映。  
- 翻訳辞書の参照パス：`/public/locales/{locale}/common.json`

### 4.4 レスポンシブ対応

| デバイス | スタイル |
|----------|----------|
| モバイル | `w-full` ボタン幅、フォント14px |
| タブレット | `w-[360px]` 固定幅中央寄せ |
| デスクトップ | `w-[400px]`、マージン上下24px |
| 共通 | `flex justify-center items-center gap-2` |

### 4.5 視覚的状態変化

| 状態 | ボタン色 | アイコン | テキスト |
|------|-----------|-----------|-----------|
| idle | 白背景 / 枠グレー | 🔑 KeyRound | `auth.passkey` |
| loading | グレー背景 | 🔄 Loader2 | `auth.loading` |
| success | 緑背景 / 白文字 | ✅ CheckCircle | `auth.success` |
| error_* | 赤背景 / 白文字 | ⚠️ AlertCircle | `auth.retry` |

---

## 第5章 結合および依存関係

### 5.1 コンポーネント階層
StaticI18nProvider (C-03)
└─ AppHeader (C-01)
└─ LanguageSwitch (C-02)
└─ LoginPage (/app/login/page.tsx)
├─ MagicLinkForm (A-01)
└─ PasskeyButton (A-02) ← 本コンポーネント
└─ AppFooter (C-04)
└─ FooterShortcutBar (C-05)


### 5.2 依存ライブラリとバージョン

| ライブラリ | バージョン | 用途 |
|-------------|-------------|------|
| `@supabase/supabase-js` | ^2.43.0 | Auth (signInWithPasskey) |
| `react` | ^19.0.0 | useState / useCallback |
| `next` | ^16.0.1 | App Router / useRouter |
| `lucide-react` | ^0.325.0 | アイコン |
| `@/components/ui/button` | shadcn/ui | ボタンベース |
| `tailwindcss` | ^3.4.0 | スタイリング |

### 5.3 外部連携

| 項目 | 内容 |
|------|------|
| 認証API | Supabase Auth (Magic Link + Passkey) |
| 成功遷移 | `/mypage` へ自動遷移 |
| DB参照 | `user` テーブル（schema.prisma 準拠） |
| RLS分離 | `tenant_id` により認可済み |
| 通信条件 | HTTPS（Origin一致が必須） |

---

---

## 第6章 テスト仕様

### 6.1 単体テスト観点（Jest + React Testing Library）

| テストID | 項目 | 期待動作 | 成否基準 |
|-----------|------|-----------|-----------|
| UT-A02-01 | 初期表示 | ボタンが「パスキーでログイン」を表示 | DOMに`auth.passkey`が存在 |
| UT-A02-02 | ローディング | クリック後`Loader2`表示 | `aria-busy=true` |
| UT-A02-03 | 成功遷移 | 成功後 `/mypage` へpushされる | `router.push`呼び出し確認 |
| UT-A02-04 | Passkey未登録 | Supabaseから`No passkey`受信 | `error.passkey_not_found`表示 |
| UT-A02-05 | Origin不一致 | Supabaseから`Origin`受信 | `error.origin_mismatch`表示 |
| UT-A02-06 | 通信例外 | fetchエラー発生 | `error.network`表示 |
| UT-A02-07 | コールバック発火 | 成功時onSuccess, エラー時onError | モック関数呼び出し確認 |
| UT-A02-08 | アクセシビリティ | `aria-live`有効、スクリーンリーダー通知 | `role="status"`存在確認 |

**テスト環境設定**
- Jest 29.x + RTL 14.x
- `setupTests.ts` で `@testing-library/jest-dom` をロード
- `supabase.auth.signInWithPasskey` をモック化して状態遷移検証

---

## 第7章 付録

### 7.1 JSON I/O スキーマ

**入力要求 (`signInWithPasskey`)**

```json
{
  "method": "passkey",
  "challenge": "WebAuthnChallenge",
  "rpId": "https://harmonet.local"
}

出力応答
{
  "data": {
    "session": {
      "access_token": "jwt...",
      "user": { "id": "uuid", "email": "user@example.com" }
    }
  },
  "error": null
}

エラー例
{
  "data": null,
  "error": { "message": "No passkey registered for this user" }
}

7.2 セキュリティ考慮
| 項目      | 内容                                 |
| ------- | ---------------------------------- |
| HTTPS必須 | 開発以外のOrigin検証強制                    |
| JWT     | Supabase Authで自動生成・Secure Cookie管理 |
| XSS対策   | React自動エスケープ、DOM未直書き               |
| CSRF    | RESTless認証（Cookie不要）               |
| 情報漏洩防止  | RLS + `tenant_id`スコープアクセス制御        |

7.3 変更履歴
| Version | Date       | Author          | Description                                |
| ------- | ---------- | --------------- | ------------------------------------------ |
| v1.0    | 2025-11-10 | TKD / Claude    | 初版（Phase9承認仕様）                             |
| v1.1    | 2025-11-10 | TKD / Tachikoma | Supabase v2.43対応 / Next.js16統合版 / 実在API整合版 |

7.4 メタ情報

保存パス: /01_docs/04_詳細設計/01_ログイン画面/PasskeyButton-detail-design_v1.1.md
Supersedes: PasskeyButton-detail-design_v1.0.md
Version Control: GitHub Projects-HarmoNet / Google Drive /01_docs/04_詳細設計/01_ログイン画面/
Review Target: Gemini (API実在性チェック), Claude (最終整合監査)

