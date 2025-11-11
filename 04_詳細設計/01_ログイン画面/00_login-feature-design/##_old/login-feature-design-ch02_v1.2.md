# HarmoNet ログイン画面 詳細設計書 – 第2章 状態管理とフォーム動作仕様 v1.2

| 属性 | 値 |
|------|----|
| **Document ID** | HNM-LOGIN-FEATURE-CH02 |
| **Version** | 1.2 |
| **Created** | 2025-11-09 |
| **Updated** | 2025-11-10 |
| **Updated by** | Tachikoma (AI Engineer) + TKD |
| **Supersedes** | v1.1 |
| **Linked Index** | `login-feature-design-ch00-index_v1.4.md` |
| **Target Environment** | Next.js 16.0.1 + Supabase 2.43 + Corbado WebAuthn SDK |

---

## 第1章 概要

本章では、ログイン画面(`/login`)および認証コールバック画面(`/auth/callback`)における  
**Magic Link + Passkey（Corbado連携）** の状態管理構造、フォーム動作仕様、イベント遷移を定義する。  
Phase9以降、HarmoNetは完全パスワードレス認証へ移行した。

---

## 第2章 レイアウト構造
┌──────────────────────────────────────────┐
│ AppHeader (C-01) │ ← ロゴ + 言語切替
├──────────────────────────────────────────┤
│ StaticI18nProvider (C-03) │
│ ├─ MagicLinkForm (A-01) │
│ ├─ Divider ("または") │
│ ├─ PasskeyButton (A-02) │
│ ├─ AuthErrorBanner (A-05) │
│ └─ AuthLoadingIndicator (A-04) │
├──────────────────────────────────────────┤
│ AppFooter (C-04) │
│ └─ FooterShortcutBar (C-05 認証後のみ)│
└──────────────────────────────────────────┘


---

## 第3章 MagicLinkForm（A-01）

| 項目 | 内容 |
|------|------|
| **目的** | メールOTP（Magic Link）送信によるログイン |
| **イベント** | `onSubmit()` → `supabase.auth.signInWithOtp()` |
| **バリデーション** | メール形式 (`/.+@.+\..+/`)、空欄禁止 |
| **状態** | `idle` → `sending` → `sent` / `error` |
| **成功時** | 「メールを確認してください」メッセージ表示 |
| **エラー表示** | `AuthErrorBanner`経由で表示 |
| **翻訳キー** | `login.email_label`, `login.send_button`, `login.sent_message` |

```typescript
const handleMagicLink = async () => {
  setState({ status: 'sending' });
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}/auth/callback` },
  });
  if (error) setState({ status: 'error', errorMessage: error.message });
  else setState({ status: 'sent' });
};

第4章 PasskeyButton（A-02）
| 項目        | 内容                                            |
| --------- | --------------------------------------------- |
| **目的**    | 登録済みPasskeyを使用したWebAuthnログイン                  |
| **ライブラリ** | Corbado WebAuthn SDK v2.x                     |
| **連携構成**  | Corbado → Supabase Auth (`signInWithIdToken`) |
| **状態**    | `idle` → `loading` → `success` / `error`      |
| **成功時**   | JWTセッション確立 → `/mypage`遷移                      |
| **エラー時**  | `error_network`, `error_origin` など表示          |

const handlePasskeyLogin = async () => {
  setState({ status: 'loading' });
  try {
    await Corbado.load({ projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID! });
    const idToken = await Corbado.authenticateWithPasskey();
    await supabase.auth.signInWithIdToken({ provider: 'corbado', token: idToken });
    router.push('/mypage');
  } catch (error) {
    setState({ status: 'error', errorMessage: (error as Error).message });
  }
};

第5章 状態遷移仕様
| 状態      | イベント        | 遷移後              | 表示                            |
| ------- | ----------- | ---------------- | ----------------------------- |
| idle    | -           | `/login`         | MagicLinkForm + PasskeyButton |
| sending | メール送信中      | `/login`         | AuthLoadingIndicator表示        |
| sent    | 成功応答        | `/auth/callback` | リダイレクト                        |
| error   | Supabaseエラー | `/login`         | AuthErrorBanner表示             |

5.2 /auth/callback 画面
| 状態 | 処理             | 遷移後                          | 表示     |
| -- | -------------- | ---------------------------- | ------ |
| 初期 | `code` パラメータ検証 | `/auth/callback`             | 検証中表示  |
| 成功 | セッション確立        | `/mypage`                    | ログイン完了 |
| 失敗 | トークン無効         | `/login?error=invalid_token` | エラー表示  |

第6章 多言語・アクセシビリティ
| 項目        | 内容                                     |
| --------- | -------------------------------------- |
| 多言語       | StaticI18nProviderによる即時切替（ja/en/zh）    |
| ラベル       | 全要素に`aria-label`付与                     |
| カラーコントラスト | WCAG 2.1 AA基準（4.5:1以上）                 |
| キーボード操作   | Tab移動 / Enter送信対応                      |
| ローディング    | `role="status"` / `aria-live="polite"` |

第7章 デザインスタイル
| 項目      | 値                                  |
| ------- | ---------------------------------- |
| 背景      | `#F9FAFB`                          |
| 角丸      | `1.5rem` (`rounded-2xl`)           |
| フォント    | BIZ UDゴシック                         |
| メインカラー  | `#2563EB`                          |
| 影       | `shadow-sm`                        |
| トランジション | `transition-all 200ms ease-in-out` |

第8章 関連ファイル
| 種別         | ファイル                                    | 用途          |
| ---------- | --------------------------------------- | ----------- |
| 共通Header   | `ch01_AppHeader_v1.0.md`                | ロゴ＋言語切替     |
| 翻訳Provider | `ch03_StaticI18nProvider_v1.0.md`       | i18n辞書管理    |
| Footer     | `ch04_AppFooter_v1.0.md`                | コピーライト表示    |
| Component  | `PasskeyButton-detail-design_v1.0.md`   | Passkey仕様詳細 |
| Spec       | `Claude実行指示書_C-07_SecuritySpec_v1.0.md` | 認証・通信制御     |

第9章 改訂履歴
| Version  | Date           | Author              | Summary                                                        |
| -------- | -------------- | ------------------- | -------------------------------------------------------------- |
| **v1.2** | **2025-11-10** | **TKD + Tachikoma** | **Next.js 16.0.1 / Supabase 2.43 / Corbado SDK対応、Phase9仕様整合化** |
| v1.1     | 2025-11-09     | TKD + Tachikoma     | Magic Link + Passkey統合構成、テナントID削除                              |
| v1.0     | 2025-10-27     | TKE                 | 初期Securea構成（メール＋テナントID）                                        |
