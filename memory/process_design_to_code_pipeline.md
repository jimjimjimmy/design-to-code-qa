# Design → Code → QA Pipeline

The canonical long-form reference for the design-to-code-qa kit. Mirrors the execution checklist in `skill/SKILL.md` and expands on the why behind each phase. If you're Claude executing this pipeline, the shorter SKILL.md is the operational source of truth — this doc is for humans and for deeper reference.

---

## The One Rule That Covers Most Mistakes

**Generator-time URLs must never end up in committed code.** When any tool (Figma Dev Mode MCP, AI codegen, design plugin) hands you a `localhost:*/...` URL, a `file://...` path, or a `127.0.0.1:*/...` reference — that URL works *during generation only*. Before committing:

1. Fetch the asset.
2. Save it to the repo under `assets/` (following the folder convention that already exists).
3. Rewrite the reference to a relative path from the file doing the referencing.

A build that renders only when Figma is open is not a build. It's a demo.

---

## The Five-Phase Execution Model

The kit enforces a sequence. Each phase ends with a STOP GATE — a condition that must be true before the next phase starts.

### Phase 0 — Setup

Before anything else:

1. `ls assets/` — record the existing folder convention verbatim. If `assets/images/` exists, new images go there. Do not invent `preview/assets/` or anything else.
2. Read `user-prefs.md` in the skill directory — pick up browser, preview style, screenshot tool, terminology.
3. Identify the preview entry file (e.g. `preview/storybook.html`). Every relative asset path resolves from its directory.

**GATE:** Record (a) the asset folder path, (b) the preview file's directory, (c) the relative path shape from preview → assets.

**Why this exists:** The #1 real-world failure was saving `expert-aaron-miller.png` to `preview/assets/images/` when the repo convention was `assets/images/` at the root. `ls` first prevents the whole class of mistake.

### Phase 1 — Spec Pull

For the target Figma node:

1. `Figma:get_metadata` on the parent frame. List every distinct visual element.
2. `Figma:get_design_context` on each child. Never assume same-named siblings share a variant.
3. `Figma:get_screenshot` on the parent. Save it as the visual reference.
4. Write into your plan, per element: width × height, directional padding (`pt`/`pr`/`pb`/`pl`), flex regions, gradient stops verbatim, font size/weight/lineHeight/letterSpacing for every text node, every asset URL the MCP returned (these are temporary).

**GATE:** Plan contains measured specs for every element. No "roughly."

### Phase 2 — Asset Download + Verify

For every non-inline asset:

1. Pick the destination inside the folder recorded in Phase 0.
2. Download: `curl -sSL "<mcp-url>" -o <dest>`.
3. Immediately verify: `ls -la <dest>` (non-zero size).
4. Compute the relative path from the preview file to the asset. Write it down.
5. Confirm no 404 in the browser before moving on.

**GATE:** Every asset exists at its recorded path and the relative path string is written down.

### Phase 3 — Implementation

Write the component. For each `src=`, `href=`, `url(...)`:

1. Use the exact relative path from Phase 2.
2. Immediately resolve the path mentally or with `ls` — confirm it points at the downloaded file.
3. Never pattern-match to a similar-looking existing component. If tempted, return to Phase 1.

**GATE:** `grep -nE 'src=|href=|url\(' <edited-files>` — eyeball every path.

### Phase 4 — Visual Diff Gate

Before claiming "done":

1. Screenshot the rendered component.
2. Side-by-side with the Phase 1 Figma screenshot.
3. Write a DIFF bullet list. Scan: content column width, badge position/size/color, gradient direction+stops, type size/weight per text node, action bar alignment, gaps.
4. If non-empty, fix, re-screenshot, re-diff.
5. Emit `DIFF: none` only when the list is truly empty.

**GATE:** `DIFF: none` explicitly stated.

### Phase 5 — Pre-Commit

1. `grep -rnE 'localhost:[0-9]+|file://|127\.0\.0\.1:' <code-dirs>` — expect empty.
2. The repo's `.git/hooks/pre-commit` runs the asset-ref validator automatically. Two gates:
   - Gate A: no generator-time URLs in staged diffs.
   - Gate B: every staged `src=`/`href=`/`url(...)` with an asset extension resolves to a file on disk.
3. Reload the preview — zero console errors, zero 404s.
4. Commit. Never `--no-verify` to bypass a real failure.

**GATE:** Hook passes. Browser shows zero 404s.

---

## Folder Convention Reference

```
assets/
  icons/         ← UI icons (chevrons, search, close)
    logos/       ← brand / third-party logos
  images/        ← photos, illustrations, hero art
  nav-icons/     ← complex multi-layer icon parts (if used)
```

Rules by type:

- **UI icons** — small, reusable, no brand identity → inline JSX SVG, tokenizable via props.
- **Brand / third-party logos** — never redraw; download the real `.svg` to `assets/icons/logos/`.
- **Photos** — external CDN (Pexels/Unsplash) OK for mocked content; real content → local or production CDN.
- **Never** `localhost:*` in committed code.

---

## Two-Pass QA (expanded reference)

### Visual QA — does it look like Figma?

1. Side-by-side at 100% zoom, same viewport width.
2. Measure, don't eyeball. Figma info panel for every text node.
3. Screenshot proof after every visual change.
4. Animations: step through frame-by-frame.

### Technical QA — does it actually work?

1. Preview in browser — console errors?
2. Network tab — any 404s or `localhost:*` requests?
3. Disable network mid-render and reload — still renders (minus CDN photos)?
4. Resize viewport.
5. Cross-browser spot check (user primary: Brave).

### Automated visual regression (when 50+ components)

- **Chromatic** — Storybook-native, TurboSnap re-renders only changed components.
- **Percy (BrowserStack)** — Playwright/Cypress/Storybook wrapper.
- **Applitools Eyes** — AI-based, tolerant of anti-aliasing noise.

---

## Transportability Test

An asset is transportable only if the build works when you:

- Clone the repo fresh on a new machine.
- Open the HTML file with Figma closed.
- Deploy to a static host (GitHub Pages, Netlify, Vercel).
- Hand the folder to a dev team with no access to your design tools.

Any failure → not transportable → the work isn't done.

---

## Anti-Patterns

1. "It works on my machine because Figma is open." Invalid state.
2. "I'll fix the URLs later." You won't.
3. Text-badge placeholders for logos unless the user explicitly asked for a stub.
4. Trusting MCP/AI codegen output as final. It's a draft — audit for external URLs, dead refs, fake imports.
5. Committing without a preview check.
6. Saving an asset to `preview/assets/` because you're editing a file in `preview/`. Folder convention comes from Phase 0.
7. `--no-verify` on a real hook failure. The hook found a bug. Fix it.

---

## Pre-Commit Checklist (human-runnable)

```
[ ] No localhost:* / file:// / 127.0.0.1:* in the diff
[ ] Every new src=, href=, url(...) resolves to a file on disk
[ ] Preview loaded in browser — no console errors, no 404s
[ ] Screenshot compared to Figma side-by-side
[ ] Measured type/spacing matches Figma info panel
[ ] DIFF: none
```

The git hook enforces the first two deterministically. The rest is on you.
