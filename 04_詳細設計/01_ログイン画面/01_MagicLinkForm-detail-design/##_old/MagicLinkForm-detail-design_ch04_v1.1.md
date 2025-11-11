# MagicLinkForm 詳細設計書 - 第4章：UI設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH04  
**Version:** 1.1  
**Updated:** 2025-11-10  
**Based on:** harmonet-technical-stack-definition_v4.0 / MagicLinkForm-detail-design_v1.1.md  
**Reviewer:** TKD  
**Status:** Phase9 正式整合版  

---

## 第4章 UI設計

### 4.1 UIコンポーネント構成

```tsx
<form
  onSubmit={(e) => { e.preventDefault(); handleSendMagicLink(); }}
  className={`w-full flex flex-col gap-3 ${className || ''}`}
>
  <Input
    type="email"
    value={email}
    onChange={(e) => setEmail(e.target.value)}
    placeholder={t('auth.magiclink.enter_email')}
    className="h-12 rounded-xl px-3 border text-base"
    required
  />
  <Button
    type="submit"
    disabled={state === 'sending'}
    variant="outline"
    className="h-12 rounded-xl flex items-center justify-center gap-2 font-medium"
  >
    {state === 'sending' && <Loader2 className="animate-spin" />}
    {state === 'sent' && <CheckCircle className="text-green-600" />}
    {state.startsWith('error') && <AlertCircle className="text-red-500" />}
    {state === 'idle' && <Mail />}
    <span>
      {state === 'sent'
        ? t('auth.magiclink.sent')
        : state.startsWith('error')
        ? t('auth.magiclink.retry')
        : t('auth.magiclink.send')}
    </span>
  </Button>
  {state === 'sent' && (
    <p className="text-sm text-gray-500" aria-live="polite">
      {t('auth.magiclink.check_email')}
    </p>
  )}
</form>
```

---

### 4.2 レイアウト仕様

| 項目 | 内容 |
|------|------|
| 配置 | 垂直（Input → Button → Message） |
| 余白 | 各要素間 `gap-3` |
| 横幅 | `w-full`（親に応じて調整） |
| ボタン高さ | `h-12` |
| 入力欄高さ | `h-12` |
| テキスト | 16px（BIZ UDゴシック） |

---

### 4.3 カラースキーム

| 状態 | 背景 | テキスト | アイコン |
|------|------|-----------|-----------|
| idle | 白 | #111827 | 灰色 |
| sending | #E0E7FF | #1E40AF | 青 |
| sent | #ECFDF5 | #065F46 | 緑 |
| error | #FEF2F2 | #B91C1C | 赤 |

---

### 4.4 状態アイコン仕様

| 状態 | アイコン | ライブラリ | サイズ | カラー |
|------|-----------|-------------|---------|---------|
| idle | Mail | lucide-react | 20px | 継承 |
| sending | Loader2 | lucide-react | 20px | 継承 + `animate-spin` |
| sent | CheckCircle | lucide-react | 20px | `text-green-600` |
| error | AlertCircle | lucide-react | 20px | `text-red-500` |

---

### 4.5 i18nラベル構成

```json
"auth": {
  "magiclink": {
    "enter_email": "メールアドレスを入力",
    "send": "Magic Linkを送信",
    "sending": "送信中...",
    "sent": "メールを送信しました",
    "retry": "再試行",
    "check_email": "メールをご確認ください"
  }
}
```

---

### 4.6 アクセシビリティ設計

| 項目 | 内容 |
|------|------|
| キーボード操作 | Enter / Tab 完全対応 |
| ARIA属性 | `aria-live="polite"`（状態通知） |
| コントラスト比 | 4.5:1以上（WCAG 2.1 AA対応） |
| フォーカスリング | `focus-visible:ring-2 ring-blue-500 ring-offset-2` |
| 入力エラー | `role="alert"`で通知 |

---

### 4.7 アニメーション仕様

- 状態切替：`transition-all duration-200 ease-in-out`
- アイコン：`animate-spin`（送信中）
- 背景フェード：状態遷移時にわずかに明度変化

---

### 🧾 ChangeLog
| Version | Date | Summary |
|----------|------|----------|
| v1.0 | 2025-11-10 | 初版（Phase8仕様） |
| v1.1 | 2025-11-10 | Phase9準拠。i18n更新、WCAG対応、カラースキーム整備。 |

---

**文書ステータス:** ✅ Phase9 正式整合版  
**次のアクション:** 第5章 テスト仕様（ch05）へ進む
