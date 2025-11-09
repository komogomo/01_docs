Document ID: HNM-LOGIN-FEATURE-CH00
Supersedes: v1.2
ChangeLog: Phase9対応。Magic Link + Passkey化、テナントID廃止、共通部品構成(C-01〜C-05)連携を反映。

HarmoNet ログイン画面 機能設計索引 v1.3.1
| 属性                     | 値                                                              |
| ---------------------- | -------------------------------------------------------------- |
| **Document ID**        | HNM-LOGIN-FEATURE-CH00                                         |
| **Version**            | 1.3.1                                                          |
| **Created**            | 2025-11-09                                                     |
| **Updated by**         | Tachikoma (AI Engineer) + TKD                                  |
| **Supersedes**         | v1.3                                                           |
| **Linked Series**      | login-feature-design-ch01〜ch06                                 |
| **Target Environment** | Next.js 15 / Supabase Auth (GoTrue 2.139 Magic Link + Passkey) |


1. 目的

本書は HarmoNet アプリケーションにおける「ログイン画面」機能群の構成・依存関係・設計章立てを定義する。
Phase9では従来のパスワードレス（Magic Link）のみの方式を拡張し、Passkey (WebAuthn) を統合したハイブリッド認証仕様を採用する。

2. 適用範囲
| 項目       | 内容                                              |
| -------- | ----------------------------------------------- |
| **対象画面** | ログイン画面 (`/login`)、認証コールバック画面 (`/auth/callback`) |
| **関連画面** | HOME (`/home`) 遷移先確認用のみ                         |
| **除外対象** | テナント登録、ユーザー管理画面（管理者専用）                          |
| **対応端末** | PC / Tablet / Smartphone                        |
| **対応言語** | 日本語 / 英語 / 中国語（StaticI18nProvider連携）            |

3. 技術前提
| 項目      | 採用技術                                                                                                     |
| ------- | -------------------------------------------------------------------------------------------------------- |
| フレームワーク | Next.js 15 (App Router)                                                                                  |
| バックエンド  | Supabase OSS v2025.10 (PostgreSQL + RLS)                                                                 |
| 認証      | Supabase Auth (Magic Link + Passkey)                                                                     |
| ORM     | Prisma 6.19.0                                                                                            |
| 多言語     | StaticI18nProvider (C-03) + LanguageSwitch (C-02)                                                        |
| スタイル    | Tailwind CSS + HarmoNet Design System v1.1                                                               |
| テスト     | Jest + React Testing Library                                                                             |
| 依存共通部品  | C-01 AppHeader / C-02 LanguageSwitch / C-03 StaticI18nProvider / C-04 AppFooter / C-05 FooterShortcutBar |

4. 構成と章立て
| 章       | ファイル名                                   | 内容概要                                                  |
| ------- | --------------------------------------- | ----------------------------------------------------- |
| **第1章** | `login-feature-design-ch01_v1.1.md`     | 認証方式仕様（Magic Link + Passkey）／Supabase設定要件／エラーハンドリング分類 |
| **第2章** | `login-feature-design-ch02_v1.1.md`     | 画面UI構成／コンポーネント配置／レスポンシブ設計／操作フロー                       |
| **第3章** | `login-feature-design-ch03_v1.1.md`     | 認証コールバック処理／セッション確立／遷移制御                               |
| **第4章** | `login-feature-design-ch04_v1.1.md`     | ローディング／エラー表示仕様（A-04 A-05）                             |
| **第5章** | `login-feature-design-ch05_v1.1.md`     | i18nキー設計／翻訳文言管理／アクセシビリティ方針                            |
| **第6章** | `login-feature-design-ch06_v1.1.md`     | テスト計画／UT項目／結合確認／自動テスト範囲                               |
| **付録**  | Appendix A 改訂履歴 / Appendix B 関連ドキュメント一覧 |                                                       |

注記（命名の衝突回避）
　本ドキュメント内の「第1章＝login-feature-design-ch01…」「第2章＝login-feature-design-ch02…」はログイン機能の章番号であり、共通部品の C-01（AppHeader）／C-02（LanguageSwitch） とは別系列である。
混同を避けるため、本索引では共通部品は “C-xx” 表記、ログイン機能は “chxx” 表記で統一する。

5. コンポーネント依存関係（Phase9）
graph TD
  RootLayout --> StaticI18nProvider
  StaticI18nProvider --> AppHeader
  AppHeader --> LanguageSwitch
  StaticI18nProvider --> LoginPage
  LoginPage --> MagicLinkForm
  LoginPage --> PasskeyButton
  LoginPage --> AuthErrorBanner
  StaticI18nProvider --> AppFooter
  AppFooter --> FooterShortcutBar

6. 主な変更点（v1.3）
| 変更項目     | 旧仕様             | 新仕様                                |
| -------- | --------------- | ---------------------------------- |
| テナントID入力 | 必須（v1.2）        | 廃止。JWT `tenant_id` で自動識別           |
| 認証方式     | Magic Linkのみ    | Magic Link ＋ Passkey               |
| UI構成     | 固有Header/Footer | 共通部品 C-01〜C-05 連携                  |
| 多言語      | 静的文言            | StaticI18nProvider による辞書管理         |
| セキュリティ   | Cookie-based    | Supabase Auth Session（JWT）         |
| 検証環境     | –               | Supabase CLI + Mailpit + Docker 構成 |

7. 関連ドキュメント
| ファイル                                             | 内容                                                |
| ------------------------------------------------ | ------------------------------------------------- |
| `harmonet-technical-stack-definition_v3.7.md`    | 技術基盤構成（Supabase Auth / Next.js 15 連携）             |
| `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | DB構成 / RLSポリシー / tenant_id連携                      |
| `機能コンポーネント一覧.md`                                 | A-01 ～ A-05 定義（Magic Link / Passkey / Callback 等） |
| `ch01_AppHeader_v1.0.md`                         | 共通Header設計                                        |
| `ch02_LanguageSwitch_v1.1.md`                    | 言語切替設計                                            |
| `ch03_StaticI18nProvider_v1.0.md`                | 翻訳Provider設計                                      |
| `ch04_AppFooter_v1.0.md`                         | 共通Footer設計                                        |
| `ch05_FooterShortcutBar_v1.0.md`                 | ログイン後ショートカット設計                                    |

8. 改訂履歴
| Version  | Date           | Author              | Summary                                                           |
| -------- | -------------- | ------------------- | ----------------------------------------------------------------- |
| v1.0     | 2025-10-27     | TKE                 | 初版（Securea版）                                                      |
| v1.1     | 2025-10-28     | Gemini              | レート制限・トークン仕様追加                                                    |
| v1.2     | 2025-10-28     | Gemini              | 共通エラーハンドリング追加                                                     |
| v1.3     | 2025-11-09     | TKD + Tachikoma | HarmoNet Phase9再設計：Magic Link ＋ Passkey 統合、テナントID廃止、共通部品構成反映。 |
| **v1.3.1** | **2025-11-10** | **TKD + Tachikoma** | **命名体系注記追加（C-xxとchxxの明確区分）。**              |
