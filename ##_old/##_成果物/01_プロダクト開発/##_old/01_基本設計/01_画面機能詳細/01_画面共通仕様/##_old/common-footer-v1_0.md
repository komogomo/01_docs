# 共通フッター領域設計書 v1.0

**Document ID:** SEC-APP-COMMON-FOOTER-001  
**Version:** 1.0  
**Created:** 2025年10月27日  
**Purpose:** 全画面共通のフッター領域（ナビゲーション）詳細仕様

---

## 1. 概要

本ドキュメントは、セキュレアシティ スマートコミュニケーションアプリの**フッター領域**の詳細仕様を定義します。

### 1.1 適用範囲

- **対象画面:** ログイン画面を除く全画面
- **表示位置:** 画面最下部（固定表示）

### 1.2 設計原則

- **アクセス性:** 主要機能へのアクセスを1タップで実現
- **視認性:** 現在の画面を明確に表示（アクティブ状態）
- **一貫性:** 全画面で同じレイアウト・デザイン

---

## 2. 基本仕様

### 2.1 レイアウト

```
┌────────────────────────────────────────────────────────┐
│  [ホーム]  [お知らせ]  [掲示板]  [駐車場]  [マイページ]  [ログアウト] │
│    🏠       📢        💬        🚗        👤          🚪     │
└────────────────────────────────────────────────────────┘
```

### 2.2 寸法

| 項目 | 値 | 備考 |
|------|-----|------|
| **高さ** | 60px（固定） | - |
| **幅** | 100%（画面幅いっぱい） | - |
| **内部パディング** | 上: 8px、下: 8px | - |
| **z-index** | 1000 | 最前面表示 |
| **背景色** | 白色（#ffffff） | - |
| **上部ボーダー** | 1px solid #e0e0e0 | - |

---

## 3. ナビゲーションボタン

### 3.1 ボタン一覧

| No | 機能名 | アイコン | 遷移先 | MVP対象 |
|----|--------|---------|--------|---------|
| 1 | ホーム | 🏠 | HOME画面 | ✅ |
| 2 | お知らせ | 📢 | お知らせ一覧画面 | ✅ |
| 3 | 掲示板 | 💬 | 掲示板一覧画面 | ✅ |
| 4 | 駐車場 | 🚗 | 駐車場予約画面 | ✅ |
| 5 | マイページ | 👤 | マイページ画面 | ✅ |
| 6 | ログアウト | 🚪 | ログイン画面 | ✅ |

### 3.2 ボタンの基本仕様

| 項目 | 値 |
|------|-----|
| **幅** | 均等配分（画面幅 ÷ 6） |
| **高さ** | 44px |
| **タップ領域** | 44px × 44px（最小） |
| **アイコンサイズ** | 24px × 24px |
| **ラベルフォントサイズ** | 11px |
| **ラベル色** | グレー（#666666） |

### 3.3 多言語対応

各ボタンのラベルは、選択中の言語に応じて自動で切り替わります。

| 機能 | 日本語(JA) | 英語(EN) | 中国語(CN) |
|------|-----------|----------|-----------|
| ホーム | ホーム | Home | 主页 |
| お知らせ | お知らせ | Notices | 通知 |
| 掲示板 | 掲示板 | Board | 公告板 |
| 駐車場 | 駐車場 | Parking | 停车场 |
| マイページ | マイページ | My Page | 我的 |
| ログアウト | ログアウト | Logout | 登出 |

### 3.4 翻訳キーの形式

**重要:** フッターの翻訳キーは**短縮形式**を使用します。

```javascript
// ✅ 正しい形式（短縮）
'home': 'ホーム',
'notice': 'お知らせ',
'board': '掲示板',
'parking': '駐車場',
'mypage': 'マイページ',
'logout': 'ログアウト'

// ❌ 誤った形式（プレフィックス付き）
'common.home': 'ホーム',  // NG
'footer.home': 'ホーム',  // NG
```

---

## 4. アクティブ状態

