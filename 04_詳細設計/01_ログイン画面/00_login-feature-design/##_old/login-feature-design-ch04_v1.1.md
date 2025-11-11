# 第4章: Magic Link送信完了 + Passkey登録誘導（A-01 MagicLinkForm）

**Document ID:** HARMONET-LOGIN-CH04-MAGICLINK-PASSKEY  
**Version:** 1.1  
**Status:** Phase9 承認仕様準拠（ContextKey: HarmoNet_LoginFeature_Phase9_v1.3_Approved）  
**Last Updated:** 2025-11-10 04:54

---

## ch04-1. 目的と範囲

本章は、ログイン機能における **Magic Link送信完了画面** と **Passkey登録誘導** を統合した詳細設計を定義する。Phase9における正式仕様は **パスワードレス**（Magic Link + Passkey）であり、**テナントID入力は不要**。  
初回は Magic Link でログインし、その後 MyPage でパスキーを登録すると、以降は **パスキー優先ログイン**を行う。

**対象コンポーネント:** A-01 MagicLinkForm（送信／完了／再送／誘導UI）  
**非対象:** 認証コールバック（A-03）、パスキー登録画面（MyPage内）、サーバー側メールテンプレート

---

## ch04-2. 前提・依存関係

### 2.1 共通前提（Phase9）
- 認証方式：**Supabase Auth**（Magic Link + Passkey）
- テナント分離：JWT `user_metadata.tenant_id` で識別（**画面でのテナント入力なし**）
- UIトーン：白基調・Appleカタログ風・BIZ UD ゴシック・角丸 2xl・最小限のシャドウ・線形アイコン

### 2.2 依存コンポーネント（Common Components）
- **C-01 AppHeader**（言語切替含む控えめヘッダー）
- **C-02 LanguageSwitch**
- **C-03 StaticI18nProvider**（`t(key)`）
- **C-04 AppFooter**
- **C-05 FooterShortcutBar**（※未認証画面では**非表示**）

### 2.3 主要ライブラリ/API
- Next.js App Router / React 19 / Tailwind CSS
- `@supabase/supabase-js` v2（`auth.signInWithOtp`, `auth.signInWithIdToken`, `auth.passkey.*`）
- `next/navigation`（`useRouter`, `useSearchParams`）

---

## ch04-3. 画面仕様（構成・UI）

### 3.1 レイアウト（3層構造／控えめデザイン）
```
┌──────────────────────────────┐
│  AppHeader（C-01）             │  ← ログイン画面では最小表示
├──────────────────────────────┤
│  コンテンツカード               │
│  ・成功アイコン（静）           │
│  ・完了メッセージ               │
│  ・補足説明（迷惑メール誘導）   │
│  ・[再送信] ボタン              │
│  ・[パスキーを登録する] リンク   │
│  ・小さなヘルプリンク群         │
├──────────────────────────────┤
│  AppFooter（C-04）             │  ← 利用規約/プライバシー等
└──────────────────────────────┘
```
- 背景は**白**、カードは `rounded-2xl shadow-sm border border-gray-100 p-6 max-w-[520px] mx-auto`
- 成功アイコンは**静的**（アニメ無し）。色彩は最小限（アクセントはSuccess）

### 3.2 コンポーネント構成（A-01）
- `MagicLinkForm.tsx`（送信フォーム＋完了状態表示を内部状態で切替）
- `EmailSentCard.tsx`（本章のカード。再送信／パスキー誘導を包含）
- `ResendButton.tsx`（クールダウン管理）

### 3.3 フォーム～完了 UI 遷移
1. メール送信成功 → 本章カードを表示
2. カード内で「再送信」可（クールダウン中は表示文言を自動切替）
3. 「パスキーを登録する」押下 → **MyPage > Security** に遷移（要認証）  
   - 初回ログイン後の**上部バナー**でも同誘導を行う（仕様補強；ch03と整合）

---

## ch04-4. 文言・i18n キー（ja/en/zh）

