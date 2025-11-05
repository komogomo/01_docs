# Smart Communication - Development Environment Setup

**Document Version:** 2.0 (English)  
**Created:** 2025/10/23  
**Last Updated:** 2025/10/24  

---

## 1. Project Overview

**Project Name:** SECUREA City

**Overview:** Smart Communication Application for Condominium Management Associations

**Purpose:** 
- Facilitate resident communication
- Facility booking management
- Bulletin board functionality

**Development Team:** AI-assisted development (Claude + Gemini collaboration)

---

## 2. GitHub Repository Structure

| Repository | Purpose | Visibility | Description |
|------------|---------|------------|-------------|
| **securea-city-static** | Presentation demo | Public | Static HTML "paper theater" (customer demo)<br>Published on GitHub Pages |
| **securea-city** | Development project | Private | Smart Communication APP<br>(React + NestJS + PostgreSQL) |

---

## 3. Local Directory Structure

### Development Machine (Windows 11 Home)

```
D:/
├── seurea-static_dev/
│   └── securea-static-work/          # Static HTML development (work area)
│       ├── index.html                 # Login screen
│       ├── templates/                 # Templates
│       ├── css/                       # Common styles
│       ├── js/                        # Common scripts
│       └── pages/                     # Screen directories
│
└── AIDriven/
    └── securea-city-static/           # Static HTML (GitHub sync)
        └── (Same structure as above)
```

### Directory Roles

