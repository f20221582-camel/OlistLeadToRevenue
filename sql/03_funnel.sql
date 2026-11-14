-- 03_funnel.sql
-- DATA CAVEAT: closed deals are only recorded from 2017-12-05. Leads first contacted before
-- 2018-01-01 therefore show artificially low win rates (see conv_by_contact_month).
-- All conversion comparisons use the "complete window": leads first contacted 2018-01-01..2018-05-31,
-- each with >= 167 days of follow-up, measured as "won within 90 days of first contact".

-- name: funnel_all_leads
SELECT 1 AS step, 'Marketing qualified lead' AS stage, COUNT(*) AS n FROM dim_lead
UNION ALL SELECT 2, 'Closed deal (won)', COUNT(*) FROM dim_lead WHERE is_won
UNION ALL SELECT 3, 'Activated (>=1 valid sale observed)', COUNT(*) FROM fact_account WHERE activated
ORDER BY step;

-- name: funnel_window
WITH w AS (SELECT * FROM dim_lead WHERE first_contact_date >= DATE '2018-01-01'),
     won AS (SELECT a.* FROM fact_account a JOIN w USING (mql_id))
SELECT 1 AS step, 'MQL (first contact Jan-May 2018)' AS stage, (SELECT COUNT(*) FROM w) AS n
UNION ALL SELECT 2, 'Won within 90 days', (SELECT COUNT(*) FROM w WHERE is_won AND days_to_close<=90)
UNION ALL SELECT 3, 'Won (any time)', (SELECT COUNT(*) FROM w WHERE is_won)
UNION ALL SELECT 4, 'Activated (>=1 valid sale observed)', (SELECT COUNT(*) FROM won WHERE activated)
ORDER BY step;

-- name: conv_by_contact_month
SELECT contact_month, COUNT(*) AS leads, SUM(is_won::INT) AS won,
       ROUND(100.0*SUM(is_won::INT)/COUNT(*),2) AS win_rate_pct,
       SUM((is_won AND days_to_close<=90)::INT) AS won_within_90d
FROM dim_lead GROUP BY 1 ORDER BY 1;

-- name: conv_by_origin
SELECT origin, COUNT(*) AS leads,
       SUM((is_won AND days_to_close<=90)::INT) AS won_90d,
       ROUND(100.0*SUM((is_won AND days_to_close<=90)::INT)/COUNT(*),2) AS win_rate_90d_pct,
       ROUND(MEDIAN(CASE WHEN is_won THEN days_to_close END),0) AS median_days_to_close
FROM dim_lead WHERE first_contact_date >= DATE '2018-01-01'
GROUP BY origin ORDER BY leads DESC;

-- name: origin_mix_by_period
SELECT origin,
       SUM((first_contact_date <  DATE '2018-01-01')::INT) AS leads_2017,
       SUM((first_contact_date >= DATE '2018-01-01')::INT) AS leads_2018
FROM dim_lead GROUP BY 1 ORDER BY 3 DESC;

-- name: landing_pages_window
SELECT landing_page_id, COUNT(*) AS leads,
       SUM((is_won AND days_to_close<=90)::INT) AS won_90d,
       ROUND(100.0*SUM((is_won AND days_to_close<=90)::INT)/COUNT(*),2) AS win_rate_90d_pct
FROM dim_lead WHERE first_contact_date >= DATE '2018-01-01'
GROUP BY 1 HAVING COUNT(*)>=100 ORDER BY leads DESC;

-- name: landing_page_concentration
WITH lp AS (SELECT landing_page_id, COUNT(*) leads, SUM((is_won AND days_to_close<=90)::INT) won
            FROM dim_lead WHERE first_contact_date >= DATE '2018-01-01' GROUP BY 1)
SELECT COUNT(*) AS n_pages, SUM(leads) AS leads, SUM(won) AS won_90d,
       SUM(CASE WHEN leads>=100 THEN leads END) AS leads_on_100plus_pages,
       SUM(CASE WHEN leads>=100 THEN won END) AS won_on_100plus_pages
FROM lp;

-- name: days_to_close_distribution
SELECT MIN(days_to_close) AS min_d, ROUND(QUANTILE_CONT(days_to_close,0.25),0) AS p25,
       ROUND(MEDIAN(days_to_close),0) AS p50, ROUND(QUANTILE_CONT(days_to_close,0.75),0) AS p75,
       ROUND(QUANTILE_CONT(days_to_close,0.9),0) AS p90, MAX(days_to_close) AS max_d,
       SUM((days_to_close<0)::INT) AS negative_days
FROM dim_lead WHERE is_won AND first_contact_date >= DATE '2018-01-01';
