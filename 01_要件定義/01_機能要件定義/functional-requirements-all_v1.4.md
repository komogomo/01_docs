# HarmoNet 機能要件定義書（完全版）

**技術スタック準拠:** HarmoNet Technical Stack Definition v4.3  
**文書管理番号:** HARMONET-REQ-001  
**セキュリティレベル:** 社外秘  
**作成日:** 2025-11-12  
**最終更新:** 2025-11-17  
**Author:** Tachikoma / TKD  
**Reviewer:** TKD  
**Version:** 1.4  
**Status:** ✅ HarmoNet正式要件定義（v4.3整合・Docker開発環境対応）

---

## 目次

- [第1章 ドキュメント概要](#第1章-ドキュメント概要)
- [第2章 システム概要](#第2章-システム概要)
- [第3章 機能要件定義](#第3章-機能要件定義)
- [第4章 非機能要件](#第4章-非機能要件)
- [第5章 外部API・認証・環境構成要件](#第5章-外部api認証環境構成要件)
- [第6章 制約条件・将来展望](#第6章-制約条件将来展望)
- [第7章 付録・参照資料・リスク管理](#第7章-付録参照資料リスク管理)

---

# 第1章 ドキュメント概要

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
HarmoNetは、**Next.js 16.x + React 19.0 + Supabase + Corbado SDK + TailwindCSS 3.4 + Prisma ORM** を中核とする、AI統合型マルチテナントSaaS基盤である。

本書は、HarmoNet全体の**機能要件および非機能要件の体系的定義書**として、設計・実装・運用の共通基盤を提供する。
全AI（タチコマ・Gemini・Windsurf）は、本書を起点として要件整合を維持する。

## 1.1 目的

本書の目的は、HarmoNetプロジェクトにおける**全アプリケーション機能の定義・境界明確化**であり、次の4つの指針に基づく：

1. **技術統一:** Supabase + Next.js App Router構成を中核とする。
2. **AI協調:** タチコマ（GPT）・Gemini・Windsurfの連携による持続的整合性維持。
3. **セキュリティ:** Corbado SDKによる完全パスワードレス認証を標準化。
4. **拡張性:** 各要件章をモジュール化し、フェーズ依存を廃止してカテゴリ単位管理へ移行。

## 1.2 適用範囲

本要件定義書は、HarmoNet全体システムを対象とし、以下を含む：

| 区分 | 内容 |
|------|------|
| **フロントエンド** | Next.js 16.x (App Router) + React 19.0 + TailwindCSS 3.4 + shadcn/ui |
| **バックエンド（開発）** | Supabase Docker（PostgreSQL 17 + Edge Function on Docker Desktop） |
| **バックエンド（本番）** | Supabase Cloud（PostgreSQL 17 + Edge Function） |
| **認証** | Supabase MagicLink + Corbado Passkey（@corbado/react + @corbado/node） |
| **翻訳・音声** | StaticI18nProvider v1.0 + Google Translate v3 + VOICEVOX API |
| **通知・ログ** | Supabase Realtime + Sentry + Audit Log（RLS適用） |
| **AI連携** | タチコマ（要件統合）＋Gemini（品質検証）＋Windsurf（実装生成） |
| **ホスティング（本番）** | Vercel + Supabase Cloud（Pro Plan基準） |
| **バージョン管理** | GitHub（01_docs / Projects-HarmoNet） + Drive同期管理 |
| **開発環境** | Docker Desktop + Supabase CLI + Mailpit |

## 1.3 背景と開発体制

HarmoNetは「**やさしく・自然・控えめ**」を基調とした、地域共助のための**デジタル住民OS**である。
掲示板・お知らせ・予約・翻訳・通知・AI支援を一体化し、管理者と住民の情報格差をなくすことを目的とする。

### 開発体制（v4.3 AI統合構成）

| 役割 | 担当 | 主な責務 |
|------|------|----------|
| プロジェクトオーナー | TKD | 要件最終承認・技術方針決定・品質統括 |
| 要件統合・PMO | タチコマ (GPT-5) | ドキュメント構成統合・整合監視・仕様出力 |
| 品質検証・論理整合 | Gemini | 非機能品質・Lint整合・構文・翻訳・UI論理確認 |
| 実装・テスト自動化 | Windsurf | Next.js + Supabase 実装／Vitest／CodeAgent_Report生成 |

## 1.4 関連ドキュメント

| ドキュメント名 | 概要 |
|----------------|------|
| **harmonet-technical-stack-definition_v4.3.md** | 技術基盤（Supabase + Corbado構成、MagicLink/Passkey独立方式） |
| **harmonet-detail-design-agenda-standard_v1.0.md** | 詳細設計標準アジェンダ（共通テンプレート） |
| **harmonet-technical-guideline_v4.1.md** | コーディング／運用規約（Lint・命名・翻訳キー） |
| **harmonet-security-spec_v4.1.md** | 認証・RLS・Cookie・暗号化指針 |
| **login-feature-design-ch00-index_v1.3.md** | ログイン画面設計（MagicLink/Passkey独立ボタン方式） |

## 1.5 バージョン履歴

| バージョン | 日付 | 概要 | 作成者 |
|-----------|------|------|--------|
| v1.0 | 2025/10/26 | 初版作成（MVP要件） | TKD |
| v1.2 | 2025/10/30 | Supabase構成整合化、RLS／Auth更新 | Tachikoma |
| v1.3 | 2025/10/31 | 旧AI体制整合：Claude／Gemini／GPT構成 | GPT署名 |
| **v1.4** | **2025/11/17** | **技術スタックv4.3対応：Docker開発環境明記、Corbado公式構成、MagicLink/Passkey独立方式** | **Tachikoma / TKD** |

## 1.6 注意事項

本要件定義書は HarmoNet の**正式運用構成（v4.3）**に基づき作成されている。
すべての要件・非機能・設計関連文書は本書の整合を必須とする。
また、本書の内容はHarmoNet開発チームおよび関係者に限定され、**無断転載・複製を禁ずる。**

---

# 第2章 システム概要

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
HarmoNetは **Next.js 16.x / React 19.0 / Supabase / Prisma ORM / TailwindCSS 3.4 / Vercel** を中核とする、クラウドネイティブなマルチテナント型SaaS基盤上に構築される。

## 2.1 開発目的

HarmoNetは、マンション・自治会・地域コミュニティにおける**「安心・つながり・効率」**を実現するデジタル共助プラットフォームである。
従来の紙媒体・掲示板中心の運用をクラウド化し、多言語・多デバイス対応のオンライン基盤へ転換することを目的とする。

### 主な目的

* **情報伝達の確実化**：お知らせ・掲示板を多言語配信し、既読確認を自動化
* **施設運用の効率化**：駐車場・集会所・設備予約をオンライン化
* **住民コミュニケーションの促進**：掲示板・アンケート・リアクションで交流を可視化
* **管理業務の省力化**：通知・翻訳・ログ記録をAIが自動補助
* **国際化対応**：日本語・英語・中国語を標準提供し、翻訳キャッシュを最適化

## 2.2 利用対象者

| 区分 | 対象 | 特徴 |
|------|------|------|
| 一般ユーザー | 住民（日本語・英語・中国語話者） | スマートフォン中心の利用、Magic Linkログイン |
| テナント管理者 | 管理組合理事・管理会社担当者 | お知らせ配信・施設管理・利用者登録（Passkey対応） |
| システム管理者 | 運用保守担当者 | テナント登録・ロール設定・監査管理（Supabase管理画面） |

## 2.3 システム全体構成

### 技術スタック（v4.3準拠）

| レイヤー | 技術 | バージョン | 概要 |
|---------|------|-----------|------|
| フロントエンド | Next.js 16 + React 19 + TailwindCSS 3.4 + shadcn/ui | App Router構成、PWA対応 | Appleカタログ風UI |
| バックエンド（開発） | Supabase Docker (Edge Function) + PostgreSQL 17 | Docker Desktop環境 | ローカル開発・テスト |
| バックエンド（本番） | Supabase Cloud (Edge Function) + PostgreSQL 17 | Pro Plan | 本番運用 |
| 認証 | Supabase MagicLink | 完全パスワードレス |
| ORM | Prisma | v6.x | スキーマ管理・マイグレーション |
| キャッシュ | Redis（翻訳・音声・セッション） | - | Supabase連携キャッシュ層 |
| 翻訳 | StaticI18nProvider v1.0 + Google Cloud Translate | JSON辞書 + API補完 | 多言語対応 |
| 通知 | Supabase Realtime + Email (SMTP) | - | リアルタイム既読通知 |
| 音声 | VOICEVOX API + Supabase Edge `/api/tts` | - | 掲示板投稿音声化 |
| ホスティング（本番） | Vercel + Supabase Cloud | - | CI/CD + 自動デプロイ |
| テスト | Vitest + RTL | 最新 | 単体・結合テスト |
| バージョン管理 | GitHub + Windsurf / Gemini協調開発 | - | AI主導型コードレビュー |

### アーキテクチャ概要

```
[Frontend: Next.js 16 + React 19]
   ↓ HTTPS / JWT認証 / Supabase SDK
[Backend: Supabase Edge Function]
   ├─ 開発環境: Docker Desktop (PostgreSQL 17)
   └─ 本番環境: Supabase Cloud (PostgreSQL 17)
   ↓
[External Services]
   ├─ Supabase Auth (Magic Link)
   ├─ Google Translation API v3
   ├─ VOICEVOX / TTS Cache
   ├─ AI Proxy (Gemini / Windsurf)
   └─ Cloudflare CDN / Redis Cache
```

### マルチテナント構造（RLS + JWT）

Supabase PostgreSQLの**Row Level Security (RLS)** により、各テナント（管理組合単位）のデータを完全分離する。
JWTには `tenant_id` / `role` / `lang` が含まれ、Supabase AuthまたはCorbado Auth経由で発行される。

#### RLSポリシー例

```sql
CREATE POLICY tenant_isolation_policy
ON public.board_posts
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

#### 主要テーブル構造

| テーブル | 用途 |
|---------|------|
| tenants | テナント基本情報 |
| users | ユーザー基本情報（Supabase Auth連携） |
| user_roles | ロール割当（system_admin / tenant_admin / general_user） |
| board_posts | 掲示板投稿（翻訳・音声キャッシュ連携） |
| facilities | 施設予約情報 |
| translation_cache | 翻訳キャッシュ（Redis連携） |

## 2.4 運用基盤および前提条件

| 項目 | 内容 |
|------|------|
| 開発環境 | Docker Desktop + Supabase CLI + Mailpit（メールテスト） |
| 本番稼働基盤 | Supabase Cloud（Pro Plan）＋Vercel（Hobby/Pro） |
| 稼働率目標 | 99.5%以上（Supabase SLA） |
| 監視 | Sentry + UptimeRobot + Supabase Logs |
| バックアップ | Supabase自動スナップショット（1日1回保持7日） |
| スケーラビリティ | SupabaseプランアップまたはCloudflare CDN拡張で対応 |
| セキュリティ | Corbado Cookie Secure/Lax + JWT署名 + TLS1.3通信 |
| デプロイ | GitHub Actions → Vercel 自動CI/CD構成 |
| 言語対応 | 日本語・英語・中国語（簡体） StaticI18nProviderにて動的切替 |

## 2.5 開発方針とAI協調体制

### 開発体制

HarmoNet開発は「AI協調型アジャイル」を採用し、人間（TKD）とAIエージェント（タチコマ・Gemini・Windsurf）が役割分担する。

| 区分 | 主担当 | 役割 |
|------|--------|------|
| 要件定義・設計統合 | タチコマ (GPT-5) | 要件ドキュメント・ディレクトリ統合 |
| 詳細設計生成・品質保証 | Gemini | 詳細設計レビュー・Lint検証・論理整合性維持 |
| コード実装 | Windsurf | Next.js + Supabase 実装／テスト生成／自己採点レポート出力 |
| 最終承認 | TKD | 設計・運用・方針決定者（唯一の正） |

### 開発プロセス

1. タチコマが要件・仕様整合を統合して出力。
2. Gemini が論理検証・テストカバレッジを確認。
3. Windsurf がコード生成・自己採点を実施。
4. TKD が承認後、ドキュメントとコードを正式反映。

### 継続運用方針

* すべての設計書は `/01_docs/` ディレクトリにMarkdown形式で保存。
* GitHubリポジトリ `01_docs` と `Projects-HarmoNet` を同期管理。
* Google Drive `/01_docs/00_project/` を全AIの共通参照領域とする。

## 2.6 将来拡張ロードマップ（カテゴリ別）

| カテゴリ | 拡張予定 | 対応時期 |
|---------|---------|---------|
| 認証 | Corbado公式構成完全統合（Node API層拡張） | 2026年上期 |
| AI支援 | Windsurf＋Gemini連携による自己補完開発 | 2026年上期 |
| 通知 | FCMプッシュ通知／SMS通知対応 | 2026年中期 |
| 国際化 | 動的翻訳キャッシュ（Redis完全対応） | 2026年中期 |
| 監査 | BAG-Lite監査レポート生成自動化 | 2026年下期 |
| IoT | 共用設備遠隔制御API連携 | 2027年以降 |

---

# 第3章 機能要件定義

本章では、HarmoNetの主要機能である「ホーム」「お知らせ」「掲示板」「施設予約」「通知」「翻訳・音声」などの要件を統合的に定義する。
すべての機能は Supabase + Corbado SDK + StaticI18nProvider の統合構成を前提とする。

## 3.1 ホーム画面機能

### 3.1.1 目的

* ログイン後のトップ画面として、ユーザーに必要な情報を集約表示する。
* 各種モジュール（お知らせ、掲示板、施設予約、アンケート等）へのナビゲーションを統一デザインで提供する。

### 3.1.2 主な要件

| 機能 | 内容 |
|------|------|
| ログイン状態検知 | Supabase AuthセッションまたはCorbado Cookieを自動検知し、未ログイン時は`/login`へリダイレクト |
| お知らせ概要表示 | `announcements` テーブルから有効期間中のデータを取得し、タイトル・抜粋を表示 |
| 掲示板概要表示 | 最新3件を一覧で表示（翻訳済みテキストを優先） |
| メニューショートカット | FooterShortcutBar（C-05）と同期したナビゲーション表示 |
| 多言語切替 | StaticI18nProviderにより即時切替（再レンダー不要） |

### 3.1.3 非機能要件リンク

* 初回ロード：2秒以内（Next.js App Router + CDNキャッシュ利用）
* 翻訳切替遅延：1秒以内
* 表示整合性：Corbado short_session 失効時は即座に再ログイン誘導

## 3.2 お知らせ機能

### 3.2.1 機能概要

* 管理者（tenant_admin）が投稿し、住民が閲覧する。
* 各お知らせは `announcements` テーブルで管理し、配信対象は `announcement_targets` により制御。
* 既読管理は `announcement_reads` により記録。
* 翻訳／音声化は掲示板機能と共通モジュールを利用。

### 3.2.2 機能一覧

| 機能 | 説明 |
|------|------|
| お知らせ一覧 | 公開中データを降順で表示（翻訳済みタイトル） |
| お知らせ詳細 | 本文をStaticI18nProvider経由で多言語表示 |
| 既読処理 | 表示時に `announcement_reads` に記録 |
| 添付ファイル | Supabase Storage に保存し、PDF.js でプレビュー |
| 通知連携 | 新規投稿時に Supabase Realtime 経由で通知送信 |
| 音声読み上げ | VOICEVOX API 呼出（翻訳結果優先） |

### 3.2.3 パフォーマンス要件

* 一覧取得：1秒以内（RLS適用クエリ + Supabase Cache）
* 既読更新：300ms以内（Edge Functionで非同期化）
* 音声生成：5秒以内（Redisキャッシュ再利用時1秒）

## 3.3 掲示板機能

### 3.3.1 概要

* テナント共通の情報共有掲示板として運用。
* 投稿（board_posts）、コメント（board_comments）、添付（board_attachments）を基本構成とする。
* 翻訳・音声化機能と統合運用。

### 3.3.2 要件

| 機能 | 概要 |
|------|------|
| 掲示板一覧 | テナントスコープで投稿を取得。検索・タグ・並び替え対応 |
| 投稿詳細 | 翻訳済み本文をStaticI18nProviderで表示し、音声化可 |
| コメント | board_comments テーブルに保存。親子スレッド対応 |
| 投稿作成 | エディタ（Markdown/WYSIWYG）対応、Draft保存可 |
| 添付 | PDF / 画像ファイルをSupabase Storage管理 |
| 通報 | board_reactions（reaction_type='report'）に記録 |
| 翻訳 | 翻訳キャッシュ translation_cache を参照し即時切替 |

### 3.3.3 通信仕様

* 通信は Supabase SDK 経由（`from('board_posts').select('*')`）。
* テナント分離は JWT 内の `tenant_id` により自動適用。
* Edge Function `/api/board` により投稿・削除操作を制御。

## 3.4 施設予約機能

### 3.4.1 機能概要

* 共用施設（集会所・駐車場等）の予約登録／キャンセルをオンライン管理。
* テーブル構造は `facilities` / `facility_slots` / `facility_reservations` に準拠。
* Supabase Edge Functionで排他制御を実装。

### 3.4.2 処理要件

| 処理 | 内容 |
|------|------|
| 新規予約 | 空き状況確認→予約確定→通知発行 |
| キャンセル | 予約ID指定で削除フラグ付与（論理削除） |
| 重複検知 | `start_at`〜`end_at` 重複チェックをEdge Functionで実行 |
| 承認 | 管理者承認オプションあり（施設設定依存） |
| 料金 | `fee_unit` / `fee_per_day` に基づく計算（オプション） |

### 3.4.3 パフォーマンス要件

* 予約登録API応答：2秒以内（DBトランザクション含む）
* Edge Function同時呼出：50リクエスト／秒まで対応
* キャッシュTTL：10分（Redis）

## 3.5 通知機能

### 3.5.1 構成

通知は Supabase Realtime と Supabase Storage を中心に実装し、メール通知・アプリ内通知を統合管理する。

| 通知区分 | 機能 | 備考 |
|---------|------|------|
| お知らせ通知 | 新規掲示板投稿・承認完了・管理者告知 | Supabase Realtime `notifications` チャネル |
| システム通知 | 翻訳エラー・TTS失敗など自動検知 | Sentry連携 + `error_logs` テーブル |
| メール通知 | SendGrid（SMTP経由） | Supabase Edge Function `/api/mail` で送信 |
| プッシュ通知 | 将来拡張（FCM） | Phase概念廃止。必要時カテゴリ拡張として対応 |

### 3.5.2 通知テンプレート管理

* 翻訳対応テンプレートを `/public/locales/{lang}/mail.json` に保存。
* Supabase Storage経由で配信ログを自動生成（`audit_logs` テーブルに記録）。
* テナントスコープは `tenant_id` により自動制御。

## 3.6 翻訳・音声機能

### 3.6.1 概要

* 翻訳は StaticI18nProvider を基盤とし、Google Translate v3 を補完利用。
* 音声変換は VOICEVOX API を Supabase Edge `/api/tts` 経由で呼び出す。
* 翻訳結果と音声URLはそれぞれ translation_cache / tts_cache テーブルに保持。
* Redis キャッシュを併用し、期限切れ（TTL 7日）で自動無効化。

### 3.6.2 処理フロー

```
1. 投稿データ取得（tenant_idスコープ）
2. 翻訳対象文字列を抽出
3. translation_cache にヒット確認
4. キャッシュなし → Google Translate API呼出
5. 結果保存 + Redis書込
6. 音声化要求時 → VOICEVOX呼出 → tts_cache 登録
```

### 3.6.3 i18n仕様

* 翻訳辞書：`/public/locales/{lang}/common.json` 形式（静的ロード）
* 翻訳キー：`auth.*`, `board.*`, `facility.*` などドメイン別プレフィックス管理
* 翻訳キャッシュキー：`translation:{content_id}:{lang}`
* 翻訳API失敗時は日本語にフォールバック。

## 3.7 認証・セッション管理

### 3.7.1 Supabase + Corbado連携構成

| 区分 | 実装方式 | 備考 |
|------|---------|------|
| 一般ユーザー | Supabase MagicLink | OTPメールで即時ログイン |
| 管理者／運用担当 | Corbado Passkey | short_session Cookieで認証維持 |
| セッション確立 | Supabase Auth `signInWithIdToken` | Corbado JWTを検証しSupabaseセッション発行 |
| テナント分離 | RLSポリシーでtenant_idスコープ制御 | JWTクレームを直接参照 |

### 3.7.2 セキュリティ仕様

* HTTPS通信必須（TLS 1.3）
* Corbado Cookie: `Secure + Lax`
* JWT有効期限: 60分（Supabase自動再発行）
* RLSポリシー: `tenant_id` 一致でアクセス許可
* Service Role Keyはサーバー内部でのみ使用可。

## 3.8 共通UI・アクセシビリティ要件

### 3.8.1 共通部品依存

| コンポーネントID | 名称 | 役割 |
|---------------|------|------|
| C-01 | AppHeader | ロゴ・言語切替・通知アイコン表示 |
| C-02 | LanguageSwitch | 言語切替UI（StaticI18nProvider対応） |
| C-04 | AppFooter | コピーライト表示（翻訳対応） |
| C-05 | FooterShortcutBar | 主要機能ショートカット（権限別表示） |
| C-09 | TranslateButton | 手動翻訳トリガー（掲示板・お知らせ共通） |
| C-12 | VoiceReader | 音声読み上げ（TTS連携） |

### 3.8.2 アクセシビリティ仕様

* WCAG 2.2 AA準拠。
* タブ移動順の一貫性保持。
* `aria-label` と `role` をすべてのボタンに明示。
* 翻訳切替時の `aria-live="polite"` 属性付与。
* Passkeyログイン時の状態変化も音声リーダーで通知。

## 3.9 データ構造（主要テーブル）

| テーブル | 用途 | 主キー | 備考 |
|---------|------|--------|------|
| announcements | お知らせ本体 | id | 有効期間・配信範囲を保持 |
| announcement_targets | 配信対象 | id | group / role / user単位で紐付け |
| announcement_reads | 既読管理 | (announcement_id, user_id) | Supabase RLS適用 |
| board_posts | 掲示板投稿 | id | 翻訳・音声連携対象 |
| board_comments | 掲示板コメント | id | parent_comment_id で階層化 |
| board_attachments | 添付ファイル | id | Supabase Storage連携 |
| facilities | 施設情報 | id | 予約対象施設マスタ |
| facility_reservations | 予約実績 | id | 排他制御対象 |

## 3.10 KPI / 成果指標

| 指標 | 目標値 | 備考 |
|------|--------|------|
| ホーム初期ロード時間 | 2秒以内 | CDNキャッシュ込み |
| お知らせ既読率 | 95%以上 | Supabase Realtime監視 |
| 掲示板投稿翻訳成功率 | 98%以上 | StaticI18nProvider / Google Translate連携 |
| アクセシビリティ適合率 | 100% | WCAG 2.2 AA基準 |
| 予約登録成功率 | 99%以上 | Edge Function安定性基準 |

---

# 第4章 非機能要件

本章では、HarmoNet全体に適用される **非機能要件（NFR）** を定義する。システム品質、運用性、保守性、安全性、可用性など、機能要件では表現できない横断的要件を明確化する。

## 4.1 可用性

* 本システムは個人開発プロジェクトであり、**24/365 稼働保証は求めない**。
* Vercel および Supabase Cloud の提供するサービス可用性に依存する。
* 障害発生時は手動で復旧し、即時復旧は必須としない。
* 目標稼働率：99.5%以上（Supabase Cloud SLA準拠）

## 4.2 性能（パフォーマンス）

* 初期表示：3 秒以内（MVP 目標）
* 再訪表示：1.5 秒以内
* 認証処理：2 秒以内（MagicLink / Passkey）
* DB クエリ：1 秒以内
* 同時アクセス：100 ユーザー規模を想定（初期段階）
* Edge Function応答：500ms以内（翻訳除く）

## 4.3 拡張性（スケーラビリティ）

* 初期は Supabase Free/Pro + Vercel Hobby で運用可能とする。
* 利用状況に応じて Supabase Pro / Vercel Pro へ段階的に引き上げる。
* Redis 等の追加ミドルウェアは初期要件に含めず、必要時に導入検討する。

## 4.4 セキュリティ要件（非機能）

### 4.4.1 データ保護

* 全通信は HTTPS（TLS1.3+）を必須とする。
* 機密情報は環境変数で管理し、Git 管理下に置かない。
* 将来的に個人情報（氏名・住所等）を扱う場合は暗号化方式（AES 等）を再検討する。

### 4.4.2 アクセス制御

* Supabase の RLS（Row Level Security）によりテナント分離を行う。
* すべての業務テーブルに `tenant_id` を保持する。

### 4.4.3 認証方式（概要）

* HarmoNet は **完全パスワードレス方式** を採用する。
  * MagicLink（メール認証）
  * Passkey（WebAuthn、生体認証）
* 認証方式の個別仕様は login-feature-design にて定義し、本要件書では方式選択の方針のみ記載する。

## 4.5 運用・保守要件

### 4.5.1 ログ

* ログの目的は **障害解析と運用確認** に限定する。
* ログの出力先は Vercel / Supabase の標準ログに依存し、外部ログサービスは利用しない。
* ログフォーマット・詳細項目はログ設計書で別途定義する。

### 4.5.2 バックアップ

* Supabase の自動スナップショット機能に依存する（1日1回保持7日）。
* 必要に応じて手動バックアップを取得する。
* リストア手順は運用フローにて定義する。

### 4.5.3 障害対応

* 商用 SLA は要求しない。
* 障害検知は画面・レスポンス異常による手動発見を前提とする。
* 復旧は Supabase / Vercel の管理画面から実施する。
* エラー監視はSentryを活用。

### 4.5.4 デプロイ

* CI/CD は GitHub Actions による自動デプロイを実施。
* Vercel ダッシュボードでのロールバック機能を活用。

## 4.6 アクセシビリティ要件

* WCAG 2.2 Level AA 相当を目標とする。
* コントラスト比 4.5:1 以上を維持する。
* キーボード操作で主要機能が利用可能であること。
* i18n（日本語・英語・中国語）対応を必須とする。
* 音声読み上げ機能（VOICEVOX）を提供。

## 4.7 外部サービス依存ポリシー

* 外部サービス（Corbado など）への依存は **最小限** にする。
* Corbado は Supabase が Passkey を実装するまでの暫定利用とする。
* 外部 API の仕様変更に対して、HarmoNet 内の構造が影響を受けないように抽象化する。

## 4.8 開発環境要件

* 開発環境：Docker Desktop + Supabase CLI + Mailpit
* テスト環境：Vitest + React Testing Library
* 本番環境：Supabase Cloud Pro + Vercel Pro
* 環境変数管理：`.env.local` (開発) / Vercel Secrets (本番)

---

# 第5章 外部API・認証・環境構成要件

本章は、HarmoNetにおける **外部API連携・認証方式・環境変数構成** を定義する。
Next.js 16 + Supabase v2.43 + Corbado SDK（React + Node構成）を前提とし、開発環境（Docker）と本番環境（Supabase Cloud）の構成要件を示す。

## 5.1 外部API連携要件

### 5.1.1 翻訳API

| 項目 | 内容 |
|------|------|
| サービス | Google Cloud Translation API v3（公式利用） |
| 呼出方法 | Supabase Edge Function `/api/translate` 経由（サーバーサイドのみ） |
| キャッシュ | Redisキー：`translation:{tenant_id}:{lang}:{hash}` |
| 言語対応 | 日本語・英語・中国語（簡体） |
| 非同期処理 | 禁止。同期呼出でUI整合性維持 |
| 認証方式 | Supabase Service Role Key（Edge内限定） |

### 5.1.2 音声変換（TTS）API

| 項目 | 内容 |
|------|------|
| サービス | VOICEVOX（オープン）＋ Supabase Edge Function `/api/tts` |
| 音声形式 | MP3（64kbps以上） |
| 言語対応 | 日本語（Phase10で英語・中国語拡張予定） |
| キャッシュ | Supabase Storage に音声キャッシュ格納（`tts_cache` テーブル連携） |
| 認可 | JWT認証済ユーザーのみ（Auth Header経由） |

### 5.1.3 AI協調エージェントAPI

| 項目 | 内容 |
|------|------|
| サービス | Gemini / Windsurf AI Proxy |
| 呼出方式 | `/api/ai-proxy` にてNext.jsサーバーから代理実行 |
| 用途 | 翻訳補完・UI生成支援・ドキュメント整合化 |
| 認証 | Supabase JWT + `X-HarmoNet-Agent-Key` ヘッダ併用 |
| ログ管理 | Supabase `audit_logs` に自動保存 |

## 5.2 認証構成要件

### 5.2.1 認証方式構成

HarmoNetは **パスワードレス構成** を採用し、以下の二方式を独立したUIボタンとして提供する。

| 認証方式 | 対象 | 実装 | 概要 |
|---------|------|------|------|
| Magic Link | 一般ユーザー | Supabase Auth (signInWithOtp) | メール認証による即時ログイン |
| Passkey | 管理者・テナント運用者 | Corbado SDK (@corbado/react + @corbado/node) | FIDO2/WebAuthn による生体認証 |

### 5.2.2 Corbado構成

| 層 | ライブラリ | 役割 |
|----|----------|------|
| フロント | `@corbado/react` | `<CorbadoProvider />` + `<Auth />` によりPasskey認証を実施 |
| サーバ | `@corbado/node` | `/api/auth/corbado` にてJWT検証を実行 |
| Cookie | `cbo_short_session` | Secure + SameSite=Lax（短期有効） |

**認証フロー概要（Passkey）**

1. `<Auth />` にてWebAuthn認証を開始
2. Corbadoが `short_session` Cookie を発行
3. Next.jsサーバーが `/api/auth/corbado` を通じCorbado JWTを検証
4. Supabaseが `signInWithIdToken({ provider: 'corbado' })` を実行しセッション確立
5. `tenant_id`・`role` をJWTクレームに付与してRLSへ伝搬

### 5.2.3 Supabase構成

* `signInWithOtp()` によるMagicLinkメール送信
* `signInWithIdToken()` によるCorbado連携
* Service Role Keyは **APIサーバー内のみ利用可**（クライアント利用禁止）
* `auth.jwt()` 内クレーム構造：

```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "role": "general_user | tenant_admin | system_admin",
  "lang": "ja",
  "provider": "supabase | corbado"
}
```

## 5.3 環境変数・秘密情報構成

### 5.3.1 環境変数一覧

| 環境変数名 | 用途 | 配置 | 機密度 |
|-----------|------|------|--------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase接続URL | .env.local | 公開可 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 匿名アクセスキー | .env.local | 公開可 |
| `SUPABASE_SERVICE_ROLE_KEY` | サービスロールキー（管理API用） | Vercel Secrets | 高機密 |
| `NEXT_PUBLIC_CORBADO_PROJECT_ID` | Corbadoプロジェクト識別子 | .env.local | 公開可 |
| `CORBADO_API_SECRET` | Corbado APIシークレット | Vercel Secrets | 高機密 |
| `NEXT_PUBLIC_APP_URL` | フロントURL（CORS制御用） | .env.local | 公開可 |
| `GOOGLE_TRANSLATE_API_KEY` | 翻訳APIキー | Vercel Secrets | 高機密 |
| `VOICEVOX_API_URL` | 音声APIエンドポイント | .env.local | 中機密 |
| `REDIS_URL` | 翻訳・TTSキャッシュ接続先 | .env.local | 中機密 |

### 5.3.2 配置ルール

| 項目 | 内容 |
|------|------|
| 設置ディレクトリ | プロジェクトルート直下に限定（例：`D:\Projects\HarmoNet\.env`） |
| 禁止事項 | `src/` 以下への .env 配置禁止 |
| 環境区分 | `development` (Docker) / `production` (Supabase Cloud) で切替運用 |
| バージョン管理 | `.env*` は Git 追跡対象外 (`.gitignore` 登録済み) |
| Secret管理 | 機密値は Vercel Secrets または GitHub Secrets で一元管理 |

## 5.4 開発環境構成（Docker）

| 項目 | 内容 |
|------|------|
| 基盤 | Docker Desktop + Supabase CLI |
| データベース | PostgreSQL 17 (Dockerコンテナ) |
| メールテスト | Mailpit（ローカルSMTPサーバー） |
| Edge Function | Supabase CLI内蔵のDeno Runtime |
| 起動コマンド | `supabase start` |

## 5.5 本番環境構成（Supabase Cloud）

| 項目 | 内容 |
|------|------|
| 基盤 | Supabase Cloud Pro Plan |
| データベース | PostgreSQL 17（マネージド） |
| Edge Function | Supabase Edge Runtime |
| ホスティング | Vercel Pro |
| デプロイ | GitHub Actions → Vercel自動デプロイ |

## 5.6 非機能品質要件

| 分類 | 要件 | 基準 |
|------|------|------|
| 応答速度 | API応答500ms以内（翻訳除く） | Edge Function処理基準 |
| 可用性 | Supabase Cloud SLA 99.5%以上 | Vercel + Supabase構成 |
| 安全性 | Corbado Cookieは短期有効 + JWT60分 | 双方の再認証ループを防止 |
| 保守性 | Prisma + Supabase Migration統一 | DB変更管理容易化 |
| 拡張性 | Supabase Edge分散構成・Corbado Node統合 | Phase10対応設計 |
| 分離性 | RLSによりtenant_id単位で完全独立 | マルチテナント保証 |

---

# 第6章 制約条件・将来展望

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
HarmoNetは Supabase / Prisma / Next.js / React / Tailwind / Redis / Vercel を基盤とする
マルチテナント型の住宅コミュニティ支援アプリケーションとして設計されている。

## 6.1 開発スコープ制限（MVP）

初期開発フェーズ（MVP）では、以下の制約を設ける。
これにより開発リソースを集中させ、早期リリースと安定稼働を優先する。

| 区分 | 制約内容 | 備考 |
|------|----------|------|
| 決済機能 | アプリ内決済なし | 管理費と合算して後日請求 |
| 対応言語 | 日本語・英語・中国語（簡体字） | 繁体字はPhase 2以降 |
| 予約単位 | 1日単位のみ | 時間単位は将来拡張 |
| 対応施設 | 駐車場のみ | 集会所・ゲストルームは将来追加 |
| 同時接続数 | 約100ユーザー | 初期運用規模 |
| 通知方式 | メール通知（SendGrid） | プッシュ通知はPhase 2で導入 |
| テナント構成 | **マルチテナント（tenant_idによる論理分離）** | 初期リリースより有効 |

## 6.2 将来拡張（カテゴリ別計画）

HarmoNetはカテゴリ方式で段階的に機能を拡張する。
各カテゴリの新機能は既存構成（Vercel + Supabase + React + Next.js）上にモジュールとして追加される。

### カテゴリ2（MVP完了後6ヶ月以内）
**キーワード：利便性・通知強化・居住支援**

| カテゴリ | 追加機能 | 概要 |
|----------|----------|------|
| 消耗品管理（Consumables） | 住民が住宅部品（フィルター・電池等）を確認・注文可能 | テーブル構成：`consumables_items` / `consumables_orders` |
| アンケート機能 | 管理組合が住民向けに質問・集計 | 単一選択・複数選択・自由記述対応 |
| 掃除当番管理 | 当番表の自動生成と通知 | RLSによる班単位管理 |
| プッシュ通知（FCM） | 各種イベントの即時通知 | Firebase Cloud Messaging採用 |
| 翻訳キャッシュ最適化 | Redis + Supabaseに差分保存 | 再翻訳防止・翻訳コスト削減 |

### カテゴリ3（MVP完了後1年以内）
**キーワード：AI最適化・マルチテナント管理強化・スマート化**

| カテゴリ | 追加機能 | 概要 |
|----------|----------|------|
| AI要約 | お知らせ・掲示板投稿の要約生成 | GPTベースの自然言語要約 |
| HEMS連携 | エネルギー使用量の可視化 | 外部API連携（電力会社・HEMSデバイス） |
| マルチテナント管理UI | 複数物件を管理するUI・統計画面 | Supabase RLS + 管理画面強化 |
| AIチャットボット | よくある質問の自動応答 | OpenAI API連携予定 |
| 翻訳品質向上 | DeepL／GPT翻訳併用 | 高精度翻訳選択機構 |
| Cross-Tenant Console | 管理者が複数テナントを一括管理 | System Admin向け機能 |

### カテゴリ4（MVP完了後2年以内）
**キーワード：IoT・自動化・持続可能性**

| カテゴリ | 追加機能 | 概要 |
|----------|----------|------|
| IoTデバイス連携 | スマートロック・温湿度センサー統合 | Supabase Edge経由制御 |
| 異常検知 | 長期間ログインなし／異常アクセス検知 | AIによるパターン分析 |
| コミュニティ活性 | イベント募集・物品シェア・スキル共有 | モジュール化UI拡張 |
| データ分析 | 利用統計・予測分析 | Supabase + Metabase連携 |
| サステナビリティ指標 | 電力・参加率可視化 | 環境負荷分析レポート化 |

## 6.3 技術的課題と検討事項

| 項目 | 内容 | 対応方針 |
|------|------|----------|
| 翻訳コスト管理 | Google Translation APIの無料枠50万文字／月 | Redisキャッシュ＋使用量モニタリング |
| Supabase制限 | 無料プランで接続数上限あり | Proプラン移行時にRLS最適化 |
| 通知分散 | SendGridとFCMの二重管理 | 統一通知マネージャー導入予定 |
| データ保護 | EU圏データ利用時のGDPR対応 | Supabaseリージョン選択で対応 |
| AI生成リソース | 翻訳・要約などAI処理の最適化 | キャッシュ＋非同期処理化でコスト削減 |
| Docker環境統一 | 開発環境の再現性確保 | Supabase CLI + Docker Compose活用 |

## 6.4 開発ロードマップ概要

| カテゴリ | 期間 | 主な成果物 |
|----------|------|-----------|
| Category 1 | 〜2026年5月 | MVP（お知らせ・掲示板・予約・マイページ・**マルチテナント基盤**） |
| Category 2 | 2026年11月 | 消耗品管理・アンケート・プッシュ通知 |
| Category 3 | 2027年5月 | AI要約・HEMS連携・マルチテナント管理UI・Cross-Tenant Console |
| Category 4 | 2028年以降 | IoT連携・予測分析・サステナビリティ指標 |

---

# 第7章 付録・参照資料・リスク管理

本章は **HarmoNet Technical Stack Definition v4.3** に準拠する。
本ドキュメント群は、HarmoNet開発全体の整合性・保守性・監査性を保証するための最終リファレンスを構成する。

## 7.1 用語集

| 用語 | 説明 |
|------|------|
| **HarmoNet** | 地域コミュニティ支援アプリ。住民・管理組合・管理会社の三者連携を支援する情報共有OS。 |
| **Supabase Cloud** | PostgreSQL + Auth + Storage + Edge Functionsを統合したクラウドBaaS。RLSとJWTでマルチテナントを実現。 |
| **Supabase Docker** | Supabase CLIによるローカル開発環境。Docker Desktop上で動作。 |
| **Corbado SDK** | Passkey / WebAuthn 認証を提供する公式認証SDK。`@corbado/react` / `@corbado/node` で構成。 |
| **Magic Link** | メールワンクリックによるパスワードレスログイン方式。Supabase Authが提供。 |
| **JWT（JSON Web Token）** | SupabaseおよびCorbadoが発行する署名付きトークン。`tenant_id` / `role` / `lang` を含む。 |
| **StaticI18nProvider** | HarmoNet独自の静的翻訳コンテキスト。JSON辞書 + Redisキャッシュ構成。 |
| **Redis Cluster** | 翻訳キャッシュ・音声キャッシュ・セッション管理に使用する分散インメモリDB。 |
| **Edge Functions** | Supabaseのサーバレス実行環境。翻訳・音声・AI連携処理を分散実行。 |
| **VOICEVOX API** | 音声読み上げAPI。Supabase Edge `/api/tts` 経由で呼び出される。 |
| **Tachikoma（タチコマ）** | GPT-5ベースのAI PMO。要件・設計・整合性統合を担当。 |
| **Gemini** | ロジック検証とLint整合を担当する品質保証AI。 |
| **Windsurf** | コード生成と自己採点・テスト自動化を行う実装AI。 |
| **AI統合アジャイル** | HarmoNet特有のAI連携開発方式。タチコマ・Gemini・Windsurfが連携して設計〜実装〜検証を完結させる。 |
| **RLS（Row Level Security）** | Supabase PostgreSQLの行レベルセキュリティ。`tenant_id`でデータ分離。 |
| **short_session Cookie** | Corbadoが発行するセッションCookie。Secure + Lax設定でブラウザ認証維持を行う。 |
| **Vercel CI/CD** | GitHub連携による自動ビルド・ロールバック構成。 |

## 7.2 関連ドキュメント

| ドキュメント名 | 概要 | 格納先 |
|---------------|------|--------|
| **harmonet-technical-stack-definition_v4.3.md** | 技術基盤仕様（Supabase + Corbado構成、MagicLink/Passkey独立方式） | `/01_docs/01_requirements/00_project/` |
| **harmonet-detail-design-agenda-standard_v1.0.md** | 詳細設計共通アジェンダ | `/01_docs/04_詳細設計/` |
| **login-feature-design-ch00-index_v1.3.md** | ログイン画面設計INDEX（MagicLink/Passkey独立ボタン方式） | `/01_docs/04_詳細設計/01_ログイン画面/` |
| **harmonet-security-spec_v4.1.md** | セキュリティ・Cookie・暗号化仕様 | `/01_docs/00_project/` |
| **schema.prisma** | Prismaスキーマ定義 | `/prisma/` |
| **20251107000000_initial_schema.sql** | 初期DB構築SQL | `/supabase/migrations/` |
| **20251107000001_enable_rls_policies.sql** | RLSポリシー有効化SQL | `/supabase/migrations/` |

## 7.3 外部サービス・API一覧（v4.3準拠）

| サービス | 用途 | プラン | 備考 |
|---------|------|--------|------|
| **Supabase Cloud** | DB・Auth・Storage・Edge Functions | Pro | PostgreSQL 17 + RLS適用 |
| **Supabase Docker** | ローカル開発環境 | - | Docker Desktop + Supabase CLI |
| **Corbado Cloud** | Passkey / WebAuthn認証基盤 | Standard | short_session Cookie + JWT連携 |
| **Redis Enterprise** | 翻訳・音声キャッシュ | Free〜Pro | Supabase Edgeと統合運用 |
| **Google Cloud Translation API v3** | 自動翻訳 | Standard | StaticI18nProvider経由呼出 |
| **VOICEVOX API** | 音声変換（TTS） | Free | Supabase `/api/tts` ラップ実装 |
| **Cloudflare CDN** | 静的ファイル・画像配信 | Free | Tailwind最適化配信構成 |
| **Sentry** | エラー監視 | Pro | Vercel + Supabase連携 |
| **UptimeRobot** | 稼働監視 | Free | 3分間隔監視 |
| **Gemini API / Windsurf Agent** | AI品質検証・自己採点・自動修正 | Internal | AI統合アジャイル専用構成 |
| **Mailpit** | ローカルメールテスト | Free | Docker環境SMTP受信 |

## 7.4 リスク管理（カテゴリ別）

| リスクカテゴリ | 内容 | 発生確率 | 影響度 | 対応策 |
|--------------|------|---------|--------|--------|
| **認証／Corbado** | Cookie期限切れ・ブラウザ間セッション不一致 | 中 | 中 | 自動再ログインと短期Cookie更新ジョブを実装 |
| **Supabase依存** | サービスダウン・メンテナンスによる一時停止 | 低 | 高 | 日次バックアップ＋RLS再検証スクリプト運用 |
| **Redisキャッシュ不整合** | 翻訳・音声キャッシュ欠損／TTL設定誤り | 中 | 低 | キャッシュ自動リフレッシュ機構を採用 |
| **AI整合性崩壊** | タチコマ／Gemini／Windsurf間の出力差異 | 中 | 中 | CodeAgent_Reportによる自己採点・自動再整合 |
| **翻訳API上限超過** | 月間文字数制限（50万文字）超過 | 低 | 中 | Redisキャッシュ／トークン分割管理 |
| **利用者UX低下** | 通知過多・遅延表示によるストレス | 中 | 中 | Realtimeサブスク管理・UI軽量化 |
| **テナントデータ競合** | 同一tenant_idでの同時更新競合 | 低 | 高 | Prismaトランザクション整合制御 |
| **AI生成誤情報** | Windsurf出力内容が仕様と乖離 | 中 | 中 | Gemini監査＋手動レビュー承認必須化 |
| **セキュリティ侵害** | JWT漏洩／トークン改ざん | 低 | 高 | Corbado署名検証＋Supabaseローテーションキー |
| **法令／PIPA対応** | 個人情報保護法・GDPR要件不履行 | 低 | 高 | 年次監査・データ削除自動化ポリシー |
| **Docker環境差異** | ローカル開発と本番環境の動作差異 | 中 | 中 | Supabase CLI最新化・環境変数統一管理 |

## 7.5 文書承認

| 役割 | 氏名 | 承認日 |
|------|------|--------|
| プロジェクトオーナー | TKD | 2025-11-17 |
| PMO / AI統合責任者 | Tachikoma | 2025-11-17 |
| 開発リードAI | Windsurf | 2025-11-17 |

## 7.6 変更履歴

| バージョン | 日付 | 変更内容 | 作成者 |
|-----------|------|----------|--------|
| v1.0 | 2025/10/26 | 初版作成 | TKD |
| v1.2 | 2025/10/30 | Supabase／RLS対応、Phase拡張 | Tachikoma |
| v1.3 | 2025/10/31 | Technical Stack v3.2準拠化 | GPT署名 |
| **v1.4** | **2025/11/17** | **技術スタックv4.3対応。Docker開発環境明記、Corbado公式構成、MagicLink/Passkey独立方式。AI統合体制・リスク再定義。** | **Tachikoma / TKD** |

## 7.7 注意事項

本書は HarmoNet プロジェクトにおける正式な参照資料であり、
AI開発体制（タチコマ・Gemini・Windsurf）およびTKD承認の下で運用される。
無断複製・配布を禁止し、外部開示は認められない。

---

**Document ID:** HARMONET-REQ-001-COMPLETE  
**Author:** Tachikoma / TKD  
**Reviewer:** TKD  
**Version:** 1.4  
**Created:** 2025-11-12  
**Updated:** 2025-11-17  
**Status:** ✅ HarmoNet正式要件定義（v4.3整合・完全版）

*by Tachikoma (HarmoNet PMO AI)*
