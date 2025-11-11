# HarmoNet 詳細設計書（ログイン画面）ch00 - Index v1.4

**Document ID:** HARMONET-LOGIN-DESIGN-CH00  
**Version:** 1.4  
**Updated:** 2025-11-10  
**Supersedes:** login-feature-design-ch00-index_v1.3.1.md  
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update  

---

## 第1章 概要

本ドキュメントは、HarmoNetログイン画面に関する詳細設計書群（ch01〜ch06）の索引および構成方針を示す。  
Phase9以降の仕様では、**Magic Link + Passkey（Corbado連携）による完全パスワードレス認証**を採用する。

---

## 第2章 技術前提

| 項目 | 内容 |
|------|------|
| フレームワーク | Next.js **16.0.1**（App Router） |
| ライブラリ | React 19.0.0 / TypeScript 5.6 |
| UIライブラリ | TailwindCSS 3.4 / shadcn/ui / lucide-react |
| 認証基盤 | Supabase Auth v2.43 + Corbado WebAuthn SDK v2.x |
| 多言語対応 | StaticI18nProvider (C-03) |
| データベース | PostgreSQL 15.6 + Prisma ORM 5.x |
| 構成管理 | GitHub / Google Drive Mirror |
| デザイン方針 | 白基調・Appleカタログ風・BIZ UDゴシック採用 |
| 共通部品 | C-01〜C-05（Header〜FooterShortcutBar） |

---

## 第3章 構成方針

### 3.1 対象構成

| 章番号 | ファイル名 | 内容 |
|:--|:--|:--|
| ch01 | login-feature-design-ch01_v1.4.md | 画面UI構成・コンポーネント配置 |
| ch02 | login-feature-design-ch02_v1.3.md | 状態管理・フォーム動作仕様 |
| ch03 | login-feature-design-ch03_v1.3.1.md | UX構成・入出力定義 |
| ch04 | login-feature-design-ch04_v1.2.md | 画面遷移・ルーティング |
| ch05 | login-feature-design-ch05_v1.1.md | セキュリティ仕様（Magic Link / Passkey共通） |
| ch06 | login-feature-design-ch06_v1.1.md | PasskeyButton設計要件（A-02） |

---

## 第4章 コンポーネント構成

| ID | 名称 | 機能 | 詳細設計書 |
|----|------|------|------------|
| A-01 | MagicLinkForm | Magic Link認証フォーム | `MagicLinkForm-detail-design_v1.1.md` |
| A-02 | PasskeyButton | Corbado Passkey連携ボタン | `PasskeyButton-detail-design_v1.0.md` |
| A-03 | AuthCallbackHandler | コールバック処理 | ch04内で定義 |
| C-01 | AppHeader | 共通ヘッダー | `/01_docs/04_詳細設計/00_共通部品/ch01_AppHeader_v1.0.md` |
| C-02 | LanguageSwitch | 言語切替 | `/01_docs/04_詳細設計/00_共通部品/ch02_LanguageSwitch_v1.1.md` |
| C-03 | StaticI18nProvider | 翻訳Provider | `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md` |
| C-04 | AppFooter | 固定フッター | `/01_docs/04_詳細設計/00_共通部品/ch04_AppFooter_v1.0.md` |
| C-05 | FooterShortcutBar | ロール別ショートカット | `/01_docs/04_詳細設計/00_共通部品/ch05_FooterShortcutBar_v1.0.md` |

---

## 第5章 ログイン方式概要

| 認証方式 | 提供主体 | 概要 |
|-----------|-----------|------|
| Magic Link | Supabase Auth | メールOTPによる一時リンクログイン |
| Passkey | Corbado SDK + Supabase | WebAuthn連携によるワンタップログイン |
| RLS制御 | PostgreSQL | tenant_id / role / is_deleted でスコープ分離 |

**特徴:**
- 両方式はSupabaseセッションを共有
- テナント境界はRLSにより厳密に分離
- Passkey登録はMyPage機能で実施予定（別設計書）

---

## 第6章 参照ドキュメント

| 分類 | ドキュメント名 | 用途 |
|------|----------------|------|
| 技術基盤 | `harmonet-technical-stack-definition_v3.9.md` | 技術スタック定義 |
| DB構成 | `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | Prisma / Supabase構成 |
| セキュリティ指示書 | `Claude実行指示書_C-07_SecuritySpec_v1.0.md` | 認証・通信・RLS対策 |
| Passkey設計 | `PasskeyButton-detail-design_v1.0.md` | 実装仕様参照 |
| Magic Link設計 | `MagicLinkForm-detail-design_v1.1.md` | 認証フォーム詳細設計 |

---

## 第7章 改訂履歴

| Version | Date | Summary |
|:--|:--|:--|
| 1.4 | 2025-11-10 | Phase9基盤（Next16 + Corbado + Supabase 2.43）対応・章構成再整合 |
| 1.3.1 | 2025-11-02 | AppRouter導入対応 |
| 1.3 | 2025-10-25 | MagicLink/Passkey併用方式を定義 |
| 1.2以前 | - | 旧Phase8構成 |

---

**次章 →** [ch01: ログイン画面UI構成](login-feature-design-ch01_v1.4.md)

---

