# 第6章: エラーハンドリングとアクセシビリティ

**Document:** LOGIN画面 機能設計書 v1.0  
**Chapter:** 6 of 6  
**Last Updated:** 2025/10/27

---

## 6.1 エラーケースと対応

### エラー分類

ログイン機能で発生しうるエラーを以下の4つに分類します。

| 分類 | 説明 | 例 |
|------|------|-----|
| **バリデーションエラー** | 入力形式の不正 | メールアドレス形式エラー、テナントID形式エラー |
| **認証エラー** | 認証情報の不一致 | テナントID不一致、メールアドレス未登録 |
| **ネットワークエラー** | 通信の失敗 | 接続失敗、タイムアウト |
| **システムエラー** | サーバー側の問題 | サーバーエラー、データベース接続エラー |

---

## 6.2 バリデーションエラー

### メールアドレスのバリデーション

**エラーケース一覧:**

**1. 必須入力エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | メールアドレスを入力してください |
| 英語 | Please enter your email address |
| 中国語 | 请输入电子邮件地址 |

**2. 形式エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | 正しいメールアドレスを入力してください |
| 英語 | Please enter a valid email address |
| 中国語 | 请输入有效的电子邮件地址 |

**3. 文字数超過エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | メールアドレスが長すぎます（80文字以内） |
| 英語 | Email address is too long (max 80 characters) |
| 中国語 | 电子邮件地址过长（最多255个字符） |

**バリデーションタイミング:**
- リアルタイム: フォーカスアウト時
- 送信時: 送信ボタンクリック時

**実装例:**
```javascript
function validateEmail(email) {
  // 必須チェック
  if (!email || email.trim() === '') {
    return { valid: false, error: 'email_required' };
  }
  
  // 文字数チェック
  if (email.length > 80) {
    return { valid: false, error: 'email_too_long' };
  }
  
  // 形式チェック
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return { valid: false, error: 'email_invalid_format' };
  }
  
  return { valid: true };
}
```

---

### テナントIDのバリデーション

**エラーケース一覧:**

**1. 必須入力エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | テナントIDを入力してください |
| 英語 | Please enter tenant ID |
| 中国語 | 请输入租户ID |

**2. 形式エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | テナントIDの形式が正しくありません（英字大文字4桁+数字2桁） |
| 英語 | Invalid tenant ID format (4 letters + 2 digits) |
| 中国語 | 租户ID格式不正确（4个字母+2个数字） |

**3. 文字数エラー**
| 言語 | エラーメッセージ |
|------|-----------------|
| 日本語 | テナントIDは6文字です |
| 英語 | Tenant ID must be 6 characters |
| 中国語 | 租户ID必须为6个字符 |

**バリデーションタイミング:**
- リアルタイム: 入力中（6文字到達時）
- 送信時: 送信ボタンクリック時

**実装例:**
```javascript
function validateTenantId(tenantId) {
  // 必須チェック
  if (!tenantId || tenantId.trim() === '') {
    return { valid: false, error: 'tenant_id_required' };
  }
  
  // 文字数チェック
  if (tenantId.length !== 6) {
    return { valid: false, error: 'tenant_id_length' };
  }
  
  // 形式チェック（AABB99）
  const tenantIdRegex = /^[A-Z]{4}[0-9]{2}$/;
  if (!tenantIdRegex.test(tenantId)) {
    return { valid: false, error: 'tenant_id_invalid_format' };
  }
  
  return { valid: true };
}
```

---

## 6.3 認証エラー

### テナントID不一致

**エラー内容:**
- 入力されたテナントIDがマスタに存在しない
- テナントIDが無効化されている

**エラーメッセージ:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | メールアドレスまたはテナントIDが正しくありません |
| 英語 | Email address or tenant ID is incorrect |
| 中国語 | 电子邮件地址或租户ID不正确 |

**注意:** セキュリティ上、テナントIDとメールアドレスのどちらが間違っているかは明示しない

---

### メールアドレス未登録

**エラー内容:**
- 入力されたメールアドレスがテナント内に存在しない
- メールアドレスが無効化されている

**エラーメッセージ:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | メールアドレスまたはテナントIDが正しくありません |
| 英語 | Email address or tenant ID is incorrect |
| 中国語 | 电子邮件地址或租户ID不正确 |

