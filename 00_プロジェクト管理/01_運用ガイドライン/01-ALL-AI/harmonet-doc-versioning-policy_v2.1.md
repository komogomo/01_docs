# HarmoNet Document Versioning Policy v2.1  
**（HarmoNet 文書バージョン管理方針 改訂版）**

**Document ID:** HRM-DOC-VERSIONING-POLICY-002  
**Version:** 2.1  
**Created:** 2025-10-31  
**Author:** TKD + GPT (HarmoNet PMO)

---

## 🎯 改訂概要

本改訂（v2.1）では、従来の `_vX.X.md` および `_latest.md` による命名管理を廃止し、  
**Gitによる履歴管理＋ファイル内ChangeLogによる明示管理方式**へ完全移行する。  
これにより、AI（GPT／Claude／Gemini）と人間の双方が、同一ファイルを安定的に参照可能となる。

---

## 🧱 基本方針

| 項目 | 方針 | 説明 |
|------|------|------|
| **1. ファイル名構成** | ファイル名にバージョン番号を含めない | 例：`board-detail-rules-ch05-functional.md`<br>ファイル名は固定し、バージョンは内部で管理する。 |
| **2. バージョン管理手段** | Git / GitHub に一本化 | コミット履歴・タグ・ブランチで全履歴を保持。<br>ファイル複製による履歴管理は禁止。 |
| **3. 変更履歴の記録** | 各文書に ChangeLog セクションを設ける | バージョン番号・日付・担当・変更内容を文書内に明示。<br>AI・人間双方が文書単体で履歴を理解できるようにする。 |
| **4. ファイルリンク** | 固定名で記述 | `[第5章](board-detail-design-ch05.md)` のように一定名称でリンク。<br> `_latest.md` および `_vX.X.md` 形式は廃止。 |
| **5. 参照整合性** | 章番号（chXX）を論理IDとする | HarmoNetでは `chXX` が機能単位IDであり、Functional／Designのペアを同期。 |
| **6. アーカイブ運用** | Gitタグまたはブランチで保存 | 旧版保存は `_old` ディレクトリではなく `git tag` または `archive/` ブランチで行う。 |
| **7. AI参照互換性** | ファイル固定名＋ChangeLog解釈 | AIはGit履歴およびChangeLogを参照して履歴を理解。<br>ファイル名やワイルドカードによる解釈は行わない。 |

---

## 🧩 ディレクトリ構造参照

HarmoNetの最新ディレクトリ構成は外部参照ファイル  
[`harmonet-doc-directory-structure.md`](harmonet-doc-directory-structure.md)  
にて定義・管理する。  
構成変更時は当該ファイルを更新し、本方針は常にそれを参照する。  

> **更新責任者:** PMO（TKD）  
> **更新タイミング:** ディレクトリ変更時または主要機能追加時  

---

## 🧾 ChangeLog の記載例
```markdown
## 🧾 ChangeLog

| Version | Date | Author | Changes |
|----------|------|--------|---------|
| 1.2 | 2025-10-31 | TKD + GPT | 音声読上げ仕様・キャッシュ制御追加 |
| 1.1 | 2025-10-30 | TKD | 翻訳機能仕様追加 |
| 1.0 | 2025-10-29 | TKD | 初版作成 |
```

---

## 🧭 Git 運用ルール
```bash
# ファイルを更新してコミット
git add board-detail-rules-ch05-functional.md
git commit -m "update: voice-read & translation cache spec (v1.2)"

# バージョンタグを追加
git tag v1.2

# リモートに反映
git push origin main --tags
```

> すべての履歴は Git が保持するため、  
> `_vX.X.md` ファイルを複製・保管する必要はない。

---

## 💬 AIドキュメント連携ルール

AIによるドキュメント参照時は、以下のルールを適用する。

> **AI参照原則**  
> 1. ファイル名は固定名を使用。  
> 2. バージョン指定は不要。  
> 3. 最新版を判定する際は、Git履歴とChangeLogを参照して解釈する。  
> 4. ワイルドカード（例：`v1.*`）指定は非推奨。  

この方式により、AIはGitリポジトリから履歴を動的に参照し、  
特定バージョンの内容を明確に識別できる。

---

## 🧠 運用意図

1. **ファイル名の永続性を保証**し、参照切れを防止する。  
2. **Git履歴とChangeLogの二重トラッキング**で、  
   人間・AIの両者が履歴を正確に追跡可能とする。  
3. **AIの自動解析を前提にした文書設計**を実現する。  
4. **ファイル数を増やさずに履歴の完全再現を担保**する。  

---

## 📎 運用ベストプラクティス

| 項目 | 実施内容 |
|------|-----------|
| コミットメッセージ | `update: <機能名> spec vX.X` の形式で統一 |
| タグ付け | `vX.X` 形式でバージョン識別 |
| Pull Requestタイトル | 「仕様更新：〇〇機能（vX.X）」と明記 |
| ChangeLog追記 | バージョン・日付・担当・概要を1行追加 |
| ドキュメントレビュー | GPT／Claude による差分検証と要約生成を推奨 |

---

**Status:** 承認済  
**Approved by:** TKD + GPT  
**Effective Date:** 2025-10-31  
**Next Review:** 2026-04-01
