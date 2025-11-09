🎯 タスク概要

目的:
HarmoNet Phase9 におけるログイン画面の共通部品（共通UI層＋非機能補助層）の詳細設計書（ch01〜ch08形式）を作成する。
本タスクでは、既存の「機能コンポーネント一覧_v1.1」からログイン画面に関連する共通部品（C群）を対象とする。
出力は /03_基本設計/04_詳細設計/00_共通部品/ に格納する設計書（Markdown形式）とする。

🧩 対象コンポーネント（共通部品）
| ID   | コンポーネント名             | 機能概要                  | 備考                    |
| ---- | -------------------- | --------------------- | --------------------- |
| C-01 | AppHeader            | ロゴ・状態・言語切替を含む共通ヘッダー   | ログイン画面ではロゴ＋言語切替のみ表示   |
| C-02 | LanguageSwitch       | next-intl による静的翻訳辞書切替 | SSR/CSR整合             |
| C-03 | StaticI18nProvider   | 辞書注入Provider          | Next.js App Routerに対応 |
| C-04 | AppFooter            | コピーライト＋バージョン情報        | ログイン・ホーム共通            |
| C-14 | ErrorAlert           | 翻訳対応エラーメッセージ表示        | 認証／通信エラー表示用           |
| C-19 | ErrorToastDispatcher | 成功・失敗メッセージトースト        | 状態通知用                 |
| C-20 | AccessibilityConfig  | 翻訳/音声設定保持             | 初回起動時に初期化             |

⚙️ Claudeへの依頼内容

出力物:
login-common-components-design-ch06_v1.0.md

内容:
・1ファイル内に対象コンポーネント全ての詳細設計（ch01〜ch08構成）を記述
・各コンポーネントを章単位（ch01〜ch07）で分割
・ch08に全体統合構造（依存関係と初期化順）を記載
・HarmoNet共通デザイン規約・i18n・アクセシビリティ仕様に準拠

📚 Claudeが参照すべき資料（PJナレッジにアップ推奨）
| 種別        | ファイル名                                            | 理由                            |
| --------- | ------------------------------------------------ | ----------------------------- |
| コンポーネント一覧 | `機能コンポーネント一覧.md`                                 | 設計対象・難易度・粒度の基準                |
| 技術スタック    | `harmonet-technical-stack-definition_v3.7.md`    | Supabase / Next.js / i18n構成整合 |
| デザイン体系    | `common-design-system_v1.1.md`                   | Appleカタログ風トーン・BIZ UDフォント準拠    |
| レイアウト仕様   | `common-layout_v1.1.md`                          | 角丸・余白・レスポンシブルール               |
| i18n仕様    | `common-i18n_v1.0.md`                            | 翻訳方針（静的/動的）                   |
| アクセシビリティ  | `common-accessibility_v1.0.md`                   | 音声読み上げ設定仕様                    |
| エラーハンドリング | `common-error-handling_v1_0.md`                  | ErrorAlert／Toast構造定義          |
| ヘッダー／フッター | `common-header_v1.1.md`, `common-footer_v1.1.md` | 再利用対象UIの仕様原本                  |
| DB関連      | `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | ユーザー／言語設定のDBスキーマ参照用           |

🧭 出力形式指定（Claude側）
・Markdown形式（UTF-8, BOMなし）
・ファイル名: login-common-components-design-ch06_v1.0.md
・構成例:

# HarmoNet 詳細設計書（ログイン共通部品）v1.0
## ch01 AppHeader
...
## ch02 LanguageSwitch
...
## ch08 Integration Structure
✅ 受け入れ条件
項目	基準
1	各コンポーネントが明確に定義（Props・イベント・状態）されている
2	Supabase Auth / Next.js App Router に適合
3	i18n, Accessibility 構成が common-i18n_v1.0.md に準拠
4	全章統合（ch08）で依存関係・初期化順が説明されている
5	Claude出力が2,000トークン以内／精度9/10以上（自己採点）