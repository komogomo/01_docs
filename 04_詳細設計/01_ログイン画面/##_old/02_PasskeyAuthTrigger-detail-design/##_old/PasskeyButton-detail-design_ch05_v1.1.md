# PasskeyButton 詳細設計書 - 第5章：UI構造（v1.1 改訂版）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH05  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmoNet-technical-stack-definition_v4.0 / PasskeyButton-detail-design_v1.4.md  
**Reviewer:** TKD  
**Status:** Phase9 正式仕様整合版  

---

## 第5章：UI構造

### 5.1 コンポーネント構造

#### 5.1.1 JSX構造（Corbado v2 対応）
```tsx
<button
  onClick={handlePasskeyLogin}
  disabled={state === 'loading'}
  className={computedClassName}
  aria-label={t('auth.passkey.label')}
  aria-busy={state === 'loading'}
  aria-live="polite"
  type="button"
>
  {state === 'loading' ? (
    <>
      <Loader2 className="w-5 h-5 animate-spin" aria-hidden="true" />
      <span>{t('auth.passkey.loading')}</span>
    </>
  ) : state === 'success' ? (
    <>
      <CheckCircle className="w-5 h-5 text-green-500" aria-hidden="true" />
      <span>{t('auth.passkey.success')}</span>
    </>
  ) : state === 'error' ? (
    <>
      <XCircle className="w-5 h-5 text-red-500" aria-hidden="true" />
      <span>{t('auth.passkey.error')}</span>
    </>
  ) : (
    <>
      <KeyRound className="w-5 h-5" aria-hidden="true" />
      <span>{t('auth.passkey.login')}</span>
    </>
  )}
</button>

5.1.2 DOM階層
button（ルート）
├── SVGアイコン（Loader2 / CheckCircle / XCircle / KeyRound）
└── span（テキスト表示）

5.2 スタイリング仕様
5.2.1 基本スタイル（Design System準拠）
const baseStyles = `
  flex items-center justify-center gap-2
  w-full sm:w-auto sm:min-w-[220px]
  px-6 py-3
  rounded-2xl
  font-medium text-base
  bg-blue-600 text-white
  shadow-sm
  transition-all duration-200
  focus-visible:outline-none
  focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2
`;

5.2.2 状態別クラス
| 状態      | Tailwindクラス                            | 補足    |
| ------- | -------------------------------------- | ----- |
| idle    | `hover:bg-blue-700 active:bg-blue-800` | 通常表示  |
| loading | `cursor-wait opacity-90`               | スピナー中 |
| success | `bg-green-600 hover:bg-green-700`      | 成功時   |
| error   | `bg-red-600 hover:bg-red-700`          | 認証失敗時 |

5.3 アイコン仕様
| 状態      | アイコン        | ライブラリ        | サイズ  | カラー                 |
| ------- | ----------- | ------------ | ---- | ------------------- |
| idle    | KeyRound    | lucide-react | 20px | 継承                  |
| loading | Loader2     | lucide-react | 20px | 継承 + `animate-spin` |
| success | CheckCircle | lucide-react | 20px | `text-green-500`    |
| error   | XCircle     | lucide-react | 20px | `text-red-500`      |

5.4 テキスト仕様（StaticI18nProvider）
5.4.1 翻訳キー構造
"auth": {
  "passkey": {
    "label": "パスキーでログイン",
    "login": "パスキーでログイン",
    "loading": "認証中...",
    "success": "認証完了",
    "error": "認証に失敗しました"
  }
}

5.4.2 対応言語例
| 言語  | login                | loading           | success   | error                 |
| --- | -------------------- | ----------------- | --------- | --------------------- |
| 日本語 | パスキーでログイン            | 認証中...            | 認証完了      | 認証に失敗しました             |
| 英語  | Sign in with Passkey | Authenticating... | Signed in | Authentication failed |
| 中国語 | 使用密钥登录               | 认证中...            | 登录成功      | 登录失败                  |

5.5 アクセシビリティ仕様
・aria-label による文脈ラベル（翻訳対応）
・aria-busy と aria-live="polite" による状態通知
・focus-visible スタイル：リング色 #2563EB、2px、offset 2px
・Tab / Enter / Space 操作対応
・WCAG 2.1 AA コントラスト比 4.5:1 準拠

5.6 トランジション・アニメーション
transition-all duration-200 ease-in-out

適用範囲: 背景色・テキスト色・アイコン色・スピナー

5.7 設計意図
・Corbado公式API構成（Corbado.load + Corbado.passkey.login）への完全適合
・Supabase signInWithIdToken 認証連携を前提とするUI
・Appleカタログ風スタイル（白ベース・控えめ・角丸2xl・shadow-sm）
・StaticI18nProviderによる翻訳統合とARIA完全対応

🧾 ChangeLog
| Version | Date       | Summary                                                        |
| ------- | ---------- | -------------------------------------------------------------- |
| v1.0    | 2025-01-10 | 初版（Claude生成、Corbado.loginWithPasskey 前提）                       |
| v1.1    | 2025-11-10 | Corbado公式構成＋Supabase整合に更新。UI状態4種化、i18n・ARIA対応、Design System反映。 |

文書ステータス: ✅ HarmoNet Phase9 正式整合版