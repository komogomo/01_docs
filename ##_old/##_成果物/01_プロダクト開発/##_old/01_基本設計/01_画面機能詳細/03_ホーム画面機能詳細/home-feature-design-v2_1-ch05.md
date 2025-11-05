# 第5章: 機能タイルセクション

**Document:** HOME画面 機能設計書 v2.1  
**Chapter:** 5 of 5  
**Last Updated:** 2025/10/27  
**Design System:** HarmoNet Design System v1.0

---

## 5.1 レイアウト

機能タイルセクションは、アプリの各機能へのアクセスポイントとして機能します。

### デバイス別タイル配置

| デバイス | グリッド構成 | タイル数 | 備考 |
|---------|-------------|---------|------|
| **スマートフォン** | 2列×3行 | 6タイル | 縦スクロール不要 |
| **タブレット** | 3列×2行 | 6タイル | 横幅を有効活用 |
| **PC** | 3列×2行 | 6タイル | 中央寄せ、最大幅1024px |

### レイアウト図

**スマートフォン（2列×3行）:**
```
┌──────────┬──────────┐
│ タイル1  │ タイル2  │
├──────────┼──────────┤
│ タイル3  │ タイル4  │
├──────────┼──────────┤
│ タイル5  │ タイル6  │
└──────────┴──────────┘
```

**タブレット・PC（3列×2行）:**
```
┌──────────┬──────────┬──────────┐
│ タイル1  │ タイル2  │ タイル3  │
├──────────┼──────────┼──────────┤
│ タイル4  │ タイル5  │ タイル6  │
└──────────┴──────────┴──────────┘
```

---

## 5.2 機能タイル一覧（MVP）

### タイル定義

| No | 機能名(JA) | 機能名(EN) | 機能名(CN) | アイコン | MVP対象 | 遷移先 |
|----|------------|------------|------------|----------|---------|--------|
| 1 | 駐車場予約 | Parking | 停车场预约 | 🚗 | ✅ MVP | `/pages/parking/parking.html` |
| 2 | 回覧板 | Circulation | 传阅板 | 📋 | ✅ MVP | `/pages/circulation/circulation.html` |
| 3 | 掲示板 | Notice Board | 公告板 | 📌 | ✅ MVP | `/pages/board/board.html` |
| 4 | 通知設定 | Notifications | 通知设置 | 🔔 | ✅ MVP | `/pages/settings/notifications.html` |
| 5 | 入居者一覧 | Residents | 居民名单 | 👥 | ❌ 将来 | (未実装) |
| 6 | お問い合わせ | Contact | 联系我们 | 📧 | ❌ 将来 | (未実装) |

### MVP対象外の扱い

**グレーアウト表示:**
- 背景色: `#F3F4F6` (HarmoNet セカンダリ背景)
- アイコン: 透明度50%
- テキスト: `#9CA3AF` (HarmoNet テキストターシャリ)
- タップ不可（pointer-events: none）
- ツールチップ: 「この機能は準備中です」

**実装例（CSS）:**
```css
.tile--disabled {
  background-color: #F3F4F6; /* HarmoNet セカンダリ背景 */
  color: #9CA3AF; /* HarmoNet テキストターシャリ */
  opacity: 0.6;
  cursor: not-allowed;
  pointer-events: none;
}
```

---

## 5.3 タイルの多言語対応

### 翻訳データ構造

**翻訳キー定義:**
```javascript
{
  "tiles": {
    "parking": {
      "ja": "駐車場予約",
      "en": "Parking",
      "cn": "停车场预约"
    },
    "circulation": {
      "ja": "回覧板",
      "en": "Circulation",
      "cn": "传阅板"
    },
    "board": {
      "ja": "掲示板",
      "en": "Notice Board",
      "cn": "公告板"
    },
    "notifications": {
      "ja": "通知設定",
      "en": "Notifications",
      "cn": "通知设置"
    },
    "residents": {
      "ja": "入居者一覧",
      "en": "Residents",
      "cn": "居民名单"
    },
    "contact": {
      "ja": "お問い合わせ",
      "en": "Contact",
      "cn": "联系我们"
    }
  }
}
```

