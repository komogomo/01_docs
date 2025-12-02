# HarmoNet クラウド移行計画（Vercel / Supabase / 各種API / GitHub）草案 v0.1

## 0. 位置付け

本書は、HarmoNet をローカル開発環境から Vercel / Supabase クラウドへ移行する際の「費用と構成・移行手順」の草案である。

* 最終品質レビュー: Antigravity / Gemini Pro 3.0
* 対象範囲:

  * Vercel（アプリ本番・UAT/デモ環境）
  * Supabase（UAT+デモ / 本番の 2 プロジェクト）
  * GitHub Team
  * ドメイン・証明書
  * 各種 API（翻訳・音声合成・メール）
* 目的:

  * ラフなインフラ・API コストを数値化し、事業計画・予算検討のたたき台とする
  * UAT → 本番 → デモ/セールス利用まで見据えた環境構成の方向性を固める

---

## 1. 環境構成（ロールの整理）

### 1-1. 環境一覧

1. **開発環境（Developer）**

   * ローカル PC + Supabase ローカル（Docker）
   * 目的: 実装・デバッグ・PoC
   * コスト: 0 （クラウド観点）

2. **検証/UAT + デモ/セールス環境（Supabase-UAT+Demo / Vercel-UAT）**

   * Supabase: Pro プロジェクト 1つ（UAT+デモ兼用）
   * Vercel: UAT/デモ用 Project
   * 目的:

     * 初期テナントのユーザ習熟（UAT）
     * UAT 完了後はデモサイトとして営業・販促で利用
   * データ: サンプル / デモ用データのみ（本番個人情報は持たない）

3. **本番環境（Supabase-Prod / Vercel-Prod）**

   * Supabase: Pro プロジェクト 1つ（本番専用）
   * Vercel: 本番用 Project
   * 目的: 実際の入居者・管理組合による利用
   * ポリシー: 障害時は「別 DB / 別 Project を新規に起こして dump/restore → env 切替」で復旧

---

## 2. Supabase 構成とコスト試算

### 2-1. Supabase プランとインスタンス

参照情報（2025-04 時点）:

* Free プラン: プロジェクト 2つまで / Micro インスタンス / 小容量（開発・検証向き）
* Pro プラン: **$25/月** で 8GB DB / 100GB ストレージ / 100K MAU / 250GB egress 等、$10/月分の compute credit 付き（Micro 1台分相当）。
* Compute インスタンス例（Pro プラン上）:

  * Micro: **$10/月**, 2-core ARM, 1GB RAM
  * Small: **$15/月**, 2-core ARM, 2GB RAM
  * Medium: **$60/月**, 2-core ARM, 4GB RAM

（上記は公式 Pricing と 2025年時点の解説記事を合成したレンジベースの整理。）

### 2-2. HarmoNet での前提

* Supabase Pro 組織 1つを契約。
* プロジェクト構成:

  * **Project-UAT+Demo**: Pro プロジェクト（Micro インスタンス）
  * **Project-Prod**: Pro プロジェクト（Small インスタンスから開始）
* Free プランの 2 プロジェクト枠は「遊び場・一時検証」に限定し、ビジネス運用はすべて Pro プロジェクト上で行う。

### 2-3. 月額・年額コスト試算（Supabase 部分）

#### パターンA: 初期フェーズ（テナント 1〜2 / アクセス少なめ）

前提:

* UAT+Demo: Micro インスタンス
* Prod: Small インスタンス
* Pro プラン: $25/月（$10 分の compute credit 込）

ラフ試算（USD, 1USD=150円で換算）:

* Pro プラン基本料: $25
* Compute:

  * Micro: $10 → credit でほぼ相殺
  * Small: $15
* Storage / egress 超過分: 初期はごく小さいと仮定し、+ $5 をバッファとして計上

**合計（初期フェーズ）**:

* $25 + $10 + $15 + $5 ≒ **$55/月**
* 円換算: **約 8,250 円/月**, **約 99,000 円/年**

