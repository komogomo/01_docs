# Next Chat Instructions v3 - home.html Refactoring

**Date:** 2025/10/25  
**Version:** 3.0  
**Priority:** HIGH  
**Estimated Time:** 60-90 minutes  
**Context:** Translation files complete, CSS verified, ready for home.html refactoring

---

## ⚠️ PREREQUISITES - CRITICAL REQUIREMENTS

### Before Starting Work

**MANDATORY ACTIONS:**

1. **Read Skills and Knowledge FIRST**
   - Check `/mnt/skills/user/securea-dev-standards/SKILL.md` for development standards
   - Review project knowledge documents for context
   - Understand BEM methodology and 3-layer structure

2. **Never Make Independent Decisions**
   - Always confirm before implementing changes
   - Ask questions when requirements are unclear
   - Verify assumptions with the user

3. **Explanation Format**
   - Do NOT provide code samples in explanations
   - Use concise written descriptions only
   - Avoid before/after code comparisons in responses

4. **Content Area Preservation**
   - The content area visual appearance MUST exactly match the reference home.html
   - Preserve all existing content structure, layout, and styling
   - Only refactor structure (header/footer/scripts) - not content appearance

5. **File Upload Instructions**
   - User will be prompted to upload required files
   - List exactly which files are needed
   - Explain why each file is necessary

---

## 📊 Current Status Summary

### ✅ Completed in Previous Chats

**Phase 1: Documentation Corrections** ✅
- Directory-Structure_v1.1.md created (CSS paths corrected)
- home-refactoring-guide_v2.2.md created (all paths verified)
- All documentation now reflects actual file structure

