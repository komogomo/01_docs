# HomePage 詳細設計書 ch02：画面構成・コンポーネント構造

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 2 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 2.1 レイアウト全体構成

HomePage（/home）は、App Router 配下のページコンポーネントとして、
以下 3 つの縦方向ブロックで構成する。

1. 共通ヘッダー: `AppHeader`（C-01）
2. HOME コンテンツ領域: H-00 HomePage コンポーネント群

   * セクションA: `HomeNoticeSection`（最新のお知らせ）
   * セクションB: `HomeFeatureTiles`（機能タイル 2×3）
3. 共通フッター: `AppFooter`（C-04）

### 2.1.1 画面構成イメージ（SP 縦向き）

```
┌──────────────────────────┐
│ AppHeader（共通）                              │
├──────────────────────────┤
│ Home コンテンツ領域                             │
│  ┌────────────────────────┐│
│  │ HomeNoticeSection                    ││
│  │  ・セクションタイトル                ││
│  │  ・お知らせカード 1〜3件             ││
│  └────────────────────────┘│
│  ┌────────────────────────┐│
│  │ HomeFeatureTiles                     ││
│  │  ・機能タイル 2×3                    ││
│  └────────────────────────┘│
├──────────────────────────┤
│ AppFooter（共通）                              │
└──────────────────────────┘
```

* スクロール方向は縦のみ。
* PC 表示時も基本構造は同一とし、横幅のみコンテナでセンタリングする。

---

## 2.2 ファイル構成（想定）

HomePage 関連コンポーネントのファイル配置は、以下の構成を想定する。

* `app/home/page.tsx`

  * HomePage のエントリポイント。
