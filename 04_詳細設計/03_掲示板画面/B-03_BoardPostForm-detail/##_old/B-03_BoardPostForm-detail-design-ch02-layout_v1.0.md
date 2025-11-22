# B-03 BoardPostForm 詳細設計書 ch02 画面構造・コンポーネント構成 v1.0

**Document ID:** HARMONET-COMPONENT-B03-BOARDPOSTFORM-DETAIL-CH02  
**Version:** 1.0  
**Supersedes:** -  
**Created:** 2025-11-22  
**Updated:** 2025-11-22  
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

LanguageSwitch / StaticI18nProvider は RootLayout 側で適用済みとし、本章では BoardPostForm 固有部分のみを対象とする。

### 2.1.2 BoardPostForm 内部構造（新規投稿 `/board/new`）

`BoardPostFormPage` 配下の構造は以下の通りとする（SP 基準）。

- `BoardPostFormPage`
  - `BoardPostFormHeader`（画面タイトル・説明）
  - `BoardPostFormBody`
    - `BoardPostFormAuthorRoleSection`（投稿者区分選択 ※管理組合ユーザのみ表示）
    - `BoardPostFormCategorySection`（投稿区分（タグ）選択）
    - `BoardPostFormTitleSection`（タイトル入力）
    - `BoardPostFormContentSection`（本文入力）
    - `BoardPostFormAttachmentSection`（添付ファイルアップロード）
    - `BoardPostFormCirculationSection`（回覧板設定 ※必要な場合）
  - `BoardPostFormFooter`（投稿ボタン・キャンセル/戻るボタン）

- 管理組合ユーザ（viewerRole = `"admin"`）は、`BoardPostFormAuthorRoleSection` で  
  「管理組合として投稿」／「一般利用者として投稿」を切り替えられる。
- 一般利用者（viewerRole = `"user"`）には `BoardPostFormAuthorRoleSection` は表示せず、  
  常に「一般利用者として投稿」として扱う。

投稿区分（カテゴリ）選択の候補は、「投稿者区分」とログインロールに応じて出し分ける。  
具体的な候補は ch03/ch05 で詳細に定義する。

---

## 2.2 主要コンポーネントの役割

### 2.2.1 BoardPostFormPage

- URL `/board/new` に対応するトップレベルコンポーネント。
- 認証コンテキストから `tenantId` / `userId` / `viewerRole` / 所属グループ情報などを受け取り、フォームの初期状態を構築する。
- 入力値・バリデーション状態・送信中状態を管理し、送信成功時には遷移先（BoardDetail など）へ誘導する。

### 2.2.2 BoardPostFormHeader

- 表示内容（例）:
  - 画面タイトル: 「掲示板に投稿する」
  - サブタイトル: 「お知らせや要望、グループ向けの連絡を入力して投稿します。」
- BoardTop/Detail とトーンを揃えたヘッダーを構成する。

### 2.2.3 BoardPostFormAuthorRoleSection（投稿者区分）

- 役割:
  - 管理組合権限を持つユーザに対して、「管理組合として投稿する」か「一般利用者として投稿する」かを選択させる。
- 挙動:
  - `viewerRole = "admin"` の場合のみ表示。
  - UI はラジオボタン 2択などを想定：
    - 「管理組合として投稿する」
    - 「一般利用者として投稿する」
  - 一般利用者（`viewerRole = "user"`）には本セクション自体を表示しない（内部的に `postAuthorRole = "user"` 固定）。

### 2.2.4 BoardPostFormCategorySection（投稿区分選択）

- 役割:
  - 投稿区分（GLOBAL系タグ、一般利用者用タグ、自グループ）を 1 つだけ選択するドロップダウンを提供する。
- 挙動（ロール×投稿者区分による出し分けの方針）:
  - 管理組合ユーザが「管理組合として投稿」を選択している場合:
    - GLOBAL 系の全カテゴリを候補とする（例：重要／お知らせ／ルール／質問／要望／その他）。
    - GROUP 投稿を許可する場合は、グループ向けカテゴリも候補として追加（詳細は ch03/ch05）。
  - 管理組合ユーザが「一般利用者として投稿」を選択している場合、および一般利用者の場合:
    - 投稿可能な区分は次の 4 種のみとする：
      - 質問
      - 要望
      - その他（フリー投稿）
      - 自グループ（所属グループ向け投稿）
    - 重要／お知らせ／ルール は候補に表示しない。

