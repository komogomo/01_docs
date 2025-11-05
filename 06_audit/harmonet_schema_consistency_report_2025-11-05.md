# HarmoNet 設計書-スキーマ整合性チェック報告書 v1.0

## 対象・前提
- 対象リポジトリ
  - プログラム資材: `d:\Projects\HarmoNet`
  - 設計書: `d:\AIDriven\01_docs`
- 参照設計書
  - `01_basic_design/schema-definition-overview_v1.0.md`
  - `04_tenant/01_harmonet-tenant-config-schema_v1.1.md`
- 参照実装
  - `supabase/config.toml`
  - `supabase/migrations/*.sql`（初期スキーマ、RLS、トリガー削除、role_inheritances RLS追加）

---

## エグゼクティブサマリ
- **テナント分離/RLS/権限メタの基本方針は概ね整合**。JWT の `tenant_id`/`role` を用いた分離・特権参照は設計意図に一致。
- **命名規則・メタ属性・論理削除・権限定義の永続化などで乖離が顕著**。実装は簡素化された一方、設計書にある規範（命名・共通メタ・ENUM集約・削除方針・設定モジュール化等）は未反映。
- **運用上の未整備**（seed 不在、FK/一意制約の不足、保持方針の未実装）があり、堅牢性に改善余地。

---

## 評価方法
- 設計書の原則・命名・構造・RLS・権限・監査/運用要件を抽出。
- Supabase マイグレーションのスキーマ定義/RLS/関数・トリガー構成と突合。
- 一致点/相違点/不足点をセクション別に整理。

---

## 整合性評価（セクション別）

- **[テナント分離/RLS]**
  - 一致
    - 全主要テーブルで RLS 有効化。
    - `tenant_id = (auth.jwt() ->> 'tenant_id')::uuid` による分離。
    - `audit_logs`/`moderation_logs` の参照を `(auth.jwt() ->> 'role') in ('tenant_admin', 'system_admin')` に限定。
    - `roles`/`permissions`/`role_permissions`/`role_inheritances` はグローバル参照許容。
  - コメント
    - 設計書の RLS 方針（テナント分離＋管理者権限）は実装と整合。

- **[命名規則/レイヤ化]**
  - 乖離
    - 設計: テーブル名は原則 `tenant_<module>_<entity>`。レイヤ L0〜L4 を明示（system_base/tenant_core/...）。
    - 実装: フラットな命名（例: `board_posts`, `facilities`, `announcements`）。レイヤ命名や `tenant_` 接頭辞は未適用。
  - 影響
    - 設計/実装トレーサビリティ低下。将来的な自動生成/静的検証の障害。

- **[共通メタ属性（tenant_id/created_at/updated_at/status/deleted_at）]**
  - 一部整合・一部乖離
    - 多くのテーブルに `tenant_id` と `created_at`/`updated_at` は存在。
    - `status` は `Status` ENUM を採用するテーブルと、`TEXT` で別値を持つテーブルが混在（例: `board_posts.status='draft'`、`facility_reservations.status='pending'`）。
    - 設計書で必須の `deleted_at`（論理削除）は実装に未登場。
    - `updated_at` は設計「auto_now」表現に対し、実装はDBトリガーを削除し「アプリ層で更新」に一本化（方針の明示はあるが文言はズレ）。
  - 影響
    - 状態モデルが不統一、論理削除の設計-実装乖離。

- **[ENUM/辞書の管理方針]**
  - 乖離
    - 設計: ENUM 定義は `enum_definitions` テーブル管理＋AI検証を許容。
    - 実装: Postgres ENUM 型（`Status`, `ReactionType`, ...）を直接定義。`enum_definitions` 不在。
  - 影響
    - 運用時の ENUM 変更プロセス/検証フローが設計と不整合。

- **[テナント設定のモジュール分割]**
  - 乖離（部分的整合）
    - 設計: `tenant_common_config`/`tenant_board_config`/`tenant_facility_config` 等のモジュール分割。
    - 実装: `tenant_settings(config_json)` + `tenant_features(feature_key, enabled)` の二層構成。モジュール別テーブルは未実装。
  - 影響
    - 設計上の「Config as Data」かつモジュール単位の変更追跡/権限制御の恩恵を活かし切れていない。

