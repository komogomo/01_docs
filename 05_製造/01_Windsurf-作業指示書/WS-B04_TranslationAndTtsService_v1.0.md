# WS-B04 TranslationAndTtsService サーバ実装指示書 v1.0

**Task ID:** WS-B04-TranslationAndTtsService-Server-Impl
**Version:** 1.0
**Target Repo:** `D:/Projects/HarmoNet`
**Executor:** Windsurf
**Status:** Ready

---

## 1. ゴール

B-04 BoardTranslationAndTtsService 詳細設計書（ch02〜ch07）に従い、

* 翻訳サービス（Google Cloud Translation v3）
* 掲示板投稿向け翻訳キャッシュサービス
* TTS サービス（Google Cloud Text-to-Speech）

の **サーバサイドサービスクラス** を実装する。

本タスクでは **Route Handler / UI / Edge Function** には触らず、あくまで
`src/server/services/translation/*` および `src/server/services/tts/*` の実装のみを対象とする。

---

## 2. スコープ

### 2.1 対象ファイル（新規作成）

以下のファイルを新規作成する。

* `src/server/services/translation/GoogleTranslationService.ts`
* `src/server/services/translation/BoardPostTranslationService.ts`
* `src/server/services/tts/GoogleTtsService.ts`
* `src/server/services/tts/BoardPostTtsService.ts`

### 2.2 非対象

* Next.js Route Handler（`app/api/.../route.ts`）の実装・修正
* B-02 / B-03 コンポーネントおよび UI ロジック
* Supabase Edge Function（翻訳キャッシュ削除バッチ）の実装
* Jest / Vitest テストコード（本タスクでは作成不要）

---

## 3. 前提・環境

### 3.1 ランタイム・依存

* Node.js / Next.js 16 (App Router)
* TypeScript
* Supabase クライアント（サーバサイド）
* Google Cloud クライアントライブラリ

  * `@google-cloud/translate`
  * `@google-cloud/text-to-speech`

### 3.2 環境変数（ローカル）

`.env.local` には、少なくとも以下が設定済みとする。

```env
GCP_PROJECT_ID=harmonet-19710403
GOOGLE_APPLICATION_CREDENTIALS=D:/Secrets/harmonet-19710403-63865f9b297a.json
```

* ローカルでは `GOOGLE_APPLICATION_CREDENTIALS` により JSON キーファイルを参照し、
  Google SDK のデフォルト認証を利用する。

### 3.3 環境変数（本番想定）

本タスクでは本番環境へのデプロイは行わないが、設計書に従い以下の前提で実装すること。

* 本番 Supabase Cloud / Vercel では、サービスアカウント JSON 本体を Secrets に格納し、
  `GCP_TRANSLATE_CREDENTIALS_JSON` として提供する。
* 実装コードは、`GCP_TRANSLATE_CREDENTIALS_JSON` が存在すればそれを `credentials` オプションに渡し、
  ない場合はローカル同様に `GOOGLE_APPLICATION_CREDENTIALS` によるデフォルト認証を利用する。

---

## 4. 実装仕様（翻訳サービス）

### 4.1 `GoogleTranslationService`

**ファイル:** `src/server/services/translation/GoogleTranslationService.ts`

#### 4.1.1 型・インターフェース

```ts
export type SupportedLang = 'ja' | 'en' | 'zh';

export interface TranslateParams {
  tenantId: string;
  sourceLang: SupportedLang;
  targetLang: SupportedLang;
  text: string;
}

export interface TranslateResult {
  text: string;
}

export interface TranslationService {
  translateOnce(params: TranslateParams): Promise<TranslateResult>;
}
```

#### 4.1.2 クラス定義

```ts
export class GoogleTranslationService implements TranslationService {
  // コンストラクタで GCP_PROJECT_ID と認証情報を解決する
}
```

要件:

* コンストラクタで `GCP_PROJECT_ID` を取得し、存在しない場合は `Error` を投げる。
* `process.env.GCP_TRANSLATE_CREDENTIALS_JSON` が存在する場合:

  * `JSON.parse` でオブジェクト化し、`new TranslationServiceClient({ projectId, credentials })` に渡す。
* 存在しない場合:

  * `new TranslationServiceClient()` を呼び出し、`GOOGLE_APPLICATION_CREDENTIALS` によるデフォルト認証を利用する。
* `translateOnce` は `translateText` を 1 回だけ呼び出し、

  * `parent = projects/{projectId}/locations/global`
  * `contents = [text]`
  * `mimeType = 'text/plain'`（HTML対応は本タスク外）
  * `sourceLanguageCode = sourceLang`
  * `targetLanguageCode = targetLang`
    で翻訳を行う。
* 正常時:

  * `translations[0].translatedText` を `TranslateResult.text` として返す。
  * 共通 Logger（`logger.info` 仮定）で `board.translation.success` を出力する（設計書 ch07 を参考に最低限の項目を出力）。
* 異常時:

  * 例外をそのまま投げ直す。
  * `logger.error('board.translation.error', ...)` を呼び出し、tenantId / sourceLang / targetLang / errorMessage / durationMs を記録する。

### 4.2 `BoardPostTranslationService`

**ファイル:** `src/server/services/translation/BoardPostTranslationService.ts`

#### 4.2.1 型

```ts
import type { SupabaseClient } from '@supabase/supabase-js';
import type { TranslationService, SupportedLang, TranslateParams } from './GoogleTranslationService';

export interface BoardPostTranslationServiceDeps {
  supabase: SupabaseClient;
  translationService: TranslationService;
}
```

#### 4.2.2 クラス定義

