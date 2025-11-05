# 命名規則

## ファイル名：ハイフン区切り（ケバブケース）

```
✓ home.html
✓ language-switcher.js
✓ footer-navigation.css

✗ Home.html（大文字NG）
✗ languageSwitcher.js（キャメルNG）
✗ footer_navigation.css（アンダースコアNG）
```

---

## 画面固有ファイルの命名規則

### Directory Structure
```
pages/[screen-name]/
├── [screen-name].html          ← Main HTML (required, single file)
├── [screen-name].css           ← Base styles
├── [screen-name].js            ← Base scripts
├── [screen-name]-[feature].css ← Additional styles (when features grow)
└── [screen-name]-[feature].js  ← Additional scripts (when features grow)
```

### Naming Patterns

**HTML Files (required, single file only):**
- Pattern: `[screen-name].html`
- Examples: `template.html`, `home.html`, `board.html`

**CSS/JS Files (can be split by feature):**
- Base file: `[screen-name].css`, `[screen-name].js`
- Feature-specific: `[screen-name]-[feature].css`, `[screen-name]-[feature].js`

**Feature Name Examples:**
- `template-animation.css` - animation-related styles
- `template-modal.js` - modal functionality
- `home-dashboard.css` - dashboard display
- `board-editor.js` - post editing functionality

### Rules
- ✓ All lowercase
- ✓ Hyphen-separated (kebab-case)
- ✗ No underscores
- ✗ No camelCase

### File Split Guidelines
- Split when a single file exceeds **300 lines**
- Split by feature/functionality for better maintainability
- Keep related functionality together

### Important Notes for Existing Files
- **When modifying existing files:** Keep the original filename
- ✗ Don't create: `header-fixed.css`, `header-v2.css`, `header_new.css`
- ✓ Modify the original: `header.css` → `header.css`
- Version history is managed by commit messages, not filenames

---

## グローバル変数：window.大文字始まり

```javascript
✓ window.LanguageSwitcher = ...;
✓ window.Translator = ...;
✓ window.I18nData = ...;

✗ languageSwitcher = ...;（windowなし）
✗ window.translator = ...;（小文字始まり）
```

**理由：**
- グローバルスコープの汚染を防ぐ
- 他のライブラリとの名前衝突を回避
- グローバル変数であることを明示

---

## CSSクラス：BEM記法

```css
/* Block（ブロック）: ハイフン区切り */
.footer-nav { }

/* Element（要素）: アンダースコア2つ */
.footer-nav__button { }

/* Modifier（修飾子）: ハイフン2つ */
.footer-nav__button--active { }

/* 状態クラス: is- プレフィックス */
.is-active { }
```

**BEM記法の利点：**
- クラス名から構造が理解できる
- CSS specificity の問題を回避
- コンポーネントの再利用が容易

---

## JavaScript関数・変数

```javascript
// 関数名: キャメルケース
function initLanguageSwitcher() { }

// クラス名: パスカルケース
class LanguageSwitcher { }

// 定数: スネーク大文字
const MAX_RETRY_COUNT = 3;

// ローカル変数: キャメルケース
let currentLanguage = 'ja';
```

**命名のベストプラクティス：**
- 関数名は動詞から始める（init, get, set, update, etc.）
- 変数名は内容を明確に表現する
- boolean変数は is/has/should などで始める
- 略語は避け、理解しやすい名前を使う
