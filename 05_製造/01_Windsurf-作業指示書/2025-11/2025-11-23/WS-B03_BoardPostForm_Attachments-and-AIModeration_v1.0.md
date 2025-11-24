````markdown
# WS-B03_BoardPostForm_Attachments-and-AIModeration_v1.0

## 1. タスク概要

- 対象コンポーネント: **B-03 BoardPostForm**
- 目的:
  - 掲示板投稿画面に **添付ファイル UI + バリデーション** を実装する。
  - 投稿確定前に **AIモデレーション** を実行し、NG の場合は画面上でブロックする。
- 前提:
  - 詳細設計書は最新版を絶対参照とすること：
    - ch02: `B-03_BoardPostForm-detail-design-ch02-layout_v1.1.md`
    - ch03: `B-03_BoardPostForm-detail-design-ch03-data-model_v1.1.md`
    - ch04: `B-03_BoardPostForm-detail-design-ch04-logic_v1.1.md`
    - ch05: `B-03_BoardPostForm-detail-design-ch05-messages-and-ui_v1.2.md`
    - ch08: `B-03_BoardPostForm-detail-design-ch08-ai-moderation_v1.1.md`（AIモデレーション仕様）

> 設計書に明記されている仕様を優先し、勝手な仕様追加や変更は行わないこと。  
> 仕様不明点がある場合は「実装しない（TODO コメント）」で明示する。

---

## 2. スコープ

### 2.1 In Scope

1. **BoardPostForm の添付ファイル UI 実装**
   - 画面構造: ch02 2.2.7 BoardPostFormAttachmentSection
   - データモデル: ch03 3.4.1 `attachments` 定義
   - ロジック: ch04 4.3.2 添付ファイル関連イベント
   - メッセージ: ch05 5.3.2 / 5.5.1（添付エラー・注意文言）

2. **AIモデレーション呼び出しの組み込み**
   - ch08 で定義された「投稿内容の AI モデレーションフロー」を、BoardPostForm の「最終送信前」に組み込む。
   - NG 判定時は投稿 API を呼ばず、ch05 で定義されたモデレーションエラーメッセージを表示する（キー定義は ch05・ch08 を参照）。

3. **カテゴリ棲み分けロジックは変更しない**
   - すでに実装済みの `postAuthorRole` ごとのカテゴリフィルタを前提に、添付・モデレーションのみ追記する。
   - カテゴリロジックに変更が必要と感じた場合は、**絶対に変更せずコメント(TODO)のみ**残す。

### 2.2 Out of Scope

- Supabase スキーマ変更（テーブル・カラム追加/削除・型変更）
- RLS ポリシーの変更
- API Route 新規作成（既存のモデレーション用ヘルパー or API を前提にする）
- BoardTop / BoardDetail / BoardEdit の UI 改修（別タスク）

---

## 3. 対象ファイル（想定）

※ 実プロジェクト構成に合わせてパスを調整してよいが、**BoardPostForm 周辺に限定**する。

- `src/components/board/BoardPostForm/BoardPostForm.tsx`
- `src/components/board/BoardPostForm/BoardPostFormAttachmentSection.tsx`（存在しない場合は BoardPostForm 内で実装）
- `src/features/board/api/upsertBoardPost.ts`（投稿 API 呼び出しヘルパーがあれば）
- `src/features/board/moderation/moderateBoardPost.ts`（既存があれば使用。なければ TODO コメントのみ）

---

## 4. 実装要件

### 4.1 添付ファイル UI

設計書に準拠して実装すること。

1. **UI 構造**
   - ch02 2.2.7 に従い、本文セクションの直下に「添付ファイル」セクションを配置する。
   - 要素:
     - セクションラベル（ラベル右に * は付けない）
     - 注意文（ch05 5.5.1 の i18n キーを使用）
     - ファイル選択ボタン（＋ドラッグ&ドロップ領域があれば尚可）
     - 選択済みファイル一覧（ファイル名／サイズ／削除ボタン）

2. **許可拡張子・サイズ制限**
   - 設計書に従うこと（すでに ch03/ch04/ch05 に定義あり）。
   - 拡張子:
     - `.pdf`, `.xls`, `.xlsx`, `.doc`, `.docx`, `.ppt`, `.pptx`, `.jpg`, `.jpeg`, `.png`
   - 上限:
     - 1 ファイル最大: 5MB（`tenant_settings.maxAttachmentSizeMB` を参照する前提で定数 or コンフィグ経由）
     - 最大添付数: 5件（`tenant_settings.maxAttachmentCount` 前提）

3. **State / 型**
   - ch03 3.4.1 の `attachments` モデルに合わせる。
   - `status` の意味:
     - `"selected"`: 画面上で選択済み（アップロード前）
     - `"uploading"`: アップロード中
     - `"uploaded"`: アップロード完了（`fileUrl` 有）
     - `"existing"`: 編集時に既に紐づいているファイル
     - `"error"`: バリデーション or アップロードエラー

4. **イベントハンドラ**
   - ch04 4.3.2 のイベント設計に従う。
   - 実装すべきハンドラ:
     - `onSelectAttachmentFile`:
       - 拡張子＋MIME チェック
       - テナント設定のサイズ／件数上限チェック
       - OK の場合に `attachments` に追加、NG の場合はフィールドエラー + サマリエラー（ch05 5.3.2）。
     - `onUploadAttachmentFile`:
       - Storage アップロード開始
       - `status="uploading"` → 完了で `"uploaded"` + `fileUrl` 設定
     - `onRemoveAttachment`:
       - 新規分は配列から削除
       - 既存分は `status="removed"` 相当の扱い（設計書の方針に合わせる）

