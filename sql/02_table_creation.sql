-- =============================================================================
-- 02_table_creation.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Create raw tables that receive the CSV imports
-- Platform: MySQL 8.0
-- Run after: 01_database_setup.sql
-- =============================================================================

USE marketing_analytics;

-- ── Drop and recreate raw tables (idempotent) ─────────────────────────────

DROP TABLE IF EXISTS ad_spend_raw;
DROP TABLE IF EXISTS signups_raw;

-- ── ad_spend_raw ─────────────────────────────────────────────────────────
-- Mirrors the ad_spend.csv schema exactly.
-- 1,046 rows expected before deduplication.
-- channel uses title-case (Paid Search, Paid Social, Display, Affiliate)
-- which differs from signups.channel — normalised in 04_transformations.sql

CREATE TABLE ad_spend_raw (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,   -- surrogate key added on import
    date        DATE         NOT NULL,
    channel     VARCHAR(50)  NOT NULL,
    campaign    VARCHAR(50)  NOT NULL,
    impressions INT UNSIGNED NOT NULL DEFAULT 0,
    clicks      INT UNSIGNED NOT NULL DEFAULT 0,
    spend       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    INDEX idx_ad_date         (date),
    INDEX idx_ad_channel      (channel),
    INDEX idx_ad_campaign     (campaign),
    INDEX idx_ad_date_channel (date, channel)
);

-- ── signups_raw ───────────────────────────────────────────────────────────
-- Mirrors the signups.csv schema exactly.
-- 18,840 rows expected; user_id is the natural primary key (no duplicates).
-- NULL campaign is correct for organic and referral channels.
-- NULL subscription_start_date means the user never became a paying customer.

CREATE TABLE signups_raw (
    user_id                  INT UNSIGNED NOT NULL,
    signup_date              DATE         NOT NULL,
    channel                  VARCHAR(50)  NOT NULL,
    campaign                 VARCHAR(50)  NULL,
    subscription_start_date  DATE         NULL,
    plan                     VARCHAR(10)  NULL,
    revenue_first_90_days    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (user_id),
    INDEX idx_sig_date         (signup_date),
    INDEX idx_sig_channel      (channel),
    INDEX idx_sig_campaign     (campaign),
    INDEX idx_sig_paid         (subscription_start_date),   -- fast IS NOT NULL lookups
    INDEX idx_sig_date_channel (signup_date, channel)
);

-- Temporary staging table for safe CSV import
DROP TABLE IF EXISTS signups_import_stage;

CREATE TABLE signups_import_stage (
    user_id                 VARCHAR(30),
    signup_date             VARCHAR(30),
    channel                 VARCHAR(50),
    campaign                VARCHAR(50),
    subscription_start_date VARCHAR(30),
    plan                    VARCHAR(10),
    revenue_first_90_days   VARCHAR(30)
);

SELECT 'Tables ad_spend_raw and signups_raw created.' AS status;


INSERT INTO signups_raw (
    user_id,
    signup_date,
    channel,
    campaign,
    subscription_start_date,
    plan,
    revenue_first_90_days
)
SELECT
    CAST(user_id AS UNSIGNED),
    STR_TO_DATE(NULLIF(TRIM(signup_date), ''), '%Y-%m-%d'),
    channel,
    NULLIF(TRIM(campaign), ''),
    STR_TO_DATE(
        NULLIF(TRIM(subscription_start_date), ''),
        '%Y-%m-%d'
    ),
    NULLIF(TRIM(plan), ''),
    COALESCE(
        CAST(NULLIF(TRIM(revenue_first_90_days), '') AS DECIMAL(10,2)),
        0.00
    )
FROM signups_import_stage;

SELECT
    COUNT(*) AS total_rows,
    SUM(subscription_start_date IS NULL) AS blank_subscription_dates
FROM signups_raw;

-- =============================================================================
-- IMPORT INSTRUCTIONS (MySQL Workbench)
-- =============================================================================
-- After running this script, import the CSVs:
--
-- 1. In the Schemas panel, right-click ad_spend_raw → Table Data Import Wizard
--    Source file : data/raw/ad_spend.csv
--    Encoding    : utf-8
--    Column map  : date→date, channel→channel, campaign→campaign,
--                  impressions→impressions, clicks→clicks, spend→spend
--    (Leave the auto-generated 'id' column unmapped — it auto-increments)
--
-- 2. Repeat for signups_raw ← data/raw/signups.csv
--    Column map  : user_id→user_id, signup_date→signup_date, channel→channel,
--                  campaign→campaign, subscription_start_date→subscription_start_date,
--                  plan→plan, revenue_first_90_days→revenue_first_90_days
--
-- Expected row counts after import:
--   ad_spend_raw : 1,046 rows
--   signups_raw  : 18,840 rows
--
-- Verify with:
--   SELECT COUNT(*) FROM ad_spend_raw;   -- expect 1046
--   SELECT COUNT(*) FROM signups_raw;    -- expect 18840
-- =============================================================================

SELECT 'signups_raw' AS table_name, COUNT(*) AS total_rows
FROM signups_raw

UNION ALL

SELECT 'ad_spend_raw', COUNT(*)
FROM ad_spend_raw;

