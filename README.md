# design-to-code-qa

A portable kit for Claude Code that enforces **pixel-faithful, transportable Figma → code builds**.

Forged from a real-world lesson: shipping a storybook with `http://localhost:3845/...` asset URLs baked in — a build that only rendered while Figma desktop was running. This kit is the guardrail so that doesn't happen again, for you or anyone you hand it to.

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
- `~/.claude/templates/design-project/` — bootstrap script + git hook + CLAUDE.md template
- (optional) A canonical pipeline doc copied to a memory folder you pick

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
3. Installs `.git/hooks/pre-commit` that blocks commits containing `localhost:*` / `file://` URLs in code files

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
├── install.sh                       ← copies files to ~/.claude/
├── skill/
│   └── SKILL.md                     ← auto-loaded by Claude Code
├── memory/
│   └── process_design_to_code_pipeline.md   ← canonical long-form doc
└── templates/
    └── design-project/
        ├── bootstrap.sh             ← one-command project setup
        ├── pre-commit-check.sh      ← git hook
        └── CLAUDE.md.template       ← project header template
```

---

## Credits

Born from building the Beacon civic-news design system. Rules match Figma's own Dev Mode MCP guidance — this kit just makes them enforceable.
