# B-01 BoardTop 詳細設計書 ch05 UI仕様・メッセージ v1.1

**Document ID:** HARMONET-COMPONENT-B01-BOARDTOP-DETAIL-CH05
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 5.1 本章の目的

本章では、掲示板 TOP 画面コンポーネント **BoardTop（B-01）** の UI 要素（レイアウト・ボタン・ラベル・状態表示）および i18n メッセージキーを定義する。
対象となる主な要素は以下の通りとする。

* フィルタ／タブ（scope 切替）
* 投稿一覧カード（カテゴリ・タイトル・本文サマリ・投稿者・日時・添付有無）
* 翻訳表示・翻訳ボタン
* 読み上げ（TTS）ボタン
* 新規投稿ボタン
* 空状態・エラー状態メッセージ

BoardTop は **一覧画面** であり、投稿の削除・編集は行わない。
削除・編集は BoardDetail（B-02）および B-03 BoardPostForm 側の責務とし、本画面では「参照＋新規投稿入口＋翻訳/TTS のトリガ」のみに機能を限定する。

---

## 5.2 画面構成（再掲）

* ヘッダー部

  * 画面タイトル（例: `board.top.title`）
  * scope 切替タブ（例: 全て / 自分の投稿 / 管理組合からのお知らせ）
* メイン部

  * 新規投稿ボタン
  * 投稿一覧カードのリスト
  * 空状態・エラー状態表示

---

## 5.3 scope 切替タブ

### 5.3.1 UI 要素

* タブ or セグメントコントロール（3 分割程度）

  * `board.top.scope.all`    : すべての投稿
  * `board.top.scope.mine`   : 自分の投稿
  * `board.top.scope.management` : 管理組合からのお知らせ

### 5.3.2 挙動

* タブ選択時に `scope` を変更し、一覧取得 API を再呼び出しする。
* 選択中のタブは強調表示し、視覚的に分かるようにする。

---

## 5.4 新規投稿ボタン

### 5.4.1 UI 要素

* ボタンラベル: `board.top.newPost`
* 表示条件: `canPost = true` の場合のみ表示。

### 5.4.2 挙動

* クリック/タップ時に B-03 BoardPostForm へ遷移する。

  * 遷移先例: `/board/new`
* 遷移先 URL はルーティング設計および B-03 詳細設計に従う。

---

## 5.5 投稿一覧カード UI

### 5.5.1 表示要素

1 件分の投稿カードには、次の要素を表示する。

* 上部

  * カテゴリバッジ（`board.top.category.*`）
  * タイトル
* 中央

  * 本文サマリ（原文 or 翻訳済み）
* 下部左側

  * 投稿者表示名（表示名モード適用後）
  * 投稿者種別ラベル（管理組合 / 一般利用者 等）
  * 投稿日時（ローカライズ済み）
* 下部右側

  * 添付アイコン（`hasAttachment = true` の場合のみクリップマーク等を表示）
* 下部アクション

  * 翻訳表示切替／翻訳ボタン
  * 読み上げ（TTS）ボタン

カード全体をタップ/クリックした場合は BoardDetail（B-02）へ遷移する。

### 5.5.2 本文サマリの表示ルール

* `hasTranslation = true` かつ `currentLanguage` が `baseLanguage` と異なる場合:

  * デフォルトで **翻訳済みサマリ**（`translatedPreview`）を表示する。
* `hasTranslation = false` の場合:

  * 日本語原文サマリ（`contentPreview`）を表示する。
  * 必要に応じて「翻訳」ボタン（5.6）を表示する。

サマリ生成ルール（何文字まで切るか等）は実装側に委ねるが、PC/スマホ問わず 2〜3 行程度に収まる長さを目安とする。

---

## 5.6 翻訳 UI

### 5.6.1 翻訳状態の種類

各投稿カードは、`BoardPostSummary` の以下の値をもとに翻訳状態を判定する。

* `baseLanguage`
* `currentLanguage`
* `hasTranslation`
* `translatedPreview`

### 5.6.2 翻訳 UI パターン

1. **原文のみ表示（翻訳キャッシュなし）**

   * 条件: `hasTranslation = false`
   * 表示:

     * 本文サマリ: 原文（`contentPreview`）
     * 下部に「翻訳」ボタンを表示。
   * ボタンラベル: `board.top.i18n.translate`

2. **翻訳済み表示**

   * 条件: `hasTranslation = true` かつ `currentLanguage != baseLanguage`
   * 表示:

     * 本文サマリ: 翻訳済みサマリ（`translatedPreview`）
     * 下部に切替リンクを表示。

       * 「原文で表示」: `board.top.i18n.viewOriginal`
       * 「翻訳で表示」: `board.top.i18n.viewTranslated`

