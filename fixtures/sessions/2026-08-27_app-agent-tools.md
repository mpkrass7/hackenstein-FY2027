# Session: App Agent Tools Implementation

**Date:** 2026-08-27
**Branch:** `mk-genie-app-tools`
**Milestone:** 3.x (Databricks App)

## Goal

Implement the 4 stubbed agent tools in `app/server/agent/storeops.ts` that power the demo's Visualize > Assist > Act arc.

## Context

The app template was rsync'd and customized for NorthPeak. Config, schema, helper queries, and the client UI all exist. The agent file has `ask_data` working and 3 tools stubbed (throwing "not implemented"). A 5th tool (`search_products`) is missing entirely.

## Deliverables

- [x] Branch `mk-genie-app-tools` created from `master`
- [x] `find_shortfall` tool: reads open_shortfalls + store_sku_position via getShortfall/worstShortfall + getPosition
- [x] `rank_recovery_moves` tool: reads recovery_recommendations via getRecommendation helper
- [x] `execute_recovery_action` tool: Drizzle insert to ops_actions + paired markdown_hold for transfers, emits dataMutated
- [x] `search_products` tool: ILIKE search over app.products (name, description, category) for substitute candidates

## Key files

- `app/server/agent/storeops.ts` (the agent + tools)
- `app/server/db/queries/stores.ts` (helper queries, already implemented)
- `app/server/db/schema.ts` (Drizzle schema)
- `app/config/app.json` (app config)

## Dependencies

- Lakebase `store_sku_position` needs data (local agent handling sync)
- Lakebase `recovery_recommendations` table needs creation + data
- Lakebase `ops_actions` table needs creation (Drizzle migration handles this)
