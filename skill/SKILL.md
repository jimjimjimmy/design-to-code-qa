---
name: design-to-code-qa
description: MANDATORY execution checklist for TWO modes - (A) BUILD mode when building any UI from a Figma design, spec, MCP output, or AI-generated component code; (B) REVIEW mode when QA'ing an existing implementation against a Figma design, Jira ticket, PRD, dev site link, or engineer video. This is not documentation - it is a sequence of steps with STOP gates. Do not skip ahead. BUILD triggers: "build/implement/port this design", Figma URL or node ID, localhost/file:// URLs in tool output, storybook work. REVIEW triggers: "can you QA this", "review this implementation", "does this match the design", "check this ticket", engineer video/dev site/screenshot shared with a ticket or Figma link.
---

# Design -> Code -> QA - Execution Checklist

**Read this as instructions to run, not prose to summarize.** Each phase ends with a STOP gate. Do not enter the next phase until the gate condition is met.

Two modes:
- **BUILD mode** (Phases 0–5): you are writing code from a design.
- **REVIEW mode** (Phase 6): you are QA'ing an implementation that already exists.

They share Phase 1 (spec pull). If the user hands you both a design and an existing implementation to check, run Phase 1 first, then jump to Phase 6.

The single biggest failure mode is treating this file as documentation. It is a script you execute.

---

## Phase 0 - Detect company context first

Before running Setup, decide whether this session has a company-specific design system that changes the tool pipeline.

**Company context exists if ANY of these are true:**
- The working directory, file paths, or user language references a specific organization, product, or team design system
- A Figma URL points to a company-owned design file (your `user-prefs.md` lists the file ID if configured)
- The work touches a company codebase or repo (your `user-prefs.md` lists repo path patterns if configured)
- The user explicitly mentions a company design system by name (Storybook, component library, token system)

**No company context if:**
- The project is personal, open-source, or unrelated to any organization with a design system
- No design system has been configured in `user-prefs.md`
- In doubt, ask the user once before applying company-specific rules

If NO company context: skip the rest of this section. Proceed with generic Figma guidance in Phase 0 below.

If YES company context: follow the three-source pipeline defined in your `user-prefs.md` BEFORE any component work. The general pattern is:

**1. Design system docs / Storybook** - first stop for usage guidance, dos/don'ts, visual examples, and pattern decisions. Your `user-prefs.md` supplies the specific MCP tool names and URLs.

**2. Component library / component MCP** - second stop for prop signatures and available variants. Your `user-prefs.md` supplies the tool names.

**3. Figma** - third stop for pixel-level token verification (color, spacing, type). Your `user-prefs.md` supplies the company Figma file ID if applicable.

Rules when company context is active:
1. **Never invent components.** Every UI element must map to a documented component in the design system. Check Storybook/docs first, then the component library.
2. **Design system docs are the source of truth for usage guidance.** "Should we use X or Y?" - pull the relevant pattern page before deciding.
3. **Component library is the source of truth for prop signatures.** Use it before writing code.
4. **Figma is the source of truth for pixel-level tokens.** Use it for color/spacing/typography exactness.
5. **If any required MCP is not loaded**, stop and load it via ToolSearch before continuing. Do NOT proceed with "best guess" styling.
6. **In REVIEW mode**, every flagged component must cite the design system component it should be using.

These rules apply to BOTH BUILD and REVIEW modes and take precedence over generic Figma-only guidance below.

---

## Phase 0 - Setup (BUILD mode, run this FIRST, every time)

Run, in order:

1. `ls assets/ 2>/dev/null || echo "NO assets/ DIR"` - **record the existing folder convention verbatim.** If `assets/images/` exists, new images go there. If `public/assets/` exists, that's the convention. Do not invent a new one.
2. `cat user-prefs.md 2>/dev/null` at this skill's directory - pull browser, preview style, screenshot tool, terminology.
3. Identify the preview entry file (e.g. `preview/storybook.html`, `src/App.tsx`). Note its directory - all relative asset paths resolve from there.

