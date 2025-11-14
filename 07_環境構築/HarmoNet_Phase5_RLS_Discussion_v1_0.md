# HarmoNet Phase 5 協議書

**件名**: `role_inheritances` テーブルのRLSポリシー設定に関する協議

**発行者**: Claude（HarmoNet Design Specialist）  
**宛先**: タチコマ（PMO / Architect）、Gemini（Audit AI）  
**協議依頼者**: TKD（Project Owner）  
**日付**: 2025-11-04  
**優先度**: 🟡 中（Phase 5 完了判定に影響）

---

## 🎯 協議の背景

### 現状

Phase 5（データベース設計・構築）において、以下の状況が確認された：

| 項目 | 状態 |
|------|------|
| 総テーブル数 | 29テーブル |
| RLS有効化 | 29テーブル（100%） ✅ |
| ポリシー設定済み | 28テーブル ✅ |
| ポリシー未設定 | **1テーブル（role_inheritances）** ⚠️ |

### 問題点

`role_inheritances` テーブルは：
- ✅ RLS有効化済み
- ❌ **ポリシー未設定**
- ❌ **現状では誰もアクセスできない状態**

---

## 📊 `role_inheritances` テーブルの詳細

### テーブル定義

```sql
CREATE TABLE role_inheritances (
    parent_role_id UUID NOT NULL,
    child_role_id UUID NOT NULL,
    PRIMARY KEY (parent_role_id, child_role_id)
);
```

### 用途

ロールの継承関係を定義するマスタテーブル

**例:**
```
parent_role_id: tenant_admin
child_role_id: general_user
意味: tenant_admin は general_user の権限を継承する
```

### アクセス頻度

- 📊 **参照**: 高頻度（権限チェック時に毎回参照）
- ✏️ **更新**: 低頻度（ロール設計変更時のみ）

### 他テーブルとの関係

| テーブル | RLSポリシー | 理由 |
|---------|------------|------|
| `roles` | グローバル参照可能 | マスタデータ |
| `permissions` | グローバル参照可能 | マスタデータ |
| `role_permissions` | グローバル参照可能 | マスタデータ |
| `role_inheritances` | **未設定** | ← 今回の協議対象 |

---

## 🔍 選択肢の検討

### 選択肢A: グローバル参照可能（Claude推奨）

```sql
CREATE POLICY role_inheritances_select
ON role_inheritances FOR SELECT
USING (true);
```

**メリット:**
- ✅ 他のマスタテーブル（roles, permissions）と整合
- ✅ アプリケーションが権限チェックに使用可能
- ✅ シンプルで理解しやすい

**デメリット:**
- ⚠️ 全ユーザーがロール構造を閲覧可能

**セキュリティリスク:**
- 🟢 低（ロール名とID以外の機密情報なし）

---

### 選択肢B: 管理者のみアクセス可能

```sql
CREATE POLICY role_inheritances_admin_only
ON role_inheritances FOR ALL
USING ((auth.jwt() ->> 'role') IN ('system_admin', 'tenant_admin'))
WITH CHECK ((auth.jwt() ->> 'role') IN ('system_admin', 'tenant_admin'));
```

**メリット:**
- ✅ セキュリティが高い
- ✅ ロール構造を一般ユーザーから隠蔽

**デメリット:**
- ❌ アプリケーション層で権限チェック時にアクセスできない
- ❌ サービスロール（service_role）での処理が必要
- ❌ 実装が複雑化

**セキュリティリスク:**
- 🟢 極めて低

---

### 選択肢C: Phase 9 で判断（先送り）

**メリット:**
- ✅ Phase 5 を暫定完了できる
- ✅ 実装時に必要性を判断

**デメリット:**
- ❌ Phase 5 が未完成状態
- ❌ Phase 9 実装時に問題が発覚する可能性
- ❌ 追加作業が発生

**リスク:**
- 🟡 中（実装時の手戻り可能性）

---

## 🧩 Prismaスキーマとの整合性

### Prismaスキーマ定義

```prisma
model role_inheritances {
  parent_role_id String
  child_role_id  String

  @@id([parent_role_id, child_role_id])
}
```

### 想定される使用例

