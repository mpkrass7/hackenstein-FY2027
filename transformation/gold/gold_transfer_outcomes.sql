-- Gold: recovery-move history for model training with situational features
CREATE OR REFRESH MATERIALIZED VIEW gold_transfer_outcomes
AS
SELECT
  transfer_id,
  product_id,
  product_name,
  category,
  move_type,
  units_moved,
  distance_km,
  days_to_fulfill,
  price_usd,
  cost_usd / NULLIF(price_usd, 0) AS margin_pct,
  recaptured_sales_usd,
  margin_impact_usd
FROM silver_transfers
