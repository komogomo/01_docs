# MagicLinkForm 詳細設計書 - 第5章：テスト仕様（v1.0）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH05
**Version:** 1.0
**Created:** 2025-11-11
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Category:** ログイン画面コンポーネント（Authentication Components）
**Status:** ✅ Phase9 正式整合版（技術スタック v4.0 準拠）
**ContextKey:** HarmoNet_LoginDocs_Realign_v4.0_Update

---

## 第5章 テスト仕様

### 5.1 テスト目的

MagicLinkForm コンポーネントの**機能的正当性・UI表示の一貫性・エラーハンドリングの堅牢性**を確認することを目的とする。
特に Supabase API (`signInWithOtp`) と状態遷移の整合、および i18n 表示の即時反映を重点的に検証する。

---

### 5.2 テスト環境・使用ツール

| ツール                             | 用途               | バージョン | 備考                  |
| ------------------------------- | ---------------- | ----- | ------------------- |
| **Vitest**                      | テストランナー          | ^1.x  | Jest互換API採用         |
| **@testing-library/react**      | コンポーネントDOMレンダリング | 最新    | Hooks / 状態変化の可視化    |
| **@testing-library/user-event** | ユーザー操作エミュレーション   | 最新    | 入力・クリック操作再現         |
| **@testing-library/jest-dom**   | DOMアサーション        | 最新    | toBeInTheDocument 等 |
| **Mock Supabase Client**        | APIモック           | 内部生成  | 外部通信遮断              |

---

### 5.3 テスト観点一覧

| No   | テスト観点     | 内容                               | 検証対象                 | 成否基準               |
| ---- | --------- | -------------------------------- | -------------------- | ------------------ |
| T-01 | 初期表示      | 入力欄・送信ボタン・文言が正しく描画される            | UIレンダリング             | DOM構造一致            |
| T-02 | 入力バリデーション | 不正メール入力で `error_invalid` 状態へ遷移   | 入力検証ロジック             | 状態変化確認             |
| T-03 | 正常送信      | 有効メール送信で Supabase API 呼出し成功      | Supabaseモック          | 状態=sent + onSent呼出 |
| T-04 | 通信エラー     | Supabase失敗応答時 `error_network` 表示 | エラーマッピング             | i18n文言出力確認         |
| T-05 | 成功コールバック  | 成功時 onSent が一度だけ呼ばれる             | イベント                 | 呼出回数=1             |
| T-06 | 失敗コールバック  | 失敗時 onError が発火                  | イベント                 | エラーオブジェクト受信        |
| T-07 | 言語切替      | 言語変更後に文言が即時切替                    | StaticI18nProvider連携 | 翻訳キー正解             |
| T-08 | 再送信       | エラー後に再入力→再送信可能                   | 状態遷移                 | idle→sending 再遷移   |
| T-09 | ボタン無効化    | 送信中に多重クリック不可                     | イベント防止               | click無視確認          |

---

### 5.4 テスト実装例

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MagicLinkForm } from './MagicLinkForm';

vi.mock('@/lib/supabase/client', () => ({
  createClient: () => ({
    auth: {
      signInWithOtp: vi.fn().mockResolvedValue({ error: null })
    }
  })
}));

describe('MagicLinkForm Component Tests', () => {
  beforeEach(() => vi.clearAllMocks());

  it('T-01 初期表示: 入力欄とボタンが存在する', () => {
    render(<MagicLinkForm />);
    expect(screen.getByRole('textbox')).toBeInTheDocument();
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('T-02 入力なしで送信時に error_invalid へ遷移', async () => {
    const onError = vi.fn();
    render(<MagicLinkForm onError={onError} />);
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onError).toHaveBeenCalled());
  });

  it('T-03 正常送信時 onSent 呼出', async () => {
    const onSent = vi.fn();
    render(<MagicLinkForm onSent={onSent} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'user@example.com' } });
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onSent).toHaveBeenCalledTimes(1));
  });

  it('T-04 通信失敗時 error_network 発火', async () => {
    const onError = vi.fn();
    vi.mocked(require('@/lib/supabase/client').createClient).mockReturnValue({
      auth: { signInWithOtp: vi.fn().mockResolvedValue({ error: { message: 'NETWORK' } }) }
    });
    render(<MagicLinkForm onError={onError} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'user@example.com' } });
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onError).toHaveBeenCalled());
  });
});
```

---

### 5.5 カバレッジ目標と品質基準

| カテゴリ      | 目標値        | 評価基準                | 備考                |
| --------- | ---------- | ------------------- | ----------------- |
| 単体テスト     | **95%** 以上 | 主要分岐・イベント発火網羅       | onSent/onError 含む |
| 結合テスト     | **80%** 以上 | Supabaseモックを通じた挙動一致 | API応答差分考慮         |
| UIレンダリング  | **100%**   | 全要素描画・属性一致          | スナップショット検証        |
| エラーハンドリング | **100%**   | 状態別メッセージ確認          | 各i18nキー別評価        |

---

### 5.6 モック方針

* Supabaseクライアント (`createClient`) は完全モック化し、実通信を禁止。
* i18nテキストは簡略キー文字列（例：`t(key) → key`）として評価可。
* 外部ライブラリ（lucide-react 等）は描画確認のみに留め、内部実装をモック化。
* 時間依存（async wait）には `waitFor` を使用し、非同期安定性を確保。

---

### 5.7 ユーザー操作UT観点

| 観点ID | 操作内容  | 期待結果               | 検証目的                   |
| ---- | ----- | ------------------ | ---------------------- |
| UT01 | 入力→送信 | API呼出成功、メッセージ表示    | 正常操作確認                 |
| UT02 | 入力エラー | 即座にエラーメッセージ表示      | フロントバリデーション確認          |
| UT03 | 通信遮断  | `error_network` 表示 | Supabase例外処理確認         |
| UT04 | 言語切替  | 文言即時反映             | StaticI18nProvider整合確認 |
| UT05 | 再送信   | 状態復帰後再試行可          | 状態管理検証                 |

---

### 5.8 テスト自動化連携

* `npm run test` 実行時、Vitest による自動スナップショット比較を有効化。
* CI/CD 上で `coverageThreshold` を設定し、Fail Fast 運用を徹底。
* 将来的には **Playwright E2E** へ拡張し、MagicLink 実際送信をシミュレーション予定。

---

### 🧾 Change Log

| Version | Date       | Summary                                  |
| ------- | ---------- | ---------------------------------------- |
| v1.0    | 2025-11-11 | 初版（Phase9仕様：Vitest統合・UT観点拡張・CI/CD自動検証対応） |
