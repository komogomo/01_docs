# B-03 BoardPostForm 詳細設計書 ch08 AIモデレーション仕様 v1.1

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH08
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-23
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 8.1 本章の目的

本章では、掲示板投稿フォームコンポーネント **B-03 BoardPostForm** において利用する **AI モデレーション機能** の仕様を定義する。

BoardPostForm は、掲示板投稿画面における「新規投稿」「投稿編集（再投稿）」などのフォーム入力・バリデーション・確認ダイアログ表示を担当するフロントエンドコンポーネントであり、
投稿内容そのものの適切性チェック（誹謗中傷・差別的表現・暴力的な表現など）は、本章で定義する AI モデレーション機能によって行う。

本章は、以下を目的とする。

1. BoardPostForm から見た AI モデレーションの役割とスコープを明確にする。
2. テナント設定（有効/無効・レベル別挙動）と投稿フローへの組み込み方法を定義する。
3. AI モデレーションログのデータモデルと、BoardPostForm が依存する振る舞いを整理する。
4. Windsurf による実装時に、バックエンド API 実装と整合が取れる「最下層の論理仕様」として機能すること。

なお、本章は **B-03 BoardPostForm** 視点の仕様であり、
AI モデレーションの実装詳細（AI モデル選定・プロンプト設計・インフラ構成）は Back-end 実装チーム/技術スタック定義に委譲する。
ただし、BoardPostForm の動作に影響するインターフェースと挙動は本章で固定する。

---

## 8.2 AIモデレーションの全体像

### 8.2.1 目的と位置づけ

AI モデレーションの目的は、掲示板の投稿・コメントに含まれる不適切な内容を抑止し、
住民トラブルの発生を未然に防ぐことである。ここでいう不適切な内容とは、主に以下のようなカテゴリを想定する。

* 差別的・ヘイト的な表現（人種・国籍・宗教・性別などに対する攻撃）
* 過度な誹謗中傷・ハラスメント
* 暴力・自傷行為・違法行為の助長
* 性的に不適切な表現（特に未成年に関わるもの）

HarmoNet における AI モデレーションは、以下の方針を取る。

* 法務レベルの厳密なコンプライアンスチェックではなく、
  **「住民向け掲示板として明らかに問題がある投稿を事前に抑止する」ライトな抑止策** として設計する。
* 完全な自動削除ではなく、テナント設定でレベル（0〜2）を選択可能とし、
  テナントごとに「どの程度まで AI 判定に任せるか」をコントロールできるようにする。
* モデレーション結果は `moderation_logs` テーブルに記録し、
  後からの調査・チューニングに利用できるようにする。

### 8.2.2 BoardPostForm との関係

BoardPostForm は、**投稿内容を収集し API に送信するフロントエンド** であり、
AI モデレーションロジック（AI モデル呼び出し・スコア判定・ログ保存）は **すべて API 側（サーバ側）** に実装する。

BoardPostForm の責務は次のとおりとする。

* 利用者からタイトル・本文・添付ファイル等を入力として受け取る。
* 画面ローカルのバリデーション（必須項目チェック・文字数制限など）を行う。
* 確認ダイアログ（プレビュー）を表示し、ユーザの投稿確定操作を受け取る。
* 投稿 API（例: `/api/board/posts`）を呼び出し、そのレスポンスに応じて

  * 成功時: 詳細画面への遷移または成功メッセージ表示
  * 失敗時: エラーメッセージ表示（その一部として「AI モデレーションによるブロック」も含まれる）

AI モデレーションに関して BoardPostForm が知る必要があるのは **結果の種別** のみであり、
AI モデルやスコアリング方式には依存しないように設計する。

---

## 8.3 テナント設定とレベル別挙動

### 8.3.1 テナント設定キー

AI モデレーションの有効/無効および挙動レベルは、テナント単位の設定値として管理する。
設定値は `tenant_settings.config_json`（もしくは同等の設定テーブル）に JSON として格納し、
掲示板 API 側から参照可能とする。

想定する設定キーは以下のとおり。

* `board.moderation.enabled: boolean`

  * AI モデレーション機能の有効/無効を表す。
  * 既定値: `true`
* `board.moderation.level: 0 | 1 | 2`

  * レベル 0: ログのみ（投稿の可否や UI 挙動には一切影響させない）
  * レベル 1: ソフトモデレーション（mask: 警告＋伏字投稿）
  * レベル 2: ストロングモデレーション（block: 投稿拒否）

