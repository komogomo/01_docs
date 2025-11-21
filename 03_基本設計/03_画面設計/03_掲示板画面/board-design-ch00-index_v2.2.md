# 第0章: 目次・位置づけ

**HarmoNet 掲示板機能 基本設計書 v2.2（BoardTop / Detail / 投稿 / 共通仕様）**

[第1章 →](board-design-ch01_latest.md)

---

## 🆕 ChangeLog (v2.2 / 2025-11-21)

* プロダクト名を「セキュレアシティ」から「HarmoNet」に統一
* 旧 `board-feature-design-*` 系の章構成を廃止し、`board-design-ch01〜07` を正式な基本設計とする構成に再編
* 機能要件 v1.6 / 技術スタック v4.4 / BBS Design-decision-summary v1.0 を上位仕様として明示
* 掲示板 UI を HOME / BoardTop / BoardDetail / 投稿フォームに整理し、翻訳・TTS・モデレーション・既読・通報・アンケートの共通仕様へのリンクを追加

---

## 0.1 文書の目的

本書は、HarmoNet の掲示板機能（BoardTop / BoardDetail / 投稿フォーム）に関する **画面別の基本設計** をまとめたものである。

* 対象:

  * HOME 内の掲示板サマリ
  * 掲示板TOP 一覧（/board）
  * 掲示板詳細（/board/[id]）
  * 掲示板投稿フォーム（新規・編集）
* 本書で定義する内容:

  * 画面ごとの役割・導線・レイアウト
  * 翻訳（3言語自動翻訳）・音声読み上げ（TTS）・AIモデレーションの基本方針
  * 既読管理・通報・アンケート（議決補助）などの補助機能
* 本書で扱わない内容:

  * DB スキーマの詳細（Prisma / Supabase 定義）
  * API 実装・ルーティング実装の詳細（Login Backend 基本設計書を参照）
  * リッチテキストエディタの技術詳細（別途リッチテキスト連携詳細設計を参照）

掲示板に関する「画面仕様の唯一の正」は、本 index からリンクされる第1〜7章の各基本設計書とする。

---

## 0.2 上位仕様・関連文書

掲示板基本設計は、以下の上位仕様および関連文書に従う。

* 機能要件・非機能要件

  * `functional-requirements-all_v1.6.md`
  * `Nonfunctional-requirements_v1.0.md`
* 技術スタック・アーキテクチャ

  * `harmonet-technical-stack-definition_v4.4.md`
* 掲示板設計決定サマリ

  * `HarmoNet-bbs-board Design-decision-summary_v1.0.md`
* リッチテキスト・翻訳・TTS 詳細

  * `board-richtext-integration_v1.0.md`
* 認証・マジックリンク・redirect

  * `Login-Backend-basic-design_v1.0.md`（掲示板ショートカットURLとの連携は本書第7章と連動）

---

## 0.3 章構成

掲示板機能の基本設計は、以下の 7 章構成とする。

### 第1章: 概要と設計方針

* ファイル: `board-design-ch01_latest.md`
* 内容:

  * 掲示板機能の目的・背景
  * 安心感・管理負担・多文化共生の三原則
  * AIモデレーションと翻訳を「付加価値」として扱う全体方針

### 第2章: 画面一覧と導線（HOME／BoardTop／Detail）

* ファイル: `board-design-ch02_latest.md`
* 内容:

  * HOME 内掲示板サマリ・BoardTop・BoardDetail の役割
  * ALL / NOTICE / RULES タブと GLOBAL / GROUP 範囲の切り替え
  * HOME → /board → /board/[id] の遷移と状態保持方針

### 第3章: 掲示板TOP一覧画面（BoardTop）

* ファイル: `board-design-ch03_latest.md`
* 内容:

  * BoardTop のレイアウト構造
  * 投稿サマリカード（タグ・タイトル・メタ情報・本文サマリ・添付アイコン・ピン留め・回覧板ステータス）
  * タブ（ALL/NOTICE/RULES）・範囲（GLOBAL/GROUP）・ソート・ページネーション
  * 空状態・エラー状態の表示方針

### 第4章: 投稿詳細画面（BoardDetail）

* ファイル: `board-design-ch04_latest.md`
* 内容:

  * 投稿タイトル・カテゴリ・メタ情報・本文の構造
  * 添付ファイルエリアと PDF プレビュー（モーダル仕様）
  * コメント一覧・コメント入力・既読状況エリア（管理投稿向け）
  * 音声読み上げ（掲示板画面限定）と翻訳表示の考え方

### 第5章: 投稿作成画面（新規・編集）

* ファイル: `board-design-ch05_latest.md`
* 内容:

  * カテゴリ／タイトル／本文／公開範囲／添付／回覧板フラグ等の入力仕様
  * 文字数・添付数・添付サイズの二段階上限（システム絶対上限＋テナント上限）
  * 保存アクション（一般住民／管理者）と 3 言語自動翻訳・translation_cache 更新
  * 回覧板作成オプションと既読管理との関係

### 第6章: 掲示板共通仕様（翻訳・音声・モデレーション）

* ファイル: `board-design-ch06_latest.md`
* 内容:

  * 投稿本文の 3 言語自動翻訳と translation_cache の利用
  * 掲示板画面限定の音声読み上げ（TTS）と tts_cache
  * 一般利用者投稿に対する AI モデレーション（任意導入、ON/OFF＋レベル設定）
  * 翻訳・TTS・モデレーションが停止しても投稿／閲覧を継続する共通エラーハンドリング

### 第7章: 補助機能（既読・通報・アンケート拡張）

* ファイル: `board-design-ch07_latest.md`
* 内容:

  * 管理投稿向け既読管理（住民側既読ボタン＋既読率、管理画面での個票閲覧）
  * 通報機能（投稿・コメントに対する通報、管理画面での対応フロー）
  * アンケート／議決機能（将来拡張、テナントごとの ON/OFF）
  * 記事番号・ショートカットURLとマジックリンク認証との連携方針

---

## 0.4 運用上の注意

* 掲示板に関する仕様変更は、必ず本書第1〜7章を更新することを前提とし、

  * 旧 `board-feature-design-*` 系ファイルは新規変更の対象としない（アーカイブ扱い）。
* 詳細設計・実装指示（Windsurf 用 WS 文書）では、本 index からリンクされる最新版のみを参照する。
* 画面仕様と DB／API／管理画面仕様の間に差異が生じた場合、

  * 上位仕様（機能要件 v1.6 / 技術スタック v4.4 / Design-decision-summary v1.0）
  * 本基本設計書（第1〜7章）
    の順に優先して解消する。

---

**Document ID:** SEC-APP-BOARD-DESIGN-002-CH00
**Version:** 2.2
**Created:** 2025-10-31
**Last Updated:** 2025-11-21
**Author:** TKD + GPT (HarmoNet PMO)
