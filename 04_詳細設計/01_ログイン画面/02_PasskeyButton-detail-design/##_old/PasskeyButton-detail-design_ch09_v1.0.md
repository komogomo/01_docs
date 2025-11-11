# PasskeyButton 詳細設計書 - 第8章：Storybook設定

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第8章：Storybook設定

### 8.1 Story定義

#### 8.1.1 基本設定
```typescript
// PasskeyButton.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { PasskeyButton } from './PasskeyButton';

const meta: Meta<typeof PasskeyButton> = {
  title: 'Features/Auth/PasskeyButton',
  component: PasskeyButton,
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'パスキー認証を開始するボタンコンポーネント',
      },
    },
  },
  argTypes: {
    email: {
      control: 'text',
      description: 'メールアドレス（パスキー認証の識別子）',
    },
    onSuccess: {
      action: 'onSuccess',
      description: '認証成功時のコールバック',
    },
    onError: {
      action: 'onError',
      description: '認証失敗時のコールバック',
    },
    disabled: {
      control: 'boolean',
      description: 'ボタンの非活性状態',
    },
    className: {
      control: 'text',
      description: 'カスタムクラス名',
    },
  },
};

export default meta;
type Story = StoryObj<typeof PasskeyButton>;
```

---

#### 8.1.2 デフォルトStory
```typescript
export const Default: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('Success!'),
    onError: (error) => console.error('Error:', error),
  },
};
```

**表示内容**:
- 通常状態のPasskeyButton
- クリック可能
- デフォルトスタイル適用

---

#### 8.1.3 Disabled Story
```typescript
export const Disabled: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('Success!'),
    onError: (error) => console.error('Error:', error),
    disabled: true,
  },
};
```

**表示内容**:
- 非活性状態
- グレーアウト表示
- クリック不可

---

#### 8.1.4 Loading Story
```typescript
export const Loading: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('Success!'),
    onError: (error) => console.error('Error:', error),
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');
    
    // ボタンをクリックしてloading状態にする
    await userEvent.click(button);
  },
};
```

**表示内容**:
- ローディング状態
- スピナーアニメーション
- "認証中..." テキスト表示

---

#### 8.1.5 CustomStyle Story
```typescript
export const CustomStyle: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('Success!'),
    onError: (error) => console.error('Error:', error),
    className: 'w-full max-w-md mt-4',
  },
};
```

**表示内容**:
- カスタムスタイル適用
- 幅指定（w-full max-w-md）
- マージン追加（mt-4）

---

### 8.2 インタラクション

#### 8.2.1 Success シナリオ
```typescript
import { expect, userEvent, within } from '@storybook/test';

export const SuccessScenario: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('✅ 認証成功！'),
    onError: (error) => console.error('❌ 認証失敗:', error),
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    
    // ボタンを取得
    const button = canvas.getByRole('button', { name: 'パスキーでログイン' });
    
    // 初期状態の確認
    expect(button).toBeEnabled();
    expect(button).toHaveTextContent('パスキーでログイン');
    
    // クリック
    await userEvent.click(button);
    
    // loading状態の確認
    expect(button).toHaveAttribute('aria-busy', 'true');
    expect(canvas.getByText('認証中...')).toBeInTheDocument();
    
    // 成功コールバックが呼ばれることを確認（モック環境）
    // ※実際のSupabase APIはモック
  },
};
```

---

#### 8.2.2 Error シナリオ
```typescript
export const ErrorScenario: Story = {
  args: {
    email: 'invalid@example.com',
    onSuccess: () => console.log('✅ 認証成功！'),
    onError: (error) => console.error('❌ 認証失敗:', error.message),
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    
    // ボタンをクリック
    const button = canvas.getByRole('button');
    await userEvent.click(button);
    
    // loading状態を確認
    expect(button).toHaveAttribute('aria-busy', 'true');
    
    // エラー後、idle状態に戻ることを確認
    // ※モック環境では即座に戻る
    await new Promise((resolve) => setTimeout(resolve, 200));
    expect(button).toHaveAttribute('aria-busy', 'false');
  },
};
```

---

#### 8.2.3 Disabled インタラクション
```typescript
export const DisabledInteraction: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => console.log('Success!'),
    onError: (error) => console.error('Error:', error),
    disabled: true,
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');
    
    // ボタンが非活性であることを確認
    expect(button).toBeDisabled();
    
    // クリックしても何も起こらないことを確認
    await userEvent.click(button);
    
    // コールバックが呼ばれないことを確認
    expect(args.onSuccess).not.toHaveBeenCalled();
    expect(args.onError).not.toHaveBeenCalled();
  },
};
```

---

### 8.3 デコレーター設定

#### 8.3.1 レイアウトデコレーター
```typescript
const meta: Meta<typeof PasskeyButton> = {
  // ...
  decorators: [
    (Story) => (
      <div style={{ 
        padding: '2rem',
        backgroundColor: '#f5f5f5',
        minHeight: '200px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
        <Story />
      </div>
    ),
  ],
};
```

