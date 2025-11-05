# File Modification Checklist v2.0

**Project:** SECUREA City Smart Communication App  
**Version:** 2.0  
**Created:** 2025/10/26  
**Purpose:** Systematic checklist for modifying existing HTML/CSS/JS files

---

## Overview

This checklist ensures consistent, error-free modifications to existing project files. Follow this checklist **EVERY TIME** you modify an existing file to prevent regressions and maintain code quality.

**Target Files:**
- HTML files in `/pages/`
- CSS files in `/css/`
- JavaScript files in `/js/`

**Key Principle:**  
When modifying existing files, ONLY change what needs to be changed. Do NOT regenerate entire files unless explicitly required.

---

## When to Use This Checklist

### Use This Checklist When:
- Modifying existing HTML/CSS/JS files
- Fixing bugs in existing files
- Adding new features to existing pages
- Refactoring existing code
- Updating translations or styles

### Do NOT Use This Checklist When:
- Creating brand new files (use templates instead)
- Creating new screens from scratch
- Writing documentation

---

## The 24-Step Process

### Phase 1: Pre-Modification (Steps 1-5)

#### Step 1: File Location Verification
- [ ] Confirm the exact file path
- [ ] Verify write permissions exist
- [ ] Check file is in correct directory according to project structure

**Example:**
```bash
ls pages/home/home.html
test -w pages/home/home.html && echo "Writable"
```

---

#### Step 2: Backup Creation (MANDATORY)
- [ ] Create backup with `.backup` extension
- [ ] Store in same directory

**Example:**
```bash
cp pages/home/home.html pages/home/home.html.backup
```

**CRITICAL:** Never skip this step.

---

#### Step 3: Git Status Check
- [ ] Check current git status
- [ ] Document current changes if any
- [ ] Create new branch for significant changes

**Example:**
```bash
git status
git checkout -b feature/home-refactoring
```

---

#### Step 4: File Context Review
- [ ] Read entire file before modifying
- [ ] Identify specific section to modify
- [ ] Note line numbers for modification area
- [ ] Check for dependencies

---

#### Step 5: Related Files Identification
- [ ] Identify related CSS files
- [ ] Identify related JS files
- [ ] Identify translation files if applicable
- [ ] List all dependencies

**Example for home.html:**
```
HTML:  /pages/home/home.html
CSS:   /css/pages/*.css + home.css
JS:    /js/features/*.js + home.js
Trans: home.ja.js, home.en.js, home.zh.js
```

---

### Phase 2: During Modification (Steps 6-14)

#### Step 6: Modification Scope Definition
- [ ] Define EXACTLY what needs to change
- [ ] Identify smallest possible change
- [ ] Avoid "while we're here" changes
- [ ] Document why each change is necessary

**Good:** "Move language switcher from floating to header container"  
**Bad:** "Fix header and also update footer while I'm at it"

---

#### Step 7: Change Isolation
- [ ] Make one logical change at a time
- [ ] Use `str_replace` tool for targeted changes
- [ ] Keep original code structure intact
- [ ] Preserve indentation and formatting

---

#### Step 8: Code Preservation
- [ ] Do NOT regenerate unchanged sections
- [ ] Preserve comments and documentation
- [ ] Keep existing formatting conventions
- [ ] Maintain consistent indentation style

**Critical Rules:**
- Preserve: Unchanged HTML sections
- Preserve: Existing comments
- Preserve: Original indentation
- Preserve: Working functionality
- Avoid: Complete file regeneration
- Avoid: Reformatting unchanged code

---

#### Step 9: Path Verification
- [ ] Verify all file paths are correct
- [ ] Check relative path depth (`../../` vs `../`)
- [ ] Confirm paths match Directory-Structure.md
- [ ] Test paths resolve correctly

**Path Patterns:**
```
From /pages/home/:
  CSS:  ../../css/pages/button.css  (up 2 levels)
  JS:   ../../js/features/translator.js
  Link: ../notice/notice.html  (up 1 level)
  Same: home.html  (same directory)
```

---

