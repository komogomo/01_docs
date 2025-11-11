# Windsurf実行指示書 - Login Module (A-01〜A-03) v1.0

**Document ID:** HARMONET-WINDSURF-LOGIN-EXEC-V1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**ContextKey:** HarmoNet_Windsurf_LoginModule_Execution_v1.0
**Status:** ✅ 実行準備完了

---

## 第1章 タスク概要

### 1.1 目的

本指示書は、HarmoNet ログインモジュール群
**A-01 MagicLinkForm / A-02 PasskeyButton / A-03 AuthCallbackHandler**
の3 コンポーネントを Windsurf によって一括生成・検証するための実装指示である。
Supabase Auth v2.43 および Corbado SDK 構成を前提とし、
完全パスワードレス認証基盤をNext.js 16 環境上に構築する。

---

## 第2章 参照ドキュメント

| 種別   | ファイル名                                                | 用途              |
| ---- | ---------------------------------------------------- | --------------- |
| 技術基盤 | `harmonet-technical-stack-definition_v4.0.md`        | 認証構成・SDK整合      |
| 詳細設計 | `MagicLinkForm-detail-design_v1.0.md`                | A-01設計仕様        |
| 詳細設計 | `PasskeyButton-detail-design_v1.4.md`                | A-02設計仕様        |
| 詳細設計 | `AuthCallbackHandler-detail-design_v1.0.md` *(生成対象)* | A-03設計仕様        |
| 設計標準 | `harmonet-detail-design-agenda-standard_v1.0.md`     | 記述粒度・UT観点統一     |
| 機能一覧 | `機能コンポーネント一覧.md`                                     | Component ID 定義 |
| レビュー | `HarmoNet_Phase9_LoginComponents_Review_v1.0.md`     | API 検証結果 参照     |

---

## 第3章 実装対象

| ID   | コンポーネント             | ファイル配置                                      | 主要依存                                                  |
| ---- | ------------------- | ------------------------------------------- | ----------------------------------------------------- |
| A-01 | MagicLinkForm       | `src/components/login/MagicLinkForm/`       | Supabase Auth, StaticI18nProvider                     |
| A-02 | PasskeyButton       | `src/components/login/PasskeyButton/`       | Corbado SDK, StaticI18nProvider, ErrorHandlerProvider |
| A-03 | AuthCallbackHandler | `src/components/login/AuthCallbackHandler/` | Supabase Auth, Next.js Router                         |

---

## 第4章 実装指示

### 4.1 共通前提

* `'use client'` を明示。
* 型定義: TypeScript strict mode 警告ゼロ。
* UI: TailwindCSS + HarmoNet Design System v1。
* i18n: `useI18n()` で `common.json` 辞書参照。
* ESLint/Prettier 構成は既存設定を継承。
* ルート: `/login` → `MagicLinkForm` / `PasskeyButton`、 `/auth/callback` → `AuthCallbackHandler`。

### 4.2 A-01 MagicLinkForm

* Supabase Auth `signInWithOtp()` を使用。
* 成功: メール送信完了 (`sent` state)。
* 失敗: `error_invalid` または `error_network`。
* UI: `Loader2`, `CheckCircle`, `AlertCircle` （lucide-react）。
* Unit Test: UT01〜UT03（正常・異常・翻訳切替）。

### 4.3 A-02 PasskeyButton

* Corbado SDK v2 `passkey.login()` ＋ Supabase `signInWithIdToken()`。
* 成功: `success` 状態、`onSuccess()` callback。
* 失敗: `error_auth` → ErrorHandlerProvider 通知。
* UI: `KeyRound`, `Loader2`, `CheckCircle`。
* UT01〜UT05 （正常認証・通信失敗・翻訳切替・エラーハンドリング・再レンダー抑制）。

### 4.4 A-03 AuthCallbackHandler

* URL クエリ`code`を解析し Supabase `exchangeCodeForSession()` を呼出。
* 成功時 → `/mypage` へ遷移。
* 失敗時 → エラーバナー表示。
* 非同期完了までは `AuthLoadingIndicator (C-04)` を利用。
* Jest + RTL で callback ルート動作を検証。

---

## 第5章 禁止事項（共通）

* schema.prisma / RLS / DB構造の変更禁止
* 新規CSS / 外部ライブラリ追加禁止
* ディレクトリ構造変更禁止
* i18n キー追加・削除禁止（辞書既存キーのみ使用）
* 任意の環境変数の直書き禁止（`.env` 参照）

---

## 第6章 Acceptance Criteria

| 評価項目               | 基準                                    |
| ------------------ | ------------------------------------- |
| TypeCheck          | `npm run type-check` でエラー0            |
| Lint/Format        | `npm run lint` ・ `npm run format` 警告0 |
| UT Coverage        | 100 %（主要state分岐網羅）                    |
| i18n動作             | ja/en/zh 即時反映                         |
| Corbado/Supabase連携 | ダミー環境で例外なく初期化                         |
| Self-Score         | 平均 ≥ 9.0 / 10 （精度・保守性・再現性）            |

---

## 第7章 CodeAgent_Report 仕様

各コンポーネント完了時に以下を出力すること。

```
[CodeAgent_Report]
Agent: Windsurf
Component: <COMPONENT_NAME>
Attempt: <Number>
AverageScore: <Score>/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 仕様準拠・依存整合・翻訳動作確認済み。
```

最終統合レポートは `/01_docs/05_品質チェック/CodeAgent_Report_LoginModule_v1.0.md` に保存。

---

## 第8章 補足

* Supabase Auth API 検証: Phase9 レビュー v1.0 整合【91†source】
* Corbado SDK 構成: 技術スタック v4.0 完全準拠【92†source】
* 詳細設計アジェンダ 準拠率 100 % を必須【94†source】

---

**End of Instruction**
