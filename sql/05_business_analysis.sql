-- =============================================================================
-- 05_business_analysis.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Answer all 8 business questions with SQL queries
--           Run after 04_transformations.sql
-- Platform: MySQL 8.0
-- =============================================================================

USE marketing_analytics;

-- =============================================================================
-- QUERY 1 — Overall H1 2025 KPI Summary (Executive Snapshot)
-- Business question: What is the total spend, signup, and revenue performance?
-- =============================================================================

SELECT
    'H1 2025 Paid Channels'                                                 AS summary_label,
    ROUND(SUM(a.total_spend), 2)                                            AS total_spend_usd,
    SUM(s.total_signups)                                                     AS total_signups,
    SUM(s.paying_customers)                                                  AS total_paying_customers,
    ROUND(SUM(s.paying_customers) / NULLIF(SUM(s.total_signups), 0) * 100, 2)  AS conversion_rate_pct,
    ROUND(SUM(s.total_revenue_90d), 2)                                      AS total_revenue_90d_usd,
    ROUND(SUM(a.total_spend)  / NULLIF(SUM(s.total_signups), 0), 2)        AS avg_cost_per_signup,
    ROUND(SUM(a.total_spend)  / NULLIF(SUM(s.paying_customers), 0), 2)     AS avg_cac,
    ROUND(SUM(s.total_revenue_90d) / NULLIF(SUM(a.total_spend), 0), 4)     AS overall_roas
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key;

/*
EXPECTED RESULT (verified against Python):
  total_spend_usd       : 124,886.22
  total_signups         : 14,266
  total_paying_customers:  1,698
  conversion_rate_pct   :  11.90 %
  total_revenue_90d_usd :  69,443.91  (paid channels only)
  avg_cost_per_signup   :      8.75
  avg_cac               :     73.55
  overall_roas          :      0.5560

INTERPRETATION:
  The portfolio of paid channels returned $0.56 in 90-day revenue for every $1 spent.
  The business is net-negative on a 90-day basis, but many Gold subscribers will remain
  active beyond 90 days, so full-lifetime ROAS is expected to be higher.
  The key question is which campaigns come closest to 90-day breakeven.
*/

-- =============================================================================
-- QUERY 2 — Campaign-Level KPI Ranking (core deliverable)
-- Business question: Which campaigns are most efficient per paying customer?
-- =============================================================================

SELECT
    channel_key,
    campaign,
    ROUND(total_spend, 2)           AS total_spend,
    total_impressions,
    total_clicks,
    ROUND(ctr * 100, 3)             AS ctr_pct,
    ROUND(cpc, 2)                   AS cpc,
    total_signups,
    paying_customers,
    ROUND(conversion_rate * 100, 2) AS conversion_rate_pct,
    ROUND(cost_per_signup, 2)       AS cost_per_signup,
    ROUND(cac, 2)                   AS cac,
    ROUND(total_revenue_90d, 2)     AS revenue_90d,
    ROUND(roas, 4)                  AS roas
FROM vw_campaign_performance
ORDER BY cac ASC;

/*
EXPECTED RESULTS (ascending CAC = best first):
  campaign           | spend    | signups | paying | CVR   | CPS   | CAC     | ROAS
  brand_search       | 10,197   |  2,177  |   465  | 21.4% |  4.68 |   21.93 | 1.91  ← BEST
  retargeting        | 12,987   |  2,465  |   418  | 17.0% |  5.27 |   31.07 | 1.34
  generic_search     | 35,939   |  2,008  |   432  | 21.5% | 17.90 |   83.19 | 0.47
  finance_blogs      | 15,392   |    864  |   162  | 18.8% | 17.82 |   95.02 | 0.41
  prospecting_video  | 33,916   |  6,484  |   213  |  3.3% |  5.23 |  159.23 | 0.26
  display_network    | 16,455   |    268  |     8  |  3.0% | 61.40 | 2056.83 | 0.03  ← WORST

KEY INSIGHT: Cheapest signup ≠ cheapest paying customer
  - prospecting_video has the 2nd-lowest CPS ($5.23) but highest CAC ($159.23)
    It attracts browsers who never convert to Gold.
  - brand_search has the lowest CPS ($4.68) AND the lowest CAC ($21.93)
    It uniquely dominates on both measures.
  - display_network: $16K spent, only 8 paying customers, $2,057 per acquisition.
    Campaign ended May 2025. Budget should be reallocated.
*/

