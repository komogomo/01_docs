# MagicLinkForm 詳細設計書 - 第5章：テスト仕様（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH05
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Supabase＋Corbado統合対応）

---

## 第5章 テスト仕様

### 5.1 テスト目的

MagicLinkForm (A-01) の **統合認証機能（MagicLink＋Passkey自動判定）** が、全てのシナリオで正しく動作することを確認する。
対象範囲は、UIレンダリング、Supabase / Corbado 連携、状態遷移、i18n反映、イベント発火である。

| テスト目的分類   | 検証項目                               |
| --------- | ---------------------------------- |
| **機能正当性** | Supabase / Corbado 呼出しの成功・失敗パターン網羅 |
| **UX整合性** | passkey_enabled に応じた自動切替が自然に動作するか  |
| **UI反応**  | ボタン状態・色・アイコン表示が状態ごとに正確か            |
| **国際化**   | StaticI18nProvider 経由で各文言が即時反映されるか |
| **例外制御**  | ネットワーク遮断・認証拒否などのエラーが正しくUIへ反映されるか   |

---

### 5.2 テスト環境・使用ツール

| ツール                             | 用途             | バージョン | 備考                      |
| ------------------------------- | -------------- | ----- | ----------------------- |
| **Vitest**                      | テストランナー        | ^1.x  | Jest互換構文                |
| **@testing-library/react**      | DOMレンダリング・操作検証 | 最新    | 状態変化・画面描画確認             |
| **@testing-library/user-event** | ユーザー操作エミュレーション | 最新    | 入力・クリック操作再現             |
| **@testing-library/jest-dom**   | DOMアサーション      | 最新    | `toBeInTheDocument()` 等 |
| **Mock Supabase Client**        | Supabase認証モック  | 内部生成  | 通信遮断                    |
| **Mock Corbado SDK**            | WebAuthnモック    | 内部生成  | Passkey認証再現             |

---

### 5.3 テスト観点一覧

| No   | テスト観点         | 内容                                         | 検証対象               | 成否基準                  |
| ---- | ------------- | ------------------------------------------ | ------------------ | --------------------- |
| T-01 | 初期表示          | 入力欄・ボタン・文言が正しく描画される                        | UIレンダリング           | DOM構造一致               |
| T-02 | 入力バリデーション     | 不正メール入力で `error_invalid` へ遷移               | 入力検証               | 状態変化確認                |
| T-03 | MagicLink成功   | passkeyEnabled=false でメール送信成功              | Supabaseモック        | 状態=sent + onSent呼出    |
| T-04 | MagicLink通信失敗 | Supabase失敗応答時 `error_network` 表示           | エラーマッピング           | 翻訳メッセージ確認             |
| T-05 | Passkey成功     | passkeyEnabled=true で Corbado→Supabase認証成功 | Corbado + Supabase | 状態=success + onSent呼出 |
| T-06 | Passkey拒否     | WebAuthn拒否時に `error_auth` へ遷移              | Corbadoモック         | 状態変化確認                |
| T-07 | Passkey通信失敗   | Corbado.load() / login() エラー時              | Corbadoモック         | `error_network` 表示    |
| T-08 | 再送信           | 失敗後に再入力→再送信可能                              | 状態管理               | idle→sending 再遷移      |
| T-09 | 言語切替          | 翻訳キー即時反映                                   | i18n               | 表示文字列一致               |
| T-10 | イベント呼出        | 成功で onSent / 失敗で onError が一度だけ発火           | イベント制御             | 呼出回数=1                |

---

### 5.4 テスト実装例（抜粋）

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MagicLinkForm } from './MagicLinkForm';

vi.mock('@/lib/supabase/client', () => ({
  createClient: () => ({
    auth: {
      signInWithOtp: vi.fn().mockResolvedValue({ error: null }),
      signInWithIdToken: vi.fn().mockResolvedValue({ error: null })
    }
  })
}));

vi.mock('@corbado/web-js', () => ({
  default: {
    load: vi.fn().mockResolvedValue(true),
    passkey: {
      login: vi.fn().mockResolvedValue({ id_token: 'mock-token' })
    }
  }
}));

describe('MagicLinkForm (Unified Auth)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('T-03: passkeyEnabled=false → MagicLink success', async () => {
    const onSent = vi.fn();
    render(<MagicLinkForm onSent={onSent} passkeyEnabled={false} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'user@example.com' } });
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onSent).toHaveBeenCalledTimes(1));
  });

  it('T-05: passkeyEnabled=true → Passkey success', async () => {
    const onSent = vi.fn();
    render(<MagicLinkForm onSent={onSent} passkeyEnabled={true} />);
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onSent).toHaveBeenCalledTimes(1));
  });

  it('T-06: Passkey denied', async () => {
    const onError = vi.fn();
    const Corbado = require('@corbado/web-js').default;
    Corbado.passkey.login.mockRejectedValueOnce(new Error('NotAllowedError'));
    render(<MagicLinkForm onError={onError} passkeyEnabled={true} />);
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onError).toHaveBeenCalled());
  });
});
```

---

### 5.5 カバレッジ目標と品質基準

| カテゴリ      | 目標値       | 評価基準                   | 備考               |
| --------- | --------- | ---------------------- | ---------------- |
| 単体テスト     | **95%以上** | 主要分岐・API呼出網羅           | passkeyEnabled含む |
| 結合テスト     | **85%以上** | Supabase＋Corbadoモック連携  | 二系統認証カバー         |
| UIレンダリング  | **100%**  | 状態ごとにDOM構造一致           | Snapshot利用       |
| エラーハンドリング | **100%**  | error_* 全種類検証          | t(key)一致確認       |
| CI/CD自動検証 | **必須**    | Windsurf + Vitest 自動実行 | CodeAgent統合      |

---

### 5.6 モック方針

* **Supabase Client**: `createClient` を完全モック化し、Auth呼出をすべてスタブ化。
* **Corbado SDK**: `load()` / `passkey.login()` をPromiseモックとして成功・失敗両方再現。
* **i18n Provider**: `t(key)`をシンプル文字返却（キー確認目的）。
* **ErrorHandlerProvider**: ダミー関数化し、副作用を排除。
* 外部通信は一切発生させない構成。

---

### 5.7 自動化・統合検証

* CI環境では `npm run test:unit` にて全テスト自動実行。
* Windsurf CodeAgent の自己採点機構 (`AverageScore >= 9.0`) と連動。
* `coverageThreshold` 設定により品質下限を強制。
* 次期拡張として Playwright E2E による **login→mypage 遷移実証** を追加予定。

---

### 5.8 ユーザー操作UT観点（拡張版）

| 観点ID | 操作                        | 期待結果                 | 検証目的            |
| ---- | ------------------------- | -------------------- | --------------- |
| UT01 | メール入力→ログイン（passkey=false） | MagicLink送信成功        | Supabase動作確認    |
| UT02 | passkey=trueでログイン         | Corbado→Supabase認証完了 | Passkey統合検証     |
| UT03 | Corbado拒否                 | error_auth 状態表示      | WebAuthnキャンセル確認 |
| UT04 | 通信遮断                      | error_network 状態表示   | API例外確認         |
| UT05 | 言語切替                      | 翻訳文言即時反映             | i18n整合性         |
| UT06 | 再試行                       | error状態から復帰→成功       | 状態再遷移確認         |

---

### 🧾 Change Log

| Version  | Date           | Summary                                             |
| -------- | -------------- | --------------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（Supabase専用テスト仕様）                                 |
| **v1.1** | **2025-11-12** | **Passkey統合対応。Supabase＋Corbadoモック追加・UT拡張・CI自動化準拠。** |
