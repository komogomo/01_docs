# SECUREA City Smart Communication App
## Development Guidelines - Coding Standards and Design Principles

**Document Version:** 2.0 (Full English)  
**Created:** 2025/10/24  
**Last Updated:** 2025/10/24  
**Audience:** All developers, AI-assisted development  

---

## Table of Contents

1. [Basic Policy](#1-basic-policy)
2. [HTML Coding Standards](#2-html-coding-standards)
3. [CSS Coding Standards](#3-css-coding-standards)
4. [JavaScript Coding Standards](#4-javascript-coding-standards)
5. [Design Principles](#5-design-principles)
6. [Prohibited Items](#6-prohibited-items)
7. [Recommended Tools](#7-recommended-tools)

---

## 1. Basic Policy

### 1.0 File Header Comment [REQUIRED]

**Every code file must have header information at the top.**

#### HTML Files
```html
<!--
  File: /index.html
  Screen: Login Screen
-->
<!DOCTYPE html>
<html lang="ja">
...
```

#### CSS/JavaScript Files
```css
/**
 * File: /css/variables.css
 * Purpose: CSS Variable Definitions
 * 
 * Centrally manage all colors, sizes, and spacing
 */
```

```javascript
/**
 * File: /js/main.js
 * Purpose: Main Logic
 * Screen: Login Screen (if applicable)
 * 
 * Login screen processing
 */
```

#### Required Information
1. **File path** - Relative path from project root
2. **File/Screen name** - File role or screen name
3. **Description** - Purpose and function summary

#### Purpose
- Instantly identify file location and role
- Prevent confusion in multi-person development
- Clarify context for AI-assisted development

---

### 1.1 Top Priorities

This project prioritizes:

1. **Maintainability** - Easy to modify
2. **Readability** - Easy to understand
3. **Reliability** - Works correctly

**Debugging ease > Design beauty**

### 1.2 Development Philosophy

```
Complex code with perfect design    ✗ Avoid
Simple code with sufficient design  ✓ Recommended
```

### 1.3 Three-Click Rule

All code follows these limits:

- One HTML file: **≤300 lines**
- One CSS class: **≤10 properties**
- One JS function: **≤30 lines**

If exceeded, consider splitting.

---

## 2. HTML Coding Standards

### 2.1 Basic Structure

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Title</title>
    <link rel="stylesheet" href="css/custom.css">
</head>
<body>
    <header class="page-header">
        <!-- Header content -->
    </header>

    <main class="page-main">
        <!-- Page-specific content -->
    </main>

    <footer class="page-footer">
        <!-- Footer content (if needed) -->
    </footer>

    <script src="js/app.js"></script>
</body>
</html>
```

### 2.2 Semantic HTML

Use meaningful tags:

```html
<!-- ✓ Good -->
<header>Header</header>
<nav>Navigation</nav>
<main>Main content</main>
<section>Section</section>
<article>Article</article>
<aside>Sidebar</aside>
<footer>Footer</footer>

<!-- ✗ Bad -->
<div class="header">Header</div>
<div class="nav">Navigation</div>
```

### 2.3 Class Naming (BEM)

```html
<!-- Block -->
<div class="post-card">
    <!-- Element -->
    <div class="post-card__header">
        <span class="post-card__category">Official</span>
        <span class="post-card__date">2025/10/24</span>
    </div>
    <h3 class="post-card__title">Title</h3>
    <p class="post-card__content">Content</p>
    
    <!-- Modifier -->
    <button class="post-card__button post-card__button--primary">
        Confirm
    </button>
</div>
```

**Naming Rules:**
- Block: `block-name` (kebab-case)
- Element: `block-name__element-name` (double underscore)
- Modifier: `block-name--modifier-name` (double hyphen)

### 2.4 Data Attributes

Use `data-*` for JavaScript operations:

```html
<div class="post-card" data-category="official" data-post-id="12345">
    <!-- Content -->
</div>
```

### 2.5 Accessibility

```html
<!-- Buttons with labels -->
<button aria-label="Back">←</button>

<!-- Images with alt text -->
<img src="image.jpg" alt="Parking map">

<!-- Forms with labels -->
<label for="email">Email</label>
<input type="email" id="email" name="email">
```

---

## 3. CSS Coding Standards

### 3.1 CSS Variables

Define all values in variables.css:

```css
:root {
    /* Colors */
    --color-primary: #4A90E2;
    --color-secondary: #7B68EE;
    
    /* Spacing */
    --spacing-1: 0.25rem;
    --spacing-2: 0.5rem;
    
    /* Typography */
    --font-size-base: 16px;
    --font-size-lg: 18px;
}
```

### 3.2 BEM Notation

```css
/* Block */
.post-card { }

/* Element */
.post-card__title { }

/* Modifier */
.post-card--featured { }

/* State class */
.is-active { }
```

### 3.3 Prohibited

❌ **`!important` usage**
❌ **Deep nesting** (max 3 levels)
❌ **Inline styles**
❌ **Magic numbers** (use variables)

### 3.4 CSS Load Order (STRICT)

```html
1. Tailwind CDN
2. variables.css
3. reset.css
4. base.css
5. common/*.css
6. [screen].css
```

**Never change this order!**

---

## 4. JavaScript Coding Standards

### 4.1 Naming Conventions

```javascript
// Functions: camelCase
function initLanguageSwitcher() { }

// Classes: PascalCase
class LanguageSwitcher { }

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRY_COUNT = 3;

// Variables: camelCase
let currentLanguage = 'ja';
```

### 4.2 Global Variables

**Must attach to window and capitalize:**

```javascript
✓ window.LanguageSwitcher
✓ window.Translator
✓ window.I18nData

✗ languageSwitcher
✗ window.translator
```

### 4.3 Function Guidelines

- Max 30 lines per function
- Single responsibility
- Descriptive names
- Start with verbs (init, get, set, update)

### 4.4 Comments

```javascript
/**
 * Initialize language switcher
 * 
 * @param {string} defaultLang - Default language (ja/en/zh)
 * @returns {void}
 */
function initLanguageSwitcher(defaultLang) {
    // Implementation
}
```

---

## 5. Design Principles

### 5.1 Mobile First

Design for mobile, then scale up:

```css
/* Mobile (default) */
.container {
    padding: 1rem;
}

/* Tablet and up */
@media (min-width: 768px) {
    .container {
        padding: 2rem;
    }
}
```

### 5.2 Responsive Design

Use flexible units:
- `rem` for font sizes
- `%` or `vw/vh` for layout
- `max-width` for containers

### 5.3 Color Contrast

Ensure WCAG AA compliance:
- Text on background: ≥4.5:1
- Large text: ≥3:1

---

## 6. Prohibited Items

### Absolutely Forbidden

1. **`!important` in CSS** - Causes specificity issues
2. **Underscore file names** - Use kebab-case
3. **Capitalized file names** - All lowercase
4. **Global vars without window** - Pollutes scope
5. **Inline styles** - Use classes
6. **Changing CSS load order** - Breaks cascade
7. **Editing header/footer** - Common areas off-limits

---

## 7. Recommended Tools

### Development Environment

- **Editor:** Visual Studio Code
- **OS:** WSL2 + Ubuntu 22.04 / macOS / Linux
- **Node.js:** LTS version (22.20.0)

### VS Code Extensions

- ESLint - JavaScript linter
- Prettier - Code formatter
- Tailwind CSS IntelliSense - CSS completion
- Auto Rename Tag - HTML tag auto-rename
- Live Server - Live reload

### Code Format Settings

```json
{
    "semi": true,
    "singleQuote": true,
    "tabWidth": 4,
    "trailingComma": "es5",
    "printWidth": 100,
    "arrowParens": "avoid"
}
```

---

## 8. Checklist

### Pre-Commit Checklist

- □ HTML file ≤300 lines?
- □ CSS class ≤10 properties?
- □ JS function ≤30 lines?
- □ No `!important`?
- □ Global variables minimized?
- □ Dead code removed?
- □ CSS variables used?
- □ Semantic HTML used?

### Review Checklist

- □ Code readable?
- □ Easy to modify?
- □ Easy to debug?
- □ Minimal features? (No over-engineering)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025/10/24 | Full English translation |
| 1.1 | 2025/10/24 | Added file header rule |
| 1.0 | 2025/10/24 | Initial version |

---

**Document ID:** SEC-APP-GUIDELINE-001  
**Last Updated:** 2025/10/24  
**Approved by:** ____________________
