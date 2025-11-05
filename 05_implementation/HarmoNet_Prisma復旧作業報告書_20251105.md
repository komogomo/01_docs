# HarmoNet Prisma環境復旧作業報告書

**Document ID**: HNM-RECOVERY-20251105  
**Version**: 1.0  
**作成日**: 2025-11-05  
**作業者**: TKE（実作業） + Claude（技術サポート）  
**プロジェクト**: HarmoNet Phase 6 準備作業

---

## 📋 作業概要

### 目的
- Prismaスキーマ・マイグレーションファイルの復旧
- Prisma Client再生成
- データベースとの整合性確認
- Git Utilityツールの改善（複数行コミットメッセージ対応）

### 作業期間
2025-11-05

### 背景
誤った操作により一部ファイルが消失。Gitバックアップから復旧作業を実施。

---

## 🚨 発生した問題

### 1. 初期状態の問題

| 問題 | 状態 |
|------|------|
| `schema.prisma` | 消失 |
| `prisma.config.ts` | 存在（不要ファイル） |
| マイグレーションファイル | 消失 |
| Prisma Client | 未生成 |
| データベース | ✅ 正常（Supabase側は無事） |

### 2. エラー内容

```
Error: @prisma/client did not initialize yet.
Please run "prisma generate" and try to import it again.
```

**原因**: Prismaスキーマファイルの消失によるPrisma Client未生成

---

## ✅ 実施した復旧作業

### Step 1: schema.prisma復元

#### 1-1. Gitバックアップからの取得
- ソース: Gitリポジトリのバックアップ
- ファイル: `schema.prisma` (v1.2)
- 内容: 29テーブル定義 + ENUM + リレーション

#### 1-2. @doc属性エラーの修正

**問題:**
```prisma
expires_at DateTime @doc("キャッシュ有効期限")
```

**原因**: `@doc`属性はPrisma 5.xでサポートされていない

**修正:**
```prisma
expires_at DateTime // キャッシュ有効期限
```

修正箇所: 6箇所
- `translation_cache.expires_at`
- `tts_cache.content_type`
- `tts_cache.language`
- `tts_cache.voice_type`
- `tts_cache.audio_url`
- `tts_cache.expires_at`

---

### Step 2: 環境変数の設定

#### 2-1. DIRECT_URL追加

**問題:**
```
Error: Environment variable not found: DIRECT_URL.
```

**解決:**

`.env` に追加:
```env
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DIRECT_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
```

`.env.local` にも同様に追加

**注**: Supabaseローカル環境では両方同じ値でOK

---

### Step 3: 不要ファイルの削除

```powershell
Remove-Item "D:\Projects\HarmoNet\src\prisma.config.ts" -Force
```

**理由**: Prismaは `schema.prisma` を直接参照するため不要

---

### Step 4: Prisma Client生成

```powershell
cd D:\Projects\HarmoNet\src
npx prisma generate
```

**結果**: ✅ 成功
- `node_modules/.prisma/client/` 生成完了

---

### Step 5: マイグレーションファイル復元

#### 5-1. マイグレーションディレクトリ作成

```powershell
New-Item -Path "prisma\migrations\20251104090633_create_initial_schema" -ItemType Directory -Force
New-Item -Path "prisma\migrations\20251104094921_enable_rls_policies" -ItemType Directory -Force
```

#### 5-2. SQLファイル配置

| マイグレーション | ファイル | 内容 |
|----------------|---------|------|
| 20251104090633 | migration.sql | 全30テーブル + ENUM + インデックス作成 |
| 20251104094921 | migration.sql | RLSポリシー34件設定 |

**ソース**: Phase 5で作成した正式なマイグレーションSQL

---

### Step 6: マイグレーション履歴の記録

```powershell
npx prisma migrate resolve --applied "20251104090633_create_initial_schema"
npx prisma migrate resolve --applied "20251104094921_enable_rls_policies"
```

**結果**: ✅ 両方とも「適用済み」として記録

---

### Step 7: データベース状態の確認

#### 7-1. SQL確認結果

| 項目 | 期待値 | 実際の値 | 結果 |
|------|--------|----------|------|
| テーブル総数 | 30個 | **31個** | ✅ |
| RLS有効テーブル | 29個 | **29個** | ✅ |
| ポリシー総数 | 30-50個 | **34個** | ✅ |
| マイグレーション履歴 | 2件 | **2件** | ✅ |

**テーブル一覧（31個）:**
1. `_prisma_migrations` - Prismaマイグレーション履歴
2. `schema_migrations` - Supabaseマイグレーション履歴
3-31. アプリケーションテーブル29個

#### 7-2. マイグレーション状態確認

```powershell
npx prisma migrate status
```

**結果:**
```
Database schema is up to date!

Applied migrations:
└─ 20251104090633_create_initial_schema
└─ 20251104094921_enable_rls_policies
```

✅ **完全に同期**

---

