# 共通パフォーマンス要件設計書 v1.0

**Document ID:** SEC-APP-COMMON-PERFORMANCE-001  
**Version:** 1.0  
**Created:** 2025年10月27日  
**Purpose:** 全画面共通のパフォーマンス要件

---

## 1. 概要

本ドキュメントは、セキュレアシティ スマートコミュニケーションアプリの**パフォーマンス要件**を定義します。

### 1.1 目的

- **ユーザー体験の向上:** 快適な操作感を提供
- **離脱率の低減:** 遅い読み込みによる離脱を防止
- **通信コストの削減:** データ通信量を最小化

### 1.2 対象デバイス

| デバイス | 想定スペック |
|---------|------------|
| **スマートフォン** | 3G/4G回線、1GB RAM |
| **タブレット** | Wi-Fi、2GB RAM |
| **PC** | 高速回線、4GB RAM |

---

## 2. パフォーマンス目標

### 2.1 Core Web Vitals

Googleが定義する重要な指標を達成します。

| 指標 | 良好 | 改善が必要 | 不良 |
|------|------|-----------|------|
| **LCP（Largest Contentful Paint）** | < 2.5秒 | 2.5〜4秒 | > 4秒 |
| **FID（First Input Delay）** | < 100ms | 100〜300ms | > 300ms |
| **CLS（Cumulative Layout Shift）** | < 0.1 | 0.1〜0.25 | > 0.25 |

**目標:** すべての指標で「良好」を達成

### 2.2 ページロード時間

| 画面 | 目標時間 | 許容時間 |
|------|---------|---------|
| **ログイン画面** | 1秒 | 2秒 |
| **HOME画面** | 2秒 | 3秒 |
| **お知らせ一覧** | 2秒 | 3秒 |
| **掲示板一覧** | 2秒 | 3秒 |
| **駐車場予約** | 2秒 | 3秒 |

**測定条件:**
- 4G回線（10Mbps）
- スマートフォン（中程度スペック）
- キャッシュなし

### 2.3 API応答時間

| API | 目標時間 | 許容時間 |
|-----|---------|---------|
| **ユーザー情報取得** | 500ms | 1秒 |
| **お知らせ一覧取得** | 500ms | 1秒 |
| **掲示板一覧取得** | 1秒 | 2秒 |
| **駐車場予約** | 1秒 | 2秒 |
| **画像アップロード** | 3秒 | 5秒 |

---

## 3. 最適化戦略

### 3.1 フロントエンド最適化

#### 3.1.1 HTML最適化

| 項目 | 対策 |
|------|------|
| **ファイルサイズ** | 1ファイル300行以内 |
| **不要なタグ削除** | コメント、空白を最小化 |
| **セマンティックHTML** | 適切なタグで文書構造を明確化 |

#### 3.1.2 CSS最適化

| 項目 | 対策 |
|------|------|
| **ファイル分割** | 共通CSS + 画面固有CSS |
| **未使用CSSの削除** | PurgeCSSで不要なスタイルを削除 |
| **CSSの圧縮** | 本番環境ではminify |
| **読み込み順序** | 重要なCSSを先に読み込む |

**推奨読み込み順序:**

```html
<link rel="stylesheet" href="/css/variables.css">
<link rel="stylesheet" href="/css/base.css">
<link rel="stylesheet" href="/css/common/button.css">
<link rel="stylesheet" href="/css/common/header.css">
<link rel="stylesheet" href="/css/common/footer.css">
<link rel="stylesheet" href="/pages/home/home.css">
```

#### 3.1.3 JavaScript最適化

| 項目 | 対策 |
|------|------|
| **遅延読み込み** | 非同期読み込み（async, defer） |
| **コード分割** | 画面ごとに必要なJSのみ読み込む |
| **関数の最適化** | 1関数30行以内 |
| **グローバル変数の管理** | `window.大文字始まり` で統一 |

**推奨読み込み順序:**

