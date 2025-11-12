# HarmoNet 詳細設計書（ログイン画面）ch00 - Index v1.0（Corbado統合構成）

**Document ID:** HARMONET-LOGIN-DESIGN-CH00
**Version:** 1.0
**Created:** 2025-11-11
**Updated:** 2025-11-11
**Supersedes:** 旧Phase8構成（Supabase単独）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update
**Standard:** harmonet-detail-design-agenda-standard_v1.0（安全テンプレートモード適用）

---

## 第1章 概要

本ドキュメントは、HarmoNetログイン画面の詳細設計書群（ch01〜ch06）の索引および構成方針を示す。
Phase9以降の仕様では、**Magic Link + Passkey（Corbado連携）による完全パスワードレス認証**を採用し、Supabaseはセッション共有・認可管理を担う。

---

## 第2章 技術前提

| 項目      | 内容                                         |
| ------- | ------------------------------------------ |
| フレームワーク | Next.js 16.0.1（App Router）                 |
| ライブラリ   | React 19.0.0 / TypeScript 5.6              |
| UIライブラリ | TailwindCSS 4.x / shadcn/ui / lucide-react |
| 認証基盤    | Supabase Auth v2.43 + Corbado SDK v2.x     |
| 多言語対応   | StaticI18nProvider (C-03)                  |
| データベース  | PostgreSQL 17 + Prisma ORM 5.x             |
| 構成管理    | GitHub / Google Drive Mirror               |
| デザイン方針  | 白基調・Appleカタログ風・BIZ UDゴシック                  |
| 共通部品    | C-01〜C-05（Header〜FooterShortcutBar）        |

---

## 第3章 構成方針

| 章番号  | ファイル名                             | 内容                                |
| ---- | --------------------------------- | --------------------------------- |
| ch01 | login-feature-design-ch01-ui_*.*.md | UI構成・コンポーネント配置                    |
| ch02 | login-feature-design-ch02-state_v*.*.md | 状態管理とフォーム動作（Magic Link + Passkey） |
| ch03 | login-feature-design-ch03-auth_v*.*.md | 認証構成（Supabase OTP + CorbadoAuth）  |
| ch04 | login-feature-design-ch04-session_v*.*.md | SessionHandler設計（/api/session）    |
| ch05 | login-feature-design-ch05-security_v*.*.md | セキュリティ設計（Cookie・RLS・ThreatModel）  |
| ch06 | login-feature-design-ch06-passkey_v*.*.md | PasskeyAuthTrigger設計（A-02）        |

---

## 第4章 コンポーネント構成

| ID        | 名称                                     | 機能                    | 詳細設計書   |
| --------- | -------------------------------------- | --------------------- | ------- |
| A-01      | MagicLinkForm                          | Supabase OTPメール送信フォーム | ch02    |
| A-02      | PasskeyAuthTrigger                     | CorbadoAuth起動トリガUI    | ch06    |
| 共通        | AuthErrorBanner / AuthLoadingIndicator | 状態通知UI                | ch02    |
| C-01〜C-05 | 共通UI（Header〜Footer）                    | グローバルUI部品             | 共通部品設計群 |

---

## 第5章 ログイン方式概要

| 認証方式       | 提供主体               | フロー概要                                          |
| ---------- | ------------------ | ---------------------------------------------- |
| Magic Link | Supabase Auth      | メールOTP → `/auth/callback` → Supabaseセッション確立    |
| Passkey    | Corbado SDK + Node | CorbadoAuth → `/api/session` → Supabaseセッション確立 |
| 共通         | Supabase RLS       | tenant_id + corbado_user_id による行レベル認可          |

**統合特徴:**

* 両方式は同一画面で併存し、Supabaseセッションを共有
* Magic Link は即時OTP型、Passkey はCorbado Cloud連携型
* RLSが両方式共通のアクセス境界を維持

---

## 第6章 参照ドキュメント

| 分類           | ドキュメント名                                          | 用途                         |
| ------------ | ------------------------------------------------ | -------------------------- |
| 技術基盤         | `harmonet-technical-stack-definition_v4.0.md`    | 技術スタック定義                   |
| DB構成         | `HarmoNet_Phase9_DB_Construction_Report_v1.0.md` | Prisma / Supabase構成        |
| セキュリティ仕様     | `Claude実行指示書_C-07_SecuritySpec_v1.0.md`          | Cookie・RLS設計指針             |
| Passkey設計    | `login-feature-design-ch03_v1.0.md`              | CorbadoAuth認証仕様            |
| Magic Link設計 | `login-feature-design-ch02_v1.0.md`              | Supabase OTP仕様             |
| 共通部品         | `/01_docs/04_詳細設計/00_共通部品/`                      | Header〜FooterShortcutBar設計 |

---

## 第7章 開発・運用ポリシー

* 詳細設計書は全て **harmonet-detail-design-agenda-standard_v1.0** および **一発コピペ出力ルール（TKD版）** に準拠。
* コード生成は Windsurf が担当。
* Claude は指示書生成、Gemini はQAレビューを担う。
* 出力形式は常に canmore内部モード（Markdown一括生成）。

---

## 第8章 改訂履歴

| Version | Date       | Author          | Summary                                                    |
| ------- | ---------- | --------------- | ---------------------------------------------------------- |
| 1.0     | 2025-11-11 | TKD + Tachikoma | Corbado公式構成・技術スタックv4.0準拠に統合。Magic Link + Passkeyの併存構成を正式化。 |
