# HarmoNet 詳細設計書 — 掲示板リッチテキスト統合（管理文書対応）
- Phase: 5→6（実装直前詳細）
- Status: 承認申請（TKD最終承認後に実装着手）
- Owner: Tachikoma（PMO / Architect）
- Reviewed by: Gemini（BAG-lite）, Claude（整形補助）
- Related: 03_harmonet-er-entity-definition_v1.2.yaml / 04_harmonet-prisma-schema_v1.0.prisma

---

## 1. 目的 / 背景
管理組合の「お知らせ／回覧板／重要通知／ルール告知」等の**定型＋自由記述**文書を、HarmoNet上で直接作成・配信できるようにする。  
これにより、Word/Excel/PDFのローカル雛形運用を廃止し、**文書文化のクラウド化**を実現する。

### 1.1 ねらい
- 役員が**PCブラウザからそのまま作成・投稿**できる運用へ移行（フォーマット管理不要）
- 書式の統一（Appleカタログ風/やさしく・自然・控えめ）
- 多言語（翻訳/TTS）・PDFプレビュー・通知と自然連携

---

## 2. 対象範囲（Scope）
- 対象機能：掲示板（board_posts）、お知らせ（announcements）、ルール掲示、回覧板
- 当面は**投稿画面**のみリッチテキスト化（閲覧は全画面）
- 将来拡張：**テンプレート管理（任意モジュール）**をテナント単位で有効化可能

---

## 3. 全体アーキテクチャ
- Frontend: Next.js（App Router） + TipTap（ProseMirror） + Tailwind（BIZ UDゴシック前提）
- Backend(API層): Next.js API Routes（認可/サニタイズ/HTML生成）
- DB: Supabase（PostgreSQL, RLS）+ Prisma
- Storage: Supabase Storage（画像/添付PDF/エクスポート用HTML or PDF）
- キャッシュ: Redis（UI応答用）、DB（translation_cache / tts_cache 永続履歴）

---

## 4. データモデル（現行スキーマへの影響）
**現行スキーマは変えず**、board_posts に後方互換フィールド追加で対応（実装時反映）。