```html
<!-- 1. 共通翻訳データ -->
<script src="/js/i18n/langs/common.ja.js"></script>
<script src="/js/i18n/langs/common.en.js"></script>
<script src="/js/i18n/langs/common.zh.js"></script>

<!-- 2. 画面固有翻訳データ -->
<script src="/pages/home/home.ja.js"></script>
<script src="/pages/home/home.en.js"></script>
<script src="/pages/home/home.zh.js"></script>

<!-- 3. 共通機能（defer） -->
<script defer src="/js/features/translator.js"></script>
<script defer src="/js/features/language-switcher.js"></script>
<script defer src="/js/features/footer-navigation.js"></script>

<!-- 4. 画面固有ロジック（defer） -->
<script defer src="/pages/home/home.js"></script>
```

#### 3.1.4 画像最適化

| 項目 | 対策 |
|------|------|
| **ファイル形式** | WebP（フォールバック: JPEG/PNG） |
| **圧縮** | 品質80%程度で圧縮 |
| **サイズ** | レスポンシブ画像（srcset使用） |
| **遅延読み込み** | 画面外の画像はlazyload |

**実装例:**

```html
<img 
  src="image.webp" 
  srcset="image-small.webp 400w, image-medium.webp 800w, image-large.webp 1200w"
  sizes="(max-width: 768px) 400px, 800px"
  loading="lazy"
  alt="画像の説明">
```

---

### 3.2 バックエンド最適化

#### 3.2.1 データベース最適化

| 項目 | 対策 |
|------|------|
| **インデックス** | 検索頻度の高いカラムにインデックス作成 |
| **クエリ最適化** | N+1問題の回避、JOIN最適化 |
| **ページネーション** | 大量データは分割取得（1ページ20件） |

#### 3.2.2 API最適化

| 項目 | 対策 |
|------|------|
| **必要なデータのみ返す** | 不要なフィールドを除外 |
| **レスポンスの圧縮** | gzip圧縮 |
| **並列処理** | 複数APIを並列呼び出し |

**例: 並列API呼び出し**

```javascript
// ❌ 悪い例（直列）
const user = await fetch('/api/users/profile');
const notices = await fetch('/api/notifications?limit=3');
// 合計: 500ms + 500ms = 1秒

// ✅ 良い例（並列）
const [user, notices] = await Promise.all([
  fetch('/api/users/profile'),
  fetch('/api/notifications?limit=3')
]);
// 合計: max(500ms, 500ms) = 500ms
```

---

### 3.3 キャッシング戦略

#### 3.3.1 ブラウザキャッシュ

| リソース | キャッシュ期間 |
|---------|--------------|
| **CSS/JS** | 1年間 |
| **画像** | 1年間 |
| **HTML** | キャッシュしない |
| **API** | 状況による |

**実装例（HTTP ヘッダー）:**

```
Cache-Control: public, max-age=31536000  # 1年間
Cache-Control: no-cache                  # キャッシュしない
```

#### 3.3.2 localStorageキャッシュ

| データ | 有効期限 |
|--------|---------|
| **ユーザー情報** | 24時間 |
| **翻訳データ** | 7日間 |
| **お知らせ一覧** | なし（sessionStorage使用） |

**実装例:**

```javascript
// キャッシュに保存
const cacheData = {
  data: userData,
  timestamp: Date.now()
};
localStorage.setItem('userProfile', JSON.stringify(cacheData));

// キャッシュから取得
const cached = JSON.parse(localStorage.getItem('userProfile'));
const isExpired = (Date.now() - cached.timestamp) > (24 * 60 * 60 * 1000);
if (!isExpired) {
  return cached.data;
}
```

#### 3.3.3 CDN活用

外部ライブラリはCDNから読み込みます。

```html
<!-- ✅ CDNから読み込み -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>

<!-- ❌ 自サーバーから読み込み -->
<script src="/js/vendor/jquery.min.js"></script>
```

---

## 4. ネットワーク最適化

