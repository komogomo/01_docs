# HarmoNet Coding Standard v1.1  
**Created:** 2025-11-06  
**Scope:** TypeScript / React / Next.js / Tailwind / Supabase（Container & Cloud共通）

---

## 第0章　前書き（Purpose & Scope）

### 0.1　目的
この規約は HarmoNet アプリケーションのコード品質と再現性を維持し、  
AI エージェント（Windsurf 等）と人間開発者の両方が同一基準でコーディングできることを目的とする。

---

### 0.2　適用範囲
本規約は、HarmoNet Phase9 実装フェーズにおける  
**フロントエンド開発（Next.js + React + TypeScript + Tailwind + Prisma ORM）** を対象とする。

Prisma ORM は Supabase を介した型安全なデータアクセスの主要手段であり、  
Windsurf／Cursor 実装時における標準ORMとする。

バックエンド（NestJS・Edge Functions）は将来拡張範囲とし、  
本規約の適用外とする。

- `/src/` 配下の実装コード全般。  
- Next.js (App Router) + React 19 + TypeScript 5 + Tailwind 4 を前提。  
- Supabase (Auth / DB / Storage) をバックエンドとする。  

### 0.3　Supabase 環境について
開発環境では Docker コンテナ版 Supabase、  
本番では Supabase Cloud (Hosted) を使用する。  
両環境で SDK / API 仕様は同一であるため、規約上は区別しない。  
環境差は `.env.development` / `.env.production` で管理し、  
URL や Key をコードへハードコーディングしてはならない。

### 0.4　禁止事項（全体）
- 未定義の命名を自動生成して使用する。  
- 規約にないディレクトリ・ファイル構造を新設する。  
- `any` 型・`eval` ・`var` を使用する。  
- 非同期例外を握りつぶす（`.catch()` のみで処理を終える）。  
- UI コードにビジネスロジックを直接記述する。  

---

## 第1章　ディレクトリ構成と運用ルール

### 1.1　固定ディレクトリ構成

/src/
├─ app/ # Next.js ルート
│ ├─ login/ # ログイン画面
│ ├─ board/ # 掲示板
│ ├─ facility/ # 施設予約
│ ├─ survey/ # アンケート
│ └─ mypage/ # マイページ
│
├─ components/ # UI コンポーネント
│ ├─ common/ # 共通部品（Header/Footer 等）
│ ├─ board/
│ ├─ facility/
│ ├─ survey/
│ └─ mypage/
│
├─ lib/ # 共通ロジック層
│ ├─ api/ # API 呼び出し
│ ├─ hooks/ # 共通 React Hook
│ └─ utils/ # 汎用関数
│
├─ styles/ # Tailwind 設定・Design Tokens
│ ├─ globals.css
│ └─ tokens.css
│
├─ types/ # 型定義
│ └─ index.d.ts
│
└─ tests/ # テスト（必要時）


---

### 1.2　ディレクトリ命名規則
| 対象 | 規則 | 例 |
|------|------|----|
| ディレクトリ | 小文字＋ハイフン区切り | `board`, `facility-booking` |
| ファイル（コンポーネント） | PascalCase | `Header.tsx`, `LoginForm.tsx` |
| 型定義ファイル | camelCase ＋ `.d.ts` | `userSchema.d.ts` |
| CSS / トークン | 小文字＋ハイフン | `globals.css`, `color-tokens.css` |

---

### 1.3　ディレクトリ操作ポリシー
| 操作 | 許可 | 備考 |
|------|------|------|
| 既存ディレクトリ内のファイル追加 | ✅ 許可 | 指定パス内でのみ作業可 |
| 新規ディレクトリ作成（第1階層） | ❌ 禁止 | タチコマ承認が必要 |
| 新規ディレクトリ作成（第2階層以下） | ⚠️ 原則禁止 | Claude / TKD 承認後に追加 |
| ディレクトリ名変更・削除 | ❌ 禁止 | バージョン履歴で管理 |
| 一時フォルダ (`tmp`, `sandbox`) | ❌ 禁止 | 管理外。別リポジトリで実施 |

---

