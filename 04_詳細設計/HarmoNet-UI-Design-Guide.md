# HarmoNet UI Design Guide

**Version:** 1.1
**Date:** 2025-12-02
**Status:** Draft (Refined based on Home/Board)

## 1. 概要
本ガイドラインは、HarmoNetアプリケーションにおけるUIデザインの一貫性を保つためのルールを定義します。
**特に「ホーム画面」および「掲示板（Board）」のデザインテイストを基準（Gold Standard）とします。**

## 2. デザイン原則 (Design Principles)
*   **Rounded & Soft**: 角丸（`rounded-2xl`）を多用し、親しみやすくモダンな印象を与える。
*   **Clean & Airy**: 余白を十分に取り、コンテンツ幅は `max-w-5xl` を基準とする。
*   **Blue Accent**: アクションカラーには `text-blue-600` や `border-blue-400` を使用し、清潔感を演出する。

## 3. カラーパレット (Colors)

### Primary (Action)
*   **Solid**: `#6495ed` (Cornflower Blue) - `bg-[#6495ed]`
*   **Outline/Text**: `text-blue-600`, `border-blue-400`
*   **Hover**: `hover:bg-blue-50/40` (Ghost/Outline), `hover:bg-[#5386d9]` (Solid)

### Neutral (Text & Border)
*   **Text Main**: `text-gray-900`
*   **Text Sub**: `text-gray-600`
*   **Border**: `border-gray-300` (Input), `border-gray-100` (Card)
*   **Background**: `bg-white`, `bg-gray-50`

## 4. コンポーネントスタイル (Component Styles)

### 4.1 ボタン (Button)
高さ `44px` (`h-11`) を基準とする。

#### Primary (Solid) - ログイン、確定など
```tsx
className="w-full h-11 rounded-2xl bg-[#6495ed] text-white text-sm font-medium flex items-center justify-center hover:bg-[#5386d9] transition-colors"
```

#### Floating Action Button (FAB) - 新規投稿など
```tsx
className="flex h-11 w-11 items-center justify-center rounded-full bg-transparent border-2 border-blue-400 text-blue-600 shadow-lg shadow-blue-200/60 hover:bg-blue-50/40"
```

### 4.2 入力フォーム (Input)
高さ `44px` (`h-11`) を基準とする。

```tsx
className="block w-full h-11 px-3 rounded-2xl border border-gray-300 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
```

### 4.3 カード (Card)
薄いボーダーと微細なシャドウで浮き上がりを表現。

```tsx
className="rounded-2xl shadow-[0_1px_2px_rgba(0,0,0,0.06)] border border-gray-100 bg-white px-4 py-4"
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
