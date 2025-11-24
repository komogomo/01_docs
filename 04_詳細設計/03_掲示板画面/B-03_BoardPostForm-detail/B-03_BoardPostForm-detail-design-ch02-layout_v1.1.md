# B-03 BoardPostForm 詳細設計書 ch02 画面構造・コンポーネント構成 v1.1

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH02
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-22
**Updated:** 2025-11-23
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 2.1 レイアウト全体構成

### 2.1.1 画面レイアウト概要

BoardPostForm は、HarmoNet 共通レイアウト（AppHeader / AppFooter / LanguageSwitch / StaticI18nProvider）配下の「メインコンテンツ領域」に表示される。  
レイアウト階層（論理レベル）は次の通りとする。

- `RootLayout`（アプリ共通レイアウト）
  - `AppHeader`（共通ヘッダー）
  - `Main` コンテンツ領域
    - `BoardPostFormPage`（本コンポーネントのページコンテナ）
  - `AppFooter`（共通フッター）

- 本画面の入力項目は、添付ファイルを除きすべて必須項目とする。
- 必須項目のラベル右側には赤色のアスタリスク（`*`）を表示する。
  - 対象: 投稿者区分 / カテゴリ / 表示名 / タイトル / 本文
  - 添付ファイルのラベルにはアスタリスクを付与しない（任意項目のため）。
- 画面下部（またはフォーム上部）に「* は必須項目です。」の注記を表示する。
- 「投稿区分が『管理組合』の場合、本ラジオボタンは表示しない（常に『管理組合』固定表示とする）。」

LanguageSwitch / StaticI18nProvider は RootLayout 側で適用済みとし、本章では BoardPostForm 固有部分のみを対象とする。

### 2.1.2 BoardPostForm 内部構造

`BoardPostFormPage` 配下の構造は以下の通りとする（SP 基準）。

- `BoardPostFormPage`
  - `BoardPostFormHeader`（画面タイトル・説明）
  - `BoardPostFormBody`
    - `BoardPostFormAuthorSection`（投稿者設定：ロール選択・表示名モード選択）
    - `BoardPostFormCategorySection`（投稿区分（タグ）選択）
    - `BoardPostFormTitleSection`（タイトル入力）
    - `BoardPostFormContentSection`（本文入力）
    - `BoardPostFormAttachmentSection`（添付ファイルアップロード）
    - `BoardPostFormCirculationSection`（回覧板設定 ※必要な場合）
  - `BoardPostFormFooter`（投稿ボタン・キャンセル/戻るボタン）

- ロール情報は認証コンテキストから受け取った  
  `hasManagementRole`（管理組合ロールを保持しているか）  
  `hasGeneralRole`（一般利用者ロールを保持しているか）  
  を基に算出する。
- 管理組合ロールと一般利用者ロールの **両方** を持つユーザのみ、`BoardPostFormAuthorSection` で  
  「管理組合として投稿」／「一般利用者として投稿」の二者択一と、「匿名／ニックネーム」の切り替えを行う。
- 管理組合ロールのみ、または一般利用者ロールのみを持つユーザにはロール選択は表示せず、  
  内部的に `postAuthorRole` を固定したうえで、「匿名／ニックネーム」の選択のみを行う。


投稿区分（カテゴリ）選択の候補は、「投稿者区分」とログインロールに応じて出し分ける。  
具体的な候補は ch03/ch05 で詳細に定義する。

---

## 2.2 主要コンポーネントの役割

### 2.2.1 BoardPostFormPage

- URL `/board/new` および `/board/[postId]/edit` に対応するトップレベルコンポーネント。
- 認証コンテキストから `tenantId` / `userId` / `viewerRole` / 所属グループ情報などを受け取り、フォームの初期状態を構築する。
- **編集モード**の場合、既存の投稿データを初期値として各セクションに渡す。
- 入力値・バリデーション状態・送信中状態を管理し、送信成功時には遷移先（BoardDetail など）へ誘導する。

### 2.2.2 BoardPostFormHeader

- 表示内容（例）:
  - 画面タイトル: 「掲示板に投稿する」（編集時は「投稿を編集する」）
  - サブタイトル: 「お知らせや要望、グループ向けの連絡を入力して投稿します。」
- BoardTop/Detail とトーンを揃えたヘッダーを構成する。

### 2.2.3 BoardPostFormAuthorSection（投稿者設定）

### 2.2.3 BoardPostFormAuthorSection（投稿者設定）

- **役割**:
  - 管理組合ロールと一般利用者ロールの **両方** を持つユーザに対して、
    「管理組合として投稿する」か「一般利用者として投稿する」かを選択させる。
  - **全ユーザに対して、「匿名で投稿」か「ニックネーム（登録名）を表示」かの選択を必須で行わせる。**

- **前提となるロール情報**:
  - `hasManagementRole: boolean` … 管理組合ロールを保持しているか
  - `hasGeneralRole: boolean` … 一般利用者ロールを保持しているか
  - `hasBothRoles = hasManagementRole && hasGeneralRole`
  - `viewerRole` は「現在の画面閲覧ロール」を表し、`"admin"` または `"user"` をとる。

