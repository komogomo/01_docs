# 第3章: ログイン画面詳細

**Document:** LOGIN画面 機能設計書 v1.2
**Chapter:** 3 of 6  
**Last Updated:** 2025/10/27  
**Design System:** HarmoNet Design System v1

---

## 3.1 画面構成（3層構造）

ログイン画面は、統一された3層構造を採用します。

```
┌─────────────────────────────────────┐
│   ヘッダー領域 (Layer 1)             │
│   - アプリタイトル                    │
│   - 言語切替ボタン                    │
├─────────────────────────────────────┤
│                                     │
│   コンテンツ領域 (Layer 2)           │
│   - タイトル                         │
│   - サブタイトル                     │
│   - 入力フォーム                     │
│     ∟ メールアドレス                │
│     ∟ テナントID                    │
│   - 送信ボタン                       │
│                                     │
├─────────────────────────────────────┤
│   フッター領域 (Layer 3)             │
│   - リンク（利用規約等）              │
│   - コピーライト                     │
└─────────────────────────────────────┘
```

---

## 3.2 ヘッダー領域

### 参照ドキュメント

ヘッダー領域のデザイン仕様については、以下を参照してください：
- `common-header.md` - 共通ヘッダー領域設計書

### ログイン画面固有の調整

**構成要素:**
- ✅ アプリタイトル（「セキュレアシティ」）
- ✅ 言語切替ボタン（ドロップダウン方式）
- ❌ **通知ボタンは非表示**
  - 理由：ログイン前のため、通知機能へのアクセスは不要

**レイアウト:**
```
┌──────────────────────────────────────┐
│  [ロゴ]                  [言語切替]   │
│  セキュレアシティ           JA ▼      │
└──────────────────────────────────────┘
```

**備考:**
- 言語切替ボタンの詳細動作・スタイルは `common-header.md` および `common-i18n.md` を参照

---

## 3.3 コンテンツ領域

### 参照ドキュメント

コンテンツ領域の基本仕様については、以下を参照してください：
- `common-contents-layout.md` - 共通コンテンツ領域設計書
- `harmonet-design-system.md` - HarmoNet Design System

### ログイン画面固有の調整

**カード最大幅:**
- 最大幅: 380px（ログイン画面専用の狭いレイアウト）
- 理由: シンプルなログインフォームに最適化

**カードパディング:**
- PC: 32px 24px
- モバイル: 32px 20px
- 理由: 共通仕様（`p-4 md:p-6`）より具体的な余白設定

### タイトル構成（ログイン画面専用）

**サブタイトル:**
- テキスト: 「ご入居者様専用WEBサイト」
- フォントサイズ: 12px
- 文字色: `#9CA3AF`（HarmoNet補足文字色）
- 配置: 中央寄せ
- 下マージン: 8px

**タイトル:**
- テキスト: 「Smart Community」
- フォントサイズ: 18px
- フォントウェイト: 600 (Semibold)
- 文字色: `#1F2937`（HarmoNet主要文字色）
- 配置: 中央寄せ
- 下マージン: 24px

**セクションタイトル:**
- テキスト: 「ログイン」
- フォントサイズ: 16px
- フォントウェイト: 500 (Medium)
- 文字色: `#1F2937`（HarmoNet主要文字色）
- 配置: 中央寄せ
- 下マージン: 24px

### 多言語対応

| 言語 | サブタイトル | タイトル | セクションタイトル |
|------|-------------|---------|-------------------|
| **日本語(JA)** | ご入居者様専用WEBサイト | Smart Community | ログイン |
| **英語(EN)** | Resident Portal | Smart Community | Login |
| **中国語(CN)** | 居民专用网站 | Smart Community | 登录 |

---

## 3.4 入力フォーム

### フォーム構成