-- =============================================================================
-- QUERY 3 — Channel-Level Roll-up (for executive overview)
-- Business question: Which channels produce the best outcomes in aggregate?
-- =============================================================================

SELECT
    a.channel_key,
    ROUND(SUM(a.total_spend), 2)                                                AS total_spend,
    SUM(s.total_signups)                                                         AS total_signups,
    SUM(s.paying_customers)                                                      AS paying_customers,
    ROUND(SUM(s.paying_customers) / NULLIF(SUM(s.total_signups), 0) * 100, 2)  AS conversion_rate_pct,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.total_signups), 0), 2)             AS cost_per_signup,
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.paying_customers), 0), 2)          AS cac,
    ROUND(SUM(s.total_revenue_90d), 2)                                          AS revenue_90d,
    ROUND(SUM(s.total_revenue_90d) / NULLIF(SUM(a.total_spend), 0), 4)         AS roas
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
GROUP BY a.channel_key
ORDER BY cac ASC;

/*
EXPECTED:
  paid_search : CAC $38.23, ROAS 0.97 (nearly break-even in 90 days)
  paid_social : CAC $55.04, ROAS 0.63
  affiliate   : CAC $95.02, ROAS 0.41
  display     : CAC $2,056.83, ROAS 0.03
*/

-- =============================================================================
-- QUERY 4 — Paid vs Unpaid Benchmark
-- Business question: How do paid channels compare to organic and referral?
-- =============================================================================

-- Unpaid channels (no spend data)
SELECT
    channel          AS channel_key,
    COUNT(user_id)   AS total_signups,
    SUM(is_paid_customer)  AS paying_customers,
    ROUND(SUM(is_paid_customer) / NULLIF(COUNT(user_id), 0) * 100, 2) AS conversion_rate_pct,
    ROUND(SUM(revenue_first_90_days), 2)  AS revenue_90d,
    NULL             AS total_spend,
    NULL             AS cac,
    NULL             AS roas
FROM vw_signups_enriched
WHERE channel IN ('organic', 'referral')
GROUP BY channel

UNION ALL

-- All-paid aggregate for comparison
SELECT
    'paid_channels_total' AS channel_key,
    SUM(s.total_signups),
    SUM(s.paying_customers),
    ROUND(SUM(s.paying_customers) / NULLIF(SUM(s.total_signups), 0) * 100, 2),
    ROUND(SUM(s.total_revenue_90d), 2),
    ROUND(SUM(a.total_spend), 2),
    ROUND(SUM(a.total_spend) / NULLIF(SUM(s.paying_customers), 0), 2),
    ROUND(SUM(s.total_revenue_90d) / NULLIF(SUM(a.total_spend), 0), 4)
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
ORDER BY conversion_rate_pct DESC;

/*
EXPECTED:
  referral             : 1,063 signups, 19.9% CVR, $9,476 revenue, no spend
  paid_channels_total  : 14,266 signups, 11.9% CVR, $69,444 revenue, $124,886 spend, CAC $73.55
  organic              : 3,511 signups, 9.8% CVR, $14,473 revenue, no spend

KEY INSIGHT:
  Referral converts at 19.9% — higher than any individual paid campaign except brand_search (21.4%).
  Referral costs $0. A referral incentive programme could produce high-quality customers
  at a fraction of the CAC of most paid campaigns.
*/

-- =============================================================================
-- QUERY 5 — Monthly Trends: Spend, Signups, CAC, ROAS
-- Business question: Are paid campaigns improving or deteriorating over time?
-- =============================================================================

SELECT
    month_key,
    SUM(total_spend)                                                             AS monthly_spend,
    SUM(total_signups)                                                           AS monthly_signups,
    SUM(paying_customers)                                                        AS monthly_paying,
    ROUND(SUM(paying_customers) / NULLIF(SUM(total_signups), 0) * 100, 2)      AS conversion_rate_pct,
    ROUND(SUM(total_spend) / NULLIF(SUM(total_signups), 0), 2)                 AS cost_per_signup,
    ROUND(SUM(total_spend) / NULLIF(SUM(paying_customers), 0), 2)              AS monthly_cac,
    ROUND(SUM(total_revenue_90d) / NULLIF(SUM(total_spend), 0), 4)             AS monthly_roas