### 1.4　承認フロー
1. **Windsurf** が新規パスを必要とする場合  
　→ `// TODO: require new directory` コメントを出力。  
2. **Claude** が設計レベルで妥当性を審査。  
3. **タチコマ** が最終承認し、設計書 `/01_docs/02_design/` に追記。  

---

### 1.5　ディレクトリ関連禁止事項
- コンポーネント階層を飛び越えて import しない。  
  （例：`app/login` から `app/board` を直接参照 ❌）  
- 相対パスの乱用禁止。`@/components/...` 形式の絶対パスを使用。  
- `.env` 以外の設定ファイルを `/src` 直下に置かない。  

---

### 1.6　補足
・この構成は Phase9 以降固定とし、新規機能追加は既存構造に準拠して行う。  
・構造変更が必要な場合は「構成変更提案書（change-proposal）」を提出すること。  

---

## 第2章　命名規則（Naming Conventions）

### 2.1　目的
・命名はAIエージェントおよび人間開発者双方が誤解なくコードを解釈するための最重要要素である。  
・すべての命名は「一貫性・可読性・再利用性」を満たすこと。

---

### 2.2　一般命名規則

| 区分 | 規則 | 例 |
|------|------|----|
| コンポーネント名 | PascalCase（名詞） | `Header`, `LoginForm`, `LanguageSwitcher` |
| 関数名 | camelCase（動詞＋目的語） | `handleSubmit`, `fetchBoardList` |
| 変数名 | camelCase（名詞） | `userEmail`, `postList` |
| 定数名 | 全大文字＋アンダースコア | `API_BASE_URL`, `DEFAULT_LANG` |
| 型／インターフェース | PascalCase＋名詞 | `UserSchema`, `PostDetail` |
| Props名 | 意味を明確に（`on`, `is`, `has`, `data`） | `onClick`, `isActive`, `dataSource` |

---

