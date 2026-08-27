-- Metric View: mv_store_position
-- The single governed definition of NorthPeak's exposure KPIs.
-- Dashboard KPI tiles, Genie headline answers, and the app all consume
-- these same measures — numbers match wherever Dana looks.
--
-- Source: gold_store_sku_position (current per store×SKU position)
-- Filter dimensions: climate_zone, region, category (dashboard-filter contract)

CREATE OR REPLACE VIEW adminbox_catalog.northpeak_retail.mv_store_position
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
source: adminbox_catalog.northpeak_retail.gold_store_sku_position
comment: >
  NorthPeak Retail exposure metrics — the single governed definition of
  lost-sales and markdown KPIs. Dashboard, Genie, and app all consume
  these same measures so numbers are consistent everywhere.
dimensions:
  - name: climate_zone
    expr: climate_zone
    comment: Store climate classification (North/South/Mixed)
    synonyms:
      - climate
      - zone
  - name: region
    expr: region
    comment: Geographic region (Northeast/Southeast/Midwest/West/South-Central)
  - name: category
    expr: category
    comment: Product category (Apparel/Home/General Merchandise)
  - name: position_status
    expr: position_status
    comment: Current inventory position status (stockout/at_risk/overstock/healthy)
    synonyms:
      - status
      - inventory status
  - name: product_id
    expr: product_id
    comment: SKU identifier
    synonyms:
      - sku
      - sku_id
  - name: product_name
    expr: product_name
    comment: Product display name
measures:
  - name: lost_sales_exposure
    expr: SUM(lost_sales_exposure_usd)
    comment: Total lost-sales revenue across stockout positions
    display_name: Lost Sales Exposure
    format:
      type: currency
      currency_code: USD
      decimal_places:
        type: exact
        places: 0
    synonyms:
      - lost sales
      - stockout exposure
  - name: markdown_exposure
    expr: SUM(markdown_exposure_usd)
    comment: Total markdown-at-risk revenue across overstock positions
    display_name: Markdown Exposure
    format:
      type: currency
      currency_code: USD
      decimal_places:
        type: exact
        places: 0
    synonyms:
      - markdown risk
      - overstock exposure
  - name: on_hand_units
    expr: SUM(on_hand_units)
    comment: Total on-hand inventory units
    display_name: On-Hand Units
  - name: recent_units_7d
    expr: SUM(recent_units_7d)
    comment: Total units sold in the trailing 7 days
    display_name: Recent Units (7d)
    synonyms:
      - sell through
      - velocity
  - name: recent_net_sales_7d
    expr: SUM(recent_net_sales_7d)
    comment: Total net sales revenue in the trailing 7 days
    display_name: Recent Net Sales (7d)
    format:
      type: currency
      currency_code: USD
      decimal_places:
        type: exact
        places: 0
  - name: position_count
    expr: COUNT(1)
    comment: Total number of store x SKU positions
    display_name: Position Count
  - name: stockout_count
    expr: SUM(CASE WHEN position_status = 'stockout' THEN 1 ELSE 0 END)
    comment: Number of positions currently stocked out
    display_name: Stockout Positions
    synonyms:
      - stockouts
      - out of stock count
  - name: overstock_count
    expr: SUM(CASE WHEN position_status = 'overstock' THEN 1 ELSE 0 END)
    comment: Number of positions currently overstocked
    display_name: Overstock Positions
    synonyms:
      - overstocks
      - surplus count
  - name: avg_weeks_of_supply
    expr: AVG(weeks_of_supply)
    comment: Average weeks of supply across positions (coarse health signal)
    display_name: Avg Weeks of Supply
    format:
      type: number
      decimal_places:
        type: exact
        places: 1
  - name: avg_markdown_risk
    expr: AVG(markdown_risk_score)
    comment: Average markdown risk score (0-1) from ai_classify
    display_name: Avg Markdown Risk
    format:
      type: number
      decimal_places:
        type: exact
        places: 2
materialization:
  schedule: every 6 hours
  mode: relaxed
  materialized_views:
    - name: exposure_by_position
      type: aggregated
      dimensions:
        - climate_zone
        - region
        - category
        - position_status
        - product_id
      measures:
        - lost_sales_exposure
        - markdown_exposure
        - on_hand_units
        - recent_units_7d
        - recent_net_sales_7d
        - position_count
        - stockout_count
        - overstock_count
        - avg_weeks_of_supply
        - avg_markdown_risk
      cluster_by:
        auto: true
$$;
