# CodeAgent Report: H00-UI-HomePage-Layout v1.0

## 1. タスク概要

- 対象画面: `/home` (HomePage)
- 対象機能: 認証後ホーム画面の **コンテンツエリア UI スケルトン**
  - 最新のお知らせ (`HomeNoticeSection`)
  - 機能タイル (`HomeFeatureTiles` / `HomeFeatureTile`)
- 前提:
  - Supabase 認証・RLS ロジックは既存のまま変更しない
  - 通知一覧 / 掲示板 / 施設予約 など機能本体は本タスク範囲外
  - i18n JSON（`public/locales/*/common.json`）の編集は原則範囲外だが、今回はユーザ側で Home 用キーを追加済み

本タスクでは、詳細設計 ch01〜ch07 をベースに UI コンポーネント実装と Jest+RTL テスト追加を行いました。

---

## 2. 変更ファイル一覧

### 2.1 既存ファイルの変更

- `app/home/page.tsx`
  - 既存の Supabase 認証・認可ロジックはそのまま維持
  - 画面の `return` 部分のみを Home UI スケルトンに差し替え
    - `HomeNoticeSection` を配置し、ダミーお知らせ `MOCK_HOME_NOTICE_ITEMS` を `items` として渡す
    - `HomeFeatureTiles` を配置し、`tiles={[]}` を渡す（実際のタイル定義は Client 側で持つ方針に変更）
    - 画面下部に既存の `HomeFooterShortcuts` を表示
  - レイアウト: `max-w-md` の 1 カラム構成、`pt-28 pb-28` など LoginPage とトーンを合わせた余白設定

### 2.2 新規追加ファイル（コンポーネント）

- `src/components/home/HomeNoticeSection/HomeNoticeSection.types.ts`
  - 型定義:
    - `HomeNoticeItem { id: string; title: string; publishedAt: string }`
    - `HomeNoticeSectionProps { items: HomeNoticeItem[]; maxItems?: number }`
    - `DEFAULT_HOME_NOTICE_COUNT = 2`
    - `HOME_NOTICE_MAX_COUNT = 3`
    - `clampNoticeCount(value: number | undefined): number`
      - `undefined` や NaN をデフォルト 2 に丸めつつ、1〜3 の範囲に clamp

- `src/components/home/HomeNoticeSection/HomeNoticeSection.tsx`
  - "最新のお知らせ" セクション本体
  - `items.length === 0` の場合:
    - セクションタイトル: `t('home.noticeSection.title')`
    - メッセージ: `t('home.noticeSection.emptyMessage')`
  - 1 件以上の場合:
    - `clampNoticeCount(maxItems)` で 1〜3 件に制限した配列をマップ
    - 各行は `button` 要素で構成（将来の画面遷移に備えた構造）
      - 上段: 左にバッジ（固定テキスト "お知らせ"）、右に `publishedAt`
      - 下段: タイトル（`line-clamp-2` で 2 行まで表示）と右端の `>` インジケータ
    - アクセシビリティ: `aria-label` に「日付 + タイトル」を付与

- `src/components/home/HomeFeatureTiles/HomeFeatureTile.types.ts`
  - `HomeFeatureTileDefinition` 型
    - `featureKey: 'NOTICE' | 'BOARD' | 'FACILITY' | 'RULES' | 'NOTIFICATION' | 'DUMMY'`
    - `labelKey: string`, `descriptionKey: string`
    - `icon: React.ComponentType<SVGProps<SVGSVGElement>>`
    - `isEnabled: boolean`, `onClick?: () => void`
  - `HomeFeatureTileProps = HomeFeatureTileDefinition`

- `src/components/home/HomeFeatureTiles/HomeFeatureTiles.types.ts`
  - `HomeFeatureTilesProps { tiles: HomeFeatureTileDefinition[] }`
  - 静的タイル定義 `HOME_FEATURE_TILES`
    - NOTICE / BOARD / FACILITY / RULES / NOTIFICATION / DUMMY の 6 タイル
    - いずれも `isEnabled: false`（MVP ではリンク無効）
    - アイコンは `lucide-react` (Bell, MessageSquare, Calendar, FileText, Settings, MoreHorizontal)

- `src/components/home/HomeFeatureTiles/HomeFeatureTile.tsx`
  - 単一タイルコンポーネント
  - `isEnabled` に応じて:
    - `aria-disabled` の付与
    - `onClick` の呼び出し有無を制御
    - Tailwind クラスでポインタ / ホバー / 枠線カラーを切り替え
  - ラベル/説明文は `useI18n().t(labelKey/descriptionKey)` で翻訳

