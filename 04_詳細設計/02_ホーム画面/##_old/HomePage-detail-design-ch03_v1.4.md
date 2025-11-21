# HomePage 詳細設計書 ch03：コンポーネント仕様（Props / State / 型定義）

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 3 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 3.1 本章の目的

本章では、H-00 HomePage を構成する主要コンポーネントの **Props / State / 型定義** を示す。

* `HomePage`（/home ページ）
* `HomeNoticeSection`
* `HomeFeatureTiles`
* `HomeFeatureTile`

を対象とし、責務と外部インターフェースを明確にする。UI クラス値・実データ取得ロジックは ch04 以降で扱う。

---

## 3.2 型定義（共通）

### 3.2.1 HomeNoticeItem 型

HOME お知らせセクションで扱う 1件分のお知らせ情報を表す。

```ts
export type HomeNoticeItem = {
  id: string; // 掲示板投稿ID（board_posts.id）を想定
  title: string; // 投稿タイトル（NOTICE）
  publishedAt: string; // 公開日。表示用にフォーマット済みでも良い（YYYY-MM-DD など）
  // 将来拡張用フィールド（必要になった段階で追加）
  // originalCreatedAt?: string; // DB上の created_at
  // tag?: 'NOTICE';
};
```

MVP ではダミーデータを想定し、`publishedAt` は表示用文字列として扱う。
Supabase 連携時に、内部的な日時型とのマッピングは別途検討する。

### 3.2.2 HomeFeatureTileDefinition 型

機能タイル一覧（2×3）を構成する静的定義情報を表す。

```ts
export type HomeFeatureTileDefinition = {
  featureKey: 'NOTICE' | 'BOARD' | 'FACILITY' | 'RULES' | 'NOTIFICATION' | 'DUMMY';
  labelKey: string; // i18n キー（例: 'home.tiles.notice.label'）
  descriptionKey: string; // i18n キー（例: 'home.tiles.notice.description'）
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>; // lucide-react アイコン
  isEnabled: boolean; // リンク有効/無効フラグ（MVPでは全て false）
  onClick?: () => void; // 有効時のクリックハンドラ（MVPでは未設定）
};
```

`featureKey` は、テナント機能フラグやルーティング定義と紐づけるための論理キーとして扱う。

---

## 3.3 HomePage コンポーネント

### 3.3.1 役割

* `/home` ルートに対応するページコンポーネント（Next.js App Router）。
* AppHeader / AppFooter と、Home コンテンツ領域（お知らせ＋機能タイル）を組み合わせて画面を構成する。
* データ取得やビジネスロジックは極力持たず、`HomeNoticeSection` と `HomeFeatureTiles` に委譲する。

### 3.3.2 Props / State

* Props: なし（Next.js の page コンポーネントとして、直接 Props を受け取らない前提）。
* State: MVP 段階では内部 State を持たない。

  * 将来、サーバコンポーネント化などにより、お知らせデータ／タイル定義を子コンポーネントへ渡す可能性はあるが、
    現時点では「ローカルの定数定義をそのまま子へ渡す」シンプルな構造とする。

### 3.3.3 擬似コード（概略）

```ts
export default function HomePage() {
  const noticeItems: HomeNoticeItem[] = MOCK_HOME_NOTICE_ITEMS; // MVP: ダミーデータ
  const featureTiles: HomeFeatureTileDefinition[] = HOME_FEATURE_TILES; // 静的定義

  return (
    <StaticI18nProvider>
      <div className="min-h-screen flex flex-col bg-background">
        <AppHeader />
        <main className="flex-1 px-4 py-4 max-w-md mx-auto w-full space-y-4">
          <HomeNoticeSection items={noticeItems} maxItems={2} />
          <HomeFeatureTiles tiles={featureTiles} />
        </main>
        <AppFooter />
      </div>
    </StaticI18nProvider>
  );
}
```

`MOCK_HOME_NOTICE_ITEMS` / `HOME_FEATURE_TILES` は ch04 で定義する想定とする。

---

## 3.4 HomeNoticeSection コンポーネント

### 3.4.1 役割

* HOME 上部に「最新のお知らせ」セクションを描画する。
* NOTICE タグ付き掲示の一部（1〜3件）をカード形式で表示する。
* 0件時は「現在表示するお知らせはありません。」というメッセージのみ表示する。

### 3.4.2 Props

```ts
export type HomeNoticeSectionProps = {
  items: HomeNoticeItem[]; // 表示候補のお知らせ一覧
  maxItems?: number; // 最大表示件数（1〜3件）。未指定時は DEFAULT_HOME_NOTICE_COUNT を使用
};
```

* `items`

  * NOTICE タグ付き、公開期間内、RLS 済みの投稿を前提とする。
  * MVP ではダミーデータで代用し、将来 Supabase 連携に差し替える。
* `maxItems`

  * HOME 基本設計の「1〜3件」の範囲を反映する。
  * コンポーネント内では `const limit = clamp(maxItems ?? DEFAULT_HOME_NOTICE_COUNT, 1, 3);` のように扱う前提。

