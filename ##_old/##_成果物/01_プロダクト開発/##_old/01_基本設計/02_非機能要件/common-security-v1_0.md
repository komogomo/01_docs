# 共通セキュリティ要件設計書 v1.0

**Document ID:** SEC-APP-COMMON-SECURITY-001  
**Version:** 1.0  
**Created:** 2025年10月27日  
**Purpose:** 全画面共通のセキュリティ要件

---

## 1. 概要

本ドキュメントは、セキュレアシティ スマートコミュニケーションアプリの**セキュリティ要件**を定義します。

### 1.1 セキュリティの目的

- **情報漏洩の防止:** 個人情報・住民情報の保護
- **不正アクセスの防止:** 認証・認可の徹底
- **改ざんの防止:** データの整合性確保
- **可用性の確保:** サービスの安定稼働

### 1.2 対象範囲

- フロントエンド（Webアプリ）
- バックエンド（API）
- データベース
- インフラ

---

## 2. 認証・認可

### 2.1 認証方式

**マジックリンク認証を採用:**

1. ユーザーがメールアドレスを入力
2. サーバーが一時トークン付きURLをメール送信
3. ユーザーがリンクをクリック
4. サーバーがトークンを検証し、セッション発行

**利点:**
- パスワード不要（漏洩リスクなし）
- 高齢者にも使いやすい
- フィッシング対策

### 2.2 セッション管理

| 項目 | 仕様 |
|------|------|
| **セッショントークン** | JWT（JSON Web Token） |
| **トークンの保存場所** | HttpOnly Cookie |
| **トークンの有効期限** | 24時間 |
| **トークンの更新** | 自動更新（アクティビティ時） |

**セキュリティ対策:**

```javascript
// ✅ HttpOnly Cookie（XSS対策）
Set-Cookie: sessionToken=...; HttpOnly; Secure; SameSite=Strict

// ❌ localStorage（XSS脆弱性）
localStorage.setItem('sessionToken', token);
```

### 2.3 認可（アクセス制御）

| ロール | 権限 |
|--------|------|
| **住民** | お知らせ閲覧、掲示板投稿、駐車場予約 |
| **管理者** | お知らせ作成、掲示板管理、ユーザー管理 |
| **理事会メンバー** | 住民権限 + 一部管理機能 |

**実装例:**

```javascript
// APIリクエスト時にトークンを検証
app.use((req, res, next) => {
  const token = req.cookies.sessionToken;
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const user = verifyToken(token);
  if (!user) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  req.user = user;
  next();
});
```

---

## 3. XSS（クロスサイトスクリプティング）対策

### 3.1 基本対策

| 項目 | 対策 |
|------|------|
| **入力のエスケープ** | すべてのユーザー入力をエスケープ |
| **Content Security Policy** | CSPヘッダーで実行可能スクリプトを制限 |
| **HttpOnly Cookie** | JavaScriptからCookieにアクセス不可 |

### 3.2 エスケープの実装

**フロントエンド:**

```javascript
// ✅ 良い例（エスケープ処理）
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

const userInput = '<script>alert("XSS")</script>';
element.textContent = userInput; // 安全
element.innerHTML = escapeHtml(userInput); // 安全

// ❌ 悪い例（エスケープなし）
element.innerHTML = userInput; // 危険
```

**バックエンド:**

```python
# Python（Flask）の例
from markupsafe import escape

@app.route('/api/posts')
def get_posts():
    posts = [
        {
            'title': escape(post.title),  # エスケープ
            'content': escape(post.content)
        }
        for post in Post.query.all()
    ]
    return jsonify(posts)
```

### 3.3 Content Security Policy

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' https://cdnjs.cloudflare.com; 
               style-src 'self' 'unsafe-inline'; 
               img-src 'self' data: https:;">
```

---

## 4. CSRF（クロスサイトリクエストフォージェリ）対策

### 4.1 基本対策

| 項目 | 対策 |
|------|------|
| **SameSite Cookie** | `SameSite=Strict` を設定 |
| **CSRFトークン** | POST/PUT/DELETEリクエストに必須 |
| **Refererチェック** | リクエスト元を検証 |

### 4.2 SameSite Cookieの設定

```javascript
Set-Cookie: sessionToken=...; HttpOnly; Secure; SameSite=Strict
```

### 4.3 CSRFトークンの実装

**バックエンド（トークン生成）:**

```python
import secrets