設定 UI はテナント管理画面（掲示板設定タブ）で提供する。
詳細は管理者画面の詳細設計で定義し、本章では「設定値が API から参照可能である」前提のみを記載する。

### 8.3.2 レベル別の基本方針（改訂）

AI モデレーションは、AI モデルから返却される `ai_score` およびカテゴリ情報をもとに
内部的な論理判定 `decision: "allow" | "mask" | "block"` を行い、テナント設定 `level` と組み合わせて次のように振る舞う。

- Level 0（ログのみ）  
  - モデレーションは実行するが、投稿の可否や UI には一切影響させない。  
  - `decision` にかかわらず投稿はそのまま保存し、`moderation_logs` にのみ記録する。

- Level 1（mask: 警告＋伏字投稿）  
  - `decision = "allow"` の場合は投稿をそのまま保存する。  
  - `decision = "mask"` の場合は、  
    - 投稿は即保存せず、伏字済みテキストを含むエラー応答（`errorCode = "ai_moderation_masked"`）を返す。  
    - フロント側で「不適切な表現が含まれる可能性があります」警告とともに、伏字済みテキストをフォームに反映する。  
    - ユーザが「この伏字済み内容で投稿」を選択し、`forceMasked = true` で再投稿した場合のみ、伏字済みテキストのまま保存する。  
  - `decision = "block"` の場合は Level 2 と同等に扱い、投稿をブロックする（安全側）。

- Level 2（block: 投稿拒否）  
  - `decision = "allow"` の場合は投稿をそのまま保存する。  
  - `decision = "mask"` または `decision = "block"` の場合は、投稿を保存せず `errorCode = "ai_moderation_blocked"` で応答する。  
  - フロント側では内容をフォームに残しつつ、「AI モデレーションでブロックされた」旨のメッセージを表示し、ユーザに修正を促す。

### 8.3.3 AI モデレーション API（OpenAI）

本システムの AI モデレーション判定は、**OpenAI の Moderation API** を利用して実装する。

* 利用エンドポイント: `POST https://api.openai.com/v1/moderations`
* 利用モデル: `omni-moderation-latest`
* 認証方式: OpenAI API キー（バックエンドの秘密情報として `.env` 等に保持し、フロントエンドには露出させない）

#### 入力フォーマット

Moderation API には、次の内容を 1 つの文字列として連結して送信する。

* 投稿タイトル
* 投稿本文（必須）
* コメント本文（コメント投稿の場合）

例（実装イメージ）:

```ts
const input = [
  title && `Title: ${title}`,
  body && `Body: ${body}`,
  comment && `Comment: ${comment}`,
]
  .filter(Boolean)
  .join("\n\n");
```

API には次のようなペイロードで送信する。

```json
{
  "model": "omni-moderation-latest",
  "input": "連結済みの投稿テキスト..."
}
```

#### 出力と HarmoNet でのマッピング

Moderation API は、カテゴリごとのフラグおよびスコアを返す。

主なフィールド（要約）:

* `results[0].categories.{hate, harassment, self-harm, sexual, violence, ...}`: true/false
* `results[0].category_scores.{hate, harassment, ...}`: 0.0〜1.0 のスコア
* `results[0].flagged`: いずれかのカテゴリで問題ありと判定された場合に true

HarmoNet 側では、以下のルールで `moderation_logs` の項目にマッピングする。

* `ai_score`:

  * `category_scores` のうち **最大値** を格納する。
* `flagged_reason`:

  * 最大スコアとなったカテゴリ名（例: `"harassment"`, `"hate"`, `"self-harm"` 等）を保存する。
  * 後続の分析のため、必要に応じて複数カテゴリをコンマ区切りで保存してもよい（実装側判断）。
* `decision`:

  * 8.3.2 で定義した low / medium / high のレベル判定ロジックに基づき、
    `allow` / `mask` / `block` のいずれかを設定する。
* `decided_by`:

  * AI 自動判定の場合は `system` を設定する。

#### スコアしきい値とレベル判定

* OpenAI Moderation API のカテゴリとスコア定義は OpenAI 側仕様に従う。

