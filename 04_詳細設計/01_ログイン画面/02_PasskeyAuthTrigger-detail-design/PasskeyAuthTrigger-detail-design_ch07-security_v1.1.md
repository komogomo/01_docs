# HarmoNet 詳細設計書 - PasskeyAuthTrigger (A-02) ch08 v1.1

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH08
**Version:** 1.1
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.2 / MagicLinkForm 統合対応）

---

## 第8章 メタ情報

### 8.1 用語定義

| 用語                              | 説明                                                                                               |
| ------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Passkey**                     | WebAuthn (FIDO2) に基づくパスワードレス認証方式。ユーザーのデバイス内で秘密鍵を保持し、安全な公開鍵署名によって認証を行う。                           |
| **Corbado Web SDK**             | Passkey 管理と WebAuthn 認証を提供する SaaS。`@corbado/web-js` および `@corbado/node` により、フロント/サーバ間でトークン検証を行う。 |
| **Supabase Auth**               | PostgreSQL ベースの BaaS 認証。Corbado から発行された id_token を使用し、`signInWithIdToken()` によりセッションを確立する。       |
| **PasskeyAuthTrigger (A-02)**   | MagicLinkForm (A-01) 内で動作する非UIロジックモジュール。Passkey 認証の実行・例外分類・Supabase セッション確立を担う。                  |
| **StaticI18nProvider (C-03)**   | 静的翻訳辞書を提供する共通部品。`t('auth.*')` による文言取得を行う。                                                        |
| **ErrorHandlerProvider (C-16)** | グローバル例外通知モジュール。Trigger 内で発生した例外を UI 層に通知する。                                                      |
| **RLS (Row Level Security)**    | Supabase (PostgreSQL) のテナント分離機能。`tenant_id` によりアクセス制御を行う。                                        |

---

### 8.2 関連資料

| ドキュメント                                        | 位置                            | 用途                                    |
| --------------------------------------------- | ----------------------------- | ------------------------------------- |
| `harmonet-technical-stack-definition_v4.2.md` | `/01_docs/01_要件定義/`           | 技術基盤の定義（MagicLinkForm + Passkey 統合仕様） |
| `MagicLinkForm-detail-design_v1.1.md`         | `/01_docs/04_詳細設計/01_ログイン画面/` | 呼出元設計書（UIおよび統合仕様）                     |
| `StaticI18nProvider-detail-design_v1.0.md`    | `/01_docs/04_詳細設計/00_共通部品/`   | 多言語辞書構成仕様                             |
| `ErrorHandlerProvider-detail-design_v1.0.md`  | `/01_docs/04_詳細設計/00_共通部品/`   | 例外通知および分類構成                           |
| `login-feature-design-ch04_v1.1.md`           | `/01_docs/03_基本設計/01_ログイン画面/` | `/api/corbado/session` の連携定義          |

---

### 8.3 開発・運用メタ情報

| 項目           | 内容                                                                          |
| ------------ | --------------------------------------------------------------------------- |
| **開発環境**     | Next.js 16 / React 19 / TypeScript 5.6 / TailwindCSS 3.4                    |
| **認証基盤**     | Corbado Web SDK (`@corbado/web-js` + `@corbado/node`) + Supabase Auth v2.43 |
| **実行環境**     | Vercel + Supabase Cloud                                                     |
| **ストレージ構成**  | PostgreSQL 17 + RLS有効 + Edge Functions                                      |
| **モジュール構造**  | MagicLinkForm (A-01) 内部で `usePasskeyAuthTrigger()` を呼出し、非同期認証を実行            |
| **翻訳言語**     | 日本語 / 英語 / 中国語（簡体字）                                                         |
| **デザイン責務**   | UIは MagicLinkForm 側で保持、PasskeyAuthTrigger はUI非依存設計                          |
| **メンテナンス方針** | Corbado / Supabase SDK の月次更新監視、ログ統計監視、例外発生率 <2% 維持                          |

---

### 8.4 セキュリティ・品質基準

* HTTPS / Secure Cookie / HttpOnly / SameSite=Lax を必須とする。
* `CORBADO_API_SECRET` は Vault にて暗号管理。
* Supabase RLS により `tenant_id` スコープの完全分離を維持。
* JWT 有効期限は 10 分。
* SDK 更新時は Windsurf 自動テストでリグレッションを検証。
* Lint・UT・Storybook いずれもエラーゼロを品質基準とする。

---

### 8.5 ChangeLog

| Version | Date           | Author              | Summary                                                               |
| ------- | -------------- | ------------------- | --------------------------------------------------------------------- |
| 1.0     | 2025-11-11     | Tachikoma           | 旧 PasskeyButton 構成。UI版メタ情報。                                           |
| **1.1** | **2025-11-12** | **Tachikoma / TKD** | **PasskeyAuthTrigger 構成に更新。非UIロジック仕様・技術スタックv4.2対応・MagicLinkForm統合版。** |

---

### 8.6 Reviewer / Author / Last Updated

| 区分           | 氏名         | 役割                |
| ------------ | ---------- | ----------------- |
| Author       | Tachikoma  | 詳細設計書作成・技術統合設計    |
| Reviewer     | TKD        | 全体監修・技術的承認        |
| Last Updated | 2025-11-12 | 最新版反映（Phase9統合仕様） |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyAuthTrigger-detail-design/PasskeyAuthTrigger-detail-design_ch08_v1.1.md`
**Compliance:** harmoNet-detail-design-agenda-standard_v1.0
