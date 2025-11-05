# 掲示板詳細画面 設計書 - 第8章 状態管理とエラーハンドリング（State Management & Error Handling）

**文書ID**: HRM-BOARD-DETAIL-CH08-001  
**バージョン**: v1.0  
**作成日**: 2025年10月29日  
**最終更新**: 2025年10月29日  
**ステータス**: レビュー待ち  

---

## 📋 改訂履歴

| バージョン | 日付 | 変更内容 | 承認者 |
|-----------|------|----------|--------|
| v1.0 | 2025-10-29 | 初版作成（状態管理・エラーハンドリング統合） | - |

---

## 目次

- [8.1 概要](#81-概要)
- [8.2 状態管理の基本設計](#82-状態管理の基本設計)
- [8.3 ステートモデル定義](#83-ステートモデル定義)
- [8.4 エラーハンドリング設計](#84-エラーハンドリング設計)
- [8.5 グローバルイベント管理](#85-グローバルイベント管理)
- [8.6 状態遷移図](#86-状態遷移図)
- [8.7 パフォーマンス・回復設計](#87-パフォーマンス回復設計)
- [8.8 テスト要件](#88-テスト要件)
- [章末ナビゲーション](#章末ナビゲーション)
- [関連ドキュメント](#関連ドキュメント)

---

## 8.1 概要

掲示板詳細画面は、投稿閲覧・コメント・翻訳・通報・編集など複数の非同期処理が同時に発生する。  
本章では、それらの操作を統一的に制御する**状態管理**と**エラーハンドリング**の仕組みを定義する。

**設計目的**

- 各コンポーネントの状態を一元的に保持  
- UIと処理状態の完全同期（リアクティブUI）  
- 非同期エラーの統一処理  
- 保守性と拡張性の向上  

---

## 8.2 状態管理の基本設計

### 8.2.1 管理範囲

対象は「掲示板詳細画面」単位とし、グローバルストア（アプリ全体）に依存しない。  
状態は`BoardDetailState`として統一管理する。

- 投稿本文（第3章）  
- コメント表示・入力（第5・6章）  
- 翻訳機能（第7章）  
- 通報・削除・編集モーダル  
- エラー・ローディング・履歴管理  

### 8.2.2 設計方針

1. **単一ソース・オブ・トゥルース**  
   全てのUI状態は`BoardDetailState`から導出する。  
2. **状態は常に非破壊更新（Immutable Update）**  
   Reactなどの再描画最適化と相性を取る。  
3. **API層とUI層を明確に分離**  
   通信結果をstateに反映する層を明示。  
4. **履歴と下書きの復元**  
   `sessionStorage`と`window.history`を併用してUI復帰を保証。

```

## 8.3 ステートモデル定義

### 8.3.1 ルートステート構造

```typescript
interface BoardDetailState {
  post: PostData | null;                  // 投稿本文データ
  comments: CommentData[];                // コメント一覧
  loading: boolean;                       // 全体ローディング
  commentSubmitting: boolean;             // コメント送信中
  translation: TranslationState;          // 翻訳状態
  modals: ModalState;                     // モーダル開閉状態
  errors: ErrorState[];                   // 発生中エラー
  scrollPosition: number;                 // スクロール復元用
}

```

### 8.3.2 翻訳状態
```typescript
interface TranslationState {
  active: boolean;
  targetLanguage: string;
  isTranslated: boolean;
  error: string | null;
}

```

### 8.3.3 モーダル状態
```typescript
interface ModalState {
  report: boolean;
  edit: boolean;
  deleteConfirm: boolean;
  conversion: boolean;
  error: boolean;
}

```

### 8.3.4 エラー状態
```typescript
interface ErrorState {
  code: string;                // 例: NET_TIMEOUT, AUTH_EXPIRED
  message: string;
  recoverable: boolean;
  source: 'comment' | 'post' | 'translation' | 'system';
  timestamp: number;
}

```

## 8.4 エラーハンドリング設計

### 8.4.1 エラー分類
| 分類    | コード例                         | 説明       | 表示形式       |
| ----- | ---------------------------- | -------- | ---------- |
| 通信エラー | `NET_TIMEOUT`, `SERVER_DOWN` | API応答なし  | モーダル + 再試行 |
| 認証エラー | `AUTH_EXPIRED`               | トークン期限切れ | ログインへ遷移    |
| 権限エラー | `FORBIDDEN_ACTION`           | 非許可操作    | トースト通知     |
| 検証エラー | `VALIDATION_FAILED`          | 入力不正     | 入力欄下メッセージ  |
| 翻訳エラー | `TRANSLATE_FAIL`             | 翻訳失敗     | コメント下警告バー  |
| 不明エラー | `UNKNOWN`                    | 想定外例外    | グローバルバナー   |



### 8.4.2 共通ハンドラ
```typescript
function handleError(error: ErrorState) {
  switch (error.code) {
    case 'NET_TIMEOUT':
      showModal('ネットワークエラー', '通信がタイムアウトしました。');
      break;
    case 'AUTH_EXPIRED':
      redirectToLogin();
      break;
    case 'TRANSLATE_FAIL':
      showBanner('翻訳に失敗しました。再試行してください。', 'warning');
      break;
    default:
      showToast(error.message || '予期せぬエラーが発生しました');
  }
  logError(error);
}

```

### 8.4.3 ログ出力
全ErrorStateをlocalStorageに最大10件まで保持

サーバー監査ログAPIへ送信（非同期）

recoverable=falseのものは再試行対象外

## グローバルイベント管理
### 8.5.1 イベント仕様
| イベント名                    | 発火元      | 説明         |
| ------------------------ | -------- | ---------- |
| `harmonet:error`         | 各API処理   | グローバルエラー発生 |
| `harmonet:stateUpdated`  | state更新時 | 再描画要求      |
| `harmonet:scrollRestore` | 履歴復元処理   | スクロール位置復帰  |
| `harmonet:modalClose`    | モーダル操作   | 全モーダル閉鎖    |


### 8.5.2 実装例
```typescript
window.addEventListener('harmonet:error', (e) => {
  const err = e.detail as ErrorState;
  handleError(err);
});

window.dispatchEvent(
  new CustomEvent('harmonet:error', { detail: { code: 'NET_TIMEOUT', message: 'サーバー応答なし' } })
);

```

## 8.6 状態遷移図

[IDLE]
   │
   ├─▶ [LOADING] ──成功──▶ [READY]
   │                     │
   │                     ├─翻訳──▶ [TRANSLATED]
   │                     │
   │                     ├─コメント送信──▶ [UPDATING_COMMENTS]
   │                     │                     │
   │                     │                     └──成功→[READY]
   │                     │                     └──失敗→[ERROR]
   │                     │
   └──失敗──▶ [ERROR]

遷移の特徴

READY状態を中心に多重非同期処理を吸収

ERROR状態時はrecoverableに応じて再試行またはモーダル提示


## 8.7 パフォーマンス回復設計
### 8.7.1 非同期制御
コメント送信・翻訳・通報のAPI呼び出しは同時最大3件まで

AbortControllerにより中断可能

2秒以上の処理はスピナーを自動表示

### 8.7.2 回復処理

ネットワーク断時はsessionStorageにpendingリクエスト保存

再接続検知時(onlineイベント)に自動再送


### 8.7.3 UI回復

showToast('再接続しました。処理を再開します。')を通知

ローディング中のUIを自動復帰

## 8.8 テスト要件
| テストケース    | 期待結果               |
| --------- | ------------------ |
| API通信エラー時 | 共通モーダル表示、再試行可能     |
| 翻訳APIエラー  | 警告バナー表示、再翻訳可能      |
| コメント投稿失敗  | 入力内容保持、リトライ可       |
| 認証切れ      | ログイン画面へ遷移          |
| 複数操作同時実行  | 排他制御によりUI競合なし      |
| 履歴復元      | スクロール・入力内容・翻訳状態が復元 |

章末ナビゲーション
| ← 前の章                                          | 目次                                      | 次の章 →                                    |
| ---------------------------------------------- | --------------------------------------- | ---------------------------------------- |
| [第7章: インタラクション仕様](board-detail-design-ch07.md) | [目次](board-detail-design-ch00-index.md) | [付録A: 関連共通仕様](harmonet-design-system.md) |


関連ドキュメント

common-error-handling.md

common-header.md

harmonet-design-system.md

common-i18n.md

Document ID: HRM-BOARD-DETAIL-CH08-001
Status: レビュー待ち
Created: 2025-10-29
Last Updated: 2025-10-29
Approved by: 未承認

HarmoNET スマートコミュニケーションアプリ
掲示板詳細画面 設計書 - 第8章 状態管理とエラーハンドリング
---