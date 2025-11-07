# 第3章: ウェルカムセクション

**Document:** HOME画面 機能設計書 v2.1  
**Chapter:** 3 of 5  
**Last Updated:** 2025/10/27  
**Design System:** HarmoNet Design System v1.0

---

## 3.1 表示内容

ウェルカムセクションは、ログイン中のユーザーを認識し、パーソナライズされた情報を表示します。

### 表示項目一覧

| 表示項目 | データソース | 表示形式 | 必須 |
|----------|--------------|----------|------|
| **挨拶メッセージ** | 固定テキスト + ユーザー名 | 「こんにちは、[ユーザー名]さん」 | ✅ |
| **自治体名** | ユーザーマスタ | 「セキュレアシティ第3期」 | ✅ |
| **号室** | ユーザーマスタ | 「A-105号室」 | ✅ |

### 表示例

**日本語表示:**
```
こんにちは、田中さん
セキュレアシティ第3期 A-105号室
```

**英語表示:**
```
Hello, Tanaka
Securea City Phase 3 A-105
```

**中国語表示:**
```
您好,田中
塞库莱城第三期 A-105室
```

---

## 3.2 多言語対応

### 翻訳データ構造

ウェルカムセクションの翻訳は、以下の構造で管理されます:

**翻訳キー:**
```javascript
{
  "welcome": {
    "greeting": {
      "ja": "こんにちは、{name}さん",
      "en": "Hello, {name}",
      "cn": "您好,{name}"
    },
    "phase": {
      "ja": "第{number}期",
      "en": "Phase {number}",
      "cn": "第{number}期"
    },
    "room": {
      "ja": "{room}号室",
      "en": "{room}",
      "cn": "{room}室"
    }
  }
}
```

### 言語別表示ルール

| 言語 | 挨拶メッセージ | 自治体名 | 号室表示 |
|------|---------------|----------|----------|
| **日本語(JA)** | こんにちは、[ユーザー名]さん | セキュレアシティ第3期 | A-105号室 |
| **英語(EN)** | Hello, [Username] | Securea City Phase 3 | A-105 |
| **中国語(CN)** | 您好,[用户名] | 塞库莱城第三期 | A-105室 |

### 動的な文字列生成

**実装例（JavaScript）:**
```javascript
const greetingMessage = i18n.t('welcome.greeting', { name: user.name });
const phaseText = i18n.t('welcome.phase', { number: user.phase });
const roomText = i18n.t('welcome.room', { room: user.room });

const fullText = `${user.communityName}${phaseText} ${roomText}`;
```

---

## 3.3 デザイン仕様（HarmoNet Design System準拠）

### 背景とカラー

**背景色:**
- カラー: `#2563EB` (HarmoNet アクション青)
- デザインコンセプト: 信頼感と落ち着きを表現する単色背景

**テキストカラー:**
- 全てのテキスト: `#ffffff` (白色)
- コントラスト比: 4.5:1以上（WCAG AA準拠）

**HarmoNet Design System準拠:**
```css
.welcome-card {
  background: #2563EB; /* HarmoNet アクション青 */
  color: #ffffff;
}
```

### タイポグラフィ

| 要素 | フォントサイズ | フォントウェイト | 行間 |
|------|---------------|-----------------|------|
| **挨拶メッセージ** | 20px | 600 (Semibold) | 1.6 |
| **自治体名・号室** | 13px | 400 (Regular) | 1.75 |

**フォントファミリー（HarmoNet基準）:**
```css
font-family: 'BIZ UDGothic', -apple-system, BlinkMacSystemFont, 
             'Segoe UI', 'SF Pro Text', 'Hiragino Sans', 
             'Noto Sans JP', sans-serif;
```

### スペーシング（HarmoNet基準）

**パディング:**
- 上下: 20px (var(--spacing-lg) = 20px)
- 左右: 20px (var(--spacing-lg) = 20px)

**内部マージン:**
- 挨拶メッセージと自治体名の間: 4px (var(--spacing-xs) = 4px)

**角丸:**
- border-radius: 1rem (var(--radius-md) = 1rem)

### レスポンシブ調整

| デバイス | フォントサイズ調整 | パディング調整 |
|---------|-------------------|---------------|
| **PC** | 基準サイズ | 上下20px 左右20px |
| **タブレット** | 基準サイズ | 上下20px 左右20px |
| **スマートフォン** | 基準サイズ | 上下20px 左右20px |

**HarmoNet原則:**
- 過度なグラデーションを避け、単色で統一
- 余白は16px/24px/32pxの3階層基準に準拠
- 彩度は低めに抑え、静かで落ち着いた印象を維持

---

## 3.4 実装上の注意事項

### ユーザー名の長さ対応

**最大表示文字数:**
- 日本語: 10文字
- 英語: 20文字
- 中国語: 10文字

**オーバーフロー時の処理:**
```css
.welcome-username {
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

### データ取得エラー時の表示

**エラーケース:**
- ユーザー情報取得失敗
- 不完全なデータ

**フォールバック表示:**
```
こんにちは
セキュレアシティ
```
- ユーザー名が取得できない場合は「ユーザー名さん」を省略
- 号室情報がない場合は号室表示を省略

### アクセシビリティ

**スクリーンリーダー対応:**
```html
<div role="banner" aria-label="ウェルカムメッセージ">
  <p id="greeting">こんにちは、田中さん</p>
  <p id="location">セキュレアシティ第3期 A-105号室</p>
</div>
```

**読み上げ順序:**
1. 挨拶メッセージ
2. 自治体名と号室

---

## 3.5 デザインコンセプト（HarmoNet Design System）

### 視覚的な意図

**単色青背景の意味:**
- **青(#2563EB)**: 信頼感・安心感・落ち着き
- **単色**: 静けさの中にある信頼を形にする
- **白文字**: 清潔感と視認性

**HarmoNet哲学との整合性:**
- 派手さよりも整然とした心地よさを優先
- 情報を叫ばせるのではなく、穏やかに滞在させる
- 時間が経っても古びない、やさしい情報空間

**配置の意図:**
- コンテンツ領域の最上部に配置
- ユーザーが最初に目にする要素
- 「自分の画面」という所有感を与える

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| v2.0 | 2025/10/27 | 初版作成 |
| v2.1 | 2025/10/27 | HarmoNet Design System v1.0に準拠。グラデーション背景を単色青(#2563EB)に変更。余白・角丸をHarmoNet基準に統一 |

---

**[← 前の章: 第2章 コンテンツ領域構成](home-feature-design-v2_1-ch02.md)**

**[次の章へ: 第4章 お知らせセクション →](home-feature-design-v2_1-ch04.md)**

**[目次に戻る ↑](home-feature-design-v2_1-index.md)**
