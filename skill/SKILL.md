---
name: design-to-code-qa
description: MANDATORY before building any UI from a Figma design, design spec, MCP tool output, or AI-generated component code. Enforces the asset pipeline (fetch + save every asset locally, never commit localhost/dev-server URLs), the visual + technical QA passes, and a pre-commit checklist. Triggers when the user asks to build/implement/port a design, convert Figma to code, work on a storybook component, or when any tool returns `localhost:*` or `file://` URLs in code.
---

# Design → Code → QA Pipeline (Required Pre-Build Reading)

Read this end-to-end **before writing a single line of code** when implementing from a design. Then do the work. Then run the pre-commit checklist before any commit.

If the project has a local copy of `process_design_to_code_pipeline.md`, read that too — it's the source of truth.

---

## The One Rule That Prevents Most Mistakes

**Generator-time URLs must never end up in committed code.**

Whenever a tool (Figma Dev Mode MCP, AI codegen, design plugin, scaffolding script) hands you a `localhost:*/...` URL, a `file://...` path, or any reference that only resolves on the generating machine while the generator is running — that URL is valid **only during generation**. Before you commit, you MUST:

1. Fetch the asset (download the file).
2. Save it into the repo under `assets/` (or equivalent).
3. Rewrite the reference to a **relative path from the repo root** (e.g. `./assets/icons/logos/reuters.svg`).

A build that renders only when the generator tool is open is not a build. It's a demo.

---

## Figma → Code Asset Pipeline

Figma's own MCP docs prescribe this order — follow it literally:

1. `get_design_context` — structured representation.
2. `get_metadata` — if (1) is truncated, navigate + re-fetch specific nodes.
3. `get_screenshot` — visual reference while building.
4. **Download every asset.** Every `localhost:*/assets/*.svg` (or equivalent) must be:
   - Fetched (`curl`, WebFetch, or MCP asset download)
   - Saved to `assets/icons/` (subfolder by kind: `logos/`, `nav-icons/`, etc.)
   - Referenced via relative path in code
5. **Only then** start implementation.

Skipping step 4 is the single most common failure mode. Don't skip it.

### Folder convention

```
assets/
  icons/        ← UI icons (chevrons, search, close, plus)
    logos/      ← brand/third-party logos (news outlets, social platforms, payments)
  images/       ← photos, illustrations, hero art
  nav-icons/    ← complex multi-layer icon parts (if applicable)
```

### Rules by asset type

- **UI icons** (small, reusable, no brand identity): inline as JSX SVG. Stays tokenizable — change `stroke` via prop.
- **Brand / third-party logos**: separate `.svg` files in `assets/icons/logos/`. Never redraw them; download the real files. Reference via `<img src="./assets/icons/logos/foo.svg"/>`.
- **Photos**: external CDN (Pexels/Unsplash) OK for **mocked** content. Real content → local or production CDN.
- **Never**: `localhost:*` URLs in committed code. Never.

---

## Design QA Workflow — Two Separate Passes

Do NOT collapse these into one. They catch different failures.

### Pass 1 — Visual QA (does it look like Figma?)

1. Figma at 100% zoom + preview at 100% zoom, same viewport width, side-by-side.
2. **Measure, don't eyeball**: Figma info panel for every text node — fontSize, fontWeight, lineHeight (px), letterSpacing (px), color. Spacing, padding, gap in pixels.
3. **Screenshot proof**: after every visual change, screenshot the preview and verify against Figma. Never claim "done" without a visual diff.
4. Animations: step through frame-by-frame. Easing + duration matter.

### Pass 2 — Technical QA (does the code actually work?)

1. Open preview in the browser — any console errors?
2. Check Network tab — any 404s? Any `localhost:*` requests? If yes → assets aren't local.
3. **Disable network mid-render** and reload — still look right (minus CDN photos)? If no → local assets missing.
4. Resize viewport — intended breakpoints still work?
5. Cross-browser spot check (user uses Brave primarily).

### Automated visual regression (when project grows)

Once the project has 50+ components, add one of:
- **Chromatic** — built for Storybook, TurboSnap only re-renders changed components.
- **Percy (BrowserStack)** — `percySnapshot()` wrapper, works with Playwright/Cypress/Storybook.
- **Applitools Eyes** — AI-based, fewer false positives from anti-aliasing.

---

## Transportability Test

An asset is "transportable" only if the build still works when you:
- Clone the repo fresh on a new machine.
- Open the HTML file with the generator tool (Figma) closed.
- Deploy to a static host (GitHub Pages, Netlify, Vercel).
- Hand the folder to a dev team with no access to your design tools.

Any of those fail → assets aren't transportable → the work isn't done.

---

## Anti-patterns to Catch Yourself On

1. "It works on my machine because Figma is open" — invalid state.
2. "I'll fix the URLs later" — URLs don't get fixed later. Fix before commit.
3. Text-badge placeholders for logos — only if the user explicitly requests a stub. Otherwise it's misrepresenting what's implemented.
4. Assuming generated code is correct — AI/MCP output is a draft. Audit for external URLs, dead refs, fake imports before committing.
5. Committing without a preview check — every visual commit gets a browser screenshot first.

---

## Pre-Commit Checklist — Run Before Every Commit That Touches Visuals

```
[ ] No localhost:*  URLs anywhere in the diff
[ ] No file://      URLs anywhere in the diff
[ ] Every new asset reference points to a file that exists in the repo
[ ] Preview loaded in browser without console errors or 404s
[ ] Screenshot compared to Figma side-by-side
[ ] Measured type/spacing matches Figma info panel
```

Quick command to verify:
```bash
grep -rn "localhost:\|file://" preview/ src/ components/ 2>/dev/null
# should return nothing
```

---

## When This Skill Applies — Activation Triggers

- User asks to build, implement, port, or convert a design into code.
- User references a Figma URL or node ID.
- Any Figma MCP tool (`get_design_context`, `get_screenshot`, etc.) is invoked.
- Any tool output includes `localhost:*`, `file://`, or other dev-server URLs.
- Working on a storybook / design-system component file.
- Reviewing or fixing visual rendering of a committed component.

When any of these apply, re-read this skill before proceeding.