#### Step 10: Translation Key Check
- [ ] Verify all `data-i18n` attributes present
- [ ] Use correct key format (short-form for footer)
- [ ] Check keys exist in translation files
- [ ] Avoid old key formats

**Key Format Rules:**
```
Correct: data-i18n="home"
Correct: data-i18n="home.title"
Wrong:   data-i18n="common.home"
Wrong:   data-i18n="footer.home"
```

---

#### Step 11: BEM Notation Check
- [ ] Use BEM notation for new classes
- [ ] Follow existing naming patterns
- [ ] Avoid Tailwind classes in common components
- [ ] Check naming-conventions.md for rules

**BEM Pattern:**
```
Block:    .page-header
Element:  .page-header__container
Modifier: .page-header--fixed

Footer:   .footer-nav-btn
          .footer-nav-btn--active
          .footer-nav-icon
          .footer-nav-label
```

---

#### Step 12: CSS Loading Order
- [ ] Maintain strict CSS loading order
- [ ] Tailwind CDN must be FIRST in `<head>`
- [ ] Common CSS before screen-specific CSS
- [ ] Screen CSS must be LAST

**Required Order:**
```html
1. <script src="https://cdn.tailwindcss.com"></script>
2. <link rel="stylesheet" href="../../css/variables.css">
3. <link rel="stylesheet" href="../../css/reset.css">
4. <link rel="stylesheet" href="../../css/base.css">
5. <link rel="stylesheet" href="../../css/pages/button.css">
6. <link rel="stylesheet" href="../../css/pages/header.css">
7. <link rel="stylesheet" href="../../css/pages/footer.css">
8. <link rel="stylesheet" href="../../css/pages/layout.css">
9. <link rel="stylesheet" href="home.css">  <!-- LAST -->
```

---

#### Step 13: JS Loading Order
- [ ] Translation data loads FIRST
- [ ] Common features load SECOND
- [ ] Screen-specific JS loads LAST
- [ ] All scripts before closing `</body>`

**Required Order:**
```html
<!-- 1. Translation Data -->
<script src="../../js/i18n/langs/common.ja.js"></script>
<script src="../../js/i18n/langs/common.en.js"></script>
<script src="../../js/i18n/langs/common.zh.js"></script>
<script src="home.ja.js"></script>
<script src="home.en.js"></script>
<script src="home.zh.js"></script>

<!-- 2. Common Features (REQUIRED) -->
<script src="../../js/features/translator.js"></script>
<script src="../../js/features/language-switcher.js"></script>
<script src="../../js/features/footer-navigation.js"></script>

<!-- 3. Screen-Specific -->
<script src="home.js"></script>
```

---

#### Step 14: Comment Preservation
- [ ] Keep all existing comments
- [ ] Add new comments for changes
- [ ] Use Japanese for implementation comments
- [ ] Update file header if structure changed

---

### Phase 3: Post-Modification (Steps 15-24)

#### Step 15: Visual Verification
- [ ] Open file in browser
- [ ] Check page renders correctly
- [ ] Verify no visual regressions
- [ ] Test on multiple screen sizes if applicable

**Test Scenarios:**
1. Page loads without errors
2. All sections display correctly
3. No missing images or broken links
4. Responsive layout works

---

#### Step 16: Functionality Testing
- [ ] Test all modified features
- [ ] Test unchanged features (smoke test)
- [ ] Check browser console for errors
- [ ] Verify network requests succeed

---

#### Step 17: Translation Testing
- [ ] Switch to Japanese (JA) - verify display
- [ ] Switch to English (EN) - verify display
- [ ] Switch to Chinese (ZH) - verify display
- [ ] Check all `data-i18n` elements update

**Language Test:**
1. Click JA button - All text in Japanese
2. Click EN button - All text in English
3. Click ZH button - All text in Chinese
4. Reload page - Language persists

---

#### Step 18: Footer Navigation Testing
- [ ] Click each footer button
- [ ] Verify active state updates
- [ ] Check page navigation works
- [ ] Confirm logout redirects correctly

---

