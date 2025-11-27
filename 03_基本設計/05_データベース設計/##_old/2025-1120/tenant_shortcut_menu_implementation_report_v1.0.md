# tenant_shortcut_menu テーブル追加 - 整合性確認報告書

**作成日**: 2025-11-20  
**作成者**: Claude (HarmoNet DB Administrator)  
**対象**: tenant_shortcut_menu テーブル追加  
**バージョン**: schema.prisma v1.8

---

## 📋 実装内容

### 1. ENUM定義追加

```prisma
/// フッターショートカット機能キー
enum shortcut_feature_key {
  home
  board
  facility
  mypage
  logout
}
```

**配置**: 既存ENUM群（93-99行目）に追加  
**命名規則**: snake_case（既存パターン準拠）  
**値**: 小文字（既存パターン準拠）

---

### 2. モデル定義追加

```prisma
/// テナント別フッターショートカットメニュー構成
/// フッターショートカットバーの表示項目・順序・アイコンを定義
model tenant_shortcut_menu {
  id            String                @id @default(uuid())
  tenant_id     String
  feature_key   shortcut_feature_key
  label_key     String
  icon          String
  display_order Int
  enabled       Boolean               @default(true)
  created_at    DateTime              @default(now())
  updated_at    DateTime              @updatedAt
  status        status                @default(active)

  tenant tenants @relation(fields: [tenant_id], references: [id])

  @@unique([tenant_id, feature_key])
  @@index([tenant_id, display_order])
}
```

**配置**: 新規セクション `// --- 10. UI Configuration ---`  
**行番号**: 632-652行目

---

### 3. tenantsモデルへのリレーション追加

```prisma
model tenants {
  // ... 既存フィールド ...
  
  // Relations
  tenant_shortcut_menu       tenant_shortcut_menu[]  // 追加（112行目）
}
```

---

## ✅ 既存スキーマとの整合性確認

### 1. 命名規則

| 項目 | 既存パターン | 今回実装 | 整合性 |
|------|------------|---------|--------|
| ENUM名 | snake_case | `shortcut_feature_key` | ✅ 一致 |
| ENUM値 | 小文字 | `home`, `board`, ... | ✅ 一致 |
| モデル名 | snake_case | `tenant_shortcut_menu` | ✅ 一致 |
| フィールド名 | snake_case | `feature_key`, `label_key`, ... | ✅ 一致 |

---

### 2. 必須フィールド

| フィールド | 既存パターン | 今回実装 | 整合性 |
|-----------|------------|---------|--------|
| `id` | UUID, Primary Key | ✅ | ✅ 一致 |
| `tenant_id` | テナント分離必須 | ✅ | ✅ 一致 |
| `created_at` | タイムスタンプ | ✅ | ✅ 一致 |
| `updated_at` | タイムスタンプ | ✅ | ✅ 一致 |
| `status` | 論理削除用 | ✅ | ✅ 一致 |

---

### 3. enabled フィールド

**既存の類似パターン:**
```prisma
model tenant_features {
  enabled Boolean @default(true)  // UI表示の有効/無効
  status  status  @default(active) // 論理削除用
}
```

**今回実装:**
```prisma
model tenant_shortcut_menu {
  enabled Boolean @default(true)  // UI表示の有効/無効
  status  status  @default(active) // 論理削除用
}
```

**整合性**: ✅ `tenant_features` と同じパターン

---

### 4. インデックス設計

| インデックス | 用途 | 既存パターンとの整合性 |
|------------|------|---------------------|
| `@@unique([tenant_id, feature_key])` | テナント内で feature_key 一意 | ✅ 一致（`board_categories` 等と同じ） |
| `@@index([tenant_id, display_order])` | 表示順クエリ最適化 | ✅ 一致（複合インデックス） |

---

### 5. リレーション設計

```prisma
// tenant_shortcut_menu → tenants
tenant tenants @relation(fields: [tenant_id], references: [id])

// tenants → tenant_shortcut_menu
tenant_shortcut_menu tenant_shortcut_menu[]
```

**外部キー制約**: `ON DELETE RESTRICT ON UPDATE CASCADE`  
**整合性**: ✅ 既存のテナント系テーブルと同じパターン

---

## ✅ RLSポリシー整合性確認

### 1. RLS_Policy_Standard_v1.0.md 準拠

| 項目 | 要求 | 実装 | 整合性 |
|------|------|------|--------|
| Subquery Wrap | `(select auth.jwt())` | ✅ | ✅ |
| Split Policies | FOR SELECT/INSERT/UPDATE/DELETE 個別定義 | ✅ | ✅ |
| Naming Convention | `{table}_{operation}_{role}` | ✅ | ✅ |
| WITH CHECK | INSERT/UPDATE で使用 | ✅ | ✅ |
| 型変換なし | `::uuid` / `::text` 使用禁止 | ✅ | ✅ |

---

### 2. ポリシー一覧

| ポリシー名 | 操作 | 条件 |
|-----------|------|------|
| `tenant_shortcut_menu_select_authenticated` | SELECT | `tenant_id` 一致 |
| `tenant_shortcut_menu_insert_authenticated` | INSERT | `tenant_id` 一致 |
| `tenant_shortcut_menu_update_authenticated` | UPDATE | `tenant_id` 一致 |
| `tenant_shortcut_menu_delete_authenticated` | DELETE | `tenant_id` 一致 |