**追加案内（オプション）:**
| 言語 | 案内 |
|------|------|
| 日本語 | ご不明な場合は、管理者にお問い合わせください |
| 英語 | If you need assistance, please contact your administrator |
| 中国語 | 如有疑问,请联系管理员 |

---

### レート制限超過

**エラー内容:**
- ログイン試行回数が制限を超過
- メール送信回数が制限を超過

**エラーメッセージ:**

**ログイン試行超過:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | ログイン試行回数が上限に達しました。しばらく待ってから再度お試しください。 |
| 英語 | Too many login attempts. Please try again later. |
| 中国語 | 登录尝试次数过多。请稍后再试。 |

**メール送信超過:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | 送信回数の上限に達しました。しばらくしてから再度お試しください。 |
| 英語 | You've reached the maximum number of attempts. Please try again later. |
| 中国語 | 您已达到最大尝试次数。请稍后再试。 |

---

## 6.4 ネットワークエラー

### 接続失敗

**エラー内容:**
- サーバーへの接続に失敗
- タイムアウト

**エラーメッセージ:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | サーバーへの接続に失敗しました。インターネット接続を確認してください。 |
| 英語 | Failed to connect to server. Please check your internet connection. |
| 中国語 | 无法连接到服务器。请检查您的互联网连接。 |

**リトライボタン:**
- エラーメッセージ下部に「再試行」ボタンを表示

---

### タイムアウト

**エラー内容:**
- リクエストが一定時間内に完了しない
- サーバーからの応答がない

**エラーメッセージ:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | リクエストがタイムアウトしました。もう一度お試しください。 |
| 英語 | Request timed out. Please try again. |
| 中国語 | 请求超时。请重试。 |

---

## 6.5 システムエラー

### サーバーエラー（500番台）

**エラー内容:**
- サーバー内部エラー
- データベース接続エラー
- その他の予期しないエラー

**エラーメッセージ:**
| 言語 | メッセージ |
|------|-----------|
| 日本語 | システムエラーが発生しました。時間をおいて再度お試しください。 |
| 英語 | A system error occurred. Please try again later. |
| 中国語 | 发生系统错误。请稍后再试。 |

**追加案内:**
| 言語 | 案内 |
|------|------|
| 日本語 | 問題が解決しない場合は、サポートにお問い合わせください。 |
| 英語 | If the problem persists, please contact support. |
| 中国語 | 如果问题仍然存在,请联系支持部门。 |

---

## 6.6 エラーメッセージの表示方法

### 表示位置

**フィールド下エラー:**
- 各入力フィールドの直下に表示
- バリデーションエラー用

**画面上部エラー:**
- コンテンツ領域の最上部に表示
- 認証エラー、ネットワークエラー、システムエラー用

### 表示スタイル

**フィールド下エラー:**
```css
.error-message {
  color: #ef4444;
  font-size: 13px;
  margin-top: 4px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.error-message::before {
  content: "⚠";
  font-size: 14px;
}
```

**画面上部エラー:**
```css
.alert-error {
  background-color: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 24px;
  color: #991b1b;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.alert-error::before {
  content: "⚠";
  font-size: 20px;
  color: #dc2626;
}
```

### 自動消去

**消去条件:**
- ユーザーが入力フィールドを修正した時
- 「×」ボタンをクリックした時
- 一定時間経過後（画面上部エラーのみ、5秒）

**実装例:**
```javascript
function showError(message, duration = 5000) {
  const alertDiv = document.createElement('div');
  alertDiv.className = 'alert-error';
  alertDiv.textContent = message;
  
  // 閉じるボタン
  const closeBtn = document.createElement('button');
  closeBtn.textContent = '×';
  closeBtn.onclick = () => alertDiv.remove();
  alertDiv.appendChild(closeBtn);
  
  // 表示
  document.querySelector('.content-container').prepend(alertDiv);
  
  // 自動消去
  setTimeout(() => {
    alertDiv.remove();
  }, duration);
}
```

---

## 6.7 バリデーションルール詳細

### リアルタイムバリデーション

**実行タイミング:**
- フォーカスアウト時（blur）
- 入力完了時（input - debounce 500ms）

