# Claude実行指示書_C-07_SecuritySpec_v1.0

**Document ID:** HARMONET-CLAUDE-INSTRUCTION-C07-SECURITYSPEC  
**Related Spec:** `/01_docs/04_詳細設計/01_ログイン画面/login-feature-design-ch05_v1.1.md`  
**ContextKey:** HarmoNet_LoginFeature_Phase9_v1.3_Approved  
**Last Updated:** 2025-11-10 05:30  

---

## 🎯 実行目的

`login-feature-design-ch05_v1.1.md` に基づき、  
**A-01〜A-03共通セキュリティ設計書（SecuritySpec）** の詳細設計ドキュメントを作成する。  

目的：Phase9承認仕様におけるセキュリティ設計（Magic Link + Passkey + Supabase Auth + RLS）を、  
**実装者が迷わず安全に実装できる粒度** に落とし込むこと。  

本出力は `/01_docs/04_詳細設計/01_ログイン画面/` に格納され、  
Geminiおよびタチコマによるクロスレビューを経て承認される。

---

## 📘 スコープ

対象範囲：
- ログイン関連コンポーネント（A-01〜A-03）
  - A-01 MagicLinkForm  
  - A-02 PasskeyButton  
  - A-03 AuthCallbackHandler  
- 認証方式：Supabase Auth（Magic Link + Passkey）
- DB保護構造：RLS + tenant_id + JWT  
- ログ／監査：Auth Log・Edge Function・Audit Trigger  

非対象：
- MyPage 内セキュリティ設定画面  
- Supabaseプロジェクト設定ファイル（既存仕様）  
- AppHeader/AppFooter等のUIコンポーネント

---

## ⚙️ 技術前提

| 項目 | 内容 |
|------|------|
| **フレームワーク** | Next.js **16.0.1** |
| **ランタイム** | Node.js 20 LTS |
| **バックエンド** | Supabase (PostgreSQL 17 + Edge Function) |
| **データ保護** | RLS (Row Level Security) + tenant_id分離 |
| **トークン管理** | JWT (HttpOnly Secure Cookie) |
| **通信保護** | HTTPS/TLS1.3 + HSTS |
| **セキュリティ標準** | OWASP ASVS Level 1 準拠 |
| **UI/UX基準** | common-design-system_v1.1.md |
| **翻訳/i18n基準** | common-i18n_v1.0.md |
| **アクセシビリティ** | common-accessibility_v1.0.md |

---

## 📑 入力ドキュメント

| ファイル | 用途 |
|-----------|------|
| `login-feature-design-ch05_v1.1.md` | セキュリティ対策仕様（Phase9正式版） |
| `login-feature-design-ch04_v1.1.md` | Magic Link + Passkey誘導仕様参照 |
| `harmonet-technical-stack-definition_v3.7.md` | 技術構成参照 |
| `common-design-system_v1.1.md` | UIデザイン・安全設計基準参照 |
| `common-i18n_v1.0.md` | エラーメッセージ辞書構造参照 |
| `common-accessibility_v1.0.md` | アラート／ARIA仕様参照 |
| `20251107000001_enable_rls_policies.sql` | RLSポリシー構成定義 |
| `schema.prisma` | ユーザーモデル／tenant_id構造定義 |

---

## 🧩 出力要件

Claudeは以下の構成で詳細設計書を出力すること。

- 出力形式：Markdown（UTF-8）
- 構成章立て：
  1. 概要（目的・適用範囲）  
  2. セキュリティ原則（ゼロトラスト設計指針）  
  3. 脅威モデル（攻撃パターンと防御策）  
  4. 技術層別対策（通信・認証・RLS・UI）  
  5. JWT・Passkey管理詳細  
  6. ログ・監査・エラーハンドリング  
  7. セキュリティテスト観点（ASVS対応表）  
  8. 受入基準（Lighthouse/OWASP）  
  9. 変更履歴  

### 設計重点
- **「安全を感じさせない安心感」** をUI/UX方針として維持。  
- Magic Link再送／Passkey登録誘導を含むシナリオ全体の防御網を明確化。  
- RLS／JWT／Supabase Auth構造の整合性を技術レベルで示すこと。  
- エラー文言は `common-i18n` 準拠キーで明記する。  

---

## 🚫 禁止事項

1. Supabaseスキーマ変更（enum追加・テーブル変更を含む）  
2. 外部セキュリティ製品の導入提案（既存スタック内完結）  
3. UIレイヤーへの警告強調表示（恐怖感を与える演出は禁止）  
4. i18nキー・命名規則変更  
5. Tailwind以外のCSSライブラリ使用  

---

## ✅ 成果物検証基準

| 項目 | 基準 |
|------|------|
| 自己評価スコア（AverageScore） | 9.0以上 |
| OWASP ASVS L1項目 | 100%準拠 |
| Lighthouse Security | 95点以上 |
| JWT失効テスト | 全ケース成功 |
| RLSテナント分離検証 | 完全遮断（403） |
| Supabase AuthトークンTTL | 60秒（Magic Link） |
| Passkey Origin Validation | 100%一致 |

---

## 🔍 整合性ルール

- Phase9設計体系（v1.3.1系列）に準拠  
- ch00〜ch06間で用語・構造を完全統一  
- 参照パスは `_latest.md` 形式  
- Document ID・Version履歴は維持  

---

## 🧠 実行メモ

Claudeは出力完了時に `[CodeAgent_Report]` ブロックを生成し、  
自己採点・試行回数・依拠ファイルを明記する。  
成果物は `/01_docs/04_詳細設計/01_ログイン画面/` に格納すること。

---

**Created:** 2025-11-10 / **Version:** 1.0 / **Document ID:** HARMONET-CLAUDE-INSTRUCTION-C07-SECURITYSPEC
