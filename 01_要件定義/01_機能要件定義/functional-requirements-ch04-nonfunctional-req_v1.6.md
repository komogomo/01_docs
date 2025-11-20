# 第4章 非機能要件（v1.6：MagicLink + Google 翻訳 + Google Cloud TTS + Supabase Cloud）

**準拠:** HarmoNet Functional Requirements v1.6
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet 正式非機能要件
**Updated:** 2025-11-19

---

# 4.1 セキュリティ要件

## 4.1.1 認証方式

HarmoNet は認証方式として **Supabase Auth（MagicLink + PKCE）** を採用する。

### 認証フロー

1. `/login` でメールを入力 → `signInWithOtp` により MagicLink を送信
2. ユーザーがメール内リンクをクリック → `/auth/callback` へ遷移
3. Supabase クライアントが URL フラグメントを検出し、PKCE でセッション確立
4. ログイン成功後、`/home` に遷移して認可チェック

### セキュリティ対策

| 項目     | 内容                                                    |
| ------ | ----------------------------------------------------- |
| 方式     | MagicLink（OTP）+ PKCE + HTTPS                          |
| Cookie | Secure / HttpOnly / SameSite=Lax（Supabase 標準）         |
| JWT    | `sub` = `auth.users.id` を唯一の正とする                      |
| URL    | MagicLink のコードは URL フラグメントで処理（Server Component で扱わない） |
| 機密情報管理 | Service Role Key / API Key は Secrets 管理（Git に含めない）    |

### データ保護

* すべての通信は TLS1.3 で暗号化
* 個人情報は最小限のみ保持し、ログには平文で残さない

---

## 4.1.2 テナント分離（RLS）

HarmoNet のマルチテナント構成は **Supabase PostgreSQL + RLS** を基盤とする。

### 基本ポリシー

```
USING (
  tenant_id = auth.jwt()->>'tenant_id'
)
```

### ポイント

* 認証後の JWT に含まれる `tenant_id` が行レベルの分離根拠
* `user_tenants` は自身の行のみ読み取り可能
* 認可は `/home` Server Component 側で最終確認

---

# 4.2 性能要件

## 4.2.1 目標値　Google TTS 構成

| 項目       | 目標値          | 備考                                  |
| -------- | ------------ | ----------------------------------- |
| 初回表示     | 3 秒以内        | App Router + Vercel Cache           |
| 再訪表示     | 1.5 秒以内      | ブラウザキャッシュ                           |
| 翻訳応答     | 1〜2 秒        | Google Translation API v3           |
| **音声生成** | **1〜2 秒**    | **Google Cloud TTS** |
| DB クエリ   | 1 秒以内        | インデックス最適化前提                         |
| 同時アクセス   | 100〜200 ユーザー | 個人開発で現実的な上限                         |

## 4.2.2 最適化方針

* Next.js 標準最適化（Dynamic Import / Suspense）
* 画像最適化（Next Image）
* 翻訳・音声キャッシュは `translation_cache` / `tts_cache`（Supabase DB + Storage）
* Redis は任意（必須ではない）

---

# 4.3 アクセシビリティ

HarmoNet は **WCAG 2.2 Level AA** を基準とする。

| 区分  | 要件                                     |
| --- | -------------------------------------- |
| 視認性 | コントラスト比 4.5:1 以上                       |
| 操作性 | 主要操作はキーボードで利用可能                        |
| 理解性 | エラーメッセージは短く明確に                         |
| 多言語 | JA/EN/ZH の切替を StaticI18nProvider で即時反映 |

---

# 4.4 スケーラビリティ

個人開発向けの現実的なスケールを前提とする。

| 段階      | ユーザ規模    | 構成                                 |
| ------- | -------- | ---------------------------------- |
| MVP     | 100 ユーザー | Supabase Free / Pro + Vercel Hobby |
| 小規模     | 300〜500  | Supabase Pro + Vercel Pro          |
| 中規模（将来） | 1000+    | 必要時に検討
---

# 4.5 可用性（Availability）

| 項目     | 内容                               |
| ------ | -------------------------------- |
| 稼働率    | Supabase / Vercel の標準 SLA に依存    |
| バックアップ | Supabase 自動スナップショット              |
| 監視     | 専用監視サービスは導入しない（画面異常で気づいた時点で手動確認） |
| 復旧     | 開発者が Supabase / Vercel 管理画面で手動復旧 |

---

# 4.6 メンテナンス性

| 観点        | 方針                                       |
| --------- | ---------------------------------------- |
| SDK 更新    | Supabase / Prisma / Next.js の標準更新に追従     |
| Migration | Prisma Migrate を基本とする                    |
| Secrets   | `.env.local` / Vercel Secrets で管理        |
| ログ運用      | 外部ログサービスは使用せず、Vercel / Supabase 標準ログのみ使用 |

---

# 4.7 法令準拠

| 区分     | 要件                                 |
| ------ | ---------------------------------- |
| 個人情報   | 不要な項目を収集しない。必要時は暗号化検討              |
| Cookie | 認証 Cookie のみ使用（サードパーティ Cookie 不使用） |
| データ削除  | 退会時の削除方針は将来設計（本要件では対象外）            |

---

# 4.8 ログ要件

## 4.8.1 ログ種別

| 種別    | 目的        |
| ----- | --------- |
| AP ログ | 開発・障害解析   |
| エラーログ | 例外発生箇所の確認 |

## 4.8.2 出力方針

* `console.log` / `console.error` による標準出力
* 本番ログは Vercel / Supabase の標準ログで確認
* 外部トラッキング（Sentry 等）は使用しない

## 4.8.3 個人情報の扱い

* メールアドレス・氏名などはログに平文で残さない
* 必要時はハッシュ化または匿名 ID を使用

---

# 4.9 運用

* 商用 SLA を要求しない
* 障害発生時は開発者が手動で確認・復旧
* デプロイは Vercel ダッシュボード（CI/CD は任意）

---

**Document ID:** HARMONET-REQ-NFR-V1.6
**Version:** 1.6
**Created:** 2025-11-19
**Updated:** 2025-11-19
**Supersedes:** v1.5
**Status:** ✅ HarmoNet 正式非機能要件（MagicLink + Google 翻訳 + Google Cloud TTS 版）