## 🛠️ Git Utilityツールの改善

### 背景
コミットメッセージを複数行で入力したいという要望

### 改善内容

#### v4.5の新機能
- **複数行コミットメッセージ入力対応**
- ENDコマンドで入力終了
- 入力内容のプレビュー表示

#### 使い方

```
[1] fix: Prisma環境復旧完了
[2] 
[3] - schema.prisma復元
[4] - マイグレーション履歴記録
[5] END
```

#### 成果物
- `harmonet-git-utility-v4.5.ps1`
- `harmonet-git-utility-v4.5.bat`

**注**: ファイル名のバージョン表記について、当初 `_v4_5` と誤って生成。正しくは `-v4.5` 形式。TKE側で修正済み。

---

## 📊 最終確認結果

### データベース構成

```
PostgreSQL (Supabase Local)
├─ テーブル: 31個
│  ├─ アプリケーション: 29個
│  ├─ _prisma_migrations: 1個
│  └─ schema_migrations: 1個
├─ RLS有効: 29テーブル
├─ ポリシー: 34件
└─ マイグレーション履歴: 2件記録
```

### Prisma環境

```
D:\Projects\HarmoNet\src\
├─ prisma\
│  ├─ schema.prisma ✅
│  └─ migrations\
│     ├─ 20251104090633_create_initial_schema\
│     │  └─ migration.sql ✅
│     └─ 20251104094921_enable_rls_policies\
│        └─ migration.sql ✅
├─ node_modules\
│  └─ .prisma\
│     └─ client\ ✅
├─ .env ✅
└─ .env.local ✅
```

---

## 🎯 次のステップ: 初期データ投入（Seed）

### 目的
テストデータを投入してログイン画面の実装準備を整える

### 実施予定作業

#### Step 1: seed.ts配置

**配置先:**
```
D:\Projects\HarmoNet\src\prisma\seed.ts
```

**内容:**
- テナントデータ作成（DEV001）
- テストユーザー3名作成
- ロール・権限の設定
- ユーザーとロールの紐付け

#### Step 2: package.json設定

**追加する設定:**

```json
{
  "scripts": {
    "seed": "ts-node --compiler-options {\"module\":\"CommonJS\"} prisma/seed.ts"
  },
  "prisma": {
    "seed": "ts-node --compiler-options {\"module\":\"CommonJS\"} prisma/seed.ts"
  }
}
```

#### Step 3: 必要パッケージ確認・インストール

```powershell
# 確認
npm list typescript ts-node @types/node

# 必要に応じてインストール
npm install -D typescript ts-node @types/node
```

#### Step 4: Seed実行

```powershell
cd D:\Projects\HarmoNet\src
npx prisma db seed
```

### 投入されるテストデータ

#### テナント

| 項目 | 値 |
|------|-----|
| tenant_code | DEV001 |
| tenant_name | 開発用管理組合 |
| timezone | Asia/Tokyo |
| is_active | true |

#### テストユーザー（3名）

| ロール | メールアドレス | 表示名 |
|--------|---------------|--------|
| システム管理者 | ttakeda43+admin@gmail.com | 管理者太郎 |
| テナント管理者 | ttakeda43+tenant@gmail.com | テナント次郎 |
| 一般ユーザー | ttakeda43+user@gmail.com | 一般三郎 |

**注**: 全て `ttakeda43@gmail.com` に届くGmailエイリアス機能を利用

#### ロール（3件）

1. `system_admin` - システム全体の管理権限
2. `tenant_admin` - テナント管理権限
3. `general_user` - 一般ユーザー権限

#### 権限（7件）

- `tenant:read` - テナント情報参照
- `tenant:write` - テナント情報編集
- `user:read` - ユーザー情報参照
- `user:write` - ユーザー情報編集
- `board:read` - 掲示板参照
- `board:write` - 掲示板投稿
- `facility:reserve` - 施設予約

### Seed実行後の確認項目

- [ ] テナントが1件作成されている
- [ ] ユーザーが3名作成されている
- [ ] ロールが3件作成されている
- [ ] 権限が7件作成されている
- [ ] ユーザーとロールの紐付けが正しい
- [ ] Supabase Authとの連携準備完了

---

## 📝 技術的な議論・学び

### Claudeの命名規則問題について

#### 発生した問題
Git Utilityファイルのバージョン表記で `_v4_5` と誤った形式を生成

#### 正しい形式
```
❌ harmonet-git-utility_v4_5.ps1
✅ harmonet-git-utility-v4.5.ps1
```

#### 原因分析
1. LLMの確率的生成による不確実性
2. メモリ・ナレッジ機能の参照が確率的
3. 「既存ファイル名を踏襲する」という単純なロジックが働かない

#### 他AI（GPT-5, Gemini）との比較
- **GPT-5**: メモリ登録でルールを確実に守る
- **Gemini**: アップロードファイルのルールを守る
- **Claude**: メモリ+ナレッジでもルールを守らないことがある

