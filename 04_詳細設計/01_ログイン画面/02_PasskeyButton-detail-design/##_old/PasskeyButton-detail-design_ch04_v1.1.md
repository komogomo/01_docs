# PasskeyButton 詳細設計書 - 第4章：内部状態とフック v1.1

**Document ID:** HNM-PASSKEY-BUTTON-CH04  
**Version:** 1.1  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** ✅ Phase9 正式仕様（v1.4整合）  

---

## 第4章：内部状態とフック

### 4.1 状態管理

#### 4.1.1 PasskeyState型定義
```typescript
type PasskeyState = 'idle' | 'loading' | 'success' | 'error';

状態の説明:
| 状態        | 説明        | UI表示       | 遷移元       | 遷移先                  |
| --------- | --------- | ---------- | --------- | -------------------- |
| `idle`    | 初期状態（待機中） | 通常ボタン      | -         | `loading`            |
| `loading` | 認証処理中     | スピナー表示     | `idle`    | `success` or `error` |
| `success` | 認証成功      | チェックアイコン表示 | `loading` | `idle`               |
| `error`   | エラー発生     | エラーメッセージ表示 | `loading` | `idle`               |

4.1.2 useState フック
const [state, setState] = useState<PasskeyState>('idle');

初期値: 'idle'

4.2 コアフック定義
4.2.1 handlePasskeyLogin（useCallback）
const handlePasskeyLogin = useCallback(async () => {
  try {
    setState('loading');

    // Corbado SDK初期化
    await Corbado.load({
      projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!,
    });

    // Passkey認証を開始
    const result = await Corbado.passkey.login();
    if (!result?.success) throw new Error('Authentication failed');

    // Supabaseセッションを確立
    const { id_token } = result;
    const { error } = await supabase.auth.signInWithIdToken({
      provider: 'corbado',
      token: id_token,
    });

    if (error) throw error;

    setState('success');
    onSuccess?.();
  } catch (err: any) {
    setState('error');

    const e: PasskeyError = {
      code: err.code || 'unknown',
      message: err.message || 'Unexpected error',
      type: 'error_auth',
    };

    onError?.(e);
    handleError(e.message);

    // 状態をidleへ戻す（再試行可能にする）
    setTimeout(() => setState('idle'), 1200);
  }
}, [onSuccess, onError, handleError, supabase]);

4.3 状態遷移フロー
[初期状態: idle]
    ↓ (クリック)
[setState('loading')]
    ↓
[Corbado.load() → passkey.login()]
    ↓
[成功] → Supabase signInWithIdToken → setState('success') → onSuccess()
    ↓ (1.2s後)
[setState('idle')]
    OR
[失敗] → setState('error') → onError() → handleError() → (1.2s後) idle

4.4 副作用・useEffect方針
・useEffectは使用しない
　状態変更は全てユーザーアクション起点。
　認証後は自動遷移するため副作用監視は不要。
・タイマー処理

setTimeout(() => setState('idle'), 1200);

成功／失敗後いずれも短時間でidleへ戻す。UXを途切れさせないため、100msではなく1.2sに拡張。

4.5 ErrorHandlerProvider統合

PasskeyButtonでは直接トーストやモーダルを表示せず、
共通エラープロバイダに委譲する。
const handleError = useErrorHandler();
...
handleError(e.message);

| 項目            | 内容                              |
| ------------- | ------------------------------- |
| **Provider名** | ErrorHandlerProvider (C-16)     |
| **ハンドラ名**     | `useErrorHandler()`             |
| **通知方式**      | トースト（shadcn/toast） or アラートダイアログ |

4.6 状態リセット設計
・成功／失敗後に自動idleへ戻す。
・再レンダリング時に状態保持しない（都度リセット）。
・Supabaseセッションはグローバル保持されるため再認証不要。

4.7 パフォーマンス最適化
| 項目                 | 方法                           | 目的            |
| ------------------ | ---------------------------- | ------------- |
| **useCallback安定化** | 依存配列に全関数を含める                 | 不要再生成防止       |
| **早期return**       | `state==='loading'` で即return | 二重クリック防止      |
| **軽量フロー**          | 例外処理をcatch内完結                | useEffect依存排除 |

4.8 設計上の決定事項
| 決定項目      | 内容                                         |
| --------- | ------------------------------------------ |
| **状態数**   | 4段階（idle / loading / success / error）      |
| **副作用管理** | useEffect不使用。全てhandlePasskeyLogin内完結。      |
| **エラー管理** | ErrorHandlerProvider経由。Props経由のonErrorも併用。 |
| **再試行**   | 成功・失敗いずれも1.2秒後にidleへ戻す。                    |
| **開発者補助** | dev環境で`console.warn()`出力を残す。               |

4.9 改訂履歴
| Version  | Date           | Author              | Summary                                                   |
| -------- | -------------- | ------------------- | --------------------------------------------------------- |
| v1.0     | 2025-01-10     | Claude              | Supabase直呼び出し構成                                           |
| **v1.1** | **2025-11-10** | **Tachikoma / TKD** | **Corbado SDK + Supabase統合構成に再定義。ErrorHandler連携・状態4段階化。** |

Author: Tachikoma
Reviewer: TKD
Directory: /01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design/
Status: ✅ 承認予定（正式仕様ライン v1.4整合）