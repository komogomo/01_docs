# HarmoNet Passkey認証の仕組みと挙動

**Document ID:** HNM-TECH-DOC-PASSKEY-BEHAVIOR  
**Version:** 1.0  
**作成日:** 2025-11-14  
**作成者:** Claude (AI Assistant)  
**対象:** HarmoNet開発チーム  

---

## 目次

1. [概要](#1-概要)
2. [Passkey登録時のキー生成タイミング](#2-passkey登録時のキー生成タイミング)
3. [デバイス側の設定状態と挙動](#3-デバイス側の設定状態と挙動)
4. [認証画面の自動表示](#4-認証画面の自動表示)
5. [プラットフォーム別の詳細挙動](#5-プラットフォーム別の詳細挙動)
6. [エラーハンドリング](#6-エラーハンドリング)
7. [実装上の推奨事項](#7-実装上の推奨事項)

---

## 1. 概要

本資料は、HarmoNetプロジェクトにおけるPasskey認証機能について、以下の疑問点を技術的に解説します：

- **Q1:** Passkey設定完了時点で、デバイス側にキーは保存されるのか？
- **Q2:** 生体認証（FaceID/指紋）が未設定の場合、どうなるのか？
- **Q3:** Passkey登録時、認証画面は自動的に開くのか？

---

## 2. Passkey登録時のキー生成タイミング

### 2.1 キーペア生成の流れ

```
ユーザー操作: 「Passkeyを登録」ボタンをクリック
        ↓
JavaScript実行: supabase.auth.registerPasskey()
        ↓
WebAuthn API: navigator.credentials.create()
        ↓
OS認証画面: FaceID / 指紋認証 / PIN入力を要求
        ↓
★ユーザー認証承認★
        ↓
【この瞬間】秘密鍵・公開鍵のペアが生成される
        ↓
秘密鍵: デバイスのセキュア領域（OS Keychain）に保存
公開鍵: Supabaseサーバーに送信・保存
        ↓
登録完了（マイページに成功メッセージ表示）
```

### 2.2 重要なポイント

| 項目 | 説明 |
|------|------|
| **生成タイミング** | ユーザーが生体認証/PINで承認した**その瞬間** |
| **秘密鍵の保存先** | デバイスのセキュア領域（外部に出ない） |
| **公開鍵の保存先** | Supabaseサーバー（DBに保存） |
| **クラウド同期** | **されない**（Device-bound passkey） |
| **エクスポート** | **不可**（セキュリティ上の理由） |

### 2.3 結論

**✅ 「チェックON = 即座にキー生成」**

- ユーザーが生体認証を承認完了した時点で、キーペアが生成・保存されます
- サーバー側の追加処理を待つ必要はありません
- キーはそのデバイスに固定され、他のデバイスには自動同期されません

---

## 3. デバイス側の設定状態と挙動

### 3.1 Passkey登録の前提条件

WebAuthn仕様上、以下が**必須**です：

| 必須要件 | 説明 |
|---------|------|
| **User Verification手段** | FaceID / 指紋認証 / PIN / パスコード のいずれか |
| **デバイス設定済み** | OSの画面ロック機能が有効になっていること |
| **Authenticator存在** | Platform Authenticator（デバイス内蔵の認証機構）が利用可能 |

### 3.2 生体認証未設定時の挙動

#### ケース1: iOS/iPadOS

```
状況A: FaceID/TouchID未設定 + パスコード設定済み
→ 結果: パスコード入力を要求される
→ 登録: ✅ 成功

状況B: FaceID/TouchID未設定 + パスコードも未設定
→ 結果: 「パスコードとFaceID/TouchIDを設定してください」とOSが促す
→ 登録: ❌ 失敗（InvalidStateError）
```

#### ケース2: Android

```
状況A: 指紋認証設定済み
→ 結果: 指紋認証を要求
→ 登録: ✅ 成功

状況B: 指紋認証未設定 + PIN/パターン設定済み
→ 結果: PIN/パターン入力を要求
→ 登録: ✅ 成功

状況C: いずれも未設定
→ 結果: NotSupportedError または InvalidStateError
→ 登録: ❌ 失敗
```

#### ケース3: Windows/macOS

```
Windows Hello未設定の場合:
→ 「Windows Helloを設定してください」とOSが促す
→ 登録: ❌ 失敗

macOS TouchID未設定の場合:
→ 「TouchIDまたはパスワードを設定してください」
→ 登録: ❌ 失敗
```

### 3.3 結論

**❌ 「キーだけが保存されている状態」は発生しません**

- Passkey登録時に、OSレベルの認証手段が**必須前提条件**です
- これらが未設定の場合、`auth.passkey.register()`実行時に**エラーが返され、登録が完了しません**
- つまり、認証手段なしでキーだけが生成されることは技術的に不可能です

---

## 4. 認証画面の自動表示

### 4.1 基本動作

**✅ 完全自動表示**

```
1. ユーザーが「Passkeyを登録」ボタンをクリック
   ↓
2. `supabase.auth.registerPasskey()` が実行される
   ↓
3. ブラウザが `navigator.credentials.create()` を呼び出す
   ↓
4. ★OS側の認証画面が0.5秒以内に自動的にポップアップ★
   ↓
5. ユーザーが生体認証 or PIN入力
   ↓
6. 認証成功 → キーペア生成 → 登録完了
```

### 4.2 重要な特徴

| 項目 | 説明 |
|------|------|
| **表示タイミング** | ボタンクリックと同時（0.5秒以内） |
| **制御主体** | ブラウザ + OS（Webアプリ側では制御不可） |
| **ユーザー操作** | 追加の設定画面を開く必要なし |
| **所要時間** | 通常2〜3秒で完了 |

### 4.3 ユーザー体験の流れ

```
【ユーザーの操作】
Step 1: 「Passkeyを登録」ボタンをクリック
        ↓ (0.5秒)
Step 2: 画面に認証ダイアログが自動表示される
        ↓ (1〜2秒)
Step 3: FaceIDスキャン or 指紋タッチ
        ↓ (0.5秒)
Step 4: 「登録完了」メッセージ表示

【合計所要時間: 約2〜3秒】
```

---

## 5. プラットフォーム別の詳細挙動

### 5.1 iOS/iPadOS

#### 自動表示される画面

```
┌─────────────────────────┐
│  example.com            │
│                         │
│  パスキーを作成           │
│                         │
│  [Face IDでサインイン]    │
│   または                 │
│  [パスコードを使用]        │
│                         │
│  [キャンセル]             │
└─────────────────────────┘
```

**特徴:**
- Face IDが設定されていれば、顔認証が優先表示
- Touch ID搭載機では指紋認証が表示
- フォールバック: パスコード入力

**技術仕様:**
- `PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()` は常に `true`
- ただし、パスコード設定が必須（未設定時はエラー）

---

### 5.2 Android

#### 自動表示される画面

```
┌─────────────────────────┐
│  パスキーを保存           │
│                         │
│  example.com用           │
│  user@example.com        │
│                         │
│  [指紋でロック解除]        │
│   または                 │
│  [PINを入力]             │
│                         │
│  [キャンセル]             │
└─────────────────────────┘
```

**特徴:**
- Google Play Servicesが画面を管理
- デバイスに設定されている認証方法を自動検出
- 複数の認証方法がある場合、選択可能

**技術仕様:**
- Android 9以降でWebAuthn対応
- Google Password Managerと統合

---

### 5.3 Windows

#### 自動表示される画面

```
┌─────────────────────────┐
│  Windows セキュリティ     │
│                         │
│  顔認証でサインイン        │
│   または                 │
│  [PINを使用]             │
│                         │
│  example.com            │
│                         │
│  [キャンセル]             │
└─────────────────────────┘
```

**特徴:**
- Windows Hello統合
- 顔認証 / 指紋認証 / PIN
- USB外部キー（YubiKey等）も利用可

**技術仕様:**
- Windows 10 バージョン1903以降で対応
- Edge/Chrome/Firefoxで利用可能

---

### 5.4 macOS

#### 自動表示される画面

```
┌─────────────────────────┐
│  "Safari"が              │
│  Touch IDを使用しようと    │
│  しています               │
│                         │
│  [Touch IDセンサーに       │
│   指を置いてください]       │
│                         │
│  example.com            │
│                         │
│  [パスワードを使用]        │
│  [キャンセル]             │
└─────────────────────────┘
```

**特徴:**
- Touch ID優先（Touch Bar搭載機）
- iCloud Keychainと統合可能
- フォールバック: macOSログインパスワード

**技術仕様:**
- macOS Monterey (12.0)以降で最適化
- Safari 14以降で完全対応

---

## 6. エラーハンドリング

### 6.1 HarmoNet実装でのエラー種別

プロジェクトナレッジ（login-feature-design-ch06_v1.1.md）より：

| エラー種別 | 表示文言 | 対応動作 | 原因 |
|-----------|----------|----------|------|
| **NotAllowedError** | 認証がキャンセルされました | idleに戻る | ユーザーが認証画面でキャンセル |
| **NotFoundError** | パスキーが登録されていません | CTA表示 | 登録済みPasskeyなし |
| **InvalidStateError** | デバイスが対応していません | ボタンdisabled | 生体認証/PIN未設定 |
| **NetworkError** | 通信エラーが発生しました | 再試行案内 | ネットワーク障害 |

### 6.2 エラー時のUI表示

```typescript
// 擬似コード
export const PasskeyButton = () => {
  const [state, setState] = useState("idle");

  const handlePasskeyLogin = async () => {
    try {
      setState("loading");
      const { data, error } = await supabase.auth.signInWithPasskey();
      if (error) throw error;
      setState("success");
      window.location.href = "/mypage";
    } catch (err) {
      if (err.message.includes("No passkey")) {
        setState("error_not_found");
      } else if (err.message.includes("InvalidState")) {
        setState("error_origin");
      } else {
        setState("error_network");
      }
    }
  };

  return (
    <button
      type="button"
      onClick={handlePasskeyLogin}
      disabled={state === "loading"}
      aria-live="polite"
    >
      {state === "loading" && "認証中..."}
      {state === "success" && "認証成功"}
      {state === "error_not_found" && "パスキーが登録されていません"}
      {state === "error_origin" && "デバイスが対応していません"}
      {state === "idle" && "パスキーでログイン"}
    </button>
  );
};
```

### 6.3 多言語対応（i18n）

| key | ja | en | zh |
|------|----|----|----|
| `auth.passkey.error_not_found` | パスキーが登録されていません | No passkey registered | 未注册通行密钥 |
| `auth.passkey.error_origin` | デバイスが対応していません | This device is not supported | 此设备不支持 |
| `auth.passkey.loading` | 認証中... | Authenticating... | 正在验证... |
| `auth.passkey.success` | 認証成功 | Authentication successful | 验证成功 |

---

## 7. 実装上の推奨事項

### 7.1 事前チェックの実装

```typescript
/**
 * Passkey登録ボタン表示前に実行する事前チェック
 */
async function checkPasskeySupport(): Promise<{
  supported: boolean;
  reason?: string;
}> {
  // Step 1: ブラウザがWebAuthnに対応しているか
  if (!window.PublicKeyCredential) {
    return { 
      supported: false, 
      reason: 'browser_unsupported' 
    };
  }
  
  // Step 2: Platform Authenticatorが利用可能か
  try {
    const available = await PublicKeyCredential
      .isUserVerifyingPlatformAuthenticatorAvailable();
    
    if (!available) {
      return { 
        supported: false, 
        reason: 'no_authenticator' 
      };
    }
  } catch (error) {
    return { 
      supported: false, 
      reason: 'check_failed' 
    };
  }
  
  return { supported: true };
}
```

### 7.2 ユーザーへの事前案内

#### 推奨UI例

```
┌──────────────────────────────────┐
│  パスキーを登録                    │
│                                  │
│  次の画面で、FaceIDまたは指紋認証を │
│  求められます。デバイスの指示に      │
│  従って認証を完了してください。      │
│                                  │
│  ※デバイスに生体認証またはPINが     │
│    設定されている必要があります      │
│                                  │
│  [登録する]  [あとで]              │
└──────────────────────────────────┘
```

### 7.3 タイムアウト設定

```typescript
// Supabase Auth設定（推奨）
const passkeyOptions = {
  timeout: 120000,  // 2分（デフォルト）
  userVerification: 'required',  // 必須
  authenticatorSelection: {
    authenticatorAttachment: 'platform',  // Platform Authenticator優先
    requireResidentKey: true,  // Discoverable Credential
    userVerification: 'required'
  }
};
```

### 7.4 エラー時のフォールバック

```
エラー発生時の推奨フロー:

1. InvalidStateError（生体認証未設定）
   → 「デバイスの設定で生体認証またはPINを設定してください」
   → Magic Linkへ誘導

2. NotAllowedError（ユーザーキャンセル）
   → 「登録をキャンセルしました」
   → 再試行ボタン表示

3. NetworkError
   → 「通信エラーが発生しました」
   → 再試行ボタン表示
```

### 7.5 アクセシビリティ対応

```typescript
// ARIA属性の設定例
<button
  type="button"
  onClick={handlePasskeyRegister}
  aria-live="polite"
  aria-busy={state === "loading"}
  aria-label="パスキーを登録する"
  disabled={state === "loading"}
>
  {/* ボタン内容 */}
</button>

// エラー表示
<div 
  role="alert" 
  aria-live="assertive"
  hidden={!errorMessage}
>
  {errorMessage}
</div>
```

---

## 付録A: HarmoNetプロジェクト仕様との整合性

### A.1 関連ドキュメント

| ドキュメント | 参照箇所 |
|-------------|---------|
| login-feature-design-ch01_v1.1.md | 3.3 Passkey登録フロー |
| login-feature-design-ch05_v1.1.md | ch05-4. Passkeyセキュリティ詳細 |
| login-feature-design-ch06_v1.1.md | ch06-7. エラー処理とハンドリング |

### A.2 技術スタック

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Next.js | 15.5.x | フロントエンドフレームワーク |
| React | 19.0.0 | UIライブラリ |
| Supabase Auth | GoTrue 2.139 | 認証基盤 |
| WebAuthn | Level 2 | Passkey標準プロトコル |

### A.3 セキュリティ要件

| 項目 | 設定値 |
|------|--------|
| **プロトコル** | WebAuthn Level 2 |
| **認証器タイプ** | Platform (内蔵)優先 |
| **Origin検証** | `window.location.origin` = `rpId` 強制一致 |
| **鍵保管先** | デバイスセキュア領域（OS Keychain） |
| **User Verification** | Required |

---

## 付録B: よくある質問（FAQ）

### Q1: Passkeyを複数デバイスで使えますか？

**A:** HarmoNetの現在の仕様では、**Device-bound passkey**（デバイス固定型）を採用しています。各デバイスで個別に登録が必要です。

### Q2: スマホで登録したPasskeyをPCで使えますか？

**A:** できません。各デバイスで別途登録してください。将来的にSynced passkey（クラウド同期型）への対応も検討されています。

### Q3: Passkeyを削除したい場合は？

**A:** マイページのセキュリティ設定から削除できます（Phase9実装予定）。

### Q4: 生体認証が使えないデバイスでは？

**A:** PIN/パスコード認証でも登録可能です。生体認証が必須ではありません。

### Q5: 登録に失敗する場合の対処法は？

**A:**
1. デバイスの画面ロック（PIN/生体認証）が設定されているか確認
2. ブラウザが最新版か確認
3. HTTPSで接続しているか確認
4. それでも解決しない場合は、Magic Linkログインをご利用ください

---

## 改訂履歴

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2025-11-14 | Claude | 初版作成。Passkey登録の挙動、デバイス設定要件、認証画面の自動表示について解説 |

---

**Document ID:** HNM-TECH-DOC-PASSKEY-BEHAVIOR  
**Status:** Draft  
**Approved by:** （承認待ち）  
**Next Review:** 2025-12-14  

---

## 参考資料

- [WebAuthn Specification (W3C)](https://www.w3.org/TR/webauthn-2/)
- [FIDO Alliance - Passkeys](https://fidoalliance.org/passkeys/)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [MDN - Web Authentication API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API)

---

**END OF DOCUMENT**