### 3.4.3 State / 内部変数

* State: 持たない（MVP 段階では items は親から渡される前提）。
* 内部変数:

```ts
const DEFAULT_HOME_NOTICE_COUNT = 2; // 明示的に定数化

const visibleItems = items.slice(0, limit);
```

### 3.4.4 主な描画ロジック

* `items.length === 0` の場合:

  * セクションタイトル＋「現在表示するお知らせはありません。」を描画。
* 1件以上の場合:

  * 先頭 `visibleItems` 分だけカードとして描画。
  * カード全体を `button` 要素とし、将来 `onClick` で掲示板詳細へ遷移させる前提。

ローディング・エラー状態の扱いは ch04（データ連携）で別途定義する。

---

## 3.5 HomeFeatureTiles コンポーネント

### 3.5.1 役割

* 機能タイル 2×3 のコンテナとして、タイル定義配列から `HomeFeatureTile` を並べる。
* 自身はビジネスロジックを持たず、配置とアクセシビリティ（セクションタイトル等）に責務を限定する。

### 3.5.2 Props

```ts
export type HomeFeatureTilesProps = {
  tiles: HomeFeatureTileDefinition[]; // 機能タイル定義配列（上段3 + 下段3）
};
```

* `tiles`

  * HOME 基本設計 ch04 で定義した 6 タイル分を想定（お知らせ／掲示板／施設予約／運用ルール／通知設定／ダミー）。
  * 並び順は配列順とし、上段→下段の順番を保つ。

### 3.5.3 State

* 持たない。
* タイルの有効／無効状態は `tiles` 配列の `isEnabled` プロパティで管理する。

### 3.5.4 主な描画ロジック

* セクションタイトル（例：`t('home.features.title')`）を表示。
* `tiles.map` で `HomeFeatureTile` を 6 枚描画。
* レイアウト（`grid grid-cols-3 gap-3` など）は ch04 以降で定義する。

---

## 3.6 HomeFeatureTile コンポーネント

### 3.6.1 役割

* 単一の機能タイルを描画し、`isEnabled` フラグに応じて見た目と挙動を切り替える。
* クリック時の遷移処理（onClick）は親（HomePage やルーティング層）から渡される前提とする。

### 3.6.2 Props

```ts
export type HomeFeatureTileProps = HomeFeatureTileDefinition;
```

* `HomeFeatureTileDefinition` をそのまま Props として利用する。
* 追加でテスト ID やクラス名を渡す必要が生じた場合は、
  将来 `HomeFeatureTileProps` を拡張する。

### 3.6.3 State

* 内部 State は持たない。
* 見た目の変化は `isEnabled` と Hover 状態に基づく CSS/Tailwind で制御する。

### 3.6.4 主な描画ロジック

```ts
export const HomeFeatureTile: React.FC<HomeFeatureTileProps> = ({
  featureKey,
  labelKey,
  descriptionKey,
  icon: Icon,
  isEnabled,
  onClick,
}) => {
  const handleClick = () => {
    if (!isEnabled || !onClick) return;
    onClick();
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      className={/* isEnabled に応じたスタイル */ ''}
      aria-disabled={!isEnabled}
      data-feature-key={featureKey}
    >
      <Icon aria-hidden="true" />
      <span>{t(labelKey)}</span>
      <span>{t(descriptionKey)}</span>
    </button>
  );
};
```

* `aria-disabled` により、スクリーンリーダーにも無効状態を伝える。
* `data-feature-key` はテストやデバッグ時の識別用途。

---

## 3.7 定数・ユーティリティ

### 3.7.1 デフォルト値

```ts
export const DEFAULT_HOME_NOTICE_COUNT = 2; // デフォルト表示件数
export const HOME_NOTICE_MAX_COUNT = 3; // 表示上限
```

### 3.7.2 件数制御ユーティリティ（任意）

```ts
export const clampNoticeCount = (value: number | undefined): number => {
  if (value == null) return DEFAULT_HOME_NOTICE_COUNT;
  return Math.min(Math.max(value, 1), HOME_NOTICE_MAX_COUNT);
};
```

* `HomeNoticeSection` 内で利用し、1〜3件の範囲に収まるようにする。

---

## 3.8 本章まとめ

* `HomeNoticeItem` と `HomeFeatureTileDefinition` を共通型として定義し、
  Home コンポーネント群間で一貫したデータ構造を使用する。
* `HomePage` は Props／State を極力持たず、ダミーデータ・タイル定義を子コンポーネントへ渡すシンプルな構造とする。
* `HomeNoticeSection` は `items` と `maxItems` のみを受け取り、表示件数制御と 0件時表示の UI を担当する。
* `HomeFeatureTiles` は静的なタイル定義配列から `HomeFeatureTile` を描画するコンテナとし、ロジックを持たない。
* `HomeFeatureTile` は `isEnabled` と `onClick` のみで挙動を切り替えるプレゼンテーションコンポーネントとして設計する。

---

**End of Document**
