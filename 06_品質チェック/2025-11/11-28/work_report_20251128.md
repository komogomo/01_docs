# 2025-11-28 作業レポート（掲示板通知・t-admin ユーザ管理周り）

## 1. 概要

本レポートでは、2025-11-28 の開発セッションにおいて実施した以下の作業内容を整理します。

- 掲示板一覧への「未読お知らせバッジ」の実装とロジック修正
- 通知 API（ベルアイコン）と掲示板一覧の未読判定ロジックの統一
- t-admin ユーザ管理 API の service_role クライアント統一と挙動修正
- t-admin ユーザ管理画面の UX 調整（更新ボタン挙動、一覧表示、言語・レイアウト調整）
- 翻訳／音声読み上げにおける中国語（簡体字）運用方針の明確化と実装反映

## 2. 前提・環境

- フロント／API: Next.js App Router（本番は Vercel デプロイ想定）
- 認証／DB／ストレージ: Supabase クラウド（本番）
- DB アクセス: Prisma（server side）、Supabase JS Client（RLS 前提）
- ログ: アプリ側では `logInfo` / `logError` による構造化ログを標準出力に出力
  - 本番では Vercel / Supabase のログ・監査で十分とし、アプリ側での独自ファイル出力や監査ログ蓄積は行わない方針

## 3. 掲示板「未読お知らせバッジ」実装・修正

### 3-1. 仕様整理

**目的**

- ヘッダのベルアイコンが示す「未読お知らせ」と同じ基準で、掲示板一覧に視覚的なバッジを表示する。
- 管理組合からの投稿（管理組合として投稿されたもの）のみを通知対象とし、一般利用者として投稿されたものは通知対象外とする。

**通知対象（お知らせ）となる投稿の条件**

- `board_posts.status = 'published'`
- `board_posts.author_role = 'management'`（管理組合として投稿）
  - これはフォーム側の「投稿者区分」と `authorRole` パラメータにより、
    - 管理組合として投稿 → `author_role = 'management'`
    - 一般利用者として投稿 → `author_role = 'general'`
    として保存される。

**未読判定ロジック**

- `user_tenants.board_last_seen_at` を使用
  - 「最後に管理組合として投稿されたお知らせの詳細画面を閲覧した日時」を保持
- 未読の有無
  - `board_last_seen_at` が `NULL` → 未読あり
  - それ以外 → テナント内の管理組合投稿の最新 `created_at` が `board_last_seen_at` より新しいかどうかで判定
- 一覧上のバッジ
  - 各投稿ごとに `post.created_at > board_last_seen_at` かつ `author_role = 'management'` の場合にバッジを表示
  - これにより、ベルアイコンと一覧バッジが同じ条件で動作する。

**既読化のタイミング**

- `POST /api/board/notifications/mark-seen` が呼ばれた際に対象投稿の `created_at` を基準に `board_last_seen_at` を更新
  - 原則として「その投稿の `created_at` までの管理組合投稿を既読とみなす」挙動
  - 最新のお知らせを先に閲覧すると、それ以前の未読も一括で既読扱いになる仕様

### 3-2. API 側の実装変更

#### (1) `GET /api/board/posts` の拡張

対象ファイル: `app/api/board/posts/route.ts`

**追加した DTO フィールド**

- `BoardPostSummaryDto` に以下を追加:
  - `isManagementNotice: boolean`  … 管理組合として投稿された記事かどうか
  - `isUnreadNotice: boolean`      … 上記かつ `board_last_seen_at` より新しいかどうか

**処理フローの主な変更点**

1. `user_tenants.board_last_seen_at` の取得
   - `user_id` / `tenant_id` の複合キーで `user_tenants` を参照し、`board_last_seen_at` を取得。
   - 取得失敗時はログのみ出力し、未読判定では `NULL` と同様に扱う（= 全件未読扱い）。

