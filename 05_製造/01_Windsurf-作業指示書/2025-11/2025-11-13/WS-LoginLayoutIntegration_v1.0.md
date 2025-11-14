# WS-LoginLayoutIntegration v1.0（正式仕様・確定版）

**目的**
HarmoNet のログイン画面を正式レイアウトで統合する。
C-01 AppHeader（ロゴ＋言語切替3ボタン）、A-01 MagicLinkForm、C-04 AppFooter を **正規レイアウト** で配置する。
UIトーンは「やさしい・自然・控えめ（Appleカタログ風）」に準拠。

---

## 1. 対象ファイル

* `app/login/page.tsx`（この1つのみ編集）
* 既存コンポーネントは **内容改変禁止**（配置のみ許可）

### 使用コンポーネント

```ts
import { AppHeader } from "@/src/components/common/AppHeader/AppHeader";
import { AppFooter } from "@/src/components/common/AppFooter/AppFooter";
import { MagicLinkForm } from "@/src/components/auth/MagicLinkForm/MagicLinkForm";
```

### ロゴ

* パス: `/public/images/logo-harmonet.png`（固定）
* 中身は TKD が後から差し替える
* コード側は固定パスのみ使用

---

## 2. レイアウト仕様（正式 UI）

スクリーン幅に依存せず **中央に固定幅カード** を配置する。
PC 全画面でもこの幅のまま変化しない。

### 2.1 ページ全体

```
背景: #F9FAFB
レイアウト: 縦並び（Header → Main → Footer）
```

### 2.2 AppHeader（C-01）

* variant="login"
* 左: ロゴ（高さ max 32px / w-auto）
* 右: 言語切替（JA / EN / ZH 水平3ボタン）
* 背景: 白
* 下線: #E5E7EB

### 2.3 メインエリア

```
中央揃え
上部余白: 80〜100px
下部余白: 100px
```

### 2.4 ログインカード（MagicLinkForm 外側のコンテナ）

```
max-width: 420px
background: #ffffff
border-radius: 16px
border: 1px solid #E5E7EB
box-shadow: 0 4px 10px rgba(0,0,0,0.04)
padding: 32px 24px
margin-bottom: 24px
```

カード内構造:

1. タイトル「ログイン」
2. MagicLinkForm（メールアドレス入力 + 送信ボタン）
3. 情報ボックス（任意情報）

### 2.5 メールアドレス入力欄（MagicLinkForm 内）

```
width: 100%
max-width: 380px（※TKD要望反映）
高さ: 48px
角丸: rounded-2xl
中央寄せ: mx-auto
```

### 2.6 送信ボタン

```
width: 100%
height: 48px
角丸: 12px
背景色: #2563EB（hover #3B82F6）
```

### 2.7 情報ボックス（カード内）

```
背景: #F1F5FF
border: 1px solid #DFE8FF
border-radius: 12px
padding: 12px
font-size: 13px
color: #1E3A8A
margin-top: 16px
```

※ Windsurf 側で内容は MagicLinkForm からそのまま表示される。
※ 内容改変しない。

### 2.8 説明文（カード下）

```
font-size: 12px
color: #6B7280
text-align: center
margin-top: 24px
```

### 2.9 AppFooter（C-04）

```
固定下部高さ: 48px
背景: #FFFFFF
border-top: 1px solid #E5E7EB
文字: © 2025 HarmoNet.
font-size: 12px
color: #9CA3AF
```

---

## 3. JSX（Windsurf が生成すべき完成形）

```tsx
'use client';

import { AppHeader } from "@/src/components/common/AppHeader/AppHeader";
import { AppFooter } from "@/src/components/common/AppFooter/AppFooter";
import { MagicLinkForm } from "@/src/components/auth/MagicLinkForm/MagicLinkForm";

export default function LoginPage() {
  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <AppHeader variant="login" />

      <main className="flex-1 flex flex-col items-center px-4 pt-28 pb-28">
        {/* タイトルブロック */}
        <section className="w-full max-w-[420px] text-center mb-10">
          <h1 className="text-2xl font-semibold text-gray-900 mb-1">HarmoNet</h1>
          <p className="text-sm text-gray-500">入居者専用コミュニティアプリ</p>
        </section>

        {/* ログインカード */}
        <section className="w-full max-w-[420px] bg-white border border-gray-200 rounded-2xl shadow-sm px-8 py-10 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">ログイン</h2>

          {/* MagicLinkForm */}
          <div className="flex flex-col items-center">
            <MagicLinkForm />
          </div>

          {/* 情報ボックス（MagicLinkFormの付随情報がここに入る） */}
          <div className="mt-6 bg-indigo-50 border border-indigo-100 rounded-xl p-4 text-sm text-indigo-900">
            {/* WindsurfはここにMagicLinkForm内の補助情報をそのまま描画する */}
          </div>
        </section>

        {/* 説明文 */}
        <section className="w-full max-w-[420px] text-center text-xs text-gray-400 mt-4">
          <p>このアプリは複数画面で構成されています。</p>
          <p>右上のボタンで言語を切り替えられます。</p>
        </section>
      </main>

      <AppFooter />
    </div>
  );
}
```

---

## 4. Windsurf 禁止事項

* MagicLinkForm 内部ロジックの変更
* AppHeader / AppFooter の改変
* Tailwind クラスの書き換え
* UIトーンの変更
* カード幅や padding の改変

---

## 5. Acceptance Criteria

* TypeCheck 0
* Lint 0
* Storybook で表示崩れなし
* ログイン画面が Claude モックと同等の重心・幅で表示される
* SelfScore 9.0 以上
* ロゴは `/public/images/logo-harmonet.png` を使用

---

これが HarmoNet ログイン画面統合の **正式版 WS 指示書**。

## 6. CodeAgent_Report 出力先（必須）

本タスクの CodeAgent_Report は以下に保存すること：

```
/01_docs/05_品質チェック/CodeAgent_Report_LoginLayoutIntegration_v1.0.md
```

Windsurf は実行完了後、このパスにレポートを出力する。

---

## 7. 参照ディレクトリ構成（必須）

本タスクは HarmoNet 公式フロントエンド構成 v1.0 に完全準拠する。
以下の構造を Windsurf の import / 配置 / 参照ルールの唯一の正とする：

```
src/
  components/
    common/
      AppHeader/
      AppFooter/
      LanguageSwitch/
      StaticI18nProvider/
      FooterShortcutBar/

    auth/
      MagicLinkForm/
      PasskeyButton/
      AuthCallbackHandler/

  app/
    layout.tsx
    login/
      page.tsx
    auth/
      callback/
        page.tsx
```

* 未定義ディレクトリを作らないこと
* 既存構造の変更・移動・rename は禁止
* import パスは `@/src/components/...` に統一

---

## 8. この指示書が Windsurf に要求するもの（要点）

1. **本番コードとしてのログイン画面レイアウト統合**
2. **MagicLinkForm / AppHeader / AppFooter を正規配置**
3. **ロゴは `/public/images/logo-harmonet.png` を使用**
4. **TypeCheck/Lint/Storybook すべて0エラー**
5. **CodeAgent_Report を上記パスへ保存**
6. **公式フロントエンド構成 v1.0 に完全準拠**