**Phase 2: Translation Files** ✅
- ja.js completed - 46 keys (footer 6 + home 18 + login 22)
- en.js completed - 46 keys
- zh.js completed - 46 keys
- Files deployed to: `D:\seurea-static_dev\securea-static-work\js\i18n\langs\`

**Phase 3: CSS Verification** ✅
- header.css verified - 4 classes confirmed
- footer.css verified - 7 classes confirmed with BEM notation
- button.css verified - language switcher styles ready
- layout.css verified - page structure classes ready

### 🎯 Current Position

**Ready for:** home.html refactoring (Phase 4)
**Prerequisites:** All completed
**Blocking Issues:** None
**Confidence Level:** HIGH - All dependencies verified

---

## 🎯 Objectives for This Chat

### Primary Goal
Refactor `home.html` from legacy structure to new 3-layer architecture

### Specific Tasks

1. **Structure Refactoring**
   - Replace inline CSS with external stylesheets
   - Replace embedded JavaScript with external modules
   - Implement 3-layer page structure (Header/Content/Footer)
   - Preserve all existing content area appearance

2. **File Creation**
   - Create `home.css` (screen-specific styles)
   - Create `home.js` (screen-specific logic)
   - Both files follow project standards

3. **Integration**
   - Link all common CSS files (correct paths)
   - Load translation data properly (correct order)
   - Initialize language manager correctly
   - Set up footer navigation active state

4. **Verification**
   - Test in browser (visual check)
   - Verify language switching works
   - Confirm footer navigation works
   - Check console for errors

### Success Criteria

- ✅ home.html follows 3-layer structure
- ✅ All inline code externalized
- ✅ Language switching functional
- ✅ Footer navigation functional
- ✅ Content area appearance unchanged
- ✅ No console errors
- ✅ BEM naming conventions followed
- ✅ File headers complete and accurate

---

## 📁 Required File Uploads

Please upload the following files to begin work:

### 1. Reference Documents (3 files)
**Purpose:** Provide procedure and context

- `home-refactoring-guide_v2.2.md` - Step-by-step refactoring procedure
- `File-Modification-Checklist.md` - Quality checklist (24 items)
- `Directory-Structure_v1.1.md` - File paths reference

**Why needed:** These documents contain the complete refactoring procedure, quality standards, and correct file paths.

### 2. Target File (1 file)
**Purpose:** File to be refactored

- `home.html` (current version from `/pages/home/`)

**Why needed:** This is the file that will be refactored according to the guide.

### 3. Optional Reference (1 file)
**Purpose:** Visual reference if needed

- Screenshot or description of current home.html appearance (optional)

**Why needed:** To ensure content area visual appearance is preserved exactly.

---

## 📋 Work Procedure

### Step 1: File Analysis (5 minutes)

**Actions:**
1. Read home-refactoring-guide_v2.2.md completely
2. Review current home.html structure
3. Identify all inline code to be externalized
4. Note content area boundaries (to be preserved)

**Questions to Answer:**
- How many inline style tags exist?
- How many inline script tags exist?
- What is the current file size?
- Are there any custom modifications not in the guide?

### Step 2: Prerequisites Verification (5 minutes)

**Check List:**
- [ ] All required CSS files exist in `/css/common/`
- [ ] All translation files exist in `/js/i18n/langs/`
- [ ] Directory structure matches documentation
- [ ] No blocking issues identified

**If ANY prerequisites fail:**
- STOP and report to user
- Do not proceed with refactoring
- Resolve issues before continuing

### Step 3: Header Section Refactoring (10 minutes)

**Tasks:**
1. Update `<head>` tag structure
2. Add Tailwind CDN (FIRST in head)
3. Link CSS files (correct order and paths)
4. Remove inline styles
5. Add file header comment

**Critical Points:**
- Tailwind CDN must be FIRST after meta tags
- CSS load order: variables → reset → base → common/* → home.css
- Use `../../` for relative paths from `/pages/home/`

### Step 4: Header Component Refactoring (10 minutes)

**Tasks:**
1. Replace floating language switcher with header structure
2. Add `.page-header` with BEM notation
3. Add `.page-header__container`
4. Position language switcher inside header
5. Remove old CSS for floating button

**Preservation:**
- Header title text (if exists)
- Language button functionality
- Current language detection

### Step 5: Content Area Preservation (5 minutes)

**Tasks:**
1. Wrap existing content in `<main class="page-content">`
2. Add `<div class="content-container">` wrapper
3. **DO NOT modify any content HTML**
4. **DO NOT change content styles**
5. Only add wrapper divs - nothing else

**CRITICAL:**
This step is about adding structure ONLY. The visual appearance of the content area MUST remain identical to the current version.

### Step 6: Footer Refactoring (10 minutes)

**Tasks:**
1. Replace current footer/nav with new structure
2. Use `.page-footer` and BEM classes
3. Add all 6 navigation buttons
4. Add `data-page` attributes for active state
5. Use short-form translation keys
6. Correct all href paths

**6 Footer Buttons:**
1. Home (`home.html`)
2. Notice (`../notice/notice.html`)
3. Board (`../board/board.html`)
4. Booking (`../booking/booking.html`)
5. My Page (`../mypage/mypage.html`)
6. Logout (`../../index.html`)

### Step 7: JavaScript Externalization (15 minutes)

**Tasks:**
1. Remove all inline `<script>` tags
2. Add external script tags (correct order)
3. Create `home.js` with initialization code
4. Ensure proper loading sequence

**Loading Order (CRITICAL):**
```
1. Translation data (ja.js, en.js, zh.js) - FIRST
2. Common features (language-switcher.js, translator.js, footer-navigation.js)
3. Screen-specific (home.js) - LAST
```

### Step 8: Create home.css (10 minutes)

**Tasks:**
1. Create new file: `/pages/home/home.css`
2. Extract any home-specific styles
3. Add file header comment
4. Use BEM naming conventions
5. Use CSS variables (not hardcoded values)

**Content:**
- Screen-specific styles only
- No common component styles
- Minimal and focused
- Well-commented

### Step 9: Create home.js (10 minutes)

**Tasks:**
1. Create new file: `/pages/home/home.js`
2. Add IIFE wrapper
3. Add initialization function
4. Add footer active state setter
5. Add file header comment

**Must Include:**
- Translation data check
- Language manager initialization
- Footer button active state
- Console logging for debugging

### Step 10: Final Verification (10 minutes)

**Browser Testing:**
- [ ] Open home.html in browser
- [ ] Check visual appearance matches original
- [ ] Test language switching (JA/EN/CN)
- [ ] Test footer navigation clicks
- [ ] Check browser console for errors
- [ ] Verify active button styling

**Code Review:**
- [ ] Run through File-Modification-Checklist.md (24 items)
- [ ] Verify all paths are correct
- [ ] Check BEM naming consistency
- [ ] Confirm file headers present
- [ ] Review all comments

---

## 📤 Expected Outputs

By the end of this chat, you should deliver:

### 1. Refactored home.html
**Location:** `/mnt/user-data/outputs/home.html`

**Changes:**
- External CSS links (no inline styles)
- External JS scripts (no inline scripts)
- 3-layer structure (Header/Content/Footer)
- BEM class names throughout
- Correct relative paths
- Complete file header

### 2. New home.css
**Location:** `/mnt/user-data/outputs/home.css`

**Content:**
- Screen-specific styles only
- BEM naming conventions
- CSS variables used
- Well-commented
- File header present

### 3. New home.js
**Location:** `/mnt/user-data/outputs/home.js`

**Content:**
- IIFE wrapper
- Initialization function
- Footer active state logic
- Error checking
- Console logging
- File header present

### 4. Verification Report
**Location:** `/mnt/user-data/outputs/Home-Refactoring-Report.md`

**Content:**
- Changes summary
- Verification results (24 checklist items)
- Browser test results
- Known issues (if any)
- Deployment notes

---

## ✅ Completion Checklist

Before considering this chat complete:

### File Creation
- [ ] home.html refactored and in outputs
- [ ] home.css created and in outputs
- [ ] home.js created and in outputs
- [ ] Verification report created

### Code Quality
- [ ] All 24 items in File-Modification-Checklist.md verified
- [ ] No console errors reported
- [ ] All paths verified correct
- [ ] BEM naming consistent
- [ ] File headers complete

### Functionality
- [ ] Language switching works (JA/EN/CN)
- [ ] Footer navigation works (all 6 buttons)
- [ ] Active button styling works
- [ ] Content area appearance preserved
- [ ] No visual regressions

### Documentation
- [ ] Verification report complete
- [ ] Changes clearly documented
- [ ] Deployment instructions provided
- [ ] Known issues listed (if any)

---

## 🚨 Common Pitfalls to Avoid

### ❌ DON'T: Regenerate Entire File
**Problem:** Loses comments, formatting, and introduces bugs
**Solution:** Use str_replace for targeted changes

### ❌ DON'T: Modify Content Area Appearance
**Problem:** Changes user-facing visual design
**Solution:** Only add wrapper divs, preserve all content HTML/CSS

### ❌ DON'T: Use Incorrect Paths
**Problem:** 404 errors for CSS/JS files
**Solution:** Always use `../../` for common files from `/pages/home/`

### ❌ DON'T: Load Scripts in Wrong Order
**Problem:** JavaScript errors due to missing dependencies
**Solution:** Translation data FIRST, common features, then screen-specific

### ❌ DON'T: Forget BEM Modifiers
**Problem:** Active states don't work
**Solution:** Use `footer-nav-btn--active` for active button

### ❌ DON'T: Hardcode Values
**Problem:** Inconsistent styling
**Solution:** Use CSS variables: `var(--color-primary)`

### ❌ DON'T: Skip Verification
**Problem:** Bugs discovered later
**Solution:** Complete all 24 checklist items

---

## 💬 Suggested Opening Message

```
I need to refactor home.html according to home-refactoring-guide_v2.2.md.

