# Judging Ad Performance: "Is This Losing Money?"

Read this before you call a campaign, product or channel a loser, a winner or "wasted spend", or say it should be paused, cut or scaled.

A raw ROAS read gives the wrong answer more often than the right one. In one store's audit, most of the campaigns first called "losing" were not losing once their conversions had come in. Most of the products flagged as losers had been profitable the quarter before. The checks below are what separates a finding from noise.

## 1. Rates come from totals

Never read CTR, CPC, CPM, CPA, ROAS, conversion rate, MER, margin or AOV from a row that covers more than one day in a legacy report. Several legacy reports add up or average the daily rates (`gadsCampaignsPerformance`, `gadsCustomerMetrics`, `gadsSearchTermViews`, `gadsProductPerformance` nodes, `fbAccountInsights`, `fbCampaignInsights`, `tiktokAdvertiserInsights`, `tiktokCampaignInsights`, and `mer`, `grossMargin` and `aov` in `profitMerReport`).

- Use the `v2*` reports. Their rates are already computed from totals (see `references/reports.md`, "Marketing reports (v2)").
- Otherwise compute the rate yourself from the totals in the same row:
  - ROAS = conversion value / cost
  - CPA = cost / conversions
  - CTR = clicks / impressions
  - CPC = cost / clicks
  - MER = net revenue / ad spend
  - margin = gross profit / net revenue
  - AOV = revenue / orders
- When you add rows together (campaigns into a channel, variants into a product), add up the totals first, then divide. Never add or average the rates.

## 2. Settled days only

Ad platforms keep adding conversions for days after the click. A Google Ads read of the last 7 days can be 30% short or more, and Meta restates its numbers for up to 28 days.

- End a judging window at least **8 days before today**.
- If the user asks about the last few days, give the numbers but say they are not settled yet, and don't judge them.

## 3. Break-even is not ROAS 1.0

ROAS 1.0 means the platform credited sales equal to the spend. The product cost, tax and shipping are still unpaid, so a campaign at ROAS 2 can lose money.

**Break-even ROAS on the platform's numbers = 1 / (margin × net share)**

- **margin** = `grossProfit / netRevenue` from `profitMerReport`, both summed over the same settled 30 days or more. Don't use `grossMargin` from a multi-day row: it is a percentage (40 means 40%), averaged over days.
- **net share** = how much of the value the platform reports is net sales. The conversion value sent to ad platforms often includes tax and shipping, depending on the store's tracking settings. Estimate it as `netSales / totalSales` from `shopifyOrderAgg` for the same window. If you can't tell, use 1 and say that break-even may be higher.
- **Missing product costs make the margin too high.** A product without a cost in Shopify counts as zero cost. If `costOfGoodsSold` is 0 or close to it, or the merchant says many products have no cost set, ask for their usual margin and use that. Always say which margin you used.

Example: margin 40% and net share 80% give break-even ROAS = 1 / (0.40 × 0.80) ≈ 3.1. A campaign at ROAS 2.5 is below break-even here.

## 4. Before any "below break-even" finding

All of these must hold, or the answer is "not enough to judge", with the reason:

1. **Tracking was healthy for the whole window.** Run the source check (`v2MarketingSourceStatuses`) and look at conversion health (`gadsLastSeenConversions`, `v2GadsConversionActions` `lastSeen`). A failed sync, a gap in coverage, or conversions that stopped make every campaign look like a loser. Say "tracking broke, not performance". Conversions that suddenly double often mean a second purchase action was set to primary.
2. **Two periods.** Below break-even in the last settled 30 days **and** in the 30 days before that. One bad month is mostly noise.
3. **Enough volume.** 30 or more conversions in the window, or spend of at least 5× the account's cost per conversion. Below that: "too little data to judge this one".
4. **The campaign sells.** Awareness, video, and brand-protection campaigns aren't judged on their own ROAS. List them as "not judged".
5. **Not a special case.** Not launched or changed in the last 14 days, and not running a promotion (a sale, a seasonal push, a launch). If you don't know, ask.

## 5. State facts; don't give orders

- **Don't say "pause", "cut", "kill", "scale", "discontinue" or "wasted"**, and don't present a list as "losers". The merchant decides; you show what was measured.
- Say what was measured, over which settled windows, and against which break-even. Then add one line on what it doesn't mean:
  - The platform credits the whole order to the click, including other products in the basket.
  - Other channels may claim the same orders.
  - The margin comes from products with a cost set.
- Offer questions, not actions: "Is this a promotion, a new launch, or a brand you protect on purpose?"
- For campaigns close to break-even (within about 1.5×), give a count only, no list: "3 campaigns are within 1.5× of break-even". Credit shared with other channels, freight and fees can move them either way.
- A store with fewer than 30 conversions a month in total gets account-level figures only: MER and break-even, and the sentence "not enough volume to judge single campaigns".

**Wording example (made-up numbers):**

> Over the 30 settled days to 3 Nov, "Generic Search" had a ROAS of 2.4 on Google's numbers (spend 2,000, conversion value 4,800). With your 40% margin and about 80% of order value being net sales, break-even is about 3.1. It was also below break-even in the 30 days before (ROAS 2.7). Google credits the whole basket to the click, so some of these orders may have come through other products or channels.

## 6. Preset filters are a starting list, never a verdict

The product presets `HIGHER_COST_LOWER_ROAS`, `LOWER_COST_LOWER_ROAS` and `UNDERPERFORMERS` compare against ROAS 1 and the range's average spend. They don't know the store's break-even and don't check settled days, volume or tracking. Use them to find items to look at, check each one against sections 2–4, and never call their output "losing money".
