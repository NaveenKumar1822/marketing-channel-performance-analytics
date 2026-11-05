# Power BI Report Documentation

**Report:** Marketing Channel Performance Analytics — H1 2025  
**Tool:** Microsoft Power BI Desktop  
**File:** `outputs/power_bi/Marketing_Channel_Performance_Analytics.pbix`

---

## 1. Report Overview

| Attribute | Detail |
|-----------|--------|
| Report name | Marketing Channel Performance Analytics — H1 2025 |
| Business purpose | Evaluate H1 2025 paid marketing performance across channels and campaigns to inform H2 2025 budget allocation |
| Primary stakeholder | CMO / marketing decision-maker |
| Core decision supported | H2 2025 paid marketing budget reallocation |
| Data period | January 1 – June 30, 2025 |
| Data source | Four imported analytical CSV tables (see Section 3) |

**Primary KPIs:**

- Total advertising spend
- Total paying customers (paid channels)
- Customer Acquisition Cost (CAC)
- Return on Ad Spend (ROAS, 90-day window)
- Conversion Rate (CVR)
- Cost per Signup (CPS)

---

## 2. Report Structure

The report contains **four pages**.

---

### Page 1 — Executive Overview

**Purpose:** Provides the CMO with a single-page summary of H1 performance across all paid channels.

**KPI Cards (top row):**
- Total Advertising Spend: $124,886.22
- Total Paid Revenue (90d): $69,443.91
- ROAS (Paid 90d): 0.56
- CAC (Paid Channels): $73.55
- Paid Conversion Rate: 11.90%

**Visuals:**
- **Monthly Advertising Spend line chart** — total paid spend by month, Jan–Jun 2025, showing the declining trend from $22,589 (January) to $18,077 (June)
- **Spend Distribution donut chart** — H1 spend share by channel: Paid Social 37.6%, Paid Search 36.9%, Display 13.2%, Affiliate 12.3%
- **Campaign Efficiency Summary table** — all campaigns with Spend, Signups, Paying Customers, Conversion Rate, CAC, and ROAS; sorted ascending by CAC with conditional formatting (green = high CVR, red = low CVR)

**Screenshot:** `outputs/power_bi/Executive_Overview.jpeg`

---

### Page 2 — Channel Performance

**Purpose:** Compares all channels — including unpaid benchmarks — on signup volume, paying-customer volume, and conversion rate.

**KPI Cards (top row):**
- Total All-Channel Signups: 18,840
- Total Paying Customers (All Channels): 2,255
- Total All-Channel Revenue: $93,392.27
- Paid Conversion Rate: 11.90%

> Note: The all-channel totals on this page (18,840 signups, 2,255 paying customers, $93,392.27 revenue) include organic and referral. These differ from the paid-channel-only figures used in the ROAS calculation.

**Visuals:**
- **Signups by Channel horizontal bar chart** — volume comparison across all six channels; Paid Social leads (8,949), followed by Paid Search (4,185), Organic (3,511), Referral (1,063), Affiliate (864), Display (268)
- **Paying Customers by Channel horizontal bar chart** — Paid Search leads on paying-customer volume (897) despite fewer signups than Paid Social (631 paying)
- **Conversion Rate by Channel horizontal bar chart** — Paid Search 21.43%, Referral 19.94%, Affiliate 18.75%, Organic 9.83%, Paid Social 7.05%, Display 2.99%
- **Channel Performance Summary table** — Channel, Signups, Paying Customers, Conversion Rate, Spend, Revenue; includes organic and referral rows (no spend for those channels)

**Screenshot:** `outputs/power_bi/Channel_Performance.jpeg`

---

### Page 3 — Campaign Efficiency

**Purpose:** Detailed campaign-level efficiency analysis, ranking campaigns on ROAS and CAC to identify where the budget worked and where it did not.

**KPI Cards (top row):**
- Total Advertising Spend: $124,886.22
- Total Paid Revenue (90d): $69,443.91
- CAC (Paid Channels): $73.55
- ROAS (Paid 90d): 0.56

**Visuals:**
- **ROAS by Campaign horizontal bar chart** — ranked descending: brand_search (1.91), retargeting (1.34), generic_search (0.47), finance_blogs (0.41), prospecting_video (0.26), display_network (0.03); reference line at ROAS = 1.0
- **Customer Acquisition Cost by Campaign horizontal bar chart** — ranked ascending (best to worst): brand_search ($21.93), retargeting ($31.07), generic_search ($83.19), finance_blogs ($95.02), prospecting_video ($159.23), display_network ($2,056.83)
- **Spend vs Revenue by Campaign horizontal grouped bar chart** — side-by-side spend (blue) and 90-day revenue (green) bars per campaign; illustrates the spend-revenue gap for lower-performing campaigns
- **Campaign Detail table** — Campaign, Channel, Spend, Signups, Paying Customers, Conversion Rate, CAC; conditional formatting applied to Conversion Rate column (green for high, red for low)

