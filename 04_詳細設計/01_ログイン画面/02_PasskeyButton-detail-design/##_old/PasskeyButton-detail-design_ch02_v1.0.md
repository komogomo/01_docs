# PasskeyButton 詳細設計書 - 第2章：依存関係とインポート

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第2章：依存関係とインポート

### 2.1 外部ライブラリ

#### 2.1.1 React関連
```typescript
import { useState, useCallback } from 'react';
```

| インポート | 用途 | バージョン |
|-----------|------|-----------|
| `useState` | ボタン状態管理（idle/loading/error） | React 19.0.0 |
| `useCallback` | クリックハンドラのメモ化 | React 19.0.0 |

#### 2.1.2 Supabase
```typescript
import { createClient } from '@supabase/supabase-js';
```

| インポート | 用途 | 参照 |
|-----------|------|------|
| `createClient` | Supabase認証クライアント | `harmonet-technical-stack-definition_v3.7.md` |

**注意事項**:
- Supabaseクライアントは親コンポーネントから注入（Props経由）
- コンポーネント内でのクライアント生成は行わない

#### 2.1.3 Lucide React（アイコン）
```typescript
import { Fingerprint, Loader2 } from 'lucide-react';
```

| アイコン | 用途 | 表示タイミング |
|---------|------|---------------|
| `Fingerprint` | パスキー認証アイコン | idle状態 |
| `Loader2` | ローディングスピナー | loading状態 |

**スタイル仕様**:
- サイズ: `w-5 h-5`
- カラー: `text-white`（デフォルト）
- アニメーション: `animate-spin`（Loader2のみ）

---

### 2.2 内部モジュール

#### 2.2.1 型定義
```typescript
import type { PasskeyButtonProps } from './types';
```

**ファイルパス**: `src/features/auth/components/PasskeyButton/types.ts`

#### 2.2.2 ユーティリティ関数（将来的に追加予定）
```typescript
// 現時点では不要
// 将来的にエラーハンドリング用のユーティリティを追加する可能性あり
```

---

### 2.3 型定義

#### 2.3.1 PasskeyButtonProps
```typescript
export interface PasskeyButtonProps {
  /**
   * メールアドレス
   * パスキー認証時の識別子として使用
   */
  email: string;

  /**
   * 認証成功時のコールバック
   */
  onSuccess: () => void;

  /**
   * 認証失敗時のコールバック
   * @param error - エラーオブジェクト
   */
  onError: (error: Error) => void;

  /**
   * ボタンの非活性状態
   * @default false
   */
  disabled?: boolean;

  /**
   * カスタムクラス名
   * Tailwind CSSクラスを追加可能
   */
  className?: string;
}
```

#### 2.3.2 内部状態の型定義
```typescript
type ButtonState = 'idle' | 'loading' | 'error';
```

**状態の意味**:
- `idle`: 初期状態、クリック可能
- `loading`: 認証処理中、非活性
- `error`: エラー発生後（即座にidleに戻る）

---

### 2.4 依存関係図
```
PasskeyButton.tsx
    ├── React (useState, useCallback)
    ├── Lucide React (Fingerprint, Loader2)
    ├── Supabase Client (Props経由で注入)
    └── types.ts (PasskeyButtonProps)
```

---

### 2.5 バージョン互換性

| パッケージ | 最小バージョン | 推奨バージョン | 参照ドキュメント |
|-----------|--------------|--------------|----------------|
| React | 19.0.0 | 19.0.0 | `harmonet-technical-stack-definition_v3.7.md` |
| Next.js | 15.5.x | 15.5.x | `harmonet-technical-stack-definition_v3.7.md` |
| Supabase JS | 2.x | 最新 | `harmonet-technical-stack-definition_v3.7.md` |
| Lucide React | 0.x | 最新 | npm registry |
| TypeScript | 5.x | 5.x | `harmonet-technical-stack-definition_v3.7.md` |

---

### 2.6 Peer Dependencies
```json
{
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

---

### 2.7 開発依存関係（テスト用）
```typescript
// PasskeyButton.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
```

| パッケージ | 用途 |
|-----------|------|
| `@testing-library/react` | コンポーネントテスト |
| `vitest` | テストランナー、モック |

---

## 📌 重要な設計決定

### 決定1: Supabaseクライアントの注入方式
- **Props経由で注入** vs コンポーネント内で生成
- **理由**: テスタビリティとモック容易性

### 決定2: 最小限の依存関係
- **アイコンライブラリのみ外部依存**
- **理由**: バンドルサイズの最小化

### 決定3: 型定義の分離
- **types.ts に分離** vs 同一ファイル内定義
- **理由**: 再利用性と可読性の向上

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第3章「Props定義」へ進む