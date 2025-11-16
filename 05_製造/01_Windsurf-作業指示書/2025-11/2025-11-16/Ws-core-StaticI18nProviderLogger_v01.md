# WS-CORE_StaticI18nProvider_Logger_v1.0

**Windsurf 実行指示書（基盤セット：StaticI18nProvider + Logger）**

**Task Category:** Core Infrastructure Update
**Target Components:** C-03 StaticI18nProvider, Common Logger (log.util.ts / log.types.ts / log.config.ts)
**Directory Standard:** harmonet-frontend-directory-guideline_v1.0（正式版）
**Design Specs:** v1.1（最新）
**Output Format:** Windsurf self-report + File generation

---

## 1. Task Summary（タスク概要）

基盤コンポーネント **StaticI18nProvider（C-03）** と **共通ログユーティリティ（Logger）** を、
HarmoNet 最新仕様（v4.3 技術スタック、v1.1 詳細設計）に完全整合する形で **再生成 / 修正** する。

Windsurf は以下を行う：

1. **StaticI18nProvider の全面再生成（v1.1 完全版）**
2. **Logger（log.util / log.types / log.config）の統一仕様へのアップデート**
3. **import / ディレクトリ構成の統一（@/src/...）**
4. **既存コードは必要に応じて置換（バックアップルール遵守）**

> UI を含まない純ロジック層タスクであるため、Windsurf に最も適した安全なタスク。

---

## 2. Target Files（編集対象ファイル）

**以下のファイルを Windsurf が生成 / 修正対象とする：**

```
src/components/common/StaticI18nProvider/StaticI18nProvider.tsx
src/components/common/StaticI18nProvider/StaticI18nProvider.types.ts
src/components/common/StaticI18nProvider/index.ts

src/lib/logging/log.util.ts
src/lib/logging/log.types.ts
src/lib/logging/log.config.ts
```

※ 既存ファイルが存在する場合はバックアップ作成後に上書き

---

## 3. Import & Directory Rules（公式ルール）

```
src/
  components/
    common/
      StaticI18nProvider/
  lib/
    logging/
```

* import パスはすべて **@/src/...** で統一
* 未使用ファイルの削除は不可（バックアップルール順守）
* ディレクトリ名・ファイル名は変更禁止

---

## 4. References（参照ドキュメント）

以下を Windsurf が唯一の正とする：

* ch03_StaticI18nProvider_v1.1（最新版）
* harmoNet-technical-stack-definition_v4.3
* harmoNet-frontend-directory-guideline_v1.0
* 共通ログユーティリティ詳細設計書 v1.1
* ch00_CommonComponents_Index_v1.1

---

## 5. Implementation Rules（実装ルール）

### StaticI18nProvider

* next-intl 非依存
* locale 主導（props 受け取り禁止）
* fallbackLocale = 'ja'
* 辞書パス：`/locales/${locale}/common.json`
* t(key) は多段キー解析に対応
* useMemo / useCallback で最適化

### Logger

* console.log 系は logDebug / logInfo / logWarn / logError のみ使用
* PII（メールアドレス）マスキング仕様を維持
* JSON 形式出力を保持
* NODE_ENV = test の場合は無効

### 禁止事項

* UI 追加禁止
* import の相対パス使用禁止（絶対パス強制）
* Props 追加禁止（Provider）
* 外部ライブラリ追加禁止

---

## 6. Acceptance Criteria（受入基準）

* TypeCheck：0エラー
* ESLint：0エラー
* Prettier：整形済み
* Jest：StaticI18nProvider のテストが PASS
* SelfScore：9.0 以上
* Storybook（必要箇所のみビルド成功）

---

## 6.5 Backup Rules（バックアップ必須）

既存ファイルに修正を行う場合：

```
<元ファイル名>_20251116_v0.1.bk
```

* 同一ディレクトリに作成
* Windsurf はバックアップ後に上書き実行

---

## 7. Forbidden Actions（禁止事項）

* ディレクトリ変更
* ファイル名変更
* UI追加（StaticI18nProvider はロジック専用）
* Logger の出力形式変更（仕様固定）
* i18n 辞書ファイルの更新（今回は対象外）

---

## 8. CodeAgent_Report（必須）

Windsurf はタスク完了後、以下を **D:\AIDriven\01_docs\06_品質チェック\CodeAgent_Report_CORE_StaticI18nProvider_Logger_v1.0.md** に保存する：

```
[CodeAgent_Report]
Agent: Windsurf
Task: CORE_StaticI18nProvider_Logger
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed/Failed
Lint: Passed/Failed
Tests: <pass率>
References:
 - ch03_StaticI18nProvider_v1.1.md
 - log.util.ts
 - log.config.ts
 - log.types.ts
 - harmonet-technical-stack-definition_v4.3
[Generated_Files]
 - <生成/更新されたファイル一覧>
Summary:
 - 実施内容
 - 注意点
```

[CodeAgent_Report]
Agent: Windsurf
Task: CORE_StaticI18nProvider_Logger
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed/Failed
Lint: Passed/Failed
Tests: <pass率>
References:

* ch03_StaticI18nProvider_v1.1.md
* log.util.ts
* log.config.ts
* log.types.ts
* harmonet-technical-stack-definition_v4.3
  [Generated_Files]
* <生成/更新されたファイル一覧>
  Summary:
* 実施内容
* 注意点

```

---

## 9. Testing Method（検証手順）
1. `npm run type-check`
2. `npm run lint`
3. `npm test src/components/common/StaticI18nProvider`
4. `npm run build`

---

**以上の内容で Windsurf を実行してください。**

```
