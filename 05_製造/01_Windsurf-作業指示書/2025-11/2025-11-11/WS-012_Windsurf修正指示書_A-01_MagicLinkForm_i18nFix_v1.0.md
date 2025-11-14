# Windsurf実行指示書 - MagicLinkForm i18n修正（v1.0）

**Document ID:** HARMONET-WINDSURF-INSTRUCTION-A01-MAGICLINKFORM-I18N-FIX
**Version:** 1.0
**Created:** 2025-11-11
**Author:** Tachikoma
**Reviewer:** TKD
**Target Component:** A-01 MagicLinkForm
**Status:** ✅ 実行準備完了（i18n修正タスク）

---

## 🎯 目的

現行の MagicLinkForm にて、ボタン・ラベル・メッセージが `common.save` や英語ハードコードになっており、
設計書（`MagicLinkForm-detail-design_v1.0.md`）で定義された `auth.*` 翻訳キー体系と一致していない。
本指示書では、UI文言をすべて正規の `auth.*` キーへ復元し、i18n整合を確保する。

---

## 📁 対象ディレクトリ

```
src/components/login/MagicLinkForm/
public/locales/{ja,en,zh}/common.json
```

| ファイル名                           | 操作 | 内容                                   |
| ------------------------------- | -- | ------------------------------------ |
| `MagicLinkForm.tsx`             | 修正 | 翻訳キーを `common.save` → `auth.*` 体系へ置換 |
| `MagicLinkForm.test.tsx`        | 修正 | テキストマッチ条件を新キーに合わせ更新                  |
| `MagicLinkForm.stories.tsx`     | 修正 | Storybook文言をauthキーへ統一                |
| `public/locales/en/common.json` | 追加 | `auth.*` キー群を ja 版と同内容で追加            |
| `public/locales/zh/common.json` | 追加 | `auth.*` キー群を ja 版と同内容で追加            |

---

## ⚙️ 修正仕様

### 1. JSX翻訳キー置換

| 要素           | 現在                   | 修正後                           |
| ------------ | -------------------- | ----------------------------- |
| 入力ラベル        | `t('common.save')`   | `t('auth.enter_email')`       |
| ボタン（idle）    | `t('common.save')`   | `t('auth.send_magic_link')`   |
| ボタン（sending） | 固定文字 `Loading`       | `{t('auth.send_magic_link')}` |
| 成功文言         | 固定文字 `Sent`          | `t('auth.email_sent')`        |
| 入力不正         | 固定文字 `Invalid email` | `t('auth.invalid_email')`     |
| 通信失敗         | 固定文字 `Network error` | `t('auth.network_error')`     |

---

### 2. 翻訳ファイル更新

#### `public/locales/en/common.json`

```json
"auth": {
  "enter_email": "Enter your email address",
  "send_magic_link": "Send login link",
  "email_sent": "Email sent successfully",
  "retry": "Retry",
  "invalid_email": "Invalid email address",
  "network_error": "Network error occurred",
  "check_your_email": "Please check your email"
}
```

#### `public/locales/zh/common.json`

```json
"auth": {
  "enter_email": "请输入电子邮件地址",
  "send_magic_link": "发送登录链接",
  "email_sent": "邮件已发送",
  "retry": "重试",
  "invalid_email": "电子邮件地址无效",
  "network_error": "发生网络错误",
  "check_your_email": "请检查您的电子邮件"
}
```

---

### 3. テスト更新

| テストID    | 内容   | 期待結果                                     |
| -------- | ---- | ---------------------------------------- |
| T-A01-01 | 初期表示 | ボタンテキストが `t('auth.send_magic_link')` に一致 |
| T-A01-02 | 成功時  | 成功文言 `t('auth.email_sent')` を表示          |
| T-A01-03 | 入力不正 | エラー文言 `t('auth.invalid_email')` を表示      |
| T-A01-04 | 通信断  | エラー文言 `t('auth.network_error')` を表示      |
| T-A01-05 | 言語切替 | ja/en/zh 切替で文言が動的更新される                   |

---

## ✅ 成果物検証基準

| 検証項目      | 判定条件                        |
| --------- | --------------------------- |
| Lint      | エラーなし                       |
| UnitTest  | 100% Pass                   |
| Storybook | 各言語で `ログインリンクを送信` 表示を確認     |
| 実機表示      | `/login` ページで設計書v1.0準拠文言を確認 |

---

## 🚫 禁止事項

* `common.save` の再利用禁止
* 固定英語文字列の残置禁止
* コンポーネント構造の改変禁止
* Tailwind トークン変更は本タスク範囲外（Phase10にて対応）

---

## 📜 ChangeLog

| Version | Date       | Author          | Summary                                               |
| ------- | ---------- | --------------- | ----------------------------------------------------- |
| 1.0     | 2025-11-11 | Tachikoma / TKD | MagicLinkForm の文言・翻訳キーを設計書v1.0のauth体系に修正。EN/ZH翻訳キー追加。 |

---

**Approved by:** TKD
**Ready for Execution:** ✅ Windsurf 実行可能（Phase9 / A-01 i18n整合）
