-- Step 2: look at the data before analysing it.
-- Each query answers one question. Results are saved in results/.

-- How many rows are in each table?
COPY (
    SELECT 'leads' AS table_name, COUNT(*) AS row_count FROM leads
    UNION ALL SELECT 'deals',   COUNT(*) FROM deals
    UNION ALL SELECT 'orders',  COUNT(*) FROM orders
    UNION ALL SELECT 'items',   COUNT(*) FROM items
    UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
) TO 'results/check_row_counts.csv' (HEADER);

-- Is mql_id unique in leads and in deals? (we join on it, so it must be)
COPY (
    SELECT COUNT(*) AS rows, COUNT(DISTINCT mql_id) AS unique_ids FROM leads
) TO 'results/check_unique_leads.csv' (HEADER);

COPY (
    SELECT COUNT(*) AS rows, COUNT(DISTINCT mql_id) AS unique_ids FROM deals
) TO 'results/check_unique_deals.csv' (HEADER);

-- Does every deal match a lead?
COPY (
    SELECT COUNT(*) AS deals_without_lead
    FROM deals d LEFT JOIN leads l ON d.mql_id = l.mql_id
    WHERE l.mql_id IS NULL
) TO 'results/check_deals_without_lead.csv' (HEADER);

-- Missing values: how many leads have no origin?
COPY (
    SELECT COUNT(*) AS leads_without_origin FROM leads WHERE origin IS NULL
) TO 'results/check_missing_origin.csv' (HEADER);

-- Date ranges: when do leads, deals and orders start and end?
COPY (
    SELECT 'leads first contact' AS what, MIN(first_contact_date)::DATE AS first_date, MAX(first_contact_date)::DATE AS last_date FROM leads
    UNION ALL SELECT 'deals won', MIN(won_date)::DATE, MAX(won_date)::DATE FROM deals
    UNION ALL SELECT 'orders placed', MIN(order_purchase_timestamp)::DATE, MAX(order_purchase_timestamp)::DATE FROM orders
) TO 'results/check_date_ranges.csv' (HEADER);

-- Orders per month. This shows the order data really ends around Aug 2018.
COPY (
    SELECT strftime(order_purchase_timestamp, '%Y-%m') AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY 1
    ORDER BY 1
) TO 'results/check_orders_per_month.csv' (HEADER);

-- Orders per day around the end of the data (Aug 20 to Sep 5 2018).
COPY (
    SELECT order_purchase_timestamp::DATE AS day, COUNT(*) AS orders
    FROM orders
    WHERE order_purchase_timestamp >= '2018-08-20' AND order_purchase_timestamp < '2018-09-06'
    GROUP BY 1
    ORDER BY 1
) TO 'results/check_orders_end_of_data.csv' (HEADER);

-- How many of the deals belong to a seller that appears in the orders data at all?
COPY (
    SELECT COUNT(*) AS deals,
           SUM(CASE WHEN seller_id IN (SELECT seller_id FROM items) THEN 1 ELSE 0 END) AS deals_with_orders
    FROM deals
) TO 'results/check_deal_sellers_in_orders.csv' (HEADER);
