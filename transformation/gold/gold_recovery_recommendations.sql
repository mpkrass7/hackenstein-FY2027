-- Gold: ranked recovery move per open shortfall via heuristic scoring
CREATE OR REFRESH MATERIALIZED VIEW gold_recovery_recommendations
AS
WITH shortfalls AS (
  SELECT
    store_id,
    product_id,
    subcategory,
    price_usd,
    avg_daily_velocity,
    nearest_surplus_store_id,
    nearest_surplus_on_hand,
    nearest_surplus_distance_km,
    GREATEST(1, CAST(CEIL(avg_daily_velocity * 14) AS INT)) AS units_needed
  FROM gold_open_shortfalls
),
-- Find best substitute: cold_weather product in same subcategory, closest price
substitutes AS (
  SELECT
    s.store_id,
    s.product_id,
    p.product_id AS substitute_product_id,
    ROW_NUMBER() OVER (
      PARTITION BY s.store_id, s.product_id
      ORDER BY ABS(p.price_usd - s.price_usd)
    ) AS rn
  FROM shortfalls s
  JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/products') p
    ON p.seasonality = 'cold_weather'
    AND p.subcategory = s.subcategory
    AND p.product_id != s.product_id
),
moves AS (
  SELECT
    s.store_id,
    s.product_id,
    s.units_needed,
    s.price_usd,
    s.nearest_surplus_store_id,
    s.nearest_surplus_on_hand,
    s.nearest_surplus_distance_km,
    sub.substitute_product_id,
    -- Transfer move
    LEAST(s.units_needed, COALESCE(s.nearest_surplus_on_hand, 0)) AS transfer_units,
    LEAST(s.units_needed, COALESCE(s.nearest_surplus_on_hand, 0)) * s.price_usd * 0.9 AS transfer_recaptured,
    60.0 + COALESCE(s.nearest_surplus_distance_km, 9999) * 1.1 AS transfer_cost,
    0.0 AS transfer_margin_impact,
    -- Expedite move
    s.units_needed * s.price_usd * 0.82 AS expedite_recaptured,
    s.units_needed * 9.0 + 400.0 AS expedite_cost,
    0.0 AS expedite_margin_impact,
    -- Substitute move
    s.units_needed * s.price_usd * 0.35 AS substitute_recaptured,
    0.0 AS substitute_cost,
    s.units_needed * (s.price_usd * 0.58) * 0.45 AS substitute_margin_impact
  FROM shortfalls s
  LEFT JOIN substitutes sub
    ON s.store_id = sub.store_id
    AND s.product_id = sub.product_id
    AND sub.rn = 1
),
scored AS (
  SELECT
    *,
    transfer_recaptured - transfer_cost - transfer_margin_impact AS transfer_net,
    expedite_recaptured - expedite_cost - expedite_margin_impact AS expedite_net,
    substitute_recaptured - substitute_cost - substitute_margin_impact AS substitute_net
  FROM moves
)
SELECT
  store_id,
  product_id,
  CASE
    WHEN nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net
    THEN 'transfer'
    WHEN expedite_net >= substitute_net THEN 'expedite'
    ELSE 'substitute'
  END AS recommended_move,
  CASE
    WHEN nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net
    THEN nearest_surplus_store_id
    ELSE NULL
  END AS recommended_source_store_id,
  CASE
    WHEN NOT (nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net)
      AND NOT (expedite_net >= substitute_net)
    THEN substitute_product_id
    ELSE NULL
  END AS recommended_substitute_product_id,
  CASE
    WHEN nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net
    THEN transfer_units
    ELSE units_needed
  END AS recommended_units,
  CASE
    WHEN nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net
    THEN transfer_recaptured
    WHEN expedite_net >= substitute_net THEN expedite_recaptured
    ELSE substitute_recaptured
  END AS predicted_recaptured_usd,
  CASE
    WHEN nearest_surplus_store_id IS NOT NULL
      AND transfer_net >= expedite_net AND transfer_net >= substitute_net
    THEN transfer_net
    WHEN expedite_net >= substitute_net THEN expedite_net
    ELSE substitute_net
  END AS predicted_net_value_usd,
  to_json(array(
    named_struct('move', 'transfer', 'recaptured', transfer_recaptured, 'cost', transfer_cost, 'net', transfer_net),
    named_struct('move', 'expedite', 'recaptured', expedite_recaptured, 'cost', expedite_cost, 'net', expedite_net),
    named_struct('move', 'substitute', 'recaptured', substitute_recaptured, 'cost', substitute_cost, 'net', substitute_net)
  )) AS move_ranking,
  CURRENT_TIMESTAMP() AS scored_at
FROM scored
