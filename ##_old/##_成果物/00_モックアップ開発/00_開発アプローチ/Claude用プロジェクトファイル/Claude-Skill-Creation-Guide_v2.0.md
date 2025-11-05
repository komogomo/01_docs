# Claude Skills - Creation and Management Guide

## Overview

Claude Skills add specialized knowledge and workflows to Claude AI. This document explains how to create, update, and manage skills for the SECUREA City project.

---

## Skill Basic Structure

### Minimal Configuration
```
my-skill/
└── SKILL.md          # Required file
```

### Multi-File Configuration (Recommended)
```
my-skill/
├── SKILL.md                    # Main file (overview, references)
├── detail-section1.md          # Detailed doc 1
├── detail-section2.md          # Detailed doc 2
└── templates/                  # Template files
    └── template.html
```

---

## SKILL.md Writing Rules

### YAML Frontmatter (Required)

```yaml
---
name: skill-name
description: Skill description (max 200 chars)
---
```

#### Allowed Fields
- `name`: Skill name (max 64 chars) [Required]
- `description`: Skill description (max 200 chars) [Required]
- `license`: License info [Optional]
- `allowed-tools`: Permitted tools [Optional]
- `metadata`: Other metadata [Optional]

#### ❌ Prohibited Fields
- `version` - Manage version via filename instead
- Any other custom fields not listed above

### Example

```markdown
---
name: securea-dev-standards
description: Development standards for SECUREA City project. Defines file naming, CSS naming, screen structure, etc.
---

# SECUREA City Development Standards

## Overview
This skill defines unified development rules.

## When to Use
- Creating/editing HTML files
- Creating/editing CSS files
- Creating/editing JavaScript files

## Detailed Documentation
- naming-conventions.md - Naming conventions
- troubleshooting.md - Troubleshooting
```

---

## External File References

### How Claude References Files

When SKILL.md mentions external files, Claude loads them as needed.

### Reference Methods

#### Pattern A: Markdown Link
```markdown
See [naming-conventions.md](./naming-conventions.md) for details.
```

#### Pattern B: Explicit Path
```markdown
### Naming Convention Details
See the following file for naming details:
- naming-conventions.md
```

#### Pattern C: List Format (Recommended)
```markdown
## Detailed Documentation
This skill includes the following documents:

- **naming-conventions.md** - Naming convention details
- **troubleshooting.md** - Troubleshooting guide
- **templates/page-template.html** - Page template
```

**Recommendation:** Pattern C is clearest and easiest for Claude to reference.

---

## Skill Packaging

### ZIP File Creation

#### Correct Structure
```
securea-dev-standards.zip
└── securea-dev-standards/    # Folder matching skill name
    ├── SKILL.md
    ├── naming-conventions.md
    └── templates/
        └── template.html
```

#### ❌ Wrong Structure
```
securea-dev-standards.zip
├── SKILL.md                  # Root placement is NG
└── naming-conventions.md
```

### Command Line (PowerShell)

```powershell
# Navigate to skills directory
cd C:\path\to\skills

# Create ZIP
Compress-Archive -Path securea-dev-standards -DestinationPath securea-dev-standards.zip
```

### Command Line (Linux/Mac)

```bash
# Create ZIP
zip -r securea-dev-standards.zip securea-dev-standards/
```

---

## Skill Upload

### Procedure

1. **Access Claude UI**
   - https://claude.ai/settings/capabilities

2. **Go to Skills Section**
   - Settings → Capabilities → Skills

3. **Upload ZIP File**
   - Drag & drop, or click to select file

4. **Confirm**
   - If same-name skill exists, replacement dialog appears
   - Click "Upload and Replace"

### Notes

- **Same-name skills are overwritten**
  - Existing skill completely replaced
  - Cannot undo
  
- **Version Management**
  - Include version in SKILL.md content if needed
  - Or use filename versioning (e.g., securea-dev-standards-v2.zip)

---

## Skill Updates

### Update Flow

1. **Edit skill files locally**
   - Modify SKILL.md and related files

2. **Recreate ZIP file**
   - Create ZIP with same structure

