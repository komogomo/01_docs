# 共通ヘッダー領域設計書 v1.1

**Document ID:** SEC-APP-COMMON-HEADER-001  
**Version:** 1.1  
**Created:** 2025年10月27日  
**Updated:** 2025年10月27日  
**Design System:** HarmoNet Design System v1  
**Purpose:** 全画面共通のヘッダー領域詳細仕様

---

## 1. 概要

本ドキュメントは、ハーモネットアプリの**ヘッダー領域**の詳細仕様を定義します。

### 1.1 適用範囲

- **対象画面:** ログイン画面を除く全画面
- **表示位置:** 画面最上部（固定表示）

### 1.2 設計原則

- **視認性:** 重要な機能（通知、言語切替）を常時表示
- **一貫性:** 全画面で同じレイアウト・デザイン
- **アクセス性:** タップ領域を十分に確保（最小44px×44px）
- **静けさ:** HarmoNetの「静かで、安心できる、永く使えるUI」に準拠

---

## 2. 基本仕様

### 2.1 レイアウト

```
┌──────────────────────────────────────────────────┐
│  [ロゴ]              [通知ボタン] [言語切替]     │
│  HarmoNET               🔔          JA ▼       │
└──────────────────────────────────────────────────┘
```

### 2.2 寸法

| 項目 | 値 | 備考 |
|------|-----|------|
| **高さ** | 60px（固定） | スマートフォンは56px |
| **幅** | 100%（画面幅いっぱい） | - |
| **内部パディング** | 左右: 20px、上下: 12px | HarmoNet余白基準準拠 |
| **z-index** | 1000 | 最前面表示 |

---

## 3. 配置要素

### 3.1 アプリ名（ロゴ）

#### 3.1.1 基本情報

| 項目 | 値 |
|------|-----|
| **位置** | 左端 |
| **サイズ** | 150px × 40px |
| **テキスト** | 「HarmoNET」（英語固定） |
| **フォント** | BIZ UDゴシック, -apple-system, sans-serif |
| **フォントサイズ** | 18px (H1サイズ) |
| **フォントウェイト** | 600 (Semibold) |
| **色** | `#1F2937`（主要文字色） |

#### 3.1.2 機能

- タップすると HOME 画面へ遷移
- どの画面からでも HOME に戻れる導線

#### 3.1.3 多言語対応

アプリ名は**日本語固定**です。言語切替を行っても変更されません。

---

### 3.2 通知ボタン

#### 3.2.1 基本情報

| 項目 | 値 |
|------|-----|
| **位置** | 右側（言語切替ボタンの左隣） |
| **サイズ** | 40px × 40px |
| **アイコン** | 🔔（ベル）または線形アイコン |
| **アイコンサイズ** | 24px × 24px |
| **アイコン色** | `#6B7280`（副次文字色） |
| **タップ領域** | 44px × 44px（最小） |

#### 3.2.2 未読通知バッジ

未読通知がある場合、ベルアイコンの右上に赤いバッジを表示:

| 項目 | 値 |
|------|-----|
| **形状** | 円形 |
| **サイズ** | 直径16px |
| **背景色** | `#DC2626`（注意レッド） |
| **テキスト色** | `#FFFFFF`（白） |
| **フォントサイズ** | 10px |
| **フォントウェイト** | 600 (Semibold) |
| **表示内容** | 未読件数（最大99、それ以上は「99+」） |

#### 3.2.3 機能

- タップすると通知一覧画面へ遷移
- 未読件数は API から取得（`/api/notifications/unread-count`）
- リアルタイム更新（5分ごと、または画面遷移時）

#### 3.2.4 ホバー時（PC/タブレット）

```css
.notification-btn:hover {
  background-color: #F9FAFB;
  border-radius: 0.5rem;
}
```

#### 3.2.5 アクセシビリティ

```html
<button aria-label="通知 (未読3件)" class="notification-btn">
  <svg class="notification-icon" width="24" height="24">
    <!-- アイコンSVG -->
  </svg>
  <span class="notification-badge">3</span>
</button>
```

