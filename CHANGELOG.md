# Changelog

## v0.1.0-alpha — 2026-04-23

First public release. Alpha because no one outside the author has used it yet.

### Added
- `skill/SKILL.md` — auto-activating design-to-code-qa skill with pre-build checklist, visual-diff gate, and anti-pattern notes.
- `memory/process_design_to_code_pipeline.md` — canonical long-form pipeline doc.
- `templates/design-project/` — `bootstrap.sh` (opt-in storybook prompt), `pre-commit-check.sh` (blocks `localhost:*` / `file://` URLs), `CLAUDE.md.template`.
- Three-hook package in `hooks/`:
  - `design-session-start.sh` — SessionStart primer injecting the three hard rules at turn 1.
  - `design-skill-refresh.sh` — UserPromptSubmit hook that re-injects SKILL.md every 30 minutes or on design keywords.
  - `design-visual-edit-gate.sh` — PostToolUse hook that injects a DIFF reminder after `Write`/`Edit` on `.tsx` / `.jsx` / `.mdx` / `*storybook.html` / `*preview.html`.
- `onboard.sh` — interactive personalization script (browser detection, preview style, screenshot tool) that writes `user-prefs.md`. SKILL.md reads the prefs file if present.
- `install.sh` — installs skill, hooks, templates, and onboarding script. Prints settings snippet for wiring all three hooks.

### Notes
- Browser detection is macOS-only for now.
- Designed to be extended via overlay scripts: teams can write their own small script that writes `user-prefs.md` directly with team-specific defaults, no need to fork the public kit.