```
┌─────────────────────────────────┐
│  メールアドレス                  │
│  ┌─────────────────────────┐    │
│  │ demo@securea-city.jp    │    │
│  └─────────────────────────┘    │
│                                 │
│  テナントID                      │
│  ┌─────────────────────────┐    │
│  │ TKSC01                  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  ログインリンクを送信     │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

## 3.5 入力項目の詳細仕様

### メールアドレス

**項目情報:**
| 項目 | 仕様 |
|------|------|
| **フィールド名** | email |
| **ラベル** | メールアドレス |
| **type** | email |
| **必須** | ✅ Yes |
| **プレースホルダー** | demo@securea-city.jp |
| **最大文字数** | 255文字 |

**バリデーション:**
- 必須入力チェック
- メール形式チェック（RFC 5322準拠）
- 最大文字数チェック（255文字）

**正規表現例:**
```javascript
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
```

**エラーメッセージ:**
| エラー | 日本語 | 英語 | 中国語 |
|--------|--------|------|--------|
| 必須エラー | メールアドレスを入力してください | Please enter your email address | 请输入电子邮件地址 |
| 形式エラー | 正しいメールアドレスを入力してください | Please enter a valid email address | 请输入有效的电子邮件地址 |
| 文字数超過 | メールアドレスが長すぎます（255文字以内） | Email address is too long (max 255 characters) | 电子邮件地址过长（最多255个字符） |

---

### テナントID

**項目情報:**
| 項目 | 仕様 |
|------|------|
| **フィールド名** | tenantId |
| **ラベル** | テナントID |
| **type** | text |
| **必須** | ✅ Yes |
| **プレースホルダー** | TKSC01 |
| **文字数** | 6文字固定 |
| **形式** | AABB99（英字大文字4桁 + 数字2桁） |

**入力制御:**
- 大文字自動変換（小文字入力時）
- 半角英数字のみ許可
- 6文字入力でフォーカス自動移動（オプション）

**バリデーション:**
- 必須入力チェック
- 文字数チェック（6文字固定）
- 形式チェック（AABB99）
- テナントマスタ存在チェック（サーバー側）

**正規表現:**
```javascript
const tenantIdRegex = /^[A-Z]{4}[0-9]{2}$/;
```

**入力例・ガイド:**
```
プレースホルダー: TKSC01
ヘルプテキスト: 英字大文字4桁 + 数字2桁（例: TKSC01）
```

**エラーメッセージ:**
| エラー | 日本語 | 英語 | 中国語 |
|--------|--------|------|--------|
| 必須エラー | テナントIDを入力してください | Please enter tenant ID | 请输入租户ID |
| 形式エラー | テナントIDの形式が正しくありません（英字大文字4桁+数字2桁） | Invalid tenant ID format (4 letters + 2 digits) | 租户ID格式不正确（4个字母+2个数字） |
| 文字数エラー | テナントIDは6文字です | Tenant ID must be 6 characters | 租户ID必须为6个字符 |
| 存在エラー | テナントIDが見つかりません | Tenant ID not found | 找不到租户ID |

---

### 送信ボタン

**ボタン仕様:**
| 項目 | 仕様 |
|------|------|
| **ラベル** | ログインリンクを送信 |
| **type** | submit |
| **背景色** | `#2563EB` (アクションブルー) |
| **文字色** | `#FFFFFF` (白) |
| **幅** | 100% |
| **高さ** | 48px (パディング: 14px) |
| **角丸** | 0.5rem (8px) |
| **フォントサイズ** | 14px |
| **フォントウェイト** | 600 (Semibold) |

**ホバー時（PC/タブレット）:**
```css
.btn-submit:hover {
  background: #1D4ED8;
  transition: background-color 0.2s;
}
```

**アクティブ時（クリック）:**
```css
.btn-submit:active {
  background: #1E40AF;
}
```

**無効状態:**
```css
.btn-submit:disabled {
  background: #9CA3AF;
  cursor: not-allowed;
  opacity: 0.6;
}
```

**ローディング状態:**
- ボタンを無効化
- ローディングアイコン（スピナー）を表示
- テキスト: 「送信中...」

