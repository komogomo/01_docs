# CodeAgent Report: Home Footer Dummy v1.0

- **Document ID**: CodeAgent_Report_HomeFooterDummy_v1.0
- **Related WS**: WS-HomeFooterDummy_v1.0
- **System**: HarmoNet
- **Date**: 2025-11-20

---

## 1. 対象スコープ

- MagicLink ログイン後に遷移するダミー HOME 画面 `/home` のフッターまわり
- 共通フレームコンポーネント:
  - `HomeFooterShortcuts`（本タスクで新規作成）
  - `AppFooter`（既存のスタイル調整）
  - `LanguageSwitch`（ヘッダー右上のスタイル調整）

---

## 2. 変更ファイル一覧

- `app/home/page.tsx`
  - `HomeFooterShortcuts` の組み込み
- `src/components/common/HomeFooterShortcuts/HomeFooterShortcuts.tsx`
  - HOME 専用ショートカットバー新規実装
- `src/components/common/AppFooter/AppFooter.tsx`
  - コピーライト行スタイル調整
- `src/components/common/LanguageSwitch/LanguageSwitch.tsx`
  - ボタンサイズ・配置・色味調整
- `public/locales/ja/common.json`
- `public/locales/en/common.json`
- `public/locales/zh/common.json`
  - `nav.*` ラベル追加（home/board/facility/mypage/logout）

---

## 3. HOME フッター構成仕様

### 3.1 レイアウト構成

HOME 画面 `/home` の最下部は、下記 2 レイヤで構成される。

1. **ショートカットバー**: `HomeFooterShortcuts`
2. **コピーライト行**: `AppFooter`

DOM 構造（抜粋）:

```tsx
return (
  <>
    <main>...既存 Home 本文...</main>
    <HomeFooterShortcuts />
    {/* ルート layout.tsx により常時 AppFooter が挿入される */}
  </>
);
```

### 3.2 HomeFooterShortcuts コンポーネント仕様

- **パス**: `src/components/common/HomeFooterShortcuts/HomeFooterShortcuts.tsx`
- **種別**: `"use client"` コンポーネント
- **役割**: HOME 画面専用のダミー・フッターショートカットバー
- **Props**:
  - `className?: string`
  - `testId?: string` （デフォルト: `"home-footer-shortcuts"`）

#### 3.2.1 配置・スタイル

- 画面下部に固定表示
- Tailwind クラス（ルート `<nav>`）:

```tsx
<nav
  role="navigation"
  aria-label={t('common.shortcut_navigation')}
  data-testid={testId}
  className={`
    fixed bottom-5 left-0 right-0 h-16
    bg-white border-t border-gray-200 z-[950]
    flex items-center
    ${className}
  `}
>
  ...
</nav>
```

- **位置**:
  - `bottom-5` により、コピーライト行のすぐ上に 1 行強の余白で重ならずに配置
- **高さ**: `h-16` (64px 相当)
- **背景**: `bg-white`
- **ボーダー**: 上端 `border-t border-gray-200`
- **重なり順**: `z-[950]`（AppFooter の `z-[900]` より上）

#### 3.2.2 ショートカット項目

内部固定配列 `SHORTCUT_ITEMS`:

```ts
const SHORTCUT_ITEMS: ShortcutItem[] = [
  { key: 'home',    labelKey: 'nav.home',    href: '/home', Icon: Home },
  { key: 'board',   labelKey: 'nav.board',   href: '',      Icon: MessageSquare },
  { key: 'facility',labelKey: 'nav.facility',href: '',      Icon: Calendar },
  { key: 'mypage',  labelKey: 'nav.mypage',  href: '',      Icon: User },
  { key: 'logout',  labelKey: 'nav.logout',  href: '',      Icon: LogOut },
];
```

- `href` が空文字の項目（board/facility/mypage/logout）は、**本タスク時点では画面遷移を行わない** 前提。
- 文言は全て StaticI18n の `nav.*` キーから取得。

#### 3.2.3 アイコン・ラベル表示

各ショートカットは次のクラスで表示される:

