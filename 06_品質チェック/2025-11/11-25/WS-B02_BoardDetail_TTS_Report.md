# WS-B02 BoardDetail TTS 作業レポート

## 1. 作業概要

- **目的**
  - 掲示板詳細画面（BoardDetail）にテキスト読み上げ（TTS）機能を追加し、投稿本文を音声で再生できるようにする。
- **対応範囲**
  - BoardDetail 画面に読上げボタンと再生制御 UI を実装。
  - 認証済みユーザ向けの TTS API エンドポイント `POST /api/board/tts` を新規実装。
  - Google Cloud Text-to-Speech を利用した音声合成ロジックを既存サービスに統合。
  - TTS 用の設定（エンジン種別、声種、話速など）を取得するための設定モジュールを新規作成。

## 2. 変更ファイル一覧

### バックエンド / サーバサイド

- `app/api/board/tts/route.ts`（新規）
  - BoardDetail 専用の TTS API エンドポイント。
- `src/lib/ttsSettings.ts`（新規）
  - テナント別 TTS 設定を返すためのヘルパーモジュール。
- `src/server/services/tts/BoardPostTtsService.ts`（既存確認のみ）
  - 既存の TTS サービスラッパー。今回の API から利用。
- `src/server/services/tts/GoogleTtsService.ts`（既存確認のみ）
  - Google Cloud Text-to-Speech の呼び出しラッパー。今回の API から利用。

### フロントエンド / 画面側

- `src/components/board/BoardDetail/BoardDetailPage.tsx`
  - 読上げボタン UI と Audio 再生ロジックを実装。
  - TTS ボタンおよび添付ファイルボタンのスタイル調整（枠線・文字色など）。

## 3. 実装内容詳細

### 3-1. TTS 設定モジュール（`src/lib/ttsSettings.ts`）

- **目的**
  - 将来的にテナントごとに TTS 設定（声種・話速・エンジン）を切り替えられるようにするための集約ポイント。
- **主な型定義**
  - `TtsEngine = "gcp" | "dummy"`
  - `TtsVoiceSettings`（`engine`, `languageCode`, `voiceName`, `speakingRate`）
  - `TenantTtsSettings`（`default: TtsVoiceSettings`）
- **デフォルト値**
  - 全テナント共通で以下を使用：
    - `engine: "gcp"`
    - `languageCode: "ja-JP"`
    - `voiceName: "ja-JP-Standard-A"`
    - `speakingRate: 1.0`
- **公開関数**
  - `getTenantTtsSettings(tenantId: string): Promise<TenantTtsSettings>`
    - 現時点では `tenantId` は未使用で、常にデフォルト設定を返却。
    - 将来 `tenant_settings` テーブル等から TTS 設定を取得する際の拡張ポイントとする前提。

### 3-2. TTS API エンドポイント（`app/api/board/tts/route.ts`）

- **エンドポイント**
  - `POST /api/board/tts`
- **リクエストボディ（JSON）**
  - `tenantId?: string`  
    → クライアントから送られてきてもサーバ側で判定したテナント ID を優先。
  - `postId?: string`  
    → ログ用に投稿 ID を任意指定可能（動作上の必須ではない）。
  - `language?: string`  
    → `"ja-JP"`, `"en-US"`, `"zh-CN"` などの BCP47 形式。
  - `text: string`  
    → 読み上げ対象の本文テキスト。
- **入力バリデーション**
  - 認証チェック
    - Supabase Auth で `getUser()` を呼び、未ログインまたはメール未設定の場合は `401 auth_error` を返却。
  - ユーザ／テナントチェック
    - `users` テーブルからメール一致かつ `status = 'active'` のレコードを取得。
    - `user_tenants` から `user_id` と `status = 'active'` で `tenant_id` を取得。
    - いずれかが取得できない場合は `403 unauthorized` を返却。
  - テキスト長チェック
    - `MIN_TEXT_LENGTH = 5`
    - `MAX_TEXT_LENGTH = 5000`
    - 上記範囲外の場合は `400 validation_error` を返却。