具体的なタグ名と DTO へのマッピングは ch03 で定義する。

### 2.2.5 BoardPostFormTitleSection

- 役割:
  - 投稿タイトルを入力するテキストフィールドを提供する。
- 条件:
  - タイトルは必須項目とし、未入力の場合は送信前にバリデーションエラーとする。

### 2.2.6 BoardPostFormContentSection

- 役割:
  - 本文を入力するテキストエリアを提供する。
- 条件:
  - 本文も必須項目とし、最大文字数は要件定義に基づき ch03 で定義する。

### 2.2.7 BoardPostFormAttachmentSection

- 役割:
  - PDF ファイルなどの添付をアップロードする UI を提供する。
- 挙動:
  - ファイル選択コンポーネント（input type="file"）またはドラッグ&ドロップ領域を提供し、選択されたファイル一覧を表示する。
  - アップロード処理や Storage との連携は共通アップロードコンポーネント側に委譲し、BoardPostForm は「選択されたファイルのメタ情報」を `board_attachments` 登録用 DTO に反映する。

### 2.2.8 BoardPostFormCirculationSection（回覧板設定）

- 役割:
  - 回覧板として扱う投稿（例: 管理組合としての「重要」「お知らせ」）の場合に、回覧対象グループや回覧期限などの設定を行う UI を提供する。
- 挙動:
  - セクション冒頭に「回覧板として回す」トグルスイッチを配置し、ON のときのみ詳細フィールドを表示する。
  - ON 時に表示する代表的な項目（詳細は ch05 で定義）:
    - 回覧対象グループ（管理組合はテナント全グループを候補、一般利用者は所属グループのみ）。
    - 回覧期限（日付入力）。
  - 一般利用者が利用する場合は、許可されたグループのみ選択可能とする。

### 2.2.9 BoardPostFormFooter

- 役割:
  - 「投稿する」ボタンと「キャンセル」または「戻る」ボタンを配置する。
- 挙動:
  - 「投稿する」押下でバリデーション→問題なければ POST API 呼び出し。
  - 「キャンセル」押下で `/board` へ戻るか、遷移元に戻る。

---

## 2.3 ルーティングとパラメータ

### 2.3.1 ルーティング

- 新規投稿
  - パス: `/board/new`
  - HTTP メソッド: GET（フォーム表示）
  - 認証: MagicLink 認証済みユーザのみ。未認証の場合は `/login` へリダイレクト（アプリ共通仕様）。

- 編集（将来拡張）
  - パス: `/board/[postId]/edit`
  - 現時点では詳細設計のスコープ外とし、将来拡張時に別途 ch02/ch03/ch04 を更新する。

### 2.3.2 クエリパラメータ

- 初版では、BoardPostForm 独自のクエリパラメータは定義しない。  
  HOME や BoardTop からの遷移時に「カテゴリ候補」を事前選択したい場合は、将来拡張としてクエリで渡すことを検討し、その際に本章を v1.1 以降へ更新する。

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
    - `BoardPostFormAuthorRoleSection`
    - `BoardPostFormCategorySection`
    - `BoardPostFormTitleSection`
    - `BoardPostFormContentSection`
    - `BoardPostFormAttachmentSection`
    - `BoardPostFormCirculationSection`
  - `BoardPostFormFooter`

BoardPostFormPage は、入力値・バリデーション状態・送信中状態を一元管理し、各セクションに必要な props を渡す役割を持つ。

### 2.5.2 props の方向性（論理）

- `BoardPostFormAuthorRoleSection`
  - props: `viewerRole`, `postAuthorRole`, onChange ハンドラ。
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
- 掲示板投稿作成 API（`board_posts` への INSERT 等）
- 添付アップロードコンポーネント／API（Supabase Storage 等）
- Logger（投稿開始/成功/失敗ログ）

以上により、BoardPostForm の画面構造とコンポーネント構成の論理レベルを定義する。詳細な props 型定義や Tailwind クラス、イベントハンドラの具体シグネチャは、ch03〜ch05 で記述する。