```ts
const baseClasses = `
  flex flex-col items-center justify-center gap-1 text-xs
  ${active ? 'text-blue-600 border-t-2 border-blue-600 font-semibold' : 'text-gray-500'}
`;
```

- **アイコン部**:
  - `<Icon aria-hidden="true" className="h-5 w-5" />`
  - 20px 四方程度
- **ラベル部**:
  - `text-xs`
  - 日本語/英語/中国語で StaticI18n により切替
- **アクティブ判定**:
  - `home` のみ、`href='/home'` のため、`pathname.startsWith('/home')` でアクティブ扱い
  - アクティブ時:
    - `text-blue-600`
    - `border-t-2 border-blue-600`
    - `font-semibold`
  - 非アクティブ時:
    - `text-gray-500`

#### 3.2.4 クリック挙動

- `logout` 以外（home/board/facility/mypage）
  - 現時点では **ボタンとして描画するが、クリック時には何も起こさない**（no-op）。
  - 将来、画面実装完了後に `href` とルーティング処理を追加予定。

- `logout` のみ特別扱い:

```ts
const handleClick = async (item: ShortcutItem) => {
  if (item.key !== 'logout') return;

  logInfo('footer.logout.start');
  const { error } = await supabase.auth.signOut();

  if (error) {
    logError('footer.logout.fail', {
      code: (error as any).code ?? 'unknown',
      message: error.message,
    });
  } else {
    logInfo('footer.logout.success');
  }

  router.replace('/login');
};
```

- ログ出力:
  - 成功/失敗ともに `footer.logout.*` イベントで構造化ログを出力。
- 最後に `router.replace('/login')` でログイン画面へ遷移。

---

## 4. AppFooter（コピーライト）の最終仕様

### 4.1 コンポーネント概要

- **パス**: `src/components/common/AppFooter/AppFooter.tsx`
- **役割**: アプリ全体のコピーライト表記（全画面共通）
- **テキスト**: StaticI18n `common.copyright`

### 4.2 スタイル仕様

```tsx
<footer
  role="contentinfo"
  data-testid={testId}
  className={`
    fixed bottom-0 left-0 right-0
    z-[900]
    py-0.5
    text-[11px] text-gray-400 text-center
    ${className}
  `}
>
  {t('common.copyright')}
</footer>
```

- **位置**: 画面最下部に固定 (`fixed bottom-0 left-0 right-0`)
- **高さ**: 明示的な `h-*` 指定はせず、`py-0.5`（上下 2px 程度）で **細い 1 行** として表示。
- **文字サイズ**: `text-[11px]`
- **色**: `text-gray-400`
- **背景・枠線**: なし（軽量な見た目）。
- **重なり順**: `z-[900]` （HomeFooterShortcuts の `z-[950]` より下）。

結果として、ショートカットバー直下に控えめなコピーライトテキストが表示される。

---

## 5. LanguageSwitch（ヘッダー右上）の最終仕様

### 5.1 コンポーネント概要

- **パス**: `src/components/common/LanguageSwitch/LanguageSwitch.tsx`
- **役割**: JA / EN / ZH のクライアントサイド言語切替
- **使用先**: `AppHeader` 内右側ブロック

### 5.2 レイアウト仕様

`AppHeader` 内では以下のように配置:

```tsx
<div className="flex items-center gap-4">
  {variant === 'authenticated' && <通知ボタン />}
  <LanguageSwitch testId={`${testId}-language-switch`} />
</div>
```

`LanguageSwitch` 自身のラッパー:

```tsx
<div className={`flex gap-1.5 justify-end ${className}`} data-testid={testId}>
  {buttons.map(...)}
</div>
```

- **ボタン間隔**: `gap-1.5`（やや詰め気味）
- **右寄せ**: `justify-end`

### 5.3 ボタン仕様（サイズ・色）

#### 5.3.1 サイズ

```tsx
className={`
  min-w-[40px]
  min-h-[30px]
  rounded-lg border
  text-xs font-semibold
  px-2.5 py-1.5
  transition-colors
  focus-visible:ring-2 focus-visible:ring-blue-600
  ${active ? ... : ...}
