-- Gold: current stockout/at-risk positions enriched with nearest same-region surplus
CREATE OR REFRESH MATERIALIZED VIEW gold_open_shortfalls
AS
WITH shortfalls AS (
  SELECT *
  FROM gold_store_sku_position
  WHERE position_status IN ('stockout', 'at_risk')
),
surplus AS (
  SELECT *
  FROM gold_store_sku_position
  WHERE position_status = 'overstock'
),
nearest_surplus AS (
  SELECT
    sf.store_id,
    sf.product_id,
    sur.store_id AS nearest_surplus_store_id,
    sur.on_hand_units AS nearest_surplus_on_hand,
    2 * 6371 * ASIN(SQRT(
      POWER(SIN(RADIANS(sur.store_lat - sf.store_lat) / 2), 2) +
      COS(RADIANS(sf.store_lat)) * COS(RADIANS(sur.store_lat)) *
      POWER(SIN(RADIANS(sur.store_lng - sf.store_lng) / 2), 2)
    )) AS nearest_surplus_distance_km,
    ROW_NUMBER() OVER (
      PARTITION BY sf.store_id, sf.product_id
      ORDER BY 2 * 6371 * ASIN(SQRT(
        POWER(SIN(RADIANS(sur.store_lat - sf.store_lat) / 2), 2) +
        COS(RADIANS(sf.store_lat)) * COS(RADIANS(sur.store_lat)) *
        POWER(SIN(RADIANS(sur.store_lng - sf.store_lng) / 2), 2)
      ))
    ) AS rn
  FROM shortfalls sf
  JOIN surplus sur
    ON sf.product_id = sur.product_id
    AND sf.region = sur.region
    AND sf.store_id != sur.store_id
)
SELECT
  sf.store_id,
  sf.store_name,
  sf.region,
  sf.climate_zone,
  sf.city,
  sf.store_lat,
  sf.store_lng,
  sf.product_id,
  sf.product_name,
  sf.category,
  sf.subcategory,
  sf.seasonality,
  sf.on_hand_units,
  sf.avg_daily_velocity,
  sf.lost_sales_exposure_usd,
  sf.price_usd,
  ns.nearest_surplus_store_id,
  ns.nearest_surplus_on_hand,
  ns.nearest_surplus_distance_km
FROM shortfalls sf
LEFT JOIN nearest_surplus ns
  ON sf.store_id = ns.store_id
  AND sf.product_id = ns.product_id
  AND ns.rn = 1
