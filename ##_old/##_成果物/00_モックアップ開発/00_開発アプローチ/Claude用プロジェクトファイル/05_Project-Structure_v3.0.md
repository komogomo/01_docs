# SECUREA City Project Structure and File Placement Rules

## Overview

This document defines the complete directory structure and file placement rules for the SECUREA City Smart Communication App static HTML prototype.

**Created:** 2025/10/24  
**Version:** 3.0 (Full English)  
**Target:** Static HTML prototype (securea-static-work)  
**Changes:** Screen-specific files in same directory, Tailwind CDN, logout button

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
│   │   └── langs/                          # Translation data
│   │       ├── ja.js                       # Japanese (all screens)
│   │       ├── en.js                       # English (all screens)
│   │       └── zh.js                       # Chinese (all screens)
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
    │   └── home.js
    │
    ├── board/                              # Board (BBS)
    │   ├── board.html
    │   ├── board.css
    │   ├── board.js
    │   ├── board-detail.html
    │   ├── board-detail.css
    │   ├── board-detail.js
    │   ├── board-post.html
    │   ├── board-post.css
    │   └── board-post.js
    │
    ├── booking/                            # Parking booking
    │   ├── booking.html
    │   ├── booking.css
    │   ├── booking.js
    │   ├── booking-confirm.html
    │   ├── booking-confirm.css
    │   ├── booking-confirm.js
    │   ├── booking-complete.html
    │   ├── booking-complete.css
    │   └── booking-complete.js
    │
    └── mypage/                             # My page
        ├── mypage.html
        ├── mypage.css
        └── mypage.js
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

**Screen-specific files (HTML/CSS/JS) in same directory**

```
pages/[screen-name]/
├── [screen-name].html
├── [screen-name].css
└── [screen-name].js
```

**Example:**
```
pages/home/
├── home.html
├── home.css
└── home.js
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

**Location:** `js/i18n/langs/[lang].js`

**Files:**
- ja.js (Japanese)
- en.js (English)
- zh.js (Chinese)

**Important:** All screens' translations consolidated

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

### Step 4: Edit HTML File

1. Update file header comment
2. Fix CSS load path (same directory)
3. Fix JS load path (same directory)
4. Edit content area (`<main>`) only

### Step 5: Add Translation Keys

Add to `js/i18n/langs/ja.js`, `en.js`, `zh.js`

---

## 6. Translation Key Naming

### Format
```
[screen-id].[section].[element]
```

### Categories
- **header** - Header related
- **content** - Content area
- **button** - Buttons
- **label** - Labels
- **message** - Messages
- **error** - Error messages

### Examples
```javascript
// Home screen
'home.header.title': 'Home',
'home.content.welcome': 'Welcome',
'home.button.logout': 'Logout',

// Board
'board.header.title': 'Board',
'board.content.new': 'New Post',
'board.button.post': 'Post',

// Booking
'booking.header.title': 'Parking Booking',
'booking.content.calendar': 'Calendar',
'booking.button.reserve': 'Reserve',
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
- □ Fixed CSS/JS load paths (same directory)
- □ Added Tailwind CDN (`<head>` tag)
- □ Added logout button (footer right)
- □ Added translation keys (ja/en/zh)
- □ Added logout translation key (`footer.nav.logout`)
- □ Tested locally
- □ Language switching works
- □ Footer nav works
- □ Logout button works

---

## 10. Summary

- **Total 24 screens** under unified rules
- **Screen-specific files in same directory** ← New rule
- **Common files only in `css/`, `js/`**
- **Standard 3-layer structure** - edit content area only
- **Consolidated translation data** for all screens
- **Development and GitHub separated** for safe development

---

## 11. Old vs New Comparison

### Old Rule (v1.0)
```
pages/home/home.html
css/pages/home.css
js/pages/home.js
```

### New Rule (v2.0+)
```
pages/home/
├── home.html
├── home.css
└── home.js
```

**Reason for Change:**
- Easier screen-based file management
- Modifications/deletions in one place
- Significantly improved maintainability

---

## Change Log

- 2025/10/24 v3.0: Full English translation
- 2025/10/24 v2.1: Tailwind CDN, logout button added
- 2025/10/24 v2.0: Screen-specific files in same directory
- 2025/10/24 v1.0: Initial version