* HarmoNet 側では、最大スコア `ai_score` に対してしきい値を定義し、次のように分類する。

  * `ai_score < T_low`   → low
  * `T_low <= ai_score < T_high` → medium
  * `T_high <= ai_score` → high

* `T_low` / `T_high` の具体値は Back-end 実装側の内部設定とし、
  本章では「low / medium / high の 3段階を用いて Level 0/1/2 の挙動を制御する」という論理仕様のみを定義する。

しきい値やカテゴリの扱いは、OpenAI モデルのバージョンアップや運用結果に応じて
バックエンド実装の設定値を調整可能とし、BoardPostForm 側の仕様には影響しないようにする。

---

## 8.4 投稿・コメントフローへの組み込み

### 8.4.1 新規投稿（board_posts INSERT）

1. 利用者が BoardPostForm にタイトル・本文等を入力し、「投稿」ボタンを押下する。

2. BoardPostForm は、既存どおり `/api/board/posts`（仮）へ POST リクエストを送信する。

3. API はテナント設定を参照し、`board.moderation.enabled` が `true` の場合に AI モデレーションを実行する。

4. AI モデルから `ai_score` と `flagged_reason` が返却される。

5. API は `ai_score` をもとに low/medium/high を判定し、レベル設定（0/1/2）に応じて以下のいずれかを行う。

   * Level 0:
     * `decision`（allow / mask / block）にかかわらず投稿を保存する。
     * AI モデレーション結果は `moderation_logs` にのみ記録し、UI 挙動には影響させない。

   * Level 1:
     * `decision = "allow"` の場合は、そのまま投稿を保存する。
     * `decision = "mask"` の場合は、本文中の不適切表現を `***` に置き換えた
       `maskedTitle` / `maskedContent` を生成し、
       `400 Bad Request` +  
       `{"errorCode":"ai_moderation_masked","maskedTitle":"...","maskedContent":"..."}` を返す
       （この時点では投稿は保存しない）。
     * `decision = "block"` の場合は、Level 2 と同様に投稿を保存せず
       `400 Bad Request` + `{"errorCode":"ai_moderation_blocked"}` を返す。

   * Level 2:
     * `decision = "allow"` の場合のみ投稿を保存する。
     * `decision = "mask"` または `decision = "block"` の場合は投稿を保存せず、
       `400 Bad Request` + `{"errorCode":"ai_moderation_blocked"}` を返す。

6. API は結果に応じて適切な HTTP ステータスとレスポンスボディを返却する。

   * 正常保存時: `201 Created` + `postId` 等
   * Level 2 でブロックした場合: `400 Bad Request`（もしくは `409 Conflict`） + エラーコード（例: `"ai_moderation_blocked"`）

7. BoardPostForm は、レスポンスに応じて次のように振る舞う。

   * 正常保存時: 詳細画面（B-02 BoardDetail）への遷移、または成功メッセージ表示。
   * モデレーションブロック時: `errorCode` を参照し、`board.postForm.error.submit.moderation.blocked` などの i18n キーに対応する
     メッセージを画面上部またはフォーム下部に表示する。

BoardPostForm は **エラー種別を i18n キーで識別する** だけであり、
AI スコアの詳細やカテゴリ名は、画面上では直接扱わない（モデレーション理由の表示が必要になった場合は、別途仕様追加とする）。

### 8.4.2 コメント投稿（board_comments INSERT）

コメント投稿時も、新規投稿と同様に API 側で AI モデレーションを実行する。

1. 利用者がコメント入力欄に本文を入力し、「コメント投稿」ボタンを押下する。
2. フロントエンドは `/api/board/comments`（仮）へ POST リクエストを送信する。
3. API はテナント設定を参照し、`board.moderation.enabled` が `true` の場合に AI モデレーションを実行する。
4. AI モデルからのスコアに基づき、投稿保存 / ブロックの判断を行う。
5. API は `ai_score` から low/medium/high を判定し、Level と組み合わせて  
   `decision: "allow" | "mask" | "block"` を決定する。

