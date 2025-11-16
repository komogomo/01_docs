# WS-AUTH_LoginModules_v1.0

**Windsurf 実行指示書（MagicLinkForm + PasskeyAuthTrigger 完全再生成）**

**Task Category:** Auth Module Rebuild (A-01 + A-02)
**Target Components:** MagicLinkForm（A-01）, PasskeyAuthTrigger（A-02）
**Directory Standard:** harmonet-frontend-directory-guideline_v1.0
**Design Specs:** MagicLinkForm v1.3 / PasskeyAuthTrigger v1.3 / LoginPage v1.2 / TechStack v4.3
**Output:** 新規コード生成 + 既存バックアップ + CodeAgent_Report

---

# 0. Pre-Cleanup（旧構成の削除 — 必須）

以下の旧ディレクトリは HarmoNet v4.3 の正式仕様と完全に非互換であり、
Windsurf が誤参照・推測・AST 誤置換を行う危険性が高いため、**必ず削除すること**。

### ■ 削除対象ディレクトリ（完全廃止）

```
src/components/auth/PasskeyButton/
src/components/login/PasskeyButton/
src/components/auth/utils/_deprecated_passkey/
```

### ■ 注意

* 上記以外のディレクトリを削除してはならない。
* 削除後、A-01 / A-02 の `MagicLinkForm/` `PasskeyAuthTrigger/` を新規に正式構成として再生成する。
* 旧仕様の PasskeyButton は廃止されたため、**保管価値なし・参照禁止**。

---

# 1. Task Summary（タスク概要）

MagicLink（メール認証）と Passkey（WebAuthn）を **左右2枚のカードタイルとして独立** させる HarmoNet 最新仕様（技術スタック v4.3）に基づき、

**A-01 MagicLinkForm** および **A-02 PasskeyAuthTrigger** を **全面再生成（フルリビルド）** するタスク。

本タスクでは、旧仕様（統合方式 / 不完全なPasskeyButton構成 / importの混在）を完全に破棄し、

* **UI（カードタイル）**
* **ロジック（MagicLink / WebAuthn）**
* **i18n（auth.login.* 全般）**
* **ログ仕様（logInfo / logError）**
* **状態遷移（A-01 / A-02）**
* **エラー分類とメッセージ体系**

をすべて最新設計へ刷新する。

> A案（全面再生成）を採用するため、旧コードの部分修正は禁止。
> Windsurf はバックアップ後、**新規コードを生成**して上書きすること。

---

# 2. Target Files（編集対象ファイル）

以下のファイルを Windsurf が **新規生成 / 上書き対象** とする。
（※ 旧 PasskeyButton は前章で削除済みであることが前提）

```
src/components/auth/MagicLinkForm/MagicLinkForm.tsx
src/components/auth/MagicLinkForm/MagicLinkForm.types.ts
src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx
src/components/auth/MagicLinkForm/MagicLinkForm.stories.tsx
src/components/auth/MagicLinkForm/index.ts

src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.tsx
src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.types.ts
src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.test.tsx
src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger.stories.tsx
src/components/auth/PasskeyAuthTrigger/index.ts
```

### ■ バックアップ保存名

```
<元ファイル名>_20251116_v0.1.bk
```

同一ディレクトリに保存すること。

---

# 3. Import & Directory Rules（公式ルール）

本タスクは **HarmoNet 公式ディレクトリ構成 v1.0** に完全準拠する。
fileciteturn5file2

```
src/
  components/
    common/           ← C-01〜C-05
    auth/             ← A-01〜A-03（本タスク）
      MagicLinkForm/
      PasskeyAuthTrigger/
```

### ● import はすべて絶対パスに統一：

```
@/src/components/auth/MagicLinkForm/MagicLinkForm
@/src/components/auth/PasskeyAuthTrigger/PasskeyAuthTrigger
```

### ● 禁止事項

