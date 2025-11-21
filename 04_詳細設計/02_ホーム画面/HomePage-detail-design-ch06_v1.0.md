# HomePage 詳細設計書 ch06：結合構成（共通部品・他画面との関係）

**Document:** HomePage 詳細設計書（/home コンテンツ領域）
**Chapter:** 6 / 8
**Component ID:** H-00 HomePage
**Version:** v1.0
**Date:** 2025-11-21
**Author:** TKD / Tachikoma
**Status:** Draft

---

## 6.1 本章の目的

本章では、HomePage（/home）と以下の要素との **結合構成** を整理する。

* 共通部品（AppHeader / LanguageSwitch / StaticI18nProvider / AppFooter）
* ログインフロー（LoginPage / AuthCallbackHandler）
* 掲示板・施設予約・通知設定などの他画面

HomePage 自体はコンテンツ領域の UI に責務を限定し、他コンポーネント・他画面との境界を明確にする。

---

## 6.2 共通部品との結合

### 6.2.1 AppHeader（C-01）

* 配置位置：画面最上部（`HomePage` の直下）。
* 役割：HarmoNet 全画面共通のヘッダーバーを提供する。
* 主な要素（共通部品側で定義）：

  * ロゴ・アプリ名
  * 言語切替ボタン（LanguageSwitch）
  * 通知アイコン（Bell）※設計上は追加予定
* HomePage から見た使用方法：

```tsx
export default function HomePage() {
  return (
    <StaticI18nProvider>
      <div className="min-h-screen flex flex-col">
        <AppHeader />
        {/* Home コンテンツ領域 */}
        <AppFooter />
      </div>
    </StaticI18nProvider>
  );
}
```

* HomePage は AppHeader の Props を直接制御しない前提とし、
  言語切替や通知アイコンの挙動は共通部品側の責務とする。

### 6.2.2 LanguageSwitch（C-02）

* 配置位置：AppHeader 内（共通部品設計に従う）。
* HomePage は LanguageSwitch を直接配置しない。
* 言語切替の結果は StaticI18nProvider を通じて Home コンテンツにも反映される。

### 6.2.3 StaticI18nProvider（C-03）

* 配置方針：

  * グローバルレイアウトで全体をラップする構成、または HomePage 直下でラップする構成のいずれか。
  * LoginPage 詳細設計と整合するように、プロジェクト共通のレイアウト設計に従う。
* HomePage の想定：

  * `t()` フック／ヘルパーを利用して、セクションタイトル・メッセージ・タイルラベル等を取得する。
  * i18n キー名は ch04 / ch05 で定義したものを使用する。

### 6.2.4 AppFooter（C-04）

* 配置位置：画面最下部（`HomePage` の直下）。
* 役割：

  * ログアウトボタン（有効）
  * 将来のフッターショートカット（お知らせ／掲示板／施設予約など）の表示
* 現仕様では、ログアウト以外のリンクは無効のままとし、
  表示のみ行う（クリック時の遷移は発生させない）前提とする。
* HOME 機能タイルとの関係：

  * AppFooter の「掲示板」アイコンと HOME の「掲示板」タイルは、将来同一遷移先を持つ想定。
  * HOME 機能タイルは AppFooter の補完（視覚的なポータル）として位置づける。

---

## 6.3 ログインフローとの関係

### 6.3.1 遷移元：LoginPage / AuthCallbackHandler

* 認証フローの概要（詳細は LoginPage・AuthCallbackHandler 詳細設計書参照）：

1. 利用者が LoginPage 上の MagicLinkForm にメールアドレスを入力し、MagicLink を送信する。
2. メール内の MagicLink をクリックすると、`/auth/callback` に遷移する。
3. AuthCallbackHandler が Supabase Auth と連携し、セッションを確立する。
4. セッション確立後、`/home` にリダイレクトする。

* HomePage の前提：

  * 認証に失敗した状態で `/home` にアクセスされないよう、LoginPage/Callback 側で制御される前提とする。
  * HomePage 自身はセッションチェック・リダイレクトロジックを持たない。

### 6.3.2 ログアウトとの関係

* ログアウト操作は AppFooter（C-04）のログアウトボタンから行う。
* ログアウト処理の詳細は、共通部品側もしくは Auth 関連の設計書で定義し、
  HomePage は「ログアウト後に /login 等へ遷移する」結果のみを前提とする。

