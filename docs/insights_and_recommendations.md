# Insights & Recommendations

> All findings are verified against the actual H1 2025 dataset. SQL queries are in `05_business_analysis.sql`.

---

## Finding 1 — The Cheapest Signup Is Not the Cheapest Paying Customer

**Business question:** Which campaigns are truly efficient?

**SQL query:** Query 2 in `05_business_analysis.sql`

**Observed result:**

| Campaign | Cost per Signup | CAC | ROAS |
|----------|---------------:|----:|-----:|
| brand_search | **$4.68** | **$21.93** | 1.91 |
| prospecting_video | $5.23 | $159.23 | 0.26 |

`prospecting_video` appears efficient by cost-per-signup — it brings in volume cheaply.  
But its conversion rate is only 3.28%: only 213 of 6,484 signups ever subscribed.  
`brand_search` costs nearly the same per signup ($4.68 vs $5.23) but converts at 21.37% — more than 6× higher.  
The result is a CAC of $21.93 for brand_search vs $159.23 for prospecting — a 7× difference.

**Why it matters:** If the team optimises for CPS alone, they will continue over-investing in a channel that attracts free users who drain CAC performance.

**Recommendation:** Re-evaluate all optimisation targets to prioritise CAC and ROAS, not CPS.

---

## Finding 2 — brand_search and retargeting Are the Only Campaigns Near or Above 90-Day Breakeven

**Observed result:**

| Campaign | ROAS | Interpretation |
|----------|-----:|----------------|
| brand_search | **1.91** | Recovers $1.91 for every $1 spent within 90 days |
| retargeting | **1.34** | Recovers $1.34 — profitable within 90 days |
| generic_search | 0.47 | Recovers 47 cents — needs longer payback |
| finance_blogs | 0.41 | Similar to generic_search |
| prospecting_video | 0.26 | Recovers only 26 cents in 90 days |
| display_network | 0.03 | Near-zero return |

**Why it matters:** H1 paid marketing spent $124,886 and recovered $69,444 in 90-day revenue (overall ROAS 0.56). Only two campaigns exceed 1.0x, meaning only those two can be considered near-term positive-ROI without relying on long-term retention assumptions.

**Recommendation:** Shift budget from sub-0.5 ROAS campaigns toward brand_search and retargeting where each dollar works harder immediately.

---

## Finding 3 — display_network Consumed 13% of Budget With Near-Zero Returns

**Observed result:**
- Total spend: $16,455 over ~4.5 months (Jan 1 – May 14 2025)
- Active days: **134** (vs 181 for all other campaigns)
- Paying customers acquired: **8**
- CAC: **$2,056.83** (vs next-worst $159.23 for prospecting)
- ROAS: **0.03**
- Campaign ended: **2025-05-14** — no spend after mid-May

**Why it matters:** $16,455 spent to acquire 8 paying customers represents a clear capital allocation failure. The campaign was 93× less efficient by CAC than brand_search.

**Alternative explanation:** Display campaigns often serve brand awareness rather than direct response, meaning the 90-day conversion window may understate their contribution to later organic conversions. However, no multi-touch attribution data is available to test this hypothesis.

**Recommendation:** Reallocate the display budget (13% of total) primarily to brand_search and retargeting in H2. Retain a small display test budget (≤5%) only if a brand-awareness objective is explicitly approved by the CMO.

---

## Finding 4 — Referral Converts at Comparable Rates to the Best Paid Campaigns, for Free

**Observed result:**

| Channel | Signups | Conversion Rate | Revenue | Direct Cost |
|---------|--------:|----------------:|--------:|-------------|
| referral | 1,063 | **19.94%** | $9,476 | $0 |
| brand_search | 2,177 | 21.37% | $19,470 | $10,197 |
| organic | 3,511 | 9.83% | $14,473 | $0 |

**Why it matters:** Referral users convert at nearly the same rate as brand_search — the best-performing paid campaign — while incurring no media cost. 1,063 referral signups produced 212 paying customers. If a referral incentive programme (e.g., one free month of Gold for both referrer and referee) converts another 1,000 users at the same rate (200 paying customers), the implied CAC would only be the incentive cost (~$30–$60 in Gold credits), versus $21.93 for brand_search.

