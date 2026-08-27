-- Silver: recovery-move history, denormalized with store and product dims
CREATE OR REFRESH MATERIALIZED VIEW silver_transfers
AS
SELECT
  t.transfer_id,
  t.product_id,
  p.product_name,
  p.category,
  t.move_type,
  t.from_store_id,
  fs.region AS from_region,
  fs.climate_zone AS from_climate,
  t.to_store_id,
  ts.region AS to_region,
  ts.climate_zone AS to_climate,
  t.substitute_product_id,
  t.units_moved,
  t.initiated_date,
  t.days_to_fulfill,
  t.recaptured_sales_usd,
  t.margin_impact_usd,
  t.cost_usd,
  p.price_usd,
  -- Haversine distance between from/to stores (km)
  CASE WHEN t.from_store_id IS NOT NULL THEN
    2 * 6371 * ASIN(SQRT(
      POWER(SIN(RADIANS(ts.store_lat - fs.store_lat) / 2), 2) +
      COS(RADIANS(fs.store_lat)) * COS(RADIANS(ts.store_lat)) *
      POWER(SIN(RADIANS(ts.store_lng - fs.store_lng) / 2), 2)
    ))
  ELSE 0
  END AS distance_km
FROM read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/transfers') t
JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/products') p
  ON t.product_id = p.product_id
LEFT JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores') fs
  ON t.from_store_id = fs.store_id
JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores') ts
  ON t.to_store_id = ts.store_id