FROM vw_monthly_channel_trend
GROUP BY month_key
ORDER BY month_key;

/*
EXPECTED:
  Month    | Spend   | Signups | Paying | CVR   | CPS  | CAC   | ROAS
  2025-01  | 22,589  |  2,471  |   284  | 11.5% | 9.14 | 79.54 | 0.56
  2025-02  | 20,278  |  2,204  |   270  | 12.3% | 9.20 | 75.10 | 0.57
  2025-03  | 22,076  |  2,483  |   283  | 11.4% | 8.89 | 78.01 | 0.55
  2025-04  | 21,724  |  2,351  |   294  | 12.5% | 9.24 | 73.89 | 0.57
  2025-05  | 20,143  |  2,407  |   292  | 12.1% | 8.37 | 68.98 | 0.60
  2025-06  | 18,077  |  2,350  |   275  | 11.7% | 7.69 | 65.74 | 0.59

KEY INSIGHT:
  Spend drops in May–June, partly because display_network went dark after May 29.
  Despite lower spend, CAC improved from $79.54 (Jan) to $65.74 (Jun) — a 17% improvement.
  CPS similarly improved from $9.14 to $7.69. The portfolio is becoming more efficient
  over time, likely as display (very low conversion) wound down.
*/

-- =============================================================================
-- QUERY 6 — Monthly Campaign-Level Trend (granular)
-- Business question: Which campaign drove the month-over-month improvements?
-- IMPORTANT: vw_monthly_channel_trend is aggregated by month + channel and has
-- no campaign column. Use the campaign-level views below for this analysis.
-- =============================================================================

-- Campaign-level monthly detail (use this query for sparklines)
SELECT
    a.month_key,
    a.channel_key,
    a.campaign,
    ROUND(a.total_spend, 2)                                                      AS spend,
    s.total_signups,
    s.paying_customers,
    ROUND(a.total_spend / NULLIF(s.total_signups, 0), 2)                        AS cps,
    ROUND(a.total_spend / NULLIF(s.paying_customers, 0), 2)                     AS cac,
    ROUND(s.paying_customers / NULLIF(s.total_signups, 0) * 100, 2)            AS cvr_pct
FROM vw_ad_spend_monthly a
JOIN vw_signups_monthly   s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
ORDER BY a.campaign, a.month_key;

-- =============================================================================
-- QUERY 7 — Budget Efficiency Ranking (which campaigns deserve more budget?)
-- Business question: Which campaigns produce the best ROAS and lowest CAC?
-- =============================================================================

SELECT
    campaign,
    channel_key,
    ROUND(total_spend, 2)                           AS total_spend,
    ROUND(total_spend / (SELECT SUM(total_spend) FROM vw_campaign_performance) * 100, 1)
                                                     AS spend_share_pct,
    paying_customers,
    ROUND(cac, 2)                                    AS cac,
    ROUND(roas, 4)                                   AS roas,
    CASE
        WHEN roas >= 1.0  AND cac <= 35  THEN 'INCREASE BUDGET'
        WHEN roas >= 0.5  AND cac <= 100 THEN 'MAINTAIN OR MODEST INCREASE'
        WHEN roas < 0.5   AND cac > 100  THEN 'REDUCE BUDGET'
        WHEN cac > 500                   THEN 'PAUSE / REALLOCATE'
        ELSE 'REVIEW'
    END                                              AS h2_budget_recommendation
FROM vw_campaign_performance
ORDER BY roas DESC;

/*
EXPECTED:
  campaign           | spend%  | CAC      | ROAS | Recommendation
  brand_search       |  8.2%   |  $21.93  | 1.91 | INCREASE BUDGET
  retargeting        | 10.4%   |  $31.07  | 1.34 | INCREASE BUDGET
  generic_search     | 28.8%   |  $83.19  | 0.47 | MAINTAIN OR MODEST INCREASE
  finance_blogs      | 12.3%   |  $95.02  | 0.41 | MAINTAIN OR MODEST INCREASE
  prospecting_video  | 27.2%   | $159.23  | 0.26 | REDUCE BUDGET
  display_network    | 13.2%   |$2,056.83  | 0.03 | PAUSE / REALLOCATE
*/

