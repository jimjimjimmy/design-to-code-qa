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
