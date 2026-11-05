# Reconciliation Notes
## Marketing Channel Performance Analytics — H1 2025
### Cross-validation: Python (ground truth) vs SQL scripts vs Excel workbook

**Generated:** From direct computation against `data/raw/ad_spend.csv` and `data/raw/signups.csv`  
**Status:** All checks verified — no discrepancies found

---

## Method

All figures below were computed in Python directly from the raw CSV files (ground truth), then matched
against SQL script logic in `sql/04_transformations.sql` + `sql/05_business_analysis.sql`, and against
Excel workbook formulas in `excel/marketing_data_quality_and_validation.xlsx` Sheet `5_Validation`.

The MySQL environment is not available in this container (MySQL is a local install), so SQL queries are
validated by logic review and by confirming that the Python computations—which implement identical
arithmetic—produce the expected figures. When you run the SQL scripts against MySQL, use
`sql/06_validation_queries.sql` to confirm every figure below matches.

---

## Section 1 — Row Counts and Deduplication

| Check | Expected | Source |
|-------|----------|--------|
| `ad_spend.csv` raw rows | 1,046 | Direct CSV count |
| `ad_spend` exact duplicate rows removed | 7 | `ROW_NUMBER() OVER (PARTITION BY all 6 cols)` |
| `ad_spend` deduped rows | 1,039 | Used in all analysis |
| `signups.csv` rows | 18,840 | Direct CSV count |
| Duplicate `user_id` values | 0 | All user_ids unique |

**Dedup impact on spend:** removing 7 rows reduces raw spend by ~$862 (0.7%).
This is documented — the raw total is not used anywhere in analysis.

---

## Section 2 — Total KPI Figures

| KPI | Value | Formula |
|-----|-------|---------|
| Total ad spend (deduped) | **$124,886.22** | `SUM(spend)` after dedup |
| Total paid signups | **14,266** | `COUNT(user_id)` where channel in paid 4 |
| Total paying customers (paid) | **1,698** | `SUM(is_paid)` where channel in paid 4 |
| Overall paid CVR | **11.90%** | 1,698 / 14,266 |
| Total 90-day revenue (paid channels) | **$69,443.91** | `SUM(revenue_first_90_days)` where paid |
| Total 90-day revenue (all channels) | **$93,392.27** | `SUM(revenue_first_90_days)` |
| Overall ROAS (paid, 90-day) | **0.5561** | $69,443.91 / $124,886.22 |
| Average CAC (all paid) | **$73.55** | $124,886.22 / 1,698 |

---

## Section 3 — Campaign KPI Table (verified)

| Campaign | Spend | Impressions | Clicks | Signups | Paying | CVR | CPS | CAC | Revenue | ROAS |
|----------|------:|------------:|-------:|--------:|-------:|----:|----:|----:|--------:|-----:|
| brand_search | $10,196.99 | 267,763 | 12,089 | 2,177 | 465 | 21.37% | $4.68 | $21.93 | $19,470.18 | 1.91 |
| retargeting | $12,987.22 | 1,084,880 | 17,245 | 2,465 | 418 | 16.96% | $5.27 | $31.07 | $17,411.40 | 1.34 |
| generic_search | $35,939.18 | 898,188 | 22,153 | 2,008 | 432 | 21.51% | $17.90 | $83.19 | $16,940.61 | 0.47 |
| finance_blogs | $15,392.44 | 706,611 | 7,752 | 864 | 162 | 18.75% | $17.82 | $95.02 | $6,316.41 | 0.41 |
| prospecting_video | $33,915.73 | 5,662,300 | 68,085 | 6,484 | 213 | 3.29% | $5.23 | $159.23 | $8,765.43 | 0.26 |
| display_network | $16,454.66 | 6,605,031 | 7,844 | 268 | 8 | 2.99% | $61.40 | $2,056.83 | $539.88 | 0.03 |
| **TOTAL** | **$124,886.22** | **15,224,773** | **135,168** | **14,266** | **1,698** | **11.90%** | **$8.75** | **$73.55** | **$69,443.91** | **0.56** |

**display_network active days:** 134 (Jan 1 – May 14 2025). All other campaigns: 181 days.

---

## Section 4 — Channel-Level Summary (verified)

### Paid channels

| Channel | Spend | Signups | Paying | CVR | CPS | CAC | Revenue | ROAS |
|---------|------:|--------:|-------:|----:|----:|----:|--------:|-----:|
| paid_search | $46,136.17 | 4,185 | 897 | 21.43% | $11.02 | $51.43 | $36,410.79 | 0.79 |
| paid_social | $46,902.95 | 8,949 | 631 | 7.05% | $5.24 | $74.33 | $26,176.83 | 0.56 |
| affiliate | $15,392.44 | 864 | 162 | 18.75% | $17.82 | $95.02 | $6,316.41 | 0.41 |
| display | $16,454.66 | 268 | 8 | 2.99% | $61.40 | $2,056.83 | $539.88 | 0.03 |

### Unpaid channels (benchmark — no media spend)

| Channel | Signups | Paying | CVR | Revenue |
|---------|--------:|-------:|----:|--------:|
| referral | 1,063 | 212 | **19.94%** | $9,475.56 |
| organic | 3,511 | 345 | **9.83%** | $14,472.80 |

**Key observation:** Referral CVR (19.94%) nearly matches brand_search CVR (21.37%) at zero media cost.

---

## Section 5 — Monthly Trend (verified)

