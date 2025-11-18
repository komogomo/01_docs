# WS-A01_MagicLinkBackendIntegration_v1.0（Logger追加反映版）

## 1. Task Summary

* 目的: MagicLink Backend Integration (A-01) 詳細設計仕様に基づき、MagicLink 認証バックエンド連携処理を Next.js App Router + Supabase Auth にて実装する。
* 対象コンポーネント: MagicLinkForm (A-01) / AuthCallbackHandler（app/auth/callback/page.tsx）。ロジック・API 仕様は詳細設計書（v1.0）に完全準拠。

---

## 2. Target Files

* `src/components/auth/MagicLinkForm/MagicLinkForm.tsx`
* `src/components/auth/MagicLinkForm/*`（types / stories / tests）
* `app/auth/callback/page.tsx`

---

## 3. Import & Directory Rules

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

* import パスは `@/src/...` 形式に統一。
* rename / 移動 / 削除禁止（指示時のみ許可）。

---

## 4. References

* MagicLinkForm-detail-design_v1.3.md
* A-00LoginPage-detail-design_v1.3.md
* Login-Backend-basic-design_v1.0.md
* harmonet-technical-stack-definition_v4.3.md

---

## 5. Implementation Rules

* Tailwind クラス変更禁止。
* Props 追加・削除禁止（例外のみ許可）。
* 不要な責務追加禁止。
* import パスは絶対パスに統一。
* `harmonet-coding-standard_v1.1` に従う。
* MagicLinkForm 内のバリデーション / メッセージ / ログ仕様は詳細設計書に完全一致させる。
* `/auth/callback` の Supabase セッション確立フローを正確に実装。

---

## 5.1 Logger 使用ルール（追加）

* 本タスクにおけるログ出力は **HarmoNet 共通ログユーティリティ v1.1** に準拠する。
* `logInfo` / `logError` / `logWarn` / `logDebug` は `@/src/lib/logging/log.util` から import して使用。
* **MagicLinkForm 内で定義されているログイベントは必ず保持**し、削除・省略不可：

  * `auth.login.start`
  * `auth.login.success.magiclink`
  * `auth.login.fail.*`
* `/auth/callback` 側のログ（必要最低限）：

  * `auth.callback.start`
  * `auth.callback.success`
  * `auth.callback.fail.session`
  * `auth.callback.redirect.home`
* PII（メールアドレス等）はユーティリティで自動マスキングされるため、追加実装不要。

---

## 6. Acceptance Criteria

* TypeCheck: 0 エラー。
* ESLint: 0 エラー。
* Prettier: 0 エラー。
* Jest / RTL: MagicLinkForm UT 100% PASS。
* Storybook: UI 崩れなし。
* SelfScore: 平均 9.0 以上。
* UI トーン準拠。

---

## 6.5 Backup Rules

修正が発生する既存ファイルは同一ディレクトリにバックアップを作成：

```
<元ファイル名>_<YYYYMMDD>_v0.1.bk
```

例：

```
MagicLinkForm.tsx_20251118_v0.1.bk
```

---

## 7. Forbidden Actions

* ディレクトリ構成の勝手な変更
* ファイル名変更（指示がある場合を除く）
* 新規 CSS ファイル追加
* UI トーン変更
* コンポーネント責務変更
* 不要な最適化
* 外部ライブラリ追加

---

## 8. CodeAgent_Report（必須）

```
[CodeAgent_Report]
Agent: Windsurf
Task: MagicLinkBackendIntegration
Attempts: <number>
AverageScore: <0–10>
TypeCheck: Passed / Failed
Lint: Passed / Failed
Tests: <pass率>
References:
 - MagicLinkForm-detail-design_v1.3.md
 - Login-Backend-basic-design_v1.0.md
[Generated_Files]
 - <生成/更新されたファイル一覧>
Summary:
 - 実施内容サマリ
 - 注意点
 - 改善必要点
```

保存先：

```
/01_docs/06_品質チェック/CodeAgent_Report_MagicLinkBackendIntegration_v1.0.md
```

---

## 9. Testing Method

### 9.1 UI

* MagicLinkForm 状態別 Storybook（Idle / Sending / Error / Sent）

### 9.2 UT

```
npm test MagicLinkForm
```

### 9.3 TypeCheck / Lint / Build

```
npm run type-check
npm run lint
npm run build
```

---

以上（Logger 反映済み）。
