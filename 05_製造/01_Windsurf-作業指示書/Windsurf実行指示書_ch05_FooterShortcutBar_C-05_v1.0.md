Windsurf実行指示書_ch05_FooterShortcutBar_C-05_v1.0.md

Document ID: HN-WINDSURF-C05-FOOTERSHORTCUTBAR
Component ID: C-05
Name: FooterShortcutBar
Category: 共通部品（ログイン後フッター）
Version: 1.0
Created: 2025-11-09
Author: Tachikoma
Approver: TKD

1. 目的

ch05_FooterShortcutBar_v1.0.md を実装・検証し、CodeAgent_Report を出力する。C-01〜C-04と整合するUI/設計・命名・QA基準を厳守。

2. 実装範囲

役割: 権限別ショートカット（アイコン＋ラベル）を最下部固定で表示

権限: system_admin | tenant_admin | general_user

表示ルール:
・system_admin: 設定 / テナント管理 / ログ
・tenant_admin: 掲示板 / 施設予約 / 設定
・general_user: 掲示板 / アンケート / マイページ
・翻訳: StaticI18nProvider（C-03）t('shortcut.xxx')
・アクティブ判定: usePathname() による現在パス判定（prefix一致OK）

3. 生成ファイル
src/components/common/FooterShortcutBar/
  ├─ FooterShortcutBar.tsx
  ├─ FooterShortcutBar.types.ts
  ├─ FooterShortcutBar.test.tsx
  ├─ FooterShortcutBar.stories.tsx
  └─ index.ts

4. 実装要件
・Props
export interface FooterShortcutBarProps {
  role: 'system_admin' | 'tenant_admin' | 'general_user';
  className?: string;
  testId?: string;
}

・UI/Tailwind（固定下部・全幅）
　fixed bottom-0 left-0 right-0 h-16 bg-white border-t border-gray-200 z-[950]
　内部は flex justify-between items-center px-3、ボタンは flex flex-col items-center gap-1 text-xs

・アクティブ状態
　text-blue-600 border-t-2 border-blue-600（非アクティブは text-gray-500）

・アクセシビリティ
　ルート要素: <nav role="navigation" aria-label="ショートカットバー">
　各ボタン: aria-label 必須

・ルーティング
　next/link 使用。usePathname() で pathname.startsWith(href) をアクティブ条件に利用

・i18nキー例
　shortcut.board, shortcut.booking, shortcut.survey, shortcut.mypage, shortcut.settings, shortcut.tenants, shortcut.logs
　※ public/locales/{ja,en,zh}/common.json に不足分があれば追加

5. テスト（Jest + RTL）
| ID       | 観点               | 期待結果                             |
| -------- | ---------------- | -------------------------------- |
| T-C05-01 | 権限別表示            | 各roleでボタンセットが仕様通り                |
| T-C05-02 | 翻訳表示             | ラベルが辞書から表示される                    |
| T-C05-03 | アクティブ判定          | 現在パスに合致するボタンがactiveスタイル          |
| T-C05-04 | ARIA             | nav/aria-label/各ボタンaria-labelが妥当 |
| T-C05-05 | className/testId | 外部クラス/`data-testid` 反映           |

テストでは fetch モックで辞書を供給。usePathname はモックして各パスを検証。

6. Storybook
・Stories: Default(ja), English(en), Chinese(zh) の3本
・各ストーリーを StaticI18nProvider currentLocale でラップ
・role は Controls で切替可、初期は general_user

7. 禁止事項
・next-intl 使用（C-03のみ依存）
・schema.prisma / Supabase 改変
・外部CSSやStyled Components追加
・ディレクトリ・命名の変更

8. 受入基準（Acceptance Criteria）
・TypeCheck: Passed（strict）
・ESLint/Prettier: エラー0
・Unit Tests: 100% Passed（T-C05-01〜05）
・Storybook: ja/en/zh 確認可
・構造整合: C-01〜C-04 と統一
・自己採点: 平均 ≥ 9.0/10

9. CodeAgent_Report 出力
テンプレート：
[CodeAgent_Report]
Agent: Windsurf
Component: FooterShortcutBar (C-05)
Attempt: 1
AverageScore: 9.x/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 仕様準拠。role別表示/アクティブ判定/i18n/ARIA/Story 完了。

[Generated_Files]
- src/components/common/FooterShortcutBar/FooterShortcutBar.tsx
- src/components/common/FooterShortcutBar/FooterShortcutBar.types.ts
- src/components/common/FooterShortcutBar/FooterShortcutBar.test.tsx
- src/components/common/FooterShortcutBar/FooterShortcutBar.stories.tsx
- src/components/common/FooterShortcutBar/index.ts
- public/locales/ja/common.json
- public/locales/en/common.json
- public/locales/zh/common.json
- jest.config.mjs
- setupTests.ts
- .eslintrc.json
- .prettierrc
- .storybook/main.ts
- .storybook/preview.ts

保存先（統一ルール）
D:\AIDriven\01_docs\05_品質チェック\01_ログイン画面共通部品\CodeAgent_Report_FooterShortcutBar_v1.0.md