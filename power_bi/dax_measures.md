# DAX Measures Reference

> **Setup:** Create all measures in a dedicated table.  
> In Power BI Desktop: Home → Enter Data → name the table `_Measures`, add one column called `Placeholder` with value `0`, load, then delete the `Placeholder` column from Data view. Add all measures to this table.

---

## Column Name Dependency Notice

All DAX measures use the **renamed** column names from the Power BI import step, not the raw SQL view column names.  
The rename mapping (SQL view name → Power BI column name) is defined in `model_specification.md`.  
Key renames that affect DAX:

| Table | SQL column | Power BI column name used in DAX |
|-------|-----------|----------------------------------|
| CampaignPerformance | `total_spend` | `Total Spend` |
| CampaignPerformance | `total_signups` | `Signups` |
| CampaignPerformance | `paying_customers` | `Paying Customers` |
| CampaignPerformance | `total_revenue_90d` | `Revenue (90-day)` |
| CampaignPerformance | `channel_key` | `Channel` |
| CampaignPerformance | `conversion_rate` | `Conversion Rate` |
| CampaignPerformance | `cac` | `CAC` |
| CampaignPerformance | `roas` | `ROAS` |
| MonthlyChannelTrend | `total_spend` | `Monthly Spend` |
| MonthlyChannelTrend | `paying_customers` | `Monthly Paying` |
| MonthlyChannelTrend | `total_signups` | `Monthly Signups` |
| MonthlyChannelTrend | `total_revenue_90d` | `Monthly Revenue` |
| MonthlyChannelTrend | `cac` | `Monthly CAC` |
| MonthlyChannelTrend | `conversion_rate` | `Monthly CVR` |
| MonthlyChannelTrend | `month_key` | `Month` |
| MonthlyChannelTrend | `channel_key` | `Channel` |
| UnpaidChannels | `channel_key` | `Channel Key` |
| UnpaidChannels | `paying_customers` | `Paying Customers` |
| UnpaidChannels | `total_signups` | `Total Signups` |

**If a DAX measure returns BLANK or an error**, first verify the column exists with the exact name shown above in Power BI's Data view.

---

## Group 1 — Core Spend Metrics

### [Total Spend]
**Business definition:** Total marketing dollars spent across selected campaigns and periods.  
**Format:** Currency `$#,##0.00`

```dax
[Total Spend] =
SUM( CampaignPerformance[Total Spend] )
```

**Validate:** Card visual with no slicers → must show **$124,886.22**

---

### [Total Spend (Monthly)]
**Business definition:** Total spend in the selected month(s) — reads from the time-series table.  
**Format:** Currency `$#,##0.00`

```dax
[Total Spend (Monthly)] =
SUM( MonthlyChannelTrend[Monthly Spend] )
```

**Used in:** Monthly trend line chart on Page 1.  
**Validate:** Filtered to 2025-01 → **$22,588.89**

---

## Group 2 — Volume Metrics

### [Total Signups]
**Business definition:** Total new free-account signups attributed to selected campaigns.  
**Format:** Whole number `#,##0`

```dax
[Total Signups] =
SUM( CampaignPerformance[Signups] )
```

**Validate:** No slicer → **14,266** (paid channels only)

---

### [Total Paying Customers]
**Business definition:** Total users who subscribed to Robinhood Gold.  
**Format:** Whole number `#,##0`

```dax
[Total Paying Customers] =
SUM( CampaignPerformance[Paying Customers] )
```

**Validate:** No slicer → **1,698**

---

### [Total Impressions]
**Format:** Whole number `#,##0`

```dax
[Total Impressions] =
SUM( CampaignPerformance[Impressions] )
```

---

### [Total Clicks]
**Format:** Whole number `#,##0`

```dax
[Total Clicks] =
SUM( CampaignPerformance[Clicks] )
```

---

## Group 3 — Rate & Efficiency Metrics

### [Conversion Rate]
**Business definition:** Percentage of signups that became paying Gold subscribers.  
**Format:** Percentage `0.00%`

```dax
[Conversion Rate] =
DIVIDE(
    [Total Paying Customers],
    [Total Signups],
    0
)
```

**Validate:**
- No slicer → **11.90%**
- brand_search only → **21.37%**
- prospecting_video only → **3.29%**
- display_network only → **2.99%**

---

### [CTR]
**Business definition:** Click-through rate — clicks ÷ impressions.  
**Format:** Percentage `0.000%` (3 decimal places — values are very small for display/affiliate)

```dax
[CTR] =
DIVIDE(
    [Total Clicks],
    [Total Impressions],
    0
)
```

---

### [CPC]
**Business definition:** Cost per click.  
**Format:** Currency `$#,##0.00`

```dax
[CPC] =
DIVIDE(
    [Total Spend],
    [Total Clicks],
    BLANK()
)
```

---

## Group 4 — Cost KPIs

### [Cost per Signup]
**Business definition:** Average spend to acquire one new free-account signup.  
**Format:** Currency `$#,##0.00`  
**Returns BLANK() for unpaid channels** — correct; they have no spend.

