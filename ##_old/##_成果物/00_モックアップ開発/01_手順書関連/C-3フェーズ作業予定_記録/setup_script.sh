#!/bin/bash

# ========================================
# セキュレアシティAPI セットアップスクリプト
# ========================================

echo "🚀 セキュレアシティAPI セットアップ開始"
echo "========================================"
echo ""

# ターミナルの色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ========================================
# 1. Node.jsバージョン確認
# ========================================
echo "${YELLOW}📋 ステップ1: 環境チェック${NC}"
echo "Node.jsバージョン確認..."

NODE_VERSION=$(node --version)
echo "Node.js: $NODE_VERSION"

NPM_VERSION=$(npm --version)
echo "npm: $NPM_VERSION"

if ! command -v node &> /dev/null; then
  echo "${RED}❌ Node.jsがインストールされていません${NC}"
  exit 1
fi

echo "${GREEN}✅ Node.js環境OK${NC}"
echo ""

# ========================================
# 2. パッケージインストール
# ========================================
echo "${YELLOW}📦 ステップ2: パッケージインストール${NC}"

if [ ! -d "node_modules" ]; then
  echo "npm installを実行中..."
  npm install
  echo "${GREEN}✅ パッケージインストール完了${NC}"
else
  echo "✅ パッケージは既にインストール済み"
fi

echo ""

# ========================================
# 3. 環境変数ファイル設定
# ========================================
echo "${YELLOW}⚙️  ステップ3: 環境変数設定${NC}"

if [ ! -f ".env" ]; then
  echo "⚠️  .envファイルが見つかりません"
  echo ".env.exampleからコピー中..."
  cp .env.example .env
  echo "${YELLOW}⚠️  .envファイルを編集してください:${NC}"
  echo "   - JWT_SECRET を強力な値に変更"
  echo "   - SMTP_* を設定"
  echo "   - APP_URL を確認"
  echo ""
else
  echo "✅ .envファイルは既に存在します"
fi

echo ""

# ========================================
# 4. Prisma初期化
# ========================================
echo "${YELLOW}🗄️  ステップ4: Prismaセットアップ${NC}"

if [ ! -d "prisma" ]; then
  echo "❌ prismaディレクトリが見つかりません"
  exit 1
fi

echo "Prisma Clientを生成中..."
npx prisma generate

echo "データベースマイグレーション実行中..."
npx prisma migrate dev --name init

echo "${GREEN}✅ Prismaセットアップ完了${NC}"
echo ""

# ========================================
# 5. ディレクトリ構成確認
# ========================================
echo "${YELLOW}📂 ステップ5: ディレクトリ構成確認${NC}"

echo "必要なファイルをチェック中..."

REQUIRED_FILES=(
  "src/auth/dto/index.ts"
  "src/auth/services/magic-link.service.ts"
  "src/auth/services/mail.service.ts"
  "src/auth/auth.controller.ts"
  "src/auth/auth.module.ts"
  "src/auth/guards/jwt-auth.guard.ts"
  "prisma/schema.prisma"
  ".env"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "${RED}❌ 見つかりません: $file${NC}"
    MISSING_FILES=$((MISSING_FILES + 1))
  else
    echo "${GREEN}✅ $file${NC}"
  fi
done

if [ $MISSING_FILES -gt 0 ]; then
  echo "${RED}⚠️  $MISSING_FILES個のファイルが見つかりません${NC}"
  echo "手動で作成してください"
else
  echo "${GREEN}✅ すべてのファイルが揃っています${NC}"
fi

echo ""

# ========================================
# 6. 起動確認
# ========================================
echo "${YELLOW}🧪 ステップ6: 起動テスト${NC}"

echo "NestJSアプリケーションをビルド中..."
npm run build

if [ $? -eq 0 ]; then
  echo "${GREEN}✅ ビルド成功${NC}"
else
  echo "${RED}❌ ビルド失敗${NC}"
  exit 1
fi

echo ""

# ========================================
# 7. 完了メッセージ
# ========================================
echo "${GREEN}========================================${NC}"
echo "${GREEN}✅ セットアップ完了！${NC}"
echo "${GREEN}========================================${NC}"
echo ""

echo "📝 次のステップ:"
echo ""
echo "1️⃣  開発サーバー起動:"
echo "   ${YELLOW}npm run start:dev${NC}"
echo ""
echo "2️⃣  APIテスト実行："
echo "   ${YELLOW}bash api-test.sh${NC}"
echo ""
echo "3️⃣  ブラウザでアクセス："
echo "   ${YELLOW}http://localhost:3000/auth/health${NC}"
echo ""
echo "💡 トラブルシューティング:"
echo "   - エラーが出た場合は .env を確認"
echo "   - データベースエラーの場合は npx prisma migrate reset"
echo "   - ポート競合の場合は PORT=3001 npm run start:dev"
echo ""