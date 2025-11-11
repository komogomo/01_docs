# HarmoNet 詳細設計書（共通部品）  
## PasskeyButton 詳細設計書 ch02 - UI構成・翻訳定義 v1.2

| 属性 | 値 |
|------|----|
| **Document ID** | HNM-PASSKEY-BUTTON-CH02 |
| **Version** | 1.2 |
| **Created** | 2025-11-10 |
| **Updated** | 2025-11-10 |
| **Author** | Tachikoma |
| **Reviewer** | TKD |
| **Supersedes** | v1.1 |
| **Status** | ✅ Phase9 正式仕様（v1.4整合） |
| **Linked Docs** | login-feature-design-ch03_v1.3.1.md, PasskeyButton-detail-design_v1.4.md |

---

## 第1章 概要

本章は、HarmoNetログイン画面における  
**A-02 PasskeyButton コンポーネント** のUI構成および翻訳仕様を定義する。  

本改訂（v1.2）では、Corbado公式UI構成（`<Auth />`）を廃止し、  
独立ボタン構成 + `Corbado.passkey.login()`呼出し方式へ完全移行。  
MagicLinkForm（A-01）と同一のUIトーン・i18n構成を採用する。

---

## 第2章 UI構成定義

### 2.1 コンポーネント階層
LoginPage (/app/login/page.tsx)
├─ AppHeader (C-01)
├─ MagicLinkForm (A-01)
├─ PasskeyButton (A-02) ← 本仕様対象
├─ AuthCallbackHandler (A-03)
└─ AppFooter (C-04)


### 2.2 デザイン指針

| 要素 | 内容 |
|------|------|
| **配色** | 白基調 (#FFFFFF) に青アクセント (#2563EB) |
| **フォント** | BIZ UDゴシック |
| **フォントサイズ** | 16px |
| **角丸** | rounded-2xl |
| **影** | shadow-sm（軽い立体感） |
| **トーン** | Appleカタログ風・自然で控えめ |
| **整列** | 中央揃え (`flex`, `justify-center`, `items-center`) |
| **高さ** | 48px (`h-12`) |
| **幅** | 100% (`w-full`) |
| **遷移状態** | idle / loading / success / error |

---

## 第3章 状態・イベント仕様

| 状態 | トリガ | 表示内容 | 処理内容 |
|------|---------|-----------|-----------|
| **idle** | 初期表示 | “パスキーでログイン” | ボタン有効 |
| **loading** | ボタン押下 | スピナー＋“認証中...” | Corbado SDKロード＆認証開始 |
| **success** | 認証成功 | チェックアイコン＋“成功” | Supabaseセッション生成 |
| **error** | 例外発生 | 赤系トーン＋再試行文言 | ErrorHandlerProvider通知 |

---

## 第4章 i18nキー仕様

| キー | ja | en | zh |
|------|----|----|----|
| `auth.passkey.login` | パスキーでログイン | Sign in with Passkey | 使用通行密钥登录 |
| `auth.passkey.progress` | 認証中... | Authenticating... | 正在验证... |
| `auth.passkey.success` | 成功しました | Success | 成功 |
| `auth.passkey.retry` | 再試行 | Retry | 重试 |
| `auth.passkey.error` | エラーが発生しました | An error occurred | 发生错误 |

`StaticI18nProvider (C-03)` からロードされ、`useI18n()` フックで取得される。  
翻訳データは `locales/ja/common.json`, `en/common.json`, `zh/common.json` に格納。

---

## 第5章 コンポーネント構造

### 5.1 JSX構成（概要）

```tsx
<button
  type="button"
  className="w-full h-12 flex items-center justify-center gap-2 rounded-2xl bg-blue-600 text-white font-medium hover:bg-blue-500 transition disabled:opacity-60"
  onClick={handlePasskeyLogin}
  disabled={state === 'loading'}
  aria-busy={state === 'loading'}
  aria-live="polite"
>
  {state === 'loading' ? (
    <>
      <Loader2 className="animate-spin" size={20} />
      {t('auth.passkey.progress')}
    </>
  ) : state === 'success' ? (
    <>
      <CheckCircle size={20} />
      {t('auth.passkey.success')}
    </>
  ) : (
    <>
      <KeyRound size={20} />
      {t('auth.passkey.login')}
    </>
  )}
</button>

・Loader2, KeyRound, CheckCircle は lucide-react アイコンを使用。
・状態管理は useState<PasskeyState> で行う。

第6章 翻訳およびアクセシビリティ
| 項目         | 対応内容                                           |
| ---------- | ---------------------------------------------- |
| **多言語**    | StaticI18nProvider経由で`ja/en/zh`切替対応            |
| **ARIA属性** | `aria-busy`, `aria-live="polite"`              |
| **フォーカス**  | `focus-visible:ring-2 focus:ring-blue-300` で強調 |
| **ボタンラベル** | i18nキーを利用し固定文字列を排除                             |

第7章 テスト観点（UI/i18n）
| テストID       | 観点     | 手順         | 成否条件                     |
| ----------- | ------ | ---------- | ------------------------ |
| T-A02-UI-01 | 表示確認   | ページ読み込み時   | “パスキーでログイン”が中央表示される      |
| T-A02-UI-02 | 状態遷移   | ボタン押下→成功   | 成功状態でチェックアイコンと“成功しました”表示 |
| T-A02-UI-03 | エラー通知  | 通信遮断       | “エラーが発生しました”文言が表示される     |
| T-A02-UI-04 | 多言語切替  | 言語トグル操作    | 各言語文言に即時反映               |
| T-A02-UI-05 | A11y検証 | キーボードTab操作 | フォーカスリング表示確認             |

第8章 改訂履歴
| Version  | Date           | Author              | Summary                                     |
| -------- | -------------- | ------------------- | ------------------------------------------- |
| v1.0     | 2025-11-03     | TKD / Tachikoma     | 初版（Supabase直呼び出し構成）                         |
| v1.1     | 2025-11-10     | TKD / Tachikoma     | Corbado公式UI構成（Auth統合）                       |
| **v1.2** | **2025-11-10** | **TKD / Tachikoma** | **独立ボタン構成 + i18n整合（MagicLinkForm準拠）に正式再定義** |

Author: Tachikoma
Reviewer: TKD
Directory: /01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design/
Status: ✅ 承認予定（正式仕様ライン v1.4整合）