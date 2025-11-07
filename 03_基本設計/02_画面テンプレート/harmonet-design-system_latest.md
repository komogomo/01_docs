# HarmoNet Design System（最新）
**Document Category:** デザインシステム定義書  
**Location:** `/01_docs/01_basic_design/`  
**Status:** 承認済（Phase 7 完了）  
**Target:** 全UI・コンポーネント共通デザイン基盤  
**Supersedes:** common-design-system_v1.0.md

---

## 🎯 目的
本書は、HarmoNet プロジェクトにおける全体的なデザイン体系を統一するための
基礎トークン・スタイルルール・テーマ構成を定義する。  
「やさしく・自然・控えめ」かつ「Appleカタログ風ミニマル」を設計思想とする。

---

## 🧩 デザイン哲学

| 原則 | 内容 |
|------|------|
| **Harmony First** | 人と人、情報とUIの調和を最優先。 |
| **Quiet Confidence** | 無駄を削ぎ落とした静けさの中に、信頼性を感じさせる。 |
| **Universal Comfort** | 年齢・文化を問わず、安心して触れられる配色と余白。 |
| **Subtle Depth** | シャドウや階層感を最小限にしながら、奥行きを感じさせる。 |

---

## 🎨 カラーパレット定義（Design Tokens）

| トークン名 | HEX | 用途 |
|-------------|------|------|
| `color-bg-primary` | #FFFFFF | メイン背景 |
| `color-bg-secondary` | #F7F8FA | サブ背景（カードなど） |
| `color-text-primary` | #333333 | メインテキスト |
| `color-text-secondary` | #666666 | 補助テキスト |
| `color-accent` | #007AFF | プライマリアクション（リンク・ボタン） |
| `color-border` | #DDDDDD | 枠線・分割線 |
| `color-success` | #2A9D8F | 成功・完了 |
| `color-warning` | #E9C46A | 注意・確認 |
| `color-danger` | #E63946 | エラー・削除 |
| `color-disabled` | #C0C0C0 | 非アクティブ要素 |

---

## 🧱 スペーシング（Spacing Scale）

| トークン | 値 | Tailwind例 | 用途 |
|-----------|----|-------------|------|
| `space-xs` | 4px | `p-1` | 極小間隔 |
| `space-sm` | 8px | `p-2` | コンポーネント内余白 |
| `space-md` | 16px | `p-4` | 標準余白 |
| `space-lg` | 24px | `p-6` | セクション間余白 |
| `space-xl` | 32px | `p-8` | コンテナ間余白 |
| `space-2xl` | 48px | `p-12` | ページ境界・大見出し間 |

---

## 🔲 角丸（Border Radius）

| トークン | 値 | Tailwindクラス | 用途 |
|-----------|----|----------------|------|
| `radius-sm` | 4px | `rounded-sm` | 小要素 |
| `radius-md` | 8px | `rounded-lg` | 標準ボタン |
| `radius-lg` | 12px | `rounded-xl` | カード・モーダル |
| `radius-2xl` | 16px | `rounded-2xl` | HarmoNet標準角丸 |
| `radius-full` | 9999px | `rounded-full` | 丸ボタン・アイコン |

---

## 🌫 シャドウ（Elevation）

| トークン | 値 | Tailwind例 | 用途 |
|-----------|----|-------------|------|
| `shadow-none` | none | `shadow-none` | フラットUI |
| `shadow-xs` | 0 1px 2px rgba(0,0,0,0.05) | `shadow-xs` | アイコン・小要素 |
| `shadow-sm` | 0 2px 4px rgba(0,0,0,0.06) | `shadow-sm` | カード・タイル |
| `shadow-md` | 0 4px 6px rgba(0,0,0,0.08) | `shadow-md` | モーダル・フローティング要素 |

---

## 🔠 タイポグラフィ（Typography Tokens）

| トークン | 値 | Tailwind例 | 用途 |
|-----------|----|-------------|------|
| `font-family-base` | "BIZ UDゴシック", system-ui | - | 全体フォント |
| `font-size-sm` | 12px | `text-xs` | 注釈 |
| `font-size-md` | 14px | `text-sm` | 通常本文 |
| `font-size-lg` | 16px | `text-base` | 小見出し |
| `font-size-xl` | 18px | `text-lg` | 大見出し |
| `font-size-2xl` | 20px | `text-xl` | ページタイトル |

---

## 🌈 テーマ構成

| テーマ | 特徴 | 主色 |
|---------|------|------|
| **Light** | デフォルト。白基調＋淡灰アクセント。 | #007AFF |
| **Warm** | 柔らかいトーン。背景に淡いベージュを採用。 | #E9C46A |
| **Contrast** | 高齢者向けコントラスト強化モード。 | #222222 / #FFFFFF |

---

## 🧭 アイコン・コンポーネント基準
- **ライブラリ:** Lucide React  
- **線幅:** 1.5px固定  
- **サイズ:** 20〜24px  
- **カラー:** `color-text-primary` に同期  
- **アクティブ状態:** 軽い影＋アニメーション（ease-in 120ms）  

---

## 🧠 アニメーション指針
| トークン | 値 | 用途 |
|-----------|----|------|
| `ease-in-fast` | cubic-bezier(0.4, 0, 1, 1) | ボタン押下 |
| `ease-out-smooth` | cubic-bezier(0, 0, 0.2, 1) | モーダル開閉 |
| `transition-base` | 150ms | デフォルトトランジション |

---

## 📱 レスポンシブ基準

| デバイス | 幅 | Tailwind breakpoint |
|-----------|----|----------------------|
| モバイル | 0〜640px | `sm:` |
| タブレット | 641〜1024px | `md:` |
| デスクトップ | 1025px〜 | `lg:` |

---

## 🔄 運用ルール
- デザイントークンは `Design_Tokens_v1.0.json` に同期。  
- Tailwind設定は `Tailwind_Config_v1.0.js` に従う。  
- `_latest.md` は常に最終確定版へのリンクとして使用。

---

**Document ID:** HNM-DESIGN-SYSTEM-LATEST-20251102  
**Version:** 1.0  
**Created:** 2025-11-02  
**Author:** Tachikoma (PMO / Architect)  
**For:** Claude / Gemini / TKD 共通参照  
**Supersedes:** common-design-system_v1.0.md  