- **[RBAC（ロール/権限/継承/権限行使ポリシー）]**
  - 一部整合・一部ギャップ
    - 実装: `roles`/`role_inheritances`/`permissions`/`role_permissions` は整備。`roles.permissions_ref` カラムあり。
    - 設計: `permissions_matrix`（boolean マトリクス定義）、`permission_policies`（継承モード/競合解決）を規定。
    - ギャップ: `permissions_matrix`/`permission_policies` を保持する永続層が未実装（`permissions_ref` の参照先も未整備）。
  - 影響
    - 設計上の宣言的権限定義→実行系（DB/アプリ）への機械的適用ができない。

- **[掲示板/承認フロー]**
  - 部分整合
    - 実装: 掲示板テーブル群＋`board_categories.requires_approval`、`board_approval_logs` があり、設計の承認フロー存在を示唆。
    - 設計: 対象カテゴリ/アクション/通知/承認者選定の詳細を規定（`post_approval` フロー）。
    - ギャップ: ルール/設定テーブル（対象カテゴリや承認者選定ロジック）を保持する仕組みは未実装（ログはあるが設定の永続化・評価はアプリ層想定）。

- **[施設予約]**
  - 概ね整合
    - 実装: 施設/設定/スロット/予約テーブルが整備。ENUM `FacilityFeeUnit` あり。
    - ギャップ: 一部 FK/ユニーク制約/インデックスは追加余地（後述）。

- **[通知/監査/モデレーション]**
  - 概ね整合
    - 実装: `notifications`, `user_notification_settings`, `audit_logs`, `moderation_logs` あり。
    - 設計: 監査の保持日数（365）明示、検索項目も規定。
    - ギャップ: 保持戦略（TTL/パーティショニング）やクリーンアップのDBレベル実装は未導入。

- **[データ整合性（FK/UNIQUE/Index）]**
  - 乖離（実装不足）
    - 欠けている可能性の高い FK（一例）
      - `board_posts.author_id` → `users.id`
      - `board_comments.author_id` → `users.id`
      - `board_reactions.user_id` → `users.id`
      - `announcement_reads.user_id` → `users.id`
      - `user_tenants.(user_id, tenant_id)` → `users.id`, `tenants.id`
      - `user_roles.(user_id, tenant_id, role_id)` → `users.id`, `tenants.id`, `roles.id`
      - `role_permissions.(role_id, permission_id)` → `roles.id`, `permissions.id`
      - `facility_reservations.slot_id` → `facility_slots.id`（NULL許容でも参照整合検討）
    - 一意制約の追加余地
      - 例: `board_categories(tenant_id, category_key)` はユニークにすべき可能性。
    - インデックスの追加余地
      - 例: `board_comments(post_id, created_at)`, `announcement_reads(announcement_id, user_id)`, `user_roles(user_id, tenant_id)`, `user_tenants(user_id, tenant_id)` 等。

- **[初期データ/seed]**
  - 乖離
    - `config.toml` では `db.seed.enabled=true` かつ `sql_paths=["./seed.sql"]` 指定。
    - 実体 `supabase/seed.sql` が未配置。
  - 影響
    - ローカル/CI セットアップの不安定化、RBAC/カテゴリ等の初期整備不可。

---

## 指摘事項（重要度順）

- **[高] 論理削除の未実装**
  - 設計: `deleted_at` による論理削除を原則化。
  - 実装: `deleted_at` 不在。対応テーブルに列追加・RLS/アプリ更新が必要。

- **[高] 外部キー/一意制約の不足**
  - データ整合性・参照整合の担保が弱い。FK/UNIQUE を計画的に付与。

- **[高] seed 不在**
  - `seed.sql` の追加、または `config.toml` の `db.seed` 無効化が必要。

- **[中] 命名規則・レイヤ化未適用**
  - 少なくとも設計書とのトレーサビリティ用に、命名規範のどちらを採択するか方針確定が必要。

- **[中] 状態表現の不統一**
  - `Status` ENUM と `TEXT` 独自値（`draft`/`pending` 等）が混在。どちらを標準化するか決定し統一。

