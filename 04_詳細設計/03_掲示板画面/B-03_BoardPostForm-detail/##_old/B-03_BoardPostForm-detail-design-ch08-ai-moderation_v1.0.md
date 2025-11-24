# B-03 BoardPostForm 詳細設計書 ch08 AIモデレーション仕様 v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH08
**Version:** 1.0
**Supersedes:** N/A（新規作成）
**Created:** 2025-11-23
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 8.1 本章の目的

本章では、掲示板投稿フォームコンポーネント **B-03 BoardPostForm** において利用する **AI モデレーション機能** の仕様を定義する。
AI モデレーションは、投稿本文・タイトル・コメント本文に対して AI による内容チェックを行い、

* 不適切な内容をユーザに警告することで、掲示板の炎上・誹謗中傷・差別的表現を抑止する

ことを目的とした「ライトな抑止機能」である。法務レベルの厳格な監査や、完全な安全性を保証するものではない。

本章で定義する仕様は、BoardPostForm（投稿・編集）およびコメント投稿 UI から呼び出される **投稿 API / コメント API** が共通で利用する前提とする。
BoardDetail（B-02）は、モデレーションの有無や結果を直接扱わず、「すでにモデレーション済み（必要ならマスク済み）の投稿内容を表示する」前提とする。

---

## 8.2 適用範囲と位置付け

### 8.2.1 対象コンテンツ

AI モデレーションの対象とするコンテンツ種別は以下の通りとする。

* 掲示板投稿（board_posts）

  * タイトル
  * 本文
* 掲示板コメント（board_comments）

  * コメント本文

将来的には、お知らせ・施設予約の自由記述欄などにも拡張可能なように、
`moderation_logs.content_type` に `"board_post" / "board_comment"` を格納する汎用設計とする。

### 8.2.2 BoardPostForm との関係

BoardPostForm は、従来どおり「投稿 API」を呼び出すフロントエンドコンポーネントとし、AI モデレーションのロジックは **API 内部（サーバ側）** に実装する。

* BoardPostForm が担う責務:

  * API の成功/失敗をハンドリングし、エラーコードに応じたメッセージを表示する。
  * モデレーションレベル・スコア・理由をフロント側で詳細に扱わない。
* API が担う責務:

  * テナント設定に応じてモデレーションの有無・レベルを判定。
  * AI モデルへ本文・タイトル等を送信し、スコア・理由を取得。
  * `moderation_logs` へ記録し、最終的なアクション（許可 / マスク / ブロック）を決定する。

---

## 8.3 テナント設定とレベル定義

### 8.3.1 テナント設定項目

AI モデレーションの ON/OFF・レベルは、テナント単位で管理する。設定値は `tenant_settings.config_json`（または同等の設定スキーマ）に保持し、API 側で参照する。

想定キー（論理定義）は次の通り。

* `board.moderation.enabled: boolean`

  * 既定値: `true`（デフォルト有効）
* `board.moderation.level: 0 | 1 | 2`

  * `0`: 無効（モデレーションを行わない）
  * `1`: レベル 1（警告中心）
  * `2`: レベル 2（警告＋ブロック or マスク）

設定値の編集 UI はテナント管理画面（掲示板設定タブ）で提供する。
詳細は管理者画面の詳細設計で定義し、本章では「設定値が API から参照可能である」前提のみを記載する。

### 8.3.2 レベル別の基本方針

AI モデレーションは、AI モデルから返却される `ai_score`（0.0〜1.0 など）および `flagged_reason` をもとに、

* low: 低リスク
* medium: 中リスク
* high: 高リスク

程度の論理レベルを内部的に判定し、そのうえで次のように振る舞う。

* Level 0: モデレーションを実行しない。ログも記録しない（もしくは最小限の "off" ログのみ）。
* Level 1: 高リスク時に警告ダイアログを表示し、ユーザ判断で続行可能。
* Level 2: 高リスク時に投稿をブロック（またはマスク保存）し、ユーザに修正を促す。

具体的なスコア閾値・カテゴリーとリスクレベルの対応は、AI プロバイダ仕様に依存するため、
Back-end 実装側の内部設定とし、本章では論理レベルの振る舞いのみを定義する。

---

## 8.4 投稿・コメントフローへの組み込み