**STOP GATE 0:** Write one sentence in your reply stating (a) the asset folder path that already exists, (b) the preview file's directory, (c) what a relative path from preview -> assets looks like (e.g. `../assets/images/foo.png`). Do not proceed to Phase 1 until this is written.

---

## Phase 0.5 - Generate the Run Checklist (HARD GATE - both modes)

**Why this exists:** the user cannot tell whether you actually executed each phase or just claimed to. A persistent checklist file is the visible artifact. The user can `cat qa/<task-slug>/checklist.md` at any time to see what you have actually completed vs skipped.

**Do this BEFORE Phase 1:**

1. Pick a `<task-slug>` from the user's task description (kebab-case, short, e.g. `buttons-links-catalog`, `issue-card-hero-fix`).
2. `mkdir -p qa/<task-slug>` at the project root (the directory containing the preview file's parent).
3. Write `qa/<task-slug>/checklist.md` using the template below. EVERY box starts as `[ ]`.
4. In your reply to the user, print exactly:
   `Checklist: qa/<task-slug>/checklist.md`
   so the user knows where to look.
5. As you complete each item in subsequent phases, update its box from `[ ]` to `[x]` using a single `Edit` call. **Update one item at a time, the moment it is actually done.** Never batch-check items at the end. Never check an item you have not done.

### Checklist template (copy verbatim, then customize the per-component lines in Phase 1.5/2/4)

```
# QA Checklist - <task title>
Mode: BUILD | REVIEW (delete one)
Source: <Figma node id or Jira ticket>
Started: <timestamp>

## Phase 0 - Setup
- [ ] Listed existing asset folder convention
- [ ] Read user-prefs.md
- [ ] Identified preview entry file and its directory
- [ ] Wrote STOP GATE 0 sentence in reply

## Phase 0.5 - Checklist
- [ ] Created qa/<task-slug>/ directory
- [ ] Wrote this checklist file
- [ ] Printed checklist path in user-visible reply

## Phase 1 - Spec Pull
- [ ] get_metadata on parent frame
- [ ] get_design_context on each distinct child (list them below)
- [ ] get_screenshot on parent frame -> saved as qa/<task-slug>/figma-parent.png
- [ ] Per-element spec written to qa/<task-slug>/specs/<component>.md
- [ ] All asset URLs (localhost:3845/...) listed in qa/<task-slug>/asset-urls.txt
- [ ] STOP GATE 1 satisfied (no "roughly" anywhere in plan)

## Phase 1.4 - Component Inventory
- [ ] Grepped codebase for each candidate component name
- [ ] Mapped Figma name -> existing code component (or "none, build new")
- [ ] No duplicate component being created

## Phase 1.5 - Asset Pull (if any new images/SVGs)
- [ ] Every asset downloaded from localhost:3845 to assets/<subdir>/
- [ ] grep -rn "localhost:\|file://" preview/ returns nothing
- [ ] Inlined SVG strokes/fills match Figma (no hand-drawn substitutes)

## Phase 2 - Build / Review per component
(Add one block per component)

### <ComponentName>
- [ ] Padding (pt/pr/pb/pl) traced from spec into JSX comment
- [ ] flex/gap values match spec exactly
- [ ] Font size/weight/lineHeight/letterSpacing match spec
- [ ] Asset references use relative path (no localhost, no file://)
- [ ] All interactive states present (Default/Hover/Active/Disabled) or em-dash placeholder

## Phase 3 - Render & Screenshot
- [ ] Preview running, component visible (no JS errors)
- [ ] Screenshot saved as qa/<task-slug>/built-<component>.png
- [ ] Did NOT call preview_resize

## Phase 4 - Visual DIFF
(One block per component)

### <ComponentName>
- [ ] Side-by-side comparison written to qa/<task-slug>/diff-<component>.md
- [ ] DIFF list written (or "DIFF: none" with proof)

## Phase 4.5 - Pre-commit hygiene
- [ ] No em-dashes in changed files (grep -c "-" returns 0)
- [ ] No localhost:/file:// URLs in committed code
- [ ] No hand-drawn SVG where Figma asset exists

## Phase 5 - Commit
- [ ] Commit message references checklist path
- [ ] Pushed to origin
- [ ] Pushed to freeradicals (if applicable)

## Phase 6 - Known broken / follow-ups
- [ ] Listed any unresolved items here for the user
```

**STOP GATE 0.5:** The file `qa/<task-slug>/checklist.md` exists on disk AND its path is printed in your reply. Do not proceed to Phase 1 until both are true. If the user reads the file and it does not exist, you have lied about following the skill.

---

## Phase 1 - Spec Pull (both modes, before any code OR QA report)

Identify the **source of truth** ($SOURCE):
- Figma frame/node -> use Figma MCP
- Jira ticket -> read title + acceptance criteria; follow any linked Figma
- PRD / spec doc -> read the section being built
- Dev site or screenshot only -> ask for the Figma link before proceeding

**If your team uses a design system MCP (configured in `user-prefs.md`):** after pulling the $SOURCE Figma spec, also pull each component's prop signature from the component library before writing the spec entry. The spec must include both the design's intent AND the component name + prop signature.

For the target node in Figma:

1. `Figma:get_metadata` on the **parent frame**. List every distinct visual element.
2. `Figma:get_design_context` on **each** distinct child. Do not assume same-named siblings share a variant.
3. `Figma:get_screenshot` on the parent frame - save the reference image.
4. Write the spec into your plan, per element:
   - width × height
   - padding: `pt-*`, `pr-*`, `pb-*`, `pl-*` (directional, exact)
   - `flex-1` / `flex-[1_0_0]` regions
   - gradient stops verbatim
   - font size / weight / lineHeight / letterSpacing for every text node
   - every asset URL handed back by the MCP (these are `localhost:3845/...` - they are TEMPORARY)

**If $SOURCE is a Jira ticket:** also extract each acceptance criterion as its own bullet. These become the pass/fail checkpoints for REVIEW mode. Always check the Jira comments section - engineers often post implementation screenshots there.

**STOP GATE 1:** Your plan contains measured specs for every element. No "roughly" or "approximately" anywhere. No code written yet. If REVIEW mode, AC bullets are listed.

---

## Phase 1.4 - Component Inventory (HARD GATE - both modes)

**This is the concrete fix for the #1 failure mode: rebuilding components that already exist.**

**If company context is active (per Phase 0):** before grepping the local codebase, also check your team's component library (per `user-prefs.md`) to see the full component palette. Treat any `NEW` row as a strong signal to re-check the library before justifying it.

Before writing ANY JSX (BUILD) or flagging any "missing component" (REVIEW):

1. From Phase 1, list every component name you see in the Figma node - every card, bar, badge, button, icon, divider, avatar, breadcrumb, tab, etc. Figma names are hints; treat both the Figma name and any obvious code-side equivalent as candidates.
2. Grep the codebase for each candidate. For a single-file storybook:
   ```bash
   grep -nE "^(function|const) [A-Z]" <preview-file> | head -200
   ```
   For a multi-file project:
   ```bash
   grep -rnE "^export (function|const) [A-Z]" <src-dirs>
   ```
3. Build a **Components Referenced** table and write it into your plan verbatim:

   | Figma element | Storybook/code name | Location | Status |
   |---------------|---------------------|----------|--------|
   | Severity bar  | `SeverityBar`       | `storybook.html:6231` | REUSE |
   | Reaction icon | `IconReactButton`   | `storybook.html:370`  | REUSE |
   | New thing     | -                   | -                     | NEW |

4. For every `NEW` row, justify in one sentence why no existing component fits. "It's slightly different" is not a justification - if it's 80% the same, extend the existing one with a prop.
5. For every `REUSE` row, open the existing component and confirm it supports the variant you need. If it doesn't, the fix is a prop (e.g. `bg="transparent"`), not a rebuild.

**STOP GATE 1.4:** The Components Referenced table is written and every row has a status. Any `NEW` row has a one-sentence justification. No JSX written yet. If you are delegating to a sub-agent, this table MUST be in the delegation prompt - the sub-agent may not proceed without it either.

**Anti-pattern watch:** If you catch yourself typing `function <SomeCard>(` and you did not first check whether `<SomeCard>` or something adjacent exists - stop, run step 2, fill the table.

---

## Phase 1.5 - Animation Spec Pull (skip if component has no animations)

Do this before writing any animation code.

1. **Find the reference animation in source.** Note every timing constant: delays, durations, easings. Write them down exactly (`useReveal(1200)`, `transition-opacity duration-300 delay-[500ms]`, etc.).
2. **Watch the reference animation run in the browser.** Hit Replay (or trigger manually). Describe in one sentence: what animates, in what order, and what carries the visual weight.
3. **List every animation the target component already has internally.** These run on mount regardless of any wrapper you add.
4. **Write the animation timeline as a table:**

   | t=Xms | what happens |
   |-------|-------------|
   | 0     | component mounts |

5. **Check for the nested-component trap.** Any component defined inside another function's render body remounts on parent re-render.

**The one rule for animations: The reference component's internal animations are the hero. Your job is to not step on them.**

**STOP GATE 1.5:** Timeline table written, internal animations listed. No animation code yet.

---

## Phase 2 - Asset Download + Verify (BUILD mode)

For every non-inline asset:

1. Pick the destination inside the folder from Phase 0.
2. Download: `curl -sSL "<mcp-url>" -o <dest>`.
3. Verify: `ls -la <dest>` - confirm non-zero size.
4. Compute the relative path from the preview file to the asset.
5. Open the preview and confirm no 404.

**STOP GATE 2:** Every asset exists on disk, relative path is written down.

---

## Phase 3 - Implementation (BUILD mode)

Write the component. For each `src=`, `href=`, `url(...)`:

1. Use the exact relative path from Phase 2.
2. Resolve the path mentally or with `ls` immediately after the Edit.
3. Never pattern-match to a similar component. If you catch yourself reusing without going through Phase 1.4, stop and rebuild the inventory table.

**STOP GATE 3:** Every asset reference resolves to an existing file.
```bash
grep -nE 'src=|href=|url\(' <files-you-edited> | head -40
```

---

## Phase 4 - Visual Diff Gate (BUILD mode, before claiming "done")

1. Screenshot the rendered component.
2. Put it side-by-side with the Phase 1 Figma screenshot.
3. Write a DIFF bullet list. Scan: column width, badge/pill position+size+color, gradient stops, type size/weight per text node, action bar alignment, section gaps.
4. If non-empty, fix, re-screenshot, re-diff.
5. Emit `DIFF: none` only when truly empty.

**STOP GATE 4:** `DIFF: none` stated.

---

## Phase 4.5 - Animation Diff Gate (BUILD mode, skip if no animations)

1. Probe the DOM at sampled timestamps (`t=50, 200, 500, 900, 1300, 1800ms`) via `preview_eval`.
2. Compare your implementation vs reference at the same timestamps.
3. Check for animation fights (wrapper opacity/transform racing child internals).
4. Re-check the nested-component trap under state changes.
5. Write an ANIMATION DIFF table; iterate until empty.

**STOP GATE 4.5:** `ANIMATION DIFF: none` stated.

---

## Phase 5 - Pre-Commit (BUILD mode)

1. `grep -rnE 'localhost:[0-9]+|file://|127\.0\.0\.1:' <code-dirs>` - expect empty.
2. Pre-commit hook runs the asset-ref validator. Do not `--no-verify`.
3. Reload preview - zero console errors, zero 404s.
4. Commit.

**STOP GATE 5:** Hook passes, browser shows zero 404s.

---

## Phase 6 - REVIEW Mode (QA an existing implementation)

Use when the user shares an implementation (Jira ticket, dev site link, screenshot, engineer video) and asks you to check it against a design/spec. Phase 1 must already be complete ($SOURCE identified, spec extracted). Phase 1.4 still applies - before flagging "missing component," verify it really isn't in the codebase.

### 6.1 Gather Inputs

| Input | Description | Required |
|-------|-------------|----------|
| Source of truth ($SOURCE) | Figma frame, Jira ticket + AC, PRD section | Yes |
| Implementation artifact | Dev site URL, screenshot, engineer video | Yes |
| Component library reference | Figma components, Storybook | Recommended |
| Viewports to check | `[mobile]`, `[desktop]`, or `[mobile, desktop]` | Default: single viewport from design |

Ask for anything missing. Don't guess.

### 6.2 Define Scope

If $SOURCE is a Jira ticket: **the acceptance criteria are the only pass/fail checkpoints.** Do not flag UI elements visible in Figma but not in the ticket - those belong to other tickets.

If $SOURCE is a Figma frame with no ticket: treat every visible element in the frame as in-scope.

If $SOURCE is a PRD: use the section being reviewed; cross-check against Figma for visual spec.

Anything clearly broken outside scope -> "Out of scope observation," don't fail for it.

### 6.3 Review the Implementation

**Dev site link:** screenshot each viewport in the matrix, compare against Figma.
**Engineer video:** watch it fully, follow the cursor, note timestamps for anything off. If unclear: "I had trouble following [action] at [timestamp] - can you share a screenshot?"
**Screenshots only:** compare directly against Figma.

### 6.4 Check Against Each Source

Work through systematically:

**Against Figma:** visual layout (spacing, alignment, hierarchy), typography (size/weight/color), color tokens, component variants, icons.
**Against Figma Dev Mode:** exact spacing values, type specs, token names.
**Against AC (if ticket):** tick each criterion one by one.
**Against PRD (if provided):** overall intent preserved, no scope drift.
**Against component library / Storybook:** component used correctly; flag deviations unless clearly intentional new variant.
**Against team design system (if company context active per Phase 0):** for each interactive element, verify the component against the design system library and check prop usage. Every flagged item must name the design system component it should be using. "Looks close to [library name]" is not acceptable.
**Accessibility:** flag obvious issues (missing labels, contrast, keyboard nav). Non-blocking. Format: "A11y note: [issue] - documented, non-blocking."

### 6.5 Write the QA Report

Save under `qa-reports/` at repo root (create if missing), filename `<ticket-id-or-frame-name>.md`. Also return the report inline in chat.

```
## [Ticket ID or Figma frame name]
**Date:** [today] · **Reviewed by:** [user] (via Claude Design QA) · **Status:** [ticket status or "Standalone review"] · **Assignee:** [name if applicable]

[verdict: Pass / Pass with notes / Fail]

### Summary
- [bullet 1 - overall assessment]
- [bullet 2 - AC or scope coverage]
- [bullet 3 - notable flags]

Summary MUST be a bullet list. Never prose.

### Components Referenced
[Paste the Phase 1.4 table. In REVIEW mode this doubles as "did the engineer use the right components?"]

### Acceptance Criteria / Scope Checklist
- [criterion 1 - one bullet per distinct check]
- [criterion 2]

### Viewport Matrix
| Viewport | Status | Notes |
|----------|--------|-------|
| Mobile   | ✅/❌/- | |
| Desktop  | ✅/❌/- | |

(Omit rows not in scope for this review.)

### Flagged Items

**[Flag title]** *(Low / Medium / High)*
- What's wrong: [description]
- Where: [screen name, viewport, or video timestamp]
- Expected: [Figma/spec shows]
- Found: [implementation shows]

### Accessibility Notes
[Short paragraph, or "No obvious a11y issues observed within scope."]

### Design Quality (optional - only when dev site link available)

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Typography | Strong / Acceptable / Needs Work | |
| Spacing | Strong / Acceptable / Needs Work | |
| Color | Strong / Acceptable / Needs Work | |
| Hierarchy | Strong / Acceptable / Needs Work | |
| Interaction States | Strong / Acceptable / Needs Work | |

**AI Slop Check** (only list patterns actually present, or "No AI slop patterns detected"):
1. Gradient hero · 2. 3-column icon grid · 3. Uniform border-radius · 4. Centered body text · 5. Floating decorative blobs · 6. Too many colors · 7. Flat heading scale · 8. Missing interaction states · 9. Bubbly everything · 10. Generic CTA styling
```

**Rules:**
- No Verdict section beyond the emoji line.
- No Screenshots/References section.
- Summary is ALWAYS a bullet list.
- One AC bullet per distinct check - never bundle.
- No nested bullets inside AC. No bold inside AC bullets. No checkboxes.
- Design Quality section is observational, non-blocking. Never fail a ticket on it.

**STOP GATE 6:** Report written with all required sections, saved to `qa-reports/`, and posted inline.

### 6.6 Edge Cases

- **Video unclear:** ask the user for a screenshot or slower recording of the specific moment.
- **Inputs missing:** ask before proceeding. Never assume intent.
- **Component deviates from library:** flag, note whether intentional (new variant) vs error.
- **Scope ambiguity:** flag as "Out of scope observation," don't fail.

---

## The One Rule That Prevents Most Mistakes (BUILD)

**Generator-time URLs never end up in committed code.** Any `localhost:*`, `file://`, or `127.0.0.1:*` is valid ONLY during generation. Fetch -> save -> relative path. A build that renders only when Figma is open is a demo, not a build.

## The One Rule That Prevents Most Mistakes (REVIEW)

**The ticket scope is the scope.** If the AC doesn't mention it, don't fail on it. Out-of-scope observations go in a separate note, not in Flagged Items.

---

## Anti-Patterns - Stop If You Catch Yourself

**Build:**
- "I'll fix the URLs later." You won't.
- "This looks like `ExistingComponent`, I'll reuse it." - you must still run Phase 1 for it.
- "This looks like nothing we have, I'll build it." - you must still run Phase 1.4 grep.
- Inventing an asset folder instead of matching Phase 0.
- Skipping `ls` after `curl`.
- `--no-verify` on a hook failure.
- Delegating a screen build to a sub-agent without the Components Referenced table in the prompt.
- **Hand-drawing an SVG icon when the Figma node has the asset URL.** Pull it. Download it. Inline it. Never substitute your own paths.
- **Using em-dash characters (-) anywhere.** Comments, prose, table labels, component names. Use a hyphen (-).
- **Calling `preview_resize` (or any equivalent viewport resize).** Never. Scroll the existing viewport with `preview_eval` instead.
- **Batch-checking the QA checklist at the end.** Update each `[ ]` -> `[x]` the moment that single item is done. If you cannot honestly check it now, leave it.
- **Claiming "DIFF: none" without a side-by-side screenshot in `qa/<task-slug>/diff-<component>.md`.** No artifact, no claim.

**Animation:**
- "Screenshot looks right, animation is probably fine." Screenshots can't see timing.
- Adding a stagger the reference doesn't have.
- Wrapping a component that has its own mount animations without checking for fights.
- Writing animation code before Phase 1.5.

**Review:**
- Failing on something outside AC scope.
- Flagging "missing component" without grepping the codebase.
- Writing the Summary as prose.
- Bundling multiple checks into one AC bullet.
- Skipping the Jira comments section.

---

## Session Hygiene

Re-injected by `~/.claude/hooks/design-skill-refresh.sh` (UserPromptSubmit) every 30 minutes or on any design keyword. When you see the `[design-skill-refresh]` banner, restart at Phase 0 for any new BUILD work, or Phase 1 for any new REVIEW work.

## Activation Triggers

**BUILD mode:**
- User asks to build, implement, port, or convert a design into code.
- User references a Figma URL or node ID alongside an intent to produce code.
- Any Figma MCP tool is invoked during a build task.
- Tool output includes `localhost:*`, `file://`, or dev-server URLs.
- Working on a storybook / design-system component file.

**REVIEW mode:**
- "Can you QA this," "review this implementation," "does this match the design," "check this ticket."
- User shares a Jira ticket, dev site link, or engineer video.
- User shares a screenshot alongside a Figma link for comparison.
- Reviewing or fixing visual rendering of a committed component against a design.

When any BUILD trigger applies, execute Phase 0 before anything else. When any REVIEW trigger applies, jump to Phase 1, then Phase 6.
