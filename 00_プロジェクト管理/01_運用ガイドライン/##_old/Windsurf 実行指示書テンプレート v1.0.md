# Windsurf 実行指示書テンプレート v1.0

**格納先推奨:** `D:\AIDriven\01_docs\00_プロジェクト管理\01_運用ガイドライン`

---

## 1. 目的

Windsurf に対して実装タスクを依頼する際の **標準化された指示書テンプレート**。
指示漏れ（参照ドキュメント、出力先、禁止事項、Acceptance Criteria）を完全に排除し、HarmoNet の SDD/ADD フローを安定させるために使用する。

以後タチコマは、Windsurf 向け指示書を生成する際、必ず **本テンプレートを基礎として出力** する。

---

## 2. 使用タイミング

* コンポーネント新規実装
* UI統合
* リファクタリング（※構造整理のみ）
* Hook / Utility 実装
* バグ修正（コード変更を伴う場合）

---

# 【Windsurf 実行指示書テンプレ】

以下がタチコマが生成する正式テンプレート（雛形）。

```
# WS-<ComponentID>_<TaskName>_vX.Y

## 1. Task Summary（タスク概要）
- 目的: <何を実装するか>
- 対象コンポーネント: <AppHeader / MagicLinkForm / LoginLayout など>
- 修正範囲: <ファイル or ディレクトリ指定>
- 注意: UI/ロジックの変更禁止／許可を明確化

---

## 2. Target Files（編集対象ファイル）
- <相対パス1>
- <相対パス2>
- <相対パス3>

※ **対象ファイルは TKD 指定の最新ファイルのみ**。  
※ タチコマは 11月10日以降にアップロードされたファイル以外を参照しない。

---

## 3. Import & Directory Rules（公式ルール）
本タスクは HarmoNet フロントエンド構成 v1.0 に完全準拠すること。

```

src/
components/
common/          ← C-01〜C-05
auth/            ← A-01〜A-03
ui/
hooks/
utils/

app/
layout.tsx
login/page.tsx
auth/callback/page.tsx

```

- import パスは `@/src/...` に統一すること
- 既存ディレクトリの rename / 削除 / 移動は禁止

---

## 4. References（参照ドキュメント）
以下の設計書を Windsurf の唯一の正として扱う：

- <参照1: 例) ch01_AppHeader_v1.0.md>
- <参照2: 例) MagicLinkForm-detail-design_v1.1.md>
- <参照3: 例) harmonet-technical-stack-definition_v4.2.md>

※ 必ず **TKD がアップロードした最新版のみ** を記載すること。
※ 漏れや誤参照を防止するため、タチコマは毎回「参照リスト」を完全列挙する。

---

## 5. Implementation Rules（実装ルール）
- Tailwind クラス変更禁止（UI改変禁止）
- 不要な責務追加禁止
- Props 追加・削除禁止（指定がある場合を除く）
- コンポーネント構造の変更禁止（指定された部分以外）
- import の統一（絶対パスのみ）
- コーディング規約（harmonet-coding-standard_v1.1）遵守

---

## 6. Acceptance Criteria（受入基準）
Windsurfの自己採点に基づく：
- TypeCheck: 0 エラー
- ESLint: 0 エラー
- Prettier: 0 エラー
- Jest / RTL: 全テスト成功（対象コンポーネントのみ）
- Storybook: 表示崩れなし
- SelfScore（精度/保守性/再現性）: 平均 9.0 以上
- UIトーン（やさしく・自然・控えめ）完全準拠

---

## 6.5 Backup Rules（重要：バックアップ運用）
既存ファイルを Windsurf が修正する場合、**必ず以下のバックアップ手順を実施すること**。

### ■ Backup 命名規則
```

<元ファイル名>_<YYYYMMDD>_v0.1.bk

```
**例:**
```

AppHeader.tsx_20251114_v0.1.bk
MagicLinkForm.tsx_20251114_v0.1.bk

```

### ■ Backup 保存場所
バックアップは元ファイルと**同一ディレクトリ**に保存すること。
- 例: `src/components/common/AppHeader/` 内に .bk を配置

### ■ Backup 動作条件
Windsurf は以下の条件でバックアップを作成：
1. ターゲットファイルが **既に存在している場合**
2. 内容を書き換えるタスクである場合（リファクタ / 統合 / 修正など）
3. 新規ファイル作成のみの場合はバックアップ不要

### ■ 注意事項
- バックアップファイルは **自動的に参照対象外** とする（import禁止）。
- TKD が手動で復元できるように、**上書き・削除は絶対禁止**。

---

## 7. Forbidden Actions（禁止事項）
- ディレクトリ構成の変更
- ファイル名変更
- 新規 CSS ファイル追加
- UI トーン変更
- コンポーネントの意味的責務を変える修正
- 指示書に書かれていない改善・最適化
- 外部ライブラリの追加

---

## 8. CodeAgent_Report（必須）
Windsurf はタスク完了後、以下形式のレポートを出力すること：

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
<生成・更新されたファイルパスをすべて列挙>
例:

* src/components/common/AppHeader/AppHeader.tsx
* src/components/common/AppHeader/AppHeader.test.tsx
* src/app/login/page.tsx
* public/images/logo-harmonet.png

Summary:

* 実施内容サマリ
* 注意点
* 改善必要点

```

### ■ Report 出力先（必須）
```

/01_docs/05_品質チェック/CodeAgent_Report_<TaskName>_vX.Y.md

```

Windsurf はタスク完了後、以下形式のレポートを出力すること：

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
  Summary:
* 実施内容サマリ
* 注意点
* 改善必要点

```

### ■ Report 出力先（必須）
```

/01_docs/05_品質チェック/CodeAgent_Report_<TaskName>_vX.Y.md

```

---

## 9. Testing Method (Windsurf 実行時の検証手順)
Windsurf がタスクを完了した後、TKD が受け入れを判断するための **標準テスト手順** を明記する。

### 9.1 手動テスト手順（UI / Layout 検証）
1. 該当コンポーネントを Storybook で開く
2. **Idle / Loading / Error / Success** など全 UI 状態を確認
3. Tailwind クラスがテンプレート通りか確認（余白・角丸・色・影）
4. 指定したコンポーネント（例：AppHeader / MagicLinkForm）が正しく表示される
5. LoginLayout などレイアウト調整タスクでは **中央寄せ / 幅 / 余白** を目視確認
6. Console に Warning / Error が出ていないことを確認

### 9.2 Jest / RTL 自動テスト手順
1. `npm test <対象コンポーネント>` を実行
2. テストスイートが **100% PASS** であることを確認
3. Snapshot（存在する場合）が正しく更新されているか確認
4. Mock 化されたハンドラ（onSent / onError など）が仕様通り呼び出されることを確認

### 9.3 TypeCheck / Lint / Build テスト
```

npm run type-check
npm run lint
npm run build

```
- TypeScript エラー 0 件
- ESLint エラー 0 件
- Turbopack ビルド成功

### 9.4 E2E（必要なタスクの場合のみ）
- Playwright による遷移検証（ログインフローなど）
- UI がタップ可能であること（モバイルサイズ含む）

---

## 10. 改訂履歴
- **v1.0（2025-11-14）**: 初版（TKD コメント反映）
```
