# GPT-DB-Standard_v1.0.md

**HarmoNet：DBスキーマ追加／変更指示書・AI安全運用基準（永久保存版）**

---

## 1. 目的

本書は、**タチコマ（GPT）が Claude に DB作業指示書を書く際に必ず参照する“標準ルール”** をまとめたもの。

HarmoNet の DB はこれに従うことで：

* DB破壊（DROP / reset）防止
* schema.prisma 全量上書き事故防止
* AI の過剰生成（妄想トリガー・余計なDDL）防止
* 安全な差分追加

を保証する。

---

## 2. 基本原則（絶対遵守）

### ✔ 2.1 Prisma schema.prisma が唯一の Source of Truth

* DBスキーマの変更は **schema.prisma の差分追加のみ**
* SQLでの CREATE TABLE / ALTER TABLE を AI が生成してはいけない

### ✔ 2.2 Supabase 運用は **db push 方式**

* 使用するコマンドは常に：

```
npx supabase db push
```

* 既存データ保持が前提
* migration ファイルは使用しない（手動 SQL 以外）

### ✔ 2.3 「AIによる schema.prisma 全量再生成禁止」

* Claude に schema.prisma 全文を書かせない
* 追加する model / enum **1ブロックだけ** を出力させる

### ✔ 2.4 「破壊的変更」全面禁止

* DROP TABLE / ALTER COLUMN / rename 禁止
* 既存 model のフィールド削除・型変更禁止

---

## 3. Claude に渡す作業指示書の構造（テンプレート）

※ タチコマは常にこの構造で指示書を作る

### ✔ 3.1 タスク内容（例）

```
目的：tenant_shortcut_menu テーブルを schema.prisma に追加する。

要求：
・既存モデルへの変更禁止
・追加する model ブロックのみ出力
・schema.prisma 全文禁止
・migration SQL を勝手に生成しない
・RLS と初期値 SQL は別タスクとして分離指示
```

### ✔ 3.2 Claude に出させるもの

* Prisma の model 1 つだけ
* 必要であれば enum 1 つだけ
* コメント
  **これ以外を出力させてはいけない**

---

## 4. RLS（Row Level Security）標準

### ✔ 4.1 すべてのテナント系テーブルに RLS 必須

### ✔ 4.2 方針

```
ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;

CREATE POLICY ... FOR SELECT  USING ((select auth.jwt())->>'tenant_id' = tenant_id);
CREATE POLICY ... FOR INSERT  WITH CHECK ((select auth.jwt())->>'tenant_id' = tenant_id);
CREATE POLICY ... FOR UPDATE  USING ((select auth.jwt())->>'tenant_id' = tenant_id) WITH CHECK (...);
CREATE POLICY ... FOR DELETE  USING ((select auth.jwt())->>'tenant_id' = tenant_id);
```

※ RLS SQL は *Claude のタスクではなく* 別ファイルとして作る

---

## 5. 初期値（Seed）運用標準

### ✔ 5.1 初期値が必要な UI/機能では必ず Seed を定義する

例：FooterShortcutBar の 5 項目（home/board/facility/mypage/logout）

### ✔ 5.2 既存テナント向けの初期値挿入は SQL で定義

* 重複チェック付き INSERT を必須とする

---

## 6. Claude への指示で禁止すること

### ❌ schema.prisma 全文出力

### ❌ migration ファイル生成

### ❌ テーブル作成 SQL の生成

### ❌ トリガー・関数の勝手な追加

### ❌ ENUM の勝手な変更

### ❌ 既存テーブルの整合性を勝手に見直す行為

---

## 7. Claude に指示する際の必須メッセージ（テンプレ）

タチコマは必ずこれを冒頭に記載して Claude に指示する：

```
※注意：このタスクは HarmoNet DB 標準（GPT-DB-Standard_v1.0）に準拠すること。
・schema.prisma の既存部分に触れてはならない
・追加する model / enum だけ出力すること
・schema.prisma 全文出力禁止
・migration SQL 自動生成禁止
・破壊的変更禁止
```

---

## 8. 役割分担

* **TKD**：業務要件を定義する
* **タチコマ**：差分（model/enum）だけを生成する指示書を書く
* **Claude**：差分 model のみ生成
* **TKD**：schema.prisma に貼り、`db push` する
* **SQL（RLS/初期値）** はタチコマ or Claude が別ファイルとして生成

---

## 9. このファイルの置き場所

```
/01_docs/05_データベース設計/GPT-DB-Standard_v1.0.md
```

タチコマは **今後すべての DB 関連指示書を作る際に必ずこのファイルを参照すること**。

---

## 10. 最後に

この標準により、

* DB破壊ゼロ
* AI暴走ゼロ
* 毎回同じ品質の安全な DB 作業指示書
  が保証される。