---

### 3.3 言語切替ボタン

#### 3.3.1 基本情報

| 項目 | 値 |
|------|-----|
| **位置** | 右端 |
| **サイズ** | 80px × 40px |
| **表示形式** | 「JA ▼」「EN ▼」「CN ▼」 |
| **フォントサイズ** | 14px |
| **フォントウェイト** | 500 (Medium) |
| **色** | `#6B7280`（副次文字色） |
| **背景色** | `#F9FAFB`（ベースカラー） |
| **角丸** | 0.5rem (8px) |

#### 3.3.2 言語コード

| 言語 | コード | 表示 |
|------|--------|------|
| 日本語 | ja | JA |
| 英語 | en | EN |
| 中国語（簡体字） | zh | CN |

#### 3.3.3 動作

**ドロップダウンメニュー方式:**

1. ボタンをタップすると、下方向にメニューが表示
2. メニューには3言語のオプションが表示
3. 選択した言語に即座に切り替わる
4. 選択後、メニューは自動的に閉じる

**ドロップダウンメニューの仕様:**

| 項目 | 値 |
|------|-----|
| **幅** | 100px |
| **背景色** | `#FFFFFF`（白） |
| **ボーダー** | 1px solid `#E5E7EB` |
| **影** | `0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)` |
| **角丸** | 0.5rem (8px) |
| **各項目の高さ** | 40px |
| **ホバー時の背景色** | `#F9FAFB` |

#### 3.3.4 選択状態

選択中の言語オプション:

| 項目 | 値 |
|------|-----|
| **背景色** | `#DBEAFE`（アクションブルー Light） |
| **テキスト色** | `#2563EB`（アクションブルー） |
| **フォントウェイト** | 600 (Semibold) |

#### 3.3.5 状態の永続化

選択した言語は以下に保存:
- **localStorage:** `selectedLanguage` キー
- **ユーザーマスタ:** `preferred_language` カラム（ログイン中の場合）

#### 3.3.6 詳細設計

> **📄 詳細は別紙参照**
> 
> 言語切替機能の詳細については、以下のドキュメントを参照してください:
> - 『**common-i18n-v1_0.md**』

---

## 4. スタイル仕様（HarmoNet準拠）

### 4.1 背景色

**重要:** HarmoNet Design System v1では、グラデーションを使用しません。

```css
background-color: #FFFFFF;
```

- 背景色: 白色（`#FFFFFF`）
- 落ち着いた、静かな印象を優先

### 4.2 下部ボーダー

ヘッダー下部に枠線を表示し、コンテンツ領域との境界を明確化:

```css
border-bottom: 1px solid #E5E7EB;
```

### 4.3 影（最小限使用）

ヘッダーには基本的に影を使用しません。必要に応じて最小限の影を適用:

```css
/* 基本は影なし */
box-shadow: none;

/* 必要な場合のみ使用 */
box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
```

### 4.4 固定表示

ヘッダーは常に画面最上部に固定表示:

```css
position: fixed;
top: 0;
left: 0;
right: 0;
z-index: 1000;
```

---

## 5. レスポンシブ対応

### 5.1 デバイスごとの調整

| デバイス | ヘッダー高さ | ロゴサイズ | ボタンサイズ | パディング |
|---------|------------|----------|------------|-----------|
| **スマートフォン** | 56px | 140px × 36px | 36px × 36px | 左右: 20px |
| **タブレット** | 60px | 150px × 40px | 40px × 40px | 左右: 24px |
| **デスクトップ** | 60px | 150px × 40px | 40px × 40px | 左右: 32px |

### 5.2 小画面での最適化

スマートフォン（< 375px）では、以下の調整を行います:
- アプリ名のフォントサイズを16pxに縮小
- 言語切替ボタンを70px幅に縮小

---

## 6. インタラクション

### 6.1 ホバーエフェクト（PC/タブレット）

