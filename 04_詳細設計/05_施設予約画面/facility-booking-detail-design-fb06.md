# 詳細設計書: FB-06 予約詳細画面（マイページ）

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-006-FB06
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
マイページ内の予約履歴から遷移し、予約の詳細確認およびキャンセルを行う画面。

### 1.1 画面ID / URL
*   **ID**: FB-06
*   **URL**: `/mypage/reservations/[id]`

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md` (7. 予約詳細画面)

## 2. UI仕様

### 2.1 レイアウト構造
標準レイアウト（`max-w-5xl`）。

### 2.2 構成コンポーネント

#### (1) ステータスバッジ
*   `Pending`: 承認待ち (Yellow)
*   `Confirmed`: 予約確定 (Green)
*   `Cancelled`: キャンセル済み (Gray)

#### (2) 予約詳細情報
*   **施設名**: `facilities.facility_name`
*   **日時**: `YYYY年MM月DD日 HH:mm 〜 HH:mm`
*   **場所**: `facility_slots.slot_name`
*   **利用目的**: `purpose`
*   **参加人数**: `participant_count`
*   **料金**: `fee` (確定額)

#### (3) アクションエリア
*   **キャンセルボタン**:
    *   開始時刻前かつステータスが `Confirmed` or `Pending` の場合のみ表示。
    *   Destructive Button (`bg-red-50 text-red-600 border-red-200`).
    *   押下時に確認モーダルを表示。

## 3. データ要件 & ロジック

### 3.1 APIコール
*   **Get Reservation**: `GET /api/facilities/reservations/[id]`
*   **Cancel Reservation**: `DELETE /api/facilities/reservations/[id]` (または `PATCH ... { status: 'cancelled' }`)

## 4. 実装タスク
1.  `src/app/(app)/mypage/reservations/[id]/page.tsx`
2.  `src/components/facilities/ReservationDetailView.tsx`
