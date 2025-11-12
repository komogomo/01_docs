# PasskeyButton 詳細設計書 - 第8章：Storybook設定（v1.1 改訂版）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYBUTTON-CH08  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / PasskeyButton-detail-design_v1.4.md  
**Reviewer:** TKD  
**Status:** Phase9 正式仕様整合版  

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
        component: 'Corbado SDK + Supabase 認証に対応したパスキー認証ボタンコンポーネント',
      },
    },
  },
  argTypes: {
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
      description: 'カスタムクラス名（Tailwind CSS）',
    },
  },
};
export default meta;
type Story = StoryObj<typeof PasskeyButton>;
```

---

#### 8.1.2 Default Story
```typescript
export const Default: Story = {
  args: {
    onSuccess: () => console.log('✅ Success!'),
    onError: (e) => console.error('❌ Error:', e),
  },
};
```

---

#### 8.1.3 Loading Story
```typescript
export const Loading: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');
    await userEvent.click(button);
    expect(button).toHaveAttribute('aria-busy', 'true');
  },
};
```

---

#### 8.1.4 Disabled Story
```typescript
export const Disabled: Story = {
  args: { disabled: true },
};
```

---

### 8.2 インタラクション

#### 8.2.1 Success シナリオ
```typescript
import { expect, userEvent, within } from '@storybook/test';

export const SuccessScenario: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button', { name: 'パスキーでログイン' });
    await userEvent.click(button);
    expect(button).toHaveAttribute('aria-busy', 'true');
  },
};
```

---

#### 8.2.2 Error シナリオ
```typescript
export const ErrorScenario: Story = {
  args: {
    onError: (error) => console.error('❌ 認証失敗:', error.message),
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');
    await userEvent.click(button);
    expect(button).toHaveAttribute('aria-busy', 'true');
  },
};
```

---

### 8.3 デコレーター設定

#### 8.3.1 Supabase + Corbado モック
```typescript
import { fn } from '@storybook/test';

const meta: Meta<typeof PasskeyButton> = {
  decorators: [
    (Story) => {
      const mockCorbado = {
        load: fn().mockResolvedValue(true),
        passkey: {
          login: fn().mockResolvedValue({ success: true, id_token: 'mock_token' }),
        },
      };
      const mockSupabase = {
        auth: {
          signInWithIdToken: fn().mockResolvedValue({ error: null }),
        },
      };
      window.mockCorbado = mockCorbado;
      window.mockSupabase = mockSupabase;
      return <Story />;
    },
  ],
};
```

---

### 8.4 Docs ページ設定

```typescript
const meta: Meta<typeof PasskeyButton> = {
  parameters: {
    docs: {
      description: {
        component: `
## PasskeyButton

Corbado SDK を利用したパスキー認証ボタンコンポーネント。  
Supabase Auth と連携し、セッション確立までを一括処理します。

### 使用例
\`\`\`tsx
<PasskeyButton
  onSuccess={() => router.push('/home')}
  onError={(error) => toast.error(error.message)}
/>
\`\`\`

### 参照ドキュメント
- harmoNet-technical-stack-definition_v4.0.md
- PasskeyButton-detail-design_v1.4.md
        `,
      },
    },
  },
};
```

---

### 8.5 アクセシビリティ設定

```typescript
const meta: Meta<typeof PasskeyButton> = {
  parameters: {
    a11y: {
      config: {
        rules: [
          { id: 'color-contrast', enabled: true },
          { id: 'button-name', enabled: true },
        ],
      },
    },
  },
};
```

---

### 8.6 実行コマンド
```bash
npm run storybook
npm run build-storybook
npm run test-storybook
npm run chromatic
```

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-01-10 | 初版（Supabase.signInWithPasskey構成） |
| v1.1 | 2025-11-10 | Corbado SDK + Supabase.signInWithIdToken対応。Docs整備・モック統合・a11y設定更新。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  

