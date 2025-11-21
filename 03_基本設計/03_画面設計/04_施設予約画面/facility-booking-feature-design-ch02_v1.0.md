# 施設予約機能 詳細設計書 Chapter 02: 施設構造・データモデル

**HarmoNet スマートコミュニケーションアプリ**

**文書ID**: HARMONET-FACILITY-BOOKING-DESIGN-001-CH02  
**バージョン**: v1.0  
**最終更新**: 2025年10月29日  
**ステータス**: 承認待ち

---

## 📑 目次

- [2.1 施設マスタ構造](#21-施設マスタ構造)
  - [2.1.1 施設の階層構造](#211-施設の階層構造)
  - [2.1.2 facility テーブル設計](#212-facility-テーブル設計)
  - [2.1.3 facility_type テーブル設計](#213-facility_type-テーブル設計)
  - [2.1.4 facility_category テーブル設計](#214-facility_category-テーブル設計)
- [2.2 予約ルール定義構造](#22-予約ルール定義構造)
  - [2.2.1 facility_rule テーブル設計](#221-facility_rule-テーブル設計)
  - [2.2.2 ゲスト駐車場のルール定義例（MVP）](#222-ゲスト駐車場のルール定義例mvp)
  - [2.2.3 集会室のルール定義例（Phase 2）](#223-集会室のルール定義例phase-2)
- [2.3 予約データ構造](#23-予約データ構造)
  - [2.3.1 booking テーブル設計](#231-booking-テーブル設計)
  - [2.3.2 連続予約の表現方法](#232-連続予約の表現方法)
  - [2.3.3 ステータス管理](#233-ステータス管理)
- [2.4 多言語データ構造](#24-多言語データ構造)
  - [2.4.1 translation_master テーブル](#241-translation_master-テーブル)
  - [2.4.2 施設予約機能で使用する翻訳キー例](#242-施設予約機能で使用する翻訳キー例)
- [2.5 ER図](#25-er図)
  - [2.5.1 主要エンティティ関係図](#251-主要エンティティ関係図)
  - [2.5.2 カーディナリティ](#252-カーディナリティ)
- [2.6 データ整合性ルール](#26-データ整合性ルール)
  - [2.6.1 制約条件](#261-制約条件)
  - [2.6.2 排他制御](#262-排他制御)

---

## 2.1 施設マスタ構造

### 2.1.1 施設の階層構造

HarmoNetの施設予約システムは、以下の3層構造で施設を管理します。

```
facility_category（施設カテゴリ）
  └─ facility_type（施設タイプ）
       └─ facility（施設個体）
```

#### 階層の説明

**第1層：施設カテゴリ（facility_category）**

施設を大分類するカテゴリです。MVP以降の拡張を見据えた分類を定義します。

| カテゴリコード | カテゴリ名（日本語） | 説明 |
|--------------|-------------------|------|
| parking | 駐車・駐輪施設 | ゲスト用駐車場、駐輪場など |
| indoor_space | 室内共用施設 | 集会室、ゲストルーム、会議室など |
| outdoor_space | 屋外共用施設 | バーベキュースペース、中庭など |
| equipment | 機能設備 | Wi-Fiルーター、プロジェクターなど |

**第2層：施設タイプ（facility_type）**

カテゴリ内の具体的な施設タイプを定義します。

| タイプコード | カテゴリ | タイプ名（日本語） | MVP対象 |
|------------|---------|-------------------|---------|
| guest_parking | parking | ゲスト用駐車場 | ✅ |
| meeting_room | indoor_space | 集会室 | Phase 2 |
| guest_room | indoor_space | ゲストルーム | Phase 2 |
| bicycle_parking | parking | 駐輪場 | Phase 3 |
| bbq_space | outdoor_space | BBQスペース | Phase 3 |

**第3層：施設個体（facility）**

実際に予約対象となる個別の施設です。

| 施設コード | 施設タイプ | 施設名（日本語） | 配置 |
|----------|----------|----------------|------|
| F1 | guest_parking | ゲスト駐車場 F1 | 表側 |
| F2 | guest_parking | ゲスト駐車場 F2 | 表側 |
| ... | ... | ... | ... |
| F6 | guest_parking | ゲスト駐車場 F6 | 表側 |
| B1 | guest_parking | ゲスト駐車場 B1 | 裏側 |
| ... | ... | ... | ... |
| B6 | guest_parking | ゲスト駐車場 B6 | 裏側 |

**参照**: プロダクト開発用_機能要件定義書_v1_1.txt - 3.4.1 対象施設（MVP）

---

### 2.1.2 facility テーブル設計

予約可能な施設の個体情報を管理するテーブルです。

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| facility_id | BIGINT | NOT NULL | PK | 施設ID（主キー、自動採番） |
| facility_type_id | BIGINT | NOT NULL | FK | 施設タイプID（外部キー） |
| facility_code | VARCHAR(20) | NOT NULL | UNIQUE | 施設コード（F1, B1など） |
| facility_name_ja | VARCHAR(100) | NOT NULL | - | 施設名（日本語） |
| facility_name_en | VARCHAR(100) | NOT NULL | - | 施設名（英語） |
| facility_name_cn | VARCHAR(100) | NOT NULL | - | 施設名（中国語） |
| description_ja | TEXT | NULL | - | 説明（日本語） |
| description_en | TEXT | NULL | - | 説明（英語） |
| description_cn | TEXT | NULL | - | 説明（中国語） |
| location | VARCHAR(50) | NULL | - | 配置場所（表側/裏側など） |
| capacity | INT | NULL | - | 収容人数・台数 |
| status | VARCHAR(20) | NOT NULL | - | ステータス（active/inactive/maintenance） |
| image_url | VARCHAR(255) | NULL | - | 施設画像URL |
| sort_order | INT | NOT NULL | - | 表示順序 |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |

#### インデックス

```sql
CREATE INDEX idx_facility_type_id ON facility(facility_type_id);
CREATE INDEX idx_facility_status ON facility(status);
CREATE UNIQUE INDEX idx_facility_code ON facility(facility_code);
```

#### 制約

```sql
ALTER TABLE facility
  ADD CONSTRAINT fk_facility_type
  FOREIGN KEY (facility_type_id) REFERENCES facility_type(facility_type_id);

ALTER TABLE facility
  ADD CONSTRAINT chk_facility_status
  CHECK (status IN ('active', 'inactive', 'maintenance'));
```

#### データ例（MVP：ゲスト駐車場）

```json
{
  "facility_id": 1,
  "facility_type_id": 1,
  "facility_code": "F1",
  "facility_name_ja": "ゲスト駐車場 F1",
  "facility_name_en": "Guest Parking F1",
  "facility_name_cn": "访客停车场 F1",
  "description_ja": "表側駐車場の1番目",
  "description_en": "Front parking space #1",
  "description_cn": "前侧停车位 #1",
  "location": "front",
  "capacity": 1,
  "status": "active",
  "image_url": "/images/parking/F1.jpg",
  "sort_order": 1
}
```

---

### 2.1.3 facility_type テーブル設計

施設タイプの定義を管理するテーブルです。

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| facility_type_id | BIGINT | NOT NULL | PK | 施設タイプID（主キー、自動採番） |
| facility_category_id | BIGINT | NOT NULL | FK | 施設カテゴリID（外部キー） |
| type_code | VARCHAR(50) | NOT NULL | UNIQUE | タイプコード（guest_parking など） |
| type_name_ja | VARCHAR(100) | NOT NULL | - | タイプ名（日本語） |
| type_name_en | VARCHAR(100) | NOT NULL | - | タイプ名（英語） |
| type_name_cn | VARCHAR(100) | NOT NULL | - | タイプ名（中国語） |
| icon | VARCHAR(50) | NULL | - | アイコン識別子 |
| sort_order | INT | NOT NULL | - | 表示順序 |
| is_enabled | BOOLEAN | NOT NULL | - | 有効フラグ |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |

#### インデックス

```sql
CREATE INDEX idx_facility_type_category_id ON facility_type(facility_category_id);
CREATE UNIQUE INDEX idx_facility_type_code ON facility_type(type_code);
```

#### 制約

```sql
ALTER TABLE facility_type
  ADD CONSTRAINT fk_facility_category
  FOREIGN KEY (facility_category_id) REFERENCES facility_category(facility_category_id);
```

#### データ例（MVP：ゲスト駐車場）

```json
{
  "facility_type_id": 1,
  "facility_category_id": 1,
  "type_code": "guest_parking",
  "type_name_ja": "ゲスト用駐車場",
  "type_name_en": "Guest Parking",
  "type_name_cn": "访客停车场",
  "icon": "parking",
  "sort_order": 1,
  "is_enabled": true
}
```

---

### 2.1.4 facility_category テーブル設計

施設カテゴリの定義を管理するテーブルです。

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| facility_category_id | BIGINT | NOT NULL | PK | 施設カテゴリID（主キー、自動採番） |
| category_code | VARCHAR(50) | NOT NULL | UNIQUE | カテゴリコード（parking など） |
| category_name_ja | VARCHAR(100) | NOT NULL | - | カテゴリ名（日本語） |
| category_name_en | VARCHAR(100) | NOT NULL | - | カテゴリ名（英語） |
| category_name_cn | VARCHAR(100) | NOT NULL | - | カテゴリ名（中国語） |
| sort_order | INT | NOT NULL | - | 表示順序 |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |

#### インデックス

```sql
CREATE UNIQUE INDEX idx_facility_category_code ON facility_category(category_code);
```

#### データ例（MVP）

```json
{
  "facility_category_id": 1,
  "category_code": "parking",
  "category_name_ja": "駐車・駐輪施設",
  "category_name_en": "Parking & Bicycle",
  "category_name_cn": "停车与自行车设施",
  "sort_order": 1
}
```

---

## 2.2 予約ルール定義構造

### 2.2.1 facility_rule テーブル設計

施設タイプごとの予約ルールを定義するテーブルです。Chapter 01で説明した「ルール定義層」を具体的なテーブル設計として実装します。

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| facility_rule_id | BIGINT | NOT NULL | PK | 予約ルールID（主キー、自動採番） |
| facility_type_id | BIGINT | NOT NULL | FK | 施設タイプID（外部キー） |
| booking_unit | VARCHAR(20) | NOT NULL | - | 予約単位（day/hour/slot） |
| advance_booking_days | INT | NOT NULL | - | 何日先まで予約可能 |
| max_consecutive_units | INT | NOT NULL | - | 連続予約可能数 |
| max_bookings_per_user | INT | NOT NULL | - | 同時予約可能数 |
| cancellation_deadline | VARCHAR(50) | NOT NULL | - | キャンセル期限（before_start/1day/3days など） |
| requires_approval | BOOLEAN | NOT NULL | - | 承認要否フラグ |
| fee_per_unit | DECIMAL(10,2) | NOT NULL | - | 単位あたり料金 |
| currency | VARCHAR(3) | NOT NULL | - | 通貨（JPY/USD など） |
| min_booking_units | INT | NULL | - | 最小予約単位数 |
| max_booking_units | INT | NULL | - | 最大予約単位数 |
| booking_start_time | TIME | NULL | - | 予約可能開始時刻（時間単位の場合） |
| booking_end_time | TIME | NULL | - | 予約可能終了時刻（時間単位の場合） |
| slot_duration_minutes | INT | NULL | - | スロット時間（分）（slot単位の場合） |
| buffer_time_minutes | INT | NULL | - | バッファー時間（分）（清掃等） |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |

#### インデックス

```sql
CREATE UNIQUE INDEX idx_facility_rule_type_id ON facility_rule(facility_type_id);
```

#### 制約

```sql
ALTER TABLE facility_rule
  ADD CONSTRAINT fk_facility_rule_type
  FOREIGN KEY (facility_type_id) REFERENCES facility_type(facility_type_id);

ALTER TABLE facility_rule
  ADD CONSTRAINT chk_booking_unit
  CHECK (booking_unit IN ('day', 'hour', 'slot'));

ALTER TABLE facility_rule
  ADD CONSTRAINT chk_fee_non_negative
  CHECK (fee_per_unit >= 0);
```

---

### 2.2.2 ゲスト駐車場のルール定義例（MVP）

**参照**: プロダクト開発用_機能要件定義書_v1_1.txt - 3.4.2 予約制限ルール

MVPで実装するゲスト駐車場の予約ルールを以下に定義します。

```json
{
  "facility_rule_id": 1,
  "facility_type_id": 1,
  "booking_unit": "day",
  "advance_booking_days": 30,
  "max_consecutive_units": 3,
  "max_bookings_per_user": 1,
  "cancellation_deadline": "before_start",
  "requires_approval": false,
  "fee_per_unit": 100.00,
  "currency": "JPY",
  "min_booking_units": 1,
  "max_booking_units": 3,
  "booking_start_time": null,
  "booking_end_time": null,
  "slot_duration_minutes": null,
  "buffer_time_minutes": null
}
```

#### ルール解説

| ルール項目 | 設定値 | 意味 |
|-----------|--------|------|
| booking_unit | day | 予約単位は「日」単位 |
| advance_booking_days | 30 | 当日から30日先まで予約可能 |
| max_consecutive_units | 3 | 最大3日間の連続予約が可能 |
| max_bookings_per_user | 1 | 同一ユーザーは同時に1件まで予約可能 |
| cancellation_deadline | before_start | 利用開始前までキャンセル可能 |
| requires_approval | false | 管理者承認は不要（即時確定） |
| fee_per_unit | 100.00 | 1日あたり100円 |
| currency | JPY | 日本円 |

#### 制限ロジックの実装

1. **同日複数予約の防止**
   - 同一ユーザーが同一日に複数の駐車場所を予約不可
   - チェックSQL例：
   ```sql
   SELECT COUNT(*) FROM booking
   WHERE user_id = :user_id
     AND booking_date = :booking_date
     AND status IN ('reserved', 'confirmed')
   ```

2. **連続予約の制限**
   - 1回の予約操作で最大3日間まで
   - 連続日数は `max_consecutive_units` で管理

3. **同時予約数の制限**
   - 未来の予約が既に1件ある場合、新規予約不可
   - チェックSQL例：
   ```sql
   SELECT COUNT(*) FROM booking
   WHERE user_id = :user_id
     AND booking_date >= CURRENT_DATE
     AND status IN ('reserved', 'confirmed')
   ```

---

### 2.2.3 集会室のルール定義例（Phase 2）

Phase 2以降で実装予定の集会室の予約ルール例です。

```json
{
  "facility_rule_id": 2,
  "facility_type_id": 2,
  "booking_unit": "hour",
  "advance_booking_days": 60,
  "max_consecutive_units": 4,
  "max_bookings_per_user": 2,
  "cancellation_deadline": "3days",
  "requires_approval": true,
  "fee_per_unit": 500.00,
  "currency": "JPY",
  "min_booking_units": 2,
  "max_booking_units": 8,
  "booking_start_time": "09:00:00",
  "booking_end_time": "21:00:00",
  "slot_duration_minutes": 60,
  "buffer_time_minutes": 30
}
```

#### ルール解説

| ルール項目 | 設定値 | 意味 |
|-----------|--------|------|
| booking_unit | hour | 予約単位は「時間」単位 |
| advance_booking_days | 60 | 当日から60日先まで予約可能 |
| max_consecutive_units | 4 | 最大4時間の連続予約が可能 |
| max_bookings_per_user | 2 | 同一ユーザーは同時に2件まで予約可能 |
| cancellation_deadline | 3days | 利用3日前までキャンセル可能 |
| requires_approval | true | 管理者承認が必要 |
| fee_per_unit | 500.00 | 1時間あたり500円 |
| min_booking_units | 2 | 最低2時間から予約可能 |
| max_booking_units | 8 | 最大8時間まで予約可能 |
| booking_start_time | 09:00:00 | 利用可能時間：9時開始 |
| booking_end_time | 21:00:00 | 利用可能時間：21時終了 |
| buffer_time_minutes | 30 | 清掃等のバッファー時間30分 |

---

## 2.3 予約データ構造

### 2.3.1 booking テーブル設計

実際の予約データを管理するテーブルです。

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| booking_id | BIGINT | NOT NULL | PK | 予約ID（主キー、自動採番） |
| user_id | BIGINT | NOT NULL | FK | 予約者のユーザーID（外部キー） |
| facility_id | BIGINT | NOT NULL | FK | 予約対象施設ID（外部キー） |
| booking_date | DATE | NOT NULL | - | 予約日 |
| start_time | TIME | NULL | - | 開始時刻（時間単位予約の場合） |
| end_time | TIME | NULL | - | 終了時刻（時間単位予約の場合） |
| booking_units | INT | NOT NULL | - | 予約単位数（日数または時間数） |
| status | VARCHAR(20) | NOT NULL | - | ステータス（reserved/confirmed/cancelled/completed） |
| approval_status | VARCHAR(20) | NULL | - | 承認ステータス（pending/approved/rejected） |
| vehicle_number | VARCHAR(4) | NULL | - | 車両ナンバー下4桁（駐車場の場合） |
| purpose | VARCHAR(255) | NULL | - | 利用目的（集会室の場合） |
| num_participants | INT | NULL | - | 利用人数 |
| fee | DECIMAL(10,2) | NOT NULL | - | 料金 |
| payment_status | VARCHAR(20) | NOT NULL | - | 支払いステータス（unpaid/paid/refunded） |
| notes | TEXT | NULL | - | 備考 |
| parent_booking_id | BIGINT | NULL | FK | 親予約ID（連続予約の場合） |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |
| cancelled_at | TIMESTAMP | NULL | - | キャンセル日時 |

#### インデックス

```sql
CREATE INDEX idx_booking_user_id ON booking(user_id);
CREATE INDEX idx_booking_facility_id ON booking(facility_id);
CREATE INDEX idx_booking_date ON booking(booking_date);
CREATE INDEX idx_booking_status ON booking(status);
CREATE INDEX idx_booking_parent_id ON booking(parent_booking_id);
CREATE INDEX idx_booking_facility_date ON booking(facility_id, booking_date);
```

#### 制約

```sql
ALTER TABLE booking
  ADD CONSTRAINT fk_booking_user
  FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE booking
  ADD CONSTRAINT fk_booking_facility
  FOREIGN KEY (facility_id) REFERENCES facility(facility_id);

ALTER TABLE booking
  ADD CONSTRAINT fk_booking_parent
  FOREIGN KEY (parent_booking_id) REFERENCES booking(booking_id);

ALTER TABLE booking
  ADD CONSTRAINT chk_booking_status
  CHECK (status IN ('reserved', 'confirmed', 'cancelled', 'completed'));

ALTER TABLE booking
  ADD CONSTRAINT chk_approval_status
  CHECK (approval_status IN ('pending', 'approved', 'rejected'));

ALTER TABLE booking
  ADD CONSTRAINT chk_payment_status
  CHECK (payment_status IN ('unpaid', 'paid', 'refunded'));

ALTER TABLE booking
  ADD CONSTRAINT chk_booking_time
  CHECK (start_time IS NULL OR end_time IS NULL OR start_time < end_time);

ALTER TABLE booking
  ADD CONSTRAINT chk_booking_units_positive
  CHECK (booking_units > 0);

ALTER TABLE booking
  ADD CONSTRAINT chk_fee_non_negative
  CHECK (fee >= 0);
```

#### データ例（MVP：ゲスト駐車場予約）

```json
{
  "booking_id": 1001,
  "user_id": 42,
  "facility_id": 3,
  "booking_date": "2025-11-15",
  "start_time": null,
  "end_time": null,
  "booking_units": 1,
  "status": "confirmed",
  "approval_status": null,
  "vehicle_number": "1234",
  "purpose": null,
  "num_participants": null,
  "fee": 100.00,
  "payment_status": "unpaid",
  "notes": null,
  "parent_booking_id": null,
  "created_at": "2025-10-29 14:30:00",
  "updated_at": "2025-10-29 14:30:00",
  "cancelled_at": null
}
```

---

### 2.3.2 連続予約の表現方法

ユーザーが3日間の連続予約を行う場合、以下のように複数のレコードを作成します。

#### 連続予約の実装パターン

**ケース：2025年11月15日〜17日の3日間連続予約**

| booking_id | user_id | facility_id | booking_date | booking_units | parent_booking_id | 備考 |
|-----------|---------|-------------|--------------|---------------|-------------------|------|
| 1001 | 42 | 3 | 2025-11-15 | 1 | NULL | 1日目（親予約） |
| 1002 | 42 | 3 | 2025-11-16 | 1 | 1001 | 2日目（子予約） |
| 1003 | 42 | 3 | 2025-11-17 | 1 | 1001 | 3日目（子予約） |

#### 連続予約の特性

1. **親子関係**
   - 1日目が「親予約」（parent_booking_id = NULL）
   - 2日目以降が「子予約」（parent_booking_id に親のIDを参照）

2. **一括キャンセル**
   - 親予約をキャンセルすると、全ての子予約も自動的にキャンセル
   - 実装例：
   ```sql
   UPDATE booking
   SET status = 'cancelled', cancelled_at = CURRENT_TIMESTAMP
   WHERE booking_id = :parent_booking_id
      OR parent_booking_id = :parent_booking_id;
   ```

3. **部分キャンセル**
   - 子予約のみキャンセルすることも可能（要件次第）
   - MVP では一括キャンセルのみサポート

4. **料金計算**
   - 各レコードに料金を個別に保存
   - 連続予約の合計料金は親予約と子予約の fee を合算

---

### 2.3.3 ステータス管理

#### booking.status（予約ステータス）

| ステータス値 | 意味 | 遷移タイミング |
|------------|------|--------------|
| reserved | 予約済み | 予約確定時（承認不要の場合） |
| confirmed | 確定済み | 管理者承認後（承認必要の場合） |
| cancelled | キャンセル済み | ユーザーまたは管理者がキャンセル時 |
| completed | 利用完了 | 利用日の翌日に自動更新（バッチ処理） |

#### booking.approval_status（承認ステータス）

| ステータス値 | 意味 | 適用条件 |
|------------|------|---------|
| NULL | 承認不要 | facility_rule.requires_approval = false の場合 |
| pending | 承認待ち | 予約作成時（承認必要の場合） |
| approved | 承認済み | 管理者が承認 |
| rejected | 却下済み | 管理者が却下 |

#### booking.payment_status（支払いステータス）

| ステータス値 | 意味 | 適用条件 |
|------------|------|---------|
| unpaid | 未払い | MVP では全ての予約（後日請求） |
| paid | 支払い済み | Phase 2以降でオンライン決済実装時 |
| refunded | 返金済み | キャンセル時の返金処理 |

#### ステータス遷移図

```
[予約作成]
    ↓
[承認不要の場合]               [承認必要の場合]
    ↓                              ↓
status: reserved              status: reserved
approval_status: NULL         approval_status: pending
    ↓                              ↓
    |                          [管理者承認]
    |                              ↓
    |                         approval_status: approved
    |                         status: confirmed
    ↓                              ↓
[利用日当日]                   [利用日当日]
    ↓                              ↓
[利用完了（翌日バッチ）]       [利用完了（翌日バッチ）]
    ↓                              ↓
status: completed             status: completed

※キャンセル時はどの段階からでも status: cancelled へ遷移
```

---

## 2.4 多言語データ構造

### 2.4.1 translation_master テーブル

静的UI要素の多言語翻訳を管理するテーブルです。

**参照**: プロダクト開発用_機能要件定義書_v1_1.txt - 3.8.4 多言語対応

| カラム名 | データ型 | NULL | キー | 説明 |
|---------|---------|------|------|------|
| translation_key | VARCHAR(255) | NOT NULL | PK | 翻訳キー（主キー） |
| ja_text | TEXT | NOT NULL | - | 日本語テキスト |
| en_text | TEXT | NOT NULL | - | 英語テキスト |
| cn_text | TEXT | NOT NULL | - | 中国語テキスト |
| category | VARCHAR(50) | NOT NULL | - | カテゴリ（facility/booking/common など） |
| description | TEXT | NULL | - | 説明・備考 |
| created_at | TIMESTAMP | NOT NULL | - | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | 更新日時 |

#### インデックス

```sql
CREATE INDEX idx_translation_category ON translation_master(category);
```

---

### 2.4.2 施設予約機能で使用する翻訳キー例

施設予約機能で使用する主な翻訳キーを以下に定義します。

#### 施設関連

| 翻訳キー | 日本語 | 英語 | 中国語 | カテゴリ |
|---------|--------|------|--------|---------|
| facility.guest_parking.name | ゲスト用駐車場 | Guest Parking | 访客停车场 | facility |
| facility.guest_parking.description | 来客用の駐車場です | Parking for guests | 访客专用停车场 | facility |
| facility.location.front | 表側 | Front | 前侧 | facility |
| facility.location.back | 裏側 | Back | 后侧 | facility |
| facility.status.available | 予約可能 | Available | 可预订 | facility |
| facility.status.booked | 予約済み | Booked | 已预订 | facility |
| facility.status.my_booking | 自分の予約 | My Booking | 我的预订 | facility |
| facility.status.unavailable | 予約不可 | Unavailable | 不可预订 | facility |

#### 予約フロー関連

| 翻訳キー | 日本語 | 英語 | 中国語 | カテゴリ |
|---------|--------|------|--------|---------|
| booking.select_date | 日付を選択してください | Please select a date | 请选择日期 | booking |
| booking.select_facility | 駐車場所を選択してください | Please select a parking space | 请选择停车位 | booking |
| booking.vehicle_number | 車両ナンバー（任意） | Vehicle Number (Optional) | 车牌号码(可选) | booking |
| booking.vehicle_number.placeholder | 下4桁を入力 | Last 4 digits | 输入后4位 | booking |
| booking.consecutive_days | 連続日数 | Consecutive Days | 连续天数 | booking |
| booking.total_fee | 合計料金 | Total Fee | 总费用 | booking |
| booking.confirm_button | 予約を確定する | Confirm Booking | 确认预订 | booking |
| booking.cancel_button | キャンセル | Cancel | 取消 | booking |

#### 成功・エラーメッセージ

| 翻訳キー | 日本語 | 英語 | 中国語 | カテゴリ |
|---------|--------|------|--------|---------|
| booking.success.title | 予約が完了しました | Booking Completed | 预订完成 | booking |
| booking.success.message | 予約確認メールを送信しました | Confirmation email sent | 已发送确认邮件 | booking |
| booking.error.already_booked | 既に予約されています | Already booked | 已被预订 | booking |
| booking.error.duplicate_booking | 同日に既に予約があります | You already have a booking on this date | 您在此日期已有预订 | booking |
| booking.error.max_consecutive | 連続予約は最大3日間です | Max 3 consecutive days | 最多连续预订3天 | booking |
| booking.error.past_date | 過去の日付は予約できません | Cannot book past dates | 无法预订过去的日期 | booking |
| booking.error.beyond_limit | 予約可能期間を超えています | Beyond booking limit | 超出预订期限 | booking |

#### 予約管理関連

| 翻訳キー | 日本語 | 英語 | 中国語 | カテゴリ |
|---------|--------|------|--------|---------|
| booking.my_bookings | 予約履歴 | My Bookings | 我的预订 | booking |
| booking.upcoming | 今後の予約 | Upcoming | 即将到来 | booking |
| booking.past | 過去の予約 | Past | 过去的预订 | booking |
| booking.cancel_confirm | 予約をキャンセルしますか? | Cancel this booking? | 取消此预订? | booking |
| booking.cancel_success | キャンセルしました | Cancelled | 已取消 | booking |

#### データ例（JSON形式）

```json
[
  {
    "translation_key": "facility.guest_parking.name",
    "ja_text": "ゲスト用駐車場",
    "en_text": "Guest Parking",
    "cn_text": "访客停车场",
    "category": "facility"
  },
  {
    "translation_key": "booking.success.title",
    "ja_text": "予約が完了しました",
    "en_text": "Booking Completed",
    "cn_text": "预订完成",
    "category": "booking"
  },
  {
    "translation_key": "booking.error.already_booked",
    "ja_text": "既に予約されています",
    "en_text": "Already booked",
    "cn_text": "已被预订",
    "category": "booking"
  }
]
```

---

## 2.5 ER図

### 2.5.1 主要エンティティ関係図

```mermaid
erDiagram
    users ||--o{ booking : "creates"
    facility ||--o{ booking : "is_booked"
    facility_type ||--o{ facility : "has"
    facility_category ||--o{ facility_type : "contains"
    facility_type ||--|| facility_rule : "defines"
    booking ||--o{ booking : "parent_booking"
    
    users {
        bigint user_id PK
        varchar email
        varchar name_ja
        varchar language
    }
    
    facility_category {
        bigint facility_category_id PK
        varchar category_code UK
        varchar category_name_ja
        varchar category_name_en
        varchar category_name_cn
    }
    
    facility_type {
        bigint facility_type_id PK
        bigint facility_category_id FK
        varchar type_code UK
        varchar type_name_ja
        varchar type_name_en
        varchar type_name_cn
        boolean is_enabled
    }
    
    facility {
        bigint facility_id PK
        bigint facility_type_id FK
        varchar facility_code UK
        varchar facility_name_ja
        varchar facility_name_en
        varchar facility_name_cn
        varchar location
        int capacity
        varchar status
    }
    
    facility_rule {
        bigint facility_rule_id PK
        bigint facility_type_id FK_UK
        varchar booking_unit
        int advance_booking_days
        int max_consecutive_units
        int max_bookings_per_user
        decimal fee_per_unit
    }
    
    booking {
        bigint booking_id PK
        bigint user_id FK
        bigint facility_id FK
        date booking_date
        time start_time
        time end_time
        int booking_units
        varchar status
        varchar approval_status
        varchar vehicle_number
        decimal fee
        bigint parent_booking_id FK
    }
    
    translation_master {
        varchar translation_key PK
        text ja_text
        text en_text
        text cn_text
        varchar category
    }
```

---

### 2.5.2 カーディナリティ

エンティティ間の関係性を以下に定義します。

| 関係 | エンティティA | 関係性 | エンティティB | 説明 |
|-----|-------------|-------|-------------|------|
| 1:N | users | 1 | N | booking | 1人のユーザーは複数の予約を持つ |
| 1:N | facility | 1 | N | booking | 1つの施設は複数の予約を受ける |
| 1:N | facility_type | 1 | N | facility | 1つの施設タイプは複数の施設個体を持つ |
| 1:N | facility_category | 1 | N | facility_type | 1つのカテゴリは複数のタイプを含む |
| 1:1 | facility_type | 1 | 1 | facility_rule | 1つのタイプは1つのルールを持つ |
| 1:N | booking (親) | 1 | N | booking (子) | 連続予約の親子関係 |

#### 参照整合性

- **ON DELETE RESTRICT**: facility_category, facility_type, facility
  - 子レコードが存在する場合、削除不可
- **ON DELETE CASCADE**: booking (parent_booking_id)
  - 親予約が削除されると、子予約も自動削除
- **ON UPDATE CASCADE**: 全ての外部キー
  - 親レコードの主キー更新時、自動的に子レコードも更新

---

## 2.6 データ整合性ルール

### 2.6.1 制約条件

データの整合性を保つための制約条件を定義します。

#### 1. ユニーク制約

```sql
-- 同一施設で同一日に複数予約を防止
CREATE UNIQUE INDEX idx_booking_unique_facility_date_user
ON booking(facility_id, booking_date, user_id)
WHERE status IN ('reserved', 'confirmed');
```

#### 2. 時刻制約

```sql
-- 開始時刻 < 終了時刻
ALTER TABLE booking
  ADD CONSTRAINT chk_booking_time_order
  CHECK (start_time < end_time OR (start_time IS NULL AND end_time IS NULL));
```

#### 3. 予約単位数制約

```sql
-- 予約単位数は正の整数
ALTER TABLE booking
  ADD CONSTRAINT chk_booking_units_positive
  CHECK (booking_units > 0);

-- 最大予約単位数の制限（ルールテーブルと連携）
-- アプリケーションレイヤーで実装
```

#### 4. 日付制約

```sql
-- 過去日の予約を防止（アプリケーションレイヤーで実装）
-- ※データベースレベルでは CURRENT_DATE を使用した制約は非推奨
```

#### 5. 料金制約

```sql
-- 料金は0以上
ALTER TABLE booking
  ADD CONSTRAINT chk_fee_non_negative
  CHECK (fee >= 0);
```

#### 6. ステータス制約

```sql
-- status の値は定義された値のみ
ALTER TABLE booking
  ADD CONSTRAINT chk_booking_status_valid
  CHECK (status IN ('reserved', 'confirmed', 'cancelled', 'completed'));

-- approval_status の値は定義された値のみ
ALTER TABLE booking
  ADD CONSTRAINT chk_approval_status_valid
  CHECK (approval_status IS NULL OR approval_status IN ('pending', 'approved', 'rejected'));
```

---

### 2.6.2 排他制御

複数ユーザーが同時に同じ施設・日付を予約しようとした場合の二重予約を防止するため、排他制御を実装します。

#### 実装方式：PESSIMISTIC LOCK（悲観的ロック）

予約処理時に、対象の facility レコードに対して行ロックを取得します。

#### 実装例（PostgreSQL）

```sql
BEGIN;

-- 1. 対象施設をロック
SELECT * FROM facility
WHERE facility_id = :facility_id
FOR UPDATE;

-- 2. 予約可能かチェック
SELECT COUNT(*) FROM booking
WHERE facility_id = :facility_id
  AND booking_date = :booking_date
  AND status IN ('reserved', 'confirmed');

-- 3. 予約が存在しない場合のみ、新規予約を作成
INSERT INTO booking (
  user_id, facility_id, booking_date, booking_units, status, fee, payment_status, created_at, updated_at
) VALUES (
  :user_id, :facility_id, :booking_date, :booking_units, 'reserved', :fee, 'unpaid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);

COMMIT;
```

#### 実装例（NestJS + TypeORM）

```typescript
async createBooking(bookingDto: CreateBookingDto): Promise<Booking> {
  return await this.dataSource.transaction(async (manager) => {
    // 1. 施設をロック
    const facility = await manager
      .createQueryBuilder(Facility, 'facility')
      .setLock('pessimistic_write')
      .where('facility.facility_id = :facilityId', { facilityId: bookingDto.facilityId })
      .getOne();

    if (!facility) {
      throw new NotFoundException('Facility not found');
    }

    // 2. 既存予約をチェック
    const existingBooking = await manager
      .createQueryBuilder(Booking, 'booking')
      .where('booking.facility_id = :facilityId', { facilityId: bookingDto.facilityId })
      .andWhere('booking.booking_date = :bookingDate', { bookingDate: bookingDto.bookingDate })
      .andWhere('booking.status IN (:...statuses)', { statuses: ['reserved', 'confirmed'] })
      .getOne();

    if (existingBooking) {
      throw new ConflictException('Already booked');
    }

    // 3. 新規予約を作成
    const booking = manager.create(Booking, {
      ...bookingDto,
      status: 'reserved',
      paymentStatus: 'unpaid',
    });

    return await manager.save(booking);
  });
}
```

#### タイムアウト設定

```sql
-- PostgreSQL: ロック取得のタイムアウトを5秒に設定
SET lock_timeout = '5s';
```

#### 楽観的ロックとの比較

| 比較項目 | 悲観的ロック（採用） | 楽観的ロック |
|---------|------------------|------------|
| 実装方式 | FOR UPDATE | version カラム |
| 競合時の挙動 | 待機 → 順次処理 | 後勝ち → エラー |
| パフォーマンス | やや低い | 高い |
| 二重予約防止 | 確実 | リトライが必要 |
| 適用シーン | 予約システム | 更新頻度が低いデータ |

**採用理由**：予約システムでは「確実な二重予約防止」が最優先であるため、悲観的ロックを採用します。

---

## 📖 ナビゲーション

- [⬅️ 前の章: Chapter 01 - 概要・MVP機能セット](facility-booking-feature-design-ch01_v1.0.md)
- [➡️ 次の章: Chapter 03 - 予約フロー・画面構成](facility-booking-feature-design-ch03_v1.0.md)
- [📚 目次に戻る](facility-booking-feature-design-ch00-index_v1.0.md)

---

**文書管理情報**

- **作成日**: 2025年10月29日
- **作成者**: HarmoNet開発チーム
- **承認者**: TKD
- **文書分類**: 詳細設計書
- **セキュリティレベル**: 社外秘

---

© 2025 HarmoNet Project. All rights reserved.
