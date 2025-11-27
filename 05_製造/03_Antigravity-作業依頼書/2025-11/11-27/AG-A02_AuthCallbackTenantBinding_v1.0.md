
---

## 指示① Auth Callback のテナント判定＋テナント状態チェック実装

### 対象

* ファイル: `app/auth/callback/route.ts`
* 仕様ソース: `Auth-Callback Handler-detail-design_v1.1.md`

### やること

1. Supabase Auth から `auth.users.id`（JWT `sub`）を取得する。
2. `public.users` でアプリユーザを取得。
3. `user_tenants` から、そのユーザに紐づくテナントを取得する。

   * 1ユーザ複数テナントがありうる場合の扱いは、設計書に従う（なければ現段階は「1件前提」）。
4. 特定した `tenant_id` を使って、`tenants` を 1 件読み込む。
5. **ここでテナント状態チェックを行う（必須）**:

   * 条件: `tenants.status = 'active'`
   * active 以外（inactive / deleted など）の場合：

     * ログイン処理は失敗扱いにする。
     * クライアントには「このテナントは現在ご利用いただけません」的なエラーを返す（文言は共通エラー方針に合わせる）。
6. `tenants.status = 'active'` の場合のみ、

   * セッション／JWT に `tenant_id`（必要に応じて `tenant_code` も）を含めて、正常にログイン完了とする。

### 完了チェック

* 有効テナントのユーザ：

  * MagicLink ログイン → 正常に HOME へ進める。
  * セッション内で `tenant_id` が取得できる。
* 無効テナント（`tenants.status != 'active'`）のユーザ：

  * MagicLink から戻ってきても、HOME には進めず、エラー扱いになる。
  * Supabase Studio 側で `status` を inactive に変えて再ログイン → ブロックされること。

---

## 指示② t-admin ユーザ登録（/t-admin/users）実装

※ tenants.status は「ログイン可否」「画面入口」で見るので、ここでは **「active テナントであることが前提」** の画面として実装します。

### 対象

* 画面: `/t-admin/users`（user-regist）
* API: `GET /api/t-admin/users`, `POST /api/t-admin/users`

### やること

1. 画面 `/t-admin/users`

   * 左: t-admin メニュー。
   * 右:

     * 上部: テナント情報表示

       * `tenant_admin`: セッションの `tenant_id` に紐づく `tenant_code + tenant_name` を表示（status = active 前提）。
       * `system_admin`: `status = 'active'` のテナントだけを候補にしたプルダウン＋選択中テナントのコード／名称表示。
     * 中央: 登録フォーム

       * 氏名 / ふりがな / ニックネーム / メールアドレス / グループID / 住居番号 / ロール
     * 下部: 同一テナントの登録済みユーザ一覧。

2. `POST /api/t-admin/users`

   * 権限チェック:

     * `system_admin` または `tenant_admin` 以外 → 403。
   * テナント決定:

     * `tenant_admin`: セッションの `tenant_id`。
     * `system_admin`: リクエストの `tenantId`（フォームのテナント選択結果）。
   * **テナント状態チェック（必須）**:

     * 決定した `tenant_id` で `tenants` を読み、`status = 'active'` であることを確認。
     * active 以外なら 400/403 で「このテナントには現在ユーザ登録できません。」と返す。
   * そのうえで、users / user_tenants / tenant_residents / user_roles を、詳細設計通りに更新する。

3. `GET /api/t-admin/users`

   * テナント決定ロジックは `POST` と同様。
   * 決定した `tenant_id` について `tenants.status = 'active'` を確認する。
   * active 以外なら一覧を返さずエラー返却とする。
   * active の場合のみ、user_tenants を基点に一覧 JSON を返す。

### 完了チェック

* `tenant_admin` で、active テナントに対して正常に登録・一覧が動く。
* `system_admin` で、プルダウンから inactive テナントを選ぼうとしても：

  * そもそも候補に出ない、または選択時にエラーになる（どちらかで「status = active 以外は扱えない」ことが保証される）。
* Supabase で `tenants.status` を inactive に変えたテナントで：

  * `/t-admin/users` にアクセス → 入口時点でエラー／ブロックされる（ログイン時に弾けているのがベスト）。

---

こういう形で、「テナント無効チェック」を**最初から必須仕様として組み込んだ指示**にします。
「別タスク」「あとで」はもう使いません。