**総ポリシー数**: 4ポリシー（既存104 → 108ポリシー）

---

## ✅ マイグレーションファイル整合性確認

### 1. BOMチェック

**ファイル1**: `20251120000000_add_tenant_shortcut_menu.sql`  
**ファイル2**: `20251120000001_enable_rls_tenant_shortcut_menu.sql`

**エンコーディング**: UTF-8（BOMなし）必須  
**確認方法**:
```powershell
$bytes = [System.IO.File]::ReadAllBytes("path/to/file.sql")
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "⚠ BOM detected!"
} else {
    Write-Host "✅ No BOM"
}
```

---

### 2. SQL構文チェック

**テーブル作成SQL:**
- ✅ CREATE TYPE（ENUM定義）
- ✅ CREATE TABLE（全フィールド定義）
- ✅ CREATE UNIQUE INDEX（tenant_id + feature_key）
- ✅ CREATE INDEX（tenant_id + display_order）
- ✅ ALTER TABLE ADD CONSTRAINT（外部キー）

**RLSポリシーSQL:**
- ✅ ALTER TABLE ENABLE ROW LEVEL SECURITY
- ✅ CREATE POLICY × 4（SELECT/INSERT/UPDATE/DELETE）
- ✅ Subquery Wrap 適用
- ✅ 型変換なし

---

## ✅ tenant_features との関係整理

### 既存: tenant_features

```prisma
model tenant_features {
  tenant_id   String
  feature_key String   // 機能の有効/無効フラグ
  enabled     Boolean
}
```

**用途**: バックエンド機能の ON/OFF 管理

---

### 新規: tenant_shortcut_menu

```prisma
model tenant_shortcut_menu {
  tenant_id     String
  feature_key   shortcut_feature_key  // UI表示構成
  label_key     String
  icon          String
  display_order Int
  enabled       Boolean
}
```

**用途**: フッターショートカットバーの UI表示構成管理

---

### 関係性

```
tenant_features      → バックエンド機能の有効/無効
tenant_shortcut_menu → UI表示構成（表示順序・アイコン・ラベル）

両者は独立して管理される
```

**例:**
- `tenant_features`: `board` 機能が `enabled = false` → 掲示板機能全体が無効
- `tenant_shortcut_menu`: `board` が `enabled = false` → フッターショートカットに非表示（機能自体は有効）

**整合性**: ✅ 独立管理（既存モデルへの影響なし）

---

## ✅ Seedデータ推奨案

```typescript
// prisma/seed.ts に追加推奨

// テナントショートカットメニュー（デフォルト5項目）
await prisma.tenant_shortcut_menu.createMany({
  data: [
    {
      tenant_id: demoTenant.id,
      feature_key: 'home',
      label_key: 'nav.home',
      icon: 'Home',
      display_order: 1,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'board',
      label_key: 'nav.board',
      icon: 'MessageSquare',
      display_order: 2,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'facility',
      label_key: 'nav.facility',
      icon: 'Calendar',
      display_order: 3,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'mypage',
      label_key: 'nav.mypage',
      icon: 'User',
      display_order: 4,
      enabled: true,
      status: 'active',
    },
    {
      tenant_id: demoTenant.id,
      feature_key: 'logout',
      label_key: 'nav.logout',
      icon: 'LogOut',
      display_order: 5,
      enabled: true,
      status: 'active',
    },
  ],
});

console.log('✅ Tenant shortcut menu created (5 items)');
```

---

## ✅ 検証チェックリスト

### スキーマ定義
- [x] ENUM定義追加（`shortcut_feature_key`）
- [x] モデル定義追加（`tenant_shortcut_menu`）
- [x] tenantsモデルへのリレーション追加
- [x] 命名規則準拠（snake_case）
- [x] 必須フィールド完備（id/tenant_id/created_at/updated_at/status）

### マイグレーションSQL
- [x] テーブル作成SQL生成
- [x] RLSポリシーSQL生成
- [x] BOMなしUTF-8エンコーディング
- [x] 型変換なし（`::uuid` / `::text` 不使用）
- [x] Subquery Wrap適用

### 整合性確認
- [x] 既存モデルへの影響なし（破壊的変更なし）
- [x] tenant_features との関係整理
- [x] RLS_Policy_Standard_v1.0.md 準拠
- [x] インデックス戦略適切

---

## 📊 変更サマリ

| 項目 | 変更内容 |
|------|---------|
| **ENUM追加** | 1件（`shortcut_feature_key`） |
| **モデル追加** | 1件（`tenant_shortcut_menu`） |
| **リレーション追加** | 1件（tenants → tenant_shortcut_menu） |
| **マイグレーションファイル** | 2件（テーブル作成 + RLSポリシー） |
| **RLSポリシー** | 4件（SELECT/INSERT/UPDATE/DELETE） |
| **総テーブル数** | 31 → 32 |
| **総ENUM数** | 11 → 12 |
| **総RLSポリシー数** | 104 → 108 |

---

## ✅ 最終確認結果

**既存スキーマとの整合性**: ✅ 完全に一致  
**RLSポリシー標準準拠**: ✅ 完全に準拠  
**命名規則**: ✅ 統一  
**破壊的変更**: ❌ なし  

**実装可否判定**: ✅ 実装可能

---

**作成者**: Claude (HarmoNet DB Administrator)  
**確認日**: 2025-11-20  
**承認待ち**: TKD (Project Owner)
