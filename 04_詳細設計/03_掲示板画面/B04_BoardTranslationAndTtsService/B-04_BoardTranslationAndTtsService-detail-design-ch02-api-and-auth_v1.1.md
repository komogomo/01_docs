# B-04 BoardTranslationAndTtsService 詳細設計書 ch02 API・認証設計 v1.2

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH02
**Version:** 1.2
**Supersedes:** v1.1
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 2.1 本章の目的

本章では、掲示板専用 翻訳＋音声読み上げサービス **B-04 BoardTranslationAndTtsService** の

* サービスインターフェース（アプリ内部 API）
* 外部サービス（Google Cloud Translation / TTS）への接続方式
* 認証・環境変数・パラメータシートとの対応

を定義する。Windsurf は本章をもとに以下を実装することを想定する。

* Node.js（Next.js / Supabase Edge Function）上のサービスクラス実装
* Google Cloud API クライアントの生成
* Route Handler / Edge Function からの翻訳・TTS 呼び出し

---

## 2.2 内部サービス API 設計

### 2.2.1 言語コード定義

掲示板の翻訳・TTS で扱う言語は、HarmoNet 全体の UI 言語と同一とする。

```ts
export type SupportedLang = 'ja' | 'en' | 'zh';
```

* `ja` : 日本語（既定言語）
* `en` : 英語
* `zh` : 中国語（簡体／繁体の扱いは別途 i18n 方針に従う）

### 2.2.2 翻訳サービスインターフェース

#### (1) 単発翻訳 API（低レベル）

```ts
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
  /**
   * Google Cloud Translation API を利用してテキストを 1 対 1 で翻訳する低レベル API。
   * キャッシュ保存は行わず、呼び出し元の責務とする。
   */
  translateOnce(params: TranslateParams): Promise<TranslateResult>;
}
```

* 実装クラス（例: `GoogleTranslationService`）は、本章 2.3 の認証・エンドポイント仕様に従って Google Translation API v3 を呼び出す。
* 本インターフェースは B-04 内部でのみ利用し、画面から直接参照させない。

#### (2) 掲示板投稿向け翻訳 API（高レベル）

```ts
export interface BoardPostTranslationService {
  /**
   * 掲示板投稿の本文（必要に応じてタイトル）を、指定されたターゲット言語群に翻訳し、
   * board_post_translations テーブルに保存する高レベル API。
   *
   * - 投稿時: B-03 BoardPostForm から原文保存後に呼び出される。
   * - 詳細画面: B-02 BoardDetail から、特定言語のキャッシュがない場合のみ呼び出される。
   */
  translateAndCacheForPost(options: {
    tenantId: string;
    postId: string;
    sourceLang: SupportedLang;
    targetLangs: SupportedLang[]; // 例: ['en', 'zh']
    originalTitle?: string;
    originalBody: string;
  }): Promise<void>;

  /**
   * 特定投稿・特定言語について、キャッシュの有無を確認するヘルパー。
   * B-02 BoardDetail が翻訳アイコン押下時に利用する想定。
   */
  hasCachedTranslation(params: {
    tenantId: string;
    postId: string;
    lang: SupportedLang;
  }): Promise<boolean>;
}
```

* `translateAndCacheForPost` は内部で `TranslationService.translateOnce` を複数回呼び出し、
  結果を `board_post_translations` テーブルに `INSERT` / `UPSERT` する。
* B-02 / B-03 からは `BoardPostTranslationService` のみ参照し、Google の詳細仕様には依存しない。

### 2.2.3 TTS サービスインターフェース

#### (1) 低レベル TTS API

```ts
export interface TtsParams {
  tenantId: string;
  lang: SupportedLang;
  text: string;
}

export interface TtsResult {
  /** 音声バイナリ（例: MP3 / Ogg / WAV）のバイト配列 */
  audioBuffer: ArrayBuffer;
  /** ブラウザで再生する際に利用する MIME タイプ（例: 'audio/mpeg'） */
  mimeType: string;
}

export interface TtsService {
  /**
   * 外部 TTS API を利用してテキストを音声に変換する低レベル API。
   * キャッシュ保存やストレージ連携は行わない（本書のスコープ外）。
   */
  synthesize(params: TtsParams): Promise<TtsResult>;
}
```

#### (2) 掲示板投稿向け TTS API

```ts
export interface BoardPostTtsService {
  /**
   * 掲示板詳細画面からの音声読み上げ要求を処理する高レベル API。
   *
   * - B-02 BoardDetail から、投稿本文・言語指定を受け取る。
   * - TtsService.synthesize を呼び出し、レスポンスをそのままクライアントへ返すか、
   *   必要に応じて一時ストレージへ保存してから URL を返す。（詳細は ch04 で定義）
   */
  synthesizePostBody(options: {
    tenantId: string;
    postId: string;
    lang: SupportedLang;
    text: string;
  }): Promise<TtsResult>;
}
```

* 本バージョンでは TTS の結果はキャッシュせず、その都度 API を呼び出す前提とする。
* 将来的にキャッシュが必要になった場合は、ch04 / ch05 にて TTS キャッシュテーブルを追加設計する。