- **[中] ENUM管理方針の不一致**
  - `enum_definitions` テーブル不在。採用方針（DB ENUM 継続 or テーブル管理への移行）を決定。

- **[中] RBAC 設定の永続化不足**
  - `permissions_matrix`/`permission_policies` のデータモデル未整備。`roles.permissions_ref` を活かす関連テーブルが必要。

- **[中] 監査保持戦略の未実装**
  - 保持 365 日の運用要件に合わせ、TTL/パーティショニング/ジョブの導入検討。

- **[低] `updated_at` 方針の文言差**
  - 設計「auto_now」対し、実装はアプリ層更新。設計書に「アプリ層で明示更新」へ改訂追記を推奨。

---

## 推奨アクション（実行順）

- **[1] seed 整備 or 無効化**
  - `supabase/seed.sql` を作成（roles/permissions/role_inheritances/board_categories（管理カテゴリ）などの初期データ）。
  - 代替として `db.seed.enabled=false` に変更（暫定）。

- **[2] データ整合性の強化**
  - 優先テーブルから FK/UNIQUE/インデックスを追加するマイグレーションを作成。
  - 影響調査しつつ段階的に適用。

- **[3] 論理削除の導入**
  - 対象テーブルに `deleted_at TIMESTAMPTZ` を追加。
  - RLS/アプリクエリに「非削除条件」を反映。

- **[4] 状態表現の標準化**
  - `Status` ENUM を標準化とするか、機能別 ENUM（例: `PostStatus`, `ReservationStatus`）を導入。
  - 既存 `TEXT` 値は ENUM 化/チェック制約で整合。

- **[5] RBAC 定義の永続化**
  - `permissions_matrix` と `permission_policies` を表現する設定テーブル群を設計・実装。
  - `roles.permissions_ref` と接続し、アプリ層で解決できるようにする。

- **[6] テナント設定のモジュール分割（段階導入）**
  - 現行 `tenant_settings` を当面維持しつつ、`tenant_board_config` 等のテーブルを追加して移行パスを設計。

- **[7] 監査保持戦略の実装**
  - `audit_logs` のパーティショニング、保持期間到来時のクリーンアップジョブを導入。

- **[8] 設計書の改訂/整合**
  - 採択方針（命名規則、ENUM 管理、updated_at 更新責務）を最新化し、実装と揃える。

---

## 付録A: 主要テーブルと設計対応の所見

- **テナント中核**: `tenants`/`tenant_settings`/`tenant_features`
  - 設計の「テナント中核」意図に整合。ただし設定モジュール分割は未実装。

- **ユーザー/認可**: `users`/`user_tenants`/`user_roles`/`roles`/`role_inheritances`/`permissions`/`role_permissions`/`user_profiles`
  - RBAC の骨格は整備良好。`permissions_matrix`/`permission_policies` の永続層は未整備。

- **掲示板**: `board_*`
  - 概要整合。承認フローの設定データはアプリ/設定層前提でDB未実装。

- **施設予約**: `facilities`/`facility_settings`/`facility_slots`/`facility_reservations`
  - 概ね整合。FK/インデックス強化の余地。

- **通知/キャッシュ/監査/モデレーション**
  - 設計意図に整合。保持/TTL/運用の追加実装が必要。

---

## 付録B: RLS 方針との整合
- テナント分離: 全体に適用済みで整合。
- 管理者参照: 監査・モデレーションに限定的付与で整合。
- グローバル参照: 権限メタ系のグローバル参照は設計思想に合致。

---

## 結論
- セキュリティ（RLS）とモジュールスコープ（掲示板/施設/監査等）の「大枠」は設計と整合。
- 一方で、設計規範（命名/メタ属性/論理削除/ENUM 管理/権限設定の永続化/seed/保持戦略）は実装に十分反映されていない。
- 上記推奨アクションを段階適用することで、設計—実装整合性と運用堅牢性を短期に向上可能。

---

# タスク進行ステータス
- 設計書の特定と読解: 完了
- スキーマ/RLS 突合: 完了
- Markdown 報告書作成: 完了
