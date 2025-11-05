# 共通言語切替・翻訳機能設計書 v1.0

**Document ID:** SEC-APP-COMMON-I18N-001  
**Version:** 1.0  
**Created:** 2025年10月27日  
**Purpose:** 全画面共通の多言語対応機能詳細仕様

---

## 1. 概要

本ドキュメントは、セキュレアシティ スマートコミュニケーションアプリの**多言語対応機能（国際化: i18n）**の詳細仕様を定義します。

### 1.1 対応言語

| 言語 | コード | 表示名 | 優先度 |
|------|--------|--------|--------|
| 日本語 | ja | 日本語 | 1（デフォルト） |
| 英語 | en | English | 2 |
| 中国語（簡体字） | zh | 中文 | 3 |

### 1.2 設計原則

- **リアルタイム切替:** ページリロード不要で即座に言語切替
- **永続化:** 選択した言語を保存し、次回訪問時も適用
- **完全性:** すべてのUI要素・メッセージが3言語対応

---

## 2. 言語切替ボタン

### 2.1 配置

**位置:** ヘッダー右端（通知ボタンの右隣）

### 2.2 表示形式

| 言語 | ボタン表示 |
|------|-----------|
| 日本語選択中 | JA ▼ |
| 英語選択中 | EN ▼ |
| 中国語選択中 | CN ▼ |

### 2.3 ドロップダウンメニュー

ボタンをタップすると、下方向にメニューが表示されます。

**メニュー項目:**

```
┌─────────────────┐
│ 日本語 (JA)     │
├─────────────────┤
│ English (EN)    │
├─────────────────┤
│ 中文 (CN)       │
└─────────────────┘
```

**選択済み言語の表示:**
- 背景色: 薄紫（#e1bee7）
- チェックマーク: ✓ を表示

### 2.4 詳細設計

> **📄 詳細は別紙参照**
> 
> 言語切替ボタンのUI詳細については、以下のドキュメントを参照してください:
> - 『**common-header-v1_0.md**』3.3節

---

## 3. 翻訳データ構造

### 3.1 ファイル構成

翻訳データは、**共通部分**と**画面固有部分**に分離します。

```
js/i18n/langs/
├── common.ja.js    # 共通部分（ヘッダー、フッター、ボタン）
├── common.en.js
├── common.zh.js
pages/[screen]/
├── [screen].ja.js  # 画面固有部分（コンテンツ領域）
├── [screen].en.js
└── [screen].zh.js
```

### 3.2 共通翻訳データ（common.ja.js）

**対象:** ヘッダー、フッター、共通ボタン、共通メッセージ

```javascript
window.I18nData = window.I18nData || {};
window.I18nData.common = window.I18nData.common || {};

window.I18nData.common.ja = {
  // ヘッダー
  'notification': '通知',
  'language': '言語',

  // フッターナビゲーション（短縮形式）
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'parking': '駐車場',
  'mypage': 'マイページ',
  'logout': 'ログアウト',

  // 共通ボタン
  'submit': '送信',
  'cancel': 'キャンセル',
  'ok': 'OK',
  'close': '閉じる',
  'back': '戻る',
  'next': '次へ',
  'save': '保存',
  'delete': '削除',
  'edit': '編集',
  'search': '検索',

  // 共通メッセージ
  'loading': '読み込み中...',
  'error': 'エラーが発生しました',
  'success': '完了しました',
  'confirm': '確認',
  'warning': '警告'
};
```

### 3.3 画面固有翻訳データ（home.ja.js）

**対象:** 各画面のコンテンツ領域のみ

```javascript
window.I18nData = window.I18nData || {};
window.I18nData.home = window.I18nData.home || {};

window.I18nData.home.ja = {
  // ウェルカムセクション
  'welcome.greeting': 'こんにちは、{name}さん',
  'welcome.community': 'セキュレアシティ第3期',
  'welcome.room': '{room}号室',

  // お知らせセクション
  'notices.title': '最新のお知らせ',
  'notices.empty': '現在お知らせはありません',
  'notices.viewAll': '一覧を見る',
  'notices.unread': '未読',

  // 機能タイル
  'tiles.parking': '駐車場予約',
  'tiles.circulation': '回覧板',
  'tiles.board': '掲示板',
  'tiles.notification': '通知設定',
  'tiles.residents': '入居者一覧',
  'tiles.contact': 'お問い合わせ'
};
```

### 3.4 翻訳キーの命名規則

| ルール | 説明 | 例 |
|--------|------|-----|
| **セクション.要素** | セクション名 + 要素名 | `welcome.greeting` |
| **複数形の使用** | リスト項目は複数形 | `notices.title`（お知らせタイトル） |
| **動詞の使用** | アクションは動詞で開始 | `viewAll`（一覧を見る） |
| **短縮禁止** | 略語は使用しない | `notification`（✓）、`notif`（✗） |

