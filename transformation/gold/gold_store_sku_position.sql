-- Gold: THE HEART OF THE DEMO — one row per (store, SKU) with current position + velocity + status
CREATE OR REFRESH MATERIALIZED VIEW gold_store_sku_position
CLUSTER BY (region, category)
AS
WITH current_inventory AS (
  SELECT *
  FROM silver_inventory
  WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM silver_inventory)
),
recent_sales AS (
  SELECT
    store_id,
    product_id,
    SUM(units_sold) AS recent_units_7d,
    SUM(net_sales_usd) AS recent_net_sales_7d
  FROM silver_sales
  WHERE sale_date >= (
    SELECT DATE_SUB(MAX(snapshot_date), 7) FROM silver_inventory
  )
  GROUP BY ALL
)
SELECT
  i.store_id,
  i.store_name,
  i.region,
  i.climate_zone,
  i.city,
  i.store_lat,
  i.store_lng,
  i.product_id,
  i.product_name,
  i.category,
  i.subcategory,
  i.seasonality,
  i.on_hand_units,
  i.on_order_units,
  COALESCE(rs.recent_units_7d, 0) AS recent_units_7d,
  COALESCE(rs.recent_net_sales_7d, 0.0) AS recent_net_sales_7d,
  COALESCE(rs.recent_units_7d, 0) / 7.0 AS avg_daily_velocity,
  i.on_hand_units / NULLIF(COALESCE(rs.recent_units_7d, 0) / 7.0 * 7, 0) AS weeks_of_supply,
  i.price_usd,
  i.markdown_risk_score,
  -- Lost sales exposure: projected lost revenue over 30 days for short/stockout positions
  GREATEST(0, COALESCE(rs.recent_units_7d, 0) / 7.0 * i.price_usd * 30) AS lost_sales_exposure_usd,
  -- Markdown exposure: overstock value at risk of markdown (30% depth)
  GREATEST(0, (i.on_hand_units - (COALESCE(rs.recent_units_7d, 0) / 7.0 * 30)) * i.price_usd * 0.3) AS markdown_exposure_usd,
  -- Position status classification
  CASE
    WHEN i.on_hand_units = 0 AND COALESCE(rs.recent_units_7d, 0) / 7.0 > 0 THEN 'stockout'
    WHEN i.on_hand_units / NULLIF(COALESCE(rs.recent_units_7d, 0) / 7.0 * 7, 0) < 1
      AND COALESCE(rs.recent_units_7d, 0) / 7.0 > 0 THEN 'at_risk'
    WHEN (i.on_hand_units / NULLIF(COALESCE(rs.recent_units_7d, 0) / 7.0 * 7, 0) > 8
      OR (COALESCE(rs.recent_units_7d, 0) = 0 AND i.on_hand_units > 0))
      AND i.markdown_risk_score >= 0.6 THEN 'overstock'
    ELSE 'healthy'
  END AS position_status
FROM current_inventory i
LEFT JOIN recent_sales rs
  ON i.store_id = rs.store_id AND i.product_id = rs.product_id