### 4.1 リクエスト数の削減

| 項目 | 対策 |
|------|------|
| **CSSファイル** | 複数ファイルを1つに統合（production） |
| **JSファイル** | 複数ファイルを1つに統合（production） |
| **画像スプライト** | 小さなアイコンは1枚の画像に統合 |

### 4.2 データ転送量の削減

| 項目 | 対策 |
|------|------|
| **gzip圧縮** | サーバー側でgzip圧縮を有効化 |
| **画像圧縮** | 画像を80%程度で圧縮 |
| **不要なデータ削除** | APIレスポンスから不要なフィールドを除外 |

### 4.3 HTTP/2の活用

HTTP/2を有効化し、並列リクエストを効率化します。

---

## 5. モバイル最適化

### 5.1 タップ遅延の解消

**300msのタップ遅延を解消:**

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

### 5.2 スクロールパフォーマンス

| 項目 | 対策 |
|------|------|
| **固定ヘッダー/フッター** | `position: fixed` の最適化 |
| **画像の遅延読み込み** | `loading="lazy"` 属性を使用 |
| **無限スクロール** | 仮想スクロール（Virtual Scroll）を検討 |

### 5.3 バッテリー消費の削減

| 項目 | 対策 |
|------|------|
| **タイマーの最小化** | `setInterval` の使用を最小限に |
| **アニメーションの最適化** | CSS Animationを使用（JS避ける） |
| **位置情報の取得** | 必要な場合のみ取得 |

---

## 6. 監視とモニタリング

### 6.1 リアルタイム監視

| 項目 | ツール |
|------|--------|
| **ページロード時間** | Google Analytics |
| **Core Web Vitals** | Google Search Console |
| **エラー監視** | Sentry |
| **APIパフォーマンス** | サーバーログ分析 |

### 6.2 定期的なパフォーマンステスト

| 頻度 | 内容 |
|------|------|
| **毎週** | Lighthouseスコアの確認 |
| **毎月** | 実機でのパフォーマンステスト |
| **リリース前** | 全画面のパフォーマンス測定 |

---

## 7. パフォーマンス目標の達成状況

### 7.1 目標値

| 画面 | 目標LCP | 目標FID | 目標CLS |
|------|---------|---------|---------|
| **HOME画面** | < 2.5秒 | < 100ms | < 0.1 |
| **お知らせ一覧** | < 2.5秒 | < 100ms | < 0.1 |
| **掲示板一覧** | < 2.5秒 | < 100ms | < 0.1 |
| **駐車場予約** | < 2.5秒 | < 100ms | < 0.1 |

### 7.2 改善が必要な場合のアクション

目標値を下回る場合、以下の優先順位で対策:

1. **画像最適化** - 最も効果が高い
2. **JavaScriptの削減** - 実行時間を短縮
3. **CSSの最適化** - レンダリングブロックを削減
4. **APIの最適化** - データ取得時間を短縮

---

## 8. パフォーマンスチェックリスト

### 8.1 開発時チェック

- [ ] 画像は圧縮済み（WebP使用）
- [ ] CSSファイルは分割（共通 + 画面固有）
- [ ] JavaScriptは遅延読み込み（defer）
- [ ] 1ファイル300行以内
- [ ] 1関数30行以内
- [ ] グローバル変数は`window.大文字始まり`

### 8.2 リリース前チェック

- [ ] Lighthouseスコア > 90
- [ ] LCP < 2.5秒
- [ ] FID < 100ms
- [ ] CLS < 0.1
- [ ] 実機（3G回線）でのテスト完了

---

## 9. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `05_Project-Structure-v3_3_EN.md` | ファイル構成・読み込み順序 |
| `code-generation-rules-v2_1_EN.md` | コード生成規則（3クリックルール） |
| `common-design-system-v1_0.md` | デザインシステム |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-PERFORMANCE-001
- バージョン: 1.0
- 作成日: 2025年10月27日
- 承認者: （未定）
