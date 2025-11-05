# 第5章: 機能タイルセクション

**Document:** HOME画面 機能設計書 v2.0  
**Chapter:** 5 of 5  
**Last Updated:** 2025/10/27

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
- 背景色: `#e0e0e0` (薄いグレー)
- アイコン: 透明度50%
- タップ不可（pointer-events: none）
- ツールチップ: 「この機能は準備中です」

**実装例（CSS）:**
```css
.tile--disabled {
  background-color: #e0e0e0;
  opacity: 0.5;
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

## 5.4 タイルのデザイン仕様

### サイズとスペーシング

**タイルサイズ:**
- 最小サイズ: 100px × 100px
- 推奨サイズ: 120px × 120px（PC）、100px × 100px（モバイル）

**間隔:**
- タイル間のギャップ: 16px（PC）、12px（タブレット）、8px（スマートフォン）

### カラーとスタイル

**通常状態:**
- 背景色: `#ffffff` (白)
- 枠線: なし
- 影: `box-shadow: 0 2px 8px rgba(0,0,0,0.1)`
- 角丸: `border-radius: 10px`

**ホバー状態（PC/タブレット）:**
- 背景色: `#e1bee7` (薄紫)
- 影: `box-shadow: 0 4px 12px rgba(0,0,0,0.15)`
- 変形: `transform: translateY(-2px)`
- 遷移: `transition: all 0.3s ease`

**アクティブ状態（モバイル）:**
- 背景色: `#d1aee0`
- 変形: `transform: scale(0.95)`

### アイコン仕様

**サイズ:**
- PC: 40px × 40px
- タブレット: 36px × 36px
- スマートフォン: 32px × 32px

**配置:**
- タイル中央上部に配置
- ラベルとの間隔: 8px

**アイコンの種類:**
- 駐車場予約: 🚗 (U+1F697)
- 回覧板: 📋 (U+1F4CB)
- 掲示板: 📌 (U+1F4CC)
- 通知設定: 🔔 (U+1F514)
- 入居者一覧: 👥 (U+1F465)
- お問い合わせ: 📧 (U+1F4E7)

### タイポグラフィ

**ラベルテキスト:**
- フォントサイズ: 1em (16px) PC、0.9em (14.4px) モバイル
- フォントウェイト: 400 (Regular)
- 文字色: `#333333`
- 行間: 1.3

**フォントファミリー:**
```css
font-family: 'Yu Gothic', 'Hiragino Sans', 'Noto Sans JP', sans-serif;
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

### アニメーション

**ホバーアニメーション（PC/タブレット）:**
```css
.tile:hover {
  transform: translateY(-2px);
  transition: transform 0.3s ease, 
              box-shadow 0.3s ease,
              background-color 0.3s ease;
}
```

**タップアニメーション（モバイル）:**
```css
.tile:active {
  transform: scale(0.95);
  transition: transform 0.1s ease;
}
```

### フィードバックの重要性

**ユーザー体験向上のために:**
- 即座の視覚的フィードバック
- スムーズなアニメーション
- 明確な状態の変化

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

**フォーカスインジケーター:**
```css
.tile:focus {
  outline: 3px solid #667eea;
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
| **スマートフォン** | < 768px | 2列×3行 | 8px |
| **タブレット** | 768px - 1024px | 3列×2行 | 12px |
| **PC** | > 1024px | 3列×2行 | 16px |

### CSS Grid実装例

```css
.tiles-container {
  display: grid;
  gap: 16px;
  padding: 20px;
}

/* スマートフォン */
@media (max-width: 767px) {
  .tiles-container {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
    padding: 15px;
  }
}

/* タブレット */
@media (min-width: 768px) and (max-width: 1024px) {
  .tiles-container {
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
}

/* PC */
@media (min-width: 1025px) {
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

**[← 前の章: 第4章 お知らせセクション](home-feature-design-v2_0-ch04.md)**

**[目次に戻る ↑](home-feature-design-v2_0-index.md)**

---

**End of Document**
