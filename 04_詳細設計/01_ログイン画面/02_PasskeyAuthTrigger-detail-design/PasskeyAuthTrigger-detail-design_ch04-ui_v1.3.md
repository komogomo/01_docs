# PasskeyAuthTrigger 詳細設計書 - 第4章：UI設計（v1.3）

**Document ID:** HARMONET-COMPONENT-A02-PASSKEYAUTHTRIGGER-CH04**
**Version:** 1.3
**Supersedes:** v1.2（非UI実装残存・旧統合方式）
**Status:** A-01 MagicLinkForm（v1.3）と完全対称の UI 章

---

## 4.1 コンポーネント概要（UI）

PasskeyAuthTrigger は、LoginPage（A-00）中央に並ぶ **右側のカードタイル UI** として表示され、
ユーザーが押下すると Passkey 認証処理を開始する。

**A-01 MagicLinkForm の左タイル UI と完全対称の構成**を持ち、
以下の UI 要素を含む：

* アイコン（KeyRound）
* タイトル
* 説明文
* エラーバナー（error_* 状態時）
* 選択可能なタイル（button ロール）

MagicLinkForm と同じトーン（やさしい・自然・控えめ、Apple カタログ風）で統一する。

---

## 4.2 レイアウト構造（カードタイル）

```
┌──────────────────────────────┐
│  [🔑 アイコン]  Passkeyでログイン           │  ← タイトル
│                端末のFaceID/指紋などで認証         │  ← 説明文
│                                                │
│  （error_* の場合）                             │
│     ┌────────────────────────────┐    │
│     │   エラーメッセージ（バナー）             │    │
│     └────────────────────────────┘    │
└──────────────────────────────┘
```

### UI仕様（A-01 と完全一致）

* **角丸**：`rounded-2xl`
* **影**：`shadow-[0_1px_2px_rgba(0,0,0,0.06)]`
* **背景色**：`bg-white`
* **高さ**：80〜92px（内容に応じて自動）
* **余白**：`p-4`
* **テキスト色**：`text-gray-900 / text-gray-600`
* **アイコン色**：`text-gray-500`

---

## 4.3 JSX 構造

```tsx
<div
  className={cardClassName}
  role="button"
  onClick={handlePasskey}
  aria-busy={state === 'processing'}
  data-testid={testId}
>
  {/* 上段：アイコン + タイトル + 説明 */}
  <div className="flex items-start gap-3">
    <KeyRound className="w-7 h-7 text-gray-500" aria-hidden="true" />

    <div>
      <h2 className="text-base font-medium text-gray-900">
        {t('auth.login.passkey.title')}
      </h2>

      <p className="mt-1 text-sm text-gray-600">
        {t('auth.login.passkey.description')}
      </p>
    </div>
  </div>

  {/* 下段：エラーバナー */}
  {banner && (
    <AuthErrorBanner kind={banner.kind} message={banner.message} />
  )}
</div>
```

### cardClassName

```ts
const cardClassName = `
  rounded-2xl
  shadow-[0_1px_2px_rgba(0,0,0,0.06)]
  bg-white
  p-4
  cursor-pointer
  transition-opacity
  ${state === 'processing' ? 'opacity-50 pointer-events-none' : 'opacity-100'}
`;
```

---

## 4.4 状態別 UI（MagicLinkForm と対称）

| 状態                 | UI変化           | 説明                  |
| ------------------ | -------------- | ------------------- |
| `idle`             | 通常カード          | タップ可能               |
| `processing`       | 不透明度50% / busy | OS ネイティブ認証待ち        |
| `success`          | 即 `/mypage` 遷移 | 成功メッセージ表示なし（A-01同様） |
| `error_denied`     | バナー表示          | キャンセル               |
| `error_origin`     | バナー表示          | Origin mismatch     |
| `error_network`    | バナー表示          | 通信エラー               |
| `error_auth`       | バナー表示          | 認証エラー               |
| `error_unexpected` | バナー表示          | 想定外                 |

---

## 4.5 i18n キー（詳細は ch06）

PasskeyAuthTrigger の UI メッセージは以下のキーを使用する。

```
auth.login.passkey.title
auth.login.passkey.description
auth.login.passkey.error_denied
auth.login.passkey.error_origin
auth.login.passkey.error_network
auth.login.passkey.error_auth
auth.login.passkey.error_unexpected
```

MagicLink のキー体系と語彙・構造を統一している。

---

## 4.6 アクセシビリティ

| 要素     | ARIA属性          | 意図          |
| ------ | --------------- | ----------- |
| カードタイル | `role="button"` | ボタンとして認識させる |
| カードタイル | `aria-busy`     | 認証中の状態を通知   |
| エラーバナー | `role="alert"`  | 画面読み上げで即時通知 |

フォーカスリングはデフォルトの focus-visible を利用する。

---

## 4.7 Storybook 構成

| ストーリー名            | 状態               | 内容              |
| ----------------- | ---------------- | --------------- |
| `Idle`            | idle             | 通常表示            |
| `Processing`      | processing       | 認証開始状態          |
| `Denied`          | error_denied     | キャンセルバナー        |
| `OriginError`     | error_origin     | Origin mismatch |
| `NetworkError`    | error_network    | 通信障害            |
| `AuthError`       | error_auth       | 認証エラー           |
| `UnexpectedError` | error_unexpected | 想定外エラー          |

---

## 4.8 UT 観点（UI）

| UT ID        | シナリオ              | 期待結果                    |
| ------------ | ----------------- | ----------------------- |
| UT-A02-UI-01 | idle → processing | カードの opacity 変化・busy状態  |
| UT-A02-UI-02 | error_* 各種        | バナー表示・i18nメッセージ一致       |
| UT-A02-UI-03 | Locale切替          | 文言が正しく切替                |
| UT-A02-UI-04 | カード押下             | `handlePasskey` が1回呼ばれる |

---

## 4.9 注意事項（A-01と完全同期）

* ログイン成功時に **成功バナーは出さない**（即遷移）。
* MagicLink と並べた時に **高さ・余白・影・角丸が完全一致**していること。
* Tailwind クラスの変更は Windsurf では禁止（設計書が唯一の正）。

---

## 4.10 ChangeLog

| Version | Summary                                                     |
| ------- | ----------------------------------------------------------- |
| 1.2     | 旧仕様の Hook 前提構造。                                             |
| **1.3** | **完全 UI 章として再構築。MagicLinkForm と対称のカードタイル UI を定義。非UI設計を全廃。** |
