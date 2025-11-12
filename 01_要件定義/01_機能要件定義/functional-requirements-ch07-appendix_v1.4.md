# 第7章 付録・参照資料・リスク管理（v1.4）

本章は **HarmoNet Technical Stack Definition v4.1** に準拠する。
本ドキュメント群は、HarmoNet開発全体の整合性・保守性・監査性を保証するための最終リファレンスを構成する。

---

## 7.1 用語集

| 用語                          | 説明                                                                            |
| --------------------------- | ----------------------------------------------------------------------------- |
| **HarmoNet**                | 地域コミュニティ支援アプリ。住民・管理組合・管理会社の三者連携を支援する情報共有OS。                                   |
| **Supabase Cloud**          | PostgreSQL + Auth + Storage + Edge Functionsを統合したクラウドBaaS。RLSとJWTでマルチテナントを実現。 |
| **Corbado SDK**             | Passkey / WebAuthn 認証を提供する公式認証SDK。`@corbado/react` / `@corbado/node` で構成。     |
| **Magic Link**              | メールワンクリックによるパスワードレスログイン方式。Supabase Authが提供。                                   |
| **JWT（JSON Web Token）**     | SupabaseおよびCorbadoが発行する署名付きトークン。`tenant_id` / `role` / `lang` を含む。            |
| **StaticI18nProvider**      | HarmoNet独自の静的翻訳コンテキスト。JSON辞書 + Redisキャッシュ構成。                                  |
| **Redis Cluster**           | 翻訳キャッシュ・音声キャッシュ・セッション管理に使用する分散インメモリDB。                                        |
| **Edge Functions**          | Supabaseのサーバレス実行環境。翻訳・音声・AI連携処理を分散実行。                                         |
| **VOICEVOX API**            | 音声読み上げAPI。Supabase Edge `/api/tts` 経由で呼び出される。                                 |
| **Tachikoma（タチコマ）**         | GPT-5ベースのAI PMO。要件・設計・整合性統合を担当。                                               |
| **Gemini**                  | ロジック検証とLint整合を担当する品質保証AI。                                                     |
| **Windsurf**                | コード生成と自己採点・テスト自動化を行う実装AI。                                                     |
| **AI統合アジャイル**               | HarmoNet特有のAI連携開発方式。タチコマ・Gemini・Windsurfが連携して設計〜実装〜検証を完結させる。                  |
| **RLS（Row Level Security）** | Supabase PostgreSQLの行レベルセキュリティ。`tenant_id`でデータ分離。                             |
| **short_session Cookie**    | Corbadoが発行するセッションCookie。Secure + Lax設定でブラウザ認証維持を行う。                           |
| **Vercel CI/CD**            | GitHub連携による自動ビルド・ロールバック構成。                                                    |

---

## 7.2 関連ドキュメント

| ドキュメント名                                                    | 概要                                 | 格納先                                    |
| ---------------------------------------------------------- | ---------------------------------- | -------------------------------------- |
| **harmonet-technical-stack-definition_v4.1.md**            | 技術基盤仕様（Supabase Cloud + Corbado構成） | `/01_docs/01_requirements/00_project/` |
| **harmonet-detail-design-agenda-standard_v1.0.md**         | 詳細設計共通アジェンダ                        | `/01_docs/04_詳細設計/`                    |
| **functional-requirements-ch01-document-scope_v1.4.md**    | 機能要件総論・範囲定義                        | `/01_docs/01_requirements/01_機能要件定義/`  |
| **functional-requirements-ch02-system-overview_v1.4.md**   | システム全体構成・AI体制                      | `/01_docs/01_requirements/01_機能要件定義/`  |
| **functional-requirements-ch04-nonfunctional-req_v1.4.md** | 非機能要件（セキュリティ・性能）                   | `/01_docs/01_requirements/01_機能要件定義/`  |
| **functional-requirements-ch05-config-env_v1.5.md**        | 外部API・認証・環境変数構成                    | `/01_docs/01_requirements/01_機能要件定義/`  |
| **harmonet-security-spec_v4.1.md**                         | セキュリティ・Cookie・暗号化仕様                | `/01_docs/00_project/`                 |

---

## 7.3 外部サービス・API一覧（v4.1準拠）

