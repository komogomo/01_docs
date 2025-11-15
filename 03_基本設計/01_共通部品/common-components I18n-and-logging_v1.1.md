# 共通部品 基本設計書：i18n & ログ連携

Version: v1.1
Status: Draft（ログ共通ユーティリティ v1.1 反映版）
Author: Tachikoma (ChatGPT)
LastUpdated: 2025-11-15

---

## 1. 本書の目的

本書は、HarmoNet 全体で共通利用する以下の技術要素について、責務分担と連携仕様を定義する。

* i18n（多言語対応）
* ログ出力（フロントエンドの共通ログ）
* 共通エラー処理（ErrorHandler / Toast / Boundary）

ログイン画面（A-00 LoginPage / A-01 MagicLinkForm / A-02 PasskeyAuthTrigger）を含む全画面が、
個別実装ではなく共通部品を経由して統一的な挙動を取ることを目的とする。

本書は、以下の詳細設計書と整合することを前提とする：

* `harmonet-log-design_v1.1.md`（ログ基本設計）
* `harmonet-log-detail-design_v1.1.md`（フロントエンド共通ログユーティリティ詳細設計）
* `A-00_LoginPage-detail-design_v1.1.md`（LoginPage 詳細設計）

---

## 2. 対象スコープと関連コンポーネント

### 2.1 対象コンポーネント

本書で対象とする共通部品は、機能コンポーネント一覧のうち以下とする。

* C-02: LanguageSwitch
* C-03: StaticI18nProvider
* C-16: ErrorHandlerProvider
* C-17: ErrorLoggerService（実体はフロントエンド共通ログユーティリティ）
* C-18: ErrorBoundary
* C-19: ErrorToastDispatcher
* C-20: AccessibilityConfig（メッセージ表示のアクセシビリティ連携のみ）

### 2.2 非対象（参考）

* 監視・アラートサービス

  * 要件定義書の方針どおり、現時点では具体的なサービス採用や連携方式は決定しない。本書では扱わない。
* 監査ログ（ビジネスイベントとしての操作履歴）

  * 将来の仕様検討対象とし、本書では扱わない。

---

## 3. i18n 基本設計

### 3.1 全体方針

* 文言はすべて i18n 辞書で管理し、画面コードにハードコードしない。
* i18n キーは UI メッセージ専用とし、ログ用 event 名（`auth.login.*` など）とは分離する。
* i18n レイヤのエラー（辞書ロード失敗・キー不足）は、共通ログ（C-17）と UI フォールバックを組み合わせて処理する。

### 3.2 StaticI18nProvider の責務（C-03）

`StaticI18nProvider` は、以下の責務を持つ。

1. 現在のロケール（`ja` / `en` / `zh`）の保持
2. 各ロケールのメッセージ辞書のロード（静的 JSON または同等の静的リソース）
3. 翻訳関数 `t(key: string, params?: Record<string, unknown>): string` の提供
4. ロケール変更 API `setLocale(locale: Locale)` の提供

#### 3.2.1 辞書ロードの挙動

* 起動時およびロケール変更時に、対応する辞書ファイルをロードする。
* ロード失敗時：

  * UI: 最低限のフォールバック（キー文字列そのまま表示、または "(translation missing)"）
  * ログ: C-17 経由で ERROR ログを出力する。

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

### 3.3 LanguageSwitch の責務（C-02）

`LanguageSwitch` は UI コンポーネントとして、以下のみを責務とする。

* 現在ロケールの取得（`StaticI18nProvider` から）
* ロケール変更のトリガ（`setLocale()` 呼び出し）
* 選択状態の表示（ボタンの active 状態など）

`LanguageSwitch` 自身はログを出力しない。ロケール変更イベントのログが必要な場合は、
`setLocale()` を呼び出す上位レイヤ（ページやレイアウト）で C-17 を利用する。

---

## 4. ログ基盤設計（C-17 共通ログユーティリティ）