### 2.3　イベントハンドラ命名
- `on` で始まる Props、`handle` で始まる実装関数。  
  ```tsx
  <Button onClick={handleLogin} />
  const handleLogin = () => { ... }

・イベント名は PascalCase のまま保持（例：onChangeLanguage）。

2.4　ファイル命名
| 種別          | 命名形式           | 例                                   |
| ----------- | -------------- | ----------------------------------- |
| コンポーネントファイル | PascalCase.tsx | `LoginForm.tsx`                     |
| ロジック・Hook   | camelCase.ts   | `useBoardFetch.ts`, `formatDate.ts` |
| API モジュール   | camelCase.ts   | `postService.ts`                    |
| 型定義         | camelCase.d.ts | `userSchema.d.ts`                   |
| スタイル        | 小文字＋ハイフン.css   | `globals.css`, `color-tokens.css`   |

2.5　命名マトリクス参照

画面単位・機能単位の命名定義は別途
/01_docs/03_rules/harmonet-naming-matrix_v1.0.md に定義する。
新しい命名が必要な場合はエージェントが勝手に生成せず、
// TODO: require name コメントを出力し、タチコマまたはClaudeに照会する。

2.6　禁止事項
・意味のない略語 (tmp, obj, data1) の使用
・同一スコープ内で類似変数名 (user, userInfo, userData) の重複
・コンポーネント名と同名の関数・変数定義
・命名に日本語・絵文字・全角文字を使用すること

2.7　命名責任分担
| レイヤ      | 役割             |
| -------- | -------------- |
| タチコマ     | 最終決定・命名マトリクス管理 |
| Claude   | 補足整形・整合性チェック   |
| Windsurf | 命名の生成禁止。参照のみ   |
| Gemini   | 命名不整合の監査報告     |

第3章　TypeScript構文規約（TypeScript Syntax Rules）
3.1　基本設定

strict モードを常に有効化。
・target は ES2022、module は ESNext を推奨。
・resolveJsonModule, esModuleInterop は有効化。
・Linter は ESLint + Prettier を併用する。

3.2　型定義とキャスト
| 禁止事項                                   | 推奨方法                    |
| -------------------------------------- | ----------------------- |
| `any` 型                                | 明示的型または `unknown` を使用   |
| 非安全キャスト (`as unknown as T`)            | 型ガードまたはジェネリクスを使用        |
| Boxed 型 (`String`, `Number`, `Object`) | プリミティブ型を使用              |
| null/undefined 混在                      | `strictNullChecks` で厳密化 |

// ✅ 推奨
function getUser(id: string): User | null { ... }

// ❌ 非推奨
function getUser(id): any { ... }

3.3　関数・定数宣言
・関数宣言は const＋アロー関数で統一。
・再代入不要な変数は必ず const。
・再代入を伴う場合のみ let。

var は全面禁止。

3.4　例外処理
try {
  const res = await fetchUser();
  if (!res.ok) throw new Error('Network error');
} catch (err: unknown) {
  console.error((err as Error).message);
}

・catch で握りつぶさない。必ずログまたはUI通知。
・非同期処理では try/catch を優先し、.catch() 
チェーンは禁止。

3.5　モジュール構成

ファイル単位で単一責務を持つこと。
・複数exportが必要な場合、index.ts で再export。
・default exportは1ファイル1つまで。

import順序は「外部→内部→型→CSS」。
// ✅ 推奨
import { useState } from "react";
import { fetchBoardList } from "@/lib/api/board";
import type { Board } from "@/types/board";
import "./styles.css";

3.6　クリーンアップ（デストラクタ代替）

ReactのuseEffect内では必ずクリーンアップ関数を返す。
これを怠るとイベントリークやWebSocket残留が発生する。

useEffect(() => {
  const timer = setInterval(() => refresh(), 1000);
  return () => clearInterval(timer); // destructor的役割
}, []);

3.7　禁止構文一覧

var、with、eval、Function()

== 比較（必ず === 使用）

・any 型の無条件利用
・console.log を残したままコミット
・DOM直接操作 (document.getElementById)
・JSX内での無名関数多用

3.8　推奨構文一覧

Null合体演算子 ?? とオプショナルチェーン ?. の活用

Array.prototype.map / filter / reduce の関数型利用

Promise.all / await の併用で並列処理化

as const によるリテラル型固定

3.9　コメント規約（TypeScript）
/**
 * getBoardList
 * Fetch board posts from Supabase
 * @param tenantId - UUID of tenant
 * @returns Board[]
 */

・英語コメントを原則とする。
・パラメータ・戻り値・例外を明記。
・JSDoc形式で自動生成可能な構文を使用。

---

## 第4章　React コーディング規約（React Coding Rules）

### 4.1　基本原則
- すべてのコンポーネントは **Functional Component** とし、Class Component は使用しない。  
- React 19 以降の `use` API に対応するが、同期的なフック呼び出しは禁止。  
- UIとロジックを分離し、1ファイル1責務を原則とする。  

---

### 4.2　コンポーネント設計
| 項目 | 規則 |
|------|------|
| ファイル単位 | 1コンポーネント1ファイル。Propsは明示的に型定義。 |
| Props命名 | `is` / `has` / `on` / `data` など意味を明確化。 |
| 再利用性 | UI構造が2画面以上で使用される場合は `components/common` へ移動。 |
| 子要素 | `children` を使用。必要時のみ `ReactNode` として受け取る。 |

```tsx
type LoginFormProps = {
  onSubmit: (email: string, password: string) => void;
};

export default function LoginForm({ onSubmit }: LoginFormProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  return (
    <form onSubmit={(e) => { e.preventDefault(); onSubmit(email, password); }}>
      ...
    </form>
  );
}

4.3　Hooks の利用ルール
・Hooks は コンポーネントのトップレベルでのみ呼び出す。
・条件分岐やループの中で呼び出してはならない。
・カスタム Hook の命名は必ず use で始める。
・useEffect は依存配列を必ず明示する。
・useEffect 内では setState を過剰に呼ばない。
・副作用処理には AbortController を利用し、クリーンアップを定義。

useEffect(() => {
  const controller = new AbortController();
  fetchData({ signal: controller.signal });
  return () => controller.abort();
}, []);

4.4　状態管理
・ローカルステート優先。グローバルステートは最小限にする。
・コンテキストは**軽い情報（言語設定やテーマなど）**に限定。
・大規模データや非同期キャッシュは SWR または Zustand を使用。
・Redux の利用は禁止。

