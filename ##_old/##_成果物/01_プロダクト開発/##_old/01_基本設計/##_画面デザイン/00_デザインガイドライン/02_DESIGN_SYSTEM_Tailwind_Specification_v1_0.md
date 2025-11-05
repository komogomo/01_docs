# Tailwind Design System Specification v1.0

**Document ID:** SEC-APP-DESIGN-SYSTEM-001  
**Status:** Draft  
**Created:** 2025-10-27  
**Last Updated:** 2025-10-27  
**Author:** TKD + Claude  

---

## 📚 Document Purpose

本ドキュメントは、**Securea City Design Guideline v2.0** で定義されたデザイン哲学を、
**Tailwind CSS** で実装するための技術仕様書です。

### 参照元ドキュメント
- `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.txt` - デザイン哲学・原則
- `03_SCREEN_SPEC_Home_Design_v1_0.html` - HOME画面実装例
- `03_SCREEN_SPEC_Board_Feature_Design_v1_0.html` - 掲示板機能実装例

### 対象読者
- フロントエンド開発者
- React/React Native開発者
- UIデザイナー

---

## 📋 Table of Contents

1. [Design Philosophy Summary](#1-design-philosophy-summary)
2. [Color System](#2-color-system)
3. [Typography System](#3-typography-system)
4. [Spacing System](#4-spacing-system)
5. [Layout System](#5-layout-system)
6. [Component Specifications](#6-component-specifications)
7. [Responsive Design](#7-responsive-design)
8. [Implementation Guidelines](#8-implementation-guidelines)

---

## 1. Design Philosophy Summary

### 中立デザイン5原則（要約）

本デザインシステムは以下の原則に基づいています：

1. **文化的中立** - 国旗・民族的特徴を含まない
2. **ジェンダー中立** - 性別を示さないアイコン・表現
3. **言語中立** - 3言語（日本語・英語・中国語）対応
4. **視覚中立** - 色覚差に配慮（赤×緑の組み合わせ禁止）
5. **感情中立** - 穏やかな色・形・アニメーション

**詳細**: `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.txt` 参照

---

## 2. Color System

### 2.1 Primary Colors（プライマリカラー）

#### グラデーション
```javascript
// Tailwind Config
primary: {
  start: '#667eea',  // パープルブルー
  end: '#764ba2',    // ディープパープル
}
```

**使用箇所**:
- ヘッダー背景
- 主要ボタン
- アクセントカード背景

**Tailwind実装例**:
```html
<div class="bg-gradient-to-r from-primary-start to-primary-end">
  <!-- コンテンツ -->
</div>
```

---

### 2.2 Accent Colors（アクセントカラー）

#### Main Blue
```javascript
accent: {
  main: '#3b82f6',   // ブルー
  light: '#60a5fa',  // ライトブルー
}
```

**使用箇所**:
- リンクテキスト
- アクティブ状態のUI要素
- アイコンの強調色

**Tailwind実装例**:
```html
<!-- リンク -->
<a class="text-accent-main hover:text-accent-light">リンク</a>

<!-- アクティブボタン -->
<button class="bg-accent-main hover:bg-accent-light">ボタン</button>
```

---

### 2.3 Background Colors（背景カラー）

```javascript
background: {
  primary: '#f9fafb',    // ホワイトグレー - メイン背景
  secondary: '#f3f4f6',  // ライトグレー - カード背景
  border: '#e5e7eb',     // ボーダーグレー - 境界線
}
```

**使用原則**:
- `primary`: アプリ全体の背景色
- `secondary`: カード、入力フォーム背景
- `border`: カード枠線、セパレーター

**Tailwind実装例**:
```html
<body class="bg-background-primary">
  <div class="bg-background-secondary border border-background-border rounded-lg">
    <!-- カードコンテンツ -->
  </div>
</body>
```

---

### 2.4 Text Colors（テキストカラー）

```javascript
text: {
  primary: '#1f2937',    // チャコールグレー - 見出し
  secondary: '#6b7280',  // ミディアムグレー - 本文
  tertiary: '#9ca3af',   // ライトグレー - 補足情報
}
```

**使用原則**:
- `primary`: 見出し、重要なテキスト（高コントラスト）
- `secondary`: 本文テキスト（標準）
- `tertiary`: 日付、補足情報（低コントラスト）

**Tailwind実装例**:
```html
<h2 class="text-text-primary">見出し</h2>
<p class="text-text-secondary">本文テキスト</p>
<span class="text-text-tertiary text-sm">2025-10-27</span>
```

---

### 2.5 State Colors（状態カラー）

```javascript
state: {
  success: '#10b981',  // グリーン - 成功
  warning: '#f59e0b',  // オレンジ - 警告
  error: '#ef4444',    // レッド - エラー
  info: '#3b82f6',     // ブルー - 情報
}
```

**使用原則**:
- 限定的に使用（過度な色使いを避ける）
- 必ずテキストと併用（色だけに依存しない）

**Tailwind実装例**:
```html
<!-- 成功メッセージ -->
<div class="bg-green-50 border-l-4 border-state-success p-4">
  <p class="text-state-success">✓ 投稿が完了しました</p>
</div>

<!-- 警告メッセージ -->
<div class="bg-orange-50 border-l-4 border-state-warning p-4">
  <p class="text-state-warning">⚠ 未読のお知らせがあります</p>
</div>
```

---

### 2.6 Color Usage Principles（カラー使用原則）

#### ✅ Good Practices
```html
<!-- 適切なコントラスト -->
<button class="bg-primary-start text-white">ボタン</button>

<!-- 状態変化の明確化 -->
<button class="bg-accent-main hover:bg-accent-light transition-colors">
  ホバー効果
</button>
```

#### ❌ Bad Practices
```html
<!-- 赤×緑の組み合わせ（色覚差への配慮不足） -->
<div class="text-red-500 bg-green-500">NG</div>

<!-- 低コントラスト（可読性不足） -->
<p class="text-gray-300 bg-gray-200">読みにくい</p>
```

---

## 3. Typography System

### 3.1 Font Family（フォントファミリー）

```javascript
fontFamily: {
  sans: [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'Noto Sans JP',
    'sans-serif',
  ],
}
```

**理由**:
- システムフォント優先（読み込み速度向上）
- 日本語: Noto Sans JP（ユニバーサルデザインフォント）
- マルチプラットフォーム対応

---

### 3.2 Font Size（フォントサイズ）

```javascript
fontSize: {
  'xs': ['0.875rem', { lineHeight: '1.25rem' }],  // 14px - 補足情報
  'sm': ['0.875rem', { lineHeight: '1.25rem' }],  // 14px - small
  'base': ['1rem', { lineHeight: '1.5rem' }],     // 16px - 本文
  'md': ['1rem', { lineHeight: '1.5rem' }],       // 16px - h4
  'lg': ['1.125rem', { lineHeight: '1.75rem' }],  // 18px - h3
  'xl': ['1.25rem', { lineHeight: '1.75rem' }],   // 20px - h2
  '2xl': ['1.5rem', { lineHeight: '2rem' }],      // 24px - h1
}
```

**使用原則**:
- モバイル優先（16px = 1rem）
- 見出し階層を明確に
- 行間は1.6-1.8を推奨

**Tailwind実装例**:
```html
<h1 class="text-2xl font-bold">ページタイトル</h1>
<h2 class="text-xl font-semibold">セクション見出し</h2>
<h3 class="text-lg font-medium">サブセクション</h3>
<p class="text-base">本文テキスト</p>
<small class="text-xs text-text-tertiary">補足情報</small>
```

---

### 3.3 Font Weight（フォントウェイト）

```javascript
fontWeight: {
  normal: '400',    // 通常テキスト
  medium: '500',    // 強調テキスト
  semibold: '600',  // 見出し
  bold: '700',      // 重要な見出し
}
```

---

### 3.4 Line Height（行間）

```javascript
lineHeight: {
  tight: '1.25',    // 見出し用
  normal: '1.5',    // 通常
  relaxed: '1.75',  // 読みやすさ重視
  loose: '2',       // 余白重視
}
```

---

## 4. Spacing System

### 4.1 Spacing Scale（スペーシングスケール）

```javascript
spacing: {
  'xs': '4px',   // 0.25rem - 最小間隔
  'sm': '8px',   // 0.5rem - 小さな余白
  'md': '16px',  // 1rem - 標準的な余白
  'lg': '24px',  // 1.5rem - 大きな余白
  'xl': '32px',  // 2rem - セクション間の余白
  '2xl': '48px', // 3rem - 大セクション間
}
```

**原則**: 4の倍数で統一

**Tailwind実装例**:
```html
<!-- パディング -->
<div class="p-md">標準パディング（16px）</div>
<div class="px-lg py-md">水平24px、垂直16px</div>

<!-- マージン -->
<section class="mb-xl">セクション下部32px余白</section>

<!-- ギャップ（Flexbox/Grid） -->
<div class="flex gap-sm">8pxの間隔</div>
```

---

## 5. Layout System

### 5.1 Three-Layer Structure（3層構造）

全画面共通の基本レイアウト：

```html
<div class="min-h-screen flex flex-col">
  <!-- Header -->
  <header class="page-header bg-white border-b border-background-border">
    <!-- ヘッダーコンテンツ -->
  </header>

  <!-- Main Content -->
  <main class="page-content flex-1 bg-background-primary overflow-y-auto">
    <!-- メインコンテンツ -->
  </main>

  <!-- Footer -->
  <footer class="page-footer bg-white border-t border-background-border">
    <!-- フッターコンテンツ -->
  </footer>
</div>
```

**原則**:
- Header/Footerは全画面共通（編集禁止）
- Main Contentのみカスタマイズ可能

---

### 5.2 Container（コンテナ）

```javascript
maxWidth: {
  'mobile': '420px',   // モバイル
  'tablet': '768px',   // タブレット
  'desktop': '1024px', // デスクトップ
}
```

**Tailwind実装例**:
```html
<div class="container mx-auto max-w-desktop px-md">
  <!-- コンテンツ -->
</div>
```

---

### 5.3 Card Component（カードコンポーネント）

```html
<div class="bg-background-secondary rounded-card shadow-card border border-background-border p-md">
  <!-- カードコンテンツ -->
</div>
```

**定義**:
```javascript
borderRadius: {
  'card': '12px',
  'button': '8px',
}

boxShadow: {
  'card': '0 2px 8px rgba(0, 0, 0, 0.1)',
}
```

---

## 6. Component Specifications

### 6.1 Button（ボタン）

#### Primary Button
```html
<button class="
  bg-gradient-to-r from-primary-start to-primary-end
  text-white
  px-6 py-3
  rounded-button
  font-semibold
  transition-all duration-200
  hover:opacity-90
  active:scale-95
">
  プライマリボタン
</button>
```

#### Secondary Button
```html
<button class="
  bg-accent-main
  text-white
  px-6 py-3
  rounded-button
  font-semibold
  transition-colors duration-200
  hover:bg-accent-light
">
  セカンダリボタン
</button>
```

#### Outline Button
```html
<button class="
  border-2 border-accent-main
  text-accent-main
  bg-transparent
  px-6 py-3
  rounded-button
  font-semibold
  transition-all duration-200
  hover:bg-accent-main hover:text-white
">
  アウトラインボタン
</button>
```

---

### 6.2 Input Field（入力フォーム）

```html
<input
  type="text"
  class="
    w-full
    px-4 py-3
    border border-background-border
    rounded-button
    bg-background-secondary
    text-text-primary
    placeholder-text-tertiary
    focus:outline-none
    focus:ring-2
    focus:ring-accent-main
    focus:border-transparent
    transition-all duration-200
  "
  placeholder="入力してください"
/>
```

---

### 6.3 Card（カード）

```html
<div class="
  bg-background-secondary
  rounded-card
  shadow-card
  border border-background-border
  p-md
  hover:shadow-lg
  transition-shadow duration-200
">
  <h3 class="text-lg font-semibold text-text-primary mb-sm">
    カードタイトル
  </h3>
  <p class="text-text-secondary">
    カードの説明文
  </p>
</div>
```

---

### 6.4 Badge（バッジ）

```html
<!-- 未読バッジ -->
<span class="
  inline-block
  px-3 py-1
  bg-state-warning
  text-white
  text-xs
  font-bold
  rounded-full
">
  未読
</span>

<!-- カテゴリバッジ -->
<span class="
  inline-block
  px-3 py-1
  bg-blue-50
  text-blue-700
  text-xs
  font-semibold
  rounded-full
  border border-blue-200
">
  お知らせ
</span>
```

---

## 7. Responsive Design

### 7.1 Breakpoints（ブレイクポイント）

```javascript
screens: {
  'mobile': '0px',      // 0-599px
  'tablet': '600px',    // 600-1023px
  'desktop': '1024px',  // 1024px以上
}
```

---

### 7.2 Mobile-First Approach（モバイルファースト）

**原則**: デフォルトはモバイル、大画面で拡張

```html
<!-- モバイル: 1カラム、タブレット以上: 2カラム -->
<div class="grid grid-cols-1 tablet:grid-cols-2 gap-md">
  <div>カラム1</div>
  <div>カラム2</div>
</div>

<!-- フォントサイズのレスポンシブ -->
<h1 class="text-xl tablet:text-2xl desktop:text-3xl">
  見出し
</h1>

<!-- パディングのレスポンシブ -->
<div class="p-sm tablet:p-md desktop:p-lg">
  コンテンツ
</div>
```

---

### 7.3 Common Responsive Patterns

#### ナビゲーション
```html
<!-- モバイル: 縦並び、デスクトップ: 横並び -->
<nav class="flex flex-col desktop:flex-row gap-sm">
  <a href="#">リンク1</a>
  <a href="#">リンク2</a>
  <a href="#">リンク3</a>
</nav>
```

#### グリッドレイアウト
```html
<!-- モバイル: 1列、タブレット: 2列、デスクトップ: 3列 -->
<div class="grid grid-cols-1 tablet:grid-cols-2 desktop:grid-cols-3 gap-md">
  <!-- アイテム -->
</div>
```

---

## 8. Implementation Guidelines

### 8.1 CSS Variable Integration（CSS変数統合）

既存のCSS変数とTailwindを併用する場合：

```css
/* variables.css */
:root {
  --color-primary-start: #667eea;
  --color-primary-end: #764ba2;
  --space-md: 16px;
}
```

```javascript
// tailwind.config.js で参照
theme: {
  extend: {
    colors: {
      primary: {
        start: 'var(--color-primary-start)',
        end: 'var(--color-primary-end)',
      }
    }
  }
}
```

---

### 8.2 BEM to Tailwind Migration（BEM→Tailwind移行）

#### Before (BEM)
```html
<div class="post-card">
  <div class="post-card__header">
    <span class="post-card__category">運営</span>
  </div>
  <button class="post-card__button post-card__button--primary">
    確認
  </button>
</div>
```

#### After (Tailwind)
```html
<div class="bg-background-secondary rounded-card shadow-card p-md">
  <div class="flex items-center justify-between mb-sm">
    <span class="px-3 py-1 bg-blue-50 text-blue-700 text-xs font-semibold rounded-full">
      運営
    </span>
  </div>
  <button class="w-full bg-accent-main text-white py-3 rounded-button font-semibold hover:bg-accent-light">
    確認
  </button>
</div>
```

---

### 8.3 Prohibited Practices（禁止事項）

#### ❌ Arbitrary Values（任意の値）の乱用
```html
<!-- NG: システム外の値 -->
<div class="p-[13px] text-[#abc123]">NG</div>

<!-- OK: 定義済みトークン使用 -->
<div class="p-md text-accent-main">OK</div>
```

#### ❌ !important の使用
```html
<!-- NG -->
<div class="!bg-red-500">NG</div>

<!-- OK: 優先度を考慮した設計 -->
<div class="bg-red-500">OK</div>
```

#### ❌ インラインスタイル
```html
<!-- NG -->
<div style="color: red;">NG</div>

<!-- OK: Tailwindクラス使用 -->
<div class="text-red-500">OK</div>
```

---

### 8.4 Performance Optimization（パフォーマンス最適化）

#### PurgeCSS設定
```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
    './public/index.html',
  ],
  // ...
}
```

#### JIT Mode（推奨）
```javascript
// tailwind.config.js
module.exports = {
  mode: 'jit', // Just-In-Time モード
  // ...
}
```

---

## 9. References

### Internal Documents
- `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.txt`
- `03_SCREEN_SPEC_Home_Design_v1_0.html`
- `03_SCREEN_SPEC_Board_Feature_Design_v1_0.html`
- `04_DEV_STANDARD_Naming_Conventions_v2_1_EN.md`
- `05_PROJECT_Structure_v3_3_EN.md`

### External Resources
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)

---

## 10. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-27 | TKD + Claude | 初版作成 |

---

**End of Document**