- `src/components/home/HomeFeatureTiles/HomeFeatureTiles.tsx`
  - タイルセクションコンテナ
  - セクションタイトル: `t('home.features.title')`
  - `tiles` 引数が空配列または未指定の場合:
    - クライアント側で保持する `HOME_FEATURE_TILES` を利用
    - （Server Component から lucide アイコン関数を含むオブジェクトを渡さないための対策）
  - UI: `grid grid-cols-3 gap-3` の 2×3 グリッド

### 2.3 新規追加ファイル（テスト）

- `src/__tests__/home/HomeNoticeSection.test.tsx`
- `src/__tests__/home/HomeFeatureTiles.test.tsx`
- `src/__tests__/home/HomePage.test.tsx`

---

## 3. 実装詳細と設計との差分

### 3.1 HomePage (`app/home/page.tsx`)

- 詳細設計 ch04 では、`MOCK_HOME_NOTICE_ITEMS` と `HOME_FEATURE_TILES` を Server Component 側で定義し、両方を子コンポーネントに props で渡す方針でした。
- Next.js 16 の Server/Client 制約により、Server Component から Client Component へ **React コンポーネント（lucide アイコン）を含むオブジェクト** を直接渡すとエラーになるため、以下のように調整しました。
  - Server 側:
    - `MOCK_HOME_NOTICE_ITEMS` はこれまでどおり `HomeNoticeSection` に渡す
    - `HomeFeatureTiles` には `tiles={[]}` を渡すのみ
  - Client 側 (`HomeFeatureTiles.tsx`):
    - `tiles` が空の場合は、自前で `HOME_FEATURE_TILES` を用いて描画

> 差分ポイント: **タイル定義の責務を Server → Client に移動** しており、設計書 ch04 の「責務分担」とわずかに異なりますが、Next App Router の技術制約に依存したやむを得ない変更です。設計側へのフィードバック候補として記載します（§6）。

その他:
- 認証・RLS ロジック（`createSupabaseServerClient` / `auth.getUser` / `user_tenants` 参照など）は一切変更していません。
- レイアウトは LoginPage に合わせて `max-w-md` / 上下パディング等を調整し、SP ポートレート前提の表示としています。

### 3.2 HomeNoticeSection

- 詳細設計 ch03/ch05 にしたがって以下を実装:
  - 0 件時: タイトル + 「現在表示するお知らせはありません。」
  - 1〜3 件時: バッジ + 日付 + タイトルのカードを縦方向に並べる
  - `maxItems` は 1〜3 に clamp（デフォルト 2 件表示）
- 差分・メモ:
  - バッジ文言は現在 **固定テキスト "お知らせ"** です（i18n キーではなく日本語固定）。
    - ユーザ作成の辞書ではタイル側に十分なキーが用意されているため、将来的には `home.noticeSection.badge` のようなキーで多言語化する余地があります。

### 3.3 HomeFeatureTiles / HomeFeatureTile

- 詳細設計 ch03/ch04 にしたがって 6 つのタイルを定義:
  - お知らせ / 掲示板 / 施設予約 / 運用ルール / 通知設定 / 準備中
  - 現時点ではすべて `isEnabled = false` とし、リンクや onClick は無効
- 差分・メモ:
  - `isEnabled=false` の場合でも `button` 要素でレンダリングし、`aria-disabled="true"` と CSS で視覚的に無効状態を表現しています（詳細設計 ch05 の方針通り）。
  - `HomeFeatureTiles` 側の `tiles` 引数は将来の拡張（テナント設定からの有効/無効判定など）を見据えたまま残していますが、現時点では `[]` を受け取った場合にのみ内部の静的定義を利用します。

### 3.4 i18n 辞書

- 実装では以下のキーを参照しています。
  - `home.noticeSection.title`
  - `home.noticeSection.emptyMessage`
  - `home.features.title`
  - `home.tiles.[notice|board|facility|rules|notification|dummy].{label,description}`
- `StaticI18nProvider` の仕様上、辞書未ロード時はキー文字列がそのまま表示されるため、実装完了時点ではブラウザ上に `home.features.title` などのキーが表示されていました。
- ユーザ側で以下のファイルに Home 用セクションを追加済みです。
  - `public/locales/ja/common.json`
  - `public/locales/en/common.json`
  - `public/locales/zh/common.json`

これにより、JA/EN/ZH すべてで設計書に沿った文言が表示され、Missing key 警告は解消されています。

---

## 4. テスト実行結果

### 4.1 追加テスト内容

