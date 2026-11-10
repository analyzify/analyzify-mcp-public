# Playbook: Profit & Revenue Analysis

## Triggers

"What's my profit?", "Am I making money?", "Revenue this month?", "Show me P&L", "Net profit?", "Gross margin?", "How much am I spending on ads?", "MER?", "Marketing efficiency?", "Break down my costs", "COGS?", "Shipping costs?", "Ad spend breakdown"

## Strategy

**Primary:** `profitMerReport` via Report API — this single query combines Shopify orders + Google Ads + Meta + TikTok into one unified profit view.

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
    newCustomers newCustomerPercentage
    cpa ncac cac cvr
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

Same query but with `groupByFields: ["month"]` instead of `groupByDate: true`.

### 3. Total Summary (single number)

Same query but with `groupByDate: false` — returns one row with totals.

**In any row covering more than one day (monthly or total), `mer`, `grossMargin` and `aov` are averages of the daily values, not the period's real figure.** Compute them from the totals in the row: MER = `netRevenue / totalAdSpend`, gross margin = `grossProfit / netRevenue`, AOV = `netRevenue / orders`. `grossMargin` is a percentage (40 means 40%).

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
| CVR | X% | Visitors who become buyers |

## Key Calculations

- **MER** = Net Revenue / Total Ad Spend (higher is better; whether it is "good" depends on the margin: compare with break-even, `references/judging-performance.md`)
- **Gross Margin** = (Revenue - COGS) / Revenue × 100
- **Net Profit** = Net Revenue - COGS - Ad Spend (as the report computes it; shipping costs, fees and other costs are not subtracted, so say "profit after product cost and ads")
- **CPA** = Total Ad Spend / Total Orders
- **CAC** = Total Ad Spend / Total Customers
- **NCAC** = Total Ad Spend / New Customers Only
- **CVR** = Orders / Total Clicks × 100

## Common Follow-ups

- "Break it down by day/week/month" → adjust `groupByDate`/`dateArgs`
- "Compare to last month" → run same query with previous period dates
- "Which ads are most profitable?" → pivot to `playbooks/ad-performance.md` (`v2GadsCampaigns` + `v2MetaCampaigns`); judge profit against break-even ROAS, not 1.0 (`references/judging-performance.md`)
- "What's my best selling product?" → pivot to `ga4ProductPerformances` or `shopifyOrderAgg`
