# HarmoNet：Passkey 導入検討結果まとめ（サーバ構成・Corbado・Supabase 含む）

## 1. 検討背景

HarmoNet の認証方式はこれまで **MagicLink（メール）** を中心として設計されていた。しかし、近年の FIDO / WebAuthn 仕様の普及により、**Passkey（生体認証）** を初回ログインから利用する方式が主流となっている。これを受け、次の観点で検討を行った：

* Passkey の初回登録とログインの正しい動作モデル
* サーバレス構成（Vercel + Supabase）での Passkey 追加可否
* Corbado の役割とリスク
* Hanko / 自前サーバなど外部依存削減案
* 将来的に Supabase が Passkey をネイティブ実装する可能性

本ドキュメントでは、議論全体の内容を整理し、**HarmoNet の技術仕様としての正式な結論**を示す。

---

## 2. Passkey の動作原則（再確認）

Passkey は従来の「登録 → ログイン」という二段階モデルではなく、

**「初回登録」＋「ログイン」を同一操作で行う** 仕様である。

### 具体的挙動

* 登録済み Credential が無ければ → **新規登録（Create）**
* 登録済みなら → **認証（Get）**
* どちらも **ログイン画面上の同じボタン** で実行される

これにより「登録画面」は不要であり、UX は大幅に簡素化される。

HarmoNet の A-02（PasskeyAuthTrigger）はこの標準モデルに完全適合しているため、既存設計の構造変更は不要である。

---

## 3. サーバレス構成と Passkey

### 現行構成

* **Vercel**：Next.js フロント
* **Supabase**：DB、Auth（MagicLink）、Storage

### 課題

WebAuthn では以下の **RP（認証サーバ）機能**が必要：

* Challenge 生成
* Credential 登録処理
* 署名検証（Origin / RP ID）
* Token 発行

これらは一般的な Serverless（Vercel/Supabase Edge）では保持が難しく、**常駐 API サーバ**が前提となる。

→ そのため Passkey を自前実装するには **別サーバが必要**になる。

Supabase 自身は現時点でネイティブ WebAuthn を提供しておらず、将来の対応が期待される状況にある。

---

## 4. Corbado 導入の検討

### 利点

* Passkey 認証を即時利用可能
* Challenge / Credential / Token すべて Corbado 側で管理
* Supabase Auth との連携も提供
* サーバレス構成を維持可能

### 懸念

* 外部サービス依存（仕様変更・プラン変更・連携終了のリスク）
* 費用（Pro $149/月）
* Supabase が将来 Passkey を実装した場合に冗長化する可能性

### 結論

Corbado は **“Supabase が Passkey をネイティブ搭載するまでの暫定アダプタ”** として利用するのが最適。

* 実装コスト最小
* 運用コスト低い（無料枠運用も可能）
* 将来的に Supabase の Passkey へスムーズに置き換え可能

---

## 5. 自前サーバ（Hanko / 独自RP）案の検討

### メリット

* 外部サービス依存ゼロ
* 長期的には安全

### デメリット

* VPS 等で常時起動サーバが必要
* 鍵管理・RP 設定・セキュリティ対応の負荷
* Supabase が Passkey ネイティブ対応を開始した場合に再設計が必要

### 結論

**現時点では採用しない。**
Corbado → Supabase の流れが最も現実的であるため、自前RPを今用意するメリットは薄い。

---

## 6. HarmoNet における最終方針

### 6.1 技術方針

| 項目           | 方針                              |
| ------------ | ------------------------------- |
| Passkey 初回登録 | ログイン画面上の同一ボタンから実施（A-02）         |
| Passkey ログイン | 初回と同一UIで実施                      |
| MagicLink    | フォールバック（A-01）として継続              |
| サーバレス構成      | Vercel + Supabase のまま維持         |
| 外部サービス       | Corbado を暫定的に利用（無料枠中心）          |
| 将来的移行        | Supabase が Passkey を実装した時点で置き換え |

### 6.2 UI 方針

* **現行の 2 カードタイル構成はそのままでよい**
* 修正が必要なのは **Passkey ボタンの文言のみ**

  * 例：

    * 「Passkey を使う」
    * 「Passkey（生体認証）」
    * 「Passkey でログイン / 登録」

### 6.3 設計書への影響

* A-02（PasskeyAuthTrigger）内の文言説明修正のみ
* A-00 / A-01 / A-02 の構造・ロジックは変更不要

---

## 7. 最終結論

**HarmoNet の現行 Passkey 実装方針（MagicLink + Passkey 2タイル構成）は正しく、構造的な変更は一切不要である。**

* 誤解していたのは Passkey の「初回登録＝ログイン」モデルであり、構造ではない
* UI 文言および認知負荷の観点での微修正のみ必要
* Passkey 認証基盤は当面 Corbado に委譲し、Supabase に Passkey が追加され次第スムーズに移行可能
* インフラ構成はサーバレス（Vercel + Supabase）のまま維持できる

これにより、HarmoNet は **現行構成を維持したまま Passkey 導入が可能であり、長期運用におけるベンダーロックインリスクも最小限に抑えられる。**

---

以上。
