# MagicLinkForm 詳細設計書 - 第5章：テスト仕様（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH05  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第5章 テスト仕様

### 5.1 テスト目的
MagicLinkForm コンポーネントの基本動作（入力、送信、状態遷移、エラー処理）を検証し、  
Supabase 認証APIおよびUI表示が正しく連携することを保証する。  

---

### 5.2 使用ツール
| ツール | 用途 | バージョン |
|--------|------|-----------|
| Vitest | テストランナー | 最新 |
| @testing-library/react | コンポーネントレンダリング | 最新 |
| @testing-library/user-event | ユーザー操作シミュレーション | 最新 |
| @testing-library/jest-dom | DOMアサーション | 最新 |

---

### 5.3 テストケース一覧

| No | テスト名 | 入力 | 期待結果 |
|----|-----------|------|-----------|
| T-01 | 初期状態の表示 | なし | 「メールを送信」ボタンと空入力欄が表示される |
| T-02 | 入力なしで送信 | 空文字 | `error_invalid` 状態へ遷移 |
| T-03 | 正常なメール送信 | 正常メール | Supabase signInWithOtp 成功で `sent` 状態 |
| T-04 | Supabase 通信失敗 | 正常メール | `error_network` 状態へ遷移 |
| T-05 | コールバック確認 | 成功時 | `onSent()` が呼ばれる |
| T-06 | エラー時コールバック確認 | 異常時 | `onError()` が呼ばれる |

---

### 5.4 実装例

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MagicLinkForm } from './MagicLinkForm';

describe('MagicLinkForm', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('T-01 初期状態でボタンと入力欄が表示される', () => {
    render(<MagicLinkForm />);
    expect(screen.getByRole('button')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('メールアドレスを入力')).toBeInTheDocument();
  });

  it('T-02 入力なしで送信時に error_invalid へ遷移', async () => {
    const onError = vi.fn();
    render(<MagicLinkForm onError={onError} />);
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onError).toHaveBeenCalled());
  });

  it('T-03 正常送信時に onSent が呼ばれる', async () => {
    const onSent = vi.fn();
    vi.mock('@/lib/supabase/client', () => ({
      createClient: () => ({
        auth: { signInWithOtp: vi.fn().mockResolvedValue({ error: null }) },
      }),
    }));
    render(<MagicLinkForm onSent={onSent} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'user@example.com' } });
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onSent).toHaveBeenCalled());
  });

  it('T-04 Supabase失敗時に error_network へ遷移', async () => {
    const onError = vi.fn();
    vi.mock('@/lib/supabase/client', () => ({
      createClient: () => ({
        auth: { signInWithOtp: vi.fn().mockResolvedValue({ error: { message: "NETWORK" } }) },
      }),
    }));
    render(<MagicLinkForm onError={onError} />);
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'user@example.com' } });
    fireEvent.click(screen.getByRole('button'));
    await waitFor(() => expect(onError).toHaveBeenCalled());
  });
});
```

---

### 5.5 カバレッジ目標
| 種別 | 目標値 | 優先度 |
|------|--------|--------|
| 単体テスト | 90%以上 | 高 |
| 結合テスト | 80%以上 | 中 |
| UIレンダリング | 100%表示確認 | 高 |
| エラーハンドリング | 100%パス確認 | 高 |

---

### 5.6 モック方針
- Supabaseクライアントは `createClient()` を完全モック化。  
- 外部通信は発生させない（`mockResolvedValue` のみ使用）。  
- i18nテキストは固定値（`t(key)` → key文字列）で評価可。  

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。Vitest構成、Supabaseモック方式統一、カバレッジ目標追加。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第6章 セキュリティ考慮事項（ch06）へ進む
