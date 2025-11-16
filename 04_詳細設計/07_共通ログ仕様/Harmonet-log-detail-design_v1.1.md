# HarmoNet 共通ログユーティリティ 詳細設計書 v1.1

**Document ID:** HARMONET-SYSTEM-LOG-UTILITY-DETAIL-DESIGN
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-15
**Updated:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Vitest対応版（TKDレビュー待ち）

---

## 第1章 概要

### 1.1 目的

本書は `harmonet-log-design_v1.1.md`（ログ基本設計）で定義された方針に基づき、
フロントエンド（Next.js / React）で使用する **共通ログユーティリティ** の詳細設計を定義する。

対象は「**いま実装する内容**」に限定し、以下のみをカバーする：

* `console.*` を用いたブラウザコンソール出力
* ログレベルとイベント名の扱い
* ログペイロード（JSON）の構造
* メールアドレス等の簡易マスキング
* Vitest / RTL からの検証方法

将来の外部ログサービス連携や拡張案など、未実装の話題は本書には含めない。

### 1.2 適用範囲

* 対象: フロントエンド（Next.js 16 / React 19 / TypeScript 5）
* 出力先: ブラウザコンソール（`console.log` / `console.info` / `console.warn` / `console.error`）のみ
* 利用者: 画面コンポーネント（例: LoginPage, MagicLinkForm, PasskeyAuthTrigger）および将来追加される UI コンポーネント群

---

## 第2章 ログ方針の具体化

### 2.1 ログレベル

ログ基本設計 v1.1 を前提とし、フロントエンドでは次の 4 レベルを扱う。

* `DEBUG` : 開発時の詳細情報。テストやデバッグの補助としてのみ使用。
* `INFO`  : アプリケーションレベルの正常イベント（いわゆる AP ログ）。
* `WARN`  : 直ちに致命的ではないが注意が必要な事象。v1.1 では利用を最小限に留める。
* `ERROR` : 異常・例外。ユーザー体験に影響する失敗を記録する。

### 2.2 出力先と利用範囲

* すべてのログは **ブラウザコンソール** にのみ出力する。
* 監視・通知・集計などの運用用途には用いず、開発・不具合調査の補助として位置付ける。
* コンポーネントやフックは `console.*` を直接呼び出さず、本書で定義するユーティリティ関数のみを使用する。

---

## 第3章 モジュール構成

### 3.1 ファイル構成

```text
src/
  lib/
    logging/
      log.types.ts       // ログレベル・ペイロードの型定義
      log.config.ts      // ログ有効/無効、レベル閾値などの設定
      log.util.ts        // 公開 API（logInfo / logError 等）の実装
```

### 3.2 型定義（log.types.ts）

```ts
export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface LogPayload {
  level: LogLevel;
  timestamp: string; // ISO8601 UTC
  event: string;     // 例: 'auth.login.success.magiclink'
  message?: string;  // 任意の補足メッセージ
  screen?: string;   // 例: 'LoginPage'
  context?: Record<string, unknown>; // 任意の補足情報
}

export interface LogConfig {
  enabled: boolean;         // ログ全体の ON/OFF
  levelThreshold: LogLevel; // このレベル以上のみ出力
  maskEmail: boolean;       // メールアドレスマスキングの有無
}
```

### 3.3 設定（log.config.ts）

```ts
import type { LogConfig, LogLevel } from './log.types';

const levelOrder: LogLevel[] = ['DEBUG', 'INFO', 'WARN', 'ERROR'];

const getEnv = () =>
  typeof process !== 'undefined' ? process.env.NODE_ENV ?? 'development' : 'development';

const env = getEnv();

export const defaultLogConfig: LogConfig = {
  enabled: env !== 'test',
  levelThreshold: env === 'production' ? 'INFO' : 'DEBUG',
  maskEmail: true,
};

export const shouldLog = (level: LogLevel, config: LogConfig = defaultLogConfig): boolean => {
  if (!config.enabled) return false;

  const idx = levelOrder.indexOf(level);
  const thresholdIdx = levelOrder.indexOf(config.levelThreshold);
  return idx >= thresholdIdx;
};
```

* `NODE_ENV = 'test'` の場合、ログは出力しない。
* 本設計では環境変数は最小限に留め、挙動は `enabled / levelThreshold / maskEmail` の 3 つで制御する。