Previous chats completed:
- ✅ Documentation corrections (Directory-Structure v1.1, home-refactoring-guide v2.2)
- ✅ Translation files (ja.js, en.js, zh.js - all 46 keys complete)
- ✅ CSS verification (header, footer, button, layout - all verified)

Uploaded files:
- Next-Chat-Instructions_v3.md (this instruction file)
- home-refactoring-guide_v2.2.md (refactoring procedure)
- File-Modification-Checklist.md (quality checklist)
- Directory-Structure_v1.1.md (file paths reference)
- home.html (current version to be refactored)

Please follow Next-Chat-Instructions_v3.md exactly.

IMPORTANT REMINDERS:
1. Read the skills and project knowledge FIRST
2. Confirm before making decisions
3. Explain changes concisely WITHOUT code samples
4. Preserve content area visual appearance EXACTLY
5. Follow File-Modification-Checklist.md (24 items)

Ready to begin home.html refactoring.
```

---

## 📋 Final Notes

### Time Management
- Total time: 60-90 minutes
- If running over time, stop and create continuation instructions
- Prioritize core functionality over perfection

### Communication
- Provide progress updates at each step
- Ask for confirmation before major changes
- Report any unexpected findings immediately

### Quality Standards
- All code must follow BEM methodology
- All files must have complete headers
- All changes must be verifiable
- No hardcoded values allowed

### Next Steps After This Chat
1. Deploy refactored files to working directory
2. Test in browser thoroughly
3. Create git commit with detailed message
4. Move to next screen refactoring (notice.html)

---

**Document Version:** 3.0  
**Created:** 2025/10/25  
**For:** home.html refactoring phase  
**Prerequisites:** Translation files complete, CSS verified

**END OF INSTRUCTIONS**
