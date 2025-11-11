# PasskeyButton 詳細設計書 - 第7章：テスト戦略

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

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

**参照**: `harmonet-technical-stack-definition_v3.7.md`

---

#### 7.1.2 テストケース一覧

##### 基本レンダリング
```typescript
describe('PasskeyButton - 基本レンダリング', () => {
  it('初期状態で正しくレンダリングされる', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    // ボタンが表示される
    const button = screen.getByRole('button', { name: 'パスキーでログイン' });
    expect(button).toBeInTheDocument();
    
    // アイコンが表示される
    expect(screen.getByTestId('fingerprint-icon')).toBeInTheDocument();
    
    // テキストが表示される
    expect(screen.getByText('パスキーでログイン')).toBeInTheDocument();
  });
  
  it('disabled状態で非活性になる', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
        disabled={true}
      />
    );
    
    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
    expect(button).toHaveClass('bg-gray-300');
  });
});
```

---

##### クリックイベント
```typescript
describe('PasskeyButton - クリックイベント', () => {
  it('クリック時にloading状態になる', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    
    // クリック
    fireEvent.click(button);
    
    // loading状態の確認
    await waitFor(() => {
      expect(screen.getByText('認証中...')).toBeInTheDocument();
      expect(screen.getByTestId('loader-icon')).toBeInTheDocument();
      expect(button).toHaveAttribute('aria-busy', 'true');
    });
  });
  
  it('disabled時はクリックしても何も起こらない', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
        disabled={true}
      />
    );
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    // コールバックが呼ばれないことを確認
    expect(onSuccess).not.toHaveBeenCalled();
    expect(onError).not.toHaveBeenCalled();
  });
});
```

---

##### 認証成功ケース
```typescript
describe('PasskeyButton - 認証成功', () => {
  it('認証成功時にonSuccessが呼ばれる', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    // Supabase Auth のモック
    const mockSupabase = {
      auth: {
        signInWithPasskey: vi.fn().mockResolvedValue({
          data: {
            user: { id: '123', email: 'test@example.com' },
            session: { access_token: 'token' },
          },
          error: null,
        }),
      },
    };
    
    vi.mock('@supabase/supabase-js', () => ({
      createClient: () => mockSupabase,
    }));
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    // onSuccessが呼ばれることを確認
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
  it('認証失敗時にonErrorが呼ばれる', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    const mockError = new Error('Passkey not registered');
    (mockError as any).code = 'passkey_not_registered';
    
    // Supabase Auth のモック
    const mockSupabase = {
      auth: {
        signInWithPasskey: vi.fn().mockResolvedValue({
          data: null,
          error: mockError,
        }),
      },
    };
    
    vi.mock('@supabase/supabase-js', () => ({
      createClient: () => mockSupabase,
    }));
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    // onErrorが呼ばれることを確認
    await waitFor(() => {
      expect(onError).toHaveBeenCalledTimes(1);
      expect(onError).toHaveBeenCalledWith(mockError);
      expect(onSuccess).not.toHaveBeenCalled();
    });
  });
  
  it('エラー後、100ms後にidle状態に戻る', async () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    const mockError = new Error('Network error');
    
    const mockSupabase = {
      auth: {
        signInWithPasskey: vi.fn().mockResolvedValue({
          data: null,
          error: mockError,
        }),
      },
    };
    
    vi.mock('@supabase/supabase-js', () => ({
      createClient: () => mockSupabase,
    }));
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    // エラー処理を待つ
    await waitFor(() => {
      expect(onError).toHaveBeenCalled();
    });
    
    // 100ms後にidle状態に戻ることを確認
    await waitFor(() => {
      expect(screen.getByText('パスキーでログイン')).toBeInTheDocument();
      expect(button).not.toHaveAttribute('aria-busy', 'true');
    }, { timeout: 200 });
  });
});
```

---

##### アクセシビリティ
```typescript
describe('PasskeyButton - アクセシビリティ', () => {
  it('適切なARIA属性が設定されている', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    
    expect(button).toHaveAttribute('aria-label', 'パスキーでログイン');
    expect(button).toHaveAttribute('aria-busy', 'false');
    expect(button).toHaveAttribute('type', 'button');
  });
  
  it('キーボード操作が可能', () => {
    const onSuccess = vi.fn();
    const onError = vi.fn();
    
    render(
      <PasskeyButton
        email="test@example.com"
        onSuccess={onSuccess}
        onError={onError}
      />
    );
    
    const button = screen.getByRole('button');
    
    // Enterキー
    fireEvent.keyDown(button, { key: 'Enter', code: 'Enter' });
    expect(button).toHaveFocus();
    
    // Spaceキー
    fireEvent.keyDown(button, { key: ' ', code: 'Space' });
    expect(button).toHaveFocus();
  });
});
```

---

### 7.2 統合テスト