3. **原文言語と UI 言語が同一**

   * 条件: `currentLanguage == baseLanguage`
   * 表示:

     * 本文サマリ: 原文（`contentPreview`）
     * 翻訳ボタン／切替は表示しない（翻訳の必要がないため）。

### 5.6.3 翻訳ボタン押下時の挙動

* `hasTranslation = false` のカードで「翻訳」ボタン押下:

  * B-04 BoardTranslationAndTtsService 経由で、該当投稿の翻訳を実行する。
  * 実行中はボタンラベルを `board.top.i18n.translating` に切り替え、スピナーを表示する。
  * 成功時:

    * `hasTranslation = true` となった新しい `BoardPostSummary` が反映され、本文サマリが翻訳済みに切り替わる。
  * 失敗時:

    * 控えめなエラーメッセージ（例: `board.top.i18n.error`）を画面下部などに表示し、原文サマリ表示に戻る。

翻訳エラーは BoardTop の UX を阻害しないようにし、画面全体のエラーとは別扱いとする。

---

## 5.7 読み上げ（TTS） UI

### 5.7.1 表示条件

* `isTtsAvailable = true` の投稿カードにのみ、TTS ボタンを表示する。
* `isTtsAvailable = false` の場合は TTS ボタンを非表示とする。

### 5.7.2 TTS ボタン

* ボタンラベル:

  * 再生中でない: `board.top.tts.play`
  * 再生中: `board.top.tts.stop`
* 再生対象テキスト:

  * `currentLanguage != baseLanguage` かつ `hasTranslation = true` の場合:

    * 翻訳済みサマリ（`translatedPreview`）を読み上げる。
  * それ以外の場合:

    * 原文サマリ（`contentPreview`）を読み上げる。

### 5.7.3 エラー時

* TTS API がエラーを返した場合:

  * 控えめなインラインメッセージ `board.top.tts.error` を表示する。
  * 再生中フラグやローディングフラグは解除する。

TTS の詳細なキャッシュやストリーミング制御は B-04 側の責務とし、BoardTop は「ボタン状態」と「簡易メッセージ」のみを扱う。

---

## 5.8 空状態・エラー状態 UI

### 5.8.1 投稿が 0 件の場合

* メイン部に「投稿がありません」メッセージを表示する。

  * キー例: `board.top.empty`

### 5.8.2 一覧取得エラー

* 投稿一覧の取得に失敗した場合:

  * メイン部に「掲示板を読み込めませんでした」系のメッセージを表示する。

    * キー例: `board.top.error.fetch`
  * 「再読み込み」ボタンを表示し、クリック時に再度一覧取得を試みる。

    * キー例: `board.top.error.retry`

翻訳キャッシュ取得エラーは、上記の「一覧取得エラー」とは別扱いとし、原文サマリのみで一覧表示を継続する（3.5.2 参照）。

---

## 5.9 i18n キー命名ポリシー

* プレフィックス: すべて `board.top.*` とする。
* 大分類例:

  * `board.top.title`                : 画面タイトル
  * `board.top.scope.*`              : scope タブラベル
  * `board.top.newPost`              : 新規投稿ボタン
  * `board.top.card.*`               : カード内のラベル（投稿者種別など）
  * `board.top.i18n.*`               : 翻訳 UI
  * `board.top.tts.*`                : TTS UI
  * `board.top.empty`                : 空状態
  * `board.top.error.*`              : エラー状態

実際の文言（日本語/英語/中国語）は StaticI18nProvider 用の辞書ファイルで定義し、本章ではキー体系と UI 上の使用箇所のみを示す。

---

## 5.10 他章との関係

* B-01 ch02 レイアウト

  * 本章で定義したカード内要素（翻訳/TTS ボタン含む）の配置位置を定義。
* B-01 ch03 データモデル

  * `BoardPostSummary` の翻訳/TTS 関連フィールド（`hasTranslation`, `translatedPreview`, `isTtsAvailable` 等）と整合していることを前提とする。
* B-02 BoardDetail

  * 詳細画面には返信・編集・削除アクションがあり、BoardTop には存在しないことを明示的に区別する。
* B-03 BoardPostForm / B-04 BoardTranslationAndTtsService

  * 翻訳キャッシュの生成・更新は B-04 側の責務であり、BoardTop はキャッシュ結果を UI に反映するのみである。

本章 v1.1 は、BoardDetail（B-02）および翻訳/TTS サービス（B-04）の仕様に整合する形で、BoardTop における翻訳・TTS・新規投稿 UI を定義している。
今後、カード内に他のアクション（ピン留め、既読マーク等）を追加する場合は、本章を v1.2 以降に更新する。
