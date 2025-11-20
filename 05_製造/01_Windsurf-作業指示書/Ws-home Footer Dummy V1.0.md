# Windsurf 実行指示書: ホーム画面ダミーフッター共通化

* Document ID: WS-HomeFooterDummy_v1.0
* System: HarmoNet
* Target Component: ホーム画面ダミー + 共通 AppFooter / FooterShortcutBar
* Related Detail Design:

  * `D:\AIDriven\01_docs\04_詳細設計\00_共通部品\02_ログイン画面以外の共通部品詳細設計/common-frame-components-detail-design_v1.0.md`
  * `D:\AIDriven\01_docs\04_詳細設計\00_共通部品\02_ログイン画面以外の共通部品詳細設計/common-frame-components-db-design_v1.0.md`（将来の DB 連携時に参照）
* CodeAgent_Report 保存先:

  * `/01_docs/06_品質チェック/CodeAgent_Report_HomeFooterDummy_v1.0.md`

---

## 1. タスク概要

### 1.1 目的

MagicLink ログイン後に表示される **ダミーホーム画面** に対して、

* 現在一時実装されているフッターを削除し、
* 共通フレーム仕様の `AppFooter`（内部で `FooterShortcutBar` を使用）を適用する。
* フッター内のショートカットアイコンは **全て表示** するが、現時点で正しく動作させるのは **Logout ショートカットのみ** とする。

ホーム画面のコンテンツ領域（中央部分）は本タスクの対象外とし、既存のダミー表示を維持する。

### 1.2 スコープ

* 対象画面:

  * MagicLink ログイン後に遷移するダミーホーム画面（現行のルーティングに従う）
* 実施範囲:

  * ダミーフッター削除
  * 共通 `AppFooter` の組み込み
  * `FooterShortcutItem[]` の固定配列定義
  * Logout ショートカットの動作実装（Supabase ログアウト + `/login` 遷移）
* 非対象:

  * `footer_shortcuts` テーブルとの DB 連携
  * HOME 画面コンテンツの UI / ロジック
  * 他画面へのフッター適用

---

## 2. 参照仕様

### 2.1 共通フレーム仕様

* `D:\AIDriven\01_docs\04_詳細設計\00_共通部品\02_ログイン画面以外の共通部品詳細設計/common-frame-components-detail-design_v1.0.md`

  * AppFooter
  * FooterShortcutBar
  * FooterShortcutItem の構造

本タスクでは、これらの仕様に従い、ホーム画面に共通フッターを組み込む。

### 2.2 ログアウト仕様（前提）

* Supabase Auth セッションを `signOut` で終了させる。
* ログアウト完了後、`/login` へ遷移する。

既存のログアウト処理がある場合は、それを呼び出す形で統一する。

---

## 3. 実装方針

### 3.1 ダミーホーム画面のフッター差し替え

1. ダミーホーム画面コンポーネントから、既存の一時的なフッター JSX を削除する。
2. 代わりに、共通フレームの `AppFooter` を配置する。
3. `AppFooter` 内部で `FooterShortcutBar` が表示される前提で、`FooterShortcutItem[]` を Props 経由で渡す。

### 3.2 FooterShortcutItem 固定配列

本タスクでは、DB 連携を行わず、**固定配列**でショートカットを定義する。

* 表示するショートカットの例（キー名・ラベルキー・アイコン名は詳細設計書に合わせて調整）：

  * `home` / `footer.shortcuts.home` / `Home`
  * `boards` / `footer.shortcuts.boards` / `PanelsTopLeft`
  * `facility` / `footer.shortcuts.facility` / `CalendarClock`
  * `account` / `footer.shortcuts.account` / `User`
  * `logout` / `footer.shortcuts.logout` / `LogOut`

* 要件:

  * アイコンおよびラベルは **全て表示** する。
  * 現時点で動作させるのは `logout` のみとし、それ以外はクリックしても何も起こらない（no-op）。

### 3.3 クリック挙動のルール

FooterShortcutBar 側、もしくはホーム画面側のクリックハンドラにて、以下のルールを実装する。

1. `item.key === 'logout'` の場合:

   * Supabase Auth `signOut`（または既存の logout ハンドラ）を実行する。
   * ログアウト完了後、`/login` へ遷移する。

2. `item.key !== 'logout'` の場合:

   * 現時点では何も行わない（クリックしても画面遷移も処理も起こさない）。

3. 将来、各ショートカットに対応する画面が実装されたタイミングで、

   * `item.href` を設定し、
   * `router.push(item.href)` を行う実装に差し替え／拡張する。
     （本タスクではまだ行わない。）

---

## 4. 実装ステップ

※ ファイルパスやコンポーネント名は、実プロジェクト構成に合わせて読み替えること。

1. **対象ホーム画面コンポーネントの特定**

   * MagicLink ログイン後に遷移するホーム画面コンポーネントを特定する。

2. **既存フッター実装の削除**

   * ホーム画面 JSX 内の一時的なフッター領域を削除する。

3. **共通 AppFooter の配置**

   * ホーム画面のレイアウト内で、画面下部に `AppFooter` を配置する。
   * AppHeader がすでに共通仕様に沿っている場合は、そのまま利用する。

4. **FooterShortcutItem 固定配列の定義**

   * ホーム画面、または上位レイアウトで `FooterShortcutItem[]` を固定配列として定義する。
   * 上記 5 種類（home / boards / facility / account / logout）を定義し、`logout` 以外の `href` は空文字のままとする。

5. **FooterShortcutBar への Props 渡し**

   * `AppFooter` 経由で `FooterShortcutBar` に `items: FooterShortcutItem[]` を渡す。

6. **クリックハンドラ実装**

   * `logout` クリック時に Supabase ログアウト + `/login` 遷移を行うハンドラを実装する。
   * それ以外のショートカットは、クリック時に何も行わないように実装する。

7. **動作確認**

   * MagicLink ログイン → ダミーホーム画面表示。
   * フッターに 5 つのショートカットが表示されていること。
   * Logout 以外をタップしても画面遷移しないこと。
   * Logout をタップすると Supabase セッションが終了し、`/login` に戻ること。

---

## 5. テスト観点（概要）

1. 表示確認

   * ダミーホーム画面で、共通 AppFooter のレイアウトとアイコン表示が詳細設計どおりであること。

2. Logout 挙動

   * Logout ショートカットタップで Supabase セッションが削除されること。
   * `/login` にリダイレクトされること。

3. 他ショートカットの無効挙動

   * home / boards / facility / account の各ショートカットをタップしても、画面遷移やエラーが発生しないこと。

4. 回帰影響

   * ログイン画面、MagicLink フローに影響が出ていないこと。

---

## 6. CodeAgent_Report

本タスクに対する CodeAgent_Report は、以下に保存する。

* `/01_docs/06_品質チェック/CodeAgent_Report_HomeFooterDummy_v1.0.md`

レポートには、少なくとも次を含めること。

* Lint / 型チェック / ビルド結果
* 実施したテスト観点と結果
* 変更ファイル一覧
* 自己評価スコア（平均 9/10 以上を目標）
