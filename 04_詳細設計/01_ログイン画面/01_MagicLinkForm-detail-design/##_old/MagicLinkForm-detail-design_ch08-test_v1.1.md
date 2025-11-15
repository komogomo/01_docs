# MagicLinkForm 詳細設計書 - 第8章：監査・保守設計（v1.1）

**Document ID:** HARMONET-COMPONENT-A01-MAGICLINKFORM-CH08
**Version:** 1.1
**Supersedes:** v1.0（Phase9構成）
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 承認提案版（Corbado統合対応・監査運用拡張）

---

## 第8章 監査・保守設計

### 8.1 概要

MagicLinkForm (A-01) の監査・保守設計は、**Supabase（メールリンク認証）** と **Corbado（Passkey認証）** の両方を統合監視し、認証ログ・障害検知・運用体制を包括的に管理する。
Phase9 では、Supabase Audit Schema を中核としつつ、Corbado API ログを暗号化保存し、WebAuthn 認証フローの可視化・分析を可能にする。

---

### 8.2 監査方針

* **対象範囲**：メール送信イベント、Passkey認証結果、Supabase・Corbado API応答、Rate制限、管理操作。
* **目的**：認証成功率／拒否率／API異常検出／パフォーマンス劣化を早期に把握。
* **設計原則**：

  * PII情報はすべてハッシュ化（masked_email / hashed_user_id）。
  * Supabase と Corbado 双方のイベントを統一スキーマで記録。
  * UTC基準でログ整合性を維持。
  * 外部ログ送信時は JSON 署名付きで改ざん検知。

---

### 8.3 ログ構造定義

```sql
CREATE TABLE audit_auth_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id text NOT NULL,
  user_identifier text NOT NULL, -- hashed_email or corbado_id
  mode text CHECK (mode IN ('magiclink','passkey')),
  result text CHECK (result IN ('success','fail','denied')),
  error_code text,
  ip_address text,
  user_agent text,
  latency_ms int,
  created_at timestamptz DEFAULT now()
);
```

| 項目                     | 説明                          | 区分        |
| ---------------------- | --------------------------- | --------- |
| tenant_id              | 操作テナント識別子                   | 機密（RLS制御） |
| user_identifier        | ハッシュ化メールまたは Corbado ユーザーID  | 匿名化PII    |
| mode                   | 認証方式（magiclink / passkey）   | 統計分析用     |
| result                 | 成否（success / fail / denied） | 成功率監視     |
| error_code             | Supabase/Corbado返却コード       | 技術分析用     |
| latency_ms             | API応答時間（ms）                 | パフォーマンス監視 |
| ip_address, user_agent | 攻撃検知分析                      | 90日保持     |
| created_at             | UTCタイムスタンプ                  | 監査基準時間    |

---

### 8.4 監査ログ運用

| 種別          | 保存先                       | 保存期間 | 備考                    |
| ----------- | ------------------------- | ---- | --------------------- |
| 認証イベント      | Supabase audit schema     | 1年   | MagicLink / Passkey共通 |
| Passkey認証ログ | Corbado API + S3暗号化       | 1年   | API署名付きで非改ざん保証        |
| エラーログ       | Supabase Storage / Sentry | 1年   | SDKバージョン別に区分保存        |
| Rate制限      | WAF + Supabase Edge Log   | 90日  | 攻撃傾向分析用               |
| 管理操作        | Admin Portal Audit        | 1年   | 監査追跡                  |

* Supabase → GCP Cloud Logging へ転送、Corbado Logs は AES256暗号化後にS3へ同期。
* Corbado側API応答の `trace_id` をSupabaseログに紐付けてトレース可能化。

---

### 8.5 保守運用体制