**Screenshot:** `outputs/power_bi/Campaign_Efficiency.jpeg`

---

### Page 4 — Monthly Trends

**Purpose:** Month-over-month trend analysis across the six-month period, tracking how spend, revenue, signups, and paying customers evolved.

**KPI Cards (top row):**
- Total Advertising Spend: $124,886.22
- Total Paid Revenue (90d): $69,443.91
- Total Paid Signups: 14K
- Total Paying Customers (Paid): 2K

**Visuals:**
- **Total Monthly Advertising Spend line chart** — monthly spend values labelled directly on the line; shows overall decline from $22,588.89 (Jan) to $18,077.43 (Jun)
- **Monthly Spend by Channel stacked bar chart** — spend split across Affiliate, Display, Paid Search, and Paid Social for each month; display_network absence from June visible in the channel stack
- **Monthly Spend vs Revenue dual-line chart** — spend (blue) and 90-day revenue (red) plotted together; spend consistently above revenue, confirming overall ROAS < 1 for the paid portfolio
- **Monthly Performance Summary table** — Month, Spend, Signups, Paying Customers, Revenue, MoM Change ($) with conditional formatting; green = positive change, red = negative change

**Screenshot:** `outputs/power_bi/Monthly_Trends.jpeg`

---

## 3. Data Model

The report uses an import-mode (non-live) data model. All data is loaded from CSV files produced by the SQL analysis pipeline.

### Imported Tables

| Table | Source File | Grain | Key Columns |
|-------|------------|-------|-------------|
| `campaign_kpis` | `outputs/sql_results/campaign_kpis.csv` | One row per campaign | campaign, channel, spend, signups, paying_customers, cvr, cps, cac, revenue_90d, roas |
| `channel_summary` | `outputs/sql_results/channel_summary.csv` | One row per channel | channel, signups, paying_customers, cvr, spend, revenue_90d |
| `monthly_trend` | `outputs/sql_results/monthly_trend.csv` | One row per month | month, spend, signups, paying_customers, cvr, cps, cac, revenue_90d, roas |
| `monthly_channel_detail` | `outputs/sql_results/monthly_channel_detail.csv` | One row per month × channel | month, channel, spend |

### Measures Table

A dedicated `_Measures` table contains all DAX measures. It has no rows and no relationships to other tables. This is a standard Power BI pattern for isolating calculated measures from data tables.

### Relationships

The tables are analytical summary exports from SQL rather than a normalised transactional schema. No direct table-to-table relationships are required: each visual draws from the appropriate table using its own fields and DAX measures. The `_Measures` table is unrelated to all data tables by design.

### No Calendar Table

A dedicated date dimension table is not used. Monthly comparisons in DAX are implemented using `EDATE` and `FILTER` on the string `month` column in `monthly_trend`, which avoids the requirement for a true date column.

---

## 4. DAX Measures

All measures are stored in the `_Measures` table. Column references use Power BI renamed column names, not raw SQL column names.

| Measure | DAX Pattern | Notes |
|---------|------------|-------|
| Total Spend | `SUM(campaign_kpis[spend])` | Deduped paid-channel spend |
| Total Signups | `SUM(campaign_kpis[signups])` | Paid channels only |
| Total Paying Customers | `SUM(campaign_kpis[paying_customers])` | Paid channels only |
| CVR | `DIVIDE([Total Paying Customers], [Total Signups])` | Safe divide; returns BLANK on zero denominator |
| CPS | `DIVIDE([Total Spend], [Total Signups])` | Cost per signup |
| CAC | `DIVIDE([Total Spend], [Total Paying Customers])` | Customer acquisition cost |
| Total Revenue | `SUM(campaign_kpis[revenue_90d])` | First-90-day revenue, paid channels |
| ROAS | `DIVIDE([Total Revenue], [Total Spend])` | 90-day revenue ÷ spend |
| MoM Spend Change | `EDATE` + `FILTER` on `monthly_trend[month]` | Month-over-month delta in spend |
| MoM Paying Change | `EDATE` + `FILTER` on `monthly_trend[month]` | Month-over-month delta in paying customers |

Full measure definitions with column-name mappings and validation output are documented in `power_bi/dax_measures.md`.

---

