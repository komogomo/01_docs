# 共通フレームコンポーネント DB 詳細設計書

* Document ID: common-frame-components-db-design_v1.0
* System: HarmoNet
* Category: 04_詳細設計 / 00_共通部品 / 02_ログイン画面以外の共通部品詳細設計
* Related Docs:

  * `common-frame-components-detail-design_v1.0.md`（AppHeader / AppFooter / FooterShortcutBar 詳細設計）
* Version: 1.0
* Status: Draft
* Last Updated: 2025-11-20

---

## ChangeLog

| Version | Date       | Author | Summary                                                              |
| ------- | ---------- | ------ | -------------------------------------------------------------------- |
| 1.0     | 2025-11-20 |        | 初版作成。AppFooter / FooterShortcutBar 用ショートカットテーブルの DB / RLS / 削除方針を定義。 |

---

## ch01. 本書の位置付け

### 1.1 目的

本書は、`common-frame-components-detail-design_v1.0.md` で定義される以下の共通フレームコンポーネントのうち、

* AppFooter
* FooterShortcutBar

が利用するショートカットメニュー情報を格納するデータベース構造および RLS・削除方針を定義する。

本書は、ログイン後メインレイアウト（MainLayout 仮称）や HOME 画面の詳細設計から参照されることを想定し、

* テーブル定義
* RLS ポリシー
* 削除方針

を記載する。

### 1.2 範囲

本書が対象とするのは、以下に限定する。

* フッターショートカット（FooterShortcutBar）に表示するメニュー群
* ログイン後共通フレームで利用するショートカット定義

以下は本書の範囲外とする（別設計書で扱う）。

* ユーザー削除時のカスケード（`auth.users` / `user_tenants` / `user_roles` など）
* 掲示板・施設予約など、個別ドメイン機能の DB 設計
* 動的翻訳・音声読み上げ等の機能に関する DB 設計

### 1.3 関連ドキュメント

* `common-frame-components-detail-design_v1.0.md`

  * AppHeader / AppFooter / FooterShortcutBar の UI / ロジック詳細設計
* ログイン後メインレイアウト詳細設計（作成予定）
* HOME 画面詳細設計（作成予定）

---

## ch02. フッターショートカットテーブル設計

### 2.1 テーブル一覧

本書では、共通フレーム用に以下のテーブルを定義する。

| 論理名            | 物理名                | 用途                                                         |
| -------------- | ------------------ | ---------------------------------------------------------- |
| フッターショートカットマスタ | `footer_shortcuts` | テナントごとに、AppFooter の FooterShortcutBar に表示するショートカット項目を管理する。 |

### 2.2 フッターショートカットマスタ `footer_shortcuts`

#### 2.2.1 役割

* ログインユーザーが所属するテナントごとに、AppFooter に表示するショートカットボタンを定義する。
* FooterShortcutBar コンポーネントが受け取る `FooterShortcutItem[]` の元データとなる。
* 管理者があらかじめ登録した固定メニューを前提とし、エンドユーザーによるカスタマイズは対象外とする。

#### 2.2.2 カラム定義

