# MagicLinkForm 詳細設計書 - 第2章：構造設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH02  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第2章 構造設計

### 2.1 Props / State 定義

#### 2.1.1 Props
```typescript
export interface MagicLinkFormProps {
  className?: string;               // カスタムクラス名
  onSent?: () => void;              // 送信成功時コールバック
  onError?: (error: MagicLinkError) => void; // 送信失敗時コールバック
}
```

#### 2.1.2 State
```typescript
type MagicLinkState =
  | 'idle'           // 初期状態
  | 'sending'        // Supabaseへリクエスト中
  | 'sent'           // 成功（メール送信完了）
  | 'error_invalid'  // 入力エラー（形式不正）
  | 'error_network'  // 通信・API失敗
  | 'error_unknown'; // 不明な例外
```

#### 2.1.3 MagicLinkError 構造
```typescript
export interface MagicLinkError {
  code: string;       // エラーコード
  message: string;    // 表示メッセージ（i18n対応）
  type: MagicLinkState; // エラー種別
}
```

---

### 2.2 コンポーネント構造概要

```typescript
'use client';

import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useI18n } from '@/components/common/StaticI18nProvider';
import { Button, Input } from '@/components/ui';
import { Loader2, Mail, CheckCircle, AlertCircle } from 'lucide-react';

export function MagicLinkForm({ className, onSent, onError }: MagicLinkFormProps) {
  const supabase = createClient();
  const { t } = useI18n();

  const [email, setEmail] = useState('');
  const [state, setState] = useState<MagicLinkState>('idle');
  const [error, setError] = useState<MagicLinkError | null>(null);

  // 詳細ロジックは第3章に記載
  ...
}
```

---

### 2.3 依存関係構造

| 区分 | 依存モジュール | 用途 |
|------|----------------|------|
| 認証 | `@supabase/supabase-js` | Magic Link送信（`signInWithOtp`） |
| UI | `@/components/ui` | 共通UI部品（Button / Input） |
| i18n | `StaticI18nProvider` | 翻訳処理 |
| アイコン | `lucide-react` | 状態アイコン表示 |

---

### 2.4 コンポーネント階層（論理構造）

```
MagicLinkForm
 ├─ Input（メール入力）
 ├─ Button（送信ボタン）
 │   ├─ Loader2（送信中）
 │   ├─ CheckCircle（送信成功）
 │   ├─ AlertCircle（エラー）
 │   └─ Mail（初期）
 └─ <p>（補足メッセージ）
```

---

### 2.5 状態遷移概要

| 現在状態 | 次状態 | トリガー | 説明 |
|-----------|---------|----------|------|
| idle | sending | ボタンクリック | Magic Link送信開始 |
| sending | sent | 成功時 | メール送信完了 |
| sending | error_network | 失敗時 | Supabase通信エラー |
| idle | error_invalid | 入力形式不正 | メールアドレス不正 |

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。State型拡張、Error構造追加、依存構成整理。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第3章 ロジック設計（ch03）へ進む