**Recommendation:** Invest in a formalised referral programme. A structured in-app referral flow and incentive may dramatically increase referral volume at a CAC competitive with the best paid campaigns.

---

## Finding 5 — CAC Improved 17% Over the Six-Month Period

**Observed result:**

| Month | Spend | Paying Customers | CAC | Trend |
|-------|------:|----------------:|----:|-------|
| Jan 2025 | $22,589 | 284 | $79.54 | baseline |
| Feb 2025 | $20,278 | 270 | $75.10 | -5.6% |
| Mar 2025 | $22,076 | 283 | $78.01 | +3.9% |
| Apr 2025 | $21,724 | 294 | $73.89 | -5.3% |
| May 2025 | $20,143 | 292 | $68.98 | -6.6% |
| Jun 2025 | $18,077 | 275 | $65.74 | -4.7% |

Overall CAC improvement Jan→Jun: **-17.4%**

**Why it matters:** The portfolio is becoming more efficient over time, even without explicit optimisation. The primary driver is likely the wind-down of display_network (the worst performer) from May onward. This trend supports the H2 strategy of continuing to reduce exposure to poor-performing campaigns.

**Recommendation:** Set a target of CAC < $60 for H2 2025 by completing the budget reallocation toward brand_search and retargeting.

---

## H2 2025 Budget Recommendation (Summary)

Total H1 paid spend: $124,886  
Assumed H2 budget: same or similar total

| Campaign | H1 Share | H2 Recommended Share | Action | Key Rationale |
|----------|:--------:|:-------------------:|--------|---------------|
| brand_search | 8.2% | **18%** | ↑ Increase | Lowest CAC ($21.93), ROAS 1.91, dominates on both metrics |
| retargeting | 10.4% | **20%** | ↑ Increase | 2nd lowest CAC ($31.07), ROAS 1.34, above 90-day breakeven |
| generic_search | 28.8% | **25%** | → Maintain | Decent volume; moderate CAC ($83); worth testing bid adjustments |
| finance_blogs | 12.3% | **12%** | → Maintain | Acceptable CAC ($95); consistent publisher relationship |
| prospecting_video | 27.2% | **20%** | ↓ Reduce | Poor conversion quality (3.3% CVR); major CAC driver |
| display_network | 13.2% | **5%** | ↓ Minimise | Essentially zero conversion; campaign ended May 2025 |

**Risks of this plan:**

1. **Top-of-funnel starvation:** prospecting_video generates the most raw signups (6,484). Cutting it too aggressively could reduce the pool of users that retargeting reaches. Monitor retargeting signup volume in H2.
2. **Brand search saturation:** brand_search targets users already searching for "Robinhood". This audience is finite. Doubling the budget may increase CPCs without doubling conversions.
3. **Display brand value unquantified:** display campaigns may contribute to assisted conversions (users who later search for "Robinhood" organically). Without multi-touch attribution data, this contribution is invisible.
4. **Small base for referral programme:** a new referral programme requires in-product engineering investment and CMO sign-off beyond the scope of this analysis.

**Monitoring metrics for H2:**
- Monthly CAC target: < $60
- ROAS target: > 0.8 (closer to full-portfolio breakeven)
- Retargeting signup volume (early warning if prospecting cut is too aggressive)
- Referral signup growth rate

---

## Limitations of This Analysis

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| 90-day revenue window only | ROAS underestimates true LTV | Apply conservative adjustment for annual subscribers |
| Last-touch attribution only | Campaign contribution is binary, not weighted | Acknowledge in budget recommendation |
| No creative-level data | Cannot distinguish underperforming audiences from underperforming creatives | Request creative breakdown from media platforms |
| No audience overlap data | Cannot measure re-exposure across channels | Request impression share data from platforms |
| 6-month history only | Seasonality effects unknown | Flag H2 may differ (summer vs Q1/Q2) |
