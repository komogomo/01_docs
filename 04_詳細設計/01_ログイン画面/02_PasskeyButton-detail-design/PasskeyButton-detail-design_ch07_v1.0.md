# HarmoNet 詳細設計書 - PasskeyButton (A-02) ch07 結合・運用 v1.0

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH07
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ Phase9 正式版（技術スタック v4.0 / アジェンダ標準準拠）

---

## 第7章 結合・運用

### 7.1 他コンポーネント結合ポイント

| 結合対象                            | 種別       | 連携内容                         | 備考                |
| ------------------------------- | -------- | ---------------------------- | ----------------- |
| **MagicLinkForm (A-01)**        | ログインUI並列 | 同一画面内配置（縦スタック）               | 認証方式切替（メール／パスキー）  |
| **StaticI18nProvider (C-03)**   | Context  | 文言取得 (`t('auth.passkey.*')`) | グローバル翻訳Context    |
| **ErrorHandlerProvider (C-16)** | Context  | 例外通知／ログ出力                    | UI表示＋Supabaseログ転送 |
| **/api/corbado/session**        | API      | Corbadoセッション検証・Supabase連携    | Node構成で実装済        |
| **AppHeader/AppFooter**         | 共通UI     | 一貫したトーン・余白調整                 | Phase9デザイン統一      |

> PasskeyButton は認証トリガのみ担当し、セッション検証やCookie処理は `/api/corbado/session` 側で行う。

---

### 7.2 環境依存要素

| 項目          | 内容                                               |
| ----------- | ------------------------------------------------ |
| **認証環境**    | Corbado Cloud（WebAuthn管理） + Supabase Auth（セッション） |
| **API動作環境** | Next.js App Router (API Routes)                  |
| **通信要件**    | HTTPS／CORS制限：`NEXT_PUBLIC_APP_URL` 限定            |
| **環境変数**    |                                                  |

* `NEXT_PUBLIC_CORBADO_PROJECT_ID`
* `CORBADO_API_SECRET`
* `NEXT_PUBLIC_SUPABASE_URL`
* `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  | **Cookie仕様** | `cbo_short_session`（HttpOnly／Secure／SameSite=Lax）|

---

### 7.3 運用設計

#### 7.3.1 デプロイ構成

| 層       | ホスティング         | 備考                      |
| ------- | -------------- | ----------------------- |
| フロントエンド | Vercel         | Next.js (React 19)      |
| BaaS    | Supabase Cloud | PostgreSQL + Auth/RLS   |
| 認証API   | Corbado Cloud  | Passkey管理＋Session JWT発行 |

#### 7.3.2 運用保守方針

* SDK更新監視（月次）：Corbado / Supabase のマイナーバージョン追随。
* 認証API `/api/corbado/session` の稼働監視を Sentry + Supabase Logs で実施。
* エラー分類統計をダッシュボード化（error_network / denied / origin / auth）。
* UI/UX改善指標：成功率（>98%）・クリックレスポンス（<500ms）を維持。

---

### 7.4 Storybook / Jest / E2E 結合設計

| 種別                   | 対象                | 構成                                   | 検証内容           |
| -------------------- | ----------------- | ------------------------------------ | -------------- |
| **Storybook**        | PasskeyButton     | 状態別ストーリー（idle／loading／success／error） | UIレンダリング確認     |
| **Jest (Unit)**      | PasskeyButton.tsx | Mock API + Supabase                  | 状態遷移・例外分類確認    |
| **Integration Test** | LoginPage         | A-01 / A-02 結合                       | 成功時遷移／失敗UI連携   |
| **E2E (Playwright)** | /login            | 実ブラウザ操作                              | 認証成功→/mypage遷移 |

> **補足**: Corbado環境をMock化し、Supabase呼出結果をスタブ化することでCI環境でも安定実行可能。

---

### 7.5 リスク・制約事項

| 種別           | 内容                              | 対策                       |
| ------------ | ------------------------------- | ------------------------ |
| **ブラウザ差異**   | Safari WebAuthn 実装差（Touch ID制限） | iCloud Keychain対応手順をガイド化 |
| **SDK更新リスク** | Corbadoメジャー更新時のAPI変更            | 月次監査・互換モード維持（web-js）     |
| **ネットワーク断**  | 通信切断／DNS遅延                      | Retry案内＋ErrorHandler通知   |
| **ユーザー誤操作**  | 繰り返しクリック／キャンセル                  | disabled制御＋UX抑制          |
| **セキュリティ**   | Origin設定誤りによる検証失敗               | Corbado Console設定テンプレート化 |

---

### 7.6 運用ドキュメント連携

| ドキュメント                                        | 用途        |
| --------------------------------------------- | --------- |
| `harmonet-technical-stack-definition_v4.0.md` | 技術スタック基準  |
| `login-feature-design-ch04_v1.0.md`           | 認証API連携仕様 |
| `AppFooter-detail-design_v1.0.md`             | UI統一要素    |
| `ErrorHandlerProvider-detail-design_v1.0.md`  | 例外処理仕様    |

---

### 7.7 ChangeLog

| Version | Date       | Author    | Summary                                    |
| ------- | ---------- | --------- | ------------------------------------------ |
| 1.0     | 2025-11-11 | Tachikoma | 初版。結合構成・環境依存・運用方針・Storybook/Jest/E2E構成を定義。 |

---

**Document Path:** `/01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design-ch07_v1.0.md`
**Compliance:** harmoNet_detail_design_agenda_standard_v1.0
