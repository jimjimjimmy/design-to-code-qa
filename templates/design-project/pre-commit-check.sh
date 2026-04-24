#!/bin/bash
# Pre-commit asset check for design projects.
# Two gates, both blocking:
#   1. No generator-time URLs (localhost:*, file://, 127.0.0.1:) in staged code.
#   2. Every relative asset reference (src=, href=, url(...)) in staged code
#      resolves to a file that actually exists on disk.
#
# Install:
#   cp ~/.claude/templates/design-project/pre-commit-check.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Docs files exempt: *.md, *.txt, *.rst (they often reference these patterns to teach).

set -e

# Staged code files only (exclude docs).
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -vE '\.(md|txt|rst)$' || true)

if [ -z "$FILES" ]; then
  echo "✅ No code files staged. Proceeding with commit."
  exit 0
fi

FAIL=0

# ─── Gate 1: Generator-time URLs ────────────────────────────────────────────
BAD_URLS=""
for f in $FILES; do
  MATCH=$(git diff --cached -U0 -- "$f" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E 'localhost:[0-9]+|file://|127\.0\.0\.1:' || true)
  if [ -n "$MATCH" ]; then
    BAD_URLS="$BAD_URLS\n--- $f ---\n$MATCH"
  fi
done

if [ -n "$BAD_URLS" ]; then
  echo "🚫 Commit blocked — generator-time URLs detected in staged code:"
  echo -e "$BAD_URLS"
  echo ""
  echo "These URLs only work while the generating tool (Figma Dev Mode MCP, etc.) is running."
  echo "Fetch each asset, save to assets/, and reference by relative path before committing."
  FAIL=1
fi

# ─── Gate 2: Broken asset references ────────────────────────────────────────
# Python does path resolution; bash writes the file list to a temp file.
REPO_ROOT=$(git rev-parse --show-toplevel)
FILELIST=$(mktemp)
printf '%s\n' $FILES > "$FILELIST"
PYSCRIPT=$(mktemp)
cat > "$PYSCRIPT" <<'PY'
import os, re, subprocess, sys

repo_root = os.environ["REPO_ROOT"]
with open(sys.argv[1]) as fh:
    files = [ln.strip() for ln in fh if ln.strip()]

# Extensions we actually care about (local asset refs).
ASSET_EXTS = {
    ".png",".jpg",".jpeg",".gif",".webp",".svg",".ico",".avif",
    ".woff",".woff2",".ttf",".otf",".eot",
    ".mp3",".mp4",".webm",".wav",".ogg",
    ".css",".js",".mjs",".json",".pdf",
}

# src="…"  href="…"  url(…)  — quoted or unquoted.
PATTERNS = [
    re.compile(r'''\bsrc\s*=\s*["']([^"']+)["']'''),
    re.compile(r'''\bhref\s*=\s*["']([^"']+)["']'''),
    re.compile(r'''\burl\(\s*["']?([^"')]+)["']?\s*\)'''),
]

broken = []

for f in files:
    if not os.path.exists(f):
        continue
    # Only scan added lines from the staged diff.
    try:
        diff = subprocess.check_output(
            ["git", "diff", "--cached", "-U0", "--", f],
            text=True, errors="replace",
        )
    except subprocess.CalledProcessError:
        continue

    added = [ln[1:] for ln in diff.splitlines()
             if ln.startswith("+") and not ln.startswith("+++")]
    if not added:
        continue

    file_dir = os.path.dirname(os.path.join(repo_root, f))

    for line in added:
        for pat in PATTERNS:
            for m in pat.finditer(line):
                ref = m.group(1).strip()
                # Skip absolute URLs, data URIs, fragments, template vars.
                if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*://', ref): continue
                if ref.startswith(("data:","#","mailto:","tel:","javascript:")): continue
                if ref.startswith("//"): continue
                if "${" in ref or "{{" in ref or "{" in ref and "}" in ref: continue
                # Strip query/hash.
                clean = ref.split("?",1)[0].split("#",1)[0]
                if not clean: continue
                # Only check things that look like asset files.
                ext = os.path.splitext(clean)[1].lower()
                if ext not in ASSET_EXTS: continue

                # Resolve relative to the file's directory, or repo root if leading "/".
                if clean.startswith("/"):
                    resolved = os.path.normpath(os.path.join(repo_root, clean.lstrip("/")))
                else:
                    resolved = os.path.normpath(os.path.join(file_dir, clean))

                if not os.path.exists(resolved):
                    rel = os.path.relpath(resolved, repo_root)
                    broken.append(f"  {f}: {ref}  →  {rel} (NOT FOUND)")

for b in broken:
    print(b)
PY

MISSING=$(REPO_ROOT="$REPO_ROOT" python3 "$PYSCRIPT" "$FILELIST")
rm -f "$FILELIST" "$PYSCRIPT"

if [ -n "$MISSING" ]; then
  echo ""
  echo "🚫 Commit blocked — broken asset references in staged code:"
  echo "$MISSING"
  echo ""
  echo "Every src=, href=, and url(...) must resolve to a file that exists on disk."
  echo "Check the folder convention (ls assets/) before picking a path."
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "See: https://github.com/jimjimjimmy/design-to-code-qa/blob/main/memory/process_design_to_code_pipeline.md"
  echo "Bypass (not recommended): git commit --no-verify"
  exit 1
fi

echo "✅ No generator-time URLs. ✅ All asset references resolve. Proceeding."