| key | ja | en | zh |
|---|---|---|---|
| `auth.emailSent.title` | メールを送信しました | Email sent | 邮件已发送 |
| `auth.emailSent.desc` | 入力されたメールアドレス宛にログインリンクを送信しました。メールボックスをご確認ください。 | We've sent a login link to your email. Please check your inbox. | 我们已向您的邮箱发送了登录链接。请查看您的收件箱。 |
| `auth.emailSent.help.spam` | 届かない場合は迷惑メールフォルダをご確認ください。 | If it hasn't arrived, please check your spam folder. | 如果未收到，请检查垃圾邮件文件夹。 |
| `auth.resend` | 再送信 | Resend | 重新发送 |
| `auth.resend.cooldown` | {seconds}秒後に再送信できます | You can resend in {seconds}s | {seconds}秒后可重新发送 |
| `auth.passkey.cta` | 次回からスムーズに。パスキーを登録する | Make sign‑in faster next time: register a passkey | 下次更便捷：注册通行密钥 |
| `auth.passkey.explainer` | パスキーを登録すると次回以降はワンタップでログインできます。 | With a passkey, future sign‑ins are one tap. | 注册后，下次登录一键完成。 |
| `auth.error.rateLimited` | 送信回数の上限に達しました。しばらくしてからお試しください。 | You've reached the limit. Please try again later. | 已达上限，请稍后再试。 |
| `auth.error.generic` | 送信に失敗しました。時間をおいて再度お試しください。 | Failed to send. Please try again later. | 发送失败，请稍后再试。 |

> 翻訳は `public/locales/*/common.json`（C-03 構成）で管理。

---

## ch04-5. ユースケースとフロー

### 5.1 メール送信成功後（本章の基本フロー）
```
[signInWithOtp(email)] 成功
        ↓
[EmailSentCard 表示]
  ・title/desc/ヘルプ
  ・[Resend]（クールダウン考慮）
  ・[パスキーを登録する]（MyPage>Securityへ）
```
- 画面遷移は行わず、同ページ内状態切替（Form→EmailSentCard）を推奨

### 5.2 再送信（レート制限）
- **同一ブラウザ**での操作を想定し、**localStorage** で最終送信時刻および直近1時間の回数を管理
- 既定値：**クールダウン 60 秒／1時間に 3 回**  
  - 超過時は `auth.error.rateLimited` を alert（`role="alert"`）で表示
  - クールダウン中は `auth.resend.cooldown` 表示、ボタンは `disabled`

### 5.3 Passkey登録誘導
- CTA押下で `"/mypage/security?from=login-email-sent"` に遷移（**ログイン後**ページ）
- 誘導の目的は**初回ログイン直後の登録率向上**。MyPage 側で `auth.passkey.register()` を実行
- 既に登録済みなら、MyPage側で「登録済み」表示／案内に自動切替

---

## ch04-6. 擬似コード / API 仕様（フロント）

### 6.1 再送信クールダウン管理（localStorage）
- key 名：`hmn_auth_last_sent_at`, `hmn_auth_hourly_counts`
- フォーマット：ISO8601（時刻）／UNIX time でも可
```ts
function canResend(now = Date.now()) {
  const last = Number(localStorage.getItem('hmn_auth_last_sent_at') || 0);
  const countJson = localStorage.getItem('hmn_auth_hourly_counts') || '[]';
  const counts = JSON.parse(countJson).filter((t: number) => now - t < 3600_000);
  const cooldownOk = now - last >= 60_000;
  const underLimit = counts.length < 3;
  return { cooldownOk, underLimit, remaining: Math.ceil((60_000 - (now - last)) / 1000) };
}
function markSent(now = Date.now()) {
  localStorage.setItem('hmn_auth_last_sent_at', String(now));
  const countJson = localStorage.getItem('hmn_auth_hourly_counts') || '[]';
  const counts = JSON.parse(countJson).filter((t: number) => now - t < 3600_000);
  counts.push(now);
  localStorage.setItem('hmn_auth_hourly_counts', JSON.stringify(counts));
}
```

### 6.2 Supabase Auth 呼び出し
- 再送信は **`auth.signInWithOtp({ email, options: { shouldCreateUser: false } })`** を再実行
- 成功時に `markSent()`、失敗時は `auth.error.generic` を `role="alert"` で表示

### 6.3 アクセシビリティ通知
- 成功文言は `role="status" aria-live="polite"`  
- エラーは `role="alert" aria-live="assertive"`

---

## ch04-7. アクセシビリティ & UX 指針

- フォーカス移動：送信成功時、**カードの見出し**に `focus()`
- キー操作：`Resend` は Enter/Space で実行可能
- 視認性：フォーカスリング `outline` を明示（Tailwind `focus-visible:outline`）
- 待機案内：メール到達までの一般的な遅延（10s〜1min）を説明行で表現
- スモールテキストで「メール誤記の可能性」「迷惑メール確認」を明示

---

## ch04-8. バリデーション・エラー設計

