# WS-N01 BoardNotification 作業レポート

## 1. 作業概要

- **目的**
  - 管理組合ロールによる掲示板投稿が `status = 'published'` になったタイミングで、テナント利用者へ「新着お知らせ」を通知できるようにする。
  - 通知チャネルは以下 3 つとし、同一イベント（管理組合 `published` 投稿）をトリガとする。
    - HOME 画面のお知らせ表示（未読フラグ）
    - AppHeader のベルアイコン＋未読バッジ
    - メール通知（テナント利用者宛、ローカル環境ではログ出力で代替）
- **前提**
  - Prisma スキーマに `user_tenants.last_seen_board_notification_at` カラムが追加されていること。
  - Supabase Auth＋Prisma によるユーザ／テナント認証が既に導入済みであること。
  - 掲示板 TOP / BoardDetail / BoardPostForm などの基本機能および WS-B02（Favorites）実装が完了済みであること。

## 2. 変更ファイル一覧

### DB / Prisma / Supabase

- `prisma/schema.prisma`
  - `user_tenants` モデル
    - `last_seen_board_notification_at DateTime? @db.Timestamptz(6)` カラムの定義を確認（本 WS では追加済み定義を利用するのみ）。
- `supabase/migrations/20251125093500_add_user_tenants_last_seen_board_notification_at.sql`
  - `user_tenants` テーブルへの `last_seen_board_notification_at timestamptz(6)` 追加マイグレーションを確認（本 WS では変更なし）。

### サーバロジック / API

- `app/api/board/notifications/has-unread/route.ts`
  - 現在ログイン中のユーザに対して、未読のお知らせが存在するかどうかを判定し、`{ hasUnread: boolean }` を返却する API を実装済みであることを確認。
  - 判定条件:
    - Supabase Auth から `user` を取得し、メールアドレスで `public.users` を参照してアプリユーザ (`status = 'active'`) を特定。
    - `user_tenants` から現在テナントに対する membership を 1 件取得し、`tenant_id` および `last_seen_board_notification_at` を取得。
    - Prisma 経由で `board_posts` を検索：
      - `tenant_id = membership.tenant_id`
      - `status = 'published'`
      - `author.user_roles` に `role.role_key = 'tenant_admin'` を持つレコードが存在すること（管理組合ロール）
      - かつ `created_at > last_seen_board_notification_at`（もしくは `last_seen` が `NULL` の場合は無条件）
    - 1 件でも該当投稿が存在すれば `hasUnread = true`、なければ `false`。
- `app/api/board/notifications/mark-seen/route.ts`
  - 現在ログイン中のユーザについて、掲示板通知の最終既読時刻を更新する API を実装。
  - 処理内容:
    - Supabase Auth から `user` を取得し、`users` / `user_tenants` を用いて現在テナント (`tenant_id`) を解決。
    - `user_tenants` テーブルを Supabase クライアントで更新：
      - `last_seen_board_notification_at = new Date().toISOString()` を `user_id`＋`tenant_id` 行に対して `UPDATE`。
    - 成功時に `{ ok: true }` を返却、失敗時は `errorCode` を含む JSON を返却。
- `src/server/services/BoardNotificationEmailService.ts`（新規）
  - 管理組合 `published` 投稿をトリガとしたメール通知（ローカル環境ではログ出力）を行うサービスを追加。
  - 関数:
    - `sendBoardNotificationEmailsForPost({ tenantId, postId })`
      - Prisma を用いて、対象投稿が以下条件を満たすか確認：
        - `id = postId`
        - `tenant_id = tenantId`
        - `status = 'published'`
        - `author.user_roles.some({ tenant_id: tenantId, role.role_key = 'tenant_admin' })`（管理組合ロールのユーザによる投稿）
      - 投稿が見つからない場合:
        - `logInfo('board.notifications.email.skip_not_management_or_not_found', { tenantId, postId })` を出力して終了。
      - 該当投稿が存在する場合:
        - `user_tenants` から `tenant_id = tenantId` かつ `status = 'active'` のレコードを取得し、`user.email` を JOIN して宛先メールアドレスリストを作成。
        - 宛先が 0 件の場合は `logInfo('board.notifications.email.no_active_recipients', ...)` を出力して終了。
        - 件名（日本語）を固定で生成：
          - `【HarmoNet】管理組合から新しいお知らせが投稿されました`
        - 本文生成は行わず、ローカル環境では実メール送信の代わりに以下のログを出力：
          - `logInfo('board.notifications.email.debug_send', { tenantId, postId, email, subject, categoryKey, categoryName, title, createdAt })`
        - 想定運用：本番ではこの処理の中身を実 SMTP / メールサービス呼び出しに差し替えることで、WS-N01 のメール通知仕様を満たす。
      - 予期せぬエラー発生時:
        - `logError('board.notifications.email.unexpected_error', { tenantId, postId, errorMessage })` を出力し、例外は外側に伝播させない（通知失敗が投稿処理全体をブロックしないようにする）。
