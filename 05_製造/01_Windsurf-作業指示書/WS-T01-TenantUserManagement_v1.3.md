# WS-T01_TenantUserManagement_v1.3

## 0. メタ情報

* Task 名: テナント管理者用ユーザ登録画面（/t-admin/users） 氏名分割＋班長ロール対応
* Screen / Component ID: T-01 TenantUserManagement
* 対象ファイル（例）

  * `src/app/(tenant)/t-admin/users/page.tsx`
  * `src/app/api/t-admin/users/route.ts`（または分割された handler ファイル）
  * `src/components/t-admin/UserForm.tsx`
  * `src/components/t-admin/UserList.tsx`
  * `src/lib/api/tAdminUsersApi.ts`（存在していれば）
* 参照ドキュメント（必読）

  * `D:\AIDriven\01_docs\04_詳細設計\99_管理者画面\01_t-admin-user-regist_detail_ch01_v1.3.md`
  * `D:\AIDriven\01_docs\02_技術スタック/harmonet-technical-stack-definition_v4.5.md`
  * `D:\AIDriven\01_docs\03_基本設計\05_データベース設計/HarmoNet-DB-Basic-Design_v2.0.md`
  * `prisma/schema.prisma`（users モデルの latest）
* CodeAgent_Report 保存先

  * `/01_docs/06_品質チェック/CodeAgent_Report_T01_TenantUserManagement_v1.3.md`

> 重要: 本タスクは **既存の /t-admin/users 画面と API を、設計書 v1.3 に合わせて改修する** ためのものです。画面仕様や API 仕様を勝手に簡略化・改変せず、差分を正確に反映すること。

---

## 1. ゴール・スコープ

### 1.1 ゴール

1. 画面の氏名項目を `fullName / fullNameKana` から

   * 「性」「名」「性：ふりがな」「名：ふりがな」
     の 4 項目に分割し、`users.last_name / first_name / last_name_kana / first_name_kana` と正しく連携させる。
2. 一覧テーブルの「氏名」「ふりがな」列を、上記 4 カラムから組み立てて表示するように改修する。
3. ロール選択肢に `group_leader`（班長）を追加し、`roles.role_key = 'group_leader'` / `user_roles` に正しく保存する。
4. `/api/t-admin/users` 系 API（一覧取得 / 登録 / 更新）の I/O を設計書 v1.3 に合わせて更新する。
5. 既存のユーザ管理画面の挙動（検索・ページネーション・削除ロジックなど）は壊さない。

### 1.2 スコープ

* 対象

  * `/t-admin/users` 画面 UI（フォーム + 一覧）
  * `/api/t-admin/users` ハンドラ（GET / POST / PUT）
* スコープ外

  * `/t-admin` 以外の画面（清掃当番管理簿など）は別 WS で実装済み。
  * DB スキーマ変更は完了済み（`users` に姓・名カラムが存在する前提）。

---

## 2. 前提・共通ルール

1. 設計書遵守

   * 仕様は `/01_docs/04_詳細設計/01_ログイン画面/01_t-admin-user-regist_detail_ch01_v1.3.md` に従う。
   * 仕様の穴を勝手に補完せず、必要ならコメント `// TODO:` を残す。

2. 技術スタック

   * Next.js 16 / React / TypeScript / App Router。
   * Tailwind CSS 4。
   * Supabase クライアントは既存ラッパを利用する。

3. i18n

   * ラベル・ボタン名・メッセージは DB ベースの i18n から取得する。
   * 新しい文言キーが必要な場合は、設計書のキー方針に合わせて仮キーをコメントで提案するが、ハードコード日本語は置かない。

4. 認証・認可

   * `/t-admin/users` は `tenant_admin` ロールのみアクセス可（既存ガードを利用）。
   * 本タスクでガード仕様を変えない。

---

## 3. UI 改修内容

### 3.1 フォーム（SEC-02）

#### 3.1.1 項目構成

現状の `氏名` / `氏名(かな)` 入力欄を、以下 4 項目に分割する。

1. メールアドレス（既存そのまま）
2. 性（lastName）
3. 名（firstName）
4. 性：ふりがな（lastNameKana）
5. 名：ふりがな（firstNameKana）
6. ニックネーム（displayName）
7. グループID（groupCode）
8. 住居番号（residenceCode）
9. ロール（roleKey）
10. 言語（language）

フォームのレイアウトは、Excel テンプレートどおりの 2 カラム構成（性と名を左右に並べる）に合わせる。既存の tailwind クラスがある場合はそれを流用する。

#### 3.1.2 バリデーション

* 必須: email / lastName / firstName / lastNameKana / firstNameKana / displayName / roleKey。
* 任意: groupCode / residenceCode / language（未指定時は `ja`）。
* 形式チェック

  * email: 既存の email バリデーションロジックを継続使用。
  * ふりがな: 既存で `fullNameKana` に対して定義していたルール（ひらがなのみ 等）があれば、それを `lastNameKana` / `firstNameKana` に分けて適用。

### 3.2 一覧テーブル（SEC-03）

#### 3.2.1 列表示

