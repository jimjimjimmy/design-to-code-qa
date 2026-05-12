---
name: handoff
description: >
  Generate a handoff.md at the project root and commit it to git.
  Use at the end of any session to leave a clean context snapshot for the
  next session (or the next machine). Works for any project - personal
  (jimjimjimmy) or work (FQ). Part of the design-to-code-qa kit.
  Triggers: "generate handoff", "make handoff", "end of session",
  "wrap up", "switching sessions", "starting fresh".
---
# Handoff Generation - Execution Steps

Run these in order. Do not skip any step.

---

## Step 1 - Gather project state

Run all of these before writing a single word of the handoff doc:

```bash
# Project identity
git remote get-url origin 2>/dev/null || echo "no git remote"
git log --oneline -10
git status --short
git diff --stat HEAD

# Uncommitted changes summary
git diff --name-only
git stash list 2>/dev/null | head -5

# CLAUDE.md if it exists (project-specific context)
cat CLAUDE.md 2>/dev/null | head -80 || echo "no CLAUDE.md"
```

---

## Step 2 - Write handoff.md at the project root

File: `./handoff.md` (always overwrite - git has the history).

Use this structure exactly. Fill every section from what you gathered in Step 1.
Do not leave placeholder text. If a section has nothing to report, write "None."

```markdown
# Handoff - {project name} - {YYYY-MM-DD}

## What this is
One sentence: what project, what machine, what was being worked on.

## Current state
- What is built and working right now
- What is partially done or broken
- Any known bugs or regressions introduced this session

## Files changed this session
List every file touched (committed or not), one per line, with one-sentence
description of what changed.

| File | Status | What changed |
|------|--------|-------------|
| ...  | committed / staged / unstaged | ... |

## Uncommitted work
If there are uncommitted changes: describe what they are and whether they
are safe to commit or need more work first.

## Open questions / decisions pending
Things that were left unresolved. Specific enough that the next session
can act on them without re-reading the whole history.

## What to do next
Ordered list. First item is the most important thing to tackle.
1. ...
2. ...
3. ...

## How to resume
Exact commands to get back to working state on any machine:
```bash
git pull
# any other setup steps
```

## Machine / account notes
- Which machine generated this handoff (MacFQ / Gandalf / other)
- Any account-specific push instructions (jimjimjimmy token form if personal repo)
```

---

## Step 3 - Commit handoff.md

```bash
git add handoff.md
git commit -m "handoff: $(date '+%Y-%m-%d') session wrap"
```

For jimjimjimmy repos, push with the explicit token form:
```bash
GITHUB_TOKEN=$(gh auth token --hostname github.com -u jimjimjimmy 2>/dev/null)
REMOTE=$(git remote get-url origin | sed 's|https://||' | sed 's|.*@||')
git push "https://jimjimjimmy:${GITHUB_TOKEN}@https://${REMOTE}" main 2>/dev/null \
  || git push origin main
```

For FQ repos, push normally:
```bash
git push origin HEAD
```

---

## Step 4 - Copy to Dropbox AI Shared

Also save a copy to Dropbox so both machines always have it even before a git pull:

```bash
PROJECT=$(basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || echo "unknown")
cp handoff.md "$HOME/Dropbox/04 Projects/AI Shared/${PROJECT}-handoff.md"
echo "Saved to Dropbox: ${PROJECT}-handoff.md"
```

---

## Done

Tell the user:
- handoff.md committed and pushed
- Dropbox copy saved at path shown above
- "Start the next session by reading handoff.md or the Dropbox copy"
