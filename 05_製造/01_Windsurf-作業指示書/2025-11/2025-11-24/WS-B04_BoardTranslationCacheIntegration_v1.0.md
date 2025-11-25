
````markdown
# WS-B04_BoardTranslationCacheIntegration_v1.0

**Task ID:** B04-BoardTranslation-Cache-Integration  
**Components:**  
- B-03 BoardPostForm（/board/new）  
- B-01 BoardTop（/board） ※翻訳表示部分のみ  
- B-02 BoardDetail（/board/[postId]） ※翻訳取得のみ  
**Task Name:** 掲示板投稿時の翻訳キャッシュ＋一覧／詳細での利用実装  
**担当AI:** Windsurf  

---

## 1. ゴール

1. 掲示板投稿フォームから投稿したときに、Google Translate API を呼び出し、  
   `board_post_translations` テーブルへ **JA→EN / JA→ZH** の翻訳結果をキャッシュする。  
2. BoardTop `/board` と BoardDetail `/board/[postId]` は、  
   現在の UI 言語に対応する `board_post_translations` を優先して利用し、  
   キャッシュが無い場合のみ日本語原文を表示する。  
3. ダミーデータに依存せず、**DB＋キャッシュ前提**の設計に揃える。

---

## 2. 前提

- 原文は日本語固定（`board_posts.content`）。  
- 翻訳対象言語は現状 EN (`en`), ZH (`zh`) の 2 種類とする。  
- Google Translate API 用のクライアント・環境変数は既に設定済みとする（未設定なら `.env` 名だけコメントに残す）。  
- `board_post_translations` スキーマ（抜粋）  
  - `id` (uuid), `tenant_id` (text), `post_id` (text), `lang` (text), `content` (text), `created_at`, `updated_at`

DB スキーマや RLS は **変更しない**。

---

## 3. サーバサイド翻訳サービスの実装

### 3.1 共通サービスモジュール

- 追加ファイル（例）  
  - `src/server/board/translationService.ts`

関数シグネチャ:

```ts
export async function translateAndCacheBoardPost(params: {
  tenantId: string;
  postId: string;
  baseLanguage?: 'ja';
  targetLanguages?: ('en' | 'zh')[];
}): Promise<void>;
````

処理概要:

1. `board_posts` から `postId` に該当するレコードを取得（`tenant_id`, `content`）。
2. `targetLanguages`（デフォルト `['en', 'zh']`）に対してループ。
3. 既に `board_post_translations` に同じ `(tenant_id, post_id, lang)` の行があればスキップ。
4. 無い場合のみ Google Translate API を呼び出し、翻訳した本文を `board_post_translations` に `insert`。
5. 失敗した言語はログ出力のみ（投稿自体は成功させる）。

例（疑似コード）:

```ts
for (const lang of langs) {
  const exists = await db
    .from('board_post_translations')
    .select('id')
    .eq('tenant_id', tenantId)
    .eq('post_id', postId)
    .eq('lang', lang)
    .maybeSingle();

  if (exists.data) continue;

  const translated = await callGoogleTranslateApi({
    text: baseContent,
    source: 'ja',
    target: lang,
  });

  await db
    .from('board_post_translations')
    .insert({
      tenant_id: tenantId,
      post_id: postId,
      lang,
      content: translated,
    });
}
```

`callGoogleTranslateApi` は既存の Google API クライアントに合わせて実装すること（ライブラリ・エンドポイントは既存コード参照）。

---

## 4. 投稿フローへの組み込み（/board/new）

### 4.1 投稿完了後に翻訳サービスを呼び出す

* 既存の投稿処理（BoardPostForm → API Route or server action）で、
  `board_posts` への insert が成功した直後に `translateAndCacheBoardPost` を呼ぶ。

例（サーバ側）:

```ts
const { tenantId, userId } = getAuthContext();

const post = await db.from('board_posts')
  .insert({
    tenant_id: tenantId,
    // ...その他フィールド
  })
  .select('id')
  .single();

