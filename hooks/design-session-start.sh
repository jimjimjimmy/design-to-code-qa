#!/bin/bash
# design-session-start.sh — SessionStart hook
#
# Purpose: inject the three hard design-to-code-qa rules at turn 1 of every
# session, so they're always fresh regardless of whether skill auto-activation
# fires for this project. Cheap insurance — ~300 tokens per new session.
#
# Hook contract (Claude Code SessionStart):
#   stdin  = JSON { hook_event_name, session_id, source, ... }
#     source = "startup" | "resume" | "clear" | "compact"
#   stdout = JSON { continue, suppressOutput, hookSpecificOutput:{additionalContext} }
#   exit 0 always.

set -e

# Read stdin but we don't need to branch on it for this primer
cat >/dev/null

MSG="[design-to-code-qa: session-start primer]

If this session touches UI from a Figma design, spec, or MCP output, THREE hard rules apply:

1. PARENT-DOWN SPEC PULL — call get_design_context on EACH distinct visual element before writing JSX. Same-named components have variants that differ at different sizes.
2. TRACE PADDING — write the exact pr-*, pl-*, pt-*, pb-* values from the spec into your plan before writing code. Never skip this for a new component.
3. VISUAL DIFF — screenshot the result, compare side-by-side with Figma, write a DIFF bullet list. 'DIFF: none' is required before requesting commit.

Pattern-matching a similar-looking existing component is the #1 failure mode. Don't do it.

Full skill: ~/.claude/skills/design-to-code-qa/SKILL.md
This primer is injected by ~/.claude/hooks/design-session-start.sh (SessionStart hook)."

/usr/bin/python3 -c "
import json, sys
payload = {
  'continue': True,
  'suppressOutput': True,
  'hookSpecificOutput': {
    'hookEventName': 'SessionStart',
    'additionalContext': sys.stdin.read()
  }
}
print(json.dumps(payload))
" <<< "$MSG"

exit 0
