# Windsurf 実行指示書テンプレート v1.2（重複修正版）

**格納先推奨:** `D:\AIDriven\01_docs\00_プロジェクト管理\01_運用ガイドライン`

---

## 1. 目的

Windsurf に対して実装タスクを依頼する際の **標準化された指示書テンプレート**。
参照ドキュメントの明確化、出力先パス、禁止事項、受入基準を一元管理し、HarmoNet の SDD/ADD フローを安定させることを目的とする。

以後タチコマは、Windsurf 向け指示書を生成する際、本テンプレートを基礎として **必ず出力** する。

---

## 2. 使用タイミング

* コンポーネント新規実装
* UI 統合
* リファクタリング（構造整理のみ）
* Hook / Utility 実装
* バグ修正（コード変更を伴う場合）

---

# 【Windsurf 用 指示書テンプレート】

```
# WS-<ComponentID>_<TaskName>_vX.Y

## 1. Task Summary（タスク概要）
- 目的: <何を実現するか>
- 対象コンポーネント: <AppHeader / MagicLinkForm / LoginLayout 等>
- 修正範囲: <対象ファイルまたはディレクトリ>
- 注意: UI/ロジックの変更禁止など、制約を明確化

---

## 2. Target Files（編集対象ファイル）
- <相対パス1>
- <相対パス2>
- <相対パス3>

※ 対象は **TKD 指定の最新版のみ**

---

## 3. Import & Directory Rules（公式ルール）
本タスクは **HarmoNet フロントエンド構成 v1.0** に完全準拠すること。

```

src/
components/
common/         ← C-01〜C-05
auth/           ← A-01〜A-03
ui/
hooks/
utils/

app/
layout.tsx
login/page.tsx
auth/callback/page.tsx

```

- import パスは `@/src/...` 形式に統一
- 既存ファイルの rename / 削除 / 移動は禁止（指示された場合のみ許可）

---

## 4. References（参照ドキュメント）
以下の設計書を Windsurf の唯一の正として扱う：
- <参照1>
- <参照2>
- <参照3>

※ 漏れ防止のため、タチコマは毎回 **参照リストを完全列挙** する。

---

## 5. Implementation Rules（実装ルール）
- Tailwind クラス変更禁止（UI改変不可）
- Props 追加・削除禁止（指定がある場合のみ許可）
- 不要な責務追加禁止
- 構造変更は **指示された部分のみ**
- import パスは絶対パスに統一
- harmonet-coding-standard_v1.1 に従う

---

## 6. Acceptance Criteria（受入基準）
- TypeCheck: 0 エラー
- ESLint: 0 エラー
- Prettier: 0 エラー
- Jest / RTL: 対象コンポーネントのテスト 100% PASS
- Storybook: 画面崩れなし
- SelfScore (精度/保守性/再現性): 平均 9.0 以上
- UI トーン（やさしく・自然・控えめ）の完全準拠

---

## 6.5 Backup Rules（バックアップルール：上書き/削除がある場合）
既存ファイルを修正する場合、以下を必ず実施する：

### ■ 命名規則
```

<元ファイル名>_<YYYYMMDD>_v0.1.bk

```
例：
```

AppHeader.tsx_20251114_v0.1.bk

```

### ■ 保存場所
- 元ファイルと同一ディレクトリ

### ■ 動作条件
- 既存ファイルが存在し、かつ上書き/削除が発生する場合

---

## 7. Forbidden Actions（禁止事項）
- ディレクトリ構成の勝手な変更
- ファイル名変更（指示がある場合を除く）
- 新規 CSS ファイル追加
- UI トーンの変更
- コンポーネントの責務変更
- 不要な改善・最適化
- 外部ライブラリ追加

---

## 8. CodeAgent_Report（必須）
Windsurf はタスク完了後、以下形式で **レポートを作成しファイルに保存** すること：

```

[CodeAgent_Report]
Agent: Windsurf
Task: <TaskName>
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:

* <参照ファイル1>
* <参照ファイル2>
* <参照ファイル3>

[Generated_Files]

* <生成/更新されたファイル一覧>

Summary:

* 実施内容サマリ
* 注意点
* 改善必要点

```

### ■ Report Export（保存先：必須）
```

/01_docs/06_品質チェック/CodeAgent_Report_<TaskName>_vX.Y.md

```

※ 重複禁止。この場所に **1回だけ** 記載すること。

---

## 9. Testing Method（検証手順）
Windsurf 実行後、TKD が受け入れ判断するための標準手順：

### 9.1 UI / Layout（手動）
- Storybook で全状態を確認
- Idle / Loading / Error / Success を目視確認
- Tailwind クラス（余白・角丸・影）の確認
- コンソールエラーの有無

### 9.2 Jest / RTL
- `npm test <対象>` を実行
- 100% PASS を確認

### 9.3 TypeCheck / Lint / Build
```

npm run type-check
npm run lint
npm run build

```

---

## 10. 改訂履歴
- **v1.1（2025-11-14）**: CodeAgent_Report セクションの重複除去、Report Export を統一し1箇所に固定。
- **v1.0（2025-11-14）**: 初版（TKD コメント反映）
```
