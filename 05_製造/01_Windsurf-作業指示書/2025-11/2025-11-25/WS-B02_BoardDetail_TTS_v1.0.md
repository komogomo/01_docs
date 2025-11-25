# WS-B02 BoardDetail 音声読上げ実装指示書_v1.0

## 1. ゴール

* 掲示板詳細画面 BoardDetail に「投稿本文の音声読上げ」機能を追加する。
* 対象は **掲示板詳細画面のみ** とし、BoardTop や他画面には読上げは実装しない。
* 音声合成のモデル／ボイスは、将来的に **テナント管理画面から変更可能** な構造にしておく。

  * 現時点ではデフォルト設定（1パターン）のみ利用し、DB からの動的変更は実装しなくてよい。

## 2. スコープ

### 2.1 フロントエンド

* 対象コンポーネント（想定）

  * `src/components/board/BoardDetail/BoardDetail.tsx`
  * または掲示板詳細本文＋アクションボタンを持つコンポーネント
* 実装内容

  * 既に配置済みの「読上げ」ボタン（スピーカーアイコン）にクリックハンドラを実装する。
  * ボタン押下で、現在表示中の投稿本文をサーバ API に送信し、返却された音声を再生する。
  * 再生中はボタン状態を変化させる（例: 無効化 or トグル表示）。

### 2.2 バックエンド

* 対象 API ルート（新規）

  * `POST /api/board/tts` （仮）
* 実装内容

  * リクエストボディとして投稿本文テキストとメタ情報（言語・テナントIDなど）を受け取る。
  * `tenant_id` に応じて TTS 設定を解決するヘルパーを呼び出す。
  * 選択された TTS エンジンを使って音声データを生成し、`audio/mpeg` 等でストリームレスポンスとして返す。

### 2.3 設定・共通処理

* 対象モジュール（新規）

  * `src/lib/ttsSettings.ts` （仮）
* 実装内容

  * テナントごとの TTS 設定（エンジン名／モデル名／ボイスなど）を一元管理する。
  * 現時点では DB からは読まず、**デフォルト値を返す純関数**として実装する。
  * 将来、テナント管理画面で編集した値を `tenant_settings` 等から取得できるように拡張する前提で構造を作る。

## 3. 仕様リファレンス

* 参照設計書

  * B-02 BoardDetail 詳細設計 chxx 本文／アクションボタン仕様（既存）
  * 非機能要件・技術スタックにおける TTS 採用方針（Google Cloud Text-to-Speech 等）
* 本WSでは、**既存で採用済みの TTS サービスに合わせる**こと（新しい外部サービスを増やさない）。

## 4. TTS 設定構造（テナント変更可能性の確保）

### 4.1 設定ヘルパー `ttsSettings.ts`

```ts
// src/lib/ttsSettings.ts

export type TtsEngine = 'gcp' | 'dummy'

export type TtsVoiceSettings = {
  engine: TtsEngine
  languageCode: string // 例: 'ja-JP', 'en-US'
  voiceName: string    // 例: 'ja-JP-Standard-A'
  speakingRate: number // 0.25〜4.0
}

export type TenantTtsSettings = {
  default: TtsVoiceSettings
}

const DEFAULT_TTS_SETTINGS: TenantTtsSettings = {
  default: {
    engine: 'gcp',
    languageCode: 'ja-JP',
    voiceName: 'ja-JP-Standard-A',
    speakingRate: 1.0,
  },
}

export async function getTenantTtsSettings(
  tenantId: string,
): Promise<TenantTtsSettings> {
  // 将来ここで tenant_settings テーブルなどから TTS 設定を取得する。
  // 現時点では、すべてのテナントで DEFAULT_TTS_SETTINGS を返す。
  return DEFAULT_TTS_SETTINGS
}
```

ポイント:

* 現時点では `DEFAULT_TTS_SETTINGS` 固定で問題ない。
* 将来的に、`tenant_settings` から `tts_engine` / `tts_voice_name` などを読んで上書きする実装に差し替えられるよう、**関数のインターフェースを固定**しておく。

### 4.2 API からの利用

* `/api/board/tts` 内では、認証済みユーザの `tenant_id` を取得し、必ず `getTenantTtsSettings(tenantId)` を経由して設定を得る。
* 直接 `process.env` からボイス名などを読まず、**設定ヘルパーを唯一の参照ポイント**とする。

## 5. バックエンド実装詳細

### 5.1 エンドポイント定義

* ファイル: `app/api/board/tts/route.ts`
* メソッド: `POST`
* リクエストボディ（JSON）例:

