# 第6章: パスキー認証ボタン詳細設計（A-02 PasskeyButton）

**Document ID:** HARMONET-LOGIN-CH06-PASSKEYBUTTON  
**Version:** 1.1  
**Status:** Phase9 承認仕様準拠（ContextKey: HarmoNet_LoginFeature_Phase9_v1.3_Approved）  
**Last Updated:** 2025-11-10 04:54

---

## ch06-1. 目的と概要

本章は、HarmoNetログイン画面における **パスキー認証ボタン（A-02 PasskeyButton）** の詳細設計を定義する。  
本機能は Phase9 における正式仕様「**パスワードレス認証（Magic Link + Passkey）**」の後段を担い、  
登録済みユーザーがワンタップでログインできる体験を提供する。  

目的：
- すでにパスキー登録済みのユーザーに即時ログインを提供  
- 未登録ユーザーには登録誘導を提示  
- セキュリティを意識させない「自然なログイン体験」を実現  

---

## ch06-2. 依存関係と前提

### 2.1 技術依存
- **Supabase Auth API:**  
  - `auth.signInWithPasskey()`（WebAuthn対応）
  - `auth.passkey.list()`（登録状態確認）
- **ブラウザAPI:** `navigator.credentials.get()`
- **共通部品:** AppHeader / LanguageSwitch / StaticI18nProvider / AppFooter  
  （FooterShortcutBarは未認証画面では非表示）

### 2.2 前提条件
- ユーザーがすでに `auth.passkey.register()` により1つ以上のパスキーを登録済み  
- 端末のブラウザが WebAuthn Level2 に対応していること  
- Origin は Supabase Auth に登録済みドメインと完全一致していること  

---

## ch06-3. UI構成

### 3.1 レイアウト
┌───────────────────────────┐
│ AppHeader（最小） │
├───────────────────────────┤
│ PasskeyButton Area │
│ ┌──────────────────────┐ │
│ │ 🔑 パスキーでログイン │ │
│ └──────────────────────┘ │
│ 状態: idle / loading / success / error │
├───────────────────────────┤
│ AppFooter │
└───────────────────────────┘


### 3.2 スタイル仕様
| 要素 | スタイル |
|------|-----------|
| 背景 | 白 |
| ボタン | 高さ44px / 角丸xl / シャドウsm |
| アイコン | `lucide-react` の `KeyRound` を使用 |
| フォント | BIZ UDゴシック / weight:600 / size:15px |
| 色 | 通常: `#111827`, hover:`#2563eb`, active:`#1e40af` |
| 無効時 | opacity:0.5, cursor:not-allowed |

---

## ch06-4. 状態遷移とUX

| 状態 | 表示 | 動作 |
|------|------|------|
| idle | 「パスキーでログイン」 | 押下待機 |
| loading | スピナー表示（2秒以内） | 認証試行中 |
| success | ✅ 「認証成功」 | `/mypage` にリダイレクト |
| error_not_found | ⚠️ 「パスキーが登録されていません」 | 「パスキーを登録する」CTA表示 |
| error_origin | ❌ 「デバイスが対応していません」 | Passkeyボタン非活性化 |

### 4.1 UXガイド
- 処理完了までの待機を2秒以内に抑制。  
- 成功時は**自動遷移**、エラー時は**再試行**または**登録誘導**。  
- フォーカスはボタンに戻る（キーボード操作対応）。  

---

## ch06-5. i18n 文言定義（ja/en/zh）

| key | ja | en | zh |
|------|----|----|----|
| `auth.passkey.button` | パスキーでログイン | Sign in with Passkey | 使用通行密钥登录 |
| `auth.passkey.loading` | 認証中... | Authenticating... | 正在验证... |
| `auth.passkey.success` | 認証成功 | Authentication successful | 验证成功 |
| `auth.passkey.error_not_found` | パスキーが登録されていません | No passkey registered | 未注册通行密钥 |
| `auth.passkey.error_origin` | デバイスが対応していません | This device is not supported | 此设备不支持 |
| `auth.passkey.register_cta` | パスキーを登録する | Register a Passkey | 注册通行密钥 |