1. `src/__tests__/home/HomeNoticeSection.test.tsx`
   - 0 件表示:
     - タイトルと空メッセージのみ表示され、カード `button` は 0 件
   - 1 件表示:
     - `items` に 1 件だけ渡した場合、カードが 1 件だけ描画される
   - 3 件 + `maxItems=2`:
     - 3 件渡しても 2 件に制限される
   - `maxItems` 未指定:
     - `DEFAULT_HOME_NOTICE_COUNT` (=2) 件まで表示される
   - `clampNoticeCount` ユーティリティ:
     - `undefined` / 0 / 1 / 2 / 3 / 4 などの入力に対し、1〜3 件に clamp されることを確認

2. `src/__tests__/home/HomeFeatureTiles.test.tsx`
   - `HOME_FEATURE_TILES` を渡した場合:
     - 少なくとも 6 個以上の `button` 要素が描画される（HomeFooterShortcuts と干渉しないよう「>=6」で判定）
   - `tiles={[]}` の場合:
     - 内部の静的定義が利用され、同様に 6 個以上のボタンが表示される
   - セクションタイトル:
     - `home.features.title` が辞書ロード後に解決され、"機能メニュー" が描画されることを `findByText` で確認
   - `HomeFeatureTile` 単体:
     - `isEnabled=false` かつ `onClick` 渡しあり: `aria-disabled="true"` となり、クリックしてもハンドラは呼ばれない
     - `isEnabled=true`: `aria-disabled` が外れ、クリック 1 回で `onClick` が 1 回呼ばれる

3. `src/__tests__/home/HomePage.test.tsx`
   - `next/navigation` / `createSupabaseServerClient` / `log.util` / 子コンポーネントを Jest モック
   - 認証・認可がすべて成功するパターンをモックし、`await HomePage()` で得た要素を `render()` して検証
   - 検証内容:
     - `HomeNoticeSection` / `HomeFeatureTiles` / `HomeFooterShortcuts` が 1 回ずつ呼び出される
     - `HomeNoticeSection` に渡される `items` 配列が 2 件のダミーデータを持つこと
     - `data-testid="home-notice-section"`, `home-feature-tiles`, `home-footer-shortcuts` をそれぞれ DOM 上で確認

### 4.2 Jest 実行結果

- コマンド: `npm test`
- 結果:
  - **Home 関連テスト 3 本はすべて PASS** しています。
  - ただし、プロジェクト全体としては既存の認証系テストが原因で FAIL しています。
    - `src/components/auth/AuthCallbackHandler/AuthCallbackHandler.test.tsx`
      - `supabase.auth.onAuthStateChange` を Jest モックした `supabase` に対して呼び出す際に `not a function` エラー
    - `src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx`
    - `src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.test.tsx`
      - これらのテストファイルでは `vitest` の `vi` を import しており、Jest 実行時に
        - "Vitest cannot be imported in a CommonJS module" エラー
      - プロジェクトには `npm run test:unit` (vitest) も存在するため、**Jest 用テストと Vitest 用テストが混在**している状況です。

> これら auth 系テストの問題は Home タスク範囲外と判断し、コードの修正は行っていません。レポート上は「既存の技術的負債」として記載しています。

### 4.3 Lint 実行結果

- コマンド: `npm run lint`
- 結果: **FAIL**
- エラー内容:
  - `src/components/common/HomeFooterShortcuts/HomeFooterShortcuts.tsx`
    - 119 行・133 行付近で `react/jsx-key` エラー（iterator 内の要素に `key` が不足）
- HomeFooterShortcuts は本タスクでコード変更を行っておらず、既存の Lint エラーです。
  - Home 画面用の `HomeFooterShortcuts` 自体は問題なく動作しており、UI 上の不具合も確認していません。

### 4.4 型チェック

- `package.json` に `type-check` / `typecheck` 等のスクリプトは定義されていません。
- コマンド: `npm run type-check`
  - 結果: `Missing script: "type-check"`

> 現状、型チェックは `tsc` を直接叩く運用か、別タスクで導入予定と推測されます。本タスクではスクリプト追加は行っていません。

---

## 5. Tailwind / UI に関するフィードバック

### 5.1 レイアウト・余白

- LoginPage と HomePage 両方で `max-w-md` / 中央寄せレイアウトを採用しており、SP ポートレート前提での一貫性があります。
- 上部ヘッダ (`AppHeader`) と下部ナビ (`HomeFooterShortcuts`) が固定表示のため、コンテンツエリアの `pt-28` / `pb-28` は **実測に応じて微調整の余地**があります。
  - 現状でも被りはありませんが、デバイスの安全領域（notch / home indicator）を考慮した padding ガイドラインが設計側にあるとより安全です。

### 5.2 お知らせカード

