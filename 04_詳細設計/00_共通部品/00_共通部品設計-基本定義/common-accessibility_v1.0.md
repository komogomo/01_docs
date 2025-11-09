# 共通アクセシビリティ要件設計書 v1.0

**Document ID:** SEC-APP-COMMON-ACCESSIBILITY-001  
**Version:** 1.0  
**Created:** 2025年10月27日  
**Purpose:** 全画面共通のアクセシビリティ要件

---

## 1. 概要

本ドキュメントは、セキュレアシティ スマートコミュニケーションアプリの**アクセシビリティ要件**を定義します。

### 1.1 対象ユーザー

- **高齢者:** 視力低下、操作に不慣れ
- **外国人住民:** 日本語に不慣れ、文化的背景の違い
- **視覚障害者:** スクリーンリーダー使用
- **聴覚障害者:** テキストベースの情報提供
- **運動障害者:** キーボードのみの操作

### 1.2 準拠基準

**WCAG 2.1 レベルAA準拠**を目指します。

| レベル | 説明 |
|--------|------|
| **A** | 最低限の基準（必須） |
| **AA** | 推奨基準（目標）|
| **AAA** | 理想基準（将来） |

---

## 2. 知覚可能性（Perceivable）

### 2.1 代替テキスト

すべての非テキストコンテンツには、代替テキストを提供します。

**画像:**

```html
<!-- ✅ 良い例 -->
<img src="icon-home.png" alt="ホームアイコン">

<!-- ❌ 悪い例 -->
<img src="icon-home.png">
```

**装飾的な画像:**

```html
<img src="decoration.png" alt="" role="presentation">
```

**アイコンボタン:**

```html
<button aria-label="通知を開く">
  <span aria-hidden="true">🔔</span>
</button>
```

### 2.2 色のコントラスト

**最小コントラスト比:**

| 要素 | WCAG AA | WCAG AAA |
|------|---------|----------|
| **通常テキスト** | 4.5:1 | 7:1 |
| **大きなテキスト** | 3:1 | 4.5:1 |
| **UIコンポーネント** | 3:1 | - |

**大きなテキストの定義:**
- 18pt（24px）以上
- 14pt（18.5px）以上の太字

**実装例:**