6. `decision` と `level` に応じて以下のように振る舞う。

   - Level 0: `decision` に関わらずそのまま投稿を保存する。  
   - Level 1:
     - `decision = "allow"` の場合は投稿を保存する。
     - `decision = "mask"` の場合は、伏字済みテキストを生成し、`400` +  
       `{"errorCode":"ai_moderation_masked","maskedTitle":"...","maskedContent":"..."}` を返す（投稿はまだ保存しない）。
     - `decision = "block"` の場合は Level 2 と同様に投稿を保存せず `400` + `{"errorCode":"ai_moderation_blocked"}` を返す。
   - Level 2:
     - `decision = "allow"` の場合のみ投稿を保存する。
     - `decision = "mask"` / `"block"` の場合は投稿を保存せず `400` + `{"errorCode":"ai_moderation_blocked"}` を返す。

7. BoardPostForm はレスポンスに応じて次のように振る舞う。

   - 正常保存時: 詳細画面（B-02）への遷移、または成功トースト表示。
   - `errorCode = "ai_moderation_masked"` の場合:
     - フォーム上部に警告を表示し（`board.postForm.error.submit.moderation.masked`）、  
       `maskedTitle` / `maskedContent` をタイトル・本文に反映する。
     - 「修正して投稿」と「この伏字済み内容で投稿」の 2 ボタンを表示し、後者の場合のみ  
       `forceMasked = true` を付与して再投稿する。
   - `errorCode = "ai_moderation_blocked"` の場合:
     - 既存どおり、内容はフォームに残したままブロックメッセージを表示し、ユーザに内容修正を促す。


コメント投稿の UI/UX は B-02 BoardDetail の詳細設計にて定義し、
本章では「コメントも投稿同様に AI モデレーション対象である」ことと、
エラーコードの扱いが投稿と揃うことのみを規定する。

---

## 8.5 データモデル（moderation_logs）

AI モデレーションの結果は、Supabase/PostgreSQL 上の `moderation_logs` テーブルに記録する。
スキーマは `schema.prisma` で定義されており、本章では BoardPostForm から見た利用方法を整理する。

### 8.5.1 スキーマ概要

```prisma
enum moderation_decision {
  allow
  mask
  block
}

enum decision_source {
  system
  human
}

model moderation_logs {
  id             String              @id @default(uuid())
  tenant_id      String
  content_type   String              // "board_post", "board_comment" など
  content_id     String              // 対象レコードID
  ai_score       Decimal             @db.Decimal(5, 2) // 0.00〜1.00 程度のスコア
  flagged_reason String              @db.Text
  decision       moderation_decision @default(allow)
  decided_by     decision_source     @default(system)
  decided_at     DateTime            @default(now())
  reviewed_by    String?

  tenant   tenants @relation(fields: [tenant_id], references: [id])
  reviewer users?  @relation(fields: [reviewed_by], references: [id])
}
```

### 8.5.2 BoardPostForm から見た利用前提

* BoardPostForm 自体は `moderation_logs` テーブルを直接参照しない。
* `moderation_logs` は、API（Back-end）側でのみ読み書きする。
* BoardPostForm に返却されるのは、あくまで

  * 投稿 API の成功/失敗
  * 必要に応じたエラーコード（例: `"ai_moderation_blocked"`）
    のみである。
* 分析・運用改善・管理者画面での閲覧は、別途「モデレーションログ管理」機能で扱う。

BoardPostForm の実装では、`moderation_logs` の存在を意識する必要はなく、
「AI モデレーションにより投稿がブロックされたかどうか」をエラーコードで判定できれば十分とする。

---

## 8.6 エラーメッセージと i18n

### 8.6.1 エラー種別

AI モデレーションに起因する代表的なエラー種別は以下のとおりとする。

1. `ai_moderation_masked`

   - 意味: AI モデレーションにより一部不適切な表現が検出され、伏字済みテキストへの変更が必要と判断された。  
   - 発生箇所: 投稿 API（Level 1 のみ）  
   - BoardPostForm 側の挙動:
     - フォーム上部に警告メッセージ（`board.postForm.error.submit.moderation.masked`）を表示する。
     - レスポンスで受け取った `maskedTitle` / `maskedContent` をフォームのタイトル・本文に反映する。
     - 「修正して投稿」「この伏字済み内容で投稿」の 2 種ボタンを表示し、後者の再送では `forceMasked: true` を付与する。

