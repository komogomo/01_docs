# HarmoNet 詳細設計書 - ログイン機能 第4章 SessionHandler設計書 v1.2

**Document ID:** HARMONET-LOGIN-CH04-SESSIONHANDLER  
**Version:** 1.2  
**Created:** 2025-11-10  
**Updated:** 2025-11-10  
**Supersedes:** v1.1  
**Related Tech Spec:** harmonet-technical-stack-definition_v4.0.md  
**Author:** Tachikoma  
**Reviewer:** TKD  
**Status:** ✅ Phase9 技術スタックv4.0準拠版  

---

## 第1章 概要

本章は、HarmoNetログイン機能における **セッション管理および状態遷移制御** の詳細設計を示す。  
本v1.2では、旧来のSupabase認証トークンベース構成を廃止し、  
**Corbado公式構成（@corbado/react + @corbado/node）** に統合する。

---

### 1.1 改訂目的

| 改訂項目 | 内容 |
|-----------|------|
| 認証管理 | Corbadoセッションを中核とする構成へ移行 |
| Supabase連携 | RLS（行レベルセキュリティ）適用に限定 |
| セッション取得 | `/api/session` APIを統一的に使用 |
| トークン交換 | `signInWithIdToken()` 呼出しを廃止 |
| セキュリティ | JWT検証をCorbado側に委譲 |
| UI | セッションハンドリング専用の非表示処理へ簡素化 |

---

## 第2章 構成概要

### 2.1 処理フロー図

```mermaid
sequenceDiagram
  participant U as User
  participant F as Next.js (React)
  participant C as Corbado Cloud
  participant N as CorbadoService (@corbado/node)
  participant S as Supabase

  U->>F: パスキー／MagicLinkによるログイン
  F->>C: Corbado認証リクエスト
  C-->>F: short_session Cookie発行
  F->>/api/session: セッション検証
  /api/session->>N: Corbado JWT検証
  N-->>/api/session: セッション情報返却
  /api/session-->>F: JSONレスポンス
  F->>S: 認可確認（RLS）
  S-->>U: MyPage表示

2.2 関連コンポーネント
| コンポーネント             | 役割          | 対応ファイル                                |
| ------------------- | ----------- | ------------------------------------- |
| **PasskeyButton**   | Passkey認証実行 | `PasskeyButton-detail-design_v1.3.md` |
| **MagicLinkForm**   | メール認証実行     | `login-feature-design-ch02_v1.2.md`   |
| **SessionHandler**  | 認証後のセッション検証 | 本章                                    |
| **Supabase Client** | 認可・RLS層管理   | `/lib/supabase/client.ts`             |

第3章 処理仕様
3.1 セッション検証（app/api/session/route.ts）
import { NextResponse } from 'next/server';
import { CorbadoService } from '@corbado/node';

const corbado = new CorbadoService({
  projectId: process.env.NEXT_PUBLIC_CORBADO_PROJECT_ID!,
  apiSecret: process.env.CORBADO_API_SECRET!,
});

export async function GET() {
  try {
    const session = await corbado.sessions().getCurrent();
    return NextResponse.json(session);
  } catch {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  }
}

・/api/session はすべてのログイン完了後に呼ばれる共通エンドポイント。
・CorbadoServiceが内部でJWT検証とセッション状態の正当性確認を実施。
・成功時はユーザー情報（email, sub, statusなど）をJSONで返す。

3.2 クライアント側処理例
'use client';
import { useEffect, useState } from 'react';

export default function useSession() {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchSession() {
      const res = await fetch('/api/session');
      const data = await res.json();
      setSession(data);
      setLoading(false);
    }
    fetchSession();
  }, []);

  return { session, loading };
}

・useSession() フックで現在のCorbadoセッションを取得。
・未認証の場合は session が null となり、リダイレクトや再認証誘導を行う。

3.3 セッション状態制御
| 状態                  | 説明             | 処理               |
| ------------------- | -------------- | ---------------- |
| `authenticated`     | Corbadoセッション有効 | MyPageへ遷移        |
| `not_authenticated` | 未ログインまたは期限切れ   | LoginPageへ戻る     |
| `error`             | JWT検証失敗        | `/error/auth`へ遷移 |

第4章 Supabase連携仕様
| 項目   | 内容                            |
| ---- | ----------------------------- |
| 連携目的 | CorbadoユーザーIDによるRLS適用         |
| 接続方式 | Supabase Client経由（anon key）   |
| 認証方式 | CorbadoセッションJWTを参照            |
| 更新頻度 | `/api/session`呼出しごとに確認        |
| メリット | SupabaseとCorbadoの責務を分離し安全性を維持 |

第5章 エラーハンドリング
| ケース                | 原因                | 対応        |
| ------------------ | ----------------- | --------- |
| 401 Unauthorized   | セッション未確立          | ログイン画面へ戻す |
| 500 Internal Error | Corbado Cloud通信失敗 | リトライ表示    |
| JWT検証失敗            | Cookie改ざん・期限切れ    | 再ログイン要求   |
| 通信エラー              | ネットワーク断           | オフライン通知   |

第6章 セキュリティ仕様
・HTTPS必須
・CORBADO_API_SECRET はサーバー専用
・Cookie属性：Secure, SameSite=Lax
・JWT有効期限：60分（Corbado管理）
・RLS: CorbadoユーザーIDで行制御

第7章 テスト観点
| テストID     | 項目                  | 期待結果      |
| --------- | ------------------- | --------- |
| T-CH04-01 | `/api/session` 正常応答 | JWT情報を返却  |
| T-CH04-02 | 未ログイン状態             | 401レスポンス  |
| T-CH04-03 | 有効セッション             | MyPageへ遷移 |
| T-CH04-04 | 期限切れセッション           | 再ログイン要求   |
| T-CH04-05 | Corbado通信断          | エラー通知     |

第8章 参考URL
・Corbado GitHub: passkeys-nextjs
・Qiita: Next.jsとCorbadoを使用したパスキー実装 #TypeScript
・Corbado Docs
・Supabase Docs: Auth SignInWithIdToken

第9章 ChangeLog
| Version  | Date           | Author              | Description                                                                 |
| -------- | -------------- | ------------------- | --------------------------------------------------------------------------- |
| v1.1     | 2025-11-07     | TKD / Tachikoma     | Supabase直呼び構成                                                               |
| **v1.2** | **2025-11-10** | **TKD / Tachikoma** | **技術スタックv4.0対応：Corbado公式構成に統合。`signInWithIdToken()`呼出しを廃止し、セッション検証APIを採用。** |

Document Status: ✅ 完成（Phase9最終仕様）
Approved by: TKD