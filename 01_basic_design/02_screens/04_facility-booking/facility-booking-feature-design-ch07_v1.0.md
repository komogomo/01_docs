# 施設予約機能 詳細設計書 Chapter 07: 将来拡張・補足

**HarmoNet スマートコミュニケーションアプリ**

**文書ID**: HARMONET-FACILITY-BOOKING-DESIGN-001-CH07  
**バージョン**: v1.0  
**最終更新**: 2025年10月29日  
**ステータス**: 承認待ち

---

## 📑 目次

- [7.1 将来実装機能](#71-将来実装機能)
  - [7.1.1 予約変更機能](#711-予約変更機能)
  - [7.1.2 予約リマインダー機能](#712-予約リマインダー機能)
  - [7.1.3 予約制限ルールの強化](#713-予約制限ルールの強化)
  - [7.1.4 管理者向けレポート機能](#714-管理者向けレポート機能)
  - [7.1.5 駐車場情報の充実](#715-駐車場情報の充実)
- [7.2 他施設への拡張](#72-他施設への拡張)
  - [7.2.1 集会所予約](#721-集会所予約)
  - [7.2.2 施設マスタ管理](#722-施設マスタ管理)
  - [7.2.3 施設種別の拡張性](#723-施設種別の拡張性)
  - [7.2.4 IoT連携の将来構想](#724-iot連携の将来構想)
- [7.3 決済機能の追加](#73-決済機能の追加)
  - [7.3.1 オンライン決済](#731-オンライン決済)
  - [7.3.2 請求書管理](#732-請求書管理)
- [7.4 AI・機械学習の活用](#74-ai機械学習の活用)
  - [7.4.1 予約需要予測](#741-予約需要予測)
  - [7.4.2 異常検知](#742-異常検知)
- [7.5 技術的補足](#75-技術的補足)
  - [7.5.1 排他制御の詳細](#751-排他制御の詳細)
  - [7.5.2 パフォーマンス最適化](#752-パフォーマンス最適化)
  - [7.5.3 セキュリティ強化](#753-セキュリティ強化)
  - [7.5.4 監視・ログ](#754-監視ログ)
- [7.6 運用・保守](#76-運用保守)
  - [7.6.1 データバックアップ](#761-データバックアップ)
  - [7.6.2 バージョンアップ手順](#762-バージョンアップ手順)
  - [7.6.3 障害対応](#763-障害対応)
- [7.7 用語集](#77-用語集)
- [7.8 参考資料](#78-参考資料)
- [7.9 まとめ](#79-まとめ)

---

## 7.1 将来実装機能

MVP（Minimum Viable Product）完成後に実装を検討する機能について記載します。各機能には実装優先度と実装時期の目安を設定しています。

### 7.1.1 予約変更機能

#### 概要
予約確定後に、日付または駐車場所の変更を可能とする機能です。

#### 現状（MVP）
予約変更が必要な場合は、既存予約をキャンセルしてから新規予約を行う運用としています。

#### 将来実装内容

**変更フロー**:
1. 予約詳細画面から「変更」ボタンをタップ
2. 変更画面へ遷移（日付変更 or 駐車場所変更を選択）
3. 変更内容を入力
   - **日付変更**: カレンダーから新しい日付を選択
   - **駐車場所変更**: 同日の空き駐車場から選択
4. 変更確認画面で内容確認
5. 変更確定ボタンで変更を確定
6. 変更完了メール送信（多言語対応）

**変更制限**:
- 利用開始の24時間前まで変更可能
- 変更は1回まで（2回目以降は要キャンセル）
- 変更後も予約制限ルール（連続3日間等）を適用

**実装優先度**: 高（MVP後 Phase 1）

**技術的課題**:
- 排他制御の拡張（変更処理中の二重予約防止）
- 変更履歴の記録（`reservation_history`テーブル）
- 変更通知の多言語対応
- ロールバック処理の実装

**データモデル拡張**:
```sql
-- 変更履歴テーブル
CREATE TABLE reservation_history (
  history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES parking_reservations(reservation_id),
  changed_by UUID NOT NULL REFERENCES users(user_id),
  change_type VARCHAR(20) NOT NULL, -- 'date_change', 'space_change', 'cancel'
  old_value JSONB,
  new_value JSONB,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 7.1.2 予約リマインダー機能

#### 概要
利用前日・当日に確認通知を送信し、予約忘れを防止する機能です。

#### 通知タイミング

| タイミング | 送信時刻 | 通知内容 |
|-----------|---------|---------|
| 利用前日 | 18:00 | 翌日の予約確認、注意事項 |
| 利用当日 | 08:00 | 当日の予約確認、駐車場所 |

#### 通知方法
- **プッシュ通知**: アプリ内通知（設定ON時）
- **メール通知**: 登録メールアドレスへ送信（設定ON時）
- **多言語対応**: ユーザーの言語設定に応じた通知文面

#### 通知内容例（日本語）
```
【予約リマインダー】
明日のゲスト駐車場予約のお知らせです。

予約日時: 2025年10月30日
駐車場所: P-03
利用時間: 終日

＜注意事項＞
・車両番号の事前登録をお願いします
・時間を過ぎた場合は自動的にキャンセルとなります

予約の確認・変更はアプリから行えます。
```

**実装優先度**: 中（MVP後 Phase 2）

**技術的実装**:
```javascript
// バッチ処理（Node.js + node-cron）
const cron = require('node-cron');

// 前日18:00に実行
cron.schedule('0 18 * * *', async () => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  // 翌日の予約を取得
  const reservations = await getReservationsByDate(tomorrow);
  
  // 通知送信
  for (const reservation of reservations) {
    await sendReminderNotification(reservation, 'day_before');
  }
});

// 当日8:00に実行
cron.schedule('0 8 * * *', async () => {
  const today = new Date();
  
  // 当日の予約を取得
  const reservations = await getReservationsByDate(today);
  
  // 通知送信
  for (const reservation of reservations) {
    await sendReminderNotification(reservation, 'same_day');
  }
});
```

---

### 7.1.3 予約制限ルールの強化

#### 概要
同一ユーザーの予約回数制限を追加し、特定ユーザーによる長期占有を防止します。

#### 現状（MVP）
- 同日複数予約禁止
- 連続3日間までの予約可能

#### 将来追加ルール

| ルール | 内容 | 優先度 |
|-------|------|-------|
| 月間予約回数上限 | 1ユーザーあたり月10回まで | 中 |
| 週間予約回数上限 | 1ユーザーあたり週3回まで | 低 |
| 繁忙期の予約制限 | 年末年始は1週間前から予約可 | 低 |
| 予約頻度の監視 | 短時間での予約・キャンセル繰り返しを検知 | 高 |

**実装優先度**: 低（MVP後 Phase 3）

#### 管理画面での設定

管理者が予約制限ルールを柔軟に設定できるUIを提供します。

**設定項目**:
- 各ルールのON/OFF切り替え
- 上限回数の設定（月間、週間）
- 繁忙期の期間設定
- ルール変更履歴の記録

**データモデル**:
```sql
-- 予約制限ルール設定テーブル
CREATE TABLE reservation_rules (
  rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
  rule_type VARCHAR(50) NOT NULL, -- 'monthly_limit', 'weekly_limit', 'busy_season'
  rule_value JSONB NOT NULL, -- {"max_count": 10, "period": "month"}
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 7.1.4 管理者向けレポート機能

#### 概要
駐車場の稼働率を分析し、統計レポートを生成する機能です。

#### レポート内容

**1. 稼働率レポート**
- 月別稼働率（全体・駐車場所別）
- 週別稼働率推移
- 曜日別平均稼働率
- 時期別（繁忙期・閑散期）の比較

**2. 利用統計レポート**
- 人気の駐車場所ランキング
- 時間帯別予約件数
- ユーザー別予約履歴
- キャンセル率の分析

**3. エクスポート機能**
- CSV形式でのデータエクスポート
- PDF形式でのレポート出力
- 管理委員会への月次レポート自動生成

**実装優先度**: 中（MVP後 Phase 2）

#### グラフ表示例

**稼働率推移グラフ（折れ線グラフ）**:
```javascript
// Chart.js を使用した実装例
const data = {
  labels: ['1月', '2月', '3月', '4月', '5月', '6月'],
  datasets: [{
    label: '稼働率 (%)',
    data: [65, 72, 68, 80, 75, 82],
    borderColor: 'rgb(75, 192, 192)',
    tension: 0.1
  }]
};
```

**駐車場所別利用回数（棒グラフ）**:
- P-01 ~ P-12の各駐車場所の利用回数を可視化
- 人気の駐車場所を特定

**曜日別平均稼働率（円グラフ）**:
- 月曜日～日曜日の稼働率を比較
- 繁忙曜日の特定

---

### 7.1.5 駐車場情報の充実

#### 概要
各駐車スペースに詳細情報を追加し、ユーザーが最適な駐車場所を選択できるようにします。

#### 追加情報

| 情報項目 | 内容 | 表示方法 |
|---------|------|---------|
| 駐車場所写真 | 実際の駐車スペースの写真 | 画像表示 |
| 車両サイズ制限 | 大型車・標準車・コンパクト | アイコン表示 |
| 屋根の有無 | 屋根付き・屋根なし | アイコン表示 |
| EV充電設備 | 充電器の有無 | アイコン表示 |
| アクセス情報 | エレベーターからの距離 | テキスト表示 |

**実装優先度**: 低（MVP後 Phase 3）

#### データモデル拡張

```sql
-- parking_spacesテーブルの拡張
ALTER TABLE parking_spaces
ADD COLUMN photo_url TEXT,
ADD COLUMN vehicle_size_limit VARCHAR(20), -- 'standard', 'large', 'compact'
ADD COLUMN has_roof BOOLEAN DEFAULT FALSE,
ADD COLUMN has_ev_charger BOOLEAN DEFAULT FALSE,
ADD COLUMN access_info JSONB; -- {"elevator_distance": "20m", "floor": "B1"}
```

#### UI表示例

```
[駐車場所 P-03の詳細]
📷 [駐車スペース写真]
🚗 車両サイズ: 標準車
☂️ 屋根: あり
⚡ EV充電器: あり
📍 エレベーターから徒歩30秒
```

---

## 7.2 他施設への拡張

MVP完成後、ゲスト用駐車場以外の共用施設にも予約機能を拡張します。

**参照**: 施設予約追加機能要件検討資料.md

### 基本方針

HarmoNetの施設予約機能は、「施設の種類が異なっても共通の予約構造で管理できる」ことを目的とします。

**設計原則**:
1. 施設間の差異は**ルール定義層（facility_rule）**で吸収
2. UIは全施設共通の流れ（予約 → 確認 → 完了）を維持
3. テナント単位で施設を管理し、複数物件に対応
4. DBスキーマ変更なしで施設追加・削除が可能

---

### 7.2.1 集会所予約

#### 概要
ゲスト用駐車場に加え、集会所の予約機能を追加します。

#### 予約対象

| 施設名 | 定員 | 設備 | 予約単位 |
|-------|------|------|---------|
| 集会所（大） | 50名 | プロジェクター、音響、キッチン | 1時間単位 |
| 集会所（小） | 20名 | ホワイトボード、Wi-Fi | 1時間単位 |

#### 予約条件

**予約単位**: 時間単位（1時間〜4時間）

**利用料金**:
- 集会所（大）: 1時間あたり500円
- 集会所（小）: 1時間あたり300円
- キッチン利用: +200円

**予約制限**:
- 2ヶ月先まで予約可能
- 同日の複数予約不可
- 利用開始2日前までキャンセル可能

**利用時間**:
- 平日: 9:00 ~ 21:00
- 土日祝: 9:00 ~ 18:00

**実装優先度**: 中（MVP後 Phase 2）

#### 駐車場との違い

| 項目 | 駐車場 | 集会所 |
|------|-------|-------|
| 予約単位 | 日単位 | 時間単位 |
| 利用料金 | 無料 | 有料（時間制） |
| キャンセル | 当日可 | 2日前まで |
| 承認 | 不要 | 不要（即時確定） |

---

### 7.2.2 施設マスタ管理

#### 概要
予約可能施設を管理画面から追加・編集できるようにします。

**参照**: 施設予約追加機能要件検討資料.md - 3. 施設構造に関する前提

#### 施設管理の3層構造

```
facility_master (施設基本情報)
    ↓
facility_rule (施設運用ルール)
    ↓
reservation (予約データ)
```

#### テーブル構造

**1. facility_master（施設基本情報）**

```sql
CREATE TABLE facility_master (
  facility_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
  facility_type VARCHAR(50) NOT NULL, -- 'parking', 'meeting_room', 'guest_room', 'lounge', 'ev_charger'
  name VARCHAR(100) NOT NULL,
  description TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE
);

-- インデックス
CREATE INDEX idx_facility_tenant_active ON facility_master(tenant_id, is_active);
```

**2. facility_rule（施設運用ルール）**

```sql
CREATE TABLE facility_rule (
  rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facility_master(facility_id) ON DELETE CASCADE,
  booking_unit VARCHAR(20) NOT NULL, -- 'day', 'hour', 'half_hour'
  open_time TIME, -- 利用開始可能時間
  close_time TIME, -- 利用終了時間
  max_booking_days INTEGER DEFAULT 30, -- 何日先まで予約可能
  max_reservations_per_user INTEGER, -- 1ユーザーあたりの最大予約数（月間）
  allow_repeat BOOLEAN DEFAULT FALSE, -- 連続予約可否
  max_repeat_days INTEGER, -- 最大連続日数
  cancellation_deadline_hours INTEGER DEFAULT 24, -- キャンセル期限（何時間前まで）
  require_approval BOOLEAN DEFAULT FALSE, -- 管理者承認が必要か
  fee_type VARCHAR(20), -- 'free', 'fixed', 'hourly'
  fee_amount INTEGER DEFAULT 0, -- 料金（円）
  fee_point INTEGER DEFAULT 0, -- 将来的なポイント消費
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_facility_rule_facility ON facility_rule(facility_id);
```

**3. facility_i18n（多言語対応）**

```sql
CREATE TABLE facility_i18n (
  i18n_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facility_master(facility_id) ON DELETE CASCADE,
  language_code VARCHAR(5) NOT NULL, -- 'ja', 'en', 'zh-CN'
  name VARCHAR(100) NOT NULL,
  description TEXT,
  usage_notes TEXT, -- 利用上の注意事項
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(facility_id, language_code)
);

-- インデックス
CREATE INDEX idx_facility_i18n_lookup ON facility_i18n(facility_id, language_code);
```

**4. reservation（予約データ - 共通構造）**

```sql
CREATE TABLE reservation (
  reservation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facility_master(facility_id),
  user_id UUID NOT NULL REFERENCES users(user_id),
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  participants INTEGER, -- 利用人数
  purpose TEXT, -- 利用目的
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'confirmed', 'cancelled'
  note TEXT,
  reservation_meta JSONB, -- 拡張データ（IoT連携、エネルギー使用等）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version INTEGER DEFAULT 1, -- 楽観的ロック用
  CONSTRAINT chk_reservation_time CHECK (end_time > start_time)
);

-- インデックス
CREATE INDEX idx_reservation_facility_time ON reservation(facility_id, start_time, end_time);
CREATE INDEX idx_reservation_user ON reservation(user_id, start_time);
CREATE INDEX idx_reservation_status ON reservation(status);
```

#### 管理画面機能

**施設一覧画面**:
- テナント内の全施設を表示
- 有効/無効の切り替え
- 表示順の変更（ドラッグ&ドロップ）

**施設登録・編集画面**:
- 施設基本情報の入力
- 施設種別の選択
- 画像アップロード
- 運用ルールの設定
- 多言語対応（日本語・英語・中国語）

**実装優先度**: 低（MVP後 Phase 3）

---

### 7.2.3 施設種別の拡張性

**参照**: 施設予約追加機能要件検討資料.md - 2. 対象範囲

#### 想定施設種別

HarmoNetでは以下のような多様な施設種別に対応可能です。

**1. 室内系施設**
- 集会室（大・小）
- パーティールーム
- シアタールーム
- ワークスペース
- ライブラリー

**2. 宿泊・駐車系施設**
- ゲストルーム（和室・洋室）
- ゲスト用駐車場
- 来客用バイク駐輪場

**3. 共用スペース系施設**
- ラウンジ
- テラス
- バーベキュースペース
- キッズルーム
- フィットネスジム

**4. 機能設備系施設**
- EV充電器
- 宅配ボックス（大型）
- 自転車整備スペース

#### 施設ごとの特性管理

各施設種別は`facility_rule`テーブルで以下の特性を持ちます。

| 特性 | 設定項目 | 例 |
|------|---------|---|
| 予約単位 | `booking_unit` | 日単位/時間単位/30分単位 |
| 利用時間 | `open_time`, `close_time` | 9:00-21:00 |
| 予約可能期間 | `max_booking_days` | 30日先まで/60日先まで |
| 承認要否 | `require_approval` | true/false |
| 料金 | `fee_type`, `fee_amount` | 無料/500円/時 |

#### 施設の有効化・無効化

各テナント（物件）は、必要な施設のみを有効化できます。

**例: マンションA**
- ✅ ゲスト用駐車場
- ✅ 集会所（大）
- ❌ ゲストルーム（未設置）
- ❌ EV充電器（未設置）

**例: マンションB**
- ✅ ゲスト用駐車場
- ✅ ゲストルーム
- ✅ EV充電器
- ❌ 集会所（未設置）

---

### 7.2.4 IoT連携の将来構想

#### 概要
将来的にIoTデバイスと連携し、施設利用の自動化を実現します。

**参照**: 施設予約追加機能要件検討資料.md - 6. 非機能的配慮

#### 想定連携例

**1. スマートロック連携**
- 予約確定時に自動で入室キーを発行
- 予約時間のみ解錠可能
- 入退室ログの記録

**2. EV充電器連携**
- 予約時間のみ充電器が稼働
- 充電量の記録・請求
- 充電完了通知

**3. エネルギー使用量連携**
- 集会所の電気・ガス使用量を記録
- エコポイントの付与
- 使用量レポートの生成

#### データ拡張

`reservation_meta`（JSONB）カラムで拡張データを管理します。

```json
{
  "smart_lock": {
    "key_id": "abc123",
    "unlock_time": "2025-10-30T10:00:00Z",
    "lock_time": "2025-10-30T12:00:00Z"
  },
  "ev_charger": {
    "charger_id": "ev-001",
    "start_charge": "50%",
    "end_charge": "80%",
    "kwh_used": 15.5
  },
  "energy_usage": {
    "electricity_kwh": 12.3,
    "gas_m3": 0.5
  }
}
```

**実装優先度**: 低（MVP後 Phase 4）

---

## 7.3 決済機能の追加

### 7.3.1 オンライン決済

#### 概要
アプリ内でクレジットカード決済を可能にします。

#### 現状（MVP）
施設利用料金は後日請求（管理費に合算）としています。

#### 将来実装内容

**対応決済方法**:
- クレジットカード決済（Visa, Mastercard, JCB）
- 電子マネー決済（PayPay, LINE Pay, 楽天Pay）
- Apple Pay / Google Pay

**決済タイミング**:
- 予約確定時に即時決済
- キャンセル時の返金処理

**実装優先度**: 低（MVP後 Phase 4）

#### 技術的実装（Stripe連携）

```javascript
// Stripe Payment Intent APIの利用
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

async function createPaymentIntent(amount, currency = 'jpy') {
  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount, // 金額（円）
    currency: currency,
    automatic_payment_methods: {
      enabled: true,
    },
    metadata: {
      reservation_id: 'res_12345',
      facility_id: 'fac_67890'
    }
  });
  
  return paymentIntent.client_secret;
}

// 決済履歴の記録
CREATE TABLE payment_history (
  payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES reservation(reservation_id),
  payment_method VARCHAR(50), -- 'credit_card', 'e_money'
  amount INTEGER NOT NULL,
  status VARCHAR(20) NOT NULL, -- 'pending', 'completed', 'refunded'
  stripe_payment_intent_id VARCHAR(100),
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 領収書発行

決済完了後、PDF形式の領収書を自動生成します。

**領収書記載内容**:
- 発行日時
- 支払者情報
- 施設名・利用日時
- 利用料金
- 決済方法

---

### 7.3.2 請求書管理

#### 概要
月次請求書の自動生成と送信を行います。

#### 機能詳細

**月末バッチ処理**:
1. 月末に当月の利用料金を集計
2. 請求書PDFを自動生成
3. ユーザーにメール送信（多言語対応）
4. 管理者に集計レポート送信

**請求書内容**:
- 請求月
- 施設別利用明細
- 合計金額
- 支払期限
- 振込先情報

**実装優先度**: 中（MVP後 Phase 2）

#### 実装例

```javascript
// 月次請求書生成バッチ
const cron = require('node-cron');
const PDFDocument = require('pdfkit');

// 毎月末日23:00に実行
cron.schedule('0 23 L * *', async () => {
  const lastDayOfMonth = getLastDayOfMonth();
  
  // 全ユーザーの当月利用料金を集計
  const users = await getAllUsers();
  
  for (const user of users) {
    const usage = await calculateMonthlyUsage(user.user_id, lastDayOfMonth);
    
    if (usage.total_amount > 0) {
      // 請求書PDF生成
      const pdfPath = await generateInvoicePDF(user, usage);
      
      // メール送信
      await sendInvoiceEmail(user, pdfPath);
    }
  }
  
  // 管理者へ集計レポート送信
  await sendMonthlyReportToAdmin();
});
```

---

## 7.4 AI・機械学習の活用

### 7.4.1 予約需要予測

#### 概要
過去の予約データから需要を予測し、ユーザーに最適な予約日時を提案します。

#### 予測内容

**1. 混雑予測**
- 曜日別・時期別の混雑予測
- イベント前後の需要増加予測
- 長期休暇期間の予約傾向分析

**2. 推奨予約日時**
- ユーザーの過去の予約パターンから推奨
- 空き状況と混雑予測を組み合わせた提案
- 「この日時は予約しやすいです」メッセージ表示

**3. 動的価格設定（将来構想）**
- 需要に応じた料金変動
- 閑散期の割引設定
- 繁忙期の価格調整

**実装優先度**: 低（MVP後 Phase 4）

#### 技術スタック

```python
# Python (scikit-learn) を使用した時系列予測
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from statsmodels.tsa.arima.model import ARIMA

# 予約データの読み込み
reservations_df = pd.read_sql('SELECT * FROM reservation', conn)

# 特徴量エンジニアリング
reservations_df['day_of_week'] = pd.to_datetime(reservations_df['start_time']).dt.dayofweek
reservations_df['month'] = pd.to_datetime(reservations_df['start_time']).dt.month
reservations_df['is_holiday'] = reservations_df['start_time'].apply(is_holiday)

# モデル訓練
model = RandomForestRegressor(n_estimators=100)
model.fit(X_train, y_train)

# 需要予測
predicted_demand = model.predict(X_test)
```

#### LSTM（深層学習）モデルの活用

```python
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense

# LSTMモデルの構築
model = Sequential([
    LSTM(50, return_sequences=True, input_shape=(30, 5)),  # 過去30日分のデータ
    LSTM(50),
    Dense(1)  # 予測値（予約数）
])

model.compile(optimizer='adam', loss='mse')
model.fit(X_train, y_train, epochs=50, batch_size=32)
```

---

### 7.4.2 異常検知

#### 概要
不正予約・キャンセルの繰り返しなど、異常な利用パターンを検知します。

#### 検知対象

**1. 不正予約パターン**
- 繰り返しの予約・キャンセル（1週間に5回以上）
- 予約後の長期間利用なし（予約したが実際は利用しない）
- 同一ユーザーの大量予約（月間20件以上）

**2. 転売目的の検知**
- 予約直後のキャンセル繰り返し
- 特定日時への集中予約

**実装優先度**: 低（MVP後 Phase 4）

#### 対応方法

**自動アラート**:
```javascript
// 異常検知バッチ
async function detectAnomalies() {
  // 1週間以内のキャンセル回数をチェック
  const suspiciousUsers = await db.query(`
    SELECT user_id, COUNT(*) as cancel_count
    FROM reservation
    WHERE status = 'cancelled'
      AND updated_at >= NOW() - INTERVAL '7 days'
    GROUP BY user_id
    HAVING COUNT(*) >= 5
  `);
  
  for (const user of suspiciousUsers) {
    // 管理者へアラート送信
    await sendAlertToAdmin({
      type: 'frequent_cancellation',
      user_id: user.user_id,
      cancel_count: user.cancel_count
    });
    
    // ユーザーの予約を一時制限
    await restrictUserReservation(user.user_id);
  }
}
```

**予約制限措置**:
- 該当ユーザーの予約を承認制に変更
- 予約回数の制限強化
- 管理者による個別審査

---

## 7.5 技術的補足

### 7.5.1 排他制御の詳細

#### 楽観的ロック vs 悲観的ロック

HarmoNetでは、**楽観的ロック**を採用します。

#### 採用理由

| 項目 | 楽観的ロック | 悲観的ロック |
|------|-------------|-------------|
| 競合頻度 | 低頻度向き（12台の駐車場） | 高頻度向き |
| パフォーマンス | 高速 | 低速（ロック待ち発生） |
| デッドロック | リスク低 | リスク高 |
| 実装複雑度 | シンプル | 複雑 |

#### 実装例（楽観的ロック）

```sql
-- バージョン番号を使った楽観的ロック
UPDATE reservation
SET status = 'confirmed',
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE reservation_id = $1
  AND version = $2;

-- 更新行数が0の場合は競合発生
-- アプリケーション側でリトライまたはエラー表示
```

```javascript
// Node.js での実装例
async function confirmReservation(reservationId, currentVersion) {
  const result = await db.query(
    `UPDATE reservation
     SET status = 'confirmed', version = version + 1, updated_at = CURRENT_TIMESTAMP
     WHERE reservation_id = $1 AND version = $2`,
    [reservationId, currentVersion]
  );
  
  if (result.rowCount === 0) {
    throw new Error('予約が競合しました。もう一度お試しください。');
  }
  
  return { success: true };
}
```

#### トランザクション分離レベル

**PostgreSQL デフォルト**: `READ COMMITTED`

**予約確定時のみ**: `SERIALIZABLE` に変更

```javascript
// トランザクション分離レベルの設定
await db.query('BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE');

try {
  // 予約確定処理
  await confirmReservation(reservationId, version);
  await db.query('COMMIT');
} catch (error) {
  await db.query('ROLLBACK');
  throw error;
}
```

---

### 7.5.2 パフォーマンス最適化

#### データベースインデックス

```sql
-- 予約検索の高速化
CREATE INDEX idx_reservations_facility_time 
ON reservation(facility_id, start_time, end_time);

CREATE INDEX idx_reservations_user_date 
ON reservation(user_id, start_time);

CREATE INDEX idx_reservations_status 
ON reservation(status);

-- 翻訳キャッシュの高速化
CREATE INDEX idx_translation_cache_hash 
ON translation_cache(source_hash, source_lang, target_lang);

-- 施設検索の高速化
CREATE INDEX idx_facility_tenant_active 
ON facility_master(tenant_id, is_active);

-- 複合インデックス（カバリングインデックス）
CREATE INDEX idx_reservation_lookup 
ON reservation(facility_id, start_time, status) 
INCLUDE (user_id, end_time);
```

#### キャッシュ戦略

**Redis によるキャッシュ**:

```javascript
const redis = require('redis');
const client = redis.createClient();

// 予約状況のキャッシュ（5分間）
async function getReservationStatus(facilityId, date) {
  const cacheKey = `reservation:${facilityId}:${date}`;
  
  // キャッシュチェック
  const cached = await client.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }
  
  // DBから取得
  const status = await db.query(
    'SELECT * FROM reservation WHERE facility_id = $1 AND DATE(start_time) = $2',
    [facilityId, date]
  );
  
  // キャッシュに保存（300秒 = 5分）
  await client.setex(cacheKey, 300, JSON.stringify(status));
  
  return status;
}
```

**ブラウザキャッシュ**:
- 静的コンテンツ（画像、CSS、JS）: 1週間
- 施設情報: 1時間
- ユーザー情報: セッション期間中

#### API レスポンスタイム目標

| API | 目標レスポンスタイム | 備考 |
|-----|-------------------|------|
| 予約一覧取得 | 200ms以内 | インデックス最適化 |
| 予約確定 | 500ms以内 | トランザクション処理含む |
| 翻訳リクエスト | 1秒以内 | 外部API呼び出しあり |
| 翻訳（キャッシュヒット） | 50ms以内 | Redisから取得 |
| 施設一覧取得 | 100ms以内 | キャッシュ活用 |

---

### 7.5.3 セキュリティ強化

#### CSRF対策

```javascript
// CSRFトークンの生成
const crypto = require('crypto');

function generateCsrfToken(sessionId) {
  const csrfToken = crypto.randomBytes(32).toString('hex');
  await redis.set(`csrf:${sessionId}`, csrfToken, 'EX', 3600);
  return csrfToken;
}

// リクエスト検証ミドルウェア
async function verifyCsrfToken(req, res, next) {
  const sessionId = req.session.id;
  const tokenFromRequest = req.body.csrfToken || req.headers['x-csrf-token'];
  const tokenFromRedis = await redis.get(`csrf:${sessionId}`);
  
  if (tokenFromRequest !== tokenFromRedis) {
    return res.status(403).json({ error: 'CSRF token mismatch' });
  }
  
  next();
}
```

#### XSS対策

**ユーザー入力のサニタイゼーション**:

```javascript
const DOMPurify = require('isomorphic-dompurify');

function sanitizeInput(input) {
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
    ALLOWED_ATTR: ['href']
  });
}

// 使用例
const userNote = sanitizeInput(req.body.note);
```

**Content-Security-Policy ヘッダー設定**:

```javascript
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
  );
  next();
});
```

**HTTPOnly Cookie**:

```javascript
res.cookie('sessionId', sessionId, {
  httpOnly: true,
  secure: true, // HTTPS環境のみ
  sameSite: 'strict'
});
```

#### SQLインジェクション対策

**プリペアドステートメントの使用**:

```javascript
// ❌ 危険: 文字列連結
const query = `SELECT * FROM users WHERE email = '${userEmail}'`;

// ✅ 安全: プリペアドステートメント
const query = 'SELECT * FROM users WHERE email = $1';
const result = await db.query(query, [userEmail]);
```

**ORMの活用（Prisma）**:

```javascript
// Prisma による安全なクエリ
const user = await prisma.user.findUnique({
  where: { email: userEmail }
});
```

---

### 7.5.4 監視・ログ

#### アプリケーションログ

**Winston を使用したログ管理**:

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    // ファイル出力
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    // コンソール出力（開発環境のみ）
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// ログレベル
logger.error('エラーメッセージ', { error: err });
logger.warn('警告メッセージ');
logger.info('情報メッセージ');
logger.debug('デバッグメッセージ');
```

**ログローテーション**:

```javascript
const DailyRotateFile = require('winston-daily-rotate-file');

const transport = new DailyRotateFile({
  filename: 'application-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '14d' // 14日間保存
});

logger.add(transport);
```

#### 監視ダッシュボード（Grafana + Prometheus）

**監視項目**:
- CPU使用率
- メモリ使用率
- ディスクI/O
- APIレスポンスタイム
- エラー発生率
- 予約処理の成功率

**アラート設定**:
- CPU使用率 > 80%: 警告
- APIレスポンスタイム > 1秒: 警告
- エラー発生率 > 5%: 重大

#### エラートラッキング（Sentry）

```javascript
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0
});

// エラーキャプチャ
try {
  await processReservation(data);
} catch (error) {
  Sentry.captureException(error, {
    user: { id: userId, email: userEmail },
    tags: { reservation_id: reservationId }
  });
  throw error;
}
```

---

## 7.6 運用・保守

### 7.6.1 データバックアップ

#### バックアップ戦略

| バックアップ種別 | 実行タイミング | 保存期間 |
|----------------|--------------|---------|
| フルバックアップ | 日次（深夜3:00） | 30日間 |
| 差分バックアップ | 1時間ごと | 7日間 |
| トランザクションログ | 継続的 | 7日間 |

#### バックアップ対象

**1. PostgreSQL データベース**
```bash
#!/bin/bash
# pg_dump によるバックアップ
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/backup/postgresql"

pg_dump -U harmonet_user -h localhost harmonet_db \
  | gzip > ${BACKUP_DIR}/harmonet_${TIMESTAMP}.sql.gz

# 古いバックアップの削除（30日以上前）
find ${BACKUP_DIR} -name "harmonet_*.sql.gz" -mtime +30 -delete
```

**2. ファイルストレージ**
- 施設画像
- 領収書PDF
- ログファイル

```bash
#!/bin/bash
# rsync によるファイルバックアップ
rsync -avz --delete \
  /var/www/harmonet/uploads/ \
  /backup/files/uploads/
```

**3. 設定ファイル**
- アプリケーション設定
- Nginx設定
- 環境変数ファイル

#### 復旧手順

**手順1: 最新のフルバックアップを復元**
```bash
gunzip < harmonet_20251029.sql.gz | psql -U harmonet_user harmonet_db
```

**手順2: 差分バックアップを順次適用**
```bash
# トランザクションログを適用
pg_restore -U harmonet_user -d harmonet_db backup.tar
```

**手順3: 整合性チェック**
```bash
# データベース整合性チェック
psql -U harmonet_user -d harmonet_db -c "SELECT COUNT(*) FROM reservation;"
```

**手順4: サービス再起動**
```bash
systemctl restart harmonet-api
systemctl restart nginx
```

---

### 7.6.2 バージョンアップ手順

#### リリースフロー

```
開発環境 → ステージング環境 → 本番環境
  ↓           ↓                ↓
テスト      統合テスト       段階的ロールアウト
```

**1. 開発環境**
- 機能開発・バグ修正
- ユニットテスト実施

**2. ステージング環境**
- 本番環境と同じ構成
- 統合テスト・負荷テスト実施
- データベースマイグレーションの検証

**3. 本番環境**
- 段階的ロールアウト（Canary Release）
- ロールバック手順の準備

#### ダウンタイム最小化

**Blue-Green デプロイメント**:

```
[Blue環境（現行版）] ← ユーザートラフィック
[Green環境（新版）]  ← デプロイ・テスト中

↓ 切り替え

[Blue環境（現行版）]  ← 待機（ロールバック用）
[Green環境（新版）]  ← ユーザートラフィック
```

**データベースマイグレーションの事前実行**:
```javascript
// Prisma Migrate
npx prisma migrate deploy

// 後方互換性を保つマイグレーション
// 1. 新カラム追加（NULL許可）
ALTER TABLE reservation ADD COLUMN new_column TEXT;

// 2. データ移行
UPDATE reservation SET new_column = old_column;

// 3. アプリケーションデプロイ

// 4. 旧カラム削除（次回リリースで実施）
ALTER TABLE reservation DROP COLUMN old_column;
```

---

### 7.6.3 障害対応

#### 障害レベル定義

| レベル | 影響範囲 | 復旧目標時間 | 例 |
|-------|---------|------------|---|
| **Critical** | サービス全体停止 | 1時間以内 | データベース障害 |
| **High** | 主要機能停止 | 4時間以内 | 予約機能停止 |
| **Medium** | 一部機能停止 | 24時間以内 | 通知機能停止 |
| **Low** | 軽微な不具合 | 次回リリース | UI表示の乱れ |

#### エスカレーションフロー

```
Level 1: サポート担当
  ↓ 30分以内に解決できない場合
Level 2: 開発チーム
  ↓ 1時間以内に解決できない場合
Level 3: アーキテクト・CTO
```

#### 障害対応手順

**1. 障害検知**
- 監視ツール（Grafana）からアラート
- ユーザーからの問い合わせ

**2. 影響範囲の特定**
```bash
# サービス状態確認
systemctl status harmonet-api
systemctl status postgresql

# ログ確認
tail -f /var/log/harmonet/error.log

# データベース接続確認
psql -U harmonet_user -d harmonet_db -c "SELECT 1;"
```

**3. 応急処置**
- サービス再起動
- ロードバランサーから切り離し
- メンテナンスモード切り替え

**4. 根本原因の調査**
- ログ分析
- Sentryのエラー詳細確認
- データベースクエリの分析

**5. 恒久対策の実施**
- バグ修正
- パフォーマンス改善
- 監視強化

**6. 事後報告書作成**
- 発生日時・原因・影響範囲
- 対応内容・再発防止策

---

## 7.7 用語集

| 用語 | 説明 |
|------|------|
| **MVP** | Minimum Viable Product（実用最小限の製品）。最小限の機能でリリースし、フィードバックを得る開発手法。 |
| **排他制御** | 複数ユーザーの同時更新を防ぐ仕組み。データの整合性を保つために必要。 |
| **楽観的ロック** | 競合が発生した場合にのみエラーを返す方式。バージョン番号を使って実装。 |
| **悲観的ロック** | 更新中は他のユーザーのアクセスをブロックする方式。デッドロックのリスクあり。 |
| **CSRF** | Cross-Site Request Forgery。不正なリクエストを送信させる攻撃。トークンで防御。 |
| **XSS** | Cross-Site Scripting。悪意のあるスクリプトを実行させる攻撃。サニタイゼーションで防御。 |
| **SQLインジェクション** | 不正なSQL文を実行させる攻撃。プリペアドステートメントで防御。 |
| **Blue-Green デプロイメント** | 2つの環境を用意し、切り替えることでダウンタイムを最小化するデプロイ手法。 |
| **Canary Release** | 一部のユーザーに先行リリースし、問題がなければ全体に展開する手法。 |
| **JSONB** | PostgreSQLのJSON型。インデックスが使えるため高速。 |
| **Prisma** | Node.js用のORMツール。型安全なデータベースアクセスを提供。 |
| **Redis** | インメモリデータストア。キャッシュやセッション管理に使用。 |
| **Sentry** | エラートラッキングサービス。エラー発生時に通知とスタックトレースを記録。 |

---

## 7.8 参考資料

### 外部サービス・API

- [Google Cloud Translation API](https://cloud.google.com/translate/docs) - 多言語翻訳
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) - プッシュ通知
- [SendGrid API](https://docs.sendgrid.com/) - メール送信
- [Stripe API](https://stripe.com/docs/api) - オンライン決済

### 技術ドキュメント

- [PostgreSQL 公式ドキュメント](https://www.postgresql.org/docs/) - データベース
- [Redis 公式ドキュメント](https://redis.io/documentation) - キャッシュ
- [Node.js ベストプラクティス](https://github.com/goldbergyoni/nodebestpractices) - バックエンド開発
- [Prisma ドキュメント](https://www.prisma.io/docs/) - ORM

### デザインパターン

- [RESTful API 設計ガイド](https://restfulapi.net/) - API設計
- [マイクロサービスアーキテクチャ](https://microservices.io/) - アーキテクチャパターン
- [The Twelve-Factor App](https://12factor.net/ja/) - モダンなWebアプリケーション開発の方法論

### セキュリティ

- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Webアプリケーションの脆弱性トップ10
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/) - 危険なソフトウェアの脆弱性

### モニタリング・ログ

- [Grafana ドキュメント](https://grafana.com/docs/) - 監視ダッシュボード
- [Prometheus ドキュメント](https://prometheus.io/docs/) - メトリクス収集
- [Winston ドキュメント](https://github.com/winstonjs/winston) - ログ管理

---

## 7.9 まとめ

Chapter 07では、MVP後の将来拡張機能と技術的補足をまとめました。

### 主要ポイント

**1. 将来実装機能**
- **予約変更機能**: 日付・駐車場所の変更対応（優先度: 高）
- **リマインダー機能**: 前日・当日の通知送信（優先度: 中）
- **予約制限ルール強化**: 月間回数制限等（優先度: 低）
- **レポート機能**: 稼働率分析、統計レポート（優先度: 中）
- **駐車場情報充実**: 写真、EV充電器情報等（優先度: 低）

**2. 他施設への拡張**
- **集会所予約**: 時間単位の予約、有料施設対応（優先度: 中）
- **施設マスタ管理**: 3層構造（facility_master, facility_rule, facility_i18n）による柔軟な施設管理（優先度: 低）
- **多様な施設種別**: 室内系、宿泊・駐車系、共用スペース系、機能設備系
- **IoT連携**: スマートロック、EV充電器連携（優先度: 低）

**3. 決済機能**
- **オンライン決済**: Stripe連携、クレジットカード・電子マネー対応（優先度: 低）
- **請求書管理**: 月次請求書の自動生成・送信（優先度: 中）

**4. AI・機械学習の活用**
- **需要予測**: ARIMA、LSTM による時系列予測（優先度: 低）
- **異常検知**: 不正予約・キャンセルの検知（優先度: 低）

**5. 技術的補足**
- **排他制御**: 楽観的ロック（バージョン番号）を採用
- **パフォーマンス**: インデックス最適化、Redis キャッシュ、API レスポンスタイム目標設定
- **セキュリティ**: CSRF対策、XSS対策、SQLインジェクション対策
- **監視・ログ**: Winston、Grafana + Prometheus、Sentry

**6. 運用・保守**
- **バックアップ**: 日次フルバックアップ、1時間ごと差分バックアップ
- **バージョンアップ**: Blue-Green デプロイメント、段階的ロールアウト
- **障害対応**: 4段階の障害レベル定義、エスカレーションフロー

### 実装ロードマップ

```
MVP完成
  ↓
Phase 1（MVP後 1-3ヶ月）: 予約変更機能
  ↓
Phase 2（MVP後 4-6ヶ月）: リマインダー機能、レポート機能、請求書管理、集会所予約
  ↓
Phase 3（MVP後 7-12ヶ月）: 予約制限ルール強化、駐車場情報充実、施設マスタ管理
  ↓
Phase 4（MVP後 1年以降）: オンライン決済、AI需要予測、IoT連携
```

### 設計思想の再確認

HarmoNetの施設予約機能は、以下の設計思想に基づいています。

**参照**: 施設予約追加機能要件検討資料.md - 1. 基本方針

1. **共通構造での管理**: 施設種別が異なっても共通の予約構造で管理
2. **ルール定義層での差異吸収**: 施設間の差異は`facility_rule`で管理
3. **UI統一**: 全施設で3ステップ予約フロー（選択 → 入力 → 確認）
4. **拡張性**: DBスキーマ変更なしで施設追加・削除が可能
5. **多言語対応**: 全ての施設情報を多言語対応（日本語・英語・中国語）
6. **テナント単位管理**: 複数物件での運用に対応

### 結論

HarmoNetの施設予約機能は、MVP完成後も継続的に進化し、住民のニーズに応え続けることができます。

技術的な基盤（排他制御、パフォーマンス最適化、セキュリティ）を確立することで、将来の機能拡張をスムーズに実装できます。

また、施設マスタ管理の柔軟な設計により、駐車場以外の多様な施設にも対応可能な拡張性を持っています。

---

## 📖 ナビゲーション

- [⬅️ 前の章: Chapter 06 - 多言語対応・通知機能](facility-booking-feature-design-ch06_v1.0.md)
- [📚 目次に戻る](facility-booking-feature-design-ch00-index_v1.0.md)

---

**文書履歴**

| バージョン | 日付 | 変更内容 | 作成者 |
|-----------|------|---------|-------|
| v1.0 | 2025-10-29 | 初版作成 | Claude |

---

© 2025 HarmoNet Project. All rights reserved.