- **言語マッピング**
  - `language` 文字列を `SupportedLang`（`'ja' | 'en' | 'zh'`）に正規化。
    - 例：`"en-US"` → `'en'`, `"zh-CN"` → `'zh'`、その他は `'ja'`。
  - `getTenantTtsSettings` の `languageCode` からも同様にマッピングし、将来的にテナントのデフォルト言語を使える構造にしている。
- **TTS 実行フロー**
  - `GoogleTtsService` を生成し、`BoardPostTtsService` に渡して利用。
  - `BoardPostTtsService#synthesizePostBody` に以下を渡す：
    - `tenantId`（サーバ側判定）
    - `postId`（任意・未指定時は `"unknown"`）
    - `lang`（`SupportedLang`）
    - `text`（本文）
  - 返却された `audioBuffer` を `Buffer` に変換し、`Content-Type` には TTS サービス側から返却された `mimeType`（想定: `audio/mpeg`）をセットして返却。
- **レスポンス**
  - 正常時
    - `status: 200`
    - Body: 音声バイナリ（`audio/mpeg`）
    - ヘッダ：`Content-Type`, `Content-Length`, `Cache-Control: no-store`
  - エラー時
    - `401`, `403`, `400` などのバリデーション／認可エラー時は JSON `{ errorCode: ... }` を返却。
    - 予期せぬ例外発生時は `500` + `{ errorCode: 'tts_failed' }` を返却。
- **ログ出力**
  - `board.tts.api.auth_error`
  - `board.tts.api.user_not_found`
  - `board.tts.api.membership_error`
  - `board.tts.api.success`
  - `board.tts.api.unexpected_error`

### 3-3. BoardDetail 画面の TTS UI（`BoardDetailPage.tsx`）

- **状態管理**
  - `ttsState: 'idle' | 'loading' | 'playing'`
    - `idle`: 読上げ待機状態
    - `loading`: TTS API 呼び出し中
    - `playing`: 音声再生中
  - `ttsErrorKey: string | null`
    - 読上げエラー発生時にエラーメッセージの翻訳キーを格納。
  - `audioRef: React.RefObject<HTMLAudioElement | null>`
  - `audioUrlRef: React.RefObject<string | null>`
    - `URL.createObjectURL` で生成したオブジェクト URL を保持し、再生終了時やアンマウント時に `URL.revokeObjectURL` で解放。
- **本文テキストの選択ロジック**
  - 画面上で表示している本文（翻訳済みを含む）と同じテキストを TTS に渡すため、
    - `data.translations` から `currentLocale`（`'ja' | 'en' | 'zh'`）に合致する翻訳を取得。
    - 該当翻訳があればその `content` を、なければ `originalContent` を使用。
- **TTS ボタン押下時の挙動**
  - `ttsState === 'playing'` の場合
    - 再生中に再度押すと、Audio を停止＋巻き戻しし、`ttsState` を `idle` に戻す（トグル動作）。
  - それ以外の場合
    - `ttsState` を `loading` に更新し、`ttsErrorKey` をクリア。
    - `currentLocale` から `languageCode` を決定：
      - `ja` → `"ja-JP"`
      - `en` → `"en-US"`
      - `zh` → `"zh-CN"`
    - `fetch('/api/board/tts', { method: 'POST', body: JSON.stringify({ text, language, postId }) })` を実行。
    - 正常終了時、`arrayBuffer()` で音声バイナリを取得し、`new Blob([...], { type: mimeType })` → `URL.createObjectURL` で Audio インスタンスを生成・再生。
    - 再生成功後、`ttsState = 'playing'`。
    - 通信エラーや API エラー時には `ttsState = 'idle'` に戻し、`ttsErrorKey = 'board.detail.tts.error'` をセットして画面にエラーメッセージを表示。
- **アンマウント処理**
  - `useEffect` のクリーンアップで以下を実施：
    - 再生中の Audio があれば `pause()` して参照を破棄。
    - `audioUrlRef` に保持している URL を `URL.revokeObjectURL` で解放。

### 3-4. 画面デザイン／スタイル調整

#### 読上げボタン

- 配置
  - 本文エリア（白背景ボックス）の右下に配置し、スクリーンショット仕様に合わせて右寄せ。