* config / env / package.json の変更
* UIトーンの変更（Appleカタログ風＋やさしく・自然・控えめ）
* Tailwind クラスの勝手な最適化・改変
* 旧ファイル削除（バックアップ後の上書きのみ）

---

# 4. References（参照ドキュメント）

Windsurf は以下の資料を **唯一の正** として扱うこと：

* MagicLinkForm-detail-design_v1.3.md fileciteturn5file10
* PasskeyAuthTrigger-detail-design_v1.3.md fileciteturn5file12
* PasskeyAuthTrigger Index ch00 v1.3 fileciteturn5file13
* LoginPage-detail-design_v1.2.md（左右2タイル UI） fileciteturn5file7
* A1 Login Screen Basic Design（カードタイルUI） fileciteturn5file8
* HarmoNet Passkey挙動仕様（Corbado/WebAuthn） fileciteturn5file5
* 技術スタック定義書 v4.3（MagicLink/Passkey二方式並列） fileciteturn5file11
* HarmoNet 共通ログユーティリティ 詳細設計 v1.1 fileciteturn5file9

---

# 5. Implementation Rules（実装ルール）

## 5.1 MagicLinkForm（A-01）

最新設計 v1.3 に準拠して全面生成する。
fileciteturn5file10

### 必須仕様

* 状態：`idle / sending / sent / error_*`
* エラー分類：input / network / auth / unexpected
* Supabase: `signInWithOtp({ email, redirectTo })`
* i18nキー：`auth.login.magiclink.*`
* ログ：`auth.login.start` / `.success.magiclink` / `.fail.*`
* UI：カードタイル（MailIcon + タイトル + 説明文 + input + ボタン）

### 禁止

* Passkey の要素・判定ロジックを含めない（完全独立）

---

## 5.2 PasskeyAuthTrigger（A-02）

最新仕様 v1.3 に基づき全面生成する。
fileciteturn5file12

### 必須仕様

* 状態：`idle / processing / success / error_*`
* Corbado.load → Corbado.passkey.login()
* Supabase: `signInWithIdToken({ provider: 'corbado', token })`
* エラー分類：denied / origin / network / auth / unexpected
* ログ：`auth.login.start` / `.success.passkey` / `.fail.passkey.*`
* i18nキー：`auth.login.passkey.*`
* UI：MagicLink と左右対称のカードタイル（KeyRound icon）

---

# 6. Acceptance Criteria（受入基準）

* TypeCheck: 0 エラー（旧 seed.ts エラーは除外）
* ESLint: 0 エラー
* Jest: A-01 / A-02 の test が 100% PASS
* Storybook: 正常描画・UI 崩れなし
* import パス統一（@/src/...）
* SelfScore 平均 9.0 以上

---

# 7. Backup Rules（バックアップ）

以下の形式で既存ファイルをバックアップ：

```
<元ファイル>_20251116_v0.1.bk
```

※ 同一ディレクトリへ保存。

---

# 8. CodeAgent_Report（必須）

Windsurf 完了後、以下のファイルへ **絶対パスで保存**：

```
D:\AIDriven\01_docs\06_品質チェック\CodeAgent_Report_AUTH_LoginModules_v1.0.md
```

### レポート形式

```
[CodeAgent_Report]
Agent: Windsurf
Task: AUTH_LoginModules
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - MagicLinkForm-detail-design_v1.3.md
 - PasskeyAuthTrigger-detail-design_v1.3.md
 - LoginPage-detail-design_v1.2.md
 - harmoNet-technical-stack-definition_v4.3.md
[Generated_Files]
 - <生成/更新したファイル一覧>
Summary:
 - 実施内容の概要
 - 注意点
```

---

# 9. Testing Method（検証手順）

```
# 型チェック（package.json を変更しない場合）
npx tsc --noEmit

npm run lint
npm test src/components/auth/MagicLinkForm
npm test src/components/auth/PasskeyAuthTrigger
npm run build
```

---

**以上の内容で MagicLinkForm + PasskeyAuthTrigger を全面再生成してください。**
