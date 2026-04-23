#!/bin/bash
# Pre-commit asset check for design projects.
# Blocks commit if any generator-time URLs are found in CODE files.
#
# Install:
#   cp ~/.claude/templates/design-project/pre-commit-check.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Skips: *.md, *.txt (docs often need to reference these patterns to teach the rule)

set -e

# Get list of staged files, exclude docs
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -vE '\.(md|txt|rst)$' || true)

if [ -z "$FILES" ]; then
  echo "✅ No code files staged. Proceeding with commit."
  exit 0
fi

# Check staged diffs in code files only
BAD=""
for f in $FILES; do
  MATCH=$(git diff --cached -U0 -- "$f" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E 'localhost:[0-9]+|file://|127\.0\.0\.1:' || true)
  if [ -n "$MATCH" ]; then
    BAD="$BAD\n--- $f ---\n$MATCH"
  fi
done

if [ -n "$BAD" ]; then
  echo "🚫 Commit blocked — generator-time URLs detected in staged code changes:"
  echo -e "$BAD"
  echo ""
  echo "These URLs only work while the generating tool (Figma Dev Mode MCP, etc.) is running."
  echo "Fetch each asset, save to assets/, and reference by relative path before committing."
  echo ""
  echo "See: ~/Dropbox/04 Projects/AI Shared/memory/process_design_to_code_pipeline.md"
  echo ""
  echo "To bypass for an emergency (not recommended): git commit --no-verify"
  exit 1
fi

echo "✅ No generator-time URLs in staged code changes. Proceeding with commit."
