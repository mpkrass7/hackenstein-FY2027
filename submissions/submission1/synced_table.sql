-- Evidence: query against a synced Unity Catalog table served from Lakebase.
--
-- `app.store_sku_position` is a READ-ONLY Lakebase synced table, continuously
-- backed by the governed UC Delta source
-- `adminbox_catalog.northpeak_retail.serving_store_sku_position`
-- (registered in UC as the database catalog `northpeak_lb`). The app serves
-- per-store reads from here at low latency.
--
-- This returns the worst northern stockouts on the affected cold-weather SKUs.
SELECT
    store_id,
    store_name,
    city,
    region,
    climate_zone,
    product_id,
    product_name,
    on_hand_units,
    recent_units_7d,
    ROUND(avg_daily_velocity::numeric, 2) AS avg_daily_velocity,
    position_status,
    ROUND(lost_sales_exposure_usd::numeric, 0) AS lost_sales_exposure_usd
FROM app.store_sku_position
WHERE position_status = 'stockout'
  AND climate_zone = 'North'
ORDER BY lost_sales_exposure_usd DESC
LIMIT 15;
