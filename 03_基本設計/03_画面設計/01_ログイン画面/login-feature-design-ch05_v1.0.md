# 第5章: セキュリティ対策

**Document:** LOGIN画面 機能設計書 v1.0  
**Chapter:** 5 of 6  
**Last Updated:** 2025/10/27

---

## 5.1 マジックリンクのセキュリティ

### トークン生成方式

**暗号学的に安全な乱数生成（CSPRNG）**

**使用アルゴリズム:**
- Node.js: `crypto.randomBytes()`
- Python: `secrets.token_urlsafe()`
- Java: `SecureRandom`

**推奨トークン長:**
- 最小: 32文字
- 推奨: 48文字
- 最大: 64文字

**エンコーディング:**
- Base64 URL-safe（RFC 4648）
- 使用可能文字: A-Z, a-z, 0-9, -, _

**生成例（Node.js）:**
```javascript
const crypto = require('crypto');

function generateMagicLinkToken() {
  // 48文字のBase64 URL-safe トークン生成
  return crypto.randomBytes(36).toString('base64url');
}

// 例: "Xa7k9Pm2Qr5tLw8NvZ3eB1cF6hG4jM0sD8kR7pY2tW5nA9qU"
```

---

### トークンのハッシュ化と保存

**なぜハッシュ化するのか:**
- データベース漏洩時のトークン保護
- 生のトークンを保存しない（Zero Knowledge）
- トークンの再利用防止

**ハッシュアルゴリズム:**
- SHA-256（推奨）
- HMAC-SHA256（さらに強固）

**実装例:**
```javascript
const crypto = require('crypto');

function hashToken(token) {
  return crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');
}

// トークン: "Xa7k9Pm2Qr5tLw8NvZ3eB1cF6hG4jM0sD8kR7pY2tW5nA9qU"
// ハッシュ: "a3f5c8d9e2b1f6a7c4d8e9f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1"
```

**データベース保存:**
```sql
INSERT INTO magic_link_tokens (
  token_hash,
  tenant_id,
  email,
  expires_at,
  created_at
) VALUES (
  'a3f5c8d9e2b1f6a7c4d8e9f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1',
  'TKSC01',
  'user@example.com',
  NOW() + INTERVAL '30 minutes',
  NOW()
);
```

---

### 有効期限管理

**推奨有効期限:**
| シナリオ | 有効期限 | 理由 |
|---------|---------|------|
| **本番環境** | 30分 | セキュリティとユーザビリティのバランス |
| **テスト環境** | 60分 | テスト作業の効率化 |
| **高セキュリティ環境** | 15分 | より厳格なセキュリティ要件 |

**有効期限チェック:**
```javascript
function isTokenExpired(expiresAt) {
  const now = new Date();
  const expiry = new Date(expiresAt);
  return now > expiry;
}
```

**有効期限切れ時の処理:**
1. エラーメッセージ表示
2. トークンをデータベースから削除
3. ユーザーにログイン画面へ戻るよう案内

---

### ワンタイム使用の保証

**実装方法:**

**1. ステータス管理方式**
```sql
-- トークンテーブルにステータスカラム
CREATE TABLE magic_link_tokens (
  id UUID PRIMARY KEY,
  token_hash VARCHAR(64) NOT NULL,
  status ENUM('active', 'used', 'expired') DEFAULT 'active',
  used_at TIMESTAMP,
  -- 他のカラム
);

-- トークン使用時の更新
UPDATE magic_link_tokens
SET status = 'used', used_at = NOW()
WHERE token_hash = ? AND status = 'active';
```

**2. 削除方式**
```javascript
// トークン検証後、即座に削除
async function verifyAndDeleteToken(tokenHash) {
  const result = await db.query(
    'DELETE FROM magic_link_tokens WHERE token_hash = ? RETURNING *',
    [tokenHash]
  );
  
  if (result.rowCount === 0) {
    throw new Error('Token already used or invalid');
  }
  
  return result.rows[0];
}
```

**推奨:** ステータス管理方式（監査ログとして履歴を残せる）