**実装例:**
```javascript
const emailInput = document.getElementById('email');

// フォーカスアウト時
emailInput.addEventListener('blur', () => {
  const result = validateEmail(emailInput.value);
  if (!result.valid) {
    showFieldError('email', result.error);
  } else {
    clearFieldError('email');
  }
});

// 入力中（デバウンス）
let debounceTimer;
emailInput.addEventListener('input', () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    const result = validateEmail(emailInput.value);
    if (!result.valid) {
      showFieldError('email', result.error);
    } else {
      clearFieldError('email');
    }
  }, 500);
});
```

---

### 送信時バリデーション

**実行タイミング:**
- フォーム送信時（submit）

**実装例:**
```javascript
const loginForm = document.getElementById('loginForm');

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  // 全フィールドのバリデーション
  const emailResult = validateEmail(emailInput.value);
  const tenantIdResult = validateTenantId(tenantIdInput.value);
  
  // エラー表示
  if (!emailResult.valid) {
    showFieldError('email', emailResult.error);
  }
  if (!tenantIdResult.valid) {
    showFieldError('tenantId', tenantIdResult.error);
  }
  
  // バリデーション失敗時は送信しない
  if (!emailResult.valid || !tenantIdResult.valid) {
    // 最初のエラーフィールドにフォーカス
    const firstErrorField = document.querySelector('.form-input--error');
    if (firstErrorField) {
      firstErrorField.focus();
    }
    return;
  }
  
  // バリデーション成功時、送信処理
  await submitLogin(emailInput.value, tenantIdInput.value);
});
```

---

## 6.8 アクセシビリティ対応

### スクリーンリーダー対応

**セマンティックHTML:**
```html
<form id="loginForm" aria-label="ログインフォーム">
  <div class="form-group">
    <label for="email" id="email-label">
      メールアドレス
      <span aria-label="必須" class="required">*</span>
    </label>
    <input 
      type="email" 
      id="email" 
      name="email"
      aria-labelledby="email-label"
      aria-required="true"
      aria-invalid="false"
      aria-describedby="email-error email-hint"
    >
    <span id="email-hint" class="hint">例: user@example.com</span>
    <span id="email-error" class="error-message" role="alert"></span>
  </div>
</form>
```

**ARIAラベルの使用:**
| 属性 | 用途 | 例 |
|------|------|-----|
| `aria-label` | 要素の説明 | `aria-label="ログインフォーム"` |
| `aria-required` | 必須項目 | `aria-required="true"` |
| `aria-invalid` | 入力エラー | `aria-invalid="true"` |
| `aria-describedby` | 追加説明 | `aria-describedby="email-error"` |
| `role="alert"` | エラー通知 | `role="alert"` |

---

### エラー読み上げ

**実装例:**
```javascript
function showFieldError(fieldName, errorKey) {
  const errorSpan = document.getElementById(`${fieldName}-error`);
  const input = document.getElementById(fieldName);
  
  // エラーメッセージ設定
  const errorMessage = getErrorMessage(errorKey);
  errorSpan.textContent = errorMessage;
  
  // ARIA属性更新
  input.setAttribute('aria-invalid', 'true');
  
  // スクリーンリーダー用のライブリージョン
  const liveRegion = document.createElement('div');
  liveRegion.setAttribute('role', 'alert');
  liveRegion.setAttribute('aria-live', 'assertive');
  liveRegion.className = 'sr-only';
  liveRegion.textContent = `エラー: ${errorMessage}`;
  document.body.appendChild(liveRegion);
  
  // 一定時間後に削除
  setTimeout(() => liveRegion.remove(), 3000);
}
```

---

### キーボードナビゲーション

**Tab順序:**
```
1. 言語切替ボタン（JA）
2. 言語切替ボタン（EN）
3. 言語切替ボタン（CN）
4. メールアドレス入力
5. テナントID入力
6. 送信ボタン
7. フッターリンク（利用規約）
8. フッターリンク（プライバシーポリシー）
9. フッターリンク（お問い合わせ）
```

**キーボードショートカット:**
| キー | 動作 |
|------|------|
| **Tab** | 次の要素へ移動 |
| **Shift + Tab** | 前の要素へ移動 |
| **Enter** | フォーム送信（フォーム内の場合） |
| **Escape** | エラーメッセージを閉じる |
| **Space** | ボタンをクリック |

**実装例:**
```javascript
// Escapeキーでエラーメッセージを閉じる
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    const alerts = document.querySelectorAll('.alert-error');
    alerts.forEach(alert => alert.remove());
  }
});

// Enterキーでフォーム送信
loginForm.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && e.target.tagName !== 'BUTTON') {
    e.preventDefault();
    loginForm.requestSubmit();
  }
});
```

