# HarmoNet テナント静的翻訳テーブル案（草案）

## 1. 方針整理

* **共通 i18n ファイル（common.json）**

  * 利用範囲を **ヘッダ／フッタなどのグローバル共通 UI のみ** に限定する。
  * 画面固有の文言は `common.json` には入れない。
* **画面固有の静的文言**

  * すべて **テナント単位で DB テーブル管理** する。
  * 言語は HarmoNet の前提どおり **JA / EN / ZH の 3 固定** とし、カラムで持つ。
* **テナント作成時の挙動**

  * システム全体の「デフォルト静的文言」を別テーブルに持つ。
  * 新規テナント作成時に、デフォルトテーブルから **そのテナント専用コピー** を `tenant_id` 紐づきで生成する。
  * 以降の画面表示は常に「テナント側テーブル」から取得する（default はあくまでテンプレート）。

---

## 2. テーブル構成案

### 2.1 デフォルト静的翻訳テーブル

システム全体の「標準文言」を持つテンプレート。テナントと無関係に 1 セットだけ存在する。

```prisma
model static_translation_defaults {
  id          String   @id @default(uuid())
  screen_key  String   // 例: "login", "board.top", "facility.detail"
  message_key String   // 例: "title", "description", "button.submit"
  text_ja     String   @db.Text
  text_en     String   @db.Text
  text_zh     String   @db.Text
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt

  @@unique([screen_key, message_key])
}
```

* `screen_key`

  * 画面／コンポーネント単位のキー。
  * 例）`"login"`, `"board.top"`, `"board.detail"`, `"facility.detail"` など。
* `message_key`

  * その画面内の文言を一意に識別するキー。
  * 例）`"title"`, `"description"`, `"button.submit"`, `"label.email"` など。
* `text_ja` / `text_en` / `text_zh`

  * 3 言語分の文言を 1 レコードにまとめて保持。
* `@@unique([screen_key, message_key])`

  * 1 画面＋1メッセージキーに対して 1 レコードのみ。
  * 言語はカラム固定なので、複合ユニークはこれで十分。

### 2.2 テナント静的翻訳テーブル

各テナントが実際に利用する文言セットを保持するテーブル。テナント作成時に `static_translation_defaults` からコピーする。

```prisma
model tenant_static_translations {
  id          String   @id @default(uuid())
  tenant_id   String
  screen_key  String
  message_key String
  text_ja     String   @db.Text
  text_en     String   @db.Text
  text_zh     String   @db.Text
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt
  status      status   @default(active)

  tenant tenants @relation(fields: [tenant_id], references: [id])

  @@unique([tenant_id, screen_key, message_key])
  @@index([tenant_id])
}
```

* `tenant_id`

  * `tenants.id` への外部キー。
  * 1 テナントごとにフルセットの文言を持つ前提。
* `screen_key` / `message_key`

  * default と同じキー体系。
* `status`

  * `status` enum（既存）を利用。
  * 通常は `active` 固定想定。
* `@@unique([tenant_id, screen_key, message_key])`

  * テナント＋画面＋メッセージキーで 1 レコードのみ。
* 利用時は `tenant_id` と選択言語（JA/EN/ZH）に応じてカラムを選択して表示する。

---

## 3. テナント作成時のコピー処理

### 3.1 基本方針

* 新規テナント作成直後に、1 回だけ下記の INSERT を実行する。
* これにより **その時点の default セットを丸ごとコピー** し、その後はテナントごとに自由に編集可能とする。

### 3.2 Supabase Studio 用 SQL サンプル

`{NEW_TENANT_ID}` を実際の `tenants.id` に置き換えて実行する想定。

```sql
INSERT INTO tenant_static_translations (
  id,
  tenant_id,
  screen_key,
  message_key,
  text_ja,
  text_en,
  text_zh,
  created_at,
  updated_at,
  status
)
SELECT
  gen_random_uuid() AS id,
  '{NEW_TENANT_ID}' AS tenant_id,
  screen_key,
  message_key,
  text_ja,
  text_en,
  text_zh,
  now()             AS created_at,
  now()             AS updated_at,
  'active'          AS status
FROM static_translation_defaults;
```

* 初期テナント（自分のマンション）については、上記をそのまま流せばよい。
* 将来的に「テナント作成 API」を用意する場合は、同等の処理を API 側（Prisma or SQL）に組み込む。

---

## 4. 画面側からの利用イメージ

### 4.1 取得クエリ（概念）

言語と `tenant_id`、`screen_key` が分かっている前提。

```sql
SELECT message_key,
       text_ja,
       text_en,
       text_zh
FROM tenant_static_translations
WHERE tenant_id = $1
  AND screen_key = $2
  AND status = 'active';
```

Next.js 側では、上記結果を `Record<message_key, { ja, en, zh }>` か、現在の UI 言語に応じて `Record<message_key, text>` に変換してコンポーネントに渡す。

### 4.2 コンポーネント側

例）`LoginPage` の場合：

```ts
// 型イメージ
interface ScreenMessages {
  [messageKey: string]: {
    ja: string;
    en: string;
    zh: string;
  };
}

// UI 言語に応じて切り替え
function getText(msgs: ScreenMessages, key: string, lang: 'ja' | 'en' | 'zh') {
  const m = msgs[key];
  if (!m) return '';
  if (lang === 'en') return m.en;
  if (lang === 'zh') return m.zh;
  return m.ja;
}
```

* ヘッダ／フッタの共有文言だけ `common.json` を継続利用。
* 画面固有の文言は、すべて `tenant_static_translations` 経由で取得して利用する。

---

## 5. 補足・検討メモ

* **編集 UI**

  * 将来的にテナント管理画面から文言編集を許可する場合、`tenant_static_translations` だけを対象にする。
  * default テーブルはシステム用テンプレートとして、人間が直接 Studio で触る想定。
* **fallback 戦略**

  * MVP では「tenant 側にレコードがある前提」で進める。
  * fallback（tenant にない場合 default を見る）は、必要になったときに検討（現時点では不要）。
* **キー命名規約**

  * `screen_key` / `message_key` の命名規約は、別途 UI 詳細設計 or i18n ガイドラインで定義する。
  * 例：`screen_key = "login"`, `message_key = "form.title"`, "form.button.submit" など。