```ts
export class BoardPostTranslationService {
  constructor(deps: BoardPostTranslationServiceDeps) { /* ... */ }

  hasCachedTranslation(params: {
    tenantId: string;
    postId: string;
    lang: SupportedLang;
  }): Promise<boolean>;

  translateAndCacheForPost(params: {
    tenantId: string;
    postId: string;
    sourceLang: SupportedLang;
    targetLangs: SupportedLang[];
    originalTitle?: string;
    originalBody: string;
  }): Promise<void>;
}
```

要件:

* `hasCachedTranslation`:

  * Supabase クライアントを用いて `board_post_translations` テーブルを問い合わせる。
  * 条件: `tenant_id = tenantId` /
    `post_id = postId` /
    `lang = lang`。
  * 1件でも存在すれば `true`、なければ `false` を返す。

* `translateAndCacheForPost`:

  * `targetLangs` をループし、`sourceLang` と同一の言語はスキップする。
  * 各ターゲット言語ごとに `translationService.translateOnce` を呼び出し、結果を `board_post_translations` に `upsert` する。

    * 挿入値:

      * `tenant_id`
      * `post_id`
      * `lang`
      * `title`（`originalTitle ?? null`）
      * `content`（翻訳結果）
    * `onConflict: 'post_id,lang'` 前提で実装してよい。
  * 単一言語での翻訳 or upsert が失敗した場合:

    * 当該言語はスキップし、他の言語処理は継続する。
    * 例外は伝播させず握りつぶす（ログは `translationService` 側で出ている前提）。

---

## 5. 実装仕様（TTS サービス）

### 5.1 `GoogleTtsService`

**ファイル:** `src/server/services/tts/GoogleTtsService.ts`

#### 5.1.1 型・インターフェース

```ts
import type { SupportedLang } from '../translation/GoogleTranslationService';

export interface TtsParams {
  tenantId: string;
  lang: SupportedLang;
  text: string;
}

export interface TtsResult {
  audioBuffer: ArrayBuffer;
  mimeType: string; // 例: 'audio/mpeg'
}

export interface TtsService {
  synthesize(params: TtsParams): Promise<TtsResult>;
}
```

#### 5.1.2 クラス定義

```ts
import textToSpeech from '@google-cloud/text-to-speech';

export class GoogleTtsService implements TtsService {
  // コンストラクタで Translation と同様に projectId / credentials を解決
}
```

要件:

* 認証処理は `GoogleTranslationService` と同じパターン（`GCP_TRANSLATE_CREDENTIALS_JSON` 優先 / フォールバックで `GOOGLE_APPLICATION_CREDENTIALS`）。
* `synthesize`:

  * `mapLangToGoogleCode(lang)` で Google の言語コードに変換する。

    * `'ja' -> 'ja-JP'`
    * `'en' -> 'en-US'`
    * `'zh' -> 'cmn-CN'`（簡体中国語前提）
  * `text:synthesize` を呼び出し、`audioEncoding = 'MP3'` で音声を生成する。
  * `audioContent` が空の場合は `Error` を投げる。
  * 正常時:

    * `audioBuffer` に `audioContent` を `ArrayBuffer` として格納し、`mimeType = 'audio/mpeg'` で返す。
    * `logger.info('board.tts.success', { tenantId, lang, durationMs, audioSizeBytes })` を出力する。
  * 異常時:

    * 例外を投げ直す。
    * `logger.error('board.tts.error', { tenantId, lang, errorMessage, durationMs })` を出力する。

### 5.2 `BoardPostTtsService`

**ファイル:** `src/server/services/tts/BoardPostTtsService.ts`

#### 5.2.1 型・クラス

```ts
import type { TtsService, TtsResult } from './GoogleTtsService';
import type { SupportedLang } from '../translation/GoogleTranslationService';

export interface BoardPostTtsServiceDeps {
  ttsService: TtsService;
}

export class BoardPostTtsService {
  constructor(deps: BoardPostTtsServiceDeps) { /* ... */ }

  synthesizePostBody(params: {
    tenantId: string;
    postId: string;
    lang: SupportedLang;
    text: string; // 実際に読み上げる文字列（B-02 側から渡される）
  }): Promise<TtsResult>;
}
```

要件:

* `synthesizePostBody` は単純なラッパーで良い。

  * `ttsService.synthesize({ tenantId, lang, text })` を呼び出す。
  * `postId` はログには不要だが、将来拡張を見越してパラメータとして受け取る（必要ならログに含められるようにしておく）。

---

## 6. 実装上の注意・禁止事項

* **設計変更禁止**: B-04 詳細設計書（ch02〜ch07）で定義されたインターフェースや責務を変更しないこと。
* **スコープ外変更禁止**:

  * 既存の Route Handler / UI コンポーネント / Edge Function のコードは変更しない。
  * DB スキーマ（`schema.prisma` や SQL）はこのタスクでは変更しない。
* **ログ出力**:

  * 本タスクでは最低限の `logger.info` / `logger.error` 呼び出しのみ実装し、メッセージフォーマットはシンプルで良い。
  * 投稿本文や翻訳結果の全文はログに含めない（設計書 ch06/ch07 に従う）。

---

## 7. 完了条件
* D:/Projects/HarmoNet/
* `src/server/services/translation/GoogleTranslationService.ts` がコンパイルエラーなくビルド可能であること。
* `src/server/services/translation/BoardPostTranslationService.ts` が Supabase 型エラーなくビルド可能であること。
* `src/server/services/tts/GoogleTtsService.ts` / `BoardPostTtsService.ts` がビルド可能であること。
* 既存の `npm run build` / `npm run lint` がエラーなく通ること（他ファイルの警告は既存と同水準であれば可）。
* 新規追加ファイルに any 乱用など致命的なコード品質低下がないこと（型が難しい部分は `as any` を最小限に留める）。

以上を満たした時点で、本WSタスクは完了とみなす。
