# HomePage 詳細設計書 ch04：データ連携・状態管理

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 4 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 4.1 本章の目的

本章では、HomePage（/home）における **お知らせセクションと機能タイルのデータ連携・状態管理方針** を定義する。

* MVP 段階：ダミーデータ／静的定義のみで実装する。
* 将来：Supabase 連携・テナント設定連携により動的化する前提とする。

HomePage 自体は認証・RLS ロジックを持たず、「すでに認証済みの利用者に対して、表示可能なデータだけが渡ってくる」前提で設計する。

---

## 4.2 データフロー概要

### 4.2.1 HomePage 全体のデータフロー

HomePage におけるデータフローは、MVP 段階では次のように単純化する。

1. `/app/home/page.tsx` 内で、ダミーのお知らせ配列 `MOCK_HOME_NOTICE_ITEMS` を定義する。
2. 同様に、機能タイル定義 `HOME_FEATURE_TILES` を静的配列として定義する。
3. `HomePage` コンポーネントは、これらの定数を `HomeNoticeSection` / `HomeFeatureTiles` に Props として渡す。
4. 各コンポーネントは、受け取ったデータをそのまま描画に用い、内部で追加のデータ取得は行わない。

将来的に Supabase 連携を行う際は、

* サーバコンポーネント（`page.tsx`）で Supabase クエリを実行し、`HomeNoticeItem[]` にマッピングした上で子コンポーネントに渡す、
* もしくは、専用の hooks / service 関数を用いてクライアント側で取得する、

のいずれかの方針を取ることを想定するが、本章では構造のみを定義し、実装方式の詳細は扱わない。

---

## 4.3 お知らせセクションのデータ管理

### 4.3.1 MVP：ダミーデータ

MVP 実装では、Supabase との連携を行わず、HomePage 内で定義したダミーデータを使用する。

```ts
// app/home/page.tsx 付近を想定

const MOCK_HOME_NOTICE_ITEMS: HomeNoticeItem[] = [
  {
    id: 'notice-1',
    title: '共用部分清掃のお知らせ（11/25 実施）',
    publishedAt: '2025/11/20',
  },
  {
    id: 'notice-2',
    title: 'エレベーター点検のお知らせ（12/05 実施）',
    publishedAt: '2025/11/18',
  },
  // 3件目以降は必要に応じて追加
];
```

* ダミーデータは、あくまで UI 確認用であり、本番運用時には Supabase 連携に差し替える。
* `publishedAt` は表示用文字列とし、日付フォーマット処理は行わない。

### 4.3.2 将来：Supabase 連携の想定

将来的に Supabase から NOTICE タグ付き掲示を取得する際の想定フローを示す。

1. `board_posts` テーブルから、対象テナントの NOTICE 投稿を取得する。
2. 公開開始・終了日時の条件を満たすレコードに絞り込む。
3. `pinned` DESC → `created_at` DESC の順にソートする。
4. 上位 N 件（N は 1〜3）を `HomeNoticeItem[]` にマッピングする。

擬似コード例（サーバコンポーネント案）：

```ts
async function loadHomeNoticeItems(tenantId: string, maxItems: number): Promise<HomeNoticeItem[]> {
  // Supabase クライアントの初期化は共通ユーティリティに委譲
  const { data, error } = await supabase
    .from('board_posts')
    .select('id, title, published_at, pinned')
    .eq('tenant_id', tenantId)
    .eq('tag', 'NOTICE')
    .lte('published_from', new Date().toISOString())
    .or('published_to.is.null,published_to.gte.' + new Date().toISOString())
    .order('pinned', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(maxItems);

  if (error || !data) return [];

  return data.map((row) => ({
    id: row.id,
    title: row.title,
    publishedAt: formatDate(row.published_at),
  }));
}
```

上記はあくまで将来のイメージであり、実際の列名やクエリは掲示板詳細設計・DB設計に従って調整する。

### 4.3.3 表示件数の制御

表示件数は、HOME 基本設計で定義した 1〜3件の範囲に収める。

* HomePage 内のロジック：

```ts
const limit = clampNoticeCount(tenantSetting.homeNoticeCount); // 未設定時は 2、最大3
const noticeItems = MOCK_HOME_NOTICE_ITEMS.slice(0, limit);
```

* `tenantSetting.homeNoticeCount` は、将来的にテナント設定テーブルから取得する値とし、
  MVP では定数 `2` を直接使用する。

---

## 4.4 機能タイルのデータ管理

### 4.4.1 静的タイル定義（MVP）

機能タイルは、MVP 段階では完全な静的定義とする。

```ts
import { Bell, MessageSquare, Calendar, FileText, Settings, MoreHorizontal } from 'lucide-react';

export const HOME_FEATURE_TILES: HomeFeatureTileDefinition[] = [
  {
    featureKey: 'NOTICE',
    labelKey: 'home.tiles.notice.label',
    descriptionKey: 'home.tiles.notice.description',
    icon: Bell,
    isEnabled: false,
  },
  {
    featureKey: 'BOARD',
    labelKey: 'home.tiles.board.label',
    descriptionKey: 'home.tiles.board.description',
    icon: MessageSquare,
    isEnabled: false,
  },
  {
    featureKey: 'FACILITY',
    labelKey: 'home.tiles.facility.label',
    descriptionKey: 'home.tiles.facility.description',
    icon: Calendar,
    isEnabled: false,
  },
  {
    featureKey: 'RULES',
    labelKey: 'home.tiles.rules.label',
    descriptionKey: 'home.tiles.rules.description',
    icon: FileText,
    isEnabled: false,
  },
  {
    featureKey: 'NOTIFICATION',
    labelKey: 'home.tiles.notification.label',
    descriptionKey: 'home.tiles.notification.description',
    icon: Settings,
    isEnabled: false,
  },
  {
    featureKey: 'DUMMY',
    labelKey: 'home.tiles.dummy.label',
    descriptionKey: 'home.tiles.dummy.description',
    icon: MoreHorizontal,
    isEnabled: false,
  },
];
```

