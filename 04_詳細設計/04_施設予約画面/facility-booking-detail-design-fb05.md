# 詳細設計書: FB-05 予約完了画面

**Document ID**: HARMONET-FACILITY-BOOKING-DETAIL-005-FB05
**Version**: 1.0
**Date**: 2025-12-02
**Status**: Draft

## 1. 画面概要
予約完了メッセージを表示し、次のアクション（ホームへ戻る、予約履歴へ）を促す画面。

### 1.1 画面ID / URL
*   **ID**: FB-05
*   **URL**: `/facilities/complete` (または `/facilities/reservations/[id]/complete`)

### 1.2 参照ドキュメント
*   **基本設計**: `facility-booking-feature-design-ch03_v1.2.md`

## 2. UI仕様

### 2.1 レイアウト構造
標準レイアウト（`max-w-5xl`）。

### 2.2 構成コンポーネント

#### (1) 完了メッセージ (CompletionMessage)
*   **アイコン**: 大きなチェックマーク (`CheckCircle`, Green or Blue)
*   **タイトル**: "予約が完了しました"
*   **メッセージ**: "ご予約ありがとうございます。予約詳細はマイページから確認できます。"

#### (2) アクションボタン
*   **ホームへ戻る**: Secondary Button
*   **予約履歴を見る**: Primary Button -> `/mypage?tab=reservations`

## 3. 実装タスク
1.  `src/app/(app)/facilities/complete/page.tsx`
