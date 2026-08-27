# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "5"
# ///
# DBTITLE 1,NorthPeak Retail — Data Exploration
# MAGIC %md
# MAGIC # NorthPeak Retail — Data Exploration
# MAGIC
# MAGIC Quick survey of the raw datasets generated into `adminbox_catalog.northpeak_retail`.
# MAGIC
# MAGIC We're validating:
# MAGIC 1. Row counts match spec
# MAGIC 2. The hero store (STORE-0214, Denver) and surplus store (STORE-0377, Colorado Springs) exist with correct attributes
# MAGIC 3. The 5 affected cold-weather SKUs are present
# MAGIC 4. The cold-snap signal is visible (northern velocity up, southern on-hand high)
# MAGIC 5. Transfer outcome separation by move type (transfer > expedite > substitute on net value)

# COMMAND ----------

# DBTITLE 1,Config
CATALOG = "adminbox_catalog"
SCHEMA = "northpeak_retail"
RAW_PATH = f"/Volumes/{CATALOG}/{SCHEMA}/raw_data"

# COMMAND ----------

# DBTITLE 1,Row counts across all raw datasets
datasets = ["stores", "products", "sales", "inventory_snapshots", "transfers", "store_traffic"]

for ds in datasets:
    count = spark.read.parquet(f"{RAW_PATH}/{ds}").count()
    print(f"{ds:25s} {count:>10,} rows")

# COMMAND ----------

# DBTITLE 1,Stores — hero & surplus store check
# MAGIC %sql
# MAGIC SELECT store_id, store_name, city, state, region, climate_zone, store_lat, store_lng
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores`
# MAGIC WHERE store_id IN ('STORE-0214', 'STORE-0377')

# COMMAND ----------

# DBTITLE 1,Stores — climate zone distribution
# MAGIC %sql
# MAGIC SELECT climate_zone, COUNT(*) AS store_count
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores`
# MAGIC GROUP BY climate_zone
# MAGIC ORDER BY store_count DESC

# COMMAND ----------

# DBTITLE 1,Products — the 5 affected cold-weather SKUs
# MAGIC %sql
# MAGIC SELECT product_id, product_name, category, subcategory, price_usd, cost_usd, seasonality, description
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/products`
# MAGIC WHERE product_id IN ('SKU-APP-04412', 'SKU-APP-04418', 'SKU-APP-04431', 'SKU-APP-04455', 'SKU-APP-04460')

# COMMAND ----------

# DBTITLE 1,Sales — cold-snap velocity divergence (last 7 days, affected SKUs)
# MAGIC %sql
# MAGIC -- Compare recent daily velocity on affected SKUs: North vs South stores
# MAGIC WITH stores AS (
# MAGIC   SELECT store_id, climate_zone
# MAGIC   FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores`
# MAGIC   WHERE climate_zone IN ('North', 'South')
# MAGIC ),
# MAGIC recent_sales AS (
# MAGIC   SELECT s.store_id, s.product_id, s.sale_date, s.units_sold, st.climate_zone
# MAGIC   FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/sales` s
# MAGIC   JOIN stores st ON s.store_id = st.store_id
# MAGIC   WHERE s.product_id IN ('SKU-APP-04412', 'SKU-APP-04418', 'SKU-APP-04431', 'SKU-APP-04455', 'SKU-APP-04460')
# MAGIC     AND s.sale_date >= current_date() - INTERVAL 7 DAYS
# MAGIC )
# MAGIC SELECT climate_zone, 
# MAGIC        COUNT(DISTINCT store_id) AS stores_selling,
# MAGIC        ROUND(SUM(units_sold), 0) AS total_units_7d,
# MAGIC        ROUND(AVG(units_sold), 1) AS avg_units_per_row
# MAGIC FROM recent_sales
# MAGIC GROUP BY climate_zone

# COMMAND ----------

# DBTITLE 1,Inventory — current snapshot: North at zero, South with surplus
# MAGIC %sql
# MAGIC -- On-hand for affected SKUs on the most recent snapshot date, by climate zone
# MAGIC WITH stores AS (
# MAGIC   SELECT store_id, climate_zone
# MAGIC   FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/stores`
# MAGIC ),
# MAGIC latest AS (
# MAGIC   SELECT MAX(snapshot_date) AS max_date
# MAGIC   FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots`
# MAGIC )
# MAGIC SELECT st.climate_zone,
# MAGIC        COUNT(*) AS positions,
# MAGIC        ROUND(AVG(i.on_hand_units), 0) AS avg_on_hand,
# MAGIC        SUM(CASE WHEN i.on_hand_units = 0 THEN 1 ELSE 0 END) AS zero_on_hand_positions
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots` i
# MAGIC JOIN stores st ON i.store_id = st.store_id
# MAGIC CROSS JOIN latest l
# MAGIC WHERE i.product_id IN ('SKU-APP-04412', 'SKU-APP-04418', 'SKU-APP-04431', 'SKU-APP-04455', 'SKU-APP-04460')
# MAGIC   AND i.snapshot_date = l.max_date
# MAGIC GROUP BY st.climate_zone
# MAGIC ORDER BY st.climate_zone

# COMMAND ----------

# DBTITLE 1,Inventory — hero store current position
# MAGIC %sql
# MAGIC -- STORE-0214 (Denver) should have 0 on-hand for the Summit Down Parka
# MAGIC WITH latest AS (
# MAGIC   SELECT MAX(snapshot_date) AS max_date
# MAGIC   FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots`
# MAGIC )
# MAGIC SELECT i.*
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots` i
# MAGIC CROSS JOIN latest l
# MAGIC WHERE i.store_id = 'STORE-0214'
# MAGIC   AND i.product_id = 'SKU-APP-04412'
# MAGIC   AND i.snapshot_date = l.max_date

# COMMAND ----------

# DBTITLE 1,Transfers — outcome separation by move type
# MAGIC %sql
# MAGIC -- The model needs this separation to learn: transfer > expedite > substitute on net value
# MAGIC SELECT move_type,
# MAGIC        COUNT(*) AS moves,
# MAGIC        ROUND(AVG(recaptured_sales_usd), 2) AS avg_recaptured,
# MAGIC        ROUND(AVG(cost_usd), 2) AS avg_cost,
# MAGIC        ROUND(AVG(margin_impact_usd), 2) AS avg_margin_impact,
# MAGIC        ROUND(AVG(recaptured_sales_usd - cost_usd - margin_impact_usd), 2) AS avg_net_value
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/transfers`
# MAGIC GROUP BY move_type
# MAGIC ORDER BY avg_net_value DESC

# COMMAND ----------

# DBTITLE 1,Merch notes — distinct values (ai_classify dedup target)
# MAGIC %sql
# MAGIC -- These are the ~15 distinct strings ai_classify will process (one LLM call each, not per-row)
# MAGIC SELECT merch_note_text, COUNT(*) AS occurrences
# MAGIC FROM parquet.`/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots`
# MAGIC WHERE merch_note_text IS NOT NULL
# MAGIC GROUP BY merch_note_text
# MAGIC ORDER BY occurrences DESC