@app.route('/api/csrf-token')
def get_csrf_token():
    token = secrets.token_urlsafe(32)
    session['csrf_token'] = token
    return jsonify({'csrf_token': token})
```

**フロントエンド（トークン送信）:**

```javascript
// CSRFトークンを取得
const csrfToken = await fetch('/api/csrf-token').then(r => r.json());

// POSTリクエスト時にトークンを送信
fetch('/api/posts', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken.csrf_token
  },
  body: JSON.stringify({ title: 'タイトル', content: '本文' })
});
```

---

## 5. SQLインジェクション対策

### 5.1 基本対策

| 項目 | 対策 |
|------|------|
| **プリペアドステートメント** | すべてのクエリでプレースホルダーを使用 |
| **ORMの使用** | SQLAlchemy、PrismaなどのORMを活用 |
| **入力検証** | ユーザー入力を厳密に検証 |

### 5.2 実装例

**✅ 良い例（プリペアドステートメント）:**

```python
# Python（SQLAlchemy）
user = User.query.filter_by(email=email).first()

# Python（raw SQL）
cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
```

**❌ 悪い例（SQLインジェクション脆弱性）:**

```python
# Python（raw SQL）
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

---

## 6. ファイルアップロードのセキュリティ

### 6.1 基本対策

| 項目 | 対策 |
|------|------|
| **ファイルサイズ制限** | 最大10MB |
| **ファイル形式制限** | 画像（JPEG、PNG、WebP）、PDF のみ |
| **ファイル名のサニタイズ** | 危険な文字を除去 |
| **マルウェアスキャン** | アップロード時にスキャン |

### 6.2 実装例

**フロントエンド:**

```javascript
const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const maxSize = 10 * 1024 * 1024; // 10MB

function validateFile(file) {
  if (!allowedTypes.includes(file.type)) {
    throw new Error('このファイル形式はサポートされていません');
  }
  
  if (file.size > maxSize) {
    throw new Error('ファイルサイズは10MB以下にしてください');
  }
}
```

**バックエンド:**

```python
import os
from werkzeug.utils import secure_filename

ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp', 'pdf'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type'}), 400
    
    if file.content_length > 10 * 1024 * 1024:
        return jsonify({'error': 'File too large'}), 400
    
    # ファイル名をサニタイズ
    filename = secure_filename(file.filename)
    file.save(os.path.join(UPLOAD_FOLDER, filename))
    
    return jsonify({'success': True})
```

---

## 7. 通信のセキュリティ

### 7.1 HTTPS通信

**必須:** すべての通信をHTTPSで暗号化します。

| 項目 | 仕様 |
|------|------|
| **プロトコル** | TLS 1.2以上 |
| **証明書** | Let's Encrypt（無料） |
| **HSTS** | `Strict-Transport-Security` ヘッダー |

**HSTS設定:**

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### 7.2 API通信の暗号化

**ペイロードの暗号化（機密情報のみ）:**

```javascript
// AES暗号化
const encrypted = CryptoJS.AES.encrypt(
  JSON.stringify(sensitiveData),
  encryptionKey
).toString();

// サーバーに送信
fetch('/api/sensitive-data', {
  method: 'POST',
  body: JSON.stringify({ data: encrypted })
});
```

---

## 8. データの保護

### 8.1 個人情報の暗号化

| データ | 暗号化 |
|--------|--------|
| **パスワード** | bcrypt（ハッシュ化） |
| **メールアドレス** | 暗号化（AES-256） |
| **電話番号** | 暗号化（AES-256） |
| **住所** | 暗号化（AES-256） |

### 8.2 データの削除

**論理削除を採用:**

- 物理削除ではなく、`deleted_at` フラグを設定
- 一定期間後に物理削除（90日後）

### 8.3 データの保持期間

| データ種類 | 保持期間 |
|-----------|---------|
| **お知らせ** | 1年間 |
| **掲示板投稿** | 3ヶ月 |
| **予約履歴** | 3ヶ月 |
| **監査ログ** | 1年間 |
| **削除されたデータ** | 90日間（その後物理削除） |

---

## 9. ログとモニタリング

### 9.1 監査ログ

以下のイベントをログに記録します:

