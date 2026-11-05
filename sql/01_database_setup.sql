-- =============================================================================
-- 01_database_setup.sql
-- Marketing Channel Performance Analytics — Robinhood H1 2025
-- Purpose : Create the database (run as root before all other scripts)
-- Platform: MySQL 8.0
-- =============================================================================

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS marketing_analytics
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Switch to the new database
USE marketing_analytics;

-- (Optional) create a dedicated project user with limited privileges
-- Uncomment and adjust if you prefer not to use root for daily work
-- CREATE USER IF NOT EXISTS 'mkt_analyst'@'localhost' IDENTIFIED BY 'your_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE VIEW
--   ON marketing_analytics.* TO 'mkt_analyst'@'localhost';
-- FLUSH PRIVILEGES;

SELECT 'Database marketing_analytics created / verified.' AS status;
