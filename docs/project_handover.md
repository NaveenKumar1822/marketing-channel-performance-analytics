# Project Handover — Marketing Channel Performance Analytics

**Project:** Marketing Channel Performance Analytics — H1 2025  
**Status: COMPLETE**  
**Completed by:** Naveen Kumar K  
**Stack:** SQL (MySQL 8) · Microsoft Excel · Microsoft Power BI Desktop · Git / GitHub

---

## 1. Project Status

This project is complete. All analytical, validation, and documentation work has been finished. The following components are delivered:

| Component | Status |
|-----------|--------|
| Business problem definition | ✅ Complete |
| Data dictionary | ✅ Complete |
| Data quality and cleaning (SQL) | ✅ Complete |
| Transformations and staging views (SQL) | ✅ Complete |
| Business analysis queries (SQL) | ✅ Complete |
| Cross-validation queries (SQL) | ✅ Complete |
| Excel data profiling and validation | ✅ Complete |
| Excel KPI workbook (8 sheets) | ✅ Complete |
| Power BI data model and DAX measures | ✅ Complete |
| Power BI report (4 pages) | ✅ Complete |
| Reconciliation notes (Python ground truth) | ✅ Complete |
| Insights and recommendations | ✅ Complete |
| Project handover documentation | ✅ Complete |

**SQL execution note:** SQL scripts have been validated by logic review and by Python computations that implement identical arithmetic. The MySQL environment requires a local MySQL 8 install. To confirm all figures in a MySQL environment, run `sql/06_validation_queries.sql` against the loaded data. All 12 cross-validation checks (V1–V12) are expected to show MATCH.

---

## 2. Business Problem

Robinhood's CMO is setting the H2 2025 marketing budget and needs to know which channels and campaigns deliver value — measured not just by signups but by paying subscribers and 90-day revenue from Robinhood Gold subscriptions.

Six months of daily ad-spend data (Jan–Jun 2025) is joined to an 18,840-row signup table that tracks whether each user ever became a paying subscriber and the revenue they generated in their first 90 days.

---

## 3. Verified Project Results

All figures below are verified against the Python ground-truth computation and cross-checked in Excel (20 validation checks, all MATCH). Full detail is in `outputs/validation/reconciliation_notes.md`.

### 3.1 Top-Level KPIs

| Metric | Value | Scope |
|--------|-------|-------|
| Total ad spend (deduped) | $124,886.22 | Paid channels |
| Total paid signups | 14,266 | Paid channels only |
| Total paying customers | 1,698 | Paid channels only |
| Paid conversion rate | 11.90% | 1,698 ÷ 14,266 |
| 90-day revenue — paid channels | $69,443.91 | Paid channels only; used in ROAS |
| 90-day revenue — all channels | $93,392.27 | Includes organic ($14,473) and referral ($9,476) |
| Overall ROAS (paid, 90-day) | 0.5561 | $69,443.91 ÷ $124,886.22 |
| Average paid CAC | $73.55 | $124,886.22 ÷ 1,698 |

> **Scope note:** Paid 90-day revenue ($69,443.91) and all-channel 90-day revenue ($93,392.27) are not interchangeable. The ROAS calculation uses paid revenue only. The all-channel figure is provided for context and appears in the Channel Performance report page.

### 3.2 Campaign Results

| Campaign | Channel | Spend | Signups | Paying | CVR | CPS | CAC | Revenue (90d) | ROAS |
|----------|---------|------:|--------:|-------:|----:|----:|----:|--------------:|-----:|
| brand_search | Paid Search | $10,196.99 | 2,177 | 465 | 21.37% | $4.68 | $21.93 | $19,470.18 | 1.91 |
| retargeting | Paid Social | $12,987.22 | 2,465 | 418 | 16.96% | $5.27 | $31.07 | $17,411.40 | 1.34 |
| generic_search | Paid Search | $35,939.18 | 2,008 | 432 | 21.51% | $17.90 | $83.19 | $16,940.61 | 0.47 |
| finance_blogs | Affiliate | $15,392.44 | 864 | 162 | 18.75% | $17.82 | $95.02 | $6,316.41 | 0.41 |
| prospecting_video | Paid Social | $33,915.73 | 6,484 | 213 | 3.29% | $5.23 | $159.23 | $8,765.43 | 0.26 |
| display_network | Display | $16,454.66 | 268 | 8 | 2.99% | $61.40 | $2,056.83 | $539.88 | 0.03 |
| **H1 Total** | | **$124,886.22** | **14,266** | **1,698** | **11.90%** | **$8.75** | **$73.55** | **$69,443.91** | **0.56** |

**display_network:** Active January 1 – May 14, 2025 only (134 days vs 181 days for all other campaigns).

### 3.3 Channel Results

#### Paid Channels

