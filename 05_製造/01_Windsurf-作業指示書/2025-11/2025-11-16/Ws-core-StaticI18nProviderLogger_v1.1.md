# WS-CORE_StaticI18nProvider_Logger_v1.1

**Windsurf 実行指示書（基盤セット：StaticI18nProvider + Logger）最終確定版**

**Task Category:** Core Infrastructure Update
**Target Components:** C-03 StaticI18nProvider, Common Logger
**Directory Standard:** harmoNet-frontend-directory-guideline_v1.0（正式版）
**Design Specs:** v1.1（TKD承認済み最新版）
**Output Format:** Windsurf self-report + File generation

---

# 1. Task Summary（タスク概要）

本タスクは、HarmoNet の基盤ロジック層である **StaticI18nProvider（C-03）** および **共通ログユーティリティ（Logger）** を、最新設計書 v1.1 に完全整合する形へ **再生成／修正** する。
Windsurf は以下の作業を行う：

1. **StaticI18nProvider（C-03）を v1.1 仕様で全面再生成**
2. **StaticI18nProvider.test.tsx を v1.1 仕様に全面更新**
3. **Logger 3ファイル（log.util / config / types）を新規実装（v1.1）**
4. **import をすべて @/src/... の絶対パスに統一**
5. **既存ファイルはすべてバックアップ後に安全上書き**

> UIを持たないため、Windsurf が最も安定して処理できるタスクです。
> 状態管理・辞書ロード・翻訳ロジックを中心に最適化してください。

---

# 2. Target Files（編集対象ファイル）

以下のファイルを Windsurf が生成／修正する：

```
src/components/common/StaticI18nProvider/StaticI18nProvider.tsx
src/components/common/StaticI18nProvider/StaticI18nProvider.types.ts
src/components/common/StaticI18nProvider/index.ts
src/components/common/StaticI18nProvider/StaticI18nProvider.test.tsx

src/lib/logging/log.util.ts
src/lib/logging/log.types.ts
src/lib/logging/log.config.ts
```

※ 既存ファイルがある場合、**同一ディレクトリ内にバックアップ**してから上書きする。

---

# 3. Project Root / Output Root（重要）

### Windsurf は複数ワークスペースを誤認するため、**必ず以下をプロジェクトルートとすること：**

```
D:\AIDriven
```

### すべての出力パスは **絶対パス** で指定する：

```
D:\AIDriven\01_docs\06_品質チェック\CodeAgent_Report_CORE_StaticI18nProvider_Logger_v1.1.md
```

**相対パス（./01_docs/...）の使用は禁止。**

---

# 4. References（唯一の正）

Windsurf は以下の設計書のみを “正” として扱う：

* **ch03_StaticI18nProvider_v1.1.md**（最新版）
* **HarmoNet 共通ログユーティリティ詳細設計 v1.1**
* **harmoNet-frontend-directory-guideline_v1.0**
* **harmoNet-technical-stack-definition_v4.3**
* **ch00_CommonComponents_Index_v1.1**
* **本指示書（v1.1）**

> これ以外の旧資料は参照禁止。推測・独自補完も禁止。

---

# 5. Implementation Rules（実装ルール）

## 5.1 StaticI18nProvider（C-03）

### ★ 実装方針（TKD承認済み）

* Logger **非使用（console のみ）**
* Props は **children のみ**（`initialLocale` などは削除）
* localStorage キーは **'selectedLanguage'** に統一
* fallbackLocale は **'ja'**
* t(key) は **params 非対応**（`t(key: string)` のみ）
* useMemo / useCallback を使用してパフォーマンスを最適化
* fetch パスは `/locales/${locale}/common.json` に固定
* 多段キー（`common.submit`）に対応
* Provider 外で useI18n() が呼ばれた場合は Error throw

### ★ 禁止

* next-intl 導入禁止
* Logger 呼び出し禁止（logInfo / logWarn など）
* UI 要素追加禁止

---

## 5.2 Logger（共通ログユーティリティ）

### ★ 実装方針（v1.1 固定）

* ファイル構成：

```
src/lib/logging/log.types.ts
src/lib/logging/log.config.ts
src/lib/logging/log.util.ts
```

* export 関数：`logDebug / logInfo / logWarn / logError`
* 出力形式：`console.*(JSON.stringify(payload))`
* PII（メールアドレス）簡易マスキング必須
* NODE_ENV === 'test' → 出力無効
* import はすべて **@/src/lib/logging/...** に統一

### ★ 禁止

* 外部ライブラリ追加禁止
* JSON schema 変更禁止
* Logger を StaticI18nProvider 内で呼び出すこと

---

## 5.3 既存コードの扱い

* 修正前のファイルは必ず以下の形式でバックアップ：

```
<元ファイル名>_20251116_v0.1.bk
```

* バックアップ作成後に上書き生成してよい

---

# 6. Acceptance Criteria（受入基準）

* TypeCheck：0エラー
* ESLint：0エラー
* Prettier：整形済み
* Jest（StaticI18nProvider.test.tsx）：全テスト PASS
* Build：成功
* SelfScore：平均 9.0 以上

---

# 7. Backup Rules（必須）

```
例：StaticI18nProvider.tsx_20251116_v0.1.bk
```

* バックアップは **同一ディレクトリ** に作成
* 元ファイル名を変更しないこと

---

# 8. CodeAgent_Report（必須）

Windsurf は作業完了後、以下の **絶対パス** にレポートを保存する：

```
D:\AIDriven\01_docs\06_品質チェック\CodeAgent_Report_CORE_StaticI18nProvider_Logger_v1.1.md
```

### レポート形式

```
[CodeAgent_Report]
Agent: Windsurf
Task: CORE_StaticI18nProvider_Logger
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - ch03_StaticI18nProvider_v1.1.md
 - log.util.ts
 - log.config.ts
 - log.types.ts
 - harmonet-technical-stack-definition_v4.3
[Generated_Files]
 - <生成/更新ファイル一覧>
Summary:
 - 実施内容の要約
 - 注意点
```

---

# 9. Testing Method（検証手順）

Windsurf 実行後、TKDが次の手順で受け入れ確認を行う：

```
npm run type-check
npm run lint
npm test src/components/common/StaticI18nProvider
npm run build
```

全て合格した場合、タスク①（基盤セット）は完了。
タスク②（認証セット：MagicLink + Passkey）へ進む。

---

**以上の内容で Windsurf を実行してください。**