| 組み合わせ | コントラスト比 | 合否 |
|-----------|--------------|------|
| 黒(#333) vs 白(#fff) | 12.6:1 | ✅ AAA |
| グレー(#666) vs 白(#fff) | 5.7:1 | ✅ AA |
| 薄グレー(#999) vs 白(#fff) | 2.8:1 | ❌ NG |

### 2.3 色だけに依存しない

情報は、色だけでなく、形状・テキスト・アイコンでも伝えます。

**例: エラー表示**

```html
<!-- ❌ 悪い例（色のみ） -->
<input style="border-color: red;">

<!-- ✅ 良い例（色 + アイコン + テキスト） -->
<input style="border-color: red;" aria-invalid="true">
<span class="error-icon">⚠️</span>
<span class="error-text">メールアドレスの形式が正しくありません</span>
```

### 2.4 テキストのリサイズ

テキストを200%まで拡大しても、情報が失われないようにします。

**実装:**

- 固定ピクセル値（px）を避ける
- 相対単位（rem, em, %）を使用
- `font-size: 16px` → `font-size: 1rem`

---

## 3. 操作可能性（Operable）

### 3.1 キーボードアクセス

すべての機能を、マウスなしで操作できるようにします。

**基本操作:**

| キー | 動作 |
|------|------|
| **Tab** | 次の要素にフォーカス移動 |
| **Shift + Tab** | 前の要素にフォーカス移動 |
| **Enter / Space** | ボタン・リンクの実行 |
| **Esc** | ダイアログ・メニューを閉じる |
| **矢印キー** | リスト内の移動 |

**実装例:**

```html
<!-- ボタン -->
<button>送信</button>

<!-- カスタムボタン -->
<div role="button" tabindex="0" onkeydown="handleKeyPress(event)">
  カスタムボタン
</div>
```

### 3.2 フォーカス表示

フォーカス中の要素を明確に表示します。

**実装:**

```css
button:focus,
input:focus,
a:focus {
  outline: 2px solid #6366f1;
  outline-offset: 2px;
}

/* ❌ outline: none; は禁止 */
```

### 3.3 タップ領域

モバイルデバイスでのタップ領域を十分に確保します。

**最小サイズ:**

| 要素 | 最小サイズ |
|------|-----------|
| **ボタン** | 44px × 44px |
| **リンク** | 44px × 44px |
| **チェックボックス** | 44px × 44px |
| **ラジオボタン** | 44px × 44px |

**実装例:**

```css
.button {
  min-width: 44px;
  min-height: 44px;
  padding: 12px 16px;
}
```

### 3.4 時間制限

自動的にタイムアウトする操作には、警告を表示します。

**例: セッションタイムアウト**

```javascript
// 5分前に警告表示
const warningTime = 5 * 60 * 1000; // 5分
setTimeout(() => {
  showWarning('あと5分でセッションが切れます。操作を続けますか？');
}, sessionTimeout - warningTime);
```

### 3.5 発作の防止

激しい点滅（1秒間に3回以上）を避けます。

**禁止事項:**
- 自動再生のアニメーション
- 激しい点滅（光感受性発作の原因）

---

## 4. 理解可能性（Understandable）

### 4.1 言語の指定

ページの言語を明示します。

```html
<html lang="ja">
```

**部分的に異なる言語:**

```html
<p>
  日本語テキスト
  <span lang="en">English text</span>
  日本語テキスト
</p>
```

### 4.2 エラーメッセージ

エラーメッセージは、具体的でわかりやすくします。

**❌ 悪い例:**

```
エラーが発生しました
```

**✅ 良い例:**

```
メールアドレスの形式が正しくありません。
例: tanaka@example.com
```

### 4.3 入力補助

フォーム入力には、ラベル・プレースホルダー・ヒントを提供します。

**実装例:**

```html
<label for="email">メールアドレス（必須）</label>
<input 
  type="email" 
  id="email" 
  name="email"
  placeholder="例: tanaka@example.com"
  aria-describedby="email-hint"
  required>
<span id="email-hint" class="hint-text">
  ログインに使用するメールアドレスを入力してください
</span>
```

### 4.4 一貫性

同じ機能・要素は、全画面で同じ表現・デザインを使用します。

**例:**
- 「送信」ボタンは常に青色
- 「キャンセル」ボタンは常にグレー
- 「削除」ボタンは常に赤色

---

## 5. 堅牢性（Robust）

### 5.1 セマンティックHTML

意味に応じた適切なHTMLタグを使用します。

**良い例:**

```html
<header>ヘッダー</header>
<nav>ナビゲーション</nav>
<main>メインコンテンツ</main>
<article>記事</article>
<section>セクション</section>
<aside>サイドバー</aside>
<footer>フッター</footer>
```

**悪い例:**

```html
<div>ヘッダー</div>
<div>ナビゲーション</div>
<div>メインコンテンツ</div>
```

### 5.2 ARIA属性

スクリーンリーダー向けに、ARIA属性を適切に設定します。

**ランドマークロール:**

```html
<header role="banner">...</header>
<nav role="navigation">...</nav>
<main role="main">...</main>
<footer role="contentinfo">...</footer>
```

**ボタンのARIA:**

```html
<button aria-label="メニューを開く" aria-expanded="false">
  ☰
</button>
```

**ライブリージョン:**

```html
<!-- 通知メッセージ -->
<div role="alert" aria-live="assertive">
  エラーが発生しました
</div>

<!-- 状態メッセージ -->
<div role="status" aria-live="polite">
  保存しました
</div>
```

### 5.3 エラー修復

HTMLの文法エラーを避け、ブラウザの互換性を確保します。

**チェック項目:**
- 開始タグと終了タグが正しく対応
- 属性値が引用符で囲まれている
- IDが重複していない

---

## 6. スクリーンリーダー対応

### 6.1 読み上げ順序

読み上げ順序は、視覚的な順序と一致させます。

**実装:**

```html
<!-- ✅ 良い例（HTML順序 = 視覚順序） -->
<h1>タイトル</h1>
<p>本文</p>
<button>送信</button>

<!-- ❌ 悪い例（CSSで順序を変更） -->
<button style="order: 3;">送信</button>
<h1 style="order: 1;">タイトル</h1>
<p style="order: 2;">本文</p>
```

### 6.2 非表示要素

視覚的に非表示でも、スクリーンリーダーには読み上げさせる場合:

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

**使用例:**

```html
<button>
  <span class="sr-only">メニューを開く</span>
  <span aria-hidden="true">☰</span>
</button>
```

### 6.3 動的コンテンツの通知

動的に変化するコンテンツは、スクリーンリーダーに通知します。

```html
<div role="status" aria-live="polite" aria-atomic="true">
  <p id="loading-message">読み込み中...</p>
</div>

<script>
// 読み込み完了後
document.getElementById('loading-message').textContent = '読み込みが完了しました';
</script>
```

---

## 7. モバイルアクセシビリティ

### 7.1 ズームの許可

ユーザーがピンチズームできるようにします。

**✅ 良い例:**

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

**❌ 悪い例:**

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, 
      maximum-scale=1.0, user-scalable=no">
```

### 7.2 横向き・縦向き対応

両方の向きで正しく表示されるようにします。

### 7.3 音声入力対応

音声入力でフォームを操作できるようにします。

---

## 8. 多言語アクセシビリティ

### 8.1 翻訳の品質

機械翻訳だけでなく、ネイティブチェックを実施します。

### 8.2 文化的配慮

- 国旗アイコンを使用しない（言語≠国）
- 性別・人種を示すアイコンを使用しない

### 8.3 右から左（RTL）言語対応

将来的にアラビア語・ヘブライ語に対応する場合を考慮します。

---

## 9. テスト方法

### 9.1 自動テスト

以下のツールで自動チェック:

| ツール | 用途 |
|--------|------|
| **axe DevTools** | Chrome拡張機能 |
| **Lighthouse** | Chrome DevTools内蔵 |
| **WAVE** | ブラウザ拡張機能 |

### 9.2 手動テスト

| テスト項目 | 方法 |
|-----------|------|
| **キーボード操作** | マウスを使わずに全機能を操作 |
| **スクリーンリーダー** | NVDA、JAWS、VoiceOverで確認 |
| **ズーム** | ブラウザのズーム機能で200%拡大 |
| **色覚シミュレーター** | 色覚異常の見え方を確認 |

### 9.3 ユーザーテスト

実際の高齢者・外国人住民にテストを依頼します。

---

## 10. アクセシビリティチェックリスト

### 10.1 開発時チェック

- [ ] すべての画像にalt属性がある
- [ ] フォームのラベルが正しく関連付けられている
- [ ] ボタンにaria-labelがある
- [ ] キーボードで全機能が操作できる
- [ ] フォーカス表示が明確
- [ ] コントラスト比がWCAG AA準拠
- [ ] セマンティックHTMLを使用
- [ ] ARIA属性が適切に設定されている

### 10.2 リリース前チェック

- [ ] 自動テストツールでエラーなし
- [ ] スクリーンリーダーで問題なく操作できる
- [ ] ブラウザのズームで200%拡大しても情報が失われない
- [ ] キーボードのみで全機能が操作できる
- [ ] 高齢者・外国人住民のユーザーテスト実施

---

## 11. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-design-system-v1_0.md` | デザインシステム（色、フォント） |
| `common-i18n-v1_0.md` | 多言語対応 |
| `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.md` | デザイン哲学 |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-ACCESSIBILITY-001
- バージョン: 1.0
- 作成日: 2025年10月27日
- 承認者: （未定）
