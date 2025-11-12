# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch08 メタ情報 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH08
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（harmonet_detail_design_agenda_standard_v1.0 準拠）

---

## 第8章 メタ情報

### 8.1 用語定義

| 用語                              | 説明                                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Passkey**                     | WebAuthn (FIDO2) に基づく認証方式。ユーザーのデバイス内に秘密鍵を保持し、パスワード不要で認証を行う。                                                         |
| **Corbado**                     | Passkey 管理と認証UIを提供する SaaS（[https://corbado.com）。React/Node](https://corbado.com）。React/Node) SDK を通じて認証・セッション検証を行う。 |
| **Supabase Auth**               | PostgreSQL ベースのBaaS認証モジュール。Corbadoから発行されたIDトークンを受け取り、セッションを確立する。                                                    |
| **StaticI18nProvider (C-03)**   | HarmoNet専用の静的翻訳プロバイダ。`public/locales/{lang}/common.json`を読み込み、`useI18n()` フックで利用する。                                 |
| **ErrorHandlerProvider (C-16)** | グローバルエラーハンドラ。アプリ全体の例外捕捉と通知を担当。                                                                                      |
| **RLS (Row Level Security)**    | Supabase（PostgreSQL）でのテナント分離機能。`tenant_id` によるアクセス制御を実施。                                                            |

---

### 8.2 関連資料

| ドキュメント                                        | 位置                            | 用途                        |
| --------------------------------------------- | ----------------------------- | ------------------------- |
| `harmonet-technical-stack-definition_v4.0.md` | `/01_docs/01_requirements/`   | 技術スタック定義（Corbado公式構成対応）   |
| `MagicLinkForm-detail-design_v1.0.md`         | `/01_docs/04_詳細設計/01_ログイン画面/` | A-01 MagicLinkForm設計書（対照） |
| `StaticI18nProvider-detail-design_v1.0.md`    | `/01_docs/04_詳細設計/00_共通部品/`   | 翻訳Provider仕様              |
| `ErrorHandlerProvider-detail-design_v1.0.md`  | `/01_docs/04_詳細設計/00_共通部品/`   | 例外通知仕様                    |
| `login-feature-design-ch04_v1.0.md`           | `/01_docs/03_基本設計/01_ログイン画面/` | 認証API `/api/session` 設計   |
| `AppHeader-detail-design_v1.0.md`             | `/01_docs/04_詳細設計/00_共通部品/`   | UI共通デザイン基準                |

---

### 8.3 開発・運用メタ情報

| 項目           | 内容                                                               |
| ------------ | ---------------------------------------------------------------- |
| **開発環境**     | Next.js 16 / React 19 / TypeScript 5.6 / TailwindCSS 3.4         |
| **認証基盤**     | Corbado SDK（@corbado/react + @corbado/node） + Supabase Auth 2.43 |
| **実行環境**     | Vercel + Supabase Cloud                                          |
| **ストレージ**    | PostgreSQL 17 + RLS有効                                            |
| **デザイン方針**   | HarmoNet Design System v1（Appleカタログ風、BIZ UDゴシック）                 |
| **翻訳言語**     | 日本語 / 英語 / 中国語（簡体字）                                              |
| **メンテナンス方針** | 月次 Corbado/Supabase SDK バージョン監視、Sentry監査連携                       |

---

### 8.4 ChangeLog

| Version | Date       | Author    | Summary                                         |
| ------- | ---------- | --------- | ----------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma | 初版。用語・関連資料・環境・メンテナンス方針を定義。Phase9 HarmoNet標準に準拠。 |

---

### 8.5 Reviewer / Author / Last Updated

| 区分           | 氏名         | 役割                |
| ------------ | ---------- | ----------------- |
| Author       | Tachikoma  | 詳細設計書作成・整合性検証     |
| Reviewer     | TKD        | 全体監修・技術的承認        |
| Last Updated | 2025-11-11 | 最新版反映（Phase9正式仕様） |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch08_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
