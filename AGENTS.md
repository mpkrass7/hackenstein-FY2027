# AGENTS.md

Working notes for anyone (human or AI) touching this repo.

## What this repo is

The **ShelfSignal** pitch deck for the FE Tech Summit FY27 AI Customer Challenge
(customer scenario: NorthPeak Retail). The deck is a single self-contained HTML file
served live via **GitHub Pages**.

- **Live URL:** https://mpkrass7.github.io/hackenstein-FY2027/
- **The deck:** `index.html` (one file, no build step, no dependencies except Google Fonts).
- **Repo is PUBLIC.** Only publish what is safe to be public.

## Updating the presentation (do this often)

The deck is plain HTML. To change it and push the update live:

```bash
# 1. edit index.html (content lives in the <section class="slide"> blocks)
# 2. preview locally — just open the file in a browser:
open index.html            # macOS

# 3. ship it
git add index.html
git commit -m "deck: <what changed>"
git push origin master
```

GitHub Pages rebuilds automatically on every push to `master`. The live site
updates in **~1 minute** (hard-refresh with Cmd+Shift+R to skip the browser cache).

### First-time Pages setup (already done, for reference)
```bash
gh api -X POST repos/mpkrass7/hackenstein-FY2027/pages \
  -f 'source[branch]=master' -f 'source[path]=/'
# check status / URL:
gh api repos/mpkrass7/hackenstein-FY2027/pages
```

## How the deck is built (so edits stay consistent)

- **One file, no framework.** All CSS and JS are inline in `index.html`.
- **Slides** are `<section class="slide">` blocks inside `<div class="deck">`. Add a
  slide by copying an existing `<section>` and bumping the counter is automatic
  (JS counts `.slide` elements).
- **Navigation is horizontal** — the deck scrolls sideways. Arrow keys (← →),
  space, PageUp/Down, Home/End, and the on-screen ← → buttons all work.
- **Theming:** light + dark, driven by CSS tokens in `:root`. Respects the
  viewer's OS theme; the ◐ Theme button toggles and remembers the choice.
- **Palette is semantic:** red = loss/stockout (`--crit`), amber = markdown
  (`--warn`), green = recovery/win (`--pos`), blue = brand accent (`--brand`).
- **Fonts:** Bricolage Grotesque (display), Inter (body), IBM Plex Mono (labels/data).
- **Placeholders:** the dashed blue `.placeholder` blocks mark where the team's
  real live-demo screenshots and real numbers go. Replace them before presenting.

## House rules

- **NO EM DASHES.** Marshall does not want em dashes (—) anywhere in the copy.
  Use periods, commas, colons, or rephrase. This is not negotiable.
- Keep the deck a single self-contained file. If you must add an asset, commit it
  to the repo and reference it with a relative path (Google Fonts is the only
  allowed external host).
- Keep copy tight. No filler.

## What stays PRIVATE (gitignored — never commit to this public repo)

- `challenge.md` — the full internal challenge requirements (rubric, internal URLs).
- `challenge-page.html` — raw capture of the internal Skills Navigator app page.
- `.databricks/`, `.isaac/`, `images/` — local/internal working files.

These are in `.gitignore`. Do not force-add them. If the team needs the challenge
requirements shared, use an internal channel, not this public repo.