---

## ch06-6. 擬似コード（実装想定）

```tsx
// PasskeyButton.tsx
import { useState } from "react";
import { useI18n } from "@/components/common/StaticI18nProvider";
import { supabase } from "@/lib/supabaseClient";

export const PasskeyButton = () => {
  const { t } = useI18n();
  const [state, setState] = useState("idle");

  const handlePasskeyLogin = async () => {
    try {
      setState("loading");
      const { data, error } = await supabase.auth.signInWithPasskey();
      if (error) throw error;
      setState("success");
      window.location.href = "/mypage";
    } catch (err) {
      if (err.message.includes("No passkey")) setState("error_not_found");
      else setState("error_origin");
    }
  };

  return (
    <button
      type="button"
      onClick={handlePasskeyLogin}
      disabled={state === "loading"}
      className="w-full h-11 rounded-xl border border-gray-300 font-semibold text-gray-800 hover:bg-gray-50 active:bg-gray-100"
    >
      {state === "loading"
        ? t("auth.passkey.loading")
        : state === "success"
        ? t("auth.passkey.success")
        : t("auth.passkey.button")}
    </button>
  );
};

ch06-7. エラー処理とハンドリング
エラー種別	表示文言	対応動作
NotAllowedError	認証がキャンセルされました	idleに戻る
NotFoundError	パスキーが登録されていません	CTA表示
InvalidStateError	デバイスが対応していません	disabled表示
NetworkError	通信エラーが発生しました	再試行案内

ch06-8. アクセシビリティ設計
・aria-live="polite" で状態更新を読上げ
・エラー時は role="alert"
・フォーカスはボタンに戻す（ref.focus()）
・視覚的インジケータ：フォーカスリング outline-blue-500

タブ順：
　1.言語切替
　2.Magic Linkフォーム
　3.Passkeyボタン
　4.Footerリンク

ch06-9. セキュリティ関連考慮
・Origin一致検証をブラウザAPIおよびSupabase双方で実施
・JWT保存先はHttpOnly Cookie（localStorage禁止）
・Passkey署名データはクライアント外部送信禁止
・失敗ログは Supabase Edge Function に送信し、監査に利用
・ch05で定義したRLS/JWT保護を継承
・ch06-10. テスト観点・受け入れ基準

ch06-10. テスト観点・受け入れ基準
| No | 試験項目                     | 合格条件           |
| -- | ------------------------ | -------------- |
| 1  | パスキー登録済ユーザーの自動認証         | 100%成功         |
| 2  | 未登録ユーザー時の登録誘導表示          | CTAが正しく表示される   |
| 3  | Origin不一致デバイスの拒否         | 実行不可（ボタン無効）    |
| 4  | ローディング→成功の状態遷移           | 2秒以内           |
| 5  | i18n切替（ja/en/zh）         | 全文言正確          |
| 6  | キーボード操作                  | Enter/Spaceで発火 |
| 7  | Lighthouse Accessibility | 95点以上          |

ch06-11. 整合性と参照
関連章:
・ch03（ログイン画面UI）
・ch04（Magic Link完了＋Passkey登録誘導）
・ch05（セキュリティ対策）

関連ファイル:
・schema.prisma（Userモデル / passkey登録状態）
・20251107000001_enable_rls_policies.sql
・CodeAgent_Report_StaticI18nProvider_v1.0.md

ch06-12. 変更履歴
Version	Date	Summary
v1.1	2025-11-10	Passkey専用ボタン設計追加。Origin検証・Supabase連携仕様を明文化。Phase9承認版。
v1.0	2025-10-27	初版（仮仕様、Passkey準備段階）。

**[← 第5章に戻る](login-feature-design-ch05_latest.md) | [目次に戻る ↑](login-feature-design-ch00-index_latest.md)

Created: 2025-11-10 / Last Updated: 2025-11-10 / Version: 1.1 / Document ID: HARMONET-LOGIN-CH06-PASSKEYBUTTON