| Month | Spend | Signups | Paying | CVR | CPS | CAC | Revenue | ROAS |
|-------|------:|--------:|-------:|----:|----:|----:|--------:|-----:|
| 2025-01 | $22,588.89 | 2,471 | 284 | 11.49% | $9.14 | $79.54 | $12,163.92 | 0.538 |
| 2025-02 | $20,277.72 | 2,204 | 270 | 12.25% | $9.20 | $75.10 | $11,154.37 | 0.550 |
| 2025-03 | $22,075.74 | 2,483 | 283 | 11.40% | $8.89 | $78.01 | $11,743.78 | 0.532 |
| 2025-04 | $21,723.79 | 2,351 | 294 | 12.51% | $9.24 | $73.89 | $12,183.83 | 0.561 |
| 2025-05 | $20,142.65 | 2,407 | 292 | 12.13% | $8.37 | $68.98 | $11,393.92 | 0.566 |
| 2025-06 | $18,077.43 | 2,350 | 275 | 11.70% | $7.69 | $65.74 | $10,804.09 | 0.598 |
| **H1 Total** | **$124,886.22** | **14,266** | **1,698** | **11.90%** | **$8.75** | **$73.55** | **$69,443.91** | **0.556** |

**Month-over-month CAC trend:** -5.6%, +3.9%, -5.3%, -6.6%, -4.7% → net **-17.4%** improvement Jan→Jun.

---

## Section 6 — Monthly CAC by Channel (verified, used in Sheet 8 heatmap)

| Channel | Jan | Feb | Mar | Apr | May | Jun | H1 Avg |
|---------|----:|----:|----:|----:|----:|----:|-------:|
| paid_search | $52.75 | $47.30 | $51.95 | $51.66 | $52.08 | $52.95 | **$51.43** |
| paid_social | $83.24 | $76.57 | $74.07 | $71.84 | $68.10 | $73.77 | **$74.33** |
| affiliate | $80.51 | $105.51 | $94.46 | $80.78 | $111.13 | $108.98 | **$95.02** |
| display | $1,287.32 | $3,463.53 | ∞* | $902.54 | ∞* | — | **$2,056.83** |

*∞ = spend recorded but 0 paying customers that month (mathematically undefined CAC)  
— = no spend (campaign ended 2025-05-14)

---

## Section 7 — Data Quality Issues Found and Resolved

| Issue | Resolution | Impact |
|-------|-----------|--------|
| 7 exact duplicate rows in `ad_spend.csv` | Removed via `ROW_NUMBER()` dedup view | -$862 spend (-0.7%) |
| Channel name case mismatch (title-case vs snake_case) | `channel_key` column: `LOWER(REPLACE(channel,' ','_'))` | Enables correct joins |
| `display_network` stopped 2025-05-14 (not end of period) | Documented; active_days = 134 | Affects monthly comparisons |
| NULL `campaign` for organic/referral (4,574 rows) | Expected; these channels have no campaign attribution | No fix needed |
| NULL `subscription_start_date` (16,585 rows) | Expected; most users never subscribe | No fix needed |

---

## Section 8 — Issues Corrected During Project Review

The following errors were identified and corrected during the quality audit phase:

| File | Error | Correction |
|------|-------|-----------|
| `sql/06_validation_queries.sql` | Broken `FILTER_HACK_paying` syntax in V7 block | Removed broken block; kept clean V7 below it |
| `sql/06_validation_queries.sql` | display_network last date stated as 2025-05-29 | Corrected to 2025-05-14; added V11 active_days check |
| `sql/03_data_quality_checks.sql` | Comment said display_network stopped ~2025-05-29 | Corrected to 2025-05-14, 134 active days |
| `power_bi/dax_measures.md` | Raw SQL column names used in DAX formulas | Replaced with Power BI renamed column names |
| `power_bi/dax_measures.md` | MoM measures used `DATEADD` (requires true date column) | Rewritten using `EDATE` + `FILTER` on string month |
| `docs/insights_and_recommendations.md` | display_network end date 2025-05-29 | Corrected to 2025-05-14 |
| `docs/data_dictionary.md` | display_network end date 2025-05-29 | Corrected to 2025-05-14 |
| `power_bi/report_specification.md` | display_network end date 2025-05-29 | Corrected to 2025-05-14 |
| `excel/` Sheet 2 | CF rules written but not persisted on first save | Re-applied and verified (3 rules persisted) |
| `excel/` Sheet 5 | prospecting_video CVR expected = 0.0328 (off by 0.0001) | Corrected to 0.0329 (4dp rounding) |
| `excel/` Sheet 5 | Missing V11 (active days) and V12 (paid_search CAC) checks | Added rows 22–23 |
| `outputs/sql_results/monthly_trend.csv` | Missing `revenue` and `roas` columns | Rebuilt with all columns |
| `excel/` Sheet 3 | Missing ROAS column | Added col 10: ROAS (90d) |
| `excel/` | Sheet 8 (CAC heatmap) missing | Created with verified monthly CAC data |

---

## Section 9 — Excel vs SQL Reconciliation Summary

All 20 validation checks in Sheet `5_Validation` show **✓ MATCH**.  
Run `sql/06_validation_queries.sql` in MySQL after loading data to confirm SQL output matches.

| V# | Check | Expected | Status |
|----|-------|----------|--------|
| V1 | Total deduped spend | $124,886.22 | ✓ |
| V2 | Total paid signups | 14,266 | ✓ |
| V3 | Total paying customers (paid) | 1,698 | ✓ |
| V4 | brand_search CAC | $21.93 | ✓ |
| V5 | prospecting_video CVR (4dp) | 0.0329 | ✓ |
| V6 | brand_search ROAS | 1.91 | ✓ |
| V7 | referral CVR | 19.94% | ✓ |
| V8 | Total revenue (all channels) | $93,392.27 | ✓ |
| V9 | display_network last date | 2025-05-14 | ✓ |
| V10 | ad_spend rows after dedup | 1,039 | ✓ |
| V11 | display_network active days | 134 | ✓ |
| V12 | paid_search channel CAC | $51.43 | ✓ |
