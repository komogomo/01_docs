# SECUREA City - Current Directory Structure

**Last Updated:** 2025/10/25 20:00  
**Version:** 1.2  
**Status:** Active Development

## ðŸ“‹ Version History

### v1.2 (2025/10/25 20:00)
- ✅ **Translation File Structure Update**: Changed to screen-based split
- ✅ **Reason**: Avoid violating 300-line rule (24 screens × 20 keys = 480 keys per file)
- ✅ **Changes**: `js/i18n/langs/*.js` → `common.[lang].js` + `pages/[screen]/[screen].[lang].js`
- ✅ **Files affected**: Directory structure, HTML loading examples

### v1.1 (2025/10/25 18:00)
- âœ… **CSS Path Correction**: Changed `css/common/` to `css/common/`
- âœ… **Reason**: Actual implementation uses `css/common/` directory
- âœ… **Files affected**: Path examples throughout document

### v1.0 (2025/10/25 15:00)
- Initial version  

---

## Ã°Å¸â€œÂ Working Directory

```
D:/seurea-static_dev/securea-static-work/
```

**Important:** Development work is done in this directory. After completion, files are copied to the GitHub repository.

---

## Ã°Å¸â€”â€šÃ¯Â¸Â Complete Directory Structure

### Current Implementation (as of 2025/10/25)

```
D:/seurea-static_dev/securea-static-work/
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ index.html                              # Login screen (Exception: root placement)
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ template/                               # Template directory
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ template.html                       # Standard 3-layer structure template
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ template.css                        # Template-specific CSS
Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ template.js                         # Template-specific JS
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ css/                                    # Common stylesheets
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ variables.css                       # CSS variables (colors, sizes, spacing)
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ base.css                            # Base styles
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ components.css                      # Common components (legacy file)
Ã¢â€â€š   Ã¢â€â€š
Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ common/                              # Common components (current structure)
Ã¢â€â€š       Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ button.css                      # Button styles
Ã¢â€â€š       Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ header.css                      # Header styles
Ã¢â€â€š       Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ footer.css                      # Footer styles (6 buttons supported)
Ã¢â€â€š       Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ layout.css                      # Layout styles
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ js/                                     # JavaScript files
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ main.js                             # Main logic
Ã¢â€â€š   Ã¢â€â€š
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ features/                           # Independent feature modules
Ã¢â€â€š   Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ language-switcher.js           # Language switching functionality
Ã¢â€â€š   Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ translator.js                  # Translation helper
Ã¢â€â€š   Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ footer-navigation.js           # Footer navigation
Ã¢â€â€š   Ã¢â€â€š
│   ├── i18n/                               # Internationalization
│   │   └── langs/                          # Translation data (common only)
│   │       ├── common.ja.js                # Common Japanese (header, footer, buttons)
│   │       ├── common.en.js                # Common English
│   │       └── common.zh.js                # Common Chinese
│   │
│   └── pages/                              # Screen-specific JS (legacy structure)
Ã¢â€â€š   Ã¢â€â€š
Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ pages/                              # Screen-specific JS (legacy structure)
Ã¢â€â€š       Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ template.js                     # Template JS
Ã¢â€â€š
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ pages/                                  # Screen directories
    Ã¢â€â€š
    └── home/                               # Home screen (TOP page)
        ├── home.html                       # Home HTML (352 lines, needs refactoring)
        ├── home.css                        # Home CSS
        ├── home.js                         # Home JavaScript
        ├── home.ja.js                      # Home Japanese translations
        ├── home.en.js                      # Home English translations
        └── home.zh.js                      # Home Chinese translations
```

---

## Ã°Å¸â€œÅ  Implementation Status Summary

