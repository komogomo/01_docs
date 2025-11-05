# Code Generation Rules v2.1

## Overview

Critical rules that must be followed when generating code. These rules prevent common errors discovered during actual development.

**Last Updated:** 2025/10/26
**Version:** 2.1 (English edition with ASCII charset + Rule 5 added)

---

## Rule 1: Required CSS Variables

### Must Define Before Use

MUST define these variables in `variables.css` before using them in any CSS file:

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

Layout calculations in `layout.css` depend on these variables. Missing variables cause silent failures - the page may render without errors, but spacing and layout will be incorrect.

### Pre-Generation Checklist

Before generating any CSS code:

- [OK] All required variables exist in `variables.css`
- [OK] No hardcoded values that should be variables
- [OK] All var() references have corresponding definitions
- [OK] layout.css calculations will work correctly

---

## Rule 2: Translation Keys - 3 Language Set Required

### The 3-Language Rule

CRITICAL: When adding ANY translation key, add to ALL 3 files simultaneously:

1. common.ja.js (Japanese) [OK]
2. common.en.js (English) [OK]
3. common.zh.js (Chinese) [OK]

Missing keys in any language file causes raw key display instead of translated text.

### Example: Complete Implementation

```javascript
// common.ja.js
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.ja = {
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'booking': '施設予約',
  'mypage': 'マイページ',
  'logout': 'ログアウト',
};

// common.en.js
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.en = {
  'home': 'Home',
  'notice': 'Notices',
  'board': 'Board',
  'booking': 'Parking',
  'mypage': 'My Page',
  'logout': 'Logout',
};

// common.zh.js
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.zh = {
  'home': '首页',
  'notice': '通知',
  'board': '公告板',
  'booking': '停车场',
  'mypage': '我的页面',
  'logout': '登出',
};
```

### What Happens If You Forget

Bad Example (missing key in en.js):
```
User switches to English => sees "home.notice.new" instead of "New"
```

### Verification Process

Step 1: Extract all keys from HTML
```bash
grep -o 'data-i18n="[^"]*"' home.html
```

Step 2: Verify in all 3 files
- Check ja.js has the key
- Check en.js has the key
- Check zh.js has the key

Step 3: Test language switching
- Switch to Japanese => All text displays
- Switch to English => All text displays
- Switch to Chinese => All text displays

### Prevention Checklist

- [OK] Extract all keys from HTML before starting
- [OK] Add missing keys to ALL 3 files (not just one)
- [OK] Use same structure in all 3 files
- [OK] Test language switching for all 3 languages

---

## Rule 3: CSS File Placement Decision

### The Ownership Rule

Every CSS style belongs to exactly ONE file based on component ownership.

### Decision Table

Component Type        | Correct File    | Location           | Reason
--                    | --              | --                 | --
Header                | header.css      | css/common/         | Reused in all screens
Button                | button.css      | css/common/         | Reused in all screens
Footer                | footer.css      | css/common/         | Reused in all screens
Form                  | form.css        | css/common/         | Reused in multiple screens
Home page content     | home.css        | pages/home/         | Screen-specific only
Bulletin board list   | board.css       | pages/board/        | Screen-specific only

### Common CSS (css/common/)

Place styles here if:
- [OK] Used in multiple screens
- [OK] Part of header, footer, or navigation
- [OK] Reusable component (buttons, forms, cards)
- [OK] Layout, typography, or base styles

Examples:
- Header components
- Footer components
- Button styles
- Form elements
- Typography rules
- Color variables
- Reset styles

### Screen-Specific CSS (pages/[screen]/)

Place styles here if:
- [OK] Used ONLY in this screen
- [OK] Not reused in other screens
- [OK] Content-specific layout
- [OK] Unique to this feature

Examples:
- Home page dashboard layout
- Bulletin board card grid
- Facility booking calendar
- Survey question layout

### Wrong Placement Causes Problems

Problem 1: Duplicate Styles
```css
/* header.css */
.welcome-header { color: blue; }

/* home.css */
.welcome-header { color: blue; } /* Duplicate! */
```

