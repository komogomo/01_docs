# 第4章 非機能要件（v1.2）

---

## 4.1 セキュリティ要件

### 4.1.1 認証方式
HarmoNetでは**Supabase Auth**を用いたMagic Link（パスワードレス）認証を採用する。  
すべてのユーザーはテナント単位で識別され、JWTトークンに `tenant_id` / `role` / `lang` を含む。

#### 認証フロー（更新版）
1. ユーザーがメールアドレスを入力し「ログインリンク送信」を押下  
2. SupabaseがMagic Linkメールを送信（SendGrid経由）  
3. ユーザーがリンクを開くと、Supabaseがトークンを検証しJWT発行  
4. JWTにはtenant_idが含まれ、RLSにより該当データのみ参照可能  
5. アプリ側（NestJS）はSupabase SDK経由で認証状態を検証  

```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "role": "tenant_admin",
  "lang": "ja",
  "exp": 1735600000
}
```

#### セキュリティ対策
| 項目 | 内容 |
|------|------|
| 認証強度 | UUIDv4トークン＋HTTPS限定 |
| トークン有効期限 | 15分（自動再発行あり） |
| レートリミット | 3リクエスト／分（Supabase設定） |
| 監査ログ | Supabase Auth Audit Logを利用 |
| 管理者強制ログアウト | Supabase APIによりセッション無効化可能 |

---

### 4.1.2 通信暗号化
- すべての通信は **TLS 1.3** により暗号化。  
- HTTPアクセスはVercelで自動リダイレクト。  
- 秘密情報（APIキー・トークン）はVercelおよびSupabaseの環境変数で管理。  
- DB上の個人情報（氏名・メール）はAES-256で暗号化保存。

---

### 4.1.3 データ分離（RLS）
Supabase PostgreSQLの **Row Level Security (RLS)** により、  
各テナント（管理組合）のデータは論理的に分離される。

```sql
CREATE POLICY tenant_isolation_policy
ON public.announcements
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

---

### 4.1.4 鍵管理
| 項目 | 方法 |
|------|------|
| 暗号鍵 | Supabase Secretsで管理 |
| 鍵ローテーション | 年1回またはインシデント時 |
| APIキー管理 | Supabaseサービスロールで限定使用 |
| 署名方式 | HS256署名によるJWT検証 |

---

## 4.2 性能要件

| 項目 | 要件値 | 備考 |
|------|----------|------|
| 初回ページ読み込み時間 | 3秒以内 | PWAキャッシュ利用時 |
| 再訪時読み込み時間 | 1秒以内 | ブラウザキャッシュ・CDN活用 |
| 翻訳処理時間 | 5秒以内（500文字） | Redisキャッシュ利用時 |
| API応答時間 | 2秒以内（95パーセンタイル） | Supabase Edge Function使用 |
| DBクエリ応答時間 | 1秒以内 | Prisma ORM最適化 |
| 同時アクセス | 200ユーザー（MVP）〜500ユーザー | Supabaseスケール対応 |

### 最適化手法
- **画像最適化**（WebP変換＋遅延読み込み）  
- **コード分割**（React Lazy Loading）  
- **CDN配信**（Vercel + Cloudflare）  
- **翻訳キャッシュ**（Redis + Supabaseストア）  
- **Supabase Edge Functions** によるバックエンド処理分散  

---

## 4.3 アクセシビリティ

WCAG 2.1 レベルAAに準拠。  
| 区分 | 要件 |
|------|------|
| 視覚 | コントラスト比4.5:1以上、200%拡大対応 |
| 聴覚 | 音声・動画コンテンツには字幕を付与（将来対応） |
| 操作 | キーボード操作・スクリーンリーダー対応 |
| 理解 | 明確なエラーメッセージと一貫したUI構成 |
| 多言語 | 日本語・英語・中国語対応（右から左言語は非対応） |

---

## 4.4 スケーラビリティ

### 対応戦略
1. **垂直スケール**：Supabaseプランアップグレード  
2. **水平スケール**：AWS ECS + RDSへの移行（フェーズ3以降）  
3. **キャッシュ層**：Redisクラスタによる分散処理  
4. **CDN**：Cloudflareで静的配信最適化  

### ユーザー規模想定
| フェーズ | 規模 | 対応 |
|-----------|------|------|
| MVP | 100ユーザー／単一物件 | Supabase Free Tier |
| Phase 2 | 500ユーザー／複数棟対応 | Supabase Pro Plan |
| Phase 3 | 5,000ユーザー／複数デベロッパー | AWS移行構成 |

---

## 4.5 信頼性・可用性

| 項目 | 要件 |
|------|------|
| 稼働率 | 99%以上（Vercel SLA基準） |
| バックアップ | Supabase自動バックアップ（1日1回、保持7日） |
| 障害検知 | UptimeRobot（3分監視）＋Sentry連携 |
| 復旧手順 | 自動スナップショットからのリストア、再デプロイ |
| デプロイ方式 | GitHub連携によるVercel自動デプロイ（ロールバック対応） |

---

*by GPT (HarmoNet PMO AI)*