| Category | Implemented | Not Implemented | Notes |
|----------|-------------|-----------------|-------|
| **Login** | Ã¢Å“â€¦ index.html | - | Root placement (exception) |
| **Template** | Ã¢Å“â€¦ template/* | - | 3-layer structure boilerplate |
| **Common CSS** | Ã¢Å“â€¦ 7 files | - | variables, base, components, common/* |
| **Common JS** | Ã¢Å“â€¦ 7 files | - | main, features/*, i18n/*, pages/* |
| **Translation Data** | ✅ 3 languages | - | common.[lang].js + screen.[lang].js (screen-based split) |
| **Screen Implementation** | Ã¢Å“â€¦ home | 23 screens | Only home implemented |

---

## Ã°Å¸Å½Â¯ Screen Implementation Plan (Total: 24 screens)

### Ã¢Å“â€¦ Implemented Screens (1 screen)

#### 1. Login & Authentication
- Ã¢Å“â€¦ **index.html** - Login screen (Magic link method)

#### 2. Dashboard
- Ã¢Å“â€¦ **home** - Home/Dashboard
  - Ã°Å¸â€œÂ Needs refactoring (legacy structure Ã¢â€ â€™ new structure)

---

### Ã°Å¸â€œâ€¹ Not Yet Implemented (23 screens)

#### 3. Notices & Bulletin Board (4 screens)
- Ã¢Â¬Å“ **notice** - Notice list
- Ã¢Â¬Å“ **notice-detail** - Notice detail
- Ã¢Â¬Å“ **bulletin** - Bulletin board list
- Ã¢Â¬Å“ **bulletin-detail** - Bulletin board detail

#### 4. BBS (Board) (3 screens)
- Ã¢Â¬Å“ **board** - Board list
- Ã¢Â¬Å“ **board-detail** - Thread detail
- Ã¢Â¬Å“ **board-post** - New post

#### 5. Parking Reservation (6 screens)
- Ã¢Â¬Å“ **booking** - Reservation calendar
- Ã¢Â¬Å“ **booking-map** - Parking map
- Ã¢Â¬Å“ **booking-confirm** - Reservation confirmation
- Ã¢Â¬Å“ **booking-complete** - Reservation complete
- Ã¢Â¬Å“ **booking-history** - Reservation history
- Ã¢Â¬Å“ **booking-detail** - Reservation detail

#### 6. Survey (3 screens)
- Ã¢Â¬Å“ **survey** - Survey list
- Ã¢Â¬Å“ **survey-detail** - Survey answer form
- Ã¢Â¬Å“ **survey-complete** - Answer complete

#### 7. Settings (2 screens)
- Ã¢Â¬Å“ **settings** - Settings
- Ã¢Â¬Å“ **notification-settings** - Notification settings

#### 8. My Page (1 screen)
- Ã¢Â¬Å“ **mypage** - My page

#### 9. Admin (3 screens)
- Ã¢Â¬Å“ **admin** - Admin dashboard
- Ã¢Â¬Å“ **admin-user** - User management
- Ã¢Â¬Å“ **admin-survey** - Survey management

---

## Ã°Å¸â€œÂ Directory Design Rules

### 1. Screen-Specific File Placement Principle

**Basic Structure:**
```
pages/[category]/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ [screen-name].html          # Main HTML (1 file required)
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ [screen-name].css           # Screen-specific CSS
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ [screen-name].js            # Screen-specific JavaScript
```

**Naming Conventions:**
- File names: kebab-case
- Class names: BEM notation
- Variable names: camelCase
- Global variables: `window.PascalCase`

**Example:**
```
pages/board/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board.html              # Board list
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board.css
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board.js
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board-detail.html       # Board detail
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board-detail.css
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board-detail.js
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board-post.html         # New post
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ board-post.css
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ board-post.js
```

---

### 2. Common File Placement Principle

#### Common CSS Files
```
css/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ variables.css           # CSS variables (colors, sizes, etc.)
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ base.css                # Base styles
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ components.css          # Legacy structure (not recommended)
Ã¢â€â€š
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ pages/                  # New structure (recommended)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ button.css          # Common button styles
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ header.css          # Common header styles
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ footer.css          # Common footer styles
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ layout.css          # Common layout styles
```

**Note:** 
- `components.css` is a legacy file; do not use for new screens
- New screens should use split files under `pages/`

#### Common JavaScript Files
```
js/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ main.js                         # Main logic
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ features/                       # Independent features
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ language-switcher.js       # Language switching
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ translator.js              # Translation functionality
Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ footer-navigation.js       # Footer navigation
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ i18n/                           # Internationalization
Ã¢â€â€š   Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ i18n.js                     # Main script
Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ langs/                      # Translation data
Ã¢â€â€š       Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ ja.js                   # Japanese (all screens consolidated)
Ã¢â€â€š       Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ en.js                   # English (all screens consolidated)
Ã¢â€â€š       Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ zh.js                   # Chinese (all screens consolidated)
Ã¢â€â€š
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ pages/                          # Screen-specific JS (legacy structure)
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ template.js                 # Template JS
```

**Note:**
- Translation data consolidated into single file per language (all screens)
- Screen-specific JS placed in `pages/[screen]/[screen].js` (NOT in `js/pages/`)

---

### 3. Path Specification Rules

#### Pattern A: Screen-specific file Ã¢â€ â€™ Common files

**Location:** `/pages/home/home.html`

```html
<!-- CSS Loading -->
<link rel="stylesheet" href="../../css/variables.css">
<link rel="stylesheet" href="../../css/base.css">
<link rel="stylesheet" href="../../css/common/button.css">
<link rel="stylesheet" href="../../css/common/header.css">
<link rel="stylesheet" href="../../css/common/footer.css">
<link rel="stylesheet" href="../../css/common/layout.css">
<link rel="stylesheet" href="home.css">  <!-- Own screen CSS -->

<!-- JavaScript Loading -->
<!-- 1. Common translations (header, footer) -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>

<!-- 2. Common features --> 
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/footer-navigation.js"></script>
<!-- 3. Screen-specific translations (content area) -->
<script src="home.ja.js"></script>
<script src="home.en.js"></script>
<script src="home.zh.js"></script>

<!-- 4. Screen-specific logic -->
<script src="home.js"></script>  <!-- Own screen JS -->
```

**Key Points:**
- Use `../../` to go up 2 levels (`/pages/home/` Ã¢â€ â€™ `/`)
- Own screen's CSS/JS: filename only (no relative path needed)

---

#### Pattern B: Inter-screen Links (Footer Navigation)

**Location:** `/pages/home/home.html` footer

```html
<footer class="page-footer">
  <div class="page-footer__container">
    <!-- To own screen (home) -->
    <a href="home.html" class="footer-nav-btn" data-page="home">
      <span class="footer-nav-icon">Ã°Å¸ÂÂ </span>
      <span class="footer-nav-label" data-i18n="home">Ã£Æ’â€ºÃ£Æ’Â¼Ã£Æ’Â </span>
    </a>
    
    <!-- To other screens (go up 1 level, then into different directory) -->
    <a href="../notice/notice.html" class="footer-nav-btn" data-page="notice">
      <span class="footer-nav-icon">Ã°Å¸â€œÂ¢</span>
      <span class="footer-nav-label" data-i18n="notice">Ã£ÂÅ Ã§Å¸Â¥Ã£â€šâ€°Ã£Ââ€º</span>
    </a>
    
    <a href="../board/board.html" class="footer-nav-btn" data-page="board">
      <span class="footer-nav-icon">Ã°Å¸â€œâ€¹</span>
      <span class="footer-nav-label" data-i18n="board">Ã¦Å½Â²Ã§Â¤ÂºÃ¦ÂÂ¿</span>
    </a>
    
    <a href="../booking/booking.html" class="footer-nav-btn" data-page="booking">
      <span class="footer-nav-icon">Ã°Å¸â€¦Â¿Ã¯Â¸Â</span>
      <span class="footer-nav-label" data-i18n="booking">Ã©Â§ÂÃ¨Â»Å Ã¥Â Â´</span>
    </a>
    
    <a href="../mypage/mypage.html" class="footer-nav-btn" data-page="mypage">
      <span class="footer-nav-icon">Ã°Å¸â€˜Â¤</span>
      <span class="footer-nav-label" data-i18n="mypage">Ã£Æ’Å¾Ã£â€šÂ¤Ã£Æ’Å¡Ã£Æ’Â¼Ã£â€šÂ¸</span>
    </a>
    
    <!-- Logout (go up 2 levels to index.html) -->
    <a href="../../index.html" class="footer-nav-btn footer-nav-btn--logout" data-page="logout">
      <span class="footer-nav-icon">Ã°Å¸Å¡Âª</span>
      <span class="footer-nav-label" data-i18n="logout">Ã£Æ’Â­Ã£â€šÂ°Ã£â€šÂ¢Ã£â€šÂ¦Ã£Æ’Ë†</span>
    </a>
  </div>
</footer>
```

**Key Points:**
- Own screen: filename only
- Same-level different screen: `../[screen]/[screen].html`
- Login screen: `../../index.html`

---

#### Pattern C: Intra-screen Links (Detail pages, etc.)

**Location:** `/pages/board/board.html` Ã¢â€ â€™ `/pages/board/board-detail.html`

```html
<!-- To another file in same directory -->
<a href="board-detail.html?id=123">View Detail</a>
```

**Key Point:**
- Within same directory: specify filename only

---

## Ã¢Å¡Â Ã¯Â¸Â Important Notes

### 1. index.html Exception

```
Ã¢ÂÅ’ Wrong: /pages/login/index.html
Ã¢Å“â€¦ Correct: /index.html (root level)
```

**Reason:** 
- Login screen is the entry point for all users, so placed at root level
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
- Ã¢ÂÅ’ NEVER change this order
- Ã¢ÂÅ’ NEVER use `!important` in CSS
- Ã¢Å“â€¦ ALWAYS place Tailwind CDN first
- Ã¢Å“â€¦ ALWAYS place screen-specific CSS last

---

### 3. JavaScript Loading Order

```html
<!-- 1. Translation Data (FIRST) -->
<!-- 1. Common translations (header, footer) -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>

<!-- 2. Common features --> 

<!-- 2. Common Features -->
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/footer-navigation.js"></script>

<!-- 3. Screen-specific JavaScript (LAST) -->
<script src="[screen-name].js"></script>
```

**Critical Rules:**
- Translation data MUST be loaded before any feature scripts
- Screen-specific JS MUST be loaded last
- NO inline `<script>` tags (except for small helpers)

---

### 4. File Naming Conventions Summary

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

### 5. Translation Key Naming Convention

**Format:** `[screen].[section].[element]`

**Categories:**
- `header` - Header related
- `content` - Content area
- `button` - Buttons
- `label` - Labels
- `message` - Messages
- `error` - Error messages

**Examples:**
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

**Footer Navigation Keys (Special):**
```javascript
// Short form (no prefix)
'home': 'Home',
'notice': 'Notice',
'board': 'Board',
'booking': 'Booking',
'mypage': 'My Page',
'logout': 'Logout',
```

---

## Ã°Å¸â€Â§ Development Workflow

### 1. Creating a New Screen

**Step 1: Create Directory**
```bash
mkdir pages/[screen-name]
```

**Step 2: Copy Template**
```bash
cp template/template.html pages/[screen-name]/[screen-name].html
cp template/template.css pages/[screen-name]/[screen-name].css
cp template/template.js pages/[screen-name]/[screen-name].js
```

**Step 3: Update File Header Comments**
```html
<!--
  File: /pages/[screen-name]/[screen-name].html
  Screen: [Screen Display Name]
  
  Description:
  [Screen purpose and functionality]
  
  Features:
  - [Feature 1]
  - [Feature 2]
-->
```

**Step 4: Fix Paths**
- CSS: `href="../../css/..."`
- JS: `src="../../js/..."`
- Links: `href="../[other-screen]/..."`

**Step 5: Add Translation Keys**
Add to `js/i18n/langs/ja.js`, `en.js`, `zh.js`

**Step 6: Test Locally**
```bash
npx http-server
```

---

### 2. Modifying Existing Files

**Before Modification:**
1. Ã¢Å“â€¦ Check current file structure
2. Ã¢Å“â€¦ Verify paths are correct
3. Ã¢Å“â€¦ Read file header comment
4. Ã¢Å“â€¦ Check related translation keys

**After Modification:**
1. Ã¢Å“â€¦ Update file header comment (if needed)
2. Ã¢Å“â€¦ Test locally
3. Ã¢Å“â€¦ Verify language switching works
4. Ã¢Å“â€¦ Verify footer navigation works
5. Ã¢Å“â€¦ Git commit with clear message

---

## Ã°Å¸â€œâ€¹ Quick Reference: Common Tasks

### Task 1: Add a footer link to new screen

**In each screen's footer:**
```html
<a href="../[new-screen]/[new-screen].html" class="footer-nav-btn" data-page="[new-screen]">
  <span class="footer-nav-icon">[emoji]</span>
  <span class="footer-nav-label" data-i18n="[new-screen]">[Japanese]</span>
</a>
```

**In translation files (ja.js, en.js, zh.js):**
```javascript
'[new-screen]': '[Translation]',
```

---

### Task 2: Add a new translation key

**Format:** `[screen].[section].[element]`

**In ja.js:**
```javascript
'board.button.reply': 'Ã¨Â¿â€Ã¤Â¿Â¡',
```

**In en.js:**
```javascript
'board.button.reply': 'Reply',
```

**In zh.js:**
```javascript
'board.button.reply': 'Ã¥â€ºÅ¾Ã¥Â¤Â',
```

**In HTML:**
```html
<button data-i18n="board.button.reply">Ã¨Â¿â€Ã¤Â¿Â¡</button>
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

## Ã°Å¸Å½Â¯ Current Development Focus

### Priority 1: Refactor home.html
- Ã¢Å“â€¦ File exists: `/pages/home/home.html`
- Ã¢ÂÅ’ Status: Legacy structure (352 lines)
- Ã°Å¸â€œâ€¹ Action needed: Follow `home-refactoring-guide.md`

### Priority 2: Implement remaining screens
- Start with: notice, board, booking (MVP features)
- Use: `template.html` as base
- Follow: All rules in this document

---

## Ã°Å¸â€œÅ¡ Related Documentation

- **Development Guidelines:** `04_Development-Guidelines_v2_0.md`
- **Project Structure:** `05_Project-Structure_v3_0.md`
- **Naming Conventions:** `naming-conventions.md`
- **Home Refactoring Guide:** `home-refactoring-guide.md`
- **Multi-Tenant Design:** `03_Multi-Tenant-Design_v2_0.md`

---

## Ã°Å¸â€œÂ Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025/10/25 | Initial version based on actual directory scan |

---

**Document ID:** SEC-APP-DIR-STRUCTURE-001  
**Last Updated:** 2025/10/25 15:00
