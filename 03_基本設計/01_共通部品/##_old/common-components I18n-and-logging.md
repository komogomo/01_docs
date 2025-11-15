# 共通部品 基本設計書：i18n & ログ連携

Version: v1.1
Status: Draft
Author: Tachikoma (ChatGPT)
LastUpdated: 2025-11-15

---

## 1. 本書の目的

本書は、HarmoNet 全体で共通利用する以下の技術要素について、責務分担と連携仕様を定義する。

* i18n（多言語対応）
* ログ出力（開発・運用ログ）
* 共通エラー処理（ErrorHandler / Toast / Boundary）

ログイン画面（A-00 LoginPage / A-01 MagicLinkForm / A-02 PasskeyButton）を含む全画面が、
個別実装ではなく共通部品を経由して統一的な挙動を取ることを目的とする。

---

## 2. 対象スコープと関連コンポーネント

### 2.1 対象コンポーネント

本書で対象とする共通部品は、機能コンポーネント一覧のうち以下とする。

* C-02: LanguageSwitch
* C-03: StaticI18nProvider
* C-16: ErrorHandlerProvider
* C-17: ErrorLoggerService（実体は `logger.ts` をラップするサービス）
* C-18: ErrorBoundary
* C-19: ErrorToastDispatcher
* C-20: AccessibilityConfig（メッセージ表示のアクセシビリティ連携のみ）

### 2.2 非対象（参考）

* 監視・アラートサービス（Sentry 等）

  * 現時点では導入しない。要件定義書・ログ設計書に従う。
* 監査ログ（ビジネスイベントとしての操作履歴）

  * 将来の仕様検討対象とし、本書では扱わない。

---

## 3. i18n 基本設計

### 3.1 全体方針

* 文言はすべて i18n 辞書で管理し、画面コードにハードコードしない。
* i18n キーは UI メッセージ専用とし、ログメッセージとは分離する。
* i18n レイヤのエラー（辞書ロード失敗・キー不足）は、ログ出力と UI フォールバックを組み合わせて処理する。

### 3.2 StaticI18nProvider の責務

`StaticI18nProvider` は、以下の責務を持つ。

1. 現在のロケール（`ja` / `en` / `zh`）の保持
2. 各ロケールのメッセージ辞書のロード（静的 JSON または同等の静的リソース）
3. 翻訳関数 `t(key: string, params?: Record<string, unknown>): string` の提供
4. ロケール変更 API `setLocale(locale: Locale)` の提供

#### 3.2.1 辞書ロードの挙動

* 起動時およびロケール変更時に、対応する辞書ファイルをロードする。
* ロード失敗時：

  * UI: 最低限のフォールバック（キー文字列そのまま表示、または "(translation missing)"）
  * ログ: `ErrorLoggerService` 経由で ERROR ログを出力する。

```ts
// 擬似インタフェース
interface I18nLoadErrorContext {
  locale: string;
  resourcePath: string;
  status?: number;
  errorMessage?: string;
}
```

* ログイベント例：

  * `event`: `i18n.load_failed`
  * `level`: `ERROR`
  * `context`: `I18nLoadErrorContext`

#### 3.2.2 t() の missing key 挙動

`t()` に存在しないキーが渡された場合の挙動を以下の通り統一する。

* 返り値: 渡されたキー文字列をそのまま返す（例: `"common.unknown_key"`）
* ログ: `WARN` レベルで `i18n.missing_key` を 1 回出力する。

```ts
interface MissingKeyContext {
  key: string;
  locale: string;
}
```

* ログイベント例：

  * `event`: `i18n.missing_key`
  * `level`: `WARN`
  * `context`: `MissingKeyContext`

### 3.3 LanguageSwitch の責務

`LanguageSwitch` は UI コンポーネントとして、以下のみを責務とする。

