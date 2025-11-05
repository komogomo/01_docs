# Naming Conventions v2.1 (English Edition)

**Version:** 2.1  
**Created:** 2025/10/24  
**Last Updated:** 2025/10/26  
**Purpose:** Unified naming conventions for SECUREA City Smart Communication App

---

## 1. File Naming Basic Rules

### 1.1 Code/Screen Files: Kebab-case (Hyphen-separated)

**Target:** HTML, CSS, JS (screen implementation files)

```
✓ home.html
✓ language-switcher.js
✓ footer-navigation.css

✗ Home.html (uppercase NG)
✗ languageSwitcher.js (camelCase NG)
✗ footer_navigation.css (underscore NG)
```

**Rules:**
- All lowercase
- Words separated by hyphens (-)
- No underscores or camelCase

---

### 1.2 Documentation Files: Version Management Required

**Target:** Technical documents, design specs, guides (.md files)

**Pattern:** `[document-name]-v[MAJOR].[MINOR].md`

**Examples:**
```
✓ code-generation-rules-v2.1.md
✓ home-refactoring-guide-v2.3.md
✓ naming-conventions-v2.1.md
✓ 05_Project-Structure-v3.3.md

✗ code-generation-rules.md (no version)
✗ code-generation-rules-v2_1.md (underscore used)
```

**Important Exception:**
- `SKILL.md` is a special filename and must NOT have version suffix
- Version info managed in file metadata instead

**Version Management Difference:**
- **Code/Screen Files:** Managed via Git commit history (no version in filename)
- **Documentation Files:** MUST include version number in filename

---

## 2. Screen-Specific File Naming Rules

### 2.1 Directory Structure

```
pages/[screen-name]/
├── [screen-name].html          ← Main HTML (required, single file)
├── [screen-name].css           ← Base styles
├── [screen-name].js            ← Base scripts
├── [screen-name].ja.js         ← Japanese translations
├── [screen-name].en.js         ← English translations
├── [screen-name].zh.js         ← Chinese translations
├── [screen-name]-[feature].css ← Additional styles (when features grow)
└── [screen-name]-[feature].js  ← Additional scripts (when features grow)
```

---

### 2.2 Naming Patterns

**HTML Files (required, single file only):**
- Pattern: `[screen-name].html`
- Examples: `home.html`, `board.html`, `booking.html`

**CSS/JS Files (can be split by feature):**
- Base file: `[screen-name].css`, `[screen-name].js`
- Feature-specific: `[screen-name]-[feature].css`, `[screen-name]-[feature].js`

**Feature Name Examples:**
- `board-editor.css` - post editing styles
- `board-modal.js` - modal functionality
- `home-dashboard.css` - dashboard display
- `booking-calendar.js` - calendar functionality

---

### 2.3 Translation File Naming Rules

**Pattern:** `[screen-name].[lang].js`

**Supported Languages:**
- `ja` - Japanese
- `en` - English
- `zh` - Chinese Simplified

**Examples:**
```
pages/home/
├── home.ja.js    ← Japanese translation data
├── home.en.js    ← English translation data
└── home.zh.js    ← Chinese translation data

pages/board/
├── board.ja.js
├── board.en.js
└── board.zh.js
```

**Common Translation Files (for header/footer):**
```
js/i18n/langs/
├── common.ja.js  ← Common Japanese translations
├── common.en.js  ← Common English translations
└── common.zh.js  ← Common Chinese translations
```

**Rules:**
- Create 3-language set (ja/en/zh) for each screen
- Language code must be lowercase 2 characters
- Extension is `.js` (not JSON format)

---

### 2.4 File Splitting Guidelines

**When to Split:**
- Single file exceeds **300 lines**
- Functionally independent components exist

**How to Split:**
- Split by feature (e.g., `-editor`, `-modal`, `-calendar`)
- Keep related features together

**Examples:**
```
✓ board.js (250 lines)
✓ board-editor.js (150 lines)
✓ board-modal.js (100 lines)

✗ board-part1.js (unclear feature split)
✗ board-v2.js (version-based split)
```

---

### 2.5 Important Notes When Modifying Existing Files

**CRITICAL:** When modifying existing files, **maintain the original filename**

```
✓ Modify header.css → Save as header.css
✓ Modify footer.js → Save as footer.js

✗ Save as header-fixed.css
✗ Save as header-v2.css
✗ Save as header_new.css
```

**Reason:**
- Code/screen file version history is managed via Git commits
- Adding version to filename requires updating all references (link tags in HTML), increasing regression risk

---

## 3. Global Variables: window.PascalCase

When defining global variables in JavaScript, always store in `window` object and use PascalCase (uppercase first letter).

```javascript
✓ window.LanguageSwitcher = ...;
✓ window.Translator = ...;
✓ window.I18nData = ...;

✗ languageSwitcher = ...;  (no window)
✗ window.translator = ...;  (lowercase first)
```

**Reason:**
- Prevents global scope pollution
- Avoids naming conflicts with other libraries
- Makes global variable status explicit

**Example:**
```javascript
// ✓ Correct
window.LanguageManager = {
  currentLang: 'ja',
  setLanguage: function(lang) { ... }
};

// ✗ Wrong
var languageManager = { ... };  // Global scope pollution
```

---

## 4. CSS Classes: BEM Notation

Use BEM (Block Element Modifier) notation for CSS class naming.

