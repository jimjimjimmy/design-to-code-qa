---
name: design-to-code-qa
description: MANDATORY execution checklist when building any UI from a Figma design, design spec, MCP tool output, or AI-generated component code. This is not documentation — it is a sequence of steps with STOP gates. Do not skip ahead. Triggers when the user asks to build/implement/port a design, convert Figma to code, work on a storybook component, or when any tool returns `localhost:*` or `file://` URLs in code.
---

# Design → Code → QA — Execution Checklist

**Read this as instructions to run, not prose to summarize.** Each phase ends with a STOP gate. Do not enter the next phase until the gate condition is met. If you find yourself writing JSX before Phase 3, you skipped a step — go back.

The single biggest failure mode is treating this file as documentation. It is a script you execute.

---

## Phase 0 — Setup (run this FIRST, every time)

Run, in order:

1. `ls assets/ 2>/dev/null || echo "NO assets/ DIR"` — **record the existing folder convention verbatim.** If `assets/images/` exists, new images go there. If `public/assets/` exists, that's the convention. Do not invent a new one.
2. `cat user-prefs.md 2>/dev/null` at this skill's directory — pull browser, preview style, screenshot tool, terminology.
3. Identify the preview entry file (e.g. `preview/storybook.html`, `src/App.tsx`). Note its directory — all relative asset paths resolve from there.

**STOP GATE 0:** Write one sentence in your reply stating (a) the asset folder path that already exists, (b) the preview file's directory, (c) what a relative path from preview → assets looks like (e.g. `../assets/images/foo.png`). Do not proceed to Phase 1 until this is written.

---

## Phase 1 — Spec Pull (before any code)

For the target node in Figma:

1. `Figma:get_metadata` on the **parent frame**. List every distinct visual element.
2. `Figma:get_design_context` on **each** distinct child. Do not assume same-named siblings share a variant.
3. `Figma:get_screenshot` on the parent frame — save the reference image.
4. Write the spec into your plan, per element:
   - width × height
   - padding: `pt-*`, `pr-*`, `pb-*`, `pl-*` (directional, exact)
   - `flex-1` / `flex-[1_0_0]` regions
   - gradient stops verbatim
   - font size / weight / lineHeight / letterSpacing for every text node
   - every asset URL handed back by the MCP (these are `localhost:3845/...` — they are TEMPORARY)

**STOP GATE 1:** Your plan contains measured specs for every element. No "roughly" or "approximately" anywhere. No code written yet.

---

## Phase 1.5 — Animation Spec Pull (skip if component has no animations)

Do this before writing any animation code. If there are no animations in the target component, skip to Phase 2.

1. **Find the reference animation in source.** Note every timing constant: delays, durations, easings. Write them down exactly (`useReveal(1200)`, `transition-opacity duration-300 delay-[500ms]`, etc.).
2. **Watch the reference animation run in the browser.** Hit Replay (or trigger manually). Describe in one sentence: what animates, in what order, and what carries the visual weight. If you can't answer "what is the hero animation," you don't understand it yet. Do not proceed.
3. **List every animation the target component already has internally.** These run on mount regardless of any wrapper you add. Plan around them — do not fight them.
4. **Write the animation timeline as a table:**

   | t=Xms | what happens |
   |-------|-------------|
   | 0     | component mounts |
   | ...   | ... |

   No "approximately." If you don't have exact numbers, go measure them (`preview_eval` computed styles at sampled timestamps).

5. **Check for the nested-component trap.** Any component *defined inside* another function's render body gets a new type identity on every parent re-render — its transitions reset. Run:
   ```bash
   grep -n "function [A-Z]" <files-you-plan-to-edit>
   ```
   If you find a capitalized function inside another function body, that's the trap. Extract it before adding animations.

**The one rule for animations: The reference component's internal animations are the hero. Your job is to not step on them.**

**STOP GATE 1.5:** You have (a) watched the reference animate in the browser, (b) written the timeline table with exact timings, (c) listed every internal animation already present in the target component. No animation code written yet.

---

## Phase 2 — Asset Download + Verify (before any JSX that references them)

For every non-inline asset (photos, logos, brand SVGs, fonts):

1. Pick the destination inside the folder you recorded in Phase 0. Example: `assets/images/expert-aaron-miller.png`. Not `preview/assets/...` unless Phase 0 told you that's the convention.
2. Download: `curl -sSL "<mcp-url>" -o <dest>`.
3. **Immediately verify:** `ls -la <dest>` — confirm non-zero file size.
4. Compute the relative path from the preview file to the asset. Write it down. This is the string that goes in `src=`.
5. Open the preview in the browser and confirm no 404 on that asset before moving on (use Chrome DevTools MCP / preview MCP if configured).

**STOP GATE 2:** Every asset that will be referenced exists on disk at the recorded path, AND the relative path from the preview file has been computed and written down. If either is missing, do not write JSX.

---

## Phase 3 — Implementation

Write the component. Each time you add a `src=`, `href=`, or `url(...)`:

1. Use the exact relative path recorded in Phase 2.
2. Immediately after the `Edit`, resolve the path in your head (or run `ls <preview-dir>/<relative-path>`) and confirm it points at the file you downloaded.
3. Never pattern-match to a "similar-looking" existing component. If you catch yourself reusing a component, return to Phase 1 for that element.