| 要素 | ホバー時の変化 |
|------|---------------|
| アプリ名 | カーソルがポインターに変化、色は変更なし |
| 通知ボタン | 背景色が`#F9FAFB`に変化 |
| 言語切替ボタン | 背景色が`#E5E7EB`に変化 |

**HarmoNet準拠:**
- hover時のみ彩度をわずかに上げる
- 派手なアニメーションは不要

```css
.app-title-link:hover {
  cursor: pointer;
}

.notification-btn:hover,
.language-btn:hover {
  background-color: #F9FAFB;
  transition: background-color 0.15s ease-in-out;
}
```

### 6.2 タップフィードバック（モバイル）

ボタンをタップした瞬間、以下のフィードバックを表示:
- **背景色:** 一時的に`#E5E7EB`に変化
- **継続時間:** 150ms

---

## 7. アクセシビリティ

### 7.1 キーボードナビゲーション

| 操作 | 動作 |
|------|------|
| Tab キー | フォーカスが「ロゴ → 通知ボタン → 言語切替ボタン」の順に移動 |
| Enter / Space キー | フォーカス中のボタンを実行 |
| Esc キー | 開いているドロップダウンメニューを閉じる |

### 7.2 スクリーンリーダー対応

```html
<header role="banner" class="app-header">
  <a href="/home" aria-label="ホーム画面に戻る">
    <h1 class="app-title">セキュレアシティ</h1>
  </a>
  <button aria-label="通知 (未読3件)" class="notification-btn">
    <svg class="notification-icon" aria-hidden="true" width="24" height="24">
      <!-- アイコンSVG -->
    </svg>
    <span aria-hidden="true" class="notification-badge">3</span>
  </button>
  <button aria-label="言語切替" aria-haspopup="true" aria-expanded="false" class="language-btn">
    <span class="language-code">JA</span>
    <span class="dropdown-icon" aria-hidden="true">▼</span>
  </button>
</header>
```

### 7.3 コントラスト比

すべてのテキストとアイコンは、WCAG 2.1 レベルAA準拠のコントラスト比を確保:

| 要素 | 前景色 | 背景色 | 比率 | 状態 |
|------|--------|--------|------|------|
| アプリ名 | `#1F2937` | `#FFFFFF` | 14.5:1 | ✅ AAA |
| ボタンテキスト | `#6B7280` | `#FFFFFF` | 5.6:1 | ✅ AA |
| アクティブ時 | `#2563EB` | `#DBEAFE` | 4.8:1 | ✅ AA |
| 通知バッジ | `#FFFFFF` | `#DC2626` | 5.4:1 | ✅ AA |

---

## 8. パフォーマンス

### 8.1 初期ロード

- ヘッダーは HTML 内に直接記述（JavaScript 不要）
- 未読件数のみ API 取得（非同期）

### 8.2 未読件数の取得

| 項目 | 値 |
|------|-----|
| **API エンドポイント** | `/api/notifications/unread-count` |
| **更新頻度** | 5分ごと、または画面遷移時 |
| **タイムアウト** | 3秒 |
| **エラー時の表示** | バッジを非表示 |

---

## 9. 実装例（HTML）

```html
<header class="app-header">
  <!-- アプリ名（ロゴ） -->
  <a href="/home" class="app-title-link" aria-label="ホーム画面に戻る">
    <h1 class="app-title">セキュレアシティ</h1>
  </a>

  <!-- 通知ボタン -->
  <button class="notification-btn" aria-label="通知 (未読3件)">
    <svg class="notification-icon" width="24" height="24" aria-hidden="true">
      <path d="M..." stroke="#6B7280" stroke-width="1.5" fill="none" />
    </svg>
    <span class="notification-badge">3</span>
  </button>

  <!-- 言語切替ボタン -->
  <div class="language-switcher">
    <button class="language-btn" aria-haspopup="true" aria-expanded="false" aria-label="言語切替">
      <span class="language-code">JA</span>
      <span class="dropdown-icon" aria-hidden="true">▼</span>
    </button>
    <ul class="language-menu" role="menu" hidden>
      <li role="menuitem">
        <button data-lang="ja" class="language-menu-item language-menu-item--active">
          日本語 (JA)
        </button>
      </li>
      <li role="menuitem">
        <button data-lang="en" class="language-menu-item">
          English (EN)
        </button>
      </li>
      <li role="menuitem">
        <button data-lang="zh" class="language-menu-item">
          中文 (CN)
        </button>
      </li>
    </ul>
  </div>
</header>
```

