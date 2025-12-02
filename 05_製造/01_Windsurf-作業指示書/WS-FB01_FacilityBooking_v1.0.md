# Windsurf 作業指示書: 施設予約機能実装 (WS-FB01)

**Document ID**: WS-FB01_FacilityBooking_v1.0
**Date**: 2025-12-02
**Target**: Windsurf (AI Agent)

## 1. 概要
本ドキュメントは、HarmoNetプロジェクトにおける「施設予約機能 (Facility Booking)」の実装指示書である。
詳細設計書に基づき、画面およびロジックの実装を行うこと。

## 2. 参照資料 (Reference Documents)
以下の資料を必ず参照し、設計内容を遵守すること。

*   **UIデザインガイド**: `D:\AIDriven\01_docs\04_詳細設計\HarmoNet-UI-Design-Guide.md`
*   **詳細設計書**:
    *   FB-01 (TOP): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb01.md`
    *   FB-02 (時間枠): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb02.md`
    *   FB-03 (区画): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb03.md`
    *   FB-04 (確認): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb04.md`
    *   FB-05 (完了): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb05.md`
    *   FB-06 (詳細): `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-booking-detail-design-fb06.md`
*   **辞書定義**: `D:\AIDriven\01_docs\04_詳細設計\05_施設予約画面\facility-i18n-keys.md`
*   **DB基本設計**: `D:\AIDriven\01_docs\03_基本設計\05_データベース設計\HarmoNet-DB-Basic-Design_v2.0.md`
*   **スキーマ定義**: `D:\Projects\HarmoNet\prisma\schema.prisma`

## 3. 作業ルール (Rules)

### 3.1 ファイル操作
*   **バックアップ必須**: 既存ファイルを変更する場合は、必ず事前にバックアップ（コピー）を作成すること。
    *   例: `MyComponent.tsx` -> `MyComponent.tsx.bak`

### 3.2 データベース
*   **スキーマ変更厳禁**: `schema.prisma` の変更は許可しない。既存のスキーマを使用すること。
*   **ポリシー変更厳禁**: RLSポリシーの変更はユーザの許可なく行ってはならない。

### 3.3 実装方針
*   **UIコンポーネント**: `HarmoNet-UI-Design-Guide.md` に従い、Tailwind CSSを用いてスタイリングすること。
*   **i18n**: `facility-i18n-keys.md` に基づき、`public/locales/{lang}/facility.json` を作成・利用すること。
*   **駐車場マップ**: `D:\Projects\HarmoNet\public\images\facility\ParkingLayout.png` を使用し、FB-03の設計通り「参照画像＋グリッド選択」で実装すること。

## 4. 作業手順 (Steps)

1.  **辞書ファイル作成**: `public/locales/{ja,en,zh}/facility.json` を作成。
2.  **コンポーネント実装**:
    *   `src/components/facilities/` 配下に各画面のコンポーネントを作成。
    *   `FacilityCard`, `TimeSlotSelector`, `ParkingSlotSelector`, `ReservationSummaryCard` 等。
3.  **ページ実装**:
    *   `src/app/(app)/facilities/` 配下にページを作成。
    *   ルーティング: `/`, `/[id]/book`, `/[id]/confirm`, `/complete`, `/reservations/[id]`
4.  **動作確認**:
    *   各画面の遷移、データ登録、バリデーションを確認。

## 5. 完了条件 & 報告
*   全ての画面が設計通りに実装され、正常に動作すること。
*   **作業完了リポート**を以下の場所にMarkdown形式で出力すること。
    *   出力先: `D:\AIDriven\01_docs\06_品質チェック\Report_WS-FB01_FacilityBooking.md`
    *   内容: 実装したファイル一覧、確認した項目、残課題（あれば）。

以上
