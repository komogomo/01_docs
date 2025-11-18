# MagicLinkForm 詳細設計書 - 第1章：概要（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH01
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Passkey自動統合対応）

---

## 第1章 概要

### 1.1 目的

本章では、HarmoNet ログイン画面における **統合認証フォーム（MagicLinkForm：A-01）** の全体概要を定義する。
本改訂（v1.1）により、従来の Magic Link メール認証に加えて、**Passkey（WebAuthn）認証を自動判定で実行**できるよう統合された。ユーザーは単一の「ログイン」ボタンを押すだけで、HarmoNetが登録状況（`passkey_enabled`）に応じて最適な認証方式を選択する。

これにより、ユーザーが認証方式を意識することなく、安全で自然なパスワードレスログインを実現する。

---

### 1.2 設計方針

HarmoNet の UX 基準「やさしく・自然・控えめ」に沿って、以下の方針で設計する。

1. **操作の一貫性（One Action Login）**

   * ログインボタンは1つのみとし、ユーザーは方式を選択しない。
   * `passkey_enabled` ユーザーの場合、Corbado SDKを介して自動的にWebAuthnフローを起動。
   * 未登録ユーザーは Supabase Auth の `signInWithOtp()` を用いた Magic Link 認証を実行。

2. **安全で確実なフロー制御**

   * SupabaseとCorbadoのいずれの認証結果も、最終的にSupabaseセッションとして統一。
   * 失敗時は `error_auth` / `error_network` / `error_invalid` の3分類で一元ハンドリング。

3. **UIデザイン原則**

   * Appleカタログ風のミニマルUIを維持（Rounded-2XL / 低コントラストトーン）。
   * ボタン数を最小化し、状態変化（送信中・成功・エラー）を色とアイコンで直感的に表示。
   * BIZ UDゴシックフォント採用、白背景・余白多めの安心感あるレイアウト。

4. **国際化 (i18n)**

   * StaticI18nProvider (C-03) を通じ、`auth.*` 名前空間で統一管理。
   * `auth.passkey.*` 系キーを本コンポーネントへ統合し、各文言を即時反映。

5. **保守性・拡張性**

   * 将来的に認証方式を追加（例：SMS OTP / OAuth）しても、共通の状態管理ロジックを流用可能。
   * API層は Supabase Client と Corbado SDK のみに依存し、UI層とは疎結合を維持。

---

### 1.3 コンポーネント識別情報

| 項目                  | 内容                                                      |
| ------------------- | ------------------------------------------------------- |
| **Component ID**    | A-01                                                    |
| **Component Name**  | MagicLinkForm                                           |
| **Category**        | ログイン画面コンポーネント（Authentication）                           |
| **Framework**       | Next.js 16 / React 19                                   |
| **Language**        | TypeScript 5.6                                          |
| **Library**         | Supabase JS SDK v2.43 / Corbado SDK v2.x / lucide-react |
| **i18n Provider**   | StaticI18nProvider (C-03)                               |
| **Version Control** | GitHub: `Projects-HarmoNet` / DocRepo: `01_docs`        |
| **Related Spec**    | AuthCallbackHandler (A-03), ErrorHandlerProvider (C-16) |

---

### 1.4 関連ドキュメント

| ファイル                                                             | 用途                                         |
| ---------------------------------------------------------------- | ------------------------------------------ |
| `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.0.md`   | 技術スタック基盤定義                                 |
| `/01_docs/04_詳細設計/01_ログイン画面/PasskeyButton-detail-design_v1.4.md` | ※廃止済。##_old保管（統合履歴参照用）                     |
| `/01_docs/04_詳細設計/00_共通部品/ch03_StaticI18nProvider_v1.0.md`       | 翻訳Provider仕様                               |
| `schema.prisma` / `20251107000000_initial_schema.sql`            | DBスキーマ定義（user_profiles.passkey_enabledを含む） |
| `HarmoNet_Phase9_DB_Construction_Report_v1_0.md`                 | DB構築報告（RLSポリシー適用確認）                        |
| `harmonet-detail-design-agenda-standard_v1.0.md`                 | 本書の章立て標準                                   |

---

### 1.5 成果物概要

| 成果物区分     | ファイル                                                  | 説明                                 |
| --------- | ----------------------------------------------------- | ---------------------------------- |
| 実装コード     | `src/components/auth/MagicLinkForm/MagicLinkForm.tsx` | メールリンク＋パスキー自動認証処理本体                |
| 型定義       | `MagicLinkForm.types.ts`                              | Props / State 型定義、passkeyEnabled含む |
| テストコード    | `MagicLinkForm.test.tsx`                              | Jest + RTL による単体・統合テスト             |
| Storybook | `MagicLinkForm.stories.tsx`                           | メール／パスキー状態のUI検証                    |
| 翻訳辞書      | `/public/locales/{ja,en,zh}/common.json`              | i18nキー：`auth.passkey.*` を含む        |

---

### 1.6 位置付け・連携構成

```mermaid
graph TD
  A[StaticI18nProvider (C-03)] --> B[MagicLinkForm (A-01)]
  B --> C[Supabase Auth]
  B --> D[Corbado SDK (Passkey)]
  D -->|passkey_enabled=true| E[WebAuthn POPUP]
  B -->|passkey_enabled=false| F[signInWithOtp]
  E --> G[Supabase Session確立]
  F --> G
  G --> H[Redirect /mypage]
```

* **AppHeader (C-01)** 下部に配置されるメインフォーム。
* `Corbado SDK` を介してパスキー認証を実行。
* `Supabase Auth` のセッション確立を共通化し、ログイン後の動線を `/mypage` に統一。
* UIトーン・翻訳仕様は既存の Phase9 共通方針に完全準拠。

---

### 1.7 保守方針

* バージョン管理は `MagicLinkForm-detail-design_chXX_v*.md` 形式で行い、 `_latest` リンクで最新版を参照。
* Supabase / Corbado SDK のメジャー更新時は差分レビュー必須。
* 主要依存（Supabase, Corbado, StaticI18nProvider）は半期ごとに互換性テストを実施。
* 将来的なPasskey再登録UIやMFA機能拡張に備え、呼出層（Corbado API）は別モジュールとして抽象化予定。

---

### 🧾 Change Log

| Version  | Date           | Summary                                         |
| -------- | -------------- | ----------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（MagicLinkForm単体構成 / PasskeyButton連携あり）       |
| **v1.1** | **2025-11-12** | **PasskeyButton廃止・MagicLinkForm統合。自動判定・1ボタン化。** |