### 4.1 役割

C-17 は、フロントエンド共通ログユーティリティとして以下を提供する。

* ログレベル（`DEBUG` / `INFO` / `WARN` / `ERROR`）と JSON ペイロードの統一
* `logDebug` / `logInfo` / `logWarn` / `logError` の 4 関数によるログ出力
* メールアドレスなどの簡易マスキング（PII 抑止）

実装は `src/lib/logging/log.types.ts` / `log.config.ts` / `log.util.ts` に分割され、
画面側は `log.util.ts` が公開する API のみを利用する。

### 4.2 公開 API

```ts
// log.util.ts
export const logDebug: (event: string, context?: Record<string, unknown>) => void;
export const logInfo:  (event: string, context?: Record<string, unknown>) => void;
export const logWarn:  (event: string, context?: Record<string, unknown>) => void;
export const logError: (event: string, context?: Record<string, unknown>) => void;
```

* `event`: `auth.login.start` のようなイベント名（命名規約はログ詳細設計に従う）
* `context`: 任意の付加情報（マスキング対象を含む場合はユーティリティ側で処理）

### 4.3 出力先とログフォーマット

* 出力先はブラウザコンソール（`console.log/info/warn/error`）のみとする。
* すべてのログは以下の JSON 形式にシリアライズされてから出力される。

```ts
interface LogPayload {
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
  timestamp: string; // ISO8601
  event: string;     // 例: 'auth.login.success.magiclink'
  message?: string;
  screen?: string;
  context?: Record<string, unknown>;
}
```

### 4.4 PII ポリシー

* context 内に含まれるメールアドレスらしき文字列（`@` を含む）は、
  ログ出力前に `[masked-email]` へ置換する。
* 氏名・住所等の情報は、そもそも context に渡さないことを基本とする。

### 4.5 ログレベル方針

* `DEBUG`: 開発時の詳細ログ。本番では設定に応じて抑制可能。
* `INFO`: 正常系イベント（ログイン開始・成功など）。
* `WARN`: 注意喚起レベル（i18n missing key など）。
* `ERROR`: 画面の利用に影響するエラー（認証失敗・通信エラーなど）。

`levelThreshold` 設定により、環境ごとに出力レベルを調整するが、
コードパスは環境によらず `logXXX → emit → console.*` で共通とする。

---

## 5. 共通エラー処理との連携

### 5.1 ErrorHandlerProvider（C-16）

`ErrorHandlerProvider` は、React コンポーネントツリーに対して以下を提供する。

* 非同期エラーのハンドリング関数

  * 例: `handleError(error: unknown, options?: HandleErrorOptions)`
* エラー種別に応じたログ出力（C-17 利用）
* ユーザー向けメッセージの発行（`ErrorToastDispatcher` 連携）

#### 5.1.1 ハンドリングポリシー

* Supabase / Corbado / fetch などのエラーは、原則として `ErrorHandlerProvider` を経由する。
* UI コンポーネント（フォーム・ボタンなど）は、

  * 例外を try/catch で捕捉したうえで `handleError()` に渡す、または
  * エラー発生関数を `ErrorHandlerProvider` 提供のラッパで包む。
* `handleError()` は内部で：

  1. エラーを分類（認証系 / ネットワーク系 / 想定外エラー）
  2. C-17 を用いてログ出力（`logError('auth.login.fail.*', context)` など）
  3. ユーザー向けメッセージキーを決定
  4. `ErrorToastDispatcher` を通じてトースト表示

### 5.2 ErrorBoundary（C-18）

`ErrorBoundary` は React のレンダリング中に発生した予期せぬ例外を捕捉し、以下の処理を行う。

* C-17 を用いて `ERROR` レベルで `ui.unhandled_error` を出力
* フォールバック UI を表示（システムエラー画面など）

Boundary は、アプリケーションルートと、必要に応じてログイン画面単位などに設置する。

### 5.3 ErrorToastDispatcher（C-19）

