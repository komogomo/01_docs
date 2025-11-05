# 第2章 システム概要（v1.2）

## 2.1 開発目的
HarmoNetは、地域社会の中で「安心・つながり・効率」を実現する**デジタル共助プラットフォーム**である。  
紙や掲示板によるアナログ運用をオンライン化し、管理者と住民の情報格差を減らすことを目的とする。  

主な目的は以下の通り。

- **情報伝達の確実化**：お知らせ・回覧板をデジタル化し、多言語で届ける  
- **共用施設の効率利用**：駐車場や集会所をオンラインで予約・可視化  
- **コミュニティ活性化**：掲示板機能を通じて心理的距離を縮める  
- **管理業務の省力化**：既読状況や通報を自動集計し、報告工数を削減  
- **国際化対応**：日本語・英語・中国語の3言語UIを標準提供  

---

## 2.2 利用対象者

| 区分 | 対象 | 特徴 |
|------|------|------|
| 一般住民 | 日本語話者・外国語話者（英語/中国語圏） | スマートフォン中心の利用想定 |
| 管理者 | 管理組合理事・管理会社担当者 | 情報発信・回覧管理・住民登録 |
| システム管理者 | 運用保守担当 | テナント登録・設定管理（Supabase管理画面） |

---

## 2.3 システム全体構成

### 技術スタック（v3.2準拠）

| レイヤー | 技術 | バージョン | 概要 |
|-----------|------|-------------|------|
| フロントエンド | React (PWA) + Tailwind CSS | 18.x / 3.x | ミニマルで自然なUI、Appleカタログ風トーン |
| バックエンド | NestJS (Node.js) + Prisma ORM | 10.x / 5.x | 型安全・マルチテナント対応API層 |
| データベース | Supabase PostgreSQL + RLS | 15.x | Row-Level Securityでテナント分離 |
| キャッシュ | Redis | 7.x | 翻訳キャッシュ・セッション管理 |
| 認証 | Supabase Auth + NextAuth | - | Magic Link + JWT認証統合 |
| 通知 | SendGrid / FCM | - | メールおよびプッシュ通知 |
| 翻訳 | Google Cloud Translation API (Basic v2) | - | JA/EN/CN自動翻訳対応 |
| ホスティング | Vercel + Supabase | - | 開発・運用コスト最適化構成 |
| バージョン管理 | GitHub + Git Flow | - | AI協調開発での安定ブランチ戦略 |

---

### アーキテクチャ概要

```
[Frontend: React PWA]
   ↓ HTTPS (REST / JSON)
[Backend: NestJS + Prisma]
   ↓
[Database: Supabase PostgreSQL (RLS)]
   ↓
[External Services]
   ├─ Supabase Auth (Magic Link, JWT)
   ├─ Google Translation API
   ├─ SendGrid / Amazon SES
   ├─ Firebase Cloud Messaging (Phase 2)
   └─ Cloudflare CDN (optional)
```

---

### マルチテナント構造（RLS適用）

Supabase PostgreSQLの**Row-Level Security (RLS)**を用い、  
テナント（管理組合単位）ごとにデータを論理分離する。  
各クエリにはJWTに埋め込まれた `tenant_id` が自動適用され、  
他テナントへのアクセスを防止する。

#### 主要テーブル例
| テーブル | 用途 |
|-----------|------|
| tenant | テナント基本情報 |
| tenant_user | ユーザーとテナントの関連付け |
| tenant_settings | カスタム設定（JSON構造） |
| tenant_features | 機能フラグ管理（bbs, parking, consumables等） |

#### RLSポリシー例
```sql
CREATE POLICY tenant_isolation_policy
ON public.bbs_posts
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

---

## 2.4 運用前提

| 項目 | 内容 |
|------|------|
| 対応デバイス | スマートフォン（iOS/Android）、タブレット、PC |
| 対応ブラウザ | Chrome / Safari / Edge / Firefox（最新版） |
| 稼働時間 | 24時間365日（メンテナンス時を除く） |
| 稼働率目標 | 99%以上（Vercel SLA基準） |
| バックアップ | Supabase自動バックアップ（1日1回） |
| 障害監視 | Sentry + UptimeRobot（3分間隔） |
| セキュリティ | TLS1.3通信、AES256暗号化、JWT署名検証 |
| スケーラビリティ | SupabaseプランアップまたはAWS移行で拡張可能 |

---

## 2.5 開発方針

HarmoNetの開発は、**AI協調型アジャイル**を採用する。  
すべての設計資料・ソースコード・仕様書をMarkdown形式で統一し、  
AI同士（GPT・Claude・Gemini）の整合性を自動的に保つ。  

開発フェーズは以下の通り。

| フェーズ | 期間 | 主要成果物 |
|-----------|------|-------------|
| Phase 1 | 〜2026年5月 | MVP（お知らせ・掲示板・駐車場予約・マイページ） |
| Phase 2 | +6ヶ月 | 消耗品管理・FCMプッシュ通知・アンケート機能 |
| Phase 3 | +1年 | AI要約・HEMS連携・多拠点化対応 |
| Phase 4 | +2年 | IoT連携・スマート通知・マルチテナント統合管理 |

---

*by GPT (HarmoNet PMO AI)*
