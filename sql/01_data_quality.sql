-- 01_data_quality.sql: key integrity, coverage, date sanity. Each row = one check.
SELECT 'mql rows' AS check_name, COUNT(*)::VARCHAR AS value FROM raw_mql
UNION ALL SELECT 'mql distinct mql_id', COUNT(DISTINCT mql_id)::VARCHAR FROM raw_mql
UNION ALL SELECT 'mql null origin', COUNT(*)::VARCHAR FROM raw_mql WHERE origin IS NULL
UNION ALL SELECT 'mql first_contact min', MIN(first_contact_date)::VARCHAR FROM raw_mql
UNION ALL SELECT 'mql first_contact max', MAX(first_contact_date)::VARCHAR FROM raw_mql
UNION ALL SELECT 'deals rows', COUNT(*)::VARCHAR FROM raw_deals
UNION ALL SELECT 'deals distinct mql_id', COUNT(DISTINCT mql_id)::VARCHAR FROM raw_deals
UNION ALL SELECT 'deals distinct seller_id', COUNT(DISTINCT seller_id)::VARCHAR FROM raw_deals
UNION ALL SELECT 'deals not in mql (orphans)', COUNT(*)::VARCHAR FROM raw_deals d LEFT JOIN raw_mql m USING (mql_id) WHERE m.mql_id IS NULL
UNION ALL SELECT 'deals won_date min', MIN(won_date)::VARCHAR FROM raw_deals
UNION ALL SELECT 'deals won_date max', MAX(won_date)::VARCHAR FROM raw_deals
UNION ALL SELECT 'deals won before first contact', COUNT(*)::VARCHAR FROM raw_deals d JOIN raw_mql m USING (mql_id) WHERE d.won_date::DATE < m.first_contact_date
UNION ALL SELECT 'deal sellers present in sellers table', COUNT(DISTINCT d.seller_id)::VARCHAR FROM raw_deals d JOIN raw_sellers s USING (seller_id)
UNION ALL SELECT 'deal sellers with >=1 order item', COUNT(DISTINCT d.seller_id)::VARCHAR FROM raw_deals d JOIN raw_items i USING (seller_id)
UNION ALL SELECT 'sellers table rows', COUNT(*)::VARCHAR FROM raw_sellers
UNION ALL SELECT 'sellers with order items', COUNT(DISTINCT seller_id)::VARCHAR FROM raw_items
UNION ALL SELECT 'orders min purchase', MIN(order_purchase_timestamp)::VARCHAR FROM raw_orders
UNION ALL SELECT 'orders max purchase', MAX(order_purchase_timestamp)::VARCHAR FROM raw_orders
UNION ALL SELECT 'orders distinct order_id', COUNT(DISTINCT order_id)::VARCHAR FROM raw_orders
UNION ALL SELECT 'items with order not in orders', COUNT(*)::VARCHAR FROM raw_items i LEFT JOIN raw_orders o USING (order_id) WHERE o.order_id IS NULL;