### 8.4.1 新規投稿（board_posts INSERT）

1. 利用者が BoardPostForm にタイトル・本文等を入力し、「投稿」ボタンを押下する。
2. BoardPostForm は、既存どおり `/api/board/posts`（仮）へ POST リクエストを送信する。
3. API はテナント設定を参照し、`board.moderation.enabled` が `true` かつ level > 0 の場合に AI モデレーションを実行する。
4. AI モデルから `ai_score` と `flagged_reason` を取得し、内部ロジックで `low / medium / high` に分類する。
5. レベル別の動作定義にしたがって、最終アクション（allow / mask / block）を決定する。
6. 最終的な `decision`・`ai_score`・`flagged_reason` を `moderation_logs` に保存する。
7. `decision` が allow（許可）の場合のみ、`board_posts` に INSERT し、`postId` をレスポンスとして返却する。

BoardPostForm は、レスポンスステータスとエラーコードに応じて、成功メッセージまたはモデレーションエラーメッセージを表示する。

### 8.4.2 投稿編集（board_posts UPDATE）

投稿内容の編集時も、新規投稿と同じフローで AI モデレーションを実行する。

* 編集前後の内容差分は API 内部の実装に委ね、BoardPostForm は「投稿/編集 API を呼ぶ」という点で同一扱いとする。
* 既存投稿に対するモデレーション結果は、`moderation_logs` の `content_id`（= postId）で紐づけられる。

### 8.4.3 コメント投稿・編集（board_comments）

コメント投稿/編集 UI は BoardPostForm とは別コンポーネントとなるが、
モデレーション仕様は同一の API ポリシーに従う。

* コメント投稿 API（例: `/api/board/comments`）も、テナント設定とレベルに応じてモデレーションを実行する。
* `moderation_logs.content_type = "board_comment"` とし、`content_id = commentId` を付与する。
* コメント本文が高リスクと判定された場合、Level2 では投稿をブロックし、エラーコードを返却する。

BoardPostForm 詳細設計ではコメント用 UI の実装は対象外とし、
「コメント投稿 UI も同一の AI モデレーション方針に従う」ことのみを明記する。

---

## 8.5 レベル別動作詳細

### 8.5.1 Level 0（無効）

* モデレーションを実行しない。
* `moderation_logs` にもレコードを残さない（または `decision = allow` の簡易ログのみ）。
* BoardPostForm から見える挙動は「従来どおりの投稿/編集」と同一となる。

### 8.5.2 Level 1（ソフトモデレーション）

* `high` リスクと判定された場合:

  * API は `moderation_logs` に `decision = allow` / 高い `ai_score` / `flagged_reason` を記録したうえで投稿を許可する。
  * 追加仕様として、フロント側に「警告表示フラグ」を返却するかどうかを選択できるが、初版では **API 内部で判定・記録のみ**とし、BoardPostForm は通常成功として扱う。
* `medium` 以下のリスク:

  * 通常どおり投稿を許可し、ログのみ記録する。

初版実装では、「警告ダイアログを出すかどうか」は UX とのバランスを見ながら、

* a) サーバ側でログのみ記録
* b) 将来的に UI に警告メッセージを出す
  の 2 段階で拡張可能なようにしておく。

### 8.5.3 Level 2（ストロングモデレーション）

Level 2 では、高リスクコンテンツに対して **投稿ブロック** を行う。

* `high` リスクと判定された場合:

  * API は `moderation_logs.decision = block` として記録する。
  * `board_posts` / `board_comments` にはレコードを保存しない。
  * レスポンスは `4xx`（例: `400 Bad Request`）とし、`errorCode = "ai_moderation_blocked"` を返却する。
  * BoardPostForm は、このエラーコードに対応するメッセージを表示し、投稿内容の修正を促す。
* `medium` リスク:

  * Level 1 と同様に許可（ログ記録のみ）。
* `low` リスク:

  * 通常どおり許可。

**マスク保存**（NG 部分のみ置換）については、実装コストと UX を鑑み、
初版では採用しない方針とする。必要となった場合はテナント設定項目を追加し、
API 側の実装とあわせて本章を v1.1 以降で更新する。

---

## 8.6 ログ仕様と運用

### 8.6.1 `moderation_logs` の利用

