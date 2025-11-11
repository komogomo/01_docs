# PasskeyButton 詳細設計書 - 第4章：内部状態とフック

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第4章：内部状態とフック

### 4.1 状態管理

#### 4.1.1 ButtonState型定義
```typescript
type ButtonState = 'idle' | 'loading' | 'error';
```

**状態の説明**:
| 状態 | 説明 | UI表示 | 遷移元 | 遷移先 |
|------|------|--------|--------|--------|
| `idle` | 初期状態・待機中 | 通常ボタン | - | `loading` |
| `loading` | 認証処理中 | スピナー表示 | `idle` | `idle` or `error` |
| `error` | エラー発生 | エラー表示後即座にidle | `loading` | `idle` |

#### 4.1.2 useState フック
```typescript
const [state, setState] = useState<ButtonState>('idle');
```

**初期値**: `'idle'`

**状態更新パターン**:
```typescript
// クリック時
setState('loading');

// 認証成功時
setState('idle'); // onSuccess実行後、画面遷移するため実質不要

// 認証失敗時
setState('error');
setTimeout(() => setState('idle'), 100); // 即座にidleに戻す
```

---

### 4.2 カスタムフック

#### 4.2.1 useCallback: handleClick
```typescript
const handleClick = useCallback(async () => {
  if (disabled || state === 'loading') return;

  setState('loading');

  try {
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    const { data, error } = await supabase.auth.signInWithPasskey({
      email,
    });

    if (error) throw error;

    if (data) {
      onSuccess();
    }
  } catch (error) {
    setState('error');
    onError(error as Error);
    
    // エラー状態を即座にクリア
    setTimeout(() => {
      setState('idle');
    }, 100);
  }
}, [email, disabled, state, onSuccess, onError]);
```

**依存配列**:
- `email`: メールアドレスの変更を検知
- `disabled`: 非活性状態の変更を検知
- `state`: 現在の状態を参照
- `onSuccess`: 成功コールバックの変更を検知
- `onError`: エラーコールバックの変更を検知

**メモ化の理由**:
- 不要な再レンダリング防止
- イベントハンドラの安定性確保

---

### 4.3 状態遷移フロー
```
[初期状態: idle]
    ↓
[ユーザークリック]
    ↓
[handleClick実行]
    ↓
[setState('loading')]
    ↓
[Supabase Auth API呼び出し]
    ↓
┌─────────────────────────────┐
│ 認証成功                     │
│ - onSuccess()実行            │
│ - setState('idle')          │ ※実質的に画面遷移するため不要
│ - 画面遷移                   │
└─────────────────────────────┘
         OR
┌─────────────────────────────┐
│ 認証失敗                     │
│ - setState('error')         │
│ - onError(error)実行        │
│ - 100ms後にsetState('idle')│
└─────────────────────────────┘
```

---

### 4.4 副作用管理

#### 4.4.1 useEffect（不使用）

PasskeyButtonでは `useEffect` を使用しません。

**理由**:
- すべての状態変更がユーザーアクション（クリック）起点
- 副作用は `handleClick` 内で完結
- クリーンアップ処理が不要

#### 4.4.2 タイマー処理
```typescript
// エラー状態のクリア
setTimeout(() => {
  setState('idle');
}, 100);
```

**注意事項**:
- コンポーネントアンマウント時のクリーンアップは不要
  - 理由: 100msと極めて短時間
  - エラー後は通常、画面遷移またはユーザー再操作

**改善案（将来的に検討）**:
```typescript
useEffect(() => {
  let timeoutId: NodeJS.Timeout;

  if (state === 'error') {
    timeoutId = setTimeout(() => {
      setState('idle');
    }, 100);
  }

  return () => {
    if (timeoutId) clearTimeout(timeoutId);
  };
}, [state]);
```

---

### 4.5 パフォーマンス最適化

#### 4.5.1 useCallback の活用
```typescript
const handleClick = useCallback(async () => {
  // ...認証処理
}, [email, disabled, state, onSuccess, onError]);
```

**効果**:
- 親コンポーネントの再レンダリング時にhandleClickが再生成されない
- イベントハンドラの参照が安定

#### 4.5.2 不要な状態更新の防止
```typescript
const handleClick = useCallback(async () => {
  // 既にloading中の場合は何もしない
  if (state === 'loading') return;
  
  // disabled時は何もしない
  if (disabled) return;

  setState('loading');
  // ...
}, [/* ... */]);
```

---

### 4.6 エラーハンドリング

#### 4.6.1 try-catch構造
```typescript
try {
  const { data, error } = await supabase.auth.signInWithPasskey({ email });
  
  if (error) throw error;
  
  if (data) {
    onSuccess();
  }
} catch (error) {
  setState('error');
  onError(error as Error);
  
  setTimeout(() => setState('idle'), 100);
}
```

#### 4.6.2 エラー種別

| エラー種別 | 原因 | 対応 |
|-----------|------|------|
| `AuthError` | Supabase認証エラー | onError実行、エラーメッセージ表示 |
| `NetworkError` | ネットワーク接続失敗 | onError実行、再試行促進 |
| `UnknownError` | その他のエラー | onError実行、一般的なエラーメッセージ |

---

### 4.7 状態の初期化

#### 4.7.1 コンポーネントマウント時
```typescript
const [state, setState] = useState<ButtonState>('idle');
```

**初期状態**: 常に `'idle'`

#### 4.7.2 Props変更時
```typescript
// emailが変更されても状態はリセットしない
// 理由: ユーザーの意図的な操作のみで状態を変更
```

**設計判断**:
- Props変更では状態リセットしない
- 状態リセットはユーザーアクション（クリック）のみ

---

## 📌 設計上の重要な決定

### 決定1: useEffect不使用
- **理由**: すべての状態変更がユーザーアクション起点
- **利点**: シンプルな状態管理

### 決定2: エラー状態の即座クリア
- **仕様**: エラー発生から100ms後にidleに戻る
- **理由**: ユーザーが即座に再試行可能

### 決定3: useCallback依存配列の完全性
- **すべての外部依存を含める**
- **理由**: React Hooksのルールに準拠、予期しないバグ防止

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第5章「UI構造」へ進む