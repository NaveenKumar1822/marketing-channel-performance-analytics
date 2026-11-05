-- =============================================================================
-- 03_data_quality_checks.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Comprehensive data quality audit of both raw tables
-- Platform: MySQL 8.0
-- Run after: 02_table_creation.sql + CSV imports
-- =============================================================================

USE marketing_analytics;

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1 : ROW COUNTS
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'ad_spend_raw row count' AS check_name,
       COUNT(*)                 AS result,
       1046                     AS expected
FROM ad_spend_raw;

SELECT 'signups_raw row count' AS check_name,
       COUNT(*)                AS result,
       18840                   AS expected
FROM signups_raw;

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2 : NULL CHECKS — ad_spend_raw
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'ad_spend NULL date'        AS check_name, COUNT(*) AS null_count FROM ad_spend_raw WHERE date IS NULL
UNION ALL
SELECT 'ad_spend NULL channel',     COUNT(*) FROM ad_spend_raw WHERE channel IS NULL
UNION ALL
SELECT 'ad_spend NULL campaign',    COUNT(*) FROM ad_spend_raw WHERE campaign IS NULL
UNION ALL
SELECT 'ad_spend NULL impressions', COUNT(*) FROM ad_spend_raw WHERE impressions IS NULL
UNION ALL
SELECT 'ad_spend NULL clicks',      COUNT(*) FROM ad_spend_raw WHERE clicks IS NULL
UNION ALL
SELECT 'ad_spend NULL spend',       COUNT(*) FROM ad_spend_raw WHERE spend IS NULL;
-- Expected: all zeros

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3 : NULL CHECKS — signups_raw
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'signups NULL user_id'                AS check_name, COUNT(*) AS null_count FROM signups_raw WHERE user_id IS NULL
UNION ALL
SELECT 'signups NULL signup_date',           COUNT(*) FROM signups_raw WHERE signup_date IS NULL
UNION ALL
SELECT 'signups NULL channel',               COUNT(*) FROM signups_raw WHERE channel IS NULL
UNION ALL
SELECT 'signups NULL campaign (expected)',   COUNT(*) FROM signups_raw WHERE campaign IS NULL
UNION ALL
SELECT 'signups NULL subscription_start',   COUNT(*) FROM signups_raw WHERE subscription_start_date IS NULL
UNION ALL
SELECT 'signups NULL plan',                  COUNT(*) FROM signups_raw WHERE plan IS NULL
UNION ALL
SELECT 'signups NULL revenue_first_90d',     COUNT(*) FROM signups_raw WHERE revenue_first_90_days IS NULL;
-- Expected: campaign NULLs = 4574 (organic+referral), subscription NULLs = plan NULLs = 16585

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4 : DUPLICATE CHECKS — ad_spend_raw
-- ─────────────────────────────────────────────────────────────────────────────

-- 4a. Full exact duplicates (all 6 business columns identical)
SELECT 'ad_spend exact duplicates (all 6 cols)' AS check_name,
       COUNT(*) - COUNT(DISTINCT CONCAT(date,'|',channel,'|',campaign,'|',
                                         impressions,'|',clicks,'|',spend)) AS duplicate_rows
FROM ad_spend_raw;
-- Expected: 7

-- 4b. Which rows are duplicated?
SELECT date, channel, campaign, impressions, clicks, spend,
       COUNT(*) AS occurrence_count
FROM ad_spend_raw
GROUP BY date, channel, campaign, impressions, clicks, spend
HAVING COUNT(*) > 1
ORDER BY date, channel, campaign;
-- Expected: 7 duplicate pairs (some campaigns appear 2x on specific dates)

-- 4c. Duplicate check — signups (user_id should be unique)
SELECT 'signups duplicate user_id' AS check_name,
       COUNT(user_id) - COUNT(DISTINCT user_id) AS duplicate_count
FROM signups_raw;
-- Expected: 0

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5 : DATE RANGE AND CONTINUITY
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'ad_spend date range' AS check_name,
       MIN(date)             AS min_date,
       MAX(date)             AS max_date,
       COUNT(DISTINCT date)  AS distinct_days
FROM ad_spend_raw;
-- Expected: 2025-01-01 to 2025-06-30, 181 distinct days

SELECT 'signups date range' AS check_name,
       MIN(signup_date)           AS min_date,
       MAX(signup_date)           AS max_date,
       COUNT(DISTINCT signup_date) AS distinct_days
FROM signups_raw;
-- Expected: 2025-01-01 to 2025-06-30, 181 distinct days

-- 5b. Display network activity — does it stop before June 30?
SELECT 'display_network active date range' AS check_name,
       MIN(date) AS first_day,
       MAX(date) AS last_day,
       COUNT(DISTINCT date) AS active_days
FROM ad_spend_raw
WHERE campaign = 'display_network';
-- Expected: last_day = 2025-05-14, active_days = 134; confirms campaign ended mid-May
-- (not 2025-05-29 — verified against actual data: 134 active days Jan 1 – May 14)

-- 5c. Campaign activity summary — display_network ran 134 days; all others ran 181 days
SELECT campaign,
       COUNT(DISTINCT date) AS active_days,
       MIN(date)            AS first_date,
       MAX(date)            AS last_date
