-- =============================================================================
-- 04_transformations.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Dedup, normalise, and build the master staging views
--           used by analysis queries and Power BI import
-- Platform: MySQL 8.0
-- Run after: 03_data_quality_checks.sql
-- =============================================================================

USE marketing_analytics;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1 : Deduplicated ad_spend view
--          Removes 7 exact-duplicate rows using ROW_NUMBER partitioned over
--          all 6 business columns.  Keeps only the first occurrence.
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_ad_spend_dedup;

CREATE VIEW vw_ad_spend_dedup AS
WITH dedup AS (
    SELECT
        id,
        date,
        channel,
        campaign,
        impressions,
        clicks,
        spend,
        -- Normalise channel name to snake_case to match signups.channel
        LOWER(REPLACE(channel, ' ', '_'))  AS channel_key,
        -- Month string for time-series joins
        DATE_FORMAT(date, '%Y-%m')         AS month_key,
        ROW_NUMBER() OVER (
            PARTITION BY date, channel, campaign, impressions, clicks, spend
            ORDER BY id
        ) AS rn
    FROM ad_spend_raw
)
SELECT
    id,
    date,
    channel,
    channel_key,
    campaign,
    impressions,
    clicks,
    spend,
    month_key
FROM dedup
WHERE rn = 1;

-- Verify dedup count
SELECT 'vw_ad_spend_dedup row count' AS check_name, COUNT(*) AS result, 1039 AS expected
FROM vw_ad_spend_dedup;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2 : Enriched signups view
--          Adds helper flags and month key
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_signups_enriched;

CREATE VIEW vw_signups_enriched AS
SELECT
    user_id,
    signup_date,
    channel,
    COALESCE(campaign, 'unpaid')                                     AS campaign,
    subscription_start_date,
    plan,
    revenue_first_90_days,
    -- Boolean: 1 = became a paying Gold subscriber
    (subscription_start_date IS NOT NULL)                            AS is_paid_customer,
    -- Channel type for filtering
    CASE WHEN channel IN ('organic', 'referral') THEN 'unpaid'
         ELSE 'paid'
    END                                                              AS channel_type,
    DATE_FORMAT(signup_date, '%Y-%m')                                AS month_key
FROM signups_raw;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3 : Campaign-level ad spend aggregated to month grain
--          This is the correct grain for joining to the signups table
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_ad_spend_monthly;

CREATE VIEW vw_ad_spend_monthly AS
SELECT
    month_key,
    channel_key,
    campaign,
    SUM(impressions)    AS total_impressions,
    SUM(clicks)         AS total_clicks,
    SUM(spend)          AS total_spend,
    COUNT(DISTINCT date) AS active_days
FROM vw_ad_spend_dedup
GROUP BY month_key, channel_key, campaign;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4 : Campaign-level signups aggregated to month grain
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_signups_monthly;

CREATE VIEW vw_signups_monthly AS
SELECT
    month_key,
    channel                          AS channel_key,
    COALESCE(campaign, 'unpaid')     AS campaign,
    COUNT(user_id)                   AS total_signups,
    SUM(is_paid_customer)            AS paying_customers,
    SUM(revenue_first_90_days)       AS total_revenue_90d
FROM vw_signups_enriched
GROUP BY month_key, channel, campaign;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 5 : Master campaign performance view (PAID only, full period)
--          Joined on channel_key + campaign across all months
--          This is the PRIMARY view for Power BI import
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_campaign_performance;

