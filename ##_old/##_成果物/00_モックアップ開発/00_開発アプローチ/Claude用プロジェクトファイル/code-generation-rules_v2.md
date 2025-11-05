# Code Generation Rules

## Overview
Critical rules that must be followed when generating code. These rules prevent common errors discovered during actual development.

---

## Rule 1: Required CSS Variables

### Must Define Before Use

**MUST define these variables in `variables.css` before using them in any CSS file:**

```css
/* Layout */
--footer-height: 70px;
--max-width-content: 1024px;

/* Spacing */
--spacing-2: 0.5rem;
--spacing-4: 1rem;
--spacing-6: 1.5rem;
--spacing-8: 2rem;

/* Colors */
--text-primary: #111827;
--bg-card: #ffffff;

/* Typography */
--font-size-xl: 1.25rem;

/* Border */
--radius-lg: 0.5rem;

/* Shadow */
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);

/* Z-index */
--z-header: 50;
--z-footer: 100;
```

### Why This Matters

Layout calculations in `layout.css` depend on these variables. Missing variables cause **silent failures** - the page may render without errors, but spacing and layout will be incorrect.

### Pre-Generation Checklist

Before generating any CSS code:

- âœ… All required variables exist in `variables.css`
- âœ… No hardcoded values that should be variables
- âœ… All `var()` references have corresponding definitions
- âœ… `layout.css` calculations will work correctly

---

## Rule 2: Translation Keys - 3 Language Set Required

### The 3-Language Rule

**CRITICAL: When adding ANY translation key, add to ALL 3 files simultaneously:**

1. `ja.js` (Japanese) âœ…
2. `en.js` (English) âœ…  
3. `zh.js` (Chinese) âœ…

Missing keys in any language file causes **raw key display** instead of translated text.

### Example: Complete Implementation

```javascript
// ja.js
home: {
  notice: {
    new: 'æœªèª­',
    all: 'ã™ã¹ã¦'
  },
  welcome: {
    title: 'ã‚ˆã†ã“ã'
  }
}

// en.js
home: {
  notice: {
    new: 'New',
    all: 'All'
  },
  welcome: {
    title: 'Welcome'
  }
}

// zh.js
home: {
  notice: {
    new: 'æœªè¯»',
    all: 'å…¨éƒ¨'
  },
  welcome: {
    title: 'æ¬¢è¿Ž'
  }
}
```

### What Happens If You Forget

**Bad Example** (missing key in en.js):
```
User switches to English â†’ sees "home.notice.new" instead of "New"
```

### Verification Process

**Step 1: Extract all keys from HTML**
```bash
grep -o 'data-i18n="[^"]*"' home.html
```

**Step 2: Verify in all 3 files**
- Check `ja.js` has the key
- Check `en.js` has the key
- Check `zh.js` has the key

**Step 3: Test language switching**
- Switch to Japanese â†’ All text displays
- Switch to English â†’ All text displays
- Switch to Chinese â†’ All text displays

### Prevention Checklist

- âœ… Extract all keys from HTML before starting
- âœ… Add missing keys to ALL 3 files (not just one)
- âœ… Use same structure in all 3 files
- âœ… Test language switching for all 3 languages

---

## Rule 3: CSS File Placement Decision

### The Ownership Rule

Every CSS style belongs to exactly ONE file based on **component ownership**.

### Decision Table

| Component Type | Correct File | Location | Reason |
|----------------|--------------|----------|--------|
| Welcome header | `header.css` | `css/common/` | Header-related component |
| Language buttons | `button.css` | `css/common/` | Button component |
| Footer navigation | `footer.css` | `css/common/` | Footer component |
| Login form | `form.css` | `css/common/` | Form component (if reused) |
| Home page content | `home.css` | `pages/home/` | Screen-specific only |
| Bulletin board list | `bulletin-board.css` | `pages/bulletin-board/` | Screen-specific only |

### Common CSS (css/common/)