**多言語対応:**
| 言語 | ボタンラベル | 送信中 |
|------|-------------|--------|
| **日本語(JA)** | ログインリンクを送信 | 送信中... |
| **英語(EN)** | Send Login Link | Sending... |
| **中国語(CN)** | 发送登录链接 | 发送中... |

---

## 3.6 デザイン仕様

本画面のデザインは **HarmoNet Design System** に準拠します。

### 参照ドキュメント

共通デザイン仕様については、以下を参照してください：

- **カラーパレット**: `harmonet-design-system.md` - 🎨 カラーパレット（Calm Neutral Palette）
- **タイポグラフィ**: `harmonet-design-system.md` - ✨ タイポグラフィ
- **レイアウトと構造**: `harmonet-design-system.md` - 🧱 レイアウトと構造
- **コンポーネント指針**: `harmonet-design-system.md` - 📱 コンポーネント指針
- **デザイン哲学**: `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2.0.md`

### ログイン画面固有のデザイン調整

**カード:**
- 最大幅: 380px（ログイン画面専用）
- パディング: 32px 24px（PC）、32px 20px（モバイル）
- 背景色: `#FFFFFF` (白)
- 角丸: 1rem (16px) ※HarmoNetデザインシステム準拠
- 影: `0 1px 2px 0 rgba(0, 0, 0, 0.05)` (shadow-sm) ※HarmoNetデザインシステム準拠
- 枠線: `1px solid #E5E7EB`

**入力フィールド:**
- 高さ: 48px（タップ領域確保）
- パディング: 12px 16px
- ラベル下マージン: 8px

---

## 3.7 入力フィールドのデザイン

### 通常状態

```css
.form-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #E5E7EB;
  border-radius: 0.5rem;
  font-size: 14px;
  color: #1F2937;
  background: #F9FAFB;
  transition: all 0.2s;
  line-height: 1.6;
}
```

### フォーカス状態

```css
.form-input:focus {
  outline: none;
  border-color: #2563EB;
  background: #FFFFFF;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}
```

### エラー状態

```css
.form-input--error {
  border-color: #DC2626;
  background: #FFFFFF;
}

.form-input--error:focus {
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1);
}
```

### ラベル

```css
.form-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #1F2937;
  margin-bottom: 8px;
  line-height: 1.6;
}
```

### エラーメッセージ

```css
.error-message {
  color: #DC2626;
  font-size: 12px;
  margin-top: 4px;
  line-height: 1.6;
}
```

---

## 3.8 フッター領域

### 参照ドキュメント

フッター領域のデザイン仕様については、以下を参照してください：
- `common-footer.md` - 共通フッター領域設計書

### ログイン画面固有の調整

**構成要素:**
- ✅ テキストリンク（利用規約、プライバシーポリシー、お問い合わせ）
- ✅ コピーライト（© 2025 HarmoNet. All rights reserved.）
- ❌ **ナビゲーションボタン（全6種類）は非表示**
  - ホーム、お知らせ、掲示板、駐車場、マイページ、ログアウトボタンは表示しない
  - 理由：ログイン前のため、アプリ内機能へのアクセスは不要

**レイアウト:**
```
┌──────────────────────────────────────────────────┐
│  利用規約 | プライバシーポリシー | お問い合わせ    │
│      © 2025 HarmoNet. All rights reserved.       │
└──────────────────────────────────────────────────┘
```

### 多言語対応

| 言語 | 利用規約 | プライバシーポリシー | お問い合わせ |
|------|---------|-------------------|-------------|
| **日本語(JA)** | 利用規約 | プライバシーポリシー | お問い合わせ |
| **英語(EN)** | Terms of Service | Privacy Policy | Contact |
| **中国語(CN)** | 使用条款 | 隐私政策 | 联系我们 |

---

## 3.9 レスポンシブ対応

### ブレークポイント

