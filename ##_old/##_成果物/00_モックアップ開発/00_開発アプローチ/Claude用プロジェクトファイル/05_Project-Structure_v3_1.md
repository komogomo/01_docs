# SECUREA City Project Structure and File Placement Rules

## Overview

This document defines the complete directory structure and file placement rules for the SECUREA City Smart Communication App static HTML prototype.

**Created:** 2025/10/24  
**Version:** 3.1  
**Target:** Static HTML prototype (securea-static-work)  
**Changes:** Translation file structure updated (screen-based split)

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
├── templates/                              # Template files
│   └── page-template.html                  # Standard 3-layer template
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

## 3. Screen List (Total: 24 Screens)

### Main Screens
1. **index.html** - Login (exception, project root)
2. **home** - Home/Dashboard
3. **mypage** - My Page

### Notice/Bulletin
4. **notice** - Notice list
5. **notice-detail** - Notice detail
6. **bulletin** - Bulletin board
7. **bulletin-detail** - Bulletin detail

### BBS (Board)
8. **board** - Board list
9. **board-detail** - Thread detail
10. **board-post** - New post

### Parking Booking
11. **booking** - Calendar
12. **booking-map** - Parking map
13. **booking-confirm** - Confirmation
14. **booking-complete** - Completion
15. **booking-history** - History
16. **booking-detail** - Booking detail

### Survey
17. **survey** - Survey list
18. **survey-detail** - Survey form
19. **survey-complete** - Survey completion

### Settings
20. **settings** - Settings
21. **notification-settings** - Notification settings

### Admin
22. **admin** - Admin dashboard
23. **admin-user** - User management
24. **admin-survey** - Survey management

---

## 4. File Placement Rules

### 4.1 Basic Principle

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

### 4.2 HTML Files

**Location:** `pages/[category]/[screen-name].html`

**Naming:**
- All lowercase
- Hyphen-separated
- Extension: `.html`

### 4.3 CSS Files

**Screen-specific:** `pages/[category]/[screen-name].css`
**Common:** `css/common/[component].css`
- button.css
- header.css
- footer.css
- layout.css

**Important:** Screen-specific CSS in same directory as HTML

### 4.4 JavaScript Files

**Screen-specific:** `pages/[category]/[screen-name].js`
**Common features:** `js/features/[feature].js`
- language-switcher.js
- translator.js
- footer-navigation.js

**Important:** Screen-specific JS in same directory as HTML

### 4.5 Translation Data

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

## 5. New Screen Creation Procedure

### Step 1: Create Directory
```bash
mkdir pages/[screen-name]/
```

### Step 2: Copy Template
```bash
cp templates/page-template.html pages/[screen-name]/[screen-name].html
```

### Step 3: Create CSS/JS Files
```bash
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

## 6. Translation Key Naming

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
window.i18nData.ja = window.i18nData.ja || {};
Object.assign(window.i18nData.ja, {
  'home.title': 'ホーム',
  'home.welcome': 'ようこそ',
  'home.content.message': 'メッセージ',
});

// Board (pages/board/board.ja.js)
window.i18nData.ja = window.i18nData.ja || {};
Object.assign(window.i18nData.ja, {
  'board.title': '掲示板',
  'board.post': '投稿',
  'board.description': '住民同士のコミュニケーション',
});

// Common (js/i18n/langs/common.ja.js)
window.i18nData = window.i18nData || {};
window.i18nData.ja = {
  'home': 'ホーム',
  'notice': 'お知らせ',
  'board': '掲示板',
  'booking': '施設予約',
  'mypage': 'マイページ',
  'logout': 'ログアウト',
};
```

---

## 7. Common Rules

### 7.1 index.html Exception

- **Location:** Project root
- **Structure:** Custom (not 3-layer)
- **CSS/JS:** Inline OK
- **Changes:** Generally prohibited

### 7.2 Standard 3-Layer Structure

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

### 7.3 Tailwind CSS Usage

**All screens use Tailwind CDN:**
```html
<!-- Tailwind CDN -->
<script src="https://cdn.tailwindcss.com"></script>
```

- Place at top of `<head>` tag
- Can combine with custom CSS
- Same as index.html

### 7.4 File Header Comment (REQUIRED)

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

## 8. Development Workflow

### 8.1 Development Environment

```
D:/seurea-static_dev/securea-static-work/
```

**Important:** Do NOT push to GitHub (development only)

### 8.2 GitHub Deployment

After all screens complete and testing done:

```
D:/AIDriven/securea-city-static/
```

Copy files here and push to GitHub

---

## 9. Checklist

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

## 10. Summary

- **Total 24 screens** under unified rules
- **Screen-specific files in same directory** including translations
- **Common files only in `css/`, `js/`**
- **Translation file split:** common + screen-specific
- **Standard 3-layer structure** - edit content area only
- **Development and GitHub separated** for safe development

---

## 11. Old vs New Comparison

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

## Change Log

- 2025/10/25 v3.1: Translation file structure updated (screen-based split)
- 2025/10/24 v3.0: Full English translation
- 2025/10/24 v2.1: Tailwind CDN, logout button added
- 2025/10/24 v2.0: Screen-specific files in same directory
- 2025/10/24 v1.0: Initial version
