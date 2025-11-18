# HarmoNet 技術スタック定義書 v4.3

**Document ID:** HARMONET-TECH-STACK-V4.3
**Version:** 4.3
**Supersedes:** v4.2
**Created:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** 最新ログイン方式（MagicLink / Passkey 独立ボタン方式）反映版

---

## 第1章 概要

本書は HarmoNet プロジェクトの技術基盤を体系的に定義するもの。
v4.3 では、ログイン方式に関する仕様を最新要件に合わせて更新し、

**MagicLink（メール認証）と Passkey（WebAuthn）の 2 方式を独立したカードタイル UI としてログイン画面に並列表示する正式仕様**

へ統一する。
旧仕様であった「Passkey を MagicLinkForm 内に統合し、自動判定する方式」は完全に廃止する。←Passkey導入は当面見送りとする。

---

## 第2章 アーキテクチャ概要

| 層          | 採用技術                                                | 目的                    |
| ---------- | --------------------------------------------------- | --------------------- |
| **UI層**    | Next.js 16 + React 19                               | Appleカタログ風 UI / SSR対応 |
| **認証層**    | Supabase Auth（MagicLink） + Corbado Web SDK（Passkey） | 2種類のパスワードレス認証方式を提供    |
| **国際化層**   | StaticI18nProvider (C‑03)                           | JSON辞書ベースの多言語化        |
| **バックエンド** | Supabase（PostgreSQL 17）                  | RLS / tenant_id 分離    |
| **CI/CD**  | GitHub Actions + Windsurf + Vitest                  | 自動テスト・静的解析・コード生成      |

---

## 第3章 技術スタック構成

| カテゴリ     | 採用技術                                    | バージョン      | 用途                           |
| -------- | --------------------------------------- | ---------- | ---------------------------- |
| フレームワーク  | Next.js                                 | 16.x       | App Router 対応                |
| 言語       | TypeScript                              | 5.6        | ESM・型安全                      |
| UI / CSS | React 19 + TailwindCSS 3.4 + shadcn/ui  | 最新         | HarmoNet UI トーン              |
| BaaS     | Supabase                                | v2.43      | MagicLink 認証 / Storage / RLS |
| ORM      | Prisma                                  | v6.x       | DB スキーマ管理・マイグレーション           |
| 認証 SDK   | Corbado Web SDK（@corbado/web-js + node） | v2.x       | Passkey（WebAuthn）対応          |
| アイコン     | lucide-react                            | 最新         | 線形アイコン標準                     |
| 国際化      | StaticI18nProvider                      | v1.0       | JSON辞書多言語化                   |
| テスト      | Vitest + RTL                            | 最新         | 単体・結合テスト                     |
| ビルド      | Turbopack                               | Next.js 標準 |                              |

---

## 第4章 SDK 構成

| SDK名               | 使用箇所                               | 機能                                        | 備考         |
| ------------------ | ---------------------------------- | ----------------------------------------- | ---------- |
| Supabase JS SDK    | MagicLinkForm, AuthCallbackHandler | `signInWithOtp()` / `signInWithIdToken()` | OTP 認証     |
| Corbado Web SDK    | PasskeyAuthTrigger                 | Passkey 認証                                | UI 依存なし    |
| Corbado Node SDK   | API側                               | トークン検証 / JWT署名確認                          | サーバー側      |
| Prisma ORM         | サーバー                               | スキーマ管理                                    | Supabase連携 |
| StaticI18nProvider | UI層                                | 多言語化                                      | JSON辞書形式   |

---

## 第5章 認証フロー（独立方式）

### 5.1 MagicLink（メール認証）フロー

```mermaid\sequenceDiagram
  participant U as User
  participant F as MagicLinkForm (A‑01)
  participant S as Supabase

  U->>F: メール入力 + 「ログイン」タイル押下
  F->>S: signInWithOtp({ email })
  S-->>F: メール送信成功
  F-->>U: メール送信完了メッセージ表示
```

