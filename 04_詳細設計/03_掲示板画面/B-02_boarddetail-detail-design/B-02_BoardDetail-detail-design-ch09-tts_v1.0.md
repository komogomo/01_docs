# B-02 BoardDetail 詳細設計 ch09 音声読上げ（TTS）仕様_v1.0

## 1. 目的

* 掲示板詳細画面 BoardDetail（B-02）において、投稿本文を音声で読み上げる機能の仕様を定義する。
* 音声読上げ機能は、弱視・極度の乱視・色覚特性などを持つ利用者が、掲示板本文を負担少なく把握できるようにするユニバーサルデザイン目的の付加機能とする。
* 対象は掲示板詳細画面のみとし、掲示板TOPその他の画面には読上げ機能を実装しない。

## 2. 対象範囲

* 対象画面: `/board/[postId]` 掲示板詳細画面 BoardDetail。
* 対象機能:

  * 本文読上げボタン押下時の API 呼び出し。
  * 返却された音声データのクライアント側再生。
* 非対象:

  * 音声データのキャッシュ保存（DB/Storage）は行わない。
  * 他画面（BoardTop など）での読上げ機能。

## 3. UI 仕様

### 3.1 読上げボタン配置

* 配置位置:

  * 投稿本文カードの直下、翻訳ボタンと同一行に右寄せで配置する。
* 表示要素:

  * アイコン: Lucide `Volume2`（既存仕様に準拠）。
  * テキストラベルは表示しない。
  * `aria-label="投稿本文を読み上げ"` を付与する。
  * ホバー/フォーカス時にはブラウザ標準の `title="読み上げ"` を表示する。

### 3.2 ボタン状態

* 状態は `idle` / `loading` / `playing` の 3 状態を想定する。

  * `idle`: 通常状態。クリック可能。
  * `loading`: 読上げ音声を取得中。ボタンを無効化（クリック不可）とし、必要であれば小さなスピナーを重ねて表示する。
  * `playing`: 音声再生中。再生停止ボタンとして再利用するか、押下無効化のどちらかとする（実装容易な方に合わせて運用で統一）。
* 画面上の視覚表現はシンプルに保ち、アイコン色だけで状態変化を示さない（色覚特性への配慮とし、アイコン形状＋動きで区別する）。

## 4. 読上げ対象テキスト

### 4.1 対象範囲

* 読上げ対象:

  * 投稿本文（現在表示中の言語に変換済みのテキスト）。
* 非対象:

  * タイトル、投稿者名、投稿日時、ボタンラベル、画面上の他要素（UI テキスト）は読上げ対象外とする。

### 4.2 言語

* 読上げ時の言語は、BoardDetail の表示言語と同一とする。

  * JA 表示時: 日本語読み上げ（`ja-JP`）。
  * EN 表示時: 英語読み上げ（`en-US`）。
  * ZH 表示時: 中国語読み上げ（`zh-CN` など）。
* 実際の `languageCode` は TTS 設定ヘルパー `getTenantTtsSettings()` の戻り値をベースとし、必要に応じて UI 言語コードから切り替える。

## 5. TTS 設定と API

### 5.1 TTS 設定ヘルパー

* ファイル: `src/lib/ttsSettings.ts`（WS 指示書に準拠）。
* 関数: `getTenantTtsSettings(tenantId: string): Promise<TenantTtsSettings>`。
* 仕様:

  * `TenantTtsSettings` は少なくとも `default: { engine, languageCode, voiceName, speakingRate }` を持つ。
  * 現時点では、すべてのテナントが共通の `DEFAULT_TTS_SETTINGS` を利用する実装とする。
  * 将来、テナント管理画面で登録した TTS 設定を `tenant_settings` 等から取得するように拡張できる構造にする。

### 5.2 読上げ API

* エンドポイント: `POST /api/board/tts`。
* リクエストボディ（JSON）例:

```json
{
  "postId": "<board_posts.id>",
  "language": "ja-JP",
  "text": "・・・読み上げ対象の本文・・・"
}
```

* サーバ処理フロー:

  1. 認証情報から `tenant_id` / `user_id` を取得する。
  2. `text` が空または閾値未満の場合は 400 を返す（不要な TTS 呼び出しを避ける）。
  3. `getTenantTtsSettings(tenantId)` を呼び出し、TTS 設定を取得する。
  4. 既存の TTS サービス（Google Cloud Text-to-Speech など）を用いて音声データを生成する。
  5. `Content-Type: audio/mpeg`（または適切な MIME）で音声データを返却する。
  6. 失敗時はログ出力のうえ、`500` + `{ errorCode: "tts_failed" }` を JSON で返却する。
* サーバ側では音声データを DB や Storage に保存せず、毎回合成した結果のみレスポンスとして返す。

## 6. フロントエンド挙動

### 6.1 API 呼び出し

* 読上げボタン押下時に、以下のフローとする。

  1. 投稿本文（現在表示中の言語）のテキストを連結し、`text` として用意する。
  2. 現在の UI 言語から `language` を決定する（例: JA → `ja-JP`）。
  3. 上記を含めた JSON を `POST /api/board/tts` に送信する。

* 疑似コード例:

```ts
setState('loading')

const res = await fetch('/api/board/tts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    postId: post.id,
    language: currentLanguageCode,
    text: readingText,
  }),
})

if (!res.ok) {
  setState('idle')
  // エラー表示
  return
}

const arrayBuffer = await res.arrayBuffer()
const blob = new Blob([arrayBuffer], { type: 'audio/mpeg' })
const url = URL.createObjectURL(blob)

const audio = new Audio(url)
audio.onended = () => {
  URL.revokeObjectURL(url)
  setState('idle')
}

setState('playing')
audio.play().catch(() => {
  URL.revokeObjectURL(url)
  setState('idle')
})
```

### 6.2 エラーハンドリング

* `res.ok` でない場合:

  * 画面下部のトーストなどで「読上げに失敗しました。」を表示する。
  * 状態を `idle` に戻す。
* ネットワークエラー時も同様に扱う。

## 7. メッセージ仕様（案）

* 成功時:

  * 明示的なメッセージ表示は不要（音声再生自体がフィードバックとなる）。
* 失敗時:

  * 共通メッセージ定義に以下のキーを追加する想定。

    * `board.detail.tts.error.generic`: 「読上げに失敗しました。」

※ 実際の i18n キー名と文言は、共通メッセージ設計に合わせて最終調整する。

## 8. 非機能・留意事項

* 想定利用頻度は高くないが、アクセシビリティ向上のために実装しておく。
* 同一投稿に対する連続呼び出し時のキャッシュは行わない（実装を単純化する）。
* 音量や再生速度はブラウザ標準機能に任せ、アプリ側での個別コントロールは行わない。