（実際には compute credit の使われ方次第で数ドル前後する想定。）

#### パターンB: テナント増加・アクセス増加後（本番スケールアップ）

前提:

* UAT+Demo: Micro のまま
* Prod: Medium インスタンスへ格上げ

ラフ試算:

* Pro プラン基本料: $25
* Compute:

  * Micro: $10 → credit で相殺
  * Medium: $60
* Storage / egress 超過: +$10（テナント数増加を加味）

**合計（スケール後）**:

* $25 + $10 + $60 + $10 ≒ **$105/月**
* 円換算: **約 15,750 円/月**, **約 189,000 円/年**

※ 上記はいずれも「アーキ設計の判断用の目安」であり、実際の請求は Supabase ダッシュボードの Usage から継続監視が必要。

---

## 3. Vercel 構成とコスト

### 3-1. プラン

* **Vercel Pro プラン**

  * $20/月 のクレジットを含むチームプラン。
  * クレジットは Edge / Function / Bandwidth 等に柔軟に利用可能。
  * Pro メンバー数に応じて課金（ここでは 1メンバー前提で計算）。

### 3-2. 環境ごとの Project

* **Vercel-Prod**

  * HarmoNet 本番アプリ。
  * カスタムドメイン（`harmonet.com` 仮）を割り当て。

* **Vercel-UAT**

  * UAT/デモ環境。
  * 別ドメイン or サブドメイン（`uat.harmonet.com`, `demo.harmonet.com` 等）を割り当て。

静的コンテンツ主体＋軽量 API であり、Pro の included リソース内に収まる想定。

### 3-3. 月額・年額コストの目安

* Pro（1メンバー）: **$20/月**

  * 円換算: 約 **3,000 円/月**, **36,000 円/年**
* Bandwidth / Edge / Functions の超過が大きくならない限り、追加数ドル〜数十ドルの範囲で収まる見込み。

---

## 4. GitHub Team コスト

* プラン: **GitHub Team**
* 料金: **$4/ユーザ/月**（年払い時）
* 前提: 開発メンバー 1 名（当面）

→ 月額: $4, 年額: $48
→ 円換算: 約 **600 円/月**, **7,200 円/年**

将来開発メンバーが増えれば、人数に比例して線形に増加。

---

## 5. ドメイン・証明書

### 5-1. ドメイン

* レジストラ候補: バリュードメイン等の国内レジストラ
* 例: `.com` ドメイン

  * 初年度: 1,000 円前後
  * 2年目以降: 1,800〜2,500 円/年 程度を目安

（実際の候補ドメイン名を決めた段階で確定見積り要。）

### 5-2. SSL 証明書

* Vercel にカスタムドメインを設定すると、**Let’s Encrypt による証明書が自動発行される**。
* 追加の証明書費用: **0 円**
* 独自証明書アップロードは Enterprise レベルの機能であり、HarmoNet 初期フェーズでは不要とする。

---

## 6. 外部 API コスト試算

### 6-1. 翻訳（Google Cloud Translation API 前提）

前提（NMT 標準モデル）:

* 500,000 文字/月までは無料枠
* その後は **約 $20/100万文字** 前後の従量課金

HarmoNet 初期運用の想定（例）:

* 掲示板投稿: 1件あたり 2,000 文字 × 月 300件 = 600,000 文字/月
* 施設予約関連: メッセージは短く、合計 100,000 文字/月 未満
* 合計: **70万文字/月 程度**

→ 無料枠 50万文字を超える 20万文字分に対し、

* 0.2M × $20/M ≒ **$4/月**
* 円換算: **約 600 円/月**, **7,200 円/年**

※ 翻訳キャッシュ実装により、再翻訳回数が減るため、実際の請求はさらに低い可能性あり。

### 6-2. 音声合成（Google Cloud Text-to-Speech 前提）

前提（標準/WaveNet 併用）：