* 現在ロケールの取得（`StaticI18nProvider` から）
* ロケール変更のトリガ（`setLocale()` 呼び出し）
* 選択状態の表示（ボタンの active 状態など）

`LanguageSwitch` 自身はログを出力しない。

* ロケール変更イベントのログが必要な場合は、`setLocale()` を呼び出す上位レイヤ（ページやレイアウト）で `ErrorLoggerService` を利用する。

---

## 4. ログ基盤設計（ErrorLoggerService）

### 4.1 logger.ts の役割

`logger.ts` は、環境に依存しない最小限のロガー API を提供する。

* 実装としては `console.debug / info / warn / error` を用い、
  Vercel / Supabase の標準ログ機構へ流す。
* 外部 SaaS（Sentry 等）への連携は行わない。

#### 4.1.1 ログレベル

* `DEBUG`
* `INFO`
* `WARN`
* `ERROR`

本番環境では `DEBUG` を出力しない方針とする（ビルド設定または logger 側で制御）。

#### 4.1.2 ログフォーマット

すべてのログは以下の JSON 形式で出力する。

```ts
interface LogPayload {
  timestamp: string; // ISO8601
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
  event: string; // 例: 'auth.login.failed'
  message?: string; // 人が読む説明（英語を推奨）
  context?: Record<string, unknown>; // 付加情報（PII 禁止）
}
```

### 4.2 PII ポリシー

ログには、以下の情報を含めない。

* メールアドレス、生年月日、氏名などの個人情報
* 住所、電話番号などの連絡先
* JWT やアクセストークンなどの秘密情報

認証関連のログでは、ユーザーを識別する必要がある場合、
アプリケーション内部で生成した匿名 ID（例: `tenantId` と `userInternalId` のみ）を使用する。

### 4.3 ErrorLoggerService のインタフェース

`ErrorLoggerService` は `logger.ts` のラッパとして以下の API を提供する想定とする。

```ts
type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

interface LogParams {
  level: LogLevel;
  event: string;
  message?: string;
  context?: Record<string, unknown>;
}

function log(params: LogParams): void;

// ショートカット
function info(event: string, context?: Record<string, unknown>): void;
function warn(event: string, context?: Record<string, unknown>): void;
function error(event: string, context?: Record<string, unknown>): void;
```

アプリケーションコードは基本的に `ErrorLoggerService` の API のみを使用し、
`console.*` を直接呼び出さない。

---

## 5. 共通エラー処理との連携

### 5.1 ErrorHandlerProvider（C-16）

`ErrorHandlerProvider` は、React コンポーネントツリーに対して以下を提供する。

* 非同期エラーのハンドリング関数

  * 例: `handleError(error: unknown, options?: HandleErrorOptions)`
* エラー種別に応じたログ出力（`ErrorLoggerService` 利用）
* ユーザー向けメッセージの発行（`ErrorToastDispatcher` 連携）

#### 5.1.1 ハンドリングポリシー

* Supabase / Corbado / fetch などのエラーは、原則として `ErrorHandlerProvider` を経由する。
* UI コンポーネント（フォーム・ボタンなど）は、

  * 例外を try/catch で捕捉したうえで `handleError()` に渡す
  * もしくはエラー発生関数を `ErrorHandlerProvider` 提供のラッパで包む
* `handleError()` は内部で：

  1. エラーを分類（認証系 / ネットワーク系 / 想定外エラー）
  2. `ErrorLoggerService` でログ出力
  3. ユーザー向けメッセージキーを決定
  4. `ErrorToastDispatcher` を通じてトースト表示

### 5.2 ErrorBoundary（C-18）

`ErrorBoundary` は React のレンダリング中に発生した予期せぬ例外を捕捉し、
以下の処理を行う。

* `ErrorLoggerService` に `ERROR` レベルで `ui.unhandled_error` を出力
* フォールバック UI を表示（システムエラー画面など）

Boundary は、アプリケーションルートと、必要に応じてログイン画面単位などに設置する。

