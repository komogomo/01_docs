# 第6章 制約条件・コスト要件

（現行構成：Supabase Pro / Vercel Hobby or Pro / Google Translate + Google TTS）

**準拠:** HarmoNet Technical Stack Definition v4.3
**Author:** Tachikoma / TKD
**Updated:** 2025-11-19
**Status:** ✅ HarmoNet 正式版（現実運用ベースのコスト・制約定義）

---

# 6.1 本章の目的

本章は HarmoNet の運用において、次の項目を明確化する：

* 利用サービス（Supabase / Vercel / Google API）の **無償・有償の制約とリスク**
* 予測可能な **月額コスト試算**
* 「監視しない」個人開発運用に適した **最適構成の判断基準**
* サービス停止リスクを避けるための **有償プラン前提設計**

将来ロードマップや未確定の将来機能は扱わず、**現行構成だけ**を対象とする。

---

# 6.2 Supabase（Free / Pro）の制約と選定

## ■ Free プランの制約

* 一定期間アクセスが無いと **自動停止（Sleep）** する
* 再起動に 2〜5 秒発生（MagicLink 認証に悪影響）
* 接続数・帯域の上限が厳しい
* SLA なし（稼働率保証なし）

## ■ Pro プランの特徴（推奨）

* 常時稼働（Sleep なし）
* SLA 99.5%
* 高帯域・高トラフィックに対応
* ログ保持期間が長い

## ■ 月額

* Free：0円
* **Pro：$25/月（約 ¥3,800）**

## ■ HarmoNet 方針

**本番環境は Supabase Pro を必須とする。**
理由：MagicLink 認証の安定性と「自動停止による予期せぬ停止」の回避。

---

# 6.3 Vercel（Hobby / Pro）の制約と費用

## ■ Hobby（無償）の制約

* Serverless 関数の実行 10 秒制限
* Sleep の可能性あり
* 帯域・ビルド制限
* ログ保持が短い

## ■ Pro（有償）

* 月額：**$20（約 ¥3,000）**
* Sleep なし
* ログ保持期間延長
* 安定性大幅向上

## ■ HarmoNet 方針

* 初期：**Hobby で十分**（本体機能に大きな負荷がないため）
* アクセス増加時：Pro に切替可能

---

# 6.4 Google Cloud API（翻訳 / TTS）の制約と費用

HarmoNet は **翻訳（Translate API）** と **音声（Text‑to‑Speech）** を Google に集約する。

## ■ Translation API v3

* 無料枠：50万文字/月
* 超過：$20 / 100万文字
* 通常運用では月数十円〜数百円程度

## ■ Text‑to‑Speech（TTS）

* 価格：**$4 / 100万文字**（WaveNet/Studio は別）
* 1 文字 = 約 0.0005 円
* 掲示板・お知らせ規模では **月数十円レベル**

## ■ HarmoNet 方針

* 翻訳・TTS ともに **Google API を採用**（請求統合により管理コスト最小化）
* TTS 障害時は読み上げ無しで運用継続（非必須機能）

---

# 6.5 Redis（任意）の制約と費用

HarmoNet の翻訳キャッシュは Supabase + API Route で対応可能だが、
大量翻訳が必要な場合は Redis を追加利用できる。

## ■ 無償（Upstash Free）

* 月 10,000 requests
* 容量 256MB
* Sleep（Cold Start）あり
* 高負荷に弱い

## ■ 有償（Upstash Pro）

* **$5〜$20 / 月**
* Sleep なし
* 高速アクセス

## ■ HarmoNet 方針

初期は Redis 不要。必要になった時点で Pro を検討する。

---

# 6.6 月額コストの総合試算

## ■ 小規模構成（1物件 / 100ユーザー）

| サービス       | プラン     | 月額      |
| ---------- | ------- | ------- |
| Supabase   | **Pro** | $25     |
| Vercel     | Hobby   | $0      |
| Google 翻訳  | 無料枠内    | $0      |
| Google TTS | 数円〜数十円  | $0.5〜$1 |
| Redis      | なし      | $0      |

→ **合計：約 ¥4,000〜¥5,000**

---

## ■ 中規模構成（3物件 / 300〜500ユーザー）

| サービス       | プラン     | 月額  |
| ---------- | ------- | --- |
| Supabase   | **Pro** | $25 |
| Vercel     | **Pro** | $20 |
| Google 翻訳  | $1〜$5   |     |
| Google TTS | $2〜$5   |     |
| Redis      | $5〜$10  |     |

→ **合計：約 ¥8,000〜¥12,000**

---

# 6.7 現行構成でのリスクと注意点

* **翻訳コストだけ変動的**（翻訳量増加時に上昇）
* Vercel Hobby は Sleep の可能性があり、TTS 連携時に影響する場合あり
* Supabase Free は採用不可（Sleep が致命的）
* TTS が落ちても HarmonNet 本体に影響なし（非必須機能）
* 翻訳 API 障害時は日本語にフォールバックする

---

# 6.8 本章のまとめ（TKD 運用ポリシー）

* **本番は Supabase Pro を必須とし、安定稼働を担保する**
* 翻訳・TTS は Google へ統合し、管理コストを最小化する
* 音声読み上げは「付加価値」であり、落ちても問題ない設計とする
* Redis は負荷増加時にのみ導入検討
* 目標月額は **¥4,000〜¥12,000 の範囲**（規模に応じて変動）

---

**Document ID:** HNM-REQ-CH06-V1.4
