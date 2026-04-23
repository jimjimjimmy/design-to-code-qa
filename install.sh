#!/bin/bash
# Install the design-to-code-qa kit into ~/.claude/ and ~/Dropbox (optional).
#
# Usage:
#   bash install.sh
#
# What it does:
#   1. Copies the skill to ~/.claude/skills/design-to-code-qa/SKILL.md (auto-activation)
#   2. Copies project templates to ~/.claude/templates/design-project/
#   3. Optionally copies the canonical pipeline doc to a memory folder you choose
#
# After install, bootstrap any new design project with:
#   cd /path/to/your/project
#   bash ~/.claude/templates/design-project/bootstrap.sh "Project Name"

set -e

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Installing design-to-code-qa kit from: $KIT_DIR"
echo ""

# 1. Skill
mkdir -p "$HOME/.claude/skills/design-to-code-qa"
cp "$KIT_DIR/skill/SKILL.md" "$HOME/.claude/skills/design-to-code-qa/SKILL.md"
echo "  ✅ Skill  → ~/.claude/skills/design-to-code-qa/SKILL.md"

# 2. Templates
mkdir -p "$HOME/.claude/templates/design-project"
cp "$KIT_DIR/templates/design-project/bootstrap.sh"       "$HOME/.claude/templates/design-project/bootstrap.sh"
cp "$KIT_DIR/templates/design-project/pre-commit-check.sh" "$HOME/.claude/templates/design-project/pre-commit-check.sh"
cp "$KIT_DIR/templates/design-project/CLAUDE.md.template" "$HOME/.claude/templates/design-project/CLAUDE.md.template"
chmod +x "$HOME/.claude/templates/design-project/bootstrap.sh"
chmod +x "$HOME/.claude/templates/design-project/pre-commit-check.sh"
echo "  ✅ Templates → ~/.claude/templates/design-project/"

# 3. Memory (optional)
echo ""
read -p "Copy the canonical pipeline doc somewhere persistent? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "Path to memory folder (e.g. ~/Documents/ai-memory): " MEM_DIR
  MEM_DIR="${MEM_DIR/#\~/$HOME}"
  mkdir -p "$MEM_DIR"
  cp "$KIT_DIR/memory/process_design_to_code_pipeline.md" "$MEM_DIR/process_design_to_code_pipeline.md"
  echo "  ✅ Memory → $MEM_DIR/process_design_to_code_pipeline.md"
  echo ""
  echo "  ℹ️  Update the absolute path in your ~/.claude/skills/design-to-code-qa/SKILL.md"
  echo "     (change the path on line 10 to $MEM_DIR/...)"
fi

echo ""
echo "🎉 Done. Next: open any Claude Code session and the design-to-code-qa skill will auto-activate on design work."
echo ""
echo "   To bootstrap a new design project:"
echo "     cd /path/to/your/project"
echo "     bash ~/.claude/templates/design-project/bootstrap.sh \"Project Name\""