---

## 5.2 レート制限（Rate Limiting）

### ログイン試行回数制限

**IP単位の制限:**
| 期間 | 試行回数 | ロックアウト時間 |
|------|---------|----------------|
| 1時間 | 10回 | 1時間 |
| 24時間 | 50回 | 24時間 |

**実装例:**
```javascript
const rateLimit = {
  ip: new Map(), // IP => { count, lastReset }
  
  checkIP(ip) {
    const now = Date.now();
    const record = this.ip.get(ip) || { count: 0, lastReset: now };
    
    // 1時間経過でリセット
    if (now - record.lastReset > 3600000) {
      record.count = 0;
      record.lastReset = now;
    }
    
    record.count++;
    this.ip.set(ip, record);
    
    return record.count <= 10;
  }
};
```

---

**メールアドレス単位の制限:**
| 期間 | 試行回数 | ロックアウト時間 |
|------|---------|----------------|
| 1時間 | 5回 | 1時間 |

**実装例:**
```javascript
async function checkEmailRateLimit(email) {
  const count = await db.query(
    `SELECT COUNT(*) FROM login_attempts
     WHERE email = ? AND created_at > NOW() - INTERVAL '1 hour'`,
    [email]
  );
  
  return count.rows[0].count < 5;
}
```

---

**テナントID単位の制限:**
| 期間 | 試行回数 | 目的 |
|------|---------|------|
| 1時間 | 20回 | テナント全体への攻撃防止 |

---

### メール送信回数制限

**同一メールアドレスへの送信制限:**
| 期間 | 送信回数 | クールダウン |
|------|---------|------------|
| 1時間 | 3回 | 60秒 |
| 24時間 | 10回 | - |

**実装例:**
```javascript
async function checkEmailSendLimit(email) {
  // 1時間以内の送信回数チェック
  const hourlyCount = await db.query(
    `SELECT COUNT(*) FROM magic_link_tokens
     WHERE email = ? AND created_at > NOW() - INTERVAL '1 hour'`,
    [email]
  );
  
  if (hourlyCount.rows[0].count >= 3) {
    throw new Error('Hourly limit exceeded');
  }
  
  // 前回送信からの経過時間チェック（クールダウン）
  const lastSent = await db.query(
    `SELECT created_at FROM magic_link_tokens
     WHERE email = ? ORDER BY created_at DESC LIMIT 1`,
    [email]
  );
  
  if (lastSent.rows.length > 0) {
    const elapsed = Date.now() - new Date(lastSent.rows[0].created_at).getTime();
    if (elapsed < 60000) { // 60秒未満
      throw new Error('Please wait before resending');
    }
  }
  
  return true;
}
```

---

**システム全体の送信制限:**
| 期間 | 送信回数 | 目的 |
|------|---------|------|
| 1分 | 100通 | メールサーバー保護 |
| 1時間 | 1,000通 | 過負荷防止 |

---

### ロックアウト機能

**ロックアウト条件:**
- ログイン試行回数が制限を超過
- メール送信回数が制限を超過
- 異常なアクセスパターンの検知

**ロックアウト時の動作:**
```javascript
function lockAccount(identifier, duration) {
  // ロックアウトレコード作成
  db.query(
    `INSERT INTO account_locks (identifier, locked_until, reason)
     VALUES (?, NOW() + INTERVAL '? minutes', 'rate_limit_exceeded')`,
    [identifier, duration]
  );
  
  // ユーザーへの通知
  sendNotification(identifier, {
    type: 'account_locked',
    message: `アカウントが${duration}分間ロックされました`,
    unlockAt: new Date(Date.now() + duration * 60000)
  });
}
```

**ロックアウト解除方法:**
1. 時間経過による自動解除
2. 管理者による手動解除
3. セキュリティ確認後の解除

---

## 5.3 入力バリデーションとサニタイゼーション

### SQLインジェクション対策

**プリペアドステートメントの使用:**

**❌ 脆弱な実装:**
```javascript
// SQLインジェクションの危険性あり
const query = `SELECT * FROM users WHERE email = '${email}'`;
```

