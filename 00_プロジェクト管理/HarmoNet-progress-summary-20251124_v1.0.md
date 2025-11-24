# HarmoNet 進捗サマリ v1.1
- 更新日: 2025-11-24

## 1. 最近の開発状況

### 1.1 2025-11-23 までの状況（抜粋）
- BoardPostForm 詳細設計（B-03 ch01〜ch07）を v1.1 ベースで整備。
- 掲示板投稿画面（/board/new）実装が一通り完了し、DB への投稿保存まで確認。
- Supabase RLS により board_posts への INSERT が 500 になる問題を Windsurf と協調して解消。
  - board_posts INSERT を Prisma 経由に変更し、RLS は維持したまま権限チェックは user_tenants 側で実施。
- AI モデレーション仕様（B-03 ch08）の初版を作成し、OpenAI モデレーションとの連携方針を整理。

（※ ここは v1.0 からの既存内容を要約）

---

## 2. 2025-11-24 の進捗

### 2.1 BoardPostForm 実装・AIモデレーション統合

- `/board/new` → `BoardPostForm` → `/api/board/posts` のフローが、設計書 B-03 ch02〜ch05 / ch08 と整合する形で完成。
- AIモデレーション連携（OpenAI + ローカル NG ワード）のパイプラインを投稿フローに組み込み、下記を確認済み:
  - `decision = allow` の場合はそのまま投稿保存。
  - `decision = block` の場合は投稿を保存せず `ai_moderation_blocked` を返し、フォーム上にブロックメッセージを表示。
- Level制御（tenant_settings.config_json）を実装:
  - `board.moderation.level = 0`: ログのみ（挙動には影響させない）。
  - `level = 1`: mask（警告＋伏字＋ユーザ選択 → 伏字状態で保存）。
  - `level = 2`: block（保存せず拒否）。

### 2.2 mask 挙動の実装完了

- Level=1（mask）の仕様を B-03 ch08 に反映し、それに合わせて実装・テストを実施。
- 実装内容の要点:
  - OpenAI モデレーションとローカル NG パターンから `decision = allow / mask / block` を決定。
  - `decision = mask` の場合:
    - 1回目投稿時は Prisma INSERT を行わず、`ai_moderation_masked` を返却。
    - サーバ側で `maskSensitiveText` を用いて不適切語を `***` に置換した `maskedTitle` / `maskedContent` を生成。
    - BoardPostForm は警告メッセージを表示し、タイトル／本文を伏字済みテキストに差し替え、黄色ボタン「この伏字済み内容で投稿」を表示。
    - 黄色ボタン経由の再投稿時は `forceMasked = true` を付与し、伏字済みテキストのまま `board_posts` へ保存。
- テスト結果:
  - NGワードを含む投稿で、初回 `ai_moderation_masked` → 伏字＋警告＋黄色ボタンが表示されることを確認。
  - 黄色ボタンで再投稿すると、DB 上の title / content が伏字状態で保存されることを確認。
  - `moderation_logs` に `decision = mask` が記録されることを確認。

### 2.3 tenant_settings の RLS 見直し

- 事象:
  - SQL エディタからは `tenant_settings` の `config_json` が参照できているにもかかわらず、アプリからの Supabase クエリ（anon/authenticated ロール）では `tenantSettingsRows = []` になり、すべて `level = 0` 扱いになっていた。
- 原因:
  - `tenant_settings_select` ポリシーが JWT の `tenant_id` に依存しており、現行の JWT クレームとテーブル側の `tenant_id` が一致しないケースがあるため、RLSにより 0 行扱いになっていた。
- 対応:
  - RLS の「あるべき論」として、テナント境界の判定を JWT ではなく `user_tenants` 経由に統一。
  - `tenant_settings` の SELECT ポリシーを次の形に変更:

    ```sql
    create policy "tenant_settings_select_for_tenant_members"
    on public.tenant_settings
    for select
    to authenticated
    using (
      exists (
        select 1
        from public.user_tenants ut
        where ut.user_id   = auth.uid()::text
          and ut.tenant_id = tenant_settings.tenant_id
          and ut.status    = 'active'
      )
    );
    ```

  - この結果、アプリからも正しく level=1 を取得できるようになり、mask 挙動が設計どおり動作することを確認。

### 2.4 詳細設計書 B-03 ch08 の更新

- B-03_BoardPostForm-detail-design-ch08-ai-moderation_v1.1.md を、実装仕様に完全に合わせる形で更新。
- 主な修正点:
  - Level 0/1/2 の役割を「ログのみ / mask / block」として再定義。
  - 投稿／コメントそれぞれのフローに `ai_moderation_masked` / `ai_moderation_blocked` の分岐を明示。
  - エラーコードと i18n キー（特に `board.postForm.error.submit.moderation.masked`）の仕様を追記。
- これにより、設計書と実装の挙動（特に mask フロー）が一致した。

### 2.5 BoardPostForm UI の仕様漏れ修正

- 投稿区分が「管理組合」の場合は、表示名ラジオ（匿名／ニックネーム）を非表示とし、表示名を常に「管理組合」に固定する挙動に変更。
- B-03 ch05 Messages & UI に補足として、「表示名ラジオは一般利用者投稿のみ表示、管理組合投稿では非表示」と明記。

---

## 3. 次のステップ（掲示板まわり）

1. 掲示板TOP `/board` の設計・実装
   - 表示項目の確定（タイトル／カテゴリ名／投稿者表示名／投稿日／添付有無／翻訳状態など）。
   - データ取得仕様の整理（board_posts + board_categories + users + translations）。
   - Windsurf 向け作業指示書の作成。

2. 掲示板詳細 `/board/[postId]` の設計・実装
   - 表示名（匿名／ニックネーム／管理組合）ロジックの反映。
   - 添付ファイル一覧および PDF プレビュー（モーダル）の実装。
   - コメント一覧と返信フロー（BoardPostForm との連携）。

3. RLS / セキュリティ再確認
   - 掲示板関連テーブル（board_posts / board_comments / board_attachments / tenant_settings 等）の RLS を `user_tenants` ベースで統一する最終チェック。
   - 掲示板全体の動作が安定してから、不要な緩和や暫定条件が残っていないかを確認。

---

## 4. 関連ドキュメント・ログ

- B-03_BoardPostForm-detail-design-ch08-ai-moderation_v1.1.md  
  - AI モデレーションの正式仕様（Level 0/1/2 / mask / block / エラーコード）が反映済み。
- 2025-11-24_掲示板AIモデレーション実装レポート.md  
  - 実装経緯・RLS トラブルシュート・テスト観点の詳細ログ。
- schema.prisma / tenant_settings RLS  
  - `tenant_residents` 追加、`tenant_settings` RLS の user_tenants ベースへの変更。