2. `ai_moderation_unavailable`（オプション）

   * 意味: AI モデレーション API の通信エラー・タイムアウトなどにより、モデレーション結果を取得できなかった。
   * 発生箇所: 投稿 API / コメント投稿 API
   * 振る舞い（例）:

     * Level 1: モデレーション無しで許可（警告ログのみ）
     * Level 2: 投稿を拒否し、「しばらく待ってから再度お試しください」メッセージを返す
   * 実際の挙動は非機能要件・運用方針に依存するため、Back-end 実装で決定する。

### 8.6.2 i18n キー例

AI モデレーション関連のメッセージは、共通 i18n 辞書（例: `board.json`）に定義する。

例:

```json
{
  "postForm": {
    "error": {
      "submit": {
        "moderation": {
          "blocked": "投稿内容に不適切な表現が含まれている可能性があります。内容を修正して再度投稿してください。",
          "masked": "不適切な表現が含まれる可能性があります。伏字済みの内容を確認し、必要に応じて修正してから投稿してください。",
          "unavailable": "現在、投稿内容のチェックが利用できません。しばらくしてから再度お試しください。"
        }
      }
    }
  }
}

```

英語版・中国語版の文言も同様のキー構造で定義する。
BoardPostForm は既存のエラーハンドリングフローの中で、エラーコードに応じて適切な i18n キーを選択するだけとする。

---

## 8.7 関連ドキュメント

* B-03 BoardPostForm 詳細設計書

  * ch01 Overview
  * ch02 Layout
  * ch03 DataModel
  * ch04 Logic
  * ch05 Messages & UI
  * ch06 Test & Quality
  * ch07 References & Traceability

* 関連コンポーネント

  * B-02 BoardDetail 詳細設計

    * モデレーション結果を反映した投稿表示（将来的に「マスク表示」等を導入する場合）
  * 管理者画面（テナント設定・モデレーションログ閲覧）

    * AI モデレーション ON/OFF・レベル設定 UI
    * moderation_logs の参照 UI（将来的な要件として検討）

* 参照スキーマ

  * `schema.prisma`

    * `moderation_logs` テーブル
    * `moderation_decision` / `decision_source` enum

---

本章は、Windsurf を含む実装エージェントが BoardPostForm および掲示板投稿 API を実装する際の
「AI モデレーションに関する最下層の論理仕様」として機能することを目的とする。

* BoardPostForm は、AI モデレーションの存在を「エラーコードとメッセージ表示」という形でのみ意識する。
* AI モデルの選定・スコアリング・ログ分析は Back-end 実装および運用側の責務とし、
  本章ではインターフェースとレベル別の挙動のみを規定する。

本章 v1.1 は、AI モデレーション API として OpenAI Moderation API (`omni-moderation-latest`) を利用する方針を明示した改訂版であり、
将来的にプロバイダやモデルが変更される場合は、本章の該当箇所を更新したうえで Back-end 実装の設定を調整する。

---

## 8.8 Back-end 実装モジュール構成

本節では、Windsurf 等の実装エージェントが迷わないよう、Back-end 側でのファイル構成および
関数インターフェースの最小限の指針を定義する。ここで定義するパスは Next.js App Router 構成を前提とする。

### 8.8.1 ファイル構成

AI モデレーション関連の実装は、少なくとも以下の 2 レイヤに分離する。

1. **サービス層（ドメインロジック）**

   * `src/server/services/moderationService.ts`

     * OpenAI Moderation API 呼び出しと `moderation_logs` へのマッピングを担当する。

2. **API Route 層（HTTP I/F）**

   * `src/app/api/board/posts/route.ts`
   * `src/app/api/board/comments/route.ts`

     * BoardPostForm / コメント投稿コンポーネントからの HTTP リクエストを受け付け、
       テナント設定の取得・AI モデレーション実行・DB 永続化・HTTP ステータス／`errorCode` 返却を担当する。

### 8.8.2 moderationService インターフェース

`src/server/services/moderationService.ts` には、少なくとも以下の関数を定義する。

```ts
// OpenAI Moderation API を呼び出す低レベル関数
export async function callOpenAiModeration(input: string): Promise<OpenAiModerationResult>;

// OpenAI 応答とテナント設定から論理上の判定結果を得る関数
export function decideModeration(
  result: OpenAiModerationResult,
  tenantConfig: TenantModerationConfig
): {
  decision: "allow" | "mask" | "block";
  aiScore: number; // 0〜1 範囲を想定
  flaggedReason: string; // 最大スコアカテゴリ名
};

// moderation_logs への永続化を行う関数
export async function saveModerationLog(params: {
  tenantId: string;
  contentType: "board_post" | "board_comment";
  contentId: string; // 投稿保存後の ID、ブロック時は一時 ID など実装側で定義
  decision: "allow" | "mask" | "block";
  aiScore: number;
  flaggedReason: string;
}): Promise<void>;
```