**✅ 安全な実装:**
```javascript
// プリペアドステートメント使用
const query = 'SELECT * FROM users WHERE email = ?';
const result = await db.query(query, [email]);
```

**ORM使用例（TypeORM）:**
```typescript
const user = await userRepository.findOne({
  where: { email: email }
});
```

---

### XSS（クロスサイトスクリプティング）対策

**入力値のサニタイゼーション:**

**❌ 脆弱な実装:**
```javascript
// XSSの危険性あり
document.getElementById('message').innerHTML = userInput;
```

**✅ 安全な実装:**
```javascript
// textContentを使用（HTMLとして解釈されない）
document.getElementById('message').textContent = userInput;

// またはHTMLエスケープ
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}
```

**Content Security Policy（CSP）ヘッダー:**
```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
```

---

### CSRF（クロスサイトリクエストフォージェリ）対策

**CSRFトークンの使用:**

**実装例:**
```javascript
// サーバー側: トークン生成
const csrfToken = crypto.randomBytes(32).toString('hex');
req.session.csrfToken = csrfToken;

// HTMLフォームに埋め込み
<input type="hidden" name="csrf_token" value="${csrfToken}">

// サーバー側: トークン検証
if (req.body.csrf_token !== req.session.csrfToken) {
  throw new Error('CSRF token mismatch');
}
```

**SameSite Cookie属性:**
```javascript
res.cookie('session', sessionId, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict' // または 'lax'
});
```

---

## 5.4 通信セキュリティ

### HTTPS必須化

**TLS設定:**
- TLS 1.2以上を使用
- TLS 1.0/1.1は無効化
- 強固な暗号スイートのみ許可

**推奨暗号スイート:**
```
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
```

**証明書管理:**
- 信頼できるCA（Let's Encrypt、DigiCert等）から取得
- 有効期限の定期的な確認
- 自動更新の設定

---

### セキュアなCookie設定

**Cookie属性:**
```javascript
res.cookie('session', sessionId, {
  httpOnly: true,    // JavaScriptからアクセス不可（XSS対策）
  secure: true,      // HTTPS通信のみ（中間者攻撃対策）
  sameSite: 'strict', // CSRF対策
  maxAge: 86400000,  // 24時間
  path: '/',
  domain: '.securea-city.jp'
});
```

**Cookie属性の説明:**
| 属性 | 目的 | 設定値 |
|------|------|--------|
| **httpOnly** | XSS対策 | true |
| **secure** | HTTPS強制 | true |
| **sameSite** | CSRF対策 | 'strict' or 'lax' |
| **maxAge** | セッション有効期限 | 86400000（24時間） |

---

### HSTS（HTTP Strict Transport Security）

**HSTSヘッダー:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**設定例（Express.js）:**
```javascript
app.use((req, res, next) => {
  res.setHeader(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains; preload'
  );
  next();
});
```

---

## 5.5 ログとモニタリング

### セキュリティログの記録

**記録すべきイベント:**
| イベント | 重要度 | ログレベル |
|---------|--------|-----------|
| ログイン成功 | 中 | INFO |
| ログイン失敗 | 高 | WARNING |
| レート制限超過 | 高 | WARNING |
| トークン生成 | 中 | INFO |
| トークン使用 | 中 | INFO |
| トークン期限切れ | 低 | INFO |
| 不正なトークン | 高 | WARNING |
| メール送信成功 | 中 | INFO |
| メール送信失敗 | 高 | ERROR |
| 異常なアクセスパターン | 最高 | CRITICAL |

**ログ項目:**
```javascript
{
  timestamp: '2025-10-27T10:30:00.000Z',
  level: 'WARNING',
  event: 'login_failed',
  ip: '192.168.1.100',
  userAgent: 'Mozilla/5.0...',
  email: 'user@example.com', // マスキング推奨
  tenantId: 'TKSC01',
  reason: 'invalid_tenant',
  requestId: 'req_abc123'
}
```

---

### 個人情報の保護

