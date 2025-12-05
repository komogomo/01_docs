# 詳細設計書: FB-01 施設予約TOP画面

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-001-FB01
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
施設予約機能のエントリーポイントとなる画面。
利用可能な施設（駐車場、集会所など）を一覧表示し、予約状況のカレンダー確認や新規予約フローへの遷移を提供する。

### 1.1 画面ID / URL
*   **ID**: FB-01
*   **URL**: `/facilities` (テナント配下: `/t/[tenantId]/facilities`)

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md` (3.2 施設予約TOP)
*   **UIガイド**: `HarmoNet-UI-Design-Guide.md`

## 2. UI仕様

### 2.1 レイアウト構造
**モックアップ (v1.3) 準拠**のレイアウトを採用する。
`HarmoNet-UI-Design-Guide.md` の標準レイアウト（`max-w-5xl`）を使用するが、コンテンツ構成はモックアップに従う。

### 2.2 構成コンポーネント

#### (1) ヘッダーエリア
*   **タイトル**: "施設予約"
*   **テナント名**: 画面上部に表示（`TenantNameDisplay` 利用）。

#### (2) 施設選択エリア (FacilitySelector)
*   **UI**: ドロップダウン (Select)
*   **動作**:
    *   選択した施設に応じて、下部の「施設情報」と「カレンダー」が切り替わる。
    *   初期値: 最初の施設（例: 集会所）。

#### (3) 施設情報カード (FacilityInfoCard)
選択中の施設情報を表示する単一のカード。

*   **スタイル**: `bg-white border rounded-lg p-4 shadow-sm` (角丸は `rounded-lg`)
*   **表示項目**:
    *   アイコン + 施設名
    *   利用可能時間 / 料金 / 補足説明 (`description`)
        *   **重要**: 補足説明（利用ルール、料金詳細、注意事項など）は **DBの `facilities.description`** から取得して表示すること。ハードコード禁止。
        *   ※テナント管理画面で編集可能な運用とするため。
    *   **アクション**: "予約状況を見る" (カレンダーへスクロール), "予約する" (今日の日付で予約フォームへ遷移)

#### (4) 予約カレンダー (CalendarView)
選択中の施設の予約状況を表示する月カレンダー。

*   **表示**: 当月（切替可能）。
*   **日付セル**:
    *   日付数字
    *   空き状況インジケータ（例: "○", "△", "×" または色分け）。
*   **インタラクション**:
    *   日付クリック -> **FB-02/03 (予約フォーム)** へ遷移 (`/facilities/[id]/book?date=YYYY-MM-DD`)。

#### (5) 自分の予約 (MyReservations)
*   カレンダーの下、またはサイド（PC時）に配置。
*   直近の予約を表示。

### 2.3 デザイン適用
*   **角丸**: `rounded-lg` または `rounded-md` を採用（`rounded-2xl` は不可）。
*   **配色**:
    *   集会所選択時: 青ベース
    *   駐車場選択時: 青ベース（または区別のためアクセント変更も可だが、基本は青統一）

## 3. データ要件 & ロジック

### 3.1 取得データ
*   **Facilities**: `GET /api/facilities` (全件取得し、クライアント側で切り替え)
*   **Availability**: `GET /api/facilities/[id]/availability?month=YYYY-MM` (選択中施設の月間状況)

### 3.2 インタラクションフロー
1.  **TOP表示**: デフォルト施設（集会所）の情報とカレンダーを表示。
2.  **ドロップダウン変更**: 施設IDを変更 -> 再フェッチ -> 情報とカレンダー更新。
3.  **日付クリック**: 選択した日付と施設IDを持って予約フォームへ遷移。

## 4. 実装タスク
1.  `src/app/(app)/facilities/page.tsx` の修正（カード一覧廃止、ドロップダウン化）
2.  `src/components/facilities/FacilitySelector.tsx` 作成
3.  `src/components/facilities/FacilityInfoCard.tsx` 作成
4.  `src/components/facilities/CalendarView.tsx` 作成

