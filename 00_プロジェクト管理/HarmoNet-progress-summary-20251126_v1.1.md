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


進捗サマリは、こちら側で更新をかけようとしましたが、既存テキストの一部が手元のバージョンと微妙に差分があるようで、パターン一致に失敗し、今回は自動書き換えができませんでした。
（ファイル自体は壊していません。そのまま残っています）

なので、内容ベースで「今日分の追記案」と「今後やること」をテキストでお渡しします。
明日、余裕のあるときに TKD ローカルの進捗サマリにコピペで反映してもらう形にしましょう。

---

## 今日の進捗追記案（2.x に追加）

### 2.6 BoardTop 動的翻訳・翻訳キャッシュ実装

* Google Translate API を用いた動的翻訳と翻訳キャッシュ（`board_post_translations`）を実装。
* 投稿時:

  * タイトル＋本文を対象に、Google の言語検出＋UI 言語フォールバックで `sourceLang` を決定。
  * `['ja','en','zh']` のうち `sourceLang` 以外の 2 言語に対して翻訳を実行し、`board_post_translations` に upsert。
  * RLS により INSERT が拒否されていた問題を、`service_role` クライアント＋既存 RLS 方針の組み合わせで解消。
* 掲示板TOP `/board`:

  * `/api/board/posts` で `board_posts` + `board_post_translations` をまとめて返す GET を追加。
  * BoardTopPage は `currentLocale`（JA/EN/ZH）に応じて翻訳キャッシュを優先し、無い場合のみ原文を表示するサマリ表示に変更。
  * 言語切替ボタン（JA/EN/ZH）で投稿サマリが自動で翻訳表示されることを確認。

### 2.7 BoardDetail 閲覧専用ビューの実装

* `/board/[postId]` に BoardDetailPage（閲覧専用）を実装。
* 内容:

  * `getBoardPostById` server 関数で 1 件の投稿＋翻訳＋添付メタ情報＋コメント一覧を取得。
  * BoardTop と同じロジックで翻訳キャッシュを利用し、JA/EN/ZH の本文切り替えを実現。
  * コメントは現時点では閲覧のみ（投稿・削除・翻訳ボタン・TTS は後続タスク）。
  * 添付ファイルリストと PDF プレビューモーダルの UI 骨格を作成（Storage 側実装は今後 BoardPostForm 側で対応）。
  * `/board/new`・`/board/[postId]` に AppFooter を追加し、エラー時でも Home/Board などへ戻れる導線を確保。

### 2.8 RLS・環境変数・ユーザデータの整備

* 翻訳キャッシュ用テーブル `board_post_translations` / `board_comment_translations` の RLS を整理し、翻訳処理のみ `service_role` クライアントで upsert する構成に統一。
* `.env.local` の Supabase キー設定を是正:

  * `NEXT_PUBLIC_SUPABASE_ANON_KEY` と `SUPABASE_SERVICE_ROLE_KEY` が同値だった問題を修正。
  * Supabase CLI の `Publishable key` を anon、`Secret key` を service_role として再設定し、`hasServiceRole: true` を確認。
* `users` テーブルの `email` に UNIQUE 制約を追加し、重複ユーザが作成されないように修正（既存の重複レコードは事前に削除）。

---

## 「次のステップ」差し替え案（3章）

```md
## 3. 次のステップ（掲示板まわり）

1. 掲示板TOP `/board` の仕上げ
   - 表示項目の最終確認（タイトル／カテゴリ名／投稿者表示名／投稿日／添付有無／翻訳状態など）。
   - Home 画面上部の「お知らせ」カードを、ダミーではなく最新掲示板投稿（管理組合向けアナウンス）から取得するように変更。

2. 掲示板詳細 `/board/[postId]` の機能拡張
   - 添付ファイルアップロード＆保存（BoardPostForm 側）
     - Supabase Storage へのアップロードと `board_attachments` メタ情報保存。
     - BoardDetail / BoardTop / Home からのダウンロード・PDF プレビュー連携。
   - 翻訳ボタンと音声読み上げ（TTS）
     - 翻訳ボタン押下で翻訳キャッシュを再生成し、画面を更新。
     - TTS ボタンで現在表示中言語の本文を読み上げ（エラー時はメッセージのみ）。
   - お気に入りフラグ
     - ログインユーザ単位での「お気に入り」ON/OFF トグルと、BoardTop/Home からのフィルタ表示を段階的に実装。

3. RLS / セキュリティ再確認
   - 掲示板関連テーブル（board_posts / board_comments / board_attachments / board_post_translations / board_comment_translations / tenant_settings 等）の RLS を `user_tenants` ベース＋`service_role` ポリシーの組み合わせで最終チェック。
   - 掲示板TOP・詳細・投稿画面が一通り完成したあとに、不要な緩和や暫定措置が残っていないか確認し、必要であれば RLS ドキュメント（harmonet-RLS-policy）を更新。

4. テスト・UX 調整
   - BoardTop / BoardDetail / BoardPostForm の E2E シナリオ（投稿→翻訳→閲覧→削除まで）を洗い出し、手動テスト観点として整理。
   - 翻訳・TTS・添付ダウンロードまわりのエラー表示・メッセージ文言（i18nキー）の微調整。
```

