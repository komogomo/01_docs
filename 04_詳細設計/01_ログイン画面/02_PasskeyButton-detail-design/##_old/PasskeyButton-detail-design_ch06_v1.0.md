# PasskeyButton 詳細設計書 - 第6章：ロジック実装

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第6章：ロジック実装

### 6.1 Passkey認証フロー

#### 6.1.1 全体フロー
```typescript
const handleClick = useCallback(async () => {
  // Step 1: 前提条件チェック
  if (disabled || state === 'loading') return;

  // Step 2: ローディング状態に変更
  setState('loading');

  try {
    // Step 3: Supabaseクライアント初期化
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    // Step 4: Passkey認証API呼び出し
    const { data, error } = await supabase.auth.signInWithPasskey({
      email,
    });

    // Step 5: エラーハンドリング
    if (error) throw error;

    // Step 6: 成功時の処理
    if (data) {
      onSuccess();
    }
  } catch (error) {
    // Step 7: 失敗時の処理
    setState('error');
    onError(error as Error);
    
    // Step 8: エラー状態のクリア
    setTimeout(() => {
      setState('idle');
    }, 100);
  }
}, [email, disabled, state, onSuccess, onError]);
```

---

### 6.2 詳細実装

#### 6.2.1 Step 1: 前提条件チェック
```typescript
if (disabled || state === 'loading') return;
```

**チェック内容**:
| 条件 | 説明 | 処理 |
|------|------|------|
| `disabled === true` | ボタンが非活性 | 早期リターン |
| `state === 'loading'` | 既に処理中 | 早期リターン（二重実行防止） |

**目的**:
- 不要なAPI呼び出しの防止
- ユーザー体験の向上（連打防止）

---

#### 6.2.2 Step 2: ローディング状態に変更
```typescript
setState('loading');
```

**効果**:
- UIがローディング表示に切り替わる
- スピナーアイコン表示
- ボタンが非活性化（`disabled`属性が付与される）

**タイミング**: API呼び出し前

---

