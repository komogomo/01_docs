# PasskeyButton 詳細設計書 - 第5章：UI構造

**バージョン**: v1.0  
**最終更新日**: 2025-01-10  
**担当**: Claude (Design Agent)  
**レビュー**: TKD (Project Owner)

---

## 第5章：UI構造

### 5.1 コンポーネント構造

#### 5.1.1 JSX構造
```tsx
<button
  onClick={handleClick}
  disabled={disabled || state === 'loading'}
  className={/* 動的スタイル */}
  aria-label="パスキーでログイン"
  aria-busy={state === 'loading'}
  type="button"
>
  {state === 'loading' ? (
    <>
      <Loader2 className="w-5 h-5 animate-spin" />
      <span>認証中...</span>
    </>
  ) : (
    <>
      <Fingerprint className="w-5 h-5" />
      <span>パスキーでログイン</span>
    </>
  )}
</button>
```

#### 5.1.2 DOM階層
```
button (ルート要素)
├── Loader2 (loading時) / Fingerprint (idle時)
│   └── SVGアイコン
└── span (テキスト)
    └── "認証中..." / "パスキーでログイン"
```

---

### 5.2 スタイリング仕様

#### 5.2.1 基本スタイル（共通）
```typescript
const baseStyles = `
  flex items-center justify-center gap-2
  px-6 py-3
  rounded-lg
  font-medium
  transition-all duration-200
  focus-visible:outline-none
  focus-visible:ring-2
  focus-visible:ring-blue-500
  focus-visible:ring-offset-2
`;
```

**説明**:
| クラス | 用途 |
|--------|------|
| `flex items-center justify-center` | 中央配置（アイコン+テキスト） |
| `gap-2` | アイコンとテキストの間隔（8px） |
| `px-6 py-3` | 内側余白（24px / 12px） |
| `rounded-lg` | 角丸（8px） |
| `font-medium` | フォントウェイト（500） |
| `transition-all duration-200` | アニメーション（200ms） |
| `focus-visible:*` | キーボードフォーカス表示 |

#### 5.2.2 状態別スタイル

##### idle状態（通常）
```typescript
const idleStyles = `
  bg-blue-600
  text-white
  hover:bg-blue-700
  active:bg-blue-800
  cursor-pointer
`;
```

**カラー仕様**:
- 背景: `#2563EB` (Apple Blue)
- テキスト: `#FFFFFF`
- ホバー: `#1D4ED8`
- アクティブ: `#1E40AF`

##### loading状態
```typescript
const loadingStyles = `
  bg-blue-600
  text-white
  cursor-wait
`;
```

**特徴**:
- ホバーエフェクトなし
- カーソルが `wait` に変更
- スピナーアニメーション実行中

##### disabled状態
```typescript
const disabledStyles = `
  bg-gray-300
  text-gray-500
  cursor-not-allowed
`;
```

**カラー仕様**:
- 背景: `#D1D5DB`
- テキスト: `#6B7280`

#### 5.2.3 動的クラス生成
```typescript
const className = `
  ${baseStyles}
  ${state === 'loading' ? loadingStyles : ''}
  ${disabled ? disabledStyles : idleStyles}
  ${props.className || ''}
`.trim().replace(/\s+/g, ' ');
```

**優先順位**:
1. 基本スタイル（常に適用）
2. 状態別スタイル（loading / disabled / idle）
3. カスタムクラス（Props経由）

---

### 5.3 アイコン仕様

#### 5.3.1 Fingerprint アイコン（idle状態）
```tsx
<Fingerprint className="w-5 h-5" />
```

**仕様**:
- サイズ: 20x20px
- カラー: 継承（`text-white`）
- ストローク幅: デフォルト（2px）

#### 5.3.2 Loader2 アイコン（loading状態）
```tsx
<Loader2 className="w-5 h-5 animate-spin" />
```

**仕様**:
- サイズ: 20x20px
- カラー: 継承（`text-white`）
- アニメーション: 回転（1秒/周）