---

今日はここまでで十分だと思います。
明日はこの内容を TKD ローカルの進捗サマリに反映してから、

* 添付ファイル対応の WS-B03 指示書
* その後の BoardDetail 翻訳ボタン／TTS／お気に入りフラグ

に進めましょう。

| B-11 | 掲示板投稿    | 管理組合投稿の公開前ワークフロー設計            | 管理組合ロールによる掲示板投稿は、公開前に複数承認者によるワークフロー承認を必須とする。承認者の指定方法（人数・候補ユーザ）、承認フロー（全員承認時に公開／否認時の扱い）、投稿ステータス遷移（draft/pending_approval/published/rejected）と管理画面UIを設計する。 | TKD  | 中     | 未着手     | 2025-11-25  |       | 掲示板の基本機能・運用が安定してから詳細設計・実装。承認履歴テーブル追加も想定。 |


# HarmoNet 掲示板まわり 進捗管理表（2025-11-26）

## 本日の実績

| No | 区分           | タスクID / ドキュメント                     | 内容概要                                               | 状態       | 備考 |
|----|----------------|----------------------------------------------|--------------------------------------------------------|------------|------|
| 1  | 実装・API      | WS-B02_BoardComments_ReplyAndDelete_v1.0    | コメント投稿API・コメント削除API・投稿削除API（親）の実装とUI統合。返信ボタン・削除モーダル、翻訳対応、BoardTopへの返信数表示。 | 完了       |      |
| 2  | 実装・機能     | WS-B02 BoardDetail Favorites                 | BoardDetailのお気に入り★トグルと、BoardTopの「☆お気に入り」フィルタタブ実装。`board_favorites` テーブル連携。 | 完了       |      |
| 3  | 実装・通知     | WS-N01 BoardNotification                      | ベル通知・HOMEバナー・HOMEお知らせ一覧・既読管理（`user_tenants.board_last_seen_at`）・メール通知ロジック（ログベース）の実装。 | 動作確認中 | 通知ベル挙動・既読更新ロジックは概ね確認済／メール実送信は未実装（通知機能全体の優先度は中〜低） |
| 4  | 実装・TTS      | WS-B02 BoardDetail TTS                        | BoardDetailの本文読上げボタンと `/api/board/tts` 実装。Google Cloud TTS連携、読上げ状態管理、添付ボタンの枠線スタイル統一。 | 完了       |      |
| 5  | 実装・添付     | WS-B03 BoardPostForm 添付機能                | BoardPostFormの添付（PDF/Office/画像 最大5件）・Storage連携・BoardDetailでのプレビュー／ダウンロード・匿名表示・翻訳キャッシュ修正。 | 完了       |      |
| 6  | 実装・RLS強化  | WS-B99_BoardApiTenantGuard_v1.0              | board API（コメント作成／削除・投稿削除）のテナントガード強化。`user_tenants` から取得した `tenantIds` での絞り込みとGuardテスト追加。 | 完了       | 既存テストにRED残あり（本タスク範囲外） |


今日の分、進捗メモ案だけ出しておきます。

---

【2025-11-26 進捗メモ（案）】

* 掲示板返信機能

  * `board_comments.author_display_name` を追加し、返信時に「管理組合／匿名／ニックネーム」を焼き付け保存できるようにした。
  * BoardPostForm に `mode=create/reply` を追加し、`/board/new?replyTo=` から返信モードで起動するよう修正。
  * 返信モードでは投稿者区分＋表示名＋本文のみ入力し、タイトル／カテゴリ／添付は非表示・非送信とした。
  * 管理組合ロールのみ「投稿者区分」を表示し、一般利用者は表示名ラジオのみ表示する仕様を実装。

* 表示・削除まわり

  * コメント一覧で `author_display_name` を優先表示し、管理組合／匿名／ニックネームが仕様どおりに見えることを確認。
  * 投稿・コメント削除時に関連データ（翻訳／キャッシュ／添付など）が残らないよう、削除フローを修正・確認。

* UI/UX 調整

  * AppFooter のレイアウト崩れ（コピーライトだけ背景が透ける問題）を修正し、フッター下に本文が見えないよう統一。
  * BoardPostForm 返信用ラベルのハードコーディングを除去し、静的 i18n 経由で JA/EN/ZH 切り替えに対応。
  * ホーム画面・掲示板TOP・詳細・返信までの一連の画面遷移と表示をスマホ幅で確認。

* カテゴリタグ

  * 掲示板TOP のカテゴリタグをトグル動作に修正。
  * フィルタ条件は「選択されたカテゴリのいずれかに該当する投稿を表示（OR 条件）」で仕様と実装を揃えた。
  * 「すべて」押下でカテゴリ／お気に入りフィルタをリセットする挙動を確認。

