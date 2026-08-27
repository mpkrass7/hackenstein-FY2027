-- Silver: per store x SKU x day denormalized sales fact
CREATE OR REFRESH MATERIALIZED VIEW silver_sales
CLUSTER BY (sale_date)
AS
SELECT
  s.store_id,
  st.store_name,
  st.region,
  st.climate_zone,
  st.city,
  st.store_lat,
  st.store_lng,
  s.product_id,
  p.product_name,
  p.category,
  p.subcategory,
  p.seasonality,
  s.sale_date,
  s.units_sold,
  s.net_sales_usd,
  s.channel
FROM read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/sales') s
JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores') st
  ON s.store_id = st.store_id
JOIN read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/products') p
  ON s.product_id = p.product_id
