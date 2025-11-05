# SECUREA City Project Structure and File Placement Rules v3.3 (English Edition)

## Overview

This document defines the complete directory structure and file placement rules for the SECUREA City Smart Communication App static HTML prototype.

**Created:** 2025/10/24  
**Version:** 3.3  
**Last Updated:** 2025/10/26  
**Target:** Static HTML prototype (securea-static-work)  
**Changes in v3.3:** Integrated detailed implementation status and screen plan from Directory-Structure document

---

## Version History

### v3.3 (2025/10/26)
- **Integration**: Merged Directory-Structure-v1.2 content into this document
- **Added**: Implementation Status Summary
- **Added**: Screen Implementation Plan with detailed progress
- **Added**: Quick Reference section for common tasks
- **Enhanced**: Path specification rules with more examples

### v3.2 (2025/10/25)
- **Translation File Structure Update**: Changed to screen-based split
- **Reason**: Avoid violating 300-line rule (24 screens × 20 keys = 480 keys per file)
- **Changes**: `js/i18n/langs/*.js` → `common.[lang].js` + `pages/[screen]/[screen].[lang].js`
- **Fixed**: Translation data structure (window.I18nData.translations)
- **Clarified**: templates/ directory status (DEPRECATED)

### v3.1 (2025/10/25)
- **CSS Path Correction**: Changed to `css/common/` directory
- **Reason**: Actual implementation uses `css/common/` directory
- **Files affected**: Path examples throughout document

### v3.0 (2025/10/24)
- Full English translation

### v2.1 (2025/10/24)
- Tailwind CDN, logout button added

### v2.0 (2025/10/24)
- Screen-specific files in same directory

### v1.0 (2025/10/24)
- Initial version

---

## 1. Project Root Directory

```
D:/seurea-static_dev/securea-static-work/
```

**Important:** Always work in this directory. Copy to GitHub repo after completion.

---

## 2. Complete Directory Structure

```
D:/seurea-static_dev/securea-static-work/
├── index.html                              # Login screen (exception)
│
├── templates/                              # Template files (DEPRECATED - use skill template)
│   └── page-template.html                  # Local template (delete recommended)
│
├── css/                                    # Common stylesheets only
│   ├── variables.css                       # CSS variables
│   ├── reset.css                           # CSS reset
│   ├── base.css                            # Base styles
│   │
│   └── common/                             # Common components
│       ├── button.css                      # Buttons (language switcher, etc.)
│       ├── header.css                      # Header
│       ├── footer.css                      # Footer
│       └── layout.css                      # Layout
│
├── js/                                     # Common JavaScript only
│   ├── i18n/                               # Internationalization
│   │   └── langs/                          # Common translation data only
│   │       ├── common.ja.js                # Common Japanese (header, footer, buttons)
│   │       ├── common.en.js                # Common English
│   │       └── common.zh.js                # Common Chinese
│   │
│   └── features/                           # Independent features
│       ├── language-switcher.js           # Language switcher
│       ├── translator.js                  # Translation helper
│       └── footer-navigation.js           # Footer navigation
│
└── pages/                                  # Screen directories
    ├── home/                               # Home screen
    │   ├── home.html
    │   ├── home.css
    │   ├── home.js
    │   ├── home.ja.js                      # Home Japanese translations
    │   ├── home.en.js                      # Home English translations
    │   └── home.zh.js                      # Home Chinese translations
    │
    ├── board/                              # Board (BBS)
    │   ├── board.html
    │   ├── board.css
    │   ├── board.js
    │   ├── board.ja.js                     # Board Japanese translations
    │   ├── board.en.js                     # Board English translations
    │   ├── board.zh.js                     # Board Chinese translations
    │   ├── board-detail.html
    │   ├── board-detail.css
    │   ├── board-detail.js
    │   ├── board-detail.ja.js              # Detail Japanese translations
    │   ├── board-detail.en.js              # Detail English translations
    │   ├── board-detail.zh.js              # Detail Chinese translations
    │   ├── board-post.html
    │   ├── board-post.css
    │   ├── board-post.js
    │   ├── board-post.ja.js                # Post Japanese translations
    │   ├── board-post.en.js                # Post English translations
    │   └── board-post.zh.js                # Post Chinese translations
    │
    ├── booking/                            # Parking booking
    │   ├── booking.html
    │   ├── booking.css
    │   ├── booking.js
    │   ├── booking.ja.js
    │   ├── booking.en.js
    │   ├── booking.zh.js
    │   ├── booking-confirm.html
    │   ├── booking-confirm.css
    │   ├── booking-confirm.js
    │   ├── booking-confirm.ja.js
    │   ├── booking-confirm.en.js
    │   ├── booking-confirm.zh.js
    │   ├── booking-complete.html
    │   ├── booking-complete.css
    │   ├── booking-complete.js
    │   ├── booking-complete.ja.js
    │   ├── booking-complete.en.js
    │   └── booking-complete.zh.js
    │
    └── mypage/                             # My page
        ├── mypage.html
        ├── mypage.css
        ├── mypage.js
        ├── mypage.ja.js
        ├── mypage.en.js
        └── mypage.zh.js
```

