# WS-A01 MagicLinkForm v1.0

**Category:** Windsurf実行指示書
**Component ID:** A-01
**Component Name:** MagicLinkForm
**Directory:** /01_docs/05_製造/01_Windsurf-作業指示書/
**Version:** 1.0
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ HarmoNet Phase9 正式仕様準拠（Next.js 16 / Supabase v2.43 / React 19 / Corbado統合）

---

## 1. Goal

MagicLinkForm (A-01) を実装し、**Magic Link + Passkey 自動判定による完全パスワードレス認証**を構築する。Supabase Auth (`signInWithOtp`) と Corbado SDK (`passkey.login()`) を統合し、ユーザーの認証状態に応じて処理を自動分岐させることを目的とする。

---

## 2. Scope

対象: `src/components/auth/MagicLinkForm/` 以下に配置する React Client Component。

範囲:

* UI: メール入力フォーム＋送信ボタン＋ステータス表示
* Logic: Supabase OTP送信 / Corbado Passkey自動判定
* i18n: StaticI18nProvider (C-03) 経由で文言取得
* Style: TailwindCSS + HarmoNet共通トーン
* Test: Jest + RTL による単体検証

除外範囲:

* サーバーサイド Corbado Node SDK 呼出し
* Supabase Edge Functions (検証は別タスク)

---

## 3. Contracts

**Props定義:**

```ts
export interface MagicLinkFormProps {
  className?: string;
  onSent?: () => void;
  onError?: (error: MagicLinkError) => void;
}

export interface MagicLinkError {
  code: string;
  message: string;
  type: 'error_invalid' | 'error_network';
}
```

**State定義:**

| 状態            | 内容              |
| ------------- | --------------- |
| idle          | 初期状態            |
| sending       | Supabaseへリクエスト中 |
| sent          | メール送信成功         |
| error_invalid | 入力形式エラー         |
| error_network | 通信・API失敗        |

---

## 4. References

* `MagicLinkForm-detail-design_v1.0.md`【50†source】
* `harmonet-technical-stack-definition_v4.2.md`【52†source】
* `PasskeyAuthTrigger-detail-design_ch06-integration_v1.1.md`
* StaticI18nProvider (C-03)【41†source】
* Supabase JS SDK v2.43 Docs
* Corbado Web SDK v2.x Docs

---

## 5. Tests

| テストID    | シナリオ          | 期待結果                                         |
| -------- | ------------- | -------------------------------------------- |
| T-A01-01 | 正常送信          | `/auth/callback` に遷移し、SupabaseがOTP送信成功       |
| T-A01-02 | 入力不正          | `error_invalid` 状態を表示                        |
| T-A01-03 | 通信断           | `error_network` 状態を表示                        |
| T-A01-04 | Passkey有効ユーザー | Corbado.passkey.login() が自動呼出され、Supabase連携成功 |
| T-A01-05 | i18n切替        | 表示文言が言語切替に応じて即時更新                            |

---

## 6. Criteria

* Self-score ≥ 9.0 / 10.0（Windsurf自己採点）
* TypeScript型エラー: 0
* ESLint/Prettier警告: 0
* Jest: 100% パス
* Storybook: 3状態（idle/sending/sent）再現確認

---

## 7. Bans

* Supabase / Corbado SDK の import 名変更禁止
* `src/components/auth/` 以外へのファイル生成禁止
* 新規環境変数・設定ファイル追加禁止
* デザイン改変禁止（HarmoNet共通スタイル厳守）
* コメント削除・命名変更禁止（保守整合性維持）

---

## 8. Meta / [CodeAgent_Report]

```
[CodeAgent_Report]
Agent: Windsurf
Component: MagicLinkForm (A-01)
Attempt: 1
TargetScore: 9.0+
Tests: T-A01-01〜T-A01-05
Expected Output:
- src/components/auth/MagicLinkForm/MagicLinkForm.tsx
- src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx
- src/components/auth/MagicLinkForm/MagicLinkForm.stories.tsx
- public/locales/{ja,en,zh}/common.json 更新
```
