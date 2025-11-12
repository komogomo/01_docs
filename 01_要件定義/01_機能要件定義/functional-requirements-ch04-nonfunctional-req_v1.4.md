# 第4章 非機能要件（v1.4）

本章は **HarmoNet Technical Stack Definition v4.0** に準拠する。
HarmoNetは **Next.js 16 / React 19 / Supabase v2.43 / Corbado SDK（React + Node） / Prisma / TailwindCSS 3.4** を中核とするマルチテナント型SaaS基盤上に構築される。

---

## 4.1 セキュリティ要件

### 4.1.1 認証方式

HarmoNetは、以下2方式を統合した**完全パスワードレス認証**を採用する：

* Supabase Auth による Magic Link 認証（一般ユーザー用）
* Corbado SDK による Passkey 認証（管理者・高度利用者用）

#### 認証フロー

1. MagicLink：ユーザーがメールアドレスを入力 → Supabase が OTP メール送信
2. Passkey：CorbadoAuth が WebAuthn 認証を実行 → `short_session` Cookie 発行
3. Supabase 側で Corbado JWT (`id_token`) を検証しセッションを確立
4. JWT には `tenant_id` / `role` / `lang` が含まれ、PostgreSQL RLS によりアクセスが制御される。

```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "role": "tenant_admin",
  "lang": "ja",
  "auth_provider": "corbado|supabase",
  "exp": 1739999999
}
```

#### セキュリティ対策

| 項目         | 内容                                         |
| ---------- | ------------------------------------------ |
| 認証強度       | WebAuthn FIDO2 + UUIDv4トークン + HTTPS限定      |
| トークン有効期限   | 15分（Corbado short_session + Supabase自動再発行） |
| レートリミット    | Supabase: 3リクエスト/分, Corbado: 5/分           |
| 監査ログ       | Supabase Auth Logs + Corbado Cloud Logs    |
| 管理者強制ログアウト | Supabase Session API で invalidate() 実行可    |

---

### 4.1.2 通信暗号化

* すべての通信を **TLS 1.3** で暗号化。
* HTTPリクエストはVercel側で自動HTTPSリダイレクト。
* Corbado `short_session` Cookie は `Secure + SameSite=Lax` 設定。
* SupabaseおよびCorbado APIキーは環境変数管理（`.env.local` / Vercel Secrets）。
* 個人情報カラム（氏名・メール・住所）はAES-256暗号化で保存。

---

### 4.1.3 データ分離（RLS）

Supabase PostgreSQL の **Row Level Security (RLS)** により、
テナント単位でデータアクセスを分離する。

