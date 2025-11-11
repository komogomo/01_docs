# MagicLinkForm 詳細設計書 - 第1章：概要（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH01  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第1章 概要

### 1.1 目的
本書は HarmoNet ログイン画面における **メールリンク認証フォーム（A-01 MagicLinkForm）** の概要を定義する。  
ユーザーがメールアドレスを入力して送信すると、Supabase Auth が **Magic Link** を発行し、  
メール経由でワンタップログインを可能にする。

### 1.2 設計方針
- Supabase JS SDK v2.43+ の `auth.signInWithOtp()` を利用。  
- パスワードレス認証（Magic Link）。  
- Next.js 16.0.1 (App Router) + React 19 + TypeScript 5.6。  
- StaticI18nProvider による i18n、簡潔で安心感のあるUI。  
- Supabaseがセッション管理とRLSを担当。  

### 1.3 コンポーネント識別
| 項目 | 内容 |
|------|------|
| コンポーネントID | A-01 |
| コンポーネント名 | MagicLinkForm |
| 分類 | ログイン画面コンポーネント |
| 使用フレームワーク | Next.js 16 / React 19 |
| バージョン | 1.1 |

---

### 1.4 関連ドキュメント
- /01_docs/00_project/harmonet-technical-stack-definition_v4.0.md  
- /01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch03_v1.3.1.md  
- /01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md  
- schema.prisma, initial_schema.sql, enable_rls_policies.sql  

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9技術スタック準拠、Supabase signInWithOtp() 採用、Next.js16対応。 |