- **挙動**:
  - `hasBothRoles === true` の場合のみ、「管理組合として投稿する／一般利用者として投稿する」ラジオボタンを表示する。
    - 選択結果は `postAuthorRole: "admin" | "user"` としてフォーム状態に保持する。
    - 未選択のまま送信しようとした場合はバリデーションエラーとする。
  - `hasManagementRole === true` かつ `hasGeneralRole === false` の場合:
    - 投稿者区分の UI は表示しない。
    - `postAuthorRole = "admin"` を内部的に固定する。
  - `hasGeneralRole === true` かつ `hasManagementRole === false` の場合:
    - 投稿者区分の UI は表示しない。
    - `postAuthorRole = "user"` を内部的に固定する。
  - 表示名モード（`displayNameMode`）は全ユーザ共通で初期値未選択とし、明示的な選択を求める。


### 2.2.4 BoardPostFormCategorySection（投稿区分選択）

- **役割**:
  - 投稿区分（GLOBAL系タグ、一般利用者用タグ、自グループ）を 1 つだけ選択するドロップダウンを提供する。
- **挙動（ロール×投稿者区分による出し分けの方針）**:
  - 管理組合ユーザが「管理組合として投稿」を選択している場合:
    - GLOBAL 系の全カテゴリを候補とする（例：重要／お知らせ／ルール／質問／要望／その他）。
    - GROUP 投稿を許可する場合は、グループ向けカテゴリも候補として追加（詳細は ch03/ch05）。
  - 管理組合ユーザが「一般利用者として投稿」を選択している場合、および一般利用者の場合:
    - 投稿可能な区分は次の 4 種のみ
      - 質問
      - 要望
      - その他（フリー投稿）
      - 自グループ（所属グループ向け投稿）
    - 重要／お知らせ／ルール は候補に表示しない。

具体的なタグ名と DTO へのマッピングは ch03 で定義する。

### 2.2.5 BoardPostFormTitleSection

- **役割**:
  - 投稿タイトルを入力するテキストフィールドを提供する。
- **条件**:
  - タイトルは必須項目とし、未入力の場合は送信前にバリデーションエラーとする。

### 2.2.6 BoardPostFormContentSection

### 2.2.6 BoardPostFormContentSection

- **役割**:
  - 本文を入力するコンポーネント（テキストエリア／リッチテキストエディタ）を提供する。

- **入力方式の切り替え**:
  - `postAuthorRole = "admin"`（＝「管理組合として投稿する」）の場合:
    - リッチテキストエディタを表示する。
    - 太字・箇条書き・リンクなど、管理組合向けのお知らせ文を整形しやすい最小限の機能を提供する。
  - `postAuthorRole = "user"`（＝「一般利用者として投稿する」）の場合:
    - シンプルなテキストエリアを表示する。
    - 余計な装飾機能は持たず、入力のしやすさを優先する。

- **条件**:
  - 本文は全モードで必須項目とする。
  - 最大文字数は要件定義に基づき ch03 で定義する。
  - リッチテキストエディタの場合も、内部状態としては HTML またはマークアップ文字列として `content` に保持する。

### 2.2.7 BoardPostFormAttachmentSection

- **役割**:
  - 具体的な拡張子・上限値に基づくファイル添付 UI を提供する。
  - 管理組合ユーザ・一般利用者を問わず、全ユーザが添付ファイルを追加できる。

- **許可する拡張子**:
  - ドキュメント系:
    - `*.pdf`
    - `*.xls` / `*.xlsx`
    - `*.doc` / `*.docx`
    - `*.ppt` / `*.pptx`
  - 画像系:
    - `*.jpg` / `*.jpeg`
    - `*.png`

- **上限値（テナント設定連動）**:
  - デフォルト値:
    - 1 ファイルあたり最大サイズ: 5MB
    - 最大添付ファイル数: 5 ファイル
  - 実際に適用する上限値は、テナント管理者画面で設定された `tenant_settings` の値を使用する。
    - 例: `maxAttachmentSizeMB`, `maxAttachmentCount` など。

- **挙動**:
  - ファイル選択コンポーネント（ドラッグ&ドロップ領域を含む）を提供し、`accept` 属性に上記拡張子および MIME タイプを指定する。
  - 選択されたファイル一覧を表示し、個別の削除ボタンを提供する。
  - アップロード処理や Storage との連携は共通アップロードコンポーネント側に委譲し、BoardPostForm は「選択されたファイルのメタ情報」を `board_attachments` 登録用 DTO に反映する。
  - 上記以外の拡張子が選択された場合、または
    - 1 ファイルのサイズが `maxAttachmentSizeMB` を超えている場合
    - 添付数の合計が `maxAttachmentCount` を超える場合
    はバリデーションエラーとし、エラーメッセージを表示する。
  - 投稿編集モードでは、投稿の編集権限を持つユーザに限り、既存添付ファイルの削除および新規添付ファイルの追加を行える。


### 2.2.8 BoardPostFormCirculationSection（回覧板設定）

