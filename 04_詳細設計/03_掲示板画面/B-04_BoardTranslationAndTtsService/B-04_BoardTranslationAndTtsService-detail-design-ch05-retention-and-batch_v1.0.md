# B-04 BoardTranslationAndTtsService 詳細設計書 ch05 翻訳キャッシュ保有期間・削除バッチ設計 v1.0

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH05
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板翻訳キャッシュ `board_post_translations` の

* 保有期間（retention）ロジック
* Supabase Edge Function + Scheduler による削除バッチ
* 開発環境での実行方法

を定義する。これにより、翻訳キャッシュが無制限に蓄積されることを防ぎつつ、テナントごとに適切な保有期間を設定できるようにする。

---

## 5.2 保有期間ロジック

### 5.2.1 retention_days の決定ルール

* 設定項目:

  * テナント設定 `tenant_settings.config_json.board.translation_retention_days`
* 型: 整数（number）
* 単位: 日

### 5.2.2 デフォルト値・許可範囲

* デフォルト値: `90` 日
* 設定可能範囲:

  * 最小値: `60` 日
  * 最大値: `120` 日
* テナント管理者画面での入力制約:

  * 60〜120 以外の値は保存不可（バリデーションエラー）。
* `translation_retention_days` が未設定の場合:

  * バッチ処理では `90` 日として扱う（アプリケーション側でデフォルトを補完）。

### 5.2.3 期限超過判定

* 判定対象:

  * `board_post_translations.created_at`
* 判定条件:

```text
created_at < now() - interval 'translation_retention_days days'
```

* テナントごとに上記条件を評価し、該当するレコードを削除対象とする。

> 削除対象は翻訳キャッシュのみとし、`board_posts` 本体には影響を与えない。

---

## 5.3 Supabase Edge Function 設計

### 5.3.1 実行トリガ（Supabase Scheduler / cron）

* 実行基盤: Supabase Cloud Pro の Edge Functions + Scheduler を利用する。
* 関数名（例）: `cleanup-board-translations`
* 実行頻度:

  * 1 日 1 回を想定（例: 毎日 03:00 JST 相当）。
  * 実際の cron 設定は Supabase プロジェクトのタイムゾーンに合わせて定義する。
* ローカル開発環境では Scheduler は使用せず、開発者が手動で Edge Function を起動する（5.4 参照）。

### 5.3.2 処理アルゴリズム（テナント単位の削除）

Edge Function 内の論理フローを以下のように定義する。

1. Supabase サービスロールで DB へ接続する。
2. `tenant_settings` から有効なテナント一覧と `translation_retention_days` を取得する。

   * `status = 'active'` のテナントのみ対象とする。
3. 各テナントについて以下を実行する。

   1. 有効な `retention_days` を決定する。

      * `translation_retention_days` が設定されていればその値。
      * 未設定の場合はデフォルト値 `90` を利用。
   2. 当該テナントの `board_post_translations` から削除対象件数を集計する（削除前確認用）。
   3. 削除クエリを実行する。

擬似 SQL:

```sql
DELETE FROM board_post_translations
WHERE tenant_id = :tenantId
  AND created_at < now() - make_interval(days => :retentionDays);
```

4. 削除件数をログとして記録する（ch07 ログ設計参照）。
5. 処理全体が正常終了した場合は `success` として終了し、例外発生時にはエラーログを出力する。

### 5.3.3 例外処理・再実行方針

* 1テナントの削除処理で例外が発生した場合:

  * 他テナントへの処理は継続せず、エラーとして処理を中断してもよい（実装時に要検討）。
  * v1.0 では実装負荷を抑えるため、まずはエラー発生時に処理全体を中断し、ログを手掛かりに手動再実行する運用を想定する。
* 再実行:

  * Edge Function は何度実行しても同じ条件で DELETE されるだけであり、副作用は「再度期限切れレコードがないことの確認」のみに留まる。

> 将来的にテナント単位の部分的失敗を許容したい場合は、テナントごとの try-catch と集約ログを持つ方式へ拡張する余地を残す。

---

## 5.4 ローカル環境での実行方法（開発用）

### 5.4.1 Edge Function の起動方法

ローカル Supabase コンテナ環境では、Scheduler の代わりに CLI から Edge Function を手動実行する。

例（関数名: `cleanup-board-translations` の場合）:

```bash
# 作業ディレクトリを HarmoNet プロジェクトルートに移動
cd D:/Projects/HarmoNet

# Edge Function ローカル起動（serve）
supabase functions serve cleanup-board-translations

# 別シェルから手動実行
supabase functions invoke cleanup-board-translations --no-verify-jwt
```

* 実行方法の詳細は Supabase CLI ドキュメントに従う。
* `--no-verify-jwt` はローカル開発時の簡略化オプションであり、本番環境では利用しない。

### 5.4.2 開発時の確認ポイント

* 削除対象件数のログが意図した値になっているか。
* `board_post_translations` テーブルから、特定テナントの古いレコードが削除されているか。
* `tenant_settings` の `translation_retention_days` を変更した場合に、削除対象期間が期待通りに変化するか。

---

本章では、翻訳キャッシュ保有期間の決定ロジックと、Supabase Edge Function + Scheduler による削除バッチ設計を定義した。
次章 ch06 では、翻訳・TTS 処理に関するタイムアウト・レート制御・セキュリティなどの非機能要件を整理する。