CREATE VIEW vw_campaign_performance AS
SELECT
    a.channel_key,
    a.campaign,
    -- Spend metrics
    SUM(a.total_spend)                                                   AS total_spend,
    SUM(a.total_impressions)                                             AS total_impressions,
    SUM(a.total_clicks)                                                  AS total_clicks,
    SUM(a.active_days)                                                   AS total_active_days,
    -- Click efficiency
    ROUND(SUM(a.total_clicks) / NULLIF(SUM(a.total_impressions), 0), 6) AS ctr,
    ROUND(SUM(a.total_spend)  / NULLIF(SUM(a.total_clicks), 0), 2)     AS cpc,
    -- Signup & conversion outcomes
    SUM(s.total_signups)                                                 AS total_signups,
    SUM(s.paying_customers)                                              AS paying_customers,
    -- KPIs
    ROUND(SUM(s.paying_customers) / NULLIF(SUM(s.total_signups), 0), 4) AS conversion_rate,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.total_signups), 0), 2)     AS cost_per_signup,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.paying_customers), 0), 2)  AS cac,
    -- Revenue & ROAS
    SUM(s.total_revenue_90d)                                             AS total_revenue_90d,
    ROUND(SUM(s.total_revenue_90d) / NULLIF(SUM(a.total_spend), 0), 4) AS roas
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
GROUP BY a.channel_key, a.campaign
ORDER BY total_spend DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 6 : Monthly trend view (all paid campaigns combined by channel)
--          Used for time-series charts in Power BI
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_monthly_channel_trend;

CREATE VIEW vw_monthly_channel_trend AS
SELECT
    a.month_key,
    a.channel_key,
    SUM(a.total_spend)                                                    AS total_spend,
    SUM(a.total_impressions)                                              AS total_impressions,
    SUM(a.total_clicks)                                                   AS total_clicks,
    SUM(s.total_signups)                                                  AS total_signups,
    SUM(s.paying_customers)                                               AS paying_customers,
    SUM(s.total_revenue_90d)                                              AS total_revenue_90d,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.total_signups), 0), 2)      AS cost_per_signup,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.paying_customers), 0), 2)   AS cac,
    ROUND(SUM(s.paying_customers) / NULLIF(SUM(s.total_signups), 0), 4) AS conversion_rate
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
GROUP BY a.month_key, a.channel_key
ORDER BY a.month_key, a.channel_key;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 7 : Unpaid channels summary view
--          For benchmarking paid performance against organic + referral
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_unpaid_channel_summary;

CREATE VIEW vw_unpaid_channel_summary AS
SELECT
    channel                                                                AS channel_key,
    COUNT(user_id)                                                         AS total_signups,
    SUM(is_paid_customer)                                                  AS paying_customers,
    ROUND(SUM(is_paid_customer) / NULLIF(COUNT(user_id), 0), 4)          AS conversion_rate,
    SUM(revenue_first_90_days)                                             AS total_revenue_90d,
    NULL                                                                   AS total_spend,
    NULL                                                                   AS cac,
    NULL                                                                   AS roas
FROM vw_signups_enriched
WHERE channel IN ('organic', 'referral')
GROUP BY channel;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 8 : Monthly ALL-channels trend (incl. organic + referral)
--          For the funnel trend page in Power BI
-- ─────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS vw_monthly_all_channels;

CREATE VIEW vw_monthly_all_channels AS
SELECT
    month_key,
    channel_key,
    'paid'     AS channel_type,
    SUM(total_spend)      AS total_spend,
    SUM(total_signups)    AS total_signups,
    SUM(paying_customers) AS paying_customers,
    SUM(total_revenue_90d) AS total_revenue_90d
FROM vw_monthly_channel_trend
GROUP BY month_key, channel_key
UNION ALL
SELECT
    month_key,
    channel                                                    AS channel_key,
    'unpaid'                                                   AS channel_type,
    NULL                                                       AS total_spend,
    COUNT(user_id)                                             AS total_signups,
    SUM(is_paid_customer)                                      AS paying_customers,
    SUM(revenue_first_90_days)                                 AS total_revenue_90d
FROM vw_signups_enriched
WHERE channel IN ('organic', 'referral')
GROUP BY month_key, channel
ORDER BY month_key, channel_type, channel_key;

SELECT 'All transformation views created successfully.' AS status;
SELECT 'Views created:' AS note,
       'vw_ad_spend_dedup, vw_signups_enriched, vw_ad_spend_monthly, vw_signups_monthly, vw_campaign_performance, vw_monthly_channel_trend, vw_unpaid_channel_summary, vw_monthly_all_channels'
       AS view_list;