* WaveNet/Standard ボイスの一部には、月あたり数百万文字までの無料枠が存在（標準ボイスは最大 400万文字程度無料、それ以降は $4/100万文字〜）。

HarmoNet 初期運用の想定:

* 音声読み上げ対象: 掲示板本文のみ
* 1記事あたり 1,000〜2,000 文字、月 200記事が聴取されると仮定 → 約 30万文字/月

→ 無料枠内に収まる可能性が高く、超過したとしても：

* 0.3M × $4/M ≒ **$1.2/月**（標準ボイスの場合）
* 円換算: **約 180 円/月**, **2,160 円/年**

※ 実際にはキャッシュ済み音声の再利用や利用率により、ほぼ $0 に近い月も想定される。

### 6-3. メール（SMTP / Supabase 経由）

Supabase クラウドでは、Auth メール送信に外部メールプロバイダ（Resend 等）連携が推奨される構成になっているため、以下を前提とする。

* 候補: Resend
* 料金例（参考レンジ）:

  * 月 3,000 通程度までは無料 / 低額プラン
  * それ以上は **$20〜$30/月** のプランで数万通/月程度カバー可能

HarmoNet 初期運用の想定:

* MagicLink ログインメール: 1ユーザ 1〜2通/日 程度
* 予約前日通知メール: 1予約 1通
* その他通知メール: 初期は限定的

合計で **月数百〜1,000 通程度** であれば、無料枠〜低額プランに収まると想定。

試算としては、バッファ込みで:

* メール API コスト: **$5/月**
* 円換算: **約 750 円/月**, **9,000 円/年**

### 6-4. 各種 API コストのまとめ

初期フェーズのざっくり試算（USD → JPY）：

* 翻訳 API: 約 **$4/月**（600 円/月）
* 音声 TTS: 約 **$1〜2/月**（200 円/月）
* メール API: 約 **$5/月**（750 円/月）

**合計（API 部分）** ≒ **$10〜11/月**（約 1,500〜1,650 円/月）

---

## 7. 総コスト試算（初期フェーズ）

前提: Supabase = パターンA（Prod Small, UAT Micro）

* Supabase: 約 **$55/月**（約 8,250 円/月）
* Vercel Pro: **$20/月**（約 3,000 円/月）
* GitHub Team（1ユーザ）: **$4/月**（約 600 円/月）
* ドメイン: 年額 ~2,000円 → 月換算 ~170円（約 0.2 千円/月）
* 各種 API（翻訳/音声/メール = Google Cloud Translation + TTS + Resend Free枠内想定）: **$0〜11/月**（最大でも約 1,650 円/月）

**USD ベース合計（最大側）**: 約 **$90/月**
→ 円換算（1USD=150円）: **約 13,500〜14,000 円/月**

年額換算: **約 16〜17 万円/年**

※ Supabase の compute credit の使われ方、Translation/TTS/Resend の実利用量により ±20〜30% 程度の変動余地あり。

---

## 8. 移行手順（概要）

詳細な実行手順は別の「移行実行手順書」で分割する前提で、ここでは大枠のみ列挙する。

### 8-1. Supabase 移行（ローカル → UAT → Prod）

1. **Supabase Pro 組織作成**
2. **Project-UAT+Demo 作成**

   * DB バージョン・リージョン選択
   * スキーマ / RLS / 拡張を適用
   * `seed.ts` をクラウド用に調整（Antigravity 担当）
   * 初期テナント + デモ用データ投入
3. **Project-Prod 作成**

   * UAT で確定したスキーマ・RLS をそのまま適用
   * 本番用 seed（初期テナント・管理者ユーザのみ）投入
4. **Storage バケット・Auth 設定**

   * 掲示板添付・施設添付向けバケットを作成
   * Auth メール設定（外部メール API: Resend 連携）
5. **Edge Functions / Scheduler の下準備**

   * 予約前日通知・データ物理削除の関数を設計

