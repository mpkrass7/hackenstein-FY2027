-- Silver: AI-classified markdown risk scores for distinct merch notes
-- Dedup trick: only ~15 distinct strings across hundreds of thousands of inventory rows
CREATE OR REFRESH MATERIALIZED VIEW note_markdown_flags
AS
SELECT
  merch_note_text,
  CASE ai_classify(merch_note_text, ARRAY('dead_stock', 'aging', 'healthy'))
    WHEN 'dead_stock' THEN 1.0
    WHEN 'aging'      THEN 0.6
    ELSE 0.1
  END AS markdown_risk_score
FROM (
  SELECT DISTINCT merch_note_text
  FROM read_files('/Volumes/adminbox_catalog/northpeak_retail/raw_data/inventory_snapshots')
  WHERE merch_note_text IS NOT NULL
)
