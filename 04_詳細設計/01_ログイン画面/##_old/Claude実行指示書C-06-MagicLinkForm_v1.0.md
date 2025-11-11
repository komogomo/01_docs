# Claude実行指示書_C-06_MagicLinkForm_v1.0

**Document ID:** HARMONET-CLAUDE-INSTRUCTION-C06-MAGICLINKFORM  
**Related Spec:** `/01_docs/03_detail_design/login-feature-design-ch04_v1.1.md`  
**ContextKey:** HarmoNet_LoginFeature_Phase9_v1.3_Approved  
**Last Updated:** 2025-11-10 04:54  

---

## 🎯 実行目的

`login-feature-design-ch04_v1.1.md` に基づき、  
**A-01 MagicLinkForm** コンポーネントの詳細設計書（Claude出力版）を生成する。  

本タスクの目的は、Phase9承認仕様（Magic Link + Passkey併用 / テナントID入力なし）を  
**Windsurf実装可能レベル**に落とし込むこと。  
Claudeの出力はそのまま `/01_docs/03_detail_design/` に格納し、  
Gemini・タチコマ両者による整合レビューを受ける。

---

## 📘 スコープ

対象：
- コンポーネント：A-01 MagicLinkForm  
- 関連章：ch00〜ch04  
- 認証方式：Supabase Auth（Magic Link + Passkey）  
- 対象画面：ログイン画面 → メール送信完了画面（再送／Passkey誘導含む）

非対象：
- A-02 PasskeyButton  
- A-03 AuthCallbackHandler  
- MyPage配下のパスキー登録画面（別巻扱い）

---

## 📑 入力ドキュメント

| ファイル | 用途 |
|-----------|------|
| `login-feature-design-ch04_v1.1.md` | MagicLinkForm画面の仕様定義（Phase9正式版） |
| `login-feature-design-ch03_v1.3.1.md` | ログイン画面仕様（UI構造の参照） |
| `CodeAgent_Report_AppHeader_v1.1.md` | 共通部品C-01構造参照 |
| `CodeAgent_Report_StaticI18nProvider_v1.0.md` | 翻訳レイヤー仕様参照 |
| `harmonet-technical-stack-definition_v3.7.md` | 使用技術・依存モジュール参照 |

---

## 🧩 出力要件

Claudeは以下の要件を満たす詳細設計書を生成すること。

- 出力形式：Markdown（UTF-8, 拡張子 `.md`）  
- 章立て構成：
  1. 概要  
  2. 構造設計（Component構成・Props・State）  
  3. 処理フロー（送信→完了→再送→Passkey誘導）  
  4. Supabase連携仕様（signInWithOtp, localStorage制御）  
  5. UI構成・アクセシビリティ設計  
  6. i18n対応（辞書キー一覧含む）  
  7. テスト観点・受入基準  
  8. 変更履歴  

- コードスニペット：TypeScript/React記法（Next.js App Router準拠）  
- コメント：日本語、JSDoc形式  
- UIトーン：白基調・控えめ・Appleカタログ風（HarmoNet共通仕様）  

---

## 🚫 禁止事項

Claudeは以下を一切行わないこと。

1. 仕様外の新規機能提案（例：追加バリデーション・外部API通信）  
2. 既存ファイルの改名・移動・削除  
3. Supabaseスキーマ／RLSの変更  
4. CSSフレームワークの置換（Tailwind固定）  
5. i18nキーや命名規則の改変  

---

## ✅ 成果物検証基準

Claudeは出力完了時に **[CodeAgent_Report]** ブロックを自動生成し、  
以下の数値基準を満たすこと。

| 項目 | 基準値 |
|------|--------|
| 自己評価スコア（AverageScore） | 9.0以上 |
| TypeCheck | Passed |
| ESLint | Passed |
| UnitTest (Jest/RTL) | 100%通過 |
| Storybook動作 | 正常 |

---

## 🔍 整合性ルール

- 本出力は **Phase9設計体系（v1.3.1系列）** に準拠し、  
  ch00〜ch03で定義されたUI・i18n・共通部品構造との整合を保つこと。  
- 設計書内リンクは `_latest.md` 形式を使用。  
- Document IDおよびバージョン履歴は維持すること。

---

## 🧠 メモ

Claudeは本タスクを「詳細設計書執筆タスク」として扱い、  
出力完了後に Windsurf / Gemini レビューに供する。

---

**Created:** 2025-11-10 / **Version:** 1.0 / **Document ID:** HARMONET-CLAUDE-INSTRUCTION-C06-MAGICLINKFORM  

