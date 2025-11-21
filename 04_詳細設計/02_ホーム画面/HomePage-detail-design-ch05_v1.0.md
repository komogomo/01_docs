# HomePage 詳細設計書 ch05：画面挙動・状態遷移・メッセージ仕様

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 5 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 5.1 本章の目的

本章では、HomePage（/home）における **画面挙動・状態遷移・メッセージ仕様** を定義する。

* `/home` 初期表示時の挙動
* お知らせセクションの件数別表示・0件時の挙動
* 機能タイルの有効/無効時の挙動
* HOME 固有メッセージ・ラベルの一覧

を明確にし、実装とテスト（Jest/RTL）の基準とする。

---

## 5.2 HomePage 初期表示フロー

### 5.2.1 正常系フロー（MVP）

1. 利用者が MagicLink ログインを完了し、`/auth/callback` から `/home` に遷移する。
2. `HomePage` コンポーネントがマウントされる。
3. `MOCK_HOME_NOTICE_ITEMS` および `HOME_FEATURE_TILES` が読み込まれる。
4. `HomeNoticeSection` に `items`（ダミー配列）と `maxItems`（2）を渡す。
5. `HomeFeatureTiles` に `tiles`（静的定義配列）を渡す。
6. HOME 画面が描画される。

MVP 段階では、Supabase からのデータ取得・テナント設定取得は行わず、
初期表示時は常に同じダミー内容が表示される。

### 5.2.2 未ログイン状態でのアクセス

* `/home` に直接アクセスされた際の未ログイン判定・リダイレクトは、
  上位のレイアウト／ミドルウェア側で処理する前提とし、HomePage ではガードロジックを持たない。
* HomePage 側では「認証済みセッションが存在する」前提でのみ挙動を定義する。

---

## 5.3 お知らせセクションの挙動

### 5.3.1 件数別表示パターン

`HomeNoticeSection` は、Props `items` と `maxItems` に基づき、以下のように動作する。

1. `items.length === 0`

   * セクションタイトルのみ表示し、本文として次のメッセージを 1 行表示する。

     * 文言：`home.noticeSection.emptyMessage`
   * カードは描画しない。

2. `1 <= items.length <= maxItems`（かつ maxItems は 1〜3 に clamp 済み）

   * 先頭から `items.length` 件のカードを描画する。

3. `items.length > maxItems`

   * 先頭から `maxItems` 件のみカードを描画する。
   * それ以降のアイテムは表示しない（「もっと見る」導線も MVP では未実装）。

### 5.3.2 カードタップ時の挙動

* MVP 段階では、カード全体を `button` 要素として描画するが、`onClick` は未設定とし、
  タップしても画面遷移は発生しない。
* 将来、掲示板詳細画面への導線を実装する際に、以下のような挙動とする：

  * カードタップ → `router.push('/board/' + item.id)` などで掲示板詳細へ遷移。

### 5.3.3 ローディング・エラー時挙動（将来）

Supabase 連携導入後の拡張として、以下の挙動を想定する（MVP では未実装）。

* `loading === true`

  * セクションタイトル下にスケルトンカード（2件分）を表示する。
* `error !== null`

  * セクションを非表示とする、もしくは「現在お知らせを読み込めませんでした。」等の
    エラーメッセージを簡易表示する（メッセージ仕様は将来定義）。

本章では、拡張ポイントとしてのみ記載し、現時点での実装対象外とする。

---

## 5.4 機能タイルの挙動

### 5.4.1 有効/無効状態

`HomeFeatureTile` は、Props `isEnabled` に応じて、以下のように挙動を変える。

1. `isEnabled === false`（MVP のデフォルト）

   * ボタンの `onClick` は noop（何もしない）。
   * 見た目：

     * 通常と同じカードスタイルだが、hover 時の色変更や押下感を抑える。
     * カーソル：`cursor: default`（PC 表示時）。
   * `aria-disabled="true"` を付与し、スクリーンリーダーに「無効」であることを伝える。

2. `isEnabled === true`（将来）

   * `onClick` が渡されている場合のみ、タップで遷移処理を実行する。
   * 見た目：

     * hover 時に軽い色変更・シャドウ強調など、押下可能であることが分かる表現を付与。
     * カーソル：`cursor: pointer`。
   * `aria-disabled="false"` または属性省略。

### 5.4.2 タイル別挙動（将来）

