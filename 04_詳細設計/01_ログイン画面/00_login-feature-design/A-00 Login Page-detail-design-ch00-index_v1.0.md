# A-00 LoginPage 詳細設計書 ch00：Index v1.1

## 第1章：目的

A-00 LoginPage 詳細設計書（ch01〜ch06）の総覧として、**各章が担う責務・依存関係・関連設計書の位置づけを簡潔に明示し、全体構造を俯瞰できるインデックス**を提供する。本章はあくまで「目次と設計思想の要約」に特化し、技術密度は ch01 以降に集中させる。

## 第2章：章構成一覧

以下は A-00 LoginPage の詳細設計を構成する全6章である。

* **ch01 UI構成**：画面レイアウト、共通部品配置、レスポンシブ要件、最大幅420pxデザイン、Appleカタログ風トーン
* **ch02 状態管理**：MagicLink + Passkey の UI状態、イベント発火、状態遷移、再レンダー要件
* **ch03 認証構成**：Supabase + Corbado の認証統合フロー、OTP・Passkey 並立ロジック
* **ch04 SessionHandler**：/api/session によるセッション検証、Corbado→Supabase 連携
* **ch05 セキュリティ**：Cookie・RLS・脅威モデル・Origin保護・WebAuthn要件
* **ch06 PasskeyAuthTrigger**：A-02 コンポーネントのトリガー動作、/login/passkey 遷移の責務

## 第3章：技術前提（要点）

* **Next.js 16 / React 19 / TypeScript 5.6**
* **Supabase Auth + Corbado SDK（WebAuthn）**
* **StaticI18nProvider (C-03)** による3言語辞書（ja/en/zh）
* **白基調・Appleカタログ風UI**、BIZ UDゴシック採用
* 共通部品（C-01〜C-05）との完全整合

## 第4章：設計思想（A-00 全体方針）

LoginPage は **認証方式の統合 UI を提供するレイアウト担当** とし、認証ロジック自体を下位コンポーネント（A-01 MagicLinkForm、A-02 PasskeyAuthTrigger、/api/session）へ明確に分離する。

設計方針は次の通り：

* UI と認証ロジックの分離により **Windsurf が安定生成できる構造**に統一
* Passkey と MagicLink を「並列に並べず、自然に統合された UX」へ収束
* 認証後は `/mypage` へ遷移し、FooterShortcutBar（C-05）が有効化

## 第5章：関連ドキュメント

* harmonet-technical-stack-definition_v4.2
* A-01 MagicLinkForm 詳細設計書
* A-02 PasskeyAuthTrigger 詳細設計書
* ch01_AppHeader / ch04_AppFooter など共通部品設計
* HarmoNet Passkey挙動仕様

## 第6章：改訂履歴

* **v1.1**：A-00 命名規則へ正式移行、Indexの軽量化。ch01〜ch06 との整合を再構築。