---

## 4. 翻訳システムの実装

### 4.1 翻訳エンジン（translator.js）

翻訳エンジンは、`data-i18n` 属性を持つ要素を検索し、翻訳を適用します。

**基本動作:**

```javascript
// HTML
<span data-i18n="home.welcome.greeting">こんにちは、{name}さん</span>

// JavaScript
window.Translator.translate('home', 'ja');
// → 「こんにちは、田中さん」に変換
```

### 4.2 プレースホルダーの置換

翻訳文字列内の `{変数名}` を実際の値に置換します。

**例:**

```javascript
// 翻訳データ
'welcome.greeting': 'こんにちは、{name}さん'

// プレースホルダーを置換
const userName = '田中';
const translated = translate('welcome.greeting', { name: userName });
// → 「こんにちは、田中さん」
```

### 4.3 翻訳の適用順序

1. **共通翻訳データの読み込み** (`common.ja.js`, `common.en.js`, `common.zh.js`)
2. **画面固有翻訳データの読み込み** (`home.ja.js`, `home.en.js`, `home.zh.js`)
3. **翻訳エンジンの初期化** (`translator.js`)
4. **デフォルト言語の適用** （日本語）
5. **保存済み言語の適用** （localStorage から取得）

---

## 5. 言語の永続化

### 5.1 保存先

選択した言語は、以下の2箇所に保存します:

**1. localStorage（優先）**
```javascript
localStorage.setItem('selectedLanguage', 'ja');
```

**2. ユーザーマスタ（ログイン中の場合）**
- テーブル: `users`
- カラム: `preferred_language`
- 値: `ja` / `en` / `zh`

### 5.2 読み込み優先順位

言語の読み込みは、以下の優先順位で決定します:

1. **URLパラメータ** `?lang=en`（最優先）
2. **localStorage** `selectedLanguage`
3. **ユーザーマスタ** `preferred_language`
4. **ブラウザ設定** `navigator.language`
5. **デフォルト** `ja`（日本語）

### 5.3 同期処理

ログイン中のユーザーが言語を切り替えた場合、以下の処理を実行:

1. localStorage に保存
2. API 経由でユーザーマスタを更新（非同期）
3. 画面を即座に翻訳

**API エンドポイント:**

```
PATCH /api/users/profile
{
  "preferred_language": "en"
}
```

---

## 6. 翻訳対象要素

### 6.1 対象要素の指定

翻訳対象の要素には、`data-i18n` 属性を設定します。

**基本形式:**

```html
<span data-i18n="[翻訳キー]">デフォルトテキスト</span>
```

**例:**

```html
<!-- ボタン -->
<button data-i18n="common.submit">送信</button>

<!-- テキスト -->
<h2 data-i18n="home.welcome.greeting">こんにちは、{name}さん</h2>

<!-- プレースホルダー -->
<input type="text" data-i18n-placeholder="common.search" placeholder="検索">
```

### 6.2 特殊な属性の翻訳

テキストコンテンツ以外の属性も翻訳できます。

| 属性 | data-i18n 形式 | 例 |
|------|---------------|-----|
| placeholder | `data-i18n-placeholder` | 入力欄のヒントテキスト |
| title | `data-i18n-title` | ツールチップ |
| aria-label | `data-i18n-aria-label` | スクリーンリーダー用ラベル |

**例:**

```html
<input type="text" 
       data-i18n-placeholder="common.search" 
       data-i18n-aria-label="common.search"
       placeholder="検索">
```

---

## 7. 動的コンテンツの翻訳

### 7.1 JavaScript で生成された要素

JavaScript で動的に生成された要素も、`data-i18n` 属性を設定すれば自動翻訳されます。

**例:**

```javascript
// 要素を生成
const notice = document.createElement('div');
notice.innerHTML = `
  <span data-i18n="home.notices.unread">未読</span>
  <span data-i18n="home.notices.title">お知らせタイトル</span>
`;

// DOM に追加
document.body.appendChild(notice);

// 翻訳を適用
window.Translator.translateElement(notice);
```

### 7.2 API から取得したデータ

API から取得したデータ（お知らせタイトル、投稿内容など）は、以下のいずれかの方法で翻訳します:

**方法A: サーバー側で翻訳済みデータを返す（推奨）**

```json
{
  "title": {
    "ja": "新しい回覧板が届いています",
    "en": "New circulation board available",
    "zh": "新的传阅板已送达"
  }
}
```

**方法B: クライアント側で翻訳API を呼び出す**

