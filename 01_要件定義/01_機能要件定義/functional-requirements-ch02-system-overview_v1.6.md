# 第2章 システム概要

**最終更新:** 2025-11-19

---

# 2.1 開発目的

HarmoNet はマンション・自治会・地域コミュニティを対象とした **クラウド型デジタル共助プラットフォーム**である。多言語化・翻訳・音声化・通知・掲示板・施設予約といった住民サービスを、**すべてスマートフォンで完結**させることを目的とする。

### 主な目的

* **情報伝達の確実化**：お知らせ・掲示板を多言語（JA/EN/ZH）で自動配信
* **コミュニケーション活性化**：掲示板・アンケート・翻訳・音声化
* **管理省力化**：通知・翻訳キャッシュ・ログ自動記録
* **国際化対応**：Google Translation / Google Cloud TTS による 3言語対応
* **クラウド化**：紙からオンライン基盤への移行

---

# 2.2 利用対象者

| 区分      | 説明             | 特徴                     |
| ------- | -------------- | ---------------------- |
| 一般ユーザー  | 住民（日本語・英語・中国語） | MagicLink ログイン、スマホ中心利用 |
| テナント管理者 | 管理組合・管理会社      | 掲示板・お知らせ・施設予約の管理       |
| システム管理者 | TKD / 運用担当     | テナント管理、RLS 監査、障害対応     |

---

# 2.3 システム全体構成（最新版）

HarmoNet は **Next.js 16 + Supabase Cloud + Google API** を中核とする。

## 2.3.1 技術スタック（v1.6）

| レイヤ      | 技術                             | バージョン        | 説明                                   |
| -------- | ------------------------------ | ------------ | ------------------------------------ |
| Frontend | Next.js（App Router） / React 19 | 16.x         | Apple カタログ風 UI（shadcn/ui + Tailwind） |
| Backend  | Supabase Auth / PostgreSQL 17  | Pro Plan     | 認証・DB・ストレージ・RLS                      |
| 認証       | MagicLink（OTP）                 | -            | Passkey は **非採用**                    |
| 翻訳（動的）   | Google Translation API v3      | 最新           | `/api/translate` でラップ                |
| 翻訳（静的）   | StaticI18nProvider             | v1.1         | common.json（JA/EN/ZH）                |
| 音声化      | Google Cloud Text-to-Speech    | 最新           | `/api/tts` でラップ（ja/en/zh）            |
| ストレージ    | Supabase Storage               | -            | PDF / 画像 / 音声キャッシュ                   |
| キャッシュ    | translation_cache / tts_cache  | DB + Storage | Redis 必須ではない（任意）                     |
| 通知       | Supabase Realtime              | -            | 掲示板・お知らせ更新通知                         |
| テスト      | Vitest + RTL                   | 最新           | 単体・結合テスト                             |

❗ **VOICEVOX、Passkey、Redis 必須構成は v1.6 で廃止**。

---

# 2.3.2 アーキテクチャ概要（最新版）

```
[Frontend: Next.js 16 + React 19]
     ↓ Supabase JS SDK / HTTPS
[Backend: Next.js API Routes]
     ├─ /api/translate  → Google Translate
     └─ /api/tts        → Google Cloud TTS
     ↓
[Supabase]
     ├─ Auth (MagicLink)
     ├─ Storage (PDF/Images/TTS Cache)
     ├─ PostgreSQL 17 + RLS
     └─ Realtime
```

---

# 2.3.3 マルチテナント構造（RLS）

Supabase PostgreSQL の RLS により、全データは `tenant_id` を基準に完全隔離される。

### RLS ポリシー例

```sql
CREATE POLICY tenant_isolation
ON board_posts
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

### 主要テーブル（概要）

* `tenants` — テナント管理
* `users` — 一般ユーザ（MagicLink 認証）
* `board_posts / board_comments` — 掲示板
* `facilities / reservations` — 施設予約
* `translation_cache` — 翻訳キャッシュ
* `tts_cache` — 音声キャッシュ

---

# 2.4 運用基盤・前提条件（v1.6）

| 項目     | 内容                                         |
| ------ | ------------------------------------------ |
| 本番基盤   | Vercel（Frontend） + Supabase Cloud（Backend） |
| 稼働率    | Supabase SLA（99.5%）                        |
| 障害監視   | 必須なし（個人開発）。必要時のみ手動確認                       |
| バックアップ | Supabase 自動スナップショット                        |
| デプロイ   | GitHub → Vercel（CI/CD 任意）                  |
| セキュリティ | HTTPS / JWT / RLS                          |
| 対応言語   | 日本語・英語・中国語（簡体）                             |

---

# 2.5 AI 協調型開発体制（最新版）

HarmoNet は「AI 協調」前提で設計されている。

| 区分       | 主担当      | 役割                         |
| -------- | -------- | -------------------------- |
| 要件統合     | タチコマ     | 要件統合・整合チェック（唯一の正：TKD承認前提）  |
| 詳細設計レビュー | Gemini   | 論理整合 / Lint / UT 整合（変更点検証） |
| 実装・テスト   | Windsurf | コード生成 / 自己採点 / UT 実行       |
| 最終承認     | TKD      | 全仕様・設計の最終決定権               |

### 進行プロセス

1. タチコマ：要件統合・仕様整理
2. Gemini：詳細設計の整合確認
3. Windsurf：Next.js + Supabase 実装・テスト
4. TKD：承認して正式反映

---

**End of Document**