* 並び順は配列順で固定し、上段→下段の順に描画する。
* `isEnabled` はすべて `false` とし、リンク無効状態で実装する。
* `labelKey` / `descriptionKey` は i18n JSON 側で定義する（本章ではキー名のみ扱う）。

### 4.4.2 将来：テナント機能設定との連携

将来的に、テナントごとに利用可能な機能が異なる場合は、
以下のような連携を想定する。

1. テナント機能設定テーブル（例：`tenant_features`）から、利用可能な機能一覧を取得する。
2. `HOME_FEATURE_TILES` を基に、対応する `featureKey` の `isEnabled` を切り替える。

擬似コード例：

```ts
function resolveHomeFeatureTiles(enabledKeys: string[]): HomeFeatureTileDefinition[] {
  return HOME_FEATURE_TILES.map((tile) => ({
    ...tile,
    isEnabled: enabledKeys.includes(tile.featureKey),
  }));
}
```

MVP 段階では、`enabledKeys` は空配列とし、すべて無効のままとする。

### 4.4.3 onClick ハンドラの扱い

* MVP 段階では、`onClick` は全て `undefined` のままとし、タップしても何も起きない。
* 将来、掲示板／施設予約／通知設定画面が実装された段階で、
  `featureKey` ごとに `onClick` を設定する。

擬似コード例：

```ts
function createHomeFeatureTiles(router: AppRouterInstance): HomeFeatureTileDefinition[] {
  return HOME_FEATURE_TILES.map((tile) => {
    switch (tile.featureKey) {
      case 'NOTICE':
        return { ...tile, isEnabled: true, onClick: () => router.push('/board?tag=NOTICE') };
      case 'BOARD':
        return { ...tile, isEnabled: true, onClick: () => router.push('/board') };
      case 'FACILITY':
        return { ...tile, isEnabled: true, onClick: () => router.push('/facility') };
      // RULES / NOTIFICATION / DUMMY は実装時に適宜定義
      default:
        return tile;
    }
  });
}
```

---

## 4.5 状態管理とローディング・エラー

### 4.5.1 MVP 段階

MVP 実装では、以下のように状態管理をシンプルに保つ。

* `HomePage` 内でダミーデータ・静的タイル定義を使用するため、

  * ローディング状態（`loading`）
  * エラー状態（`error`）

を Home コンポーネント内で扱わない。

画面の表示可否は、上位のレイアウトや認証フローに委譲する。

### 4.5.2 将来の拡張ポイント

Supabase 連携時などに、以下のような状態管理を追加する余地を残す。

* お知らせ取得用の hook 例：`useHomeNoticeItems()`

  * `loading: boolean`
  * `error: Error | null`
  * `items: HomeNoticeItem[]`
* HomePage では、上記 hook の結果に応じて、

  * `loading` 時：ローディングインジケータ（スケルトンカード等）
  * `error` 時：簡易エラー表示 or セクション非表示

MVP では hook 自体を実装せず、UI 仕様だけを先に定義しておく。

---

## 4.6 i18n キーと文言の扱い

本章では、i18n JSON の実体は扱わず、以下の方針のみを定義する。

* セクションタイトル・0件時メッセージ・タイルラベル・タイル説明は、
  StaticI18nProvider を用いた静的 i18n キーで管理する。
* 例：

```ts
// お知らせセクション
'home.noticeSection.title' = '最新のお知らせ';
'home.noticeSection.emptyMessage' = '現在表示するお知らせはありません。';

// 機能タイル
'home.features.title' = '機能メニュー';
'home.tiles.notice.label' = 'お知らせ';
'home.tiles.notice.description' = '管理組合からのお知らせ一覧';
// ... 他タイルも同様
```

* 実際の JSON ファイル（`home.json` 等）の定義は、i18n 設計書の範囲とし、
  HomePage 詳細設計では「キー名のみ」を固定する。

---

## 4.7 本章まとめ

* HomePage のデータ連携は、MVP 段階ではダミーデータ・静的定義のみで構成し、
  Supabase やテナント設定との連携は将来の拡張ポイントとして設計しておく。
* お知らせセクション：

  * `HomeNoticeItem[]` を Props 経由で受け取り、1〜3件に制限して表示する。
  * 初期実装では `MOCK_HOME_NOTICE_ITEMS` を使用し、Supabase 連携は行わない。
* 機能タイル：

  * `HOME_FEATURE_TILES` として 6枚のタイルを静的定義し、すべて `isEnabled = false` とする。
  * 将来、テナント機能設定や Router と連携して `isEnabled` と `onClick` を有効化する。
* 状態管理：

  * MVP では loading/error 状態を Home コンポーネントでは扱わず、将来の hook 導入に備えた枠だけ定義する。
* i18n：

  * 文言はすべて静的 i18n キーで管理し、HomePage 詳細設計ではキー名のみを指定する。

---

**End of Document**