`}
```

- **最小幅**: `min-w-[40px]`
- **最小高さ**: `min-h-[30px]`
- **パディング**: `px-2.5 py-1.5`
- **フォント**: `text-xs font-semibold`
- **角丸**: `rounded-lg`

#### 5.3.2 色とアクティブ状態

フッターショートカットの配色ポリシーに合わせ、以下のように統一。

- **アクティブ時 (`currentLocale === code`)**:

```ts
'bg-white text-blue-600 border-blue-600 border-2'
```

  - 文字色: `text-blue-600`
  - 枠線色: `border-blue-600`
  - 枠線太さ: `border-2`（FooterShortcutBar の `border-t-2` に相当）
  - 背景: `bg-white`（青背景は使用しない）

- **非アクティブ時**:

```ts
'bg-white text-gray-500 border-transparent hover:bg-gray-50'
```

  - 文字色: `text-gray-500`（FooterShortcutBar 非アクティブ `text-gray-500` と同系）
  - 枠線: `border-transparent`（ほぼ見えない）
  - ホバー: `hover:bg-gray-50`

#### 5.3.3 文言

- `JA` / `EN` / `ZH` の 2 文字ラベル
- `aria-label`: `${label}に切り替え`（例: "JAに切り替え"）

---

## 6. i18n 辞書追加内容

StaticI18n は `/locales/{locale}/common.json` を参照する。
今回のタスクで、フッターショートカット用の `nav.*` キーを追加した。

### 6.1 日本語 `public/locales/ja/common.json`

```json
"nav": {
  "home": "ホーム",
  "board": "掲示板",
  "facility": "施設予約",
  "mypage": "マイページ",
  "logout": "ログアウト"
}
```

### 6.2 英語 `public/locales/en/common.json`

```json
"nav": {
  "home": "Home",
  "board": "Board",
  "facility": "Facility",
  "mypage": "My page",
  "logout": "Logout"
}
```

### 6.3 中国語 `public/locales/zh/common.json`

```json
"nav": {
  "home": "首页",
  "board": "公告板",
  "facility": "设施预约",
  "mypage": "我的页面",
  "logout": "登出"
}
```

これにより、`HomeFooterShortcuts` から `t('nav.*')` を呼び出すだけで 3 言語切替が可能になっている。

---

## 7. テスト・動作確認

### 7.1 手動確認

- MagicLink ログイン → `/home` 遷移
  - HOME 本文が表示されること
  - 画面下部にショートカットバー（5 アイコン）とコピーライトが 2 段で表示されること
- フッターショートカット:
  - ラベルが JA/EN/ZH の各言語に切り替わること
  - `home` のみアクティブ装飾（青文字 + 上部ボーダー）になること
  - `logout` 以外をクリックしても画面遷移しないこと
  - `logout` クリックで Supabase セッションが終了し、`/login` に戻ること
- LanguageSwitch:
  - ヘッダー右上に JA/EN/ZH の 3 ボタンが小さめサイズで右寄せ表示されること
  - アクティブボタンが青文字 + 青枠（2px）で表示されること
  - 言語切替によりフッターラベルも連動して変わること

### 7.2 自動テスト

- 既存のコンポーネントテスト（AppFooter / FooterShortcutBar / StaticI18n など）はエラーなく通過（本タスク中に新規 UT は追加していない）。
- 必要に応じて、HomeFooterShortcuts 専用の UT を別タスクで追加可能。

---

## 8. 自己評価

- UI 一貫性: 9.5/10
  - フッターショートカットとヘッダーの LanguageSwitch の色・太さ・トーンが揃い、全体として統一感のあるフレームになった。
- 仕様準拠度: 9/10
  - WS と詳細設計書に従い、HOME 画面のみ共通フッターを適用し、Logout 以外はダミーとする方針を守った。
- 今後の改善余地:
  - HomeFooterShortcuts の UT 追加
  - 将来の本実装時に、`href` とナビゲーションロジックを差し替えやすいよう Storybook も整備する。
