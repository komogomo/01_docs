# Windsurf修正指示書 - layout統合・StaticI18nProvider適正化 v1.0

**Document ID:** HARMONET-WINDSURF-FIX-LAYOUT-V1.0
**Created:** 2025-11-11
**Author:** Tachikoma (GPT Pro)
**Reviewer:** TKD
**Status:** ✅ 修正指示（Phase9正式構成整合）

---

## 第1章 修正概要

### 1.1 目的

本指示書は、HarmoNet プロジェクトにおける Next.js App Router のルート構成を Phase9 正式構成に統一し、**`StaticI18nProvider` を正式なルート（app/layout.tsx）で適用**するための修正を定義する。
旧構成 `src/app/layout.tsx` および `I18nRootProvider.tsx` を削除または退避し、ルート配下 (`/app/`) の layout.tsx を正式ファイルとして確定する。

---

## 第2章 対象ファイル

| 操作        | パス                                                  | 対応内容                        |
| --------- | --------------------------------------------------- | --------------------------- |
| ✅ 変更      | `D:\Projects\HarmoNet\app\layout.tsx`               | StaticI18nProvider の正式参照に修正 |
| 🗑️ 削除/退避 | `D:\Projects\HarmoNet\src\app\layout.tsx`           | 旧構成ファイル（使用禁止）               |
| 🗑️ 削除/退避 | `D:\Projects\HarmoNet\src\app\I18nRootProvider.tsx` | 旧 i18n Provider（非使用）        |

---

## 第3章 修正指示内容

### 3.1 修正版 layout.tsx

```tsx
// D:\Projects\HarmoNet\app\layout.tsx
import "./globals.css";
import React from "react";
import { StaticI18nProvider } from "@/components/common/StaticI18nProvider";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ja">
      <body className="bg-white text-gray-900 font-sans antialiased">
        <StaticI18nProvider>{children}</StaticI18nProvider>
      </body>
    </html>
  );
}
```

---

## 第4章 影響範囲分析

| コンポーネント                   | ID          | 影響内容                                                          | 対応要否   |
| ------------------------- | ----------- | ------------------------------------------------------------- | ------ |
| **StaticI18nProvider**    | C-03        | importパス (`@/components/common/StaticI18nProvider`) が正式ルートに一致 | ✅ 影響なし |
| **LanguageSwitch**        | C-02        | `useI18n` Hook の提供元が C-03 内部Contextで解決されるため構造的影響なし            | ✅ 影響なし |
| **AppHeader / AppFooter** | C-01 / C-04 | StaticI18nProvider の親Contextに位置するため動作影響なし                     | ✅ 影響なし |

結論：
既存共通部品（C-01〜C-05）への副作用は発生しない。
ただし、ローカルキャッシュをクリアし再ビルド（`npm run dev`）を推奨。

---

## 第5章 Acceptance Criteria

| 項目               | 基準                                             |
| ---------------- | ---------------------------------------------- |
| `npm run build`  | 成功（TypeCheck/Lintエラーなし）                        |
| TailwindCSS      | ログイン画面で正常反映（背景白・中央配置）                          |
| i18n             | 言語切替が引き続き正常動作                                  |
| 構成警告             | Duplicate root layout / Missing provider 警告が消失 |
| CodeAgent_Report | SelfScore ≥ 9.0 / 10（整合・安定性・再利用性）              |

---

## 第6章 CodeAgent_Report 出力先

```
/01_docs/05_品質チェック/CodeAgent_Report_layout統合修正版_v1.0.md
```

---

## 第7章 備考

* 本修正は **Phase9 構成最終統一処理** に該当する。
* 次フェーズ（Phase10）以降では、`/app` ルートが Windsurf の唯一の実行対象となる。
* 旧 `src/app` フォルダは削除または `_legacy` フォルダに退避すること。

---

**End of Instruction**
