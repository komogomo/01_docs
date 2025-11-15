# HarmoNet ログ出力 基本設計書（v1.1 修正版）

## 0. ドキュメント情報

* 文書名: HarmoNet ログ出力 基本設計書
* Version: v1.1
* Status: Draft（TKD確認前）
* 対象システム: HarmoNet
* 関連文書:

  * 機能要件定義書 第4章 非機能要件（`functional-requirements-ch04-nonfunctional-req_v1.4.md` 修正版）
  * HarmoNet 技術スタック定義書 v4.2
  * LoginPage / MagicLinkForm / PasskeyButton 詳細設計書

---

## 1. 目的・前提

本書は、HarmoNet における **ログ出力方式** を定義する「最小限の共通ルール」を示す。

### 1.1 対象範囲

* 対象とするログ種別

  * アプリケーションログ（APログ）
  * エラーログ
* 対象レイヤ

  * フロントエンド：Next.js 16 / React 19（Vercel ホスティング）
  * バックエンド：Supabase（PostgreSQL / Auth / Edge Functions）

### 1.2 前提条件（非機能要件との整合）

* 監視サービス（Sentry / UptimeRobot / Datadog 等）は **導入しない**。
* 外部ログ集約サービス（Axiom / Logflare 等）は **導入しない**。
* CI/CD（GitHub Actions などの自動デプロイ）は **導入しない**。
* 本番ログの保持期間は、Vercel / Supabase の標準ログ保持（目安 7 日）で十分とする。
* 操作履歴や法的な証跡を目的とした「監査ログ（Audit Log）」は **MVP スコープ外** とする。

---

## 2. ログ種別と目的

### 2.1 アプリケーションログ（APログ）

* 目的

  * 動作確認・障害調査・開発時のデバッグを行うための挙動記録。
* 典型的な記録対象

  * ログイン／ログアウトの試行・成功・失敗
  * 重要画面の表示（ダッシュボード等）
  * 重要な UI アクション（送信ボタン押下など）の開始／完了

### 2.2 エラーログ

* 目的

  * 想定外エラー・例外発生箇所と原因を特定するための記録。
* 典型的な記録対象

  * 例外スロー（`throw`）により処理が中断したケース
  * Supabase との通信エラー / Corbado 連携エラー
  * ネットワーク切断等によりユーザー操作が完了できなかったケース

---

## 3. 出力先・保持・確認方法

### 3.1 出力先

* フロントエンド

  * `console.log` / `console.info` / `console.warn` / `console.error` による **標準出力（stdout）** のみ。
* Supabase 側（Edge Functions / サーバログ）

  * 標準出力に対する `console.log` / `console.error` を基本とする。

### 3.2 保持期間

* Vercel ログ

  * Vercel が提供する標準保持期間（目安 7 日）に依存する。
  * 7 日を超える長期保存は要件としない。
* Supabase ログ

  * Supabase プロジェクトの標準ログ保持期間に依存し、長期アーカイブは行わない。

### 3.3 確認方法

* 開発環境

  * Next.js 開発サーバ：`npm run dev` のターミナル出力。
  * Docker 利用時：`docker compose logs`。
* 本番環境

  * フロントエンド：Vercel ダッシュボードの Logs 画面。
  * Supabase：Supabase ダッシュボードの Logs / Auth / Edge Functions ビュー。

> 備考：
>
> * 「監視」や「自動アラート（メール通知等）」は実施しない。
> * 障害に気付いた時点で、開発者が手動でログを確認する運用とする。

---

## 4. ログフォーマット

### 4.1 共通フォーマット方針

* APログ・エラーログとも、**JSON 文字列** を `console.*` で出力する。
* 最小限、以下のフィールドを推奨とする：

```ts
{
  level: 'INFO' | 'WARN' | 'ERROR' | 'DEBUG',
  timestamp: string,          // ISO8601 UTC
  event: string,              // 例: 'auth.login.success'
  message?: string,           // 人間可読な補足
  screen?: string,            // 例: 'LoginPage'
  context?: Record<string, unknown>,
  stack?: string              // ERROR 時のみ（本番では省略可）
}
```

### 4.2 個人情報の扱い

* 直接的な個人情報（氏名・メールアドレス・住所・電話番号等）はログに出力しない。
* 必要な場合は、匿名化された ID やハッシュ値で代替する。
* メールアドレスは、原則として context からも除外する（どうしても必要な場合はハッシュ化）。

### 4.3 ログレベル運用

* `DEBUG`

  * 開発時の詳細トレース用。本番環境では基本的に使用しない。
* `INFO`

  * 正常系イベントの記録（ログイン成功、画面表示開始／完了など）。
* `WARN`

  * 想定内だが注意が必要な事象（バリデーションエラー、リトライ発生など）。