* 氏名列:

  * 表示値: `{lastName} + ' ' + {firstName}`。
  * DTO に `fullName` を追加する場合でも、組み立て元は `lastName` / `firstName`。

* ふりがな列:

  * 表示値: `{lastNameKana} + ' ' + {firstNameKana}`。

* ロール列:

  * `tenant_admin` / `general_user` / `group_leader` を、既存のラベル方式に従って表示（例: システム管理者 / 一般利用者 / 班長）。

#### 3.2.2 検索

* キーワード検索は、既存の対象に加えて、姓・名・ふりがな分割にも対応する。

  * 検索対象: email / displayName / lastName / firstName / lastNameKana / firstNameKana / groupCode / residenceCode。

---

## 4. API 改修内容

### 4.1 `/api/t-admin/users` GET（一覧）

1. 現状のクエリロジック（tenant_id で絞り `user_tenants` 経由で JOIN）を維持。
2. SELECT カラムを `users.last_name / first_name / last_name_kana / first_name_kana` を含む形に更新。
3. レスポンス DTO を以下にする（型定義も合わせて更新）。

```ts
type TAdminUser = {
  userId: string;
  email: string;
  displayName: string;
  lastName: string;
  firstName: string;
  lastNameKana: string;
  firstNameKana: string;
  groupCode: string | null;
  residenceCode: string | null;
  roleKey: 'tenant_admin' | 'general_user' | 'group_leader';
  language: 'ja' | 'en' | 'zh';
};
```

4. フロントの一覧描画ロジックで、氏名・ふりがな列を DTO から組み立てる。

### 4.2 `/api/t-admin/users` POST（登録）

1. リクエストボディの型を以下に変更。

```ts
type TAdminUserCreateRequest = {
  email: string;
  lastName: string;
  firstName: string;
  lastNameKana: string;
  firstNameKana: string;
  displayName: string;
  groupCode?: string | null;
  residenceCode?: string | null;
  roleKey: 'tenant_admin' | 'general_user' | 'group_leader';
  language?: 'ja' | 'en' | 'zh';
};
```

2. `users` テーブルへの保存は、以下のマッピングにする。

* `last_name  = lastName`
* `first_name = firstName`
* `last_name_kana  = lastNameKana`
* `first_name_kana = firstNameKana`

3. `user_roles` 登録時に、`roleKey = 'group_leader'` のケースを追加し、`roles.role_key = 'group_leader'` を正しく参照する。

4. 既存の email / displayName 一意性チェックロジックはそのまま維持する。

### 4.3 `/api/t-admin/users` PUT（更新）

1. リクエストボディの型定義を POST と同様に分割。`userId` を含める。

```ts
type TAdminUserUpdateRequest = {
  userId: string;
  email: string;
  lastName: string;
  firstName: string;
  lastNameKana: string;
  firstNameKana: string;
  displayName: string;
  groupCode?: string | null;
  residenceCode?: string | null;
  roleKey: 'tenant_admin' | 'general_user' | 'group_leader';
  language?: 'ja' | 'en' | 'zh';
};
```

2. `users` 更新時に、上記 4 フィールドを更新対象に含める。
3. `user_roles` 更新時に、既存ロールをクリアしてから新しい 1 つを設定する現行仕様を維持しつつ、`group_leader` ケースを追加。

### 4.4 その他の API

* 削除 API / メールアドレス存在チェック API の仕様は変更しない。ただし型定義に `lastName*` などを載せていないか確認し、`fullName` を参照している箇所があれば削除する。

---

## 5. 実装上の注意点

1. DB スキーマとの整合

   * Supabase Studio で `users` の定義が `first_name / last_name` NOT NULL かつ `*_kana` NULL であることを前提とする。
   * Prisma Client の型が同じ前提になっているか確認する（生成済み）。

2. UI の互換性

   * 既存のコンポーネント構造を大きく変えず、入力欄の分割として実装する。
   * 既に存在するテストユーザのデータ表示が崩れないことを確認する（氏名・ふりがな列）。

3. ログ

   * 既存のログ出力があれば、フィールド名の変更により壊れていないか確認する。

---

## 6. 自己チェック項目（Windsurf 用）

実装完了後、以下をブラウザ＋Supabase Studio で確認すること。

1. `/t-admin/users` を開くと、フォームに「性／名／性：ふりがな／名：ふりがな」の4項目が表示される。
2. 必須項目を空にして登録しようとすると、適切なエラーメッセージが表示される。
3. ユーザを新規登録すると、`users` テーブルの `last_name / first_name / last_name_kana / first_name_kana` に値が入り、一覧にも正しく表示される。
4. 既存ユーザを編集しても、氏名とふりがなが正しく更新される。
5. ロール選択肢に `班長`（group_leader）が追加されており、選択して登録すると `user_roles` に `role_key = 'group_leader'` が紐づく。
6. キーワード検索で、姓／名／ふりがなでヒットすることを確認する。
7. 既存の削除機能・メールアドレス存在チェックなど、v1.2 で動いていた機能がすべて動作する。

---

以上。
