# Playbook: Budget Allocation & Scaling Decisions

## Triggers

"Where should I spend more?", "How to allocate my budget?", "Should I increase ad spend?", "Which channel to invest in?", "Am I overspending?", "Diminishing returns?", "Scale my ads?", "Budget optimization?", "Cut wasteful spending?", "What's my best channel?", "Paid vs organic split?"

## Strategy

Combine cross-platform ad data with attribution and profit metrics, so the merchant can see where spend goes and what it returns. This requires data from multiple sources. Give the facts and the trade-offs; the merchant makes the budget call.

**Queries to run:**

1. `profitMerReport` — net revenue, gross profit, COGS and ad spend by platform (compute MER and margin from the totals)
2. `v2GadsCustomerMetrics` / `v2GadsCampaigns` — Google Ads totals and campaigns
3. `v2MetaCampaigns` — Meta spend, purchases and purchase value
4. `v2TiktokCampaigns` — TikTok spend and conversions (no conversion value)
5. `shopifyCampaignAttributionReport` — orders and revenue by channel as Shopify and Analyzify record them
6. `ga4Channels` — organic vs paid traffic split
7. `v2MarketingSourceStatuses` — make sure each source is connected and current before comparing them

Use settled days for anything you compare (the window ends 8 days before today); see `references/judging-performance.md`.

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

### Campaign-Level Efficiency

| Campaign | Spend | Platform conversion value | ROAS | Break-even ROAS | Settled window |
|----------|-------|---------------------------|------|-----------------|----------------|
| Brand Search | $X | $X | 8.0x | 3.1x | 30 days to <date> |
| Generic Search | $X | $X | 2.5x | 3.1x | 30 days to <date> |
| Meta Prospecting | $X | $X | 1.5x | 3.1x | 30 days to <date> |

Show facts in this table, not a "Recommendation" column. Brand campaigns usually show the highest ROAS because they capture demand that already exists; prospecting campaigns usually show a lower ROAS because they create it. Say so rather than ranking them against each other.

### Break-even ROAS

Calculate it, don't assume 1.0:

- **margin** = `grossProfit / netRevenue` from `profitMerReport`, summed over the same settled 30 days or more. `grossMargin` in a multi-day row is a percentage averaged over days; don't use it directly.
- **net share** = `netSales / totalSales` from `shopifyOrderAgg` for the same window (the value sent to ad platforms often includes tax and shipping).
- **break-even ROAS = 1 / (margin × net share)**. Example: margin 40%, net share 80% → 1 / 0.32 ≈ 3.1.
- If product costs are missing in Shopify (`costOfGoodsSold` is 0 or very low), the margin is too high. Ask for the merchant's own margin and say which you used.

### What to Say About Each Campaign

Follow `references/judging-performance.md`. A campaign is only "below break-even" when, on settled days, it is below in the last 30 days **and** the 30 before, with enough volume (30+ conversions, or spend of 5× the account's cost per conversion), while tracking was healthy. Otherwise say "too new", "too little data" or "tracking issue in this window".

Facts worth pointing out (not orders):
- ROAS against break-even, for two settled periods
- CPA and its trend against the store's average order value
- Frequency above 3 on Meta (the same people see the ads often)
- CPM rising faster than conversion rate

Don't say "cut", "pause", "scale" or "shift budget". If the merchant asks what to do, lay out the options and what each would need to be true (for example: "more budget here only helps if the campaign isn't already limited by demand; check impression share first"), and ask what they know that the numbers don't: promotions, launches, brands they protect on purpose.

### Paid vs Organic Health Check

| Metric | Current | Healthy Range |
|--------|---------|---------------|
| Paid Revenue % | X% | 40-60% |
| Organic Revenue % | X% | 30-50% |
| Email/SMS Revenue % | X% | 15-30% |
| MER (net revenue / ad spend, from totals) | X.Xx | depends on margin: compare with break-even |
| Blended CAC | $X | < 1/3 of LTV |

## Common Follow-ups

- "Break down Google Ads by campaign" → `v2GadsCampaigns`
- "Which products should I advertise?" → pivot to product-optimization playbook
- "How much more can I spend?" → the data here can't show diminishing returns; say so, show the trend of CPA as spend changed over past months, and suggest a small, time-boxed test the merchant can measure
- "Should I try TikTok?" → show current TikTok metrics if connected, compare efficiency
- "What's my break-even ROAS?" → 1 / (margin × net share), as above; say which margin you used and whether product costs are set in Shopify