* `OpenAiModerationResult` 型は、`/v1/moderations` 応答のうち必要なフィールドのみを保持する内部型とする。
* `TenantModerationConfig` 型は、`board.moderation.enabled` / `board.moderation.level` などを含む構造体とする。
* しきい値 `T_low` / `T_high` の具体値は `decideModeration` 内部で完結させ、BoardPostForm 側からは見えないようにする。

これらの関数は純粋な TypeScript モジュールとして実装し、React/JSX には依存させない。

### 8.8.3 API Route からの呼び出しフロー

`src/app/api/board/posts/route.ts`（新規投稿 API）の実装フローは、概ね以下とする。

1. 認証済みユーザ／テナント情報を取得する。
2. リクエストボディからタイトル・本文・添付情報を取得し、ドメインバリデーションを行う。
3. テナント設定（`TenantModerationConfig`）を取得する。
4. テナント設定が Level 0 の場合も、AI モデレーションは実行する。

   * 投稿テキストを組み立てて `callOpenAiModeration` を実行する。
   * 応答を `decideModeration` に渡し、`decision` / `aiScore` / `flaggedReason` を取得する。
   * 結果を `saveModerationLog` で永続化する。
   * `decision` の値にかかわらず、そのまま投稿を保存し `201 Created` を返却する
     （Level 0 ではログ用途のみであり、投稿挙動には影響させない）。

5. テナント設定が Level 1 または Level 2 の場合:

   * 投稿テキストを組み立てて `callOpenAiModeration` を実行する。
   * 応答を `decideModeration` に渡し、`decision` / `aiScore` / `flaggedReason` /
     `maskedTitle` / `maskedContent` を取得する。
   * 結果を `saveModerationLog` で永続化したうえで、`decision` と Level に応じて次のように振る舞う。

     * Level 1:
       * `decision = "allow"`:
         * 通常どおり投稿を保存し、`201 Created` を返却する。
       * `decision = "mask"`:
         * 投稿は保存せず、`400 Bad Request` +  
           `{"errorCode":"ai_moderation_masked","maskedTitle":"...","maskedContent":"..."}` を返却する。
       * `decision = "block"`:
         * 投稿を保存せず、`400 Bad Request` + `errorCode = "ai_moderation_blocked"` を返却する。

     * Level 2:
       * `decision = "allow"`:
         * 通常どおり投稿を保存し、`201 Created` を返却する。
       * `decision = "mask"` または `decision = "block"`:
         * 投稿を保存せず、`400 Bad Request` + `errorCode = "ai_moderation_blocked"` を返却する。

`src/app/api/board/comments/route.ts`（コメント投稿 API）も同様に、
BoardDetail のコメント投稿 UX に合わせたフローの中で上記サービス関数を利用する。

### 8.8.4 環境変数と秘密情報

OpenAI API キーは、常に環境変数経由で取得する。

* 変数名（推奨）: `OPENAI_API_KEY`
* 取得例:

```ts
const openAiApiKey = process.env.OPENAI_API_KEY;
if (!openAiApiKey) {
  throw new Error("OPENAI_API_KEY is not set");
}
```

* `.env.local` 等で開発用キー（例: `harmonet-dev`）、本番環境の環境変数で本番用キー（例: `harmonet-prod`）を設定する。
* キーをファイルとしてアプリケーションに送信したり、クライアントサイドに露出させてはならない。
* OpenAI 側のプロジェクトやサービスアカウントの詳細な運用ルールはインフラ設計に委譲し、
  本章では「Back-end から `OPENAI_API_KEY` を用いて Moderation API を呼び出す」という前提のみを規定する。

---

本節で定義したモジュール構成と関数インターフェースにより、
Windsurf 等の実装エージェントは BoardPostForm / コメント投稿ロジックを実装する際、
AI モデレーションに関する実装を `moderationService` に集約しつつ、
BoardPostForm 側では `errorCode` ベースの単純なエラーハンドリングに専念できる。