---

## 3. Implementation Status Summary

| Category | Implemented | Not Implemented | Notes |
|----------|-------------|-----------------|-------|
| **Login** | ✅ index.html | - | Root placement (exception) |
| **Template** | ✅ templates/* | - | DEPRECATED - use skill template |
| **Common CSS** | ✅ 7 files | - | variables, reset, base, common/* |
| **Common JS** | ✅ 6 files | - | features/*, i18n/langs/* |
| **Translation Data** | ✅ 3 languages | - | common.[lang].js + screen.[lang].js (screen-based split) |
| **Screen Implementation** | ✅ home | 23 screens | Only home implemented, needs refactoring |

---

## 4. Screen List (Total: 24 Screens)

### ✅ Implemented Screens (2 screens)

#### 1. Login & Authentication
- ✅ **index.html** - Login screen (Magic link method)

#### 2. Dashboard
- ✅ **home** - Home/Dashboard
  - ⚠️ Status: Legacy structure (352 lines)
  - 🔧 Action needed: Follow `home-refactoring-guide.md`

---

### 🔲 Not Yet Implemented (22 screens)

#### 3. Notices & Bulletin Board (4 screens)
- ⬜ **notice** - Notice list
- ⬜ **notice-detail** - Notice detail
- ⬜ **bulletin** - Bulletin board list
- ⬜ **bulletin-detail** - Bulletin board detail

#### 4. BBS (Board) (3 screens)
- ⬜ **board** - Board list
- ⬜ **board-detail** - Thread detail
- ⬜ **board-post** - New post

#### 5. Parking Reservation (6 screens)
- ⬜ **booking** - Reservation calendar
- ⬜ **booking-map** - Parking map
- ⬜ **booking-confirm** - Reservation confirmation
- ⬜ **booking-complete** - Reservation complete
- ⬜ **booking-history** - Reservation history
- ⬜ **booking-detail** - Reservation detail

#### 6. Survey (3 screens)
- ⬜ **survey** - Survey list
- ⬜ **survey-detail** - Survey answer form
- ⬜ **survey-complete** - Answer complete

#### 7. Settings (2 screens)
- ⬜ **settings** - Settings
- ⬜ **notification-settings** - Notification settings

#### 8. My Page (1 screen)
- ⬜ **mypage** - My page

#### 9. Admin (3 screens)
- ⬜ **admin** - Admin dashboard
- ⬜ **admin-user** - User management
- ⬜ **admin-survey** - Survey management

---

## 5. File Placement Rules

### 5.1 Basic Principle

**Screen-specific files (HTML/CSS/JS/translations) in same directory**

```
pages/[screen-name]/
├── [screen-name].html
├── [screen-name].css
├── [screen-name].js
├── [screen-name].ja.js        # Japanese translations
├── [screen-name].en.js        # English translations
└── [screen-name].zh.js        # Chinese translations
```

**Example:**
```
pages/home/
├── home.html
├── home.css
├── home.js
├── home.ja.js
├── home.en.js
└── home.zh.js
```

### 5.2 HTML Files

**Location:** `pages/[category]/[screen-name].html`

**Naming:**
- All lowercase
- Hyphen-separated (kebab-case)
- Extension: `.html`

### 5.3 CSS Files

**Screen-specific:** `pages/[category]/[screen-name].css`
**Common:** `css/common/[component].css`
- button.css
- header.css
- footer.css
- layout.css

**Important:** Screen-specific CSS in same directory as HTML

### 5.4 JavaScript Files

**Screen-specific:** `pages/[category]/[screen-name].js`
**Common features:** `js/features/[feature].js`
- language-switcher.js
- translator.js
- footer-navigation.js

**Important:** Screen-specific JS in same directory as HTML

### 5.5 Translation Data

#### Common Translations
**Location:** `js/i18n/langs/common.[lang].js`

**Files:**
- common.ja.js (Japanese)
- common.en.js (English)
- common.zh.js (Chinese)

**Content:** Header, footer, buttons only

#### Screen-specific Translations
**Location:** `pages/[screen]/[screen].[lang].js`

**Files per screen:**
- [screen].ja.js (Japanese)
- [screen].en.js (English)
- [screen].zh.js (Chinese)

**Content:** Content area text only

**Important:** 
- Common translations: Shared across all screens (header, footer, navigation)
- Screen translations: Specific to each screen (content area)
- This split prevents files from exceeding 300-line rule

---

## 6. Path Specification Rules

### Pattern A: Screen-specific file → Common files

**Location:** `/pages/home/home.html`

```html
<!-- CSS Loading -->
<link rel="stylesheet" href="../../css/variables.css">
<link rel="stylesheet" href="../../css/base.css">
<link rel="stylesheet" href="../../css/common/button.css">
<link rel="stylesheet" href="../../css/common/header.css">
<link rel="stylesheet" href="../../css/common/footer.css">
<link rel="stylesheet" href="../../css/common/layout.css">
<link rel="stylesheet" href="home.css"> <!-- Own screen CSS -->

<!-- JavaScript Loading -->
<!-- 1. Common translations (header, footer) -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>

<!-- 2. Screen-specific translations (content area) -->
<script src="home.ja.js"></script>
<script src="home.en.js"></script>
<script src="home.zh.js"></script>

<!-- 3. Common features (REQUIRED: translator, language-switcher, footer-navigation) -->
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/footer-navigation.js"></script>

<!-- 4. Screen-specific logic -->
<script src="home.js"></script> <!-- Own screen JS -->
```

**Key Points:**
- Use `../../` to go up 2 levels (`/pages/home/` → `/`)
- Own screen's CSS/JS: filename only (no relative path needed)

---

### Pattern B: Inter-screen Links (Footer Navigation)

**From:** `/pages/home/home.html`  
**To:** `/pages/board/board.html`

```html
<a href="../board/board.html" class="footer-nav-btn" data-page="board">
  <span class="footer-nav-icon">💬</span>
  <span class="footer-nav-label" data-i18n="board">Board</span>
</a>
```

**Key Points:**
- Use `../` to go up 1 level (`/pages/home/` → `/pages/`)
- Then specify directory and file: `board/board.html`

---

### Pattern C: Logout Link (Back to Root)

**From:** `/pages/home/home.html`  
**To:** `/index.html`

```html
<a href="../../index.html" class="footer-nav-btn footer-nav-btn--logout">
  <span class="footer-nav-icon">🚪</span>
  <span class="footer-nav-label" data-i18n="logout">Logout</span>
</a>
```

**Key Points:**
- Use `../../` to go up 2 levels to project root
- index.html is at root level

---

## 7. Loading Order Rules

### 1. index.html Exception

**Location:** Project root
- Only exception allowed

---

### 2. CSS Loading Order (STRICT - DO NOT CHANGE)

```html
<!-- 1. Tailwind CDN (ALWAYS FIRST) -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- 2. CSS Variables -->
<link rel="stylesheet" href="../../css/variables.css">

<!-- 3. CSS Reset (if exists) -->
<link rel="stylesheet" href="../../css/reset.css">

<!-- 4. Base Styles -->
<link rel="stylesheet" href="../../css/base.css">

<!-- 5. Common Components (in this order) -->
<link rel="stylesheet" href="../../css/common/button.css">
<link rel="stylesheet" href="../../css/common/header.css">
<link rel="stylesheet" href="../../css/common/footer.css">
<link rel="stylesheet" href="../../css/common/layout.css">

<!-- 6. Screen-specific CSS (LAST) -->
<link rel="stylesheet" href="[screen-name].css">
```

**Critical Rules:**
- ⚠️ NEVER change this order
- ⚠️ NEVER use `!important` in CSS
- ✅ ALWAYS place Tailwind CDN first
- ✅ ALWAYS place screen-specific CSS last

---

### 3. JavaScript Loading Order

```html
<!-- 1. Translation Data (FIRST) -->
<!-- Common translations (header, footer) -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>

<!-- Screen-specific translations (content area) -->
<script src="[screen-name].ja.js"></script>
<script src="[screen-name].en.js"></script>
<script src="[screen-name].zh.js"></script>

<!-- 2. Common Features (REQUIRED) -->
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/footer-navigation.js"></script>

<!-- 3. Screen-specific JavaScript (LAST) -->
<script src="[screen-name].js"></script>
```

**Critical Rules:**
- Translation data MUST be loaded before any feature scripts
- Common translations before screen-specific translations
- Screen-specific JS MUST be loaded last
- NO inline `<script>` tags (except for small helpers)

---

## 8. New Screen Creation Procedure

### Step 1: Create Directory
```bash
mkdir pages/[screen-name]/
```

### Step 2: Copy Template
**Source:** Use skill template (recommended) or copy from existing screen (e.g., home.html)

**Option A - From Skill (Recommended):**
Request Claude to generate template using securea-dev-standards skill

**Option B - From Existing Screen:**
```bash
cp pages/home/home.html pages/[screen-name]/[screen-name].html
cp pages/home/home.css pages/[screen-name]/[screen-name].css
cp pages/home/home.js pages/[screen-name]/[screen-name].js
```

### Step 3: Create Files
```bash
touch pages/[screen-name]/[screen-name].html
touch pages/[screen-name]/[screen-name].css
touch pages/[screen-name]/[screen-name].js
```

### Step 4: Create Translation Files
```bash
touch pages/[screen-name]/[screen-name].ja.js
touch pages/[screen-name]/[screen-name].en.js
touch pages/[screen-name]/[screen-name].zh.js
```

### Step 5: Edit HTML File

1. Update file header comment
2. Fix CSS load path (same directory)
3. Fix JS load path (same directory)
4. Fix translation file paths (same directory)
5. Edit content area (`<main>`) only

### Step 6: Add Translation Keys

Add to screen-specific translation files:
- `pages/[screen]/[screen].ja.js`
- `pages/[screen]/[screen].en.js`
- `pages/[screen]/[screen].zh.js`

**Do NOT add to** `js/i18n/langs/common.[lang].js` unless it's header/footer/button text

---

## 9. Translation Key Naming

### Format
```
[screen-id].[element]
or
[screen-id].[section].[element]
```

### Categories
- **title** - Screen title
- **content** - Content area
- **button** - Buttons
- **label** - Labels
- **message** - Messages
- **error** - Error messages

### Examples
```javascript
// Home screen (pages/home/home.ja.js)
window.I18nData = window.I18nData || { translations: {} };
Object.assign(window.I18nData.translations.ja, {
  'home.title': 'ホーム',
  'home.welcome': 'ようこそ',
  'home.content.message': 'メッセージ',
});

// Board (pages/board/board.ja.js)
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.ja = window.I18nData.translations.ja || {};
Object.assign(window.I18nData.translations.ja, {
  'board.title': '掲示板',
  'board.post': '投稿',
  'board.description': '住民同士のコミュニケーション',
});

// Common (js/i18n/langs/common.ja.js)
window.I18nData = window.I18nData || { translations: {} };
window.I18nData.translations.ja = {
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'booking': '施設予約',
  'mypage': 'マイページ',
  'logout': 'ログアウト',
};
```

---

## 10. File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **HTML files** | kebab-case | `board-detail.html` |
| **CSS files** | kebab-case | `board-detail.css` |
| **JS files** | kebab-case | `board-detail.js` |
| **CSS classes** | BEM notation | `.footer-nav-btn--active` |
| **JS variables** | camelCase | `currentLanguage` |
| **JS constants** | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| **JS functions** | camelCase | `initHomePage()` |
| **JS classes** | PascalCase | `LanguageManager` |
| **Global variables** | window.PascalCase | `window.LanguageManager` |

---

## 11. Common Rules

### 11.1 index.html Exception

- **Location:** Project root
- **Structure:** Custom (not 3-layer)
- **CSS/JS:** Inline OK
- **Changes:** Generally prohibited

### 11.2 Standard 3-Layer Structure

All screens (except index.html) follow:

1. **Header Area** (`<header class="page-header">`)
   - Common, do not edit
   - App name (logo)
   - Notification button
   - Language switcher
   - Screen title

2. **Content Area** (`<main class="page-content">`)
   - Screen-specific, editable
   - Customize this area only

3. **Footer Area** (`<footer class="page-footer">`)
   - Common, do not edit
   - Navigation buttons (5)
   - Logout button (right edge)

### 11.3 Tailwind CSS Usage

**All screens use Tailwind CDN:**
```html
<!-- Tailwind CDN -->
<script src="https://cdn.tailwindcss.com"></script>
```

- Place at top of `<head>` tag
- Can combine with custom CSS
- Same as index.html

### 11.4 File Header Comment (REQUIRED)

All HTML/CSS/JS files must have header comment:

```html
<!--
  File: /pages/[screen-name]/[screen-name].html
  Screen: [Screen Name]
-->
```

```css
/**
 * File: /pages/[screen-name]/[screen-name].css
 * Purpose: [Screen Name] screen-specific styles
 */
