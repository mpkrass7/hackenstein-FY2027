-- Core business question (answered from Lakebase synced tables):
--   "Which northern stores are short on the Summit Down Parka (SKU-APP-04412),
--    and where is the nearest surplus store to recover from?"
--
-- Joins two governed, UC-synced tables served from Lakebase:
--   app.open_shortfalls    (the shortfall + its nearest surplus store)
--   app.store_sku_position (position detail for the surplus store)
SELECT
    s.store_id                                   AS short_store,
    s.store_name                                 AS short_store_name,
    s.city                                       AS short_city,
    s.region,
    s.on_hand_units,
    ROUND(s.lost_sales_exposure_usd::numeric, 0) AS lost_sales_usd,
    s.nearest_surplus_store_id                   AS surplus_store,
    surplus.store_name                           AS surplus_store_name,
    surplus.city                                 AS surplus_city,
    s.nearest_surplus_on_hand                    AS surplus_on_hand,
    ROUND(s.nearest_surplus_distance_km::numeric, 0) AS distance_km
FROM app.open_shortfalls s
LEFT JOIN app.store_sku_position surplus
       ON surplus.store_id  = s.nearest_surplus_store_id
      AND surplus.product_id = s.product_id
WHERE s.product_id = 'SKU-APP-04412'          -- Summit Down Parka
  AND s.climate_zone = 'North'
  AND s.nearest_surplus_store_id IS NOT NULL  -- has a recoverable surplus
ORDER BY s.lost_sales_exposure_usd DESC
LIMIT 15;