Problem 2: Maintenance Difficulty
- Change header style => Must edit multiple files
- Easy to miss updates
- Inconsistent behavior

Problem 3: Performance
- Loading unnecessary CSS on every page
- Larger file sizes

### Decision Flowchart

Question: Is this component used in multiple screens?

If YES:
- Place in Common CSS (css/common/)
- Determine component type:
  - Header related => header.css
  - Footer related => footer.css
  - Button component => button.css
  - Form component => form.css
  - Other components => component-name.css

If NO:
- Place in Screen-specific CSS (pages/[screen]/)
- File location: pages/[screen]/[screen].css

### Quick Test

Ask yourself:
1. "Will other screens need this style?"
   - YES => Common CSS
   - NO => Screen-specific CSS

2. "Is this part of header/footer/button?"
   - YES => Respective component CSS
   - NO => Check question 1

### Prevention Checklist

Before placing CSS:

- [OK] Ask "Is this used in multiple screens?"
- [OK] Check existing common CSS files first
- [OK] If header/footer/button related => common CSS
- [OK] If screen content only => screen-specific CSS
- [OK] When in doubt, ask for clarification

---

## Rule 4: Translation File Organization - Screen-based Split

### The Screen-based Rule

CRITICAL: Translation files MUST be organized per screen, not globally.

Each screen has its own set of translation files co-located with the screen files.

### Correct File Structure

```
pages/home/
  home.html
  home.css
  home.js
  home.ja.js     (Home screen Japanese translations)
  home.en.js     (Home screen English translations)
  home.zh.js     (Home screen Chinese translations)

pages/board/
  board.html
  board.css
  board.js
  board.ja.js    (Board screen Japanese translations)
  board.en.js    (Board screen English translations)
  board.zh.js    (Board screen Chinese translations)

js/i18n/langs/
  common.ja.js   (Common translations ONLY: header, footer, buttons)
  common.en.js
  common.zh.js
```

### Wrong Structure (Do NOT Use)

WRONG - All screens in single file:

```
js/i18n/langs/
  ja.js   (ALL screens' Japanese: home + board + booking + ...)
  en.js   (ALL screens' English: home + board + booking + ...)
  zh.js   (ALL screens' Chinese: home + board + booking + ...)
```

### Why This Matters

Scalability Problem:
```
24 screens x 20 keys per screen = 480 keys in single file
480 keys x 3 lines per key = 1,440 lines
=> Violates 300-line rule (from Development Guidelines)
```

Independence: Each screen is self-contained - easy to add, modify, or delete

Maintainability: Finding translations is trivial - just look in the screen's directory

Parallel Development: No merge conflicts when multiple developers work on different screens

Performance: Only load translations needed for current screen

### Translation Categories

#### Common Translations (js/i18n/langs/common.ja.js)

Include ONLY:
- Header elements
- Footer navigation labels
- Common button labels
- Shared error messages

Example:
```javascript
// common.ja.js
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.ja = {
  /* Footer navigation (short form) */
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'booking': '施設予約',
  'mypage': 'マイページ',
  'logout': 'ログアウト',
  
  /* Common buttons */
  'common.save': '保存',
  'common.cancel': 'キャンセル',
  'common.confirm': '確認',
};
```

#### Screen-specific Translations (pages/[screen]/[screen].ja.js)

Include ONLY:
- Content area text
- Screen-specific buttons
- Screen-specific messages
- Screen-specific labels

Example:
```javascript
// pages/board/board.ja.js
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.ja = window.I18nData.translations.ja || {};

Object.assign(window.I18nData.translations.ja, {
  'board.title': '掲示板',
  'board.post': '投稿',
  'board.description': '住民同士のコミュニケーション',
  'board.category.all': 'すべて',
  /* other board-specific keys */
});
```

### HTML Loading Order

Correct order in HTML:

