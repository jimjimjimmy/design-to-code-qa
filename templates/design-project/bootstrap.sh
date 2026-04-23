#!/bin/bash
# Bootstrap a design project with the design-to-code-qa guardrails.
#
# Usage (run from inside the project root):
#   bash ~/.claude/templates/design-project/bootstrap.sh "Project Name"
#
# Non-interactive (skip prompts, take defaults):
#   WITH_STORYBOOK=0 bash ~/.claude/templates/design-project/bootstrap.sh "Project Name"
#   WITH_STORYBOOK=1 bash ~/.claude/templates/design-project/bootstrap.sh "Project Name"
#
# What it does:
#   1. Drops a CLAUDE.md with the required-reading header (if none exists)
#   2. Creates the assets/ folder structure
#   3. (optional) Scaffolds a standalone preview/storybook.html — OFF by default
#   4. Installs the git pre-commit hook that blocks localhost/file:// URLs

set -e

PROJECT_NAME="${1:-$(basename "$PWD")}"
TEMPLATES_DIR="$HOME/.claude/templates/design-project"

echo "🎨 Bootstrapping design project: $PROJECT_NAME"
echo ""

# 0. Storybook preview — opt in.
#    Default: NO. Most designers working inside an existing codebase already have
#    a component preview (their team's Storybook, a live dev server, Figma, etc.)
#    and don't need a second one. The standalone preview/storybook.html is for
#    solo/personal projects where there's no surrounding app to render components in.
if [ -n "$WITH_STORYBOOK" ]; then
  # Non-interactive override
  case "$WITH_STORYBOOK" in
    1|true|yes|y|Y) WANT_STORYBOOK=1 ;;
    *)              WANT_STORYBOOK=0 ;;
  esac
else
  echo "📓 Standalone storybook preview?"
  echo "   A single-file preview/storybook.html that renders your components via"
  echo "   React + Babel Standalone with no build step. Useful only if the project"
  echo "   has no other component preview. If your team already has a Storybook,"
  echo "   a dev server, or you preview via Figma, SKIP THIS."
  echo ""
  read -r -p "   Scaffold preview/storybook.html? [y/N] " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    WANT_STORYBOOK=1
  else
    WANT_STORYBOOK=0
  fi
  echo ""
fi

# 1. CLAUDE.md
if [ -f CLAUDE.md ]; then
  echo "  CLAUDE.md already exists — skipping (review it manually to add the required-reading header)."
else
  sed "s/{PROJECT_NAME}/$PROJECT_NAME/g" "$TEMPLATES_DIR/CLAUDE.md.template" > CLAUDE.md
  echo "  ✅ CLAUDE.md created"
fi

# 2. assets/ structure
mkdir -p assets/icons/logos assets/images
echo "  ✅ assets/{icons,icons/logos,images}/ created"

# 2b. Optional standalone storybook preview
if [ "$WANT_STORYBOOK" = "1" ]; then
  mkdir -p preview
  if [ -f preview/storybook.html ]; then
    echo "  ⚠️  preview/storybook.html already exists — skipping scaffold."
  else
    cat > preview/storybook.html <<'STORYBOOK_HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Storybook</title>
  <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <style>body{font-family:system-ui;margin:2rem;}</style>
</head>
<body>
  <div id="root"></div>
  <script type="text/babel" data-presets="env,react">
    const App = () => <div><h1>Storybook</h1><p>Add your components here.</p></div>;
    ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
  </script>
</body>
</html>
STORYBOOK_HTML
    echo "  ✅ preview/storybook.html scaffolded"
  fi
else
  echo "  ⏭  Skipping standalone storybook (most projects don't need it)."
fi

# 3. Git pre-commit hook
if [ ! -d .git ]; then
  echo "  ⚠️  Not a git repo yet — skipping pre-commit hook. Run 'git init' then re-run this script."
else
  if [ -f .git/hooks/pre-commit ]; then
    echo "  ⚠️  .git/hooks/pre-commit already exists — not overwriting. Merge manually from:"
    echo "       $TEMPLATES_DIR/pre-commit-check.sh"
  else
    cp "$TEMPLATES_DIR/pre-commit-check.sh" .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "  ✅ .git/hooks/pre-commit installed (blocks commits with localhost/file:// URLs)"
  fi
fi

echo ""
echo "🎨 Done. Next: open this project in Claude Code — the design-to-code-qa skill will auto-activate on design work."
