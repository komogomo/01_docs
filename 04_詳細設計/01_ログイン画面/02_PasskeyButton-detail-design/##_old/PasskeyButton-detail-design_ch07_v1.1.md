# PasskeyButton 詳細設計書 - 第7章：テスト戦略（v1.1 改訂版）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH07  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / PasskeyButton-detail-design_v1.4.md  
**Reviewer:** TKD  
**Status:** Phase9 正式仕様整合版  

---

## 第7章：テスト戦略

### 7.1 単体テスト

#### 7.1.1 テストフレームワーク
```typescript
// PasskeyButton.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PasskeyButton } from './PasskeyButton';
```

**使用ツール**:
| ツール | 用途 | バージョン |
|--------|------|-----------|
| Vitest | テストランナー | 最新 |
| @testing-library/react | コンポーネントテスト | 最新 |
| @testing-library/user-event | ユーザー操作シミュレーション | 最新 |

---

#### 7.1.2 テストケース一覧

##### 基本レンダリング
```typescript
describe('PasskeyButton - 基本レンダリング', () => {
  it('初期状態で正しくレンダリングされる', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();

    render(<PasskeyButton onSuccess={onSuccess} onError={onError} />);

    const button = screen.getByRole('button', { name: 'パスキーでログイン' });
    expect(button).toBeInTheDocument();
    expect(button).toHaveAttribute('aria-label', 'パスキーでログイン');
  });
});
```

---

##### 認証成功ケース
```typescript
describe('PasskeyButton - 認証成功', () => {
  it('Corbado + Supabase 連携成功時に onSuccess が呼ばれる', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();

    // CorbadoとSupabaseのモック
    vi.mock('@corbado/web-js', () => ({
      default: {
        load: vi.fn().mockResolvedValue(true),
        passkey: {
          login: vi.fn().mockResolvedValue({ success: true, id_token: 'mock_token' }),
        },
      },
    }));

    const mockSupabase = {
      auth: {
        signInWithIdToken: vi.fn().mockResolvedValue({ error: null }),
      },
    };
    vi.mock('@/lib/supabase/client', () => ({ createClient: () => mockSupabase }));

    render(<PasskeyButton onSuccess={onSuccess} onError={onError} />);
    const button = screen.getByRole('button');
    fireEvent.click(button);

    await waitFor(() => {
      expect(onSuccess).toHaveBeenCalledTimes(1);
      expect(onError).not.toHaveBeenCalled();
    });
  });
});
```

---

##### 認証失敗ケース
```typescript
describe('PasskeyButton - 認証失敗', () => {
  it('Corbado失敗時に onError が呼ばれる', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();

    vi.mock('@corbado/web-js', () => ({
      default: {
        load: vi.fn().mockResolvedValue(true),
        passkey: { login: vi.fn().mockRejectedValue(new Error('認証失敗')) },
      },
    }));

    const mockSupabase = { auth: { signInWithIdToken: vi.fn() } };
    vi.mock('@/lib/supabase/client', () => ({ createClient: () => mockSupabase }));

    render(<PasskeyButton onSuccess={onSuccess} onError={onError} />);
    const button = screen.getByRole('button');
    fireEvent.click(button);

    await waitFor(() => {
      expect(onError).toHaveBeenCalledTimes(1);
    });
  });
});
```

---

### 7.2 統合テスト（LoginScreen 連携）

```typescript
describe('LoginScreen + PasskeyButton 統合', () => {
  it('Passkey認証成功時に /home へ遷移', async () => {
    render(<LoginScreen />);
    const button = await screen.findByText('パスキーでログイン');
    fireEvent.click(button);

    await waitFor(() => {
      expect(window.location.pathname).toBe('/home');
    });
  });
});
```

---

### 7.3 E2Eテスト（将来実装）
```typescript
// e2e/passkey-login.spec.ts
import { test, expect } from '@playwright/test';

test('パスキー認証フロー（Corbado + Supabase連携）', async ({ page }) => {
  await page.goto('/login');
  await page.click('button:has-text("パスキーでログイン")');
  // WebAuthnプロンプトモック
  await expect(page).toHaveURL('/home');
});
```

---

### 7.4 カバレッジ目標

| テスト種別 | 目標カバレッジ | 重要度 |
|-----------|--------------|--------|
| 単体テスト | 90%以上 | 高 |
| 統合テスト | 80%以上 | 中 |
| E2Eテスト | 主要フローのみ | 低 |

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-01-10 | 初版（Supabase.signInWithPasskey構成） |
| v1.1 | 2025-11-10 | Corbado + Supabase.signInWithIdToken 構成に全面対応。モック・E2E・統合テスト更新。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  

