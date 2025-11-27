# AG-A02 AuthCallback Tenant Binding 追加指示書 v1.1（inactive 試験用）

* Parent: `AG-A02_AuthCallbackTenantBinding_v1.0.md`
* Purpose: **tenants.status = 'inactive' 時の動作確認のみ** を追加で実施すること。

---

## 1. 対象

* テーブル: `public.tenants`
* 対象テナントID: `ab3d5d5f-027b-4108-b6aa-2a31941d88eb`
* 対象ユーザ: `admin@gmail.com`（既に正常系ログイン確認済みのユーザ）

---

## 2. 手順（Docker + psql）

### 2.1 前提

PowerShell:

```powershell
cd D:\Projects\HarmoNet

docker ps --format "table {{.Names}}\t{{.Status}}"
# DB コンテナ名が supabase_db_HarmoNet であることを確認
```

以降のコマンドではコンテナ名を `supabase_db_HarmoNet` として記載する。

---

### 2.2 tenants.status を inactive に変更

```powershell
docker exec -it supabase_db_HarmoNet ^
  psql -U postgres -d postgres -c `
  "UPDATE public.tenants
     SET status = 'inactive'
   WHERE id = 'ab3d5d5f-027b-4108-b6aa-2a31941d88eb';"
```

---

### 2.3 動作確認

1. `admin@gmail.com` で MagicLink ログインを試行する。
2. 期待結果:

   * `/home` には遷移せず、`/login?error=unauthorized` にリダイレクトされること。
   * 同じブラウザセッションで `/home` や `/board` に直接アクセスしても、利用できないこと。
3. ブラウザのアドレスバーと画面表示を確認し、挙動を記録すること。

---

### 2.4 tenants.status を active に戻す（必須）

試験終了後、テナント状態を元に戻す。

```powershell
docker exec -it supabase_db_HarmoNet ^
  psql -U postgres -d postgres -c `
  "UPDATE public.tenants
     SET status = 'active'
   WHERE id = 'ab3d5d5f-027b-4108-b6aa-2a31941d88eb';"
```

---

## 3. レポートへの記載事項

CodeAgent レポート `D:\AIDriven\01_docs\06_品質チェック\CodeAgent_Report_AuthCallbackTenantBinding_v1.0.md` に、以下を追記すること。

* 実行した psql コマンド（inactive への変更／active への復旧）
* inactive 状態でのブラウザ挙動:

  * MagicLink ログイン時の遷移先 URL
  * `/home`・`/board` 直接アクセス時の挙動
* 期待結果との一致／不一致の有無
