# Why This Kit Exists

This document explains the real-world failures that motivated building `design-to-code-qa` — and why hook-based enforcement was chosen over relying on Claude's instructions alone.

---

## The Core Problem

When implementing UI components from Figma specs in long Claude Code sessions, three failure modes kept appearing:

1. **Spec-tracing failure** — Claude reads a Figma spec (e.g. `padding-right: 640px`), acknowledges it, then writes code that ignores it and pattern-matches to a similar-looking existing component instead.
2. **Rules forgotten mid-session** — Instructions given at the start of a session degraded after 30–40 turns. Claude would skip visual verification steps it had followed earlier.
3. **Premature "done"** — Claude would declare a component finished without taking a screenshot or comparing it against the Figma reference.

The instinct was to write better instructions. But better instructions kept failing. The reason turned out to be partly structural (long-session context degradation) and partly something else entirely.

---

## The Anthropic April 2025 Postmortem

On April 23, 2025, Anthropic published a postmortem ([anthropic.com/engineering/april-23-postmortem](https://www.anthropic.com/engineering/april-23-postmortem)) revealing that **three separate bugs had been silently degrading Claude Code's quality** between March and April 2025 — all while looking like normal model behavior to users.

### Bug 1: Reasoning effort quietly downgraded (March 4 → April 7)
Default reasoning effort was switched from `high` to `medium` to fix UI freezes. Lower reasoning = more pattern-matching, less careful spec-reading. Claude was literally thinking less per turn without any indication to users.

**How it caused failures here:** Pattern-matching to an existing component instead of tracing the Figma spec is exactly what happens when reasoning effort drops. The model takes the path of least resistance.

### Bug 2: Caching bug that wiped thinking every turn (March 26 → April 10)
A prompt caching optimization contained a flaw: instead of clearing Claude's reasoning once at session idle, it **cleared thinking every single turn for the rest of the session**. Claude appeared to forget instructions it had just followed.

**How it caused failures here:** "Rules get forgotten mid-session" was attributed to context window degradation. It was actually a bug that made Claude lose its chain of thought between every single turn.

### Bug 3: Forced brevity instruction (April 16 → April 20)
A system prompt was added instructing Claude to keep responses under 25 words between tool calls and under 100 words total. This reduced coding quality by ~3%.

**How it caused failures here:** "Declares task done before visually verifying" — Claude was being internally penalized for writing thorough verification steps. Skipping the screenshot comparison was the "correct" response under that instruction.

All three issues were fixed by April 20 (v2.1.116). Users were given usage limit resets on April 23.

---

## What This Means for Any Claude-Assisted Design Workflow

These bugs were invisible. Nothing in the UI indicated that reasoning effort had been halved, or that thinking was being wiped every turn, or that brevity was being incentivized. Users (and Claude itself) experienced the symptoms as normal behavior.

**The lesson:** Instruction-based enforcement has a ceiling. If the model's underlying reasoning quality changes — whether by bug, config change, or version update — all your carefully written rules become suggestions at best.

This is why the kit uses **three enforcement layers**, ordered by reliability:

| Layer | How it works | Survives model regressions? |
|---|---|---|
| `pre-commit-check.sh` | Blocks commits with `localhost:*` URLs | ✅ Yes — shell script, model-independent |
| `design-visual-edit-gate.sh` | Injects DIFF checklist after every visual file write | 🟡 Partially — hook fires regardless, but Claude still writes the diff |
| `design-session-start.sh` | Injects rules at session start | 🟡 Partially — helps with fresh sessions, not mid-session bugs |
| `SKILL.md` instructions | Claude reads the pipeline before building | ❌ No — subject to all three failure modes above |

The git hook is the only layer that is fully immune to model behavior changes. Everything above it degrades gracefully — it's better than nothing, but don't treat it as guaranteed enforcement.

---

## Why "Better Instructions" Wasn't the Answer

The natural response to Claude skipping steps is to add more explicit instructions. This kit has those too. But:

- A verbosity instruction at the system level **overrides** any user-level instruction to "always take a screenshot"
- A caching bug **overwrites** any rules Claude read at the start of the session
- Reduced reasoning effort means Claude reads the rules and then reasons less carefully about applying them

The correct response is to move enforcement **outside Claude's reasoning loop entirely** — into shell scripts that fire unconditionally. That's what the hooks are. They don't ask Claude to remember; they create conditions where skipping the step produces a visible artifact (a blocked commit, an injected checklist) rather than a silent failure.

---

## Will This Happen Again?

Almost certainly something else will change at Anthropic that affects Claude Code's behavior. Models are updated frequently, system prompts change, and infrastructure bugs happen. This kit is designed to be resilient to those changes:

- The git hook works regardless of model version or system prompt
- The session-start hook re-injects rules on every new conversation, compensating for caching-related forgetfulness
- The visual-edit-gate hook fires on file writes, not on Claude's self-assessment of completeness

The goal isn't to make the AI perfect. It's to make the **process** robust enough that when the AI has a bad day (or a bad deploy), the output still meets a minimum quality bar.