```css
/* Block: hyphen-separated */
.footer-nav { }

/* Element: double underscore */
.footer-nav__button { }

/* Modifier: double hyphen */
.footer-nav__button--active { }

/* State class: is- prefix */
.is-active { }
```

**BEM Benefits:**
- Structure visible from class name
- Avoids CSS specificity issues
- Easy component reuse
- Prevents deep nesting

**Concrete Example:**
```html
<footer class="page-footer">
  <nav class="footer-nav">
    <a href="#" class="footer-nav__button footer-nav__button--active">
      <span class="footer-nav__icon">🏠</span>
      <span class="footer-nav__label">Home</span>
    </a>
  </nav>
</footer>
```

```css
/* Block */
.footer-nav {
  display: flex;
}

/* Element */
.footer-nav__button {
  display: flex;
  flex-direction: column;
}

/* Modifier */
.footer-nav__button--active {
  color: var(--color-primary);
}
```

**Important Notes:**
- BEM is 3 levels max (Block__Element--Modifier)
- Don't create Element within Element (`.block__elem1__elem2` is NG)
- If deep nesting needed, define as new Block

---

## 5. JavaScript Functions & Variables

### 5.1 Function Names: camelCase

```javascript
✓ function initLanguageSwitcher() { }
✓ function updateDynamicContent() { }
✓ function handleButtonClick() { }

✗ function InitLanguageSwitcher() { }  // PascalCase (for classes)
✗ function init_language_switcher() { } // snake_case
```

---

### 5.2 Class Names: PascalCase

```javascript
✓ class LanguageSwitcher { }
✓ class TranslationManager { }
✓ class PostRenderer { }

✗ class languageSwitcher { }  // camelCase (for functions)
✗ class language_switcher { } // snake_case
```

---

### 5.3 Constants: SCREAMING_SNAKE_CASE

```javascript
✓ const MAX_RETRY_COUNT = 3;
✓ const DEFAULT_LANGUAGE = 'ja';
✓ const API_BASE_URL = 'https://api.example.com';

✗ const maxRetryCount = 3;  // camelCase
✗ const MaxRetryCount = 3;  // PascalCase
```

---

### 5.4 Local Variables: camelCase

```javascript
✓ let currentLanguage = 'ja';
✓ const postList = [];
✓ const isActive = true;

✗ let CurrentLanguage = 'ja';  // PascalCase
✗ const post_list = [];        // snake_case
```

---

### 5.5 Naming Best Practices

**Function Names:**
- Start with verb (init, get, set, update, render, handle, etc.)
- Examples: `initHomePage()`, `getUserData()`, `setLanguage()`, `updateDynamicContent()`

**Variable Names:**
- Clearly express content
- Avoid abbreviations (`usr` → `user`, `msg` → `message`)

**Boolean Variables:**
- Start with `is`, `has`, `should`, `can`
- Examples: `isActive`, `hasError`, `shouldUpdate`, `canEdit`

**Arrays/Lists:**
- Use plural form
- Examples: `posts`, `users`, `items`, `translations`

**Objects:**
- Use singular form
- Examples: `post`, `user`, `config`, `translationData`

**Names to Avoid:**
```javascript
✗ let d = new Date();           // Unclear
✓ let currentDate = new Date(); // Clear

✗ function proc() { }           // Too abstract
✓ function processUserData() { } // Specific

✗ let tmp = getData();          // Even temp vars need meaningful names
✓ let fetchedPosts = getData(); // Clear
```

---

## 6. Summary

### 6.1 Quick Reference

| Target | Format | Examples |
|--------|--------|----------|
| HTML files | kebab-case | `home.html`, `board-detail.html` |
| CSS files | kebab-case | `home.css`, `footer-navigation.css` |
| JS files | kebab-case | `home.js`, `language-switcher.js` |
| Translation files | kebab-case + lang | `home.ja.js`, `board.en.js` |
| Documentation | kebab-case + version | `code-generation-rules-v2.1.md` |
| Function names | camelCase | `initLanguageSwitcher()` |
| Class names | PascalCase | `LanguageManager` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Local variables | camelCase | `currentLanguage` |
| Global variables | window.PascalCase | `window.I18nData` |
| CSS Classes (Block) | kebab-case | `.footer-nav` |
| CSS Classes (Element) | Block__element | `.footer-nav__button` |
| CSS Classes (Modifier) | Element--modifier | `.footer-nav__button--active` |

---

### 6.2 Checklist

When creating new files:
- [ ] Is filename in kebab-case?
- [ ] Does documentation file have version number?
- [ ] Are all 3 translation files (ja/en/zh) present?

When coding:
- [ ] Are global variables in window.PascalCase format?
- [ ] Do CSS classes follow BEM notation?
- [ ] Do function names start with verbs?
- [ ] Do Boolean variables start with is/has/should?

When modifying existing files:
- [ ] Is original filename maintained? (No version number added?)
- [ ] If exceeding 300 lines, split by feature?

---

## 7. Related Documentation

- **05_Project-Structure-v3.3.md** - Directory structure and file placement rules
- **code-generation-rules-v2.1.md** - Mandatory rules for code generation
- **File-Modification-Checklist.md** - Checklist for file modifications
- **SKILL.md** - Basic development standards (securea-dev-standards)

---

**Document ID:** SEC-APP-NAMING-CONVENTIONS-001  
**Version:** 2.1  
**Last Updated:** 2025/10/26
