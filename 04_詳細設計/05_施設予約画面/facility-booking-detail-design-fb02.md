# 詳細設計書: FB-02 時間枠選択画面（集会所）

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-002-FB02
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
集会所（Meeting Room）の予約において、希望する時間枠を選択し、利用目的などの詳細情報を入力する画面。
FB-01で日付を選択した後に遷移する。

### 1.1 画面ID / URL
*   **ID**: FB-02
*   **URL**: `/facilities/[facilityId]/book?date=YYYY-MM-DD`

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md` (4. 集会所の予約フロー)
*   **UIガイド**: `HarmoNet-UI-Design-Guide.md`

## 2. UI仕様

### 2.1 レイアウト構造
標準レイアウト（`max-w-5xl`）を採用。

### 2.2 構成コンポーネント

#### (1) ヘッダーエリア
*   **タイトル**: "予約情報の入力"
*   **サブタイトル**: 施設名と選択した日付を表示
*   **施設備考**: アコーディオンまたはカード形式で「使用料」「最大使用時間」「注意事項」などを表示（`facilities.description`）。
*   **戻るボタン**: FB-01へ戻る

#### (2) 時間枠セレクター (TimeSlotSelector)
*   **表示形式**: グリッドまたはリスト形式で、30分単位のスロットを表示。
*   **状態**:
    *   `Available`: 選択可能（白背景）
    *   `Selected`: 選択中（Primary Color背景）
    *   `Booked`: 予約済み（グレーアウト、不可）
    *   `Blocked`: 利用不可（メンテナンス等）
*   **操作**:
    *   タップで選択/解除。
    *   連続した枠のみ選択可能とするバリデーション（任意）。

#### (3) 予約詳細フォーム (ReservationDetailForm)
時間枠選択後に表示（または常時表示）。

*   **利用目的** (`purpose`): テキスト入力（必須）
*   **参加人数** (`participant_count`): 数値入力（任意）
*   **備品利用**: チェックボックス（オプション）

#### (4) アクションエリア
*   **確認画面へ進む**: Primary Button（必須項目入力完了時のみ活性化）

### 2.3 デザイン適用
*   **Selected Slot**: `bg-blue-600 text-white`
*   **Available Slot**: `bg-white border border-gray-200 hover:border-blue-400`
*   **Booked Slot**: `bg-gray-100 text-gray-400 cursor-not-allowed`

## 3. データ要件 & ロジック

### 3.1 取得データ
*   **Facility Info**: `GET /api/facilities/[id]`
*   **Availability**: `GET /api/facilities/[id]/slots?date=YYYY-MM-DD`
    *   Response: `{ time: "09:00", status: "available" | "booked" }[]`

### 3.2 バリデーション (Client Side)
1.  **時間枠**: 1つ以上選択されていること。
2.  **連続性**: 飛び地選択（9:00と10:00を選択し、9:30が未選択など）はエラーとする。
3.  **利用目的**: 空白不可。

### 3.3 インタラクション
1.  **確認ボタン押下**:
    *   バリデーション実行。
    *   OKなら `FB-04` (予約確認) へ遷移。
    *   クエリパラメータまたはStateで予約情報を渡す。

## 4. 実装タスク
1.  `src/app/(app)/facilities/[facilityId]/book/page.tsx` の作成
2.  `src/components/facilities/TimeSlotSelector.tsx` の作成
3.  `src/components/facilities/ReservationForm.tsx` の作成

## 5. 国際化 (i18n)
施設利用ルールの説明文は、`public/locales/{lang}/facility.json` を新規作成して定義し、動的値（料金など）を埋め込んで表示する。
これにより、外国籍の居住者もルールを理解できるようにする。

### キー定義案 (`facility.json`)
```json
{
  "rules": {
    "fee": "使用料: {{price}}円/回",
    "payment": "支払方法: 使用前に集会所備え付けの集金ボックスに入金",
    "hours": "使用時間: 原則 {{start}} より {{end}} まで",
    "max_limit": "最大使用回数: {{count}}回/月",
    "alcohol": "遵守事項: 集会所では原則飲酒、喫煙をしないこと...",
    "reservation_method": "予約方法: 貸切での利用に限り、本サイト上での予約が必要"
  }
}
```

## 6. 備考
*   モバイル表示時は、時間枠を2列などで表示し、タップしやすくする。