### 5.3 ErrorToastDispatcher（C-19）

`ErrorToastDispatcher` は、エラーや通知を画面上のトーストとして表示する責務を持つ。

* 受け取るのは **i18n キー** と optional なパラメータ
* 表示文言は i18n レイヤが解決する（トースト側では生の文言を持たない）

```ts
interface ToastMessage {
  type: 'error' | 'warning' | 'info' | 'success';
  i18nKey: string; // 例: 'auth.login.failed'
  i18nParams?: Record<string, unknown>;
}
```

`ErrorHandlerProvider` は `ToastMessage` を生成して `ErrorToastDispatcher` に渡す。

---

## 6. 認証フローとの連携（MagicLink / Passkey）

### 6.1 ログイベント設計

MagicLink / Passkey 認証フローでは、最低限以下のイベントを共通で出力する。

* `auth.login.requested`

  * level: `INFO`
  * context: `{ method: 'magic_link' | 'passkey' }`
* `auth.login.success`

  * level: `INFO`
  * context: `{ method: 'magic_link' | 'passkey' }`
* `auth.login.failed`

  * level: `WARN` または `ERROR`（エラー種別による）
  * context: `{ method: 'magic_link' | 'passkey', reason?: string }`

### 6.2 ログを出力するレイヤ

* ログは原則として **サービスレイヤ or 認証専用 hooks**（例: `useMagicLinkAuth`, `usePasskeyAuth`）から出力する。
* UI コンポーネント（MagicLinkForm / PasskeyButton）は、エラーを `ErrorHandlerProvider` に渡すのみとし、
  `ErrorLoggerService` を直接呼び出さない。

### 6.3 UI との連携

* 認証失敗など、ユーザーに通知すべきエラーは `ErrorHandlerProvider` を経由し、
  `ToastMessage`（`auth.login.failed` など）として表示する。
* 文言は i18n 辞書の `auth.*` 名前空間に整理する。

---

## 7. テスト観点

### 7.1 i18n

* `t()` が存在しないキーに対してキー文字列を返すこと。
* missing key 発生時に `ErrorLoggerService.warn('i18n.missing_key', ...)` が一度だけ呼ばれること。
* 辞書ロード失敗時に `ErrorLoggerService.error('i18n.load_failed', ...)` が呼ばれ、
  UI はフォールバック表示となること。

### 7.2 ログ

* `ErrorLoggerService` 単体 UT で、各レベルのログが `logger.ts` に正しく委譲されること。
* 認証 hooks（MagicLink / Passkey）で、成功・失敗時に適切なログイベントが出力されること。

### 7.3 共通エラー処理

* `handleError()` に認証エラーを渡した際、

  * `auth.login.failed` のトーストが発行されること
  * ログイベント `auth.login.failed` が出力されること
* 想定外エラーの場合、`ui.unhandled_error` が `ErrorBoundary` によりログ出力されること。

UI コンポーネントの UT では、ログ呼び出しの有無そのものはテスト対象とせず、

* エラー時にトーストが表示される
* 正常系で適切な文言が表示される
  ことにフォーカスする。

---

## 8. メタ情報（Version / ChangeLog）

### 8.1 Version

* v1.0: 初版作成
* v1.1: i18n missing key / load error のログ仕様を追加し、
  ErrorHandlerProvider / ErrorLoggerService / 認証フローとの連携仕様を明文化

### 8.2 ChangeLog

* [v1.1]

  * ファイル名から `HarmoNet` プレフィックスを削除。
  * StaticI18nProvider の missing key 挙動とログ仕様を追記。
  * i18n 辞書ロード失敗時のログイベント `i18n.load_failed` を定義。
  * ErrorHandlerProvider / ErrorBoundary / ErrorToastDispatcher 間の責務分担を整理。
  * MagicLink / Passkey 認証フローにおけるログイベント設計（`auth.login.*`）を追加。
