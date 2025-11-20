# A-00 LoginPage 詳細設計書 ch00：Index v1.1

**Document ID:** HARMONET-A00-LOGINPAGE-INDEX
**Version:** 1.1
**Supersedes:** v1.0
**Status:** MagicLink専用 / 不要要素削除済み（正式版）

---

# 第1章：目的

A-00 LoginPage 詳細設計（ch01〜ch06）の **全体像を示すインデックス**として、章の役割・責務・依存関係を簡潔に整理する。
本章は仕様そのものを記述せず、**構造の俯瞰と章間の関係のみ**を示す。

---

# 第2章：章構成一覧（MagicLink専用・6章構成）

A-00 LoginPage の詳細設計は、以下 6 章で構成する。

* **ch01 UI構成**：画面レイアウト、共通部品配置（AppHeader / MagicLinkForm / AppFooter）、レスポンシブ、最大幅 `max-w-md`、Appleカタログ風トーン
* **ch02 状態管理**：LoginPage 自体は state を持たず、MagicLinkForm 内部に状態を委譲する方針を明確化
* **ch03 認証構成**：MagicLink（Supabase signInWithOtp → /auth/callback）に限定したフローの整理
* **ch04 SessionHandler**：/auth/callback の PKCE セッション確立の概要（A-03 AuthCallbackHandler 参照）
* **ch05 セキュリティ**：HTTPS / Cookie / RLS / CSRF といったフロント側の抽象セキュリティ要件（MagicLink専用）
* **ch06 結合構成**：A-01 MagicLinkForm との依存、AppHeader/AppFooter との構造結合、Windsurf の参照ポイント

---

# 第3章：技術前提（現行仕様）

* **Next.js 16 / React 19 / TypeScript 5.6**
* **Supabase Auth（MagicLink 専用）**
* **StaticI18nProvider（C-03）による 3 言語（ja/en/zh）切替**
* **白基調・Appleカタログ風UI**、BIZ UD ゴシック前提
* 共通部品（C-01 AppHeader / C-04 AppFooter / C-02 LanguageSwitch）との整合

---

# 第4章：設計思想（A-00 全体指針）

LoginPage は **認証ロジックを持たない純粋なレイアウトコンポーネント**とする。
MagicLinkForm（A-01）が保持する UI・ロジック・メッセージ仕様を正しく配置することのみが責務となる。

設計思想：

* LoginPage は UI コンテナとして最小責務に限定
* 認証処理は **すべて A-01 MagicLinkForm に委譲**
* セッション確立（PKCE）は A-03 AuthCallbackHandler 側の責務
* Windsurf が安定して構造を生成できるよう、**構造固定・責務分離**を徹底

---

# 第5章：関連ドキュメント（現行仕様のみ）

* **A-00 LoginPage 詳細設計 v1.x**（本書）
* **A-01 MagicLinkForm 詳細設計 v1.x**
* **A-03 AuthCallbackHandler 詳細設計 v1.x**（/auth/callback）
* **harmonet-technical-stack-definition_v4.4**（MagicLink専用版）
* **StaticI18nProvider / AppHeader / AppFooter 詳細設計**

---

# 第6章：改訂履歴

| Version | Summary                                               |
| ------- | ----------------------------------------------------- |
| v1.2    | Passkey・Corbado・二方式UI の残存箇所を完全削除。MagicLink専用の6章構成へ改訂。 |
| v1.1    | A-00 命名規則への整合、Index の軽量化。                             |
| v1.0    | 初版（旧仕様：MagicLink＋Passkey混在）。                          |

---

**End of Document**