**Place styles here if:**
- âœ… Used in multiple screens
- âœ… Part of header, footer, or navigation
- âœ… Reusable component (buttons, forms, cards)
- âœ… Layout, typography, or base styles

**Examples:**
- Header components
- Footer components
- Button styles
- Form elements
- Typography rules
- Color variables
- Reset styles

### Screen-Specific CSS (pages/[screen]/)

**Place styles here if:**
- âœ… Used ONLY in this screen
- âœ… Not reused in other screens
- âœ… Content-specific layout
- âœ… Unique to this feature

**Examples:**
- Home page dashboard layout
- Bulletin board card grid
- Facility booking calendar
- Survey question layout

### Wrong Placement Causes Problems

**Problem 1: Duplicate Styles**
```css
/* header.css */
.welcome-header { ... }

/* home.css */
.welcome-header { ... }  /* âŒ Duplicate! */
```

**Problem 2: Maintenance Difficulty**
- Change header style â†’ Must edit multiple files
- Easy to miss updates
- Inconsistent behavior

**Problem 3: Performance**
- Loading unnecessary CSS on every page
- Larger file sizes

### Decision Flowchart

```
Is this component used in multiple screens?
â”‚
â”œâ”€ YES â†’ Common CSS (css/common/)
â”‚   â”‚
â”‚   â””â”€ Which type?
â”‚       â”œâ”€ Header â†’ header.css
â”‚       â”œâ”€ Footer â†’ footer.css
â”‚       â”œâ”€ Button â†’ button.css
â”‚       â”œâ”€ Form â†’ form.css
â”‚       â””â”€ Other â†’ component-name.css
â”‚
â””â”€ NO â†’ Screen-specific CSS (pages/[screen]/)
    â”‚
    â””â”€ Place in pages/[screen]/[screen].css
```

### Quick Test

Ask yourself:
1. **"Will other screens need this style?"**
   - YES â†’ Common CSS
   - NO â†’ Screen-specific CSS

2. **"Is this part of header/footer/button?"**
   - YES â†’ Respective component CSS
   - NO â†’ Check question 1

### Prevention Checklist

Before placing CSS:

- âœ… Ask "Is this used in multiple screens?"
- âœ… Check existing common CSS files first
- âœ… If header/footer/button related â†’ common CSS
- âœ… If screen content only â†’ screen-specific CSS
- âœ… When in doubt, ask for clarification

---

## Rule 4: Translation File Organization - Screen-based Split

### The Screen-based Rule

**CRITICAL: Translation files MUST be organized per screen, not globally.**

Each screen has its own set of translation files co-located with the screen files.

### Correct File Structure

```
pages/home/
├── home.html
├── home.css
├── home.js
├── home.ja.js      ← Home screen Japanese translations
├── home.en.js      ← Home screen English translations
└── home.zh.js      ← Home screen Chinese translations

pages/board/
├── board.html
├── board.css
├── board.js
├── board.ja.js     ← Board screen Japanese translations
├── board.en.js     ← Board screen English translations
└── board.zh.js     ← Board screen Chinese translations

js/i18n/langs/
├── common.ja.js    ← Common translations ONLY (header, footer, buttons)
├── common.en.js
└── common.zh.js
```

### Wrong Structure (Do NOT Use)

```
âŒ WRONG - All screens in single file:

js/i18n/langs/
├── ja.js           ← ALL screens' Japanese (home + board + booking + ...)
├── en.js           ← ALL screens' English (home + board + booking + ...)
└── zh.js           ← ALL screens' Chinese (home + board + booking + ...)
```

### Why This Matters

**Scalability Problem:**
```
24 screens × 20 keys per screen = 480 keys in single file
480 keys × 3 lines per key = 1,440 lines
```
**→ Violates 300-line rule** (from Development Guidelines)

**Independence:** Each screen is self-contained - easy to add, modify, or delete

**Maintainability:** Finding translations is trivial - just look in the screen's directory

**Parallel Development:** No merge conflicts when multiple developers work on different screens