`ErrorToastDispatcher` は、エラーや通知を画面上のトーストとして表示する責務を持つ。

* 受け取るのは **i18n キー** とオプションのパラメータ
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

### 6.1 ログイベント設計（概要）

MagicLink / Passkey 認証フローでは、LoginPage 詳細設計に従い、
最低限以下のイベントを共通で出力する。

* `auth.login.start`

  * level: `INFO`
  * context: `{ method: 'magiclink' | 'passkey', screen: 'LoginPage' }`
* `auth.login.success.magiclink`

  * level: `INFO`
  * context: `{ method: 'magiclink', screen: 'LoginPage' }`
* `auth.login.success.passkey`

  * level: `INFO`
  * context: `{ method: 'passkey', screen: 'LoginPage' }`
* `auth.login.fail.*`

  * level: `ERROR`
  * context: `{ method: 'magiclink' | 'passkey', reason?: string, screen: 'LoginPage' }`

詳細な分類（`auth.login.fail.supabase.network` など）は、
LoginPage / MagicLinkForm / PasskeyAuthTrigger の詳細設計書に従う。

### 6.2 ログを出力するレイヤ

* ログは原則として A-01 / A-02（フォーム・認証用ロジック）から C-17 を用いて出力する。
* UI コンポーネントは、ログ出力とユーザー向けメッセージ表示の双方において、
  LoginPage 詳細設計の表に従った event / i18n キーを使用する。

### 6.3 UI との連携

* 認証失敗など、ユーザーに通知すべきエラーは `ErrorHandlerProvider` を経由し、
  `ToastMessage`（`auth.login.error.*` 系）として表示する。
* 文言は i18n 辞書の `auth.*` 名前空間で管理し、ログ event 名とは分離する。

---

## 7. テスト観点

### 7.1 i18n

* `t()` が存在しないキーに対してキー文字列を返すこと。
* missing key 発生時に、C-17 の `logWarn('i18n.missing_key', ...)` が一度だけ呼ばれること。
* 辞書ロード失敗時に、`logError('i18n.load_failed', ...)` が呼ばれ、
  UI はフォールバック表示となること。

### 7.2 ログ

* C-17 単体 UT で、各レベルのログが JSON 形式で `console.*` に出力されること。
* MagicLink / Passkey 認証処理で、成功・失敗時に LoginPage 詳細設計で定義された
  `auth.login.*` 系イベントが `logInfo` / `logError` で出力されること。

### 7.3 共通エラー処理

* `handleError()` に認証エラーを渡した際、

  * 適切な `auth.login.error.*` のトーストが発行されること
  * 対応する `auth.login.fail.*` ログ event が出力されること
* 想定外エラーの場合、`ui.unhandled_error` が ErrorBoundary によりログ出力されること。

UI コンポーネントの UT では、主に以下を確認する：

* エラー時に適切なトースト／エラーメッセージが表示されること
* 正常系で期待どおりの文言が表示されること

ログ呼び出しの有無そのものは、サービス／ロジック層のテスト（C-17 および認証ロジック）で担保する。

---

## 8. メタ情報（Version / ChangeLog）

### 8.1 Version

* v1.0: 初版作成
* v1.1: i18n missing key / load error のログ仕様を追加し、ErrorHandlerProvider / ErrorBoundary / ErrorToastDispatcher 間の責務分担を整理。MagicLink / Passkey 認証フローにおける `auth.login.*` ベースのログイベント設計を追加。

### 8.2 ChangeLog

* [v1.1 再構成版]

  * ログ基盤を「フロントエンド共通ログユーティリティ（logDebug/logInfo/logWarn/logError）」に統一。
  * 出力先をブラウザコンソールのみとし、外部サービス名を含む記述を削除。
  * C-17 の役割を、共通ログユーティリティとして再定義。
  * LoginPage / MagicLink / Passkey の `auth.login.*` イベント設計と整合するようにログ関連記述を整理。