---

## 6.4 掲示板機能との関係

### 6.4.1 掲示板TOP

* 掲示板TOP 画面（BoardTop）は、テナント内の掲示情報を一覧表示する画面。
* HomePage との関係：

  * お知らせセクション：NOTICE タグ付き掲示の一部をハイライト表示。
  * HOME 機能タイル（T1〜T4）：掲示板TOPのフィルタ状態を変えたショートカットとして機能する予定。

### 6.4.2 掲示板詳細

* 掲示板詳細画面（BoardDetail）は、1件分の掲示内容を表示する画面。
* HomePage との関係：

  * お知らせカードタップ → 将来 BoardDetail (`/board/{id}` 等) へ遷移する想定。
* BoardDetail 側では、閲覧権限・PDF 添付プレビュー・音声読み上げなど、
  掲示板固有の仕様を実装する（HomePage では扱わない）。

### 6.4.3 タグ/フィルタキー

* HomePage で想定するフィルタキー：

  * `ALL`：全掲示
  * `NOTICE`：お知らせ
  * `RULES`：運用ルール
* 実際の実装では、BoardTop 側の URL 設計（例：`/board?tag=NOTICE`）と連携する。
* HomePage 詳細設計では、フィルタキーの論理名のみを前提とし、
  URL やクエリパラメータ形式の最終決定は掲示板詳細設計書に委譲する。

---

## 6.5 施設予約・通知設定機能との関係

### 6.5.1 施設予約機能

* 施設予約画面は、共用施設の予約状況表示・予約申請を行う画面。
* HomePage の「施設予約」タイル（T3）は、この画面の入口として機能する予定。
* 遷移先 URL（例：`/facility`）や画面構成は、施設予約詳細設計書側で定義する。

### 6.5.2 通知設定機能

* 通知設定画面は、PUSH/メール通知の受信設定を行う画面。
* HomePage の「通知設定」タイル（T5）は、この画面の入口として機能する予定。
* 遷移先 URL（例：`/settings/notifications`）や設定項目は、通知機能の詳細設計書側で定義する。

---

## 6.6 他画面から HomePage への導線

* 今後、以下のような画面から HomePage への戻り導線が追加される可能性がある：

  * 掲示板詳細画面（ヘッダーの「HOME」アイコン等）
  * 施設予約画面（完了画面から HOME に戻るボタン）
  * 通知設定画面（保存後に HOME に戻る選択肢）
* HomePage 側では、これらの導線を特別に扱わず、
  単に `/home` への遷移先として受け入れる構造とする。

---

## 6.7 結合テスト観点（概要）

HomePage と他コンポーネント・他画面の結合観点を簡単に整理する。

1. LoginPage 〜 HomePage

   * MagicLink ログイン成功時に `/home` が表示されること。
   * 未ログイン時に直接 `/home` にアクセスすると、LoginPage にリダイレクトされること（上位責務）。

2. HomePage 〜 AppHeader/AppFooter

   * HomePage 表示時に、共通ヘッダー・フッターが正しく描画されること。
   * フッターのログアウトボタンが動作し、ログイン画面へ戻ること。

3. HomePage 〜 掲示板機能

   * 将来、HOME お知らせカードから掲示板詳細へ遷移できること。
   * 掲示板関連タイル（お知らせ／掲示板／運用ルール）の遷移先が BoardTop と整合すること。

4. HomePage 〜 施設予約・通知設定

   * 将来、施設予約・通知設定タイルから各画面へ遷移できること。

詳細なテストケースは ch07（テスト観点）で定義する。

---

## 6.8 本章まとめ

* HomePage は、共通部品（AppHeader/LanguageSwitch/StaticI18n/AppFooter）と密接に結合しつつ、
  認証・RLS・各機能画面のロジックからは切り離された UI ポータルとして設計する。
* ログインフローとの結合は、`/auth/callback → /home` の遷移完了を前提とし、
  HomePage 自身はガードロジックを持たない。
* 掲示板・施設予約・通知設定との関係は、「入口としてのタイル」と「NOTICE ハイライト」のみとし、
  各機能の詳細仕様はそれぞれの設計書へ委譲する。
* 本章の結合構成を前提として、ch07 以降で結合テスト観点を整理し、
  Windsurf 実装・結合確認の基盤とする。

---

**End of Document**
