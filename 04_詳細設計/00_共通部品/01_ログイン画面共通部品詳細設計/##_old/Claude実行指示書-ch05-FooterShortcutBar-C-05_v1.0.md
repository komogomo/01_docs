# Claude実行指示書 - FooterShortcutBar (C-05) v1.0

**目的:**  
共通部品「FooterShortcutBar」を詳細設計書として作成する。  
本指示書は C-01〜C-04 の構造・品質基準を継承し、HarmoNet Design System に準拠した  
権限別ショートカットバーの初回設計を出力するための仕様定義である。

---

## 1. 対象情報

| 項目 | 内容 |
|------|------|
| Component ID | C-05 |
| Component Name | FooterShortcutBar |
| 分類 | 共通部品（Common Components） |
| 規模 | S |
| 難易度 | 3 |
| Safe Steps | 4 |
| 主な役割 | 権限別ショートカットリンク表示 |
| 依存関係 | StaticI18nProvider (C-03), Supabase Auth Context |
| 参照文書 | AppFooter(C-04), AppHeader(C-01), LanguageSwitch(C-02) 各詳細設計書 |

---

## 2. 機能要件

### 2.1 機能概要
- ログイン後画面の最下部に固定表示されるショートカットバー。
- 権限（system_admin / tenant_admin / general_user）に応じて  
  表示するボタンセットを切り替える。
- 各ボタンは主要機能画面へのナビゲーションリンクとなる。

### 2.2 表示ルール

| 権限 | 表示ボタン |
|------|-------------|
| **system_admin** | 設定 / テナント管理 / ログ |
| **tenant_admin** | 掲示板 / 施設予約 / 設定 |
| **general_user** | 掲示板 / アンケート / マイページ |

### 2.3 表示仕様
- 各ボタンはアイコン＋ラベル構成（shadcn/ui Buttonベース）
- アクティブ状態は Tailwind の `text-blue-600` + `border-t-2 border-blue-600`
- 非アクティブ時は `text-gray-500`
- スクリーンリーダー用 `aria-label` 設定必須

---

## 3. UI仕様

| 項目 | 値 |
|------|-----|
| 背景色 | `#FFFFFF` |
| ボーダー | `1px solid #E5E7EB` |
| 高さ | 64px |
| 配置 | fixed bottom-0 left-0 right-0 |
| z-index | 950（AppFooter:900 より上） |
| フォント | BIZ UD ゴシック |
| レイアウト | 横並び（flex justify-between） |
| アニメーション | hover時に淡い背景変化 (`hover:bg-gray-50`) |

---

## 4. 技術仕様

| 項目 | 内容 |
|------|------|
| フレームワーク | Next.js 16 / React 19 |
| スタイル | Tailwind CSS のみ |
| 状態管理 | React Context 経由で認証情報取得 |
| 翻訳 | StaticI18nProvider から `t(key)` 利用 |
| アクセシビリティ | `role="navigation"`、ボタンには `aria-label` |

---

## 5. 型定義

```typescript
export interface FooterShortcutBarProps {
  /** 現在のロール */
  role: 'system_admin' | 'tenant_admin' | 'general_user';
  /** 任意クラス追加 */
  className?: string;
  /** テストID */
  testId?: string;
}

6. テスト仕様
| テストID    | 内容             | 期待結果               |
| -------- | -------------- | ------------------ |
| T-C05-01 | 権限に応じて表示ボタンが変化 | 各ロールで定義通りボタン表示     |
| T-C05-02 | 翻訳ラベルが表示される    | 辞書キーが正常に取得される      |
| T-C05-03 | active状態が正しく反映 | `active`ボタンにスタイル付与 |
| T-C05-04 | ARIA属性が正しい     | roleとaria-labelが存在 |
| T-C05-05 | className適用    | 外部クラスが反映される        |

7. 出力条件

Claudeは以下を生成すること：

1.詳細設計書：ch05_FooterShortcutBar_v1.0.md
2.設計書には：

UI構成図

Props表

依存関係図
・TypeScript型定義
・Storybook例
・UT仕様
・実装例コード（React + Tailwind）

StaticI18nProviderとの連携を明示（t('common.xxx')使用）

8. 注意事項
・next-intlは禁止（StaticI18nProviderのみ使用）
・スタイルはTailwindのみ
・PrismaやSupabaseのSchema変更は禁止
・ストレージ操作を行わない
・CSS Modules・Styled Components使用禁止

9. 成果基準（Acceptance Criteria）
項目	基準
TypeCheck	Passed
ESLint / Prettier	エラーゼロ
Unit Tests	100% Passed
Storybook	ja/en/zh 各localeで確認可
構造整合性	C-01〜C-04と統一
自己採点平均	≥9.0/10

10. 出力先
/01_docs/04_詳細設計/00_共通部品/01_ログイン画面共通部品詳細設計/
└─ ch05_FooterShortcutBar_v1.0.md

作成日: 2025-11-09
作成者: Tachikoma
承認者: TKD