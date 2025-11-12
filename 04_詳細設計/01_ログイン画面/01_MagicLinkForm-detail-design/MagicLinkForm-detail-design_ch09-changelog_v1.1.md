# MagicLinkForm 詳細設計書 - 第9章：ChangeLog（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH09
**Version:** 1.1
**Supersedes:** v1.0（Phase9初版）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Passkey統合・正式改訂履歴）

---

## 第9章 ChangeLog

### 9.1 目的

本章では、MagicLinkForm (A-01) に関する詳細設計書（ch01〜ch08）の改訂履歴を統合管理する。
v1.1では、**PasskeyButton (A-02) の廃止と MagicLinkFormへの統合**、および Supabase / Corbado 連携によるパスワードレス自動認証設計への改訂内容を正式記録する。

---

### 9.2 章別更新履歴

| 章番号  | 章タイトル     | Version | 更新日        | 主な変更点                                           |
| ---- | --------- | ------- | ---------- | ----------------------------------------------- |
| ch01 | 概要        | v1.1    | 2025-11-12 | A-02廃止を明記。Passkey統合の目的と背景を追加。                   |
| ch02 | 機能設計      | v1.1    | 2025-11-12 | Propsに`passkeyEnabled`を追加、Corbado統合仕様を定義。       |
| ch03 | ロジック設計    | v1.1    | 2025-11-12 | Supabase / Corbado両API統合、`handleLogin()`一本化。    |
| ch04 | UI設計      | v1.1    | 2025-11-12 | ログインボタン1本化・i18nキー統合、WCAG2.1AA準拠再検証。             |
| ch05 | テスト仕様     | v1.1    | 2025-11-12 | Supabase＋Corbadoモック統合、自己採点自動化対応。                |
| ch06 | セキュリティ設計  | v1.1    | 2025-11-12 | 脅威モデルにCorbado追加、RLS整合・環境変数拡張。                   |
| ch07 | 環境設定      | v1.1    | 2025-11-12 | tenant_configに`passkey_enabled` / Corbado設定を追加。 |
| ch08 | 監査・保守設計   | v1.1    | 2025-11-12 | Supabase＋Corbado監査統合、フェイルオーバー運用設計を追加。           |
| ch09 | ChangeLog | v1.1    | 2025-11-12 | 全章統合履歴更新・承認体制刷新。                                |

---

### 9.3 バージョン推移概要

| Version | Date          | 内容                                        |
| ------- | ------------- | ----------------------------------------- |
| v1.1    | 2025-11-12    | Passkey自動判定統合版。A-02廃止、A-01へ統合、Phase9最終構成。 |
| v1.0    | 2025-11-11    | Phase9初版（MagicLinkForm単体構成）。              |
| v0.x    | 2025-11-09〜10 | Phase8仕様（Supabase v2.30基盤・Corbado未統合）。    |

---

### 9.4 ドキュメント構成規則

* 各章の更新時には必ず本章に改訂履歴を追記する。
* バージョン番号は全章共通（例：v1.1）。軽微修正は `v1.1.x` で管理。
* 技術仕様の構成変更（例：API統合、UI再構成）を伴う場合は `v2.0` とする。
* 旧版は `/01_docs/04_詳細設計/01_ログイン画面/99_archive/` に保存し、Phase単位で参照可。
* Claude/Gemini/Windsurf 間の整合レビューはPhase単位で固定化。
* Windsurf 実行指示書（WS-A01）と常にバージョンを一致させること。

---

### 9.5 将来対応項目（Phase10以降計画）

| 項目                  | 概要                                 | 対応時期       |
| ------------------- | ---------------------------------- | ---------- |
| Corbado React SDK移行 | 現行WebJS SDKから公式React構成へ移行。         | Phase10    |
| Corbado監査API統合      | PasskeyログをCorbado公式監査APIで直接取得。     | Phase10    |
| AI自動テスト拡張           | WindsurfによるE2E＋UT自動生成スイート構築。       | Phase10    |
| Redis翻訳キャッシュ        | 多言語辞書をRedis経由でキャッシュ化。              | Phase10    |
| Audit BI可視化         | Supabase + Corbado監査をBI統合ダッシュボード化。 | Phase10〜11 |

---

### 9.6 承認・管理

| 役割   | 担当        | 内容                        |
| ---- | --------- | ------------------------- |
| 作成   | Tachikoma | 全章再構築（v1.1統合対応）           |
| レビュー | TKD       | 技術・UI・UX整合承認（Phase9最終承認者） |
| 実装整合 | Windsurf  | コード生成・テスト自己採点との一致確認       |
| 品質監査 | Gemini    | UTカバレッジ・CI品質検証            |
| 履歴管理 | Claude    | バージョン履歴・ファイルリンク整合維持       |

---

### 9.7 統合コメント

本設計書群（ch01〜ch09）は、HarmoNet Phase9 における **正式統合仕様** として承認される。
A-02 PasskeyButton は廃止され、A-01 MagicLinkForm に完全統合された。これにより、ユーザーは単一操作（ログインボタン押下）のみで MagicLink または Passkey による認証が可能となり、UX・保守性・セキュリティの三要素が最適化された。

本v1.1は、Supabase Auth / Corbado SDK / StaticI18nProvider / ErrorHandlerProvider の完全整合を保証し、Windsurf 実装および CI/CD 自動検証に直接利用可能な最終仕様である。
Phase10以降の技術移行（Corbado React SDK採用）に伴い、再度 `v2.0` 系で改訂予定。

---

**Document Status:** ✅ HarmoNet Phase9 最終統合仕様（MagicLink + Passkey 自動認証対応・v1.1）