**ログに記録してはいけない情報:**
- ❌ パスワード
- ❌ トークン（生のトークン）
- ❌ クレジットカード番号
- ❌ その他の機密情報

**マスキング例:**
```javascript
function maskEmail(email) {
  const [localPart, domain] = email.split('@');
  const masked = localPart.slice(0, 2) + '***' + localPart.slice(-1);
  return `${masked}@${domain}`;
}

// "user@example.com" → "us***r@example.com"
```

---

### アラート設定

**アラート条件:**
| 条件 | 閾値 | アクション |
|------|------|-----------|
| ログイン失敗率 | 50%以上 | 管理者へメール通知 |
| レート制限発動 | 10回/分以上 | 管理者へSMS通知 |
| 異常なアクセス | IP単位で100回/分 | 自動IP遮断 |
| システムエラー | 10回/分以上 | エスカレーション |

**実装例（監視ツール連携）:**
```javascript
function sendAlert(type, details) {
  // Slack通知
  slackClient.send({
    channel: '#security-alerts',
    text: `🚨 セキュリティアラート: ${type}`,
    attachments: [details]
  });
  
  // メール通知
  emailClient.send({
    to: 'security@securea-city.jp',
    subject: `[ALERT] ${type}`,
    body: JSON.stringify(details, null, 2)
  });
}
```

---

## 5.6 ブルートフォース攻撃対策

### プログレッシブディレイ

**仕組み:**
- 試行回数に応じて待機時間を段階的に増加
- 総当たり攻撃の効率を大幅に低下させる

**実装例:**
```javascript
function calculateDelay(attemptCount) {
  // フィボナッチ数列で遅延時間を増加
  const delays = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55];
  const index = Math.min(attemptCount, delays.length - 1);
  return delays[index] * 1000; // ミリ秒
}

async function handleLoginAttempt(email) {
  const attempts = await getAttemptCount(email);
  const delay = calculateDelay(attempts);
  
  if (delay > 0) {
    await new Promise(resolve => setTimeout(resolve, delay));
  }
  
  // ログイン処理
}
```

**遅延時間の例:**
| 試行回数 | 待機時間 |
|---------|---------|
| 1回目 | 0秒 |
| 2回目 | 1秒 |
| 3回目 | 2秒 |
| 4回目 | 3秒 |
| 5回目 | 5秒 |
| 10回目以上 | 55秒 |

---

### CAPTCHAの導入検討

**導入タイミング:**
- ログイン失敗3回以上
- レート制限に近い回数の試行
- 異常なアクセスパターンの検知

**推奨サービス:**
- reCAPTCHA v3（Google）- 透過的、スコアベース
- hCaptcha - プライバシー重視
- Cloudflare Turnstile - 開発者フレンドリー

**実装例（reCAPTCHA v3）:**
```javascript
// フロントエンド
grecaptcha.ready(function() {
  grecaptcha.execute('SITE_KEY', {action: 'login'}).then(function(token) {
    document.getElementById('recaptcha_token').value = token;
    document.getElementById('loginForm').submit();
  });
});

// バックエンド
const response = await axios.post(
  'https://www.google.com/recaptcha/api/siteverify',
  {
    secret: RECAPTCHA_SECRET,
    response: req.body.recaptcha_token
  }
);

if (response.data.score < 0.5) {
  throw new Error('CAPTCHA verification failed');
}
```

---

### IP制限

**ブロックリスト管理:**
```javascript
const ipBlocklist = new Set();

function blockIP(ip, duration) {
  ipBlocklist.add(ip);
  
  // 一定時間後に解除
  setTimeout(() => {
    ipBlocklist.delete(ip);
  }, duration);
}

function isIPBlocked(ip) {
  return ipBlocklist.has(ip);
}
```

**地理的制限（オプション）:**
- 特定の国・地域からのアクセスを制限
- GeoIP データベース使用
- 注意: 誤検知のリスクあり

---

## 5.7 セッション管理

### セッションIDの安全な生成

**要件:**
- 予測不可能
- 十分な長さ（128bit以上）
- 暗号学的に安全な乱数生成

