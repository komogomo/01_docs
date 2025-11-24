# B-04 BoardTranslationAndTtsService 詳細設計書 ch01 概要 v1.0

**Document ID:** HARMONET-COMPONENT-B04-BOARDTRANSLATIONANDTTSSERVICE-DETAIL-CH01
**Version:** 1.0
**Supersedes:** -
**Created:** 2025-11-22
**Updated:** 2025-11-22
**Author:** Tachikoma
**Reviewer:** TKD
**Status:** Draft

---

## 1.1 目的

本章では、掲示板機能において利用される **翻訳＋音声読み上げサービス（B-04 BoardTranslationAndTtsService）** の概要を定義する。
本コンポーネントは UI を持たないバックエンド／サービス層の機能であり、以下を目的とする。

* 掲示板投稿本文（必要に応じてタイトル）を **日本語・英語・中国語** に翻訳し、翻訳結果をキャッシュとして保存／再利用する。
* 掲示板詳細画面において、投稿本文の **音声読み上げ（Text-To-Speech; TTS）** を提供する。
* 翻訳キャッシュの保有期間をテナントごとに設定し、**Supabase Edge Function + Scheduler** により期限切れデータを自動削除する。
* B-01 BoardTop / B-02 BoardDetail / B-03 BoardPostForm から利用される翻訳・TTS の仕様を一元化し、Windsurf が実装可能なレベルで API・スキーマ・バッチ処理を明示する。

---

## 1.2 適用範囲（スコープ）

本コンポーネントの適用範囲は以下の通りとする。

### 1.2.1 対象機能

* 掲示板投稿の翻訳

  * B-03 BoardPostForm からの新規投稿時

    * 原文を保存後に翻訳を実行し、翻訳キャッシュテーブルへ保存する「初回翻訳」。
  * B-02 BoardDetail からのオンデマンド翻訳

    * 翻訳キャッシュが存在しない場合に限り、投稿本文下部の翻訳アイコン押下をトリガとして翻訳を実行・キャッシュ保存する。

* 掲示板投稿の音声読み上げ（TTS）

  * B-02 BoardDetail の投稿本文に対し、音声読み上げボタンから呼び出される TTS 処理。

* 翻訳キャッシュの保守

  * `board_post_translations` テーブル（新設）の TTL 管理。
  * テナント設定 `translation_retention_days` に基づく期限切れ行の削除（Supabase Edge Function によるバッチ）。

### 1.2.2 対象画面・コンポーネント

* B-01 BoardTop-detail

  * 翻訳済み本文の取得／表示のみ（翻訳・TTS の直接呼び出しは行わない）。

* B-02 BoardDetail-detail

  * 翻訳サービス：投稿本文下部の翻訳アイコン押下時に、キャッシュが無い場合のみ呼び出す。
  * TTS サービス：投稿本文の音声読み上げボタン押下時に呼び出す。

* B-03 BoardPostForm-detail

  * 新規投稿保存完了後に、原文をもとに翻訳サービスを非同期／または連続処理として呼び出す（詳細は ch02/ch03 で定義）。

* B-04 BoardTranslationAndTtsService

  * 本書で定義するサービス本体（翻訳／TTS／TTL バッチ）。

---

## 1.3 前提条件・システム構成

### 1.3.1 インフラ・ランタイム前提

* 本番環境

  * DB / 認証: Supabase Cloud **Pro プラン** を利用する。
  * バックエンド: Supabase Edge Functions + Supabase Scheduler（cron）を利用し、常駐サーバは持たない。
  * フロントエンド: Next.js 16 (App Router) + React + TypeScript。

* 開発環境

  * Supabase CLI + Docker コンテナによるローカル Supabase を利用する。
  * Edge Function の開発・動作確認は `supabase functions serve` 等を利用する。
    （ローカルでの定期実行は、開発者による手動実行または簡易スクリプトで代替してよい。設計上の正式なスケジューラは本番の Supabase Scheduler とする。）

- 開発環境補足
  - ローカル Supabase コンテナ環境では、Studio / Edge Functions / Storage / Logflare を含む全コンポーネントを起動する。
  - 本番 Supabase Cloud Pro 環境と同等の機能セットを前提とし、翻訳・TTS・Edge Function・ログ出力の挙動は原則としてローカル環境で再現・検証可能とする。

