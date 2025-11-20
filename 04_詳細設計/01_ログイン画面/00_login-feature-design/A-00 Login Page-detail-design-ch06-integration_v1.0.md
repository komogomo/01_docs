# A-00 LoginPage 詳細設計書 ch06：結合構成（Integration） v1.0

**Document ID:** HARMONET-A00-CH06-INTEGRATION**
**Version:** 1.0
**Status:** MagicLink専用・実装準拠

---

# 第1章：目的

本章は **A-00 LoginPage** における **結合構成（Integration Layer）** を定義する。
UIレイアウト、共通部品（C-01/C-02/C-04）、A-01 MagicLinkForm、A-03 AuthCallbackHandler が **どのように結合され、整合を保って動作するか** を明確化する。

LoginPage は認証ロジックを持たないため、本章は **構造・依存・結合ポイントの設計** に専念する。

---

# 第2章：構造結合（Component Integration）

LoginPage は以下 3 コンポーネントで構成される：

```
AppHeader (C-01)
MagicLinkForm (A-01)
AppFooter (C-04)
```

## 2.1 結合構造（Mermaid）

```mermaid
graph TD
  A[LoginPage (A-00)] --> B[AppHeader (C-01)]
  A --> C[MagicLinkForm (A-01)]
  A --> D[AppFooter (C-04)]
```

## 2.2 結合方針

* AppHeader/AppFooter は **固定配置（top/bottom）**
* MagicLinkForm は中央カード内に配置し、**UI責務は完全委譲**
* LoginPage は **Props を渡さず**、A-01 は内部状態のみで完結
* Layout.tsx で StaticI18nProvider をラップし、言語切替は全体統制

---

# 第3章：A-01 MagicLinkForm との結合

LoginPage の中心機能は **MagicLinkForm の UI 受け皿となること**。

## 3.1 受け取る情報

| 種別   | 内容                                       |
| ---- | ---------------------------------------- |
| 状態   | idle / sending / sent / error_* （A-01発行） |
| 表示文言 | A-01 が翻訳したメッセージ（LoginPageは反映のみ）          |

## 3.2 LoginPage 側の責務

* `login-status` 領域に **成功/失敗メッセージを表示**
* MagicLinkForm のフォーム表示を **レイアウトとして包むだけ**

## 3.3 禁止事項

* A-01 のロジックに介入しない
* Props 追加禁止（A-01 の独立性を守る）
* MagicLink 発火後の遷移制御を A-00 で行わない

---

# 第4章：AppHeader / AppFooter との結合

## 4.1 Header（C-01）

* 言語切替（C-02 LanguageSwitch）を内包
* LoginPage は variant="login" のみ使用
* 固定表示であり MagicLinkForm とは完全分離

## 4.2 Footer（C-04）

* コピーライトのみ表示
* 固定表示であり UI 結合は薄い（視覚配置のみ）
* セッション状態や認証結果には依存しない

---

# 第5章：画面遷移との結合（A-03 AuthCallbackHandler）

MagicLink の認証成立は **/auth/callback（A-03）が担当**。
LoginPage はセッション判定を一切行わない。

```
/login  →  MagicLinkForm が OTP送信
/auth/callback  →  PKCEにより Supabase セッション確立
/mypage  →  認証後の画面
```

LoginPage は **認証後に再表示されない前提** で設計される。

---

# 第6章：DB（Supabase）との結合ポイント

LoginPage 自身は DB にアクセスしないが、MagicLink 認証後、
**DB 側で必ず満たすべき整合条件** をここに定義する。

## 6.1 必須DB整合条件

* `auth.users.id` = `public.users.id`（トリガにより自動同期）
* `user_tenants` に該当ユーザーの active 行が存在する
* RLSは `auth.jwt() ->> 'sub'` により public.users.id と一致

## 6.2 トリガ（DB側）の設計（A-00 参照用）

ログイン成功後のアプリ利用には、次のトリガが必要となる：

### ① auth.users → public.users 自動同期トリガ

```
CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    created_at,
    updated_at,
    status,
    language
  ) VALUES (
    NEW.id,
    NEW.email,
    now(),
    now(),
    'active',
    'ja'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### ② トリガ定義

```
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE handle_new_auth_user();
```

※ LoginPage 自身はこのトリガを呼び出さず、**DB整合用の前提条件として参照するだけ**。

---

# 第7章：Windsurf 実装時の結合注意点

* LoginPage は **UIコンテナのみ編集対象**
* MagicLinkForm / AuthCallbackHandler / DB トリガは **別タスク**
* import パスの統一：
  `@/src/components/common/*` / `@/src/components/auth/*`
* 画面遷移（/auth/callback / /mypage ）は A-03 が担当

---

# 第8章：改訂履歴

| Version | Summary                                              |
| ------- | ---------------------------------------------------- |
| v1.0    | MagicLink 用 Integration 章として新規作成。Passkey 系要素は一切含まない。 |

---

**End of Document**