- **レート制限超過**：`auth.error.rateLimited`（ボタン無効＋カウントダウン）  
- **ネットワーク/その他**：`auth.error.generic`  
- **メール未入力での再送要求**：基本的にこの画面に来る時点でフォーム検証済み。想定外の場合はフォームに戻す。

---

## ch04-9. セキュリティ・データ取扱い

- **テナントIDの入力は不要**。認証後は JWT の `user_metadata.tenant_id` を参照し RLS で分離。
- localStorageに保持するのは**送信時刻（数値）と回数（数値配列）**のみ。個人情報は保存しない。
- ログはクライアントではなく**Supabase（Auth Log / Edge Function）側で集中管理**（将来拡張点）。

---

## ch04-10. 受け入れ基準（定量）

1. Magic Link 送信成功後、**1秒以内**に EmailSentCard が表示される  
2. Resend：**60秒**未満は常に無効化。**1時間に3回**を超える操作でエラー表示  
3. 文言は `ja/en/zh` 全言語に切替可能（C-03辞書/キー一致）  
4. Passkey登録CTAは **認証後に到達可能**なURLへ遷移し、未認証ならログイン要求へフォールバック  
5. Lighthouse Accessibility **95点以上**（AA水準相当）  
6. Jest/RTLのUIテスト：**主要分岐100%通過**（Resendクールダウン・エラー・i18n切替）

---

## ch04-11. 実装スケッチ（UI）

```tsx
// EmailSentCard.tsx（概略）
export function EmailSentCard({ onResend, cooldown, remaining, i18n }) {
  return (
    <section aria-labelledby="email-sent-title" className="rounded-2xl border border-gray-100 shadow-sm p-6">
      <div className="mx-auto mb-4 h-10 w-10 rounded-full grid place-items-center text-emerald-600 bg-emerald-50">
        {/* 静的チェックアイコン */}
        ✓
      </div>
      <h2 id="email-sent-title" className="text-lg font-bold">{i18n.t('auth.emailSent.title')}</h2>
      <p className="text-sm text-gray-600 mt-1">{i18n.t('auth.emailSent.desc')}</p>
      <p className="text-xs text-gray-500 mt-2">{i18n.t('auth.emailSent.help.spam')}</p>

      <div className="mt-4 flex gap-2">
        <button
          type="button"
          disabled={!cooldown}
          aria-disabled={!cooldown}
          onClick={onResend}
          className="flex-1 h-10 rounded-xl border px-3 text-sm font-semibold hover:bg-gray-50 disabled:opacity-50"
          aria-live="polite"
        >
          {cooldown ? i18n.t('auth.resend') : i18n.t('auth.resend.cooldown', { seconds: remaining })}
        </button>
        <a
          href="/mypage/security?from=login-email-sent"
          className="flex-1 h-10 rounded-xl border px-3 text-sm font-semibold hover:bg-gray-50 grid place-items-center"
        >
          {i18n.t('auth.passkey.cta')}
        </a>
      </div>
    </section>
  );
}
```

---

## ch04-12. 試験観点（抜粋）

- **機能テスト**：送信成功→カード表⽰、Resend クールダウン、上限到達、エラー表示、CTA遷移
- **i18n**：全キー存在／置換（`{seconds}`）の正しさ
- **アクセシビリティ**：`role`/`aria-live`/フォーカスリングの有無、キーボード操作
- **回帰**：AppHeader/C-04との併用表示の破綻がないこと（未認証でC-05非表示）

---

## ch04-13. 変更履歴

- **v1.1**（Phase9）：Magic Link + Passkey 併用仕様、テナントID入力廃止、UIトーン刷新、共通部品統合、レート制限をlocalStorage簡素管理に変更  
- **v1.0**（2025-10-27）：メール送信完了画面（旧：背景グラデーション／独自カード／再送信仕様）

---

### 付記：整合性メモ
- ch00〜ch03（v1.3.1）と章内参照・用語を統一（「パスワードレス」「控えめトーン」「共通部品ID」）。
- MyPage 側のパスキー登録章（別巻）にて `auth.passkey.register()` 詳細を定義予定。

---

**[← 第3章に戻る](login-feature-design-ch03_latest.md)  |  [第5章へ →](login-feature-design-ch05_latest.md)**

**Created:** 2025-11-10 / **Last Updated:** 2025-11-10 04:54 / **Version:** 1.1 / **Document ID:** HARMONET-LOGIN-CH04-MAGICLINK-PASSKEY