### 動的テキスト切替

**実装例:**
```javascript
const currentLang = localStorage.getItem('language') || 'ja';
const tileText = i18n.t(`tiles.${tileKey}.${currentLang}`);
```

**文字数の違いへの対応:**
- 日本語: 最大7文字
- 英語: 最大15文字（Notificationsなど）
- 中国語: 最大7文字

**オーバーフロー処理:**
```css
.tile-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100%;
}
```

---

## 5.4 タイルのデザイン仕様（HarmoNet Design System準拠）

### サイズとスペーシング

**タイルサイズ:**
- 最小サイズ: 100px × 100px
- 推奨サイズ: 120px × 120px（PC）、100px × 100px（モバイル）

**間隔（HarmoNet基準）:**
- タイル間のギャップ: 12px（全デバイス共通）

### カラーとスタイル（HarmoNet準拠）

**通常状態:**
- 背景色: `#FFFFFF` (HarmoNet カード背景)
- 枠線: `1px solid #E5E7EB` (HarmoNet ボーダー)
- 影: なし（HarmoNetは最小限のシャドウのみ使用）
- 角丸: `border-radius: 1rem` (var(--radius-md))

**ホバー状態（PC/タブレット）:**
```css
.function-tile:hover {
  background-color: #F9FAFB; /* HarmoNet ベース背景 */
  border-color: #2563EB; /* HarmoNet アクション青 */
  box-shadow: 0 2px 8px rgba(0,0,0,0.08); /* 控えめなシャドウ */
  transform: translateY(-2px); /* 軽い浮き上がり */
  transition: all 0.2s ease;
}
```

**アクティブ状態（モバイル）:**
```css
.function-tile:active {
  background-color: #F3F4F6; /* HarmoNet セカンダリ背景 */
  transform: scale(0.98);
}
```

**HarmoNet Design System準拠:**
- 派手な色演出を避ける
- シャドウは最小限
- 過度なアニメーションを避け、静かで落ち着いた動き

### アイコン仕様

**サイズ:**
- PC: 32px × 32px
- タブレット: 32px × 32px
- スマートフォン: 32px × 32px

**カラー:**
- 通常時: `#2563EB` (HarmoNet アクション青)
- 無効時: `#9CA3AF` (HarmoNet テキストターシャリ)

**配置:**
- タイル中央上部に配置
- ラベルとの間隔: 8px (var(--spacing-sm))

**アイコンの種類:**
- 駐車場予約: 🚗 (U+1F697)
- 回覧板: 📋 (U+1F4CB)
- 掲示板: 📌 (U+1F4CC)
- 通知設定: 🔔 (U+1F514)
- 入居者一覧: 👥 (U+1F465)
- お問い合わせ: 📧 (U+1F4E7)

### タイポグラフィ（HarmoNet準拠）

**ラベルテキスト:**
- フォントサイズ: 12px (var(--font-size-sm))
- フォントウェイト: 500 (Medium)
- 文字色: `#1F2937` (HarmoNet テキストプライマリ)
- 行間: 1.6

**フォントファミリー:**
```css
font-family: 'BIZ UDGothic', -apple-system, BlinkMacSystemFont, 
             'Segoe UI', 'SF Pro Text', 'Hiragino Sans', 
             'Noto Sans JP', sans-serif;
```

---

## 5.5 インタラクション

### タップ/クリック操作

**有効なタイル（MVP対象）:**
1. タップ/クリック
2. 視覚的フィードバック（色変化、アニメーション）
3. 対応する画面へ遷移

**無効なタイル（MVP対象外）:**
1. タップ/クリック
2. 反応なし（グレーアウト状態維持）
3. ツールチップ表示（オプション）

### アニメーション（HarmoNet準拠）

