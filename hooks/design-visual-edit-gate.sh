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
  *.tsx|*.jsx|*storybook.html|*preview.html) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")
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

Ref: ~/.claude/skills/design-to-code-qa/SKILL.md → 'Mandatory Visual-Diff Gate'"

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
