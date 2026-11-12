# Playbook: Profit & Revenue Analysis

## Triggers

"What's my profit?", "Am I making money?", "Revenue this month?", "Show me P&L", "Net profit?", "Gross margin?", "How much am I spending on ads?", "MER?", "Marketing efficiency?", "Break down my costs", "COGS?", "Shipping costs?", "Ad spend breakdown"

## Strategy

**Primary:** `profitMerReport` via Report API — this single query combines Shopify orders + Google Ads + Meta + TikTok into one unified profit view. First read `v2MarketingSourceStatuses`: if a connected ad source's data stops before the end of the period, its spend may be missing from those days (or the account had no delivery), so name it and call the profit for those days provisional.

**Fallback:** If profitMerReport returns empty (no data synced), use `shopifyOrderAgg` for revenue + `v2GadsCustomerMetrics`/`v2MetaAccountMetrics`/`v2TiktokAdvertiserMetrics` separately.

## Queries

### 1. Full Profit Report (daily trend)

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated year month week day
    netRevenue netProfit currency
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    costOfGoodsSold shippingCost
    mer grossProfit grossMargin
    orders aov
    newCustomers newCustomerPercentage totalCustomers
    cpa ncac cac cvr adClicks
    adSpendComplete incompleteAdSources
  }
}
```

```json
{
  "input": {
    "default": {
      "spaceId": "{{reportSpaceId}}",
      "refId": "{{workspaceId}}",
      "startDate": "2024-03-01",
      "endDate": "2024-03-31",
      "groupByDate": true
    }
  }
}
```

### 2. Monthly Summary (for period comparison)

Same query with `groupByFields: ["month"]`: one row per calendar month (`year` and `month`), and every ratio on it (MER, margin, AOV, CPA, NCAC, CAC, CVR) is computed from the month's totals. A month that is not fully inside the date range covers only the days in the range.

### 3. Period Totals

There is no single "totals" row: `groupByDate` is ignored and rows are one per day (or one per month, above). For a period, add up the rows (`netRevenue`, `grossProfit`, `costOfGoodsSold`, `shippingCost`, `totalAdSpend` and each platform's spend, `orders`, `newCustomers`, `totalCustomers`, `adClicks`, `netProfit`).

**Compute ratios from those sums:** MER = `netRevenue / totalAdSpend`, gross margin = `grossProfit / netRevenue`, AOV = `netRevenue / orders`, CPA = `totalAdSpend / orders`, NCAC = `totalAdSpend / newCustomers`, CAC = `totalAdSpend / totalCustomers`, CVR = `orders / adClicks × 100`. Never average the daily `mer`, `grossMargin` or `aov`. `totalCustomers` counts customers per day, so summed over days a customer who ordered on two days counts twice. `grossMargin` is a percentage (40 means 40%).

**Ad spend not synced yet:** a row with `adSpendComplete: false` (today and up to two days before it, in UTC) may be missing the spend of the sources in `incompleteAdSources` (or the account simply had no delivery), so its net profit may be too high and its ad spend too low. Say those days are provisional, or end the period before them. On a monthly row, `mer`, `cpa`, `ncac`, `cac` and `cvr` leave those days out while `netProfit` and `totalAdSpend` include them: for the current month, end the period before the flagged days and add up the daily rows. A monthly ratio of 0 with `adSpendComplete: false` means "not known yet", not zero.

**Older gaps are not flagged:** `adSpendComplete: true` does not prove the spend is complete. A sync that has been failing for weeks is not flagged on older days. Before reporting profit, check `v2MarketingSourceStatuses` covers the whole period for every connected ad source, and name any source whose data stops early (a paused account also has no rows, so say spend may be missing, not that it is).

**Days without orders:** only days with Shopify orders or refunds are in the report. Ad spend on a day with neither is not counted, so `totalAdSpend` can be a little lower than the ad platforms show.

**Missing product costs:** a product without a cost in Shopify counts as zero COGS, so gross profit, margin and net profit come out too high. If `costOfGoodsSold` is 0 or looks low for the store, say so.

## How to Present

### Quick Summary (when user asks "how's my profit?")

Present a clean summary table:

| Metric | Value |
|--------|-------|
| Net Revenue | $X |
| Ad Spend | $X (Google: $X, Meta: $X, TikTok: $X) |
| COGS | $X |
| Shipping | $X (shown for reference; not subtracted in net profit) |
| **Net Profit** | **$X** |
| Gross Margin | X% |
| MER | X.Xx |

### Trend (when user asks "revenue trend" or "this month vs last")

Run the daily query and present as a time series. Highlight:
- Best and worst days
- Overall trend direction
- Any significant spikes or drops

### Cost Breakdown (when user asks "where is my money going?")

| Cost Category | Amount | % of Revenue |
|---------------|--------|-------------|
| COGS | $X | X% |
| Google Ads | $X | X% |
| Meta Ads | $X | X% |
| TikTok Ads | $X | X% |
| Shipping | $X | X% |
| **Total Costs** | **$X** | **X%** |
| **Net Profit** | **$X** | **X%** |

### Unit Economics (when user asks about CAC, CPA, AOV)

| Metric | Value | What It Means |
|--------|-------|---------------|
| AOV | $X | Average order value |
| CPA | $X | Cost to acquire one order |
| CAC | $X | Cost to acquire one customer |
| NCAC | $X | Cost to acquire one NEW customer |
| MER | X.Xx | $X revenue per $1 ad spend |
| CVR | X% | Orders per 100 ad clicks |

## Key Calculations

- **MER** = Net Revenue / Total Ad Spend (higher is better; whether it is "good" depends on the margin: compare with break-even, `references/judging-performance.md`)
- **Gross Margin** = (Revenue - COGS) / Revenue × 100
- **Net Profit** = Net Revenue - COGS - Ad Spend (as the report computes it; shipping costs, fees and other costs are not subtracted, so say "profit after product cost and ads")
- **CPA** = Total Ad Spend / Total Orders
- **CAC** = Total Ad Spend / Total Customers
- **NCAC** = Total Ad Spend / New Customers Only
- **CVR** = Orders / Total Clicks × 100

## Common Follow-ups

- "Break it down by day/week/month" → daily rows as returned; for weeks, add up the days yourself; for months, `groupByFields: ["month"]`
- "Compare to last month" → run same query with previous period dates
- "Which ads are most profitable?" → pivot to `playbooks/ad-performance.md` (`v2GadsCampaigns` + `v2MetaCampaigns`); judge profit against break-even ROAS, not 1.0 (`references/judging-performance.md`)
- "What's my best selling product?" → pivot to `ga4ProductPerformances` or `shopifyOrderAgg`
