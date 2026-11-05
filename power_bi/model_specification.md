# Power BI Data Model Specification

## Import Source

Connect Power BI Desktop to **MySQL 8.0** using the MySQL connector.

**Connection string:**
- Server: `localhost`
- Database: `marketing_analytics`
- Port: `3306`
- Authentication: Database (username/password)
- Data connectivity mode: **Import** (not DirectQuery, for performance)

---

## Tables to Import

Import these views from MySQL. Do not import the raw tables.

| Power BI Table Name | MySQL View | Grain | Purpose |
|---------------------|-----------|-------|---------|
| `CampaignPerformance` | `vw_campaign_performance` | 1 row per campaign | Core KPI table |
| `MonthlyChannelTrend` | `vw_monthly_channel_trend` | 1 row per month × channel | Time-series charts |
| `MonthlyCampaignDetail` | *(SQL query below)* | 1 row per month × campaign | Granular trends |
| `UnpaidChannels` | `vw_unpaid_channel_summary` | 1 row per unpaid channel | Benchmark comparison |
| `DimDate` | *(create in Power BI)* | 1 row per calendar day | Date slicer & calendar |

### MonthlyCampaignDetail — custom query

Use this query as a named query in Power Query (Get Data → MySQL → Advanced):

```sql
SELECT
    a.month_key,
    a.channel_key,
    a.campaign,
    ROUND(a.total_spend, 2)                                                       AS total_spend,
    a.total_impressions,
    a.total_clicks,
    s.total_signups,
    s.paying_customers,
    ROUND(a.total_spend / NULLIF(s.total_signups, 0), 2)                        AS cost_per_signup,
    ROUND(a.total_spend / NULLIF(s.paying_customers, 0), 2)                     AS cac,
    ROUND(s.paying_customers / NULLIF(s.total_signups, 0), 4)                  AS conversion_rate,
    ROUND(s.total_revenue_90d / NULLIF(a.total_spend, 0), 4)                   AS roas,
    ROUND(s.total_revenue_90d, 2)                                                AS revenue_90d
FROM marketing_analytics.vw_ad_spend_monthly a
JOIN marketing_analytics.vw_signups_monthly  s
  ON  a.channel_key = s.channel_key
  AND a.campaign    = s.campaign
  AND a.month_key   = s.month_key
ORDER BY a.month_key, a.channel_key, a.campaign
```

---

## Star Schema Design

```
                    ┌──────────────────┐
                    │    DimDate       │
                    │  (date, month,   │
                    │   month_name,    │
                    │   quarter, year) │
                    └────────┬─────────┘
                             │ 1:M  on month_key
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐  ┌───────────────────┐  ┌──────────────────────┐
│ CampaignPerf.   │  │ MonthlyChannelTrend│  │ MonthlyCampaignDetail│
│ (1 row/campaign)│  │ (month×channel)   │  │ (month×campaign)     │
└─────────────────┘  └───────────────────┘  └──────────────────────┘
          │                                         │
          │ No direct relationship needed            │
          ▼                                         ▼
┌─────────────────────┐
│  UnpaidChannels     │
│  (organic+referral) │
└─────────────────────┘
```

**Model type:** Mostly flat — `CampaignPerformance` and `MonthlyChannelTrend` serve different visual purposes and are not related to each other in the model. DAX `CALCULATE` and slicers filter within each table.

---

## Relationship Configuration

| From Table | From Column | To Table | To Column | Cardinality | Cross-filter |
|-----------|-------------|----------|-----------|------------|--------------|
| DimDate | `month_key` | MonthlyChannelTrend | `month_key` | 1:M | Single |
| DimDate | `month_key` | MonthlyCampaignDetail | `month_key` | 1:M | Single |

**No relationship** between `CampaignPerformance` and `MonthlyChannelTrend` — these have different grains.  
**No relationship** between `UnpaidChannels` and any other table — it is a standalone reference table used in DAX.

---

## DimDate — Create in Power BI (DAX Calendar Table)

In Power BI Desktop: Modelling → New Table:

```dax
DimDate = 
ADDCOLUMNS(
    CALENDAR(DATE(2025,1,1), DATE(2025,6,30)),
    "Year",           YEAR([Date]),
    "Month Number",   MONTH([Date]),
    "Month Name",     FORMAT([Date], "MMM YYYY"),
    "Month Short",    FORMAT([Date], "MMM"),
    "Month Key",      FORMAT([Date], "YYYY-MM"),
    "Quarter",        "Q" & QUARTER([Date]),
    "Day of Week",    FORMAT([Date], "ddd"),
    "Week Number",    WEEKNUM([Date])
)
```

After creating it:
1. Mark as Date Table: Table Tools → Mark as Date Table → Date column = `Date`
2. Set `Month Name` sort by `Month Number`
3. Set `Month Key` sort by `Month Key` (already alpha-sorts correctly as YYYY-MM)
4. Relationship: DimDate[Month Key] → MonthlyChannelTrend[month_key] (1:M)
5. Relationship: DimDate[Month Key] → MonthlyCampaignDetail[month_key] (1:M)

---

## Column Formatting & Visibility

### CampaignPerformance

| Column | Rename to | Format | Visible |
|--------|-----------|--------|---------|
| channel_key | Channel | Text | ✓ |
| campaign | Campaign | Text | ✓ |
| total_spend | Total Spend | Currency $#,##0.00 | ✓ |
| total_impressions | Impressions | Whole number | ✓ |
| total_clicks | Clicks | Whole number | ✓ |
| total_active_days | Active Days | Whole number | ✓ |
| ctr | CTR | Percentage 0.000% | ✓ |
| cpc | CPC | Currency $#,##0.00 | ✓ |
| total_signups | Signups | Whole number | ✓ |
| paying_customers | Paying Customers | Whole number | ✓ |
| conversion_rate | Conversion Rate | Percentage 0.00% | ✓ |
| cost_per_signup | Cost per Signup | Currency $#,##0.00 | ✓ |
| cac | CAC | Currency $#,##0.00 | ✓ |
| total_revenue_90d | Revenue (90-day) | Currency $#,##0.00 | ✓ |
| roas | ROAS | Decimal 0.00 | ✓ |

### MonthlyChannelTrend

| Column | Rename to | Format | Visible |
|--------|-----------|--------|---------|
| month_key | Month | Text (sort by Month Key) | ✓ |
| channel_key | Channel | Text | ✓ |
| total_spend | Monthly Spend | Currency | ✓ |
| total_signups | Monthly Signups | Whole number | ✓ |
| paying_customers | Monthly Paying | Whole number | ✓ |
| cost_per_signup | Monthly CPS | Currency | ✓ |
| cac | Monthly CAC | Currency | ✓ |
| conversion_rate | Monthly CVR | Percentage | ✓ |
| total_revenue_90d | Monthly Revenue | Currency | ✓ |
| total_impressions | Impressions | Whole number | hide |
| total_clicks | Clicks | Whole number | hide |

---

## Model Limitations

1. **No date granularity below month** — daily spend data is aggregated to month before joining with signups, because individual signup rows cannot be reliably matched to a specific daily ad spend row.
2. **No multi-touch attribution** — each signup is credited to exactly one channel/campaign.
3. **Revenue is 90-day cap** — ROAS calculations are conservative underestimates of true lifetime value.
4. **No campaign creative-level data** — analysis is at campaign aggregate level only.
5. **display_network active only Jan–May** — its 6-month totals are lower than peers by definition; compare monthly figures for fairness.
