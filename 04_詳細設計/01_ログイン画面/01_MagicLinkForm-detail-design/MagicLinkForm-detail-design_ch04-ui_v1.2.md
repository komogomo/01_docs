# MagicLinkForm 詳細設計書 - 第4章：UI設計（v1.2）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH04
**Version:** 1.2
**Supersedes:** v1.1
**Updated:** 2025-11-16
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** MagicLink 専用カードタイル方式 / 技術スタック v4.3 整合版

---

## 4.1 コンポーネント構成概要

MagicLinkForm（A-01）は、ログイン画面（A-00）中央のカードコンテナ内に配置される **左側カードタイル** として、
以下の要素で構成される：

* タイトル・説明（テキスト）
* メールアドレス入力欄
* 「ログイン」ボタン（MagicLink 送信用）
* 成功・エラー時のメッセージ表示領域

Passkey 用 UI は本コンポーネントには含まず、右側カードタイル（A-02 PasskeyAuthTrigger）が担当する。

---

## 4.2 JSX 構造（概要）

```tsx
export const MagicLinkForm: React.FC<MagicLinkFormProps> = ({
  className,
  onSent,
  onError,
  testId = 'magiclink-form',
}) => {
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [state, setState] = useState<MagicLinkFormState>('idle');
  const [error, setError] = useState<MagicLinkError | null>(null);

  return (
    <section
      className={cn(
        'rounded-2xl border border-gray-200 bg-white shadow-sm p-4 md:p-6 flex flex-col gap-4',
        className,
      )}
      data-testid={testId}
    >
      {/* ヘッダー（アイコン＋タイトル＋説明） */}
      <header className="flex items-start gap-3">
        <Mail className="w-6 h-6 text-gray-500" aria-hidden="true" />
        <div className="flex-1">
          <h2 className="text-base font-semibold text-gray-900">
            {t('auth.login.magiclink.title')}
          </h2>
          <p className="mt-1 text-sm text-gray-600">
            {t('auth.login.magiclink.description')}
          </p>
        </div>
      </header>

      {/* フォーム本体 */}
      <form
        className="mt-2 flex flex-col gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          handleSubmit();
        }}
        noValidate
      >
        <label className="text-sm font-medium text-gray-700" htmlFor="magiclink-email">
          {t('auth.login.email.label')}
        </label>
        <input
          id="magiclink-email"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => onChangeEmail(e.target.value)}
          className="h-11 rounded-2xl border border-gray-300 px-3 text-sm md:text-base text-gray-900 placeholder:text-gray-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:border-transparent"
          placeholder={t('auth.login.email.placeholder')}
          disabled={state === 'sending'}
        />

        {state === 'error_input' && error && (
          <p className="text-xs text-red-600" role="alert">
            {error.message}
          </p>
        )}

        <button
          type="submit"
          disabled={state === 'sending'}
          className={cn(
            'h-11 rounded-2xl flex items-center justify-center gap-2 text-sm md:text-base font-semibold transition-colors shadow-sm',
            state === 'sending'
              ? 'bg-blue-400 text-white cursor-wait'
              : 'bg-blue-600 text-white hover:bg-blue-500 disabled:opacity-60',
          )}
        >
          {state === 'sending' ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" aria-hidden="true" />
              <span>{t('auth.login.magiclink.button_sending')}</span>
            </>
          ) : (
            <>
              <Mail className="w-4 h-4" aria-hidden="true" />
              <span>{t('auth.login.magiclink.button_login')}</span>
            </>
          )}
        </button>

        {/* 成功・エラーメッセージ（バナー） */}
        {state === 'sent' && (
          <p className="text-xs md:text-sm text-gray-600" aria-live="polite">
            {t('auth.login.magiclink_sent')}
          </p>
        )}

        {['error_network', 'error_auth', 'error_unexpected'].includes(state) && error && (
          <p className="text-xs md:text-sm text-red-600" role="alert" aria-live="assertive">
            {error.message}
          </p>
        )}
      </form>
    </section>
  );
};
```

---

## 4.3 レイアウト仕様

| 項目  | 内容                                           |
| --- | -------------------------------------------- |
| 配置  | 左側カードタイルとして LoginPage 中央に並置（右側は Passkey カード） |
| 横幅  | 親コンテナ内で `w-full max-w-md`                    |
| 余白  | カード内 `p-4 md:p-6`、要素間 `gap-3`                |
| 入力欄 | 高さ `h-11`、角丸 `rounded-2xl`、左右 `px-3`         |
| ボタン | 高さ `h-11`、角丸 `rounded-2xl`、アイコン＋テキスト横並び      |

カード全体は **白背景 + 薄いシャドウ + 角丸2xl** を基本とし、A1 ログイン画面のカードタイル仕様と一致させる。

---

## 4.4 カラースキーム