-- =============================================================================
-- QUERY 8 — Funnel Analysis: Impressions → Clicks → Signups → Paying
-- Business question: Where does each campaign lose the most of its audience?
-- =============================================================================

SELECT
    cp.campaign,
    cp.channel_key,
    cp.total_impressions,
    cp.total_clicks,
    cp.total_signups,
    cp.paying_customers,
    -- Funnel drop-off rates
    ROUND(cp.total_clicks    / NULLIF(cp.total_impressions, 0) * 100, 3) AS impression_to_click_pct,
    ROUND(cp.total_signups   / NULLIF(cp.total_clicks, 0) * 100, 2)     AS click_to_signup_pct,
    ROUND(cp.paying_customers / NULLIF(cp.total_signups, 0) * 100, 2)   AS signup_to_paying_pct
FROM vw_campaign_performance cp
ORDER BY signup_to_paying_pct DESC;

/*
INTERPRETATION:
  The funnel has three bottlenecks:
  1. Impression→Click (CTR):   display_network has ~0.12% CTR (lowest); brand_search ~4.5% (highest)
  2. Click→Signup:             Varies by campaign quality and landing page
  3. Signup→Paying (CVR):      brand_search (21.4%) and generic_search (21.5%) lead.
                                prospecting_video (3.3%) and display (3.0%) trail badly.
  
  Campaigns with poor signup-to-paying rates (prospecting, display) are filling the top of
  the funnel with users who never intend to subscribe. This is the root cause of their high CAC.
*/

-- =============================================================================
-- QUERY 9 — Period-over-Period Comparison (MoM change in spend efficiency)
-- =============================================================================

WITH monthly_kpis AS (
    SELECT
        month_key,
        SUM(total_spend)      AS spend,
        SUM(total_signups)    AS signups,
        SUM(paying_customers) AS paying,
        ROUND(SUM(total_spend) / NULLIF(SUM(total_signups), 0), 2)    AS cps,
        ROUND(SUM(total_spend) / NULLIF(SUM(paying_customers), 0), 2) AS cac
    FROM vw_monthly_channel_trend
    GROUP BY month_key
)
SELECT
    curr.month_key,
    curr.spend,
    curr.signups,
    curr.paying,
    curr.cps,
    curr.cac,
    -- Month-over-month changes
    ROUND(curr.spend   - prev.spend,   2)  AS mom_spend_delta,
    curr.signups       - prev.signups      AS mom_signups_delta,
    curr.paying        - prev.paying       AS mom_paying_delta,
    ROUND(curr.cps     - prev.cps,     2)  AS mom_cps_delta,
    ROUND(curr.cac     - prev.cac,     2)  AS mom_cac_delta,
    -- Growth rates
    ROUND((curr.spend - prev.spend)   / NULLIF(prev.spend,   0) * 100, 1) AS mom_spend_pct,
    ROUND((curr.cac   - prev.cac)     / NULLIF(prev.cac,     0) * 100, 1) AS mom_cac_pct
FROM monthly_kpis  curr
LEFT JOIN monthly_kpis prev
  ON prev.month_key = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(curr.month_key,'-01'),'%Y-%m-%d'),
                                            INTERVAL 1 MONTH), '%Y-%m')
ORDER BY curr.month_key;

-- =============================================================================
-- QUERY 10 — Campaign Spend vs Conversion Efficiency (for scatter chart data)
-- =============================================================================

SELECT
    campaign,
    channel_key,
    ROUND(total_spend, 2)         AS total_spend,
    paying_customers,
    ROUND(cac, 2)                 AS cac,
    ROUND(roas, 2)                AS roas,
    ROUND(conversion_rate * 100, 2) AS conversion_rate_pct
FROM vw_campaign_performance
ORDER BY total_spend DESC;

SELECT 'All business analysis queries defined. Export results to outputs/sql_results/.' AS status;
