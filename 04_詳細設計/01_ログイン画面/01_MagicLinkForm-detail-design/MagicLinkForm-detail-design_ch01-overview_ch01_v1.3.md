# MagicLinkForm 詳細設計書 — 第1章：概要

本章は MagicLinkForm（A-01）の実装方式について記述する。

---

## 1.1 目的

MagicLinkForm は、HarmoNet ログイン画面において **メールアドレスを入力し、
MagicLink（OTP）を送信するためのフォームコンポーネント**である。
本コンポーネントは UI 表示および MagicLink 送信ロジックのみを担当し、
認証後のセッション確立や認可処理は担当しない。

---

## 1.2 役割

MagicLinkForm の役割は以下の通り：

* メールアドレス入力欄の提供
* 入力値の形式チェック
* MagicLink（signInWithOtp）送信
* 成否に応じた状態管理と UI 反映
* エラーメッセージの表示
* 共通ログユーティリティによるログ出力

---

## 1.3 配置位置

MagicLinkForm は LoginPage（A-00）のメイン領域に単一カードとして配置される。
レイアウト上の制御は LoginPage が担当し、MagicLinkForm はフォーム UI と送信処理のみを担当する。

---

## 1.4 前提条件

* 技術スタック：Next.js 16 / React 19 / TypeScript / TailwindCSS
* 認証方式：Supabase MagicLink（OTP）
* 国際化：StaticI18nProvider による JSON 辞書切替
* ログ：共通ログユーティリティ（logInfo / logError）を使用

---

## 1.5 コンポーネント識別情報

| 項目             | 内容                                               |
| -------------- | ------------------------------------------------ |
| Component ID   | A-01                                             |
| Component Name | MagicLinkForm                                    |
| Category       | ログイン画面 UI                                        |
| File Path      | `src/components/auth/MagicLinkForm/`             |
| 主な依存           | StaticI18nProvider / Supabase JS SDK / 共通 Logger |

---

## 1.6 本コンポーネントが扱うもの

**扱う：**

* メール入力
* バリデーション
* MagicLink送信
* UI状態（idle / sending / sent / error_*）

**扱わない：**

* セッション確立
* 認可（ユーザマスタ・テナント判定）
* 画面遷移制御
* 他認証方式

---

## 1.7 参照ドキュメント

* LoginPage 詳細設計書（A-00）
* AuthCallbackHandler 詳細設計書（A-03）
* StaticI18nProvider 詳細設計書（C-03）
* 共通ログユーティリティ詳細設計書
* 技術スタック定義書 v4.4

---

## 1.8 章構成（v1.4）

本コンポーネントの詳細仕様は以下の章で構成される：

* 第2章：機能設計
* 第3章：構造設計
* 第4章：実装設計
* 第5章：UI仕様
* 第6章：ロジック仕様
* 第7章：結合・運用
* 第8章：メタ情報

---

**End of Document**
