# ========================================
# データベース設定
# ========================================

# SQLiteを使用する場合
DATABASE_URL="file:./prisma/dev.db"

# PostgreSQLを使用する場合（コメント解除して使用）
# DATABASE_URL="postgresql://user:password@localhost:5432/secure_city_db"

# MySQLを使用する場合（コメント解除して使用）
# DATABASE_URL="mysql://user:password@localhost:3306/secure_city_db"

# ========================================
# JWT設定
# ========================================

# ★重要: 本番環境では強力なランダム文字列に変更してください
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_EXPIRATION="24h"

# ========================================
# メール送信設定（SMTP）
# ========================================

# Mailtrap（開発・テスト用）
SMTP_HOST="smtp.mailtrap.io"
SMTP_PORT="2525"
SMTP_USER="your_mailtrap_user"
SMTP_PASS="your_mailtrap_password"

# # Gmail（本番推奨）
# SMTP_HOST="smtp.gmail.com"
# SMTP_PORT="587"
# SMTP_USER="your-email@gmail.com"
# SMTP_PASS="your-app-password"

# # SendGrid
# SMTP_HOST="smtp.sendgrid.net"
# SMTP_PORT="587"
# SMTP_USER="apikey"
# SMTP_PASS="your-sendgrid-api-key"

MAIL_FROM="noreply@securecity.app"

# ========================================
# アプリケーション設定
# ========================================

# アプリのURL（マジックリンク生成に使用）
APP_URL="http://localhost:3000"

# ノード環境
NODE_ENV="development"

# ポート
PORT="3000"

# ========================================
# ログレベル
# ========================================

LOG_LEVEL="debug"

# ========================================
# CORS設定（必要に応じて）
# ========================================

CORS_ORIGIN="http://localhost:3000,http://localhost:3001"

# ========================================
# マジックリンク設定
# ========================================

# トークン有効期限（分）
MAGIC_LINK_EXPIRY_MINUTES=15

# レート制限（1ユーザーあたり）
RATE_LIMIT_WINDOW_MINUTES=5
RATE_LIMIT_MAX_REQUESTS=3