---

## 第4章 ログユーティリティ API 仕様（log.util.ts）

### 4.1 公開関数

```ts
export const logDebug: (event: string, context?: Record<string, unknown>) => void;
export const logInfo:  (event: string, context?: Record<string, unknown>) => void;
export const logWarn:  (event: string, context?: Record<string, unknown>) => void;
export const logError: (event: string, context?: Record<string, unknown>) => void;
```

* `event`: ログイベント名（命名規約は第5章）
* `context`: 任意の補足情報。メールアドレスなどを含む場合は、内部でマスキングされる。

### 4.2 内部処理フロー

1. `logInfo('auth.login.start', { screen: 'LoginPage' })` などが呼ばれる。
2. `shouldLog(level, defaultLogConfig)` で出力対象かを判定。
3. 出力対象の場合、`LogPayload` を組み立てる。
4. `maskEmail = true` の場合、context 内のメールアドレスらしき値を簡易マスキング。
5. `JSON.stringify(payload)` で文字列化し、レベルに応じて `console.*` に渡す。

### 4.3 実装イメージ

```ts
import { defaultLogConfig, shouldLog } from './log.config';
import type { LogLevel, LogPayload } from './log.types';

const maskSensitive = (context?: Record<string, unknown>): Record<string, unknown> | undefined => {
  if (!context) return undefined;

  const cloned: Record<string, unknown> = { ...context };

  for (const key of Object.keys(cloned)) {
    const value = cloned[key];
    if (typeof value === 'string' && /@/.test(value)) {
      cloned[key] = '[masked-email]';
    }
  }

  return cloned;
};

const buildPayload = (level: LogLevel, event: string, context?: Record<string, unknown>): LogPayload => {
  const base: LogPayload = {
    level,
    timestamp: new Date().toISOString(),
    event,
  };

  const maskedContext = defaultLogConfig.maskEmail ? maskSensitive(context) : context;
  return maskedContext ? { ...base, context: maskedContext } : base;
};

const emit = (level: LogLevel, event: string, context?: Record<string, unknown>): void => {
  if (!shouldLog(level, defaultLogConfig)) return;

  const payload = buildPayload(level, event, context);
  const json = JSON.stringify(payload);

  switch (level) {
    case 'ERROR':
      console.error(json);
      break;
    case 'WARN':
      console.warn(json);
      break;
    case 'INFO':
      console.info(json);
      break;
    default:
      console.log(json);
  }
};

export const logDebug = (event: string, context?: Record<string, unknown>) => emit('DEBUG', event, context);
export const logInfo  = (event: string, context?: Record<string, unknown>) => emit('INFO', event, context);
export const logWarn  = (event: string, context?: Record<string, unknown>) => emit('WARN', event, context);
export const logError = (event: string, context?: Record<string, unknown>) => emit('ERROR', event, context);
```

---

## 第5章 イベント命名規約

### 5.1 命名ルール

`event` には以下の形式を用いる：

```text
<domain>.<feature>.<action>[.<detail>]
```

* `domain` : 機能領域（例: `auth`, `board`, `reservation`）
* `feature`: サブ機能（例: `login`, `magiclink`, `passkey`）
* `action` : 成否・状態（例: `start`, `success`, `fail`）
* `detail` : 必要に応じた補足（例: `supabase`, `network`, `not_supported`）

### 5.2 LoginPage 系の例

LoginPage 詳細設計（A-00）で定義するイベント ID と対応させる想定で、例を示す：

| ID（参考） | event 値                                 | 用途               |
| ------ | --------------------------------------- | ---------------- |
| LG-01  | `auth.login.page.mount`                 | `/login` 初期表示    |
| LG-02  | `auth.login.start`                      | ログイン処理開始         |
| LG-03  | `auth.login.success.magiclink`          | MagicLink ログイン成功 |
| LG-04  | `auth.login.success.passkey`            | Passkey ログイン成功   |
| LG-05  | `auth.login.fail.input`                 | 入力バリデーションエラー     |
| LG-06  | `auth.login.fail.supabase.network`      | Supabase 通信エラー   |
| LG-07  | `auth.login.fail.supabase.auth`         | Supabase 認証エラー   |
| LG-08  | `auth.login.fail.passkey.denied`        | Passkey キャンセル    |
| LG-09  | `auth.login.fail.passkey.not_supported` | Passkey 非対応      |
| LG-10  | `auth.login.fail.unexpected`            | 想定外エラー           |

