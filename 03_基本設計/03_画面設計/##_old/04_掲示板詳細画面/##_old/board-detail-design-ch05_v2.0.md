# 掲示板詳細画面 詳細設計書 - 第5章：コメントエリアの詳細設計

**HarmoNet スマートコミュニケーションアプリ**

**文書ID**: HRM-BOARD-DETAIL-CH05  
**バージョン**: 2.0  
**作成日**: 2025-10-29  
**最終更新**: 2025-10-29

---

## 📋 改訂履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| v2.0 | 2025-10-29 | 初版作成（コメントエリアの詳細設計） |

---

## 目次

1. [コメントエリアの概要](#51-コメントエリアの概要)
2. [コメント一覧の表示仕様](#52-コメント一覧の表示仕様)
3. [コメントカードのデザイン](#53-コメントカードのデザイン)
4. [投稿者情報の表示](#54-投稿者情報の表示)
5. [投稿日時の表示](#55-投稿日時の表示)
6. [コメント本文の表示](#56-コメント本文の表示)
7. [翻訳ボタンの実装](#57-翻訳ボタンの実装)
8. [編集・削除機能](#58-編集削除機能)
9. [返信不可投稿での表示](#59-返信不可投稿での表示)
10. [エラーハンドリング](#510-エラーハンドリング)
11. [レスポンシブ対応](#511-レスポンシブ対応)
12. [テスト項目](#512-テスト項目)
13. [CSS実装仕様](#513-css実装仕様)
14. [JavaScript実装仕様](#514-javascript実装仕様)

---

## 5.1 コメントエリアの概要

### 5.1.1 目的と役割

コメントエリアは、投稿に対する住民からの返信・意見・質問を表示するエリアです。以下の目的を持ちます：

- **情報共有の促進**: 投稿に対する追加情報や関連情報の提供
- **質問と回答**: 投稿内容に対する疑問点の解消
- **コミュニティ形成**: 住民間のコミュニケーション促進
- **多様な意見の表示**: 様々な視点からの意見を可視化

### 5.1.2 配置位置

コメントエリアは投稿詳細画面の以下の位置に配置されます：

```
┌─────────────────────────┐
│ ヘッダー領域            │
├─────────────────────────┤
│ 投稿本文エリア          │
├─────────────────────────┤
│ 既読状況エリア          │ ← 回覧板のみ
├─────────────────────────┤
│ ★ コメントエリア ★     │ ← 本章の対象
├─────────────────────────┤
│ コメント入力エリア      │
├─────────────────────────┤
│ フッター領域            │
└─────────────────────────┘
```

### 5.1.3 表示条件

コメントエリアの表示は以下の条件に基づきます：

| 条件 | 表示 |
|------|------|
| 返信可能な投稿 | コメント一覧を表示 |
| 返信不可な投稿（回覧板） | 既存コメントは表示、新規入力欄は非表示 |
| コメント数が0件 | 空状態メッセージを表示 |

### 5.1.4 レイアウト構造

コメントエリアは以下の構造で構成されます：

```html
<section class="comment-area">
  <div class="comment-area__header">
    <h3 class="comment-area__title">コメント（5件）</h3>
  </div>
  <div class="comment-list">
    <!-- コメントカードが繰り返し表示される -->
    <article class="comment-card">...</article>
    <article class="comment-card comment-card--own">...</article>
    ...
  </div>
  <div class="comment-area__footer">
    <button class="comment-load-more">さらに読み込む（残り10件）</button>
  </div>
</section>
```

---

## 5.2 コメント一覧の表示仕様

### 5.2.1 表示順序

**基本ルール**: 投稿日時の昇順（古いコメントが上）

```
[最初のコメント]   投稿日時: 2025-10-20 10:00
[2番目のコメント]  投稿日時: 2025-10-20 14:30
[3番目のコメント]  投稿日時: 2025-10-21 09:15
...
[最新のコメント]   投稿日時: 2025-10-29 16:45
```

**理由**: 会話の流れを自然に追えるようにするため

**Phase 2での拡張**:
- 新着順（降順）
- いいね順（Phase 2で実装予定）
- ユーザー選択可能なソート機能

### 5.2.2 階層制限

**重要な設計決定**: コメントは1階層のみ

```
✅ 許可される構造:
投稿
├─ コメント1
├─ コメント2
└─ コメント3

❌ 禁止される構造:
投稿
├─ コメント1
│   ├─ 返信1-1  ← 不可
│   └─ 返信1-2  ← 不可
└─ コメント2
    └─ 返信2-1  ← 不可
```

**理由**:
- UI複雑化を避ける
- 運用コストを削減
- スマホでの表示・操作を簡潔に保つ

### 5.2.3 ページネーション

#### 初期表示件数

- **スマホ**: 10件
- **タブレット**: 15件
- **デスクトップ**: 20件

#### 追加読み込み

**方式**: 「さらに読み込む」ボタン方式（無限スクロールは採用しない）

```html
<button class="comment-load-more">
  さらに読み込む（残り15件）
</button>
```

**動作フロー**:
1. ボタンをタップ
2. ローディング表示「読み込み中...」
3. 次の10件を読み込み
4. コメントリストの末尾に追加
5. ボタンのラベルを更新「さらに読み込む（残り5件）」
6. 全件表示済みの場合、ボタンを非表示

**理由**:
- ユーザーが読み込みをコントロール可能
- パフォーマンスへの影響を最小化
- 通信量の削減

### 5.2.4 空状態の表示

コメントが0件の場合の表示：

```html
<div class="comment-area__empty">
  <div class="comment-area__empty-icon">💬</div>
  <p class="comment-area__empty-text">
    まだコメントはありません
  </p>
  <p class="comment-area__empty-subtext">
    最初のコメントを投稿してみましょう
  </p>
</div>
```

**デザイン仕様**:
- アイコン: 💬（グレー色、サイズ 48px）
- メインテキスト: フォントサイズ 16px、色 #6B7280
- サブテキスト: フォントサイズ 14px、色 #9CA3AF
- 背景: #F9FAFB
- 内側余白: 48px（上下）、24px（左右）
- 中央揃え

**多言語対応**:
- 日本語: 「まだコメントはありません」
- 英語: 「No comments yet」
- 中国語: 「还没有评论」

---

## 5.3 コメントカードのデザイン

### 5.3.1 カード構造

各コメントは独立したカードとして表示されます：

```html
<article class="comment-card">
  <div class="comment-header">
    <div class="comment-author">
      <img class="comment-avatar" src="..." alt="アバター">
      <span class="comment-author-name">ニックネーム</span>
      <span class="comment-admin-badge">管理者</span>
    </div>
    <time class="comment-timestamp">3分前</time>
  </div>
  
  <div class="comment-body">
    <p class="comment-text">コメント本文...</p>
  </div>
  
  <div class="comment-actions">
    <button class="comment-translate-button">
      <span class="icon">🌐</span>
      <span class="label">翻訳</span>
    </button>
    <button class="comment-menu-button">
      <span class="icon">⋮</span>
    </button>
  </div>
</article>
```

### 5.3.2 デザイン仕様

#### 基本スタイル

```css
.comment-card {
  background-color: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 1rem;
  padding: 24px;
  margin-bottom: 16px;
}
```

#### 自分のコメント

自分が投稿したコメントは視覚的に区別します：

```css
.comment-card--own {
  background-color: #EFF6FF; /* 淡い青色 */
  border-color: #BFDBFE;
}
```

#### ホバー状態（デスクトップ）

```css
.comment-card:hover {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  transition: box-shadow 0.2s ease;
}
```

### 5.3.3 視覚的な区別

| コメント種類 | 背景色 | 枠線色 | 識別マーク |
|-------------|--------|--------|-----------|
| 他人のコメント | #FFFFFF | #E5E7EB | なし |
| 自分のコメント | #EFF6FF | #BFDBFE | 「あなた」ラベル（任意） |
| 管理者のコメント | #FFFFFF | #E5E7EB | 「管理者」バッジ |

---

## 5.4 投稿者情報の表示

### 5.4.1 表示項目

コメント投稿者の情報として以下を表示します：

1. **アバター画像**（必須、デフォルトあり）
2. **ニックネーム**（必須）
3. **管理者バッジ**（管理者の場合のみ）

```html
<div class="comment-author">
  <img class="comment-avatar" src="/avatars/user-123.png" alt="アバター">
  <span class="comment-author-name">田中太郎</span>
  <span class="comment-admin-badge">管理者</span>
</div>
```

### 5.4.2 デザイン仕様

#### ニックネーム

```css
.comment-author-name {
  font-size: 14px;
  font-weight: 500;
  color: #1F2937;
  margin-left: 8px;
}
```

#### 管理者バッジ

```css
.comment-admin-badge {
  display: inline-block;
  background-color: #DBEAFE;
  color: #1E40AF;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
  margin-left: 8px;
  text-transform: uppercase;
}
```

**多言語対応**:
- 日本語: 「管理者」
- 英語: 「ADMIN」
- 中国語: 「管理员」

### 5.4.3 アバター仕様

#### サイズと形状

```css
.comment-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%; /* 円形 */
  object-fit: cover;
  border: 2px solid #E5E7EB;
}
```

#### デフォルトアイコン

アバター画像が設定されていない場合のデフォルト表示：

```html
<div class="comment-avatar comment-avatar--default">
  <svg><!-- ユーザーアイコンSVG --></svg>
</div>
```

**デフォルトアイコンの要件**:
- 文化中立なデザイン（性別・人種を連想させない）
- シンプルなシルエット
- 背景色: #E5E7EB
- アイコン色: #9CA3AF

---

## 5.5 投稿日時の表示

### 5.5.1 表示形式

コメントの投稿日時は、経過時間に応じて表示形式を切り替えます：

| 経過時間 | 表示形式 | 例 |
|---------|---------|-----|
| 1分未満 | 「たった今」 | たった今 |
| 1分〜59分 | 「X分前」 | 3分前 |
| 1時間〜23時間 | 「X時間前」 | 2時間前 |
| 1日〜6日 | 「X日前」 | 3日前 |
| 7日以上 | 「YYYY年MM月DD日 HH:MM」 | 2025年10月20日 10:30 |

### 5.5.2 多言語対応

#### 日本語

```javascript
const jaRelativeTime = {
  justNow: 'たった今',
  minutesAgo: (n) => `${n}分前`,
  hoursAgo: (n) => `${n}時間前`,
  daysAgo: (n) => `${n}日前`,
};
```

#### 英語

```javascript
const enRelativeTime = {
  justNow: 'Just now',
  minutesAgo: (n) => `${n} ${n === 1 ? 'minute' : 'minutes'} ago`,
  hoursAgo: (n) => `${n} ${n === 1 ? 'hour' : 'hours'} ago`,
  daysAgo: (n) => `${n} ${n === 1 ? 'day' : 'days'} ago`,
};
```

#### 中国語

```javascript
const zhRelativeTime = {
  justNow: '刚刚',
  minutesAgo: (n) => `${n}分钟前`,
  hoursAgo: (n) => `${n}小时前`,
  daysAgo: (n) => `${n}天前`,
};
```

### 5.5.3 デザイン仕様

```css
.comment-timestamp {
  font-size: 12px;
  color: #9CA3AF;
  font-weight: 400;
}
```

### 5.5.4 ホバー時の詳細表示

デスクトップでは、タイムスタンプにホバーすると完全な日時を表示：

```html
<time class="comment-timestamp" 
      datetime="2025-10-29T10:30:00+09:00"
      title="2025年10月29日 10:30">
  3分前
</time>
```

---

## 5.6 コメント本文の表示

### 5.6.1 テキスト表示

#### 基本仕様

- **最大文字数**: 500文字
- **改行対応**: 改行を保持して表示
- **URLの自動リンク化**: URLを検出して自動的にリンク化

```css
.comment-text {
  font-size: 14px;
  line-height: 1.6;
  color: #1F2937;
  word-wrap: break-word;
  white-space: pre-wrap;
}
```

#### URLリンク化の仕様

```javascript
// URLを検出してリンク化
function linkify(text) {
  const urlPattern = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlPattern, '<a href="$1" target="_blank" rel="noopener noreferrer">$1</a>');
}
```

```css
.comment-text a {
  color: #2563EB;
  text-decoration: underline;
}

.comment-text a:hover {
  color: #1D4ED8;
}
```

### 5.6.2 長文の扱い

コメントが3行（約120文字）を超える場合、「続きを読む」機能を実装します：

#### 初期状態（折りたたみ）

```html
<div class="comment-body">
  <p class="comment-text comment-text--collapsed">
    コメント本文の最初の3行分が表示されます...
  </p>
  <button class="comment-expand-button">続きを読む</button>
</div>
```

```css
.comment-text--collapsed {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```

#### 展開状態

```html
<div class="comment-body">
  <p class="comment-text comment-text--expanded">
    コメント本文の全文が表示されます...
  </p>
  <button class="comment-collapse-button">閉じる</button>
</div>
```

#### ボタンのデザイン

```css
.comment-expand-button,
.comment-collapse-button {
  background: none;
  border: none;
  color: #2563EB;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  padding: 4px 0;
  margin-top: 8px;
}

.comment-expand-button:hover,
.comment-collapse-button:hover {
  text-decoration: underline;
}
```

**多言語対応**:
- 日本語: 「続きを読む」/ 「閉じる」
- 英語: 「Read more」/ 「Show less」
- 中国語: 「阅读更多」/ 「收起」

---

## 5.7 翻訳ボタンの実装

### 5.7.1 表示位置

翻訳ボタンはコメント本文の右下に配置します：

```html
<div class="comment-actions">
  <button class="comment-translate-button">
    <span class="comment-translate-icon">🌐</span>
    <span class="comment-translate-label">翻訳</span>
  </button>
</div>
```

### 5.7.2 ボタンデザイン

```css
.comment-translate-button {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #2563EB;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background-color 0.2s ease;
}

.comment-translate-button:hover {
  background-color: #EFF6FF;
}

.comment-translate-icon {
  font-size: 16px;
}
```

### 5.7.3 翻訳動作

#### 翻訳実行フロー

1. **翻訳ボタンをタップ**
2. **ローディング状態を表示**
   ```html
   <button class="comment-translate-button comment-translate-button--loading">
     <span class="comment-translate-spinner"></span>
     <span class="comment-translate-label">翻訳中...</span>
   </button>
   ```
3. **Google Translation APIにリクエスト**
4. **翻訳結果を受信**
5. **コメント本文を翻訳テキストに置き換え**
6. **ボタンラベルを「原文に戻す」に変更**

#### 翻訳後の状態

```html
<div class="comment-body">
  <p class="comment-text comment-text--translated">
    This is the translated comment text...
  </p>
  <div class="comment-translate-info">
    <span class="comment-translate-badge">Translated</span>
    <span class="comment-original-lang">原文: 日本語</span>
  </div>
</div>

<div class="comment-actions">
  <button class="comment-translate-button comment-translate-button--active">
    <span class="comment-translate-icon">🌐</span>
    <span class="comment-translate-label">原文に戻す</span>
  </button>
</div>
```

### 5.7.4 翻訳表示のデザイン

#### 翻訳済みバッジ

```css
.comment-translate-badge {
  display: inline-block;
  background-color: #DBEAFE;
  color: #1E40AF;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  margin-right: 8px;
}
```

#### 元の言語表示

```css
.comment-original-lang {
  font-size: 12px;
  color: #6B7280;
}
```

#### 翻訳情報エリア

```css
.comment-translate-info {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #E5E7EB;
}
```

### 5.7.5 多言語対応

| ボタンラベル | 日本語 | 英語 | 中国語 |
|-------------|--------|------|--------|
| 翻訳前 | 翻訳 | Translate | 翻译 |
| 翻訳中 | 翻訳中... | Translating... | 翻译中... |
| 翻訳後 | 原文に戻す | Show original | 显示原文 |

| 表示要素 | 日本語 | 英語 | 中国語 |
|---------|--------|------|--------|
| 翻訳済みバッジ | 翻訳済み | Translated | 已翻译 |
| 元の言語 | 原文: 日本語 | Original: Japanese | 原文: 日语 |

---

## 5.8 編集・削除機能

### 5.8.1 表示条件

編集・削除ボタンの表示条件：

| ユーザー種別 | 編集 | 削除 | 通報 |
|-------------|------|------|------|
| コメント投稿者本人 | ✅ | ✅ | ❌ |
| 他のユーザー | ❌ | ❌ | ✅ |
| 管理者 | ❌* | ✅ | ❌ |

*管理者は他人のコメントを編集できません（改ざん防止）

### 5.8.2 三点メニュー

アクションボタンは三点メニューに集約します：

```html
<div class="comment-actions">
  <button class="comment-menu-button" aria-label="メニューを開く">
    <span class="icon">⋮</span>
  </button>
</div>

<!-- メニュー展開時 -->
<div class="comment-menu">
  <button class="comment-menu-item">
    <span class="icon">✏️</span>
    <span class="label">編集</span>
  </button>
  <button class="comment-menu-item comment-menu-item--danger">
    <span class="icon">🗑️</span>
    <span class="label">削除</span>
  </button>
  <button class="comment-menu-item">
    <span class="icon">🚩</span>
    <span class="label">通報</span>
  </button>
</div>
```

#### メニューのデザイン

```css
.comment-menu {
  position: absolute;
  right: 0;
  top: 100%;
  background-color: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  min-width: 160px;
  z-index: 10;
}

.comment-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 12px 16px;
  background: none;
  border: none;
  font-size: 14px;
  color: #1F2937;
  text-align: left;
  cursor: pointer;
}

.comment-menu-item:hover {
  background-color: #F9FAFB;
}

.comment-menu-item--danger {
  color: #DC2626;
}

.comment-menu-item--danger:hover {
  background-color: #FEE2E2;
}
```

### 5.8.3 編集機能

#### インライン編集モード

編集ボタンをクリックすると、その場で編集モードに切り替わります：

```html
<div class="comment-body comment-body--editing">
  <textarea class="comment-edit-input" maxlength="500">
    編集中のコメント本文...
  </textarea>
  <div class="comment-edit-actions">
    <button class="comment-edit-save">保存</button>
    <button class="comment-edit-cancel">キャンセル</button>
  </div>
  <div class="comment-edit-counter">
    <span class="current">120</span> / 500文字
  </div>
</div>
```

#### 編集入力欄のデザイン

```css
.comment-edit-input {
  width: 100%;
  min-height: 80px;
  padding: 12px;
  border: 2px solid #2563EB;
  border-radius: 0.5rem;
  font-size: 14px;
  line-height: 1.6;
  resize: vertical;
}

.comment-edit-input:focus {
  outline: none;
  border-color: #1D4ED8;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}
```

#### 編集アクションボタン

```css
.comment-edit-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.comment-edit-save {
  background-color: #2563EB;
  color: #FFFFFF;
  border: none;
  padding: 8px 16px;
  border-radius: 0.5rem;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.comment-edit-save:hover {
  background-color: #1D4ED8;
}

.comment-edit-cancel {
  background-color: #F9FAFB;
  color: #6B7280;
  border: 1px solid #E5E7EB;
  padding: 8px 16px;
  border-radius: 0.5rem;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.comment-edit-cancel:hover {
  background-color: #F3F4F6;
}
```

#### 編集完了フロー

1. **保存ボタンをクリック**
2. **バリデーション実行**（文字数チェック）
3. **APIにPUTリクエスト送信**
4. **ローディング表示**
5. **更新成功後、編集モードを終了**
6. **トースト通知「コメントを更新しました」を表示**
7. **「編集済み」マークを表示**

```html
<div class="comment-header">
  <time class="comment-timestamp">3分前</time>
  <span class="comment-edited-badge">編集済み</span>
</div>
```

```css
.comment-edited-badge {
  font-size: 11px;
  color: #9CA3AF;
  margin-left: 8px;
}
```

### 5.8.4 削除機能

#### 確認ダイアログ

削除ボタンをクリックすると、確認ダイアログを表示します：

```html
<div class="modal-overlay">
  <div class="modal modal--small">
    <div class="modal-header">
      <h3 class="modal-title">コメントの削除</h3>
    </div>
    <div class="modal-body">
      <p>このコメントを削除してもよろしいですか？</p>
      <p class="modal-note">この操作は取り消せません。</p>
    </div>
    <div class="modal-footer">
      <button class="modal-button modal-button--cancel">キャンセル</button>
      <button class="modal-button modal-button--danger">削除する</button>
    </div>
  </div>
</div>
```

#### 削除実行フロー

1. **「削除する」ボタンをクリック**
2. **APIにDELETEリクエスト送信**
3. **ローディング表示**
4. **削除成功後、ダイアログを閉じる**
5. **該当コメントをDOMから削除（フェードアウトアニメーション）**
6. **コメント件数を更新**
7. **トースト通知「コメントを削除しました」を表示**

#### トースト通知のデザイン

```html
<div class="toast toast--success">
  <span class="toast-icon">✓</span>
  <span class="toast-message">コメントを削除しました</span>
</div>
```

```css
.toast {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background-color: #10B981;
  color: #FFFFFF;
  padding: 12px 24px;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 500;
  z-index: 1000;
  animation: slideUp 0.3s ease;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translate(-50%, 20px);
  }
  to {
    opacity: 1;
    transform: translate(-50%, 0);
  }
}
```

---

## 5.9 返信不可投稿での表示

### 5.9.1 表示条件

以下の投稿では、コメント入力欄を非表示にします：

- **回覧板**（返信不可フラグがtrueの投稿）
- **管理者が返信を無効化した投稿**

### 5.9.2 表示内容

#### 既存コメントの表示

返信不可の投稿でも、既存のコメントは表示されます：

```html
<section class="comment-area comment-area--readonly">
  <div class="comment-area__header">
    <h3 class="comment-area__title">コメント（3件）</h3>
  </div>
  <div class="comment-list">
    <!-- 既存のコメントが表示される -->
    <article class="comment-card">...</article>
    <article class="comment-card">...</article>
    <article class="comment-card">...</article>
  </div>
  <div class="comment-area__notice">
    <div class="comment-area__notice-icon">🔒</div>
    <p class="comment-area__notice-text">
      この投稿には返信できません
    </p>
  </div>
</section>
```

#### メッセージ表示エリア

```css
.comment-area__notice {
  background-color: #F9FAFB;
  border: 1px solid #E5E7EB;
  border-radius: 0.5rem;
  padding: 16px;
  text-align: center;
  margin-top: 16px;
}

.comment-area__notice-icon {
  font-size: 24px;
  margin-bottom: 8px;
}

.comment-area__notice-text {
  font-size: 14px;
  color: #6B7280;
  margin: 0;
}
```

### 5.9.3 多言語対応

| 言語 | メッセージ |
|------|-----------|
| 日本語 | この投稿には返信できません |
| 英語 | Comments are disabled for this post |
| 中国語 | 此帖子已禁用评论 |

---

## 5.10 エラーハンドリング

### 5.10.1 コメント読み込みエラー

#### エラー画面

```html
<div class="comment-area__error">
  <div class="comment-area__error-icon">⚠️</div>
  <p class="comment-area__error-text">
    コメントの読み込みに失敗しました
  </p>
  <button class="comment-area__retry-button">
    再試行
  </button>
</div>
```

#### デザイン仕様

```css
.comment-area__error {
  background-color: #FEE2E2;
  border: 1px solid #FCA5A5;
  border-radius: 0.5rem;
  padding: 24px;
  text-align: center;
}

.comment-area__error-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.comment-area__error-text {
  font-size: 14px;
  color: #991B1B;
  margin-bottom: 16px;
}

.comment-area__retry-button {
  background-color: #DC2626;
  color: #FFFFFF;
  border: none;
  padding: 8px 16px;
  border-radius: 0.5rem;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.comment-area__retry-button:hover {
  background-color: #B91C1C;
}
```

### 5.10.2 翻訳エラー

#### エラー表示

翻訳に失敗した場合、ボタンの下にエラーメッセージを表示：

```html
<div class="comment-actions">
  <button class="comment-translate-button comment-translate-button--error">
    <span class="comment-translate-icon">🌐</span>
    <span class="comment-translate-label">翻訳</span>
  </button>
</div>
<div class="comment-translate-error">
  <span class="comment-translate-error-icon">⚠️</span>
  <span class="comment-translate-error-text">
    翻訳に失敗しました
  </span>
  <button class="comment-translate-retry">もう一度試す</button>
</div>
```

```css
.comment-translate-error {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding: 8px 12px;
  background-color: #FEE2E2;
  border-radius: 0.5rem;
  font-size: 12px;
}

.comment-translate-error-icon {
  font-size: 16px;
}

.comment-translate-error-text {
  color: #991B1B;
  flex: 1;
}

.comment-translate-retry {
  background: none;
  border: none;
  color: #DC2626;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  text-decoration: underline;
}
```

### 5.10.3 編集・削除エラー

#### エラー表示

編集や削除に失敗した場合、トースト通知でエラーを表示：

```html
<div class="toast toast--error">
  <span class="toast-icon">✕</span>
  <span class="toast-message">コメントの更新に失敗しました</span>
</div>
```

```css
.toast--error {
  background-color: #DC2626;
}
```

#### エラーメッセージ一覧

| エラー種類 | 日本語 | 英語 | 中国語 |
|-----------|--------|------|--------|
| 編集失敗 | コメントの更新に失敗しました | Failed to update comment | 更新评论失败 |
| 削除失敗 | コメントの削除に失敗しました | Failed to delete comment | 删除评论失败 |
| ネットワークエラー | ネットワーク接続を確認してください | Check your network connection | 请检查网络连接 |
| 権限エラー | この操作を実行する権限がありません | You don't have permission | 您没有权限 |

---

## 5.11 レスポンシブ対応

### 5.11.1 スマホ（〜767px）

#### レイアウト調整

```css
@media (max-width: 767px) {
  .comment-card {
    padding: 16px;
    border-radius: 0.75rem;
    margin-bottom: 12px;
  }
  
  .comment-avatar {
    width: 28px;
    height: 28px;
  }
  
  .comment-author-name {
    font-size: 13px;
  }
  
  .comment-timestamp {
    font-size: 11px;
  }
  
  .comment-text {
    font-size: 14px;
  }
  
  .comment-actions {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}
```

#### タッチ領域の最適化

```css
@media (max-width: 767px) {
  .comment-menu-button,
  .comment-translate-button {
    min-height: 44px;
    min-width: 44px;
  }
  
  .comment-menu-item {
    padding: 16px;
    font-size: 15px;
  }
}
```

### 5.11.2 タブレット（768px〜1023px）

```css
@media (min-width: 768px) and (max-width: 1023px) {
  .comment-card {
    padding: 20px;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }
  
  .comment-avatar {
    width: 32px;
    height: 32px;
  }
  
  .comment-text {
    font-size: 14px;
  }
}
```

### 5.11.3 デスクトップ（1024px〜）

```css
@media (min-width: 1024px) {
  .comment-card {
    padding: 24px;
    max-width: 800px;
    margin-left: auto;
    margin-right: auto;
  }
  
  .comment-avatar {
    width: 36px;
    height: 36px;
  }
  
  .comment-text {
    font-size: 14px;
  }
  
  /* ホバー効果を有効化 */
  .comment-card:hover {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }
}
```

---

## 5.12 テスト項目

### 5.12.1 表示テスト

| テスト項目 | 確認内容 | 期待結果 |
|-----------|---------|---------|
| コメント一覧表示 | コメントが投稿日時の昇順で表示される | ✓ 古いコメントが上に表示される |
| 空状態表示 | コメントが0件の場合 | ✓ 空状態メッセージが表示される |
| 自分のコメント識別 | 自分が投稿したコメント | ✓ 淡い青色の背景で表示される |
| 管理者バッジ | 管理者のコメント | ✓ 「管理者」バッジが表示される |
| アバター表示 | アバター画像が設定されていない場合 | ✓ デフォルトアイコンが表示される |
| 投稿日時表示 | 経過時間に応じた表示 | ✓ 「3分前」「2日前」などが表示される |
| 長文コメント | 3行を超えるコメント | ✓ 「続きを読む」ボタンが表示される |
| URLリンク化 | コメント本文にURLが含まれる | ✓ URLが自動的にリンク化される |
| 返信不可投稿 | 回覧板などの返信不可投稿 | ✓ 「この投稿には返信できません」メッセージが表示される |

### 5.12.2 機能テスト

| テスト項目 | 操作内容 | 期待結果 |
|-----------|---------|---------|
| ページネーション | 「さらに読み込む」ボタンをタップ | ✓ 次の10件が読み込まれる |
| コメント展開 | 「続きを読む」ボタンをタップ | ✓ コメント全文が表示される |
| コメント折りたたみ | 「閉じる」ボタンをタップ | ✓ 最初の3行のみ表示に戻る |
| 翻訳実行 | 翻訳ボタンをタップ | ✓ コメントが翻訳される |
| 翻訳解除 | 「原文に戻す」ボタンをタップ | ✓ 元の言語に戻る |
| 編集モード | 編集ボタンをタップ | ✓ インライン編集モードに切り替わる |
| 編集保存 | 編集後、保存ボタンをタップ | ✓ コメントが更新される |
| 編集キャンセル | 編集中、キャンセルボタンをタップ | ✓ 編集前の状態に戻る |
| 削除確認 | 削除ボタンをタップ | ✓ 確認ダイアログが表示される |
| 削除実行 | 確認ダイアログで「削除する」をタップ | ✓ コメントが削除される |
| 削除キャンセル | 確認ダイアログで「キャンセル」をタップ | ✓ ダイアログが閉じ、削除されない |

### 5.12.3 エラーハンドリングテスト

| テスト項目 | 条件 | 期待結果 |
|-----------|------|---------|
| 読み込みエラー | APIエラー発生時 | ✓ エラーメッセージと再試行ボタンが表示される |
| 翻訳エラー | 翻訳APIエラー発生時 | ✓ エラーメッセージと再試行ボタンが表示される |
| 編集エラー | 更新APIエラー発生時 | ✓ エラートースト通知が表示される |
| 削除エラー | 削除APIエラー発生時 | ✓ エラートースト通知が表示される |
| ネットワークエラー | オフライン時 | ✓ ネットワークエラーメッセージが表示される |

### 5.12.4 レスポンシブテスト

| デバイス | 画面幅 | 確認内容 |
|---------|--------|---------|
| スマホ（縦） | 375px | カード幅100%、余白16px、フォント14px |
| スマホ（横） | 667px | カード最大幅なし、適切な余白 |
| タブレット（縦） | 768px | カード最大幅600px、中央配置 |
| タブレット（横） | 1024px | カード最大幅800px、中央配置 |
| デスクトップ | 1440px | カード最大幅800px、ホバー効果あり |

### 5.12.5 多言語テスト

| 言語 | 確認内容 |
|------|---------|
| 日本語 | すべてのラベル・メッセージが日本語で表示される |
| 英語 | すべてのラベル・メッセージが英語で表示される |
| 中国語 | すべてのラベル・メッセージが中国語で表示される |

---

## 5.13 CSS実装仕様

### 5.13.1 必要なCSSクラス

#### コメントエリア全体

```css
.comment-area { /* コメントエリア全体のコンテナ */ }
.comment-area--readonly { /* 返信不可の投稿 */ }

.comment-area__header { /* ヘッダーエリア */ }
.comment-area__title { /* 「コメント(X件)」タイトル */ }

.comment-area__footer { /* フッターエリア */ }
.comment-area__empty { /* 空状態エリア */ }
.comment-area__empty-icon { /* 空状態アイコン */ }
.comment-area__empty-text { /* 空状態メインテキスト */ }
.comment-area__empty-subtext { /* 空状態サブテキスト */ }

.comment-area__notice { /* 返信不可メッセージエリア */ }
.comment-area__notice-icon { /* 返信不可アイコン */ }
.comment-area__notice-text { /* 返信不可テキスト */ }

.comment-area__error { /* エラー表示エリア */ }
.comment-area__error-icon { /* エラーアイコン */ }
.comment-area__error-text { /* エラーテキスト */ }
.comment-area__retry-button { /* 再試行ボタン */ }
```

#### コメント一覧

```css
.comment-list { /* コメント一覧コンテナ */ }

.comment-load-more { /* さらに読み込むボタン */ }
.comment-load-more--loading { /* 読み込み中状態 */ }
```

#### コメントカード

```css
.comment-card { /* コメントカードのベース */ }
.comment-card--own { /* 自分のコメント */ }

.comment-header { /* コメントヘッダー */ }

.comment-author { /* 投稿者情報エリア */ }
.comment-avatar { /* アバター画像 */ }
.comment-avatar--default { /* デフォルトアバター */ }
.comment-author-name { /* 投稿者名 */ }
.comment-admin-badge { /* 管理者バッジ */ }

.comment-timestamp { /* 投稿日時 */ }
.comment-edited-badge { /* 編集済みバッジ */ }

.comment-body { /* コメント本文エリア */ }
.comment-body--editing { /* 編集モード */ }

.comment-text { /* コメント本文テキスト */ }
.comment-text--collapsed { /* 折りたたみ状態 */ }
.comment-text--expanded { /* 展開状態 */ }
.comment-text--translated { /* 翻訳済み状態 */ }

.comment-expand-button { /* 続きを読むボタン */ }
.comment-collapse-button { /* 閉じるボタン */ }

.comment-translate-info { /* 翻訳情報エリア */ }
.comment-translate-badge { /* 翻訳済みバッジ */ }
.comment-original-lang { /* 元の言語表示 */ }
```

#### コメントアクション

```css
.comment-actions { /* アクションボタン群 */ }

.comment-translate-button { /* 翻訳ボタン */ }
.comment-translate-button--loading { /* 翻訳中状態 */ }
.comment-translate-button--active { /* 翻訳済み状態 */ }
.comment-translate-button--error { /* エラー状態 */ }
.comment-translate-icon { /* 翻訳アイコン */ }
.comment-translate-label { /* 翻訳ラベル */ }
.comment-translate-spinner { /* ローディングスピナー */ }

.comment-translate-error { /* 翻訳エラー表示 */ }
.comment-translate-error-icon { /* エラーアイコン */ }
.comment-translate-error-text { /* エラーテキスト */ }
.comment-translate-retry { /* 再試行ボタン */ }

.comment-menu-button { /* 三点メニューボタン */ }
.comment-menu { /* メニューパネル */ }
.comment-menu-item { /* メニュー項目 */ }
.comment-menu-item--danger { /* 削除ボタン（危険アクション） */ }
```

#### 編集機能

```css
.comment-edit-input { /* 編集用テキストエリア */ }
.comment-edit-actions { /* 編集アクションボタン群 */ }
.comment-edit-save { /* 保存ボタン */ }
.comment-edit-cancel { /* キャンセルボタン */ }
.comment-edit-counter { /* 文字数カウンター */ }
```

#### トースト通知

```css
.toast { /* トースト通知ベース */ }
.toast--success { /* 成功通知 */ }
.toast--error { /* エラー通知 */ }
.toast-icon { /* トーストアイコン */ }
.toast-message { /* トーストメッセージ */ }
```

### 5.13.2 カラーパレット（HarmoNet Design System準拠）

```css
:root {
  /* 背景色 */
  --bg-base: #F9FAFB;
  --bg-card: #FFFFFF;
  --bg-own-comment: #EFF6FF;
  
  /* 枠線 */
  --border-default: #E5E7EB;
  --border-own-comment: #BFDBFE;
  
  /* 文字色 */
  --text-primary: #1F2937;
  --text-secondary: #6B7280;
  --text-tertiary: #9CA3AF;
  
  /* アクション色 */
  --color-blue: #2563EB;
  --color-blue-hover: #1D4ED8;
  --color-blue-light: #DBEAFE;
  
  /* 成功色 */
  --color-green: #10B981;
  
  /* エラー色 */
  --color-red: #DC2626;
  --color-red-hover: #B91C1C;
  --color-red-light: #FEE2E2;
  
  /* シャドウ */
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}
```

---

## 5.14 JavaScript実装仕様

### 5.14.1 必要な関数

#### 初期化

```javascript
/**
 * コメントエリアの初期化
 * @param {string} postId - 投稿ID
 */
function initCommentArea(postId) {
  loadComments(postId);
  setupEventListeners();
}
```

#### コメント読み込み

```javascript
/**
 * コメント一覧を読み込む
 * @param {string} postId - 投稿ID
 * @param {number} offset - オフセット（ページネーション用）
 * @param {number} limit - 取得件数
 * @returns {Promise<Array>}
 */
async function loadComments(postId, offset = 0, limit = 10) {
  try {
    const response = await fetch(`/api/posts/${postId}/comments?offset=${offset}&limit=${limit}`);
    const data = await response.json();
    return data.comments;
  } catch (error) {
    console.error('Failed to load comments:', error);
    showError('コメントの読み込みに失敗しました');
  }
}
```

#### コメント表示

```javascript
/**
 * コメントを表示する
 * @param {Object} comment - コメントデータ
 * @returns {HTMLElement}
 */
function renderComment(comment) {
  const isOwn = comment.authorId === currentUserId;
  const isAdmin = comment.author.isAdmin;
  
  const card = document.createElement('article');
  card.className = `comment-card ${isOwn ? 'comment-card--own' : ''}`;
  card.dataset.commentId = comment.id;
  
  card.innerHTML = `
    <div class="comment-header">
      <div class="comment-author">
        <img class="comment-avatar" src="${comment.author.avatar}" alt="アバター">
        <span class="comment-author-name">${comment.author.nickname}</span>
        ${isAdmin ? '<span class="comment-admin-badge">管理者</span>' : ''}
      </div>
      <time class="comment-timestamp" datetime="${comment.createdAt}">
        ${formatRelativeTime(comment.createdAt)}
      </time>
    </div>
    <div class="comment-body">
      <p class="comment-text">${linkify(comment.text)}</p>
    </div>
    <div class="comment-actions">
      <button class="comment-translate-button" data-comment-id="${comment.id}">
        <span class="comment-translate-icon">🌐</span>
        <span class="comment-translate-label">翻訳</span>
      </button>
      ${renderCommentMenu(comment, isOwn)}
    </div>
  `;
  
  return card;
}
```

#### 翻訳処理

```javascript
/**
 * コメントを翻訳する
 * @param {string} commentId - コメントID
 * @param {string} targetLang - ターゲット言語（ja, en, zh）
 */
async function translateComment(commentId, targetLang) {
  const button = document.querySelector(`[data-comment-id="${commentId}"]`);
  const textElement = button.closest('.comment-card').querySelector('.comment-text');
  
  // 既に翻訳済みの場合は元に戻す
  if (button.classList.contains('comment-translate-button--active')) {
    textElement.textContent = textElement.dataset.originalText;
    button.classList.remove('comment-translate-button--active');
    button.querySelector('.comment-translate-label').textContent = '翻訳';
    return;
  }
  
  // ローディング状態
  button.classList.add('comment-translate-button--loading');
  button.querySelector('.comment-translate-label').textContent = '翻訳中...';
  
  try {
    const response = await fetch(`/api/translate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: textElement.textContent,
        targetLang: targetLang
      })
    });
    
    const data = await response.json();
    
    // 元のテキストを保存
    textElement.dataset.originalText = textElement.textContent;
    
    // 翻訳結果を表示
    textElement.textContent = data.translatedText;
    
    // ボタン状態を更新
    button.classList.remove('comment-translate-button--loading');
    button.classList.add('comment-translate-button--active');
    button.querySelector('.comment-translate-label').textContent = '原文に戻す';
    
  } catch (error) {
    console.error('Translation failed:', error);
    showTranslationError(button);
  }
}
```

#### 編集処理

```javascript
/**
 * コメントを編集モードにする
 * @param {string} commentId - コメントID
 */
function editComment(commentId) {
  const card = document.querySelector(`[data-comment-id="${commentId}"]`);
  const body = card.querySelector('.comment-body');
  const text = card.querySelector('.comment-text').textContent;
  
  body.innerHTML = `
    <textarea class="comment-edit-input" maxlength="500">${text}</textarea>
    <div class="comment-edit-actions">
      <button class="comment-edit-save" data-comment-id="${commentId}">保存</button>
      <button class="comment-edit-cancel">キャンセル</button>
    </div>
    <div class="comment-edit-counter">
      <span class="current">${text.length}</span> / 500文字
    </div>
  `;
  
  body.classList.add('comment-body--editing');
  
  // イベントリスナーを設定
  body.querySelector('.comment-edit-save').addEventListener('click', saveComment);
  body.querySelector('.comment-edit-cancel').addEventListener('click', cancelEdit);
  body.querySelector('.comment-edit-input').addEventListener('input', updateCharCounter);
}

/**
 * コメントを保存する
 * @param {string} commentId - コメントID
 * @param {string} newText - 新しいテキスト
 */
async function saveComment(commentId, newText) {
  try {
    const response = await fetch(`/api/comments/${commentId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: newText })
    });
    
    if (response.ok) {
      showToast('コメントを更新しました', 'success');
      // コメントを再読み込み
      reloadComment(commentId);
    }
  } catch (error) {
    console.error('Failed to update comment:', error);
    showToast('コメントの更新に失敗しました', 'error');
  }
}
```

#### 削除処理

```javascript
/**
 * コメント削除の確認ダイアログを表示
 * @param {string} commentId - コメントID
 */
function confirmDeleteComment(commentId) {
  showModal({
    title: 'コメントの削除',
    message: 'このコメントを削除してもよろしいですか？',
    note: 'この操作は取り消せません。',
    confirmText: '削除する',
    confirmClass: 'modal-button--danger',
    onConfirm: () => deleteComment(commentId)
  });
}

/**
 * コメントを削除する
 * @param {string} commentId - コメントID
 */
async function deleteComment(commentId) {
  try {
    const response = await fetch(`/api/comments/${commentId}`, {
      method: 'DELETE'
    });
    
    if (response.ok) {
      // DOMから削除（フェードアウトアニメーション）
      const card = document.querySelector(`[data-comment-id="${commentId}"]`);
      card.style.animation = 'fadeOut 0.3s ease';
      
      setTimeout(() => {
        card.remove();
        updateCommentCount(-1);
      }, 300);
      
      showToast('コメントを削除しました', 'success');
    }
  } catch (error) {
    console.error('Failed to delete comment:', error);
    showToast('コメントの削除に失敗しました', 'error');
  }
}
```

#### ユーティリティ関数

```javascript
/**
 * 相対時間を表示する
 * @param {string} datetime - ISO 8601形式の日時
 * @returns {string}
 */
function formatRelativeTime(datetime) {
  const now = new Date();
  const past = new Date(datetime);
  const diff = now - past;
  
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);
  
  if (minutes < 1) return 'たった今';
  if (minutes < 60) return `${minutes}分前`;
  if (hours < 24) return `${hours}時間前`;
  if (days < 7) return `${days}日前`;
  
  // 7日以上前は絶対時間
  return formatDateTime(datetime);
}

/**
 * URLを自動リンク化する
 * @param {string} text - テキスト
 * @returns {string}
 */
function linkify(text) {
  const urlPattern = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlPattern, '<a href="$1" target="_blank" rel="noopener noreferrer">$1</a>');
}

/**
 * トースト通知を表示する
 * @param {string} message - メッセージ
 * @param {string} type - 'success' | 'error'
 */
function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = `toast toast--${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${type === 'success' ? '✓' : '✕'}</span>
    <span class="toast-message">${message}</span>
  `;
  
  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.remove();
  }, 3000);
}
```

### 5.14.2 イベントハンドラ

```javascript
/**
 * イベントリスナーを設定する
 */
function setupEventListeners() {
  // 翻訳ボタン
  document.addEventListener('click', (e) => {
    if (e.target.closest('.comment-translate-button')) {
      const button = e.target.closest('.comment-translate-button');
      const commentId = button.dataset.commentId;
      const targetLang = getCurrentLanguage();
      translateComment(commentId, targetLang);
    }
  });
  
  // 三点メニュー
  document.addEventListener('click', (e) => {
    if (e.target.closest('.comment-menu-button')) {
      toggleCommentMenu(e.target.closest('.comment-menu-button'));
    }
  });
  
  // さらに読み込むボタン
  document.addEventListener('click', (e) => {
    if (e.target.closest('.comment-load-more')) {
      loadMoreComments();
    }
  });
  
  // 続きを読むボタン
  document.addEventListener('click', (e) => {
    if (e.target.closest('.comment-expand-button')) {
      expandComment(e.target.closest('.comment-card'));
    }
  });
  
  // 閉じるボタン
  document.addEventListener('click', (e) => {
    if (e.target.closest('.comment-collapse-button')) {
      collapseComment(e.target.closest('.comment-card'));
    }
  });
}
```

---

## 総括

本章では、掲示板詳細画面のコメントエリアの詳細設計を定義しました。以下の重要ポイントを確実に実装してください：

### 重要ポイント

1. **1階層のみのコメント構造**: ネストされた返信は実装しない
2. **自分のコメントの視覚的識別**: 淡い青色の背景で明確に区別
3. **多言語対応**: 日本語・英語・中国語の完全対応
4. **翻訳機能**: コメントごとに翻訳可能
5. **返信不可投稿の扱い**: 既存コメント表示、新規入力不可
6. **HarmoNet Design System準拠**: カラー・フォント・余白の統一
7. **レスポンシブ対応**: スマホ・タブレット・デスクトップで最適表示
8. **アクセシビリティ**: タッチ領域44px以上、コントラスト比確保

### 次章への接続

- **第6章: コメント入力エリア** - 新規コメント投稿機能
- **第7章: フッター領域** - 固定ナビゲーション
- **第8章: 画面遷移とインタラクション** - 全体フロー

---

**文書ID**: HRM-BOARD-DETAIL-CH05  
**バージョン**: 2.0  
**作成日**: 2025-10-29  
**承認**: TKD + Claude

---

以上