3. **Re-upload**
   - Follow same upload procedure
   - Existing skill automatically replaced

### Update Recommendations

- **Record change history**
  - Add change log section in SKILL.md
  - Or create separate CHANGELOG.md

- **Test**
  - Simple test after upload
  - Ask Claude "Tell me about naming conventions"

---

## Common Errors and Solutions

### 1. YAML Frontmatter Error

**Error Message:**
```
unexpected key in SKILL.md frontmatter
```

**Cause:**
Using prohibited fields

**Solution:**
- Remove custom fields like `version`
- Use only allowed fields (name, description, license, allowed-tools, metadata)

### 2. ZIP Structure Error

**Cause:**
Incorrect folder structure

**Solution:**
- Place folder with same name as skill at root
- Place SKILL.md inside that folder

### 3. File Not Found Error

**Cause:**
Wrong reference path to external files

**Solution:**
- Check relative paths
- Verify filename case sensitivity

---

## Best Practices

### 1. Keep SKILL.md Concise

- Overview and usage timing only
- Detailed content in external files
- Consider splitting if exceeding 500 lines

### 2. Structure Documentation with External Files

```
skill/
├── SKILL.md              # Overview (100-200 lines)
├── getting-started.md    # Basic rules
├── advanced.md           # Advanced usage
└── reference.md          # Reference
```

### 3. Use Template Files

```
skill/
└── templates/
    ├── html-template.html
    ├── css-template.css
    └── js-template.js
```

### 4. Craft Description Carefully

Claude uses description to decide whether to use skill, so:

- **Be specific:** Clearly state what it does
- **Be concise:** Under 200 characters
- **Include keywords:** Include relevant terms

**Good Example:**
```yaml
description: Development standards for SECUREA City project. Defines file naming conventions, global variable management, CSS naming (BEM), 3-layer screen structure, and common rules. Unified rules applied when creating/editing HTML, CSS, and JavaScript files.
```

**Bad Example:**
```yaml
description: Development rules
```

---

## Skill Deletion

### Method

Currently, no direct skill deletion feature in Claude UI.

### Alternatives

1. **Overwrite with empty skill**
   - Create minimal content skill
   - Upload with same name to replace

2. **Stop usage**
   - Keep skill but change description to prevent usage

---

## Troubleshooting

### Claude Doesn't Use Skill

**Cause:**
- Description unclear
- Missing relevant keywords

**Solution:**
1. Review description
2. Explicitly instruct "Use XX skill"

### External Files Not Referenced

**Cause:**
- File reference unclear
- Wrong path

**Solution:**
1. Clearly state filename in SKILL.md
2. Check relative paths
3. List in list format

---

## SECUREA City Project Operations

### Current Skills

- **securea-dev-standards** - Development standards
  - Naming conventions, directory structure, screen structure, etc.

### Update Timing

- When new rules added
- When existing rules changed
- When adding troubleshooting info

### Update Procedure

1. Edit files locally
2. Create ZIP file
3. Upload via Claude UI
4. Test operation

---

## Reference Links

- **Official Documentation**
  - https://support.claude.com/en/articles/12512198-how-to-create-custom-skills
  
- **GitHub Repository (Samples)**
  - https://github.com/anthropics/skills

---

## Summary

### Checklist

Verify when creating/updating skills:

- □ YAML frontmatter correct (name, description only)?
- □ Folder structure correct (skill name folder → SKILL.md)?
- □ Description specific (under 200 chars)?
- □ External file references clear?
- □ ZIP file correctly created?
- □ Tested after upload?

### Common Mistakes

1. ❌ Including `version` in YAML frontmatter
2. ❌ Wrong ZIP structure (SKILL.md at root)
3. ❌ Vague description
4. ❌ Unclear external file references

### Success Keys

1. ✅ Follow basic structure
2. ✅ Write clear, specific descriptions
3. ✅ List external files explicitly
4. ✅ Test after upload
5. ✅ Record version in content or filename

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025/10/24 | Full English translation |
| 1.0 | 2025/10/24 | Initial Japanese version |

---

**Document ID:** SEC-APP-SKILL-GUIDE-001  
**Last Updated:** 2025/10/24
