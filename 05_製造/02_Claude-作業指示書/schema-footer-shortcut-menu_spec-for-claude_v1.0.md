# HarmoNet スキーマ改修指示書 - テナント別フッターショートカットメニュー対応

**Version:** 1.0
**Created:** 2025-11-20
**Target Agent:** Claude（schema.prisma 改修担当）

---

## 1. 目的

HarmoNet の **フッターショートカットバー（FooterShortcutBar）** を、テナント毎に異なる構成で表示できるようにするため、
`schema.prisma` に必要最小限のテーブル定義を追加する。

* 既存スキーマとの整合性を維持しつつ、
* テナント毎にショートカット構成（項目・順序・有効/無効）を制御可能とすること

をゴールとする。

**重要:** 既存モデルの破壊的変更（rename / drop / 型変更など）は禁止。追加のみで対応すること。

---

## 2. 対象ファイル / 参照資料（フルパス）

### 2.1 対象スキーマ

* `/01_docs/05_データベース設計/schema.prisma`

### 2.2 関連設計書

* フロントエンド技術スタック定義
  `/01_docs/01_要件定義/harmonet-technical-stack-definition_v4.4.md`
* 共通デザインシステム基本設計書
  `/01_docs/03_基本設計/01_共通部品/common-design-system_v1.2.md`
* 共通フレーム統合詳細設計書（AppHeader / AppFooter / FooterShortcutBar）※本タスクと密接
  `/01_docs/04_詳細設計/00_共通部品/02_ログイン画面以外の共通部品詳細設計/common-frame-components_detail-design_v1.0.md`
* FooterShortcutBar 旧詳細設計（参考・ロジック確認用）
  `/01_docs/04_詳細設計/00_共通部品/02_ログイン画面以外の共通部品詳細設計/ch05_FooterShortcutBar_v1.1.md`

※ 上記以外のファイルは参照してよいが、**schema.prisma の唯一の正は `/01_docs/05_データベース設計/schema.prisma` とする。**

---

## 3. 現状の問題認識（前提）

1. `schema.prisma` には `tenant_features` モデルが存在し、テナント単位の機能 ON/OFF を保持している。
   しかし、**フッターショートカットメニューそのものを定義するテーブルは存在しない**。

2. FooterShortcutBar の現行詳細設計では、一時的に **固定 5 項目**（ホーム / 掲示板 / 施設予約 / マイページ / ログアウト）として記述されているが、
   将来的には **テナント毎に構成が変わる前提** である（表示項目と表示順序）。

3. 現状のスキーマでは以下が不足している：

   * テナント毎のショートカット構成を表すテーブル
   * 表示順序（display_order）
   * feature_key と UI 表示（i18nキー / アイコン）を結びつけるメタ情報

---

## 4. 要件（スキーマレベル）

### 4.1 新規テーブルの目的

**テナント毎のフッターショートカットメニュー構成を表現するモデル** を追加すること。

このモデルは、少なくとも以下を満たす必要がある：

1. **テナント毎に** 表示対象のショートカット項目を定義できること
2. 各ショートカットの **表示順（display_order）** を定義できること
3. ショートカットの論理キー（例：`home`, `board`, `facility`, `mypage`, `logout`）を **文字列で保持** すること
4. 必要に応じて i18n 用の label_key や、アイコン種別（lucide 名）を拡張できる構造であること

### 4.2 推奨モデル案（叩き台）

以下のような新モデルを **ベース案** として考えてほしい（最終形は Claude の判断で調整可）。

```prisma
model tenant_shortcut_menu {
  id            String   @id @default(uuid())
  tenant_id     String
  feature_key   String              // 例: "home", "board", "facility", "mypage", "logout" など
  label_key     String?             // 例: "nav.home" （i18nキー）
  icon          String?             // 例: "Home", "MessageSquare"（lucide アイコン名）
  display_order Int                  // 表示順（昇順で並べる）
  enabled       Boolean  @default(true)

  tenant tenants @relation(fields: [tenant_id], references: [id])

  @@index([tenant_id])
  @@unique([tenant_id, feature_key])
}
```

**重要:**

* `feature_key` は既存の `tenant_features.feature_key` と意味的に近いが、**既存モデルは変更せず**、このモデルは UI 表示構成専用として独立させてよい。
* もし `tenant_features` を再利用した方が整合的と判断する場合でも、**既存フィールドの rename / 削除は行わないこと**。

### 4.3 RLS / テナント境界（方針レベル）

Supabase 側で RLS を定義する際は、他のテナント系テーブルに合わせて：

* `tenant_id = jwt.tenant_id` を基本とする
* UI で閲覧するテーブルのため、**読み取り専用であれば INSERT/UPDATE ポリシーは後回しでもよい**（MVP では管理画面からの編集が未実装のため）

※ RLS の詳細ポリシー文は、この指示書では必須ではないが、
他のテナント系モデル（例：`facilities`, `announcement_targets` 等）との整合を保つようにしてほしい。

---

## 5. 実装上の制約・禁止事項

1. **既存モデルの破壊的変更禁止**

   * `model` 名の変更
   * 既存フィールドの削除 / rename / 型変更
   * 既存 `@@id` / `@@unique` の変更

2. **既存テーブルへの列追加は慎重に**

   * 原則として、新要件は `tenant_shortcut_menu` のような **新規モデル追加で完結**させること
   * どうしても既存モデルへの追加が必要と判断した場合は、理由をコメントとして明示すること

3. **命名規約**

   * Prisma モデル名：`tenant_shortcut_menu` など、既存に合わせた snake_case の DBテーブル名対応
   * フィールド名：既存の命名規則（tenant_id, created_at など）に合わせる

4. **Migration ファイル**

   * Supabase 用 Migration の作成が必要な場合、
     `supabase/migrations/<YYYYMMDDHHMMSS>_add_tenant_shortcut_menu.sql` のような名前で作成方針とする（ファイル名は Claude 側で決定してよい）。

---

## 6. 期待するアウトプット（Claude への具体要求）

Claude に対しては、以下の成果物を期待する：

1. **更新済み `/01_docs/05_データベース設計/schema.prisma` の差分**

   * 新規 `model tenant_shortcut_menu`（名称は最終判断可）
   * 必要であれば関連する enum や index の追加

2. **新モデルの簡単なコメント**

   * Prisma 内にコメントで「テナント別フッターショートカットメニュー構成を表すモデル」であることを明記

3. **（必要な場合）Migration SQL のたたき台**

   * 上記モデルを作成するための `CREATE TABLE` 文
   * index / unique 制約
   * `FOREIGN KEY (tenant_id) REFERENCES tenants(id)`

4. **既存テーブルとの整合性チェック結果の一言コメント**

   * `tenant_features` との関係をどう整理したか
   * 追加したモデルにより既存構造に影響がないことの確認

---

## 7. 補足

* 本タスクは **UI 側の FooterShortcutBar 実装を前提にした“バックエンド側の基盤整備”** であり、
  アプリの動作に直接影響するため、**スキーマの整合性が最重要**となる。

* 仕様に曖昧さがある場合は、勝手に拡張せず、
  「テナント毎にショートカット構成（項目・順序・有効/無効）を変えられる」という要件に
  最小限必要な構造に留めてほしい。

---

**以上を前提として、Claude による schema.prisma 改修を依頼する。**