## 5. Business Logic and KPI Definitions

| KPI | Formula | Notes |
|-----|---------|-------|
| CPS | Spend ÷ Signups | Paid campaigns only |
| CAC | Spend ÷ Paying Customers | Subscription conversions only; excludes unpaid channels |
| CVR | Paying Customers ÷ Signups | Per campaign or channel |
| CTR | Clicks ÷ Impressions | Ad click-through efficiency |
| CPC | Spend ÷ Clicks | Media buying efficiency |
| ROAS | 90-day Revenue ÷ Spend | First-90-day revenue window only |

**ROAS interpretation:**

- ROAS is calculated from the subscriber's first 90 days of revenue only. It is not full customer lifetime value.
- ROAS > 1.0 means the campaign recovered more than its media cost within the first 90 days. This indicates strong near-term performance relative to spend but should not be automatically equated with accounting profitability, which depends on operational costs, subscriber retention, and long-term LTV.
- ROAS should be used for relative campaign ranking across the H1 portfolio, not as a standalone profitability assessment.

**Paid vs unpaid scope:**

- All KPIs involving spend (CPS, CAC, ROAS) apply to paid channels only: Paid Search, Paid Social, Affiliate, and Display.
- Organic and Referral appear in channel-level views as conversion quality benchmarks. They carry no spend and are excluded from spend-based KPI calculations.

---

## 6. Verified Report KPIs

These are the authoritative H1 2025 figures as confirmed in `outputs/validation/reconciliation_notes.md`:

| Metric | Value | Scope |
|--------|-------|-------|
| Total ad spend | $124,886.22 | Paid channels, deduped |
| Total paid signups | 14,266 | Paid channels only |
| Total paying customers | 1,698 | Paid channels only |
| Paid CVR | 11.90% | 1,698 ÷ 14,266 |
| Paid 90-day revenue | $69,443.91 | Used in ROAS |
| All-channel 90-day revenue | $93,392.27 | Includes organic and referral |
| Paid ROAS | 0.5561 | $69,443.91 ÷ $124,886.22 |
| Average paid CAC | $73.55 | $124,886.22 ÷ 1,698 |

---

## 7. Report Design and Interactivity

The report uses a dark theme throughout (near-black background with white text and coloured data series).

**KPI cards:** Each page opens with a row of KPI cards showing top-line totals for the page's scope.

**Conditional formatting:** Applied to Conversion Rate columns in the Campaign Efficiency and Executive Overview tables — green shading for high CVR, red for low CVR.

**Cross-filtering:** Standard Power BI cross-filtering is active. Selecting a campaign or channel in one visual filters related visuals on the same page.

**Sorting:** The Campaign Detail table on the Executive Overview and Campaign Efficiency pages is sorted ascending by CAC (lowest first), making brand_search the first row.

**MoM Change column:** The Monthly Performance Summary table on the Monthly Trends page includes a MoM Change ($) column with conditional formatting — green for positive month-over-month spend change, red for negative.

**No drill-through, slicers, or bookmarks** are documented in the final PBIX beyond the standard cross-filtering behaviour described above.

---

## 8. Known Data Issues and Resolutions

The following issues were identified during project review and corrected before the final report was built:

| Issue | Resolution |
|-------|-----------|
| `display_network` end date incorrectly stated as 2025-05-29 in several files | Corrected to 2025-05-14 (134 active days) across all documentation and SQL scripts |
| DAX measures originally referenced raw SQL column names | Replaced with Power BI renamed column names throughout `dax_measures.md` |
| MoM measures originally used `DATEADD` (requires a true date column) | Rewritten using `EDATE` + `FILTER` on the string `month` column |
| `prospecting_video` CVR in Excel Sheet 5 stated as 0.0328 | Corrected to 0.0329 (4-decimal rounding) |

---

## 9. Limitations

| Limitation | Impact |
|------------|--------|
| 90-day revenue window | ROAS and revenue underestimate true LTV. Relative ranking across campaigns is valid; absolute profitability claims require LTV modelling. |
| Last-touch attribution | Campaign credit is binary; assisted conversions across multiple channels are not measured. |
| display_network campaign duration | Ran 134 days vs 181 days for other campaigns. Per-day comparisons must account for this difference. |
| No A/B test data | Cannot distinguish creative quality from audience or targeting effects. |
| 6-month history | H1 2025 only. Seasonality effects for H2 are unknown. |
| Synthetic data | Dataset is provided by Data Career School for educational purposes. |

---

*Documentation by Naveen Kumar K · Data Analyst Portfolio · Marketing Channel Performance Analytics*