#### 7.2.1 LoginScreen との統合
```typescript
describe('PasskeyButton - LoginScreen統合', () => {
  it('LoginScreen内で正しく動作する', async () => {
    render(<LoginScreen />);
    
    // メールアドレス入力
    const emailInput = screen.getByLabelText('メールアドレス');
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    
    // マジックリンク送信
    const sendButton = screen.getByText('マジックリンクを送信');
    fireEvent.click(sendButton);
    
    // PasskeyButtonが表示される
    await waitFor(() => {
      expect(screen.getByText('パスキーでログイン')).toBeInTheDocument();
    });
    
    // PasskeyButtonをクリック
    const passkeyButton = screen.getByText('パスキーでログイン');
    fireEvent.click(passkeyButton);
    
    // 認証成功後、ホーム画面へ遷移
    await waitFor(() => {
      expect(window.location.pathname).toBe('/home');
    });
  });
});
```

---

#### 7.2.2 エラーハンドリング統合
```typescript
describe('PasskeyButton - エラーハンドリング統合', () => {
  it('エラー時にトーストメッセージが表示される', async () => {
    const mockError = new Error('Passkey not registered');
    (mockError as any).code = 'passkey_not_registered';
    
    const mockSupabase = {
      auth: {
        signInWithPasskey: vi.fn().mockResolvedValue({
          data: null,
          error: mockError,
        }),
      },
    };
    
    vi.mock('@supabase/supabase-js', () => ({
      createClient: () => mockSupabase,
    }));
    
    render(<LoginScreen />);
    
    // メールアドレス入力とマジックリンク送信（省略）
    
    // PasskeyButtonをクリック
    const passkeyButton = screen.getByText('パスキーでログイン');
    fireEvent.click(passkeyButton);
    
    // エラーメッセージが表示される
    await waitFor(() => {
      expect(screen.getByText('パスキーが登録されていません')).toBeInTheDocument();
    });
  });
});
```

---

### 7.3 E2Eテスト（将来実装）

#### 7.3.1 Playwright設定
```typescript
// e2e/passkey-login.spec.ts
import { test, expect } from '@playwright/test';

test('パスキーログインの完全フロー', async ({ page }) => {
  // ログイン画面へ遷移
  await page.goto('/login');
  
  // メールアドレス入力
  await page.fill('input[type="email"]', 'test@example.com');
  
  // マジックリンク送信
  await page.click('button:has-text("マジックリンクを送信")');
  
  // PasskeyButtonが表示されるまで待機
  await page.waitForSelector('button:has-text("パスキーでログイン")');
  
  // PasskeyButtonをクリック
  await page.click('button:has-text("パスキーでログイン")');
  
  // ブラウザのPasskeyプロンプトをシミュレーション（モック）
  // ※実際のWebAuthn APIはE2Eでモック必要
  
  // ホーム画面へ遷移することを確認
  await expect(page).toHaveURL('/home');
});
```

**注意**: WebAuthn APIのE2Eテストは複雑なため、初期実装では対象外

---

### 7.4 カバレッジ目標

| テスト種別 | 目標カバレッジ | 重要度 |
|-----------|--------------|--------|
| 単体テスト | 90%以上 | 高 |
| 統合テスト | 80%以上 | 中 |
| E2Eテスト | 主要フローのみ | 低（将来実装） |

---

### 7.5 テスト実行コマンド
```bash
# 単体テスト実行
npm run test

# カバレッジ付き実行
npm run test:coverage

# ウォッチモード
npm run test:watch

# 統合テスト実行
npm run test:integration

# E2Eテスト実行（将来実装）
npm run test:e2e
```

---

### 7.6 モック戦略

#### 7.6.1 Supabase Auth のモック
```typescript
// __mocks__/@supabase/supabase-js.ts
export const createClient = vi.fn(() => ({
  auth: {
    signInWithPasskey: vi.fn().mockResolvedValue({
      data: {
        user: { id: '123', email: 'test@example.com' },
        session: { access_token: 'mock-token' },
      },
      error: null,
    }),
  },
}));
```

#### 7.6.2 環境変数のモック
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './tests/setup.ts',
    env: {
      NEXT_PUBLIC_SUPABASE_URL: 'https://mock.supabase.co',
      NEXT_PUBLIC_SUPABASE_ANON_KEY: 'mock-anon-key',
    },
  },
});
```

---

## 📌 テスト戦略の重要な決定

### 決定1: Vitestの採用
- **理由**: Next.js 15との互換性、高速実行

### 決定2: Testing Libraryの使用
- **理由**: ユーザー中心のテスト、アクセシビリティ重視

### 決定3: E2Eテストの段階的実装
- **理由**: WebAuthn APIのモックが複雑、初期フェーズでは対象外

### 決定4: 高カバレッジ目標
- **単体テスト: 90%以上**
- **理由**: コア機能の信頼性確保

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第8章「Storybook設定」へ進む