translateAndCacheBoardPost({
  tenantId,
  postId: post.id,
}).catch((err) => {
  logger.error('board.translation.error', { tenantId, postId: post.id, error: err });
});
```

要件:

* 翻訳失敗は投稿をロールバックしない。
* 投稿 API のレスポンスは従来通り即座に返し、翻訳は async でよい。

フロント側（BoardPostForm）は、翻訳の成否を気にしなくてよい。

---

## 5. BoardTop での翻訳利用

### 5.1 データ取得時にキャッシュを同時取得

BoardTop のデータ取得処理（既存の `fetchBoardTopPage` 相当）がある前提とする。

* 変更箇所:

  * 現在の UI 言語 `currentLanguage` を受け取り、
    `currentLanguage !== 'ja'` のときだけ `board_post_translations` を join 取得する。

疑似 SQL:

```sql
select
  p.id,
  p.tenant_id,
  p.category_key,
  p.title,
  p.content as original_content,
  t.content as translated_content,
  t.lang    as translated_lang
from board_posts p
left join board_post_translations t
  on t.post_id   = p.id
 and t.tenant_id = p.tenant_id
 and t.lang      = :currentLanguage
where ...
order by p.created_at desc;
```

DTO:

```ts
type BoardPostSummary = {
  // ...
  contentPreview: string;        // 実際に表示するサマリ
  originalContentPreview: string;
  translatedContentPreview?: string;
  hasTranslation: boolean;
};
```

* `hasTranslation = !!translated_content`
* `contentPreview = translated_content ?? original_content`

### 5.2 UI 側

* 現在の UI 言語が `ja` 以外で、`hasTranslation = true` の場合
  → 最初から翻訳済みサマリを表示。
* 翻訳キャッシュが無い場合は従来通り日本語を表示し、「翻訳」ボタン（B-01 ch05）の UI を使う。
  リアルタイム翻訳ボタンは現状未実装でも構わない（キャッシュだけで最低限成立する）。

---

## 6. BoardDetail での翻訳利用（最低限）

B-02 BoardDetail のデータ取得でも、BoardTop と同じ考え方で `board_post_translations` を join し、

* `currentLanguage` 用の翻訳があれば本文としてそれを表示
* 無ければ日本語本文を表示し、「翻訳」ボタンで将来のオンデマンド翻訳に備える

ところまで入れておくと、TOP／詳細で挙動が揃う。

---

## 7. テスト / 受け入れ条件

### 7.1 テスト観点

1. `/board/new` から投稿 → 投稿成功後に `board_post_translations` を確認

   * 該当 `post_id` で `lang = 'en'` / `'zh'` の行が追加されている。
2. UI 言語 = JA で `/board`

   * 日本語サマリが表示される（従来通り）。
3. UI 言語 = EN で `/board`

   * 同じ投稿で、サマリが英訳されたテキストになっている。
   * `board_post_translations` に該当行が無い場合は日本語のまま。
4. UI 言語 = EN / ZH で `/board/[postId]`

   * キャッシュがあれば翻訳本文／無ければ日本語本文。

### 7.2 完了条件

* `npm run lint` / `npm run test` が成功。
* 上記テスト観点が手動確認で満たされている。
* `board_post_translations` に投稿後のデータが蓄積されていることを確認。
* CodeAgent_Report_B04-BoardTranslationCacheIntegration_v1.0.md を
  `/01_docs/06_品質チェック/` 配下に作成し、変更ファイル一覧と自己評価を記載する。

---

## 8. CodeAgent_Report 要件

* `agent_name: Windsurf`
* `task_id: B04-BoardTranslation-Cache-Integration`
* `attempt_count`, `self_score_overall`, `typecheck`, `lint`, `test`
* `changed_files`（翻訳サービス・投稿処理・BoardTop/Detail で触ったファイル一覧）
* `notes`（Google API 周りの制約・今後の改善案など）

本タスクは「翻訳キャッシュを作る／読む」までに限定し、
新しい UI ボタン・設定画面などは勝手に追加しないこと。


1. **原文言語の扱い**

   * 先の指示書: 「投稿時の UI 言語（currentLocale）＝原文言語」とみなす前提で説明していた。
   * いまの方針: 「Google の言語自動判定をベースにし、`ja/en/zh` 以外と判定された場合のみ UI 言語にフォールバック」。
   * ⇒ 最終仕様は「自動判定＋UI言語フォールバック」で統一する。

2. **翻訳対象言語の扱い**

   * 先の指示書の一部で、「source='ja' 固定」っぽく読める記述があった。
   * いまの方針: 「`ja/en/zh` のどれで書かれていても、**残り 2 言語**へ翻訳キャッシュを作る」。
   * ⇒ 最終仕様は「常に 3言語間相互翻訳（投稿言語＋残り2言語）」で統一する。

3. **BoardTop / BoardDetail と翻訳ボタン**

   * 方向性は一貫していて矛盾なし。

     * BoardTop: 「キャッシュ済み翻訳があれば使うだけ。翻訳ボタンは置かない」。
     * BoardDetail: 「翻訳ボタンを持つ唯一の画面。必要に応じて翻訳 API を叩いてキャッシュ生成／更新」。

上の 1 と 2 を直した「1枚もの」の統合指示は、WS には下記を渡せば足ります。

---

### WS-B04 向け・統合仕様（最終版）

#### 1. 前提

* 対応言語は **`ja` / `en` / `zh`** の 3 言語。
* 投稿本文の翻訳は **3言語どれに対しても対等** に行い、「日本語中心」ではない。
* 翻訳対象は **掲示板投稿のタイトル＋本文のみ**（UI ラベルは StaticI18nProvider 管理で別扱い）。

#### 2. 原文言語（sourceLang）の決め方

1. Google の言語判定（detect）で原文言語を自動判定する。
2. 判定結果が `ja` / `en` / `zh` のいずれかであれば、それを `sourceLang` として採用する。
3. 判定結果がそれ以外 or 失敗した場合は、**投稿時の UI 言語（currentLocale）を `sourceLang` として使う**。

擬似コード:

```ts
const SUPPORTED_LANGS = ['ja', 'en', 'zh'] as const;