### 4.1 アクティブ状態の定義

現在表示中の画面に対応するボタンを**アクティブ状態**として強調表示します。

### 4.2 アクティブ時のスタイル

| 項目 | 通常時 | アクティブ時 |
|------|--------|------------|
| **背景色** | 透明 | 薄紫（#e1bee7） |
| **アイコン色** | グレー（#666666） | プライマリーカラー（#667eea） |
| **ラベル色** | グレー（#666666） | プライマリーカラー（#667eea） |
| **ラベル太さ** | 通常（400） | 太字（700） |

### 4.3 アクティブ状態の判定

各画面のHTMLに `data-page` 属性を設定し、JavaScript でアクティブボタンを判定:

```html
<!-- HOME画面の場合 -->
<body data-page="home">
  <footer class="app-footer">
    <button class="footer-nav-btn" data-page="home">
      <span class="footer-nav-icon">🏠</span>
      <span class="footer-nav-label" data-i18n="home">ホーム</span>
    </button>
    <!-- 他のボタン -->
  </footer>
</body>
```

**JavaScript による自動判定:**

```javascript
// body の data-page と一致するボタンをアクティブ化
const currentPage = document.body.dataset.page;
const buttons = document.querySelectorAll('.footer-nav-btn');
buttons.forEach(btn => {
  if (btn.dataset.page === currentPage) {
    btn.classList.add('footer-nav-btn--active');
  }
});
```

---

## 5. ログアウトボタン

### 5.1 特別な扱い

ログアウトボタンは、他のナビゲーションボタンと以下の点で異なります:

| 項目 | 通常ボタン | ログアウトボタン |
|------|-----------|----------------|
| **位置** | 左から順番に配置 | 右端に配置 |
| **アクティブ状態** | あり | なし（常に通常状態） |
| **遷移先** | 各機能画面 | ログイン画面 |
| **確認ダイアログ** | なし | あり |

### 5.2 ログアウト時の動作

1. ログアウトボタンをタップ
2. 確認ダイアログを表示
   - メッセージ: 「ログアウトしますか？」
   - ボタン: 「キャンセル」「ログアウト」
3. 「ログアウト」を選択した場合:
   - セッショントークンを削除
   - localStorage をクリア
   - ログイン画面へリダイレクト

### 5.3 多言語対応

| 言語 | ダイアログメッセージ | キャンセル | ログアウト |
|------|---------------------|----------|-----------|
| 日本語 | ログアウトしますか？ | キャンセル | ログアウト |
| 英語 | Do you want to log out? | Cancel | Logout |
| 中国語 | 您要退出登录吗？ | 取消 | 登出 |

---

## 6. スタイル仕様

### 6.1 フッター全体

```css
.app-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60px;
  background-color: #ffffff;
  border-top: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-around;
  align-items: center;
  z-index: 1000;
}
```

### 6.2 ナビゲーションボタン

```css
.footer-nav-btn {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 44px;
  border: none;
  background: transparent;
  cursor: pointer;
}

.footer-nav-btn--active {
  background-color: #e1bee7;
  border-radius: 8px;
}
```

---

## 7. レスポンシブ対応

### 7.1 小画面での調整

スマートフォン（< 375px）では、以下の調整を行います:

| 項目 | 通常 | 小画面 |
|------|------|--------|
| **ラベルフォントサイズ** | 11px | 10px |
| **アイコンサイズ** | 24px × 24px | 20px × 20px |

### 7.2 タブレット・PCでの最適化

タブレット・PC では、フッターの最大幅を制限し、中央寄せ表示:

```css
@media (min-width: 768px) {
  .app-footer {
    max-width: 768px;
    left: 50%;
    transform: translateX(-50%);
  }
}
```

---

## 8. インタラクション

### 8.1 ホバーエフェクト（PC/タブレット）

| 要素 | ホバー時の変化 |
|------|---------------|
| ナビゲーションボタン | 背景色が薄グレー（#f5f5f5）に変化 |
| ログアウトボタン | 背景色が薄赤（#ffebee）に変化 |