---

## 2.3 Google Cloud Translation API 連携

本節では、`TranslationService` 実装が従うべき Google Cloud Translation API v3 の利用方法を定義する。

### 2.3.1 認証方式

* 認証方式: **サービスアカウントによる OAuth2（JWT）認証** を利用する。
* HarmoNet では、Google Cloud 公式 Node.js SDK（`@google-cloud/translate`）を採用し、REST 直叩きは想定しない。

#### 環境別の取り扱い

* 開発環境（ローカル Supabase コンテナ / Next.js 開発サーバ）:

  * サービスアカウントの JSON キーファイルをローカルに配置し、
    環境変数 `GOOGLE_APPLICATION_CREDENTIALS` にファイルパスを設定する。
  * Google SDK のデフォルト認証機構により、ファイルから認証情報を取得する。

* 本番環境（Supabase Cloud Pro / Vercel 等）:

  * サービスアカウント JSON の **中身** を Supabase / Vercel の Secrets に格納し、
    環境変数 `GCP_TRANSLATE_CREDENTIALS_JSON` として提供する。
  * アプリケーションコードでは `process.env.GCP_TRANSLATE_CREDENTIALS_JSON` を `JSON.parse` し、
    SDK の `credentials` オプションに渡す（ファイルパス方式は使用しない）。

#### 環境変数

Google Cloud クライアントの認証情報は、以下の環境変数を通じて与える。

| 論理名               | 環境変数名                                                               | 説明                                  |
| ----------------- | ------------------------------------------------------------------- | ----------------------------------- |
| GCP プロジェクト ID     | `GCP_PROJECT_ID`                                                    | Translation / TTS 共通のプロジェクト ID      |
| 翻訳用サービスアカウント JSON | `GOOGLE_APPLICATION_CREDENTIALS` / `GCP_TRANSLATE_CREDENTIALS_JSON` | ローカル: JSON キーファイルへのパス / 本番: JSON 本体 |

パラメータシートには、少なくとも以下を記載する。

* GCP プロジェクト ID
* Translation/TTS 用サービスアカウントのメールアドレス
* サービスアカウントキーファイルの保管場所（ローカル）
* 本番環境での Secrets 名（例: `GCP_TRANSLATE_CREDENTIALS_JSON`）

#### クライアント生成方針

```ts
import { TranslationServiceClient } from '@google-cloud/translate';

export class GoogleTranslationService implements TranslationService {
  private client: TranslationServiceClient;

  constructor() {
    const credentialsJson = process.env.GCP_TRANSLATE_CREDENTIALS_JSON;

    this.client = credentialsJson
      ? new TranslationServiceClient({
          projectId: process.env.GCP_PROJECT_ID,
          credentials: JSON.parse(credentialsJson),
        })
      : new TranslationServiceClient(); // ローカル開発では GOOGLE_APPLICATION_CREDENTIALS によるデフォルト認証を利用
  }

  async translateOnce(params: TranslateParams): Promise<TranslateResult> {
    // 実装詳細は Windsurf 実装タスクで具体化する
  }
}
```

### 2.3.2 エンドポイント・リクエスト仕様

* API: Google Cloud Translation API v3 `translateText`
* HTTP メソッド: `POST`
* ベースパス: `projects/{PROJECT_ID}/locations/{LOCATION}`

  * LOCATION は `global` を既定とする（必要に応じて `asia-northeast1` 等へ変更可能）

SDK 利用時のパラメータ例（論理レベル）:

```ts
const request = {
  parent: `projects/${projectId}/locations/${location}`,
  contents: [params.text],
  mimeType: 'text/plain', // または 'text/html'（本文の保存形式に合わせて決定）
  sourceLanguageCode: params.sourceLang,
  targetLanguageCode: params.targetLang,
};
```

* `mimeType` は本文の保存形式に合わせて決定する。

  * B-03 で HTML を保存する場合は `text/html` を指定する。
  * 本書では単純なテキストを既定として `text/plain` を用い、最終決定は B-03 と整合させる。
* レスポンス `translations[0].translatedText` を `TranslateResult.text` として返す。

### 2.3.3 エラー処理方針（翻訳）

* 翻訳 API 呼び出しが失敗した場合、`TranslationService.translateOnce` は例外を投げる。
* `BoardPostTranslationService.translateAndCacheForPost` では、少なくとも以下を実装する想定とする。

  * 単一ターゲット言語での失敗時には、その言語のみスキップし、他言語は継続するかどうかを選択可能な設計とする。
  * 翻訳失敗自体は投稿処理のロールバック条件とはしない（投稿自体は成功させる）。
* エラー内容は共通 Logger を通じて Supabase / Logflare に出力する（詳細はログ設計書参照）。

---

## 2.4 TTS API 連携

TTS についても、翻訳と同様に Google Cloud を候補とした構成を定義する。

### 2.4.1 認証方式