2. 管理組合投稿判定
   - 以前は「著者ユーザが `tenant_admin` ロールを持つかどうか」を `user_roles` 経由で判定していたが、
     これは「管理組合ロールを持っているが『一般利用者として投稿』したケース」でも通知対象になってしまう。
   - 修正後は **`board_posts.author_role === 'management'` を直接参照** して判定:
     - `isManagementNotice = (post.author_role === 'management')`

3. 未読判定
   - `isUnreadNotice = isManagementNotice && (!boardLastSeenAt || post.created_at > boardLastSeenAt)`
   - これを一覧 DTO に含めてフロントへ返却。

#### (2) 通知 API のロジック統一

対象ファイル:

- `app/api/board/notifications/has-unread/route.ts`
- `app/api/board/notifications/mark-seen/route.ts`

**`has-unread`**

- 変更前: 「著者が tenant_admin ロールを持つ投稿」を `author.user_roles` 経由で判定
- 変更後: `board_posts.author_role = 'management'` のみを対象に最新投稿を検索
  - `where: { tenant_id, status: 'published', author_role: 'management' }`
  - それ以外のロジック（`board_last_seen_at` との比較）は従来どおり

**`mark-seen`**

- 変更前: `postId` に対応する投稿が「著者が tenant_admin」の場合のみ `board_last_seen_at` を更新
- 変更後: `postId` に対応する投稿が `author_role = 'management'` かどうかで判定
  - `where: { id: postId, tenant_id, status: 'published', author_role: 'management' }`
  - 管理組合として投稿されていない記事を閲覧しても `board_last_seen_at` は更新されない。

### 3-3. フロント側（掲示板一覧・カード）の実装変更

対象ファイル:

- `src/components/board/BoardTop/BoardTopPage.tsx`
- `src/components/board/BoardTop/BoardTopPage.types.ts`（`BoardPostSummary`）
- `src/components/board/BoardTop/BoardPostSummaryCard.tsx`

**`BoardPostSummary` 型の拡張**

- `isManagementNotice: boolean`
- `isUnreadNotice: boolean`

**API からの受け取りとマッピング**

- `BoardTopPage.tsx` 内で、API から受け取った `isManagementNotice` / `isUnreadNotice` をそのまま boolean 化し、`BoardPostSummary` に渡すように変更。

**カード上のバッジ表示**

- `BoardPostSummaryCard.tsx` のカテゴリと日時を表示している行において、
  - `post.isUnreadNotice` が `true` の場合のみ、日時の左側に小さな丸型バッジ（`!`）を表示
  - 既読になった管理組合投稿では `isUnreadNotice` が `false` になるため、バッジは表示されない

**ユーザ観点の動作**

- 一般利用者としてログインした場合:
  - 管理組合として投稿された最新の記事が存在し、`board_last_seen_at` より新しい場合 → ベルアイコンにバッジ + 一覧で対象記事の日時左に `!` 表示
  - 対象記事の詳細を開く → `mark-seen` により `board_last_seen_at` 更新 → 一覧に戻ると `!` が消える
- 管理組合ロールを持つユーザが「一般利用者として投稿」した記事は、
  - `author_role = 'general'` となるため、ベルアイコン／一覧いずれのバッジも点灯しない。

## 4. t-admin ユーザ管理 API の修正

### 4-1. service_role クライアントの統一

対象ファイル:

- `app/api/t-admin/users/route.ts`
- `app/api/t-admin/users/check-email/route.ts`

**変更内容**

- これまでは `@supabase/supabase-js` の `createClient` を各 API 内で直接呼び出し、service_role キーを埋め込んでいました。
- 今回、他の箇所と同様に
  - `src/lib/supabaseServiceRoleClient.ts` の `createSupabaseServiceRoleClient()` を利用する形に統一。
- メリット:
  - service_role クライアントの初期化ロジックが 1 箇所に集約され、
    - URL やキーの変更
    - auth 設定（`persistSession: false` など）の見直し
    が容易になる。
  - セキュリティ上も "どこで service_role を使っているか" が明確になる。

