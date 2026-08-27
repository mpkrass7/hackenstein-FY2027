# NorthPeak Retail — Agent Session Context

## Team

Marshall Krassenstein & Logan — pair-building with Genie Code as the primary authoring tool.

## Why We're Doing This

This is for **Tech Summit FY27 Live Days** — a mandatory enablement sprint ("AI Customer Challenge"). The format: adopt a customer scenario, complete three connected builds (Lakebase, Apps, Unity Gateway), and submit to rank against other teams. Genie Code is the default build tool. We're iterating through the milestones with the agent doing the heavy lifting.

## Project Overview

Retail stockout & markdown rescue app. A cold snap caused 5 cold-weather apparel SKUs to sell out in ~30 northern stores while piling up unsold in ~40 southern stores. We're building the full stack: data pipeline → dashboard → Genie → Lakebase → app → AI Gateway.

## Environment

- **Catalog**: `adminbox_catalog`
- **Schema**: `northpeak_retail`
- **Volume**: `/Volumes/adminbox_catalog/northpeak_retail/raw_data/`
- **Project folder**: `/Users/marshall.krassenstein@databricks.com/northpeak-retail/`

## Key Data Anchors

- **Hero store**: `STORE-0214` (Denver, CO — North)
- **Hero SKU**: `SKU-APP-04412` (Summit Down Parka)
- **Surplus store**: `STORE-0377` (Colorado Springs, CO — Mixed, ~100mi from Denver)
- **Affected SKUs**: 5 cold-weather apparel items
- **Lost-sales exposure**: ~$4.8M (northern stockouts)
- **Markdown exposure**: ~$5.6M (southern overstock)

## Raw Datasets (in UC Volume as parquet)

| Dataset | Rows | Notes |
| --- | --- | --- |
| stores | 400 | Climate-tagged (North/South/Mixed), GPS |
| products | 1,998 | Includes 5 affected cold_weather SKUs with searchable descriptions |
| sales | 3,309,000 | 18-month POS with cold-snap velocity divergence |
| inventory_snapshots | 254,900 | North→0 on-hand, South→surplus, merch notes for ai_classify |
| transfers | 40,000 | Historical recovery moves with outcomes (model training) |
| store_traffic | 220,000 | Daily foot traffic |

## Milestone Progress

- [x] **1.1** — Data generation (job run completed successfully)
- [x] **1.2** — Data exploration notebook (all validations passed)
- [ ] **1.3** — SDP pipeline (silver + gold + heuristic recommendations)
- [ ] **1.4** — Metric view `mv_store_position`
- [ ] **1.5** — AI/BI dashboard + Genie space
- [ ] **1.6** — (Optional) ML recovery model
- [ ] **2.1** — Lakebase instance + dev branch
- [ ] **2.2** — Sync gold tables (read-only)
- [ ] **2.3** — Writable `ops_actions` table
- [ ] **2.4** — Lakebase Search on products
- [ ] **3.x** — Databricks App
- [ ] **4.x** — Unity AI Gateway

## Conventions

- **Session summaries**: Following [Genie Code best practices](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#session-summaries). Summaries live in `fixtures/sessions/` with an `INDEX.md` (reverse-chronological) and individual `YYYY-MM-DD_short-description.md` files. Always use `datetime.now()` for dates.
- **Code style**: Per user preferences — docstrings, type hints, isort imports at top, annotated cells with markdown headers, clean and non-verbose.

---

## Presentation deck (ShelfSignal) + GitHub Pages

The pitch deck for the challenge lives in this repo as a single self-contained HTML file,
served live via **GitHub Pages**.

- **Live URL:** https://mpkrass7.github.io/hackenstein-FY2027/
- **File:** `index.html` (all CSS + JS inline; no build step; only external dependency is Google Fonts)
- The deck is a **horizontal-scroll** slide deck (arrow keys, space, on-screen ← →), light + dark themes, semantic palette (red = loss/stockout, amber = markdown, green = recovery, blue = brand).

### Updating the deck and shipping it live

```bash
# 1. edit index.html — content is in the <section class="slide"> blocks inside <div class="deck">
# 2. preview locally:
open index.html
# 3. ship it (Pages auto-rebuilds on push to master, live in ~1 min):
git add index.html
git commit -m "deck: <what changed>"
git push origin master
```

Hard-refresh (Cmd+Shift+R) to bypass the browser cache after a deploy.
Add a slide by copying a `<section class="slide">` block — the slide counter is automatic.

### Pages setup (already done, for reference)
```bash
gh api -X POST repos/mpkrass7/hackenstein-FY2027/pages -f 'source[branch]=master' -f 'source[path]=/'
gh api repos/mpkrass7/hackenstein-FY2027/pages    # check status / URL
```

### Deck TODO — swap generic framing for our real scenario
The deck currently uses the challenge-wide numbers and a generic hero example. Replace with
our actual build for a stronger pitch:
- Hero moment → the cold-snap story: **Store 0214 (Denver)** out of the **Summit Down Parka**, surplus sitting in **Store 0377 (Colorado Springs, ~100mi away)**.
- Demo numbers → our exposure: **~$4.8M lost-sales** / **~$5.6M markdown**.
- Fill the dashed `.placeholder` blocks with real app screenshots + gateway dashboard once built.

## House rules

- **NO EM DASHES anywhere in deck copy.** Marshall does not want em dashes (—). Use periods, commas, colons, or rephrase. Non-negotiable.
- Keep the deck one self-contained file. Reference any added asset by relative path (Google Fonts is the only allowed external host).
- Keep copy tight. No filler.

## This repo is PUBLIC — keep these files private (gitignored, never commit)

- `challenge.md` — full internal challenge requirements (scoring rubric, internal `go/` + FEVM + dashboard URLs).
- `challenge-page.html` — raw capture of the internal Skills Navigator app page.
- `.databricks/`, `.isaac/`, `images/`, `.DS_Store` — local/internal working files.

They are listed in `.gitignore`. Do not force-add them. Share challenge requirements over an internal channel, not this public repo.
