# HarmoNet 認証・掲示板・テナント管理 実装レビュー（2025-11-28）

## 対象範囲

- ログイン画面・認証フロー
  - `app/login/page.tsx`
  - `src/components/auth/MagicLinkForm/MagicLinkForm.tsx`
  - `app/api/auth/check-email/route.ts`
  - `app/api/auth/callback/route.ts`
  - `lib/supabaseClient.ts`
  - `src/lib/supabaseServerClient.ts`
  - `src/lib/supabaseServiceRoleClient.ts`
  - `app/layout.tsx`

- 掲示板系
  - TOP: `app/board/page.tsx` + `src/components/board/BoardTop/BoardTopPage.tsx`
  - 詳細: `app/board/[postId]/page.tsx` + `src/components/board/BoardDetail/BoardDetailPage.tsx` + `src/server/board/getBoardPostById.ts`
  - 新規投稿: `app/board/new/page.tsx` + `src/components/board/BoardPostForm/BoardPostForm.tsx`
  - API: `app/api/board/posts/route.ts`, `app/api/board/comments/route.ts`, `app/api/board/comments/[commentId]/route.ts`, `app/api/board/posts/[postId]/route.ts`
  - 通知: `app/api/board/notifications/has-unread/route.ts`, `app/api/board/notifications/mark-seen/route.ts`

- テナント管理（t-admin）
  - 画面: `app/t-admin/users/page.tsx` + `src/components/t-admin/TenantAdminUserManagement/TenantAdminUserManagement.tsx`
  - API: `app/api/t-admin/users/route.ts`, `app/api/t-admin/users/check-email/route.ts`

- 関連テーブル（Prisma / Supabase）
  - `users`, `user_tenants`, `user_roles`, `roles`
  - `board_categories`, `board_posts`, `board_comments`, `board_post_translations`, `board_comment_translations`, `board_attachments`, `board_favorites`
  - `tenant_settings`, `moderation_logs`, `notifications` など

---

## 1. ログイン／認証フロー

### 実装概要

- フロント:
  - `/login` で `MagicLinkForm` を表示し、メールアドレス入力 → `/api/auth/check-email` で存在チェック → `supabase.auth.signInWithOtp` で MagicLink 発行。
  - MagicLink の `emailRedirectTo` は `/auth/callback`。
- コールバック:
  - `app/api/auth/callback/route.ts` の `GET` で `code` を受け取り、`supabase.auth.exchangeCodeForSession(code)` を実行。
  - その後、service_role クライアントで
    - `public.users` からアプリユーザを検索
    - `user_tenants` からテナント所属を取得
    - `tenants.status` が `active` であることを確認
  - 条件を満たせば `next`（デフォルト `/home`）へリダイレクト、失敗時は `/login?error=unauthorized`。
- 共通レイアウト:
  - `app/layout.tsx` で `createSupabaseServerClient()` → `auth.getUser()` して、ログイン状態を判定。
  - ログイン済みなら `user_tenants` + service_role クライアントでテナント名を取得し、ヘッダに表示。

### 評価（要件との整合・問題点）

- MagicLink + PKCE フローは Supabase の推奨パターンに沿っており、構成は妥当。
- セッション確立は Supabase Auth、テナント認可はサーバ側（`users` / `user_tenants` / `tenants`）で行っており、
  これまでの設計方針と整合している。
- `/auth/callback` は現在 route ベースのみで、過去に使っていた `AuthCallbackHandler`（クライアント側処理）は未使用のバックアップとなっている。
  - Next.js App Router + `exchangeCodeForSession` で完結しているため、実装としては問題なし。
- `app/layout.tsx` では、認証エラー時に例外を握りつぶして「ログインヘッダのまま」にしており、
  グローバルレイアウトでの失敗が画面崩壊につながらないよう配慮されている。

### 改善・注意ポイント

- 本番運用では、`auth.check_email` 系のログにメールアドレスが含まれるため、
  ログ閲覧権限の管理やマスキングポリシーを別途検討する必要あり（実装としては許容範囲）。
- `/auth/callback` の正式な実装方針（route.ts 方式 vs AuthCallbackHandler 方式）は
  ドキュメント上でどちらかに統一しておくと、将来の保守時に混乱が少ない。

---

## 2. ホーム／掲示板 TOP（/home, /board）

### /home

- `app/home/page.tsx` で
  - `auth.getUser()` → `public.users` → `user_tenants` を順に確認。
  - 失敗時は `signOut()` して `/login?error=...` にリダイレクト。
  - `user_roles` から `tenant_admin` かどうかを判定し、UI に `isTenantAdmin` を渡して機能タイルを制御。
  - `tenant_settings.config_json` からホーム画面の「お知らせ最大件数」を読み出し、`clampNoticeCount()` で安全に正規化。