* `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
* `src/components/home/HomeNoticeSection/HomeNoticeSection.types.ts`
* `src/components/home/HomeFeatureTiles/HomeFeatureTiles.tsx`
* `src/components/home/HomeFeatureTiles/HomeFeatureTiles.types.ts`
* `src/components/home/HomeFeatureTiles/HomeFeatureTile.tsx`
* `src/components/home/HomeFeatureTiles/HomeFeatureTile.types.ts`

補助的なコンポーネントやユーティリティが必要になった場合は、
`src/components/home/` 配下に追加する（例：`HomeSectionContainer` など）。

実際のパス・命名は、HarmoNet 全体のフロントエンドディレクトリ・ガイドラインに従い、
本詳細設計では「概念的な配置」として扱う。

---

## 2.3 コンポーネント一覧

### 2.3.1 ページコンポーネント

* `HomePage`（`app/home/page.tsx` 内のデフォルトエクスポート）

  * 役割:

    * `/home` へのルーティングエントリ。
    * AppHeader / AppFooter と Home コンテンツを組み合わせたページレイアウトを構成する。
  * 主な子コンポーネント:

    * `AppHeader`
    * `HomeNoticeSection`
    * `HomeFeatureTiles`
    * `AppFooter`

### 2.3.2 セクションコンポーネント

* `HomeNoticeSection`

  * 役割:

    * HOME 上部に配置される「最新のお知らせ」セクションを描画する。
    * NOTICE タグ付きお知らせのタイトル・日付をカードとして 1〜3件表示する。

* `HomeFeatureTiles`

  * 役割:

    * HOME 下部の機能タイル 2×3 を描画する。
    * タイル定義配列から `HomeFeatureTile` を並べるコンテナとして動作する。

### 2.3.3 タイルコンポーネント

* `HomeFeatureTile`

  * 役割:

    * 単一の機能タイル（アイコン＋ラベル＋説明）を描画する。
    * `isEnabled` フラグに応じて、リンク有効／無効の見た目と挙動を切り替える。

---

## 2.4 コンポーネントツリー

### 2.4.1 JSX ツリー（概略）

`app/home/page.tsx` における JSX 構造の概略は以下の通りとする。

```tsx
export default function HomePage() {
  return (
    <StaticI18nProvider>
      <div className="min-h-screen flex flex-col bg-background">
        <AppHeader />

        <main className="flex-1 px-4 py-4 max-w-md mx-auto w-full space-y-4">
          <HomeNoticeSection />
          <HomeFeatureTiles />
        </main>

        <AppFooter />
      </div>
    </StaticI18nProvider>
  );
}
```

* `StaticI18nProvider` の配置位置は、LoginPage 詳細設計と整合を取る。

  * グローバルでラップされている場合は省略し、`HomePage` 直下では使用しない。
* `max-w-md` / `mx-auto` などの具体クラスは、最終的に Tailwind 設計（ch03 以降）で確定する。

### 2.4.2 HomeNoticeSection 内部構造（概略）

```tsx
export const HomeNoticeSection: React.FC<HomeNoticeSectionProps> = ({ items, maxItems }) => {
  // items: HomeNoticeItem[]（MVPではダミーデータ）

  if (!items || items.length === 0) {
    return (
      <section aria-labelledby="home-notice-title">
        <h2 id="home-notice-title">{t('home.noticeSection.title')}</h2>
        <p>{t('home.noticeSection.emptyMessage')}</p>
      </section>
    );
  }

  const visibleItems = items.slice(0, maxItems ?? DEFAULT_HOME_NOTICE_COUNT);

  return (
    <section aria-labelledby="home-notice-title">
      <h2 id="home-notice-title">{t('home.noticeSection.title')}</h2>
      <div className="space-y-2">
        {visibleItems.map((item) => (
          <button
            key={item.id}
            type="button"
            className="w-full text-left"
            // クリック時の遷移は将来実装
          >
            {/* バッジ＋日付＋タイトルを表示 */}
          </button>
        ))}
      </div>
    </section>
  );
};
```

* 本章では構造イメージのみを示し、クラスや型の詳細は ch03 以降で定義する。

### 2.4.3 HomeFeatureTiles 内部構造（概略）

```tsx
export const HomeFeatureTiles: React.FC<HomeFeatureTilesProps> = ({ tiles }) => {
  // tiles: HomeFeatureTileDefinition[]（静的定義を受け取る想定）

  return (
    <section aria-labelledby="home-feature-tiles-title">
      <h2 id="home-feature-tiles-title">{t('home.features.title')}</h2>
      <div className="grid grid-cols-3 gap-3">
        {tiles.map((tile) => (
          <HomeFeatureTile key={tile.featureKey} {...tile} />
        ))}
      </div>
    </section>
  );
};
```

```tsx
export const HomeFeatureTile: React.FC<HomeFeatureTileProps> = ({
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
    >
      <Icon aria-hidden="true" />
      <span>{t(labelKey)}</span>
      <span>{t(descriptionKey)}</span>
    </button>
  );
};
```

* `HomeFeatureTiles` は単純なコンテナとし、ビジネスロジックは持たない。
* `HomeFeatureTile` は `isEnabled` による見た目制御とクリック制御のみを担当する。

---

## 2.5 レスポンシブ・余白・コンテナ幅

### 2.5.1 基本方針

* SP 縦向き（幅 360〜430px）を主ターゲットとし、
  1画面内に「最新のお知らせ」＋「機能タイル 2×3」が概ね収まるようにする。
* PC 表示時は、中央寄せコンテナ（例：`max-w-md mx-auto`）を用い、
  コンテンツ幅を広げすぎない。

### 2.5.2 余白とセクション間隔

* 上下 padding は LoginPage 詳細設計とトーンを揃える（例：`py-4`〜`py-6`）。
* セクション間隔は `space-y-4` 〜 `space-y-6` 程度とし、
  タイルの視認性とタップしやすさを優先する。

具体的な Tailwind クラス値は、ch03 以降のスタイル仕様で確定する。

---

## 2.6 本章まとめ

* HomePage は、AppHeader／Home コンテンツ／AppFooter の 3 ブロック構成とする。
* Home コンテンツ領域は、`HomeNoticeSection` と `HomeFeatureTiles` の 2 セクションで構成する。
* コンポーネントツリーは、`HomePage` → `HomeNoticeSection` / `HomeFeatureTiles` → `HomeFeatureTile` の 3層を基本とする。
* JSX の骨格を本章で固定し、Props・型・Tailwind クラス・データ連携は ch03 以降で詳細化する。

---

**End of Document**
