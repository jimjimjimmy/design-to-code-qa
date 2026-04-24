# design-to-code-qa

**Status:** Alpha (v0.1.0-alpha) — published, seeking real-world use. See [Versioning](#versioning) and [CHANGELOG](./CHANGELOG.md).

A portable kit for Claude Code that enforces **pixel-faithful, transportable Figma → code builds**.

Forged from a real-world lesson: shipping a project with `http://localhost:*/...` asset URLs baked in — a build that only rendered while Figma desktop was running. This kit is the guardrail so that doesn't happen again, for you or anyone you hand it to.

The deeper motivation: during the build that created this kit, Claude kept silently skipping visual verification steps, pattern-matching to existing components instead of tracing Figma specs, and forgetting rules mid-session. This turned out to coincide with [three simultaneous bugs in Claude Code](./docs/why-this-exists.md) that degraded reasoning quality invisibly — and reinforced the lesson that **instruction-based enforcement has a ceiling**. The hooks in this kit exist because shell scripts don't forget, even when the model does. See [`docs/why-this-exists.md`](./docs/why-this-exists.md) for the full context.

---

## What it does (in one sentence)

Teaches Claude Code to **always download every design asset into the repo before committing**, and **blocks commits at the git hook level** if any `localhost:*` / `file://` URL sneaks through.

See [SUMMARY.md](./SUMMARY.md) for a per-file breakdown.

---

## Install — Claude Code (CLI)

```bash
git clone https://github.com/jimjimjimmy/design-to-code-qa.git
cd design-to-code-qa
bash install.sh
```

What it installs:
- `~/.claude/skills/design-to-code-qa/SKILL.md` — auto-activates in Claude Code on design work
- `~/.claude/hooks/` — **three-hook package** (see below)
- `~/.claude/templates/design-project/` — bootstrap script + git hook + CLAUDE.md template
- (optional) A canonical pipeline doc copied to a memory folder you pick

### The three-hook package

Skill auto-activation is not 100% reliable across long sessions and context compactions. These hooks are deterministic backstops — cheap in tokens, aggressive at keeping the rules present.

| Hook | Event | What it does |
|---|---|---|
| `design-session-start.sh`    | `SessionStart`     | Injects the three hard rules (parent-down spec pull, trace padding, visual diff) at turn 1 of every session. |
| `design-skill-refresh.sh`    | `UserPromptSubmit` | Re-injects the full SKILL.md every 30 minutes, or immediately on any prompt containing a design keyword (`figma`, `design`, `storybook`, `component`, etc.). |
| `design-visual-edit-gate.sh` | `PostToolUse`      | After any `Write`/`Edit` to `.tsx` / `.jsx` / `storybook.html` / `preview.html`, injects a non-blocking DIFF-checklist reminder so the session can't declare "done" without a visual diff pass. |

After `install.sh`, the script prints the exact JSON to paste into `~/.claude/settings.json` under `"hooks"` to enable all three.

---

## Install — Claude Desktop (chat app)

Claude Desktop doesn't have the `~/.claude/skills/` system, so auto-activation won't work. You set it up manually per Project instead. The git-hook safety net still works the same.

**One-time setup per Project:**

1. Clone the repo (for reference): `git clone https://github.com/jimjimjimmy/design-to-code-qa.git`
2. Open `memory/process_design_to_code_pipeline.md` and copy its contents.
3. In Claude Desktop → create a new **Project** for your design work.
4. Paste the pipeline doc into the Project's **Custom Instructions** (or "Project knowledge").
5. Prepend this line so Claude treats it as binding:
   > *"Before implementing any UI from a Figma design or design spec, read and follow this pipeline end-to-end. The pre-commit checklist is mandatory."*

**Per design project (the git-hook safety net, still works for Desktop users):**

```bash
cd /path/to/your/design-project
git init   # if not already a repo
# Copy the bootstrap into place (or just run it from the cloned kit):
bash /path/to/design-to-code-qa/templates/design-project/bootstrap.sh "Project Name"
```

Bootstrap installs the pre-commit hook, creates the `assets/` folder structure, and drops a `CLAUDE.md` the Project can also reference.

**Note:** On Claude Desktop, you're responsible for telling Claude to follow the pipeline — it won't auto-load. The git hook is your deterministic backstop if Claude forgets.

---

## Using it on a new project

```bash
cd /path/to/new-project
git init   # if not already a repo
bash ~/.claude/templates/design-project/bootstrap.sh "My Project"
```

What bootstrap does:
1. Drops a `CLAUDE.md` with the required-reading header
2. Creates `assets/icons/logos/`, `assets/images/`
3. **Prompts** whether to scaffold a standalone `preview/storybook.html` (default: **No**). Most projects already have a component preview (team Storybook, dev server, Figma) and don't need a second one. Say yes only for solo/personal projects with no surrounding app. Override non-interactively with `WITH_STORYBOOK=1` or `WITH_STORYBOOK=0`.
4. Installs `.git/hooks/pre-commit` that blocks commits containing `localhost:*` / `file://` URLs in code files

From there, any Claude Code session working on that project will auto-load the skill and follow the pipeline.

---

## Using it on an existing project

```bash
cd /path/to/existing-project
bash ~/.claude/templates/design-project/bootstrap.sh
```

If `CLAUDE.md` already exists, bootstrap skips it — you'll need to paste the required-reading header from `CLAUDE.md.template` manually.

If `.git/hooks/pre-commit` already exists, bootstrap skips it — merge from `pre-commit-check.sh` manually.

---

## How the enforcement works

Three layers, on purpose:

1. **Skill (proactive)** — Claude reads the pipeline before writing code.
2. **CLAUDE.md header (contextual)** — reminds every new session what the non-negotiables are.
3. **Git hook (deterministic)** — if the first two fail, the commit fails. Docs files (`.md`, `.txt`, `.rst`) are exempt since they often reference these patterns to teach the rule.

---

## File layout

```
design-to-code-qa/
├── README.md                        ← you are here
├── SUMMARY.md                       ← what each file does, in plain English
├── CHANGELOG.md                     ← version history
├── install.sh                       ← copies files to ~/.claude/
├── docs/
│   └── why-this-exists.md           ← origin story + Anthropic April 2025 postmortem context
├── skill/
│   └── SKILL.md                     ← auto-loaded by Claude Code
├── hooks/
│   ├── design-session-start.sh     ← SessionStart primer (3 hard rules)
│   ├── design-skill-refresh.sh     ← UserPromptSubmit refresh (time + keyword)
│   └── design-visual-edit-gate.sh  ← PostToolUse DIFF reminder on visual files
├── memory/
│   └── process_design_to_code_pipeline.md   ← canonical long-form doc
└── templates/
    └── design-project/
        ├── bootstrap.sh             ← one-command project setup
        ├── pre-commit-check.sh      ← git hook
        └── CLAUDE.md.template       ← project header template
```

---

## Versioning

Three stages, advance manually:

- **Alpha** — first publish. Shape may change. Expect breaking updates between versions.
- **Beta** — shape locked, hardening in use. Safe for non-critical work.
- **Stable** — API frozen. Semver-level changes only. Production-ready.

Promotion requires a conscious commit (e.g. `v0.1.0-alpha` → `v0.2.0-beta` → `v1.0.0`). No silent transitions. Self-policed.

---

## Personalizing the skill

The skill runs generically out of the box. To tailor it to your browser, preview style, and screenshot tool, run:

```bash
bash ~/.claude/skills/design-to-code-qa/onboard.sh
```

This writes `~/.claude/skills/design-to-code-qa/user-prefs.md`. The skill reads that file if present and phrases its instructions in your terms.

**Team overlays.** If you want a group of designers to share a preset (browser, preview reference, terminology), write a small overlay script that writes `user-prefs.md` directly and skips the interactive prompts. The public kit stays generic; your overlay stays private. Install flow becomes:

```bash
bash install.sh            # public kit
bash your-overlay.sh       # writes user-prefs.md with team defaults
```

---

## Credits

Born from a real-world Figma-to-code project. Rules match Figma's own Dev Mode MCP guidance — this kit just makes them enforceable.