→ 認証・認可・テナント設定の扱いはいずれも妥当で、とくに問題なし。

### /board (TOP)

- `app/board/page.tsx` で /home と同様に
  - `auth.getUser()` → `users`（email）、`user_tenants` で membership チェック。
  - 失敗時は `signOut()` → `/login` リダイレクト。
  - `tenantId` を `BoardTopPage` に渡す。
- `BoardTopPage`（クライアントコンポーネント）では
  - `tenantId` をクエリに `GET /api/board/posts?tenantId=...` を呼び出し、DTO を表示に変換。
  - カテゴリタブ・お気に入りフィルタ・カテゴリフィルタ、および新規投稿 FAB のドラッグ挙動などを実装。

### GET /api/board/posts

- `app/api/board/posts/route.ts::GET` では
  - `auth.getUser()` / `users` / `user_tenants` で再度 membership チェック（多重防御）。
  - `user_roles` ＋ `roles(role_key)` から `tenant_admin` / `system_admin` を判定し、`isAdmin` フラグを決定。
  - 非管理者の場合は Prisma の where に
    - `category_key <> 'group'`
    - もしくは `category_key = 'group' AND author.group_code = 自分の group_code`
    を付与し、他グループ向け投稿を制限。
  - `board_posts` と
    - `category`
    - `translations`
    - `attachments`
    - `_count.comments`
    - `favorites`（当該ユーザ分）
    を join し、BoardTop 用の DTO を構築。

### 評価・改善ポイント

- **テナント境界** はすべて `tenant_id` で確実に絞り込まれており、RLS と合わせて安全。
- group 向け投稿の可視性も、`group_code` ベースのフィルタで正しく制限されている。
- `BoardPostSummaryDto.authorDisplayType` は現在 `"user"` 固定で、`board_posts.author_role` をまだ反映していない。
  - 将来的に「管理組合からの投稿」の見た目を変える場合は、
    - POST 時に `author_role` を正しく設定
    - GET 時に DTO へ `authorDisplayType: 'management' | 'user'` を反映
    する必要あり。

---

## 3. 掲示板詳細（/board/[postId]）

### ルートとデータ取得

- `app/board/[postId]/page.tsx`:
  - `params` は `Promise<{ postId: string }>` として受け取り、`await` で展開（Next 14 の新仕様に対応）。
  - 以降は /board と同様に `auth.getUser()` / `users` / `user_tenants` をチェックし、
    エラー時は `/login` へリダイレクト。
  - `tenantId` と `currentUserId` を `getBoardPostById({ tenantId, postId, currentUserId })` に渡す。

- `getBoardPostById`:
  - Prisma で
    - `board_posts`（`tenant_id`, `status='published'`）
    - `category`
    - `board_post_translations`
    - `board_attachments`
    - `board_comments` + コメント翻訳 + コメント著者
  を一括取得。
  - 別途 `board_favorites` と `user_roles` を Prisma で参照し、
    - `isFavorite`
    - `hasAdminRole`
    - `isDeletable = (post.author_id == currentUserId) OR hasAdminRole`
    を計算。

### BoardDetailPage

- 受け取った DTO から
  - カテゴリラベル（i18n キー）
  - 日時表示
  - 本文 / 翻訳
  - 添付ファイル（プレビュー・ダウンロード・削除）
  - コメント（削除・翻訳）
  - お気に入りトグル
  を描画。
- 画面表示時に `POST /api/board/notifications/mark-seen` を呼び出し、
  - tenant 内の管理者投稿の最新日時と `user_tenants.board_last_seen_at` を比較するロジックと連携して、
    「お知らせバッジ」を制御している。

### 評価

- テナント境界 + 権限（著者 or admin）の判定はサーバサイドで行っており、安全な構成。
- コメント削除についても `isDeletable` を DTO に含め、画面側はそれに従うだけなので、
  権限ロジックはサーバに集約されている。
- 通知既読の更新タイミングは「詳細画面を開いたとき」であり、要件の「管理組合からのお知らせが来たらバッジ表示／既読更新」と整合している。

---

## 4. 掲示板新規投稿（/board/new + BoardPostForm + POST /api/board/posts）

### サーバコンポーネント /board/new

- 認証フローは /board と同様。
- `user_roles` / `roles` を用いて `viewerRole = 'admin' | 'user'` を判定。
- Supabase 経由で `board_categories`（`status='active'`）を読んだうえで、
  自テナントのカテゴリのみにフィルタリングしてフォームに渡す。

