# Claude実行指示書_C-08_PasskeyButton_v1.0

**Document ID:** HARMONET-CLAUDE-INSTRUCTION-C08-PASSKEYBUTTON  
**Related Spec:** `/01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch06_v1.1.md`  
**ContextKey:** HarmoNet_LoginFeature_Phase9_v1.3_Approved  
**Last Updated:** 2025-11-10 06:04  

---

## 🎯 実行目的

`login-feature-design-ch06_v1.1.md` に基づき、  
**A-02 PasskeyButton** コンポーネントの詳細設計書を作成する。  

目的：Phase9承認仕様で定義された **パスワードレス認証（Magic Link + Passkey）** のうち、  
登録済みPasskeyによる即時ログイン機能を **実装可能レベル** に落とし込む。  
Claudeの出力は `/01_docs/04_詳細設計/01_ログイン画面/` に格納し、  
Gemini・タチコマ双方による最終レビューを受けて承認とする。

---

## 📘 スコープ

対象範囲：
- コンポーネント：A-02 PasskeyButton  
- 関連章：ch03〜ch06（ログインUI全体整合）  
- 認証方式：Supabase Auth + WebAuthn  
- 動作状態：Idle / Loading / Success / Error  
- 端末条件：WebAuthn Level 2対応ブラウザ（Safari / Chrome / Edge 最新版）  

非対象：
- MyPage 内パスキー登録機能  
- AuthCallbackHandler (A-03)  
- Magic Link フロー全体（A-01で定義済み）

---

## ⚙️ 技術前提

| 項目 | 内容 |
|------|------|
| **フレームワーク** | Next.js **16.0.1**（App Router構成） |
| **言語** | TypeScript（strictモード） |
| **UIライブラリ** | React 19 / Tailwind CSS |
| **認証基盤** | Supabase Auth + WebAuthn |
| **トークン管理** | JWT (HttpOnly Secure Cookie) |
| **セキュリティ基準** | OWASP ASVS L1 / Lighthouse Security 95+ |
| **UI/UX基準** | `common-design-system_v1.1.md` 準拠 |
| **翻訳/i18n基準** | `common-i18n_v1.0.md` 準拠 |
| **アクセシビリティ基準** | `common-accessibility_v1.0.md` 準拠 |
| **セキュリティ設計基準** | `login-feature-design-ch05_v1.1.md` 参照 |

---

## 📑 入力ドキュメント

| ファイル | 用途 |
|-----------|------|
| `login-feature-design-ch06_v1.1.md` | PasskeyButton仕様定義（Phase9正式版） |
| `login-feature-design-ch05_v1.1.md` | セキュリティ対策仕様参照 |
| `harmonet-technical-stack-definition_v3.7.md` | 技術構成参照 |
| `common-design-system_v1.1.md` | UI設計基準参照 |
| `common-i18n_v1.0.md` | 翻訳キー・命名規則参照 |
| `common-accessibility_v1.0.md` | ARIAロール・フォーカス設計参照 |
| `schema.prisma` | User / Tenant モデル構造参照 |
| `20251107000001_enable_rls_policies.sql` | RLSポリシー定義参照 |
| `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | DB構造・セキュリティ整合性確認用 |

---

## 🧩 出力要件

Claudeは以下の構成で詳細設計書を生成すること。

- 出力形式：Markdown（UTF-8, `.md`）  
- 構成章立て：
  1. 概要  
  2. 構造設計（Props・State・関数定義）  
  3. 認証フロー（WebAuthn署名→SupabaseAuth→JWT）  
  4. エラーハンドリング・再試行処理  
  5. UI構成と状態遷移図  
  6. i18n文言とARIA設計  
  7. セキュリティ考慮（Origin検証・署名失敗・Timeout）  
  8. テスト観点と受入基準  
  9. 変更履歴  

### 設計重点
- WebAuthn APIを用いた **`navigator.credentials.get()`** の正確なフローを明記すること。  
- Origin一致検証（Supabase側rpIdとの突合）を必須化。  
- i18nキーは `auth.passkey.*` を使用。  
- UX方針「安心感と自然さ」を損なわない演出（アニメーション最小限）。  
- ARIA roleとfocusリングを `common-accessibility` に準拠して定義。  

---

## 🚫 禁止事項

1. Supabaseスキーマの改変・拡張（テーブル/enum変更を含む）  
2. 独自暗号化方式やサーバーサイド署名検証の追加提案  
3. UIトーンを変更するスタイル提案（Appleカタログ風以外禁止）  
4. i18nキーの新規追加・命名規則変更  
5. Tailwind以外のCSSライブラリ使用  

---

## ✅ 成果物検証基準

| 項目 | 基準値 |
|------|--------|
| Self-Score (HQI) | 9.0以上 |
| TypeCheck | Passed |
| ESLint | Passed |
| Jest/RTL | 100%通過 |
| Lighthouse Accessibility | 95点以上 |
| Lighthouse Security | 95点以上 |
| WebAuthnフロー成功率 | 100%（認証済端末） |

---

## 🔍 整合性ルール

- Phase9設計体系（v1.3.1系列）に完全準拠  
- ch03〜ch06間のUI構造・文言を統一  
- `_latest.md` 形式リンクを使用  
- Document ID・Version履歴は維持  

---

## 🧠 実行メモ

Claudeは本タスクを「PasskeyButton詳細設計書生成タスク」として扱い、  
出力完了時に `[CodeAgent_Report]` ブロックを自動生成し、  
自己評価・試行回数・参照ファイルを明示する。  

出力物は `/01_docs/04_詳細設計/01_ログイン画面/` に格納すること。

---

**Created:** 2025-11-10 / **Version:** 1.0 / **Document ID:** HARMONET-CLAUDE-INSTRUCTION-C08-PASSKEYBUTTON
