# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch01 v1.2

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH01  
**Version:** 1.2  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Component ID:** A-02  
**Component Name:** PasskeyButton  
**Category:** ログイン画面コンポーネント（Authentication Components）  
**Status:** ✅ Phase9 正式仕様（v1.4整合）  

---

## 第1章 概要

### 1.1 目的
本章は、HarmoNetログイン画面における **A-02 PasskeyButton** の機能的・構造的概要を定義する。  
本コンポーネントは MagicLinkForm (A-01) と並列配置され、登録済みパスキーを用いた**ワンタップ認証**を提供する。  
v1.2では `<Auth />` 構成を廃止し、**独立ボタン＋Corbado.passkey.login() 呼出し構成**に統一した。

---

### 1.2 役割と責務

| 項目 | 内容 |
|------|------|
| **主機能** | Passkey認証開始（Corbado SDK経由） |
| **前提** | CorbadoProviderによりSDK初期化済み |
| **出力** | Corbadoのid_token（JWT） |
| **後続処理** | Supabase Authへ `signInWithIdToken()` 連携 |
| **状態管理** | loading / success / error の3段階 |
| **UIトーン** | MagicLinkFormと統一したAppleカタログ風 |

---

### 1.3 コンポーネントの責務範囲

| レイヤ | 責務 | 実装主体 |
|--------|------|----------|
| **UI層** | ボタン表示・クリックハンドラ | PasskeyButton.tsx |
| **SDK層** | Corbado.passkey.login()呼出し | Corbado SDK |
| **セッション層** | Supabase Auth連携 (`signInWithIdToken`) | Supabase SDK |
| **例外層** | ErrorHandlerProvider通知・トースト表示 | 共通部品(C-16) |
| **翻訳層** | StaticI18nProviderより文言取得 (`auth.passkey.*`) | 共通部品(C-03) |

---

### 1.4 配置位置と依存関係
LoginPage (/app/login/page.tsx)
├─ AppHeader (C-01)
├─ MagicLinkForm (A-01)
├─ PasskeyButton (A-02) ← 本コンポーネント
├─ AuthCallbackHandler (A-03)
└─ AppFooter (C-04)


**依存構造図**

```mermaid
graph TD
  A[StaticI18nProvider (C-03)] --> B[PasskeyButton (A-02)]
  C[ErrorHandlerProvider (C-16)] --> B
  B --> D[Corbado SDK]
  B --> E[Supabase Auth]
  F[MagicLinkForm (A-01)] --> G[共通LoginLayout]

1.5 技術仕様概要
| 項目          | 内容                           |
| ----------- | ---------------------------- |
| **フレームワーク** | Next.js 16.0.1 (App Router)  |
| **言語**      | TypeScript 5.6               |
| **UI**      | React 19 + TailwindCSS 3.4   |
| **認証SDK**   | @corbado/web-js v2.x         |
| **DB接続**    | Supabase-js v2.43            |
| **翻訳**      | StaticI18nProvider (C-03)    |
| **例外処理**    | ErrorHandlerProvider (C-16)  |
| **テスト**     | Jest + React Testing Library |
| **ビルド**     | Vite (Next統合)                |

1.6 関連ドキュメント
| 文書名                                           | 参照目的          |
| --------------------------------------------- | ------------- |
| `PasskeyButton-detail-design_v1.4.md`         | 全体仕様との整合基準    |
| `MagicLinkForm-detail-design_v1.1.md`         | 並列UIトーン比較     |
| `login-feature-design-ch03_v1.3.1.md`         | 画面構成定義        |
| `harmonet-technical-stack-definition_v3.9.md` | SDK・バージョン基準   |
| `common-design-system_v1.1.md`                | デザイン共通ルール     |
| `common-i18n_v1.0.md`                         | 翻訳キー・命名規則     |
| `common-accessibility_v1.0.md`                | ARIA・操作ガイドライン |

1.7 更新履歴
| Version  | Date           | Author              | Description                                    |
| -------- | -------------- | ------------------- | ---------------------------------------------- |
| v1.0     | 2025-11-10     | Claude              | Supabase直呼び出し版                                 |
| v1.1     | 2025-11-10     | Tachikoma           | Corbado公式構成採用（暫定）                              |
| **v1.2** | **2025-11-10** | **Tachikoma / TKD** | **正式仕様：独立ボタン構成＋Corbado.passkey.login()方式に再整合** |

Author: Tachikoma
Reviewer: TKD
Directory: /01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design/
Status: ✅ 承認予定（正式仕様ライン）