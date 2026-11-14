-- 02_model.sql: analytic layer. Mirrors a CRM view: leads -> deals(accounts) -> usage (orders).
-- Definitions (documented so every number is traceable):
--   valid sale  = order_status NOT IN ('canceled','unavailable')
--   GMV         = SUM(item price) over valid sales (freight excluded)
--   activated   = deal seller has >= 1 valid-sale item in the marketplace data
--   NOTE: marketplace data is a sample; "not observed" != "never sold".
--   DATA END: order volume falls from ~70/day to ~14/day on 2018-08-29 and Sep-Oct 2018 hold only
--   20 orders in total, so the effective end of the data is 2018-08-28 (see params below).

CREATE OR REPLACE TABLE params AS SELECT
  DATE '2018-08-28'  AS data_end_excl,        -- orders on/after this date are ignored (sparse tail)
  DATE '2018-05-29'  AS obs90_cutoff,         -- won on/before this date => 90 days of order data observable
  DATE '2018-08-01'  AS last_full_month_end;  -- calendar months before this date are complete

CREATE OR REPLACE VIEW dim_lead AS
SELECT m.mql_id,
       m.first_contact_date,
       DATE_TRUNC('month', m.first_contact_date)::DATE AS contact_month,
       m.landing_page_id,
       COALESCE(m.origin, 'unknown') AS origin,            -- 60 NULL origins folded into 'unknown'
       (m.origin IS NULL) AS origin_was_null,
       d.seller_id, d.sdr_id, d.sr_id, d.won_date,
       d.business_segment, d.lead_type, d.lead_behaviour_profile, d.business_type,
       (d.mql_id IS NOT NULL) AS is_won,
       DATE_DIFF('day', m.first_contact_date, d.won_date::DATE) AS days_to_close
FROM raw_mql m LEFT JOIN raw_deals d USING (mql_id);

CREATE OR REPLACE VIEW fact_sale_item AS
SELECT i.seller_id, i.order_id, i.price, i.freight_value,
       o.order_purchase_timestamp::DATE AS order_date, o.order_status
FROM raw_items i JOIN raw_orders o USING (order_id)
WHERE o.order_status NOT IN ('canceled','unavailable')
  AND o.order_purchase_timestamp::DATE < (SELECT data_end_excl FROM params);

CREATE OR REPLACE VIEW fact_account AS      -- one row per won account (seller)
WITH usage AS (
  SELECT seller_id, MIN(order_date) AS first_order_date,
         COUNT(DISTINCT order_id) AS orders, SUM(price) AS gmv
  FROM fact_sale_item GROUP BY seller_id)
SELECT l.mql_id, l.seller_id, l.won_date, l.contact_month, l.origin, l.landing_page_id,
       l.business_segment, l.lead_type, l.lead_behaviour_profile, l.business_type,
       l.sdr_id, l.sr_id, l.days_to_close,
       u.first_order_date,
       COALESCE(u.orders,0) AS orders,
       COALESCE(u.gmv,0) AS gmv,
       (u.seller_id IS NOT NULL) AS activated,
       DATE_DIFF('day', l.won_date::DATE, u.first_order_date) AS days_won_to_first_order
FROM dim_lead l LEFT JOIN usage u ON u.seller_id = l.seller_id
WHERE l.is_won;
