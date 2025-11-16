# HarmoNet DB PasskeyCredential 追加作業指示書 v1.0

## 1. 目的

本書は、HarmoNet の既存データベーススキーマ（schema.prisma / Supabase PostgreSQL）に対して、
`passkey_credentials` テーブルを安全に追加し、Prisma・Supabase 双方のマイグレーションと
RLS ポリシーを整合させるための **実行手順（作業指示）** を定義する。

対象環境は TKD ローカルの HarmoNet 開発環境とする。

---

## 2. 前提条件

* OS: Windows 11
* プロジェクトパス: `D:\Projects\HarmoNet`
* Supabase ローカル環境が起動済み（Docker コンテナ）
* Node.js / npm / Prisma / Supabase CLI がインストール済み
* 既に以下のマイグレーションが適用済みであること

  * `supabase/migrations/20251107000000_initial_schema.sql`
  * `supabase/migrations/20251107000001_enable_rls_policies.sql`
* `schema.prisma` に `passkey_credentials` モデルが追記済みであること
* 既存テーブルの `id` / `tenant_id` / `user_id` は TEXT 型で統一されていること

> 重要: 既存のマイグレーションファイル（20251107 日付）は **編集しない**。
> 追加の差分はすべて新しいマイグレーションとして作成する。

---

## 3. 変更概要

### 3.1 追加するテーブル

Prisma スキーマ上では、以下のモデルが新規追加されている前提とする。
（実際の定義は TKD 追記済みの schema.prisma を正とする）

```prisma
/// WebAuthn パスキーのクレデンシャル情報
model passkey_credentials {
  id             String    @id @default(cuid())
  user_id        String
  tenant_id      String
  credential_id  String    @unique
  public_key     String
  sign_count     Int       @default(0)
  transports     String[]
  device_name    String?
  platform       String?
  last_used_at   DateTime? @db.Timestamptz(6)
  created_at     DateTime  @default(now()) @db.Timestamptz(6)
  updated_at     DateTime  @updatedAt      @db.Timestamptz(6)

  // Relations
  user   users   @relation(fields: [user_id], references: [id], onDelete: Cascade)
  tenant tenants @relation(fields: [tenant_id], references: [id], onDelete: Cascade)

  @@index([user_id])
  @@index([tenant_id])
}
```

### 3.2 必要となる作業

1. Prisma スキーマ差分から **Prisma マイグレーション SQL** を作成（`--create-only`）
2. 生成された SQL をベースに、Supabase 用マイグレーションファイルを新規作成
3. 新規テーブル `passkey_credentials` 向けの RLS ポリシーを定義する SQL を作成
4. Supabase にマイグレーションを適用（開発環境では `db reset` で再構築）
5. Prisma Client 再生成 & 影響範囲の動作確認

---

## 4. 作業フロー（全体像）

```text
1. 作業ディレクトリへ移動
2. Prisma マイグレーション SQL を作成（create-only）
3. Supabase 用マイグレーションファイルを新規作成
4. RLS ポリシー SQL を追記
5. Supabase DB を再構築（db reset）
6. Prisma Client 再生成
7. Prisma Studio / psql でテーブル構造確認
```

---

## 5. 詳細手順

### Step 0: 作業ディレクトリの確認

```powershell
cd D:\Projects\HarmoNet
```

`package.json` や `prisma/schema.prisma` が存在することを確認する。

---

### Step 1: Prisma マイグレーション SQL を生成（create-only）

Prisma の差分から、DB にはまだ適用しない **SQL ファイルのみ** を生成する。

```powershell
npx prisma migrate dev --name add_passkey_credentials --create-only
```

* 期待結果: `prisma/migrations/<timestamp>_add_passkey_credentials/` ディレクトリが作成され、
  `migration.sql` が生成される。
* ここで DB 変更はまだ行われない（`--create-only` のため）。

> 備考: 既に他の差分が紛れ込んでいないか、migration.sql の内容を目視で確認する。
> `CREATE TABLE "passkey_credentials" ...` および関連する FK 定義のみが含まれていることが望ましい。

---

### Step 2: Supabase 用マイグレーションファイルを作成

HarmoNet 既存ルールに従い、Supabase 側にも SQL マイグレーションを追加する。

1. 新規ファイル名の例（TKD が実際のタイムスタンプを確定する）：

   * `supabase/migrations/20251114000000_add_passkey_credentials.sql`