| No | 論理名           | 物理名          | 型           | NOT NULL | デフォルト               | 説明                                                                       |
| -- | ------------- | ------------ | ----------- | -------- | ------------------- | ------------------------------------------------------------------------ |
| 1  | テナントID        | tenant_id    | uuid        | YES      | -                   | 所属テナントを表す。RLS で現在のテナントと一致する行のみ参照可能とする。                                   |
| 2  | ショートカットID     | id           | uuid        | YES      | `gen_random_uuid()` | 主キー。アプリ内部での識別に使用する。                                                      |
| 3  | ショートカットキー     | shortcut_key | text        | YES      | -                   | アプリ側で機能を識別するキー。例: `home`, `boards`, `facilities`。                        |
| 4  | 表示ラベル i18n キー | label_key    | text        | YES      | -                   | StaticI18nProvider の辞書キー。例: `footer.shortcuts.home`。実際の文言は i18n 辞書で管理する。 |
| 5  | 遷移先パス         | href         | text        | YES      | -                   | Next.js の遷移先パス。例: `/home`, `/boards`。                                    |
| 6  | アイコン識別子       | icon_name    | text        | YES      | -                   | フロントエンドで使用するアイコン名。例: Lucide のアイコン名。                                      |
| 7  | 並び順           | sort_order   | integer     | YES      | 0                   | フッター内での表示順。昇順に並べて表示する。                                                   |
| 8  | 有効フラグ         | is_active    | boolean     | YES      | true                | false の場合、そのテナントではショートカットを表示しない。論理削除用途も兼ねる。                              |
| 9  | 作成日時          | created_at   | timestamptz | YES      | `now()`             | レコード作成日時。                                                                |
| 10 | 更新日時          | updated_at   | timestamptz | YES      | `now()`             | レコード更新日時。トリガなどで自動更新する。                                                   |
| 11 | 作成者ユーザーID     | created_by   | uuid        | NO       | null                | 管理者画面からの作成者を追跡したい場合に利用する。現時点では null 許容。                                  |
| 12 | 更新者ユーザーID     | updated_by   | uuid        | NO       | null                | 管理者画面からの更新者を追跡したい場合に利用する。現時点では null 許容。                                  |

#### 2.2.3 インデックス設計

本テーブルでは、以下以外のインデックスは定義しない。

* 主キー定義により自動作成されるインデックス
* 一意制約 `(tenant_id, shortcut_key)` により自動作成されるインデックス

データ件数は各テナント数件程度を想定しており、追加のインデックスは不要と判断する。

#### 2.2.4 制約

* 主キー: `PRIMARY KEY (id)`
* 一意制約: `UNIQUE (tenant_id, shortcut_key)`

  * 同一テナント内で同じショートカットキーを重複登録しないため。

---

## ch03. RLS ポリシー設計

### 3.1 対象

* テーブル: `footer_shortcuts`

### 3.2 基本方針

* ログインユーザーは、所属テナントのショートカットのみ参照できる。
* 一般利用者は `SELECT` のみを許可する。
* テナント管理者以上のロールのみ `INSERT` / `UPDATE` / `DELETE` を許可する。

### 3.3 SELECT ポリシー

* 対象ロール: 認証済みユーザー
* 条件:

  * `tenant_id = current_setting('request.jwt.claims.tenant_id', true)::uuid`
  * `is_active = true`

この条件により、ユーザーは所属テナントかつ有効フラグが立っているショートカットのみ取得できる。

### 3.4 INSERT / UPDATE / DELETE ポリシー

* 対象ロール: テナント管理者ロール（名称はロール設計書に従う）
* 条件:

  * `tenant_id = current_setting('request.jwt.claims.tenant_id', true)::uuid`

この条件により、テナント管理者は自テナント分のみショートカット定義を登録・更新・削除できる。

---

## ch04. 削除方針

### 4.1 基本方針

* ショートカット定義は、アプリのナビゲーションに直結するため、原則として論理削除（`is_active = false`）を基本とする。
* 完全に不要になったテナントやショートカットを整理する場合のみ、管理者による物理削除を想定する。

### 4.2 テナント削除時の扱い

* テナント削除時には、当該テナントの `footer_shortcuts` 行を削除対象とする。
* 具体的なテナント削除処理の流れは、テナント管理に関する DB 詳細設計書で定義する。

---

## ch05. MainLayout / HOME 詳細設計への引き渡し

### 5.1 FooterShortcutBar へのデータ引き渡し

`common-frame-components-detail-design_v1.0.md` で定義された FooterShortcutBar の Props 仕様に従い、本テーブルから取得したデータを `FooterShortcutItem[]` にマッピングして渡す。

* 主なマッピング例

  * `shortcut_key` → 内部キー
  * `label_key` → StaticI18nProvider で解決する文言キー
  * `href` → Next.js の `<Link>` コンポーネントの `href`
  * `icon_name` → アイコンコンポーネントの選択
  * `sort_order` → 表示順

### 5.2 取得条件（概要）

* 取得対象:

  * `tenant_id` が現在のテナント
  * `is_active = true`
* 並び順:

  * `sort_order` 昇順

上記条件に従って取得したデータを、FooterShortcutBar の描画用データとして利用する。