- 見た目
  - 枠線:
    - `rounded-full border-2`
    - 非アクティブ時: `border-gray-200`
    - 再生中: `border-blue-600`
  - 文字色:
    - 非アクティブ時: `text-gray-500`
    - 再生中: `text-blue-600`
  - ホバー時: `hover:bg-gray-50`
  - アイコン: `Volume2`（`lucide-react`）を使用し、`className="h-4 w-4"` でボタン内に表示。
- 文言
  - 非再生時: `t('board.detail.tts.play')`（例: 「読み上げる」）
  - 再生中: `t('board.detail.tts.stop')`（例: 「読み上げを停止」）

#### 添付ファイルボタン（プレビュー／ダウンロード）

- 対象
  - BoardDetail 画面内の添付ファイルリストに表示される `プレビュー` / `ダウンロード` ボタン。
- 変更内容
  - 枠線をフッターのアクティブ線と同程度の太さにするため、`border` → `border-2` に変更。
  - それ以外の色やフォントサイズは従来どおり。具体的には：
    - プレビューボタン:
      - `className="rounded-md border-2 border-blue-200 px-2 py-1 text-[11px] text-blue-600 hover:bg-blue-50"`
    - ダウンロードボタン:
      - `className="rounded-md border-2 border-gray-200 px-2 py-1 text-[11px] text-gray-700 hover:bg-gray-50"`

## 4. 動作確認内容

### 4-1. 一般ユーザでの確認

- 前提
  - 一般ユーザとしてログインし、テナントに所属している状態。
- 確認項目
  - BoardDetail 画面を開くと、本文下部に「読み上げる」ボタンが表示される。
  - ボタン押下で `/api/board/tts` が呼び出され、数秒後に音声が再生される。
  - 再生中はボタンの枠線および文字色が青になり、文言が「読み上げを停止」に変化する。
  - 再度ボタンを押すと音声が停止し、ボタンの見た目・文言が元に戻る。
  - 添付ファイルがある場合、`プレビュー` / `ダウンロード` ボタンの枠線がフッターと同等の太さで表示される。

### 4-2. 管理組合ユーザでの確認

- 前提
  - 管理組合ユーザとしてログインし、同一テナントの投稿詳細を閲覧。
- 確認項目
  - 一般ユーザと同様に、BoardDetail の本文下に読上げボタンが表示される。
  - 読上げボタンの挙動（再生・停止、見た目の変化、エラー時のメッセージ表示）が同等に動作することを確認。

### 4-3. エラー系確認

- 読上げテキストが極端に短い場合（5文字未満）
  - API 側で `validation_error` となり、音声は生成されない。
  - 実運用では本文が空の状態で BoardDetail に遷移しない前提のため、UI 上では特別な制御は行っていない（ボタン押下時に空文字の場合は早期 return）。
- ネットワークエラー・サーバエラー時
  - `/api/board/tts` のレスポンスが `ok` でない場合、`ttsState` を `idle` に戻し、
    - `board.detail.tts.error` の文言を本文下に表示（多言語対応）。

## 5. 残課題・今後の検討

1. **TTS 結果のキャッシュ／再利用**
   - 現状は、毎回 `/api/board/tts` 呼び出しのたびに Google TTS で音声合成を行っている。
   - 投稿 ID ＋言語ごとにハッシュをキーとしたキャッシュ（例: Supabase Storage や DB テーブル）を設けることで、同一内容の再合成を避ける余地がある。
   - 今回の WS では仕様上「将来対応」とし、実装は行っていない。

2. **テナント別 TTS 設定の反映**
   - `getTenantTtsSettings` は現時点で固定値を返す実装になっている。
   - 将来的に `tenant_settings` の JSON に TTS 設定を保持し、
     - エンジン種別（GCP / 他サービス）
     - 声種（男性/女性、読み上げスタイル）
     - 話速・ピッチ
     などをテナント管理画面から変更できるようにする余地がある。

3. **アクセシビリティ向上**
   - 現在はボタンにラベル（テキスト）とアイコンが併記されているため、スクリーンリーダーでも概ね問題なく利用可能と想定。
   - 追加で `aria-pressed` 属性や、再生中であることを明示するための `aria-live` 領域の検討余地がある。

---

以上が、WS-B02 BoardDetail TTS の実装および確認内容のレポートです。
