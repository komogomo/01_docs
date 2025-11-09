# Claude実行指示書 - AppFooter (C-04) v1.0

**目的:**  
共通部品「AppFooter」を詳細設計書として作成する。  
本指示書はClaudeがC-01〜C-03の構造・品質基準を継承し、HarmoNetのデザイン・実装方針に沿った初回設計を出力するための仕様定義である。

---

## 1. 対象情報

| 項目 | 内容 |
|------|------|
| Component ID | C-04 |
| Component Name | AppFooter |
| 分類 | 共通部品（Common Components） |
| 規模 | S |
| 難易度 | 1 |
| Safe Steps | 2 |
| 主な役割 | コピーライト表示（固定フッター） |
| 依存関係 | StaticI18nProvider (C-03) から `t(key)` で文言取得 |
| 参照文書 | AppHeader(C-01)、LanguageSwitch(C-02)、StaticI18nProvider(C-03) 各詳細設計書 |

---

## 2. 設計要件

### 2.1 機能要件
- 画面最下部に固定表示されるフッター領域。
- HarmoNet共通デザインに準拠し、コピーライト表記を静的に表示。
- 翻訳は StaticI18nProvider 経由の `t('common.copyright')`
- クリックイベントや動的状態を持たない stateless component。

### 2.2 UI仕様
| 項目 | 値 |
|------|-----|
| 背景色 | `#FFFFFF` |
| テキスト色 | `#9CA3AF` (gray-400) |
| 高さ | 48px |
| 配置 | 画面下部固定（fixed bottom-0 left-0 right-0） |
| フォント | BIZ UD ゴシック、12px |
| テキスト中央揃え |
| 文言 | `© 2025 HarmoNet. All rights reserved.`（翻訳キーで対応） |

### 2.3 アクセシビリティ
- `<footer role="contentinfo">` を使用。
- スクリーンリーダー対応のため `aria-label="フッター領域"` を付与。

### 2.4 型定義
```typescript
export interface AppFooterProps {
  className?: string;
  testId?: string;
}

2.5 ファイル構成
src/
└── components/
    └── common/
        └── AppFooter/
            ├── AppFooter.tsx
            ├── AppFooter.types.ts
            ├── AppFooter.test.tsx
            ├── AppFooter.stories.tsx
            └── index.ts

3. テスト仕様
| テストID    | 内容             | 期待結果                              |
| -------- | -------------- | --------------------------------- |
| T-C04-01 | コピーライト文言が表示される | 翻訳キー出力がDOMに存在                     |
| T-C04-02 | セマンティックHTML    | `<footer role="contentinfo">` が存在 |
| T-C04-03 | クラス適用          | `className` が反映される                |

4. 出力条件

Claudeは以下を生成すること：
・詳細設計書：ch04_AppFooter_v1.0.md
・構成・章立てはC-01〜C-03と統一
・翻訳参照はStaticI18nProvider準拠
・Storybook・テスト含む完全版

次工程用テンプレート：

Windsurf実行指示書_ch04_AppFooter_C-04_v1.0.md
→ Claude完了後、タチコマが自動作成予定。

5. 注意事項

next-intlは禁止。StaticI18nProvider利用。
・スタイルはTailwind CSSのみ。外部CSSやstyled-components禁止。
・ESLint/Prettierエラーゼロ。
・TypeScript strictモード対応。
・schema.prisma・DB構造に触れない。

6. 成果基準（Acceptance Criteria）
項目	基準
構造整合	C-01〜C-03と章構成一致
TypeCheck	Passed
Lint	Passed
Tests	100% Passed
自己採点平均	≥ 9.0/10
出力形式	Markdown完全版1枚構成

7. 出力先
/01_docs/04_詳細設計/00_共通部品/01_ログイン画面共通部品詳細設計/
└─ ch04_AppFooter_v1.0.md

次工程: Windsurf実行指示書生成
作成日: 2025-11-09
作成者: Tachikoma
承認者: TKD