**実装例:**
```javascript
const crypto = require('crypto');

function generateSessionId() {
  return crypto.randomBytes(32).toString('hex'); // 256bit
}
```

---

### セッションタイムアウト

**アイドルタイムアウト:**
- 推奨: 30分
- ユーザーの操作がない場合、セッション無効化

**絶対タイムアウト:**
- 推奨: 24時間
- 操作の有無に関わらず、一定時間後にセッション無効化

**実装例:**
```javascript
const session = {
  id: generateSessionId(),
  userId: user.id,
  createdAt: new Date(),
  lastAccessedAt: new Date(),
  expiresAt: new Date(Date.now() + 86400000) // 24時間後
};

function isSessionValid(session) {
  const now = Date.now();
  const idleTimeout = 30 * 60 * 1000; // 30分
  
  // 絶対タイムアウトチェック
  if (now > session.expiresAt.getTime()) {
    return false;
  }
  
  // アイドルタイムアウトチェック
  if (now - session.lastAccessedAt.getTime() > idleTimeout) {
    return false;
  }
  
  return true;
}
```

---

### セッション固定攻撃対策

**ログイン後のセッションID再生成:**
```javascript
async function handleLogin(req, res, user) {
  // 古いセッションを破棄
  req.session.destroy();
  
  // 新しいセッションを生成
  req.session = createNewSession(user);
  
  // セッションIDを再生成
  req.session.regenerate((err) => {
    if (err) {
      throw err;
    }
    
    // ログイン処理続行
    res.redirect('/home');
  });
}
```

---

## 5.8 その他のセキュリティ考慮事項

### メール送信のセキュリティ

**SPF/DKIM/DMARC設定:**

**SPF（Sender Policy Framework）:**
```
v=spf1 include:_spf.google.com ~all
```

**DKIM（DomainKeys Identified Mail）:**
- メール送信サーバーでDKIM署名を設定
- 公開鍵をDNSレコードに登録

**DMARC（Domain-based Message Authentication）:**
```
v=DMARC1; p=quarantine; rua=mailto:dmarc@securea-city.jp
```

---

### エラーメッセージの適切な設計

**❌ 詳細すぎるエラー:**
```
エラー: ユーザー user@example.com は存在しません
→ 攻撃者がユーザーの存在を確認できてしまう
```

**✅ 適切なエラー:**
```
エラー: メールアドレスまたはテナントIDが正しくありません
→ どちらが間違っているか特定できない
```

**実装方針:**
- ユーザー存在の有無を推測できないようにする
- 攻撃に有利な情報を提供しない
- ただし、ユーザーが問題を解決できる程度の情報は提供

---

### セキュリティヘッダーの設定

**推奨ヘッダー:**
```javascript
app.use((req, res, next) => {
  // クリックジャッキング対策
  res.setHeader('X-Frame-Options', 'DENY');
  
  // MIMEタイプスニッフィング防止
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // XSS対策
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // Referrer-Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Content-Security-Policy
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';"
  );
  
  next();
});
```

---

## セキュリティ対策のまとめ

### 実装優先度

| 優先度 | 対策 | 理由 |
|--------|------|------|
| **最高** | HTTPS必須化 | 通信の盗聴・改ざん防止 |
| **最高** | SQLインジェクション対策 | データベース保護 |
| **最高** | XSS対策 | ユーザー保護 |
| **高** | レート制限 | 総当たり攻撃防止 |
| **高** | トークンセキュリティ | 認証基盤の保護 |
| **高** | セッション管理 | 不正アクセス防止 |
| **中** | CSRF対策 | クロスサイト攻撃防止 |
| **中** | ログとモニタリング | インシデント検知 |
| **低** | CAPTCHA | ボット対策（必要に応じて） |

---

**[← 前の章: 第4章 メール送信完了画面詳細](login-feature-design-ch04.md)**

**[次の章へ: 第6章 エラーハンドリングとアクセシビリティ →](login-feature-design-ch06.md)**

**[目次に戻る ↑](login-feature-design-ch00-index_v1.0.md)**