**結論**: Anthropicの設計・実装の問題。改善が必要。

#### 対策
1. 重要な命名規則は毎回リマインド
2. 生成されたファイル名を必ず確認
3. Anthropicへのフィードバック（👎ボタン）

---

## ⚠️ 注意事項・今後の課題

### 1. Prismaスキーマのバージョン管理

現在のスキーマ:
- バージョン: v1.2
- `@updatedAt` 使用（自動更新）
- Phase5協議では「アプリ層管理」だったが、開発効率のため `@updatedAt` を維持

**今後の方針:**
- 開発フェーズでは `@updatedAt` を継続使用
- 本番環境で問題があれば見直し

### 2. マイグレーション管理

**安全なコマンド:**
```powershell
✅ npx prisma migrate dev --name <名前>  # 新規マイグレーション
✅ npx prisma migrate deploy              # 本番適用
✅ npx prisma migrate status              # 状態確認
```

**危険なコマンド（絶対に実行禁止）:**
```powershell
❌ npx prisma migrate reset  # 全データ削除
❌ npx prisma db push        # スキーマ強制同期
```

### 3. 環境変数の管理

- `.env` と `.env.local` の両方に `DIRECT_URL` を設定
- Prismaコマンドは `.env` を優先的に読み込む
- Git管理: `.env` は `.gitignore` に追加済みか確認

---

## 📚 参考資料

### プロジェクトドキュメント
- Phase 5 最終引き継ぎ資料: `08_harmonet-phase5-final-handover_v1.0.md`
- Prismaスキーマ定義: `04_harmonet-prisma-schema_v1.0.prisma`
- DB ER定義: `05_harmonet-db-er-definition_v1.0.md`
- DBテーブル定義: `06_harmonet-db-table-definition_v1.0.md`

### 外部ドキュメント
- Prisma公式ドキュメント: https://www.prisma.io/docs
- Supabase CLI: https://supabase.com/docs/guides/cli
- Next.js環境変数: https://nextjs.org/docs/basic-features/environment-variables

---

## ✅ 作業完了チェックリスト

### Prisma環境復旧
- [x] schema.prisma復元
- [x] @doc属性エラー修正
- [x] 環境変数設定（DATABASE_URL, DIRECT_URL）
- [x] 不要ファイル削除（prisma.config.ts）
- [x] Prisma Client生成
- [x] マイグレーションファイル復元（2件）
- [x] マイグレーション履歴記録
- [x] データベース状態確認（SQL実行）
- [x] 全体整合性確認

### Git管理
- [x] Gitにコミット（復旧状態の保護）
- [x] Git Utility v4.5作成（複数行コミット対応）

### 次作業の準備
- [ ] seed.ts配置
- [ ] package.json設定
- [ ] 必要パッケージ確認
- [ ] Seed実行
- [ ] テストデータ確認

---

## 📊 作業時間・工数

| 作業項目 | 所要時間（概算） |
|---------|----------------|
| 問題調査・原因特定 | 30分 |
| schema.prisma復元・修正 | 30分 |
| 環境変数設定 | 10分 |
| Prisma Client生成 | 5分 |
| マイグレーションファイル復元 | 20分 |
| データベース確認 | 15分 |
| Git Utility改善 | 20分 |
| Git管理・報告書作成 | 30分 |
| **合計** | **約2.5時間** |

---

## 🎉 成果

### 達成事項
1. ✅ Prisma環境完全復旧
2. ✅ データベースとの整合性確認
3. ✅ マイグレーション履歴管理開始
4. ✅ Git Utility改善（複数行コミット対応）
5. ✅ 安全な状態でGitコミット完了

### Phase 6への準備
- ✅ 開発環境整備完了
- ✅ 次のステップ（Seed実行）準備完了
- ✅ ログイン画面実装に向けた基盤確立

---

## 📝 所感・改善点

### 良かった点
- Gitバックアップにより迅速な復旧が可能
- データベース本体は無事で、定義のみの復旧で済んだ
- Phase 5の正式なマイグレーションファイルが使用できた

### 改善が必要な点
- ファイル削除の事前確認不足（今後は慎重に）
- バックアップの定期的な確認・更新
- Claude（AI）の命名規則遵守問題（ツール側の課題）

### 学び
- Prismaのマイグレーション管理の重要性
- 環境変数（.env）の適切な管理
- AIツールの限界と適切な使い方

---

## 🚀 次回作業予定

### 実施内容
**初期データ投入（Seed実行）**

### スケジュール
準備完了次第、即座に実施可能

### 期待される成果
- テストユーザーでのログインテスト準備完了
- 画面実装の基盤データ投入完了
- Phase 6（機能詳細設計・実装）への移行準備完了

---

**Document End**

---

**作成者**: Claude (Sonnet 4.5) + TKE  
**承認**: TKE  
**配布**: HarmoNetプロジェクトチーム
