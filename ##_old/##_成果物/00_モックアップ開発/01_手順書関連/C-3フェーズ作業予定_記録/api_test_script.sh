#!/bin/bash

# ========================================
# セキュレアシティAPI テストスクリプト
# ========================================

echo "🧪 セキュレアシティ API テスト開始"
echo "=================================="
echo ""

# APIのベースURL
BASE_URL="http://localhost:3000"

# ========================================
# 1. ヘルスチェック
# ========================================
echo "✅ テスト1: ヘルスチェック"
curl -X GET "$BASE_URL/auth/health"
echo -e "\n\n"

# ========================================
# 2. マジックリンク要求（新規ユーザー）
# ========================================
echo "✅ テスト2: マジックリンク要求（新規ユーザー）"
RESPONSE=$(curl -s -X POST "$BASE_URL/auth/request-magic-link" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user1@example.com",
    "name": "ユーザー1",
    "language": "JP"
  }')

echo "$RESPONSE"
echo -e "\n\n"

# ========================================
# 3. マジックリンク要求（英語）
# ========================================
echo "✅ テスト3: マジックリンク要求（英語ユーザー）"
curl -s -X POST "$BASE_URL/auth/request-magic-link" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user2@example.com",
    "name": "User Two",
    "language": "EN"
  }'
echo -e "\n\n"

# ========================================
# 4. マジックリンク要求（中国語）
# ========================================
echo "✅ テスト4: マジックリンク要求（中国語ユーザー）"
curl -s -X POST "$BASE_URL/auth/request-magic-link" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user3@example.com",
    "name": "用户3",
    "language": "CN"
  }'
echo -e "\n\n"

# ========================================
# 5. レート制限テスト
# ========================================
echo "✅ テスト5: レート制限チェック（同じメールで3回連続要求）"
for i in {1..3}; do
  echo "リクエスト $i 回目:"
  curl -s -X POST "$BASE_URL/auth/request-magic-link" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "ratelimit@example.com",
      "language": "JP"
    }'
  echo -e "\n"
  sleep 1
done

# 4回目は失敗するはず
echo "リクエスト 4 回目（失敗予定）:"
curl -s -X POST "$BASE_URL/auth/request-magic-link" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ratelimit@example.com",
    "language": "JP"
  }'
echo -e "\n\n"

# ========================================
# 6. 無効なトークンでの検証
# ========================================
echo "✅ テスト6: 無効なトークンでの検証（エラー予定）"
curl -s -X POST "$BASE_URL/auth/verify-token" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "invalid_token_here"
  }'
echo -e "\n\n"

# ========================================
# 7. 認証なしでプロフィール取得（エラー予定）
# ========================================
echo "✅ テスト7: 認証なしでプロフィール取得（エラー予定）"
curl -s -X GET "$BASE_URL/auth/profile"
echo -e "\n\n"

# ========================================
# 8. 有効なトークンでのプロフィール取得
# ========================================
echo "✅ テスト8: 有効なJWT トークンでプロフィール取得"
# ※実際のテストでは、テスト6で取得した有効なトークンを使用
VALID_TOKEN="your-actual-jwt-token-here"
curl -s -X GET "$BASE_URL/auth/profile" \
  -H "Authorization: Bearer $VALID_TOKEN"
echo -e "\n\n"

# ========================================
# まとめ
# ========================================
echo "✅ APIテスト完了！"
echo "=================================="
echo ""
echo "📝 テスト結果の確認ポイント："
echo "  ✓ テスト1: 200ステータスが返ること"
echo "  ✓ テスト2-4: マジックリンク送信成功メッセージ"
echo "  ✓ テスト5: 4回目は『リクエストが多すぎます』エラー"
echo "  ✓ テスト6: 『無効なトークン』エラー"
echo "  ✓ テスト7: 『認証トークンが見つかりません』エラー"
echo "  ✓ テスト8: プロフィール情報が返ること"
echo ""
echo "💡 次のステップ："
echo "  1. メールボックスを確認（Mailtrapの場合）"
echo "  2. メール内のマジックリンクをクリック"
echo "  3. ブラウザのコンソール でトークンを確認"
echo "  4. テスト8でそのトークンを使用"
echo ""