- `app/api/board/posts/route.ts`
  - 掲示板投稿作成（POST）処理内で BoardNotificationEmailService を呼び出すフックを追加。
  - 変更点（抜粋）:
    - 冒頭の import に通知サービスを追加：
      - `import { sendBoardNotificationEmailsForPost } from '@/src/server/services/BoardNotificationEmailService';`
    - 投稿 INSERT 成功後（添付ファイル処理とモデレーションログ保存・翻訳処理の後ろ）に通知処理を追加：
      - `await sendBoardNotificationEmailsForPost({ tenantId, postId });`
      - 通知処理自体の失敗は `try/catch` で握りつぶし、
        - `logError('board.post.api.notification_error', { tenantId, postId, errorMessage })` のみ出力して投稿 API とレスポンスには影響させない。
    - これにより、
      - 投稿が AI モデレーションで `block` / `mask` 判定となり `status = 'published'` にならないケースでは通知は送信されない。
      - `status = 'published'` になった投稿のみが通知（ログ）対象となる。

### フロントエンド

- `src/components/common/AppHeader/AppHeader.tsx`
  - 既存実装にて WS-N01 の仕様を満たしていることを確認（本 WS ではロジック変更なし）。
  - 仕様との対応:
    - Lucide `Bell` アイコンをヘッダ右側に表示（認証済みバリアントのみ）。
    - `useEffect` 内でマウント時に一度だけ `GET /api/board/notifications/has-unread` を呼び、レスポンスの `hasUnread` を `useState` で保持。
    - `hasUnread = true` のとき、ベルアイコン右上に赤丸バッジを表示。
    - クリック時の挙動:
      - MVP として `/board` へ `router.push('/board')` で遷移。
- `src/components/home/HomeNoticeSection/HomeBoardNotificationBanner.tsx`
  - HOME 画面上部に「新しいお知らせがあります」バナーを表示するコンポーネント。
  - 仕様との対応:
    - マウント時に `GET /api/board/notifications/has-unread` を呼び、`hasUnread` state を更新。
    - `hasUnread = false` の場合は `null` を返却し、バナー非表示。
    - `hasUnread = true` の場合のみ、黄色背景に赤いドット＋`t('home.noticeSection.hasUnread')` 文言を表示。
- `app/home/page.tsx`
  - HOME 画面 Server Component 内で次のコンポーネントを組み合わせて表示：
    - `<HomeBoardNotificationBanner />` … 未読フラグ表示。
    - `<HomeBoardNoticeContainer tenantId={tenantId} maxItems={noticeMaxCount} />` … 管理組合投稿のお知らせ一覧表示。

- `src/components/home/HomeNoticeSection/HomeBoardNoticeContainer.tsx`
  - HOME 画面に表示する「管理組合からのお知らせ」一覧のデータ取得とフィルタリングを実装。
  - 主な仕様:
    - `tenantId` を受け取り、`GET /api/board/posts?tenantId=...` を呼び出し BoardTop 一覧と同じ DTO を取得。
    - その中から、
      - 過去 60 日以内 (`MAX_NOTICE_DAYS = 60`) の投稿のみを対象とし、
      - `BoardCategoryKey` が `['important', 'circular', 'event', 'rules']` のもの（管理組合カテゴリ）だけを抽出。
    - 日付降順にソートしたうえで、タイトル・本文・投稿日を `HomeNoticeItem` にマッピングし、`HomeNoticeSection` へ渡す。

