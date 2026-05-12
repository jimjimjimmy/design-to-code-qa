#!/bin/bash
# handoff-stop-reminder.sh - Stop hook
#
# Purpose: when Claude Code stops, check whether a handoff.md was committed
# this session. If not, remind the user to generate one before switching
# sessions or machines.
#
# Non-blocking by design. This is a nudge, not a gate.
#
# Hook contract (Claude Code Stop):
#   stdin  = JSON { hook_event_name, session_id, cwd, ... }
#   stdout = JSON { continue: true, suppressOutput: false,
#                   hookSpecificOutput: { additionalContext: "..." } }
#             OR empty (no-op)
#   exit 0 always

set -e

INPUT=$(cat)

# Get the cwd from hook input, fall back to $PWD
CWD=$(echo "$INPUT" | /usr/bin/python3 -c '
import sys, json
try: print(json.load(sys.stdin).get("cwd", ""))
except Exception: pass
' 2>/dev/null || echo "")
[ -z "$CWD" ] && CWD="$PWD"

# Only fire if we are inside a git repo
if ! git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# Check: was handoff.md committed in the last 4 hours?
# (covers a full working session without false-positives from yesterday)
RECENT=$(git -C "$CWD" log --since="4 hours ago" --oneline -- handoff.md 2>/dev/null | head -1)
if [ -n "$RECENT" ]; then
  exit 0
fi

# Check: are there any changes at all this session? (skip reminder on idle sessions)
CHANGED=$(git -C "$CWD" diff --name-only HEAD 2>/dev/null)
STAGED=$(git -C "$CWD" diff --cached --name-only 2>/dev/null)
RECENT_COMMITS=$(git -C "$CWD" log --since="4 hours ago" --oneline 2>/dev/null | head -1)
if [ -z "$CHANGED" ] && [ -z "$STAGED" ] && [ -z "$RECENT_COMMITS" ]; then
  exit 0
fi

PROJECT=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "this project")

MSG="[handoff reminder] No handoff.md committed yet for ${PROJECT}.

Before switching sessions or machines, consider running:
  'generate handoff' or 'wrap up'

This will write handoff.md, commit it, and copy it to Dropbox so the next
session starts with clean context instead of a stale one.

Skill: ~/.claude/skills/handoff/SKILL.md"

/usr/bin/python3 -c "
import json, sys
payload = {
  'continue': True,
  'suppressOutput': False,
  'hookSpecificOutput': {
    'hookEventName': 'Stop',
    'additionalContext': sys.stdin.read()
  }
}
print(json.dumps(payload))
" <<< "$MSG"

exit 0
