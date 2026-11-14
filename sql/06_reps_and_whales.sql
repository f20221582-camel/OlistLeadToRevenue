-- 06_reps_and_whales.sql
-- LIMITATION: the deal table only contains WON deals, so rep-level WIN RATES cannot be computed
-- (no lead-assignment denominators). We can only compare volume and downstream account quality.

-- name: sdr_summary
SELECT sdr_id, COUNT(*) AS deals_won,
       ROUND(MEDIAN(days_to_close),0) AS median_days_to_close,
       SUM((activated AND days_won_to_first_order<=90 AND won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT) AS activated_90d,
       SUM((won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT) AS observable_90d,
       ROUND(100.0*SUM((activated AND days_won_to_first_order<=90 AND won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT)
             / NULLIF(SUM((won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT),0),1) AS act_90d_pct,
       ROUND(SUM(gmv),0) AS lifetime_gmv
FROM fact_account GROUP BY 1 ORDER BY deals_won DESC LIMIT 12;

-- name: sr_summary
SELECT sr_id, COUNT(*) AS deals_won,
       ROUND(MEDIAN(days_to_close),0) AS median_days_to_close,
       ROUND(100.0*SUM((activated AND days_won_to_first_order<=90 AND won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT)
             / NULLIF(SUM((won_date::DATE<=(SELECT obs90_cutoff FROM params))::INT),0),1) AS act_90d_pct,
       ROUND(SUM(gmv),0) AS lifetime_gmv
FROM fact_account GROUP BY 1 ORDER BY deals_won DESC;

-- name: rep_counts
SELECT COUNT(DISTINCT sdr_id) AS sdrs, COUNT(DISTINCT sr_id) AS srs FROM fact_account;

-- name: top_decile_profile
-- Profile of the top-10% GMV accounts among activated accounts vs the rest.
WITH r AS (SELECT *, NTILE(10) OVER (ORDER BY gmv DESC) AS decile FROM fact_account WHERE activated)
SELECT lead_type, COUNT(*) AS activated_accounts, SUM((decile=1)::INT) AS in_top_decile,
       ROUND(100.0*SUM((decile=1)::INT)/COUNT(*),1) AS pct_in_top_decile,
       ROUND(SUM(gmv),0) AS gmv, ROUND(AVG(gmv),0) AS gmv_per_activated
FROM r GROUP BY 1 HAVING COUNT(*)>=10 ORDER BY gmv DESC;

-- name: top_segments_by_lifetime_gmv
SELECT business_segment, COUNT(*) AS won_accounts, SUM(activated::INT) AS activated,
       ROUND(SUM(gmv),0) AS lifetime_gmv, ROUND(100.0*SUM(gmv)/SUM(SUM(gmv)) OVER (),1) AS share_pct
FROM fact_account GROUP BY 1 HAVING COUNT(*)>=15 ORDER BY lifetime_gmv DESC;

-- name: gmv_totals
SELECT COUNT(*) AS activated_accounts, ROUND(SUM(gmv),0) AS total_gmv, ROUND(AVG(gmv),0) AS mean_gmv,
       ROUND(MEDIAN(gmv),0) AS median_gmv FROM fact_account WHERE activated;