**アニメーション詳細**:
```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

---

### 5.4 テキスト仕様

#### 5.4.1 フォント設定
```typescript
// グローバル設定（tailwind.config.js）
fontFamily: {
  sans: ['BIZ UD Gothic', 'sans-serif'],
}
```

**適用箇所**: すべてのテキスト

#### 5.4.2 テキスト内容

| 状態 | 表示テキスト | 言語 |
|------|------------|------|
| idle | "パスキーでログイン" | 日本語 |
| loading | "認証中..." | 日本語 |

**国際化対応**（将来実装）:
```typescript
// i18n対応時
const text = {
  ja: { idle: 'パスキーでログイン', loading: '認証中...' },
  en: { idle: 'Sign in with Passkey', loading: 'Authenticating...' },
  zh: { idle: '使用密钥登录', loading: '认证中...' },
};
```

---

### 5.5 レスポンシブ対応

#### 5.5.1 ブレークポイント

| デバイス | 幅 | 調整内容 |
|---------|-----|----------|
| モバイル | < 640px | デフォルト設定 |
| タブレット | 640px ~ 1024px | デフォルト設定 |
| デスクトップ | > 1024px | デフォルト設定 |

**結論**: レスポンシブ調整は不要
- 理由: ボタンサイズは固定で問題なし

#### 5.5.2 親コンポーネントでの幅制御
```tsx
// LoginScreen.tsx
<PasskeyButton
  email={email}
  onSuccess={handleSuccess}
  onError={handleError}
  className="w-full sm:w-auto sm:min-w-[200px]"
/>
```

**推奨設定**:
- モバイル: `w-full`（親要素いっぱい）
- デスクトップ: `w-auto` + 最小幅指定

---

### 5.6 アクセシビリティ属性

#### 5.6.1 ARIA属性
```tsx
<button
  aria-label="パスキーでログイン"
  aria-busy={state === 'loading'}
  role="button"
  type="button"
>
```

**属性の説明**:
| 属性 | 値 | 用途 |
|------|-----|------|
| `aria-label` | "パスキーでログイン" | スクリーンリーダー用ラベル |
| `aria-busy` | `true` / `false` | 処理中状態の通知 |
| `role` | "button" | セマンティックロール（念のため明示） |
| `type` | "button" | フォーム送信を防ぐ |

#### 5.6.2 キーボード操作

| キー | 動作 |
|------|------|
| `Tab` | フォーカス移動 |
| `Enter` | ボタン実行（onClick発火） |
| `Space` | ボタン実行（onClick発火） |
| `Esc` | なし（親コンポーネントで処理） |

#### 5.6.3 フォーカス表示
```css
focus-visible:outline-none
focus-visible:ring-2
focus-visible:ring-blue-500
focus-visible:ring-offset-2
```

**視覚表示**:
- 青色のリング（2px）
- オフセット（2px）
- マウスクリック時は非表示（`:focus-visible`）

---

### 5.7 アニメーション仕様

#### 5.7.1 トランジション
```css
transition-all duration-200
```

**適用対象**:
- 背景色変化（hover, active）
- テキストカラー変化（disabled）

**タイミング**: 200ms

#### 5.7.2 スピナーアニメーション
```css
animate-spin
```

**仕様**:
- 回転速度: 1秒/周
- イージング: linear
- 無限ループ

---

## 📌 設計上の重要な決定

### 決定1: Flexboxレイアウト
- **理由**: アイコンとテキストの中央配置が容易

### 決定2: 固定サイズアイコン
- **サイズ**: 20x20px（`w-5 h-5`）
- **理由**: HarmoNet Design Systemに準拠

### 決定3: 状態による動的スタイル
- **方式**: クラス名の動的生成
- **理由**: Tailwind CSSのユーティリティクラスを活用

### 決定4: アクセシビリティ優先
- **ARIA属性の完全実装**
- **理由**: WCAG 2.1 AA準拠

---

**文書ステータス**: ✅ レビュー待ち  
**次のアクション**: 第6章「ロジック実装」へ進む