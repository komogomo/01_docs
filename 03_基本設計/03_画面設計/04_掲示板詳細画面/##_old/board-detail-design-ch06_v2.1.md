# 第6章 コメント入力エリア（Comment Input Area）

**セキュレアシティ スマートコミュニケーションアプリ - 掲示板詳細設計書**

**文書ID**: SEC-APP-BOARD-DETAIL-CH06  
**バージョン**: v2.0  
**最終更新**: 2025年10月29日

---

## 📝 改訂履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| v1.0 | 2025年10月 | 初版作成（基本仕様、レイアウト、バリデーション） |
| v2.0 | 2025年10月29日 | AIモデレーション連携の詳細追加、HarmoNET Design System v1.0準拠に更新、テスト要件を拡充 |

---

## 目次

1. [概要](#1-概要)
2. [基本仕様](#2-基本仕様)
3. [レイアウト設計](#3-レイアウト設計)
4. [UIコンポーネント](#4-uiコンポーネント)
5. [入力バリデーション](#5-入力バリデーション)
6. [AIモデレーション連携](#6-aiモデレーション連携)
7. [送信処理フロー](#7-送信処理フロー)
8. [返信不可投稿での非表示制御](#8-返信不可投稿での非表示制御)
9. [レスポンシブ対応](#9-レスポンシブ対応)
10. [アクセシビリティ](#10-アクセシビリティ)
11. [エラーハンドリング](#11-エラーハンドリング)
12. [多言語対応](#12-多言語対応)
13. [状態管理](#13-状態管理)
14. [パフォーマンス要件](#14-パフォーマンス要件)
15. [テスト要件](#15-テスト要件)

---

## 1. 概要

### 1.1 目的と重要性

コメント入力エリアは、投稿詳細画面においてユーザーがコメントを投稿するための入力インターフェースです。掲示板におけるコミュニケーションの起点となる重要な機能であり、以下の目的を持ちます：

**主要目的**
- **安心感のある投稿体験** - AIモデレーションにより、不適切な表現を事前に検知・変換
- **シンプルで直感的な操作** - 最小限のUIで誰でも簡単にコメント可能
- **トラブル防止** - 投稿前チェックにより、近隣トラブルの原因となる表現を排除
- **多言語住民への配慮** - 言語の壁を越えたコミュニケーション基盤

### 1.2 設計方針

**HarmoNET Design System v1.0 準拠**

本章のUI設計は、「静かで、安心できる、永く使えるUI」をコンセプトとするHarmoNET Design System v1.0に完全準拠します。

**重要な設計判断**
- **AIモデレーション必須化** - 全コメントを投稿前に自動チェック
- **送信前の確認不要** - AIが自動処理するため、ユーザーは「送信」ボタンを押すだけ
- **エラーは即座にフィードバック** - バリデーションエラーはリアルタイムで表示
- **スマホファースト** - モバイル環境での快適な入力体験を最優先

### 1.3 第5章との連携


#### 1.4 テナントスコープおよびデータ分離

本機能は、掲示板投稿およびコメント機能を**テナント単位で完全に分離**して運用します。  
各コメントデータは、紐づく投稿（post_id）およびテナント（tenant_id）と関連づけられ、異なるテナント間での閲覧・投稿・検索は不可能とします。

**運用方針**
- すべてのコメントデータは `tenant_id` によりスコープ管理される。  
- ログインセッションから取得される `tenant_id` と異なるデータへのアクセスはAPI層で拒否される。  
- テナント管理者は、自テナント内の投稿・コメントのみを閲覧・削除可能。  
- サービス運営者（プラットフォーム管理者）は、監査目的に限り全テナント横断的な参照が可能。

**データモデル補足**

| エンティティ | 主キー構成 | 関連テーブル | 備考 |
|--------------|-------------|---------------|------|
| `board_posts` | `id, tenant_id` | `board_comments` | 投稿（掲示板本体） |
| `board_comments` | `id, tenant_id` | `board_posts` | コメント（本章対象） |

**API前提**
- コメント投稿API `/api/v1/board/posts/{postId}/comments/moderate` の内部処理では、`tenant_id` 一致検証を必須化。
- モデレーションAPI呼び出し時にも `tenant_id` を付与し、誤スコープ投稿を防止。


本章（第6章：コメント入力エリア）は、第5章（コメント表示エリア）と密接に連携します：

- **投稿完了後の表示更新** - 新規コメントが第5章のコメント一覧に即座に追加
- **コメント件数の更新** - 投稿完了後、コメント件数を自動インクリメント
- **スクロール制御** - 投稿完了後、新規コメントの位置まで自動スクロール

---

## 2. 基本仕様

### 2.1 入力制限

| 項目 | 制限値 | 備考 |
|------|-------|------|
| **最大文字数** | 500文字 | 日本語・英語・中国語共通 |
| **最小文字数** | 1文字 | 空文字・空白のみは不可 |
| **改行** | 制限なし | ただし連続改行は2つまで |
| **添付ファイル** | 不可 | MVP範囲外（Phase 2で検討） |

### 2.2 入力形式

**許可される文字**
- 日本語（ひらがな、カタカナ、漢字）
- 英数字（半角・全角）
- 中国語（簡体字・繁体字）
- 記号（一般的な記号のみ）
- 絵文字（Unicode標準）

**禁止される文字**
- 制御文字（タブ、NULL文字など）
- サロゲートペア外の文字

### 2.3 送信操作

**キーボード操作**
- **Enterキー** → 送信
- **Shift + Enter** → 改行
- **Ctrl + Enter（Win）/ Cmd + Enter（Mac）** → 送信（代替操作）

**マウス/タッチ操作**
- 送信ボタンをクリック/タップ

---

## 3. レイアウト設計

### 3.1 配置位置

コメント入力エリアは、投稿詳細画面の以下の位置に配置されます：

```
┌─────────────────────────────────┐
│ ヘッダー（戻る、メニュー）       │
├─────────────────────────────────┤
│                                 │
│ 投稿本文エリア                   │
│ （第3章: 本文表示エリア）        │
│                                 │
├─────────────────────────────────┤
│                                 │
│ コメント表示エリア               │
│ （第5章: コメントエリア）        │
│                                 │
├─────────────────────────────────┤
│ ▼ コメント入力エリア（本章）     │ ← スクロール最下部
│   [テキストエリア]               │
│   [送信ボタン] [文字カウンター]  │
├─────────────────────────────────┤
│ フッターナビゲーション           │
│ （第7章: フッター領域）          │
└─────────────────────────────────┘
```

### 3.2 固定位置指定

**スクロール挙動**
- コメント入力エリアは**固定表示ではない**（画面下部に追従しない）
- ユーザーがスクロールして最下部に到達すると表示される
- フッターナビゲーションの上に配置

**理由**
- 常時固定表示すると、コメント閲覧時に画面領域を圧迫
- スクロール最下部に到達した時点で「コメントしたい」意図が明確になる

### 3.3 余白設計（HarmoNET Design System 準拠）

```css
/* コンテナ余白 */
.comment-input-container {
  padding: 24px 20px; /* 上下24px、左右20px */
  margin-bottom: 16px; /* フッターとの距離 */
  background-color: #FFFFFF;
  border-top: 1px solid #E5E7EB;
}

/* テキストエリアとボタンの間隔 */
.input-group {
  gap: 12px; /* 入力欄とボタンの間隔 */
}
```

---

## 4. UIコンポーネント

### 4.1 テキストエリア（Textarea）

#### 4.1.1 基本スタイル

```css
.comment-textarea {
  width: 100%;
  min-height: 80px; /* 初期表示時の高さ */
  max-height: 200px; /* 最大高さ */
  padding: 12px 16px;
  
  /* HarmoNET Design System 準拠 */
  background-color: #F9FAFB;
  border: 1px solid #E5E7EB;
  border-radius: 0.75rem; /* lg */
  
  font-size: 14px;
  line-height: 1.6;
  color: #1F2937;
  
  resize: none; /* 手動リサイズ無効 */
  overflow-y: auto; /* 縦スクロール有効 */
}

/* フォーカス時 */
.comment-textarea:focus {
  outline: none;
  border-color: #2563EB;
  ring: 2px solid rgba(37, 99, 235, 0.2);
}

/* エラー時 */
.comment-textarea.error {
  border-color: #DC2626;
  ring: 2px solid rgba(220, 38, 38, 0.1);
}
```

#### 4.1.2 プレースホルダー

**多言語対応**
- 日本語: `"コメントを入力...（最大500文字）"`
- 英語: `"Write a comment... (max 500 characters)"`
- 中国語: `"输入评论...（最多500字）"`

#### 4.1.3 自動リサイズ機能

テキストエリアは、入力内容に応じて自動的に高さを調整します。

**動作仕様**
1. 初期表示: 80px（約3行分）
2. テキスト入力に応じて自動拡大
3. 最大高さ: 200px（約10行分）
4. 最大高さ到達後は縦スクロール表示

**実装方法**
```javascript
// 入力イベント時に高さを調整
textarea.addEventListener('input', function() {
  this.style.height = 'auto';
  this.style.height = Math.min(this.scrollHeight, 200) + 'px';
});
```

### 4.2 送信ボタン（Send Button）

#### 4.2.1 基本スタイル

```css
.send-button {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  
  padding: 10px 20px;
  min-width: 100px;
  
  /* HarmoNET Design System 準拠 */
  background-color: #2563EB; /* アクションブルー */
  color: #FFFFFF;
  border: none;
  border-radius: 0.5rem; /* md */
  
  font-size: 14px;
  font-weight: 500;
  
  cursor: pointer;
  transition: background-color 0.15s ease;
}

/* ホバー時 */
.send-button:hover:not(:disabled) {
  background-color: #1D4ED8;
}

/* 無効時 */
.send-button:disabled {
  background-color: #9CA3AF;
  cursor: not-allowed;
  opacity: 0.6;
}

/* 送信中 */
.send-button.loading {
  background-color: #6B7280;
  cursor: wait;
}
```

#### 4.2.2 ボタンラベル

**多言語対応**
- 日本語: `"送信"`
- 英語: `"Send"`
- 中国語: `"发送"`

**アイコン**
- 送信アイコン（紙飛行機）: `<SendHorizontal />` (Lucide Icons)
- サイズ: 16px
- カラー: 白 (`#FFFFFF`)

#### 4.2.3 無効状態

以下の条件で送信ボタンを無効化：
- テキストエリアが空
- 空白文字のみ
- 500文字超過
- 送信処理中
- ネットワークエラー発生中

### 4.3 文字カウンター（Character Counter）

#### 4.3.1 表示位置

テキストエリアの右下に表示

```
┌─────────────────────────────┐
│ [テキストエリア]             │
│                             │
│                  125 / 500  │ ← 文字カウンター
└─────────────────────────────┘
```

#### 4.3.2 スタイル

```css
.char-counter {
  margin-top: 8px;
  text-align: right;
  font-size: 12px;
  color: #6B7280; /* 副次文字色 */
}

/* 警告表示（450文字以上） */
.char-counter.warning {
  color: #F59E0B; /* オレンジ */
  font-weight: 500;
}

/* エラー表示（500文字超過） */
.char-counter.error {
  color: #DC2626; /* 注意レッド */
  font-weight: 600;
}
```

#### 4.3.3 表示ロジック

```javascript
function updateCharCounter(currentLength) {
  const counter = document.querySelector('.char-counter');
  const maxLength = 500;
  
  counter.textContent = `${currentLength} / ${maxLength}`;
  
  // 警告・エラー状態の切り替え
  if (currentLength > maxLength) {
    counter.classList.add('error');
    counter.classList.remove('warning');
  } else if (currentLength >= 450) {
    counter.classList.add('warning');
    counter.classList.remove('error');
  } else {
    counter.classList.remove('warning', 'error');
  }
}
```

### 4.4 エラーメッセージ表示

#### 4.4.1 表示位置

テキストエリアの直下に表示

```
┌─────────────────────────────┐
│ [テキストエリア]             │
└─────────────────────────────┘
❌ 500文字を超えています。短くしてください。
```

#### 4.4.2 スタイル

```css
.error-message {
  margin-top: 8px;
  padding: 8px 12px;
  
  background-color: #FEE2E2; /* 薄い赤 */
  border-left: 3px solid #DC2626;
  border-radius: 0.25rem;
  
  font-size: 13px;
  color: #991B1B;
  line-height: 1.5;
}

/* アイコン */
.error-message::before {
  content: "❌ ";
  margin-right: 4px;
}
```

---

## 5. 入力バリデーション

### 5.1 リアルタイムバリデーション

入力中に以下のチェックを実行：

#### 5.1.1 文字数チェック

```javascript
function validateLength(text) {
  const length = text.length;
  const maxLength = 500;
  
  if (length === 0) {
    return { valid: false, error: 'コメントを入力してください' };
  }
  
  if (length > maxLength) {
    return { 
      valid: false, 
      error: `${maxLength}文字を超えています。${length - maxLength}文字削除してください。` 
    };
  }
  
  return { valid: true, error: null };
}
```

#### 5.1.2 空白文字のみチェック

```javascript
function validateNotEmpty(text) {
  const trimmed = text.trim();
  
  if (trimmed.length === 0) {
    return { 
      valid: false, 
      error: '空白のみのコメントは投稿できません' 
    };
  }
  
  return { valid: true, error: null };
}
```

#### 5.1.3 連続改行チェック

```javascript
function validateLineBreaks(text) {
  const consecutiveNewlines = /\n{3,}/g;
  
  if (consecutiveNewlines.test(text)) {
    return { 
      valid: false, 
      error: '連続する改行は2つまでです' 
    };
  }
  
  return { valid: true, error: null };
}
```

### 5.2 送信時バリデーション

送信ボタン押下時に最終チェックを実行：

```javascript
async function validateBeforeSubmit(text) {
  // 1. 基本バリデーション
  const lengthCheck = validateLength(text);
  if (!lengthCheck.valid) return lengthCheck;
  
  const emptyCheck = validateNotEmpty(text);
  if (!emptyCheck.valid) return emptyCheck;
  
  const lineBreakCheck = validateLineBreaks(text);
  if (!lineBreakCheck.valid) return lineBreakCheck;
  
  // 2. NGワードチェック（クライアント側）
  const ngWordCheck = await checkNGWords(text);
  if (!ngWordCheck.valid) return ngWordCheck;
  
  return { valid: true, error: null };
}
```

### 5.3 エラーメッセージ一覧

| エラー条件 | メッセージ（日本語） | メッセージ（英語） |
|-----------|---------------------|-------------------|
| 空文字 | `コメントを入力してください` | `Please enter a comment` |
| 空白のみ | `空白のみのコメントは投稿できません` | `Comments with only spaces cannot be posted` |
| 文字数超過 | `500文字を超えています。XX文字削除してください。` | `Exceeds 500 characters. Please remove XX characters.` |
| 連続改行 | `連続する改行は2つまでです` | `Consecutive line breaks are limited to 2` |

---

## 6. AIモデレーション連携

### 6.1 モデレーション概要

コメント送信時、AIが自動的に内容をチェックし、3段階で判定します。この処理は**board-feature-design-v1_1.md 第14章「モデレーション機能」**と完全に連携します。

**処理タイミング**
- 送信ボタン押下後、即座に実行
- サーバー側で処理（フロントエンドはローディング表示）

### 6.2 3段階判定フロー

```
送信ボタン押下
  ↓
[送信中...] 表示（0.5秒）
  ↓
AIモデレーション実行
  ↓
┌─────────────────────────────────────────┐
│ レベル1: ブロック                        │
│ → エラー表示、修正を促す                  │
├─────────────────────────────────────────┤
│ レベル2: 変換提案                        │
│ → 変換後の文章を表示、ユーザーが選択      │
├─────────────────────────────────────────┤
│ レベル3: OK                             │
│ → 即座にコメント投稿完了                  │
└─────────────────────────────────────────┘
```

### 6.3 レベル1: ブロック（投稿不可）

#### 6.3.1 ブロック対象

以下の内容を含むコメントは即座にブロックされます：

1. **誹謗中傷・暴言**
   - 「バカ」「アホ」「死ね」「最低」「クズ」など

2. **人種・国籍差別**
   - 「外国人は○○」「中国人が」など

3. **個人特定情報**
   - 部屋番号、個人名、特定できる特徴

4. **個人情報**
   - 電話番号、メールアドレス

5. **NGワード**（管理者が設定）

#### 6.3.2 ブロック時の表示

```
┌─────────────────────────────────────┐
│ ❌ コメントを投稿できませんでした      │
│                                     │
│ 【理由】                             │
│ ・攻撃的な表現が含まれています         │
│ ・部屋番号が含まれています            │
│                                     │
│ 内容を修正してから再度投稿してください。 │
│                                     │
│ [ 内容を修正する ]                   │
└─────────────────────────────────────┘
```

**UI動作**
1. モーダルダイアログで表示
2. 背景をグレーアウト（オーバーレイ）
3. 「内容を修正する」ボタンでモーダルを閉じる
4. テキストエリアにフォーカスを戻す
5. **入力内容は保持される**（ユーザーが修正可能）

### 6.4 レベル2: 変換提案（ユーザー選択）

#### 6.4.1 変換対象

攻撃的だが改善可能な表現を自動変換して提案：

**変換例**
| 元の表現 | 変換後 |
|---------|--------|
| 「上の階の人、夜中うるさすぎる」 | 「上階の部屋から夜間に生活音が聞こえます」 |
| 「301号室」 | 「ある部屋」 |
| 「昨日の夜10時」 | 「夜遅い時間帯」 |

#### 6.4.2 変換提案時の表示

```
┌─────────────────────────────────────┐
│ ⚠️ より適切な表現に変換しました        │
│                                     │
│ 【あなたの文章】                      │
│ 「上の階の人、夜中うるさすぎる」       │
│                                     │
│ 【変換後の提案】                      │
│ 「上階の部屋から夜間に生活音が聞こえます」│
│                                     │
│ 【なぜ変換が必要か】                  │
│ ・攻撃的な表現は近隣トラブルの原因になります│
│ ・「人」→「部屋」に変更し、特定リスクを低減│
│                                     │
│ [ この表現で投稿する ]（推奨）         │
│ [ 自分で修正する ]                   │
│ [ キャンセル ]                       │
└─────────────────────────────────────┘
```

**UI動作**
1. モーダルダイアログで表示
2. 「この表現で投稿する」→ 変換後の文章で投稿
3. 「自分で修正する」→ モーダルを閉じて入力欄に戻る
4. 「キャンセル」→ 投稿を中止

### 6.5 レベル3: OK（即座に投稿）

問題なしと判定された場合、即座にコメントを投稿します。

**表示フロー**
```
送信ボタン押下
  ↓
[送信中...] 表示（0.5秒）
  ↓
投稿完了
  ↓
コメント一覧に新規コメントを追加
  ↓
入力欄をクリア
  ↓
成功メッセージ表示（トースト）
```

### 6.6 API連携仕様

#### 6.6.1 エンドポイント

```
POST /api/v1/board/posts/{postId}/comments/moderate
```

#### 6.6.2 リクエスト

```json
{
  "postId": 123,
  "content": "コメント本文",
  "userId": 456,
  "language": "ja"
}
```

#### 6.6.3 レスポンス（レベル1: ブロック）

```json
{
  "status": "blocked",
  "level": 1,
  "reasons": [
    "攻撃的な表現が含まれています",
    "部屋番号が含まれています"
  ],
  "detectedWords": ["バカ", "301号室"]
}
```

#### 6.6.4 レスポンス（レベル2: 変換提案）

```json
{
  "status": "converted",
  "level": 2,
  "originalText": "上の階の人、夜中うるさすぎる",
  "convertedText": "上階の部屋から夜間に生活音が聞こえます",
  "conversionReasons": [
    "攻撃的な表現を丁寧な依頼表現に変更",
    "特定リスクのある「人」→「部屋」に変更"
  ]
}
```

#### 6.6.5 レスポンス（レベル3: OK）

```json
{
  "status": "success",
  "level": 3,
  "commentId": 789,
  "createdAt": "2025-10-29T12:34:56Z"
}
```

---

## 7. 送信処理フロー

### 7.1 完全な送信フロー

```javascript
async function handleCommentSubmit() {
  const textarea = document.querySelector('.comment-textarea');
  const sendButton = document.querySelector('.send-button');
  const content = textarea.value.trim();
  
  // 1. クライアント側バリデーション
  const validation = await validateBeforeSubmit(content);
  if (!validation.valid) {
    showErrorMessage(validation.error);
    return;
  }
  
  // 2. 送信ボタンを無効化、ローディング表示
  sendButton.disabled = true;
  sendButton.classList.add('loading');
  sendButton.textContent = '送信中...';
  
  try {
    // 3. AIモデレーションAPI呼び出し
    const response = await fetch(`/api/v1/board/posts/${postId}/comments/moderate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content, userId, language })
    });
    
    const result = await response.json();
    
    // 4. レベル別処理
    switch (result.level) {
      case 1: // ブロック
        showBlockedModal(result.reasons);
        break;
        
      case 2: // 変換提案
        showConversionModal(result.originalText, result.convertedText, result.conversionReasons);
        break;
        
      case 3: // OK
        handleCommentSuccess(result.commentId);
        break;
    }
    
  } catch (error) {
    // 5. エラーハンドリング
    showErrorModal('ネットワークエラーが発生しました。再度お試しください。');
    
  } finally {
    // 6. ボタン状態を復元
    sendButton.disabled = false;
    sendButton.classList.remove('loading');
    sendButton.textContent = '送信';
  }
}
```

### 7.2 投稿成功時の処理

```javascript
function handleCommentSuccess(commentId) {
  // 1. 入力欄をクリア
  const textarea = document.querySelector('.comment-textarea');
  textarea.value = '';
  textarea.style.height = '80px'; // 高さをリセット
  
  // 2. 文字カウンターをリセット
  updateCharCounter(0);
  
  // 3. 成功メッセージ表示（トースト）
  showSuccessToast('コメントを投稿しました');
  
  // 4. コメント一覧を再取得して更新（第5章と連携）
  await refreshCommentList();
  
  // 5. 新規コメントまでスクロール
  scrollToComment(commentId);
}
```

### 7.3 エラー時のリトライ処理

ネットワークエラー時は、**入力内容を保持したまま**リトライを促します。

```javascript
function showErrorModal(message) {
  // モーダルを表示
  const modal = createModal({
    icon: '❌',
    title: 'エラー',
    message: message,
    buttons: [
      { text: '再試行', action: () => handleCommentSubmit(), primary: true },
      { text: 'キャンセル', action: () => closeModal() }
    ]
  });
  
  // 入力内容は保持される（テキストエリアはクリアしない）
}
```

---

## 8. 返信不可投稿での非表示制御

### 8.1 非表示条件

以下の条件でコメント入力エリアを非表示にします：

- **回覧板投稿** - `post.type === 'circular'`
- **返信不可フラグ** - `post.allowComments === false`
- **管理者からの公式通知** - `post.isOfficialNotice === true`

### 8.2 非表示時の表示

コメント入力エリアの代わりに、以下のメッセージを表示：

```
┌─────────────────────────────────────┐
│ 📋 この投稿には返信できません         │
│                                     │
│ この投稿は回覧板のため、コメントは     │
│ 受け付けておりません。                │
└─────────────────────────────────────┘
```

### 8.3 実装コード

```javascript
function renderCommentInputArea(post) {
  const container = document.querySelector('.comment-input-container');
  
  // 返信不可の場合
  if (!post.allowComments || post.type === 'circular') {
    container.innerHTML = `
      <div class="no-comment-notice">
        <div class="notice-icon">📋</div>
        <div class="notice-title">この投稿には返信できません</div>
        <div class="notice-message">
          この投稿は回覧板のため、コメントは受け付けておりません。
        </div>
      </div>
    `;
    return;
  }
  
  // 通常のコメント入力エリアを表示
  container.innerHTML = renderCommentInput();
}
```

### 8.4 スタイル

```css
.no-comment-notice {
  padding: 24px;
  text-align: center;
  background-color: #F9FAFB;
  border: 1px dashed #E5E7EB;
  border-radius: 1rem;
}

.notice-icon {
  font-size: 32px;
  margin-bottom: 12px;
}

.notice-title {
  font-size: 16px;
  font-weight: 600;
  color: #1F2937;
  margin-bottom: 8px;
}

.notice-message {
  font-size: 14px;
  color: #6B7280;
  line-height: 1.6;
}
```

---

## 9. レスポンシブ対応

### 9.1 デバイス別レイアウト

#### 9.1.1 スマートフォン（〜767px）

**最優先のUX設計**

```css
@media (max-width: 767px) {
  .comment-input-container {
    padding: 16px;
    margin-bottom: 80px; /* フッター分の余白 */
  }
  
  .comment-textarea {
    font-size: 16px; /* iOSズーム防止のため16px以上 */
    min-height: 100px;
    padding: 14px 16px;
  }
  
  .send-button {
    width: 100%; /* 全幅ボタン */
    padding: 14px 20px;
    font-size: 16px;
  }
}
```

**タッチ領域の確保**
- すべてのタップ可能要素は44px以上の高さを確保
- ボタンは指で押しやすい大きさ（最小44x44px）

#### 9.1.2 タブレット（768px〜1023px）

```css
@media (min-width: 768px) and (max-width: 1023px) {
  .comment-input-container {
    padding: 20px 24px;
    max-width: 720px;
    margin: 0 auto;
  }
  
  .send-button {
    width: auto;
    min-width: 120px;
  }
}
```

#### 9.1.3 PC（1024px〜）

```css
@media (min-width: 1024px) {
  .comment-input-container {
    padding: 24px 32px;
    max-width: 800px;
    margin: 0 auto;
  }
  
  /* 送信ボタンとカウンターを横並び */
  .input-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
```

### 9.2 キーボード表示時の挙動（スマホ）

#### 9.2.1 iOS対応

```javascript
// iOSでキーボード表示時にビューポートを調整
if (iOS) {
  textarea.addEventListener('focus', () => {
    // ビューポートを調整
    window.scrollTo(0, textarea.offsetTop - 60);
  });
}
```

#### 9.2.2 Android対応

```javascript
// Androidでは自動調整されるため特別な処理不要
// ただし、フッターの位置調整は必要
textarea.addEventListener('focus', () => {
  document.body.classList.add('keyboard-open');
});

textarea.addEventListener('blur', () => {
  document.body.classList.remove('keyboard-open');
});
```

---

## 10. アクセシビリティ

### 10.1 キーボード操作

#### 10.1.1 Tab順序

```html
<!-- タブ順序 -->
1. テキストエリア (tabindex="1")
2. 送信ボタン (tabindex="2")
```

#### 10.1.2 ショートカットキー

| キー | 動作 |
|------|------|
| `Tab` | 次の要素へフォーカス移動 |
| `Shift + Tab` | 前の要素へフォーカス移動 |
| `Enter` | 送信 |
| `Shift + Enter` | 改行 |
| `Ctrl/Cmd + Enter` | 送信（代替） |
| `Esc` | フォーカスを外す |

### 10.2 ARIA属性

```html
<div class="comment-input-container" role="form" aria-label="コメント入力フォーム">
  <textarea
    class="comment-textarea"
    role="textbox"
    aria-label="コメント入力欄"
    aria-required="true"
    aria-invalid="false"
    aria-describedby="char-counter error-message"
    placeholder="コメントを入力...（最大500文字）"
  ></textarea>
  
  <div 
    id="char-counter" 
    class="char-counter" 
    aria-live="polite"
    aria-atomic="true"
  >
    0 / 500
  </div>
  
  <div 
    id="error-message" 
    class="error-message" 
    role="alert"
    aria-live="assertive"
    style="display: none;"
  ></div>
  
  <button
    class="send-button"
    type="submit"
    aria-label="コメントを送信"
    aria-disabled="false"
  >
    送信
  </button>
</div>
```

### 10.3 スクリーンリーダー対応

#### 10.3.1 エラーメッセージの読み上げ

```javascript
function showErrorMessage(message) {
  const errorDiv = document.getElementById('error-message');
  errorDiv.textContent = message;
  errorDiv.style.display = 'block';
  errorDiv.setAttribute('aria-live', 'assertive'); // 即座に読み上げ
}
```

#### 10.3.2 送信完了の通知

```javascript
function announceSuccess() {
  const announcement = document.createElement('div');
  announcement.setAttribute('role', 'status');
  announcement.setAttribute('aria-live', 'polite');
  announcement.textContent = 'コメントが正常に投稿されました';
  announcement.style.position = 'absolute';
  announcement.style.left = '-10000px';
  document.body.appendChild(announcement);
  
  setTimeout(() => announcement.remove(), 3000);
}
```

---

## 11. エラーハンドリング

### 11.1 エラーの種類と対応

| エラー種別 | 原因 | 対応 |
|-----------|------|------|
| **バリデーションエラー** | 文字数超過、空文字など | 入力欄下にエラーメッセージ表示 |
| **ネットワークエラー** | 接続タイムアウト、サーバー障害 | モーダルで再試行を促す |
| **認証エラー** | セッション切れ | ログイン画面へリダイレクト |
| **権限エラー** | 投稿権限なし | エラーメッセージ表示 |
| **AIモデレーションエラー** | AI APIタイムアウト | フォールバック処理（自動承認） |

### 11.2 ネットワークエラー時の処理

```javascript
async function handleNetworkError(error) {
  console.error('Network error:', error);
  
  // 入力内容を一時保存（ローカルストレージ）
  localStorage.setItem('pendingComment', textarea.value);
  
  // エラーモーダル表示
  showErrorModal({
    title: 'ネットワークエラー',
    message: '通信エラーが発生しました。ネットワーク接続を確認して、再度お試しください。',
    buttons: [
      { text: '再試行', action: retrySubmit, primary: true },
      { text: '下書き保存', action: saveDraft },
      { text: '閉じる', action: closeModal }
    ]
  });
}
```

### 11.3 リトライ処理

```javascript
async function retrySubmit() {
  const savedContent = localStorage.getItem('pendingComment');
  if (savedContent) {
    textarea.value = savedContent;
    await handleCommentSubmit();
  }
}
```

### 11.4 フォールバック処理

AIモデレーションAPIがタイムアウトした場合、以下のフォールバック処理を実行：

```javascript
async function fallbackModeration(content) {
  // 1. クライアント側NGワードチェックのみ実行
  const ngWordCheck = checkNGWordsClient(content);
  
  if (ngWordCheck.blocked) {
    return { status: 'blocked', level: 1, reasons: ngWordCheck.reasons };
  }
  
  // 2. AIチェックをスキップして投稿許可
  return { status: 'success', level: 3 };
}
```

---

## 12. 多言語対応

### 12.1 UI要素の翻訳

#### 12.1.1 翻訳キー一覧

| キー | 日本語 | 英語 | 中国語 |
|------|-------|------|-------|
| `comment.placeholder` | `コメントを入力...（最大500文字）` | `Write a comment... (max 500 characters)` | `输入评论...（最多500字）` |
| `comment.send` | `送信` | `Send` | `发送` |
| `comment.sending` | `送信中...` | `Sending...` | `发送中...` |
| `comment.charCounter` | `{current} / {max}` | `{current} / {max}` | `{current} / {max}` |
| `comment.error.empty` | `コメントを入力してください` | `Please enter a comment` | `请输入评论` |
| `comment.error.tooLong` | `{max}文字を超えています` | `Exceeds {max} characters` | `超过{max}字` |
| `comment.success` | `コメントを投稿しました` | `Comment posted` | `评论已发布` |
| `comment.noReply` | `この投稿には返信できません` | `Comments are not allowed` | `无法回复此帖子` |

#### 12.1.2 実装例

```javascript
function getTranslation(key, params = {}) {
  const translations = {
    ja: {
      'comment.placeholder': 'コメントを入力...（最大500文字）',
      'comment.send': '送信',
      // ... 他の翻訳
    },
    en: {
      'comment.placeholder': 'Write a comment... (max 500 characters)',
      'comment.send': 'Send',
      // ... 他の翻訳
    },
    cn: {
      'comment.placeholder': '输入评论...（最多500字）',
      'comment.send': '发送',
      // ... 他の翻訳
    }
  };
  
  const currentLang = getUserLanguage(); // 'ja', 'en', 'cn'
  let text = translations[currentLang][key] || translations['ja'][key];
  
  // パラメータ置換
  Object.keys(params).forEach(param => {
    text = text.replace(`{${param}}`, params[param]);
  });
  
  return text;
}
```

### 12.2 言語切り替え時の挙動

```javascript
function onLanguageChange(newLang) {
  // 1. プレースホルダーを更新
  const textarea = document.querySelector('.comment-textarea');
  textarea.placeholder = getTranslation('comment.placeholder');
  
  // 2. ボタンテキストを更新
  const sendButton = document.querySelector('.send-button');
  sendButton.textContent = getTranslation('comment.send');
  
  // 3. エラーメッセージを更新（表示中の場合）
  if (errorVisible) {
    updateErrorMessage();
  }
}
```

---

## 13. 状態管理

### 13.1 入力状態の保持

#### 13.1.1 入力中の状態

ユーザーが入力中の内容を一時保存し、ページ遷移時やエラー時に復元できるようにします。

```javascript
// 入力内容を自動保存（デバウンス処理）
let saveTimeout;
textarea.addEventListener('input', () => {
  clearTimeout(saveTimeout);
  saveTimeout = setTimeout(() => {
    sessionStorage.setItem(`comment-draft-${postId}`, textarea.value);
  }, 500);
});

// ページ読み込み時に復元
window.addEventListener('DOMContentLoaded', () => {
  const draft = sessionStorage.getItem(`comment-draft-${postId}`);
  if (draft) {
    textarea.value = draft;
    updateCharCounter(draft.length);
  }
});
```

#### 13.1.2 送信完了後のクリア

```javascript
function clearDraft() {
  sessionStorage.removeItem(`comment-draft-${postId}`);
}
```

### 13.2 送信ボタンの状態管理

```javascript
const buttonStates = {
  IDLE: 'idle',        // 待機中
  DISABLED: 'disabled', // 無効
  LOADING: 'loading',   // 送信中
  ERROR: 'error'        // エラー
};

function setButtonState(state) {
  const button = document.querySelector('.send-button');
  
  switch (state) {
    case buttonStates.IDLE:
      button.disabled = false;
      button.classList.remove('loading', 'error');
      button.textContent = getTranslation('comment.send');
      break;
      
    case buttonStates.DISABLED:
      button.disabled = true;
      button.classList.remove('loading', 'error');
      break;
      
    case buttonStates.LOADING:
      button.disabled = true;
      button.classList.add('loading');
      button.textContent = getTranslation('comment.sending');
      break;
      
    case buttonStates.ERROR:
      button.disabled = false;
      button.classList.add('error');
      button.textContent = getTranslation('comment.retry');
      break;
  }
}
```

---

## 14. パフォーマンス要件

### 14.1 レスポンス時間要件

| 処理 | 目標時間 | 備考 |
|------|---------|------|
| **文字入力の反応** | 16ms以内 | 60fps維持 |
| **自動リサイズ** | 50ms以内 | スムーズな拡大 |
| **文字カウンター更新** | 100ms以内 | デバウンス処理 |
| **AIモデレーション** | 2秒以内 | サーバー処理含む |
| **コメント投稿完了** | 3秒以内 | 一覧更新含む |

### 14.2 最適化手法

#### 14.2.1 デバウンス処理

```javascript
// 文字カウンター更新のデバウンス
const debouncedUpdateCounter = debounce(updateCharCounter, 100);

textarea.addEventListener('input', (e) => {
  debouncedUpdateCounter(e.target.value.length);
});

function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}
```

#### 14.2.2 仮想スクロール（将来実装）

コメント数が100件を超える場合、仮想スクロールを実装してパフォーマンスを維持します（Phase 2）。

---

## 15. テスト要件

### 15.1 機能テスト項目

#### 15.1.1 基本入力機能

| テストケース | 期待結果 |
|------------|---------|
| 空文字で送信 | エラーメッセージ表示、送信不可 |
| 空白のみで送信 | エラーメッセージ表示、送信不可 |
| 500文字ちょうどで送信 | 正常に送信される |
| 501文字で送信 | エラーメッセージ表示、送信不可 |
| 改行を含む投稿 | 正常に送信される |
| 絵文字を含む投稿 | 正常に送信される |
| 日本語・英語・中国語混在 | 正常に送信される |

#### 15.1.2 AIモデレーション

| テストケース | 期待結果 |
|------------|---------|
| 暴言を含む投稿 | レベル1でブロック |
| 部屋番号を含む投稿 | レベル1でブロック |
| 攻撃的表現を含む投稿 | レベル2で変換提案 |
| 問題ない投稿 | レベル3で即座に投稿 |
| AIモデレーションタイムアウト | フォールバック処理実行 |

#### 15.1.3 キーボード操作

| テストケース | 期待結果 |
|------------|---------|
| Enterキー押下 | 送信処理実行 |
| Shift+Enter押下 | 改行挿入 |
| Tab押下 | 送信ボタンにフォーカス移動 |

#### 15.1.4 返信不可投稿

| テストケース | 期待結果 |
|------------|---------|
| 回覧板の場合 | 入力エリア非表示、メッセージ表示 |
| 返信不可フラグがtrueの場合 | 入力エリア非表示、メッセージ表示 |

### 15.2 UIテスト項目

#### 15.2.1 レイアウト

| テストケース | 確認項目 |
|------------|---------|
| スマホ（375px） | 全幅表示、ボタンが押しやすいサイズ |
| タブレット（768px） | 適切な余白、中央寄せ |
| PC（1024px） | 最大幅800px、読みやすいレイアウト |

#### 15.2.2 自動リサイズ

| テストケース | 期待結果 |
|------------|---------|
| 1行入力 | 高さ80px（初期値） |
| 5行入力 | 高さ自動拡大 |
| 10行以上入力 | 高さ200px固定、縦スクロール表示 |

#### 15.2.3 文字カウンター

| テストケース | 期待結果 |
|------------|---------|
| 0文字 | `0 / 500` グレー表示 |
| 450文字 | `450 / 500` オレンジ表示 |
| 500文字 | `500 / 500` オレンジ表示 |
| 501文字 | `501 / 500` 赤色表示 |

### 15.3 エラーハンドリングテスト

| テストケース | 期待結果 |
|------------|---------|
| ネットワークエラー | エラーモーダル表示、入力内容保持 |
| セッション切れ | ログイン画面へリダイレクト |
| 権限エラー | エラーメッセージ表示 |

### 15.4 パフォーマンステスト

| テストケース | 目標値 |
|------------|--------|
| 文字入力時のレスポンス | 16ms以内 |
| 自動リサイズ | 50ms以内 |
| AIモデレーション | 2秒以内 |

### 15.5 アクセシビリティテスト

| テストケース | 確認項目 |
|------------|---------|
| キーボードのみで操作 | すべての機能が使用可能 |
| スクリーンリーダー | ARIA属性が正しく読み上げられる |
| コントラスト比 | WCAG AA基準を満たす（4.5:1以上） |

---

## 補足

本章は、掲示板詳細設計書の第6章として、コメント入力エリアの詳細仕様を定義しています。

**関連章との連携**
- **第5章（コメント表示エリア）**: 投稿完了後のコメント一覧更新
- **第7章（フッター領域）**: フッターとの位置関係、スクロール制御
- **第14章（モデレーション機能）**: AIモデレーションとの完全連携

**参考ドキュメント**
- HarmoNET Design System v1.0
- 掲示板機能 詳細設計書 v1.1（board-feature-design-v1_1.md）

---

**文書ID**: SEC-APP-BOARD-DETAIL-CH06  
**作成日**: 2025年10月29日  
**バージョン**: v2.0

---

← 第5章: コメント表示エリア | 目次 | 第7章: フッター領域 →