### BoardPostForm

- `viewerRole`, `isManagementMember`, `categories` から
  - 管理組合として投稿: `ADMIN_CATEGORY_KEYS = ['important', 'circular', 'event', 'rules']`
  - 一般ユーザとして投稿: `USER_CATEGORY_KEYS = ['question', 'request', 'group', 'other']`
  のどちらかにカテゴリを制限。
- バリデーション:
  - 必須: カテゴリ、表示名モード（一般投稿時）、タイトル（新規投稿）、本文。
  - 添付ファイル数・タイプ・サイズは `BOARD_ATTACHMENT_DEFAULTS` を参照。
- 投稿時
  - 返信モード: `POST /api/board/comments` へ JSON で送信。
  - 新規投稿: multipart/form-data で `POST /api/board/posts` へ送信。
    - `tenantId`, `authorId`, `posterType`, `displayNameMode`, `categoryKey`, `title`, `content`, `forceMasked`, `uiLanguage`, `attachments`。

### POST /api/board/posts

- 認証・membership チェック（`users`, `user_tenants`）を再実施。
- 添付ファイル制約を `boardAttachmentSettings` から判定。
- `board_categories` / `tenant_settings(board.moderation)` を読んで AI モデレーションを実施し、
  - `allow` / `mask` / `block` に応じて本文をマスク or ブロック。
- `board_posts` に `status='published'` で Insert。
- 添付ファイルは Supabase Storage + `board_attachments` に保存し、エラー時はトランザクション的にロールバック。
- 翻訳キャッシュ（`board_post_translations` 相当）とメール通知（`sendBoardNotificationEmailsForPost`）も実行。

### 評価・改善ポイント

- 要件（B03）の範囲で求められていた
  - テナント管理者／一般ユーザのカテゴリ制限
  - AI モデレーション（許可・マスク・ブロック）のハンドリング
  - 添付ファイル上限
  は概ね満たされている。

- 課題点（要修正候補）:
  - `BoardPostForm` からは `posterType` を送っているが、API 側が読んでいるのは `authorRole` であり、
    現状 multipart 側では `authorRole` が送られていない。
  - その結果、`board_posts.author_role` は常に `'general'` となり、
    「管理組合として投稿」しても DB では一般投稿扱いになっている可能性が高い。
  - コメント API 側は `author_role === 'management'` を見て権限制御しているため、
    今後仕様を厳密にする場合は
    - フロント → API へ `authorRole` を送る
    - API 内で `posterType` から `authorRole` を決定する
    などの橋渡しが必要。

---

## 5. コメント API / 削除 API

### コメント作成 `POST /api/board/comments`

- `getActiveTenantIdsForUser` でユーザの所属テナントを一覧取得し、
  `board_posts` を `tenant_id in (tenantIds)` で検索（テナント境界を Prisma で担保）。
- `author_role` + `user_roles`/`roles` から
  - 管理組合投稿には admin のみ返信可
  - 重要系カテゴリ（important/circular/event/rules）には誰も返信不可
  といった制約を実装。
- コメント本文の翻訳キャッシュも BoardPostTranslationService 経由で実施。

### コメント削除 `DELETE /api/board/comments/[commentId]`

- `getActiveTenantIdsForUser` で membership 判定後、Prisma でコメントを `tenant_id in (tenantIds)` で取得。
- 著者本人 or admin であれば、
  - `board_comment_translations` / `moderation_logs` を削除しつつ
  - `board_comments.status = 'deleted'`, `content = 'この投稿は削除されました。'` に更新（論理削除）。
  - enum 不整合時は物理削除にフォールバック。

### 投稿削除 `DELETE /api/board/posts/[postId]`

- `getActiveTenantIdsForUser` で tenantIds を取得し、`board_posts` を `tenant_id in (tenantIds)` で検索。
- 著者本人 or admin であれば、
  - 添付ファイル（Supabase Storage + `board_attachments`）削除
  - `moderation_logs` / `board_posts` をトランザクションで削除。

### 評価

- いずれの削除系 API も
  - 認証 → `public.users` → `user_tenants` での membership 確認
  - author or admin 判定
  - テナント境界の Prisma 条件
  を踏んでおり、実装として健全。
- `getActiveTenantIdsForUser` の `status` カラム参照バグは今回修正済み（`user_tenants.status` は現行スキーマには存在しない）。

---

## 6. テナント管理（t-admin）

### 画面実装

