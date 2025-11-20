# Login — 設計書 文書体系と各章アジェンダ v1.1

**Document ID:** HARMONET-LOGIN-DOC-STRUCTURE-V1.1
**Version:** 1.1
**Supersedes:** v1.0
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink専用・不要文書整理済み（正式版）

---

# 1. 目的

Login（A-00 / A-01）に関わる設計書の **正式な文書体系** を定義する。

---

# 2. Login 設計書の正式構成（最新版）

Login の設計書は **A-00 / A-01 の 2 枚で完結**する。
その他の文書は必要時にのみ作成する補助資料とし、設計書体系には含めない。

### ✔ 正式構成（必須）

| 種別         | ファイル名                                 | 目的                     |
| ---------- | ------------------------------------- | ---------------------- |
| 詳細設計（A-00） | `A-00LoginPage-detail-design_v*.*.md` | LoginPage（レイアウト親）の詳細設計 |
| 詳細設計（A-01） | `MagicLinkForm-detail-design_v*.*.md` | MagicLink 専用フォームの詳細設計  |

### ✔ 任意（必要時のみ作成）

| 種別        | ファイル名                                     | 目的                                     |
| --------- | ----------------------------------------- | -------------------------------------- |
| メッセージ仕様   | `LoginPage_MSG_Catalog_v*.*.md`           | 文言/i18nキーの統一（必要時）                      |
| バックエンド仕様  | `MagicLinkBackend-integration_v*.*.md`    | `/auth/callback` や API Route の入出力（必要時） |
| Windsurf用 | `Frontend_IntegrationSpec_WS-A00_v*.*.md` | Windsurfへの実装タスク指示書（必要時）                |

---

# 3. 文書アジェンダ（正式）

A-00 / A-01 の詳細設計は **harmonet-detail-design-agenda-standard_v*.*.md** に準拠する。

必要最小限の Login 固有追記事項のみ以下に示す。

---

## 3.1 A-00 LoginPage 詳細設計（正式アジェンダ）

* 第1章：概要（目的・スコープ）
* 第2章：機能設計（レイアウトのみ / MagicLinkForm 委譲）
* 第3章：構造設計（Header / Form / Footer）
* 第4章：実装設計（page.tsx コード）
* 第5章：UI仕様（max-w-md / Appleトーン）
* 第6章：ロジック仕様（保持なし）
* 第7章：テスト設計（存在確認 / レンダリング）
* 第8章：メタ情報

---

## 3.2 A-01 MagicLinkForm 詳細設計

* 第1章：概要（MagicLink 専用フォーム）
* 第2章：機能設計（Props / エラー型 / 状態遷移）
* 第3章：処理フロー（正常系 / 異常系）
* 第4章：UI仕様（メール入力 / ボタン / メッセージ）
* 第5章：ロジック仕様（handleLogin など）
* 第6章：ログ出力仕様
* 第7章：テスト設計（Vitest + RTL）
* 第8章：結合・運用（A-00 との依存）
* 第9章：セキュリティ・非機能

---

# 4. Login 補助資料

### 4.1 LoginPage_MSG_Catalog

* MagicLink の成功/失敗文言（MSG-01〜）
* i18n キー一覧（ja/en/zh）
* 表示トリガ（成功 / 入力エラー / ネットワーク / 認証 / 想定外）

### 4.2 MagicLinkBackend-integration

* `/auth/callback` の PKCE 処理
* Supabase Auth セッション確立方式
* 成功/失敗の HTTP仕様

### 4.3 Windsurf IntegrationSpec

* 対象ファイル一覧
* import path の統一ルール
* CodeAgent_Report の保存先

これらは **詳細設計ではなく補助資料** と位置付ける。

---

# 5. 文書ルール（HarmoNet 全体準拠）

* 設計書は **必要最小限**、検討資料は含めない
* 過去仕様（Passkey 等）は **一切記述しない**
* Windsurf が参照するドキュメントは **常に最新版のみ**
* “決定事項のみ” を記述し、歴史・比較・案は書かない
* ファイル名は TKD の命名規則を厳守（`_vX.Y`）

---

# 6. ChangeLog

| Version | Date       | Summary                                               |
| ------- | ---------- | ----------------------------------------------------- |
| v1.1    | 2025-11-19 | Passkey関連・不要文書を全削除。Login 設計書体系を A-00/A-01 の2枚に統一し正式化。 |
| v1.0    | 2025-11-16 | 旧仕様（Passkey前提）＋冗長文書案を含んだ初版。                           |

---

**End of Document**
