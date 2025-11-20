# 第4章 非機能要件（v1.5）

（MagicLink + Google 翻訳 + VOICEVOX + Supabase Cloud 構成）

**準拠:** HarmoNet Technical Stack Definition v4.3
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Updated:** 2025-11-19
**Status:** ✅ HarmoNet 正式非機能要件（現実的構成 / 個人開発運用方針整合）

---

# 4.1 セキュリティ要件

## 4.1.1 認証方式（MagicLink のみ）

HarmoNet は、認証方式として **Supabase Auth（MagicLink + PKCE）** を採用する。

### 認証フロー（確定仕様）

1. `/login` でメールアドレス入力 → `signInWithOtp` により MagicLink を送信。
2. ユーザーがメール内リンクをクリックし、`/auth/callback` に遷移。
3. ブラウザ側 Supabase クライアントが URL フラグメントを検出し、PKCE フローでセッション確立。
4. 成功後、`/home` にリダイレクトされ、Server Component にて認可チェックが行われる。

### セキュリティ対策

| 項目      | 内容                                                              |
| ------- | --------------------------------------------------------------- |
| 方式      | MagicLink（OTP）+ PKCE + HTTPS                                    |
| セッション管理 | Supabase Auth（ブラウザ側でセッション維持）                                    |
| JWT     | `sub` = `auth.users.id` を唯一の正として利用                              |
| URL     | MagicLink のコードは URL フラグメントに格納（Server Component では読み取らない）        |
| Cookie  | Secure / HttpOnly / SameSite=Lax（Supabase 標準）                   |
| 機密情報管理  | API Key / Service Role Key は `.env.local` / Vercel Secrets にて管理 |

### データ保護

* すべての通信を HTTPS（TLS 1.3）で暗号化する。
* E2E 暗号化は Supabase 標準を使用し、追加暗号化は不要。
* 個人情報は最小限の項目のみ保存し、ログには平文で残さない。

---

## 4.1.2 テナント分離（RLS）

HarmoNet のマルチテナント設計は **Supabase PostgreSQL の Row Level Security（RLS）** を基盤とする。

### 基本ルール

```
USING (
  tenant_id = auth.jwt() ->> 'tenant_id'
  OR user_id = auth.jwt() ->> 'sub'
)
```

### 要点

* `auth.users` をソースオブトゥルースとし、`public.users` は同期トリガーで保持。
* `user_tenants` の RLS は「自分自身（sub）の行は常に閲覧可能」とする。
* 認可チェックは `/home` Server Component にて実行する。

---

# 4.2 性能要件

## 4.2.1 目標値（現実的・MVP 向け）

| 項目     | 目標値        | 備考                                           |
| ------ | ---------- | -------------------------------------------- |
| 初回表示   | 3 秒以内      | Next.js App Router + Vercel Cache            |
| 再訪表示   | 1.5 秒以内    | ブラウザキャッシュ前提                                  |
| 翻訳応答   | 1〜3 秒      | Google Translation API（Next.js API Route 経由） |
| 音声生成   | 5 秒以内      | VOICEVOX（キャッシュ再利用で 1 秒以下）                    |
| DB クエリ | 1 秒以内      | インデックス最適化前提                                  |
| 同時アクセス | 100 ユーザー程度 | 個人開発アプリとして現実的規模                              |

## 4.2.2 最適化方針

* Next.js App Router の標準最適化（Dynamic Import / 画像最適化）。
* バンドルサイズ抑制：不要ライブラリは使用しない。
* Supabase クエリは最小回数にし、UI フリーズを避ける。
* 翻訳・音声のキャッシュは Redis / Supabase Storage を併用する。

---

# 4.3 アクセシビリティ

HarmoNet は **WCAG 2.2 Level AA 相当** を基準とする。

| 区分  | 要件                                           |
| --- | -------------------------------------------- |
| 視認性 | コントラスト比 4.5:1 以上                             |
| 操作性 | 全主要操作をキーボードで実行可能にする                          |
| 理解性 | エラー文言は短く明確で、次の行動が分かる内容にする                    |
| 多言語 | UI テキストは StaticI18nProvider 管理。日本語・英語・中国語に対応 |

---

# 4.4 スケーラビリティ

HarmoNet の初期運用は現実的なスケールであり、大規模運用を前提としない。
次の構成を基準とする：

| 段階  | ユーザー規模       | 構成                                 |
| --- | ------------ | ---------------------------------- |
| MVP | 100 ユーザー     | Supabase Free / Pro + Vercel Hobby |
| 小規模 | 300〜500 ユーザー | Supabase Pro + Vercel Pro          |

※ それ以上は必要時にインフラ設計を見直す。

---

# 4.5 可用性（Availability）

HarmoNet は個人開発であり、常時 SLA は要求しない。
Vercel / Supabase が提供する稼働率に依存する。

| 項目     | 内容                                    |
| ------ | ------------------------------------- |
| 稼働率    | 明確な SLA は設定しない（Supabase / Vercel に準拠） |
| バックアップ | Supabase 自動スナップショットに依存。必要に応じ手動 Export |
| 復旧     | 障害時は Supabase / Vercel の管理画面で手動復旧     |
| 監視     | 専用監視サービスは導入しない（画面異常で気づいたら確認する運用）      |

---

# 4.6 メンテナンス性

| 観点        | 方針                                          |
| --------- | ------------------------------------------- |
| SDK 更新    | Supabase / Prisma / Next.js の標準更新に追従        |
| Migration | Prisma Migrate を基本とする                       |
| 環境変数      | `.env.local` / Vercel Secrets で管理。Git に含めない |
| ログ運用      | Vercel / Supabase の標準ログのみ利用。外部サービスは使用しない    |

---

# 4.7 法令準拠

| 区分     | 要件                      |
| ------ | ----------------------- |
| 個人情報   | 不要な個人情報を収集しない。必要時は暗号化検討 |
| Cookie | 認証に必要な Cookie のみ使用      |
| データ削除  | ユーザー退会時の削除ルールを将来策定      |

---

# 4.8 ログ要件

## 4.8.1 ログ種別

HarmoNet で扱うログは 2 種類のみ。

| 種別    | 目的        |
| ----- | --------- |
| AP ログ | 開発・障害解析   |
| エラーログ | 例外発生箇所の確認 |

## 4.8.2 出力方針

* `console.log` / `console.error` を使用。標準出力へ集約。
* 本番ログは Vercel / Supabase 標準ログで確認。
* 外部エラートラッキング（Sentry 等）は使用しない。

## 4.8.3 個人情報の扱い

* メールアドレス・氏名などはログに平文で残さない。
* 必要時はハッシュ化または匿名化 ID を使用する。

---

# 4.9 運用

## 方針

* 個人開発であり、商用 SLA を要求しない。
* 障害発生時は開発者が手動確認し、必要に応じて再デプロイする。
* Vercel / Supabase のログでトラブルシュートする。

---

**Document ID:** HARMONET-REQ-NFR-V1.5
**Version:** 1.5
**Created:** 2025-11-12
**Updated:** 2025-11-19
**Supersedes:** v1.4
**Status:** ✅ HarmoNet 正式非機能要件（MagicLink + Google 翻訳 + VOICEVOX 構成）
