# HarmoNet 外部SDKリスクマトリクス v1.0

**Document ID:** HARMONET-EXTERNAL-SDK-RISK-MATRIX-V1.0
**Version:** 1.0
**Created:** 2025-11-12
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** ✅ 提案版（内部資料）

---

## ch01 概要

本書は HarmoNet プロジェクトにおける **外部SDK / API 依存リスク** を整理し、将来的な仕様変更・メジャーアップデートに対する影響範囲を明確化する。特に Corbado / Supabase など、認証・データレイヤーに関わる外部API群は更新頻度が高く、破壊的変更（breaking changes）への備えが重要である。

---

## ch02 対象範囲

| 分類     | 名称                                  | 用途                    | 備考                  |
| ------ | ----------------------------------- | --------------------- | ------------------- |
| 認証     | Corbado SDK (web-js / react / node) | Passkey / WebAuthn認証  | メジャー更新で非互換あり        |
| BaaS   | Supabase SDK v2                     | 認証 / ストレージ / DB       | 安定だが月次更新あり          |
| フロント   | Next.js 16                          | App Router / SSR      | LTS安定中、React 19同期更新 |
| UI     | TailwindCSS 3.4 + shadcn/ui         | デザイン / UI Kit         | メジャー更新でClass変動あり    |
| DB ORM | Prisma ORM                          | PostgreSQL / schema管理 | 移行時に命名変更あり          |

---

## ch03 変更リスク評価基準

| 指標        | 定義                   | 評価基準       |
| --------- | -------------------- | ---------- |
| **更新頻度**  | SDKの更新サイクル（月次 / 四半期） | 低 / 中 / 高  |
| **破壊的変更** | 下位互換性を失う変更           | 無 / 一部 / 多 |
| **依存度**   | HarmoNet機能への関与範囲     | 低 / 中 / 高  |
| **対応コスト** | コード修正・再テストに要する労力     | 小 / 中 / 大  |

---

## ch04 Corbado SDK 詳細

| SDK名                       | 現行Ver | 最終更新    | 更新頻度 | Breaking Change    | 下位互換 | HarmoNet影響    | 対応方針          |
| -------------------------- | ----- | ------- | ---- | ------------------ | ---- | ------------- | ------------- |
| **@corbado/web-js**        | 2.0.8 | 2025-02 | 中    | 部分あり（v1→v2）        | 一部維持 | PasskeyButton | API呼び出し層抽象化維持 |
| **@corbado/react**         | 1.1.1 | 2025-06 | 中    | UI構成変更             | 低    | 将来移行候補        | UI層独自維持・監視    |
| **@corbado/node**          | 1.0.5 | 2025-05 | 低    | 無                  | 高    | サーバーセッション検証   | 移行検討中         |
| **corbado_auth (Flutter)** | 3.4.0 | 2025-03 | 高    | あり（FrontendAPI v2） | 無    | 対象外           | 情報監視のみ        |

### 備考

* Flutter版で重大変更（`customDomain`→`frontendApiUrl`）があり、他言語版も追随の可能性。
* HarmoNetはUI非依存のため、API構造の変更のみ監視対象。

---

## ch05 Supabase SDK 詳細

| モジュール        | 現行Ver  | 最終更新    | 変更傾向     | 下位互換 | 影響領域            | 対応方針            |
| ------------ | ------ | ------- | -------- | ---- | --------------- | --------------- |
| supabase-js  | 2.43.0 | 2025-10 | 安定・月次更新  | あり   | 認証API・RLS       | 月次監視＋Lockfile固定 |
| postgrest-js | 1.8.2  | 2025-07 | 軽微修正     | 高    | DB接続層           | 差分テスト維持         |
| gotrue-js    | 2.23.1 | 2025-08 | メソッド追加中心 | 中    | MagicLink / OTP | AuthAPIテスト強化    |

---

## ch06 Next.js / React リスク

| 項目                   | 内容                        | リスク | 対応             |
| -------------------- | ------------------------- | --- | -------------- |
| **Next.js 16 → 17**  | Turbopack正式化、App Router固定 | 中   | LTS採用・ver固定    |
| **React 19**         | useEffectバグ修正、コンパイラ追加予定   | 低   | minor追随のみ      |
| **App Router API変更** | Layout再構成で微変更あり           | 中   | layout.tsx構造固定 |

---

## ch07 UI層リスク

| ライブラリ        | 現行Ver | 傾向       | 影響 | 対応                |
| ------------ | ----- | -------- | -- | ----------------- |
| TailwindCSS  | 3.4.x | Class変更稀 | 低  | tailwind.config固定 |
| shadcn/ui    | 1.7   | コンポ更新頻度高 | 中  | 必要最小限採用           |
| lucide-react | 0.320 | 安定       | 低  | アイコン固定使用          |

---

## ch08 Prisma / DB層

| 項目                  | 内容                  | リスク | 対応                   |
| ------------------- | ------------------- | --- | -------------------- |
| Prisma ORM          | enum / schema仕様更新あり | 中   | schema.prismaにCI検証追加 |
| Supabase Migrations | CLI更新で構文警告発生        | 中   | バージョン固定＋seed確認       |

---

## ch09 リスク監視プロセス

| 項目                  | 実施者       | 頻度  | 内容                              |
| ------------------- | --------- | --- | ------------------------------- |
| SDKアップデート監視         | Tachikoma | 月1  | npm/yarn outdated / changelog確認 |
| Corbado API変更追跡     | Tachikoma | 随時  | GitHub releases / Docs更新監視      |
| Supabaseリリース監視      | Gemini    | 月1  | APIドキュメント比較                     |
| Next.js / React更新追跡 | Tachikoma | 四半期 | Majorリリース前後に検証                  |

---

## ch10 HarmoNet対応方針

1. **抽象化層（Adapter Pattern）** により、外部SDKの変更をUI層へ波及させない。
2. **Lockfile固定**（`package-lock.json` / `pnpm-lock.yaml`）で環境再現性確保。
3. **月次レポート化**：GeminiがSDK更新を自動監視し、変更差分を通知。
4. **Corbado専用テスト**：Passkey認証APIをmock化し、互換性確認を自動化。

---

## ch11 今後の課題

* Corbadoが次の FrontendAPI v3 を公開した際、互換性検証を即時実施する体制構築。
* Supabase Auth v3（将来β）への移行準備。
* Windsurf CodeAgentへのAPI差分検知タスク連携検討。

---

## ch12 ChangeLog

| Version | Date       | Author    | Summary                                                            |
| ------- | ---------- | --------- | ------------------------------------------------------------------ |
| 1.0     | 2025-11-12 | Tachikoma | 初版作成。Corbado / Supabase / Next.js / Tailwind / Prisma のリスクマトリクス整備。 |

---

**Document Status:** 内部管理資料（PJ技術基盤リスク監視用）