### 4-2. ユーザ新規登録時のロール重複エラーの扱い

**現象**

- `POST /api/t-admin/users` で新規ユーザ作成時に、`user_roles` へ INSERT した際、以下のエラーが発生することがあった:

```text
Key (user_id, tenant_id, role_id)=... already exists.
duplicate key value violates unique constraint "user_roles_user_id_tenant_id_role_id_key"
```

- これは、既に同じ `(user_id, tenant_id, role_id)` の組み合わせが存在しているケースであり、本質的には「ロールは既に付与済み」であることを意味する。
- にもかかわらず、API は 500 を返し、フロントでは「ロール設定に失敗しました。」と表示されていた。

**対応**

- `user_roles` への INSERT 結果のエラーコードを判定し、
  - `code === '23505'`（重複キー）であれば **成功扱い（既にロール付与済み）** とみなして処理続行
  - それ以外のエラーのみ 500 + エラーメッセージを返す

```ts
if (userRolesError) {
  const isDuplicateKeyError =
    typeof (userRolesError as any).code === 'string' &&
    (userRolesError as any).code === '23505';

  if (!isDuplicateKeyError) {
    // 本当のエラーのみログ＋500
  }
}
```

- これにより、既にロールが存在する場合でもユーザ登録処理全体は正常終了し、フロント上は「ユーザを登録しました。」と表示されるようになった。

### 4-3. ユーザ更新時のロール変更

対象: `PUT /api/t-admin/users`

- 既存実装では以下の流れになっており、今回ロジック上の問題はなかったが、挙動確認を実施。

1. `roles` テーブルから `role_key` に対応する `id` を取得
2. 現在の `user_roles` を `supabaseAdmin` で取得し、`role_id` が異なる場合のみ更新
   - 既存ロール削除 → 新ロールINSERT
3. 同時に `users` テーブルのプロフィール情報（メール、表示名、氏名など）を更新
4. 必要に応じて `auth.admin.updateUserById` で `auth.users` 側も更新

- 実際の動作として:
  - 「一般ユーザ → テナント管理者」等のロール変更を行い、一覧表示で反映されることを確認
  - 一覧側のロール取得は、後述の修正により service_role 経由で `user_roles` を参照するよう統一済み。

### 4-4. ユーザ一覧取得時のロール参照方法修正

対象: `GET /api/t-admin/users`

**修正前**

- ユーザ一覧は以下の 2 段階で構成されていた:
  1. `users` テーブルから、対象テナントのユーザを取得（`supabaseAdmin`）
  2. 取得した `userIds` に対して `user_roles` テーブルを `supabase`（RLS あり）で参照
- このとき、RLS の制約により、tenant_admin であっても他ユーザの `user_roles` が正しく取得できず、
  - 一覧上ではロールが `general_user` にフォールバックされるケースがあった。

**修正後**

- `user_roles` も `supabaseAdmin`（service_role）で取得するよう変更:

```ts
const { data: rolesData } = await supabaseAdmin
  .from('user_roles')
  .select('user_id, roles(role_key)')
  .eq('tenant_id', tenantId)
  .in('user_id', userIds);
```

- これにより、t-admin 画面の一覧表示が、実際の `user_roles` の状態と正しく一致するようになった。

## 5. t-admin ユーザ管理画面（UI）の調整

対象ファイル:

- `src/components/t-admin/TenantAdminUserManagement/TenantAdminUserManagement.tsx`
- `src/components/t-admin/TenantAdminUserManagement/TenantAdminUserManagement.types.ts`

### 5-1. 更新ボタンの挙動（変更なし更新の禁止）

**現象**

- 一覧からユーザを選択 → 何も変更せずに「更新」ボタンを押すと、
  - フロント側では `isDirty()` が `false` のため即 return しており、
  - サーバ API も呼ばれない（ログにも `PUT /api/t-admin/users` が出ない）