```json
{
  "tenantId": "tenant-xxx", // サーバ側で検証・上書きしてよい
  "postId": "post-123",     // ログ用（必須ではない）
  "language": "ja-JP",      // UI言語 or 投稿言語
  "text": "・・・読み上げ対象の本文・・・"
}
```

### 5.2 サーバ処理フロー

1. 認証・テナント判定

   * Supabase Auth or 既存のサーバクライアントから `user_id` / `tenant_id` を取得する。
   * リクエストボディ内の `tenantId` は信用せず、サーバ判定結果を優先する。

2. パラメータ検証

   * `text` が空文字 or 一定文字数未満の場合は 400 を返す（無音リクエスト防止）。
   * `text` が上限文字数を超える場合は、適切な長さに切るか 400 とする（仕様に合わせる）。

3. TTS 設定取得

   * `const settings = await getTenantTtsSettings(tenantId)`
   * `language` パラメータが指定されている場合は、`settings.default.languageCode` を上書きしてよい。

4. TTS 実行

   * 既存の TTS クライアント（例: Google Cloud Text-to-Speech のラッパ）を利用する。
   * 戻り値を `Buffer` or `Uint8Array` の音声バイト列として取得する。

5. レスポンス

   * `Content-Type: audio/mpeg`（または適切な MIME）
   * `Content-Length` を設定（可能なら）
   * 本文無しのストリームレスポンスとして音声データを返す。

6. エラーハンドリング

   * TTS 呼び出しで失敗した場合:

     * ログ出力（tenantId, postId, errorCode）
     * `500` + JSON で `{ errorCode: 'tts_failed' }` を返す

### 5.3 TTS クライアント層

* 既に Google TTS 試験コード等がある場合は、それを `src/server/services/ttsService.ts` のように共通化して利用する。

```ts
export async function synthesizeSpeech(
  text: string,
  settings: TtsVoiceSettings,
): Promise<Uint8Array> {
  // GCP Text-to-Speech クライアントを初期化し、
  // settings.languageCode / voiceName / speakingRate に基づいて合成する。
}
```

* `/api/board/tts` は、この `synthesizeSpeech` のみを呼び出す薄いレイヤに留める。

## 6. フロントエンド実装詳細

### 6.1 UI 振る舞い

* 対象ボタン: BoardDetail の本文直下にある読上げアイコン（Volume系）
* 状態管理:

  * `idle` / `loading` / `playing` の 3 状態を持つとよい。
  * `loading` 中はボタンを無効化（スピナー表示も可）。
  * `playing` 中に再度押されたら停止するか無効化するか、どちらかに統一する（実装しやすい方で可）。

### 6.2 呼び出しフロー

1. クリック時に現在の投稿本文を取得

   * BoardDetail が既に持っている `post.body`（翻訳後表示テキスト）を使用する。
   * 可能であれば、現在の UI 言語（`ja-JP` / `en-US` / `zh-CN` 等）も渡す。

2. API 呼び出し

```ts
const res = await fetch('/api/board/tts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: textForTts,
    language: currentLanguageCode, // 例: 'ja-JP'
    postId: post.id,
  }),
})

if (!res.ok) {
  // エラー処理
}

const audioData = await res.arrayBuffer()
const blob = new Blob([audioData], { type: 'audio/mpeg' })
const url = URL.createObjectURL(blob)

const audio = new Audio(url)
audio.play()
```

3. 後片付け

   * 再生終了時に `URL.revokeObjectURL(url)` を呼び出す。
   * 再生中に再度ボタンを押された場合の挙動（停止 or 無視）を決めて実装する。

4. エラー表示

   * API が `tts_failed` を返した場合は、画面下部トースト等で「読上げに失敗しました。」程度のメッセージを表示する。

## 7. テスト観点

### 7.1 フロント（BoardDetail）

* 単体テスト（React Testing Library 想定）

  * 読上げアイコンがレンダリングされていること。
  * クリック時に `/api/board/tts` へ `POST` されること（`fetch` モックで検証）。
  * `text` に投稿本文が入っていること。
  * エラー時にエラーメッセージが表示されること（トースト or 画面内メッセージ）。

### 7.2 バックエンド（/api/board/tts）

* 単体テスト／統合テスト（可能な範囲で）

  * `text` 正常入力時に `audio/mpeg` のレスポンスが返る（モック TTS クライアントで検証）。
  * `text` 空／超長文の場合に `400` が返る。
  * TTS クライアントが例外を投げた場合に `500` + `errorCode: 'tts_failed'` が返る。

## 8. CodeAgent_Report 保存先

* 本タスクに対する CodeAgent_Report は、以下に保存すること。

  * `/01_docs/06_品質チェック/CodeAgent_Report_WS-B02_BoardDetail_TTS_v1.0.md`