4.5　レンダリング最適化
・再レンダー抑制に React.memo を活用。
・コールバック関数は useCallback、計算結果は useMemo でメモ化。
・key 属性はユニークな値を指定（index禁止）。
・コンポーネントは React.Fragment (<>...</>) を基本構文とする。

4.6　イベント処理
・JSX内で匿名関数を多用しない。
・handleXxx 関数を外部に切り出し、useCallbackで固定。

const handleClick = useCallback(() => {
  router.push("/board");
}, [router]);

4.7　エラーハンドリング
・例外は try/catch で捕捉し、ErrorBoundary でUIを保護する。
・ユーザー通知はToastやモーダル経由で表示。
・Promiseのcatchのみで終了するパターンは禁止。

4.8　非同期処理
・すべてのデータ取得は fetch ではなく Supabase SDK または useSWR を使用。
・useSWR は key と fetcher を定義し、キャッシュ管理を統一。
・不要になったリクエストは AbortController で中断。

4.9　Suspense / ErrorBoundary
・非同期コンポーネントには <Suspense> を必ず設置。
・グローバルに <ErrorBoundary> を1つ設ける（_app.tsx レベル）。

4.10　禁止事項
・useEffect 内で setInterval や WebSocket を放置する。
・useState を連続呼び出しして再レンダーを多発させる。
・Hooks 呼び出し順序を変更する。
・JSX 内にロジックや重い計算式を直接記述する。
・props に無名関数を直接渡す。

第5章　Tailwind / UI 設計ルール（UI & Styling Rules）
5.1　基本原則
・HarmoNet の UI は「やさしく・自然・控えめ」を基調とする。
・Apple カタログ風のミニマルデザインを採用。
・フォントは BIZ UD ゴシックを基本とし、角丸は 2xl、影は最小限。

5.2　クラス構成規則
・クラスは論理ブロック単位で整理：
1.レイアウト（flex, grid, gap, items-center）
2.サイズ（w-, h-, p-, m-）
3.色・背景（bg-, text-, border-）
4.装飾（rounded-, shadow-, ring-）

<div className="flex items-center justify-between p-4 bg-surface shadow-sm rounded-2xl">