将来的に `onClick` を実装する際の想定動作をまとめる（MVP ではリンク無効）。

* T1 お知らせ（featureKey: 'NOTICE'）

  * 挙動例：`/board?tag=NOTICE` へ遷移し、NOTICE フィルタの掲示板TOPを表示する。
* T2 掲示板（'BOARD'）

  * 挙動例：`/board` へ遷移し、ALL フィルタの掲示板TOPを表示する。
* T3 施設予約（'FACILITY'）

  * 挙動例：`/facility` へ遷移し、施設予約TOPを表示する。
* T4 運用ルール（'RULES'）

  * 挙動例：`/board?tag=RULES` または `/rules` へ遷移する。
* T5 通知設定（'NOTIFICATION'）

  * 挙動例：`/settings/notifications` へ遷移する。
* T6 ダミー（'DUMMY'）

  * 挙動例：当面は常に `isEnabled = false` とし、遷移先は未定。

本詳細設計では、遷移先 URL はあくまで「候補」として位置づけ、
実際のルーティング仕様は各機能の詳細設計で確定させる。

---

## 5.5 HOME 固有メッセージ・ラベル仕様

### 5.5.1 セクションタイトル・メッセージ

HOME 画面における固定テキストは、StaticI18nProvider による i18n キーで管理する。

* お知らせセクション

  * タイトル：`home.noticeSection.title`

    * ja: 「最新のお知らせ」
  * 0件時メッセージ：`home.noticeSection.emptyMessage`

    * ja: 「現在表示するお知らせはありません。」

* 機能タイルセクション

  * タイトル：`home.features.title`

    * ja: 「機能メニュー」 など（最終文言は i18n 定義書で確定）

### 5.5.2 機能タイルのラベル・説明

各タイルのラベル・説明は、次の i18n キーで管理する。

* お知らせタイル（T1）

  * ラベル：`home.tiles.notice.label`
  * 説明：`home.tiles.notice.description`

* 掲示板タイル（T2）

  * ラベル：`home.tiles.board.label`
  * 説明：`home.tiles.board.description`

* 施設予約タイル（T3）

  * ラベル：`home.tiles.facility.label`
  * 説明：`home.tiles.facility.description`

* 運用ルールタイル（T4）

  * ラベル：`home.tiles.rules.label`
  * 説明：`home.tiles.rules.description`

* 通知設定タイル（T5）

  * ラベル：`home.tiles.notification.label`
  * 説明：`home.tiles.notification.description`

* ダミータイル（T6）

  * ラベル：`home.tiles.dummy.label`
  * 説明：`home.tiles.dummy.description`

各キーに対応する実際の文言（ja/en/zh）は、i18n 設計書および `home.json` で定義する。
本書ではキー名のみを固定し、文言は別管理とする。

---

## 5.6 アクセシビリティ挙動

### 5.6.1 お知らせセクション

* セクション要素に `aria-labelledby` を付与し、タイトルとセクションの関連付けを行う。
* 各カードは `button` 要素とし、キーボードフォーカス可能とする。
* スクリーンリーダー向けには、少なくとも以下を読み上げる：

  * タイトル全文
  * 公開日
  * （任意）「お知らせ」である旨のラベル

### 5.6.2 機能タイル

* 各タイルは `button` 要素とし、`aria-disabled` により有効/無効状態を示す。
* アイコンには `aria-hidden="true"` を付与し、ラベル・説明テキストを主たる読み上げ対象とする。
* キーボード操作のみでも、全タイルを順番にフォーカス・選択できることを前提とする。

---

## 5.7 本章まとめ

* `/home` 初期表示時は、ダミーお知らせと静的タイル定義を用いて、
  即時に HOME 画面を描画するシンプルな挙動とする。
* お知らせセクションは、件数 0/1〜max の場合で挙動を分け、
  0件時は専用メッセージを表示し、カードは描画しない。
* 機能タイルは、`isEnabled` によって有効/無効を切り替える仕組みを持たせ、
  MVP 段階では全タイル無効（リンクなし）とする。
* HOME 固有のラベル・メッセージは i18n キーで管理し、本書ではキー名を固定する。
* アクセシビリティとして、セクションタイトルとの関連付け・`aria-disabled`・
  スクリーンリーダー向け読み上げ内容を定義し、実装・テストの基準とする。

---

**End of Document**