| サービス                                | 用途                             | プラン      | 備考                           |
| ----------------------------------- | ------------------------------ | -------- | ---------------------------- |
| **Supabase Cloud**                  | DB・Auth・Storage・Edge Functions | Pro      | PostgreSQL 17.6 + RLS適用      |
| **Corbado Cloud**                   | Passkey / WebAuthn認証基盤         | Standard | short_session Cookie + JWT連携 |
| **Redis Enterprise**                | 翻訳・音声キャッシュ                     | Free〜Pro | Supabase Edgeと統合運用           |
| **Google Cloud Translation API v3** | 自動翻訳                           | Standard | StaticI18nProvider経由呼出       |
| **VOICEVOX API**                    | 音声変換（TTS）                      | Free     | Supabase `/api/tts` ラップ実装    |
| **Cloudflare CDN**                  | 静的ファイル・画像配信                    | Free     | Tailwind最適化配信構成              |
| **Sentry**                          | エラー監視                          | Pro      | Vercel + Supabase連携          |
| **UptimeRobot**                     | 稼働監視                           | Free     | 3分間隔監視                       |
| **Gemini API / Windsurf Agent**     | AI品質検証・自己採点・自動修正               | Internal | AI統合アジャイル専用構成                |

---

## 7.4 リスク管理（カテゴリ別）

| リスクカテゴリ           | 内容                         | 発生確率 | 影響度 | 対応策                           |
| ----------------- | -------------------------- | ---- | --- | ----------------------------- |
| **認証／Corbado**    | Cookie期限切れ・ブラウザ間セッション不一致   | 中    | 中   | 自動再ログインと短期Cookie更新ジョブを実装      |
| **Supabase依存**    | サービスダウン・メンテナンスによる一時停止      | 低    | 高   | 日次バックアップ＋RLS再検証スクリプト運用        |
| **Redisキャッシュ不整合** | 翻訳・音声キャッシュ欠損／TTL設定誤り       | 中    | 低   | キャッシュ自動リフレッシュ機構を採用            |
| **AI整合性崩壊**       | タチコマ／Gemini／Windsurf間の出力差異 | 中    | 中   | CodeAgent_Reportによる自己採点・自動再整合 |
| **翻訳API上限超過**     | 月間文字数制限（50万文字）超過           | 低    | 中   | Redisキャッシュ／トークン分割管理           |
| **利用者UX低下**       | 通知過多・遅延表示によるストレス           | 中    | 中   | Realtimeサブスク管理・UI軽量化          |
| **テナントデータ競合**     | 同一tenant_idでの同時更新競合        | 低    | 高   | Prismaトランザクション整合制御            |
| **AI生成誤情報**       | Windsurf出力内容が仕様と乖離         | 中    | 中   | Gemini監査＋手動レビュー承認必須化          |
| **セキュリティ侵害**      | JWT漏洩／トークン改ざん              | 低    | 高   | Corbado署名検証＋Supabaseローテーションキー |
| **法令／PIPA対応**     | 個人情報保護法・GDPR要件不履行          | 低    | 高   | 年次監査・データ削除自動化ポリシー             |

---

## 7.5 文書承認

| 役割            | 氏名        | 承認日        |
| ------------- | --------- | ---------- |
| プロジェクトオーナー    | TKD       | 2025-11-12 |
| PMO / AI統合責任者 | Tachikoma | 2025-11-12 |
| 開発リードAI       | Windsurf  | 2025-11-12 |

---

## 7.6 変更履歴

| バージョン    | 日付             | 変更内容                                                        | 作成者                 |
| -------- | -------------- | ----------------------------------------------------------- | ------------------- |
| v1.0     | 2025/10/26     | 初版作成                                                        | TKD                 |
| v1.2     | 2025/10/30     | Supabase／RLS対応、Phase拡張                                      | Tachikoma           |
| v1.3     | 2025/10/31     | Technical Stack v3.2準拠化                                     | GPT署名               |
| **v1.4** | **2025/11/12** | **技術スタックv4.1対応。Corbado・Supabase Cloud構成に統一。AI統合体制・リスク再定義。** | **Tachikoma / TKD** |

---

### 7.7 注意事項

本書は HarmoNet プロジェクトにおける正式な参照資料であり、
AI開発体制（タチコマ・Gemini・Windsurf）およびTKD承認の下で運用される。
無断複製・配布を禁止し、外部開示は認められない。

---

*by Tachikoma (HarmoNet PMO AI)*
**（End of Chapter 7 – v4.1準拠版）**