```javascript
const translatedTitle = await window.Translator.translateText(
  originalTitle,
  'ja',
  'en'
);
```

---

## 8. 翻訳の品質保証

### 8.1 翻訳チェックリスト

| 項目 | 確認内容 |
|------|---------|
| **完全性** | すべてのUI要素が3言語分あるか |
| **一貫性** | 同じ概念に同じ訳語を使用しているか |
| **文脈** | 文脈に応じた適切な訳語か |
| **長さ** | UI に収まる長さか（特に中国語） |
| **プレースホルダー** | `{変数名}` が正しく動作するか |

### 8.2 翻訳の検証

開発時に、以下のツールで翻訳の完全性を検証します:

**未翻訳キーの検出:**

```javascript
// すべての data-i18n 属性を取得
const i18nElements = document.querySelectorAll('[data-i18n]');

// 各言語で翻訳が存在するか確認
i18nElements.forEach(el => {
  const key = el.dataset.i18n;
  if (!window.I18nData.home.ja[key]) {
    console.error(`Missing translation: ${key}`);
  }
});
```

---

## 9. パフォーマンス最適化

### 9.1 翻訳データの遅延読み込み

画面固有の翻訳データは、その画面を表示するときのみ読み込みます。

**読み込み順序:**

1. 共通翻訳データ（`common.*.js`）→ 全ページで事前読み込み
2. 画面固有翻訳データ（`[screen].*.js`）→ 該当ページでのみ読み込み

### 9.2 翻訳キャッシュ

一度翻訳した要素は、言語を切り替えるまで再翻訳しません。

### 9.3 目標パフォーマンス

| 項目 | 目標値 |
|------|--------|
| 言語切替の応答時間 | 500ms以内 |
| 初回翻訳の完了時間 | 1秒以内 |
| 翻訳データのサイズ | 各ファイル 50KB以下 |

---

## 10. エラーハンドリング

### 10.1 翻訳データの読み込み失敗

翻訳データの読み込みに失敗した場合、以下の順序でフォールバック:

1. 日本語データを使用
2. HTML に記述されたデフォルトテキストを使用

### 10.2 翻訳キーが存在しない

指定された翻訳キーが存在しない場合:

```javascript
// 翻訳キーが存在しない場合、キー名を表示
<span data-i18n="home.invalid.key">home.invalid.key</span>

// 開発環境では警告をコンソールに出力
console.warn(`Translation key not found: home.invalid.key`);
```

---

## 11. アクセシビリティ

### 11.1 lang 属性の自動更新

言語を切り替えた際、HTML の `lang` 属性を自動更新します:

```javascript
// 言語切替時
document.documentElement.lang = 'en'; // ja, en, zh
```

### 11.2 スクリーンリーダー対応

言語切替時に、スクリーンリーダーに通知:

```javascript
// ARIA ライブリージョンで通知
<div role="status" aria-live="polite">
  言語を英語に切り替えました
</div>
```

---

## 12. 実装例

### 12.1 HTML

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title data-i18n="home.title">ホーム - セキュレアシティ</title>
</head>
<body data-page="home">
  <header class="app-header">
    <!-- 言語切替ボタン -->
    <button class="language-btn" aria-haspopup="true">
      <span class="language-code">JA</span> ▼
    </button>
  </header>

  <main class="app-content">
    <h1 data-i18n="home.welcome.greeting">こんにちは、{name}さん</h1>
    <button data-i18n="common.submit">送信</button>
  </main>
</body>
</html>
```

### 12.2 JavaScript（読み込み順序）

```html
<!-- 1. 共通翻訳データ -->
<script src="/js/i18n/langs/common.ja.js"></script>
<script src="/js/i18n/langs/common.en.js"></script>
<script src="/js/i18n/langs/common.zh.js"></script>

<!-- 2. 画面固有翻訳データ -->
<script src="/pages/home/home.ja.js"></script>
<script src="/pages/home/home.en.js"></script>
<script src="/pages/home/home.zh.js"></script>

<!-- 3. 翻訳エンジン -->
<script src="/js/features/translator.js"></script>

<!-- 4. 言語切替機能 -->
<script src="/js/features/language-switcher.js"></script>
```

---

## 13. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-header-v1_0.md` | ヘッダー領域（言語切替ボタン） |
| `common-footer-v1_0.md` | フッター領域（ナビゲーション翻訳） |
| `naming-conventions-v2_1_EN.md` | 翻訳ファイルの命名規則 |
| `05_Project-Structure-v3_3_EN.md` | ファイル構成・パス仕様 |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-I18N-001
- バージョン: 1.0
- 作成日: 2025年10月27日
- 承認者: （未定）