### 8-2. Vercel 移行

1. GitHub リポジトリを Vercel と接続
2. `main` / `uat` ブランチに応じて、それぞれ Vercel-Prod / Vercel-UAT に自動デプロイ
3. Vercel の環境変数に Supabase-UAT / Prod の接続情報を設定
4. カスタムドメインを割り当て（本番 / UAT / デモ）

### 8-3. `.env` / `.env.local` 設定

* 必須キー例:

  * `NEXT_PUBLIC_SUPABASE_URL`
  * `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  * `SUPABASE_SERVICE_ROLE_KEY`
  * `NEXT_PUBLIC_APP_BASE_URL`
  * `GOOGLE_TRANSLATE_API_KEY`（またはサービスアカウント JSON）
  * `GOOGLE_TTS_API_KEY`
  * メール API トークン（Resend 等）

* 確認方法:

  * Supabase: Project Settings → API
  * Vercel: Project Settings → Environment Variables
  * Google Cloud: Credentials / Service Accounts

---

## 9. 追加実装が必要な機能（クラウド前提での整理）

### 9-1. 期日経過後の物理削除

1. 対象データ

   * 掲示板投稿（本文・コメント・添付を含む）
   * 施設予約（予約・キャンセル・履歴）

2. 追加カラム・設定

   * テナント設定:

     * `board_data_retention_years` / `board_data_retention_months`
     * `facility_data_retention_years` / `facility_data_retention_months`
   * 掲示板 / 施設予約テーブル:

     * `deleted_at` / `archived_at` を明示化（論理削除）

3. 削除ロジック

   * Supabase Edge Function + Scheduler（1日1回）
   * 手順:

     1. テナントごとに保持期間設定を取得
     2. `created_at` / `archived_at` から保持期限を計算
     3. 期限経過レコードを物理削除
   * ログ: 削除件数を Audit テーブル or Supabase Logs に記録

### 9-2. SMTP メール連携

* 機能対象:

  * MagicLink 送信メール
  * 施設予約前日通知メール
  * 必要に応じて掲示板通知メール

* 設計方針:

  * Supabase Auth のメール機能 + 外部メール API（Resend）を組み合わせる
  * テナントごとに通知 ON/OFF 設定を持たせる（特に前日通知）

### 9-3. 施設予約前日通知

* バッチ仕様（案）:

  * 実行タイミング: 毎日 9:00（タイムゾーン: Asia/Tokyo）
  * 対象予約:

    * `status = confirmed`
    * `reservation_date = 翌日`
  * メール内容:

    * 施設名、利用日時、利用者名、キャンセルポリシー等

### 9-4. HarmoNet WEB サイト

* 別 Vercel Project として構築（マーケティングサイト）
* 静的コンテンツが中心で DB 依存は薄いため、

  * Supabase は使わない / もしくは Free プロジェクトで問い合わせフォームのみ利用 など柔軟に選択可能
* 成果として:

  * デモ環境（UAT+Demo）へのリンク
  * 管理組合向けの導入案内・料金ページ
* 費用扱い:

  * ホームページ用 Project も、Vercel Pro の 1アカウント内で運用する前提とし、
    追加料金は「Vercel Pro: $20/月」に含めて本書の試算に計上する。

---

## 10. 今後のタスク整理（草案レベル）

1. Supabase / Vercel / GitHub / ドメイン / API の **正確な最新単価の再確認**
2. 上記前提をもとにした「正式版 移行計画書」の作成
3. Supabase UAT/Prod Project の実際の作成と、スキーマ・seed.ts 適用手順書（Antigravity 担当）の詳細化
4. 期日経過後物理削除・前日通知バッチの詳細設計書作成
5. HarmoNet WEB サイト（マーケ用）の要件定義と構造設計

（本書はあくまで草案であり、Antigravity / Gemini Pro 3.0 によるレビューを経て、数値・章立て・記述レベルを正式版に引き上げる。）
