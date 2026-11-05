# Methodology

## Database Platform

**MySQL 8.0** is used for all SQL work.

**Why MySQL over SQL Server?**  
This project targets a reproducible Windows desktop setup. MySQL Community Edition is free, widely available,
and MySQL Workbench provides a GUI-based CSV import that avoids BULK INSERT file-path permissions issues that
SQL Server Express frequently requires extra configuration to resolve. The SQL syntax used (CTEs, window
functions, DATE_FORMAT) is fully supported in MySQL 8.

If you prefer SQL Server, replace:
- `DATE_FORMAT(date, '%Y-%m')` → `FORMAT(date, 'yyyy-MM')`
- `IFNULL()` → `ISNULL()`
- `LIMIT` → `TOP`

---

## Environment Setup

### Step 1 — Install MySQL 8

1. Download MySQL Community Installer from https://dev.mysql.com/downloads/installer/
2. Choose "Developer Default" during setup.
3. Set root password. Remember it.
4. MySQL Workbench is included — use it for CSV imports and query execution.

### Step 2 — Create the database

Run `sql/01_database_setup.sql` as root in MySQL Workbench or the command line:

```bash
mysql -u root -p < sql/01_database_setup.sql
```

### Step 3 — Create tables

```bash
mysql -u root -p marketing_analytics < sql/02_table_creation.sql
```

### Step 4 — Import the CSVs

Use MySQL Workbench's Table Data Import Wizard:

1. Right-click `ad_spend_raw` table → Table Data Import Wizard
2. Browse to `data/raw/ad_spend.csv`
3. Accept the default column mappings (all columns match)
4. Click Finish

Repeat for `signups_raw` ← `data/raw/signups.csv`

**Alternative — LOAD DATA INFILE (fast, CLI):**

```sql
LOAD DATA LOCAL INFILE '/path/to/data/raw/ad_spend.csv'
INTO TABLE ad_spend_raw
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date, channel, campaign, impressions, clicks, spend);
```

Note: `LOCAL INFILE` requires `local_infile=ON` in MySQL config and the `--local-infile=1` flag at login.

### Step 5 — Run quality checks

```bash
mysql -u root -p marketing_analytics < sql/03_data_quality_checks.sql
```

Review the output. All counts should match the expected values in this document.

### Step 6 — Run transformations

```bash
mysql -u root -p marketing_analytics < sql/04_transformations.sql
```

This creates the staging views and the `vw_campaign_performance` master view.

### Step 7 — Run business analysis

```bash
mysql -u root -p marketing_analytics < sql/05_business_analysis.sql
```

Export each result set to `outputs/sql_results/` using MySQL Workbench: Results Grid → Export.

---

## Data Cleaning Decisions

| Decision | Reason | Impact |
|----------|--------|--------|
| Remove 7 exact duplicate rows in `ad_spend` | Identical date+channel+campaign+metrics rows would double-count spend | Spend decreases by ~$862 (0.7%) |
| Do NOT remove `display_network` rows from May 30 onward | Campaign ended naturally; this is a finding, not an error | Spend and active-day counts reflect reality |
| Keep NULLs in `campaign` for organic/referral | These channels have no campaign; NULLs are correct | Unpaid channels analysed separately |
| No imputation for missing `subscription_start_date` | NULL means the user never subscribed — this is factual | Paying customer counts are conservative |
| Revenue = 0 for non-subscribers | Correct; no imputation | ROAS calculations are unbiased |

---

## KPI Definitions & Formulas

### Cost per Signup (CPS)
```
CPS = Total Campaign Spend / Total Signups attributed to that campaign
```
Denominator: users in `signups` where `channel` and `campaign` match.

### Customer Acquisition Cost (CAC)
```
CAC = Total Campaign Spend / Paying Customers attributed to that campaign
```
Denominator: users where `subscription_start_date IS NOT NULL`.

### Conversion Rate (CVR)
```
CVR = Paying Customers / Total Signups
```

### Click-Through Rate (CTR)
```
CTR = Total Clicks / Total Impressions
```

### Cost per Click (CPC)
```
CPC = Total Spend / Total Clicks
```

### Return on Ad Spend (ROAS)
```
ROAS = Sum(revenue_first_90_days) / Total Spend
```
Revenue window: first 90 days after signup only. ROAS > 1.0 means the campaign recovered more than it spent
within 90 days at the subscriber level. ROAS < 1.0 does not mean the campaign is unprofitable over the full
customer lifetime — it means it has not yet paid back within the 90-day window.

---

## Aggregation Grain

All KPIs are computed at the **campaign + channel** grain for comparisons, and at **channel** grain for
channel-level roll-ups. Time-series analysis uses **month** grain.

**Never join at row grain (daily spend × individual user)** — the two tables have different structures
and such a join would create false many-to-many relationships.

---

## Attribution Method

Last-touch attribution is used throughout. Each signup is credited to exactly one channel and one campaign
(or NULL for organic/referral). Multi-touch attribution data is not available in this dataset.