- ただし UI 上はボタンが押せてしまうため、ユーザから見ると「押したのに何も起きない」ように見えていた。

**対応**

- 更新ボタンの `disabled` 条件と見た目を修正:

```ts
<button
  type="submit"
  onClick={(e) => handleSubmit(e, editingId ? 'update' : 'create')}
  disabled={editingId ? (!emailExists || isCheckingEmail || !isDirty()) : false}
  className={
    editingId
      ? (emailExists && !isCheckingEmail && isDirty())
        ? '... 有効スタイル ...'
        : '... 無効スタイル（グレーアウト） ...'
      : '... 新規登録時スタイル ...'
  }
>
  {editingId ? '更新' : 'ユーザ登録'}
</button>
```

- 結果:
  - 編集開始直後（まだフィールドを変更していない状態）では「更新」ボタンがグレーアウトされ、クリック不可
  - いずれかのフィールドを変更した時点でボタンが有効化される

### 5-2. 言語フィールドの取り扱い・表示

**フォーム上の表示**

- 言語選択セレクトボックスを以下のように統一:

```tsx
<select ...>
  <option value="ja">JA</option>
  <option value="en">EN</option>
  <option value="zh">ZH</option>
</select>
```

- DB には従来どおり `users.language` に `ja` / `en` / `zh` が保存される。

**一覧での表示**

- ユーザ一覧テーブルに「言語」列を追加し、`JA/EN/ZH` 表示を行うようにした。
  - `user.language` の値に応じて
    - `ja` → `JA`
    - `en` → `EN`
    - `zh` → `ZH`

### 5-3. 翻訳・TTS における中国語（簡体字）運用

対象ファイル:

- `src/server/services/translation/GoogleTranslationService.ts`
- `src/server/services/tts/GoogleTtsService.ts`
- `app/api/board/tts/route.ts`

**翻訳（Google Cloud Translation）**

- 内部表現: `SupportedLang = 'ja' | 'en' | 'zh'`
- Google 翻訳 API 呼び出し時に、`zh` を `zh-CN` に正規化して送信するよう変更:

```ts
const normalizeLangCode = (lang: SupportedLang): string => {
  if (lang === 'zh') {
    return 'zh-CN'; // 簡体字中国語
  }
  return lang;
};
```

- 言語検出 (`detectLanguageOnce`) の結果についても、`zh` / `zh-CN` / `zh-Hans` 等をすべて内部的に `zh` として扱うように補正。

**TTS（Google Cloud Text-to-Speech）**

- 既存実装:
  - `SupportedLang` から Google の言語コードへのマッピングで、`zh` を `cmn-CN`（標準中国語・中国本土）として扱っており、既に簡体字相当。
- 追加での変更は不要であり、翻訳側の `zh-CN` と意味的に揃う形になっている。

**TTS API 入口の言語マッピング**

- `/api/board/tts` では、クライアントから渡された言語コード（例: `ja-JP`, `en-US`, `zh-CN`）を `SupportedLang` に正規化している:

```ts
const mapLanguageToSupportedLang = (language?: string): SupportedLang => {
  if (!language) return 'ja';
  const lower = language.toLowerCase();
  if (lower.startsWith('en')) return 'en';
  if (lower.startsWith('zh')) return 'zh';
  return 'ja';
};
```

- これにより、翻訳／TTS ともに
  - アプリ内部: `ja/en/zh`
  - Google API 実体: `ja-JP / en-US / zh-CN（/ cmn-CN）`
 という整合した運用となった。

### 5-4. ユーザ一覧テーブルのレイアウト調整

**課題**

- もともとの実装では:
  - 見出しが折り返され、列ごとの幅バランスが悪い
  - 「編集」「削除」ボタンがカード右端からはみ出し・重なって見えることがある

**対応内容**

