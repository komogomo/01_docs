HarmoNet ログイン画面 詳細設計書 – 第2章 UI構成と画面遷移仕様 v1.1
| 属性                     | 値                                                 |
| ---------------------- | ------------------------------------------------- |
| **Document ID**        | HNM-LOGIN-FEATURE-CH02                            |
| **Version**            | 1.1                                               |
| **Created**            | 2025-11-09                                        |
| **Updated by**         | Tachikoma (AI Engineer) + TKD                     |
| **Supersedes**         | v1.0                                              |
| **Linked Index**       | `login-feature-design-ch00-index_v1.3.md`         |
| **Target Environment** | Next.js 15 + Supabase Auth (Magic Link + Passkey) |

第2章 概要
 本章では、ログイン画面（/login）および認証コールバック画面（/auth/callback）のUI構成・コンポーネント配置・画面遷移仕様を定義する。
全体は共通UI部品（AppHeader・AppFooter・LanguageSwitch・StaticI18nProvider）を利用した統一デザイン構造で構築される。

1. レイアウト構造
1.1 全体構造
┌──────────────────────────────────────────┐
│ AppHeader (C-01)                        │  ← ロゴ + 言語切替
├──────────────────────────────────────────┤
│                                          │
│   ┌──────────────────────────────────┐   │
│   │  MagicLinkForm (A-01)            │   │
│   │  PasskeyButton (A-02)            │   │
│   │  AuthErrorBanner (A-05)          │   │
│   │  AuthLoadingIndicator (A-04)     │   │
│   └──────────────────────────────────┘   │
│                                          │
├──────────────────────────────────────────┤
│ AppFooter (C-04)                         │
│ └─ FooterShortcutBar (C-05, 認証後のみ) │
└──────────────────────────────────────────┘

1.2 レイアウト原則
| 項目      | 値                                   |
| ------- | ----------------------------------- |
| 最大幅     | 420px（中央寄せカードレイアウト）                 |
| 縦位置     | 画面中央固定、上部60px余白（Header分）            |
| 背景      | `#F9FAFB`                           |
| 角丸      | `1.5rem (radius-2xl)`               |
| 影       | `shadow-sm`                         |
| コンテンツ間隔 | `gap-4`                             |
| ボタン配置   | MagicLinkForm → PasskeyButtonの順に縦配置 |

2. UIコンポーネント仕様
2.1 MagicLinkForm（A-01）
| 項目          | 内容                                                                   |
| ----------- | -------------------------------------------------------------------- |
| **目的**      | メールアドレス入力・ログインリンク送信                                                  |
| **構成要素**    | `<input type="email">`, `<button type="submit">`, `InlineFieldError` |
| **バリデーション** | 必須 + メール形式 (`/.+@.+\..+/`)                                           |
| **イベント**    | `onSubmit()` → `signInWithOtp()`                                     |
| **エラー表示**   | AuthErrorBanner (A-05)を通じて表示                                         |
| **状態**      | `loading`, `success`, `error`                                        |
| **文言キー**    | `auth.email`, `auth.sendLink`, `auth.error.invalid_link`             |

2.2 PasskeyButton（A-02）
| 項目       | 内容                                         |
| -------- | ------------------------------------------ |
| **目的**   | 登録済みPasskeyでのワンタップログイン                     |
| **構成要素** | `<Button>` (shadcn/ui)、アイコン: `Fingerprint` |
| **動作**   | `supabase.auth.signInWithPasskey()` 呼出     |
| **成功時**  | `/home` へ遷移                                |
| **失敗時**  | `auth.error.no_passkey` を表示                |
| **補助表示** | 未登録時「Passkey登録はマイページから」の案内                 |

2.3 AuthErrorBanner（A-05）
| 項目          | 内容                            |
| ----------- | ----------------------------- |
| **役割**      | 認証時のエラーメッセージ表示領域              |
| **配置**      | フォーム下部（固定高さ 48px）             |
| **カラー**     | 背景: `#FEF2F2` / 文字: `#B91C1C` |
| **翻訳キー**    | `auth.error.*`                |
| **アニメーション** | `fadeIn` / `fadeOut` (300ms)  |

