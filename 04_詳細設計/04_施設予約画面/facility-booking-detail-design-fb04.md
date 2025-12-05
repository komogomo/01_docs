# 詳細設計書: FB-04 予約確認画面

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-004-FB04
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
予約内容の最終確認を行う画面。
利用規約や注意事項への同意を求め、予約を確定する。

### 1.1 画面ID / URL
*   **ID**: FB-04
*   **URL**: `/facilities/confirm` (または `/facilities/[facilityId]/confirm`)

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md` (6. 予約確認画面)

## 2. UI仕様

### 2.1 レイアウト構造
標準レイアウト（`max-w-5xl`）。

### 2.2 構成コンポーネント

#### (1) 予約内容サマリ (ReservationSummaryCard)
*   **施設名**: `facilities.facility_name`
*   **日時**: `YYYY年MM月DD日 HH:mm 〜 HH:mm`
*   **区画/部屋**: `facility_slots.slot_name` (ある場合)
*   **利用目的**: 入力値
*   **参加人数**: 入力値
*   **車両情報**: 入力値 (駐車場の場合)
*   **料金**: `facility_settings.fee_per_day` 等から計算した見積もり額。

#### (2) 注意事項・同意エリア (TermsAndConditions)
*   **内容**: `facility.json` の `rules` を表示。
*   **同意チェックボックス**: "注意事項を確認し、同意しました" (必須)

#### (3) アクションエリア
*   **戻る**: FB-02/03へ戻る
*   **予約を確定する**: Primary Button (同意チェックで活性化)

## 3. データ要件 & ロジック

### 3.1 入力データ
*   前の画面（FB-02/03）から渡された予約データ（State管理 または URLパラメータ）。

### 3.2 APIコール
*   **Create Reservation**: `POST /api/facilities/reservations`
    *   Request: `{ facilityId, slotId, startAt, endAt, purpose, ... }`
    *   Response: `{ id: "reservation_id" }`

### 3.3 エラーハンドリング
*   **重複エラー**: 同時タイミングで他者が予約した場合、エラーメッセージを表示し、FB-01へ戻す。
*   **制限エラー**: 月間利用制限超過など。

## 4. 実装タスク
1.  `src/app/(app)/facilities/confirm/page.tsx`
2.  `src/components/facilities/ReservationSummaryCard.tsx`
