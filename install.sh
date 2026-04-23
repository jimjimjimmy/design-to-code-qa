#!/bin/bash
# Install the design-to-code-qa kit into ~/.claude/ (and optionally a memory folder of your choice).
# Installs the skill, three hooks, project templates, and optionally the canonical pipeline doc.
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

# 1. Skill + onboarding script
mkdir -p "$HOME/.claude/skills/design-to-code-qa"
cp "$KIT_DIR/skill/SKILL.md" "$HOME/.claude/skills/design-to-code-qa/SKILL.md"
echo "  ✅ Skill    → ~/.claude/skills/design-to-code-qa/SKILL.md"
cp "$KIT_DIR/onboard.sh" "$HOME/.claude/skills/design-to-code-qa/onboard.sh"
chmod +x "$HOME/.claude/skills/design-to-code-qa/onboard.sh"
echo "  ✅ Onboard  → ~/.claude/skills/design-to-code-qa/onboard.sh"

# 2. Three-hook package
#    - design-skill-refresh.sh   (UserPromptSubmit) — re-inject skill every 30 min or on design keywords
#    - design-visual-edit-gate.sh (PostToolUse)     — DIFF reminder after Write/Edit on visual files
#    - design-session-start.sh    (SessionStart)    — hard-rules primer at turn 1
mkdir -p "$HOME/.claude/hooks"
for H in design-skill-refresh.sh design-visual-edit-gate.sh design-session-start.sh; do
  cp "$KIT_DIR/hooks/$H" "$HOME/.claude/hooks/$H"
  chmod +x "$HOME/.claude/hooks/$H"
  echo "  ✅ Hook   → ~/.claude/hooks/$H"
done
echo ""
echo "  ℹ️  To enable the hooks, add this to ~/.claude/settings.json under \"hooks\":"
cat <<'HOOKJSON'
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/design-skill-refresh.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/design-visual-edit-gate.sh" }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "$HOME/.claude/hooks/design-session-start.sh" }
        ]
      }
    ]
HOOKJSON
echo ""

# 3. Templates
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
echo ""
echo "   Optional — personalize the skill to your tools (~30 seconds):"
echo "     bash ~/.claude/skills/design-to-code-qa/onboard.sh"
echo "   Teams with a shared preset can write a separate overlay script that"
echo "   writes user-prefs.md directly instead of running onboard interactively."