| イベント | 記録内容 |
|---------|---------|
| **ログイン/ログアウト** | ユーザーID、IPアドレス、日時 |
| **データ作成/更新/削除** | ユーザーID、対象データ、操作内容、日時 |
| **権限エラー** | ユーザーID、アクセス先、日時 |
| **異常なアクセス** | IPアドレス、リクエスト内容、日時 |

### 9.2 ログの保存

| 項目 | 仕様 |
|------|------|
| **保存先** | 専用ログサーバー |
| **保持期間** | 1年間 |
| **暗号化** | 保存時に暗号化 |

### 9.3 セキュリティ監視

| 項目 | 対策 |
|------|------|
| **異常なログイン試行** | 5回失敗でアカウントロック（30分） |
| **大量リクエスト** | レートリミット（100リクエスト/分） |
| **不正なアクセス** | IPアドレスのブロック |

---

## 10. 脆弱性対策

### 10.1 依存パッケージの管理

| 項目 | 対策 |
|------|------|
| **定期的な更新** | 月1回、依存パッケージを更新 |
| **脆弱性スキャン** | `npm audit`、`pip check` を実行 |
| **自動通知** | Dependabotで脆弱性を通知 |

### 10.2 セキュリティパッチ

| 優先度 | 対応期間 |
|--------|---------|
| **Critical** | 24時間以内 |
| **High** | 1週間以内 |
| **Medium** | 1ヶ月以内 |
| **Low** | 次回リリース時 |

---

## 11. 開発時のセキュリティ

### 11.1 シークレット管理

**禁止事項:**
- GitにAPIキー、パスワードをコミットしない
- ハードコードしない

**推奨:**
- 環境変数で管理（`.env` ファイル）
- `.gitignore` に `.env` を追加

**例:**

```javascript
// ✅ 良い例
const apiKey = process.env.API_KEY;

// ❌ 悪い例
const apiKey = 'sk-1234567890abcdef';
```

### 11.2 コードレビュー

| 項目 | 確認内容 |
|------|---------|
| **入力検証** | すべてのユーザー入力を検証 |
| **エスケープ処理** | XSS対策が実施されているか |
| **認証・認可** | 適切にアクセス制御されているか |
| **シークレット管理** | APIキー等がハードコードされていないか |

---

## 12. インシデント対応

### 12.1 セキュリティインシデントの定義

| レベル | 定義 |
|--------|------|
| **Critical** | 個人情報の漏洩、システムダウン |
| **High** | 不正アクセス成功、データ改ざん |
| **Medium** | 脆弱性の発見、異常なアクセス |
| **Low** | 設定ミス、軽微な脆弱性 |

### 12.2 対応フロー

1. **検知:** 監視システムがインシデントを検知
2. **隔離:** 影響範囲を特定し、該当システムを隔離
3. **調査:** 原因を特定
4. **復旧:** システムを復旧
5. **報告:** 関係者に報告、必要に応じて公表

### 12.3 連絡先

| 役割 | 連絡先 |
|------|--------|
| **セキュリティ担当者** | security@securea.jp |
| **システム管理者** | admin@securea.jp |
| **緊急連絡先** | +81-XX-XXXX-XXXX |

---

## 13. セキュリティチェックリスト

### 13.1 開発時チェック

- [ ] すべてのユーザー入力をエスケープ
- [ ] CSRFトークンを実装
- [ ] プリペアドステートメントを使用
- [ ] ファイルアップロードを検証
- [ ] セッショントークンはHttpOnly Cookie
- [ ] APIキーを環境変数で管理

### 13.2 リリース前チェック

- [ ] 脆弱性スキャン実施（npm audit）
- [ ] HTTPS通信が有効
- [ ] Content Security Policyが設定済み
- [ ] 監査ログが正しく記録される
- [ ] セキュリティパッチが適用済み

---

## 14. 関連ドキュメント

| ドキュメント名 | 説明 |
|--------------|------|
| `common-performance-v1_0.md` | パフォーマンス要件 |
| `common-accessibility-v1_0.md` | アクセシビリティ要件 |
| `03_Multi-Tenant-Design-v2_0.md` | マルチテナント設計 |

---

**文書管理**
- 文書ID: SEC-APP-COMMON-SECURITY-001
- バージョン: 1.0
- 作成日: 2025年10月27日
- 承認者: （未定）
