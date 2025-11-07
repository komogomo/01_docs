# HarmoNet API インタフェース仕様書 _latest  
**Phase 9.8 構成対応版（Supabase + Prisma + Next.js 15）**

---

## 第1章　目的と適用範囲
本書は HarmoNet アプリケーションにおける Next.js API Routes の設計仕様を定義する。  
Phase9.8 現行構成（技術スタック v3.7）に基づき、翻訳API・音声変換API・AI連携APIの通信構造および認証要件を明示する。

---

## 第2章　API全体設計方針

| 項目 | 内容 |
|------|------|
| 実行環境 | Next.js 15 / Node.js 22 LTS |
| 実装方式 | App Router 構成 (`/src/app/api/`) |
| データアクセス | Prisma ORM 経由で Supabase(PostgreSQL) に接続 |
| 認証方式 | JWT (Supabase Auth) |
| 認可方式 | tenant_id + role による判定 |
| 通信形式 | JSON (UTF-8) |
| エラーハンドリング | HTTPステータス＋JSONメッセージ形式で返却 |
| 環境変数 | `.env` ルート固定（`src/` 配下禁止） |

---

## 第3章　共通仕様

### 3.1 リクエストヘッダ

| キー | 型 | 必須 | 説明 |
|------|----|------|------|
| Authorization | string | ✅ | `Bearer <JWT>` Supabase Authトークン |
| Content-Type | string | ✅ | `application/json` |
| Accept-Language | string | 任意 | ユーザーの言語設定（翻訳APIで使用） |

### 3.2 共通レスポンス形式

```json
{
  "status": "success",
  "data": { ... },
  "error": null
}

エラー時：

{
  "status": "error",
  "message": "Invalid token",
  "code": 401
}

3.3 CORSポリシー

許可ドメイン: http://localhost:3000, 本番環境ドメイン（harmonet.cloud想定）

メソッド: GET, POST, OPTIONS

認証ヘッダ送信許可: Authorization

第4章　API一覧
| API名    | エンドポイント          | 概要                     | 認証 | 実行層  |
| ------- | ---------------- | ---------------------- | -- | ---- |
| 翻訳API   | `/api/translate` | Google Translate v3 呼出 | 必須 | サーバー |
| 音声変換API | `/api/tts`       | Voicebox / VOICEVOX 呼出 | 必須 | サーバー |
| AI連携API | `/api/ai-proxy`  | Claude / Gemini 呼出     | 必須 | サーバー |

第5章　個別API仕様
5.1 /api/translate
| 項目   | 内容                                 |         |
| ---- | ---------------------------------- | ------- |
| メソッド | POST                               |         |
| 入力   | `{ text: string, targetLang: "en"  | "zh" }` |
| 出力   | `{ translatedText: string }`       |         |
| 処理概要 | Google Translate API v3 を呼出し、結果を返却 |         |
| 補足   | キャッシュ（Phase10導入予定）                 |         |
| 例外   | APIキー欠損時は 500 Internal Error       |         |

5.2 /api/tts
| 項目   | 内容                                                       |
| ---- | -------------------------------------------------------- |
| メソッド | POST                                                     |
| 入力   | `{ text: string, voice?: "zundamon" }`                   |
| 出力   | `audio/mp3`                                              |
| 処理概要 | Voicebox → MP3生成 → Supabase Storage に保存 → URL返却          |
| 返却例  | `{ url: "https://storage.supabase.co/audio/xxxxx.mp3" }` |
| 認証   | JWT必須                                                    |
| 備考   | Storage ルールで tenant_id による分離                             |

5.3 /api/ai-proxy
| 項目   | 内容                                  |                             |
| ---- | ----------------------------------- | --------------------------- |
| メソッド | POST                                |                             |
| 入力   | `{ model: "claude"                  | "gemini", prompt: string }` |
| 出力   | `{ result: string, model: string }` |                             |
| 処理概要 | 選択モデルに応じて内部APIキーを呼出し、結果を返却          |                             |
| 認証   | JWT必須                               |                             |
| 制約   | 外部直接呼出禁止（内部サーバー経由のみ）                |                             |
| 備考   | Phase9以降、AI出力監査ログをDB記録予定            |                             |

第6章　DBアクセス仕様（Prisma統合）
| 区分       | 内容                                |
| -------- | --------------------------------- |
| ORM      | Prisma 6.19.0                     |
| DB       | Supabase PostgreSQL 15.6.1        |
| モデル      | schema.prisma v1.7                |
| トランザクション | `prisma.$transaction()` で制御       |
| エラー処理    | PrismaClientKnownRequestError を捕捉 |
| 非同期制御    | `async/await` 構文を原則とする            |
| 禁止事項     | Supabase JS Client 直呼び（REST経由除く）  |

第7章　エラーハンドリングポリシー
| 種類         | ステータス | 説明                     |
| ---------- | ----- | ---------------------- |
| 認証エラー      | 401   | JWT 無効または期限切れ          |
| 権限エラー      | 403   | role 不一致または tenant 不一致 |
| バリデーションエラー | 422   | 入力不正                   |
| サーバーエラー    | 500   | Prisma または 外部API 呼出失敗  |
| 成功         | 200   | 正常応答                   |

第8章　ログ・監査設計
・全API呼出は Next.js サーバーログに記録
・エラー発生時は console.error() + DB system_logs テーブルに出力（Phase10導入）
・AI連携APIはモデル名・入力長・レスポンス長を記録（匿名化）

第9章　ChangeLog
| Date       | Version | Summary                                    | Author |
| ---------- | ------- | ------------------------------------------ | ------ |
| 2025-11-07 | 1.3     | Phase9.8対応：Prisma経由API統一／翻訳・音声・AI連携API仕様更新 | タチコマ   |

Document ID: HNM-API-SPEC-20251107
Version: 1.3
Created: 2025-11-07
Last Updated: 2025-11-07
Author: タチコマ（HarmoNet AI Architect）
Approved: TKD（Project Owner）