```html
<body>
  <!-- 1. Common translations (header, footer) -->
  <script src="../../js/i18n/langs/common.ja.js"></script>
  <script src="../../js/i18n/langs/common.en.js"></script>
  <script src="../../js/i18n/langs/common.zh.js"></script>

  <!-- 2. Screen-specific translations (content area) -->
  <script src="board.ja.js"></script>
  <script src="board.en.js"></script>
  <script src="board.zh.js"></script>

  <!-- 3. Common features (REQUIRED: translator, language-switcher, footer-navigation) -->
  <script src="../../js/features/translator.js"></script>
  <script src="../../js/features/language-switcher.js"></script>
  <script src="../../js/features/footer-navigation.js"></script>

  <!-- 4. Screen-specific logic -->
  <script src="board.js"></script>
</body>
```

CRITICAL: Load Order Rules
- Translation data (steps 1-2) MUST load BEFORE feature modules (step 3)
- footer-navigation.js is REQUIRED for all screens (not optional)
- Incorrect order causes translation failures requiring cache clear (Ctrl+Shift+R)

### File Size Guidelines

Maximum file sizes:
- Common translation file: approx 100 lines (approx 10 keys)
- Screen translation file: approx 60 lines (approx 20 keys)
- Total per screen: 180 lines (well under 300-line limit)

### Migration from Old Structure

If you find old structure with consolidated ja.js, en.js, zh.js:

1. Extract common keys => common.ja.js, common.en.js, common.zh.js
2. Extract screen keys => [screen].ja.js, [screen].en.js, [screen].zh.js
3. Delete old consolidated files
4. Update all HTML files to load new structure

### Prevention Checklist

Before adding translation keys:

- [OK] Is this key used in header/footer? => Add to common.[lang].js
- [OK] Is this key used in content area? => Add to [screen].[lang].js
- [OK] Added to ALL 3 language files? (ja, en, zh)
- [OK] Files under 300 lines?
- [OK] HTML loads common translations first?

---

## Rule 5: 3-Layer Structure Consistency and Translation System Initialization

### The 3-Layer Design Principle

All screens (except index.html) MUST follow unified 3-layer structure:

```html
<header class="page-header">        <!-- Layer 1: Common, Unified -->
  ...
</header>

<main class="page-content">         <!-- Layer 2: Screen-specific -->
  <div class="content-container">
    <!-- YOUR CUSTOM CONTENT HERE -->
  </div>
</main>

<footer class="page-footer">        <!-- Layer 3: Common, Unified -->
  ...
</footer>
```

IMPORTANT: Only Layer 2 can be customized. Layers 1 and 3 MUST use unified class names.

### Why Layer 1 and Layer 3 Are Critical

Common feature modules depend on unified Layer 1/3 structure:

Modules affected:
- translator.js
- language-switcher.js
- footer-navigation.js

What These Modules Expect:
- Layer 1: <header class="page-header"> with language switcher buttons
- Layer 3: <footer class="page-footer"> with footer navigation buttons
- NOT: Custom inline HTML with Tailwind utility classes

### The Problem: Custom Header/Footer

If Layer 1 or Layer 3 use custom HTML (Tailwind classes):

```html
<!-- WRONG: Custom inline HTML breaks translator.js -->
<header class="bg-white shadow-sm">
  <div class="flex items-center justify-between">
    <h1 class="text-xl font-bold">Board</h1>
    <div class="flex gap-2">
      <button class="px-3 py-1 rounded bg-blue-500 text-white">JA</button>
    </div>
  </div>
</header>
```

Results:
1. Translator.js cannot find .page-header container
2. Language switcher initialization fails
3. Translation system queues changes but doesn't apply them immediately
4. Content area translations remain cached
5. User must press Ctrl+Shift+R to see translations (SYMPTOM)

### The Solution: Use Unified Structure

```html
<!-- CORRECT: Unified structure - translator.js works -->
<header class="page-header">
  <div class="page-header__container">
    <h1 class="header-title" data-i18n="board.title">Board</h1>
    <div class="language-switcher">
      <button class="lang-btn" data-lang="ja">JA</button>
      <button class="lang-btn" data-lang="en">EN</button>
      <button class="lang-btn" data-lang="zh">ZH</button>
    </div>
  </div>
</header>
```

