-- 00_load.sql: load raw CSVs into DuckDB tables (raw layer, untouched)
CREATE OR REPLACE TABLE raw_mql AS SELECT * FROM read_csv_auto('data/olist_marketing_qualified_leads_dataset.csv', header=true);
CREATE OR REPLACE TABLE raw_deals AS SELECT * FROM read_csv_auto('data/olist_closed_deals_dataset.csv', header=true);
CREATE OR REPLACE TABLE raw_orders AS SELECT * FROM read_csv_auto('data/olist_orders_dataset.csv', header=true);
CREATE OR REPLACE TABLE raw_items AS SELECT * FROM read_csv_auto('data/olist_order_items_dataset.csv', header=true);
CREATE OR REPLACE TABLE raw_sellers AS SELECT * FROM read_csv_auto('data/olist_sellers_dataset.csv', header=true);
CREATE OR REPLACE TABLE raw_payments AS SELECT * FROM read_csv_auto('data/olist_order_payments_dataset.csv', header=true);
