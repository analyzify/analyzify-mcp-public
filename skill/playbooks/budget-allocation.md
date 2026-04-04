# Playbook: Budget Allocation & Scaling Decisions

## Triggers

"Where should I spend more?", "How to allocate my budget?", "Should I increase ad spend?", "Which channel to invest in?", "Am I overspending?", "Diminishing returns?", "Scale my ads?", "Budget optimization?", "Cut wasteful spending?", "What's my best channel?", "Paid vs organic split?"

## Strategy

Combine cross-platform ad data with attribution and profit metrics to give budget recommendations. This requires data from multiple sources.

**Queries to run:**

1. `profitMerReport` — total revenue, profit, and ad spend by platform
2. `gadsCustomerMetrics` — Google Ads efficiency
3. `gadsCampaignsPerformance` — Google campaign-level data
4. `fbAccountInsights` + `fbAccountActionValues` — Meta efficiency + revenue
5. `tiktokAdvertiserInsights` — TikTok efficiency
6. `shopifyCampaignAttributionReport` — true attribution by channel
7. `ga4Channels` — organic vs paid traffic split

## How to Present

### Channel Efficiency Comparison

| Channel | Spend | Revenue (Attributed) | ROAS | CPA | New Customers | NCAC |
|---------|-------|---------------------|------|-----|---------------|------|
| Google Ads | $X | $X | X.Xx | $X | X | $X |
| Meta Ads | $X | $X | X.Xx | $X | X | $X |
| TikTok Ads | $X | $X | X.Xx | $X | X | $X |
| Organic | $0 | $X | — | — | X | — |
| **Total** | **$X** | **$X** | **X.Xx (MER)** | **$X** | **X** | **$X** |

### Revenue Dependency Analysis

| Source | Revenue | % of Total |
|--------|---------|-----------|
| Paid Channels | $X | X% |
| Organic/Free | $X | X% |

Flag if paid > 70%: "Your business is heavily reliant on paid traffic. Consider investing in SEO, email, and content to reduce dependency."

### Campaign-Level Efficiency (for reallocation)

| Campaign | Spend | Revenue | ROAS | Recommendation |
|----------|-------|---------|------|----------------|
| Brand Search | $X | $X | 8.0x | Maintain — high ROAS, captures demand |
| Generic Search | $X | $X | 2.5x | Moderate — test scaling cautiously |
| Shopping | $X | $X | 4.0x | Scale — strong ROAS, can handle more |
| Meta Prospecting | $X | $X | 1.5x | Watch — near break-even |
| Meta Retargeting | $X | $X | 6.0x | Scale — high ROAS, low spend |
| TikTok | $X | $X | 0.8x | Reduce — below break-even |

### Recommendations Framework

After analyzing the data, provide specific guidance:

**Break-even ROAS:** Calculate from profitMerReport data
- `breakEvenROAS = 1 / grossMargin`
- Example: If gross margin is 40%, break-even ROAS = 2.5x
- Any campaign above this is profitable; below is losing money

**Scaling signals (increase spend):**
- ROAS above break-even AND CPA trending down
- High conversion rate with room to grow impressions
- New customer acquisition cost below LTV

**Warning signals (reduce spend):**
- ROAS below break-even for 2+ weeks
- CPA trending up while conversion rate is flat
- Frequency > 3 on Meta (audience fatigue)
- CPMs increasing faster than conversion rate

**Reallocation logic:**
1. Cut spend from campaigns with ROAS < break-even
2. Shift budget to campaigns with ROAS > 2× break-even
3. Allocate test budget (10-15%) to new channels/campaigns
4. Protect brand campaigns (usually highest ROAS)

### Paid vs Organic Health Check

| Metric | Current | Healthy Range |
|--------|---------|---------------|
| Paid Revenue % | X% | 40-60% |
| Organic Revenue % | X% | 30-50% |
| Email/SMS Revenue % | X% | 15-30% |
| MER | X.Xx | >3x is strong |
| Blended CAC | $X | < 1/3 of LTV |

## Common Follow-ups

- "Break down Google Ads by campaign" → `gadsCampaignsPerformance`
- "Which products should I advertise?" → pivot to product-optimization playbook
- "How much more can I spend?" → estimate from current ROAS × diminishing returns curve
- "Should I try TikTok?" → show current TikTok metrics if connected, compare efficiency
- "What's my break-even ROAS?" → calculate from gross margin in profitMerReport