- `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
  - `HomeNoticeItem[]` を受け取り、HOME 上のお知らせカード群を描画。
  - items が空のときはタイトル＋「新しいお知らせはありません」相当の文言を表示、1 件以上のときは指定件数までカードを表示。

- `src/components/board/BoardTop/BoardTopPage.tsx`
  - BoardTop 画面マウント時に `POST /api/board/notifications/mark-seen` を一度だけ呼び出し、掲示板通知を「既読」扱いにする処理を追加済みであることを確認（本 WS ではロジック変更なし）。

## 3. 実装詳細

### 3-1. 未読有無チェック API (`GET /api/board/notifications/has-unread`)

- 認証フロー:
  1. `createSupabaseServerClient` から Supabase クライアントを取得。
  2. `auth.getUser()` で現在ログイン中のユーザを取得。
     - 未ログインもしくはメールアドレス欠如時は `401` を返却し、ボディは `{ hasUnread: false }` とする。
  3. `users` テーブルから `email = user.email` かつ `status = 'active'` のレコードを 1 件取得し、`appUser.id` を得る。
  4. `user_tenants` から `user_id = appUser.id` かつ `status = 'active'` のレコードを 1 件取得し、`tenant_id` と `last_seen_board_notification_at` を取得。
     - membership 取得に失敗した場合は `403` を返却し、ボディは `{ hasUnread: false }`。
- 未読判定クエリ:
  - Prisma で `board_posts.findFirst` を実行し、次の条件を満たす投稿を検索：
    - `tenant_id = membership.tenant_id`
    - `status = 'published'`
    - `created_at > lastSeen`（`lastSeen` が `null` の場合はこの条件を省略）
    - `author.user_roles.some({ tenant_id: tenantId, role.role_key = 'tenant_admin' })`
  - 投稿が 1 件でも見つかれば `hasUnread = true`、そうでなければ `false` として JSON `{ hasUnread }` を `200` で返却。
- エラーハンドリング:
  - 認証・ユーザ検索・membership 取得・Prisma 実行中のエラーは `logError` で記録し、クライアントには `hasUnread: false` とともに `401/403/500` を返却。

### 3-2. 既読マーク API (`POST /api/board/notifications/mark-seen`)

- 認証フロー:
  - `has-unread` と同様に Supabase Auth から `user` と `appUser`、`user_tenants` の membership を取得。
- 更新処理:
  - Supabase クライアントで `user_tenants.update` を実行：
    - `last_seen_board_notification_at = new Date().toISOString()`
    - 条件は `user_id = appUser.id` かつ `tenant_id = membership.tenant_id` かつ `status = 'active'`。
- レスポンス:
  - 更新成功時は `{ ok: true }` を `200` で返却。
  - 更新失敗時は `logError('board.notifications.api.mark_seen_update_error', ...)` を出力し、`{ errorCode: 'update_failed' }` を `500` で返却。

### 3-3. メール通知処理（ログ出力ベース）

- `sendBoardNotificationEmailsForPost({ tenantId, postId })` の詳細:
  - 対象投稿取得:
    - `board_posts.findFirst` で `id`, `title`, `content`, `created_at`, `category.category_key`, `category.category_name` を `select`。
    - `where` 句で `tenant_id`, `status = 'published'`, および `author.user_roles.role.role_key = 'tenant_admin'` を指定し、「管理組合ロールのユーザによる published 投稿」のみを対象とする。
  - 管理組合投稿でない場合:
    - 上記 `findFirst` で投稿が見つからなかった場合は通知対象外として、
      - `logInfo('board.notifications.email.skip_not_management_or_not_found', { tenantId, postId })` を出力し、処理終了。
  - 宛先ユーザ取得:
    - `user_tenants.findMany` で `tenant_id = tenantId` かつ `status = 'active'` の行を取得し、`user.email` を JOIN。
    - 取得したメールアドレスリストから `null` や空文字を除外した `recipientEmails: string[]` を作成。
    - 宛先が存在しない場合は `logInfo('board.notifications.email.no_active_recipients', { tenantId, postId })` を出力して終了。
  - ローカル環境でのメール送信シミュレーション:
    - 件名を固定値で生成し、各宛先に対して次のログを出力：
      - `logInfo('board.notifications.email.debug_send', { tenantId, postId, email, subject, categoryKey, categoryName, title, createdAt })`
    - 実メール送信処理はまだ組み込んでおらず、WS-N01 の「ローカル環境ではログ出力でも可」という方針に従う。
  - 予期せぬ例外時:
    - `logError('board.notifications.email.unexpected_error', { tenantId, postId, errorMessage })` を出力し、例外は外側に投げない（通知失敗で投稿 API が 500 にならないようにする）。

### 3-4. AppHeader / HOME の未読表示

- AppHeader:
  - 認証済みバリアント (`variant = 'authenticated'`) のみベルアイコンを表示し、マウント時に `has-unread` API を 1 回だけ呼び出して `hasUnread` state に反映。
  - `hasUnread` が `true` のときのみ赤いバッジを表示し、ARIA ラベルでは `t('home.noticeSection.hasUnread')` を用いて「新しいお知らせがあります」を読み上げる。
  - クリック時には `/board` へ遷移し、BoardTop マウント時の `mark-seen` 呼び出しにより既読処理が行われる。

- HOME 画面:
  - `HomeBoardNotificationBanner` が `has-unread` API を用いて未読フラグを判定し、未読ありのときのみバナーを表示。
  - `HomeBoardNoticeContainer` は `GET /api/board/posts` のレスポンスから管理組合カテゴリ（`important`, `circular`, `event`, `rules`）かつ直近 60 日以内の投稿を抽出し、`HomeNoticeSection` に渡してカードを表示。

## 4. 動作確認

### 4-1. 管理組合投稿時のメール通知ログ

1. 管理組合ロール（`tenant_admin` ロールを持つユーザ）でログインし、BoardNew から管理組合として新規掲示板投稿を作成する。
2. 投稿が正常に `status = 'published'` で登録されるケースで、サーバログに以下のレコードが出力されることを確認：
   - `board.notifications.email.debug_send` が、対象テナントの `user_tenants.status = 'active'` なユーザ数分だけ出力されている。
   - `tenantId`, `postId`, `email`, `subject`, `categoryKey`, `title`, `createdAt` などが期待どおりの値になっていること。
3. 一般利用者ロールのみを持つユーザが投稿した場合には、`board.notifications.email.skip_not_management_or_not_found` ログが出力され、`debug_send` ログが出ないことを確認。

### 4-2. HOME / AppHeader の未読バッジ・バナー

1. 一般ユーザでログインし、HOME 画面を表示する。
2. 管理組合ユーザが新規投稿を行ったあと、ブラウザをリロードして HOME を再表示し、次を確認：
   - AppHeader のベルアイコンに赤い未読バッジが表示されること。
   - HOME 上部に「新しいお知らせがあります」バナーが表示されること。
3. HOME から FooterShortcutBar などを用いて `/board` に遷移し、BoardTop がマウントされた時点で `POST /api/board/notifications/mark-seen` が呼ばれていることを Network タブで確認。
4. `/board` から `/home` に戻った際、未読投稿が他に存在しなければ：
   - ベルアイコンの赤バッジが非表示になっていること。
   - HOME の「新しいお知らせがあります」バナーが非表示になっていること。

### 4-3. エラー時の挙動

1. `user_tenants` に active な membership が存在しないユーザでアクセスした場合：
   - `has-unread` / `mark-seen` API がそれぞれ `403` を返却し、ログに `membership_error` が記録されること。
   - フロントエンドでは未読情報取得失敗を握りつぶす実装となっており、画面が致命的に壊れないことを確認。
2. Prisma または Supabase の一時的エラーが発生した場合：
   - `board.notifications.api.has_unread_unexpected_error` または `board.notifications.email.unexpected_error` 等のログが出力されること。
   - その場合でも掲示板投稿自体の作成 (`POST /api/board/posts`) が成功すれば 201 が返却されること（通知失敗が投稿処理をブロックしない）。

## 5. 残課題・今後の拡張余地

1. **実際のメール送信実装**
   - 現状はローカル環境前提で `logInfo('board.notifications.email.debug_send', ...)` による疑似送信のみ実装している。
   - 実運用では、Nonfunctional 要件およびメール送信基盤（SMTP / 外部メールサービス SDK）の確定後、本サービス関数内部を置き換えることで本物のメール送信を行う必要がある。
2. **言語別メールテンプレート**
   - WS-N01 仕様上は日本語テンプレートのみでよい前提だが、将来的には `users.language` やテナント設定を参照して、EN/ZH 含む多言語メールテンプレートを導入する余地がある。
3. **通知の ON/OFF 設定**
   - `user_notification_settings` などの通知設定テーブルと連携し、ユーザごとに「掲示板メール通知 ON/OFF」フラグでフィルタする拡張が想定されている（本 WS では実装対象外）。
4. **パフォーマンス・バッチ化**
   - 現行実装では 1 投稿につき `user_tenants`→`users` の JOIN 結果をメモリ上でループし、ログ出力している。
   - 実メール送信時には、大量テナント・大量ユーザ環境を想定して、キューイングやバッチ処理、再送リトライなどを考慮する余地がある。
