#!/bin/bash
# ============================================
# HarmoNet Docs Reorganization Script v1.0
# Author: タチコマ（HarmoNet AI Architect）
# Purpose: Move mixed old directories into the
#           new unified /00_project structure.
# ============================================

set -e

# --- 1. Ensure destination directory exists ---
mkdir -p ./00_project ./99_archive/rules ./99_archive/drafts ./99_archive/etc

# --- 2. Move key governance files into 00_project ---
mv -v ./rules/HarmoNet_FileNaming_Standard_v1.0.md ./00_project/ 2>/dev/null || echo "No FileNaming_Standard found"
mv -v ./rules/HarmoNet_Document_Policy_v1.0.md ./00_project/harmonet-document-policy_latest.md 2>/dev/null || echo "No Document_Policy found"
mv -v ./etc/HarmoNet_Ai_Operation_Architecture_v1.2.md ./00_project/ 2>/dev/null || echo "No Ai_Operation_Architecture found"
mv -v ./drafts/HarmoNet_Buddy_Alignment_v1.0.md ./00_project/ 2>/dev/null || echo "No Buddy_Alignment found"
mv -v ./etc/HarmoNet_README_shared-context.md ./00_project/ 2>/dev/null || echo "No Shared README found"
mv -v ./drafts/harmonet-wbs-outline.md ./00_project/ 2>/dev/null || echo "No WBS outline found"

# --- 3. Keep confirmed existing project docs ---
echo "Preserving existing governance docs..."
for f in \
  "harmonet-docs-directory-definition_v3.0.md" \
  "HarmoNet チーム全体の進め方と役割分担ガイドライン v1.0.md" \
  "harmonet-dev-shared-summary_2025-11-01.md"; do
  [ -f "./00_project/$f" ] && echo "✓ Found $f" || echo "⚠ Missing $f"
done

# --- 4. Archive obsolete directories ---
echo "Archiving legacy directories..."
[ -d ./rules ] && mv -v ./rules/* ./99_archive/rules/ && rmdir ./rules
[ -d ./drafts ] && mv -v ./drafts/* ./99_archive/drafts/ && rmdir ./drafts
[ -d ./etc ] && mv -v ./etc/* ./99_archive/etc/ && rmdir ./etc

# --- 5. Display result summary ---
echo ""
echo "✅ Reorganization complete."
echo "All governance & coordination docs are now under: /00_project/"
echo "Old directories archived in: /99_archive/"

# --- 6. Optional: Git auto-commit (uncomment to use) ---
# git add .
# git commit -m "Reorganized project governance files into /00_project (v1.0)"
# git push origin main
