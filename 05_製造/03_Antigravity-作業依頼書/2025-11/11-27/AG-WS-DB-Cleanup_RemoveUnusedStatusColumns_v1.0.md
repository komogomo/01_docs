# AG DB Cleanup 作業指示書 - users / user_tenants / tenants カラム削除 v1.0

## 1. 目的

HarmoNet 現行実装は、ログイン〜Home〜掲示板までが開発済みであり、その他機能は未実装です。

本指示書では、**現時点で不要と判断されたカラム**について、

* Prisma schema / DB からの削除
* それに伴う TypeScript コードの修正

を行い、ユーザ／テナント所属モデルをシンプルかつ要件に沿った形に整理することを目的とします。

> 重要: HarmoNet では「一時停止／復活」「論理削除」「過去住民履歴」は扱いません。退去・退会・削除が必要な場合は **行削除（ハード delete）** で対応する前提です。

---

## 2. 対象テーブルと削除対象カラム

### 2.1 tenants

**削除対象カラム**

* `tenants.is_active : Boolean`
  → `status : status`（`active / inactive / archived`）と完全重複しており、実装からも参照されていません。

**残すカラム（例）**

* `id` / `tenant_code` / `tenant_name` / `timezone` / `status` / `created_at` / `updated_at` など

> テナント件数は当面 1〜数十件規模を想定しており、履歴や複雑な状態管理は行いません。`status` のみで十分です。

---

### 2.2 users

**削除対象カラム**

* `users.status : status`

  * 現在はログイン時に `status = 'active'` でフィルタする用途でのみ使用されていますが、
  * HarmoNet では「一時停止して復活させる」運用は行わず、不要となります。
  * アカウント削除が必要な場合は、レコード DELETE で対応します。

**残すカラム（例）**

* `id` : Supabase `auth.users.id` と一致
* `email` : ログイン用メールアドレス
* `display_name` : 掲示板等での表示名
* `language` : 利用申請書で指定されたベース言語（言語切替ボタンのデフォルト）
* `tenant_id` : 「最後に利用したテナント」のキャッシュ用途（将来見直しの可能性あり）
* `created_at` / `updated_at`

---

### 2.3 user_tenants

**削除対象カラム**

* `user_tenants.status : status`

  * 現状は `status = 'active'` で所属テナントを決定するために使用していますが、
  * 退去・解約時に「いつか復活させる」運用は行わないため、

    * 所属 = レコードが存在する／非所属 = レコードが存在しない
      というルールに統一します。
* `user_tenants.joined_at : DateTime`

  * 現行コードから一切参照されておらず、要件も存在しません。
  * 将来の履歴用途も採用しない前提のため削除します。

**残すカラム**

* `user_id` : `users.id`
* `tenant_id` : `tenants.id`
* `board_last_seen_at : DateTime?`

  * 掲示板未読バッジ／通知の判定に使用中です（`api/board/notifications/*`）。

> `board_last_seen_at` は **既に実装で使用している有用カラム** のため、そのまま残します。

---

## 3. 仕様上の前提（重要）

1. **一時停止・復活はしない**

   * NETFLIX 型の「一時利用停止」「復活」は扱いません。
   * 退去・解約・削除は、必要なテーブルのレコード DELETE で対応します。

2. **過去住民の履歴・audit を持たない**

   * 「以前この部屋に誰が住んでいたか」「いつ退去したか」といった履歴は保存しません。
   * 退去時点で現行データからは削除される前提です。

3. **boards 以外の機能はまだ存在しない**

   * 現行実装はログイン〜Home〜掲示板のみです。
   * 今のタイミングでカラム削除とコード修正を行っても、他機能への影響はありません。

4. **Prisma Migrate（migration ファイル）は使用しない**

   * HarmoNet では Prisma の migration 機能は運用していません。
   * スキーマ変更は以下の手順で行ってください：

     1. `schema.prisma` を直接編集
     2. `npx prisma db push` で DB に反映
   * 追加で手書き SQL や Supabase Studio でのカラム削除を行う場合は、実際に実行したコマンド・SQL をレポートに残してください。

---

## 4. 具体的な作業内容

### 4.1 Prisma schema.prisma の修正

1. `tenants` モデルから `is_active` を削除
2. `users` モデルから `status` を削除
3. `user_tenants` モデルから `status` / `joined_at` を削除
4. `user_tenants` の `@@id([user_id, tenant_id])` はそのまま維持

修正後は、`npx prisma validate` でスキーマが正しいことを確認してください。

### 4.2 DB 反映

1. ローカル開発環境（Docker Supabase）の HarmoNet プロジェクトに対して、

   ```bash
   cd D:/Projects/HarmoNet
   npx prisma db push
   ```

2. もし `db push` でカラム削除が反映されない場合は、

   * Supabase Studio から対象カラムを手動で DROP し、
   * 再度 `prisma db push` を実行し、Prisma モデルと実DBの整合を取ってください。

> 繰り返しになりますが、**Prisma Migrate の migration ファイルは作成しないでください**。

---

## 5. TypeScript / アプリコードの修正方針

### 5.1 users.status 依存ロジックの削除

* 認証コールバック (`/auth/callback` など) や API で、

  * `users.status = 'active'` を条件にしている箇所をすべて削除してください。
* 今後は、

  * `users` レコードが存在するかどうか
  * Supabase Auth の `user` が取得できるかどうか
    でログイン可否を判断します。

### 5.2 user_tenants.status 依存ロジックの修正

* テナント所属判定に `status = 'active'` を使っている箇所をすべて修正してください。

  * 例: `where: { user_id, status: 'active' }` → `where: { user_id }`
* 退去・削除運用は、今後 `user_tenants` レコード削除で統一します。

### 5.3 joined_at の参照削除

* `.ts` / `.tsx` / `.sql` などで `joined_at` を参照している箇所があれば、すべて削除してください。

  * AG-INV02 の結果では参照がない前提ですが、念のため再確認をお願いします。

### 5.4 board_last_seen_at はそのまま維持

* `board_last_seen_at` は掲示板未読バッジに使用中のため、現行実装を維持してください。
* 仕様としては「掲示板を最後に見た時刻」として、`mark-seen` / `has-unread` API で利用を継続します。

---

## 6. 完了条件

1. `schema.prisma` から対象カラムが削除されていること
2. ローカル DB からも対象カラムが削除されていること
3. `npm run lint` / `npm run typecheck` / `npm run test`（存在する範囲）でエラーが出ないこと
4. ログイン〜Home〜掲示板の一連の動作が、削除前と同じように行えること

   * ログイン
   * Home 表示
   * 掲示板一覧表示（カテゴリフィルタ含む）
   * 掲示板詳細表示

作業完了後、簡単なレポート（実施した変更ファイル一覧・実行コマンド・気づきなど）を返してください。