**STOP GATE 3:** Every asset reference you added has been resolved to an existing file. Run:

```bash
grep -nE 'src=|href=|url\(' <files-you-edited> | head -40
```

and eyeball every path.

---

## Phase 4 — Visual Diff Gate (before claiming "done")

1. Screenshot the rendered component (Chrome DevTools MCP / preview MCP / manual, per user-prefs).
2. Put it side-by-side with the Phase 1 Figma screenshot.
3. Write a DIFF bullet list. Scan for: content column width, badge/pill position+size+color, gradient direction+stops, type size/weight per text node, action bar alignment, section gaps.
4. If the list is non-empty, fix, re-screenshot, re-diff.
5. Only emit `DIFF: none` when the list is truly empty.

**STOP GATE 4:** `DIFF: none` explicitly stated. No commits before this.

---

## Phase 4.5 — Animation Diff Gate (skip if component has no animations)

Run after Phase 4 static diff passes. A screenshot cannot see a broken animation — this phase catches what Phase 4 misses.

1. **Probe the DOM at sampled timestamps** using `preview_eval` (or browser DevTools). Sample computed styles of every animated property at: `t=50, 200, 500, 900, 1300, 1800ms` post-trigger (adjust if the animation is shorter/longer). Record the values.
2. **Compare mobile vs desktop at the same timestamps.** The timing and order should match the Phase 1.5 reference timeline. Any deviation is a bug.
3. **Check for animation fights.** Does your wrapper's opacity/transform run simultaneously with the child's internal animation? Is one masking the other? If the donut starts at t=0 but your fade-in starts at t=500, the hero animation is already half-done before it's visible. That's a fight — fix it.
4. **Check for the nested-component trap (again).** If parent state changes mid-animation, nested components remount and their animations reset. Trigger a state change while an animation is running and watch whether it interrupts. If yes, extract the component (see Phase 1.5 step 5).
5. Write an ANIMATION DIFF table: `| property | expected at t=Xms | actual |`. If any row shows a mismatch, fix it, re-probe, re-table.
6. Only emit `ANIMATION DIFF: none` when the table is empty.

**STOP GATE 4.5:** `ANIMATION DIFF: none` explicitly stated. Both static and animation diffs clear before committing.

---

## Phase 5 — Pre-Commit

Run, in order:

1. `grep -rnE 'localhost:[0-9]+|file://|127\.0\.0\.1:' <code-dirs>` — expect empty.
2. The repo's `.git/hooks/pre-commit` runs the asset-ref validator automatically. If it blocks, DO NOT `--no-verify`. Fix the path.
3. Reload the preview — zero console errors, zero 404s in the Network tab.
4. Commit.

**STOP GATE 5:** Pre-commit hook passes. Browser shows zero 404s.

---

## The One Rule That Prevents Most Mistakes

**Generator-time URLs never end up in committed code.** Any `localhost:*/...`, `file://...`, or `127.0.0.1:*/...` is valid ONLY during generation. Fetch → save to `assets/` → rewrite reference to a relative path from the preview file. Always.

A build that renders only when Figma is open is not a build. It's a demo.

---

## Anti-Patterns — If You Catch Yourself Doing Any of These, Stop

- "I'll fix the URLs later." You won't. Fix before commit.
- "This looks like `ExistingComponent`, I'll reuse it." Re-run Phase 1 for this element.
- "I'll put the asset in `preview/assets/` since I'm editing `preview/storybook.html`." Check Phase 0's recorded convention. Don't invent.
- "I don't need to screenshot, the code looks right." Screenshot proof is non-negotiable.
- Skipping `ls` after `curl`. The download may have 404'd silently.
- Running `--no-verify` on a hook failure. The hook caught a real bug. Fix the bug.

**Animation-specific:**
- "The screenshot looks right, the animation is probably fine." Screenshots cannot see timing. Run Phase 4.5.
- "I'll add a stagger to make it feel polished." First ask: does the reference have a stagger? If not, yours is noise.
- "I read the reference component's source." Source ≠ behavior. Watch it run in the browser.
- "I'll wrap this in a fade-in." Does the wrapped component have its own mount-time animations? They fire at t=0 regardless of your wrapper. Check before wrapping.
- Writing animation code before Phase 1.5 is complete. You don't know what the hero animation is yet.

---

## Session Hygiene

This skill is re-injected by `~/.claude/hooks/design-skill-refresh.sh` (UserPromptSubmit) every 30 minutes or on any design keyword. When you see the `[design-skill-refresh]` banner, restart at Phase 0 for any new work. Do not assume earlier Phase 0 output still holds — folder conventions change between projects.

## Activation Triggers

- User asks to build, implement, port, or convert a design into code.
- User references a Figma URL or node ID.
- Any Figma MCP tool is invoked.
- Any tool output includes `localhost:*`, `file://`, or other dev-server URLs.
- Working on a storybook / design-system component file.
- Reviewing or fixing visual rendering of a committed component.

When any of these apply, execute Phase 0 before anything else.
