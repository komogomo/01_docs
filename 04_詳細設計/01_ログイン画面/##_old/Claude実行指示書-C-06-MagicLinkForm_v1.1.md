# Claude実行指示書_C-06_MagicLinkForm_v1.1

**Document ID:** HARMONET-CLAUDE-INSTRUCTION-C06-MAGICLINKFORM  
**Related Spec:** `/01_docs/03_detail_design/login-feature-design-ch04_v1.1.md`  
**ContextKey:** HarmoNet_LoginFeature_Phase9_v1.3_Approved  
**Last Updated:** 2025-11-10 05:12  

---

## 🎯 実行目的

`login-feature-design-ch04_v1.1.md` に基づき、  
**A-01 MagicLinkForm** コンポーネントの詳細設計書（Claude出力版）を生成する。  

目的：Phase9承認仕様（Magic Link + Passkey併用 / テナントID入力なし）を  
**Windsurf実装可能レベル** に落とし込むこと。  
Claudeの出力は `/01_docs/03_detail_design/` に格納し、  
Gemini・タチコマの両レビュー後に承認版として採用する。

---

## 📘 スコープ

対象：
- **コンポーネント:** A-01 MagicLinkForm  
  - **MagicLinkForm.tsx**（親／状態管理・送信処理）  
  - **EmailSentCard.tsx**（完了メッセージ＋再送／Passkey誘導）  
  - **ResendButton.tsx**（クールダウン管理）  
- **関連章:** ch00〜ch04  
- **認証方式:** Supabase Auth（Magic Link + Passkey）  
- **対象画面:** ログイン → 送信完了（再送・Passkey誘導含む）

非対象：
- A-02 PasskeyButton（別タスク）  
- A-03 AuthCallbackHandler（別タスク）  
- MyPage内パスキー登録画面（別巻）

---

## ⚙️ 技術前提

| 項目 | 内容 |
|------|------|
| **フレームワーク** | Next.js **16.0.1**（App Router） |
| **言語** | TypeScript（strictモード） |
| **UIライブラリ** | React 19 / Tailwind CSS |
| **認証** | Supabase Auth（Magic Link + Passkey） |
| **DB保護** | RLS + JWT tenant_id |
| **スタイル設計** | HarmoNet共通デザインシステム（BIZ UDゴシック / Appleカタログトーン） |

---

## 📑 入力ドキュメント

| ファイル | 用途 |
|-----------|------|
| `login-feature-design-ch04_v1.1.md` | MagicLinkForm画面仕様（Phase9正式版） |
| `login-feature-design-ch03_v1.3.1.md` | ログイン画面UI構造参照 |
| `CodeAgent_Report_AppHeader_v1.1.md` | 共通部品C-01仕様参照 |
| `CodeAgent_Report_StaticI18nProvider_v1.0.md` | 翻訳レイヤー仕様参照 |
| `harmonet-technical-stack-definition_v3.7.md` | 技術構成参照 |
| `common-design-system_v1.1.md` | UIデザイン・スタイル一貫性参照 |
| `common-i18n_v1.0.md` | 翻訳構造・辞書命名規則参照 |
| `common-accessibility_v1.0.md` | ARIA属性・操作ガイドライン参照 |

---

## 🧩 出力要件

Claudeは以下の要件を満たす詳細設計書を出力すること。

- 出力形式：Markdown（UTF-8, 拡張子 `.md`）  
- 構成章立て：
  1. 概要  
  2. 構造設計（Component構成・Props・State）  
  3. 処理フロー（送信→完了→再送→Passkey誘導）  
  4. Supabase連携仕様（signInWithOtp, localStorage制御）  
  5. UI構成・アクセシビリティ設計  
  6. i18n対応（辞書キー一覧含む）  
  7. テスト観点・受入基準  
  8. 変更履歴  

### UIデザイン基準
- **基調:** 白基調・控えめ・Appleカタログ風（共通仕様）  
- **フォント:** BIZ UDゴシック  
- **角丸:** rounded-2xl  
- **影:** shadow-sm  
- **アクセントカラー:** #2563EB  
- **余白:** 16 / 24 / 32px  
- **アクセシビリティ:** ARIA role属性・focus ring準拠（common-accessibility参照）

---

## 🚫 禁止事項

1. 仕様外の機能追加  
2. 既存ファイルの改名・削除・移動  
3. Supabaseスキーマ／RLS定義の変更  
4. CSSフレームワーク置換（Tailwind固定）  
5. i18nキー・命名規則改変  

---

## ✅ 成果物検証基準

| 項目 | 基準 |
|------|------|
| 自己評価スコア | 9.0以上 |
| TypeCheck | Passed |
| ESLint | Passed |
| UnitTest (Jest/RTL) | 100%通過 |
| Storybook | 正常動作 |
| Lighthouse Accessibility | 95点以上 |

### Storybook構成要件
- 言語別: ja / en / zh  
- 状態別: Default / Sending / Sent / Cooldown / Error / LimitReached  

---

## 🔍 整合性ルール

- Phase9設計体系（v1.3.1系列）に準拠  
- ch00〜ch03定義のUI・i18n・共通部品構造と完全整合  
- ドキュメント内リンクは `_latest.md` 形式を使用  
- Document ID・Version履歴は維持  

---

## 🧠 実行メモ

Claudeはこの指示書をもとに詳細設計書を作成し、  
出力完了時に `[CodeAgent_Report]` ブロックを自動付与すること。  

---

**Created:** 2025-11-10 / **Version:** 1.1 / **Document ID:** HARMONET-CLAUDE-INSTRUCTION-C06-MAGICLINKFORM