* 認証方式: 翻訳 API と同じサービスアカウントを利用する。
* 環境変数: 翻訳 API と同一の `GCP_PROJECT_ID` / `GOOGLE_APPLICATION_CREDENTIALS` / `GCP_TRANSLATE_CREDENTIALS_JSON` を利用する。
* サービスアカウントの権限には、Cloud Text-to-Speech API の利用権限を付与する。

### 2.4.2 エンドポイント・パラメータ（論理）

* API: Google Cloud Text-to-Speech API `text:synthesize`
* HTTP メソッド: `POST`

論理的なリクエスト構造（SDK または REST クライアント）:

```ts
const request = {
  input: { text: params.text },
  voice: {
    languageCode: mapLangToGoogleCode(params.lang), // 例: 'ja-JP', 'en-US', 'cmn-CN'
    ssmlGender: 'NEUTRAL',
  },
  audioConfig: {
    audioEncoding: 'MP3', // 'OGG_OPUS' なども可
  },
};
```

* `mapLangToGoogleCode` は、`SupportedLang` から Google の言語コードへのマッピング関数。
* `audioEncoding` は、ブラウザ再生の容易さを優先して `MP3` を既定とする。

### 2.4.3 TTS 結果の扱い

* 本バージョンでは、TTS 結果はキャッシュせず、その都度 TTS API に問い合わせて音声を生成する。
* `TtsService.synthesize` は以下の責務を持つ。

  * TTS API から base64 / バイナリ形式で音声を取得する。
  * `ArrayBuffer` に変換し、`mimeType` とともに `TtsResult` として返す。
* `BoardPostTtsService.synthesizePostBody` は、B-02 BoardDetail からの要求に応じて `TtsService.synthesize` を呼び出し、Route Handler や Edge Function 経由でブラウザに音声バイナリを返す（詳細は ch04）。

### 2.4.4 エラー処理方針（TTS）

* TTS API 呼び出しが失敗した場合、`TtsService.synthesize` は例外を投げる。
* `BoardPostTtsService.synthesizePostBody` では、B-02 側に返すエラーレスポンスを次のように定義する（詳細は B-02 / ch04 で文言を確定）。

  * HTTP ステータス: 5xx（または 4xx + アプリ固有コード）
  * UI 表示メッセージ例: 「音声読み上げに失敗しました。しばらくしてから再度お試しください。」
* エラーは共通 Logger を通じて記録し、翻訳 API 同様に Logflare / Supabase に送信する。

---

## 2.5 B-02 / B-03 からの利用契約（サマリ）

本章で定義したインターフェースを、B-02 / B-03 からどのように利用するかを整理する。

### 2.5.1 B-03 BoardPostForm（投稿時翻訳）

* 原文投稿保存後に以下を呼び出す。

```ts
await boardPostTranslationService.translateAndCacheForPost({
  tenantId,
  postId,
  sourceLang: 'ja', // 投稿時点での原文言語（LanguageSwitch 状態に依存しない）
  targetLangs: ['en', 'zh'],
  originalTitle: title,
  originalBody: body,
});
```

* 翻訳失敗時も投稿自体は成功とし、翻訳キャッシュ無しの状態で BoardDetail に遷移する。

### 2.5.2 B-02 BoardDetail（オンデマンド翻訳）

* 詳細画面表示時、選択中の言語に対するキャッシュの有無を確認する。
* 投稿本文下部の翻訳アイコン押下時、キャッシュが無い場合のみ以下を呼び出す。

```ts
if (!(await boardPostTranslationService.hasCachedTranslation({ tenantId, postId, lang }))) {
  await boardPostTranslationService.translateAndCacheForPost({
    tenantId,
    postId,
    sourceLang: 'ja', // 原文言語（保存時に決まる）
    targetLangs: [lang],
    originalBody: originalBody,
  });
}
```

* 翻訳結果は `board_post_translations` から取得し、B-02 側の表示ロジックで利用する（取得ロジックは ch03 で定義）。

### 2.5.3 B-02 BoardDetail（音声読み上げ）

* 投稿本文の音声読み上げボタン押下時に以下を呼び出す。

```ts
const audio = await boardPostTtsService.synthesizePostBody({
  tenantId,
  postId,
  lang,
  text: bodyTextForReading, // 実際に読み上げる文字列
});
```

* ルートハンドラまたは Edge Function からブラウザへ `audioBuffer` と `mimeType` を返し、クライアント側で `Blob` / `Audio` 要素等を用いて再生する（詳細は ch04 / B-02 で定義）。

---

本章では、B-04 BoardTranslationAndTtsService の内部 API と、Google Cloud Translation / TTS との認証・エンドポイント仕様を定義した。

認証方式として、

* ローカル環境では `GOOGLE_APPLICATION_CREDENTIALS` によるファイルパス方式
* 本番 Supabase Cloud や Vercel では Secrets に格納した JSON を `GCP_TRANSLATE_CREDENTIALS_JSON` 経由で渡す方式

を採用する。

次章 ch03 では、翻訳キャッシュテーブル `board_post_translations` / `board_comment_translations` のスキーマ、および翻訳キャッシュ保有期間の管理方法（tenant_settings との連携、Edge Function バッチ）を詳細に定義する。