- **役割**:
  - 回覧板として扱う投稿（例: 管理組合としての「重要」「お知らせ」）の場合に、回覧対象グループや回覧期限などの設定を行う UI を提供する。
- **挙動**:
  - セクション冒頭に「回覧板として回す」トグルスイッチを配置し、ON のときのみ詳細フィールドを表示する。
  - ON 時に表示する代表的な項目（詳細は ch05 で定義）:
    - 回覧対象グループ（管理組合はテナント全グループを候補、一般利用者は所属グループのみ）。
    - 回覧期限（日付入力）。
  - 一般利用者が利用する場合は、許可されたグループのみ選択可能とする。

### 2.2.9 BoardPostFormFooter

- **役割**:
  - 「投稿する」ボタンと「キャンセル」または「戻る」ボタンを配置する。
- **挙動**:
  - 「投稿する」（新規）または「保存する」（編集）押下でバリデーション→問題なければ確認ダイアログ（プレビュー付き）を表示。
  - 「キャンセル」押下で `/board` へ戻るか、遷移元に戻る。

---

## 2.3 ルーティングとパラメータ

### 2.3.1 ルーティング

- 新規投稿
  - パス: `/board/new`
  - HTTP メソッド: GET（フォーム表示）
  - 認証: MagicLink 認証済みユーザのみ。未認証の場合は `/login` へリダイレクト（アプリ共通仕様）。

- 編集
  - パス: `/board/[postId]/edit`
  - HTTP メソッド: GET（フォーム表示・既存データ読み込み）
  - 権限: 自分が投稿した記事（`authorId === currentUserId`）である場合のみアクセス可能。

### 2.3.2 クエリパラメータ

- 初版では、BoardPostForm 独自のクエリパラメータは定義しない。
  HOME や BoardTop からの遷移時に「カテゴリ候補」を事前選択したい場合は、将来拡張としてクエリで渡すことを検討し、その際に本章を v1.2 以降へ更新する。

---

## 2.4 レスポンシブレイアウト方針

### 2.4.1 SP（スマートフォン）

- 基本は 1 カラムの縦積みフォームとし、要素の順序は 2.1.2 の通り。
- 各入力行の上下に十分な余白を確保し、入力ミスを防ぐ。
- ボタンは画面下部に固定せず、フォーム末尾に配置する（スクロール操作を妨げない）。

### 2.4.2 PC（デスクトップ）

- コンテンツ幅は最大幅（例: 960〜1200px）で中央寄せにし、左右に余白を持たせる。
- レイアウト順序は SP と同一とし、左右 2 カラム化は行わない（設計と実装のシンプルさを優先）。
- 入力欄は横幅を広く取り、長いタイトルや本文でも入力しやすいようにする。

---

## 2.5 コンポーネント間の依存関係

### 2.5.1 依存関係概要

- `BoardPostFormPage`
  - `BoardPostFormHeader`
  - `BoardPostFormBody`
    - `BoardPostFormAuthorSection`
    - `BoardPostFormCategorySection`
    - `BoardPostFormTitleSection`
    - `BoardPostFormContentSection`
    - `BoardPostFormAttachmentSection`
    - `BoardPostFormCirculationSection`
  - `BoardPostFormFooter`

BoardPostFormPage は、入力値・バリデーション状態・送信中状態を一元管理し、各セクションに必要な props を渡す役割を持つ。

### 2.5.2 props の方向性（論理）

- `BoardPostFormAuthorSection`
  - props: `viewerRole`, `postAuthorRole`, `displayNameMode`, およびそれぞれの変更ハンドラ。
- `BoardPostFormCategorySection`
  - props: 利用可能なカテゴリ一覧（ロール・投稿者区分に応じてフィルタ済み）、選択中カテゴリ、変更ハンドラ。
- `BoardPostFormTitleSection`
  - props: タイトル文字列、変更ハンドラ、エラー状態（必須エラー等）。
- `BoardPostFormContentSection`
  - props: 本文文字列、変更ハンドラ、エラー状態。
- `BoardPostFormAttachmentSection`
  - props: 選択済み添付ファイル一覧、追加・削除ハンドラ、アップロード状態。
- `BoardPostFormCirculationSection`
  - props: 回覧板フラグ、回覧対象グループ候補一覧・選択値、回覧期限、変更ハンドラ。
- `BoardPostFormFooter`
  - props: 送信ボタン活性/非活性状態、送信ハンドラ、キャンセルハンドラ。

### 2.5.3 外部依存

BoardPostForm は、次の外部要素に依存するが、その具体実装は本章では扱わない（該当章・別文書で定義）。

- 認証コンテキスト（現在ユーザ・tenantId・viewerRole・所属グループ等）
- 掲示板カテゴリ・範囲のマスタ取得 API
- 掲示板投稿作成 API（`board_posts` への INSERT / UPDATE 等）
- 添付アップロードコンポーネント／API（Supabase Storage 等）
- Logger（投稿開始/成功/失敗ログ）

以上により、BoardPostForm の画面構造とコンポーネント構成の論理レベルを定義する。詳細な props 型定義や Tailwind クラス、イベントハンドラの具体シグネチャは、ch03〜ch05 で記述する。