# HarmoNet アイコン実装ガイド v1.0

**Document ID:** HARMONET-ICON-IMPL-V1.0  
**Version:** 1.0  
**Created:** 2025-11-19  
**Author:** Claude (AI Development Assistant)  
**Target:** HarmoNet Phase 9 実装  
**Icon Library:** Lucide Icons (lucide-react)

---

## 📋 目次

1. [概要](#概要)
2. [ディレクトリ構造](#ディレクトリ構造)
3. [実装ファイル](#実装ファイル)
4. [使用例](#使用例)
5. [実装パターン比較](#実装パターン比較)

---

## 概要

### 採用アイコンライブラリ

**Lucide Icons (lucide-react)**
- バージョン: 最新
- ライセンス: MIT（商用利用可能）
- アイコン数: 1,600+
- 特徴: Feather Icons の後継、React 19 完全対応

### インストール

```bash
npm install lucide-react
```

### 推奨実装パターン

**パターン1: Icon + 定数管理（推奨）**
- ✅ 型安全
- ✅ 一元管理
- ✅ 変更容易
- ✅ デザインシステム準拠

---

## ディレクトリ構造

```
src/
├── components/
│   └── icons/
│       ├── index.ts                 # 統一エクスポート
│       └── Icon.tsx                 # 共通ラッパーコンポーネント
├── app/
│   └── (dashboard)/
│       └── home/
│           └── page.tsx             # ホーム画面（使用例）
└── lib/
    └── constants/
        └── icons.ts                 # アイコン定義（型安全）
```

---

## 実装ファイル

### 1. 共通Iconコンポーネント

**ファイル:** `src/components/icons/Icon.tsx`

```tsx
import { LucideIcon } from 'lucide-react';

interface IconProps {
  icon: LucideIcon;
  size?: number;
  strokeWidth?: number;
  className?: string;
  'aria-label'?: string;
}

/**
 * Lucide Icons 共通ラッパーコンポーネント
 * HarmoNet Design System 準拠
 */
export default function Icon({ 
  icon: IconComponent, 
  size = 24, 
  strokeWidth = 1.5,
  className = "",
  'aria-label': ariaLabel,
}: IconProps) {
  return (
    <IconComponent 
      size={size} 
      strokeWidth={strokeWidth}
      className={className}
      aria-label={ariaLabel}
      aria-hidden={!ariaLabel}
    />
  );
}
```

---

### 2. アイコン定義（型安全）

**ファイル:** `src/lib/constants/icons.ts`

```tsx
import { 
  Calendar, 
  FileText, 
  MessageSquare, 
  Camera, 
  Wrench, 
  Bell,
  Home,
  LogOut,
  LucideIcon 
} from 'lucide-react';

/**
 * HarmoNet 機能別アイコンマッピング
 * 型安全にアイコンを管理
 */
export const HARMONET_ICONS = {
  // メイン機能
  parking: Calendar,
  document: FileText,
  board: MessageSquare,
  camera: Camera,
  maintenance: Wrench,
  notification: Bell,
  
  // ナビゲーション
  home: Home,
  logout: LogOut,
} as const;

export type HarmoNetIconKey = keyof typeof HARMONET_ICONS;

/**
 * 機能タイル用アイコン設定
 */
export interface FunctionTileIcon {
  key: HarmoNetIconKey;
  icon: LucideIcon;
  label: string;
  labelEn?: string;
}

export const FUNCTION_TILES: FunctionTileIcon[] = [
  { 
    key: 'parking', 
    icon: HARMONET_ICONS.parking, 
    label: '駐車場予約', 
    labelEn: 'Parking' 
  },
  { 
    key: 'document', 
    icon: HARMONET_ICONS.document, 
    label: '回覧板', 
    labelEn: 'Documents' 
  },
  { 
    key: 'board', 
    icon: HARMONET_ICONS.board, 
    label: '掲示板', 
    labelEn: 'Board' 
  },
  { 
    key: 'camera', 
    icon: HARMONET_ICONS.camera, 
    label: '監視カメラ', 
    labelEn: 'Camera' 
  },
  { 
    key: 'maintenance', 
    icon: HARMONET_ICONS.maintenance, 
    label: 'メンテナンス', 
    labelEn: 'Maintenance' 
  },
  { 
    key: 'notification', 
    icon: HARMONET_ICONS.notification, 
    label: '通知設定', 
    labelEn: 'Settings' 
  },
];
```

---

### 3. 統一エクスポート

**ファイル:** `src/components/icons/index.ts`

```tsx
export { default as Icon } from './Icon';
export * from 'lucide-react';
```

---

## 使用例

### パターンA: 型安全な実装（推奨）

**ファイル:** `src/app/(dashboard)/home/page.tsx`

```tsx
import { Icon } from '@/components/icons';
import { FUNCTION_TILES } from '@/lib/constants/icons';

export default function HomePage() {
  return (
    <main className="page-content">
      {/* 機能メニュー */}
      <section className="function-section">
        <div className="section-header">
          <h2 className="section-title">機能メニュー</h2>
        </div>

        <div className="function-grid">
          {FUNCTION_TILES.map((tile) => (
            <button 
              key={tile.key}
              className="function-tile"
              aria-label={tile.label}
            >
              <Icon 
                icon={tile.icon} 
                size={48} 
                strokeWidth={1.5}
                className="text-[var(--color-action-blue)]"
              />
              <span className="function-tile__label">{tile.label}</span>
            </button>
          ))}
        </div>
      </section>
    </main>
  );
}
```

---

### パターンB: 直接使用（シンプル）

```tsx
import { Calendar, Bell, MessageSquare } from 'lucide-react';

export default function SimpleComponent() {
  return (
    <div className="icons">
      {/* 基本使用 */}
      <Calendar size={24} strokeWidth={1.5} className="text-blue-600" />
      
      {/* 通知バッジ付き */}
      <button className="notification-btn">
        <Bell size={24} strokeWidth={1.5} />
        <span className="badge">3</span>
      </button>
      
      {/* カスタムスタイル */}
      <MessageSquare 
        size={48} 
        strokeWidth={1.5}
        className="text-[var(--color-action-blue)] hover:text-[var(--color-action-blue-hover)]"
      />
    </div>
  );
}
```

---

### パターンC: Iconラッパー使用

```tsx
import { Icon } from '@/components/icons';
import { HARMONET_ICONS } from '@/lib/constants/icons';

export default function WrapperComponent() {
  return (
    <div className="icons">
      {/* 型安全に使用 */}
      <Icon icon={HARMONET_ICONS.parking} size={48} />
      
      {/* CSS変数でスタイル */}
      <Icon 
        icon={HARMONET_ICONS.bell} 
        size={24}
        className="text-[var(--color-action-blue)]"
        aria-label="通知"
      />
    </div>
  );
}
```

---

## 実装パターン比較

### 比較表

| パターン | 使用場面 | メリット | デメリット | 推奨度 |
|---------|---------|---------|----------|-------|
| **A. Icon + 定数管理** | 大規模・保守性重視 | ✅ 型安全<br>✅ 一元管理<br>✅ 変更容易<br>✅ デザインシステム準拠 | ⚠️ 初期コスト | ⭐⭐⭐⭐⭐ |
| **B. 直接インポート** | 小規模・プロトタイプ | ✅ 最速実装<br>✅ シンプル | ❌ 保守性低<br>❌ スタイル統一困難 | ⭐⭐ |
| **C. Iconラッパーのみ** | 中規模 | ✅ 統一スタイル<br>✅ まあまあシンプル | ⚠️ 管理が分散 | ⭐⭐⭐ |

---

### HarmoNet 推奨：パターンA

**理由:**
- ✅ 将来的なアイコン変更が容易（1箇所の修正で全体に反映）
- ✅ TypeScript型安全で開発効率向上
- ✅ 多言語対応しやすい（labelEn フィールド活用）
- ✅ コンポーネント再利用性が高い
- ✅ デザインシステムとの整合性

---

## スタイリング

### HarmoNet Design System 準拠

```tsx
// CSS変数使用（推奨）
<Icon 
  icon={Calendar} 
  size={48}
  strokeWidth={1.5}
  className="text-[var(--color-action-blue)] hover:text-[var(--color-action-blue-hover)]"
/>
```

### Tailwind CSS 直接

```tsx
<Icon 
  icon={Calendar} 
  size={48}
  strokeWidth={1.5}
  className="text-blue-600 hover:text-blue-700"
/>
```

### 標準SVG属性

```tsx
<Calendar 
  size={24}
  strokeWidth={1.5}
  color="currentColor"
  className="custom-icon"
/>
```

---

## アイコン一覧

### HarmoNet 標準アイコン

| 機能 | アイコン名 | Lucide | インポート |
|------|-----------|--------|-----------|
| 駐車場予約 | Calendar | ✅ | `Calendar` |
| 回覧板 | File Text | ✅ | `FileText` |
| 掲示板 | Message Square | ✅ | `MessageSquare` |
| 監視カメラ | Camera | ✅ | `Camera` |
| メンテナンス | Wrench | ✅ | `Wrench` |
| 通知 | Bell | ✅ | `Bell` |
| ホーム | Home | ✅ | `Home` |
| ログアウト | Log Out | ✅ | `LogOut` |

### その他の推奨アイコン

| 用途 | アイコン名 | インポート |
|------|-----------|-----------|
| ユーザー | User | `User` |
| 設定 | Settings | `Settings` |
| 検索 | Search | `Search` |
| フィルター | Filter | `Filter` |
| メニュー | Menu | `Menu` |
| 閉じる | X | `X` |
| チェック | Check | `Check` |
| プラス | Plus | `Plus` |

---

## アクセシビリティ

### aria-label の使用

```tsx
<Icon 
  icon={Bell} 
  size={24}
  aria-label="通知センター"
/>
```

### ボタン内での使用

```tsx
<button aria-label="駐車場予約">
  <Icon icon={Calendar} size={24} />
  <span className="sr-only">駐車場予約</span>
</button>
```

---

## トラブルシューティング

### Q1: アイコンが表示されない

**原因:** lucide-react がインストールされていない

**解決:**
```bash
npm install lucide-react
```

---

### Q2: 型エラーが出る

**原因:** LucideIcon 型のインポート漏れ

**解決:**
```tsx
import { LucideIcon } from 'lucide-react';
```

---

### Q3: スタイルが適用されない

**原因:** className が正しく渡されていない

**解決:**
```tsx
// ❌ 悪い例
<Icon icon={Calendar} class="text-blue-600" />

// ✅ 良い例
<Icon icon={Calendar} className="text-blue-600" />
```

---

## まとめ

### 実装手順

1. **lucide-react をインストール**
   ```bash
   npm install lucide-react
   ```

2. **3つのファイルを作成**
   - `src/components/icons/Icon.tsx`
   - `src/lib/constants/icons.ts`
   - `src/components/icons/index.ts`

3. **コンポーネントで使用**
   ```tsx
   import { Icon } from '@/components/icons';
   import { FUNCTION_TILES } from '@/lib/constants/icons';
   ```

4. **スタイル適用**
   ```tsx
   <Icon icon={tile.icon} size={48} className="..." />
   ```

---

### 推奨事項

✅ **パターンA（Icon + 定数管理）を採用**  
✅ **HarmoNet Design System のCSS変数を使用**  
✅ **aria-label でアクセシビリティ確保**  
✅ **strokeWidth は 1.5 に統一**  
✅ **size は用途別に統一（タイル:48 / ナビ:24）**

---

## 参考リンク

- **Lucide Icons 公式:** https://lucide.dev/
- **GitHub:** https://github.com/lucide-icons/lucide
- **Lucide React:** https://lucide.dev/guide/packages/lucide-react

---

**End of Document**
