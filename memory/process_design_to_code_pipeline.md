# Design → Code → QA Pipeline

The end-to-end process for implementing a Figma design into a React or HTML preview, then doing visual + technical QA. Based on industry best practice and Figma's own Dev Mode MCP guidelines.

---

## The One Rule That Covers Most Mistakes

**Generator-time URLs must never end up in committed code.** When any tool (Figma MCP, AI codegen, design plugin) hands you a `localhost:*/...` URL, a `file://...` path, or a reference to a build-machine-only resource — that URL works *during generation only*. Before committing, you must:

1. Fetch the asset (download the file).
2. Save it to the repo under `assets/` (or equivalent).
3. Rewrite the reference to a **relative path from the repo root** (e.g. `./assets/icons/logos/reuters.svg`).

If the asset lives anywhere other than inside the repo, the build is broken by definition — it'll render for the person who generated it and nobody else, whenever the dev server happens to be running.

---

## Figma → Code Asset Pipeline

Figma's official workflow (verified via their MCP docs):

1. **`get_design_context`** → structured representation of the design.
2. **`get_metadata`** → if step 1 is truncated, use to navigate + re-fetch specific nodes.
3. **`get_screenshot`** → for visual reference while building.
4. **Download every asset.** This is the step that was skipped in Beacon's CorroborationCard — localhost:3845 URLs were committed raw. Each asset URL returned by MCP must be:
   - Fetched (`curl`, WebFetch, or MCP's asset download)
   - Saved under `assets/icons/` (or `assets/icons/logos/`, `assets/images/`, etc. — organize by kind)
   - Referenced by relative path in the code
5. **Only then** start implementation.

### Asset folder convention for `assets/`

```
assets/
  icons/         ← UI icons (chevrons, search, etc.)
    logos/       ← brand/third-party logos (news outlets, social, payments)
  images/        ← photos, illustrations, hero art
  nav-icons/     ← complex multi-layer icon parts (Beacon project)
```

### Rules by asset type

- **UI icons (chevrons, arrows, close, plus)** — small, reusable, no brand identity. Inline as JSX SVG in a `components/icons.jsx` or inside the storybook file. Keeps them tokenizable (change `stroke` via prop).
- **Brand/third-party logos** — separate `.svg` files in `assets/icons/logos/`. Do NOT try to redraw them; download the actual files. Reference via `<img src="./assets/icons/logos/foo.svg"/>`.
- **Photos** — external CDN OK (Pexels, Unsplash) for *mocked* content. Real content → local or production CDN.
- **Never** use `localhost:*` URLs in committed code. Never.

---

## Design QA Workflow

Two separate passes. Do not collapse them.

### Visual QA (does it look like the Figma?)

1. **Side-by-side:** Figma at 100% zoom, preview at 100% zoom, same viewport width.
2. **Measure, don't eyeball:** use Figma's info panel for every text node — fontSize, fontWeight, lineHeight (px), letterSpacing (px), color. Measure spacing, padding, gap in pixels.
3. **Screenshot proof:** after every visual change, screenshot the preview and verify against Figma. Never claim "done" without a visual diff step.
4. **Animations:** record or step through frame-by-frame. Easing + duration matter.

### Technical QA (does the code actually work?)

1. **Open preview in browser** — does the page render without console errors?
2. **Check network tab** — any 404s? Any `localhost:*` requests? (If yes → assets aren't local.)
3. **Disable network mid-render** and reload — does it still look right, except for photos? (It should — only CDN photos should depend on network.)
4. **Resize viewport** — intended breakpoints still work?
5. **Cross-browser** spot-check on the browsers the user actually uses (Brave, Chrome, Safari).

### Automated visual regression (when the project grows)

- **Chromatic** — built for Storybook; diffs components per-commit. TurboSnap only re-renders changed ones.
- **Percy (BrowserStack)** — wrap tests with `percySnapshot()`; works with Playwright/Cypress/Storybook.
- **Applitools Eyes** — AI-based (not pixel diff); fewer false positives from anti-aliasing.

Not needed for small personal projects, but set up before you have 50+ components.

---

## Hosting & Transportability Rules

An asset is "transportable" if the build still works when you:
- Clone the repo fresh on another machine.
- Open the HTML file with the generator tool (Figma) closed.
- Deploy it to a static host (GitHub Pages, Netlify, Vercel).
- Hand the folder to a dev team with no access to your design tools.

If any of those four fail, assets are not transportable.

For the Beacon project specifically:
- `preview/storybook.html` is served by GitHub Pages.
- All asset references must be **relative paths** from that file.
- `<img src="../assets/icons/..."/>` ← correct
- `<img src="http://localhost:3845/..."/>` ← broken the moment Figma isn't serving

---

## Anti-patterns to Catch Yourself On

1. **"It works on my machine because Figma is open"** — not a valid state.
2. **"I'll fix the URLs later"** — URLs don't get fixed later. Fix before commit.
3. **Text-badge placeholders for logos** — only acceptable if the user explicitly requests a stub. Otherwise it's lying about what's implemented.
4. **Assuming the generated code is correct** — treat AI/MCP codegen as a draft. Audit for external URLs, dead references, fake imports before committing.
5. **Committing without a preview check** — every commit that touches visuals needs a browser screenshot beforehand.

---

## Check Before Every Commit That Touches Visuals

```
[ ] No localhost:* URLs anywhere in the diff
[ ] No file:// URLs anywhere in the diff
[ ] Every new asset reference points to a file that exists in the repo
[ ] Preview loaded in browser without console errors or 404s
[ ] Screenshot compared to Figma side-by-side
[ ] Measured type/spacing matches Figma info panel
```

Use: `grep -rn "localhost:" preview/ && grep -rn "file://" preview/` — should return nothing.