2. `prisma/migrations/<timestamp>_add_passkey_credentials/migration.sql` の内容をベースに、
   新規ファイルへコピーする。

3. ファイル保存時は必ず **BOM なし UTF-8** で保存する。

   * これは初回構築時の教訓と同じ（Supabase が BOM 付き SQL を受け付けないため）。

> 既存の `20251107000000_initial_schema.sql` は絶対に編集しないこと。
> 今回の差分は「追加のマイグレーション」として扱う。

---

### Step 3: RLS ポリシー SQL の追加

`passkey_credentials` テーブルにも `tenant_id` ベースの RLS を適用する。
既存の `20251107000001_enable_rls_policies.sql` は編集せず、
**新しいマイグレーションファイルに RLS 定義を追加する** 方針とする。

1. 新規ファイル名の例：

   * `supabase/migrations/20251114000001_enable_rls_passkey_credentials.sql`

2. ファイル内容（例）：

```sql
-- passkey_credentials RLS 設定
ALTER TABLE passkey_credentials ENABLE ROW LEVEL SECURITY;

CREATE POLICY passkey_credentials_select ON passkey_credentials
  FOR SELECT USING (tenant_id::text = (auth.jwt() ->> 'tenant_id'));

CREATE POLICY passkey_credentials_insert ON passkey_credentials
  FOR INSERT WITH CHECK (tenant_id::text = (auth.jwt() ->> 'tenant_id'));

CREATE POLICY passkey_credentials_update ON passkey_credentials
  FOR UPDATE USING (tenant_id::text = (auth.jwt() ->> 'tenant_id'));

CREATE POLICY passkey_credentials_delete ON passkey_credentials
  FOR DELETE USING (tenant_id::text = (auth.jwt() ->> 'tenant_id'));
```

3. こちらも **BOM なし UTF-8** で保存する。

> ポリシー名は既存の命名規則（`<table>_<operation>`）に合わせている。
> テナント分離ポリシーは、他テーブルと同様に `tenant_id = auth.jwt()->>'tenant_id'` を前提とする。

---

### Step 4: Supabase DB 再構築（開発環境）

開発環境では、既存データは `seed.ts` から再投入可能であるため、
最も確実な方法として `db reset` で DB を再構築する。

```powershell
npx supabase db reset
```

* 期待結果:

  * 既存の初期スキーマ + 既存 RLS + 新規テーブル + Passkey 用 RLS がすべて適用される
  * エラーが出ないことを確認する

> もし reset ではなく差分適用のみとしたい場合は、`supabase migration up` で
> 新規 2 ファイル（add_passkey_credentials / enable_rls_passkey_credentials）
> が順に適用されることを確認する。

---

### Step 5: Prisma Client 再生成

DB スキーマに `passkey_credentials` が追加されたため、Prisma Client を再生成する。

```powershell
npx prisma generate
```

* 期待結果:

  * `node_modules/@prisma/client` が更新され、`prisma.passkey_credentials` が利用可能になる

---

### Step 6: テーブル構造・RLS の確認

#### 6.1 Prisma Studio で確認

```powershell
npx prisma studio
```

ブラウザで Prisma Studio を開き、`passkey_credentials` テーブルが一覧に表示されることを確認する。

#### 6.2 psql / Supabase Studio で確認（任意）

* `SELECT * FROM passkey_credentials LIMIT 1;` を実行し、テーブル自体が存在することだけ確認する
* RLS ポリシー一覧に `passkey_credentials_*` のポリシーが追加されていることを確認する

---

## 6. ロールバック方針（トラブル時）

開発環境で問題が発生した場合は、以下の手順でやり直す。

1. 新規作成した 2 つの Supabase マイグレーションファイルを一時的に退避（別ディレクトリへ移動）
2. `schema.prisma` から `passkey_credentials` モデルをコメントアウトまたは削除
3. `npx supabase db reset` を実行し、元の状態に戻す
4. 原因を調査した上で、本指示書に沿って再度マイグレーションを作成

---

## 7. メモ

* 本指示書では「既存マイグレーションの書き換え」は一切行わない。
* 以後の DB 変更も、同様に **差分マイグレーションを追加する方式** で統一する。
* Passkey 認証ロジック（A-01/A-02）は、`passkey_credentials` が存在する前提で
  Windsurf 実装指示書から参照されるため、この作業完了が前提条件となる。
