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
- **Asset location**: All created files go in this project folder. Transformation code under `./transformation/`, dashboard + Genie at root.

## Architecture Notes

- **No bronze layer** — raw parquet in Volume → SDP silver reads via `read_files()`
- **`ai_classify` trick** — dedup distinct `merch_note_text` values into a small MV, classify once per unique string, join back
- **Pipeline heuristic** builds `gold_recovery_recommendations` (no ML required) — ranks transfer/expedite/substitute by net value
- **Transfer wins for hero** because STORE-0377 is nearby, same region, with surplus
- **Metric view** `mv_store_position` is the single source of truth for exposure KPIs — dashboard, Genie, and app all read it
- **All files created** go in project folder: transformation code under `./transformation/`, dashboard + Genie at root
