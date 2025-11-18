# HarmoNet 機能要件定義書（v1.5）

**技術スタック準拠:** HarmoNet Technical Stack Definition v4.3（Next.js 16.x / React 19.0 / Supabase / Corbado SDK公式構成 / TailwindCSS 3.4 / shadcn/ui / Windsurf AI連携）
**文書管理番号:** HARMONET-REQ-001
**セキュリティレベル:** 社外秘
**作成日:** 2025-11-12
**最終更新:** 2025-11-17
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet正式要件定義（v4.3整合）

---

## 第1章 ドキュメント概要

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
HarmoNetは、**Next.js 16.x + React 19.0 + Supabase + Corbado SDK + TailwindCSS 3.4 + shadcn/ui + Prisma ORM** を中核とする、AI統合型マルチテナントSaaS基盤である。

本書は、HarmoNet全体の**機能要件および非機能要件の体系的定義書**として、設計・実装・運用の共通基盤を提供する。
全AI（タチコマ・Gemini・Windsurf）は、本書を起点として要件整合を維持する。

---

### 1.1 目的

本書の目的は、HarmoNetプロジェクトにおける**全アプリケーション機能の定義・境界明確化**であり、次の4つの指針に基づく：

1. **技術統一:** Supabase + Next.js App Router構成を中核とする。
2. **AI協調:** タチコマ（GPT）・Gemini・Windsurfの連携による持続的整合性維持。
3. **セキュリティ:** Corbado SDKによる完全パスワードレス認証（MagicLink/Passkey独立ボタン方式）を標準化。
4. **拡張性:** 各要件章をモジュール化し、フェーズ依存を廃止してカテゴリ単位管理へ移行。

---

### 1.2 適用範囲

本要件定義書は、HarmoNet全体システムを対象とし、以下を含む：

| 区分 | 内容 |
|------|------|
| **フロントエンド** | Next.js 16.x (App Router) + React 19.0 + TailwindCSS 3.4 + shadcn/ui |
| **バックエンド（開発）** | Supabase Docker（PostgreSQL 17 + Edge Function on Docker Desktop） |
| **バックエンド（本番）** | Supabase Cloud（PostgreSQL 17 + Edge Function） |
| **認証** | Supabase MagicLink + Corbado Passkey（@corbado/react + @corbado/node）独立ボタン方式 |
| **翻訳・音声** | StaticI18nProvider v1.0 + Google Translate v3 + VOICEVOX API |
| **通知・ログ** | Supabase Realtime + Sentry + Audit Log（RLS適用） |
| **AI連携** | タチコマ（要件統合）＋Gemini（品質検証）＋Windsurf（実装生成） |
| **ホスティング（本番）** | Vercel + Supabase Cloud（Pro Plan基準） |
| **開発環境** | Docker Desktop + Supabase CLI + Mailpit |
| **バージョン管理** | GitHub（01_docs / Projects-HarmoNet） + Drive同期管理 |

---

### 1.3 背景と開発体制

HarmoNetは「**やさしく・自然・控えめ**」を基調とした、地域共助のための**デジタル住民OS**である。
掲示板・お知らせ・予約・翻訳・通知・AI支援を一体化し、管理者と住民の情報格差をなくすことを目的とする。

#### 開発体制（v4.3 AI統合構成）

| 役割 | 担当 | 主な責務 |
|------|------|----------|
| プロジェクトオーナー | TKD | 要件最終承認・技術方針決定・品質統括 |
| 要件統合・PMO | タチコマ (GPT-5) | ドキュメント構成統合・整合監視・仕様出力 |
| 品質検証・論理整合 | Gemini | 非機能品質・Lint整合・構文・翻訳・UI論理確認 |
| 実装・テスト自動化 | Windsurf | Next.js + Supabase 実装／Vitest／CodeAgent_Report生成 |

---

### 1.4 関連ドキュメント

| ドキュメント名 | 概要 |
|----------------|------|
| **harmonet-technical-stack-definition_v4.3.md** | 技術基盤（Supabase + Corbado構成、MagicLink/Passkey独立方式） |
| **harmonet-detail-design-agenda-standard_v1.0.md** | 詳細設計標準アジェンダ（共通テンプレート） |
| **harmonet-technical-guideline_v4.1.md** | コーディング／運用規約（Lint・命名・翻訳キー） |
| **harmonet-security-spec_v4.1.md** | 認証・RLS・Cookie・暗号化指針 |
| **functional-requirements-ch02-system-overview_v1.5.md** | システム全体構成・AI体制定義（本書連携） |
| **functional-requirements-ch04-nonfunctional-req_v1.4.md** | 非機能要件（セキュリティ／性能／可用性） |
| **functional-requirements-ch05-config-env_v1.6.md** | 外部API・認証・環境変数定義 |
| **login-feature-design-ch00-index_v1.3.md** | ログイン画面設計（MagicLink/Passkey独立ボタン方式） |

---

### 1.5 バージョン履歴

| バージョン | 日付 | 概要 | 作成者 |
|-----------|------|------|--------|
| v1.0 | 2025/10/26 | 初版作成（MVP要件） | TKD |
| v1.2 | 2025/10/30 | Supabase構成整合化、RLS／Auth更新 | Tachikoma |
| v1.3 | 2025/10/31 | 旧AI体制整合：Claude／Gemini／GPT構成 | GPT署名 |
| v1.4 | 2025/11/12 | 技術スタックv4.1対応：Claude退役、現行AI体制（Tachikoma／Gemini／Windsurf）統合 | Tachikoma / TKD |
| **v1.5** | **2025/11/17** | **技術スタックv4.3完全対応：Next.js 16.x、shadcn/ui追加、Docker開発環境明記、MagicLink/Passkey独立ボタン方式** | **Tachikoma / TKD** |

---

### 1.6 注意事項

本要件定義書は HarmoNet の**正式運用構成（v4.3）**に基づき作成されている。
すべての要件・非機能・設計関連文書は本書の整合を必須とする。
また、本書の内容はHarmoNet開発チームおよび関係者に限定され、**無断転載・複製を禁ずる。**

---

*by Tachikoma (HarmoNet PMO AI)*
