# Chapter 06: 多言語対応

**HarmoNet 施設予約機能 基本設計書**

---

## 改訂履歴

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-10-29 | TKD + Claude | 初版作成 |
| v1.1 | 2025-11-29 | TKD + Claude | 動的翻訳不要の方針明確化、通知機能削除 |

---

## 目次

1. [多言語対応の方針](#1-多言語対応の方針)
2. [静的翻訳（next-intl）](#2-静的翻訳next-intl)
3. [施設名・区画名の多言語対応](#3-施設名区画名の多言語対応)
4. [利用規約の多言語対応](#4-利用規約の多言語対応)

---

## 1. 多言語対応の方針

### 1.1 対応言語

| 言語 | コード | 対象ユーザー |
|------|--------|-------------|
| 日本語 | JA | 日本人住民 |
| 英語 | EN | 英語圏住民 |
| 中国語（簡体字） | ZH | 中国出身住民 |

### 1.2 翻訳方式

**施設予約機能では動的翻訳は不要。**

| 対象 | 翻訳方式 | 理由 |
|------|---------|------|
| UI（ボタン/ラベル/エラー） | 静的（next-intl） | 固定文言 |
| 施設名 | マスタ登録時に3言語入力 | テナント管理者が設定 |
| 区画名 | 翻訳不要 | ①②③等の記号はそのまま |
| 利用規約 | 掲示板連携 | 掲示板の動的翻訳機能を利用 |
| 使用目的（ユーザー入力） | 翻訳不要 | 本人のみ参照 |

### 1.3 動的翻訳の適用基準

**動的翻訳が必要な条件:** 複数の人が参照するコンテンツ

施設予約機能では該当なし:
- 使用目的 → 本人＋管理者程度 → **翻訳不要**

### 1.4 通知について

予約状況はマイページから確認できるため、メール通知・プッシュ通知は不要。

---

## 2. 静的翻訳（next-intl）

### 2.1 既存実装の流用

施設予約機能の UI 翻訳は、既存の next-intl 実装を流用する。

**翻訳ファイル:**
```
public/locales/
  ├── ja/common.json
  ├── en/common.json
  └── zh/common.json
```

### 2.2 施設予約用の翻訳キー例

| キー | JA | EN | ZH |
|-----|-----|-----|-----|
| facility.tab.meetingRoom | 集会所 | Meeting Room | 会议室 |
| facility.tab.parking | ゲスト駐車場 | Guest Parking | 访客停车场 |
| facility.button.reserve | 予約する | Reserve | 预订 |
| facility.button.cancel | キャンセル | Cancel | 取消 |
| facility.label.date | 予約日 | Date | 日期 |
| facility.label.timeSlot | 時間帯 | Time Slot | 时间段 |
| facility.label.purpose | 使用目的 | Purpose | 使用目的 |
| facility.label.participants | 参加人数 | Participants | 参加人数 |
| facility.message.success | 予約が完了しました | Reservation completed | 预订成功 |
| facility.error.alreadyBooked | この時間帯は既に予約されています | Already booked | 该时段已被预订 |
| facility.error.monthlyLimit | 今月の予約上限に達しています | Monthly limit reached | 本月预订已达上限 |

---

## 3. 施設名・区画名の多言語対応

### 3.1 施設名

テナント管理者が施設登録時に入力。

**現時点の方針:**
- `facilities.facility_name` に日本語名を登録
- 英語・中国語の施設名は将来対応（カラム追加）

**将来対応案:**
```
facility_name_ja: セキュレアステーション
facility_name_en: SECUREA Station
facility_name_zh: SECUREA会议室
```

### 3.2 区画名

区画名（①②③...、A1, B2 等）は翻訳不要。記号・英数字のまま全言語共通で表示。

---

## 4. 利用規約の多言語対応

### 4.1 方針

施設の利用規約は掲示板連携で対応。

- 掲示板の「ルール・規則」カテゴリに投稿
- 掲示板の動的翻訳機能で3言語自動翻訳
- 施設予約画面からはリンクのみ表示

### 4.2 メリット

- 利用規約の翻訳は掲示板機能で自動化
- 規約変更時は掲示板投稿を編集するだけ
- 施設予約機能の実装がシンプルになる

---

**Document ID**: HARMONET-FACILITY-BOOKING-DESIGN-001-CH06  
**Status**: 確定版  
**Created**: 2025-10-29  
**Last Updated**: 2025-11-29  
**Version**: v1.1  
**Authors**: TKD + Claude  

---

© 2025 HarmoNet Project. All rights reserved.
