# HarmoNet 共通ヘッダー領域設計書

**Document ID:** HNM-COMMON-HEADER-001
**Updated:** 2025-11-19

---

## 1. 概要

本書は HarmoNet アプリケーション全画面で共通利用される **AppHeader（C-01）** の基本仕様を定義する。
対象範囲は「UI 構造・配置・役割」のみとし、詳細な JSX/Tailwind 実装は別紙の **C-01 AppHeader 詳細設計書** に委譲する。

---

## 2. 適用範囲

### 2.1 表示対象

* HOME を含む **ログイン後の全画面**

### 2.2 非表示対象

* LoginPage（A-00）

### 2.3 本書で扱う内容

* AppHeader の論理構造（ロゴ / 通知 / 言語切替）
* レイアウトと役割
* i18n 対応の方針
* アクセシビリティの基本要件

### 2.4 本書で扱わない内容

* JSX / Tailwind の詳細コード
* 状態管理ロジック（通知件数の算出等）
* 通知機能自体の仕様（別設計書）
* 詳細な翻訳キー構成（C-03/C-02 にて定義）

---

## 3. ヘッダー構成（基本設計）

AppHeader は画面上部に固定表示され、以下 3 要素で構成される：

```
┌─────────────────────────────────────┐
│ [HarmoNetロゴ]       [通知(Bell)]   [LanguageSwitch] │
└─────────────────────────────────────┘
```

### 3.1 ロゴ（アプリ名）

* 表示テキスト：`HarmoNet`
* 位置：左端に固定
* 挙動：押下時に `/home` へ遷移（共通導線）
* アクセシビリティ：`aria-label="ホーム画面に戻る"`

### 3.2 通知アイコン（Lucide Icons `Bell`）

* 設置位置：右上、LanguageSwitch の左隣
* 役割：お知らせ一覧画面 `/notices` への導線
* 未読件数表示：基本設計では扱わず、詳細設計（通知設計書）で定義
* アイコン：Lucide Icons

  * 名称：`Bell`
  * 色・サイズは詳細設計で定義
* アクセシビリティ：`aria-label="お知らせ"`

### 3.3 LanguageSwitch（C-02）

* 右端に固定配置
* JA / EN / ZH の 3ボタン
* StaticI18nProvider の locale / setLocale を使用
* タップ領域 48×48px 以上（基本設計レベルの要求）
* 詳細仕様は **`ch02_LanguageSwitch_v1.1.md`** に準拠

---

## 4. レイアウト（基本設計レベル）

* 配置：左右フレックス（左：ロゴ、右：通知＋切替）
* 高さ：**約 56〜60px**（SP=56px / PC=60px 目安）
* 背景：白（Design System）
* 下部ボーダー：1px（gray-200）
* 余白：左右 16〜24px

詳細な Tailwind クラス指定は AppHeader 詳細設計書にて行う。

---

## 5. アクセシビリティ（方針）

* `<header>` 要素を使用
* 必要に応じて `role="banner"` を付与
* フォーカス順：ロゴ → 通知 → LanguageSwitch
* フォーカスリング：Design System の標準（青）
* アイコンは `aria-hidden="true"`、ラベルで意味を伝達

---

## 6. i18n（基本設計レベル）

AppHeader 自体が保持する翻訳キーは存在しないが、
以下のような i18n キーを利用する画面もあるため、LanguageSwitch との連携を考慮する。

例：

* `nav.home`
* `nav.notices`
* `nav.language`

文言の実体および JSON は StaticI18nProvider 詳細設計書で定義する。

---

## 7. HOME 基本設計との関係

* HOME 画面（ch00〜ch04）は「コンテンツ領域のみ」を記載する方針
* AppHeader は HOME 側には仕様を書かず、本書（C-01）を参照する
* HOME の構成変更（ウェルカム削除）により、Header 要素は HOME 画面の最上部固定に一本化された

---

## 8. フロントエンド公式ディレクトリ構成との整合

本コンポーネントは **`src/components/common/AppHeader/`** に配置する。

```
src/components/common/AppHeader/
  AppHeader.tsx
  AppHeader.types.ts
  AppHeader.test.tsx
  AppHeader.stories.tsx
  index.ts
```

import ルール：

```
import { AppHeader } from '@/src/components/common/AppHeader/AppHeader';
```

---

## 9. 本章まとめ

* AppHeader はロゴ・通知・LanguageSwitch の3構成
* Lucide Icons を採用し、Bell を使用
* 詳細ロジック・スタイリングは詳細設計書に委譲
* HOME 側には仕様を重複記載せず、本書が唯一の正

---

**End of Document **