**ホバーアニメーション（PC/タブレット）:**
```css
.tile:hover {
  transform: translateY(-2px); /* 控えめな移動 */
  transition: transform 0.2s ease, 
              box-shadow 0.2s ease,
              background-color 0.2s ease,
              border-color 0.2s ease;
}
```

**タップアニメーション（モバイル）:**
```css
.tile:active {
  transform: scale(0.98); /* 軽い縮小 */
  transition: transform 0.1s ease;
}
```

**HarmoNet原則:**
- 過度なアニメーションを避ける
- 動きは最小限で静かに
- ユーザーを驚かせず、安心感を与える

---

## 5.6 アクセシビリティ

### スクリーンリーダー対応

**セマンティックHTML:**
```html
<section aria-labelledby="features-heading">
  <h2 id="features-heading" class="sr-only">機能一覧</h2>
  <nav aria-label="主要機能">
    <button 
      aria-label="駐車場予約画面へ移動" 
      class="tile">
      <span class="tile-icon" aria-hidden="true">🚗</span>
      <span class="tile-label">駐車場予約</span>
    </button>
    <!-- 他のタイル -->
  </nav>
</section>
```

**無効なタイルのARIA属性:**
```html
<button 
  aria-label="入居者一覧 準備中" 
  aria-disabled="true"
  class="tile tile--disabled">
  <span class="tile-icon" aria-hidden="true">👥</span>
  <span class="tile-label">入居者一覧</span>
</button>
```

### キーボードナビゲーション

**Tab順序:**
- 左上から右下へ、行ごとに移動
- スマートフォン: 1→2→3→4→5→6
- PC/タブレット: 1→2→3→4→5→6

**Enterキー/Spaceキー:**
- 有効なタイル: 対応画面へ遷移
- 無効なタイル: 反応なし

**フォーカスインジケーター（HarmoNet準拠）:**
```css
.tile:focus {
  outline: 3px solid #2563EB; /* HarmoNet アクション青 */
  outline-offset: 2px;
}
```

### タッチターゲット

**最小サイズ:**
- 44px × 44px（WCAG 2.1 Level AAA）
- 実際のタイルサイズは100px以上なので基準を満たす

---

## 5.7 レスポンシブ対応の詳細

### ブレークポイント

| デバイス | 幅 | タイル配置 | ギャップ |
|---------|-----|----------|---------|
| **スマートフォン** | < 768px | 2列×3行 | 12px |
| **タブレット** | 768px - 1024px | 3列×2行 | 12px |
| **PC** | > 1024px | 3列×2行 | 12px |

### CSS Grid実装例

```css
.tiles-container {
  display: grid;
  gap: 12px; /* HarmoNet基準の間隔 */
  padding: 16px; /* var(--spacing-md) */
}

/* スマートフォン */
@media (max-width: 767px) {
  .tiles-container {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* タブレット・PC */
@media (min-width: 768px) {
  .tiles-container {
    grid-template-columns: repeat(3, 1fr);
    max-width: 1024px;
    margin: 0 auto;
  }
}
```

---

## 5.8 将来の拡張性

### タイルの追加

**新しい機能を追加する場合:**
1. 翻訳データに新しいキーを追加
2. タイル定義配列に新しい項目を追加
3. アイコンを選定
4. 遷移先を定義

**注意点:**
- タイル数が7つ以上になる場合、レイアウトを再検討
- 4列×2行、または2列×4行への変更を検討

### カテゴリ分け

**多数の機能がある場合:**
- タイルをカテゴリ別にグループ化
- タブ切替による表示
- ドロップダウンメニューの追加

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| v2.0 | 2025/10/27 | 初版作成 |
| v2.1 | 2025/10/27 | HarmoNet Design System v1.0に準拠。ホバー背景色・ボーダー・シャドウをHarmoNet基準に統一。アニメーションを控えめに調整。グレーアウト表示をHarmoNetカラーパレットに変更 |

---

**[← 前の章: 第4章 お知らせセクション](home-feature-design-v2_1-ch04.md)**

**[目次に戻る ↑](home-feature-design-v2_1-index.md)**

---

**End of Document**