### 5.2 Passkey（WebAuthn）フロー

```mermaid\sequenceDiagram
  participant U as User
  participant P as PasskeyAuthTrigger (A‑02)
  participant C as Corbado
  participant S as Supabase

  U->>P: Passkey タイル押下
  P->>C: Corbado.passkey.login()
  C-->>P: id_token 返却
  P->>S: signInWithIdToken({ token })
  S-->>P: セッション確立
  P-->>U: /mypage へ遷移
```

Passkey の利用可否判定や OS ネイティブ UI 表示は、すべて Corbado / WebAuthn 側の仕様に従う。

---

## 第6章 通信・API仕様

| 区分               | 呼出元                | メソッド                  | 概要             |
| ---------------- | ------------------ | --------------------- | -------------- |
| Supabase Auth    | MagicLinkForm      | `signInWithOtp()`     | MagicLink 送信   |
| Supabase Auth    | PasskeyAuthTrigger | `signInWithIdToken()` | Passkey トークン認証 |
| Corbado Web SDK  | PasskeyAuthTrigger | `passkey.login()`     | WebAuthn 起動    |
| Corbado Node SDK | API層               | `verify()`            | id_token 検証    |

---

## 第7章 セキュリティ指針

* HTTPS 必須（WebAuthn 要件）
* RP ID / Origin は `harmonet.app` に固定
* Supabase RLS: `tenant_id = (auth.jwt()->>'tenant_id')` で分離
* Corbado API Key は Vault 管理
* JWT 有効期限: 10 分
* Cookie: Secure + HttpOnly

---

## 第8章 マルチテナント / RLS

Supabase による列レベルセキュリティを全テーブルに適用する。
MagicLink / Passkey いずれも **tenant_id** を JWT の Claim から取得し、
ログイン後のデータアクセスが完全に分離されるよう設計する。

---

## 第9章 運用・拡張性

1. SDK / ライブラリ更新は月次で確認
2. Feature Flag により **Passkey 機能の段階的リリース**が可能
3. CI/CD で `.env.production` を自動生成
4. Windsurf 自己採点レポート（平均 9 以上）を品質基準として採用

---

## 第10章 関連設計書

| 種別         | ファイル名                                      | 内容               |
| ---------- | ------------------------------------------ | ---------------- |
| 詳細設計（A-01） | `MagicLinkForm-detail-design_v1.3.md`      | MagicLink 専用フォーム |
| 詳細設計（A-02） | `PasskeyAuthTrigger-detail-design_v1.2.md` | Passkey 認証トリガ    |
| 詳細設計（A-00） | `LoginPage-detail-design_v1.2.md`          | ログイン画面構成（左右2タイル） |
| 共通部品       | StaticI18nProvider-detail-design_v1.0      | 多言語化             |
| セキュリティ     | `harmonet-security-policy_latest.md`       | 全体セキュリティ基準       |
| DB/RLS     | `schema.prisma`                            | テナント分離・RLS定義     |

---

## 第11章 改訂履歴

| Version  | Date           | Author          | Summary                                                            |
| -------- | -------------- | --------------- | ------------------------------------------------------------------ |
| v4.0     | 2025-11-10     | TKD / Tachikoma | 旧仕様（PasskeyButton）前提の構成                                            |
| v4.1     | 2025-11-12     | TKD / Tachikoma | PasskeyButton 廃止案（※現行要件では非採用）                                      |
| v4.2     | 2025-11-12     | Tachikoma       | MagicLinkForm に Passkey 統合案（旧仕様・廃止）                                |
| **v4.3** | **2025-11-16** | **Tachikoma**   | **最新要件反映。MagicLink / Passkey を独立ボタンとして並列表示する正式仕様へ統一。自動判定方式を完全廃止。** |

---

**Document Status:** HarmoNet ログイン方式（MagicLink / Passkey）最新版仕様反映版 v4.3