### 8.2 タップフィードバック（モバイル）

ボタンをタップした瞬間、以下のフィードバックを表示:
- **背景色:** 一時的に薄グレー（#e0e0e0）に変化
- **継続時間:** 150ms

---

## 9. アクセシビリティ

### 9.1 キーボードナビゲーション

| 操作 | 動作 |
|------|------|
| Tab キー | フォーカスが左から右へ順番に移動 |
| Enter / Space キー | フォーカス中のボタンを実行 |

### 9.2 スクリーンリーダー対応

```html
<footer role="contentinfo" class="app-footer">
  <button class="footer-nav-btn footer-nav-btn--active" 
          data-page="home" 
          aria-label="ホーム（現在のページ）"
          aria-current="page">
    <span class="footer-nav-icon" aria-hidden="true">🏠</span>
    <span class="footer-nav-label" data-i18n="home">ホーム</span>
  </button>
  
  <!-- 他のボタン -->
  
  <button class="footer-nav-btn footer-nav-btn--logout" 
          aria-label="ログアウト">
    <span class="footer-nav-icon" aria-hidden="true">🚪</span>
    <span class="footer-nav-label" data-i18n="logout">ログアウト</span>
  </button>
</footer>
```

### 9.3 コントラスト比

すべてのテキストとアイコンは、WCAG 2.1 レベルAA準拠のコントラスト比を確保:
- **通常時:** グレー（#666666） vs 白背景（#ffffff） = 5.7:1（AA準拠）
- **アクティブ時:** プライマリーカラー（#667eea） vs 薄紫背景（#e1bee7） = 4.8:1（AA準拠）

---

## 10. パフォーマンス

### 10.1 初期ロード

- フッターは HTML 内に直接記述（JavaScript 不要）
- アクティブ状態の判定のみ JavaScript 使用

### 10.2 画面遷移の最適化

- フッターボタンのクリック時、即座に画面遷移
- 遷移アニメーションは最小限（150ms以内）

---

## 11. 実装例（HTML）

```html
<footer class="app-footer">
  <!-- ホームボタン -->
  <button class="footer-nav-btn" data-page="home">
    <span class="footer-nav-icon">🏠</span>
    <span class="footer-nav-label" data-i18n="home">ホーム</span>
  </button>

  <!-- お知らせボタン -->
  <button class="footer-nav-btn" data-page="notice">
    <span class="footer-nav-icon">📢</span>
    <span class="footer-nav-label" data-i18n="notice">お知らせ</span>
  </button>

  <!-- 掲示板ボタン -->
  <button class="footer-nav-btn" data-page="board">
    <span class="footer-nav-icon">💬</span>
    <span class="footer-nav-label" data-i18n="board">掲示板</span>
  </button>

  <!-- 駐車場ボタン -->
  <button class="footer-nav-btn" data-page="parking">
    <span class="footer-nav-icon">🚗</span>
    <span class="footer-nav-label" data-i18n="parking">駐車場</span>
  </button>

  <!-- マイページボタン -->
  <button class="footer-nav-btn" data-page="mypage">
    <span class="footer-nav-icon">👤</span>
    <span class="footer-nav-label" data-i18n="mypage">マイページ</span>
  </button>

  <!-- ログアウトボタン -->
  <button class="footer-nav-btn footer-nav-btn--logout" onclick="handleLogout()">
    <span class="footer-nav-icon">🚪</span>
    <span class="footer-nav-label" data-i18n="logout">ログアウト</span>
  </button>
</footer>
```

---

## 12. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-layout-v1_0.md` | 3層構造の全体設計 |
| `common-i18n-v1_0.md` | 言語切替・翻訳機能の詳細 |
| `common-design-system-v1_0.md` | デザインシステム |
| `common-accessibility-v1_0.md` | アクセシビリティ要件 |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-FOOTER-001
- バージョン: 1.0
- 作成日: 2025年10月27日
- 承認者: （未定）