**Performance:** Only load translations needed for current screen

### Translation Categories

#### Common Translations (js/i18n/langs/common.ja.js)

**Include ONLY:**
- Header elements
- Footer navigation labels
- Common button labels
- Shared error messages

**Example:**
```javascript
// common.ja.js
window.i18nData = window.i18nData || {};
window.i18nData.ja = {
  // Footer navigation (short form)
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'booking': '施設予約',
  'mypage': 'マイページ',
  'logout': 'ログアウト',
  
  // Common buttons
  'common.save': '保存',
  'common.cancel': 'キャンセル',
  'common.confirm': '確認',
};
```

#### Screen-specific Translations (pages/[screen]/[screen].ja.js)

**Include ONLY:**
- Content area text
- Screen-specific buttons
- Screen-specific messages
- Screen-specific labels

**Example:**
```javascript
// pages/board/board.ja.js
window.i18nData = window.i18nData || {};
window.i18nData.ja = window.i18nData.ja || {};

Object.assign(window.i18nData.ja, {
  'board.title': '掲示板',
  'board.post': '投稿',
  'board.description': '住民同士のコミュニケーション',
  'board.category.all': 'すべて',
  // ... other board-specific keys
});
```

### HTML Loading Order

**Correct order in HTML:**
```html
<body>
  <!-- 1. Common translations (header, footer) -->
  <script src="../../js/i18n/langs/common.ja.js"></script>
  <script src="../../js/i18n/langs/common.en.js"></script>
  <script src="../../js/i18n/langs/common.zh.js"></script>
  
  <!-- 2. Common features -->
  <script src="../../js/features/language-switcher.js"></script>
  <script src="../../js/features/translator.js"></script>
  <script src="../../js/features/footer-navigation.js"></script>
  
  <!-- 3. Screen-specific translations (content area) -->
  <script src="board.ja.js"></script>
  <script src="board.en.js"></script>
  <script src="board.zh.js"></script>
  
  <!-- 4. Screen-specific logic -->
  <script src="board.js"></script>
</body>
```

### File Size Guidelines

**Maximum file sizes:**
- Common translation file: ~100 lines (≈10 keys)
- Screen translation file: ~60 lines (≈20 keys)
- Total per screen: 180 lines (well under 300-line limit)

### Migration from Old Structure

If you find old structure with consolidated `ja.js`, `en.js`, `zh.js`:

1. Extract common keys → `common.ja.js`, `common.en.js`, `common.zh.js`
2. Extract screen keys → `[screen].ja.js`, `[screen].en.js`, `[screen].zh.js`
3. Delete old consolidated files
4. Update all HTML files to load new structure

### Prevention Checklist

Before adding translation keys:

- âœ… Is this key used in header/footer? → Add to `common.[lang].js`
- âœ… Is this key used in content area? → Add to `[screen].[lang].js`
- âœ… Added to ALL 3 language files? (ja, en, zh)
- âœ… Files under 300 lines?
- âœ… HTML loads common translations first?

---

## Summary

### Four Critical Rules

1. **CSS Variables** â†’ Define before use, check `variables.css`
1. **CSS Variables** → Define before use, check `variables.css`
2. **Translation Keys** → Always 3-language set (ja/en/zh)
3. **CSS Placement** → Common vs Screen-specific decision
4. **Translation Files** → Screen-based split, not global consolidation

### Impact

Following these rules prevents:
- ✘ Silent layout failures
- ✘ Raw key display in UI
- ✘ Style duplication and maintenance issues
- ✘ Inconsistent behavior across screens
- ✘ Massive translation files (violating 300-line rule)
- ✘ Merge conflicts in translation files

### Next Steps

When generating code:
1. Review this file FIRST
2. Apply all four rules
3. Use checklists for verification
4. Test thoroughly

---

**Last Updated:** 2025/10/25  
**Version:** 2.0 (Added Rule 4: Translation File Organization)  
**Related Files:** troubleshooting.md, checklist.md
