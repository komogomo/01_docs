# WS-CXX_CleaningDutyPage_v1.0

## 0. メタ情報

* Task 名: 清掃当番管理画面（CleaningDutyPage）実装
* コンポーネントID: C-XX
* 対象ファイル例:

  * `src/app/(tenant)/cleaning-duty/page.tsx`（ルーティングは既存構成に合わせて調整）
  * `src/components/cleaning-duty/CleaningDutyPage.tsx`
  * `src/components/cleaning-duty/CleaningDutyHeader.tsx`
  * `src/components/cleaning-duty/CleaningDutyTable.tsx`
  * `src/components/cleaning-duty/CleaningDutyRow.tsx`
  * `src/components/cleaning-duty/CleaningDutyFooterActions.tsx`
  * `src/components/cleaning-duty/CleaningDutyHistoryModal.tsx`
  * `src/components/cleaning-duty/CleaningDutyCompleteDialog.tsx`
  * `src/lib/api/cleaningDutyApi.ts`（API ラッパ）
* 参照ドキュメント（必読）:

  * `D:\AIDriven\01_docs\03_基本設計\03_画面設計\05_清掃当番画面/C-XX_清掃当番管理画面-基本設計_v1.0.md`
  * `D:\AIDriven\01_docs\04_詳細設計\05_清掃当番画面/清掃当番管理画面 詳細設計書 v1.0.md`
  * `/01_docs/02_技術スタック/harmonet-technical-stack-definition_v4.5.md`
  * `/01_docs/02_DB設計/HarmoNet-DB-Basic-Design_v2.0.md`
  * Prisma スキーマ: `schema.prisma`
* CodeAgent_Report 保存先:

  * `/01_docs/06_品質チェック/CodeAgent_Report_CXX_CleaningDutyPage_v1.0.md`

本タスクでは、上記設計書の仕様を**変更せずに実装に落とし込むこと**。実装上の都合で仕様を変えたくなった場合は、TKD にエスカレーション前提とし、勝手に簡略化・改変しないこと。

---

## 1. ゴール・スコープ

### 1.1 ゴール

* ホーム画面の機能タイル（旧「アンケート」）から遷移する「清掃当番管理画面」を実装し、以下を満たすこと:

  * ログインユーザの `group_code` が設定されている場合のみ、清掃当番管理簿を表示できること。
  * 本文TOPに `group_code + "_掃除当番管理簿"` が表示されること（i18n 管理）。
  * 清掃当番表が現行 Excel 管理簿と同じ列順・ボタン配置で表示されること。
  * 班員は自分の行の「実施結果」を記録できること。
  * 班長は世帯主の設定・変更と、サイクル単位の完了確定ができること。
  * 「前回」ボタンで自グループ全体の履歴（最大 3 サイクル）が参照できること。

### 1.2 スコープ

* 対象: フロントエンド実装 + フロントから呼ぶ API ラッパの実装。
* DB スキーマ変更（`cleaning_duties` 追加など）は別タスクで完了している前提。ここでは Prisma モデルを読み取り、想定フィールドを使用するのみとする。
* RLS ポリシーの SQL 実装そのものは別タスク。フロント側では「こう制御される前提」でクエリ条件／UI 制御を行う。

---

## 2. 前提・共通ルール

1. 設計書遵守

   * 基本設計・詳細設計に記載された仕様を**変更しない**こと。
   * 不明点がある場合、勝手に補完せずコメント TODO を残す。

2. 技術スタック

   * Next.js 16 / React / TypeScript / App Router。
   * Tailwind CSS 4, Lucide アイコン。
   * Supabase クライアント（既存のラッパを利用）。
   * 共通ロガー（`logger`）が存在する前提で、詳細設計 6章のログイベントを出力する。

3. i18n

   * すべてのラベル・ボタン名・メッセージは DB 由来の i18n 機構から取得する。
   * 画面内ハードコーディングの日本語は置かない。

4. 権限

   * 認証済み前提（Auth ガードは既存を利用）。
   * ページ入室条件: `users.group_code IS NOT NULL`。
   * UI 制御は詳細設計のロール別表に従うこと（自分行のみチェック可、班長のみ世帯主編集・完了）。

---

## 3. UI 実装要件

### 3.1 レイアウト

* 既存のテナントユーザ管理画面のカードレイアウトと同じスタイルを流用する。
* 本文カード内構成:

  1. グループタイトル: `<group_code>_掃除当番管理簿`（i18n suffix を利用）。
  2. 説明テキスト: 詳細設計 1.2 を参照し、i18n キーで取得。
  3. 清掃当番表: テーブル。
  4. ページネーション: 既存共通コンポーネント。
  5. 下部ボタン行: 左にページネーション、右に [前回] [完了] ボタン。

### 3.2 テーブル定義

* 列順は **Excel 管理簿と完全一致**させる。

| 列 | ヘッダ表示 | 内容                                   |
| - | ----- | ------------------------------------ |
| 1 | 項番    | 行番号（1,2,3...）                        |
| 2 | 実施結果  | チェックボックス (`is_done`)                 |
| 3 | 清掃日   | `cleaned_on` を日付形式で表示                |
| 4 | 住居番号  | `residence_code` 表示のみ                |
| 5 | 世帯主   | `assignee_id` に紐づく `users.last_name` |
| 6 | 操作    | [編集] ボタン（班長のみ）                       |

* 世帯主の編集:

  * 通常表示: テキスト（`last_name`）。
  * [編集] 押下時: ドロップダウンに切り替え、自グループ内ユーザ一覧から選択。

### 3.3 ボタン

* [前回]

  * テーブル下部左側付近に 1 個。
  * クリックで `CleaningDutyHistoryModal` を表示。