```sql
CREATE POLICY tenant_isolation_policy
ON public.announcements
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

**補足:** すべてのテーブルに `tenant_id` カラムを持たせ、
`auth.jwt()` の内容に基づき自動的にスコープ制御を行う。Corbadoでログインした場合も Supabase 側で JWT検証が行われるため、テナント越境は不可能。

---

### 4.1.4 鍵管理

| 項目                 | 管理方法                                  |
| ------------------ | ------------------------------------- |
| 暗号鍵                | Supabase Secrets に保存し、API経由では取得不可     |
| Corbado API Secret | サーバ側 `.env` にのみ配置し、クライアント側へ露出禁止       |
| 鍵ローテーション           | 半年周期またはインシデント発生時に即時更新                 |
| JWT署名方式            | HS256（Supabase標準） + RS256（Corbado連携用） |
| APIキー管理            | Supabase Service Role 限定使用 + IP制限設定   |

---

## 4.2 性能要件

| 項目      | 目標値                   | 備考                              |
| ------- | --------------------- | ------------------------------- |
| 初回ページ表示 | 2.5秒以内                | Turbopack ビルド最適化 + CDNキャッシュ     |
| 再訪時表示   | 1秒以内                  | Vercel Edge CDN + ブラウザキャッシュ     |
| 翻訳応答    | 3秒以内（500文字）           | StaticI18nProvider + Redisキャッシュ |
| API応答   | 2秒以内（95th Percentile） | Supabase Edge Functions 活用      |
| DBクエリ   | 1秒以内                  | Prisma 最適化 + インデックス設計           |
| 同時アクセス  | 500ユーザー               | Supabase Pro Plan 想定            |

### 最適化施策

* **Next.js 16 App Router最適化**（Streaming + Suspense対応）
* **画像最適化**：WebP変換＋遅延ロード
* **コード分割**：Dynamic Importによる初期描画軽量化
* **Redisキャッシュ**：翻訳・セッション・設定値キャッシュ
* **Edge Function分散**：認証・翻訳・ログ取得をSupabase Edgeに委譲

---

## 4.3 アクセシビリティ

HarmoNetは **WCAG 2.2 Level AA** に準拠。
BIZ UDゴシックを基調とした「やさしく・自然・控えめ」デザインで、操作性と安心感を両立する。

| 区分  | 要件                               |
| --- | -------------------------------- |
| 視覚  | コントラスト比4.5:1以上、200%拡大対応          |
| 聴覚  | 音声・動画には字幕または代替テキスト提供（Phase後期対応）  |
| 操作  | キーボード・スクリーンリーダー完全対応（Passkey操作含む） |
| 理解  | 明快なエラーメッセージと統一UIトーン              |
| 多言語 | 日本語・英語・中国語に対応。ARIA属性と文言連動。       |

#### Passkey操作支援

* WebAuthn操作時に明示的な進行状態を表示（例：「パスキーを確認しています…」）。
* キーボードナビゲーションでPasskeyボタンへのフォーカス移動を保証。
* i18nキー：`auth.passkey.progress` / `auth.passkey.success` / `auth.passkey.error`。

---

## 4.4 スケーラビリティ

### 戦略

1. **垂直スケール**：Supabaseプランアップグレード（Pro→Team）でCPU/メモリ拡張。
2. **水平スケール**：Supabase Cloud + Vercel マルチリージョン展開対応。
3. **キャッシュ層**：Redisクラスタ化で翻訳・セッションを分散。
4. **テナント分離**：tenant_id単位バックアップにより復旧・負荷分散を容易化。
5. **CDN最適化**：Cloudflare CDNにより静的リソース配信を強化。

### 想定利用規模

| 段階  | ユーザー規模           | 対応構成                                    |
| --- | ---------------- | --------------------------------------- |
| MVP | 100ユーザー／単一物件     | Supabase Free Tier + Vercel Hobby       |
| 展開期 | 500ユーザー／複数物件     | Supabase Pro + Redis 1GB                |
| 拡張期 | 5,000ユーザー／複数管理会社 | Supabase Team + AWS Backup + Cloudflare |

---

## 4.5 信頼性・可用性

| 項目     | 要件                                   |
| ------ | ------------------------------------ |
| 稼働率    | 99.5%以上（Supabase Cloud SLA）          |
| バックアップ | Supabase 自動スナップショット（1日1回）            |
| 保持期間   | 7日間（増設可）                             |
| 監視     | Sentry + UptimeRobot + Supabase Logs |
| 復旧手順   | 自動リストア後、Vercel再デプロイで即復旧（RTO: 10分以内）  |
| デプロイ   | GitHub連携CI/CD（ロールバック3世代保持）           |

---

## 4.6 メンテナンス性・拡張性

| 観点     | 内容                                                 |
| ------ | -------------------------------------------------- |
| SDK更新  | Corbado・Supabase SDKを月次監視し、互換性検証後更新                |
| スキーマ管理 | Prisma Migrate + Supabase Migrationに統一             |
| 環境変数   | `.env.local` / Vercel Secret / GitHub Secretで管理一元化 |
| ログ設計   | Supabase Log + Sentry統合でリアルタイム可視化                  |
| コード規約  | ESLint + Prettier + Jest 100%パスを必須化                |

---

## 4.7 セキュリティ監査・法令準拠

| 区分       | 内容                                   |
| -------- | ------------------------------------ |
| 個人情報保護   | 日本の個人情報保護法およびGDPR準拠                  |
| Cookie方針 | 必要最小限のCookie使用。Corbado短期Cookie除外対象外。 |
| セキュリティ監査 | 年1回、外部ペネトレーションテスト実施予定                |
| データ削除    | ユーザー退会時に全関連データを即時削除（7日以内ログ保持）        |
| 開発者権限    | Supabase IAMで個別キー発行・権限最小化            |

---

**Document ID:** HARMONET-REQ-NFR-V1.4
**Version:** 1.4
**Created:** 2025-11-12
**Updated:** 2025-11-12
**Supersedes:** v1.3
**Author:** Tachikoma / TKD
**Reviewer:** TKD
**Status:** ✅ HarmoNet正式版（技術スタックv4.0準拠）
**Directory:** /01_docs/01_requirements/01_機能要件定義/
