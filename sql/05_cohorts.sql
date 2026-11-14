-- 05_cohorts.sql: seller cohorts by month won; share of the cohort with a valid sale in each
-- month since won. Only fully observed calendar months are shown (effective end of order data 2018-08-28,
-- so months up to 2018-07 are complete).

-- name: cohort_activity
WITH cohort AS (
  SELECT seller_id, DATE_TRUNC('month', won_date)::DATE AS cohort_month FROM fact_account
  WHERE won_date >= TIMESTAMP '2018-01-01' AND won_date < TIMESTAMP '2018-06-01'),
size AS (SELECT cohort_month, COUNT(*) AS cohort_size FROM cohort GROUP BY 1),
act AS (
  SELECT c.cohort_month,
         DATE_DIFF('month', c.cohort_month, DATE_TRUNC('month', f.order_date)::DATE) AS months_since_won,
         COUNT(DISTINCT c.seller_id) AS active_sellers, SUM(f.price) AS gmv
  FROM cohort c JOIN fact_sale_item f USING (seller_id)
  WHERE f.order_date >= c.cohort_month AND f.order_date < (SELECT last_full_month_end FROM params)
  GROUP BY 1,2)
SELECT a.cohort_month, s.cohort_size, a.months_since_won, a.active_sellers,
       ROUND(100.0*a.active_sellers/s.cohort_size,1) AS pct_of_cohort_active, ROUND(a.gmv,0) AS gmv
FROM act a JOIN size s USING (cohort_month)
WHERE a.months_since_won >= 0 ORDER BY 1,3;

-- name: cohort_pivot_pct
WITH cohort AS (
  SELECT seller_id, DATE_TRUNC('month', won_date)::DATE AS cohort_month FROM fact_account
  WHERE won_date >= TIMESTAMP '2018-01-01' AND won_date < TIMESTAMP '2018-06-01'),
size AS (SELECT cohort_month, COUNT(*) AS n FROM cohort GROUP BY 1),
act AS (
  SELECT c.cohort_month, DATE_DIFF('month', c.cohort_month, DATE_TRUNC('month', f.order_date)::DATE) AS m,
         COUNT(DISTINCT c.seller_id) AS a
  FROM cohort c JOIN fact_sale_item f USING (seller_id)
  WHERE f.order_date >= c.cohort_month AND f.order_date < (SELECT last_full_month_end FROM params) GROUP BY 1,2)
SELECT s.cohort_month, s.n AS cohort_size,
  ROUND(100.0*MAX(CASE WHEN m=0 THEN a END)/s.n,1) AS m0,
  ROUND(100.0*MAX(CASE WHEN m=1 THEN a END)/s.n,1) AS m1,
  ROUND(100.0*MAX(CASE WHEN m=2 THEN a END)/s.n,1) AS m2,
  ROUND(100.0*MAX(CASE WHEN m=3 THEN a END)/s.n,1) AS m3,
  ROUND(100.0*MAX(CASE WHEN m=4 THEN a END)/s.n,1) AS m4,
  ROUND(100.0*MAX(CASE WHEN m=5 THEN a END)/s.n,1) AS m5,
  ROUND(100.0*MAX(CASE WHEN m=6 THEN a END)/s.n,1) AS m6
FROM size s LEFT JOIN act USING (cohort_month) GROUP BY s.cohort_month, s.n ORDER BY 1;

-- name: retention_of_activated
-- Of sellers active in month k (k>=1), what share is active again in month k+1? (all cohorts pooled,
-- calendar months 2018-01..2018-07 only)
WITH m AS (
  SELECT seller_id, DATE_TRUNC('month', order_date)::DATE AS mth
  FROM fact_sale_item WHERE order_date >= DATE '2018-01-01' AND order_date < (SELECT last_full_month_end FROM params)
  AND seller_id IN (SELECT seller_id FROM fact_account) GROUP BY 1,2)
SELECT a.mth AS month, COUNT(*) AS active_sellers,
       COUNT(b.seller_id) AS active_next_month,
       ROUND(100.0*COUNT(b.seller_id)/COUNT(*),1) AS next_month_retention_pct
FROM m a LEFT JOIN m b ON b.seller_id=a.seller_id AND b.mth = a.mth + INTERVAL 1 MONTH
WHERE a.mth < DATE '2018-07-01' GROUP BY 1 ORDER BY 1;
