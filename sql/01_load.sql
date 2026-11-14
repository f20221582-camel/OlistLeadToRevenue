-- Step 1: load the CSV files into tables.
-- read_csv_auto lets DuckDB guess the column types (dates become DATE or TIMESTAMP).

CREATE OR REPLACE TABLE leads   AS SELECT * FROM read_csv_auto('data/olist_marketing_qualified_leads_dataset.csv');
CREATE OR REPLACE TABLE deals   AS SELECT * FROM read_csv_auto('data/olist_closed_deals_dataset.csv');
CREATE OR REPLACE TABLE orders  AS SELECT * FROM read_csv_auto('data/olist_orders_dataset.csv');
CREATE OR REPLACE TABLE items   AS SELECT * FROM read_csv_auto('data/olist_order_items_dataset.csv');
CREATE OR REPLACE TABLE sellers AS SELECT * FROM read_csv_auto('data/olist_sellers_dataset.csv');
