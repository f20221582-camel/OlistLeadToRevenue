-- Step 5: where does the money come from?
-- GMV = total price of items sold (freight not included), in Brazilian reais (R$).

-- Total sales per seller who won a deal (all deals, all time up to the end of the data)
CREATE OR REPLACE TABLE account_sales AS
SELECT d.seller_id,
       COALESCE(d.lead_type, 'not recorded') AS lead_type,
       SUM(i.price) AS gmv
FROM deals d
JOIN items i ON d.seller_id = i.seller_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp < '2018-08-28'
GROUP BY d.seller_id, COALESCE(d.lead_type, 'not recorded');

-- Totals
COPY (
    SELECT COUNT(*) AS accounts_with_sales,
           ROUND(SUM(gmv)) AS total_gmv,
           ROUND(AVG(gmv)) AS average_gmv,
           ROUND(MEDIAN(gmv)) AS median_gmv
    FROM account_sales
) TO 'results/gmv_totals.csv' (HEADER);

-- Share of GMV from the top 10% of accounts (10% of 379 accounts is about 38)
COPY (
    SELECT COUNT(*) AS top_accounts,
           ROUND(SUM(gmv)) AS top_gmv,
           ROUND(100.0 * SUM(gmv) / (SELECT SUM(gmv) FROM account_sales), 1) AS share_of_total_pct
    FROM (SELECT gmv FROM account_sales ORDER BY gmv DESC LIMIT 38)
) TO 'results/gmv_top_10_percent.csv' (HEADER);

-- Which lead types are in that top 38?
COPY (
    SELECT lead_type, COUNT(*) AS accounts_in_top_38
    FROM (SELECT lead_type FROM account_sales ORDER BY gmv DESC LIMIT 38)
    GROUP BY lead_type
    ORDER BY accounts_in_top_38 DESC
) TO 'results/top_10_percent_by_lead_type.csv' (HEADER);

-- GMV by lead type
COPY (
    SELECT lead_type,
           COUNT(*) AS accounts_with_sales,
           ROUND(SUM(gmv)) AS gmv,
           ROUND(100.0 * SUM(gmv) / (SELECT SUM(gmv) FROM account_sales), 1) AS share_of_gmv_pct,
           ROUND(AVG(gmv)) AS avg_gmv_per_account
    FROM account_sales
    GROUP BY lead_type
    ORDER BY gmv DESC
) TO 'results/gmv_by_lead_type.csv' (HEADER);
