# 詳細設計書: FB-03 区画選択画面（駐車場）

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-003-FB03
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
ゲスト駐車場（Parking）の予約において、希望する区画（Slot）を選択し、詳細情報を入力する画面。
FB-01で日付を選択した後に遷移する。

### 1.1 画面ID / URL
*   **ID**: FB-03
*   **URL**: `/facilities/[facilityId]/book?date=YYYY-MM-DD`
    *   ※集会所と同じURLパスだが、`facility_type` によって表示コンポーネントを切り替える（または `page.tsx` 内で分岐）。

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md` (5. 駐車場の予約フロー)
*   **UIガイド**: `HarmoNet-UI-Design-Guide.md`

## 2. UI仕様

### 2.1 レイアウト構造
標準レイアウト（`max-w-5xl`）を採用。

### 2.2 構成コンポーネント

#### (1) ヘッダーエリア
*   **タイトル**: "予約情報の入力"
*   **サブタイトル**: 施設名と選択した日付
*   **施設備考**: `facilities.description` を表示（i18n対応）。

#### (2) 区画セレクター (ParkingSlotSelector)
*   **表示形式**: **参照画像 ＋ グリッド選択方式**。
    *   **配置図エリア**: 駐車場の配置図画像（`facilities.image_url` または `meta`）を上部に表示（タップ不可、参照用）。
        *   ※画像はテナントごとに異なるため、DBから取得する。
    *   **選択エリア**: 画像の下に、登録されている区画（`facility_slots`）をカード/ボタンのグリッドとして並べる。
        *   **重要**: DBの `facility_slots` テーブルに登録されたレコード数分だけ、自動的にボタンが生成されること（テナントごとの台数変更にコード修正なしで対応可能）。
        *   ※「全8区画」などと決め打ちしない。
*   **区画アイテム**:
    *   シンプルな番号付きボタン（例: "1", "2", "3"...）。
    *   `slot_name` を表示。
*   **状態とスタイル**:
    *   `Available` (空き): **白背景、緑枠、緑文字** (`border-green-500 text-green-600`)。
    *   `Selected` (選択中): **青背景、白文字** (`bg-blue-600 text-white`)。
    *   `Booked` (予約済): **グレー背景、グレー文字** (`bg-gray-100 text-gray-400`)。
    *   `MyBooking` (自分の予約): **白背景、青枠、青文字** (`border-blue-500 text-blue-600`)。
*   **メリット**:
    *   テナントごとに区画数や配置が異なっても、DBの登録データに基づいて自動的にボタンが並ぶため、画面改修不要で汎用性が高い。

#### (3) 予約詳細フォーム
*   **利用目的**: テキスト入力（必須）
*   **車両情報**: `meta` カラムに保存するための追加フィールド（任意）。
    *   "車両ナンバー" (Vehicle Number)
    *   "車種" (Vehicle Model)
*   **※注意**: 「参加人数」「備品利用」などの項目は表示しないこと（集会所用のため）。

#### (4) アクションエリア
*   **戻る**: Secondary Button
*   **次へ**: Primary Button

### 2.3 デザイン適用
*   **全体**: `rounded-lg` または `rounded-md` を採用し、過度な丸みを避ける（`rounded-2xl` は使用しない）。
*   **Slot Card**: `flex flex-col items-center justify-center w-16 h-16 border-2 rounded-lg transition-all font-bold`

## 3. データ要件 & ロジック

### 3.1 取得データ
*   **Facility Info**: `GET /api/facilities/[id]`
*   **Slots**: `GET /api/facilities/[id]/slots` (全区画マスタ)
*   **Availability**: `GET /api/facilities/[id]/availability?date=YYYY-MM-DD`
    *   区画ごとの予約状況を取得。

### 3.2 バリデーション
1.  **区画**: 1つ選択されていること。
2.  **利用目的**: 必須。
3.  **ダブルブッキング防止 (Critical)**:
    *   選択された区画 (`slot_id`) と日付において、既存の有効な予約と重複がないか厳密にチェックする。
    *   ※駐車場は「日単位」または「時間単位」の管理設定 (`fee_unit`) に従う。
4.  **キャンセル規定**:
    *   `facility_settings.cancel_restriction_days` を確認し、期限切れの予約に対するキャンセル操作をブロックする。

## 4. 実装タスク
1.  `src/components/facilities/ParkingSlotSelector.tsx` の作成
2.  `src/components/facilities/VehicleInfoForm.tsx` の作成（必要に応じて）

## 5. 国際化 (i18n)
`facility.json` に駐車場固有のキーを追加。

```json
{
  "labels": {
    "vehicle_number": "車両ナンバー",
    "vehicle_model": "車種"
  }
}
```