- `/t-admin/users/page.tsx`:
  - `auth.getUser()` → `user_tenants` で tenantId 取得。
  - `user_roles` + `roles(role_key)` で `tenant_admin` ロールを確認し、
    一般ユーザなら `/home` へリダイレクト。
  - service_role クライアントで `tenants.tenant_name` を取得し、画面コンポーネントに渡す。

- `TenantAdminUserManagement`:
  - `/api/t-admin/users` に対する GET / POST / PUT / DELETE をラップ。
  - クライアント側で
    - 必須項目バリデーション
    - 編集時の Dirty チェック
    - メール存在チェック（`/api/t-admin/users/check-email`）
    - 検索・ソート・ページング
    - 削除確認モーダル
    を行っており、管理画面としての UX は問題なし。

### /api/t-admin/users

- GET:
  - ログイン + tenant_admin 確認後、service_role クライアントで
    - `users.tenant_id = tenantId` のユーザ一覧を取得。
  - Supabase 通常クライアントで `user_roles` を読み、role_key を付与。

- POST / PUT / DELETE:
  - すべて `user_tenants.tenant_id = tenantId` で対象ユーザをスコープし、他テナントユーザへの誤操作を防止。
  - auth.users と public.users の同期ロジックも丁寧に実装されており、
    メールアドレス／表示名変更時には auth 側も更新される。
  - 最後のテナントから抜ける場合は、`public.users` と `auth.users` も削除する挙動になっている。

### 評価・改善ポイント

- 権限チェックはすべて API 側で行っており、フロントからの想定外リクエストに対しても安全な設計。
- service_role クライアントが
  - 共通の `createSupabaseServiceRoleClient`
  - `app/api/t-admin/users/route.ts` 内の `supabaseAdmin`
  の 2 系統に分かれている点は、将来的に一元化するとメンテ性が向上する（現時点では動作上の問題はなし）。

---

## 7. テーブル設計の妥当性（この範囲で使用している部分）

### 良い点

- **認証とアプリユーザの分離**
  - Supabase auth.users と public.users を分け、トリガや t-admin API で同期する構成は一般的で、安全なパターン。

- **テナント分離**
  - テナント依存テーブル（users, user_tenants, board_*, tenant_settings, moderation_logs, notifications 等）はすべて `tenant_id` を持ち、
    Prisma レイヤでも `tenant_id` 条件を必ず付与している。

- **権限モデル**
  - `user_roles` + `roles` + `role_scope`（system_admin / tenant_admin / general_user）で柔軟なロール設計が可能。
  - board 関連の権限もこのロールモデルを参照しており、一貫性がある。

- **掲示板スキーマ**
  - posts / comments / reactions / attachments / translations / favorites / approval_logs が正規化されており、
    将来の機能拡張にも耐えられる構成。

### 注意・割り切りポイント

- 現在は「1ユーザ=1テナント」だが、`user_tenants` で所属関係を別管理している。
  - 通知系カラム（`board_last_seen_at`）や将来のマルチテナント対応を見据えた設計であり、
    一般的にも許容される構造。
- `board_posts.author_role` / `board_author_role` enum は定義済みだが、
  フロント～API 間のパラメータ連携がまだ不完全で、
  一部の権限仕様（管理組合投稿の扱い）にまだ十分反映されていない。

---

## 8. 総評と推奨アクション

### 総評

- 認証・テナント認可・RLS／service_role の使い分けは全体的に良く設計されており、
  セキュリティ面で大きな懸念は見当たらない。
- 掲示板機能は
  - 多言語表示（翻訳キャッシュ）
  - AI モデレーション
  - 添付ファイル管理
  - 通知との連携
  まで含めて、実装品質は高い。
- t-admin ユーザ管理も auth.users と public.users の整合性を意識した実装になっており、
  業務システムとして十分なレベルにある。

### すぐに検討したい改善候補

1. **BoardPostForm ↔ POST /api/board/posts のロール連携**
   - `posterType` から `author_role` を正しく決定し、DB に反映させる。
   - 併せて GET `/api/board/posts` / `getBoardPostById` の DTO に `authorDisplayType` を正しく反映し、
     UI で「管理組合投稿」を区別できるようにする。

2. **service_role クライアントの一本化**
   - `createSupabaseServiceRoleClient` を t-admin API などでも利用する形に揃え、
     service_role の初期化ロジックを一元管理する。

3. **ログに含まれるメールアドレス等の扱い方針の明確化**
   - ログ出力自体は開発途上では有用だが、本番運用時の
     - ログの保存期間
     - 閲覧権限
     - マスキング／匿名化
     についてポリシーを定めると安心。

上記はいずれも構造全体を壊さない範囲の改善であり、
現行実装はそのままでも十分に運用可能な品質になっていると評価できます。
