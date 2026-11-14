-- 04_accounts.sql: what happens after the deal is won (activation, time to first sale, GMV).
-- Observation limits: effective end of order data = 2018-08-28 (see params). Accounts are only included
-- in an N-day metric if won_date + N days <= data end (no right-censoring inside the metric).

-- name: wins_by_won_month
SELECT DATE_TRUNC('month', won_date)::DATE AS won_month, COUNT(*) AS deals_won FROM raw_deals GROUP BY 1 ORDER BY 1;

-- name: first_order_vs_won_date
SELECT SUM((days_won_to_first_order < 0)::INT) AS first_order_before_won,
       SUM((days_won_to_first_order >= 0)::INT) AS first_order_on_or_after_won,
       SUM((NOT activated)::INT) AS no_order_observed
FROM fact_account;

-- name: activation_overall
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params))   -- 90d observable
SELECT COUNT(*) AS accounts,
       SUM((activated AND days_won_to_first_order <= 30)::INT) AS act_30d,
       SUM((activated AND days_won_to_first_order <= 60)::INT) AS act_60d,
       SUM((activated AND days_won_to_first_order <= 90)::INT) AS act_90d,
       ROUND(100.0*SUM((activated AND days_won_to_first_order <= 90)::INT)/COUNT(*),1) AS act_90d_pct,
       ROUND(MEDIAN(CASE WHEN activated THEN days_won_to_first_order END),0) AS median_days_to_first_order
FROM base;

-- name: activation_by_segment
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params))
SELECT business_segment, COUNT(*) AS accounts,
       SUM((activated AND days_won_to_first_order <= 90)::INT) AS act_90d,
       ROUND(100.0*SUM((activated AND days_won_to_first_order <= 90)::INT)/COUNT(*),1) AS act_90d_pct
FROM base GROUP BY 1 HAVING COUNT(*) >= 15 ORDER BY accounts DESC;

-- name: activation_by_lead_type
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params))
SELECT lead_type, COUNT(*) AS accounts,
       SUM((activated AND days_won_to_first_order <= 90)::INT) AS act_90d,
       ROUND(100.0*SUM((activated AND days_won_to_first_order <= 90)::INT)/COUNT(*),1) AS act_90d_pct
FROM base GROUP BY 1 HAVING COUNT(*) >= 10 ORDER BY accounts DESC;

-- name: activation_by_origin
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params))
SELECT origin, COUNT(*) AS accounts,
       SUM((activated AND days_won_to_first_order <= 90)::INT) AS act_90d,
       ROUND(100.0*SUM((activated AND days_won_to_first_order <= 90)::INT)/COUNT(*),1) AS act_90d_pct
FROM base GROUP BY 1 HAVING COUNT(*) >= 15 ORDER BY accounts DESC;

-- name: gmv_90d_by_segment
-- GMV in the 90 days after won_date, among all won accounts observable for 90 days (zeros included).
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params)),
g AS (SELECT b.mql_id, b.business_segment, COALESCE(SUM(f.price),0) AS gmv90
      FROM base b LEFT JOIN fact_sale_item f
        ON f.seller_id=b.seller_id AND f.order_date >= b.won_date::DATE
       AND f.order_date <= b.won_date::DATE + 90
      GROUP BY 1,2)
SELECT business_segment, COUNT(*) AS accounts, ROUND(SUM(gmv90),0) AS gmv90_total,
       ROUND(AVG(gmv90),0) AS gmv90_per_account,
       ROUND(AVG(gmv90) FILTER (WHERE gmv90>0),0) AS gmv90_per_active_account
FROM g GROUP BY 1 HAVING COUNT(*)>=15 ORDER BY gmv90_total DESC;

-- name: gmv_concentration
-- How concentrated is revenue among the activated accounts? (Lorenz-style: top decile share)
WITH a AS (SELECT gmv, NTILE(10) OVER (ORDER BY gmv DESC) AS decile FROM fact_account WHERE activated)
SELECT decile, COUNT(*) AS accounts, ROUND(SUM(gmv),0) AS gmv,
       ROUND(100.0*SUM(gmv)/SUM(SUM(gmv)) OVER (),1) AS share_pct
FROM a GROUP BY 1 ORDER BY 1;
