# HarmoNet ログ出力 基本設計書 v1.0

**Document ID:** HARMONET-LOG-DESIGN-V1.0
**作成日:** 2025-11-15
**作成者:** Gemini (HarmoNet Architect)
**レビュアー:** TKD (Project Owner)
**ステータス:** Draft
**準拠:** functional-requirements-ch04-nonfunctional-req_v1.4.md

---

## 1. 目的

本設計書は、HarmoNetプロジェクトにおけるアプリケーションログの出力方式を統一し、開発時のデバッグと本番環境（Vercel）での障害調査を効率化することを目的とする。

非機能要件定義書（v1.4）の4.8.5節に基づき、`console.log` / `console.error` で出力する際の**共通フォーマット（JSON構造）**と**ログレベル**を定義する。

## 2. ログアーキテクチャ概要

非機能要件（v1.4）に基づき、HarmoNetのログアーキテクチャは以下を前提とする。

* **監査ログ:** スコープ外（廃止）。
* **エラー監視 (Sentry):** スコープ外（廃止）。
* **外部ログサービス (Axiom等):** スコープ外（廃止）。
* **出力先:** すべてのログは**標準出力（stdout）**に出力する。
* **閲覧場所:**
    * 開発環境: `docker-compose logs`
    * 本番環境: Vercel UI (Logsタブ)
* **保持期間:** Vercelの標準保持期間（7日間程度）に従う。

## 3. ログレベル定義

非機能要件（v1.4）の4.8.3節に基づき、ログレベルを以下のように定義する。

| レベル | 使用する関数 | 目的 | 本番出力 |
| :--- | :--- | :--- | :--- |
| **ERROR** | `console.error` | 致命的な例外・クラッシュ。システムの継続が困難なエラー。 | **必須** |
| **WARN** | `console.warn` | 警告。処理は続行できるが、想定外の状態や将来の問題を示唆する。 | **必須** |
| **INFO** | `console.info` | 情報。主要な処理の開始・終了など、動作フローを把握するためのログ。 | **必須** |
| **DEBUG** | `console.debug` | デバッグ。開発時のみ使用する詳細なトレース情報（例: 変数の中身）。 | **非推奨** |

> **方針:** 本番環境では`INFO`レベル以上を出力する。`DEBUG`レベルのログは、Vercelの環境変数 `LOG_LEVEL` が `DEBUG` の時のみ出力するなど、本番環境でデフォルトで出力されないように制御する。

## 4. 共通ログフォーマット（JSON）

Vercel UIでの検索性・可読性を高めるため、すべてのログは**単一のJSONオブジェクト**として出力する。

### 4.1 基本構造

```json
{
  "level": "INFO",
  "timestamp": "2025-11-15T09:30:00.123Z",
  "message": "ここに人間が読むためのメッセージを記載",
  "context": {
    "key": "value"
  }
}

| キー | 型 | 必須 | 説明 |
| :--- | :--- | :--- | :--- |
| `level` | String | ✅ | ログレベル (`INFO`, `WARN`, `ERROR`のいずれか) |
| `timestamp` | String | ✅ | ISO 8601形式のタイムスタンプ (`new Date().toISOString()`) |
| `message` | String | ✅ | ログの概要を示す人間が読めるメッセージ |
| `context` | Object | ⚠️ | 調査に必要な補助情報（コンテキスト）。詳細は次項。 |
| `stack` | String | (Error時) | `ERROR`レベルの場合、`error.stack`を格納する。 |

4.3 context オブジェクトの詳細
contextには、ログの発生源や状況を特定するための情報を格納する。

共通コンテキスト:
・functionName: (推奨) ログが出力された関数名やコンポーネント名（例: handleLogin, FacilityBookingCalendar）

リクエストコンテキスト (API Routes / Server Components):
・path: (推奨) リクエストパス（例: /api/auth/login）
・method: (推奨) HTTPメソッド（例: POST）
・userId: (可能な場合) 認証済みユーザーのID
・tenantId: (可能な場合) 処理対象のテナントID

セキュリティ:
・非機能要件（v1.4）の4.8.3節に基づき、個人情報（メールアドレス、氏名、パスワード等）は絶対に出力しないこと。

---

### 3/3: 実装例・詳細設計 (5〜6章)

```markdown
## 5. 実装例（ロガーユーティリティ）

開発 eficiencia化のため、このJSONフォーマットを生成する簡易的なロガーユーティリティ（例: `src/lib/logger.ts`）を作成することを推奨する。

```typescript
// src/lib/logger.ts (実装例)

type LogContext = Record<string, any>;

const output = (level: 'INFO' | 'WARN' | 'ERROR' | 'DEBUG', message: string, context?: LogContext, stack?: string) => {
  // DEBUGレベルは環境変数で制御
  if (level === 'DEBUG' && process.env.LOG_LEVEL !== 'DEBUG') {
    return;
  }

  const logEntry = {
    level,
    timestamp: new Date().toISOString(),
    message,
    context: context || {}, // contextがnullでも空オブジェクトを保証
    stack: stack || undefined, // stackがなければundefined
  };

  // Vercelログに出力
  if (level === 'ERROR') {
    console.error(JSON.stringify(logEntry));
  } else if (level === 'WARN') {
    console.warn(JSON.stringify(logEntry));
  } else if (level === 'DEBUG') {
    console.debug(JSON.stringify(logEntry));
  } else {
    console.info(JSON.stringify(logEntry));
  }
};

export const logger = {
  info: (message: string, context?: LogContext) => {
    output('INFO', message, context);
  },
  warn: (message: string, context?: LogContext) => {
    output('WARN', message, context);
  },
  error: (message: string, error: Error, context?: LogContext) => {
    output('ERROR', message, context, error.stack);
  },
  debug: (message: string, context?: LogContext) => {
    output('DEBUG', message, context);
  },
};

6. 詳細設計書での利用
要件定義書（v1.4）の4.8.5節に基づき、各画面・機能の詳細設計書では、この基本設計書（v1.0）に従い、以下の点を明記する。
・どのイベントで（例: 「ログインボタン押下時」「DB接続失敗時」）
・どのレベルで（例: INFO, ERROR）
・どのようなmessageとcontextを 記録するか

詳細設計書 記述例
### 4. ログ出力仕様

本機能では、以下のタイミングでログを出力する。

| タイミング | レベル | メッセージ | context (例) |
| :--- | :--- | :--- | :--- |
| ログイン処理開始 | INFO | ログイン処理開始 | `{ functionName: 'handleLogin', path: '/api/auth/login' }` |
| 認証失敗 | WARN | 認証に失敗しました | `{ functionName: 'handleLogin', error: 'Invalid credentials' }` |
| サーバーエラー | ERROR | ログイン処理中に例外発生 | `{ functionName: 'handleLogin' }` (エラー詳細はstackに) |

