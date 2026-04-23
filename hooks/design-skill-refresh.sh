#!/bin/bash
# design-skill-refresh.sh — UserPromptSubmit hook
#
# Purpose: re-inject the design-to-code-qa SKILL.md as additional context
# every N minutes so long sessions don't drift from the pipeline rules.
#
# Mechanism:
#   - Read last-refresh timestamp from ~/.claude/.design-skill-last-refresh
#   - If stale (>N minutes) OR if the user's prompt contains a design-work
#     trigger keyword, output SKILL.md as stdout JSON with additionalContext.
#   - Write current timestamp on refresh.
#
# Hook contract (Claude Code UserPromptSubmit):
#   stdin  = JSON { hook_event_name, session_id, cwd, prompt, ... }
#   stdout = JSON { continue: true, suppressOutput: true, additionalContext: "..." }
#             OR empty (no-op)
#   exit 0 always

set -e

REFRESH_MIN=30
STATE_FILE="$HOME/.claude/.design-skill-last-refresh"
SKILL_FILE="$HOME/.claude/skills/design-to-code-qa/SKILL.md"

# Design-work trigger keywords — if the user's prompt mentions these,
# force a refresh regardless of timer.
TRIGGERS='figma|design|storybook|component|pixel|mockup|screen|hero|carousel|build (the|a|this) .* (page|screen|component)'

# Read stdin JSON (the hook input)
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | /usr/bin/python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("prompt",""))' 2>/dev/null || echo "")

# Is this a design-work prompt?
FORCE=0
if echo "$PROMPT" | grep -iEq "$TRIGGERS"; then
  FORCE=1
fi

# Skill file missing? No-op.
if [ ! -f "$SKILL_FILE" ]; then
  exit 0
fi

# Check staleness
NOW=$(date +%s)
LAST=0
[ -f "$STATE_FILE" ] && LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
AGE=$((NOW - LAST))
STALE=0
if [ "$AGE" -gt $((REFRESH_MIN * 60)) ]; then
  STALE=1
fi

# Decide whether to inject
if [ "$FORCE" -eq 0 ] && [ "$STALE" -eq 0 ]; then
  exit 0
fi

# Inject the skill content
SKILL_CONTENT=$(cat "$SKILL_FILE")
HEADER="[design-skill-refresh: auto-reinjected design-to-code-qa skill — last refresh ${AGE}s ago, threshold ${REFRESH_MIN}min]"
COMBINED=$(printf '%s\n\n%s\n' "$HEADER" "$SKILL_CONTENT")

# Emit JSON with additionalContext
/usr/bin/python3 -c "
import json, sys
payload = {
  'continue': True,
  'suppressOutput': True,
  'hookSpecificOutput': {
    'hookEventName': 'UserPromptSubmit',
    'additionalContext': sys.stdin.read()
  }
}
print(json.dumps(payload))
" <<< "$COMBINED"

# Update timestamp
echo "$NOW" > "$STATE_FILE"

exit 0
