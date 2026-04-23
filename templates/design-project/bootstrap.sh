#!/bin/bash
# Bootstrap a design project with the design-to-code-qa guardrails.
#
# Usage (run from inside the project root):
#   bash ~/.claude/templates/design-project/bootstrap.sh "Project Name"
#
# What it does:
#   1. Drops a CLAUDE.md with the required-reading header (if none exists)
#   2. Creates the assets/ folder structure
#   3. Installs the git pre-commit hook that blocks localhost/file:// URLs

set -e

PROJECT_NAME="${1:-$(basename "$PWD")}"
TEMPLATES_DIR="$HOME/.claude/templates/design-project"

echo "🎨 Bootstrapping design project: $PROJECT_NAME"
echo ""

# 1. CLAUDE.md
if [ -f CLAUDE.md ]; then
  echo "  CLAUDE.md already exists — skipping (review it manually to add the required-reading header)."
else
  sed "s/{PROJECT_NAME}/$PROJECT_NAME/g" "$TEMPLATES_DIR/CLAUDE.md.template" > CLAUDE.md
  echo "  ✅ CLAUDE.md created"
fi

# 2. assets/ structure
mkdir -p assets/icons/logos assets/images
echo "  ✅ assets/{icons,icons/logos,images}/ created"

# 3. Git pre-commit hook
if [ ! -d .git ]; then
  echo "  ⚠️  Not a git repo yet — skipping pre-commit hook. Run 'git init' then re-run this script."
else
  if [ -f .git/hooks/pre-commit ]; then
    echo "  ⚠️  .git/hooks/pre-commit already exists — not overwriting. Merge manually from:"
    echo "       $TEMPLATES_DIR/pre-commit-check.sh"
  else
    cp "$TEMPLATES_DIR/pre-commit-check.sh" .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "  ✅ .git/hooks/pre-commit installed (blocks commits with localhost/file:// URLs)"
  fi
fi

echo ""
echo "🎨 Done. Next: open this project in Claude Code — the design-to-code-qa skill will auto-activate on design work."