1. ヘッダセルに `whitespace-nowrap` を付与し、見出しの折り返しを防止。
2. 各列におおよその幅を割り当て、相対的なバランスを調整:
   - メールアドレス: やや広め
   - ニックネーム／氏名／ふりがな: 中程度
   - グループID／住居番号／言語／ロール: コンパクト（センタリング）
   - 操作列: 編集・削除が横並びで収まる程度に十分な幅
3. 行データ側では、幅を圧迫する長いテキスト（メールアドレス、ニックネーム、氏名、ふりがな）に対して
   - `max-w-[...]` および `truncate` を付与して省略表示
   - `title` 属性にフルテキストを設定し、マウスオーバーで全体が確認できるようにした
4. 操作列のセルは `whitespace-nowrap` と `flex space-x-2 justify-center` により、常に「編集」「削除」が横一列に見えるよう調整。

**結果**

- 一覧テーブルの横幅はカードの `max-w-5xl` 制約の中に収まりつつ、
  - ヘッダが見やすく、
  - 各列の情報が適切に省略／センタリングされ、
  - 操作ボタンがカード外にはみ出さない
 というレイアウトに改善された。

## 6. 確認済み動作と既知の仕様

### 6-1. 確認済み動作

- 管理組合ロールを持つユーザが:
  - 「管理組合として投稿」した記事 → ベル／一覧の未読バッジ対象
  - 「一般利用者として投稿」した記事 → 未読バッジ対象外
- 複数の管理組合投稿がある状態で、
  - 古い投稿から順に詳細を開いていった場合、`board_last_seen_at` の前後関係に応じて一覧バッジが順当に減っていくこと
  - 最新の投稿を先に閲覧した場合、それ以前の管理組合投稿もまとめて既読扱いになり、ベル・一覧双方のバッジが消えること
- t-admin ユーザ管理で:
  - 新規登録が 500 エラーを返さず動作すること（ロール重複があっても成功扱い）
  - 既存ユーザのロールを変更した際、一覧の「ロール」列に即反映されること
  - 編集開始直後は「更新」ボタンが無効、何らかの変更後に有効化されること
  - 一覧に「言語」列が追加され、フォームと同じ `JA/EN/ZH` の表記で表示されること
  - メールアドレス・ニックネーム等が長い場合でも、一覧では省略表示され、カード右端の「編集／削除」ボタンがはみ出さないこと

### 6-2. 既知の仕様（設計判断）

- 未読管理は **`board_last_seen_at` による「時刻ベース」** で行っており、
  - 「N件のうち1件だけ既読としてマークする」といった**投稿単位の既読管理**は行っていない。
  - そのため、最新投稿を閲覧した時点で、それ以前の管理組合投稿も既読扱いになるのは仕様どおりの挙動。
- 投稿単位での既読管理を行う場合は、
  - `user_id × post_id` 単位で既読を保持するテーブル追加など、DB設計レベルの変更が必要となるため、
  - 現段階では採用していない（将来の要望や運用状況を見て再検討）。
- ログファイル出力／独自監査ログについては、本番が Vercel + Supabase クラウドであることから、
  - 追加のファイルベースの監査仕組みは不要と判断。
  - 現状の構造化ログを標準出力に書き出す実装で問題ない方針とした。

## 7. 今後の検討候補

- 掲示板通知の UX 強化
  - 一覧上で「未読のみ」「管理組合のお知らせのみ」をフィルタする機能の追加
  - ベルアイコンから直接「未読お知らせ一覧」に飛べるショートカット
- t-admin 周り
  - 言語設定に応じた UI 文言の出し分け（多言語 t-admin）
  - 将来的な `tenant_settings` との連携による TTS／翻訳のきめ細かな設定（例: テナントごとの話速・音声の種類など）
- 既読管理の高度化
  - 要望があれば、`user_post_reads` のような中間テーブルを設計し、「投稿単位での既読・未読」を扱う仕組みを検討

以上が、2025-11-28 セッションにおける主な作業内容とその結果です。