### 1.3.2 外部サービス前提

* 翻訳 API

  * Google Cloud Translation API v3 を利用する。
  * 認証はサービスアカウント（JSON キー）を用い、環境変数でパスまたは鍵情報を与える。
  * 実際の呼び出し方法（SDK 利用 / REST 直叩き）は ch02 で詳細定義する。

* 音声読み上げ API（TTS）

  * 外部 TTS サービス（候補: Google Cloud Text-to-Speech API など）を利用する。
  * 現時点では「日本語・英語・中国語の読み上げが可能であること」のみを前提とし、具体的なプロバイダ・プランは ch04 で確定させる。
  * 認証方式は翻訳 API と同様にサービスアカウントを前提とし、環境変数管理ルールを揃える。

### 1.3.3 DB・スキーマ前提

* 既存テーブル

  * `board_posts` : 掲示板投稿の本体テーブル。
  * `tenant_settings` : テナントごとの設定情報を JSON で保持するテーブル。

    * 本サービスでは `config_json.board.translation_retention_days` を利用し、翻訳キャッシュ保有日数を管理する。

* 新規テーブル（本書 ch03 で論理設計を定義し、schema.prisma / SQL で実装）

  * `board_post_translations` : 翻訳済み本文を言語コードごとに保持するキャッシュテーブル。

---

## 1.4 対象外・非スコープ

本コンポーネントが扱わない領域を明示する。

* 掲示板 UI レイアウト・スタイル

  * ボタン配置・色・フォントなどの詳細な UI デザインは、B-01/B-02/B-03 の詳細設計書で定義する。

* 翻訳結果の品質

  * 機械翻訳の文品質は保証しない。
  * 専門用語の辞書管理やユーザによる修正インターフェースは本スコープ外とする。

* 音声品質・アクセシビリティの細部

  * 音声の自然さ／アクセント調整／スピード微調整などは外部 TTS サービス依存とし、本書では最低限のパラメータ（言語・話者・再生フォーマット）のみ対象とする。

* 汎用翻訳 API としての公開

  * 本サービスはあくまで掲示板機能専用とし、他機能（例: 施設予約、プロフィールなど）での再利用は想定しない。
  * 必要になった場合は、別途「共通翻訳サービス」として再設計する。

---

## 1.5 関連ドキュメント

* B-00 HarmoNet-bbs-board Design-decision-summary_v1.0.md

  * 掲示板全体の設計方針・翻訳／音声読み上げ有無の決定を記載。
* B-01 BoardTop-detail-design 系

  * 掲示板トップ画面の UI・一覧表示仕様。翻訳済み本文の表示方法を参照。
* B-02 BoardDetail-detail-design 系

  * 掲示板詳細画面の UI・動作仕様。翻訳アイコン／音声読み上げボタンの UI 仕様を参照。
* B-03 BoardPostForm-detail-design 系

  * 掲示板投稿フォームの詳細設計。投稿時に翻訳サービスをトリガするフローを参照。
* HarmoNet 非機能要件定義書 / 技術スタック定義書

  * Supabase / Next.js / Google Cloud サービス利用方針、ログ・監視・セキュリティ要件を参照。

---

## 1.6 本書で今後定義する内容

後続章（ch02〜ch04）では、以下の内容を詳細に定義する。

* ch02: 翻訳・TTS サービス API と認証

  * `TranslationService` / `BoardPostTranslationService` のインターフェース。
  * TTS 向け `TtsService` / `BoardPostTtsService` のインターフェース。
  * Google Cloud Translation / TTS への認証方式・エンドポイント・環境変数定義。

* ch03: 翻訳キャッシュ／DB スキーマ／TTL 設計

  * `board_post_translations` テーブルの論理設計（カラム・制約・インデックス）。
  * `tenant_settings.config_json.board.translation_retention_days` の仕様。
  * Supabase Edge Function + Scheduler による削除バッチの前提。

* ch04: 音声読み上げ（TTS）詳細設計

  * B-02 BoardDetail からの呼び出しフロー。
  * 音声フォーマット、レスポンス種別（ストリーミング／ファイル）、ブラウザ再生方法。
  * エラー時の UI メッセージ仕様（B-02 側と連携）。

本章をもって、B-04 BoardTranslationAndTtsService の位置づけと責務を確定する。
