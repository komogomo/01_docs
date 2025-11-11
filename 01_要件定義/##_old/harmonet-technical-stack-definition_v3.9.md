# HarmoNet 技術スタック定義書  
**Document ID:** HARMONET-TECH-STACK-V3.9**  
**Version:** 3.9  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Supersedes:** harmonet-technical-stack-definition_v3.8.md  

---

## 第1章 概要
本書は HarmoNet プロジェクトにおけるアプリケーション基盤・技術構成・外部依存関係を定義する。  
本バージョンでは、Passkey（WebAuthn）認証を Corbado SDK 経由で実装する外部連携構成を追加した。

---

## 第2章 基本構成
| 層 | 技術要素 | 備考 |
|----|-----------|------|
| フロントエンド | **Next.js 16.0.1 (App Router)** + React 19 | TailwindCSS / shadcn/ui |
| 認証 | **Supabase Auth**（Magic Link / OTP / External Provider） | RLSによる制御 |
| 外部Passkey認証 | **Corbado WebAuthn SDK (@corbado/web-js)** | WebAuthn登録・認証を担当 |
| API通信 | Supabase Edge Function / REST | HTTPS必須 |
| データベース | PostgreSQL 15.6（Supabaseコンテナ） | Prisma ORM |
| i18n | StaticI18nProvider (C-03) | ja / en / zh |
| スタイル | TailwindCSS 3.4 / shadcn/ui | Appleカタログ調 |
| テスト | Jest + React Testing Library | ユニット・結合検証 |
| バージョン管理 | GitHub + Google Drive Mirror | PJファイル同期 |

---

## 第3章 認証・セキュリティ構成

### 3.1 認証方式
| 区分 | 概要 | 担当 |
|------|------|------|
| Magic Link / OTP | Supabase標準Auth | Supabase |
| Passkey（WebAuthn） | Corbado連携方式 | Corbado SDK |
| セッション管理 | JWT / Secure Cookie | Supabase |
| アクセス制御 | RLS / tenant_id スコープ | PostgreSQL |

### 3.2 Corbado連携構成
1. ユーザーが `Corbado.loginWithPasskey()` によりWebAuthn認証を実行  
2. 成功時に Corbado SDK から `id_token` を取得  
3. `supabase.auth.signInWithIdToken({ provider: 'corbado', token: id_token })` でセッション確立  
4. SupabaseはRLSに基づきアクセス制御を実施  

> **注記:**  
> 2025年11月時点、SupabaseはネイティブなPasskey APIを未提供。  
> HarmoNetではCorbado連携方式を採用し、WebAuthn検証責務をCorbadoが担う。  

---

## 第4章 データベース構成
- PostgreSQL 15.6（Supabase）
- Prisma ORM v5系
- テナント分離: tenant_id スコープ管理
- RLSポリシー: user_role / tenant_id / is_deleted
- JSONB利用: 多言語・拡張属性保持

---

## 第5章 使用ライブラリ一覧
| ライブラリ | バージョン | 用途 |
|-------------|-------------|------|
| next | ^16.0.1 | App Router構成 |
| react | ^19.0.0 | UIレンダリング |
| @supabase/supabase-js | ^2.43.0 | 認証・DB通信 |
| @corbado/web-js | ^2.x | Passkey(WebAuthn)連携 |
| prisma | ^5.x | ORM |
| tailwindcss | ^3.4.0 | スタイリング |
| shadcn/ui | latest | UIコンポーネント |
| lucide-react | ^0.325.0 | アイコン |
| jest / rtl | ^29.x / ^14.x | テスト |

---

## 第6章 今後の拡張
- SupabaseがネイティブPasskey APIを実装した際は、Corbado依存を段階的に縮小。  
- MyPage配下にPasskey登録・管理UIを追加予定。  
- 多要素認証 (MFA) 連携機能の導入を検討中。  

---

## 第7章 メタ情報
**保存パス:** `/01_docs/00_project/harmonet-technical-stack-definition_v3.9.md`  
**Supersedes:** v3.8  
**Author:** Tachikoma / TKD  
**Reviewers:** Gemini-Audit, Claude  
**Purpose:** Phase9 認証機構確定仕様書  

---

## 第8章 監査・保守指針
- **設計監査:** Gemini-Audit によるAPI実在性・セキュリティ整合監査を継続  
- **コード監査:** Claude 実行指示書を基に Windsurf 実装出力を検証  
- **運用監査:** MyPage / Authフローに対し年1回の脆弱性検査を実施  
- **依存監査:** Corbado SDK / Supabase SDK のバージョン差分を月次でチェック  
- **記録:** GitHub + Google Drive にバージョン履歴を保管（PJファイル統合）

---

## 第9章 ChangeLog（更新履歴）
| Version | Date | Author | Description |
|----------|------|---------|-------------|
| v3.8 | 2025-11-10 | TKD / Tachikoma | Next.js 16.0.1 対応、StaticI18nProvider統合 |
| **v3.9** | **2025-11-10** | **TKD / Tachikoma** | **Passkey認証をCorbado WebAuthn SDK方式へ変更。Supabaseはセッション管理専用に限定。第8章監査指針・第9章ChangeLog追加。** |

---

✅ **本書はHarmoNet Phase9技術仕様の最新版として正式採用。**
