# HarmoNet UI Design Guide

**Version:** 1.1
**Date:** 2025-12-02
**Status:** Draft (Refined based on Home/Board)

## 1. 概要
本ガイドラインは、HarmoNetアプリケーションにおけるUIデザインの一貫性を保つためのルールを定義します。
**特に「ホーム画面」および「掲示板（Board）」のデザインテイストを基準（Gold Standard）とします。**

## 2. デザイン原則 (Design Principles)
*   **Rounded**: コンテナ（カード）は `rounded-lg`、インタラクティブ要素（ボタン・入力）は `rounded-md` を基準とする。
*   **Clean & Airy**: 余白を十分に取り、コンテンツ幅は `max-w-5xl` を基準とする。
*   **Blue Accent**: アクションカラーには `text-blue-600` や `border-blue-400` を使用し、清潔感を演出する。

## 3. カラーパレット (Colors)

### Primary (Action)
*   **Solid**: `bg-blue-600` (Hover: `bg-blue-700`)
*   **Outline/Text**: `text-blue-600`, `border-blue-200` (Hover: `bg-blue-50`)

### Neutral (Text & Border)
*   **Text Main**: `text-gray-900`
*   **Text Sub**: `text-gray-600`, `text-gray-500`
*   **Border**: `border-gray-200` (Card), `border-gray-300` (Input/Cancel)
*   **Background**: `bg-white`, `bg-gray-50`

## 4. コンポーネントスタイル (Component Styles)

### 4.1 ボタン (Button)
高さ `40px` (`py-2`) 〜 `44px` を基準とする。**角丸は `rounded-md`**。

#### Primary (Solid) - 確定、投稿など
```tsx
className="rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
```

#### Secondary (Outline) - アクション（返信、翻訳など）
```tsx
className="rounded-md border-2 border-blue-200 bg-white px-4 py-2 text-sm font-medium text-blue-600 hover:bg-blue-50"
```

#### Cancel (Neutral) - キャンセル、戻る
```tsx
className="rounded-md border-2 border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50"
```

### 4.2 入力フォーム (Input)
**角丸は `rounded-md`**。ボーダーは `border-2`。

```tsx
className="block w-full rounded-md border-2 border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
```

### 4.3 カード (Card)
**角丸は `rounded-lg`**。ボーダーは `border-2`。

```tsx
className="rounded-lg border-2 border-gray-200 bg-white px-4 py-3 shadow-sm"
```

### 4.4 レイアウト (Layout)
メインコンテンツエリアの標準レイアウト。

```tsx
<main className="min-h-screen bg-white">
  <div className="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-4 pt-20 pb-24">
    {/* Content */}
  </div>
</main>
```

### 4.5 アイコン (Icons)
*   **Library**: `lucide-react`
*   **Size**: `w-6 h-6` (Standard), `w-4 h-4` (Small)
*   **Stroke**: `strokeWidth={2.6}` (Emphasis)

## 5. 推奨実装方針
今後の新規実装（施設予約機能など）では、上記「Home/Board」のスタイル（特にレイアウト構造と配色）を遵守してください。
Windsurf等のAIツールに指示を出す際は、本ガイドラインの内容をプロンプトに含めることを推奨します。
