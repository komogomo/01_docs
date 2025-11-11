# MagicLinkForm 詳細設計書 - 第1章：概要（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH01
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式整合版（技術スタック v4.0 準拠）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第1章 概要

### 1.1 目的

本章では、HarmoNet ログイン画面における **メールリンク認証フォーム（MagicLinkForm：A-01）** の全体概要を定義する。
MagicLinkForm は、ユーザーが入力したメールアドレスを基に **Supabase Auth** を通じて Magic Link を発行し、パスワードを使用せずにログインを完了させるコンポーネントである。
本機能は Phase9 において、**PasskeyButton (A-02)** と連携し、完全なパスワードレス認証基盤を形成する。

---

### 1.2 設計方針

HarmoNet のログイン体験を「安全・簡潔・一貫性あるUI」で提供するため、以下の設計指針に基づく：

1. **技術基盤の統一性**

   * Next.js 16 (App Router) + React 19 を採用。
   * Supabase JS SDK v2.43 による `auth.signInWithOtp()` API を利用。
   * Corbado SDK と共通基盤化（Phase9技術スタック v4.0 に完全整合）。

2. **UI/UX設計原則**

   * Appleカタログ風のミニマルデザイン。
   * BIZ UDゴシックフォント採用、Rounded-2XL・低コントラストトーン。
   * 入力→送信→成功／エラー表示までを1画面で完結。

3. **国際化 (i18n)**

   * StaticI18nProvider (C-03) を通じ、全メッセージをJSON辞書から取得。
   * 翻訳キーは `auth.*` 名前空間で統一。
   * 日本語・英語・中国語（簡体字）を標準対応。

4. **セキュリティ・RLS整合**

   * Supabase Auth + PostgreSQL RLS によるテナント分離を厳守。
   * Magic Link の有効期限を短縮化（5分）し、リンク再利用を防止。
   * フロント側で入力検証を実施し、サーバー不要な安全構成を維持。

5. **保守・拡張性**

   * Form バリデーション・状態遷移は React Hooks により完結。
   * テスト性・型安全性を重視し、Props型・State定義を厳密管理。
   * 将来的に MFA（多要素認証）連携を容易に統合可能な構造とする。

---

### 1.3 コンポーネント識別情報

| 項目                  | 内容                                               |
| ------------------- | ------------------------------------------------ |
| **Component ID**    | A-01                                             |
| **Component Name**  | MagicLinkForm                                    |
| **Category**        | ログイン画面コンポーネント（Authentication）                    |
| **Framework**       | Next.js 16 / React 19                            |
| **Language**        | TypeScript 5.6                                   |
| **Library**         | Supabase JS SDK v2.43 / lucide-react             |
| **i18n Provider**   | StaticI18nProvider (C-03)                        |
| **Version Control** | GitHub: `Projects-HarmoNet` / DocRepo: `01_docs` |
| **Related Spec**    | PasskeyButton (A-02), AuthCallbackHandler (A-03) |

---

### 1.4 関連ドキュメント

* `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.0.md`（技術基盤定義）
* `/01_docs/04_詳細設計/01_ログイン画面/PasskeyButton-detail-design_v1.4.md`（認証統合仕様）
* `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md`（翻訳基盤）
* `schema.prisma`, `20251107000000_initial_schema.sql`, `20251107000001_enable_rls_policies.sql`（DB定義）
* `HarmoNet_Phase9_DB_Construction_Report_v1_0.md`（RLS実装報告）
* `harmonet-detail-design-agenda-standard_v1.0.md`（本書アジェンダ標準）

---

### 1.5 成果物概要

MagicLinkForm の開発・検証における出力成果物は以下の通り：

| 成果物区分     | ファイル                                     | 説明                  |
| --------- | ---------------------------------------- | ------------------- |
| 実装コード     | `src/components/login/MagicLinkForm.tsx` | メールリンク送信処理本体        |
| 型定義       | `MagicLinkForm.types.ts`                 | Props / State 型定義   |
| テストコード    | `MagicLinkForm.test.tsx`                 | Jest + RTL による単体テスト |
| Storybook | `MagicLinkForm.stories.tsx`              | 送信前／送信中／成功／エラーのUI確認 |
| 翻訳辞書      | `/public/locales/{ja,en,zh}/common.json` | UI文言辞書              |

---

### 1.6 位置付け・連携構成

```mermaid
graph TD
  A[StaticI18nProvider (C-03)] --> B[MagicLinkForm (A-01)]
  B --> C[Supabase Auth signInWithOtp]
  B --> D[AuthCallbackHandler (A-03)]
  B -.-> E[PasskeyButton (A-02)]
```

* **AppHeader (C-01)** 下部に配置され、ログイン画面の主要入力要素を構成。
* 認証後は AuthCallbackHandler (A-03) が Supabase セッション確立を実施。
* 同画面に配置される PasskeyButton (A-02) と統一したUI/UXトーンを維持。

---

### 1.7 保守方針

* バージョン管理は `MagicLinkForm-detail-design_chXX_v*.md` 形式で行い、 `_latest` リンクで常に最新版を参照。
* Supabase JS SDK / Next.js バージョンアップ時は API 差分レビューを必須とする。
* 主要依存（Supabase, Corbado, StaticI18nProvider）は半期ごとに再検証を実施。

---

### 🧾 Change Log

| Version | Date       | Summary                              |
| ------- | ---------- | ------------------------------------ |
| v1.0    | 2025-11-11 | 初版（Phase9仕様：技術スタックv4.0準拠、設計アジェンダ統合版） |