AI モデレーションの結果は `moderation_logs` テーブルに記録する。
スキーマは既存定義に従い、本章では利用イメージのみ記載する。

* `content_type`: `"board_post"` / `"board_comment"` など
* `content_id`: 対象レコード ID（postId / commentId）
* `ai_score`: モデルから返る数値スコア
* `flagged_reason`: モデルが返す理由やカテゴリ（hate, harassment 等）
* `decision`: `allow` / `mask` / `block`（初版では `allow` / `block` を使用）
* `decided_by`: `system`（AI 判定） / 将来的に `human`（人手レビュー）
* `reviewed_by`: 人手レビューを行った管理者ユーザ ID（必要となった場合に使用）

BoardPostForm / BoardDetail からは `moderation_logs` を直接参照しない。
運用上の調査や、特定テナント・投稿に対する事後分析で利用する。

### 8.6.2 人手レビュー（将来拡張）

将来的に、人手によるモデレーション見直しワークフローを導入する場合、
管理者画面から `moderation_logs` を一覧表示し、`decision` を `allow` / `block` などに変更することで対応可能である。
その場合も BoardPostForm 側の挙動は変えず、バックエンドの判定ロジックと管理者画面側の仕様で完結させる。

---

## 8.7 障害時・タイムアウト時の扱い

AI モデレーション API がエラーまたはタイムアウトした場合の扱いは、掲示板の UX と安全性のバランスを考慮して次のように定める。

* Level 0: そもそもモデレーションを実行しないため影響なし。
* Level 1:

  * モデルエラー・タイムアウト時は **モデレーションなしで投稿を許可** する。
  * ログには「エラーにより判定できなかった」旨を残すことが望ましいが、実装はバックエンド側に委ねる。
* Level 2:

  * 初版では Level 1 と同様に「エラー時は投稿を許可」する方針とする。
    （掲示板が止まることを避けるため）
  * より厳格な運用が必要となった場合は、「エラー時は投稿をブロック」するオプションをテナント設定として追加し、本章を更新する。

BoardPostForm 側から見ると、「AI モデレーション障害」による特別なハンドリングは不要であり、
API から返却された通常の成功/失敗をそのまま扱えばよい。

---

## 8.8 メッセージ仕様との関係

AI モデレーションエラー時に BoardPostForm が表示する文言は、
ch05 "Messages and UI" にて i18n キーとともに定義する。
本章では、使用するメッセージ種別のみを列挙する。

* 送信時に AI モデレーションでブロックされた場合:

  * `board.postForm.error.submit.moderationBlocked`
* その他の送信エラー（ネットワーク・500 系等）とは別のメッセージキーとし、利用者に「内容の修正が必要」であることを示す。

具体的な日本語/英語/中国語の文言は、B-03 ch05 側で定義する。
BoardPostForm は errorCode とメッセージキーのマッピングだけを持ち、AI モデルやスコアの詳細を UI に出さない。

---

## 8.9 他章・他コンポーネントとのトレース

本章に記載した AI モデレーション仕様のトレース関係を整理する。

* 要件定義

  * `functional-requirements-all_v1.6.md`

    * 掲示板機能の安全性・抑止策に関する要件（AI モデレーション）
* 非機能要件

  * `Nonfunctional-requirements_v1.0.md`

    * 可用性・性能・運用制約（AI 障害時のフェイルセーフ方針）
* 技術スタック

  * `harmonet-technical-stack-definition_v4.4.md`

    * 利用する AI モデル/外部 API の候補、コスト方針
* 詳細設計

  * B-03 BoardPostForm ch01〜ch07

    * 投稿フロー・メッセージ仕様・テスト仕様
  * B-04 BoardTranslationAndTtsService ch01〜ch07

    * 翻訳/TTS サービス（AI モデレーションとは別機能）
  * B-02 BoardDetail ch01〜ch07

    * モデレーション済み投稿内容の表示のみを担当
* DB スキーマ

  * `schema.prisma` の `moderation_logs` / `moderation_decision` / `decision_source` 定義

本章 v1.0 は、現時点の要件・スキーマ・技術スタックに基づく初版定義である。
実装・運用の結果に応じて、レベル別動作・フェイルセーフ・マスク機能の有無等を見直す場合は、
本章を v1.1 以降に更新する。
