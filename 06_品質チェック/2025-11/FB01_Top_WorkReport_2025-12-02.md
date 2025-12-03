# FB-01 施設予約TOP画面 作業レポート（2025-12-02）

## 1. 作業時間
- 開始: 2025-12-02 朝
- 終了: 2025-12-02 24:30 頃
- 所要時間: 約 10.5 時間（設計確認＋実装＋UI調整）

## 2. 目的
- 施設予約TOP画面（FB-01）を、基本設計・モックアップ・UIガイドに沿って**作り直す**。
- 施設利用説明の多言語対応（JA/EN/ZH）＋翻訳キャッシュ仕様を反映。
- 施設名・利用時間・カレンダーなど、実際の DB データに基づいて表示。
- スタイル（枠線、色、タイポグラフィ）を TKD デザインに合わせて調整。

## 3. 実施内容サマリ

### 3.1 サーバーサイド実装（`app/facilities/page.tsx`）
- Supabase Auth によるユーザ認証＆`user_tenants` から `tenant_id` 解決。
- Service Role クライアントで以下を取得:
  - `facilities`（集会室・ゲスト駐車場）
  - `facility_settings`（利用時間、料金、連続利用日数など）
- `tenant_settings.config_json.facility.usageNotes` から
  - 施設IDごとの `ja` / `en` / `zh` 利用説明を読み出し。
- 認証エラー・テナント未所属時のリダイレクト処理を Board / Home と同等レベルで実装。
- 取得結果を [FacilityTopPage](cci:1://file:///d:/Projects/HarmoNet/src/components/facility/FacilityTopPage/FacilityTopPage.tsx:61:0-349:2) に Props 渡し。

### 3.2 クライアント実装（[FacilityTopPage.tsx](cci:7://file:///d:/Projects/HarmoNet/src/components/facility/FacilityTopPage/FacilityTopPage.tsx:0:0-0:0)）

#### 施設選択・情報カード
- ドロップダウン:
  - DB の `facility_type` を基に、[facility.json](cci:7://file:///d:/Projects/HarmoNet/public/locales/zh/facility.json:0:0-0:0) の
    - JA: 集会室 / ゲスト用駐車場
    - EN: Community room / Guest parking
    - ZH: 会议室 / 访客停车位
  - を使用して表示名をローカライズ。
  - UI:
    - `border-2 border-gray-300` の枠
    - `ChevronDown`（青 / 太めの線）を右端に重ね表示。
    - フォントサイズは周辺コントロールと揃えて `text-xs` に統一。
- 利用時間チップ:
  - `facility_settings.available_from_time` / `available_to_time` を表示。
  - 表示ラベルは [facility.json](cci:7://file:///d:/Projects/HarmoNet/public/locales/zh/facility.json:0:0-0:0) の `top.usageTimeLabel`（JA/EN/ZH）を使用。
  - 見た目: `rounded-md bg-blue-50 text-blue-700` のピル型。

- 利用説明テキスト:
  - 現在の UI 言語に応じて
    - EN: `en` → `ja` fallback
    - ZH: `zh` → `ja` fallback
    - JA: `ja`
  - 「本文」は `tenant_settings.config_json` で事前に投入したテキストをそのまま表示。
  - 日本語版は数値の半角化済み。

- 翻訳ボタン（Languagesアイコン）:
  - JA 以外のときのみ表示。
  - 対象言語にキャッシュがあれば disabled（グレー）で表示。
  - まだ API 連携はせず、UI 挙動のみ BoardDetail と揃える準備状態。

#### カレンダー UI
- 月表示:
  - 当月を初期表示、先月 / 次月ボタンで前後移動。
  - JA: 「先月 / 次月」
  - EN: 「Previous month / Next month」
  - ZH: 「上个月 / 下个月」
- 日付グリッド:
  - `getDay()` を用いて 1 日の曜日にあわせて**先頭に空セルを挿入**し、ヘッダと列が一致するよう修正。
  - 日付セルスタイル:
    - Today: `border-blue-500 bg-blue-50 text-blue-700 font-semibold`
    - Available（平日）: `border-blue-200 bg-white text-gray-800 hover:bg-blue-50`
    - Saturday: `border-yellow-400 bg-white text-yellow-600 hover:bg-yellow-50`
    - Sunday: `border-red-400 bg-white text-red-500 hover:bg-red-50`
    - Past days: `border-gray-200 bg-gray-50 text-gray-400`（disabled）

- 曜日ヘッダ:
  - JA: `日 月 火 水 木 金 土`
  - EN: `Sun. Mon. Tue. Wed. Thu. Fri. Sat.`
  - ZH: `周日 周一 周二 周三 周四 周五 周六`
  - いずれも `facility.json.top.weekdays.*` から取得。

- 凡例（カード内、中央寄せ）:
  - 本日（青）
  - 予約可能（薄い青）
  - 土曜（黄）
  - 日曜（赤）
  - 「過去日」は UI 上は自明と判断し、凡例から除外。

### 3.3 i18n 設計の整理
- [StaticI18nProvider](cci:1://file:///d:/Projects/HarmoNet/src/components/common/StaticI18nProvider/StaticI18nProvider.tsx:42:0-129:2) が [common.json](cci:7://file:///d:/Projects/HarmoNet/public/locales/zh/common.json:0:0-0:0) のみ読む仕様を維持しつつ、
  - 施設画面内で `/locales/{locale}/facility.json` を**個別にロード**。
  - `tf(key)` ヘルパーで facility.json 専用の翻訳を解決。
- [facility.json](cci:7://file:///d:/Projects/HarmoNet/public/locales/zh/facility.json:0:0-0:0) に以下を追加:
  - `top.selectFacility`
  - `top.usageTimeLabel`
  - `top.calendarTitle`
  - `top.prevMonth` / `top.nextMonth`
  - `top.legend.*`（today / available / saturday / sunday）
  - `top.weekdays.*`（sun..sat）
  - `top.facilityName.room / parking`
- これにより、施設TOPの静的文言は common.json から切り離し。

### 3.4 スタイル微調整（ラウンド、枠線、色）
- ドロップダウン:
  - アイコンサイズ／線幅／色を複数回微調整し、他画面との整合性と視認性を確保。
- 利用時間チップの角丸:
  - `rounded-full` → `rounded-md` に変更し、全体の角丸ルールと統一。
- カレンダー:
  - 日付のフォントサイズ `text-[12px]` に調整。
  - 先月／次月ボタンの枠線を `border-2 border-gray-200` に統一。

## 4. 課題・懸念点
- i18n 全体（common.json の設計、DB での管理）は、システム横断で見直した方がよいが、FB-01 の範囲では facility.json 分離までに留めた。
- 日付クリック時の遷移（FB-02/FB-03）や、実際の予約状況の反映は未実装（次フェーズ）。