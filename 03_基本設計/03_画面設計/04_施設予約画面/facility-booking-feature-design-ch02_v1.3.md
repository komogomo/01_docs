# Chapter 02: 施設構造・データモデル

**HarmoNet 施設予約機能 基本設計書**

---

## 改訂履歴

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-10-29 | TKD + Claude | 初版作成 |
| v1.1 | 2025-11-28 | TKD + Claude | テナント可変構造明確化、利用規約の掲示板連携追加 |
| v1.2 | 2025-11-29 | TKD + Claude | 予約データ構造にschema.prisma整合カラム追加、料金設定方針明確化 |
| v1.3 | 2025-12-02 | TKD + Claude | facility_settings追加カラム定義、マルチテナント設定項目の網羅的記載 |

---

## 目次

1. [施設マスタ構造](#1-施設マスタ構造)
2. [施設タイプ分類](#2-施設タイプ分類)
3. [ルール定義層（facility_settings）](#3-ルール定義層facility_settings)
4. [予約データ構造](#4-予約データ構造)
5. [利用規約の掲示板連携](#5-利用規約の掲示板連携)
6. [データ関係図](#6-データ関係図)
7. [スキーマ追加項目](#7-スキーマ追加項目)

---

## 1. 施設マスタ構造

### 1.1 テナント毎の施設構成

施設構成はテナント（管理組合）毎に完全に異なる。

**テナント毎に変わる項目:**

| 施設タイプ | 可変項目 |
|-----------|---------|
| 集会所系 | 施設名称、施設数、利用可能時間帯、予約単位（分）、料金、月間制限 |
| 駐車場系 | 駐車場名称、台数、区画名、料金、月間制限 |

**構成例:**

| テナント | 集会所系 | 駐車場系 |
|---------|---------|---------|
| セキュレア研究学園 | セキュレアステーション 1室 | ゲスト駐車場 8台（①〜⑧） |
| テナントA | 集会室 2室、パーティールーム 1室 | 来客用駐車場 20台（A1〜A10, B1〜B10） |
| テナントB | 多目的室 1室 | ゲスト駐車場 5台（1〜5） |

### 1.2 施設マスタの管理単位

- すべての施設マスタは `tenant_id` で分離
- テナント管理者が自テナントの施設を登録・編集
- 施設名称、区画番号等は自由入力

---

## 2. 施設タイプ分類

### 2.1 大分類

| タイプ | 予約単位 | 特徴 |
|--------|---------|------|
| 集会所系 | 時間単位（分刻み、テナント設定可能） | 使用目的・参加人数の入力あり |
| 駐車場系 | 日単位 | 区画選択のみ |

### 2.2 集会所系の例

- 集会室
- パーティールーム
- 多目的室
- ゲストルーム
- スカイラウンジ

### 2.3 駐車場系の例

- ゲスト用駐車場
- 来客用駐車場
- バイク駐車場

---

## 3. ルール定義層（facility_settings）

### 3.1 設計思想

施設タイプ毎の違いは「ルール定義」で吸収する。
コード変更なしで、テナント毎に異なるルールを設定可能。

### 3.2 facility_settings テーブル定義

| カラム名 | 型 | デフォルト | 説明 | 既存/追加 |
|---------|---|----------|------|----------|
| id | UUID | - | 主キー | 既存 |
| tenant_id | UUID | - | テナントID | 既存 |
| facility_id | UUID | - | 施設ID（1:1） | 既存 |
| fee_per_day | Decimal(8,2) | null | 利用料金 | 既存 |
| fee_unit | Enum | day | 料金単位（day/hour） | 既存 |
| max_consecutive_days | Int | 3 | 最大連続予約日数 | 既存 |
| reservable_until_months | Int | 1 | 予約可能期間（何ヶ月先まで） | 既存 |
| **slot_duration_minutes** | Int | 30 | 予約単位（分） | **追加** |
| **available_from_time** | String | "09:00" | 利用開始時刻 | **追加** |
| **available_to_time** | String | "19:00" | 利用終了時刻 | **追加** |
| **monthly_limit** | Int | null | 月間利用制限回数（null=無制限） | **追加** |
| created_at | DateTime | now() | 作成日時 | 既存 |
| updated_at | DateTime | - | 更新日時 | 既存 |

### 3.3 設定項目の説明

| 項目 | 説明 | 集会所系 | 駐車場系 |
|------|------|---------|---------|
| fee_per_day | 利用料金（fee_unitに応じて解釈） | 0〜（時間単価） | 0〜（1回あたり） |
| fee_unit | 料金単位 | hour | day |
| slot_duration_minutes | 予約の最小単位（分） | 30, 60等 | 1440（24時間） |
| available_from_time | 利用開始時刻 | "09:00"等 | "00:00" |
| available_to_time | 利用終了時刻 | "19:00"等 | "23:59" |
| monthly_limit | 月間利用回数制限 | null（無制限） | 10等 |
| max_consecutive_days | 連続予約可能日数 | 1 | 3等 |
| reservable_until_months | 予約可能期間 | 1（翌月末） | 1（翌月末） |

### 3.4 セキュレア研究学園の設定例

**ゲスト駐車場:**

| カラム | 設定値 |
|--------|--------|
| fee_per_day | 100.00 |
| fee_unit | day |
| slot_duration_minutes | 1440（24時間） |
| available_from_time | "00:00" |
| available_to_time | "23:59" |
| monthly_limit | 10 |
| max_consecutive_days | 3 |
| reservable_until_months | 1 |

**集会所（セキュレアステーション）:**

| カラム | 設定値 |
|--------|--------|
| fee_per_day | 0.00 |
| fee_unit | hour |
| slot_duration_minutes | 30 |
| available_from_time | "09:00" |
| available_to_time | "19:00" |
| monthly_limit | null（無制限） |
| max_consecutive_days | 1 |
| reservable_until_months | 1 |

---

## 4. 予約データ構造

### 4.1 予約テーブル（facility_reservations）

| カラム | 型 | 説明 | 必須 |
|--------|-----|------|------|
| id | UUID | 予約ID | ○ |
| tenant_id | UUID | テナントID | ○ |
| facility_id | UUID | 施設ID | ○ |
| slot_id | UUID | 区画ID（駐車場の場合） | - |
| user_id | UUID | 予約者ID | ○ |
| start_at | DateTime | 開始日時 | ○ |
| end_at | DateTime | 終了日時 | ○ |
| purpose | String | 使用目的（集会所系は必須） | △ |
| participant_count | Int | 参加人数（集会所系、任意） | - |
| status | Enum | pending / confirmed / canceled | ○ |
| created_at | DateTime | 作成日時 | ○ |
| updated_at | DateTime | 更新日時 | ○ |

※ `purpose`, `participant_count` は schema.prisma に追加が必要

### 4.2 施設タイプ別の入力項目

| 項目 | 駐車場 | 集会所 |
|------|--------|--------|
| 区画選択（slot_id） | ○ | - |
| 開始日時（start_at） | ○（日付のみ） | ○（時刻含む） |
| 終了日時（end_at） | ○（日付のみ） | ○（時刻含む） |
| 使用目的（purpose） | - | ○（必須） |
| 参加人数（participant_count） | - | △（任意） |

### 4.3 ステータス遷移

```
予約作成 → pending → confirmed → (利用完了)
                        ↓
                    canceled
```

| ステータス | 説明 |
|-----------|------|
| pending | 予約申請中（承認待ち、または確定処理中） |
| confirmed | 予約確定 |
| canceled | キャンセル済み |

- 承認フローは現時点では不要（将来実装）
- 承認不要の場合は pending → confirmed を自動遷移

---

## 5. 利用規約の掲示板連携

### 5.1 方針

- 施設予約画面内に詳細な利用規約は持たない
- 掲示板の「ルール・規則」カテゴリに投稿 → 自動で3言語翻訳
- 施設予約画面からはリンクのみ表示

### 5.2 画面表示

**施設情報カード:**
- 施設名称
- 基本情報（使用時間、定員等）
- 「利用規約を確認」リンク → 掲示板の該当投稿へ遷移

### 5.3 メリット

- 利用規約の多言語対応は掲示板の翻訳機能で自動化
- 規約変更時は掲示板投稿を編集するだけ
- 施設予約機能の実装がシンプルになる

---

## 6. データ関係図

### 6.1 主要エンティティ（schema.prisma準拠）

```
tenants (テナント)
  │
  ├── facilities (施設マスタ)
  │     ├── facility_settings (ルール設定: 1:1)
  │     ├── facility_slots (区画: 駐車場の場合)
  │     └── facility_blocked_ranges (ブロック期間)
  │
  └── facility_reservations (予約データ)
        └── users (予約者)
```

### 6.2 関係性

| 関係 | 説明 |
|------|------|
| tenants → facilities | 1テナントは複数の施設を持つ |
| facilities → facility_settings | 1施設は1つのルール設定を持つ（1:1） |
| facilities → facility_slots | 1施設は複数の区画を持つ（駐車場） |
| facilities → facility_blocked_ranges | 1施設は複数のブロック期間を持つ |
| facilities → facility_reservations | 1施設は複数の予約を受ける |
| users → facility_reservations | 1ユーザーは複数の予約を持つ |

---

## 7. スキーマ追加項目

### 7.1 facility_settings への追加カラム

以下のカラムを `facility_settings` テーブルに追加する。

```prisma
model facility_settings {
  // 既存カラム
  id                      String   @id @default(uuid())
  tenant_id               String
  facility_id             String   @unique
  fee_per_day             Decimal? @db.Decimal(8, 2)
  fee_unit                fee_unit @default(day)
  max_consecutive_days    Int      @default(3)
  reservable_until_months Int      @default(1)
  created_at              DateTime @default(now())
  updated_at              DateTime @updatedAt

  // 追加カラム
  slot_duration_minutes   Int      @default(30)    // 予約単位（分）
  available_from_time     String   @default("09:00") // 利用開始時刻
  available_to_time       String   @default("19:00") // 利用終了時刻
  monthly_limit           Int?     // 月間利用制限回数（null=無制限）

  // Relations
  tenant   tenants    @relation(fields: [tenant_id], references: [id])
  facility facilities @relation(fields: [facility_id], references: [id])

  @@index([tenant_id])
}
```

### 7.2 facility_reservations への追加カラム

以下のカラムを `facility_reservations` テーブルに追加する。

```prisma
model facility_reservations {
  // 既存カラム
  id          String             @id @default(uuid())
  tenant_id   String
  facility_id String
  slot_id     String?
  user_id     String
  start_at    DateTime
  end_at      DateTime
  status      reservation_status @default(pending)
  created_at  DateTime           @default(now())
  updated_at  DateTime           @updatedAt

  // 追加カラム
  purpose           String?  // 使用目的（集会所系）
  participant_count Int?     // 参加人数（集会所系）
  meta              Json?    // 拡張データ（キャンセル理由、IoT設定等）

  // Relations
  tenant   tenants         @relation(fields: [tenant_id], references: [id])
  facility facilities      @relation(fields: [facility_id], references: [id])
  slot     facility_slots? @relation(fields: [slot_id], references: [id])
  user     users           @relation(fields: [user_id], references: [id])

  @@index([tenant_id])
  @@index([facility_id])
  @@index([slot_id])
  @@index([user_id])
}
```

---

**Document ID**: HARMONET-FACILITY-BOOKING-DESIGN-001-CH02  
**Status**: 確定版  
**Created**: 2025-10-29  
**Last Updated**: 2025-12-02  
**Version**: v1.3  
**Authors**: TKD + Claude  

---

© 2025 HarmoNet Project. All rights reserved.