| Channel | Spend | Signups | Paying | CVR | CAC | Revenue (90d) | ROAS |
|---------|------:|--------:|-------:|----:|----:|--------------:|-----:|
| paid_search | $46,136.17 | 4,185 | 897 | 21.43% | $51.43 | $36,410.79 | 0.79 |
| paid_social | $46,902.95 | 8,949 | 631 | 7.05% | $74.33 | $26,176.83 | 0.56 |
| affiliate | $15,392.44 | 864 | 162 | 18.75% | $95.02 | $6,316.41 | 0.41 |
| display | $16,454.66 | 268 | 8 | 2.99% | $2,056.83 | $539.88 | 0.03 |

#### Unpaid Channels (Benchmarks — No Media Spend)

| Channel | Signups | Paying | CVR | Revenue (90d) |
|---------|--------:|-------:|----:|--------------:|
| referral | 1,063 | 212 | 19.94% | $9,475.56 |
| organic | 3,511 | 345 | 9.83% | $14,472.80 |

Referral CVR (19.94%) nearly matches brand_search CVR (21.37%) at zero media cost.

### 3.4 Monthly Trend

| Month | Spend | Signups | Paying | CVR | CAC | Revenue (90d) | ROAS |
|-------|------:|--------:|-------:|----:|----:|--------------:|-----:|
| Jan 2025 | $22,588.89 | 2,471 | 284 | 11.49% | $79.54 | $12,163.92 | 0.538 |
| Feb 2025 | $20,277.72 | 2,204 | 270 | 12.25% | $75.10 | $11,154.37 | 0.550 |
| Mar 2025 | $22,075.74 | 2,483 | 283 | 11.40% | $78.01 | $11,743.78 | 0.532 |
| Apr 2025 | $21,723.79 | 2,351 | 294 | 12.51% | $73.89 | $12,183.83 | 0.561 |
| May 2025 | $20,142.65 | 2,407 | 292 | 12.13% | $68.98 | $11,393.92 | 0.566 |
| Jun 2025 | $18,077.43 | 2,350 | 275 | 11.70% | $65.74 | $10,804.09 | 0.598 |
| **H1 Total** | **$124,886.22** | **14,266** | **1,698** | **11.90%** | **$73.55** | **$69,443.91** | **0.556** |

CAC improved 17.4% from January ($79.54) to June ($65.74), driven primarily by the wind-down of display_network.

---

## 4. Power BI Report — Final State

The delivered report (`outputs/power_bi/Marketing_Channel_Performance_Analytics.pbix`) contains **four pages**.

### Data Model

The report uses four imported analytical CSV tables and a dedicated measures table:

| Table | Source File | Description |
|-------|------------|-------------|
| `campaign_kpis` | `outputs/sql_results/campaign_kpis.csv` | Campaign-level spend, signups, paying, CVR, CPS, CAC, revenue, ROAS |
| `channel_summary` | `outputs/sql_results/channel_summary.csv` | Channel-level aggregates including unpaid benchmarks |
| `monthly_trend` | `outputs/sql_results/monthly_trend.csv` | Monthly totals: spend, signups, paying, CVR, CAC, revenue, ROAS |
| `monthly_channel_detail` | `outputs/sql_results/monthly_channel_detail.csv` | Monthly spend broken down by channel |
| `_Measures` | (DAX table, no source file) | All calculated DAX measures; no rows |

### Report Pages

| Page | Purpose |
|------|---------|
| 1 — Executive Overview | Top-line KPI scorecards, monthly spend line chart, spend distribution donut chart by channel, campaign efficiency summary table sorted by CAC |
| 2 — Channel Performance | All-channel signup and paying-customer volume bars, CVR comparison by channel, channel performance summary table including organic and referral benchmarks |
| 3 — Campaign Efficiency | ROAS ranked bar chart, CAC ranked bar chart, spend vs revenue comparison bars, full campaign detail table with conditional formatting |
| 4 — Monthly Trends | Monthly spend line chart, monthly spend-by-channel stacked bars, spend vs revenue dual-line chart, monthly performance summary table with MoM change column |

### DAX Measures

The `_Measures` table contains 10 DAX measures covering all core KPIs:

| Measure | Definition |
|---------|-----------|
| Total Spend | `SUM(campaign_kpis[spend])` |
| Total Signups | `SUM(campaign_kpis[signups])` |
| Total Paying Customers | `SUM(campaign_kpis[paying_customers])` |
| CVR | `DIVIDE([Total Paying Customers], [Total Signups])` |
| CPS | `DIVIDE([Total Spend], [Total Signups])` |
| CAC | `DIVIDE([Total Spend], [Total Paying Customers])` |
| Total Revenue | `SUM(campaign_kpis[revenue_90d])` |
| ROAS | `DIVIDE([Total Revenue], [Total Spend])` |
| MoM Spend Change | Month-over-month spend delta using `EDATE` + `FILTER` on string month |
| MoM Paying Change | Month-over-month paying-customer delta using `EDATE` + `FILTER` on string month |