Results:
- Translator.js finds .page-header container
- Language switcher initializes correctly
- Content area translations render immediately
- No cache clear needed
- Consistent behavior across all screens

### Reference Pattern

ALWAYS use home.html as template - proven working 3-layer structure.

Location: pages/home/home.html

Copy and modify ONLY the <main class="page-content"> section.

### Common Mistakes to Avoid

Mistake 1: Using Tailwind classes in Layer 1/3
```html
<!-- WRONG -->
<header class="bg-white shadow-sm border-b">
  <div class="max-w-4xl mx-auto px-4 py-4 flex justify-between">
```

Mistake 2: Custom header structure
```html
<!-- WRONG -->
<header>
  <div class="my-header">
    <h1>Title</h1>
  </div>
</header>
```

Mistake 3: Using different class names for same component
```html
<!-- WRONG -->
Screen 1: <header class="page-header"> ... </header>
Screen 2: <header class="app-header"> ... </header>
```

### JavaScript Loading Order (Related to Rule 5)

Correct order matters for translator.js to work:

```html
<!-- 1. Translation data FIRST -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>
<script src="board.ja.js"></script>
<script src="board.en.js"></script>
<script src="board.zh.js"></script>

<!-- 2. Feature modules SECOND (depend on unified structure) -->
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/footer-navigation.js"></script>

<!-- 3. Screen logic LAST -->
<script src="board.js"></script>
```

Why this order:
- Translator.js needs to find language switcher buttons (Layer 1)
- Translator.js needs to find footer buttons (Layer 3)
- Both depend on unified class names

### Prevention Checklist

Before generating any screen:

- [OK] Header uses class="page-header" (NOT custom Tailwind)
- [OK] Footer uses class="page-footer" (NOT custom Tailwind)
- [OK] Header/Footer structure matches home.html template exactly
- [OK] ONLY Layer 2 (content area) customized
- [OK] All 3 feature modules loaded (translator, language-switcher, footer-navigation)
- [OK] JavaScript load order correct (translation data => features => screen logic)
- [OK] No hardcoded language switcher buttons in custom header
- [OK] No custom footer navigation buttons

### Troubleshooting

Symptom: Translations don't work until Ctrl+Shift+R is pressed

Causes (in order of likelihood):
1. Custom header/footer structure (not using page-header/page-footer classes)
2. Feature modules loaded in wrong order
3. Feature modules not loaded at all
4. Translation data not loaded before feature modules

Solution: Compare HTML structure with home.html template and match exactly

---

## Summary

### Five Critical Rules

1. CSS Variables => Define before use, check variables.css
2. Translation Keys => Always 3-language set (ja/en/zh)
3. CSS Placement => Common vs Screen-specific decision
4. Translation Files => Screen-based split, not global consolidation
5. 3-Layer Structure => Unified Layers 1/3, custom Layer 2 only

### Impact

Following these rules prevents:
- Silent layout failures
- Raw key display in UI
- Style duplication and maintenance issues
- Inconsistent behavior across screens
- Massive translation files (violating 300-line rule)
- Merge conflicts in translation files
- Translation system failures requiring cache clear
- Translator.js initialization errors

### Next Steps

When generating code:

1. Review this file FIRST
2. Apply all five rules
3. Use checklists for verification
4. Test thoroughly
5. Compare with reference patterns (home.html)

---

## Related Documentation

- **naming-conventions-v2.1.md** - Naming conventions and file structure rules
- **05_Project-Structure-v3.3.md** - Complete directory structure and file placement
- **File-Modification-Checklist.md** - Checklist for modifying existing files
- **Claude-Skill-Creation-Guide-v2.0.md** - Guide for creating Claude skills

---

**Last Updated:** 2025/10/26  
**Version:** 2.1  
**Charset:** ASCII safe (UTF-8 compatible)  
**Document ID:** SEC-APP-CODE-GENERATION-RULES-001
