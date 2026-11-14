-- Step 4: after a deal is won, does the seller actually start selling? (activation)
-- A "valid sale" is an order that is not canceled or unavailable.
-- Orders on or after 2018-08-28 are ignored because the data thins out at the end.

-- Date of the first valid sale for each seller
CREATE OR REPLACE TABLE first_sale AS
SELECT i.seller_id,
       MIN(o.order_purchase_timestamp::DATE) AS first_sale_date
FROM items i
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp < '2018-08-28'
GROUP BY i.seller_id;

-- One row per won deal (account).
-- We keep only deals won on or before 2018-05-29, so every account has had a full 90 days
-- of order data (data ends 2018-08-28). Newer deals have not had time to show a first sale.
-- active_90 = 1 if the first sale happened within 90 days of the win.
CREATE OR REPLACE TABLE accounts AS
SELECT d.mql_id,
       d.seller_id,
       COALESCE(d.lead_type, 'not recorded') AS lead_type,
       COALESCE(l.origin, 'unknown') AS origin,
       d.won_date::DATE AS won_date,
       f.first_sale_date,
       f.first_sale_date - d.won_date::DATE AS days_to_first_sale,
       CASE WHEN f.first_sale_date - d.won_date::DATE <= 90 THEN 1 ELSE 0 END AS active_90
FROM deals d
JOIN leads l ON d.mql_id = l.mql_id
LEFT JOIN first_sale f ON d.seller_id = f.seller_id
WHERE d.won_date::DATE <= '2018-05-29';

-- Overall activation
COPY (
    SELECT COUNT(*) AS accounts,
           SUM(CASE WHEN days_to_first_sale <= 30 THEN 1 ELSE 0 END) AS active_30,
           SUM(active_90) AS active_90,
           ROUND(100.0 * SUM(active_90) / COUNT(*), 1) AS active_90_pct,
           MEDIAN(days_to_first_sale) AS median_days_to_first_sale
    FROM accounts
) TO 'results/activation.csv' (HEADER);

-- Activation by lead type
COPY (
    SELECT lead_type,
           COUNT(*) AS accounts,
           SUM(active_90) AS active_90,
           ROUND(100.0 * SUM(active_90) / COUNT(*), 1) AS active_90_pct
    FROM accounts
    GROUP BY lead_type
    HAVING COUNT(*) >= 10
    ORDER BY accounts DESC
) TO 'results/activation_by_lead_type.csv' (HEADER);

-- Activation by origin
COPY (
    SELECT origin,
           COUNT(*) AS accounts,
           SUM(active_90) AS active_90,
           ROUND(100.0 * SUM(active_90) / COUNT(*), 1) AS active_90_pct
    FROM accounts
    GROUP BY origin
    HAVING COUNT(*) >= 15
    ORDER BY accounts DESC
) TO 'results/activation_by_origin.csv' (HEADER);

-- Sales in the first 90 days after the win, per active account
COPY (
    SELECT COUNT(DISTINCT a.seller_id) AS active_accounts,
           ROUND(SUM(i.price)) AS sales_first_90_days,
           ROUND(SUM(i.price) / COUNT(DISTINCT a.seller_id)) AS avg_sales_per_active_account
    FROM accounts a
    JOIN items i ON a.seller_id = i.seller_id
    JOIN orders o ON i.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.order_purchase_timestamp::DATE BETWEEN a.won_date AND a.won_date + 90
      AND o.order_purchase_timestamp < '2018-08-28'
) TO 'results/sales_first_90_days.csv' (HEADER);
