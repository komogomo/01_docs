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
`HarmoNet-UI-Design-Guide.md` の標準レイアウト（`max-w-5xl`）に準拠する。

```tsx
<main className="min-h-screen bg-white">
  <div className="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-4 pt-20 pb-24">
    <header>...</header>
    <section>...</section>
  </div>
  <HomeFooterShortcuts />
</main>
```

### 2.2 構成コンポーネント

#### (1) ヘッダーエリア
*   **タイトル**: "施設予約" (`text-xl font-bold`)
*   **説明文**: "利用したい施設を選択してください"

#### (2) 施設リスト (FacilityList)
施設タイプごとにカード形式で表示する。

*   **コンポーネント**: `FacilityCard` (新規作成)
*   **スタイル**:
    *   Container: `grid grid-cols-1 gap-4 md:grid-cols-2`
    *   Card: `rounded-2xl border border-gray-100 shadow-sm p-4`
*   **表示項目**:
    *   アイコン (Lucide: `Car`, `Users` 等)
    *   施設名 (`text-lg font-medium`)
    *   施設説明 (`text-sm text-gray-600 line-clamp-2`) - 備考/利用ルールの一部を表示
    *   利用可能時間 / 料金
    *   アクションボタン: "予約状況を見る" (Secondary), "予約する" (Primary)

#### (3) 自分の予約 (MyReservations)
直近の予約がある場合のみ表示。

*   **スタイル**: `bg-blue-50 rounded-2xl p-4`
*   **項目**: 日時、施設名、ステータス

### 2.3 デザイン適用 (Tailwind)
UIガイドライン v1.1 に従い、以下のクラスを適用する。

*   **Primary Button**: `bg-[#6495ed] text-white rounded-2xl h-11`
*   **Secondary Button**: `bg-white border border-gray-300 text-gray-700 rounded-2xl h-11`
*   **Text**: `text-gray-900` (Main), `text-gray-600` (Sub)

## 3. データ要件 & ロジック

### 3.1 取得データ (Server Component / API)
*   **Facilities**: `GET /api/facilities`
    *   `id`, `name`, `type`, `image_url`
*   **My Reservations**: `GET /api/reservations/me?upcoming=true`

### 3.2 状態管理 (Client State)
*   **Loading**: スケルトン表示 (`Skeleton` component)
*   **Error**: エラーバナー表示

### 3.3 インタラクション
1.  **施設カードクリック**:
    *   `/facilities/[facilityId]` (カレンダー画面) へ遷移
2.  **「予約する」ボタン**:
    *   `/facilities/[facilityId]/book` (予約フォーム) へ遷移

## 4. 実装タスク
1.  `src/app/(app)/facilities/page.tsx` の作成
2.  `src/components/facilities/FacilityList.tsx` の作成
3.  `src/components/facilities/FacilityCard.tsx` の作成
4.  `src/components/facilities/MyReservationPreview.tsx` の作成

## 5. 懸念点・備考
*   アイコンは `lucide-react` から適切なものを選定すること（駐車場: `CarFront`, 集会所: `UsersRound` 推奨）。
