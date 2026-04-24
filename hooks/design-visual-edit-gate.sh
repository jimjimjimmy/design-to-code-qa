#!/bin/bash
# design-visual-edit-gate.sh — PostToolUse hook
#
# Purpose: after any Write/Edit to a visual source file (.tsx/.jsx/storybook.html
# /preview.html), inject a reminder that the component must be screenshot-diffed
# against the Figma reference before the session declares done or requests commit.
#
# This is non-blocking by design — hard-blocking every JSX edit would be
# maddening. The reminder keeps visual-diff pressure on, cumulatively.
#
# Hook contract (Claude Code PostToolUse):
#   stdin  = JSON { hook_event_name, tool_name, tool_input, tool_response, ... }
#   stdout = JSON { continue: true, suppressOutput: true,
#                   hookSpecificOutput: { hookEventName, additionalContext } }
#             OR empty
#   exit 0 always.

set -e

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | /usr/bin/python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("tool_name",""))
except Exception: pass' 2>/dev/null || echo "")

FILE_PATH=$(echo "$INPUT" | /usr/bin/python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))
except Exception: pass' 2>/dev/null || echo "")

# Only fire for Write/Edit
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Only fire for visual files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.mdx|*storybook.html|*preview.html) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")

# Check whether the written/edited content contains animation keywords.
# Pull from new_string (Edit) or content (Write) via tool_input.
ANIM_CONTENT=$(echo "$INPUT" | /usr/bin/python3 -c '
import sys, json, re
try:
  d = json.load(sys.stdin)
  ti = d.get("tool_input", {})
  text = ti.get("new_string", "") + ti.get("content", "")
  keywords = ["useReveal", "animate", "keyframe", "motion", "framer",
              "useSpring", "useTransition", "useAnimation",
              "AnimatePresence", "variants", "initial=", "whileInView="]
  if any(k in text for k in keywords):
    print("yes")
except Exception:
  pass
' 2>/dev/null || echo "")

ANIMATION_ADDENDUM=""
if [ "$ANIM_CONTENT" = "yes" ]; then
ANIMATION_ADDENDUM="
⚠️  Animation keywords detected. Also run Phase 4.5 — Animation Diff Gate:
- Probe computed styles via preview_eval at t=50/200/500/900/1300ms post-trigger.
- Compare property values against Phase 1.5 timeline table.
- Check for animation fights: does your wrapper opacity/transform overlap the child's internal animation?
- Check for nested-component trap: trigger a parent state change mid-animation — does the child's animation reset?
- Write an ANIMATION DIFF table. Only emit 'ANIMATION DIFF: none' when the table is empty.
The hero is the reference component's internal animation. Do not step on it."
fi

MSG="[design-qa gate] Visual file edited: ${BASENAME}

Before declaring this component done or asking to commit:
1. Screenshot the rendered result (preview_screenshot or equivalent).
2. Place it side-by-side with the Figma reference screenshot.
3. Write a DIFF bullet list. Scan for:
   - Content column width (is text constrained to the correct region via pr-*?)
   - Badge / pill position, size, color, border
   - Gradient direction and stops
   - Type size and weight for every text element
   - Action / engagement bar alignment (left-clustered vs. spread)
   - Spacing between sections (gap, margin, padding)
4. Only emit 'DIFF: none' and request commit AFTER the list is empty.
${ANIMATION_ADDENDUM}
Ref: ~/.claude/skills/design-to-code-qa/SKILL.md → Phase 4 / Phase 4.5"

/usr/bin/python3 -c "
import json, sys
payload = {
  'continue': True,
  'suppressOutput': True,
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': sys.stdin.read()
  }
}
print(json.dumps(payload))
" <<< "$MSG"

exit 0