| 要素    | 状態      | 背景 / 枠線                        | テキスト            | 備考                         |
| ----- | ------- | ------------------------------ | --------------- | -------------------------- |
| カード   | 常時      | `bg-white` / `border-gray-200` | `text-gray-900` | ベースカード                     |
| 入力欄   | idle    | `border-gray-300`              | `text-gray-900` | プレースホルダ `text-gray-400`    |
| 入力欄   | フォーカス   | `ring-2 ring-blue-500`         | 変化なし            | 枠線は透明化                     |
| ボタン   | idle    | `bg-blue-600`                  | `text-white`    | hover で `bg-blue-500`      |
| ボタン   | sending | `bg-blue-400`                  | `text-white`    | `cursor-wait`、opacity 変更なし |
| メッセージ | sent    | -                              | `text-gray-600` | 補足テキスト                     |
| メッセージ | error_* | -                              | `text-red-600`  | `role="alert"`             |

---

## 4.5 タイポグラフィ

| 要素     | フォント / サイズ                                      | 備考          |
| ------ | ----------------------------------------------- | ----------- |
| タイトル   | BIZ UD ゴシック想定 / `text-base font-semibold`       | アイコン右に配置    |
| 説明     | `text-sm text-gray-600`                         | 2行以内想定      |
| 入力ラベル  | `text-sm font-medium text-gray-700`             | 上部に配置       |
| 入力値    | `text-sm md:text-base text-gray-900`            | モバイルで視認性を確保 |
| ボタンラベル | `text-sm md:text-base font-semibold text-white` | 常に 2〜3語以内   |
| メッセージ  | `text-xs md:text-sm`                            | 情報量を抑えた一文   |

---

## 4.6 状態別 UI 振る舞い

MagicLinkForm の UI は `MagicLinkFormState` に応じて変化する。

| 状態               | ボタン表示              | ボタン活性 | メッセージ               | 備考             |
| ---------------- | ------------------ | ----- | ------------------- | -------------- |
| idle             | 「ログイン」 + Mail アイコン | 有効    | なし                  | 初期状態           |
| sending          | 「送信中…」 + Loader2   | 無効    | なし                  | 多重送信防止         |
| sent             | 「ログイン」             | 有効    | 「MagicLink を送信しました」 | 成功情報をカード内下部に表示 |
| error_input      | 「ログイン」             | 有効    | 入力欄直下に Inline エラー   | メール形式のみ        |
| error_network    | 「ログイン」             | 有効    | 赤テキストのバナー行          | 再送信誘導          |
| error_auth       | 「ログイン」             | 有効    | 赤テキストのバナー行          | ユーザー向けに一般化した文言 |
| error_unexpected | 「ログイン」             | 有効    | 赤テキストのバナー行          | サポート案内に差し替え可能  |

---

## 4.7 i18n キー使用一覧

本コンポーネントで使用する主な i18n キーは以下の通り。
キーの定義は ch06 および共通 i18n 設計書にて詳細化する。

| 用途           | キー例                                   |
| ------------ | ------------------------------------- |
| タイトル         | `auth.login.magiclink.title`          |
| 説明           | `auth.login.magiclink.description`    |
| ラベル          | `auth.login.email.label`              |
| プレースホルダ      | `auth.login.email.placeholder`        |
| ボタン（idle）    | `auth.login.magiclink.button_login`   |
| ボタン（sending） | `auth.login.magiclink.button_sending` |
| 成功メッセージ      | `auth.login.magiclink_sent`           |
| エラー（入力）      | `auth.login.error.email_invalid`      |
| エラー（通信）      | `auth.login.error.network`            |
| エラー（認証）      | `auth.login.error.auth`               |
| エラー（想定外）     | `auth.login.error.unexpected`         |

---

## 4.8 アクセシビリティ

| 項目      | 内容                                                                          |
| ------- | --------------------------------------------------------------------------- |
| ラベル     | `label` と `htmlFor` によりメール入力と関連付け                                           |
| live 領域 | 成功メッセージは `aria-live="polite"`、エラーは `role="alert"` + `aria-live="assertive"` |
| フォーカス   | `focus-visible:ring-2 ring-blue-500` によりキーボードフォーカスを明示                       |
| キーボード操作 | Tab / Shift+Tab / Enter で全操作可能                                              |

---

## 4.9 ChangeLog

| Version | Date       | Summary                                                                                                                                                                                                  |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.2     | 2025-11-16 | MagicLinkForm を **MagicLink 専用カードタイル UI** として再定義。旧 v1.1 の Passkey 統合ボタン仕様を完全削除し、メール入力＋MagicLinkボタン＋メッセージ領域のみを残す構成に整理。i18n キーを `auth.login.*` 系に統一し、状態別 UI（idle / sending / sent / error_*）の定義を最新ロジックと整合。 |

---

**End of Document**
