-- Step 3: the funnel, from lead to won deal.

-- One row per lead. won_90 is 1 if the deal was won within 90 days of first contact.
-- (LEFT JOIN keeps leads that never became a deal. For them the deal columns are empty.)
CREATE OR REPLACE TABLE lead_status AS
SELECT l.mql_id,
       l.first_contact_date,
       l.landing_page_id,
       COALESCE(l.origin, 'unknown') AS origin,
       d.won_date::DATE AS won_date,
       d.won_date::DATE - l.first_contact_date AS days_to_win,
       CASE WHEN d.mql_id IS NOT NULL AND d.won_date::DATE - l.first_contact_date <= 90
            THEN 1 ELSE 0 END AS won_90
FROM leads l
LEFT JOIN deals d ON l.mql_id = d.mql_id;

-- Win rate by month of first contact, for ALL leads.
-- It looks bad before 2018 because deals are only recorded from Dec 2017.
-- So the rest of the analysis only uses leads first contacted Jan-May 2018.
COPY (
    SELECT strftime(first_contact_date, '%Y-%m') AS month,
           COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * SUM(won_90) / COUNT(*), 1) AS win_rate_pct
    FROM lead_status
    GROUP BY 1
    ORDER BY 1
) TO 'results/win_rate_by_month.csv' (HEADER);

-- Leads we analyse: first contact between 1 Jan and 31 May 2018.
CREATE OR REPLACE TABLE window_leads AS
SELECT * FROM lead_status
WHERE first_contact_date BETWEEN '2018-01-01' AND '2018-05-31';

-- Overall funnel
COPY (
    SELECT COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * SUM(won_90) / COUNT(*), 1) AS win_rate_pct,
           MEDIAN(days_to_win) AS median_days_to_win
    FROM window_leads
) TO 'results/funnel.csv' (HEADER);

-- Win rate by origin (where the lead came from)
COPY (
    SELECT origin,
           COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * SUM(won_90) / COUNT(*), 1) AS win_rate_pct
    FROM window_leads
    GROUP BY origin
    ORDER BY leads DESC
) TO 'results/win_rate_by_origin.csv' (HEADER);

-- Win rate by landing page (only pages with at least 100 leads, so rates are not noise)
COPY (
    SELECT landing_page_id,
           COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * SUM(won_90) / COUNT(*), 1) AS win_rate_pct
    FROM window_leads
    GROUP BY landing_page_id
    HAVING COUNT(*) >= 100
    ORDER BY leads DESC
) TO 'results/win_rate_by_landing_page.csv' (HEADER);

-- The two best pages together vs all the other pages
COPY (
    SELECT CASE WHEN landing_page_id IN ('b76ef37428e6799c421989521c0e5077',
                                         '22c29808c4f815213303f8933030604c')
                THEN 'top 2 pages' ELSE 'all other pages' END AS page_group,
           COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * SUM(won_90) / COUNT(*), 1) AS win_rate_pct
    FROM window_leads
    GROUP BY 1
) TO 'results/win_rate_top2_pages.csv' (HEADER);

-- Social and email leads: share of all leads vs share of all wins
COPY (
    SELECT CASE WHEN origin IN ('social', 'email') THEN 'social + email' ELSE 'other origins' END AS origin_group,
           COUNT(*) AS leads,
           SUM(won_90) AS won_90,
           ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM window_leads), 1) AS pct_of_leads,
           ROUND(100.0 * SUM(won_90) / (SELECT SUM(won_90) FROM window_leads), 1) AS pct_of_wins
    FROM window_leads
    GROUP BY 1
) TO 'results/social_email_share.csv' (HEADER);