```dax
[Cost per Signup] =
DIVIDE(
    [Total Spend],
    [Total Signups],
    BLANK()
)
```

**Validate:**
- brand_search → **$4.68**
- prospecting_video → **$5.23**
- display_network → **$61.40**
- generic_search → **$17.90**

---

### [CAC]
**Business definition:** Average spend to acquire one paying Gold subscriber. Primary budget allocation KPI.  
**Format:** Currency `$#,##0.00`

```dax
[CAC] =
DIVIDE(
    [Total Spend],
    [Total Paying Customers],
    BLANK()
)
```

**Validate:**
- brand_search → **$21.93**
- retargeting → **$31.07**
- generic_search → **$83.19**
- finance_blogs → **$95.02**
- prospecting_video → **$159.23**
- display_network → **$2,056.83**
- No slicer (all paid) → **$73.55**

---

## Group 5 — Revenue & ROAS

### [Revenue (90-day)]
**Business definition:** Total first-90-day revenue from users attributed to selected campaigns.  
**Limitation:** First 90 days only — not full LTV.  
**Format:** Currency `$#,##0.00`

```dax
[Revenue (90-day)] =
SUM( CampaignPerformance[Revenue (90-day)] )
```

**Validate:**
- No slicer (paid) → **$69,443.91**
- brand_search → **$19,470.18**

---

### [ROAS]
**Business definition:** Revenue per dollar of ad spend within 90 days. ROAS ≥ 1.0 = 90-day breakeven.  
**Format:** Decimal `0.00`

```dax
[ROAS] =
DIVIDE(
    [Revenue (90-day)],
    [Total Spend],
    BLANK()
)
```

**Validate:**
- brand_search → **1.91**
- retargeting → **1.34**
- No slicer → **0.56**
- display_network → **0.03**

---

## Group 6 — Month-over-Month Measures

> **Important:** These measures use `EDATE` + `FILTER` on the string `Month` column (format YYYY-MM),  
> not the time-intelligence shortcut functions (such as the function that shifts by N periods),  
> because the relationship to DimDate is on `month_key` (a text string "YYYY-MM"), not a true date column.  
> Time-intelligence functions require a proper date column; the EDATE+FILTER pattern below works with string months.

### [Prev Month Spend]
**Business definition:** Total spend in the calendar month immediately before the current filter context.

```dax
[Prev Month Spend] =
VAR CurrentMonth = SELECTEDVALUE( MonthlyChannelTrend[Month] )
VAR PrevMonth =
    FORMAT(
        EDATE( DATEVALUE( CurrentMonth & "-01" ), -1 ),
        "YYYY-MM"
    )
RETURN
    CALCULATE(
        SUM( MonthlyChannelTrend[Monthly Spend] ),
        MonthlyChannelTrend[Month] = PrevMonth
    )
```

**Note:** Works correctly when a single month is selected (e.g. from a slicer or matrix row).  
Returns BLANK when multiple months are selected — this is correct behaviour.

---

### [MoM Spend Change]
**Format:** Currency, with conditional formatting (green = positive, red = negative)

```dax
[MoM Spend Change] =
[Total Spend (Monthly)] - [Prev Month Spend]
```

---

### [MoM Spend Change %]
**Format:** Percentage `+0.0%;-0.0%`

```dax
[MoM Spend Change %] =
DIVIDE(
    [MoM Spend Change],
    [Prev Month Spend],
    BLANK()
)
```

---

### [Prev Month CAC]
**Business definition:** CAC in the prior month for MoM comparison.

```dax
[Prev Month CAC] =
VAR CurrentMonth = SELECTEDVALUE( MonthlyChannelTrend[Month] )
VAR PrevMonth =
    FORMAT(
        EDATE( DATEVALUE( CurrentMonth & "-01" ), -1 ),
        "YYYY-MM"
    )
RETURN
    CALCULATE(
        DIVIDE(
            SUM( MonthlyChannelTrend[Monthly Spend] ),
            SUM( MonthlyChannelTrend[Monthly Paying] ),
            BLANK()
        ),
        MonthlyChannelTrend[Month] = PrevMonth
    )
```

---

### [MoM CAC Change]
**Interpretation:** Negative = improving (CAC going down = good).  
**Format:** Currency `$#,##0.00` with colour rule: green if negative, red if positive.

```dax
[MoM CAC Change] =
DIVIDE(
    SUM( MonthlyChannelTrend[Monthly Spend] ),
    SUM( MonthlyChannelTrend[Monthly Paying] ),
    BLANK()
) - [Prev Month CAC]
```

---

### [MoM CAC Change %]
**Format:** Percentage `0.0%`

```dax
[MoM CAC Change %] =
DIVIDE(
    [MoM CAC Change],
    [Prev Month CAC],
    BLANK()
)
```

**Verified MoM CAC changes (from actual data):**