* [完了]

  * テーブル下部右側に 1 個。
  * 班長 (`group_leader`) のみ表示・活性。
  * クリックで `CleaningDutyCompleteDialog` 表示 → 確定で完了API呼び出し。

---

## 4. ロジック・データフロー

### 4.1 初期表示

1. ログインユーザ情報を取得（tenant_id, user_id, group_code, roles）。
2. group_code が NULL の場合:

   * 詳細設計 8.1 のメッセージを i18n から取得して表示。
   * テーブルやボタンは表示しない。
3. group_code がある場合:

   * `cleaningDutyApi.fetchCurrentDuties(tenant_id, group_code)` で現サイクル一覧を取得。
   * 成功時、テーブルにマッピングして描画。
   * 画面表示時に `logger.info(cleaningDuty.page.view)` を出力。

### 4.2 実施結果チェック

* 対象: ログインユーザの `residence_code` に一致する行のみ。
* チェックON/OFFのたびに、以下を行う:

  1. 楽観的更新で UI 上のチェック状態を変更。
  2. `cleaningDutyApi.toggleDuty(id, is_done)` を呼び出し。
  3. 成功時:

     * `is_done = true` になった場合、レスポンスの `cleaned_on` を UI に反映。
     * `logger.info(cleaningDuty.duty.toggle)` を出力。
  4. 失敗時:

     * UI 状態を元に戻し、共通エラートーストを表示。

### 4.3 世帯主編集（班長のみ）

1. [編集] ボタン押下:

   * 行内の世帯主表示をドロップダウンに差し替え。
   * 自グループ内ユーザ一覧を取得済みなら再利用、未取得なら API で取得。
2. 選択確定時:

   * `cleaningDutyApi.changeAssignee(id, assignee_id)` を呼び出し。
   * 成功時:

     * テキスト表示に戻し、`last_name` を更新。
     * `logger.info(cleaningDuty.assignee.change)` を出力。
   * 失敗時:

     * 変更前の値に戻し、エラートースト表示。

### 4.4 完了処理（班長のみ）

1. [完了] ボタン押下 → `CleaningDutyCompleteDialog` 表示。
2. ダイアログで「完了する」選択時:

   * `cleaningDutyApi.completeCycle(tenant_id, group_code)` を呼び出し。
   * 成功時:

     * 現サイクル行群に `completed_at` が付与されたとみなし、フロント側では新しいサイクルの一覧を再取得する。

       * `fetchCurrentDuties` を再呼び出し。
     * `logger.info(cleaningDuty.cycle.complete)` を出力。
   * 失敗時:

     * 何も変更せず、エラートースト表示。

### 4.5 前回履歴

1. [前回] ボタン押下:

   * `cleaningDutyApi.fetchHistory(tenant_id, group_code)` を呼び出し。
2. 成功時:

   * 詳細設計 5.3 の形式でモーダルに一覧表示。
3. 失敗時:

   * エラートースト表示。

---

## 5. cleaningDutyApi インタフェース（想定）

```ts
// 自グループの現サイクル一覧取得
async function fetchCurrentDuties(params: { tenantId: string; groupCode: string }): Promise<CleaningDutyRow[]>;

// 実施結果トグル
async function toggleDuty(params: { id: string; isDone: boolean }): Promise<{ cleanedOn: string | null }>;

// 世帯主変更
async function changeAssignee(params: { id: string; assigneeId: string }): Promise<void>;

// サイクル完了
async function completeCycle(params: { tenantId: string; groupCode: string }): Promise<void>;

// 前回履歴取得（最大3サイクル）
async function fetchHistory(params: { tenantId: string; groupCode: string }): Promise<CleaningDutyHistoryCycle[]>;
```

戻り値の型定義は詳細設計書のフィールド構成に合わせて定義すること。Supabase クエリの where 句・order 句は詳細設計 3章・5章を参照。

---

## 6. ログ出力実装

詳細設計 6章のイベントに対応する箇所で、共通ロガーを呼び出す。

例:

```ts
logger.info('cleaningDuty.page.view', { tenantId, userId, groupCode, route: '/cleaning-duty' });
logger.info('cleaningDuty.duty.toggle', { tenantId, userId, groupCode, residenceCode, cycleNo, isDone, cleanedOn });
logger.info('cleaningDuty.assignee.change', { tenantId, userId, groupCode, residenceCode, oldAssigneeId, newAssigneeId });
logger.info('cleaningDuty.cycle.complete', { tenantId, userId, groupCode, cycleNo, completedAt });
logger.error('cleaningDuty.error', { tenantId, userId, groupCode, operation, errorMessage });
```

キー名・フィールド名は既存 logger の命名規則に合わせて調整してよいが、イベント名は上記をベースにすること。

---

## 7. テスト観点（Windsurf 自己チェック用）

実装後、自分で最低限以下を確認すること。

1. `group_code` を持つユーザでログインすると、清掃当番管理簿が表示される。
2. `group_code` が NULL のユーザでは、エラーメッセージが表示され、表・ボタンは出ない。
3. 自分の行のチェック ON で清掃日が入り、API が成功している。別住戸の行は操作できない。
4. 班長ユーザで世帯主の編集・保存ができ、班員ユーザでは [編集] が出ない。
5. 班長ユーザで [完了] → ダイアログ → 完了後、一覧が次サイクルに切り替わる。
6. [前回] で自グループ全体の履歴（最大3サイクル）が表示される。編集はできない。
7. ロガーに各イベントのログが出力されている（Vercel ログで目視確認）。


全作業完了後に、詳細な作業リポートを下記ディレクトリに出力してください。
D:\AIDriven\01_docs\06_品質チェックWS-CXX_CleaningDutyPage_WorkReportv1.0.md

---

以上。
