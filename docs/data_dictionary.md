# Data Dictionary

## Source Files

| File | Rows | Cols | Size | Grain |
|------|------|------|------|-------|
| `ad_spend.csv` | 1,046 raw / 1,039 deduped | 6 | 53 KB | One row per campaign per day |
| `signups.csv` | 18,840 | 7 | 872 KB | One row per unique user |

---

## ad_spend.csv

| Column | Type | Description | Notes |
|--------|------|-------------|-------|
| `date` | DATE (string in CSV) | Calendar day the results were recorded | Format: YYYY-MM-DD; range Jan 1 – Jun 30 2025 |
| `channel` | VARCHAR | Marketing channel name | Title-case: `Paid Search`, `Paid Social`, `Display`, `Affiliate` |
| `campaign` | VARCHAR | Individual campaign name | 6 distinct values (see below) |
| `impressions` | INT | Number of times the ad was displayed | Always ≥ 0; no nulls |
| `clicks` | INT | Number of clicks on the ad | Always ≤ impressions; no nulls |
| `spend` | DECIMAL(10,2) | USD amount spent that day | Range $41.18–$240.48; no nulls or zeros |

### Campaigns in ad_spend

| campaign | channel |
|----------|---------|
| brand_search | Paid Search |
| generic_search | Paid Search |
| prospecting_video | Paid Social |
| retargeting | Paid Social |
| display_network | Display |
| finance_blogs | Affiliate |

### Data Quality Issues — ad_spend

| Issue | Count | Resolution |
|-------|-------|------------|
| Exact duplicate rows (all 6 columns identical) | 7 rows (forming 3–4 duplicate pairs) | Removed with `SELECT DISTINCT` / `ROW_NUMBER()` dedup |
| `display_network` spend stops after 2025-05-14 | Campaign ran 134 of 181 days; ended mid-May | Documented; no imputation |
| Channel names in title-case (mismatch with signups) | All 1,039 rows | `channel_key` column created: `LOWER(REPLACE(channel,' ','_'))` |

---

## signups.csv

| Column | Type | Description | Notes |
|--------|------|-------------|-------|
| `user_id` | INT | Unique user identifier | Primary key; no duplicates; range 500001–518840 |
| `signup_date` | DATE | Date user created their free account | Range Jan 1 – Jun 30 2025 |
| `channel` | VARCHAR | Channel credited with the signup | Snake-case: `paid_search`, `paid_social`, `display`, `affiliate`, `organic`, `referral` |
| `campaign` | VARCHAR | Campaign credited with the signup | NULL for organic and referral; matches ad_spend campaign names |
| `subscription_start_date` | DATE | Date user started paying for Gold | NULL if the user never subscribed (84.7% of users) |
| `plan` | VARCHAR | Subscription plan chosen | `monthly`, `annual`, or NULL |
| `revenue_first_90_days` | DECIMAL(10,2) | Total USD revenue in user's first 90 days | 0 for non-subscribers; monthly = $9.99/mo, annual = $79.99 |

### Channels in signups

| channel (signups) | Equivalent in ad_spend | Is Paid? |
|-------------------|----------------------|----------|
| paid_search | Paid Search | ✓ |
| paid_social | Paid Social | ✓ |
| display | Display | ✓ |
| affiliate | Affiliate | ✓ |
| organic | — | ✗ (no spend) |
| referral | — | ✗ (no spend) |

### Data Quality Issues — signups

| Issue | Count | Resolution |
|-------|-------|------------|
| NULL `campaign` | 4,574 rows | Expected — organic and referral have no campaign |
| NULL `subscription_start_date` | 16,585 rows (88.1%) | Expected — most users never pay; `IS NOT NULL` = paying customer |
| NULL `plan` | 16,585 rows | Same users as above |
| `revenue_first_90_days` = 0 for non-subscribers | ~15,585 rows | Correct — zero revenue before subscription |
| Duplicate `user_id` | 0 | No issue |

---

## Derived / Staging Columns

| Column | Table | Formula | Notes |
|--------|-------|---------|-------|
| `channel_key` | ad_spend | `LOWER(REPLACE(channel,' ','_'))` | Enables join to signups.channel |
| `is_paid_customer` | signups | `subscription_start_date IS NOT NULL` | Boolean flag |
| `month_key` | both | `DATE_FORMAT(date, '%Y-%m')` | For time-series aggregation |
| `ctr` | ad_spend | `clicks / impressions` | Computed in views |
| `cpc` | ad_spend | `spend / clicks` | Computed in views; NULLIF guard |
| `cps` | combined | `spend / signups` | Campaign or channel grain |
| `cac` | combined | `spend / paying_customers` | Campaign or channel grain; NULLIF guard |
| `conversion_rate` | combined | `paying_customers / signups` | Campaign or channel grain |
| `roas` | combined | `revenue_90d / spend` | Campaign or channel grain; NULLIF guard |

---

## Join Relationship

```
ad_spend (deduped, aggregated to campaign+month grain)
  JOIN
signups (aggregated to channel+campaign+month grain)
  ON  ad_spend.channel_key = signups.channel
  AND ad_spend.campaign     = signups.campaign
  AND ad_spend.month_key    = signups.month_key
```

**Important:** The join is many-to-one at the user level but one-to-one at the campaign+month aggregation level.  
Never join at the row level (daily spend × individual user) — this creates a cartesian explosion.