---

## 10. CSS実装例（HarmoNet準拠）

```css
/* ヘッダー全体 */
.app-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 60px;
  background-color: #FFFFFF;
  border-bottom: 1px solid #E5E7EB;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  z-index: 1000;
}

/* アプリ名 */
.app-title {
  font-size: 18px;
  font-weight: 600;
  color: #1F2937;
  margin: 0;
  line-height: 1.6;
}

.app-title-link {
  text-decoration: none;
}

/* 通知ボタン */
.notification-btn {
  position: relative;
  width: 40px;
  height: 40px;
  border: none;
  background: transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  transition: background-color 0.15s ease-in-out;
}

.notification-btn:hover {
  background-color: #F9FAFB;
}

.notification-icon {
  width: 24px;
  height: 24px;
  color: #6B7280;
}

.notification-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 16px;
  height: 16px;
  background-color: #DC2626;
  color: #FFFFFF;
  border-radius: 50%;
  font-size: 10px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 言語切替ボタン */
.language-btn {
  min-width: 80px;
  height: 40px;
  padding: 0 12px;
  background-color: #F9FAFB;
  border: none;
  border-radius: 0.5rem;
  color: #6B7280;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  transition: background-color 0.15s ease-in-out;
}

.language-btn:hover {
  background-color: #E5E7EB;
}

/* ドロップダウンメニュー */
.language-menu {
  position: absolute;
  top: calc(100% + 4px);
  right: 0;
  width: 100px;
  background-color: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
  list-style: none;
  margin: 0;
  padding: 0;
  overflow: hidden;
}

.language-menu-item {
  width: 100%;
  height: 40px;
  padding: 0 12px;
  border: none;
  background: transparent;
  color: #6B7280;
  font-size: 14px;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s ease-in-out;
}

.language-menu-item:hover {
  background-color: #F9FAFB;
}

.language-menu-item--active {
  background-color: #DBEAFE;
  color: #2563EB;
  font-weight: 600;
}

/* レスポンシブ対応 */
@media (max-width: 767px) {
  .app-header {
    height: 56px;
  }
  
  .app-title {
    font-size: 16px;
  }
  
  .notification-btn,
  .language-btn {
    width: 36px;
    height: 36px;
  }
}
```

---

## 11. デザイン哲学の適用

### 11.1 「静かで、安心できる、永く使えるUI」の実現

**1. 静けさの表現:**
- グラデーション背景を削除し、白色で統一
- アイコン色をグレー階調で抑える（`#6B7280`）
- 装飾的な要素を最小限に

**2. 安心感の提供:**
- 明確な境界線（下部ボーダー）で領域を区別
- 視認性の高いコントラスト比を確保
- アクセシビリティ基準の遵守

**3. 永く使える設計:**
- トレンドに左右されないシンプルな配色
- 明確で理解しやすいレイアウト
- 最小限の影とアニメーション

**4. 余白による呼吸感:**
- 20px〜32pxのパディングで適切な余白を確保
- 要素間に適切な距離を保つ

---

## 12. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-design-system-v1_1.md` | デザインシステム（HarmoNet準拠） |
| `common-layout-v1_0.md` | 3層構造の全体設計 |
| `common-i18n-v1_0.md` | 言語切替・翻訳機能の詳細 |
| `common-notification-v1_0.md` | 通知機能の詳細 |
| `common-accessibility-v1_0.md` | アクセシビリティ要件 |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-HEADER-001
- バージョン: 1.1
- 作成日: 2025年10月27日
- 更新日: 2025年10月27日
- デザインシステム: HarmoNet Design System v1
- 承認者: （未定）
