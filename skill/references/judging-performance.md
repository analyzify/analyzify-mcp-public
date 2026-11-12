# Judging Ad Performance: "Is This Losing Money?"

Read this before you call a campaign, product or channel a loser, a winner or "wasted spend", or say it should be paused, cut or scaled.

A raw ROAS read gives the wrong answer more often than the right one. In one store's audit, most of the campaigns first called "losing" were not losing once their conversions had come in. Most of the products flagged as losers had been profitable the quarter before. The checks below are what separates a finding from noise.

## 1. Rates come from totals

In a legacy report, don't read CTR, CPC, CPM, CPA, ROAS, conversion rate, MER, margin or AOV from a row that covers more than one day: compute the rate from the totals in that row. That gives the right answer however the report computed its rate field. `profitMerReport` computes the ratios of a monthly row from the month's totals; for any other period, add up its daily rows, then divide.

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

- End a judging window at least **8 days before today** for Google Ads and TikTok. Meta can restate for 28 days: treat a Meta window ending less than 28 days ago as provisional and say so.
- If the user asks about the last few days, give the numbers but say they are not settled yet, and don't judge them.

## 3. Break-even is not ROAS 1.0

ROAS 1.0 means the platform credited sales equal to the spend. The product cost, tax and shipping are still unpaid, so a campaign at ROAS 2 can lose money.

**Break-even ROAS on the platform's numbers = 1 / (margin × net share)**

- **margin** = `grossProfit / netRevenue`, each added up over the rows of `profitMerReport` for the same settled 30 days or more. A daily row's `grossMargin` is that one day's figure, as a percentage (40 means 40%): don't use it for a period.
- **net share** = how much of the value the platform reports is net sales. **Default to 1** (the value sent is net sales), which gives the lowest, most cautious break-even. Only if the merchant confirms the conversion value includes tax and shipping, use `netSales / totalSales` from `shopifyOrderAgg` for the same window. If you don't know, show both break-evens and say which assumption each makes.
- **Missing product costs make the margin too high.** A product without a cost in Shopify counts as zero cost. If `costOfGoodsSold` is 0 or close to it, or the merchant says many products have no cost set, ask for their usual margin and use that. Always say which margin you used.

Example: margin 40% gives break-even ROAS = 1 / 0.40 = 2.5. If the value sent includes tax and shipping and net sales are 80% of it, break-even = 1 / (0.40 × 0.80) ≈ 3.1.

Product verdicts use the account margin unless the merchant gives a product's own margin; say so.

## 4. Before any "below break-even" finding

All of these must hold, or the answer is "not enough to judge", with the reason:

1. **Tracking was healthy for the whole window.** A failed sync, a gap in the data or a tag that stopped firing makes every campaign look like a loser. Check, for the window:
   - `v2MarketingSourceStatuses` (or the report's own `meta`): `freshness.status` isn't `failed`, and `coverage.missingDays` is 0 with no `gapRanges` inside the window.
   - The daily rows of `v2GadsCustomerMetrics` / `v2MetaAccountMetrics`: no day with normal spend or clicks but zero conversions. (`lastSeen` in `v2GadsConversionActions` only shows the latest conversion, so it misses an outage in the middle of the window.)
   - No day where conversions suddenly double: that often means a second purchase action was set to primary.

   If any check fails, there is no verdict. Say "tracking broke, not performance", and name the dates.
2. **Two periods.** Below break-even in the last settled 30 days **and** in the 30 days before that. One bad month is mostly noise.
3. **Enough volume.** 30 or more conversions in the window. With fewer, judge only when the shortfall is clear: expected conversions at break-even = spend × break-even ROAS ÷ the account's value per conversion. Zero conversions needs at least 3 expected. With some conversions, at least 6 must be expected and fewer than half of them observed. Below that: "too little data to judge this one".
4. **The campaign sells.** Awareness, video, and brand-protection campaigns aren't judged on their own ROAS. List them as "not judged".
5. **Big enough to mention.** The loss is at least 2× the account's cost per conversion, where loss = spend − (conversion value × margin × net share). Smaller gaps get a count, not a line.
6. **Not a special case.** Not launched or changed in the last 14 days, and not running a promotion (a sale, a seasonal push, a launch). If you don't know, ask.

## 5. State facts; don't give orders

- **Don't say "pause", "cut", "kill", "scale", "discontinue" or "wasted"**, and don't present a list as "losers". The merchant decides; you show what was measured.
- Say what was measured, over which settled windows, and against which break-even. Then add one line on what it doesn't mean:
  - The platform credits the whole order to the click, including other products in the basket.
  - Other channels may claim the same orders.
  - The margin comes from products with a cost set.
- Offer questions, not actions: "Is this a promotion, a new launch, or a brand you protect on purpose?"
- For campaigns just below break-even (ROAS between break-even ÷ 1.5 and break-even), give a count only, no names: "3 campaigns are slightly below break-even". Credit shared with other channels, freight and fees can move them either way. Name a campaign only when it is further below than that.
- When you can, add what Analyzify itself recorded: orders and revenue for the same campaign from `shopifyCampaignAttributionReport` (matched by campaign name). It is a floor, not the full picture, but it is the store's own record rather than the platform's claim.
- A store with fewer than 30 conversions a month in total gets account-level figures only: MER and break-even, and the sentence "not enough volume to judge single campaigns".

**Wording example (made-up numbers):**

> Over the 30 settled days to 3 Nov, "Generic Search" had a ROAS of 2.4 on Google's numbers (spend 2,000, conversion value 4,800, 31 conversions). It needs about 3.9 to cover product cost with your margin. It was also below in the 30 days before (ROAS 2.5). We can match 14 Shopify orders to its clicks. Google credits the whole basket to the click, so some of these orders may have come through other products or channels.

## 6. Preset filters are a starting list, never a verdict

The product presets `HIGHER_COST_LOWER_ROAS` and `LOWER_COST_LOWER_ROAS` compare against ROAS 1 and the range's average spend; `UNDERPERFORMERS` means spend above average and under 1 conversion. They don't know the store's break-even and don't check settled days, volume or tracking. Use them to find items to look at, check each one against sections 2–4, and never call their output "losing money".
