HarmoNet ログイン画面 詳細設計書 – 第1章 認証方式仕様（Magic Link + Passkey） v1.1
| 属性                     | 値                                                              |
| ---------------------- | -------------------------------------------------------------- |
| **Document ID**        | HNM-LOGIN-FEATURE-CH01                                         |
| **Version**            | 1.1                                                            |
| **Created**            | 2025-11-09                                                     |
| **Updated by**         | Tachikoma (AI Engineer) + TKD                                  |
| **Supersedes**         | v1.0                                                           |
| **Linked Index**       | `login-feature-design-ch00-index_v1.3.md`                      |
| **Target Environment** | Next.js 15 + Supabase Auth (GoTrue 2.139 Magic Link + Passkey) |

第1章 概要
1.1 目的
　本章は、HarmoNetログイン画面におけるSupabase Auth認証方式の技術仕様を定義する。
Magic Linkによるメールベース認証と、Passkey（WebAuthn）による生体認証を統合し、パスワードを用いないセキュアなログイン体験を実現する。

2. 採用方式と構成
| 区分     | 方式                     | 使用API                                       | 備考                     |
| ------ | ---------------------- | ------------------------------------------- | ---------------------- |
| メール認証  | Magic Link             | `signInWithOtp()`                           | ワンタイムリンクによるログイン        |
| 生体認証   | Passkey (WebAuthn)     | `signInWithPasskey()` / `registerPasskey()` | FaceID / 指紋認証等に対応      |
| 認証管理   | Supabase Auth (GoTrue) | JWT発行・検証                                    | MagicLink・Passkey共通で利用 |
| コールバック | `/auth/callback`       | `exchangeCodeForSession()`                  | トークン検証・セッション確立         |

3. 認証動作フロー
3.1 Magic Link 認証フロー
1. ユーザーがメールアドレスを入力し「ログインリンクを送信」を押下
2. Supabase AuthがMagic Linkを生成し、Mailpit経由でメール送信
3. ユーザーがメール内のリンクをクリック
4. ブラウザで `/auth/callback` ページへ遷移
5. Supabaseがトークンを検証し、セッションを発行
6. ログイン完了後 `/home` にリダイレクト

3.2 Passkey 認証フロー
1. ログイン画面で「Passkeyでログイン」を押下
2. OS側生体認証を起動
3. 認証成功後、Supabase Authがセッションを生成
4. `/home` に遷移

3.3 Passkey登録フロー（初回のみ）
1. Magic Linkログイン完了後、マイページで「Passkeyを登録」押下
2. `supabase.auth.registerPasskey()` 実行
3. 生体認証デバイスに登録
4. 次回以降のログインで自動利用可能

4. Supabase Auth 設定要件
| 設定キー                            | 推奨値                     | 説明                     |
| ------------------------------- | ----------------------- | ---------------------- |
| `GOTRUE_FEATURES`               | `email,webauthn`        | Magic LinkとPasskeyを有効化 |
| `GOTRUE_WEBAUTHN_ENABLED`       | `true`                  | WebAuthn利用を許可          |
| `GOTRUE_EXTERNAL_EMAIL_ENABLED` | `true`                  | メールログイン許可              |
| `GOTRUE_MAILER_AUTOCONFIRM`     | `true`                  | 開発環境で自動承認              |
| `MAILER_URL_PATHS_CONFIRMATION` | `/auth/callback`        | Magic LinkのコールバックURL   |
| `SITE_URL`                      | `http://localhost:3000` | Mailpit受信リンクのベースURL    |

5. トークンとセッション管理
| 項目               | 格納先               | 有効期限 | 備考              |
| ---------------- | ----------------- | ---- | --------------- |
| `access_token`   | Supabaseセッション     | 60分  | JWT署名付き         |
| `refresh_token`  | Supabaseセッション     | 自動更新 | 長期保持            |
| `user.id`        | JWT `sub`         | -    | RLS参照キー         |
| `user.tenant_id` | JWT claim         | -    | RLSによるマルチテナント分離 |
| `user.role`      | `user_roles` テーブル | -    | 権限制御に使用         |

6. 例外・エラーハンドリング仕様
| 分類         | 表示UI              | メッセージキー                   | 処理内容            |
| ---------- | ----------------- | ------------------------- | --------------- |
| 入力未指定      | `AuthErrorBanner` | `auth.error.empty_email`  | 送信不可、エラー表示      |
| 不正リンク      | `AuthErrorBanner` | `auth.error.invalid_link` | コールバックリダイレクト    |
| Passkey未登録 | `AuthErrorBanner` | `auth.error.no_passkey`   | 登録誘導表示          |
| 通信失敗       | Toast通知           | `common.network_error`    | 再試行案内           |
| レート制限      | `AuthErrorBanner` | `auth.error.rate_limit`   | 再送信ボタンを無効化（60秒） |

7. コールバック処理仕様
| 処理対象        | 内容                                   |
| ----------- | ------------------------------------ |
| **URL**     | `/auth/callback`                     |
| **処理順**     | ① トークン検証 → ② セッション保存 → ③ `/home` へ遷移 |
| **例外時**     | `/login?error=invalid_token` へリダイレクト |
| **ステートレス性** | セッションはSupabase Authが管理（Cookie不要）     |

8. 状態管理仕様
・クライアント側は supabase.auth.onAuthStateChange() でログイン状態を監視。
・状態は AuthContext または Zustand に保持。
・SSRでは createServerClient() を利用してトークンを復元し、認証済みルート制御を行う。

9. 関連コンポーネント
| ID   | 名称                   | 役割                 |
| ---- | -------------------- | ------------------ |
| A-01 | MagicLinkForm        | メール入力・リンク送信フォーム    |
| A-02 | PasskeyButton        | Passkeyログインボタン     |
| A-03 | AuthCallbackHandler  | `/auth/callback`処理 |
| A-04 | AuthLoadingIndicator | ローディング表示           |
| A-05 | AuthErrorBanner      | エラー表示領域            |

10. 翻訳キー一覧（i18n）
| キー                        | 日本語                | 英語                    | 中国語         |
| ------------------------- | ------------------ | --------------------- | ----------- |
| `auth.title`              | ログイン               | Login                 | 登录          |
| `auth.email`              | メールアドレス            | Email                 | 邮箱          |
| `auth.sendLink`           | ログインリンクを送信         | Send Magic Link       | 发送登录链接      |
| `auth.passkey`            | Passkeyでログイン       | Login with Passkey    | 使用Passkey登录 |
| `auth.error.invalid_link` | 無効なリンクです           | Invalid link          | 链接无效        |
| `auth.error.rate_limit`   | 短時間に多くのリクエストがありました | Too many requests     | 请求过多        |
| `auth.error.no_passkey`   | Passkeyが登録されていません  | No passkey registered | 尚未注册Passkey |

11. 改訂履歴
| Version  | Date           | Author              | Summary                                                       |
| -------- | -------------- | ------------------- | ------------------------------------------------------------- |
| v1.0     | 2025-10-27     | TKE                 | Securea版：Magic Link単体構成                                       |
| **v1.1** | **2025-11-09** | **TKD + Tachikoma** | **HarmoNet版：Magic Link + Passkey統合。テナントID廃止。Supabase設定仕様追加。** |
