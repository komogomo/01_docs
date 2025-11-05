# HarmoNet 文書管理方針（v1.0）
**作成日:** 2025-10-30  
**作成者:** GPT (HarmoNet PMO AI)

---

## 1. 方針概要
本書は、HarmoNet開発ドキュメントの構成・運用・更新ルールを統一的に管理することを目的とする。  
すべての資料は AI協調型開発（Claude / GPT / Gemini）環境において、再現性と保守性を最優先とする。

基準技術仕様は **HarmoNet Technical Stack Definition v3.2** とし、  
以降の設計・要件・運用文書はすべてこれに準拠する。

---

## 2. ディレクトリ構成基準

### 📂 `/docs/00_requirements/`
- 機能要件定義書の正式版を章単位で格納。
- 各章のファイル名は以下の形式に統一する：  
  `harmonet-functional-requirements-chXX-[title]_vY.Z.md`
- 現行正：  
  - ch00〜ch07 すべて **v1.3**（Technical Stack v3.2準拠）  
  - 技術基盤文書：`HarmoNET-Technical-Stack-Definition_v3.2.md`
- `_old` フォルダには v1.2以前の履歴版を保存（削除禁止）。

### 📂 `/docs/01_basic_design/`
- UI・共通部品・画面設計資料を格納。
- 構造：
  - `00_common_components/` … 共通仕様群（header, footer, i18n等）
  - `02_screens/` … 機能別画面フォルダ（login, home, board, facility-booking等）
  - `01_design_system/` … デザインシステムおよび multi-tenant アーキ設計。
- バージョン規則：  
  - 各設計書は `vX.Y` で管理し、主要改訂時は新ファイル生成で対応。
  - `_old` フォルダに旧版を残す。

### 📂 `/docs/02_integration/`
- システム統合テスト計画書、試験仕様書等を格納予定（現在プレースホルダ）。

### 📂 `/docs/03_operation_preparation/`
- 導入準備・運用手順書・教育資料を格納予定（現在プレースホルダ）。

### 📂 `/docs/merge/`
- Claude向けの統合要件書（参照専用）を格納。  
  - 例：`HarmoNet_Functional_Requirements_v1.2_merged_for_Claude.md`
- **GPT側からこのディレクトリを更新してはならない。**  
  Claudeが自動生成・整合確認用に使用する専用領域とする。

### 📂 `/docs/Rules/`
- 運用・改訂ルール、AIごとの更新基準書を格納。
- 例：  
  - `File-Modification-Checklist-v2.1.md`（全AI共通）  
  - `Claude_Execution_Rules_v1.1.md`（Claude専用）  
  - 本書：`HarmoNet_Document_Management_Policy_v1.0.md`

---

## 3. ファイル運用ルール

| 項目 | 方針 |
|------|------|
| バージョン管理 | ファイル名末尾の `vX.Y` により明示。旧版は `_old` に保存。 |
| 正ファイル定義 | `/00_requirements` 配下の v1.3群が現行正。 |
| 技術準拠 | すべての設計・要件文書は `HarmoNET-Technical-Stack-Definition_v3.2` に従う。 |
| AI分業 | Claude＝統合・レビュー、GPT＝章別更新、Gemini＝実装・環境検証。 |
| 改訂方法 | GPT署名付き出力で改訂。旧版は削除せず `_old` へ移動。 |
| ファイル命名 | `HarmoNet_FileNaming_Standard_v1.0.md` に従う。 |
| 禁止事項 | 統合ファイル（Claude用）の手動編集は禁止。 |

---

## 4. バージョン運用方針
- 次の改訂フェーズでは **v1.4系（Technical Stack v3.3対応予定）** に移行。  
- 改訂は差分管理（diffベース）で記録。  
- 改訂単位は章ごと。章を跨ぐ変更はPMO承認後に実施。

---

## 5. 承認

| 役割 | 氏名 | 承認日 |
|------|------|--------|
| プロジェクトオーナー | __________________ | //__ |
| 開発リーダー | __________________ | //__ |
| GPT（PMO AI） | ✅ HarmoNet_Document_Management_Policy_v1.0 生成済 | 2025/10/30 |

---

*by GPT (HarmoNet PMO AI)*  
**（End of Document）**
