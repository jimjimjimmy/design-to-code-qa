# What each file does

A quick plain-English reference.

---

## `skill/SKILL.md`

**The auto-loader.** A Claude Code "skill" file with YAML frontmatter that activates automatically whenever you work on design-to-code tasks. Once installed to `~/.claude/skills/design-to-code-qa/`, Claude will read it before touching any Figma-driven work. It contains the rules, the asset pipeline, the QA checklist, and the anti-patterns.

Think of it as: *"Claude's standing orders for any design job."*

---

## `memory/process_design_to_code_pipeline.md`

**The canonical long-form doc.** Same rules as the skill, expanded — the reference you'd hand to a human teammate. Useful if you want a single source of truth to point at during code review or onboarding. The skill file links to it.

Think of it as: *"The book version of the skill."*

---

## `templates/design-project/bootstrap.sh`

**One-command project setup.** Run it inside any project folder and it:
1. Drops a `CLAUDE.md` with the required-reading header
2. Creates `assets/icons/logos/` and `assets/images/`
3. Installs the git pre-commit hook

Safe to re-run — it won't overwrite existing `CLAUDE.md` or hook files.

Think of it as: *"Make this project follow the rules."*

---

## `templates/design-project/pre-commit-check.sh`

**The git hook that actually blocks bad commits.** Scans your staged diffs for `localhost:*`, `file://`, or `127.0.0.1:` URLs in code files (skips `.md`/`.txt`/`.rst` so docs can still reference these patterns as examples). If any are found, the commit fails with a message pointing at the pipeline doc.

This is the deterministic safety net — it works even if Claude ignores the skill.

Think of it as: *"The bouncer at the commit door."*

---

## `templates/design-project/CLAUDE.md.template`

**The per-project header.** A template for a project's `CLAUDE.md` that includes the required-reading block pointing at the skill and pipeline doc. Use it when `bootstrap.sh` detects an existing `CLAUDE.md` and you want to merge the header in manually.

Think of it as: *"The first thing every new Claude session reads about this project."*

---

## `install.sh`

**Puts the kit in the right global locations.** Copies the skill to `~/.claude/skills/`, the templates to `~/.claude/templates/design-project/`, and optionally the memory doc to a folder you choose. Run once per machine.

Think of it as: *"Install the kit globally so every project can use it."*

---

## How they work together

```
                   ┌─────────────────────────┐
                   │  install.sh (one-time)  │
                   └────────────┬────────────┘
                                │ copies to ~/.claude/
                ┌───────────────┴───────────────┐
                ▼                               ▼
   ~/.claude/skills/               ~/.claude/templates/design-project/
   design-to-code-qa/SKILL.md      bootstrap.sh, pre-commit, CLAUDE.md.template
                │                               │
                │ auto-loaded                   │ run per project
                │ by Claude Code                │
                ▼                               ▼
        ┌──────────────────────────────────────────┐
        │  Your design project                     │
        │    • CLAUDE.md with required-reading     │
        │    • assets/ folder structure            │
        │    • .git/hooks/pre-commit (enforcer)    │
        │    • Claude follows the pipeline         │
        └──────────────────────────────────────────┘
```
