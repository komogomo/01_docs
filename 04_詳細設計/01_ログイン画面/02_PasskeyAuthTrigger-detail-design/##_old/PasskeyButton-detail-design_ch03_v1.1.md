# PasskeyButton 詳細設計書 - 第3章：Props定義 v1.1

**Document ID:** HNM-PASSKEY-BUTTON-CH03  
**Version:** 1.1  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** ✅ Phase9 正式仕様（v1.4整合）  

---

## 第3章：Props定義

### 3.1 Props Interface

```typescript
export interface PasskeyButtonProps {
  /**
   * 認証成功時に呼び出されるコールバック
   * @description Supabaseセッション確立後に発火
   */
  onSuccess?: () => void;

  /**
   * 認証エラー時に呼び出されるコールバック
   * @param error - PasskeyErrorオブジェクト
   */
  onError?: (error: PasskeyError) => void;

  /**
   * ボタンの非活性制御
   * @default false
   */
  disabled?: boolean;

  /**
   * カスタムクラス名
   * @description Tailwindクラスによるレイアウト調整のみ許可
   */
  className?: string;
}

/**
 * Passkey認証時のエラー型
 */
export interface PasskeyError {
  code: string;
  message: string;
  type: 'error_network' | 'error_auth' | 'error_unknown';
}

3.2 各Propsの詳細
3.2.1 onSuccess（任意）

型: () => void
概要: Corbado SDKで認証成功し、Supabase側セッションが生成された際に呼び出される。
使用例:

<PasskeyButton
  onSuccess={() => router.push('/mypage')}
/>

補足:
アプリ側でリダイレクトやトースト表示などを行う。

3.2.2 onError（任意）
型: (error: PasskeyError) => void
概要: 認証処理中に例外が発生した場合に呼び出される。
内部動作: ErrorHandlerProvider 経由で共通UI通知も実行。
例:

const handleError = (error: PasskeyError) => {
  console.error(error.message);
};
<PasskeyButton onError={handleError} />

エラーコード一覧:
| コード             | 種別            | 想定シナリオ             | ユーザー表示文言           |
| --------------- | ------------- | ------------------ | ------------------ |
| `network_error` | error_network | 通信断・Corbadoサーバー不応答 | “ネットワークエラーが発生しました” |
| `auth_failed`   | error_auth    | Passkey不一致・認証拒否    | “認証に失敗しました”        |
| `unknown`       | error_unknown | その他例外              | “予期せぬエラーが発生しました”   |

3.2.3 disabled（任意）
型: boolean
デフォルト値: false
概要:
ボタンを一時的に非活性化する（例：同時押下防止・ロード中）。
例:

<PasskeyButton disabled={state === 'loading'} />

視覚表現: opacity-60 + cursor-not-allowed

3.2.4 className（任意）
型: string
デフォルト値: undefined
概要:
外部レイアウト調整のためのTailwindクラス付与。
使用例:

<PasskeyButton className="mt-4 w-full" />
・制約事項:
・色指定 (bg-*, text-*) の上書き禁止
・レイアウト関連 (mt-*, mb-*, mx-auto) のみ許可

3.3 Props使用例
3.3.1 基本パターン
<PasskeyButton
  onSuccess={() => router.push('/mypage')}
  onError={(err) => console.log(err.message)}
/>

3.3.2 ローディング制御パターン
<PasskeyButton
  disabled={isProcessing}
  onSuccess={() => toast.success('ログイン成功')}
  onError={(err) => toast.error(err.message)}
/>

3.3.3 カスタムスタイル
<PasskeyButton
  className="mt-8 w-full max-w-md"
  onSuccess={handleSuccess}
  onError={handleError}
/>

3.4 Props検証
3.4.1 TypeScript型チェック
// ✅ 正常
<PasskeyButton onSuccess={() => {}} onError={() => {}} />

// ❌ エラー: onErrorの型不一致
<PasskeyButton onError="string" /> // TSエラー

3.4.2 実行時検証（開発モード）
if (process.env.NODE_ENV === 'development') {
  if (onSuccess && typeof onSuccess !== 'function') {
    console.warn('PasskeyButton: onSuccess must be a function');
  }
  if (onError && typeof onError !== 'function') {
    console.warn('PasskeyButton: onError must be a function');
  }
}

3.5 設計上の決定事項
| Version  | Date           | Author              | Summary                                                    |
| -------- | -------------- | ------------------- | ---------------------------------------------------------- |
| v1.0     | 2025-01-10     | Claude              | 旧構成（Supabase直呼び出し）                                         |
| **v1.1** | **2025-11-10** | **Tachikoma / TKD** | **Corbado SDK + Supabase統合構成に再定義。email削除・PasskeyError導入。** |

Author: Tachikoma
Reviewer: TKD
Directory: /01_docs/04_詳細設計/01_ログイン画面/02_PasskeyButton-detail-design/
Status: ✅ 承認予定（正式仕様ライン v1.4整合）