* `ERROR`

  * 想定外のエラーや処理が完了できなかった事象。

本番環境でのログ出力は、最低限 `INFO`・`WARN`・`ERROR` を対象とし、必要に応じて `DEBUG` を一時的に有効化してもよい。

---

## 5. ロガー構成（論理設計）

### 5.1 Logger ヘルパ

フロントエンド・バックエンド共通で利用可能な、薄いロガー関数を 1 箇所にまとめる。

* 想定配置：`src/lib/logger.ts`
* 役割

  * ログレベル / タイムスタンプ / event / context をまとめて JSON 出力する。
  * 呼び出し側は `logInfo('auth.login.success', { screen: 'LoginPage' })` のように利用する。

```ts
// 例: logger.ts（概念レベル）

export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

function log(level: LogLevel, event: string, context: Record<string, unknown> = {}): void {
  const payload = {
    level,
    event,
    timestamp: new Date().toISOString(),
    ...context,
  };

  // 実際の出力先は console のみ
  // （外部ログサービスやファイル出力は行わない）
  switch (level) {
    case 'ERROR':
      console.error(JSON.stringify(payload));
      break;
    case 'WARN':
      console.warn(JSON.stringify(payload));
      break;
    case 'INFO':
      console.info(JSON.stringify(payload));
      break;
    default:
      console.log(JSON.stringify(payload));
  }
}

export const logDebug = (event: string, context?: Record<string, unknown>) =>
  log('DEBUG', event, context);
export const logInfo = (event: string, context?: Record<string, unknown>) =>
  log('INFO', event, context);
export const logWarn = (event: string, context?: Record<string, unknown>) =>
  log('WARN', event, context);
export const logError = (event: string, context?: Record<string, unknown>) =>
  log('ERROR', event, context);
```

> 備考：
>
> * Next.js / Edge Runtime での `console.*` 出力は標準ログとして扱われる。
> * 環境変数によるログレベル制御（`LOG_LEVEL` など）は、必要になった時点で追加検討する。

---

## 6. 画面・機能ごとのログ出力方針

### 6.1 LoginPage（A-00）

* MagicLinkForm / PasskeyButton の詳細設計書で定義されたイベントに対し、以下を基本とする：

| タイミング             | レベル   | event 例                       | 備考                |
| ----------------- | ----- | ----------------------------- | ----------------- |
| ログインボタン押下         | INFO  | `auth.login.submit`           | 入力値はログに含めない       |
| ログイン成功（MagicLink） | INFO  | `auth.login.success.magic`    | userId は匿名 ID のみ  |
| ログイン成功（Passkey）   | INFO  | `auth.login.success.passkey`  |                   |
| 入力エラー（メール形式不正など）  | WARN  | `auth.login.validation_error` | どの項目で失敗したかのみ記録    |
| 想定外エラー            | ERROR | `auth.login.unexpected_error` | `logError` で詳細を記録 |

### 6.2 その他画面・機能

* 掲示板・予約など他機能でも、同様に「開始 / 成功 / 失敗 / 想定外エラー」を中心に AP / エラーログを出す。
* 具体的な event 名・レベルは、それぞれの詳細設計書にて定義する。

---

## 7. 運用・監視との関係

* 専用の監視サービスは導入しないため、ログはあくまで

  * 開発中デバッグ
  * 障害発生後の原因調査（直近 7 日程度）
    に用いる。
* 稼働監視・通知は行わない。

  * システム停止に気づいたタイミングで、開発者が Vercel / Supabase のログを確認する運用とする。
* 長期的な統計分析・行動分析（BI）的な用途は、本ログ設計の対象外とする。

---

## 8. 将来拡張のためのメモ

将来的に監査ログ・監視・外部ログサービスを導入する場合、以下の観点で別設計書を用意する。

* 監査ログ（Audit Log）の導入

  * 操作履歴を保持するための DB テーブル設計（`audit_logs` 等）
  * 多テナント対応・保持期間・開示ポリシー
* 監視・アラート

  * Uptime チェック / レイテンシ監視 / 5xx 比率
  * 通知チャネル（メール / Slack 等）
* 外部ログサービス

  * Axiom / Datadog 等に転送する場合のフォーマット・コスト・運用方針

これらは **現行バージョンのスコープ外** であり、必要になったタイミングで別途要件定義から実施する。

---

## 9. ChangeLog

* v1.1 (2025-11-15)

  * 非機能要件 ch04 v1.4 修正版に合わせて全面見直し。
  * 監査ログ（Audit Log）・Sentry・外部ログサービス依存の記述を削除。
  * ログ種別を「APログ / エラーログ」の 2 種類に整理。
  * 出力先を `console.*` → Vercel / Supabase 標準ログのみに限定。
  * LoginPage を例に、イベントごとのログレベルと event 名の例を追加。