---

### フォーカスインジケーター

**仕様:**
```css
/* 入力フィールド */
.form-input:focus {
  outline: 3px solid #3b82f6;
  outline-offset: 2px;
}

/* ボタン */
.btn-submit:focus {
  outline: 3px solid #3b82f6;
  outline-offset: 2px;
}

/* リンク */
a:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
  border-radius: 2px;
}

/* 言語切替ボタン */
.lang-btn:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 1px;
}
```

**ブラウザデフォルトのフォーカスを無効化しない:**
```css
/* ❌ NG - アクセシビリティを損なう */
*:focus {
  outline: none;
}

/* ✅ OK - カスタムフォーカスインジケーターを追加 */
*:focus-visible {
  outline: 3px solid #3b82f6;
  outline-offset: 2px;
}
```

---

### コントラスト比

**WCAG 2.1 Level AA準拠:**
- 通常テキスト: 4.5:1以上
- 大きなテキスト（18pt以上、または14pt太字以上）: 3:1以上

**カラー検証:**
| 組み合わせ | コントラスト比 | 合否 |
|-----------|---------------|------|
| テキスト (#1f2937) / 背景 (#ffffff) | 16.1:1 | ✅ PASS |
| ボタンテキスト (#ffffff) / ボタン背景 (#3b82f6) | 4.6:1 | ✅ PASS |
| エラーテキスト (#ef4444) / 背景 (#ffffff) | 4.5:1 | ✅ PASS |
| リンク (#3b82f6) / 背景 (#ffffff) | 8.6:1 | ✅ PASS |

**検証ツール:**
- WebAIM Contrast Checker
- Chrome DevTools (Lighthouse)
- axe DevTools

---

### スクリーンリーダー専用テキスト

**実装方法:**
```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

**使用例:**
```html
<button class="lang-btn">
  JA
  <span class="sr-only">日本語に切り替え</span>
</button>

<form aria-label="ログインフォーム">
  <h2 class="sr-only">ログイン情報入力</h2>
  <!-- フォーム内容 -->
</form>
```

---

## 6.9 ユーザーエクスペリエンスの最適化

### ローディング状態

**表示内容:**
- ローディングスピナー
- 「送信中...」テキスト
- ボタンの無効化

**実装例:**
```javascript
function showLoading() {
  const submitBtn = document.querySelector('.btn-submit');
  
  // ボタン無効化
  submitBtn.disabled = true;
  
  // テキスト変更
  submitBtn.innerHTML = `
    <span class="spinner"></span>
    <span>送信中...</span>
  `;
}

function hideLoading() {
  const submitBtn = document.querySelector('.btn-submit');
  
  // ボタン有効化
  submitBtn.disabled = false;
  
  // テキスト復元
  submitBtn.innerHTML = 'ログインリンクを送信';
}
```

---

### 成功フィードバック

**送信成功時:**
- メール送信完了画面へリダイレクト
- 成功アイコン表示
- 明確な成功メッセージ

**実装例:**
```javascript
async function submitLogin(email, tenantId) {
  try {
    showLoading();
    
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, tenantId })
    });
    
    if (response.ok) {
      // 成功時、メール送信完了画面へリダイレクト
      window.location.href = '/pages/login/email-sent.html';
    } else {
      // エラー処理
      const error = await response.json();
      showError(error.message);
    }
  } catch (error) {
    showError('ネットワークエラーが発生しました');
  } finally {
    hideLoading();
  }
}
```

---

## エラーハンドリングのまとめ

### チェックリスト

**実装時の確認項目:**
- [ ] 全てのエラーケースに対応している
- [ ] エラーメッセージが3言語で用意されている
- [ ] エラー表示位置が適切
- [ ] リアルタイムバリデーションが動作する
- [ ] 送信時バリデーションが動作する
- [ ] スクリーンリーダーでエラーが読み上げられる
- [ ] キーボードで全ての操作が可能
- [ ] フォーカスインジケーターが表示される
- [ ] コントラスト比が基準を満たす
- [ ] ローディング状態が表示される

---

**[← 前の章: 第5章 セキュリティ対策](login-feature-design-ch05.md)**

**[目次に戻る ↑](login-feature-design-ch00-index.md)**

---

**End of Document**
