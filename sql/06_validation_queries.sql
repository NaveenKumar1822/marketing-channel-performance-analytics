-- =============================================================================
-- 06_validation_queries.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Cross-validate SQL totals against Excel workbook figures
--           Run after 05_business_analysis.sql; compare to Excel Sheet "5_Validation"
-- Platform: MySQL 8.0
-- Last updated: corrected display_network last date (2025-05-14, not 2025-05-29)
--               removed malformed V7 block; kept clean V7 only
-- =============================================================================

USE marketing_analytics;

-- ─────────────────────────────────────────────────────────────────────────────
-- V1 : Total spend validation
--      SQL total (deduped) should match Excel cell B3 on Validation sheet
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V1: Total deduped spend' AS validation_check,
       ROUND(SUM(total_spend), 2) AS sql_value,
       124886.22                  AS excel_expected,
       ABS(ROUND(SUM(total_spend), 2) - 124886.22) AS difference
FROM vw_campaign_performance;

-- ─────────────────────────────────────────────────────────────────────────────
-- V2 : Total signups (paid channels)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V2: Total paid signups' AS validation_check,
       SUM(total_signups)       AS sql_value,
       14266                    AS excel_expected,
       ABS(SUM(total_signups) - 14266) AS difference
FROM vw_campaign_performance;

-- ─────────────────────────────────────────────────────────────────────────────
-- V3 : Total paying customers (paid channels)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V3: Total paying customers' AS validation_check,
       SUM(paying_customers)        AS sql_value,
       1698                         AS excel_expected,
       ABS(SUM(paying_customers) - 1698) AS difference
FROM vw_campaign_performance;

-- ─────────────────────────────────────────────────────────────────────────────
-- V4 : brand_search CAC
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V4: brand_search CAC' AS validation_check,
       ROUND(cac, 2)          AS sql_value,
       21.93                  AS excel_expected,
       ABS(ROUND(cac, 2) - 21.93) AS difference
FROM vw_campaign_performance
WHERE campaign = 'brand_search';

-- ─────────────────────────────────────────────────────────────────────────────
-- V5 : prospecting_video conversion rate (4 d.p. to avoid rounding ambiguity)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V5: prospecting_video CVR (4dp)' AS validation_check,
       ROUND(conversion_rate, 4)          AS sql_value,
       0.0329                             AS excel_expected,
       ABS(ROUND(conversion_rate, 4) - 0.0329) AS difference
FROM vw_campaign_performance
WHERE campaign = 'prospecting_video';
-- Note: value is 0.032850; rounds to 0.0329 at 4dp, 0.03 at 2dp

-- ─────────────────────────────────────────────────────────────────────────────
-- V6 : brand_search ROAS
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V6: brand_search ROAS' AS validation_check,
       ROUND(roas, 2)          AS sql_value,
       1.91                    AS excel_expected,
       ABS(ROUND(roas, 2) - 1.91) AS difference
FROM vw_campaign_performance
WHERE campaign = 'brand_search';

-- ─────────────────────────────────────────────────────────────────────────────
-- V7 : Referral channel conversion rate
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V7: referral CVR (%)' AS validation_check,
       ROUND(SUM(is_paid_customer) / COUNT(*) * 100, 2) AS sql_value_pct,
       19.94                                             AS excel_expected_pct,
       ABS(ROUND(SUM(is_paid_customer) / COUNT(*) * 100, 2) - 19.94) AS difference
FROM vw_signups_enriched
WHERE channel = 'referral';

-- ─────────────────────────────────────────────────────────────────────────────
-- V8 : Total revenue (all channels)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V8: Total revenue all channels' AS validation_check,
       ROUND(SUM(revenue_first_90_days), 2) AS sql_value,
       93392.27                              AS excel_expected,
       ABS(ROUND(SUM(revenue_first_90_days), 2) - 93392.27) AS difference
FROM signups_raw;

-- ─────────────────────────────────────────────────────────────────────────────
-- V9 : display_network last active date
--      CORRECTED: actual last date is 2025-05-14, not 2025-05-29
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V9: display_network last date' AS validation_check,
       MAX(date)                       AS sql_value,
       '2025-05-14'                    AS excel_expected
FROM vw_ad_spend_dedup
WHERE campaign = 'display_network';
-- Expected: 2025-05-14  (campaign ran 134 active days; ended mid-May, not end-May)

-- ─────────────────────────────────────────────────────────────────────────────
-- V10 : Row count after dedup
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V10: ad_spend rows after dedup' AS validation_check,
       COUNT(*)                          AS sql_value,
       1039                              AS excel_expected,
       ABS(COUNT(*) - 1039)              AS difference
FROM vw_ad_spend_dedup;

-- ─────────────────────────────────────────────────────────────────────────────
-- V11 : display_network active days
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V11: display_network active days' AS validation_check,
       COUNT(DISTINCT date)               AS sql_value,
       134                                AS excel_expected,
       ABS(COUNT(DISTINCT date) - 134)    AS difference
FROM vw_ad_spend_dedup
WHERE campaign = 'display_network';
-- All other campaigns ran 181 days (full Jan–Jun period)
-- display_network: 134 active days only (Jan 1 – May 14 2025)

-- ─────────────────────────────────────────────────────────────────────────────
-- V12 : paid_search channel CAC
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'V12: paid_search channel CAC' AS validation_check,
       ROUND(SUM(total_spend) / NULLIF(SUM(paying_customers), 0), 2) AS sql_value,
       51.43                                                           AS excel_expected,
       ABS(ROUND(SUM(total_spend) / NULLIF(SUM(paying_customers), 0), 2) - 51.43) AS difference
FROM vw_campaign_performance
WHERE channel_key = 'paid_search';

-- ─────────────────────────────────────────────────────────────────────────────
-- Summary
-- ─────────────────────────────────────────────────────────────────────────────

SELECT 'Run V1–V12. Difference = 0 means SQL matches Excel.' AS instruction,
       'Any difference > 0.02 requires investigation.'        AS threshold_note;