FROM ad_spend_raw
GROUP BY campaign
ORDER BY active_days DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6 : DISTINCT VALUE CHECKS
-- ─────────────────────────────────────────────────────────────────────────────

-- 6a. Channels in ad_spend (expect 4)
SELECT DISTINCT channel FROM ad_spend_raw ORDER BY channel;

-- 6b. Channels in signups (expect 6, incl. organic + referral)
SELECT DISTINCT channel FROM signups_raw ORDER BY channel;

-- 6c. Channel key mismatch check — after normalisation
SELECT DISTINCT
       channel                                              AS ad_channel_raw,
       LOWER(REPLACE(channel, ' ', '_'))                   AS channel_key,
       LOWER(REPLACE(channel, ' ', '_')) IN (
           SELECT DISTINCT channel FROM signups_raw
       )                                                    AS matches_signups
FROM ad_spend_raw
ORDER BY channel;
-- Expected: all 4 paid channels should have matches_signups = 1

-- 6d. Campaigns in ad_spend vs signups — must match exactly
SELECT a.campaign AS ad_campaign,
       s.campaign AS sig_campaign,
       CASE WHEN s.campaign IS NULL THEN 'ONLY IN AD_SPEND'
            WHEN a.campaign IS NULL THEN 'ONLY IN SIGNUPS'
            ELSE 'MATCHED'
       END AS match_status
FROM (SELECT DISTINCT campaign FROM ad_spend_raw) a
LEFT JOIN (SELECT DISTINCT campaign FROM signups_raw WHERE campaign IS NOT NULL) s
  ON a.campaign = s.campaign
UNION ALL
SELECT a.campaign, s.campaign,
       CASE WHEN a.campaign IS NULL THEN 'ONLY IN SIGNUPS' ELSE 'MATCHED' END
FROM (SELECT DISTINCT campaign FROM signups_raw WHERE campaign IS NOT NULL) s
LEFT JOIN (SELECT DISTINCT campaign FROM ad_spend_raw) a
  ON a.campaign = s.campaign
WHERE a.campaign IS NULL;
-- Expected: all 6 campaigns MATCHED; no orphans on either side

-- 6e. Plan values in signups
SELECT plan, COUNT(*) AS user_count
FROM signups_raw
GROUP BY plan
ORDER BY user_count DESC;
-- Expected: NULL (non-subscribers), 'monthly', 'annual'

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 7 : NUMERIC RANGE CHECKS
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'ad_spend spend range'      AS check_name, MIN(spend) AS min_val, MAX(spend) AS max_val FROM ad_spend_raw
UNION ALL
SELECT 'ad_spend clicks range',     MIN(clicks), MAX(clicks) FROM ad_spend_raw
UNION ALL
SELECT 'ad_spend impressions range',MIN(impressions), MAX(impressions) FROM ad_spend_raw;

-- Clicks should never exceed impressions
SELECT 'clicks > impressions anomalies' AS check_name, COUNT(*) AS anomaly_count
FROM ad_spend_raw
WHERE clicks > impressions;
-- Expected: 0

-- Negative spend
SELECT 'negative spend rows' AS check_name, COUNT(*) AS anomaly_count
FROM ad_spend_raw
WHERE spend < 0;
-- Expected: 0

-- Revenue range in signups
SELECT 'revenue_first_90d range' AS check_name,
       MIN(revenue_first_90_days) AS min_val,
       MAX(revenue_first_90_days) AS max_val,
       AVG(revenue_first_90_days) AS avg_val
FROM signups_raw;
-- Expected: min=0, max=79.99, avg~4.96

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 8 : CONSISTENCY CHECK — paying customers have revenue
-- ─────────────────────────────────────────────────────────────────────────────

-- Paying customers with zero revenue (shouldn't happen)
SELECT 'Paying customers with 0 revenue' AS check_name, COUNT(*) AS anomaly_count
FROM signups_raw
WHERE subscription_start_date IS NOT NULL
  AND revenue_first_90_days = 0;
-- If > 0, these are edge cases where subscription started after the 90-day window

-- Non-subscribers with non-zero revenue (shouldn't happen)
SELECT 'Non-subscribers with revenue > 0' AS check_name, COUNT(*) AS anomaly_count
FROM signups_raw
WHERE subscription_start_date IS NULL
  AND revenue_first_90_days > 0;
-- Expected: 0

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 9 : SUMMARY TOTALS (for Excel reconciliation)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'Total raw spend'           AS metric, ROUND(SUM(spend), 2)               AS value FROM ad_spend_raw
UNION ALL
SELECT 'Total deduped spend',       ROUND(SUM(spend), 2)
FROM (SELECT DISTINCT date, channel, campaign, impressions, clicks, spend FROM ad_spend_raw) d
UNION ALL
SELECT 'Total signups',             COUNT(*)         FROM signups_raw
UNION ALL
SELECT 'Total paying customers',    SUM(subscription_start_date IS NOT NULL) FROM signups_raw
UNION ALL
SELECT 'Total 90d revenue',         ROUND(SUM(revenue_first_90_days), 2) FROM signups_raw;

SELECT 'Data quality checks complete. Review any anomaly counts above.' AS status;