#### 6.2.3 Step 3: Supabaseクライアント初期化
```typescript
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

**環境変数**:
| 変数名 | 説明 | 参照 |
|--------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | SupabaseプロジェクトURL | `.env.local` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 匿名キー | `.env.local` |

**注意事項**:
- 環境変数が未設定の場合はビルドエラー
- `!`（Non-null assertion）を使用

**代替案**（将来検討）:
```typescript
// Props経由でクライアントを注入
interface PasskeyButtonProps {
  supabaseClient: SupabaseClient;
  // ...
}
```

---

#### 6.2.4 Step 4: Passkey認証API呼び出し
```typescript
const { data, error } = await supabase.auth.signInWithPasskey({
  email,
});
```

**API仕様**:
- **メソッド**: `signInWithPasskey`
- **パラメータ**: `{ email: string }`
- **戻り値**: `{ data: AuthResponse | null, error: AuthError | null }`

**WebAuthn フロー**:
```
1. ブラウザがPasskeyプロンプトを表示
2. ユーザーが生体認証またはPINで認証
3. Supabaseがセッションを作成
4. レスポンスが返される
```

**参照**: `login-feature-design-ch03_v1.3.1.md`（Passkey認証仕様）

---

#### 6.2.5 Step 5: エラーハンドリング
```typescript
if (error) throw error;
```

**エラーの種類**:
| エラーコード | 説明 | 原因 |
|------------|------|------|
| `passkey_not_registered` | パスキー未登録 | ユーザーがパスキーを登録していない |
| `user_cancelled` | ユーザーキャンセル | 認証プロンプトをキャンセル |
| `invalid_email` | 無効なメールアドレス | メールアドレス形式エラー |
| `network_error` | ネットワークエラー | 接続失敗 |
| `unknown_error` | その他のエラー | 予期しないエラー |

**エラーオブジェクト構造**:
```typescript
interface AuthError extends Error {
  message: string;
  status?: number;
  code?: string;
}
```

---

#### 6.2.6 Step 6: 成功時の処理
```typescript
if (data) {
  onSuccess();
}
```

**data の構造**:
```typescript
interface AuthResponse {
  user: User;
  session: Session;
}
```

**onSuccess実行後の処理**:
- 親コンポーネント（LoginScreen）が画面遷移を実行
- 通常: `/home` へリダイレクト

**セッション情報**:
- Supabaseが自動的にセッションをlocalStorageに保存
- 以降のAPI呼び出しで自動的に認証される

---

#### 6.2.7 Step 7: 失敗時の処理
```typescript
catch (error) {
  setState('error');
  onError(error as Error);
  
  setTimeout(() => {
    setState('idle');
  }, 100);
}
```

**処理順序**:
1. 状態を `'error'` に変更
2. `onError` コールバック実行（親がエラーメッセージ表示）
3. 100ms後に `'idle'` に戻す（ユーザーが再試行可能に）

**onError の役割**:
```typescript
// 親コンポーネントでの実装例
const handleError = (error: Error) => {
  console.error('Passkey authentication failed:', error);
  
  // エラーメッセージの表示
  toast.error(getErrorMessage(error));
  
  // ログ記録（Sentryなど）
  logError('passkey_auth_failed', error);
};
```

---

### 6.3 エラーメッセージマッピング

#### 6.3.1 ユーザー向けメッセージ
```typescript
function getErrorMessage(error: Error): string {
  const code = (error as AuthError).code;
  
  switch (code) {
    case 'passkey_not_registered':
      return 'パスキーが登録されていません。マジックリンクでログインしてください。';
    
    case 'user_cancelled':
      return '認証がキャンセルされました。';
    
    case 'invalid_email':
      return 'メールアドレスが無効です。';
    
    case 'network_error':
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    
    default:
      return '認証に失敗しました。もう一度お試しください。';
  }
}
```

**参照**: `common-error-handling_v1.0.md`

---

### 6.4 パフォーマンス最適化

#### 6.4.1 useCallback によるメモ化
```typescript
const handleClick = useCallback(async () => {
  // ...
}, [email, disabled, state, onSuccess, onError]);
```

**効果**:
- 親コンポーネントの再レンダリング時に関数が再生成されない
- 不要な再レンダリングの防止

**依存配列の最適化**:
- 必要最小限の依存のみ含める
- Props の変更を適切に検知

---

#### 6.4.2 早期リターンによる最適化
```typescript
if (disabled || state === 'loading') return;
```

**効果**:
- 不要なAPI呼び出しを防止
- リソース節約

---

### 6.5 セキュリティ考慮事項

#### 6.5.1 環境変数の保護
```typescript
// ✅ 正しい: NEXT_PUBLIC_ プレフィックス
process.env.NEXT_PUBLIC_SUPABASE_URL

// ❌ 誤り: 秘密鍵をクライアントで使用
process.env.SUPABASE_SERVICE_ROLE_KEY // サーバーサイドのみ
```

**参照**: `login-feature-design-ch06_v1.1.md`（セキュリティ仕様）

#### 6.5.2 XSS 対策
```typescript
// React が自動的にエスケープするため追加対応不要
<span>{email}</span> // 安全
```

#### 6.5.3 CSRF 対策

- Supabase Auth が自動的に対応
- カスタムトークン実装は不要

---

### 6.6 ロギング実装

#### 6.6.1 開発環境でのロギング
```typescript
if (process.env.NODE_ENV === 'development') {
  console.log('[PasskeyButton] Authentication started', { email });
  console.log('[PasskeyButton] Authentication result', { data, error });
}
```

#### 6.6.2 本番環境でのロギング
```typescript
// Sentryなどのエラートラッキングツールへ送信
if (error) {
  Sentry.captureException(error, {
    tags: {
      component: 'PasskeyButton',
      email: email, // PII注意
    },
  });
}
```

**注意**: メールアドレスは個人情報（PII）のため、ログ記録時は慎重に扱う

---

## 📌 設計上の重要な決定

### 決定1: Supabaseクライアントの生成方式
- **コンポーネント内で生成** vs Props注入
- **選択**: コンポーネント内で生成
- **理由**: シンプルさ優先、将来的にProps注入へ移行可能

### 決定2: エラー状態の自動クリア
- **タイミング**: 100ms後
- **理由**: ユーザーが即座に再試行可能

### 決定3: エラーハンドリングの責務分離
- **PasskeyButton**: エラーの検知とコールバック実行
- **親コンポーネント**: エラーメッセージの表示とログ記録
- **理由**: 単一責任の原則

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第7章「テスト戦略」へ進む