```

```javascript
/**
 * File: /pages/[screen-name]/[screen-name].js
 * Purpose: [Screen Name] screen-specific logic
 */
```

```javascript
/**
 * File: /pages/[screen-name]/[screen-name].ja.js
 * Purpose: [Screen Name] Japanese translations
 */
```

---

## 12. Quick Reference: Common Tasks

### Task 1: Add a footer link to new screen

**In each screen's footer:**
```html
<a href="../[new-screen]/[new-screen].html" class="footer-nav-btn" data-page="[new-screen]">
  <span class="footer-nav-icon">[emoji]</span>
  <span class="footer-nav-label" data-i18n="[new-screen]">[Japanese]</span>
</a>
```

**In translation files (common.ja.js, common.en.js, common.zh.js):**
```javascript
'[new-screen]': '[Translation]',
```

---

### Task 2: Add a new translation key

**Format:** `[screen].[section].[element]`

**In screen-specific translation file (e.g., board.ja.js):**
```javascript
'board.button.reply': '返信',
```

**In en.js:**
```javascript
'board.button.reply': 'Reply',
```

**In zh.js:**
```javascript
'board.button.reply': '回复',
```

**In HTML:**
```html
<button data-i18n="board.button.reply">返信</button>
```

---

### Task 3: Fix broken paths

**Common Issues:**

| Issue | Wrong | Correct |
|-------|-------|---------|
| Missing `../../` | `href="css/variables.css"` | `href="../../css/variables.css"` |
| Absolute path | `href="/css/variables.css"` | `href="../../css/variables.css"` |
| Wrong screen link | `href="board.html"` | `href="../board/board.html"` |
| Wrong logout link | `href="../index.html"` | `href="../../index.html"` |

---

## 13. Development Workflow

### 13.1 Development Environment

```
D:/seurea-static_dev/securea-static-work/
```

**Important:** Do NOT push to GitHub (development only)

### 13.2 Modifying Existing Files

**Before Modification:**
1. ✅ Check current file structure
2. ✅ Verify paths are correct
3. ✅ Read file header comment
4. ✅ Check related translation keys

**After Modification:**
1. ✅ Update file header comment (if needed)
2. ✅ Test locally with `npx http-server`
3. ✅ Verify language switching works
4. ✅ Verify footer navigation works
5. ✅ Git commit with clear message

### 13.3 GitHub Deployment

After all screens complete and testing done:

```
D:/AIDriven/securea-city-static/
```

Copy files here and push to GitHub

---

## 14. Checklist

New screen creation checklist:

- □ Created `pages/[screen]/` directory
- □ Copied template
- □ Added file header comment
- □ Created CSS/JS in **same directory**
- □ Created translation files (ja/en/zh) in **same directory**
- □ Fixed CSS/JS load paths (same directory)
- □ Fixed translation file paths (same directory)
- □ Added Tailwind CDN (`<head>` tag)
- □ Added logout button (footer right)
- □ Added translation keys to **screen-specific** files
- □ Common translations only in `common.[lang].js`
- □ Tested locally
- □ Language switching works
- □ Footer nav works
- □ Logout button works

---

## 15. Current Development Focus

### Priority 1: Refactor home.html
- ✅ File exists: `/pages/home/home.html`
- ⚠️ Status: Legacy structure (352 lines)
- 🔧 Action needed: Follow `home-refactoring-guide.md`

### Priority 2: Implement remaining screens
- Start with: notice, board, booking (MVP features)
- Use: Skill template or home.html as base
- Follow: All rules in this document

---

## 16. Summary

- **Total 24 screens** under unified rules
- **Screen-specific files in same directory** including translations
- **Common files only in `css/`, `js/`**
- **Translation file split:** common + screen-specific
- **Standard 3-layer structure** - edit content area only
- **Development and GitHub separated** for safe development
- **Version 3.3** integrates comprehensive implementation tracking

---

## 17. Old vs New Comparison

### Old Rule (v3.0 and earlier)
```
pages/home/home.html
pages/home/home.css
pages/home/home.js