他画面でも同じ規則を用い、`domain` / `feature` の部分だけを変更する。

---

## 第6章 個人情報保護

### 6.1 マスキング対象

* context 内に含まれるメールアドレスらしき文字列（`@` を含む文字列）は、
  ログ出力前に `[masked-email]` へ置換する。
* v1.1 では単純な判定とし、厳密な PII 判定は行わない。

### 6.2 呼び出し側の責務

* ユーザー名や自由入力文など、明らかにログに残すべきでない情報は、
  そもそも `context` に渡さない。
* どうしても渡す必要がある場合は、呼び出し側で十分に加工した値を渡す。

---

## 第7章 使用例

### 7.1 LoginPage からの利用例

```ts
// ログイン開始
logInfo('auth.login.start', {
  screen: 'LoginPage',
  method: 'magiclink',
});

// Supabase 認証エラー
logError('auth.login.fail.supabase.auth', {
  screen: 'LoginPage',
  reason: 'auth_error',
  code: error.code,
});

// Passkey キャンセル
logError('auth.login.fail.passkey.denied', {
  screen: 'LoginPage',
  reason: 'user_cancelled',
});
```

### 7.2 その他画面の例

```ts
logInfo('board.post.create.start', { screen: 'BoardPostPage' });
logInfo('board.post.create.success', { screen: 'BoardPostPage', postId });
logError('board.post.create.fail.network', { screen: 'BoardPostPage' });
```

---

## 第8章 テスト仕様

### 8.1 ユニットテスト（log.util.ts, log.config.ts）

* フレームワーク: Vitest

#### 8.1.1 観点

1. レベルフィルタ

   * `levelThreshold = 'INFO'` の場合、`DEBUG` は出力されず、`INFO` 以上のみ出力される。
2. PII マスキング

   * `context` にメールアドレスを含めた場合、ログ出力時には `[masked-email]` に置換されている。
3. JSON 出力

   * `console.info` / `console.error` に渡される引数が JSON 文字列であること。
4. 有効/無効

   * `enabled: false` の設定では、どのレベルでも `console.*` が呼ばれないこと。

#### 8.1.2 サンプルテスト

```ts
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { logInfo } from '@/src/lib/logging/log.util';

describe('log.util', () => {
  beforeEach(() => {
    vi.spyOn(console, 'info').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('INFO ログを JSON 形式で出力する', () => {
    logInfo('auth.login.start', { screen: 'LoginPage' });

    expect(console.info).toHaveBeenCalledTimes(1);
    const [arg] = (console.info as any).mock.calls[0];

    const payload = JSON.parse(arg as string);
    expect(payload.level).toBe('INFO');
    expect(payload.event).toBe('auth.login.start');
    expect(payload.context.screen).toBe('LoginPage');
  });
});
```

### 8.2 結合テスト（LoginPage からの呼び出し）

* RTL + Vitest で LoginPage / MagicLinkForm をレンダリングし、以下を確認する：

  * 「ログイン」ボタン押下で `logInfo('auth.login.start', ...)` が 1 回呼ばれる。
  * バリデーションエラー時に `logError('auth.login.fail.input', ...)` が呼ばれる。
  * Supabase エラーをモックした場合に `logError('auth.login.fail.supabase.*', ...)` が呼ばれる。

---

## 第9章 変更履歴（ChangeLog）

| Version | 日付         | 変更概要                                                                                                                                     |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| v1.1    | 2025-11-16 | Vitest対応版。Jest記述をVitestに変更（`vi.spyOn()`, `vi.restoreAllMocks()`, Vitestインポート）。テストフレームワークを既存プロジェクト設定に統一。                             |
| v1.0    | 2025-11-15 | 初版作成。ログ基本設計 v1.1 を前提に、フロントエンド共通ログユーティリティ（logDebug/logInfo/logWarn/logError）の仕様・JSON フォーマット・イベント命名規約・PII マスキング・テスト観点を定義（Jest版）。 |