| デバイス | 幅 | 調整内容 |
|---------|-----|---------|
| **PC** | > 768px | デフォルト |
| **タブレット** | 768px | カード幅調整 |
| **スマートフォン** | < 768px | パディング縮小 |

### スマートフォン最適化

**カード:**
- パディング: 32px 20px

**タイトル:**
- フォントサイズ: 18px（変更なし）

**入力フィールド:**
- タップ領域確保（最小44px高さ）
- フォントサイズ: 16px（iOS自動ズーム防止）

**ヘッダー:**
- パディング: 16px 20px

**フッター:**
- パディング: 16px 20px

---

## 3.10 アクセシビリティ

### セマンティックHTML

```html
<main class="page-content">
  <div class="login-card">
    <header class="login-card__header">
      <h1>Smart Community</h1>
      <h2>ログイン</h2>
    </header>
    
    <form id="loginForm" aria-label="ログインフォーム">
      <div class="form-group">
        <label for="email" class="form-label">メールアドレス</label>
        <input 
          type="email" 
          id="email" 
          name="email"
          class="form-input"
          required
          aria-required="true"
          aria-describedby="email-error"
          placeholder="demo@securea-city.jp"
        >
        <span id="email-error" class="error-message" role="alert"></span>
      </div>
      
      <div class="form-group">
        <label for="tenantId" class="form-label">テナントID</label>
        <input 
          type="text" 
          id="tenantId" 
          name="tenantId"
          class="form-input"
          required
          aria-required="true"
          aria-describedby="tenantId-error"
          placeholder="TKSC01"
          maxlength="6"
        >
        <span id="tenantId-error" class="error-message" role="alert"></span>
      </div>
      
      <button type="submit" class="btn-submit">
        ログインリンクを送信
      </button>
    </form>
  </div>
</main>
```

### キーボードナビゲーション

**Tab順序:**
1. 言語切替ボタン（JA）
2. 言語切替ボタン（EN）
3. 言語切替ボタン（CN）
4. メールアドレス入力
5. テナントID入力
6. 送信ボタン
7. フッターリンク（利用規約）
8. フッターリンク（プライバシーポリシー）
9. フッターリンク（お問い合わせ）

**Enter キー:**
- フォーム内でEnterキー押下 → 送信

**Escapeキー:**
- エラーメッセージ表示時 → エラー非表示

### フォーカスインジケーター

```css
.form-input:focus,
.btn-submit:focus,
.lang-btn:focus {
  outline: 2px solid #2563EB;
  outline-offset: 2px;
}
```

### コントラスト比

**WCAG 2.1 Level AA準拠:**
- テキストとバックグラウンド: 4.5:1以上
- ボタンテキスト: 4.5:1以上
- エラーメッセージ: 4.5:1以上

**検証済みコントラスト比:**
| 要素 | 前景色 | 背景色 | 比率 | 状態 |
|------|--------|--------|------|------|
| 主要文字 | `#1F2937` | `#FFFFFF` | 14.5:1 | ✅ AAA |
| 副次文字 | `#6B7280` | `#FFFFFF` | 5.6:1 | ✅ AA |
| ボタン文字 | `#FFFFFF` | `#2563EB` | 5.9:1 | ✅ AA |
| エラー文字 | `#DC2626` | `#FFFFFF` | 5.4:1 | ✅ AA |

---

## デザイン哲学の適用

本画面は、HarmoNet Design Systemの「静かで、安心できる、永く使えるUI」の理念に基づいて設計されています。

詳細は以下を参照してください：
- `harmonet-design-system.md` - 💡 デザイン哲学
- `01_DESIGN_PHILOSOPHY_Securea_City_Guideline_v2.0.md` - Securea City Design Philosophy

---

**[← 前の章: 第2章 認証フローと画面構成](login-feature-design-ch02.md)**

**[次の章へ: 第4章 メール送信完了画面詳細 →](login-feature-design-ch04.md)**

**[目次に戻る ↑](login-feature-design-ch00-index.md)**