2.4 AuthLoadingIndicator（A-04）
| 項目         | 内容                                    |
| ---------- | ------------------------------------- |
| **役割**     | Supabase呼出中の状態表示                      |
| **構成**     | スピナー（SVG, `animate-spin`）＋「認証中…」メッセージ |
| **条件**     | `loading=true` のときのみ表示                |
| **ARIA属性** | `role="status"`, `aria-live="polite"` |

3. 状態遷移仕様
3.1 ログイン画面 /login
| 状態  | イベント            | 遷移先              | 表示                            |
| --- | --------------- | ---------------- | ----------------------------- |
| 初期  | -               | `/login`         | MagicLinkForm + PasskeyButton |
| 入力中 | 入力操作            | `/login`         | 入力反映                          |
| 送信中 | submit          | `/login`         | AuthLoadingIndicator表示        |
| 成功  | Supabaseから成功応答  | `/auth/callback` | 自動遷移                          |
| エラー | Supabaseからエラー応答 | `/login`         | AuthErrorBanner表示             |

3.2 コールバック画面 /auth/callback
| 状態 | 処理              | 遷移先                          | 表示                |
| -- | --------------- | ---------------------------- | ----------------- |
| 初期 | クエリに `code` が存在 | `/auth/callback`             | 検証処理開始            |
| 成功 | セッション確立         | `/home`                      | -                 |
| 失敗 | トークン無効          | `/login?error=invalid_token` | AuthErrorBanner表示 |

4. 多言語およびアクセシビリティ
4.1 多言語対応
・全ラベル・メッセージは StaticI18nProvider (C-03) から取得。
・LanguageSwitch (C-02) により即時切替可能。
・JSON辞書：/public/locales/{ja|en|zh}/common.json

4.2 アクセシビリティ方針
| 対応項目      | 内容                                         |
| --------- | ------------------------------------------ |
| フォームラベル   | `aria-label`, `for`属性で明示                   |
| ボタン       | `aria-pressed` / `aria-busy` 対応            |
| カラーコントラスト | WCAG 2.1 AA準拠（コントラスト比 4.5:1以上）             |
| キーボード操作   | Tab移動・Enter送信対応                            |
| ローディング    | `role="status"` / `aria-live="polite"` を付与 |

5. デザインスタイル
| 項目      | 値                                     |
| ------- | ------------------------------------- |
| フォント    | BIZ UDゴシック                            |
| テーマカラー  | `#2563EB` (action-blue)               |
| 背景      | `#F9FAFB`                             |
| 角丸      | 12px                                  |
| シャドウ    | `0 1px 2px rgba(0,0,0,0.05)`          |
| 間隔      | `gap-4`                               |
| トランジション | 全体 `transition-all 200ms ease-in-out` |

6. 関連ファイル
| 依存         | ファイル                              | 用途       |
| ---------- | --------------------------------- | -------- |
| 共通ヘッダー     | `ch01_AppHeader_v1.0.md`          | ロゴと言語切替  |
| 翻訳Provider | `ch03_StaticI18nProvider_v1.0.md` | i18n辞書管理 |
| フッター       | `ch04_AppFooter_v1.0.md`          | コピーライト表示 |
| ローディング     | `A-04 AuthLoadingIndicator`       | 状態表示     |
| エラー        | `A-05 AuthErrorBanner`            | エラー出力    |

7. 改訂履歴
| Version  | Date           | Author              | Summary                                                                               |
| -------- | -------------- | ------------------- | ------------------------------------------------------------------------------------- |
| v1.0     | 2025-10-27     | TKE                 | Securea版 UI構成（メール＋テナントID）                                                             |
| **v1.1** | **2025-11-09** | **TKD + Tachikoma** | **Magic Link + Passkey統合構成。テナントID入力削除。AppHeader/AppFooter/StaticI18nProvider構成に再設計。** |

---

**[← 第1章に戻る](login-feature-design-ch01_latest.md)  |  [第3章へ →](login-feature-design-ch03_latest.md)**