**効果**:
- ボタンが中央配置される
- 背景色でボタンが見やすくなる
- 十分なスペースが確保される

---

#### 8.3.2 Supabase モックデコレーター
```typescript
import { fn } from '@storybook/test';

const meta: Meta<typeof PasskeyButton> = {
  // ...
  decorators: [
    (Story) => {
      // Supabase Auth のモック
      const mockSupabase = {
        auth: {
          signInWithPasskey: fn().mockResolvedValue({
            data: {
              user: { id: '123', email: 'test@example.com' },
              session: { access_token: 'mock-token' },
            },
            error: null,
          }),
        },
      };
      
      // グローバルモックの設定
      window.mockSupabase = mockSupabase;
      
      return <Story />;
    },
  ],
};
```

---

### 8.4 Docs ページ設定

#### 8.4.1 コンポーネント説明
```typescript
const meta: Meta<typeof PasskeyButton> = {
  // ...
  parameters: {
    docs: {
      description: {
        component: `
## PasskeyButton

パスキー（WebAuthn）認証を開始するボタンコンポーネントです。

### 主要機能
- パスキー認証フローの開始
- 認証処理中の視覚的フィードバック
- エラーハンドリング
- アクセシビリティ対応

### 使用例
\`\`\`tsx
<PasskeyButton
  email="user@example.com"
  onSuccess={() => router.push('/home')}
  onError={(error) => toast.error(error.message)}
/>
\`\`\`

### 参照ドキュメント
- \`login-feature-design-ch03_v1.3.1.md\`（Passkey認証仕様）
- \`common-design-system_v1.1.md\`（デザインシステム）
        `,
      },
    },
  },
};
```

---

#### 8.4.2 Props ドキュメント
```typescript
const meta: Meta<typeof PasskeyButton> = {
  // ...
  argTypes: {
    email: {
      control: 'text',
      description: 'メールアドレス（パスキー認証の識別子）',
      table: {
        type: { summary: 'string' },
        defaultValue: { summary: 'なし' },
      },
    },
    onSuccess: {
      action: 'onSuccess',
      description: '認証成功時のコールバック',
      table: {
        type: { summary: '() => void' },
      },
    },
    onError: {
      action: 'onError',
      description: '認証失敗時のコールバック',
      table: {
        type: { summary: '(error: Error) => void' },
      },
    },
    disabled: {
      control: 'boolean',
      description: 'ボタンの非活性状態',
      table: {
        type: { summary: 'boolean' },
        defaultValue: { summary: 'false' },
      },
    },
    className: {
      control: 'text',
      description: 'カスタムクラス名（Tailwind CSS）',
      table: {
        type: { summary: 'string' },
        defaultValue: { summary: 'undefined' },
      },
    },
  },
};
```

---

### 8.5 アクセシビリティチェック

#### 8.5.1 a11y アドオン設定
```typescript
const meta: Meta<typeof PasskeyButton> = {
  // ...
  parameters: {
    a11y: {
      config: {
        rules: [
          {
            id: 'color-contrast',
            enabled: true,
          },
          {
            id: 'button-name',
            enabled: true,
          },
        ],
      },
    },
  },
};
```

**チェック項目**:
- カラーコントラスト比（WCAG AA基準）
- ボタンに適切な名前が付いているか
- ARIA属性の適切な使用

---

### 8.6 ビジュアルリグレッションテスト（将来実装）

#### 8.6.1 Chromatic 設定
```typescript
// .storybook/main.ts
export default {
  // ...
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-interactions',
    '@storybook/addon-a11y',
    '@chromatic-com/storybook', // 追加
  ],
};
```

**Story設定**:
```typescript
export const VisualTest: Story = {
  args: {
    email: 'user@example.com',
    onSuccess: () => {},
    onError: () => {},
  },
  parameters: {
    chromatic: {
      viewports: [320, 768, 1024], // モバイル、タブレット、デスクトップ
    },
  },
};
```

---

### 8.7 実行コマンド
```bash
# Storybook起動
npm run storybook

# Storybookビルド
npm run build-storybook

# インタラクションテスト実行
npm run test-storybook

# ビジュアルリグレッションテスト（Chromatic）
npm run chromatic
```

---

## 📌 Storybook設定の重要な決定

### 決定1: 充実したStory構成
- **Default, Disabled, Loading, Error など**
- **理由**: すべての状態を視覚的に確認可能

### 決定2: インタラクションテストの実装
- **play関数の活用**
- **理由**: 手動テストの削減、回帰テスト自動化

### 決定3: アクセシビリティチェックの統合
- **a11yアドオンの有効化**
- **理由**: WCAG準拠の継続的な確認

### 決定4: Docs ページの充実
- **使用例、Props説明、参照ドキュメント**
- **理由**: 開発者オンボーディングの効率化

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第9章「今後の拡張可能性」へ進む