async function resolveSourceLang(textForDetect: string, uiLocale: 'ja'|'en'|'zh') {
  try {
    const detected = await detectLanguage(textForDetect); // Google Detect
    if (detected && SUPPORTED_LANGS.includes(detected as any)) {
      return detected as 'ja'|'en'|'zh';
    }
  } catch {}
  return uiLocale;
}
```

#### 3. 翻訳対象言語（targetLangs）

* `sourceLang` が決まったら、**3言語のうち `sourceLang` を除いた残り2言語**を `targetLangs` とする。

```ts
const allLangs = ['ja', 'en', 'zh'] as const;
const targetLangs = allLangs.filter(l => l !== sourceLang);
```

* 各 `targetLang` に対して、タイトル＋本文を翻訳し
  `board_post_translations(tenant_id, post_id, lang, title, content)` に upsert する。

#### 4. BoardTop での利用

* `/api/board/posts` の GET で、`board_posts` と `board_post_translations` をまとめて返す。

  ```ts
  type BoardPostTranslationDto = {
    lang: 'ja'|'en'|'zh';
    title: string | null;
    content: string;
  };

  type BoardPostSummaryDto = {
    // ...
    originalTitle: string;
    originalContent: string;
    translations: BoardPostTranslationDto[];
  };
  ```

* BoardTopPage 側では:

  1. `currentLocale`（`ja/en/zh`）を取得
  2. `translation = translations.find(tr => tr.lang === currentLocale)`
  3. タイトル: `translation?.title ?? originalTitle`
  4. 本文サマリ: `translation?.content ?? originalContent`

* **BoardTop には翻訳ボタンは置かない**。
  「キャッシュがあれば翻訳表示／無ければ原文表示」に徹する。

#### 5. BoardDetail と翻訳ボタン

* B04 のスコープでは、**翻訳付きで 1件取得するサーバ関数**だけ用意しておく。

  ```ts
  // 例: src/server/board/getBoardPostById.ts
  export async function getBoardPostById(params: { tenantId: string; postId: string; currentUserId: string; })
    : Promise<BoardPostSummaryDto | null> { ... }
  ```

* `/board/[postId]` の UI と「翻訳ボタン押下 → 再翻訳＆キャッシュ更新」の実装は **別タスク** とし、
  B04 時点では「将来 BoardDetail から流用できる取得 API／サーバ関数を整える」ところまでで良い。

---