| Directory | Role | Git Management |
|-----------|------|----------------|
| **D:/seurea-static_dev/securea-static-work/** | Development work area | Not managed (local only) |
| **D:/AIDriven/securea-city-static/** | Production deploy source | Git managed, push to GitHub |

---

## 4. Technology Stack

### Static HTML Version (Current Phase)

| Category | Technology | Purpose |
|----------|-----------|---------|
| **HTML** | HTML5 | Markup |
| **CSS** | Tailwind CSS CDN | Styling (utility-first) |
| **CSS** | Custom CSS | Component/screen-specific styles |
| **JavaScript** | Vanilla JS | Interactivity |
| **i18n** | Custom implementation | Multilingual (JA/EN/ZH) |
| **Deploy** | GitHub Pages | Public demo hosting |

### Production Version (Future Phase)

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Frontend** | React Native | Latest | Mobile app (iOS/Android) |
| **Frontend** | React | 18.x | Web app |
| **Backend** | NestJS | 10.x | API server |
| **Database** | PostgreSQL | 15.x | Data storage |
| **ORM** | Prisma | Latest | Database access |
| **Auth** | Magic Link | - | Passwordless authentication |
| **i18n** | i18next | Latest | Internationalization |
| **Deploy** | Vercel/Railway | - | Hosting |

---

## 5. Development Environment Setup

### 5.1 Prerequisites

- **OS:** Windows 11 Home
- **Git:** Latest version
- **Node.js:** LTS (22.20.0 recommended)
- **Editor:** Visual Studio Code
- **Browser:** Chrome/Edge (latest)

### 5.2 Initial Setup Steps

#### Step 1: Install Git
```bash
# Download from: https://git-scm.com/
# Verify installation
git --version
```

#### Step 2: Clone Repository
```bash
# Navigate to target directory
cd D:/AIDriven/

# Clone repository
git clone https://github.com/[username]/securea-city-static.git
```

#### Step 3: Setup Working Directory
```bash
# Create development directory
mkdir D:/seurea-static_dev/securea-static-work

# Copy from Git repo for initial setup
cp -r D:/AIDriven/securea-city-static/* D:/seurea-static_dev/securea-static-work/
```

#### Step 4: Install Local Server (Optional)
```bash
# Install http-server globally
npm install -g http-server

# Or use npx (no installation)
npx http-server
```

---

## 6. Development Workflow

### 6.1 Daily Development

1. **Work in development directory**
   ```
   D:/seurea-static_dev/securea-static-work/
   ```

2. **Test locally**
   ```bash
   cd D:/seurea-static_dev/securea-static-work/
   npx http-server -p 8080
   ```
   Open: http://localhost:8080

3. **Verify functionality**
   - Screen display
   - Language switching
   - Navigation
   - Translations

### 6.2 Deploy to GitHub Pages

**When ready for production:**

1. **Copy to Git directory**
   ```bash
   # Copy completed files
   cp -r D:/seurea-static_dev/securea-static-work/* D:/AIDriven/securea-city-static/
   ```

2. **Git commit and push**
   ```bash
   cd D:/AIDriven/securea-city-static/
   
   git add .
   git commit -m "Update: [description]"
   git push origin main
   ```

3. **Verify GitHub Pages**
   - URL: https://[username].github.io/securea-city-static/
   - Usually live within 1-2 minutes

---

## 7. VS Code Setup

### 7.1 Recommended Extensions

- **Live Server** - Real-time preview
- **Prettier** - Code formatter
- **ESLint** - JavaScript linter
- **Tailwind CSS IntelliSense** - CSS completion
- **Auto Rename Tag** - HTML tag auto-rename

### 7.2 Workspace Settings

Create `.vscode/settings.json`:

```json
{
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "files.encoding": "utf8",
    "files.eol": "\n",
    "editor.tabSize": 2,
    "editor.insertSpaces": true
}
```

---

## 8. File Encoding and Line Endings

### Critical Settings

- **Encoding:** UTF-8 (no BOM)
- **Line Endings:** LF (\n) - Unix style
- **Tab:** 2 spaces (convert tabs to spaces)

### Why These Settings?

- ✅ Cross-platform compatibility
- ✅ Git diff clarity
- ✅ Prevents encoding issues
- ✅ Consistent with team standards

---

## 9. Git Workflow

### 9.1 Branch Strategy

**Current (Simple):**
- `main` branch only
- Direct commits to main

**Future (Production):**
- `main` - Production
- `develop` - Development
- `feature/*` - Feature branches

### 9.2 Commit Message Convention

```
[Type]: Short description

Examples:
- feat: Add parking booking screen
- fix: Fix language switch bug
- docs: Update README
- style: Format CSS files
- refactor: Reorganize directory structure
```

---

## 10. Testing Checklist

### Before Committing

- □ All screens load correctly
- □ Language switching works (JA/EN/ZH)
- □ All translations display properly
- □ Navigation functions correctly
- □ No console errors
- □ Responsive on mobile (if applicable)
- □ Tested on Chrome and Edge

### Before GitHub Push

- □ All files in correct directories
- □ No temporary/test files included
- □ File names follow conventions
- □ File headers present
- □ Committed to correct directory (Git managed)

---

## 11. Troubleshooting

### Issue: Files not updating on GitHub Pages

**Solution:**
1. Clear browser cache (Ctrl+Shift+Del)
2. Wait 2-3 minutes for deployment
3. Check GitHub Actions for build status
4. Force refresh (Ctrl+F5)

### Issue: Encoding problems (garbled Japanese)

**Solution:**
1. Set editor to UTF-8
2. Re-save all files with UTF-8
3. Check browser encoding settings
4. Verify HTML charset meta tag

### Issue: Local server not starting

**Solution:**
```bash
# Kill existing process
taskkill /F /IM node.exe

# Try different port
npx http-server -p 3000
```

---

## 12. Security Notes

### Sensitive Data

❌ **Never commit:**
- API keys
- Database passwords
- Environment variables (.env files)
- Personal information

✅ **Use:**
- `.gitignore` for sensitive files
- Environment variables for production
- Placeholder values in demo

---

## 13. Future Migration Plan

### Phase 1: Static HTML (Current)
- ✅ Create all 24 screens
- ✅ Implement i18n
- ✅ Deploy on GitHub Pages
- ✅ Stakeholder demo

### Phase 2: Backend Development
- NestJS API implementation
- PostgreSQL database setup
- Magic link authentication
- API endpoint testing

### Phase 3: Frontend Integration
- React/React Native setup
- API integration
- State management
- PWA implementation

### Phase 4: Production Deployment
- Server setup (Vercel/Railway)
- Database migration
- Domain setup
- Production testing

---

## 14. Resources

### Documentation
- Project Knowledge (in Claude Project)
- GitHub Repository README
- API Specification (future)

### Tools
- GitHub: https://github.com/[username]/securea-city-static
- Tailwind CSS: https://tailwindcss.com/
- MDN Web Docs: https://developer.mozilla.org/

---

## 15. Contact & Support

### Development Team
- Primary: AI-assisted development (Claude)
- Support: Project documentation
- Issues: GitHub Issues (future)

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025/10/24 | English translation |
| 1.0 | 2025/10/23 | Initial Japanese version |

---

**Document ID:** SEC-APP-DEVENV-001  
**Last Updated:** 2025/10/24
