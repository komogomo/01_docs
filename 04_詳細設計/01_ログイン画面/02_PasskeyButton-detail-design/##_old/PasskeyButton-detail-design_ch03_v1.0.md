# PasskeyButton 詳細設計書 - 第3章：Props定義

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第3章：Props定義

### 3.1 Props Interface
```typescript
export interface PasskeyButtonProps {
  /**
   * メールアドレス
   * パスキー認証時の識別子として使用
   * @required
   */
  email: string;

  /**
   * 認証成功時のコールバック
   * @required
   */
  onSuccess: () => void;

  /**
   * 認証失敗時のコールバック
   * @param error - エラーオブジェクト
   * @required
   */
  onError: (error: Error) => void;

  /**
   * ボタンの非活性状態
   * @optional
   * @default false
   */
  disabled?: boolean;

  /**
   * カスタムクラス名
   * Tailwind CSSクラスを追加可能
   * @optional
   */
  className?: string;
}
```

---

### 3.2 各Propsの詳細

#### 3.2.1 email (必須)

**型**: `string`

**用途**:
- パスキー認証時のユーザー識別子
- Supabase Auth APIに渡される

**バリデーション**:
- 親コンポーネント（LoginScreen）で実施済み
- PasskeyButton内では追加バリデーション不要

**使用例**:
```typescript
<PasskeyButton
  email="user@example.com"
  onSuccess={handleSuccess}
  onError={handleError}
/>
```

**制約事項**:
- 空文字列は許可しない（親で検証）
- メールアドレス形式は親で検証済み

---

#### 3.2.2 onSuccess (必須)

**型**: `() => void`

**用途**:
- パスキー認証成功時に実行されるコールバック
- 通常、ホーム画面へのリダイレクト処理を含む

**実行タイミング**:
```typescript
// Supabase Auth成功直後
const { data, error } = await supabase.auth.signInWithPasskey({ email });
if (data) {
  onSuccess(); // ← ここで実行
}
```

**使用例**:
```typescript
const handleSuccess = () => {
  router.push('/home');
};

<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
/>
```

**注意事項**:
- 非同期処理は親コンポーネントで管理
- PasskeyButton内では同期的に実行

---

#### 3.2.3 onError (必須)

**型**: `(error: Error) => void`

**用途**:
- パスキー認証失敗時に実行されるコールバック
- エラーメッセージの表示やログ記録に使用

**実行タイミング**:
```typescript
// Supabase Auth失敗時
const { data, error } = await supabase.auth.signInWithPasskey({ email });
if (error) {
  onError(error); // ← ここで実行
}
```

**エラーオブジェクト構造**:
```typescript
interface AuthError extends Error {
  message: string;
  status?: number;
  code?: string;
}
```

**使用例**:
```typescript
const handleError = (error: Error) => {
  console.error('Passkey authentication failed:', error);
  toast.error('認証に失敗しました。もう一度お試しください。');
};

<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
/>
```

**エラーの種類**:
| エラーコード | 説明 | ユーザー表示メッセージ |
|------------|------|---------------------|
| `passkey_not_registered` | パスキー未登録 | "パスキーが登録されていません" |
| `user_cancelled` | ユーザーがキャンセル | "認証がキャンセルされました" |
| `network_error` | ネットワークエラー | "ネットワークエラーが発生しました" |
| `unknown_error` | その他のエラー | "認証に失敗しました" |

---

#### 3.2.4 disabled (オプション)

**型**: `boolean`  
**デフォルト値**: `false`

**用途**:
- ボタンの非活性化制御
- メールアドレス未入力時などに使用

**動作**:
- `true`: ボタンクリック不可、視覚的に非活性表示
- `false`: 通常動作

**使用例**:
```typescript
<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
  disabled={!email || isLoading}
/>
```

**スタイル変更**:
```typescript
// disabled=true の場合
className="bg-gray-300 text-gray-500 cursor-not-allowed"
```

---

#### 3.2.5 className (オプション)

**型**: `string`  
**デフォルト値**: `undefined`

**用途**:
- カスタムTailwind CSSクラスの追加
- レイアウト調整（margin, paddingなど）

**使用例**:
```typescript
<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
  className="mt-4 w-full"
/>
```

**制約事項**:
- デフォルトスタイルを上書きしない
- レイアウト関連のクラスのみ推奨

**推奨クラス**:
- `mt-*`, `mb-*`: マージン調整
- `w-*`: 幅調整
- `mx-auto`: 中央配置

**非推奨クラス**:
- `bg-*`: 背景色（内部で管理）
- `text-*`: テキスト色（内部で管理）
- `p-*`: パディング（内部で管理）

---

### 3.3 Props使用パターン

#### 3.3.1 基本パターン
```typescript
<PasskeyButton
  email="user@example.com"
  onSuccess={() => router.push('/home')}
  onError={(error) => console.error(error)}
/>
```

#### 3.3.2 非活性制御パターン
```typescript
<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
  disabled={!email || isProcessing}
/>
```

#### 3.3.3 カスタムスタイルパターン
```typescript
<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
  className="mt-6 w-full max-w-md mx-auto"
/>
```

---

### 3.4 Props検証

#### 3.4.1 TypeScript型チェック
```typescript
// ✅ 正常: すべての必須Propsが提供されている
<PasskeyButton
  email="user@example.com"
  onSuccess={() => {}}
  onError={(error) => {}}
/>

// ❌ エラー: emailが欠落
<PasskeyButton
  onSuccess={() => {}}
  onError={(error) => {}}
/>

// ❌ エラー: onSuccessが欠落
<PasskeyButton
  email="user@example.com"
  onError={(error) => {}}
/>
```

#### 3.4.2 実行時検証（開発モード）
```typescript
if (process.env.NODE_ENV === 'development') {
  if (!email) {
    console.warn('PasskeyButton: email prop is required');
  }
  if (typeof onSuccess !== 'function') {
    console.warn('PasskeyButton: onSuccess must be a function');
  }
  if (typeof onError !== 'function') {
    console.warn('PasskeyButton: onError must be a function');
  }
}
```

---

## 📌 設計上の重要な決定

### 決定1: コールバック駆動設計
- **Props**: `onSuccess`, `onError`
- **理由**: 親コンポーネントが画面遷移やエラー表示を制御

### 決定2: 最小限のProps
- **不要なProps**: `size`, `variant`, `theme`
- **理由**: 単一用途コンポーネントとして設計

### 決定3: className の制限的使用
- **許可**: レイアウト調整のみ
- **理由**: デザインシステムの一貫性維持

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第4章「内部状態とフック」へ進む