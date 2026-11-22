# Playbook: Budget Allocation

## Triggers

"Where should I spend more?", "How to allocate my budget?", "Should I increase ad spend?", "Which channel to invest in?", "Am I overspending?", "Diminishing returns?", "Scale my ads?", "Budget optimization?", "Cut wasteful spending?", "What's my best channel?", "Paid vs organic split?"

## Strategy

Combine cross-platform ad data with attribution and profit metrics, so the merchant can see where spend goes and what it returns. This requires data from multiple sources. Give the facts and the trade-offs; the merchant makes the budget call.

**Queries to run:**

1. The `source_status` tool — make sure each source is connected and current before comparing them
2. The `channel_breakdown` tool — each platform's spend, conversions and ROAS, the blended MER and cost per order, and Analyzify's attributed orders per channel, in one call
3. `profitMerReport` — gross profit and margin, one row per day (add up the days, then compute margin from the sums)
4. `v2GadsCampaigns` — Google Ads campaigns
5. `v2MetaCampaigns` — Meta campaigns: spend, purchases and purchase value
6. `v2TiktokCampaigns` — TikTok campaigns: spend and conversions (no conversion value)
7. `shopifyCampaignAttributionReport` — orders and revenue by campaign as Shopify and Analyzify record them
8. `ga4Channels` — organic vs paid traffic split

Use settled days for anything you compare (the window ends 8 days before today); see `references/judging-performance.md`.

## How to Present

### Channel Efficiency Comparison

| Channel | Spend (platform) | ROAS (platform's own) | Orders (Analyzify attribution) | Order totals (Analyzify attribution) |
|---------|------------------|-----------------------|--------------------------------|--------------------------------------|
| Google Ads | $X | X.Xx | X | $X |
| Meta Ads | $X | X.Xx | X | $X |
| TikTok Ads | $X | not reported | X | $X |
| Organic channels | — | — | X | $X |
| **Store** | **$X** | **MER X.Xx** (net revenue / total ad spend) | **X** | |

Spend and ROAS are each platform's own figures; orders and order totals are Analyzify's attribution under one model (`channel_breakdown`'s Orders by channel block, or the attribution reports; say which model), so each order is counted once. Two sources, two sets of columns: never divide one by the other (no attributed order totals over spend as a ROAS, no spend over attributed orders or new customers as a cost per order or NCAC). Meta's orders can sit on Facebook, Instagram and Meta rows. Don't add up the platforms' own conversion values: they claim overlapping orders. The total uses MER = Shopify net revenue / total ad spend from `profitMerReport`.

### Revenue Dependency Analysis

| Source | Revenue | % of Total |
|--------|---------|-----------|
| Paid Channels | $X | X% |
| Organic/Free | $X | X% |

State the split as a fact ("70% of revenue came through paid channels in this period") and compare with the store's own past periods, not with a fixed benchmark.

### Campaign-Level Efficiency

| Campaign | Spend | Platform conversion value | ROAS | Break-even ROAS | Settled window |
|----------|-------|---------------------------|------|-----------------|----------------|
| Brand Search | $X | $X | 8.0x | 3.1x | 30 days to <date> |
| Generic Search | $X | $X | 2.5x | 3.1x | 30 days to <date> |
| Meta Prospecting | $X | $X | 1.5x | 3.1x | 30 days to <date> |

Show facts in this table, not a "Recommendation" column. Brand campaigns usually show the highest ROAS because they capture demand that already exists; prospecting campaigns usually show a lower ROAS because they create it. Say so rather than ranking them against each other.

### Break-even ROAS

Calculate it, don't assume 1.0:

- **margin** = `grossProfit / netRevenue`, each added up over the daily rows of `profitMerReport` for the same settled 30 days or more. A row's `grossMargin` is one day's figure, as a percentage; don't use it for a period.
- **net share** defaults to 1. Only if the merchant confirms the value sent to ad platforms includes tax and shipping, use `netSales / totalSales` from `shopifyOrderAgg` for the same window; if unsure, show both.
- **break-even ROAS = 1 / (margin × net share)**. Example: margin 40%, net share 1 → 1 / (0.40 × 1) = 2.5; net share 80% → 1 / (0.40 × 0.80) ≈ 3.1.
- Write both factors in the answer and say which net share you used, even when it is 1. Never shorten the formula to 1 / margin.
- If product costs are missing in Shopify (`costOfGoodsSold` is 0 or very low), the margin is too high. Ask for the merchant's own margin and say which you used.

### What to Say About Each Campaign

Follow `references/judging-performance.md`. A campaign is only "below break-even" when, on settled days, it is below in the last 30 days **and** the 30 before, with enough volume (see the volume rule there), while tracking was healthy. Otherwise say "too new", "too little data" or "tracking issue in this window".

Facts worth pointing out (not orders):
- ROAS against break-even, for two settled periods
- A campaign's cost per purchase and its trend, against the store's gross profit per order. Gross profit per order is `grossProfit / orders`, each added up over `profitMerReport`'s rows for the same settled window. Cost per purchase is a campaign's spend / its own purchases: Meta's stored `cpa` (`v2MetaCampaigns`, spend / purchases), or for Google Ads the campaign's purchases from a live read by `segments.conversion_action_category` (conversion metrics only) and its spend from a second live read for the same campaign and dates, never stored spend (the purchases line of `channel_breakdown`, when it is there, is the whole account, not a campaign). Google Ads' primary conversions include non-purchase actions: with a Google Ads cost per purchase, say what share of its conversions were purchases. Compare them only when both are in the same currency (an ad account billing in another currency than the shop is never compared), and not when `costOfGoodsSold` is 0 or near it: then gross profit per order is not known (it would equal the average order value), so ask for the merchant's margin or leave the line out. Google Ads' stored conversions and TikTok's conversions are not purchases, so their cost per conversion is never set against an order figure. The platforms claim overlapping orders, and stored Meta days can stay below Meta's own report, so this is a pointer, not a verdict: below break-even is decided by the ROAS test in `references/judging-performance.md`
- Meta frequency rising over recent weeks (`v2MetaAccountMetrics` daily rows; the period figure is roughly an average daily frequency, not a monthly one)
- CPM rising faster than conversion rate

Don't say "cut", "pause", "scale" or "shift budget". If the merchant asks what to do, lay out the options and what each would need to be true (for example: "more budget here only helps if the campaign isn't already limited by demand; check impression share first"), and ask what they know that the numbers don't: promotions, launches, brands they protect on purpose.

### Paid vs Organic Over Time

| Metric | This period | Previous period | Same period last year |
|--------|-------------|-----------------|-----------------------|
| Paid revenue share | X% | X% | X% |
| Email/SMS revenue share | X% | X% | X% |
| MER (net revenue / ad spend, from totals) | X.Xx | X.Xx | X.Xx |
| NCAC (ad spend / new customers) | $X | $X | $X |

Compare the store with itself, not with generic "healthy ranges": what is healthy depends on margin, price point and category.

## Common Follow-ups

- "Break down Google Ads by campaign" → `v2GadsCampaigns`
- "Which products should I advertise?" → pivot to product-optimization playbook
- "How much more can I spend?" → the data here can't show diminishing returns; say so, show the trend of CPA as spend changed over past months, and suggest a small, time-boxed test the merchant can measure
- "Should I try TikTok?" → show current TikTok metrics if connected, compare efficiency
- "What's my break-even ROAS?" → 1 / (margin × net share), as above; say which margin you used and whether product costs are set in Shopify