- 現在の Tailwind:
  - `rounded-2xl border border-gray-200 bg-white px-4 py-3 shadow-sm`
  - バッジ: `inline-flex items-center rounded-full bg-blue-50 px-2 py-0.5 text-blue-700 text-[11px]`
  - タイトル: `text-sm font-medium text-gray-900 line-clamp-2`
- 補足フィードバック:
  - 長いタイトルの 2 行制限 (`line-clamp-2`) は読みやすさと情報量のバランスが良く、設計意図に合致していると考えられます。
  - ただし Tailwind v4 以降の `line-clamp` プラグイン有無によってはビルド設定が必要になるため、**プロジェクト全体での利用方針**をどこかに明文化しておくとよいです。

### 5.3 機能タイル

- カードスタイル:
  - `flex flex-col items-start gap-1 rounded-2xl border px-3 py-3 text-left text-xs bg-white shadow-sm`
  - 無効状態: `cursor-default border-gray-100 text-gray-400`
- フィードバック:
  - 「すべて無効」の状態でもアイコン＋ラベル＋説明が視認しやすく、情報カードとしての役割は果たせています。
  - 将来的に `isEnabled=true` のタイルが出てきた際には、
    - `hover:bg-blue-50` 等のホバー表現
    - `aria-disabled` と `tabIndex` の関係
    を設計ガイドライン側に追記しておくと、他画面タイルとの一貫性を保ちやすくなります。

### 5.4 お知らせバッジの多言語化

- 現状: バッジ文言は固定テキスト `"お知らせ"`（日本語のみ）です。
- スクリーンショットでは EN/ZH 言語でもバッジだけ日本語で表示されています。
- 改善案:
  - `home.noticeSection.badge` のようなキーを辞書に追加し、各言語で自然なラベルに差し替える。
  - 実装側では `t('home.noticeSection.badge')` に切り替えるだけで対応可能です。

---

## 6. 設計側へのフィードバック・相談事項

1. **Server/Client 境界と HOME_FEATURE_TILES の責務分担**
   - 設計 ch04 では HomePage (Server Component) が `HOME_FEATURE_TILES` を持ち、子コンポーネントに渡す想定でした。
   - Next 16 + App Router の制約上、Server から Client へ `icon: Bell` のような **コンポーネント関数を含むオブジェクト** を渡すと実行時エラーになります。
   - そのため、実装では以下のように責務を変更しています。
     - Server: `tiles` はあくまで「設定情報」（今は `[]` 固定）だけを渡す
     - Client: `HOME_FEATURE_TILES`（React コンポーネントを含む）は Client 側に閉じる
   - 今後の設計では、「React コンポーネントを含む構造体は Client 側で完結させる」というポリシーを明記しておくと混乱が減ると考えます。

2. **既存テスト基盤 (Jest vs Vitest) の整理**
   - プロジェクトには Jest (`npm test`) と Vitest (`npm run test:unit`) が共存しており、
     - 一部テストは `vi` を import（Vitest 前提）
     - 実際のコマンドは Jest 実行
     という状態です。
   - Home タスクとしては既存テストに手を入れていませんが、以下のどちらかで基盤整理を行うと運用が安定します。
     - Jest に統一し、Vitest 依存のテストを Jest 形式に書き換える
     - Home 系コンポーネントは Jest、auth 系は Vitest など **役割を分け**、CI で両方のコマンドを別々に実行する

3. **Lint エラー (HomeFooterShortcuts の key)**
   - 現時点で `npm run lint` 実行時に `HomeFooterShortcuts.tsx` の `react/jsx-key` エラーが出ます。
   - Home タスクでは HomeFooterShortcuts のロジックには触れていないため、今回の編集とは独立した既存課題です。
   - どのタイミングで共通コンポーネントのリファクタリング（key 追加等）を行うか、別タスクとして整理しておくと良さそうです。

---

## 7. まとめ

- HomePage UI スケルトン（最新のお知らせ + 機能タイル）は、詳細設計 ch01〜ch05 の要件に沿って実装済みです。
- Home 関連の Jest + RTL テスト 3 本を追加し、**Home 系の挙動については自動テストでカバー** できています。
- `npm test` / `npm run lint` 実行時には、Home 以外の既存 auth 系コンポーネントの課題（Vitest 依存や Lint エラー）が残っていることを確認しましたが、本タスクではコード変更は行っていません。
- i18n 辞書はユーザ側で `ja/en/zh` すべてに Home 用セクションを追加済みであり、UI 上の表示・切替も良好です。

設計との最大の差分は「`HOME_FEATURE_TILES` を Server ではなく Client 側に持たせた点」です。これは Next.js の Server/Client 境界に起因する技術的制約であり、将来の設計ドキュメント更新時に明記しておく価値があると考えます。
