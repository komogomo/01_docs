# Claude 実行指示書（HarmoNet Phase9 Day-2）

## 1. タスク概要
- **タスク名:** Phase9 Day-2 Seed投入およびログイン画面実装準備
- **対象フェーズ:** Phase9 実装フェーズ
- **対象ファイル:**
  - `/prisma/seed.ts`
  - `/src/app/login/page.tsx`
  - `/01_docs/06_audit/HarmoNet_Phase9_Initialization_Report_v1.1.md`
- **目的:** 
  Prisma DB seed実行により初期データを投入し、ログイン画面の実装準備を整える。
  実行結果を報告書（v1.1）に反映し、Phase9のアプリ動作確認へ移行する。
- **出力形式:** Markdown完全版（差分禁止）
- **出力場所:** `/01_docs/06_audit/`

---

## 2. 実行ルール（Claude必読）

### 2.1 ドキュメント生成ルール
- 既存ファイルの上書きは禁止。新しいバージョン番号（v1.1）で出力する。
- 出力は完全版Markdown。末尾に以下のメタ情報を必ず記載：

Created: YYYY-MM-DD
Last Updated: YYYY-MM-DD
Version: vX.X
Document ID: harmo-phase9-day2-[version]


### 2.2 Prisma操作ルール
- **禁止コマンド:** `npx prisma init` / `db push` / `migrate reset`
- **許可コマンド:** `migrate dev` / `migrate deploy` / `db pull` / `db seed`
- **実行手順:**  
```bash
cd D:\Projects\HarmoNet\src
npx prisma db seed --schema ../prisma/schema.prisma

.env には必ず DIRECT_URL を定義済みであること。

2.3 Git / ファイル運用ルール

ファイル名は変更せずバージョンのみ上げる（例: _v1.0 → _v1.1）。

_latest.md リンクは常に最新版を指す。

/01_docs/ 配下の正式構成に従う。

2.4 実装・安全性

DB削除・リセット系コマンドは使用禁止。

Prisma Client再生成は自動許可。

ログイン画面UIは既存UIルール「やさしく・自然・控えめ」「Appleカタログ風」に従う。

3. 実行手順（Claude向け）
Step 1. Seed投入

npx prisma db seed --schema ../prisma/schema.prisma を実行。

実行ログ（成功・失敗）を記録。

Prisma Studioで投入データ確認。

結果を報告書（v1.1）へ反映。

Step 2. 初期化報告書更新

/01_docs/06_audit/HarmoNet_Phase9_Initialization_Report_v1.0.md をコピーし、
新規ファイル ..._v1.1.md として作成。

セクション13「初期データ投入（Seed計画）」の直後に以下を追加：

13.7 実行結果（実績）

実際の投入結果（テナント・ロール・ユーザー・紐付け）

実行ログ抜粋

メタ情報更新：

Version: v1.1
Last Updated: 2025-11-07