```prisma
// board_posts 拡張（後方互換）
model board_posts {
  // 既存:
  id           String @id @default(uuid())
  tenant_id    String
  author_id    String
  category_id  String
  title        String
  content      String           // 従来のプレーンテキスト（残す）
  tags         String[]
  status       String @default("draft")
  created_at   DateTime @default(now())
  updated_at   DateTime @default(now())
  // 追加:
  content_json Json?            // リッチ本文（構造）
  content_html String?          // サニタイズ済HTML（表示キャッシュ）
}

注: 追加は後方互換。既存の一覧/検索は title, content, tags を継続使用。徐々に content_html 検索拡張を検討。

5. テンプレート管理（任意モジュール / テナント単位）

テンプレートを組合（テナント）ごとに保有したい場合のみ採用。v1.0では仕様に含めるが実装は任意。

論理モデル（オプション）

board_templates:
  id: uuid (PK)
  tenant_id: uuid (FK→tenants.id)         # テナントスコープ
  title: string                            # 「重要なお知らせ」等
  category: string                         # announcement/rule/circulation/custom
  content_json: jsonb                      # TipTap構造
  is_public: boolean default false         # 将来: テナント間共有
  created_by: uuid (FK→users.id)
  created_at: timestamp default now()
  updated_at: timestamp default now()
  status: string default active

利用フロー

役員がテンプレートを選択 → 2) content_json をエディタにロード → 3) 編集 → 4) 投稿保存（board_posts.content_json/html）

v1.0 実装方針：テンプレート無しでも運用可。雛形は「エディタ内ブロック」やガイドで代替可能。
テナント差異が顕著になった段階で board_templates を導入する（段階確定方式）。

6. フロントエンド設計（エディタ）
6.1 エディタ選定

TipTap（ProseMirrorベース）

理由：拡張性/アクセシビリティ/日本語IME安定、JSON構造で保存可能、Next.js実績豊富

6.2 構成（必須プラグイン）

見出し（H2/H3）、段落、リスト（番号/箇条）

太字/斜体/下線/打消し、引用、リンク

画像挿入（Storage連携）、表（軽量）

コード/インラインコード（住民向けは非推奨UIにして露出下げ）

署名/日付/注記ブロック（組合向けコンポーネント）

キーボード操作/アクセシビリティ（ARIA）

6.3 UIガイド（HarmoNetトーン）

白基調 / 角丸 2xl / 最小限のシャドウ / 線形アイコン

BIZ UDゴシック前提、見出しは大きめ・本文は読みやすい字間

ボタン語：やさしく・直接的（例：「下書き保存」「プレビュー」「投稿」）

翻訳/TTS/プレビューは右上の控えめアクション群に集約

7. セキュリティ / サニタイズ / RLS

投稿保存前：content_html は DOMPurify（allowlist）でサニタイズ

表示時：dangerouslySetInnerHTML は使用不可、安全なレンダラ経由で描画

画像/添付は Supabase Storage（RLS）+ 署名付きURL

役割：

投稿（役員/管理者のみ）

編集（投稿者/管理者）

公開設定（管理者）

監査：audit_logs に保存（action_type: create_post/update_post/publish_post など）

8. 多言語・音声読み上げ（翻訳/TTS）連携

翻訳：translation_cache を使用（キー：tenant_id, content_type=post, content_id, language）

TTS：tts_cache を使用（同キー＋voice_type）。30日保持（設定可）

処理対象は**content_html**（サニタイズ後）

失効時：Redisキャッシュ失効→DBキャッシュ参照→無ければ再生成→*_cache 保存

9. PDFプレビュー / エクスポート

PDFプレビュー：既存要件に合わせ、PDF.jsモーダル（背景タップで閉じない、✕/テキスト閉じる）

エクスポート：投稿をPDF化してStorageへ保存（pdf/{tenant_id}/{postId}.pdf）

UI：投稿画面に「PDFプレビュー」「PDFとして保存」を追加（管理者/役員向け）

10. API / 保存フロー（簡易）

下書き保存

POST /api/board/posts/draft

入力：title, category_id, tags, content_json

サーバで content_html 生成→サニタイズ→DB保存

公開

POST /api/board/posts/publish（id指定）

ステータス draft→published、通知キュー投入

翻訳/TTS（非同期）

POST /api/board/posts/:id/translate?lang=xx

POST /api/board/posts/:id/tts?lang=xx&voice=default

11. 通知連携

公開時に notifications へレコード作成、購読者に配信

user_notification_settings の notification_type='board'|'announcement'|'rule' を尊重

12. 既存画面要件との整合

PDFプレビューのモーダル仕様（閉じる挙動/背景タップ不可/控えめUI）を踏襲

既存の一覧・検索はそのまま動作（title/content/tags）。将来 content_html の全文検索拡張は別途。

13. 実装計画（影響最小の段階導入）

v1.0：リッチエディタ導入、content_json/html 保存、プレビュー・公開・通知・翻訳/TTS連携

v1.1（任意）：テンプレート機能（board_templates）導入（テナント単位）

v1.2：テンプレート共有（is_public=true の他テナント参照）、AI校正/要約アシスト

14. 非機能要件

パフォーマンス：初回ロード < 2.0s（キャッシュ前提）、編集中のオートセーブ 10s間隔

アクセシビリティ：Tab移動/スクリーンリーダー対応、コントラスト比ガイド遵守

監査性：audit_logs へ主要アクションを記録

テレメトリ：編集中クラッシュ/保存失敗を計測（Sentry等）

15. リスク / 回避策

XSS：サニタイズ徹底、HTML埋め込み制限、リンクtarget/href検証

画像・PDFサイズ肥大：アップロード時点での制限/圧縮

テンプレート氾濫：v1.0は未導入、導入時はカテゴリ・所有者・公開範囲で整理

16. 導入におけるDB変更

必須：board_posts に content_json(jsonb), content_html(text) を追加
※ Prisma側にフィールド追加（後方互換）。マイグレーション生成→実行。

任意：テンプレートを導入する場合のみ board_templates 新規作成（テナントFK/RLS）

17. まとめ（判断ポイント）

現行スキーマへの影響は極小（board_posts への2列追加のみ）

テンプレート管理はテナント単位で運用可能（任意モジュール）

役員がブラウザだけで作成→配信→PDF→翻訳→TTSまで完結する運用へ移行

ChangeLog

v1.0 (2025-11-04): 初版作成（リッチテキスト統合の目的/アーキ/UX/セキュリティ/DB影響/任意テンプレート設計を定義）

Meta
Created: 2025-11-04
Last Updated: 2025-11-04
Version: 1.0
Document ID: HNM-DD-BRD-RT-20251104