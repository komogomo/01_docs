# PasskeyAuthTrigger 詳細設計書 - 第1章：概要（v1.2）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH01
**Version:** 1.2
**Supersedes:** v1.1（旧 Phase9 構成）
**Status:** MagicLinkForm（A-01）と完全対称の最新構成

---

## 1.1 目的

PasskeyAuthTrigger（A-02）は、HarmoNet ログイン画面における **「Passkey でログイン」カードタイル UI と認証処理** を提供する独立コンポーネントである。

本コンポーネントは A-01 MagicLinkForm と **左右対称のカードタイル UI** として LoginPage（A-00）中央に配置され、押下時に WebAuthn（Passkey）認証を実行する。

本 v1.2 では、以下の最新仕様を反映した：

* A-01 / A-02 の **カードタイル UI 二方式並列**（A1 基本設計）
* 技術スタック定義 v4.3 に準拠した **MagicLink / Passkey 独立方式**
* Passkey の旧統合方式（MagicLinkForm 内での自動処理）を完全廃止
* A-01 MagicLinkForm v1.3 と構成・密度・用語を完全一致させる

---

## 1.2 認証方式における位置づけ

PasskeyAuthTrigger（A-02）は、HarmoNet におけるパスワードレス認証方式の一つであり、以下を担当する：

| 項目       | 内容                                            |
| -------- | --------------------------------------------- |
| **役割**   | ログイン画面右側の Passkey ログイン用カードタイル                 |
| **UI**   | アイコン + タイトル + 説明文 + 状態別バナー                    |
| **ロジック** | Corbado Web SDK による WebAuthn 起動 + Supabase 認証 |
| **状態管理** | idle / processing / success / error_*         |
| **ログ**   | MagicLink と統一した共通ログイベント出力                     |
| **i18n** | Passkey 専用メッセージキー（auth.login.passkey.*）       |

MagicLink（A-01）とは **完全独立**して動作し、UI・メッセージ・ログ体系のみ共通化している。

---

## 1.3 前提条件

PasskeyAuthTrigger の前提条件は以下のとおり：

* **Corbado Web SDK** を利用して Passkey（WebAuthn）認証を起動する
* **Supabase Auth** の `signInWithIdToken()` を用いてセッション確立する
* UI 文言は **StaticI18nProvider（C-03）** の多言語辞書から取得
* LoginPage（A-00）が本コンポーネントを **カードタイル RHS（右側）** に配置する
* OS ネイティブの認証 UI（FaceID / 指紋 / PIN）はブラウザ + OS に委譲
* 認証成功後は `/mypage` への遷移を行う（A-02 の責務）

Passkey の可否判定や OS の挙動詳細は **HarmoNet_Passkey認証の仕組みと挙動_v1.0** に従う。

---

## 1.4 コンポーネントの境界（責務と非責務）

PasskeyAuthTrigger が担う部分と、担わない部分を明確化する。

### ✔ A-02 の責務（やる）

* Passkey ログインカード UI の描画
* ログインボタン押下時の WebAuthn / Corbado 連携
* Supabase 認証処理（`signInWithIdToken()`）
* 状態管理（idle, processing, success, error_*）
* UI 用メッセージ（i18n）の表示
* ログ出力（共通ログユーティリティ）
* 成功後のリダイレクト（`/mypage`）

### ❌ A-02 の非責務（やらない）

* メール入力欄の提供（→ A-01 の責務）
* MagicLink 送信（→ A-01 の責務）
* LoginPage のレイアウト制御（→ A-00 の責務）
* 画面構造・ヘッダー・フッター配置（→ C-01 / C-04）
* OS ネイティブ認証 UI の制御（OS が担当）

---

## 1.5 画面内での位置（A-00 LoginPage との関係）

LoginPage（A-00）において PasskeyAuthTrigger は以下のように配置される：

```
┌───────────────────────────────┐
│  [     MagicLinkForm (A-01)     ]  ← 左タイル
│  [ PasskeyAuthTrigger (A-02) ]      ← 右タイル
└───────────────────────────────┘
```

MagicLink と Passkey は対等であり、どちらかが優先されることはない。

---

## 1.6 UIトーン・スタイル方針（A-01 と完全一致）

PasskeyAuthTrigger の UI は、A-01 MagicLinkForm と完全同期したトーンで設計される。

```
・rounded-2xl
・shadow-[0_1px_2px_rgba(0,0,0,0.06)]
・高さ 80〜92px
・アイコン + 見出し + 説明文の構造
・i18n メッセージ位置共通化
・Apple カタログ風のシンプル・控えめデザイン
```

UI の設計原則は **A1 ログイン画面基本設計** と MagicLinkForm の ch04 を基準とする。

---

## 1.7 本設計書の読者

* Windsurf（実装担当）
* TKD（最終レビュー）
* Gemini（整合性監査）
* Cursor（補助実装）

本章（ch01）は、A-02 の目的・役割・前提を明確にし、
**Windsurf が誤解なく A-01 と対称構造を理解できること** を目的としている。

---

## 1.8 ChangeLog

| Version | Date       | Summary                                                                |
| ------- | ---------- | ---------------------------------------------------------------------- |
| 1.1     | 2025-11-12 | Phase9 旧構成（MagicLink統合前提）。                                             |
| **1.2** | 2025-11-16 | **A-01 と構成を完全統一。Passkey を独立カードタイルとして再定義し、UI・ロジック・メッセージ・ログ仕様を最新要件へ更新。** |
