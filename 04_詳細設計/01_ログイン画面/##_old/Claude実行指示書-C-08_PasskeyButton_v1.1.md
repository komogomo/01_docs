# Claude実行指示書_C-08_PasskeyButton_v1.1

**Document ID:** HARMONET-CLAUDE-INSTRUCTION-C08-PASSKEYBUTTON  
**Related Spec:** `/01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch06_v1.1.md`  
**ContextKey:** HarmoNet_LoginFeature_Phase9_v1.3_Approved  
**Last Updated:** 2025-11-10 06:38  

---

## 🎯 実行目的

本タスクは、Claudeが **設計エンジニアとして詳細設計書を執筆（生成）するための指示書** である。  
レビューや監査ではなく、Claude自身が仕様を解釈し、  
`login-feature-design-ch06_v1.1.md` に基づいて **A-02 PasskeyButton** の詳細設計書を完成させる。  

目的：Phase9承認仕様で定義された **パスワードレス認証（Magic Link + Passkey）** のうち、  
登録済みPasskeyによる即時ログイン機能を **実装可能レベル** に落とし込む。  
出力成果物は `/01_docs/04_詳細設計/01_ログイン画面/` に格納し、  
Gemini・タチコマによる最終レビュー後に承認とする。

---

## 📘 スコープ

対象範囲：
- コンポーネント：A-02 PasskeyButton  
- 関連章：ch03〜ch06（ログインUI整合）  
- 認証方式：Supabase Auth + WebAuthn  
- 状態：Idle / Loading / Success / Error  
- 対応ブラウザ：WebAuthn Level2準拠（Safari / Chrome / Edge 最新版）

非対象：
- MyPage 内パスキー登録画面  
- AuthCallbackHandler (A-03)  
- Magic Link フロー全体（A-01で定義済み）

---

## ⚙️ 技術前提

| 項目 | 内容 |
|------|------|
| **フレームワーク** | Next.js **16.0.1**（App Router） |
| **言語** | TypeScript（strictモード） |
| **UIライブラリ** | React 19 / Tailwind CSS |
| **認証基盤** | Supabase Auth + WebAuthn |
| **セキュリティ** | OWASP ASVS L1 / Lighthouse Security 95+ |
| **UI/UX基準** | `common-design-system_v1.1.md` 準拠 |
| **翻訳/i18n基準** | `common-i18n_v1.0.md` 準拠 |
| **アクセシビリティ** | `common-accessibility_v1.0.md` 準拠 |
| **セキュリティ設計参照** | `login-feature-design-ch05_v1.1.md` |

---

## 📑 入力ドキュメント

| ファイル | 用途 |
|-----------|------|
| `login-feature-design-ch06_v1.1.md` | PasskeyButton仕様定義（Phase9正式版） |
| `login-feature-design-ch05_v1.1.md` | セキュリティ対策仕様参照 |
| `harmonet-technical-stack-definition_v3.7.md` | 技術構成参照 |
| `common-design-system_v1.1.md` | UI設計基準参照 |
| `common-i18n_v1.0.md` | 翻訳キー・命名規則参照 |
| `common-accessibility_v1.0.md` | ARIA設計・操作性基準参照 |
| `schema.prisma` | User / Tenant モデル構造参照 |
| `20251107000001_enable_rls_policies.sql` | RLSポリシー参照 |
| `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | DB構造整合性確認用 |

---

## 🧩 出力要件

Claudeは次の章構成で、**詳細設計書（開発者向け設計仕様書）** を執筆すること。

1. 概要  
2. 構造設計（Props・State・関数構成）  
3. 認証フロー（WebAuthn署名→SupabaseAuth→JWT）  
4. エラーハンドリング・再試行処理  
5. UI構成と状態遷移図  
6. i18n文言およびARIA設計  
7. セキュリティ考慮（Origin検証・署名失敗・Timeout）  
8. テスト観点・受入基準  
9. 変更履歴  

### 設計重点
- **WebAuthn** フローを正確に記述し、Supabase Authとの接続を明確化する。  
- **Origin一致検証** を明示（`rpId`と`window.location.origin`）。  
- i18nキー：`auth.passkey.*` を全て明示。  
- UIは「やさしく・自然・控えめ」トーンで表現。  
- **ARIA role**、`aria-live`、focus制御を必ず定義。  

---

## 🚫 禁止事項

1. Supabaseスキーマの改変  
2. 独自の暗号化・署名検証処理提案  
3. HarmoNetデザイン原則外のスタイル追加  
4. i18nキーの新規定義や命名規則改変  
5. Tailwind以外のCSS利用  

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
| WebAuthn認証成功率 | 100%（登録済端末） |

---

## 🔍 整合性ルール

- Phase9設計体系（v1.3.1系列）に完全準拠  
- ch03〜ch06間のUI構造・文言統一  
- `_latest.md` 形式リンクを使用  
- Document ID・Version履歴維持  

---

## 🧠 実行メモ

Claudeはこの指示書を「**PasskeyButton詳細設計書の執筆タスク**」として実行すること。  
出力完了時に `[CodeAgent_Report]` ブロックを自動生成し、  
自己採点・試行回数・参照ファイルを明示する。  

成果物は `/01_docs/04_詳細設計/01_ログイン画面/` に格納すること。

---

**Created:** 2025-11-10 / **Version:** 1.1 / **Document ID:** HARMONET-CLAUDE-INSTRUCTION-C08-PASSKEYBUTTON