| Month | CAC | vs Prior Month |
|-------|----:|---------------|
| Jan 2025 | $79.54 | baseline |
| Feb 2025 | $75.10 | **-5.6%** |
| Mar 2025 | $78.01 | +3.9% |
| Apr 2025 | $73.89 | **-5.3%** |
| May 2025 | $68.98 | **-6.6%** |
| Jun 2025 | $65.74 | **-4.7%** |

Overall H1 improvement: **-17.4%** (Jan → Jun)

---

## Group 7 — Rankings

### [Campaign Rank by CAC]
**Business definition:** Rank 1 = most efficient (lowest CAC).  
**Format:** Whole number

```dax
[Campaign Rank by CAC] =
RANKX(
    ALL( CampaignPerformance[Campaign] ),
    [CAC],
    ,
    ASC,
    Dense
)
```

**Expected ranking:**
1. brand_search ($21.93)
2. retargeting ($31.07)
3. generic_search ($83.19)
4. finance_blogs ($95.02)
5. prospecting_video ($159.23)
6. display_network ($2,056.83)

---

### [Campaign Rank by ROAS]
**Format:** Whole number

```dax
[Campaign Rank by ROAS] =
RANKX(
    ALL( CampaignPerformance[Campaign] ),
    [ROAS],
    ,
    DESC,
    Dense
)
```

---

### [Spend Share %]
**Business definition:** This campaign's spend as a share of total paid spend.  
**Format:** Percentage `0.0%`

```dax
[Spend Share %] =
DIVIDE(
    [Total Spend],
    CALCULATE( [Total Spend], ALL( CampaignPerformance ) ),
    0
)
```

**Expected values (H1 2025):**
- brand_search: 8.2%
- retargeting: 10.4%
- generic_search: 28.8%
- finance_blogs: 12.3%
- prospecting_video: 27.2%
- display_network: 13.2%

---

## Group 8 — Status Flags (for tooltips / data labels)

### [CAC Status]
**Returns a text flag used in tooltips and conditional formatting rules.**

```dax
[CAC Status] =
IF(
    ISBLANK( [CAC] ), "No spend",
    IF( [CAC] <= 35,   "✓ Efficient",
    IF( [CAC] <= 100,  "⚠ Moderate",
                        "✗ High CAC" ) )
)
```

---

### [ROAS Status]
```dax
[ROAS Status] =
IF(
    ISBLANK( [ROAS] ), "No spend",
    IF( [ROAS] >= 1.0,  "✓ At/above 90d breakeven",
    IF( [ROAS] >= 0.5,  "⚠ Below breakeven",
                         "✗ Poor 90d return" ) )
)
```

---

## Group 9 — Unpaid Channel Benchmarks

> These measures read from the `UnpaidChannels` table, which has no relationship  
> to other tables. They are used as reference cards on Pages 1 and 2.

### [Organic CVR]
**Format:** Percentage `0.00%`

```dax
[Organic CVR] =
CALCULATE(
    DIVIDE(
        SUM( UnpaidChannels[Paying Customers] ),
        SUM( UnpaidChannels[Total Signups] ),
        0
    ),
    UnpaidChannels[Channel Key] = "organic"
)
```

**Validate:** → **9.83%**

---

### [Referral CVR]
**Format:** Percentage `0.00%`

```dax
[Referral CVR] =
CALCULATE(
    DIVIDE(
        SUM( UnpaidChannels[Paying Customers] ),
        SUM( UnpaidChannels[Total Signups] ),
        0
    ),
    UnpaidChannels[Channel Key] = "referral"
)
```

**Validate:** → **19.94%**  
*Referral converts at nearly the same rate as brand_search (21.37%) at zero media cost.*

---

## Complete Validation Checklist

After creating every measure, place a Card visual on a blank scratch page and verify:

| Measure | Slicer / Filter | Expected Value |
|---------|----------------|----------------|
| [Total Spend] | None | **$124,886.22** |
| [Total Signups] | None | **14,266** |
| [Total Paying Customers] | None | **1,698** |
| [Conversion Rate] | None | **11.90%** |
| [CAC] | None | **$73.55** |
| [ROAS] | None | **0.56** |
| [Revenue (90-day)] | None | **$69,443.91** |
| [CAC] | Campaign = brand_search | **$21.93** |
| [ROAS] | Campaign = brand_search | **1.91** |
| [CAC] | Campaign = display_network | **$2,056.83** |
| [CAC] | Campaign = retargeting | **$31.07** |
| [Conversion Rate] | Campaign = brand_search | **21.37%** |
| [Conversion Rate] | Campaign = prospecting_video | **3.29%** |
| [Cost per Signup] | Campaign = prospecting_video | **$5.23** |
| [Cost per Signup] | Campaign = brand_search | **$4.68** |
| [Spend Share %] | Campaign = brand_search | **8.2%** |
| [Spend Share %] | Campaign = display_network | **13.2%** |
| [Organic CVR] | None | **9.83%** |
| [Referral CVR] | None | **19.94%** |
| [Total Spend (Monthly)] | Month = 2025-01 | **$22,588.89** |
| [Total Spend (Monthly)] | Month = 2025-06 | **$18,077.43** |

Delete the scratch page before saving the final `.pbix`.