| 項目   | 内容                                |
| ---- | --------------------------------- |
| 運用責任 | HarmoNet PMO（セキュリティ監査責任者）         |
| 対応時間 | 平日9:00〜18:00（Critical時24h）        |
| 監視頻度 | 5分間隔でSupabase / Corbado両ログを監視     |
| 通知方法 | Slack + PagerDuty（Critical時）      |
| 障害分類 | Corbado / Supabase / ネットワーク / その他 |

* Corbado障害時は即座に MagicLinkへフォールバック。
* Supabase異常時は送信処理を停止し、管理者へ自動通知。
* WebAuthn関連APIの停止は `AUTH_DISABLED=true` フラグにより全テナント即停止。

---

### 8.6 定期メンテナンス項目

| 区分      | 項目                          | 内容                    | 頻度  |
| ------- | --------------------------- | --------------------- | --- |
| バージョン管理 | Supabase SDK / Corbado SDK  | 最新安定版適用               | 月次  |
| 認証構成    | MagicLink / Passkey両動作確認    | `/auth/callback` 動作検証 | 月次  |
| Secrets | Supabase / Corbado APIキー再発行 | Vaultに自動保存            | 半期  |
| 監査DB    | audit_auth_events 最適化       | パーティション分割・古ログ圧縮       | 四半期 |
| パフォーマンス | Corbado API遅延検知             | SLA 500ms超過アラート       | 週次  |
| テナント設定  | passkey_enabled 整合          | 設定誤差検出・修正             | 四半期 |

---

### 8.7 インシデント対応フロー

```mermaid
flowchart TD
  A[異常検知] --> B{重大度判定}
  B -->|Supabase障害| C[ログ送信停止・再試行制御]
  B -->|Corbado障害| D[Passkey認証を一時停止→MagicLinkへ切替]
  B -->|ネットワーク障害| E[再送リトライ + 監視保持]
  B -->|重大(Critical)| F[PMO緊急通知 + エスカレーション]
  F --> G[根本原因分析 + 再発防止策]
```

**報告書テンプレート**：

* 発生日／影響範囲／担当者／暫定対応／恒久対策
* Supabase / Corbado / UI層 の責任分界点を明示。
* 再発防止策には SDK バージョン固定・自動監視改善を含める。

---

### 8.8 定期監査チェックリスト

| チェック項目          | 目的                         | 頻度  |
| --------------- | -------------------------- | --- |
| MagicLinkログ整合   | メール送信の成功率・重複検出             | 月次  |
| Passkey成功率分析    | WebAuthn認証率・拒否率分析          | 月次  |
| Rate制限分析        | スパム抑止・不正試行分析               | 週次  |
| RLS検証           | tenant_id分離確認              | 四半期 |
| Secrets監査       | Supabase / Corbado鍵の有効期限確認 | 月次  |
| Corbado Trace確認 | Supabaseログとの照合整合           | 四半期 |

---

### 8.9 障害復旧方針

* **Corbado障害**：Passkey認証を停止しMagicLink認証のみ許可（自動フェイルオーバー）。
* **Supabase障害**：API再起動・RLS再検証後に再稼働。
* **ネットワーク断**：再送キューでリトライ処理、最大3回。
* **トークン漏洩・改ざん**：`AUTH_DISABLED=true` 設定、Secretsローテーション実施。

---

### 8.10 保守効率化計画

* Supabase / Corbado 双方のメトリクスを Datadog ダッシュボードに集約。
* Corbado API の `status` エンドポイントを監視に統合。
* 月次レポートを Supabase Functions + GitHub Actions にて自動生成。
* ログアーカイブは 13ヶ月でローテーション。
* Phase10では AI分析基盤による異常トレンド検出を導入予定。

---

### 🧾 Change Log

| Version  | Date           | Summary                                       |
| -------- | -------------- | --------------------------------------------- |
| v1.0     | 2025-11-11     | 初版（MagicLink専用監査構成）                           |
| **v1.1** | **2025-11-12** | **Corbado統合対応。監査スキーマ拡張・保守体制統合・フェイルオーバー設計追加。** |
