# C-02 LanguageSwitch 基本設計書

**Document ID:** HNM-COMMON-C02-LANGUAGESWITCH-BASIC
**Updated:** 2025-11-19

---

## 1. 概要（Purpose）

LanguageSwitch（C-02）は、HarmoNet 全画面で使用される **共通言語切替 UI コンポーネント**である。本書は **基本設計書** として、UI・役割・配置・動作方針を定義し、詳細なロジックや JSX／Tailwind 記述は **詳細設計書（v1.1）** に委譲する。

本コンポーネントは AppHeader（C-01）内に配置され、ユーザーが **日本語／英語／中国語（簡体）** を即時切替できる共通 UI として設計する。

---

## 2. 適用範囲（Scope）

### ✔ 対象

* 言語切替 UI（3ボタン：JA / EN / 中文）
* AppHeader 内での配置位置（右端）
* 全画面共通の表示要件
* コンポーネントの **役割・構造・基本UI方針**

### ❌ 対象外（詳細設計書で扱う）

* 型定義（Props / Locale 型）
* Tailwind クラス・色・角丸・フォント指定
* `useI18n()` のロジック（StaticI18nProvider の責務）
* JSX 構造の最終形
* UT 観点・テストケース
* フォーカスリングや aria 属性の最終定義

---

## 3. 役割（Role）

LanguageSwitch の役割は以下の 2 点に限定する：

1. **現在の言語を視覚的に示す**（選択状態の強調）
2. **ユーザー操作で言語を切り替える**（JA/EN/中文）

実際の翻訳処理や辞書ロードは **StaticI18nProvider（C-03）** が担い、本コンポーネントは UI と操作イベントのみ担当する。

---

## 4. 配置位置（Placement）

LanguageSwitch は **AppHeader（C-01）の右端** に固定配置する。
他 UI と重複しないよう、通知アイコン（Bell）の右隣に位置づける。

```
[ HarmoNetロゴ ]       [通知(Bell)]  [ JA | EN | 中文 ]
```

* ログイン前（/login）・ログイン後のすべての画面で常時表示される。
* 画面幅に応じてレイアウトは柔軟に縮むが、**3 ボタン構造は変えない**。

---

## 5. UI 方針（Design Guidelines）

HarmoNet 共通 UI 方針「やさしい・自然・控えめ」に従い、次の方針で設計する：

### 5.1 ボタン構造（基本設計レベル）

* ボタンは 3 個並列（JA / EN / 中文）
* 横方向の `flex-row` を基本構造とする
* 余白・角丸・色が控えめで均一であること

### 5.2 選択状態

* 現在の locale に対応するボタンを強調表示する
* 強調方法は **色** と **枠線** のみ（アニメーションは不要）

### 5.3 タップ領域

* モバイル最適化として最小 **48×48px** を確保する
* 誤タップを避けたストレスの無い操作性

### 5.4 レスポンシブ

* 横幅が非常に狭い場合のみ、内部余白が縮むが **3 ボタン構成は固定**
* 言語表記（JA/EN/中文）は省略しない（UI トーン維持のため）

### 5.5 i18n

* 言語ラベル（JA/EN/中文）は UI 固定のため翻訳対象外
* その他文言は StaticI18nProvider が管理

---

## 6. 動作仕様（基本設計レベル）

LanguageSwitch の振る舞いは以下に限定する：

### ✔ 言語の即時切替

* ボタン押下 → `setLocale(code)` を呼ぶ（StaticI18nProvider 内部で処理）
* 翻訳辞書が即時再ロードされ、画面全体が更新される

### ✔ 画面遷移は伴わない

* 言語切替はページ遷移なし（SPA 内での UI 更新のみ）

### ✔ エラー処理は保持しない

* 辞書ロード失敗などの例外は StaticI18nProvider が処理する
* 当コンポーネントは try/catch を持たない（UI の責務ではない）

---

## 7. アクセシビリティ（方針）

* ボタンに `aria-label="<言語> に切り替え"` を付与する
* 現在の言語ボタンに `aria-pressed="true"` を設定
* フォーカスリングは Design System の標準（青系）
* スクリーンリーダーで 3 つの言語ボタンの役割が明確になる構造とする

詳細な ARIA / キーボード操作仕様は **詳細設計書 v1.1** で定義する。

---

## 8. 依存関係（Dependencies）

### 8.1 依存コンポーネント

* **C-01 AppHeader**（親 UI）
* **C-03 StaticI18nProvider**（locale 管理・辞書ロード）

### 8.2 外部依存

* React（Event / Rendering）
* TailwindCSS（スタイル適用：詳細設計で扱う）

---

## 9. ディレクトリ配置（Frontend Official Directory v1.0 準拠）

```
src/components/common/LanguageSwitch/
  LanguageSwitch.tsx
  LanguageSwitch.types.ts
  LanguageSwitch.test.tsx
  LanguageSwitch.stories.tsx
  index.ts
```

import ルール：

```
import { LanguageSwitch } from '@/src/components/common/LanguageSwitch/LanguageSwitch';
```

---

## 10. 本章まとめ

* LanguageSwitch は共通部品（C-02）として全画面で使用
* UI は 3 ボタン構造で固定（JA/EN/中文）
* 言語切替は StaticI18nProvider の責務であり UI は操作のみ担当
* 基本設計書として、構造・役割・UI方針・配置のみ記述
* Tailwind / JSX / ロジック詳細は詳細設計（v1.1）に委譲

---

**End of Document **