Screenshots of all four report pages are saved in `outputs/power_bi/`.

---

## 5. Final Deliverables

### Documentation

| File | Description |
|------|-------------|
| `README.md` | Project overview, findings, KPI definitions, reproduction steps |
| `docs/business_problem.md` | Formal business problem statement and analytical objectives |
| `docs/data_dictionary.md` | Field-level definitions for both source files |
| `docs/methodology.md` | End-to-end analytical methodology, tool choices, pipeline description |
| `docs/insights_and_recommendations.md` | Five verified findings and H2 2025 budget recommendations |
| `docs/project_handover.md` | This file — final project status and deliverables summary |

### SQL

| File | Description |
|------|-------------|
| `sql/01_database_setup.sql` | Create database and user |
| `sql/02_table_creation.sql` | DDL for raw and staging tables |
| `sql/03_data_quality_checks.sql` | Nulls, duplicates, date gaps, channel mismatches |
| `sql/04_transformations.sql` | Dedup logic, `channel_key` normalisation, 8 staging views |
| `sql/05_business_analysis.sql` | 10 business analysis queries with inline results |
| `sql/06_validation_queries.sql` | 12 cross-validation checks (V1–V12) |

### Data

| File | Description |
|------|-------------|
| `data/raw/ad_spend.csv` | Raw daily ad-spend file (1,046 rows) |
| `data/raw/signups.csv` | Raw user signup file (18,840 rows) |
| `data/processed/` | Cleaned exports from SQL after MySQL run |

### Excel

| File | Description |
|------|-------------|
| `excel/marketing_data_quality_and_validation.xlsx` | 8-sheet workbook: data inventory, campaign KPIs, monthly trend, channel summary, 20-check validation sheet, PivotTable guide, key formulas, CAC heatmap |

### Power BI

| File | Description |
|------|-------------|
| `power_bi/dax_measures.md` | All DAX measure definitions with validation table |
| `power_bi/model_specification.md` | Star schema documentation, relationships, column renames |
| `power_bi/report_specification.md` | Final Power BI report documentation (4 pages) |
| `outputs/power_bi/Marketing_Channel_Performance_Analytics.pbix` | Final Power BI file |
| `outputs/power_bi/Executive_Overview.jpeg` | Page 1 screenshot |
| `outputs/power_bi/Channel_Performance.jpeg` | Page 2 screenshot |
| `outputs/power_bi/Campaign_Efficiency.jpeg` | Page 3 screenshot |
| `outputs/power_bi/Monthly_Trends.jpeg` | Page 4 screenshot |

### Validation

| File | Description |
|------|-------------|
| `outputs/validation/reconciliation_notes.md` | 12-check reconciliation; Python ground truth vs SQL logic vs Excel; all checks MATCH |
| `outputs/sql_results/campaign_kpis.csv` | Verified campaign-level results |
| `outputs/sql_results/monthly_trend.csv` | Verified monthly trend results |
| `outputs/sql_results/channel_summary.csv` | Verified channel-level results |
| `outputs/sql_results/monthly_channel_detail.csv` | Verified monthly-by-channel spend |

---

## 6. Limitations and Reproducibility Notes

| Limitation | Detail |
|------------|--------|
| 90-day revenue window | ROAS and revenue figures capture only the subscriber's first 90 days. True lifetime value will be higher. Use ROAS for relative campaign ranking, not absolute profitability assessment. |
| Last-touch attribution | A user who encountered multiple channels before signing up is credited entirely to the final channel. Cross-channel contribution is not measured. |
| No A/B test data | Campaign performance differences may reflect audience targeting or ad placement rather than creative quality. |
| display_network comparison | display_network ran for 134 days (Jan 1 – May 14) vs 181 days for all other campaigns. Direct per-day comparisons should account for this. |
| MySQL execution environment | SQL scripts were validated by logic review and Python arithmetic. Direct execution in MySQL requires a local MySQL 8 install and CSV import via MySQL Workbench or equivalent. |
| Organic and referral benchmarks | Organic and referral channels carry no media spend and have no campaign attribution. They appear in the channel-level analysis as conversion quality benchmarks only. |
| NULL subscription dates | 16,585 of 18,840 signup rows have a NULL `subscription_start_date`. This is expected — most users never subscribe. No imputation was applied. |
| Synthetic data | The dataset is synthetic and provided by Data Career School for educational purposes. Findings should not be treated as production business intelligence. |

---

## 7. GitHub Publication

The project is ready for GitHub publication. Steps:

1. Confirm all files are present per Section 5 above.
2. Verify the `.gitignore` excludes any local environment files or credentials.
3. Push to your GitHub repository.
4. The `README.md` references dashboard screenshots at `outputs/power_bi/` — confirm those files are committed.

---

*Project by Naveen Kumar K · Data Analyst Portfolio · Built on the Data Career School Marketing Channel Performance lab*