5. **バリデーション**
   - ch05 5.3.2 の添付関連エラーメッセージキーを必ず使用。
   - 条件:
     - 許可外拡張子 → `board.postForm.error.attachment.invalidType`
     - 1ファイルサイズが上限超過 → `board.postForm.error.attachment.tooLarge`
     - 合計件数が上限超過 → `board.postForm.error.attachment.tooMany`（キーが設計書に無ければ TODO コメントのみ）
   - エラーサマリ:
     - 添付関連のエラーが1件以上ある場合は `board.postForm.error.summary.attachment` をセット。

6. **必須マークとの関係**
   - 添付ファイルは任意のため、ラベルに赤 `*` を表示しない（ch02 2.1.1 のルールを尊重）。

---

### 4.2 AI モデレーション組み込み

詳細は ch08 の仕様を絶対に優先すること。ここでは BoardPostForm から見た統合ポイントだけ定義する。

1. **呼び出しポイント**
   - 「入力バリデーション → OK」後、「確認ダイアログ表示の直前 or 直後」に AIモデレーションを呼び出す。
   - モデレーション NG の場合:
     - 投稿確認ダイアログは開かない or 閉じる
     - フォーム上にエラーを表示し、投稿処理を停止する。

2. **インタフェース（フロント側）**

   既存 or 今後実装されるヘルパー関数を前提にする。  
   このタスクでは **新しい API Route を増やさず**, 既存設計にある呼び出し契約をそのまま使うこと。

   ```ts
   // 例：実際のシグネチャは ch08 に合わせること
   import { moderateBoardPost } from "@/features/board/moderation/moderateBoardPost";

   const result = await moderateBoardPost({
     title,
     content,
     tenantId,
     categoryTag,
     postAuthorRole,
   });
````

* `moderateBoardPost` が存在しない場合、このタスクでは **実装せず TODO コメント** を残すだけとし、勝手に新規ファイルを作らないこと。
* 実際の API 呼び出し先（OpenAI / Vercel / 自前 API）は ch08 の設計に従う。

3. **エラーハンドリング**

   * AI モデレーション結果が NG の場合:

     * ch05 / ch08 で定義された i18n キー（例: `board.postForm.error.moderation.blocked`）を `submitError` またはフィールドエラーとして設定。
     * HTTP ステータスや OpenAI エラーコードはログ出力（Logger）にのみ残す（ユーザには詳細を見せない）。
   * AI モデレーション自体が失敗（タイムアウト等）した場合:

     * 設計書の方針に従う（例: 投稿を許可する／許可しない）。
       不明な場合は「投稿を許可しない」で実装せず、TODO コメントで明示。

4. **ログ連携**

   * ch04 4.7 の Logger 仕様に従い、AI モデレーション関連イベントを必要に応じて追加してもよい。
   * ただし新規イベント名を追加する場合は、コメントで明示し、既存ログ設計と矛盾しないように。

---

## 5. 非機能・制約

* **絶対禁止**

  * DB スキーマ (`schema.prisma`) の変更
  * Supabase RLS ポリシーの追加・変更・削除
  * 既存ファイル・フォルダのリネーム・移動
  * 任意の CSS フレームワーク追加、グローバルスタイルの変更

* **スタイル**

  * 既存 BoardPostForm の UI トーン（白基調・控えめなカード・BIZ UD ゴシック前提）を崩さない。
  * ボタン位置・ラベルなど、既に実装済みの部分は最小限の変更に留める（TKD が後で微調整）。

---

## 6. テスト観点（UT / 手動確認）

### 6.1 添付ファイル

* 許可拡張子（pdf/doc/xls/ppt/jpg/png）を選択 → 正常にリスト表示されること。
* 許可外拡張子（exe 等）を選択 → `board.postForm.error.attachment.invalidType` が出ること。
* 5MB 超のファイルを選択 → `board.postForm.error.attachment.tooLarge` が出ること。
* 6 個以上選択 → 件数上限エラーが出ること（キーが未定義なら TODO を残す）。
* 編集モードで既存添付が表示され、削除／追加ができること。

### 6.2 AI モデレーション

* モデレーション OK ケース:

  * 通常投稿フローが変わらないこと（確認ダイアログ → 投稿成功）。
* モデレーション NG ケース（モック or ダミー条件で再現）:

  * 投稿がブロックされること。
  * 画面にモデレーション関連エラーメッセージが表示されること。
* モデレーション呼び出し失敗（ネットワーク例外など）:

  * 設計書どおりの扱い（投稿許可／不許可）が行われること。
  * 必要に応じて `submitError` が設定されること。

---

## 7. CodeAgent_Report 保存先

* 本タスクに対する CodeAgent_Report は、以下のパスに Markdown で保存してください。

`/01_docs/06_品質チェック/CodeAgent_Report_WS-B03_BoardPostForm_Attachments-and-AIModeration_v1.0.md`

* Report には最低限以下を含めること:

  * 実装ファイル一覧
  * 自己採点（9/10 以上を目標）
  * 実施したテスト観点と結果
  * 残した TODO / 未実装事項

```
