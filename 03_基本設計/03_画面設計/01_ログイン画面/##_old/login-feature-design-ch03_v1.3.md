HarmoNet ログイン画面 詳細設計書 – 第3章 コールバック処理・セッション確立仕様 v1.3
| 属性                     | 値                                                 |
| ---------------------- | ------------------------------------------------- |
| **Document ID**        | HNM-LOGIN-FEATURE-CH03                            |
| **Version**            | 1.3                                               |
| **Created**            | 2025-11-09                                        |
| **Updated by**         | Tachikoma (AI Engineer) + TKD                     |
| **Supersedes**         | v1.2                                              |
| **Linked Index**       | `login-feature-design-ch00-index_v1.3.md`         |
| **Target Environment** | Next.js 15 + Supabase Auth (Magic Link + Passkey) |

第3章 概要
　本章では、ログイン認証後の /auth/callback ページにおけるトークン検証・セッション確立・リダイレクト処理の仕様を定義する。
Magic Link および Passkey 双方のフローで共通のセッション確立方式を用いる。

1. コールバック概要
1.1 処理の目的
・Supabase Authが発行した一時コード (code) を検証し、有効なJWTセッションを確立する。
・認証結果に応じて、アプリの初期遷移先（/home）またはエラー遷移先へ制御を移す。

1.2 対象ページ
| ページ              | 役割                                  |
| ---------------- | ----------------------------------- |
| `/auth/callback` | 認証完了後に戻る専用ページ（Magic Link／Passkey共通） |

2. フローチャート
ユーザー
  ↓ (Magic Linkクリック / Passkey認証成功)
`/auth/callback` にアクセス
  ↓
Supabase Auth が URL パラメータ `code` を付与
  ↓
App Router が `AuthCallbackHandler` を起動
  ↓
1. `exchangeCodeForSession()` でセッション検証
2. 成功 → セッション保存 → `/home` へ遷移
3. 失敗 → エラー通知 → `/login?error=invalid_token` へ

3. 実装仕様
3.1 コールバックハンドラ構造
| コンポーネント                | ファイル                                            | 概要         |
| ---------------------- | ----------------------------------------------- | ---------- |
| `AuthCallbackHandler`  | `/src/components/auth/AuthCallbackHandler.tsx`  | コールバック処理本体 |
| `AuthErrorBanner`      | `/src/components/auth/AuthErrorBanner.tsx`      | エラー表示領域    |
| `AuthLoadingIndicator` | `/src/components/auth/AuthLoadingIndicator.tsx` | 検証中インジケータ  |

3.2 コード構成（擬似構文）
'use client'
import { useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabaseClient'

export default function AuthCallbackHandler() {
  const router = useRouter()
  const supabase = createClient()
  const code = useSearchParams().get('code')

  useEffect(() => {
    const process = async () => {
      if (!code) return router.push('/login?error=invalid_link')
      const { error } = await supabase.auth.exchangeCodeForSession(code)
      if (error) router.push(`/login?error=${error.message}`)
      else router.push('/home')
    }
    process()
  }, [code])
}

4. セッション管理
| 項目   | 内容                                             |
| ---- | ---------------------------------------------- |
| 管理方式 | Supabase Auth 内部セッション（Cookieレス）                |
| 保持情報 | `access_token`, `refresh_token`, `user` オブジェクト |
| 有効期限 | 60分（自動リフレッシュ有効）                                |
| 保管場所 | IndexedDB（`localStorage` 非使用）                  |
| 同期監視 | `supabase.auth.onAuthStateChange()` により状態監視    |

4.1 状態遷移
| 状態                | イベント                     | 処理                               |
| ----------------- | ------------------------ | -------------------------------- |
| `unauthenticated` | Magic Linkクリック／Passkey成功 | `exchangeCodeForSession()` 実行    |
| `authenticated`   | セッション発行成功                | `/home` リダイレクト                   |
| `error`           | 無効リンク・期限切れ               | `/login?error=invalid_token` へ遷移 |

5. リダイレクト制御
| 条件         | 遷移先                         | 備考                        |
| ---------- | --------------------------- | ------------------------- |
| 認証成功       | `/home`                     | 初期画面へ                     |
| 無効リンク      | `/login?error=invalid_link` | `auth.error.invalid_link` |
| トークン期限切れ   | `/login?error=expired`      | `auth.error.expired_link` |
| 通信失敗       | `/login?error=network`      | ネットワークエラー通知               |
| Passkey未登録 | `/login?error=no_passkey`   | 登録誘導を表示                   |

6. SSRとセッション復元
| 項目        | 内容                                     |
| --------- | -------------------------------------- |
| サーバーサイド復元 | `createServerClient()` を利用して認証済み状態を再構築 |
| クライアント引継ぎ | SSR後、`AuthContext` により認証状態を維持          |
| クッキー利用    | なし（Supabase SDKが自動的にローカルセッションを管理）      |
| RLS対応     | JWT内 `tenant_id` を自動注入し、テナントデータを制御     |

7. エラーハンドリング仕様
| 分類         | 表示UI            | 翻訳キー                      | 処理               |
| ---------- | --------------- | ------------------------- | ---------------- |
| 無効リンク      | AuthErrorBanner | `auth.error.invalid_link` | `/login` に遷移し再試行 |
| 有効期限切れ     | AuthErrorBanner | `auth.error.expired_link` | 再送信案内を表示         |
| 通信失敗       | Toast通知         | `common.network_error`    | 再送信ボタン活性化        |
| Passkey未登録 | AuthErrorBanner | `auth.error.no_passkey`   | 案内文を表示           |
| 不明エラー      | AuthErrorBanner | `auth.error.unknown`      | 一般エラー表示          |

8. 関連フロー連携
| 前段階        | 対応ファイル                              | 出力結果                              |
| ---------- | ----------------------------------- | --------------------------------- |
| ログインフォーム送信 | `login-feature-design-ch02_v1.1.md` | `/auth/callback?code=[token]` へ遷移 |
| コールバック処理   | 本章                                  | セッション確立・RLS適用                     |
| ホーム画面遷移    | `/home`                             | 認証完了状態                            |

9. i18n キー一覧
| キー                        | 日本語               | 英語                    | 中国語         |
| ------------------------- | ----------------- | --------------------- | ----------- |
| `auth.error.invalid_link` | 無効なリンクです          | Invalid link          | 链接无效        |
| `auth.error.expired_link` | リンクの有効期限が切れています   | Link expired          | 链接已过期       |
| `auth.error.network`      | 通信エラーが発生しました      | Network error         | 网络错误        |
| `auth.error.no_passkey`   | Passkeyが登録されていません | No passkey registered | 尚未注册Passkey |
| `auth.error.unknown`      | 不明なエラーが発生しました     | Unknown error         | 未知错误        |

10. 改訂履歴
| Version  | Date           | Author              | Summary                                                                   |
| -------- | -------------- | ------------------- | ------------------------------------------------------------------------- |
| v1.0     | 2025-10-27     | TKE                 | 初版（Magic Link単体構成）                                                        |
| v1.1     | 2025-10-28     | Gemini              | レート制限・エラーハンドリング更新                                                         |
| v1.2     | 2025-10-29     | Gemini              | コールバック構成・テナント検証追加                                                         |
| **v1.3** | **2025-11-09** | **TKD + Tachikoma** | **HarmoNet仕様化：Supabase Authセッション化、Magic Link＋Passkey統合、JWT tenant_id対応。** |