5.3　Design Tokens の利用
・/src/styles/tokens.css に定義されたトークンを使用する。
・色やフォントを直接指定しない（例：text-[#333] は禁止）。
・トークン例：text-primary, bg-surface, border-default, shadow-sm。

5.4　レスポンシブルール
・Tailwind のブレークポイント：sm, md, lg, xl を標準。
・レイアウト崩れが生じる場合は grid + auto-fit を優先使用。
・モバイルファースト設計。最小幅 320px で正常表示を保証。

5.5　共通UIコンポーネント規則
| コンポーネント          | 役割        | 命名例                    |
| ---------------- | --------- | ---------------------- |
| Header           | 共通ヘッダー    | `Header.tsx`           |
| Footer           | 共通フッター    | `Footer.tsx`           |
| LanguageSwitcher | 言語切替ボタン   | `LanguageSwitcher.tsx` |
| PrimaryButton    | 汎用ボタン     | `PrimaryButton.tsx`    |
| LayoutContainer  | ページレイアウト枠 | `LayoutContainer.tsx`  |

・共通コンポーネントは components/common 配下に配置。
・共通化基準：「2画面以上で再利用される場合」。
・コンポーネントのPropsは型安全を保証（汎用 variant / size / onClick 形式）。

5.6　アニメーション
・標準はFramer Motionを使用。
・0.2〜0.3秒のfade/slideを上限とし、派手な動きは禁止。
・アニメーションは利用意図をコメントで明示する。

5.7　アクセシビリティ
・すべてのボタンに aria-label を付与。
・フォーム要素にはラベルと入力補助（placeholder）を必ず設定。
・音声読み上げ（VoiceBox連携）対応タグを考慮。

5.8　禁止事項
・!important の使用。
・カラーコードの直書き。
・インラインスタイル (style={{...}}) の多用。
・外部CSSライブラリの導入（Material UI, Bootstrap 等）。
・クラス命名の略語 (btn-pri, hdr)。

5.9　推奨事項
・Tailwind クラス順序を統一。
・複数クラスはスペース区切りで可読性優先。
・複雑な構造は小コンポーネントへ分割。
・フォントサイズ・余白は Design Tokens に準拠。

## 第6章　Performance & Resource Management  
（パフォーマンス設計・メモリパージ・セッション管理）

---

### 6.1　目的
この章では、HarmoNet アプリケーションのパフォーマンス最適化、  
メモリリーク防止、Supabase 認証セッション管理の指針を定義する。  
UIレスポンスの軽量化とメモリ安全性を両立することを目的とする。

---

### 6.2　レンダリング最適化（React Performance）
| 項目 | 規則 |
|------|------|
| **再レンダー制御** | props/state は最小限に。再レンダーを伴う setState 呼び出しを制限。 |
| **メモ化** | `React.memo`, `useMemo`, `useCallback` を適切に使用し、同一関数インスタンスを維持。 |
| **キー指定** | リスト描画ではユニークキーを必須とし、index使用を禁止。 |
| **バーチャルリスト** | 大量データは `react-window` または `react-virtualized` を利用。 |
| **Suspense** | 非同期ロードコンポーネントに `Suspense` を設置。 |

---

### 6.3　非同期処理の最適化
- `Promise.all` による並列化を推奨。逐次 await 禁止（依存関係がある場合のみ許可）。  
- fetch 呼び出しには Supabase SDK または `useSWR` を使用。  
- API 応答が変わらない場合は `stale-while-revalidate` パターンでキャッシュ維持。  
- 不要なリクエストは AbortController で中断。  

```ts
const controller = new AbortController();
await fetch(url, { signal: controller.signal });
return () => controller.abort();

6.4　メモリパージ方針
React に明示的な GC は存在しないため、副作用のクリーンアップを徹底する。
| 対象                                 | パージタイミング       | 処理内容                            |
| ---------------------------------- | -------------- | ------------------------------- |
| タイマー (`setInterval`, `setTimeout`) | コンポーネントアンマウント時 | `clearInterval`, `clearTimeout` |
| WebSocket / EventSource            | 切断時            | `.close()`                      |
| API フェッチ                           | ページ切り替え時       | `controller.abort()`            |
| SWR / Cache                        | ログアウト・タブ離脱時    | `mutate(undefined)`             |
| State 配列                           | Unmount時       | `setData([])` または `null`        |

useEffect(() => {
  const socket = io("/realtime");
  socket.on("msg", handleMessage);
  return () => {
    socket.off("msg", handleMessage);
    socket.disconnect();
  };
}, []);

6.5　メモリ管理ルール
・useEffect の return 関数を必ず定義（return 省略禁止）。
・一度生成したリスナーはクリーンアップ時に解除。
・長時間放置される Timer や Subscriptions は必ず破棄。
・不要になった State は null または初期値に戻す。

6.6　Supabase セッション管理方針
・Supabase Auth による JWT セッションを採用。
・セッションは「認証と識別」のみに使用し、UI状態を保持してはならない。

6.6.1　セッションで保持する情報
| カテゴリ    | 保持内容                                    |
| ------- | --------------------------------------- |
| 認証情報    | access_token, refresh_token, expires_at |
| ユーザー情報  | user.id, user.email, user.role          |
| テナント情報  | tenant_id（ユーザー所属）                       |
| 言語設定    | locale (`ja`, `en`, `zh`)               |
| タイムスタンプ | last_login, last_active                 |

6.6.2　保持禁止情報
・パスワード、平文トークン
・UI 状態（開閉、入力中など）
・投稿・画像などの業務データ
・翻訳キャッシュ、管理者権限キャッシュ

6.7　セッション有効期間
項目	設定	備考
アクセストークン	1時間	Supabase標準。自動リフレッシュ有効。
リフレッシュトークン	7日間	期限切れ後は再ログイン要。
自動延長	有効	アクティブ操作中は自動更新。
無操作ログアウト	30分	Phase10で実装予定。

6.8　セッション制御の実装例
import { useSession } from "@supabase/auth-helpers-react";

const { session } = useSession();

useEffect(() => {
  if (!session) router.push("/login");
  else setUserContext({
    id: session.user.id,
    tenant_id: session.user.user_metadata.tenant_id,
    locale: session.user.user_metadata.locale
  });
}, [session]);

6.9　セッション破棄とメモリパージ
const handleLogout = async () => {
  await supabase.auth.signOut();
  clearUserCache();
  resetAppState();
};

6.10　セッションに関する禁止事項
| 禁止項目                      | 理由                 |
| ------------------------- | ------------------ |
| `localStorage` 直接操作       | Supabase SDK に任せる。 |
| トークンを URL や Cookie に埋め込む  | セキュリティリスク。         |
| Redux や Context にセッションコピー | 重複・不整合を招く。         |
| セッション更新時に再ログインを強制         | Supabase が自動管理する。  |

6.11　セッション管理まとめ
| 観点        | 方針                        |
| --------- | ------------------------- |
| セッション責任範囲 | 認証・識別・言語設定のみ              |
| 有効期間      | 1時間（更新自動）＋7日（リフレッシュ）      |
| 保存先       | Supabase 内部（localStorage） |
| 更新        | Supabase SDK 自動           |
| セキュリティ    | HTTPS必須・Cookie非使用         |
| 無操作破棄     | 30分無通信でサインアウト             |

6.12　AIエージェント運用補足
・Windsurf（実装AI）は Supabase セッション API を直接変更してはならない。
・Supabase Auth 関連コードに変更が必要な場合は
・// TODO: require auth change コメントで報告。
・セッション構造変更は設計層（タチコマ／Claude）で承認する。

6.13　要点まとめ
・パフォーマンス：メモ化・再レンダー抑制・非同期最適化。
・メモリ管理：副作用は必ずクリーンアップ関数でパージ。
・セッション：Supabase に一任し、アプリは監視に徹する。
・ログアウト＝完全リセット が原則。

## 第7章　コメント／ドキュメンテーション規約  
（Commenting & Documentation Rules）

---

### 7.1　目的
AI・人間問わず、コードの意図を正確に理解できるよう  
コメントは「理由」と「背景」を記述する。  
コードの説明（何をしているか）ではなく、**なぜそうしているか** を中心に残す。

---

### 7.2　コメント基本ルール
| 種類 | 書式 | 用途 |
|------|------|------|
| 単一行コメント | `//` | 処理の意図を簡潔に記載 |
| ブロックコメント | `/* ... */` | 補足説明・複数行注釈 |
| ドキュメントコメント | `/** ... */` | JSDoc 形式。関数・型・クラスに使用 |

---

### 7.3　JSDocフォーマット
```ts
/**
 * getBoardList
 * Fetch board posts for current tenant
 * @param tenantId - UUID of tenant
 * @returns Promise<Board[]>
 * @throws NetworkError
 */

・すべての公開関数・Hook・型に JSDoc を付与。
・AI エージェントが自動解析可能な英語記述を原則とする。
・@param, @returns, @throws を明記する。

7.4　ファイル先頭コメント
各ファイルの先頭には必ずメタ情報を記載する。
/**
 * File: BoardList.tsx
 * Description: Display list of posts in the board.
 * Created: 2025-11-06
 * Author: Windsurf (auto-generated)
 * Reviewed: Claude
 */

7.5　TODO／FIXMEコメント
| ラベル          | 意味         | 処理担当            |
| ------------ | ---------- | --------------- |
| `// TODO:`   | 未実装・追加検討箇所 | Windsurf／Claude |
| `// FIXME:`  | バグ・暫定処理    | Windsurf        |
| `// REVIEW:` | 設計確認・要承認   | Claude／タチコマ     |
| `// NOTE:`   | 記録的補足・仕様根拠 | 任意（保守目的）        |

7.6　自動ドキュメント生成

JSDoc は typedoc または tsdoc でHTML化可能な形式で記述。

API層は /01_docs/02_design/api-spec_latest.md に連携出力可能。

コメント文に日本語を混在させる場合は英訳を併記する。

7.7　コメント禁止事項

「何をしているか」だけを説明する冗長コメント

コードと乖離したコメントを放置

絵文字、全角スペース、顔文字の使用

実装コードのコピーをコメントとして残すこと

第8章　AIエージェント実行ポリシー

（AI Agent Execution Policy）

8.1　目的

AIエージェント（Windsurf・Claude・Gemini・タチコマ）が
HarmoNet のコード生成・整形・監査を行う際に遵守すべき実行ルールを定義する。

8.2　役割分担
| AIエージェント     | 主担当                        | 禁止事項               |
| ------------ | -------------------------- | ------------------ |
| **タチコマ**     | 規約策定・承認・最終整合               | コード自動生成            |
| **Claude**   | コード整形・規約準拠チェック・ChangeLog更新 | 実装推測での命名生成         |
| **Windsurf** | 実装生成・修正提案                  | 独自ディレクトリ作成・未定義命名使用 |
| **Gemini**   | 静的解析・品質監査                  | 外部APIやネットアクセス      |

8.3　エージェント実行ルール
1.実行前の確認
・Windsurfは作業前に必ず最新規約 (harmonet-coding-standard_latest.md) を参照する。
・未定義命名・ディレクトリ要求は // TODO: require name または // TODO: require directory を出力。

２．命名・構文
・命名はマトリクス参照必須。自動生成は禁止。
・非推奨構文（第3章 3.7参照）は検出時にClaudeへ報告。

3.出力形式
・コード出力時は Prettier 準拠で整形。
・ESLint 警告が出る構文は生成禁止。
・ファイル操作
・src 直下への新規ディレクトリ作成は禁止。
・既存構造に従い、共通部品は components/common/ に配置。

4.レビュー連携
・Windsurf の出力は Claude が整形確認し、Gemini が品質監査（BAG-lite）を行う。
・重大な構文逸脱は Claude が // REVIEW: コメントで報告。

8.4　AI間プロトコル
| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 命名・構文参照  | `harmonet-coding-standard_latest.md` |
| 設計情報参照   | `/01_docs/02_design/` 内の設計書群         |
| 監査結果保存   | `/01_docs/06_audit/` に自動格納           |
| ドキュメント反映 | Claude が自動反映後、TKDが最終承認               |

8.5　AI実行禁止事項
・未定義構造の自動生成（例：/src/temp/）
・未承認APIコールの挿入
・明示的なデータ削除（RLSに違反する処理）
・設計書外の命名・関数・クラス定義の生成
・人間承認なしでのマージ・自動コミット

8.6　AI実行安全化原則
・すべてのAI出力は再現性があり、人間が追跡可能であること。
・AI同士の出力差異は Claude が正準化し、Gemini が一貫性を検証する。
・Windsurf は決して「推測」で動作してはならない。

8.7　AI出力コメント例
// GENERATED BY WINDSURF
// TASK: Implement LoginForm component
// REVIEW: Claude required for props validation
// AUDIT: Gemini pending check

8.8　AI出力の署名
各AIが生成したコードはコメント内に署名を残すこと。
| AI       | 署名形式                       |
| -------- | -------------------------- |
| Windsurf | `// GENERATED BY WINDSURF` |
| Claude   | `// REVIEWED BY CLAUDE`    |
| Gemini   | `// AUDITED BY GEMINI`     |
| タチコマ     | `// APPROVED BY TACHIKOMA` |

8.9　運用補足

各AIが規約違反を検知した場合は即座に停止し、
タチコマへレポートを送信する。

AI出力が規約未更新状態で実行された場合、再生成を要求する。

AIが自動修正を行う場合も必ず // AUTO-FIX コメントを添付する。

8.10　まとめ
1.Windsurf：実装担当。自律生成禁止。
2.Claude：整形と規約適合。
3.Gemini：監査とBAG解析。
4.タチコマ：最終責任者・承認。
全AIはこの規約を共通言語とし、ファイル生成・命名・構文・ディレクトリ操作を統一基準で行う。

## 第9章　禁止事項一覧（Prohibited Practices）

---

### 9.1　言語レベルの禁止事項
| 項目 | 理由 |
|------|------|
| `var` 宣言 | スコープ汚染、再代入の危険 |
| `any` 型 | 型安全性を喪失 |
| `eval`, `Function()` | セキュリティリスク |
| `==` 比較 | 暗黙変換によるバグの温床 |
| DOM直接操作 | React仮想DOMを破壊 |
| JSX内匿名関数多用 | 不要な再レンダーを誘発 |
| `console.log` 残存 | デバッグ情報漏洩の恐れ |
| `with` 構文 | スコープ曖昧化、予測不能動作 |
| 未定義の命名利用 | AI整合性破壊 |

---

### 9.2　UI／スタイル禁止事項
| 項目 | 理由 |
|------|------|
| `!important` の使用 | スタイル優先度崩壊 |
| カラーコード直書き | Design Tokens破壊 |
| 外部UIライブラリ導入 | 統一デザイン方針と不整合 |
| インラインスタイル多用 | 再利用性と可読性の低下 |
| クラス略語命名 | 意図不明・検索困難 |

---

### 9.3　ディレクトリ操作禁止事項
| 操作 | 理由 |
|------|------|
| 新規トップ階層の作成 | 構成統一を崩壊させる |
| 管理外のフォルダ作成 (`tmp/`, `sandbox/`) | 追跡不能データの発生 |
| 構造改変の無断実施 | 他AIとの参照不整合 |
| ファイル削除の自動実行 | バージョン履歴の喪失 |

---

### 9.4　AI実行禁止事項
| 操作 | 理由 |
|------|------|
| 自動命名・推測生成 | 命名マトリクス不整合 |
| 設計書外の関数生成 | スキーマ逸脱リスク |
| 未承認APIコール | 安全性・監査性の欠如 |
| 機密情報アクセス | セキュリティポリシー違反 |
| 自動コミット／マージ | 人間承認プロセス違反 |

---

### 9.5　開発運用禁止事項
| 操作 | 理由 |
|------|------|
| `.env` ファイルの共有 | 機密漏洩リスク |
| 公開鍵・秘密鍵をコード埋め込み | セキュリティ重大違反 |
| 機能実装前のテストコードコミット | テスト環境混乱 |
| コードレビューを経ずに本番反映 | 品質保証プロセス違反 |

---

### 9.6　例外承認手続き
やむを得ず禁止事項に該当する操作を行う場合、  
タチコマが「例外承認申請書（exception-approval.md）」を生成し、  
承認履歴を `/01_docs/00_project/` に記録すること。  
一時的な許可であっても、必ずドキュメントに根拠を残す。

---

## 第10章　ChangeLog / メタ情報

---

### 10.1　文書情報
| 項目 | 内容 |
|------|------|
| Document Title | HarmoNet Coding Standard |
| Version | 1.1 |
| Category | /01_docs/03_rules |
| Author | タチコマ（Tachikoma, PMO） |
| Reviewers | Claude（整形）・Gemini（監査） |
| Approved by | TKD |
| Created | 2025-11-06 |
| Last Updated | 2025-11-06 |

---

### 10.2　ChangeLog
| Version | Date | Description | Author |
|----------|------|-------------|--------|
| v1.0 | 2025-11-06 | 初版作成。Phase9実装開始に伴うエージェント向け統一コーディング規約策定。 | タチコマ |
| v1.1 | 2025-11-06 | 補足追記。Phase9追記：Prisma明記・スコープ明示 | タチコマ |

---

### 10.3　後続更新予定
| 項目 | 予定Phase | 内容 |
|------|------------|------|
| v1.X | Phase10 | 無操作ログアウト・SWRキャッシュ再設計を反映 |
| v1.X | Phase11 | テスト設計規約（Unit/E2E）追加 |
| v2.0 | Phase12 | マルチテナント動的コンポーネント分離ポリシー導入 |

---

### 10.4　文書識別情報
**Document ID:** `HARMONET-CS-010-V1.0`  
**Supersedes:** None  
**Location:** `/01_docs/03_rules/harmonet-coding-standard_v1.1.md`

---

### 10.5　締めの声明
本規約は HarmoNet プロジェクト全AIおよび人間開発者が共有する唯一のコーディング基準である。  
この規約の改訂は必ず ChangeLog に記載し、  
全AIメンバ（タチコマ／Claude／Gemini／Windsurf）が参照可能な状態に保つこと。  

**「ルールは自由の敵ではなく、秩序の味方である。」**

---

**End of File**  
