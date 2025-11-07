# 第4章：既読状況エリアの詳細設計

**HarmoNET スマートコミュニケーションアプリ**  
**掲示板詳細画面 - 既読状況エリア**

**Document ID:** HRM-BOARD-DETAIL-CH04  
**Version:** 2.0  
**Created:** 2025-10-29  
**Status:** 承認待ち

---

## 目次

- [4.1 既読状況エリアの概要](#41-既読状況エリアの概要)
  - [4.1.1 目的と役割](#411-目的と役割)
  - [4.1.2 表示対象](#412-表示対象)
  - [4.1.3 配置位置](#413-配置位置)
  - [4.1.4 レイアウト構造](#414-レイアウト構造)
- [4.2 既読人数の表示仕様](#42-既読人数の表示仕様)
  - [4.2.1 表示形式](#421-表示形式)
  - [4.2.2 デザイン仕様](#422-デザイン仕様)
  - [4.2.3 多言語対応](#423-多言語対応)
  - [4.2.4 リアルタイム更新](#424-リアルタイム更新)
- [4.3 既読ステータスバー](#43-既読ステータスバー)
  - [4.3.1 プログレスバーのデザイン](#431-プログレスバーのデザイン)
  - [4.3.2 進捗表示ロジック](#432-進捗表示ロジック)
  - [4.3.3 アニメーション](#433-アニメーション)
  - [4.3.4 レスポンシブ対応](#434-レスポンシブ対応)
- [4.4 「既読にする」ボタンの詳細仕様](#44-既読にするボタンの詳細仕様)
  - [4.4.1 表示条件](#441-表示条件)
  - [4.4.2 ボタンラベル](#442-ボタンラベル)
  - [4.4.3 デザイン仕様](#443-デザイン仕様)
  - [4.4.4 タップ時の動作フロー](#444-タップ時の動作フロー)
- [4.5 管理者向け既読者リスト表示（Phase 2）](#45-管理者向け既読者リスト表示phase-2)
- [4.6 既読期限の表示（Phase 2）](#46-既読期限の表示phase-2)
- [4.7 エラーハンドリング](#47-エラーハンドリング)
  - [4.7.1 ネットワークエラー時](#471-ネットワークエラー時)
  - [4.7.2 API失敗時](#472-api失敗時)
  - [4.7.3 タイムアウト処理](#473-タイムアウト処理)
- [4.8 レスポンシブ対応](#48-レスポンシブ対応)
  - [4.8.1 スマホ（〜767px）](#481-スマホ767px)
  - [4.8.2 タブレット（768px〜1023px）](#482-タブレット768px1023px)
  - [4.8.3 デスクトップ（1024px〜）](#483-デスクトップ1024px)
- [4.9 テスト項目](#49-テスト項目)
  - [4.9.1 表示テスト](#491-表示テスト)
  - [4.9.2 機能テスト](#492-機能テスト)
  - [4.9.3 レスポンシブテスト](#493-レスポンシブテスト)
- [4.10 CSS実装仕様](#410-css実装仕様)
  - [4.10.1 必要なCSSクラス](#4101-必要なcssクラス)
  - [4.10.2 BEM命名規則](#4102-bem命名規則)
  - [4.10.3 CSSコード例](#4103-cssコード例)
- [4.11 JavaScript実装仕様](#411-javascript実装仕様)
  - [4.11.1 必要な関数](#4111-必要な関数)
  - [4.11.2 イベントハンドラ](#4112-イベントハンドラ)
  - [4.11.3 API連携](#4113-api連携)

---

## 4.1 既読状況エリアの概要

### 4.1.1 目的と役割

既読状況エリアは、管理組合からの重要なお知らせ（回覧板）を住民全員が確実に確認したかを把握するための機能です。

**主な目的**

- 重要なお知らせの到達率を可視化
- 住民が既読状態を登録できる
- 管理者が既読状況を確認できる
- 未読者への再通知を可能にする（Phase 2）

**役割**

- 紙の回覧板のデジタル版として機能
- 総会案内、工事予定、緊急連絡などの重要情報の確実な伝達
- 管理組合の運営効率化

### 4.1.2 表示対象

既読状況エリアは**回覧板投稿のみ**に表示されます。

| 掲示板タイプ | 既読状況エリア表示 |
|------------|-----------------|
| 回覧板（重要お知らせ） | ✅ 表示 |
| 全体掲示板 | ❌ 非表示 |
| グループ掲示板 | ❌ 非表示 |

**判定ロジック**

投稿データの `post_type` フィールドが `"circulation"` の場合のみ表示します。

```javascript
if (post.post_type === 'circulation') {
  // 既読状況エリアを表示
  showReadStatusArea();
}
```

### 4.1.3 配置位置

既読状況エリアは、投稿詳細画面内の以下の位置に配置されます：

```
┌─────────────────────────┐
│ ヘッダー領域            │
├─────────────────────────┤
│ 投稿本文エリア          │
│ - カテゴリバッジ        │
│ - タイトル              │
│ - 投稿者情報            │
│ - 本文                  │
│ - 翻訳ボタン            │
├─────────────────────────┤
│ 添付ファイルエリア      │ ← この下に配置
├─────────────────────────┤
│ ★ 既読状況エリア ★     │ ← ここ
│ - 既読人数表示          │
│ - プログレスバー        │
│ - 既読にするボタン      │
├─────────────────────────┤
│ コメントエリア          │
├─────────────────────────┤
│ コメント入力エリア      │
│ （回覧板の場合は非表示）│
├─────────────────────────┤
│ フッター領域            │
└─────────────────────────┘
```

**配置理由**

- 投稿内容を確認した後、自然な流れで既読登録できる
- コメントエリアより上に配置することで、重要性を視覚的に示す
- 添付ファイル確認後、すぐに既読ボタンを押せる

### 4.1.4 レイアウト構造

既読状況エリアは、以下の3つのコンポーネントで構成されます：

```
┌───────────────────────────────────┐
│ 既読状況エリア                     │
│                                   │
│ ┌─────────────────────────────┐   │
│ │ 既読 45人 / 全体 50人（90%） │   │ ← 既読人数表示
│ └─────────────────────────────┘   │
│                                   │
│ ┌─────────────────────────────┐   │
│ │████████████████░░░░░░░░░░░░ │   │ ← プログレスバー
│ └─────────────────────────────┘   │
│                                   │
│        ┌────────────────┐         │
│        │ 既読にする      │         │ ← 既読ボタン
│        └────────────────┘         │
│                                   │
└───────────────────────────────────┘
```

**余白設定**

- エリア全体の上下余白: 24px
- エリア全体の左右余白: 24px
- 各要素間の余白: 16px

---

## 4.2 既読人数の表示仕様

### 4.2.1 表示形式

既読人数は、以下の形式で表示されます：

**日本語**
```
既読 45人 / 全体 50人（90%）
```

**英語**
```
Read 45 / Total 50 (90%)
```

**中国語**
```
已读 45人 / 总计 50人（90%）
```

**構成要素**

- 既読人数: 既読登録したユーザー数
- 全体人数: 対象となる全住民数
- 既読率: 既読人数 ÷ 全体人数 × 100（小数点以下切り捨て）

### 4.2.2 デザイン仕様

既読人数表示は、HarmoNET Design System v1.0に準拠します。

**フォント仕様**

| 項目 | 値 |
|------|---|
| フォントファミリー | BIZ UDゴシック（和文）、SF Pro Text / Segoe UI（欧文） |
| フォントサイズ | 14px |
| フォントウェイト | regular (400) |
| 行間 | 1.6 |

**色指定**

- 通常テキスト: `#1F2937`（主要文字色）
- 数値部分: `#2563EB`（アクションブルー）
- パーセンテージ: `#2563EB`（アクションブルー）

**CSS例**

```css
.read-status-count {
  font-size: 14px;
  font-weight: 400;
  line-height: 1.6;
  color: #1F2937;
}

.read-status-count__number {
  color: #2563EB;
  font-weight: 500;
}
```

**HTML構造例**

```html
<div class="read-status-count">
  既読 <span class="read-status-count__number">45人</span> / 
  全体 <span class="read-status-count__number">50人</span>
  （<span class="read-status-count__number">90%</span>）
</div>
```

### 4.2.3 多言語対応

既読人数表示は、ユーザーの言語設定に応じて自動的に切り替わります。

**翻訳キーの構造**

```javascript
// 日本語 (ja)
readStatus: {
  read: '既読',
  total: '全体',
  people: '人'
}

// 英語 (en)
readStatus: {
  read: 'Read',
  total: 'Total',
  people: ''
}

// 中国語 (zh)
readStatus: {
  read: '已读',
  total: '总计',
  people: '人'
}
```

**表示ロジック**

```javascript
const displayReadCount = (readCount, totalCount) => {
  const percentage = Math.floor((readCount / totalCount) * 100);
  const lang = getCurrentLanguage();
  
  const text = {
    ja: `既読 ${readCount}人 / 全体 ${totalCount}人（${percentage}%）`,
    en: `Read ${readCount} / Total ${totalCount} (${percentage}%)`,
    zh: `已读 ${readCount}人 / 总计 ${totalCount}人（${percentage}%）`
  };
  
  return text[lang];
};
```

### 4.2.4 リアルタイム更新

既読人数は、他のユーザーが既読登録した際にリアルタイムで更新されます。

**更新方法**

1. **WebSocket（優先）**
   - サーバーからの更新通知を受信
   - 即座に画面を更新
   - 接続断時はポーリングにフォールバック

2. **ポーリング（フォールバック）**
   - 30秒ごとに既読状況をAPI取得
   - WebSocket接続失敗時に自動切替

**更新フロー**

```
他のユーザーが既読登録
  ↓
サーバーがWebSocketで通知送信
  ↓
クライアントが通知を受信
  ↓
既読人数を更新（APIコール不要）
  ↓
プログレスバーをアニメーション更新
```

**JavaScript実装例**

```javascript
// WebSocket接続
const connectWebSocket = (postId) => {
  const ws = new WebSocket(`wss://api.example.com/posts/${postId}/read-status`);
  
  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    updateReadStatus(data.readCount, data.totalCount);
  };
  
  ws.onerror = () => {
    // ポーリングにフォールバック
    startPolling(postId);
  };
};

// ポーリング処理
const startPolling = (postId) => {
  setInterval(async () => {
    const response = await fetch(`/api/posts/${postId}/read-status`);
    const data = await response.json();
    updateReadStatus(data.readCount, data.totalCount);
  }, 30000); // 30秒ごと
};
```

---

## 4.3 既読ステータスバー

### 4.3.1 プログレスバーのデザイン

既読ステータスバーは、既読率を視覚的に表現するプログレスバーです。

**デザイン仕様**

| 項目 | 値 |
|------|---|
| 高さ | 8px |
| 角丸 | border-radius: 0.5rem (8px) |
| 背景色 | #E5E7EB（枠線・分割線色） |
| 進捗色 | #2563EB（アクションブルー） |
| 最大幅 | 100%（レスポンシブ） |

**CSS実装**

```css
.read-status-bar {
  width: 100%;
  height: 8px;
  background-color: #E5E7EB;
  border-radius: 0.5rem;
  overflow: hidden;
  margin: 16px 0;
}

.read-status-bar__progress {
  height: 100%;
  background-color: #2563EB;
  border-radius: 0.5rem;
  transition: width 0.3s ease-out;
}
```

**HTML構造**

```html
<div class="read-status-bar">
  <div class="read-status-bar__progress" style="width: 90%;"></div>
</div>
```

**視覚例**

```
既読率 0%
┌──────────────────────────────────┐
│                                  │ ← 背景色のみ
└──────────────────────────────────┘

既読率 50%
┌──────────────────────────────────┐
│████████████████░░░░░░░░░░░░░░░░░│ ← 半分まで進捗色
└──────────────────────────────────┘

既読率 90%
┌──────────────────────────────────┐
│████████████████████████████████░│ ← ほぼ満タン
└──────────────────────────────────┘

既読率 100%
┌──────────────────────────────────┐
│██████████████████████████████████│ ← 全て進捗色
└──────────────────────────────────┘
```

### 4.3.2 進捗表示ロジック

**既読率の計算式**

```javascript
const calculateReadPercentage = (readCount, totalCount) => {
  if (totalCount === 0) return 0;
  return Math.floor((readCount / totalCount) * 100);
};
```

**小数点以下の処理**

- 小数点以下は切り捨て
- 0.1%でも既読があれば1%として表示
- 99.9%でも全員既読でなければ99%として表示

**特殊ケースの処理**

| ケース | 既読率表示 | プログレスバー幅 |
|--------|-----------|----------------|
| 全員未読 | 0% | 0% |
| 1人でも既読 | 計算結果 | 計算結果 |
| 全員既読 | 100% | 100% |
| 対象者0人（エラー） | 0% | 0% |

### 4.3.3 アニメーション

プログレスバーは、既読率が変化した際にスムーズにアニメーションします。

**アニメーション仕様**

| 項目 | 値 |
|------|---|
| プロパティ | width |
| 持続時間 | 0.3s |
| イージング | ease-out |

**CSS実装**

```css
.read-status-bar__progress {
  transition: width 0.3s ease-out;
}
```

**JavaScript実装**

```javascript
const updateProgressBar = (percentage) => {
  const progressBar = document.querySelector('.read-status-bar__progress');
  progressBar.style.width = `${percentage}%`;
};
```

**初期表示時のアニメーション**

画面表示時、プログレスバーは0%から現在の既読率まで滑らかにアニメーションします。

```javascript
// 初期表示時
const animateProgressBar = (targetPercentage) => {
  const progressBar = document.querySelector('.read-status-bar__progress');
  progressBar.style.width = '0%';
  
  // 次のフレームで目標値に設定（CSSトランジションが発火）
  requestAnimationFrame(() => {
    progressBar.style.width = `${targetPercentage}%`;
  });
};
```

### 4.3.4 レスポンシブ対応

プログレスバーは、すべてのデバイスで適切に表示されます。

**スマホ（〜767px）**

```css
@media (max-width: 767px) {
  .read-status-bar {
    width: 100%;
    max-width: none;
  }
}
```

**タブレット・デスクトップ（768px〜）**

```css
@media (min-width: 768px) {
  .read-status-bar {
    width: 100%;
    max-width: 600px;
  }
}
```

---

## 4.4 「既読にする」ボタンの詳細仕様

### 4.4.1 表示条件

「既読にする」ボタンは、ユーザーの既読状態に応じて表示が切り替わります。

| ユーザーの状態 | ボタン表示 | ボタン状態 |
|--------------|----------|----------|
| 未読 | 「既読にする」 | アクティブ（青色） |
| 既読 | 「既読済み」 | 非活性（グレー） |

**判定ロジック**

```javascript
const getReadButtonState = (isRead) => {
  if (isRead) {
    return {
      label: '既読済み', // 言語により変化
      active: false,
      icon: 'check' // チェックマークアイコン
    };
  } else {
    return {
      label: '既読にする',
      active: true,
      icon: null
    };
  }
};
```

### 4.4.2 ボタンラベル

ボタンラベルは、ユーザーの言語設定と既読状態に応じて変化します。

**未読時のラベル**

| 言語 | ラベル |
|------|-------|
| 日本語 | 既読にする |
| 英語 | Mark as Read |
| 中国語 | 标记为已读 |

**既読時のラベル**

| 言語 | ラベル |
|------|-------|
| 日本語 | 既読済み ✓ |
| 英語 | Already Read ✓ |
| 中国語 | 已读 ✓ |

**翻訳キーの構造**

```javascript
// 翻訳ファイル (board-detail.ja.js)
readStatus: {
  markAsRead: '既読にする',
  alreadyRead: '既読済み'
}

// 翻訳ファイル (board-detail.en.js)
readStatus: {
  markAsRead: 'Mark as Read',
  alreadyRead: 'Already Read'
}

// 翻訳ファイル (board-detail.zh.js)
readStatus: {
  markAsRead: '标记为已读',
  alreadyRead: '已读'
}
```

### 4.4.3 デザイン仕様

#### 4.4.3.1 未読時（アクティブ状態）

ボタンはプライマリアクションボタンとして表示されます。

**デザイン仕様**

| 項目 | 値 |
|------|---|
| 背景色 | #2563EB（アクションブルー） |
| 文字色 | #FFFFFF（白） |
| フォントサイズ | 14px |
| フォントウェイト | 500 (medium) |
| パディング | 上下: 8px、左右: 16px |
| 角丸 | border-radius: 0.5rem (8px) |
| シャドウ | shadow-sm |
| 最小タップ領域 | 44px × 44px |

**CSS実装**

```css
.read-status-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 140px;
  min-height: 44px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  color: #FFFFFF;
  background-color: #2563EB;
  border: none;
  border-radius: 0.5rem;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.read-status-button:hover {
  background-color: #1D4ED8;
}

.read-status-button:active {
  background-color: #1E40AF;
}
```

**ホバー時の変化**

- 背景色: `#2563EB` → `#1D4ED8`（やや濃くなる）
- トランジション: 0.2s ease

**タップ時の変化**

- 背景色: `#1E40AF`（さらに濃くなる）
- わずかに縮小: `scale(0.98)`

#### 4.4.3.2 既読時（非活性状態）

ボタンは非活性状態として表示されます。

**デザイン仕様**

| 項目 | 値 |
|------|---|
| 背景色 | #F9FAFB（背景色） |
| 枠線 | 1px solid #E5E7EB |
| 文字色 | #9CA3AF（補足文字色） |
| フォントサイズ | 14px |
| フォントウェイト | 400 (regular) |
| パディング | 上下: 8px、左右: 16px |
| 角丸 | border-radius: 0.5rem (8px) |
| アイコン | チェックマーク（✓） |
| カーソル | not-allowed |

**CSS実装**

```css
.read-status-button--disabled {
  background-color: #F9FAFB;
  border: 1px solid #E5E7EB;
  color: #9CA3AF;
  cursor: not-allowed;
  pointer-events: none;
}

.read-status-button--disabled::before {
  content: '✓ ';
  margin-right: 4px;
}
```

**HTML構造**

```html
<!-- 未読時 -->
<button class="read-status-button" onclick="markAsRead()">
  既読にする
</button>

<!-- 既読時 -->
<button class="read-status-button read-status-button--disabled" disabled>
  既読済み
</button>
```

### 4.4.4 タップ時の動作フロー

ユーザーが「既読にする」ボタンをタップした際の処理フローです。

**処理フロー図**

```
ユーザーがボタンをタップ
  ↓
[1] ボタンを非活性化（連打防止）
  ↓
[2] ローディング表示開始
  - ボタンテキスト: 「処理中...」
  - スピナーアイコン表示
  ↓
[3] APIリクエスト送信
  - POST /api/posts/{postId}/mark-as-read
  ↓
[4] レスポンス待機（最大10秒）
  ↓
成功? ─── YES ──→ [5a] 既読状態に更新
  │                - ボタンを「既読済み」に変更
  │                - 既読人数を +1
  │                - プログレスバーを更新
  │                ↓
  │              [6a] トースト通知表示
  │                - 「既読として登録しました」
  │                ↓
  │              完了
  │
  └─── NO ──→ [5b] エラー処理
              - ボタンを再度アクティブ化
              - エラーメッセージ表示
              ↓
            [6b] リトライ案内
              - 「もう一度試す」ボタン表示
              ↓
            完了
```

**JavaScript実装例**

```javascript
const markAsRead = async (postId) => {
  const button = document.querySelector('.read-status-button');
  
  // [1] ボタンを非活性化
  button.disabled = true;
  button.classList.add('read-status-button--loading');
  
  // [2] ローディング表示
  const originalText = button.textContent;
  button.innerHTML = '<span class="spinner"></span> 処理中...';
  
  try {
    // [3] APIリクエスト送信
    const response = await fetch(`/api/posts/${postId}/mark-as-read`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${getAuthToken()}`
      }
    });
    
    if (!response.ok) {
      throw new Error('API request failed');
    }
    
    const data = await response.json();
    
    // [5a] 既読状態に更新
    button.classList.remove('read-status-button--loading');
    button.classList.add('read-status-button--disabled');
    button.innerHTML = '✓ 既読済み';
    button.disabled = true;
    
    // 既読人数とプログレスバーを更新
    updateReadStatus(data.readCount, data.totalCount);
    
    // [6a] トースト通知表示
    showToast('既読として登録しました', 'success');
    
  } catch (error) {
    // [5b] エラー処理
    console.error('既読登録エラー:', error);
    
    button.disabled = false;
    button.classList.remove('read-status-button--loading');
    button.textContent = originalText;
    
    // [6b] エラーメッセージ表示
    showToast('既読登録に失敗しました。もう一度お試しください。', 'error');
  }
};
```

**連打防止の実装**

```javascript
let isProcessing = false;

const markAsRead = async (postId) => {
  // 既に処理中の場合は何もしない
  if (isProcessing) {
    return;
  }
  
  isProcessing = true;
  
  try {
    // 既読登録処理
    await performMarkAsRead(postId);
  } finally {
    isProcessing = false;
  }
};
```

**タイムアウト処理**

```javascript
const markAsReadWithTimeout = async (postId) => {
  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Timeout')), 10000);
  });
  
  const requestPromise = fetch(`/api/posts/${postId}/mark-as-read`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getAuthToken()}`
    }
  });
  
  try {
    const response = await Promise.race([requestPromise, timeoutPromise]);
    return response;
  } catch (error) {
    if (error.message === 'Timeout') {
      throw new Error('リクエストがタイムアウトしました');
    }
    throw error;
  }
};
```

---

## 4.5 管理者向け既読者リスト表示（Phase 2）

管理者は、回覧板の既読者リストを確認できる機能が提供されます（Phase 2で実装予定）。

**主な機能**

- 既読者一覧の表示（ユーザー名、既読日時）
- 未読者一覧の表示（フィルタリング）
- CSV出力機能
- 未読者への個別通知機能

**アクセス権限**

- 管理者（理事）のみ閲覧可能
- 一般住民には表示されない

**表示方法**

投稿詳細画面の既読状況エリア内に「詳細を見る」ボタンを配置し、タップするとモーダルまたは専用画面で既読者リストを表示します。

**Phase 2での詳細設計**

具体的な画面レイアウト、テーブル構造、フィルタリングUIについては、Phase 2の詳細設計書で定義します。

---

## 4.6 既読期限の表示（Phase 2）

管理者が設定した既読期限を表示する機能です（Phase 2で実装予定）。

**主な機能**

- 既読期限日時の表示
- 期限切れの警告表示
- 期限超過後の表示変更

**表示例**

```
┌─────────────────────────────────┐
│ ⚠️ 既読期限: 2025年11月5日まで  │
└─────────────────────────────────┘

既読 30人 / 全体 50人（60%）
████████████░░░░░░░░░░░░░░░░░░░

[ 既読にする ]
```

**期限切れ時の表示**

```
┌─────────────────────────────────┐
│ ❌ 既読期限を過ぎています         │
└─────────────────────────────────┘

既読 30人 / 全体 50人（60%）
████████████░░░░░░░░░░░░░░░░░░░

[ 既読にする ]
```

**デザイン仕様（Phase 2）**

- 警告表示: 注意レッド (#DC2626) 背景 + 警告アイコン
- 通常期限表示: 副次文字色 (#6B7280)

**Phase 2での詳細設計**

具体的な期限アラート機能、通知タイミング、未読者への自動リマインダーについては、Phase 2の詳細設計書で定義します。

---

## 4.7 エラーハンドリング

既読登録処理では、適切なエラーハンドリングが必要です。

### 4.7.1 ネットワークエラー時

ネットワーク接続がない場合、またはサーバーに到達できない場合の処理です。

**エラーメッセージ**

| 言語 | メッセージ |
|------|-----------|
| 日本語 | ネットワークに接続できません。インターネット接続を確認してください。 |
| 英語 | Cannot connect to network. Please check your internet connection. |
| 中国語 | 无法连接到网络。请检查您的互联网连接。 |

**表示方法**

- トースト通知（画面下部に3秒間表示）
- エラーアイコン（赤色の警告マーク）

**リトライボタン**

```html
<div class="error-message">
  <p>ネットワークに接続できません。</p>
  <button class="retry-button" onclick="markAsRead()">
    もう一度試す
  </button>
</div>
```

**JavaScript実装**

```javascript
const handleNetworkError = () => {
  showToast(
    'ネットワークに接続できません。インターネット接続を確認してください。',
    'error',
    {
      action: {
        label: 'もう一度試す',
        callback: () => markAsRead(postId)
      }
    }
  );
};
```

### 4.7.2 API失敗時

APIリクエストは送信できたが、サーバーがエラーを返した場合の処理です。

**エラーケース別の処理**

| HTTPステータス | エラー内容 | 処理 |
|--------------|-----------|------|
| 400 Bad Request | 不正なリクエスト | エラーメッセージ表示 |
| 401 Unauthorized | 認証エラー | ログイン画面へ遷移 |
| 403 Forbidden | 権限なし | エラーメッセージ表示 |
| 404 Not Found | 投稿が存在しない | エラーメッセージ表示 |
| 409 Conflict | 既に既読済み | 既読状態に更新（エラーとしない） |
| 500 Internal Server Error | サーバーエラー | 自動リトライ |
| 503 Service Unavailable | サービス停止中 | エラーメッセージ表示 |

**自動リトライ処理**

サーバーエラー（5xx）の場合、自動的にリトライを実行します。

```javascript
const markAsReadWithRetry = async (postId, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(`/api/posts/${postId}/mark-as-read`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getAuthToken()}`
        }
      });
      
      if (response.ok) {
        return await response.json();
      }
      
      // 5xxエラーの場合はリトライ
      if (response.status >= 500) {
        if (i < maxRetries - 1) {
          // 指数バックオフ: 2秒、4秒、8秒
          await sleep(Math.pow(2, i + 1) * 1000);
          continue;
        }
      }
      
      // その他のエラーは即座に失敗
      throw new Error(`API Error: ${response.status}`);
      
    } catch (error) {
      if (i === maxRetries - 1) {
        throw error;
      }
    }
  }
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
```

**リトライ間隔（指数バックオフ）**

| リトライ回数 | 待機時間 |
|------------|---------|
| 1回目 | 2秒 |
| 2回目 | 4秒 |
| 3回目 | 8秒 |

### 4.7.3 タイムアウト処理

APIリクエストが一定時間内に完了しない場合の処理です。

**タイムアウト時間**

- 既読登録API: 10秒

**タイムアウト時の処理**

1. リクエストを中断
2. エラーメッセージを表示
3. ボタンを再度アクティブ化
4. リトライ案内を表示

**エラーメッセージ**

| 言語 | メッセージ |
|------|-----------|
| 日本語 | リクエストがタイムアウトしました。もう一度お試しください。 |
| 英語 | Request timed out. Please try again. |
| 中国語 | 请求超时。请重试。 |

**JavaScript実装**

```javascript
const fetchWithTimeout = (url, options, timeout = 10000) => {
  return Promise.race([
    fetch(url, options),
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout')), timeout)
    )
  ]);
};

const markAsRead = async (postId) => {
  try {
    const response = await fetchWithTimeout(
      `/api/posts/${postId}/mark-as-read`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getAuthToken()}`
        }
      },
      10000 // 10秒
    );
    
    // 成功処理
    
  } catch (error) {
    if (error.message === 'Timeout') {
      showToast('リクエストがタイムアウトしました。もう一度お試しください。', 'error');
    } else {
      // その他のエラー処理
    }
  }
};
```

---

## 4.8 レスポンシブ対応

既読状況エリアは、すべてのデバイスで適切に表示されます。

### 4.8.1 スマホ（〜767px）

**レイアウト仕様**

- 既読状況エリア全体の横幅: 100%
- 左右の余白: 16px
- ボタン: 幅100%（block表示）
- フォントサイズ: 14px

**CSS実装**

```css
@media (max-width: 767px) {
  .read-status-area {
    width: 100%;
    padding: 16px;
  }
  
  .read-status-count {
    font-size: 14px;
    text-align: center;
  }
  
  .read-status-bar {
    width: 100%;
    margin: 12px 0;
  }
  
  .read-status-button {
    width: 100%;
    display: block;
    margin: 0 auto;
  }
}
```

**表示例（スマホ）**

```
┌─────────────────────┐
│                     │
│ 既読 45人 / 50人    │ ← 中央揃え
│     （90%）         │
│                     │
│ ████████████░░░░░░░ │ ← 幅100%
│                     │
│ ┌─────────────────┐ │
│ │  既読にする      │ │ ← 幅100%
│ └─────────────────┘ │
│                     │
└─────────────────────┘
```

### 4.8.2 タブレット（768px〜1023px）

**レイアウト仕様**

- 既読状況エリアの最大幅: 600px
- 左右の余白: 24px
- ボタン: インライン表示、中央揃え
- フォントサイズ: 14px

**CSS実装**

```css
@media (min-width: 768px) and (max-width: 1023px) {
  .read-status-area {
    max-width: 600px;
    margin: 0 auto;
    padding: 24px;
  }
  
  .read-status-count {
    font-size: 14px;
    text-align: center;
  }
  
  .read-status-bar {
    width: 100%;
    margin: 16px 0;
  }
  
  .read-status-button {
    display: inline-block;
    margin: 0 auto;
  }
}
```

**表示例（タブレット）**

```
┌──────────────────────────┐
│                          │
│   既読 45人 / 50人       │ ← 中央揃え
│       （90%）            │
│                          │
│ ██████████████░░░░░░░░░░ │ ← 最大幅600px
│                          │
│    ┌──────────────┐      │
│    │ 既読にする    │      │ ← インライン、中央
│    └──────────────┘      │
│                          │
└──────────────────────────┘
```

### 4.8.3 デスクトップ（1024px〜）

**レイアウト仕様**

- 既読状況エリアの最大幅: 800px
- 左右の余白: 32px
- ボタン: インライン表示、中央揃え
- フォントサイズ: 14px

**CSS実装**

```css
@media (min-width: 1024px) {
  .read-status-area {
    max-width: 800px;
    margin: 0 auto;
    padding: 32px;
  }
  
  .read-status-count {
    font-size: 14px;
    text-align: center;
  }
  
  .read-status-bar {
    width: 100%;
    max-width: 600px;
    margin: 16px auto;
  }
  
  .read-status-button {
    display: inline-block;
    margin: 0 auto;
  }
}
```

**表示例（デスクトップ）**

```
┌───────────────────────────────────┐
│                                   │
│     既読 45人 / 全体 50人（90%）   │ ← 中央揃え
│                                   │
│   ████████████████░░░░░░░░░░░░░   │ ← 最大幅600px
│                                   │
│       ┌───────────────┐            │
│       │ 既読にする     │            │ ← インライン、中央
│       └───────────────┘            │
│                                   │
└───────────────────────────────────┘
```

---

## 4.9 テスト項目

既読状況エリアの品質を保証するためのテスト項目です。

### 4.9.1 表示テスト

**基本表示テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| 回覧板での表示 | 回覧板投稿の詳細画面を表示 | 既読状況エリアが表示される |
| 全体掲示板での非表示 | 全体掲示板投稿の詳細画面を表示 | 既読状況エリアが表示されない |
| グループ掲示板での非表示 | グループ掲示板投稿の詳細画面を表示 | 既読状況エリアが表示されない |
| 既読人数の表示 | 既読人数を確認 | 正しい人数が表示される |
| 全体人数の表示 | 全体人数を確認 | 正しい人数が表示される |
| 既読率の表示 | 既読率を確認 | 正しいパーセンテージが表示される |
| プログレスバーの表示 | プログレスバーを確認 | 既読率と一致する幅で表示される |

**多言語表示テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| 日本語表示 | 言語設定を日本語に変更 | 「既読 XX人 / 全体 XX人（XX%）」と表示される |
| 英語表示 | 言語設定を英語に変更 | 「Read XX / Total XX (XX%)」と表示される |
| 中国語表示 | 言語設定を中国語に変更 | 「已读 XX人 / 总计 XX人（XX%）」と表示される |

**ボタン状態テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| 未読時のボタン表示 | 未読の回覧板を表示 | 青色の「既読にする」ボタンが表示される |
| 既読時のボタン表示 | 既読済みの回覧板を表示 | グレーの「既読済み」ボタンが表示される |
| ボタンラベルの多言語対応 | 各言語でボタンを確認 | 正しい言語でラベルが表示される |

### 4.9.2 機能テスト

**既読登録テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| 既読登録の成功 | 「既読にする」ボタンをタップ | 既読状態に更新される |
| 既読人数の更新 | 既読登録後の既読人数を確認 | 既読人数が +1 される |
| プログレスバーの更新 | 既読登録後のプログレスバーを確認 | プログレスバーが更新される |
| ボタン状態の変更 | 既読登録後のボタンを確認 | 「既読済み」ボタンに変わる |
| トースト通知の表示 | 既読登録後の通知を確認 | 「既読として登録しました」と表示される |
| 連打防止 | ボタンを連続でタップ | 1回のみ処理される |

**リアルタイム更新テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| WebSocket更新 | 他のユーザーが既読登録 | 自動的に既読人数が更新される |
| プログレスバーの自動更新 | 既読人数の更新を確認 | プログレスバーが自動更新される |
| ポーリング動作 | WebSocket切断時の動作 | ポーリングで更新される |

**エラーハンドリングテスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| ネットワークエラー | ネットワークを切断して既読登録 | エラーメッセージが表示される |
| API失敗 | サーバーエラー時の動作 | リトライ処理が実行される |
| タイムアウト | タイムアウト発生時の動作 | タイムアウトメッセージが表示される |
| リトライ動作 | エラー後のリトライ | 正常にリトライされる |

### 4.9.3 レスポンシブテスト

**デバイス別表示テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| スマホ表示（iPhone SE） | 320px幅で表示確認 | 適切にレイアウトされる |
| スマホ表示（iPhone 14） | 390px幅で表示確認 | 適切にレイアウトされる |
| タブレット表示（iPad） | 768px幅で表示確認 | 適切にレイアウトされる |
| デスクトップ表示 | 1920px幅で表示確認 | 適切にレイアウトされる |

**タップ領域テスト**

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| ボタンのタップ領域 | ボタンのタップ可能領域を確認 | 最小44px × 44pxが確保される |
| タップの反応 | ボタンをタップ | 確実に反応する |

---

## 4.10 CSS実装仕様

### 4.10.1 必要なCSSクラス

既読状況エリアの実装に必要なCSSクラスの一覧です。

| クラス名 | 用途 | 要素 |
|---------|------|------|
| `.read-status-area` | 既読状況エリア全体 | div |
| `.read-status-count` | 既読人数表示 | div |
| `.read-status-count__number` | 数値部分（青色） | span |
| `.read-status-bar` | プログレスバー本体 | div |
| `.read-status-bar__progress` | プログレスバーの進捗部分 | div |
| `.read-status-button` | 既読ボタン（基本） | button |
| `.read-status-button--active` | アクティブ状態（未読時） | button |
| `.read-status-button--disabled` | 非活性状態（既読時） | button |
| `.read-status-button--loading` | ローディング状態 | button |

### 4.10.2 BEM命名規則

既読状況エリアのCSSクラスは、BEM（Block Element Modifier）命名規則に準拠します。

**基本構造**

```
Block:    read-status-area
Element:  read-status-area__count
Modifier: read-status-button--disabled
```

**命名例**

```html
<!-- Block -->
<div class="read-status-area">
  
  <!-- Element -->
  <div class="read-status-count">
    既読 <span class="read-status-count__number">45人</span>
  </div>
  
  <!-- Element -->
  <div class="read-status-bar">
    <!-- Element (子要素) -->
    <div class="read-status-bar__progress"></div>
  </div>
  
  <!-- Element with Modifier -->
  <button class="read-status-button read-status-button--active">
    既読にする
  </button>
  
</div>
```

### 4.10.3 CSSコード例

完全なCSSコード例です（HarmoNET Design System v1.0準拠）。

```css
/* ========================================
   既読状況エリア
   ======================================== */

/* エリア全体 */
.read-status-area {
  width: 100%;
  max-width: 800px;
  margin: 24px auto;
  padding: 24px;
  background-color: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 1rem;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

/* 既読人数表示 */
.read-status-count {
  font-size: 14px;
  font-weight: 400;
  line-height: 1.6;
  color: #1F2937;
  text-align: center;
  margin-bottom: 16px;
}

.read-status-count__number {
  color: #2563EB;
  font-weight: 500;
}

/* プログレスバー */
.read-status-bar {
  width: 100%;
  max-width: 600px;
  height: 8px;
  background-color: #E5E7EB;
  border-radius: 0.5rem;
  overflow: hidden;
  margin: 16px auto;
}

.read-status-bar__progress {
  height: 100%;
  background-color: #2563EB;
  border-radius: 0.5rem;
  transition: width 0.3s ease-out;
}

/* 既読ボタン（基本） */
.read-status-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 140px;
  min-height: 44px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  margin: 16px auto 0;
}

/* 既読ボタン（アクティブ状態 - 未読時） */
.read-status-button--active {
  color: #FFFFFF;
  background-color: #2563EB;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.read-status-button--active:hover {
  background-color: #1D4ED8;
}

.read-status-button--active:active {
  background-color: #1E40AF;
  transform: scale(0.98);
}

/* 既読ボタン（非活性状態 - 既読時） */
.read-status-button--disabled {
  color: #9CA3AF;
  background-color: #F9FAFB;
  border: 1px solid #E5E7EB;
  cursor: not-allowed;
  pointer-events: none;
}

.read-status-button--disabled::before {
  content: '✓ ';
  margin-right: 4px;
}

/* 既読ボタン（ローディング状態） */
.read-status-button--loading {
  color: #FFFFFF;
  background-color: #60A5FA;
  cursor: wait;
  pointer-events: none;
}

/* スピナーアニメーション */
.spinner {
  display: inline-block;
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #FFFFFF;
  border-radius: 50%;
  animation: spinner 0.6s linear infinite;
  margin-right: 8px;
}

@keyframes spinner {
  to {
    transform: rotate(360deg);
  }
}

/* ========================================
   レスポンシブ対応
   ======================================== */

/* スマホ（〜767px） */
@media (max-width: 767px) {
  .read-status-area {
    padding: 16px;
    margin: 16px;
    border-radius: 0.5rem;
  }
  
  .read-status-count {
    font-size: 13px;
  }
  
  .read-status-bar {
    margin: 12px 0;
  }
  
  .read-status-button {
    width: 100%;
    margin-top: 12px;
  }
}

/* タブレット（768px〜1023px） */
@media (min-width: 768px) and (max-width: 1023px) {
  .read-status-area {
    max-width: 600px;
    padding: 20px;
  }
  
  .read-status-bar {
    max-width: 500px;
  }
}

/* デスクトップ（1024px〜） */
@media (min-width: 1024px) {
  .read-status-area {
    max-width: 800px;
    padding: 32px;
  }
  
  .read-status-bar {
    max-width: 600px;
  }
}
```

---

## 4.11 JavaScript実装仕様

### 4.11.1 必要な関数

既読状況エリアの実装に必要なJavaScript関数の一覧です。

| 関数名 | 用途 | パラメータ | 戻り値 |
|-------|------|----------|--------|
| `initReadStatus()` | 既読状況エリアの初期化 | postId: string | void |
| `updateReadStatus()` | 既読状況の更新 | readCount: number, totalCount: number | void |
| `markAsRead()` | 既読登録処理 | postId: string | Promise<void> |
| `showReadStatusError()` | エラー表示 | message: string | void |
| `calculateReadPercentage()` | 既読率の計算 | readCount: number, totalCount: number | number |
| `updateProgressBar()` | プログレスバー更新 | percentage: number | void |
| `connectWebSocket()` | WebSocket接続 | postId: string | WebSocket |
| `startPolling()` | ポーリング開始 | postId: string | void |

### 4.11.2 イベントハンドラ

**ボタンクリックイベント**

```javascript
// 既読ボタンのクリックイベント
document.querySelector('.read-status-button').addEventListener('click', async (event) => {
  const postId = event.target.dataset.postId;
  await markAsRead(postId);
});
```

**WebSocket更新イベント**

```javascript
// WebSocketからの更新通知を受信
ws.addEventListener('message', (event) => {
  const data = JSON.parse(event.data);
  
  if (data.type === 'read_status_update') {
    updateReadStatus(data.readCount, data.totalCount);
  }
});
```

### 4.11.3 API連携

**既読登録API**

```javascript
/**
 * 既読登録API
 * @param {string} postId - 投稿ID
 * @returns {Promise<Object>} APIレスポンス
 */
const markAsReadAPI = async (postId) => {
  const response = await fetch(`/api/posts/${postId}/mark-as-read`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getAuthToken()}`
    }
  });
  
  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }
  
  return await response.json();
};
```

**既読状況取得API**

```javascript
/**
 * 既読状況取得API
 * @param {string} postId - 投稿ID
 * @returns {Promise<Object>} 既読状況データ
 */
const getReadStatus = async (postId) => {
  const response = await fetch(`/api/posts/${postId}/read-status`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${getAuthToken()}`
    }
  });
  
  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }
  
  return await response.json();
};
```

**APIレスポンス例**

```json
{
  "postId": "post_12345",
  "readCount": 45,
  "totalCount": 50,
  "readPercentage": 90,
  "isRead": true,
  "readAt": "2025-10-29T10:30:00Z"
}
```

---

## 🔗 関連ドキュメント

### 前後の章

- [第3章: 投稿本文エリア](board-detail-design-ch03_v2_0.md)
- [第5章: コメントエリア](board-detail-design-ch05_v2_0.md)

### 参照ドキュメント

- [board-feature-design-v1_1.md](board-feature-design-v1_1.md) - 掲示板機能の全体仕様
- [harmonet-design-system_v1_0.md](harmonet-design-system_v1_0.md) - HarmoNET Design System
- [01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.md](01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2_0.md) - デザイン哲学
- [プロダクト開発用_機能要件定義書_v1_1.txt](プロダクト開発用_機能要件定義書_v1_1.txt) - 機能要件定義書

---

**Document ID:** HRM-BOARD-DETAIL-CH04  
**Version:** 2.0  
**Created:** 2025-10-29  
**Status:** 承認待ち  
**Author:** Claude (Anthropic)

---

以上
