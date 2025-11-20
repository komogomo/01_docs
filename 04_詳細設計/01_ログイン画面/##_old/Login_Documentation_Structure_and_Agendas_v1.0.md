# Login — 設計書 文書体系と各章アジェンダ

**Version:** v1.0
**Supersedes:** (新規)
**Author:** Tachikoma
**Date:** 2025-11-16

---

## 目的

Login（A-00）周りで必要な設計ドキュメントの体系を定義し、各ドキュメントの章立て（アジェンダ）を示す。TKDの単独開発ワークフローに最適化し、必要最小限の文書で運用効率を担保する。

---

## 文書一覧（提案）

下記ファイルはすべて `/01_docs/04_詳細設計/01_ログイン画面/` 配下に保存する。

1. `PasskeyBackend-detail-design_v1.0.md`
2. `MagicLinkBackend-integration_v1.0.md`
3. `Login_API_Contracts_v1.0.md`
4. `LoginPage_MSG_Catalog_v1.0.md`
5. `Login_TestPlan_v1.0.md`
6. `LoginPage_UI_Spec_v1.0.md`
7. `Frontend_IntegrationSpec_WS-A00_v1.0.md`
8. `schema.prisma_migration_reference_v1.0.md`  *(補助文書 — 必要時のみ作成)*
9. `Security_Key_Handling_and_Secrets_v1.0.md` *(鍵管理/環境変数/運用)*
10. `WS-LoginLayoutIntegration_change_log_v1.0.md` *(WS指示書との整合メモ／差し戻し履歴)*

---

## 各文書のアジェンダ（章立て）

以下、各ドキュメントに含めるべき章見出し（最小限）。各章は簡潔に、実行手順・受入基準を明記する。

### 1) PasskeyBackend-detail-design_v1.0.md

* 目的と範囲（対象フロー: 登録/認証/解除）
* 前提（現在の schema.prisma 参照）
* 選定ライブラリ／サービス（Corbado/WebAuthn libs）と理由
* API エンドポイント設計（URI/メソッド/入出力例）
* サーバ側ロジック（チャレンジ生成/検証/署名検査/サインカウント）
* DB 参照・更新（passkey_credentials の扱い）
* エラーハンドリング（HTTPコード、i18nキー紐付け）
* テスト戦略（モック手順・自動化要件）
* 運用・監査ログ（何をログに残すか）
* 受入基準

### 2) MagicLinkBackend-integration_v1.0.md

* 目的と範囲
* フロント→バックエンド契約（リクエスト/レスポンス）
* メール送信実装案（Supabase/Auth or SMTP）
* リンク形式と有効期限設計
* 再送/レート制限ポリシー
* 成功/失敗時のUIイベント（i18nキー）
* テスト（受信シミュレート、タイムアウト、再送）
* 受入基準

### 3) Login_API_Contracts_v1.0.md

* 目的と使用範囲
* OpenAPI 断片（主要エンドポイント）

  * `/api/auth/magiclink/send`
  * `/api/auth/passkey/register`
  * `/api/auth/passkey/authenticate`
* 各エンドポイントのリクエスト・レスポンス JSON 例
* エラーコード一覧と i18n キーの紐付け
* セキュリティ（認可スコープ・CSRF 対策）
* 受入基準（契約通りにモックが動くこと）

### 4) LoginPage_MSG_Catalog_v1.0.md

* 目的とスコープ
* i18n キー一覧（ja/en/zh）と短文言（トーン）
* 表示トリガー（どのUIイベントで何を出すか）
* 優先度（必須/任意）と翻訳担当メモ
* テストチェックリスト（文言一致の自動検査用）

### 5) Login_TestPlan_v1.0.md

* 目的とテストポリシー
* テスト種別一覧（Unit/Integration/MockE2E）
* 必須テストケース（MagicLink, Passkey, i18n, UI レイアウト）
* モックの作り方とシナリオ（バックエンド未実装時の検証方法）
* 実行コマンドと期待結果（`npm run test` 等）
* 受入基準

### 6) LoginPage_UI_Spec_v1.0.md

* 目的とデザイン原則（やさしい・自然・控えめ）
* レイアウト（1列固定、カード寸法、ブレークポイント明記）
* コンポーネント一覧（MagicLinkForm, PasskeyAuthTrigger, LanguageSwitch など）
* 各コンポーネントのプロップス/状態一覧
* アクセシビリティ要件（ARIA、キーボード操作）
* スクリーンショット参照と差分チェックリスト
* 受入基準

### 7) Frontend_IntegrationSpec_WS-A00_v1.0.md

* 実行ディレクトリと Git ワークフロー明示（`cd D:\Projects\HarmoNet` など）
* 該当ファイル一覧（編集対象）
* AST 置換ポリシー / import path の統一規則
* Storybook 登録手順とスクショ取得方法
* CodeAgent_Report 出力要件

### 8) schema.prisma_migration_reference_v1.0.md  *(補助)*

* 目的（参照用マイグレーション・seed の説明）
* 現行 schema.prisma の差分要約（passkey部分中心）
* ローカルでの migrate / seed 再現手順（コマンド）
* ロールバック手順（必要時）

### 9) Security_Key_Handling_and_Secrets_v1.0.md

* 秘密鍵の配置と管理（env, vault 等）
* Corbado／WebAuthn の鍵ライフサイクル
* 開発/本番での差分運用（モック/実鍵）
* ログ出力に含めて良い情報・含めてはいけない情報

### 10) WS-LoginLayoutIntegration_change_log_v1.0.md

* 目的（WS 指示書との差分と決定記録）
* 変更履歴テーブル（日時 / 内容 / TKD承認）
* 差し戻し理由と対応履歴

---

## 優先順位（推奨）

1. `PasskeyBackend-detail-design_v1.0.md`  ← バックエンド未実装のため最優先
2. `MagicLinkBackend-integration_v1.0.md`
3. `LoginPage_MSG_Catalog_v1.0.md`  ← 文言不整合防止（早めに固定）
4. `Login_API_Contracts_v1.0.md`
5. `LoginPage_UI_Spec_v1.0.md`
6. `Login_TestPlan_v1.0.md`
7. `Frontend_IntegrationSpec_WS-A00_v1.0.md` ← Windsurf 実装向け指示書
8. `Security_Key_Handling_and_Secrets_v1.0.md`
9. `schema.prisma_migration_reference_v1.0.md` *(補助。必要時作成)*
10. `WS-LoginLayoutIntegration_change_log_v1.0.md`

---

## 備考（運用ルール）

* すべての設計書は完全版 Markdown（canmore.create_textdoc）で作成。TKD の明示的承認が出るまで「ドラフト」扱いとする。
* 既にPJにあるファイルは一次情報として優先する（推測・想像で上書きしない）。
* 章立ては必要最小限に留め、実装手順と受入基準を必ず含める。

---

*End of document*