```typescript
// 権限チェック時の使用例
const inheritedRoles = await prisma.role_inheritances.findMany({
  where: {
    parent_role_id: currentUserRoleId
  }
});
```

**このクエリが実行できるか？**
- 選択肢A: ✅ 実行可能
- 選択肢B: ❌ 実行不可（管理者以外）
- 選択肢C: ❓ 未定義

---

## 📋 他システムの事例調査

### 類似システムでの一般的な設計

| システム | role_inheritances の扱い | 理由 |
|---------|-------------------------|------|
| **Keycloak** | グローバル参照可能 | 権限チェックに必要 |
| **Auth0** | グローバル参照可能 | マスタデータとして扱う |
| **AWS IAM** | グローバル参照可能 | ポリシー評価に必要 |

**結論: 業界標準はグローバル参照可能**

---

## 🎯 Claude の推奨（設計者として）

### 推奨: **選択肢A（グローバル参照可能）**

### 理由

1. **整合性**
   - `roles`, `permissions`, `role_permissions` と同じ扱い
   - マスタデータとして一貫性がある

2. **実装容易性**
   - Prismaからの参照が可能
   - サービスロール不要

3. **業界標準**
   - 類似システムと同じ設計
   - ベストプラクティスに準拠

4. **セキュリティ**
   - リスクは低い（ロール名とID以外の機密情報なし）
   - テナント分離は維持される

5. **Phase 9 への影響**
   - 実装時の手戻りなし
   - 権限チェックロジックがシンプル

---

## 📊 協議事項

### タチコマへの質問

**質問1: アーキテクチャ整合性**
- `role_inheritances` を他のマスタテーブルと同様に扱うべきか？
- テナント分離設計との整合性は保たれるか？

**質問2: Phase 9 への影響**
- 選択肢Bの場合、実装がどの程度複雑化するか？
- サービスロール使用の是非

---

### Gemini への質問

**質問1: セキュリティ監査**
- グローバル参照可能にした場合のリスク評価
- 業界標準との比較

**質問2: BAG監査観点**
- どの選択肢が最も設計整合性が高いか？
- Phase 9 実装時の品質リスク

---

## 📝 協議の進め方

### Step 1: 各AIの意見表明

1. **タチコマ**: アーキテクチャ観点からの判断
2. **Gemini**: セキュリティ・品質観点からの判断

### Step 2: 合意形成

- 各AIの意見を踏まえて最終推奨を決定

### Step 3: TKD への報告

- 協議結果をまとめて報告
- 実装方針を提示

---

## ⏰ 期限

**協議期限**: 本チャット内で即時（Phase 5 完了判定のため）

---

## 📎 添付資料

### 参考情報

- Phase 5 成果物: `06_harmonet-db-table-definition_v1.0.md`
- Prismaスキーマ: `04_harmonet-prisma-schema_v1.0.prisma`
- RLSポリシー一覧: 本協議書発行時のクエリ結果参照

### 現在のRLS設定状況

```
総テーブル: 29
RLS有効化: 29（100%）
ポリシー設定: 28テーブル（33ポリシー）
未設定: role_inheritances（1テーブル）
```

---

## ✅ 協議完了時のアクション

協議完了後、以下を実施：

1. **合意された選択肢でマイグレーション作成**
2. **適用・確認**
3. **Phase 5 完了報告**

---

## 📋 協議記録

### タチコマの意見

（ここに記入）

---

### Gemini の意見

（ここに記入）

---

### 最終合意

（協議後に記入）

---

## 📋 メタ情報

| 項目 | 値 |
|------|-----|
| **Document ID** | HNM-DISCUSSION-20251104-001 |
| **Version** | 1.0 |
| **Created** | 2025-11-04 |
| **Last Updated** | 2025-11-04 |
| **Author** | Claude（HarmoNet Design Specialist） |
| **Reviewers** | タチコマ（Architect）、Gemini（Audit AI） |
| **Approver** | TKD（Project Owner） |
| **Status** | 🟡 協議中 |
| **Priority** | 🟡 中 |
| **Impact** | Phase 5 完了判定、Phase 9 実装容易性 |

---

**協議をお願いします。** 🙇‍♂️

タチコマ、Gemini の意見表明をお待ちしています。

---

**Document End**
