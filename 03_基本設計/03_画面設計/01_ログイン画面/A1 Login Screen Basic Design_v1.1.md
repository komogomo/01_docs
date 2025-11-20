# HarmoNet 基本設計書（A1）- ログイン画面 v1.1

**Document ID:** HARMONET-BASICDESIGN-A1-LOGINSCREEN
**Version:** 1.1
**Supersedes:** v1.0
**Created:** 2025-11-19
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink 専用 UI 反映版

---

# 1. 目的（Purpose）

本書は HarmoNet ログイン画面の **基本UI設計（A1）** を定義する。ログイン画面は本システムのエントリポイントであり、
ユーザにシンプル・安全・自然な操作を提供することを目的とする。

---

# 2. 前提条件（Prerequisites）

* 認証方式：**MagicLink を採用**（Supabase Auth signInWithOtp）
* StaticI18nProvider による 3 言語（JA / EN / ZH）切替
* Header/Footer は C-01 / C-04 を利用
* A-01 MagicLinkForm にメール入力＋送信処理を委譲

---

# 3. 画面全体概要（Overview）

実装中の UI（スクリーンショット）と整合する構成は以下の通り：

```
┌──────────────────────────────┐
│  AppHeader（右上：JA / EN / 中文）          │
├──────────────────────────────┤
│         Harmony Network               │
│   入居者様専用コミュニティアプリ                 │
│                                        │
│   ┌──────────────────────────┐
│   │   📧 メールでログイン                    │
│   │   メールアドレス入力欄                   │
│   │   ［ログイン］ボタン                    │
│   │   送信完了メッセージ領域                 │
│   └──────────────────────────┘
│                                        │
│                 AppFooter              │
└──────────────────────────────┘
```

---

# 4. 機能概要（Functional Summary）

本画面は以下の機能のみを提供する：

* MagicLink ログイン（メール入力 → OTP 送信 → `/auth/callback`）
* 言語切替（JA / EN / 中文）
* UI 表示（成功／失敗メッセージ）
* Header / Footer の共通 UI

---

# 5. UI構造（UI Structure）

## 5.1 メール入力欄

* `type="email"`
* BIZ UD ゴシックベースの自然なトーン
* 枠線：gray-300、rounded-xl
* プレースホルダ：メールアドレス

## 5.2 ログインボタン（MagicLink）

* 幅：100%
* 色：HarmoNet 基調ブルー（#6495ED 系）
* 角丸：`rounded-full`
* 高さ：48px 以上
* テキスト：白、中央揃え
* 状態：`idle` / `sending` / `disabled`

## 5.3 メッセージ領域

* 送信成功：青系の控えめな情報バナー
* 送信失敗：赤系のエラーバナー（A-01 詳細設計の MSG 仕様と一致）
* 画面下部に固定表示しない（MagicLinkForm 内に表示）

## 5.4 タイトル階層

* メインタイトル：Harmony Network
* サブテキスト：入居者様専用コミュニティアプリ（i18n対応）

---

# 6. レイアウト・スタイル仕様（Layout / Style）

### 共通ルール

* 画面幅：max-w-md（モバイル優先）
* 背景：白（#FFFFFF）
* マージン：上下 24〜40px
* Apple 風のミニマル・控えめな UI

### MagicLink カード

* rounded-2xl
* shadow-[0_1px_2px_rgba(0,0,0,0.06)]
* padding: 24px
* アイコンは薄めのグレイッシュ（メールアイコン）

### Header（C-01）

* 高さ 60px、白背景、固定表示
* 右上に LanguageSwitch 3 ボタンを配置

### Footer（C-04）

* 高さ 48px、固定表示
* コピーライトのみ表示

---

# 7. 認証方式 UX（MagicLink のみ）

### Supabase Auth MagicLink

```
メール入力 → ログインボタン押下 → OTP送信 → 完了メッセージ表示 → /auth/callback
```

### 挙動要件

* ボタン連打抑止（sending 中は disabled）
* 成功後は控えめなメッセージ表示
* UI トーンは "やさしく・自然・控えめ" を保持

選択 UX セクション（v1.0）は削除済。

---

# 8. メッセージ出力仕様（概要）

MagicLinkForm（A-01）のメッセージ仕様と一致させる。

## 正常系

* ログイン用リンクを送信しました。

## 異常系

* メール形式エラー
* 通信障害
* 認証エラー
* 想定外エラー

※ 具体的な i18n キーは A-01 詳細設計の MSG カタログに準拠。

---

# 9. 状態遷移（State Transition）

A-01 MagicLinkForm に完全準拠。

```
idle → input → sending → sent → redirect
```

---

# 10. 非機能要件（NFR）

* スマホで誤タップが起きない UI
* 3秒以内の操作応答
* セキュリティ（HTTPS／MagicLink／Cookie）
* 読み上げ機能：本画面対象外

---

# 11. 参照資料（References）

* harmonet-technical-stack-definition_v*.*.md
* MagicLinkForm-detail-design_v*.*.md
* LoginPage-detail-design_v*.*.md
* StaticI18nProvider-detail-design_v*.*.md
* AppHeader/AppFooter

---

# 12. 改訂履歴

| Version  | Date       | Summary                              |
| -------- | ---------- | ------------------------------------ |
| **v1.1** | 2025-11-19 | 廃止に伴う UI 再定義。実画面と完全整合。 |
| v1.0     | 2025-11-15 | MagicLink +  並列 UI 版。                |

---

**End of Document**
