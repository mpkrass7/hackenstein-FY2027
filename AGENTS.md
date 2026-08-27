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
- [x] **1.3** — SDP pipeline (silver + gold + heuristic recommendations)
- [x] **1.4** — Metric view `mv_store_position`
- [x] **1.5** — AI/BI dashboard + Genie space
- [x] **1.6** — (Optional) ML recovery model
- [x] **2.1** — Lakebase instance + dev branch
- [x] **2.2** — Sync gold tables (read-only)
- [x] **2.3** — Writable `ops_actions` table
- [x] **2.4** — Lakebase Search on products
- [ ] **3.x** — Databricks App
- [ ] **4.x** — Unity AI Gateway

## Conventions

We follow the [Genie Code best practices](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md). Section-specific pointers:

- **Git workflow & branch policy**: See [Git Workflow](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#git-workflow). All work happens in feature branches — never commit directly to `master`. Branch naming: `<initials>-genie-<short-description>` (e.g. `mk-genie-lakebase-sync`). The agent may commit and push from feature branches; work flows feature branch → PR → review → merge. Only commit or push when Marshall asks.
- **Project memory (this file)**: See [Project Memory](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#project-memory). The doc uses `PROJECT_MEMORY.md`; **for this project that role is served by this `AGENTS.md`**. Read it at session start for full context, and keep architecture, naming, resource IDs, milestone progress, and open questions current here.
- **Session summaries**: See [Session Summaries](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#session-summaries). Summaries live in `fixtures/sessions/` with an `INDEX.md` (reverse-chronological) and individual `YYYY-MM-DD_short-description.md` files capturing date, branch, problems, root causes, and changes made. Always use `datetime.now()` for dates.
- **Unity Catalog as context**: See [Unity Catalog as Context](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#unity-catalog-as-context) and [Naming for Discoverability](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#naming-for-discoverability). Column comments are the highest-ROI context for Genie; use semantic `<domain>_<entity>` names and standard suffixes (`_id`, `_at`, `_count`).
- **Bundle & pipeline conventions**: See [Declarative Automation Bundle Conventions](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#declarative-automation-bundle-conventions) and [Spark Declarative Pipeline Conventions](https://github.com/mkgs-databricks-demos/genieCodeWorkshop/blob/main/docs/conventions/genie-code-best-practices.md#spark-declarative-pipeline-conventions).
- **Code style**: Per user preferences — docstrings, type hints, isort imports at top, annotated cells with markdown headers, clean and non-verbose.

---

## Presentation deck (Grand Theft Demo) + GitHub Pages

The pitch deck for the challenge lives in this repo as a single self-contained HTML file,
served live via **GitHub Pages**. It is themed as **Grand Theft Demo** (a GTA send-up):
Marshall as "The Demo Guy," Logan as "The Wheelman," and the goodest boy as "The Co-Host."

- **Live URL:** https://mpkrass7.github.io/hackenstein-FY2027/
- **File:** `index.html` (all CSS + JS inline; no build step; only external dependency is Google Fonts)
- **Cover art:** `assets/grand_theft_demo.png` (the title card). `assets/` IS published; reference deck images from there with a relative path.
- The deck is a **horizontal-scroll** slide deck (arrow keys, space, on-screen back/next buttons). Single committed dark theme.
- **Fonts:** Anton (display headings + stat numbers), Inter (body), IBM Plex Mono (labels/data).
- **Semantic palette:** orange = brand accent, red = loss/stockout, gold = markdown (and the rating stars), green = recovery/win, on a dark teal ground.

### Updating the deck and shipping it live

```bash
# 1. edit index.html (content is in the <section class="slide"> blocks inside <div class="deck">)
# 2. preview locally:
open index.html
# 3. ship it (Pages auto-rebuilds on push to master, live in ~1 min):
git add index.html
git commit -m "deck: <what changed>"
git push origin master
```

Hard-refresh (Cmd+Shift+R) to bypass the browser cache after a deploy.
Add a slide by copying a `<section class="slide">` block; the slide counter is automatic.

### Pages setup (already done, for reference)
```bash
gh api -X POST repos/mpkrass7/hackenstein-FY2027/pages -f 'source[branch]=master' -f 'source[path]=/'
gh api repos/mpkrass7/hackenstein-FY2027/pages    # check status / URL
```

### Scenario baked in (done)
The deck uses our real scenario, not generic framing:
- Hero moment: the cold-snap story, **Store 0214 (Denver)** out of the **Summit Down Parka** (`SKU-APP-04412`), surplus at **Store 0377 (Colorado Springs, ~100mi away)**.
- Numbers: **~$4.8M lost sales** / **~$5.6M markdown** for the event, ~$200M/yr chain-wide, plus ~$10M and ~$12M as the annual outcomes to defend.

### Remaining TODO
- Fill the dashed `.placeholder` blocks on the demo and AI-spend slides with real app screenshots and the gateway usage dashboard once built.

## House rules

- **NO EM DASHES anywhere in deck copy.** Marshall does not want em dashes (—). Use periods, commas, colons, or rephrase. Non-negotiable.
- Keep the deck one self-contained file. Reference any added asset by relative path (Google Fonts is the only allowed external host).
- Keep copy tight. No filler.

## This repo is PUBLIC — keep these files private (gitignored, never commit)

- `challenge.md` — full internal challenge requirements (scoring rubric, internal `go/` + FEVM + dashboard URLs).
- `challenge-page.html` — raw capture of the internal Skills Navigator app page.
- `.databricks/`, `.isaac/`, `images/`, `.DS_Store` — local/internal working files.

They are listed in `.gitignore`. Do not force-add them. Share challenge requirements over an internal channel, not this public repo.