js/i18n/langs/ja.js        # All screens consolidated
js/i18n/langs/en.js
js/i18n/langs/zh.js
```

### New Rule (v3.1+)
```
pages/home/
├── home.html
├── home.css
├── home.js
├── home.ja.js             # Screen-specific
├── home.en.js
└── home.zh.js

js/i18n/langs/
├── common.ja.js           # Common only
├── common.en.js
└── common.zh.js
```

**Reason for Change:**
- Prevents translation files from violating 300-line rule
- Easier to find and modify screen-specific translations
- Better scalability (24 screens × 20 keys = 480 keys per file was too large)
- Each screen is self-contained and independent

---

## 18. Related Documentation

- **Development Guidelines:** `04_Development-Guidelines-v2.1.md`
- **Naming Conventions:** `naming-conventions.md`
- **Home Refactoring Guide:** `home-refactoring-guide-v2.3.md`
- **Multi-Tenant Design:** `03_Multi-Tenant-Design-v2.0.md`
- **Code Generation Rules:** `code-generation-rules-v2.1.md`
- **File Modification Checklist:** `File-Modification-Checklist.md`
- **Next Chat Instructions:** `Next-Chat-Instructions-v3.md`

---

**Document ID:** SEC-APP-PROJECT-STRUCTURE-001  
**Last Updated:** 2025/10/26  
**Version:** 3.3