#### Step 19: Cross-File Verification
- [ ] Check if changes affect related files
- [ ] Verify CSS changes don't break other pages
- [ ] Verify JS changes don't break other pages
- [ ] Test shared components on multiple pages

---

#### Step 20: Code Quality Check
- [ ] No console.log statements left (unless intentional)
- [ ] No commented-out code (unless documented)
- [ ] No hardcoded values (use CSS variables)
- [ ] No duplicate code

---

#### Step 21: File Header Check
- [ ] File header comment exists
- [ ] File path is correct
- [ ] Description is accurate
- [ ] Features list updated if applicable

---

#### Step 22: Diff Review
- [ ] Review all changes made
- [ ] Confirm no accidental deletions
- [ ] Verify no unintended modifications
- [ ] Check for whitespace-only changes (avoid)

**Example:**
```bash
git diff pages/home/home.html
```

---

#### Step 23: Documentation Update
- [ ] Update relevant documentation if needed
- [ ] Add notes to commit message
- [ ] Update changelog if exists
- [ ] Document breaking changes

---

#### Step 24: Git Commit
- [ ] Stage modified files
- [ ] Write clear commit message
- [ ] Include reason for change
- [ ] Reference issue number if applicable

**Commit Message Format:**
```bash
git add pages/home/home.html pages/home/home.css

git commit -m "refactor(home): Move language switcher to header

- Moved floating language switcher into page-header__container
- Updated CSS to remove fixed positioning
- Follows new 3-layer structure standard
- Ref: home-refactoring-guide_v2.1.md"
```

---

## Quick Reference Table

| Phase | Steps | Time | Can Skip? |
|-------|-------|------|-----------|
| Pre-Modification | 1-5 | 5-10 min | Step 3 only (if no git) |
| During Modification | 6-14 | 15-30 min | Steps 9-11 (if no changes) |
| Post-Modification | 15-24 | 10-20 min | Step 19 only (if isolated) |
| **Total** | **24** | **30-60 min** | |

### Cannot Skip:
- Step 2: Backup Creation
- Step 15: Visual Verification
- Step 16: Functionality Testing
- Step 22: Diff Review

---

## Common Mistakes (Top 8)

### 1. Regenerating Entire Files
**Bad:** "Here's the complete 500-line home.html file"  
**Good:** "Using str_replace to change lines 45-48 only"

### 2. Ignoring Path Depth
**Bad:** `<link href="../css/base.css">` (only 1 level up)  
**Good:** `<link href="../../css/base.css">` (2 levels up)

### 3. Forgetting Translation Keys
**Bad:** `<span>Home</span>`  
**Good:** `<span data-i18n="home">Home</span>`

### 4. Breaking CSS Order
**Bad:** Tailwind CDN AFTER common CSS  
**Good:** Tailwind CDN FIRST

### 5. Breaking JS Dependencies
**Bad:** home.js loads before translation data  
**Good:** Translation data loads FIRST

### 6. Using Wrong Directory Names
**Bad:** `../../css/common/footer.css`  
**Good:** `../../css/pages/footer.css`

### 7. Skipping Visual Tests
**Why Bad:** Console errors not noticed, regressions not caught

### 8. Forgetting Backup
**Why Bad:** No safety net if changes go wrong

---

## Final Verification Checklist

Before considering modification complete:

- [ ] All 24 steps completed
- [ ] File tested in browser
- [ ] No console errors
- [ ] All languages work
- [ ] All links work
- [ ] Changes committed to git
- [ ] Documentation updated (if needed)
- [ ] Backup created and preserved

---

## Related Documentation

- **05_Project-Structure-v3.3.md** - File organization and paths
- **naming-conventions-v2.1.md** - Naming rules (BEM, translation keys)
- **code-generation-rules-v2.1.md** - Code generation mandatory rules
- **SKILL.md** - Development standards (securea-dev-standards)

---

**Remember:**
> "The time spent following this checklist is always less than the time spent debugging issues caused by skipping it."

---

**Document ID:** SEC-APP-FILE-MODIFICATION-CHECKLIST-001  
**Last Updated:** 2025/10/26  
**Version:** 2.0
