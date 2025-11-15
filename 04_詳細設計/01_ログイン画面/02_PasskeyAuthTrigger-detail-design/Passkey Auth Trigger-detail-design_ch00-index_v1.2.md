# PasskeyAuthTrigger 詳細設計書 - 第0章：Index

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH00
**Version:** 1.2
**Supersedes:** v1.1（Phase9 旧構成）
**Status:** 

---

## 🔧 本章の目的

PasskeyAuthTrigger（A-02）の **詳細設計全体構成（ch01〜ch07）** を定義し、
MagicLinkForm（A-01）と完全左右対称となる最新構成を示す。

旧仕様（Phase9）で存在した以下の章は **廃止**：

* ch06: 結合・運用（不要）
* ch08: テスト（各章へ分散済）
* ch09: メタ情報（Index と ChangeLog に吸収）

A-02 は A-01 と同格の **UI + ロジック コンポーネント** として扱われるため、
章構成・粒度・密度は MagicLinkForm-detail-design_v1.3 と完全一致させる。

---

## 📁 第0章：ファイル一覧（最新版）

PasskeyAuthTrigger の詳細設計は次の 8 ファイルで構成する。
MagicLinkForm（A-01）と構成を完全に揃えている。

| 章        | ファイル名                                                 | 内容                           |
| -------- | ----------------------------------------------------- | ---------------------------- |
| **ch00** | PasskeyAuthTrigger-detail-design_ch00-index_v1.3.md   | 本ファイル（Index）                 |
| **ch01** | PasskeyAuthTrigger-detail-design_ch01-overview_*.*.md | 概要・責務・位置づけ                   |
| **ch02** | PasskeyAuthTrigger-detail-design_ch02-props_*.*.md    | Props / State / Event 定義     |
| **ch03** | PasskeyAuthTrigger-detail-design_ch03-logic_*.*.md    | 認証ロジック・Supabase / Corbado 連携 |
| **ch04** | PasskeyAuthTrigger-detail-design_ch04-ui_*.*.md       | カードタイル UI / Tailwind 設計      |
| **ch05** | PasskeyAuthTrigger-detail-design_ch05-error_*.*.md    | エラー分類・メッセージ仕様・ログ連携           |
| **ch06** | PasskeyAuthTrigger-detail-design_ch06-i18n_*.*.md     | i18n キー定義（メッセージ翻訳）           |
| **ch07** | PasskeyAuthTrigger-detail-design_ch07-security_*.*.md | クライアント側セキュリティ指針              |

> **注意**：
> A-01 と同じく「テスト仕様（UT/IT/E2E）」は **各章に分散して記述し、ch08 は作成しない**。

---

## 📘 第1章以降の記述基準

PasskeyAuthTrigger は MagicLinkForm と完全対称構造で記述する。

### ✔ UI（カードタイル）を持つため：

* UI章（ch04）が必須
* i18n（ch06）は **UIメッセージ用として必須**
* error章（ch05）は **MagicLinkForm と同じ分類方式**

### ✔ 認証ロジックのため：

* ch03 に Corbado → Supabase → 遷移 のロジックを整理
* イベントログは MagicLink と同じ命名規則

### ✔ セキュリティのため：

* ch07（Origin / HTTPS / RP ID など）を最小限記述

---

## 📚 関連ファイル

* MagicLinkForm-detail-design_v1.3（A-01）
* LoginPage-detail-design_v1.2（A-00）
* harmoNet-technical-stack-definition_v4.3
* HarmoNet_Passkey認証の仕組みと挙動_v1.0

---

## 📝 ChangeLog

| Version | Date       | Summary                                                                     |
| ------- | ---------- | --------------------------------------------------------------------------- |
| 1.1     | 2025-11-12 | Phase9 旧構成（ch01〜ch09）版                                                      |
| **1.2** | 2025-11-16 | **MagicLinkForm v1.3 の構成に合わせて章構成のみ更新。旧 ch06/ch08/ch09 を廃止し、新アジェンダ準拠構成へ整理。** |

---

